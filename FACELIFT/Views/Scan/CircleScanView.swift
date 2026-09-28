import SwiftUI
import ARKit
import SceneKit

/// Full-screen guided scan: a large circular live preview inside a segmented ring.
/// She lines her face up with an outline to start; when it matches, the ticks light up and a
/// constellation appears on her features, then she slowly circles her head to fill the ring.
struct CircleScanView: View {
    let onComplete: ([UIImage]) -> Void
    let onCancel: () -> Void

    @State private var scan = FaceScanController()
    @State private var showsQuickOption: Bool = false
    @State private var pulse: Bool = false
    @State private var flash: Double = 0
    @State private var finishSweep: CGFloat = 0
    @State private var finishGlow: Bool = false
    @State private var cameraOpacity: Double = 1

    var body: some View {
        ZStack {
            Palette.night.ignoresSafeArea()

            // Camera, tint, circle and ring, all centered on the screen.
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let diameter = min(width * 0.8, 360)
                let center = CGPoint(x: width / 2, y: height / 2 - 30)
                let ringRadius = diameter / 2 + 23

                ZStack {
                    // Native 3:4 camera (no extra zoom), centered, with its top and bottom
                    // edges faded into the background so there's no hard edge.
                    ARFacePreview(controller: scan, isMeshVisible: scan.phase == .circling)
                        .frame(width: width, height: width * 4 / 3)
                        .opacity(cameraOpacity)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.18),
                                    .init(color: .black, location: 0.82),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .position(center)

                    Rectangle()
                        .fill(Palette.night.opacity(0.7))
                        .mask {
                            ZStack {
                                Rectangle()
                                Circle()
                                    .frame(width: diameter, height: diameter)
                                    .position(center)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        }
                        .allowsHitTesting(false)

                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .frame(width: diameter, height: diameter)
                        .position(center)

                    // Shutter: a soft white flash each time a photo is taken.
                    Circle()
                        .fill(Color.white)
                        .frame(width: diameter, height: diameter)
                        .opacity(flash)
                        .position(center)
                        .allowsHitTesting(false)

                    // Finish: a rose sweep closes the ring, then glows once.
                    Circle()
                        .trim(from: 0, to: finishSweep)
                        .stroke(Palette.rose, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: ringRadius * 2, height: ringRadius * 2)
                        .shadow(color: Palette.rose.opacity(finishGlow ? 0.95 : 0), radius: finishGlow ? 24 : 0)
                        .position(center)
                        .allowsHitTesting(false)

                    SegmentRing(filled: scan.filled, diameter: ringRadius * 2, isLive: scan.phase != .aligning)
                        .position(center)

                    // Face outline: line up with it to start. Brightens and turns rose as her
                    // face matches, then dissolves when the scan begins.
                    if scan.phase == .aligning {
                        FaceOutline(diameter: diameter, alignment: scan.alignment)
                            .position(center)
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    }

                    // Instructions sit just under the ring.
                    VStack(spacing: 0) {
                        instructions
                        if showsQuickOption && scan.phase != .done {
                            Button {
                                scan.finishNow()
                            } label: {
                                Text("Having trouble? Finish scan")
                                    .font(FLFont.sans(14))
                                    .foregroundStyle(Palette.nightBody)
                                    .underline()
                                    .frame(height: 44)
                            }
                            .buttonStyle(PressableStyle())
                            .padding(.top, 4)
                            .transition(.opacity)
                        }
                    }
                    .frame(width: width - 64)
                    .fixedSize(horizontal: false, vertical: true)
                    .position(x: center.x, y: center.y + ringRadius + 90)
                }
            }
            .ignoresSafeArea()

            // Top bar respects the status bar.
            VStack(spacing: 0) {
                header
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeOut(duration: 0.25), value: scan.phase)
        .animation(.easeOut(duration: 0.25), value: scan.hint)
        .sensoryFeedback(.selection, trigger: scan.filledCount)
        .sensoryFeedback(.impact(weight: .light), trigger: scan.captures.count)
        .sensoryFeedback(.success, trigger: finishGlow)
        .onChange(of: scan.captures.count) { _, _ in
            flash = 0.35
            withAnimation(.easeOut(duration: 0.4)) { flash = 0 }
        }
        .onAppear {
            pulse = true
            scan.onFinish = { images in
                Task { @MainActor in
                    await playFinish()
                    onComplete(images)
                }
            }
            scan.start()
        }
        .onDisappear { scan.stop() }
        .task {
            try? await Task.sleep(for: .seconds(25))
            withAnimation { showsQuickOption = true }
        }
    }

    /// Ring closes with a rose sweep, glows once, then hands off to the analysis screen.
    private func playFinish() async {
        withAnimation(.easeOut(duration: 0.3)) { cameraOpacity = 0 }
        try? await Task.sleep(for: .milliseconds(250))
        scan.stop()
        withAnimation(.easeInOut(duration: 0.55)) { finishSweep = 1 }
        try? await Task.sleep(for: .milliseconds(550))
        withAnimation(.easeOut(duration: 0.35)) { finishGlow = true }
        try? await Task.sleep(for: .milliseconds(650))
    }

    /// Top bar: close on the left, the privacy promise centered.
    private var header: some View {
        ZStack {
            PrivacyNote(tint: Color(hex: 0xD9D1CF))

            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Palette.nightBody)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Cancel scan")
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
    }

    private var instructions: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(FLFont.serif(30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            Text(scan.hint ?? subtitle)
                .font(FLFont.sans(15))
                .foregroundStyle(scan.hint == nil ? Palette.nightBody : Palette.rose)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            ZStack(alignment: .leading) {
                Capsule().fill(Palette.nightTrack)
                Capsule()
                    .fill(Palette.rose)
                    .frame(width: 160 * scan.progress)
                    .animation(.easeOut(duration: 0.2), value: scan.progress)
            }
            .frame(width: 160, height: 3)
            .padding(.top, 8)
        }
    }

    private var title: String {
        switch scan.phase {
        case .aligning: "Line your face up\nwith the outline"
        case .circling: "Now slowly circle\nyour head"
        case .done: "Scan complete"
        }
    }

    private var subtitle: String {
        switch scan.phase {
        case .aligning: "Eyes on the marks, then hold still"
        case .circling: "Fill the ring all the way around"
        case .done: " "
        }
    }
}

/// Dotted face oval with two eye marks. Its geometry matches what the scan controller checks.
private struct FaceOutline: View {
    let diameter: CGFloat
    /// 0...1 from the controller.
    let alignment: Double

    var body: some View {
        let ovalWidth = diameter * 0.56
        let ovalHeight = diameter * 0.76
        let eyeY = FaceScanController.eyeOffsetY * diameter
        let eyeX = FaceScanController.eyeSpacing * diameter / 2
        let isMatched = alignment >= 1
        let color = isMatched ? Palette.rose : Color.white.opacity(0.35 + 0.45 * alignment)

        ZStack {
            Ellipse()
                .stroke(color, style: StrokeStyle(lineWidth: isMatched ? 2.5 : 1.5, lineCap: .round, dash: isMatched ? [] : [2, 7]))
                .frame(width: ovalWidth, height: ovalHeight)
                .offset(y: diameter * 0.05)
                .shadow(color: Palette.rose.opacity(isMatched ? 0.8 : 0), radius: 10)

            ForEach([-1.0, 1.0], id: \.self) { side in
                EyeMark()
                    .stroke(color, style: StrokeStyle(lineWidth: isMatched ? 2.5 : 1.8, lineCap: .round))
                    .frame(width: diameter * 0.1, height: diameter * 0.035)
                    .offset(x: CGFloat(side) * eyeX, y: eyeY)
            }
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeOut(duration: 0.2), value: alignment)
        .sensoryFeedback(.impact(weight: .medium), trigger: isMatched)
    }
}

/// A soft almond: the eye mark on the outline.
private struct EyeMark: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.6))
        return p
    }
}

/// 48 tick marks around the preview; each lights up rose as its part of the circle is covered.
private struct SegmentRing: View {
    let filled: [Bool]
    let diameter: CGFloat
    /// Dim while she's centering; switching on lights the ticks up in a quick sweep.
    var isLive: Bool = true

    private let ticks = 48

    var body: some View {
        ZStack {
            ForEach(0..<ticks, id: \.self) { tick in
                let segment = tick * filled.count / ticks
                let isOn = filled.indices.contains(segment) && filled[segment]
                // Tick angle measured clockwise from the right, matching the controller.
                let angle = (Double(tick) + 0.5) / Double(ticks) * 360

                Capsule()
                    .fill(isOn ? Palette.rose : Color.white.opacity(isLive ? 0.3 : 0.08))
                    .frame(width: 4, height: 22)
                    .scaleEffect(y: isOn ? 1 : (isLive ? 0.72 : 0.45), anchor: .center)
                    .shadow(color: Palette.rose.opacity(isOn ? 0.8 : 0), radius: isOn ? 6 : 0)
                    .offset(y: -diameter / 2)
                    .rotationEffect(.degrees(angle + 90))
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isOn)
                    // Ignition: ticks switch on one after another around the ring.
                    .animation(.easeOut(duration: 0.25).delay(Double(tick) * 0.012), value: isLive)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement()
        .accessibilityLabel("Scan progress")
        .accessibilityValue("\(filled.filter { $0 }.count) of \(filled.count)")
    }
}

/// Live, mirrored front-camera feed from the ARKit session, with a delicate rose
/// "constellation" mesh on her face.
private struct ARFacePreview: UIViewRepresentable {
    let controller: FaceScanController
    /// Hidden while she centers; draws on at ignition; dissolves at the end.
    let isMeshVisible: Bool

    func makeCoordinator() -> FaceMeshRenderer { FaceMeshRenderer() }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session = controller.session
        view.delegate = context.coordinator
        controller.sceneView = view
        view.scene = SCNScene()
        view.automaticallyUpdatesLighting = false
        view.backgroundColor = .black
        // Make sure the scan controller (not the view) receives frame updates.
        controller.session.delegate = controller
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.setVisible(isMeshVisible)
    }
}

/// A constellation on her face: glowing stars on real features (brows, eye corners, nose,
/// cheekbones, lips, jaw, chin, forehead) joined by fine rose lines, moving live with her.
/// Landmarks are found once on ARKit's face mesh, then follow it every frame.
/// ARKit calls the renderer methods on SceneKit's render thread.
final class FaceMeshRenderer: NSObject, ARSCNViewDelegate {
    nonisolated(unsafe) private var container: SCNNode?
    nonisolated(unsafe) private var stars: [SCNNode] = []
    nonisolated(unsafe) private var linesNode: SCNNode?
    nonisolated(unsafe) private var landmarks: [Int] = []
    nonisolated(unsafe) private var wantsVisible = false

    /// Star pairs joined by lines (indexes into the landmark list built below).
    private static let links: [(Int, Int)] = [
        // Brows (outer, middle, inner) on each side, meeting at the bridge.
        (0, 1), (1, 2), (2, 12), (3, 4), (4, 5), (5, 12),
        // Eyes: inner corner to outer corner.
        (6, 7), (8, 9),
        // Forehead to inner brows; bridge down the nose to the lips and chin.
        (20, 2), (20, 5), (12, 13), (13, 16), (16, 17),
        // Outer eye to cheekbone to jaw to chin.
        (7, 14), (14, 18), (18, 17), (9, 15), (15, 19), (19, 17)
    ]

    private static let lineColor = UIColor(red: 0.90, green: 0.70, blue: 0.70, alpha: 0.55)

    func setVisible(_ visible: Bool) {
        guard visible != wantsVisible else { return }
        wantsVisible = visible
        guard let node = container else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = visible ? 0.8 : 0.3
        node.opacity = visible ? 1 : 0
        node.scale = visible ? SCNVector3(1, 1, 1) : SCNVector3(1.04, 1.04, 1.04)
        SCNTransaction.commit()
    }

    nonisolated func renderer(_ renderer: any SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let face = anchor as? ARFaceAnchor else { return nil }
        landmarks = Self.findLandmarks(face)

        let node = SCNNode()
        let glow = Self.glowImage
        stars = landmarks.map { _ in
            let plane = SCNPlane(width: 0.011, height: 0.011)
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.diffuse.contents = glow
            material.blendMode = .add
            material.writesToDepthBuffer = false
            material.readsFromDepthBuffer = false
            plane.firstMaterial = material
            let star = SCNNode(geometry: plane)
            star.constraints = [SCNBillboardConstraint()]
            star.renderingOrder = 10
            node.addChildNode(star)
            return star
        }

        let lines = SCNNode()
        lines.renderingOrder = 5
        node.addChildNode(lines)
        linesNode = lines

        node.opacity = wantsVisible ? 1 : 0
        node.scale = wantsVisible ? SCNVector3(1, 1, 1) : SCNVector3(1.04, 1.04, 1.04)
        container = node
        update(face)
        return node
    }

    nonisolated func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let face = anchor as? ARFaceAnchor else { return }
        update(face)
    }

    /// Moves every star to its landmark and redraws the lines between them.
    nonisolated private func update(_ face: ARFaceAnchor) {
        let vertices = face.geometry.vertices
        guard !landmarks.isEmpty, landmarks.allSatisfy({ $0 < vertices.count }) else { return }
        // Lift points a hair off the skin so they never sink into it.
        let points = landmarks.map { vertices[$0] + simd_float3(0, 0, 0.002) }

        for (star, point) in zip(stars, points) {
            star.simdPosition = point
        }

        let source = SCNGeometrySource(vertices: points.map { SCNVector3($0.x, $0.y, $0.z) })
        var indices: [UInt16] = []
        for (a, b) in Self.links where a < points.count && b < points.count {
            indices.append(UInt16(a))
            indices.append(UInt16(b))
        }
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = Self.lineColor
        material.writesToDepthBuffer = false
        material.readsFromDepthBuffer = false
        geometry.firstMaterial = material
        linesNode?.geometry = geometry
    }

    /// Picks mesh vertices for each landmark using the face's own geometry and eye positions,
    /// so it adapts to every face. Order matters: `links` refers to these positions.
    nonisolated private static func findLandmarks(_ face: ARFaceAnchor) -> [Int] {
        let v = face.geometry.vertices
        guard !v.isEmpty else { return [] }

        let leftEye = simd_make_float3(face.leftEyeTransform.columns.3)
        let rightEye = simd_make_float3(face.rightEyeTransform.columns.3)
        let eyeY = (leftEye.y + rightEye.y) / 2
        let half = abs(leftEye.x - rightEye.x) / 2   // half the eye spacing
        let sign: Float = leftEye.x < rightEye.x ? -1 : 1   // which x side the left eye is on

        // Nearest vertex to a point on the face (x, y), preferring the front surface.
        func nearest(_ x: Float, _ y: Float) -> Int {
            var best = 0
            var bestScore = Float.greatestFiniteMagnitude
            for (i, p) in v.enumerated() {
                let score = (p.x - x) * (p.x - x) + (p.y - y) * (p.y - y) - 0.02 * p.z
                if score < bestScore {
                    bestScore = score
                    best = i
                }
            }
            return best
        }

        let noseTip = v.indices.max { v[$0].z < v[$1].z } ?? 0
        let centerLine = v.indices.filter { abs(v[$0].x) < 0.006 }
        let chin = centerLine.min { v[$0].y < v[$1].y } ?? noseTip
        let forehead = centerLine.max { v[$0].y < v[$1].y } ?? noseTip
        let tipY = v[noseTip].y
        let chinY = v[chin].y
        let browY = eyeY + 0.024

        func side(_ s: Float, _ amount: Float) -> Float { s * sign * half * amount }

        return [
            // 0-2 left brow (outer, middle, inner), 3-5 right brow (outer, middle, inner)
            nearest(side(1, 1.65), browY - 0.004), nearest(side(1, 1.05), browY + 0.003), nearest(side(1, 0.45), browY),
            nearest(side(-1, 1.65), browY - 0.004), nearest(side(-1, 1.05), browY + 0.003), nearest(side(-1, 0.45), browY),
            // 6-7 left eye inner/outer corner, 8-9 right eye inner/outer corner
            nearest(side(1, 0.55), eyeY), nearest(side(1, 1.5), eyeY),
            nearest(side(-1, 0.55), eyeY), nearest(side(-1, 1.5), eyeY),
            // 10-11 unused spacers kept for stable numbering (under-eye)
            nearest(side(1, 1.0), eyeY - 0.018), nearest(side(-1, 1.0), eyeY - 0.018),
            // 12 bridge, 13 nose tip
            nearest(0, eyeY + 0.004), noseTip,
            // 14-15 cheekbones
            nearest(side(1, 1.55), eyeY - 0.032), nearest(side(-1, 1.55), eyeY - 0.032),
            // 16 upper lip center, 17 chin
            nearest(0, tipY - 0.026), chin,
            // 18-19 jaw
            nearest(side(1, 1.35), chinY + 0.03), nearest(side(-1, 1.35), chinY + 0.03),
            // 20 top of forehead
            forehead
        ]
    }

    /// Bright core with a soft rose halo, drawn once.
    private static let glowImage: UIImage = {
        let size = CGSize(width: 64, height: 64)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [
                UIColor(white: 1, alpha: 1).cgColor,
                UIColor(red: 1, green: 0.86, blue: 0.85, alpha: 0.9).cgColor,
                UIColor(red: 0.83, green: 0.55, blue: 0.56, alpha: 0.35).cgColor,
                UIColor(red: 0.83, green: 0.55, blue: 0.56, alpha: 0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0, 0.14, 0.4, 1]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            context.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: size.width / 2, options: [])
        }
    }()
}
