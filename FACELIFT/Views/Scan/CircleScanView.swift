import SwiftUI
import ARKit
import SceneKit

/// Full-screen guided scan: a large circular live preview with a segmented ring around it.
/// She looks straight ahead to start, then slowly circles her head until the ring is full.
struct CircleScanView: View {
    let onComplete: ([UIImage]) -> Void
    let onCancel: () -> Void

    @State private var scan = FaceScanController()
    @State private var showsQuickOption: Bool = false
    @State private var pulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let diameter = min(width * 0.8, 360)
            let top = geo.safeAreaInsets.top
            let centerY = top + 96 + diameter / 2 + 20

            ZStack {
                // Full-screen live camera; the dark layer on top has a clear circle cut out,
                // so she sees herself framed, with the rest softly visible behind the tint.
                // Camera at its natural 3:4 shape (no extra zoom), centered on the circle
                // so her face lands inside it.
                ARFacePreview(controller: scan)
                    .frame(width: width, height: width * 4 / 3)
                    .position(x: width / 2, y: centerY)

                Rectangle()
                    .fill(Palette.night.opacity(0.72))
                    .mask {
                        ZStack {
                            Rectangle()
                            Circle()
                                .frame(width: diameter, height: diameter)
                                .position(x: width / 2, y: centerY)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    }
                    .allowsHitTesting(false)

                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .frame(width: diameter, height: diameter)
                    .position(x: width / 2, y: centerY)

                SegmentRing(filled: scan.filled, diameter: diameter + 46)
                    .position(x: width / 2, y: centerY)

                // Glowing dot that follows her nose around the ring.
                if scan.phase == .circling {
                    Circle()
                        .fill(Palette.rose)
                        .frame(width: 16, height: 16)
                        .shadow(color: Palette.rose.opacity(0.9), radius: 10)
                        .position(
                            x: width / 2 + scan.pointer.x * (diameter / 2 + 23),
                            y: centerY + scan.pointer.y * (diameter / 2 + 23)
                        )
                        .animation(.linear(duration: 0.08), value: scan.pointer)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                VStack(spacing: 0) {
                    header
                        .padding(.top, top)
                    PrivacyNote(tint: Color(hex: 0xC9C1BF))
                        .padding(.top, 6)
                    Spacer()
                }

                VStack(spacing: 0) {
                    instructions
                        .padding(.horizontal, 32)

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
                        .padding(.top, 6)
                        .transition(.opacity)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, centerY + diameter / 2 + 48)
            }
            .frame(width: width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .background(Palette.night.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .animation(.easeOut(duration: 0.25), value: scan.phase)
        .animation(.easeOut(duration: 0.25), value: scan.hint)
        .sensoryFeedback(.selection, trigger: scan.filledCount)
        .sensoryFeedback(.success, trigger: scan.phase == .done)
        .onAppear {
            pulse = true
            scan.onFinish = { images in onComplete(images) }
            scan.start()
        }
        .onDisappear { scan.stop() }
        .task {
            try? await Task.sleep(for: .seconds(25))
            withAnimation { showsQuickOption = true }
        }
    }

    private var header: some View {
        ZStack {
            HStack(spacing: 9) {
                Circle()
                    .fill(Palette.nightDot)
                    .frame(width: 7, height: 7)
                    .opacity(pulse ? 0.35 : 1)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                Text("CAMERA ACTIVE")
                    .font(FLFont.sans(12))
                    .tracking(1.4)
                    .foregroundStyle(Palette.nightText)
            }

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
        case .aligning: "Look straight ahead"
        case .circling: "Slowly move your head\nin a circle"
        case .done: "Got it"
        }
    }

    private var subtitle: String {
        switch scan.phase {
        case .aligning: "Keep your face inside the circle"
        case .circling: "Fill the ring all the way around"
        case .done: "Reading your skin…"
        }
    }
}

/// 48 tick marks around the preview; each lights up rose as its part of the circle is covered.
private struct SegmentRing: View {
    let filled: [Bool]
    let diameter: CGFloat

    private let ticks = 48

    var body: some View {
        ZStack {
            ForEach(0..<ticks, id: \.self) { tick in
                let segment = tick * filled.count / ticks
                let isOn = filled.indices.contains(segment) && filled[segment]
                // Tick angle measured clockwise from the right, matching the controller.
                let angle = (Double(tick) + 0.5) / Double(ticks) * 360

                Capsule()
                    .fill(isOn ? Palette.rose : Color.white.opacity(0.2))
                    .frame(width: 4, height: isOn ? 22 : 16)
                    .offset(y: -diameter / 2)
                    .rotationEffect(.degrees(angle + 90))
                    .animation(.easeOut(duration: 0.2), value: isOn)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement()
        .accessibilityLabel("Scan progress")
        .accessibilityValue("\(filled.filter { $0 }.count) of \(filled.count)")
    }
}

/// Live, mirrored front-camera feed from the ARKit session.
private struct ARFacePreview: UIViewRepresentable {
    let controller: FaceScanController

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session = controller.session
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
