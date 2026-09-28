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
    /// Live head direction relative to where she started (x right, y down on screen), roughly
    /// -1...1. Drives the dot that follows her nose around the ring.
    private(set) var pointer: CGPoint = .zero

    var filledCount: Int { filled.filter { $0 }.count }
    var progress: Double { Double(filledCount) / Double(Self.segmentCount) }

    @ObservationIgnored let session = ARSession()
    @ObservationIgnored var onFinish: (([UIImage]) -> Void)?
    @ObservationIgnored private let ciContext = CIContext()
    @ObservationIgnored private var centeredSince: Date?
    @ObservationIgnored private var smoothed: SIMD2<Double>?
    @ObservationIgnored private var steadyReference: SIMD2<Double> = .zero
    @ObservationIgnored private var baseline: SIMD2<Double> = .zero
    @ObservationIgnored private var capturedSides: Set<Int> = []

    // Tuning. Direction values are roughly sin(head angle): 0.22 is about a 13 degree turn.
    @ObservationIgnored private let steadyTolerance: Double = 0.05
    @ObservationIgnored private let turnThreshold: Double = 0.22
    /// How far a turn reaches the ring for the pointer dot.
    @ObservationIgnored private let pointerReach: Double = 0.42
    /// 0...1, higher follows faster, lower is steadier.
    @ObservationIgnored private let smoothing: Double = 0.35

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

        // Hints are advice only; they never pause the scan.
        if let light = frame.lightEstimate, light.ambientIntensity < 250 {
            setHint("Find brighter, even light")
        } else if distance > 0.6 {
            setHint("Bring your phone a little closer")
        } else if distance < 0.2 {
            setHint("Hold your phone a little farther away")
        } else {
            setHint(nil)
        }

        // Smooth out jitter from frame to frame.
        let raw = headDirection(face: face, camera: frame.camera)
        let current = smoothed.map { $0 + (raw - $0) * smoothing } ?? raw
        smoothed = current

        switch phase {
        case .aligning:
            // Wherever she naturally holds the phone becomes "center" once she's steady,
            // so a phone held low or off to one side doesn't throw off the ring.
            if simd_length(current - steadyReference) < steadyTolerance {
                let since = centeredSince ?? Date()
                centeredSince = since
                if Date().timeIntervalSince(since) > 0.7 {
                    baseline = current
                    capture(frame)                 // straight-on photo
                    phase = .circling
                }
            } else {
                steadyReference = current
                centeredSince = nil
            }

        case .circling:
            let relative = current - baseline
            updatePointer(relative)

            let magnitude = simd_length(relative)
            guard magnitude > turnThreshold else { return }

            // Screen angle: 0 = right, increasing clockwise (screen y points down).
            let fullTurn = Double.pi * 2
            let angle = (atan2(relative.y, relative.x) + fullTurn).truncatingRemainder(dividingBy: fullTurn)

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

    /// Where the head is pointing, as seen on the mirrored selfie preview:
    /// x > 0 toward the right edge of the screen, y > 0 toward the bottom. About sin(angle).
    private func headDirection(face: ARFaceAnchor, camera: ARCamera) -> SIMD2<Double> {
        // The face's "forward" (out of the nose) in the camera's portrait view space,
        // where x is screen-right and y is screen-up for the un-mirrored image.
        let forwardWorld = simd_float4(simd_normalize(simd_make_float3(face.transform.columns.2)), 0)
        let forwardView = camera.viewMatrix(for: .portrait) * forwardWorld
        // Mirror x for the selfie preview; flip y so down is positive like SwiftUI.
        return SIMD2(Double(-forwardView.x), Double(-forwardView.y))
    }

    private func updatePointer(_ relative: SIMD2<Double>) {
        var point = relative / pointerReach
        let length = simd_length(point)
        if length > 1 { point /= length }
        let next = CGPoint(x: point.x, y: point.y)
        if abs(next.x - pointer.x) > 0.01 || abs(next.y - pointer.y) > 0.01 {
            pointer = next
        }
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
