import SwiftUI
import ARKit
import SceneKit

/// Full-screen guided scan: a large circular live preview with a rose face mesh and a
/// segmented ring around it. A dot follows her nose from the start; she centers it and holds
/// still (a thin ring fills), the ticks light up, then she slowly circles her head.
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
                    ARFacePreview(controller: scan)
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

                    // Hold ring: fills while she keeps the dot centered and still.
                    if scan.phase == .aligning {
                        Circle()
                            .trim(from: 0, to: scan.holdProgress)
                            .stroke(Palette.rose, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: diameter + 10, height: diameter + 10)
                            .animation(.linear(duration: 0.1), value: scan.holdProgress)
                            .position(center)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }

                    // Dot that follows her nose, from the very first frame.
                    if scan.phase != .done {
                        Circle()
                            .fill(Palette.rose)
                            .frame(width: 12, height: 12)
                            .shadow(color: Palette.rose.opacity(0.9), radius: 8)
                            .position(
                                x: center.x + scan.pointer.x * ringRadius,
                                y: center.y + scan.pointer.y * ringRadius
                            )
                            .animation(.linear(duration: 0.08), value: scan.pointer)
                            .allowsHitTesting(false)
                            .transition(.opacity)
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
        case .aligning: "Center the dot\nand hold still"
        case .circling: "Now slowly circle\nyour head"
        case .done: "Scan complete"
        }
    }

    private var subtitle: String {
        switch scan.phase {
        case .aligning: "Your scan starts in a moment"
        case .circling: "Fill the ring all the way around"
        case .done: " "
        }
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

/// Live, mirrored front-camera feed from the ARKit session, with a fine rose wireframe
/// of her face that follows every movement.
private struct ARFacePreview: UIViewRepresentable {
    let controller: FaceScanController

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

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

/// Draws ARKit's face geometry as a thin rose mesh. Called on SceneKit's render thread.
final class FaceMeshRenderer: NSObject, ARSCNViewDelegate {
    nonisolated func renderer(_ renderer: any SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor,
              let device = renderer.device,
              let geometry = ARSCNFaceGeometry(device: device) else { return nil }

        let material = geometry.firstMaterial ?? SCNMaterial()
        material.fillMode = .lines
        material.lightingModel = .constant
        material.diffuse.contents = UIColor(red: 0.83, green: 0.63, blue: 0.63, alpha: 1)
        material.isDoubleSided = false
        geometry.firstMaterial = material

        let node = SCNNode(geometry: geometry)
        node.opacity = 0.35
        return node
    }

    nonisolated func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let face = anchor as? ARFaceAnchor,
              let geometry = node.geometry as? ARSCNFaceGeometry else { return }
        geometry.update(from: face.geometry)
    }
}
