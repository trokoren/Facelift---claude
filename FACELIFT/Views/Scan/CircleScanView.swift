import SwiftUI
import ARKit
import SceneKit

/// Full-screen guided scan inside a tall oval window.
/// 1. She lines her face up with an outline.
/// 2. A scan line sweeps down and back up her face, lighting the constellation stars.
/// 3. The ticks light up and she slowly circles her head to fill the ring.
/// A light-level chip, help sheet and one-time privacy consent sit around it.
struct CircleScanView: View {
    let onComplete: ([UIImage]) -> Void
    let onCancel: () -> Void

    @State private var scan = FaceScanController()
    @State private var showsQuickOption: Bool = false
    @State private var flash: Double = 0
    @State private var finishSweep: CGFloat = 0
    @State private var finishGlow: Bool = false
    @State private var cameraOpacity: Double = 1
    @State private var showsHelp: Bool = false
    @State private var needsConsent: Bool = !ScanPrivacySheet.hasAgreed

    var body: some View {
        ZStack {
            Palette.night.ignoresSafeArea()

            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let ovalWidth = FaceScanController.ovalWidth(for: width)
                let ovalHeight = ovalWidth * FaceScanController.ovalAspect
                let center = CGPoint(x: width / 2, y: height / 2 - 20)
                let ringSize = CGSize(width: ovalWidth + 46, height: ovalHeight + 46)

                ZStack {
                    // Native 3:4 camera (no extra zoom), centered on the oval, edges faded.
                    ARFacePreview(
                        controller: scan,
                        isMeshVisible: scan.phase == .mapping || scan.phase == .circling,
                        sweep: scan.phase == .mapping ? scan.sweepProgress : nil
                    )
                    .frame(width: width, height: width * 4 / 3)
                    .opacity(cameraOpacity)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.16),
                                .init(color: .black, location: 0.84),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .position(center)

                    // Dark tint everywhere except the oval window.
                    Rectangle()
                        .fill(Palette.night.opacity(0.72))
                        .mask {
                            ZStack {
                                Rectangle()
                                Ellipse()
                                    .frame(width: ovalWidth, height: ovalHeight)
                                    .position(center)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                        }
                        .allowsHitTesting(false)

                    Ellipse()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .frame(width: ovalWidth, height: ovalHeight)
                        .position(center)

                    // Shutter: a soft white flash each time a photo is taken.
                    Ellipse()
                        .fill(Color.white)
                        .frame(width: ovalWidth, height: ovalHeight)
                        .opacity(flash)
                        .position(center)
                        .allowsHitTesting(false)

                    // Finish: a sparkle wave runs around the diamonds, then the ring glows once.
                    OvalTickRing(filled: scan.filled, size: ringSize, isLive: scan.phase == .circling || scan.phase == .done, celebrate: finishSweep > 0)
                        .shadow(color: Palette.rose.opacity(finishGlow ? 0.8 : 0), radius: finishGlow ? 18 : 0)
                        .position(center)

                    // Dot that follows her nose around the ring once the circle starts.
                    if scan.phase == .circling {
                        Circle()
                            .fill(Palette.rose)
                            .frame(width: 12, height: 12)
                            .shadow(color: Palette.rose.opacity(0.9), radius: 8)
                            .position(
                                x: center.x + scan.pointer.x * ringSize.width / 2,
                                y: center.y + scan.pointer.y * ringSize.height / 2
                            )
                            .animation(.linear(duration: 0.08), value: scan.pointer)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }

                    if scan.phase == .aligning {
                        FaceOutline(diameter: ovalWidth, alignment: scan.alignment)
                            .position(center)
                            .allowsHitTesting(false)
                            .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    }

                    // Instructions just under the ring.
                    VStack(spacing: 0) {
                        instructions
                        if showsQuickOption && scan.phase == .circling {
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
                            .transition(.opacity)
                        }
                    }
                    .frame(width: width - 64)
                    .fixedSize(horizontal: false, vertical: true)
                    .position(x: center.x, y: center.y + ringSize.height / 2 + 70)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                PrivacyNote(tint: Color(hex: 0xD9D1CF))
                    .padding(.top, 6)
                #if DEBUG
                if scan.phase == .aligning && !scan.debugStatus.isEmpty {
                    Text(scan.debugStatus)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                        .padding(.top, 6)
                }
                #endif
                Spacer()
            }

            if needsConsent {
                ScanPrivacySheet(onAgree: {
                    ScanPrivacySheet.hasAgreed = true
                    withAnimation(.easeOut(duration: 0.3)) { needsConsent = false }
                    scan.start()
                }, onDecline: onCancel)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showsHelp) {
            ScanHelpSheet()
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
        }
        .animation(.easeOut(duration: 0.25), value: scan.phase)
        .animation(.easeOut(duration: 0.25), value: scan.hint)
        .animation(.easeOut(duration: 0.25), value: scan.lightLevel)
        .sensoryFeedback(.selection, trigger: scan.filledCount)
        .sensoryFeedback(.impact(weight: .light), trigger: scan.captures.isEmpty)
        .sensoryFeedback(.success, trigger: finishGlow)
        .onChange(of: scan.captures.isEmpty) { _, isEmpty in
            // One soft flash when the straight-on photo is taken.
            guard !isEmpty else { return }
            flash = 0.35
            withAnimation(.easeOut(duration: 0.4)) { flash = 0 }
        }
        .onAppear {
            scan.onFinish = { images in
                Task { @MainActor in
                    await playFinish()
                    onComplete(images)
                }
            }
            if !needsConsent { scan.start() }
        }
        .onDisappear { scan.stop() }
        .onChange(of: scan.phase) { _, phase in
            guard phase == .circling else { return }
            Task {
                try? await Task.sleep(for: .seconds(25))
                withAnimation { showsQuickOption = true }
            }
        }
    }

    /// Camera fades to dark (no frozen last frame), ring closes with a rose sweep and glows.
    private func playFinish() async {
        withAnimation(.easeOut(duration: 0.3)) { cameraOpacity = 0 }
        try? await Task.sleep(for: .milliseconds(250))
        scan.stop()
        finishSweep = 1   // starts the sparkle wave (about 0.65 s around the ring)
        try? await Task.sleep(for: .milliseconds(660))
        withAnimation(.easeOut(duration: 0.3)) { finishGlow = true }
        try? await Task.sleep(for: .milliseconds(300))
    }

    /// Close on the left, light level in the middle, help on the right.
    private var header: some View {
        HStack {
            circleButton(systemName: "xmark", label: "Cancel scan", action: onCancel)
            Spacer()
            LightChip(level: scan.lightLevel)
            Spacer()
            circleButton(systemName: "questionmark", label: "How to scan") { showsHelp = true }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }

    private func circleButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .accessibilityLabel(label)
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
            .opacity(scan.phase == .circling ? 1 : 0)
        }
    }

    private var title: String {
        switch scan.phase {
        case .aligning: scan.lightLevel == .dark ? "Find brighter light\nto begin" : "Line your face up\nwith the outline"
        case .mapping: "Mapping your face"
        case .circling: "Gently circle\nyour head"
        case .done: "Scan complete"
        }
    }

    private var subtitle: String {
        switch scan.phase {
        case .aligning: "Eyes on the marks, then hold still"
        case .mapping: "Hold still"
        case .circling: "Fill the ring all the way around"
        case .done: " "
        }
    }
}

/// Live light check from the camera: "Good light", "A bit dim" or "Too dark".
private struct LightChip: View {
    let level: FaceScanController.LightLevel

    private var icon: String {
        switch level {
        case .good: "sun.max.fill"
        case .dim: "sun.min"
        case .dark: "moon"
        }
    }

    private var text: String {
        switch level {
        case .good: "Good light"
        case .dim: "A bit dim"
        case .dark: "Too dark"
        }
    }

    private var tint: Color {
        level == .good ? Color.white.opacity(0.9) : Palette.rose
    }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .contentTransition(.symbolEffect(.replace))
            Text(text)
                .font(FLFont.sans(13.5, .medium))
                .contentTransition(.opacity)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 16)
        .frame(height: 38)
        .background(level == .good ? Color.clear : Palette.rose.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(level == .good ? Color.white.opacity(0.22) : Palette.rose.opacity(0.7), lineWidth: 1))
        .animation(.easeOut(duration: 0.3), value: level)
        .accessibilityElement(children: .combine)
    }
}

/// 48 small diamonds around the oval. They light rose where her nose has been.
private struct OvalTickRing: View {
    let filled: [Bool]
    let size: CGSize
    /// Dim while she lines up; switching on lights the ticks up in a quick sweep.
    var isLive: Bool = true
    /// At the finish: each diamond brightens and pops in turn, all the way around.
    var celebrate: Bool = false

    private let ticks = 48

    var body: some View {
        ZStack {
            ForEach(0..<ticks, id: \.self) { tick in
                let segment = tick * filled.count / ticks
                let isOn = filled.indices.contains(segment) && filled[segment]
                // Angle measured clockwise from the right, matching the controller.
                let theta = (Double(tick) + 0.5) / Double(ticks) * 2 * .pi
                let a = Double(size.width / 2)
                let b = Double(size.height / 2)
                let normal = atan2(sin(theta) / b, cos(theta) / a)

                Diamond()
                    .fill(celebrate ? Color(hex: 0xF6D9D6) : (isOn ? Palette.rose : Color.white.opacity(isLive ? 0.32 : 0.08)))
                    .frame(width: 9, height: 13)
                    .scaleEffect(celebrate ? 1.35 : (isOn ? 1 : (isLive ? 0.75 : 0.5)), anchor: .center)
                    .shadow(color: Palette.rose.opacity(isOn || celebrate ? 0.9 : 0), radius: celebrate ? 9 : (isOn ? 6 : 0))
                    .rotationEffect(.radians(normal + .pi / 2))
                    .offset(x: CGFloat(a * cos(theta)), y: CGFloat(b * sin(theta)))
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isOn)
                    .animation(.easeOut(duration: 0.35).delay(Double(tick) * 0.022), value: isLive)
                    // Around the ring in about 0.65 s: 20% slower than the original sweep (0.55 s).
                    .animation(.easeOut(duration: 0.22).delay(Double(tick) * 0.0092), value: celebrate)
            }
        }
        .frame(width: size.width, height: size.height)
        .accessibilityElement()
        .accessibilityLabel("Scan progress")
        .accessibilityValue("\(filled.filter { $0 }.count) of \(filled.count)")
    }
}

/// A slim diamond, longer than it is wide.
private struct Diamond: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

/// Quick tips, opened from the "?" button.
private struct ScanHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let tips: [(String, String, String)] = [
        ("sun.max", "Face soft, even light", "A window in front of you is perfect. Avoid light from behind."),
        ("eyeglasses", "Glasses off, hair back", "Bare skin gives the most accurate read."),
        ("iphone", "Arm's length, eye level", "Hold your phone straight in front of your face."),
        ("arrow.triangle.2.circlepath", "Move slowly", "Keep your face in the oval as you circle.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("How to get a great scan")
                    .font(FLFont.serif(28))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Palette.stone)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .padding(.trailing, -12)
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(tips, id: \.1) { icon, title, detail in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Palette.rose)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(FLFont.sans(16, .medium))
                                .foregroundStyle(Palette.ink)
                            Text(detail)
                                .font(FLFont.sans(14))
                                .foregroundStyle(Palette.stone)
                        }
                    }
                }
            }
            .padding(.top, 18)

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(Palette.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

/// One-time consent before the first scan: what we scan, where the photo goes, and an
/// explicit checkbox (face scans and health answers both need clear, recorded consent).
struct ScanPrivacySheet: View {
    let onAgree: () -> Void
    let onDecline: () -> Void

    /// Bump the version when the consent wording changes, so everyone agrees to the new text.
    private static let key = "facelift.scanConsent.v2"
    private static let dateKey = "facelift.scanConsent.v2.date"
    static var hasAgreed: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            if newValue { UserDefaults.standard.set(Date(), forKey: dateKey) }
        }
    }

    @State private var isChecked: Bool = false
    @State private var openLink: URL?

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Palette.rose)
                    .frame(width: 52, height: 52)
                    .background(Palette.blush, in: Circle())

                Text("Private by design")
                    .font(FLFont.serif(30))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 14)

                Text("To read your skin, we map your face to guide the scan and analyze one photo. It's sent securely to our skin-analysis partners to create your consultation. We never store your photo and never sell it.")
                    .font(FLFont.sans(15))
                    .foregroundStyle(Palette.body)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 10)

                // The whole row toggles the box. Policy links sit on their own line below,
                // outside the button, so tapping them opens the policy instead of toggling.
                Button {
                    isChecked.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(isChecked ? Palette.rose : Palette.stone)
                        Text("I agree to FACELIFT scanning my face and using my photo and my answers, including any health details I share, to create my skin consultation.")
                            .font(FLFont.sans(13))
                            .foregroundStyle(Palette.body)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(Palette.blush.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
                .sensoryFeedback(.selection, trigger: isChecked)
                .accessibilityAddTraits(isChecked ? .isSelected : [])

                Text("See our [Privacy Policy](https://faceliftai.app/privacy), [Consumer Health Data Privacy Policy](https://faceliftai.app/health-privacy) and [Terms](https://faceliftai.app/terms).")
                    .multilineTextAlignment(.center)
                    .font(FLFont.sans(12))
                    .foregroundStyle(Palette.stone)
                    .tint(Palette.rose)
                    .padding(.top, 10)

                OnboardingCTA(title: "Start my scan", isEnabled: isChecked) { onAgree() }
                    .padding(.top, 18)

                Button(action: onDecline) {
                    Text("Not now")
                        .font(FLFont.sans(15))
                        .foregroundStyle(Palette.stone)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 12)
            .background(Palette.canvas, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(.horizontal, 8)
        }
        .background(Color.black.opacity(0.35).ignoresSafeArea())
        .preferredColorScheme(.light)
        // Policy links open inside the app instead of jumping to Safari.
        .environment(\.openURL, OpenURLAction { url in
            openLink = url
            return .handled
        })
        .sheet(item: $openLink) { url in
            SafariSheet(url: url)
                .ignoresSafeArea()
        }
    }
}

/// Live, mirrored front-camera feed from the ARKit session, with the constellation and the
/// contour scan line drawn on her face.
private struct ARFacePreview: UIViewRepresentable {
    let controller: FaceScanController
    /// Hidden while she lines up; appears for the scan line and the circle.
    let isMeshVisible: Bool
    /// 0...1 through the scan-line sweep, or nil when it isn't running.
    let sweep: Double?

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
        context.coordinator.sweep = sweep
    }
}

/// Dotted face oval with two eye marks. Its geometry matches what the scan controller checks.
private struct FaceOutline: View {
    let diameter: CGFloat
    /// 0...1 from the controller.
    let alignment: Double

    var body: some View {
        // Scales with the eye spacing, so a closer target draws a bigger face outline.
        let ovalWidth = diameter * 0.56 * (FaceScanController.eyeSpacing / 0.24)
        let ovalHeight = diameter * 0.76 * (FaceScanController.eyeSpacing / 0.24)
        let eyeY = FaceScanController.eyeOffsetY * diameter
        let eyeX = FaceScanController.eyeSpacing * diameter / 2
        let isMatched = alignment >= 1
        let color = isMatched ? Palette.rose : Color.white.opacity(0.35 + 0.45 * alignment)

        ZStack {
            Ellipse()
                .stroke(color, style: StrokeStyle(lineWidth: isMatched ? 2.5 : 1.5, lineCap: .round, dash: isMatched ? [] : [2, 7]))
                .frame(width: ovalWidth, height: ovalHeight)
                .offset(y: diameter * 0.05 * (FaceScanController.eyeSpacing / 0.24))
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

/// A constellation on her face: glowing stars on real features (brows, eye corners, nose,
/// cheekbones, lips, jaw, chin, forehead) joined by fine rose lines, moving live with her.
/// Landmarks are found once on ARKit's face mesh, then follow it every frame.
/// During mapping, a glowing line wraps the face's contours as it sweeps down and back up,
/// and each star lights up as the line passes it.
/// ARKit calls the renderer methods on SceneKit's render thread.
final class FaceMeshRenderer: NSObject, ARSCNViewDelegate {
    nonisolated(unsafe) private var container: SCNNode?
    nonisolated(unsafe) private var stars: [SCNNode] = []
    nonisolated(unsafe) private var linesNode: SCNNode?
    nonisolated(unsafe) private var landmarks: [Int] = []
    nonisolated(unsafe) private var wantsVisible = false
    nonisolated(unsafe) private var scanLineNode: SCNNode?
    nonisolated(unsafe) private var scanGeometry: ARSCNFaceGeometry?
    nonisolated(unsafe) private var litStars: Set<Int> = []
    /// 0...1 through the sweep while mapping; nil otherwise. Set from the main thread.
    nonisolated(unsafe) var sweep: Double?

    /// Draws only a thin glowing band of the face mesh at height `sweepY` (camera space),
    /// so the line follows the face's real contours, bending over the nose and cheeks.
    private static let scanLineShader = """
    #pragma arguments
    float sweepY;
    #pragma transparent
    #pragma body
    float d = abs(_surface.position.y - sweepY);
    float core = 1.0 - smoothstep(0.0006, 0.0018, d);
    float glow = (1.0 - smoothstep(0.0, 0.012, d)) * 0.35;
    float a = clamp(core + glow, 0.0, 1.0);
    _output.color = float4(float3(1.0, 0.86, 0.86) * a, a);
    """

    /// Star pairs joined by lines (indexes into the landmark list built below).
    private static let links: [(Int, Int)] = [
        // Brows (outer, middle, inner) on each side, meeting at the bridge.
        (0, 1), (1, 2), (2, 12), (3, 4), (4, 5), (5, 12),
        // Eyes: inner corner to outer corner, and down to the under-eye.
        (6, 7), (8, 9), (7, 10), (9, 11),
        // Forehead: top, across the upper forehead, down the middle to the inner brows.
        (20, 27), (27, 2), (27, 5), (20, 28), (20, 29), (28, 30), (29, 31), (30, 0), (31, 3),
        // Bridge down the nose to the lips and chin.
        (12, 13), (13, 16), (16, 17),
        // Face outline: outer brow, temple, by the ear, jaw corner, jaw, chin.
        (0, 21), (21, 23), (23, 25), (25, 18), (18, 17),
        (3, 22), (22, 24), (24, 26), (26, 19), (19, 17),
        // Cheekbones: under-eye to cheekbone, out to the ear, down to the jaw corner.
        (10, 14), (14, 23), (14, 25), (11, 15), (15, 24), (15, 26),
        // Nose tip to cheekbones.
        (13, 14), (13, 15),
        // Outer cheeks and the apples of the cheeks.
        (14, 32), (32, 25), (14, 34), (34, 18), (15, 33), (33, 26), (15, 35), (35, 19)
    ]

    private static let lineColor = UIColor(white: 1, alpha: 0.55)
    nonisolated(unsafe) private var strands: [SCNNode] = []

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
            star.opacity = 0.18
            star.scale = SCNVector3(0.7, 0.7, 0.7)
            node.addChildNode(star)
            return star
        }

        let lines = SCNNode()
        lines.renderingOrder = 5
        node.addChildNode(lines)
        linesNode = lines

        // Fine white strands between stars. Real geometry, because GPU "lines" draw one
        // pixel wide and all but vanish on a Retina screen.
        let strandMaterial = SCNMaterial()
        strandMaterial.lightingModel = .constant
        strandMaterial.diffuse.contents = Self.lineColor
        strandMaterial.writesToDepthBuffer = false
        strandMaterial.readsFromDepthBuffer = false
        strands = Self.links.map { _ in
            let cylinder = SCNCylinder(radius: 0.00032, height: 1)
            cylinder.radialSegmentCount = 6
            cylinder.firstMaterial = strandMaterial
            let strand = SCNNode(geometry: cylinder)
            strand.renderingOrder = 6
            strand.opacity = 0
            lines.addChildNode(strand)
            return strand
        }

        if let device = renderer.device, let mesh = ARSCNFaceGeometry(device: device) {
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.shaderModifiers = [.fragment: Self.scanLineShader]
            material.setValue(NSNumber(value: 10), forKey: "sweepY")
            material.writesToDepthBuffer = false
            material.isDoubleSided = false
            mesh.firstMaterial = material
            let scanNode = SCNNode(geometry: mesh)
            scanNode.renderingOrder = 8
            scanNode.isHidden = true
            node.addChildNode(scanNode)
            scanGeometry = mesh
            scanLineNode = scanNode
        }

        node.opacity = wantsVisible ? 1 : 0
        node.scale = wantsVisible ? SCNVector3(1, 1, 1) : SCNVector3(1.04, 1.04, 1.04)
        container = node
        update(face, renderer: renderer, node: node)
        return node
    }

    nonisolated func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let face = anchor as? ARFaceAnchor else { return }
        update(face, renderer: renderer, node: node)
    }

    /// Moves every star to its landmark and redraws the lines between them.
    nonisolated private func update(_ face: ARFaceAnchor, renderer: any SCNSceneRenderer, node: SCNNode) {
        let vertices = face.geometry.vertices
        guard !landmarks.isEmpty, landmarks.allSatisfy({ $0 < vertices.count }) else { return }
        // Lift points a hair off the skin so they never sink into it.
        let points = landmarks.map { vertices[$0] + simd_float3(0, 0, 0.002) }

        for (star, point) in zip(stars, points) {
            star.simdPosition = point
        }

        // Scan line: forehead (landmark 20) down to chin (17) and back up.
        if let progress = sweep, let scanNode = scanLineNode, let mesh = scanGeometry {
            let top = points[20].y + 0.01
            let bottom = points[17].y - 0.01
            let down = progress < 0.5
            let t = Float(down ? progress * 2 : 2 - progress * 2)
            let modelY = top + (bottom - top) * t

            mesh.update(from: face.geometry)
            if let camera = renderer.pointOfView {
                let cameraSpace = node.convertPosition(SCNVector3(0, modelY, 0.03), to: camera)
                mesh.firstMaterial?.setValue(NSNumber(value: cameraSpace.y), forKey: "sweepY")
            }
            scanNode.isHidden = false

            // Stars light up as the line passes them on the way down.
            if down {
                for (index, point) in points.enumerated() where point.y >= modelY && !litStars.contains(index) {
                    litStars.insert(index)
                    light(stars[index])
                }
            }
        } else {
            scanLineNode?.isHidden = true
            if sweep == nil && wantsVisible && litStars.count < stars.count {
                for index in stars.indices where !litStars.contains(index) {
                    litStars.insert(index)
                    light(stars[index])
                }
            }
        }

        // Stretch each strand between its two stars; show it once both have lit up.
        for ((a, b), strand) in zip(Self.links, strands) where a < points.count && b < points.count {
            let start = points[a]
            let end = points[b]
            let length = simd_distance(start, end)
            guard length > 0.0001 else { continue }
            strand.simdPosition = (start + end) / 2
            strand.simdScale = simd_float3(1, length, 1)
            strand.simdOrientation = simd_quatf(from: simd_float3(0, 1, 0), to: simd_normalize(end - start))
            let shouldShow = litStars.contains(a) && litStars.contains(b)
            if shouldShow && strand.opacity == 0 {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.35
                strand.opacity = 1
                SCNTransaction.commit()
            }
        }
    }

    /// Brightens a star with a little pop when the scan line reaches it.
    nonisolated private func light(_ star: SCNNode) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        star.opacity = 1
        star.scale = SCNVector3(1.35, 1.35, 1.35)
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            star.scale = SCNVector3(1, 1, 1)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
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
        let foreheadY = v[forehead].y
        let midForeheadY = (browY + foreheadY) / 2

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
            // 18-19 lower jaw
            nearest(side(1, 1.6), chinY + 0.018), nearest(side(-1, 1.6), chinY + 0.018),
            // 20 top of forehead
            forehead,
            // 21-22 temples
            nearest(side(1, 2.15), browY - 0.002), nearest(side(-1, 2.15), browY - 0.002),
            // 23-24 in front of the ears
            nearest(side(1, 2.35), eyeY - 0.03), nearest(side(-1, 2.35), eyeY - 0.03),
            // 25-26 jaw corners
            nearest(side(1, 2.2), eyeY - 0.068), nearest(side(-1, 2.2), eyeY - 0.068),
            // 27 middle of the forehead
            nearest(0, midForeheadY),
            // 28-29 upper forehead, 30-31 outer forehead
            nearest(side(1, 1.0), foreheadY - 0.01), nearest(side(-1, 1.0), foreheadY - 0.01),
            nearest(side(1, 1.8), midForeheadY - 0.004), nearest(side(-1, 1.8), midForeheadY - 0.004),
            // 32-33 outer cheeks, 34-35 apples of the cheeks
            nearest(side(1, 2.1), eyeY - 0.05), nearest(side(-1, 2.1), eyeY - 0.05),
            nearest(side(1, 1.2), eyeY - 0.052), nearest(side(-1, 1.2), eyeY - 0.052)
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
