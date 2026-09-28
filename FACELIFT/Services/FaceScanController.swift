import ARKit
import SceneKit
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
    /// 0...1 while she holds still at the start; fills the thin ring around the circle.
    private(set) var holdProgress: Double = 0

    var filledCount: Int { filled.filter { $0 }.count }
    var progress: Double { Double(filledCount) / Double(Self.segmentCount) }

    @ObservationIgnored let session = ARSession()
    /// The on-screen preview. Head direction is measured in its coordinates, so the ring
    /// always matches exactly what she sees (mirroring included).
    @ObservationIgnored weak var sceneView: ARSCNView?
    @ObservationIgnored var onFinish: (([UIImage]) -> Void)?
    @ObservationIgnored private let ciContext = CIContext()
    @ObservationIgnored private var smoothed: SIMD2<Double>?
    @ObservationIgnored private var steadyReference: SIMD2<Double> = .zero
    @ObservationIgnored private var baseline: SIMD2<Double> = .zero
    /// Seconds her nose has spent pointing at each segment. A segment fills once it has
    /// been held long enough, which paces the scan so it can't be whipped through.
    @ObservationIgnored private var dwell: [Double] = Array(repeating: 0, count: FaceScanController.segmentCount)
    @ObservationIgnored private var lastTimestamp: TimeInterval?
    @ObservationIgnored private var hold: Double = 0
    @ObservationIgnored private var capturedSides: Set<Int> = []

    // Tuning. Direction values are roughly sin(head angle): 0.28 is about a 16 degree turn.
    @ObservationIgnored private let steadyTolerance: Double = 0.05
    /// How close to center the dot must be to start the hold (about 10 degrees).
    @ObservationIgnored private let centerTolerance: Double = 0.18
    /// Seconds of steady, centered hold before the scan starts.
    @ObservationIgnored private let holdDuration: Double = 1.0
    @ObservationIgnored private let turnThreshold: Double = 0.28
    /// How long each segment needs her attention before it fills (16 segments).
    @ObservationIgnored private let dwellPerSegment: Double = 0.3
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
        // Sharpest photos the front camera offers during face tracking.
        if let best = ARFaceTrackingConfiguration.supportedVideoFormats.max(by: {
            $0.imageResolution.width * $0.imageResolution.height < $1.imageResolution.width * $1.imageResolution.height
        }) {
            configuration.videoFormat = best
        }
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
            hold = max(0, hold - 0.05)
            if hold == 0 && holdProgress != 0 { holdProgress = 0 }
            return
        }

        let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
        let facePosition = simd_make_float3(face.transform.columns.3)
        let distance = simd_length(cameraPosition - facePosition)

        // Hints are advice only; they never pause the scan.
        if let light = frame.lightEstimate, light.ambientIntensity < 250 {
            setHint("Find brighter, even light")
        } else if distance > 0.55 {
            setHint("Bring your phone a little closer")
        } else if distance < 0.28 {
            setHint("Hold your phone a little farther away")
        } else {
            setHint(nil)
        }

        // Smooth out jitter from frame to frame.
        let raw = headDirection(face: face, camera: frame.camera)
        let current = smoothed.map { $0 + (raw - $0) * smoothing } ?? raw
        smoothed = current

        let elapsed = min(max(frame.timestamp - (lastTimestamp ?? frame.timestamp), 0), 0.1)
        lastTimestamp = frame.timestamp

        switch phase {
        case .aligning:
            // The dot follows her nose right away; centering it and holding still fills the
            // hold ring. Moving drains it.
            updatePointer(current)
            let isSteady = simd_length(current - steadyReference) < steadyTolerance
            let isCentered = simd_length(current) < centerTolerance
            steadyReference = current + (steadyReference - current) * 0.8

            if isSteady && isCentered {
                hold = min(1, hold + elapsed / holdDuration)
            } else {
                hold = max(0, hold - elapsed * 2)
                if hint == nil {
                    setHint(isCentered ? "Hold still for a moment" : "Center the dot in the circle")
                }
            }

            // Publish in small steps so the screen isn't redrawn every single frame.
            if abs(hold - holdProgress) > 0.03 || hold == 0 || hold == 1 {
                if hold != holdProgress { holdProgress = hold }
            }

            if hold >= 1 {
                baseline = current
                capture(frame)                 // straight-on photo
                phase = .circling
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
            // Time spent here counts fully for this segment and half for its neighbors,
            // so a slow sweep fills smoothly without needing pixel-perfect aim. Nothing is
            // filled on her behalf: the ring completes only when she's actually gone around.
            let count = Self.segmentCount
            dwell[index] += elapsed
            dwell[(index + 1) % count] += elapsed * 0.5
            dwell[(index + count - 1) % count] += elapsed * 0.5

            var updated = filled
            for i in 0..<count where !updated[i] && dwell[i] >= dwellPerSegment {
                updated[i] = true
            }
            if updated != filled { filled = updated }

            // One photo per side: right, down, left, up.
            let side = Int(((angle + .pi / 4).truncatingRemainder(dividingBy: fullTurn)) / (.pi / 2)) % 4
            // Wait until she's held this direction long enough to fill it: steadier photo.
            if filled[index] && !capturedSides.contains(side) {
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

    /// Where the nose is pointing on screen: x > 0 toward the right edge, y > 0 toward the
    /// bottom, roughly sin(angle). Measured by projecting a point 10 cm out from the face
    /// (along the nose) into the preview view, so it matches what she sees.
    private func headDirection(face: ARFaceAnchor, camera: ARCamera) -> SIMD2<Double> {
        let facePosition = simd_make_float3(face.transform.columns.3)
        let forward = simd_normalize(simd_make_float3(face.transform.columns.2))
        let sideways = simd_normalize(simd_make_float3(face.transform.columns.0))

        func onScreen(_ point: simd_float3) -> CGPoint {
            if let view = sceneView {
                let projected = view.projectPoint(SCNVector3(point.x, point.y, point.z))
                return CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
            }
            return camera.projectPoint(point, orientation: .portrait, viewportSize: CGSize(width: 1000, height: 1000))
        }

        let center = onScreen(facePosition)
        let ahead = onScreen(facePosition + forward * 0.1)
        let side = onScreen(facePosition + sideways * 0.1)
        let scale = max(Double(hypot(side.x - center.x, side.y - center.y)), 1)
        return SIMD2(Double(ahead.x - center.x) / scale, Double(ahead.y - center.y) / scale)
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
        // Don't pause here: pausing freezes her last (mid-turn) frame on screen. The view
        // fades the camera out, then stops the session when it goes away.
        onFinish?(captures)
    }

    private func setHint(_ text: String?) {
        if hint != text { hint = text }
    }
}
