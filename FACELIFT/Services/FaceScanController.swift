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
        case aligning   // line her face up with the outline
        case mapping    // the scan line sweeps down and back up her face
        case circling   // fill the ring
        case done
    }

    enum LightLevel: Equatable {
        case good
        case low
    }

    /// Width of the oval window for a given screen width. Shared with the view.
    static func ovalWidth(for screenWidth: CGFloat) -> CGFloat { min(screenWidth * 0.8, 340) }
    /// Oval height = width x this.
    static let ovalAspect: CGFloat = 1.3
    /// Seconds for the scan line to sweep down and back up.
    static let mappingDuration: Double = 1.8

    static var isSupported: Bool { ARFaceTrackingConfiguration.isSupported }
    /// One segment per tick on the ring, so what lights up is exactly where her nose went.
    static let segmentCount = 48

    private(set) var phase: Phase = .aligning
    private(set) var filled: [Bool] = Array(repeating: false, count: FaceScanController.segmentCount)
    private(set) var hint: String?
    private(set) var captures: [UIImage] = []
    /// Live head direction relative to where she started (x right, y down on screen), roughly
    /// -1...1. Drives the dot that follows her nose around the ring.
    private(set) var pointer: CGPoint = .zero
    /// 0...1: how closely her face lines up with the outline at the start. Brightens it.
    private(set) var alignment: Double = 0
    /// 0...1 through the scan-line sweep while mapping.
    private(set) var sweepProgress: Double = 0
    private(set) var lightLevel: LightLevel = .good

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
    @ObservationIgnored private var mappingStart: TimeInterval?
    @ObservationIgnored private var capturedSides: Set<Int> = []

    // Tuning. Direction values are roughly sin(head angle): 0.28 is about a 16 degree turn.
    @ObservationIgnored private let steadyTolerance: Double = 0.05
    /// Seconds of a steady match with the outline before the scan starts.
    @ObservationIgnored private let holdDuration: Double = 0.5

    // Face outline geometry, as fractions of the circle's diameter. Shared with the view.
    /// Target distance between her eyes on screen (about 30 to 45 cm from the phone).
    static let eyeSpacing: CGFloat = 0.24
    /// Target height of her eyes relative to the circle's center (negative is up).
    static let eyeOffsetY: CGFloat = -0.1
    @ObservationIgnored private let turnThreshold: Double = 0.28
    /// Attention each tick needs before it lights (neighbors share half, so a smooth sweep
    /// lights ticks right under the dot). A full circle takes roughly 6 to 9 seconds.
    @ObservationIgnored private let dwellPerSegment: Double = 0.2
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
            hold = 0
            if alignment != 0 { alignment = 0 }
            return
        }

        let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
        let facePosition = simd_make_float3(face.transform.columns.3)
        let distance = simd_length(cameraPosition - facePosition)

        // Hints are advice only; they never pause the scan.
        if let light = frame.lightEstimate {
            let level: LightLevel = light.ambientIntensity < (lightLevel == .low ? 380 : 300) ? .low : .good
            if level != lightLevel { lightLevel = level }
        }
        if phase == .circling && distance > 0.55 {
            setHint("Bring your phone a little closer")
        } else if phase == .circling && distance < 0.26 {
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
            // She lines her face up with the outline: eyes on the marks, the right size
            // (distance), level, and looking straight ahead. Holding a match starts the scan.
            let match = outlineMatch(face: face, direction: current)
            let isSteady = simd_length(current - steadyReference) < steadyTolerance
            steadyReference = current + (steadyReference - current) * 0.8

            if match.isMatched && isSteady {
                hold = min(1, hold + elapsed / holdDuration)
            } else {
                hold = max(0, hold - elapsed * 2)
                if hint == nil, let tip = match.hint { setHint(tip) }
            }

            let shown = match.isMatched ? 1 : match.score * 0.85
            if abs(shown - alignment) > 0.04 || shown == 1 {
                if shown != alignment { alignment = shown }
            }

            if hold >= 1 {
                baseline = current
                capture(frame)                 // straight-on photo
                mappingStart = frame.timestamp
                phase = .mapping
            }

        case .mapping:
            let elapsed = frame.timestamp - (mappingStart ?? frame.timestamp)
            let progress = min(1, elapsed / Self.mappingDuration)
            sweepProgress = progress
            if progress >= 1 {
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

    /// Compares her eyes (as drawn on screen) with the outline's eye marks.
    private func outlineMatch(face: ARFaceAnchor, direction: SIMD2<Double>) -> (score: Double, isMatched: Bool, hint: String?) {
        guard let view = sceneView, view.bounds.width > 0 else { return (0, false, nil) }
        let bounds = view.bounds
        let diameter = Self.ovalWidth(for: bounds.width)
        let target = CGPoint(x: bounds.midX, y: bounds.midY + Self.eyeOffsetY * diameter)
        let targetSpacing = Self.eyeSpacing * diameter

        func onScreen(_ eye: simd_float4x4) -> CGPoint {
            let world = face.transform * eye
            let p = view.projectPoint(SCNVector3(world.columns.3.x, world.columns.3.y, world.columns.3.z))
            return CGPoint(x: CGFloat(p.x), y: CGFloat(p.y))
        }
        let left = onScreen(face.leftEyeTransform)
        let right = onScreen(face.rightEyeTransform)
        let middle = CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)

        let offset = Double(hypot(middle.x - target.x, middle.y - target.y) / diameter)
        let size = Double(hypot(left.x - right.x, left.y - right.y) / targetSpacing)
        let tiltAngle = abs(atan2(Double(right.y - left.y), Double(right.x - left.x)))
        let tilt = min(tiltAngle, .pi - tiltAngle) * 180 / .pi
        let facing = simd_length(direction)

        let score = max(0, 1 - offset / 0.25) * max(0, 1 - abs(size - 1) / 0.6) * max(0, 1 - facing / 0.5)
        let isMatched = offset < 0.07 && abs(size - 1) < 0.22 && tilt < 10 && facing < 0.2

        let hint: String?
        if size < 0.78 {
            hint = "Bring your phone a little closer"
        } else if size > 1.22 {
            hint = "Hold your phone a little farther away"
        } else if offset >= 0.07 {
            hint = "Line your face up with the outline"
        } else if facing >= 0.2 || tilt >= 10 {
            hint = "Look straight at the screen"
        } else {
            hint = nil
        }
        return (score, isMatched, hint)
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
