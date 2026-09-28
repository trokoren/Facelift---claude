import SwiftUI

/// Dark scan: live camera inside the rose oval, then a four-step checklist and progress bar.
struct ScanLoadingStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(AppStore.self) private var store
    @State private var didCapture: Bool = false
    @State private var camera = CameraService()
    @State private var progress: Double = 0
    @State private var sweepDown: Bool = false
    @State private var pulse: Bool = false
    @State private var completedSteps: Int = 0
    @State private var didFinish: Bool = false

    private let ovalSize = CGSize(width: 250, height: 324)
    private let stages: [String] = ["Reading your skin", "Scanning 14+ categories", "Scoring categories", "Building your report"]
    private let stageDuration: Double = 1.6

    var body: some View {
        if FaceScanController.isSupported && !didCapture {
            CircleScanView(onComplete: { images in
                store.lastCaptures = images
                withAnimation(.easeInOut(duration: 0.3)) { didCapture = true }
            }, onCancel: { flow.back() })
            .transition(.opacity)
        } else {
            analyzingView
        }
    }

    /// Checklist + progress while the scan is analyzed.
    private var analyzingView: some View {
        ZStack(alignment: .top) {
            Palette.night.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 9) {
                    Circle()
                        .fill(Palette.nightDot)
                        .frame(width: 8, height: 8)
                        .opacity(pulse ? 0.35 : 1)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                    Text("CAMERA ACTIVE")
                        .font(FLFont.sans(15))
                        .tracking(1.6)
                        .foregroundStyle(Color(hex: 0xA79D99))
                }
                .padding(.top, 6)

                PrivacyNote(tint: Color(hex: 0xB3ABA9))
                    .padding(.top, 14)

                oval
                    .padding(.top, 48)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        HStack(spacing: 18) {
                            if index < completedSteps {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(Color(hex: 0x7C6564))
                                    .frame(width: 22)
                            } else {
                                Circle()
                                    .fill(index == completedSteps ? Palette.rose : Color.clear)
                                    .frame(width: 9, height: 9)
                                    .frame(width: 22)
                            }
                            Text(stage)
                                .font(FLFont.sans(18.5))
                                .foregroundStyle(index == completedSteps ? .white : Color(hex: 0x6E6866))
                        }
                        .animation(.easeOut(duration: 0.25), value: completedSteps)
                    }
                }
                .padding(.top, 38)

                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.nightTrack)
                    Capsule()
                        .fill(Palette.rose)
                        .frame(width: 140 * progress)
                }
                .frame(width: 140, height: 3)
                .padding(.top, 34)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.success, trigger: didFinish)
        .onAppear { pulse = true }
        .task {
            await camera.start()
            await runScan()
        }
        .onDisappear { camera.stop() }
    }

    private var oval: some View {
        ZStack {
            if camera.status == .running {
                CameraPreviewView(session: camera.session)
                    .frame(width: ovalSize.width, height: ovalSize.height)
                    .clipShape(Ellipse())
                    .opacity(0.9)
                    .transition(.opacity)
            }
            Ellipse()
                .stroke(Palette.rose, lineWidth: 1.6)
                .frame(width: ovalSize.width, height: ovalSize.height)
            LinearGradient(
                colors: [Palette.rose.opacity(0), Palette.rose.opacity(0.75), Palette.rose.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: ovalSize.width - 8, height: 0.8)
            .offset(y: sweepDown ? ovalSize.height * 0.36 : -ovalSize.height * 0.36)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: sweepDown)
        }
        .frame(width: ovalSize.width, height: ovalSize.height)
        .animation(.easeOut(duration: 0.6), value: camera.status)
    }

    private func runScan() async {
        sweepDown = true
        let total = Double(stages.count) * stageDuration
        let ticks = 80
        for tick in 1...ticks {
            try? await Task.sleep(for: .seconds(total / Double(ticks)))
            if Task.isCancelled { return }
            let fraction = Double(tick) / Double(ticks)
            withAnimation(.linear(duration: total / Double(ticks))) {
                progress = fraction
            }
            let stage = min(stages.count - 1, Int(fraction * Double(stages.count)))
            if stage != completedSteps && stage < stages.count {
                completedSteps = stage
            }
        }
        completedSteps = stages.count
        didFinish = true
        try? await Task.sleep(for: .milliseconds(500))
        if Task.isCancelled { return }
        camera.stop()
        flow.next()
    }
}
