import ARKit
import CoreImage
import UIKit
import Observation

/// Drives the "move your head in a circle" scan.
///
/// ARKit's face tracking (the Face ID camera) reports where her head is pointing many times a
/// second. We turn that into a direction on screen, fill the matching segment of the ring, and
/// grab a sharp photo from the front plus each side (right, down, left, up) along the way.
/// Photos live in memory only and are handed to the caller when the ring is complete.
@Observable
final class FaceScanController: NSObject, ARSessionDelegate {
    enum Phase: Equatable {
        case aligning   // look straight ahead to start
        case circling   // fill the ring
        case done
    }

    static var isSupported: Bool { ARFaceTrackingConfiguration.isSupported }
    static let segmentCount = 16

    private(set) var phase: Phase = .aligning
    private(set) var filled: [Bool] = Array(repeating: false, count: FaceScanController.segmentCount)
    private(set) var hint: String?
    private(set) var captures: [UIImage] = []

    var filledCount: Int { filled.filter { $0 }.count }
    var progress: Double { Double(filledCount) / Double(Self.segmentCount) }

    @ObservationIgnored let session = ARSession()
    @ObservationIgnored var onFinish: (([UIImage]) -> Void)?
    @ObservationIgnored private let ciContext = CIContext()
    @ObservationIgnored private var centeredSince: Date?
    @ObservationIgnored private var capturedSides: Set<Int> = []

    // Tuning. Direction values are roughly sin(head angle): 0.26 is about a 15 degree turn.
    @ObservationIgnored private let centeredThreshold: Double = 0.12
    @ObservationIgnored private let turnThreshold: Double = 0.26

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard Self.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }

    /// "Having trouble?" escape hatch: finish with whatever photos we have.
    func finishNow() {
        finish()
    }

    // MARK: ARSessionDelegate (delivered on the main queue)

    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        MainActor.assumeIsolated {
            self.process(frame)
        }
    }

    // MARK: Frame processing

    private func process(_ frame: ARFrame) {
        guard phase != .done else { return }

        guard let face = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first, face.isTracked else {
            setHint("Center your face in the circle")
            centeredSince = nil
            return
        }

        let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
        let facePosition = simd_make_float3(face.transform.columns.3)
        let distance = simd_length(cameraPosition - facePosition)

        if let light = frame.lightEstimate, light.ambientIntensity < 250 {
            setHint("Find brighter, even light")
            return
        }
        if distance > 0.6 {
            setHint("Bring your phone a little closer")
            return
        }
        if distance < 0.2 {
            setHint("Hold your phone a little farther away")
            return
        }
        setHint(nil)

        let direction = headDirection(face: face, facePosition: facePosition, camera: frame.camera)
        let magnitude = hypot(direction.x, direction.y)

        switch phase {
        case .aligning:
            if magnitude < centeredThreshold {
                let since = centeredSince ?? Date()
                centeredSince = since
                if Date().timeIntervalSince(since) > 0.6 {
                    capture(frame)                 // straight-on photo
                    phase = .circling
                }
            } else {
                centeredSince = nil
            }

        case .circling:
            guard magnitude > turnThreshold else { return }

            // Screen angle: 0 = right, increasing clockwise (screen y points down).
            let fullTurn = Double.pi * 2
            let angle = (atan2(direction.y, direction.x) + fullTurn).truncatingRemainder(dividingBy: fullTurn)

            let index = min(Int(angle / fullTurn * Double(Self.segmentCount)), Self.segmentCount - 1)
            var updated = filled
            updated[index] = true
            // Forgive single gaps between two filled segments.
            for i in 0..<Self.segmentCount where !updated[i] {
                let previous = updated[(i + Self.segmentCount - 1) % Self.segmentCount]
                let next = updated[(i + 1) % Self.segmentCount]
                if previous && next { updated[i] = true }
            }
            if updated != filled { filled = updated }

            // One photo per side: right, down, left, up.
            let side = Int(((angle + .pi / 4).truncatingRemainder(dividingBy: fullTurn)) / (.pi / 2)) % 4
            if !capturedSides.contains(side) {
                capturedSides.insert(side)
                capture(frame)
            }

            if filled.allSatisfy({ $0 }) {
                finish()
            }

        case .done:
            break
        }
    }

    /// Where the head is pointing, as seen on the (mirrored) selfie preview.
    /// x > 0 is toward the right edge of the screen, y > 0 toward the bottom.
    private func headDirection(face: ARFaceAnchor, facePosition: simd_float3, camera: ARCamera) -> (x: Double, y: Double) {
        let viewport = CGSize(width: 1000, height: 1000)
        let forward = simd_normalize(simd_make_float3(face.transform.columns.2))
        let sideways = simd_normalize(simd_make_float3(face.transform.columns.0))

        let center = camera.projectPoint(facePosition, orientation: .portrait, viewportSize: viewport)
        let ahead = camera.projectPoint(facePosition + forward * 0.1, orientation: .portrait, viewportSize: viewport)
        let side = camera.projectPoint(facePosition + sideways * 0.1, orientation: .portrait, viewportSize: viewport)

        let scale = max(Double(hypot(side.x - center.x, side.y - center.y)), 1)
        // The preview is mirrored like a selfie, so flip x to match what she sees.
        let x = -Double(ahead.x - center.x) / scale
        let y = Double(ahead.y - center.y) / scale
        return (x, y)
    }

    private func capture(_ frame: ARFrame) {
        guard captures.count < 6 else { return }
        let image = CIImage(cvPixelBuffer: frame.capturedImage).oriented(.leftMirrored)
        let longest = max(image.extent.width, image.extent.height)
        let scale = min(1, 1600 / longest)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = ciContext.createCGImage(scaled, from: scaled.extent) else { return }
        captures.append(UIImage(cgImage: cgImage))
    }

    private func finish() {
        guard phase != .done else { return }
        phase = .done
        session.pause()
        onFinish?(captures)
    }

    private func setHint(_ text: String?) {
        if hint != text { hint = text }
    }
}
