import SwiftUI

/// Dark scanning screen: live front camera inside a rose oval, sweeping scan line, progress bar.
struct ScanCameraView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var camera = CameraService()
    @State private var progress: Double = 0
    @State private var sweepDown: Bool = false
    @State private var pulse: Bool = false
    @State private var didFinish: Bool = false

    private let ovalSize = CGSize(width: 209, height: 271)
    private let scanDuration: Double = 5

    var body: some View {
        ZStack(alignment: .top) {
            Palette.night.ignoresSafeArea()

            VStack(spacing: 0) {
                statusLabel
                    .padding(.top, 6)

                oval
                    .padding(.top, 170)

                Group {
                    switch camera.status {
                    case .denied:
                        deniedState
                    case .unavailable:
                        unavailableState
                    case .idle, .running:
                        scanningState
                    }
                }
                .padding(.top, 45)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Palette.nightText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Cancel scan")
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, -6)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: didFinish)
        .task {
            await camera.start()
            guard camera.status == .running else { return }
            await runScan()
        }
        .onDisappear {
            camera.stop()
        }
    }

    private var statusLabel: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(Palette.nightDot)
                .frame(width: 7, height: 7)
                .opacity(pulse ? 0.35 : 1)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            Text(camera.status == .running || camera.status == .idle ? "CAMERA ACTIVE" : "CAMERA OFF")
                .font(FLFont.sans(11.5))
                .tracking(1)
                .foregroundStyle(Palette.nightText)
        }
        .onAppear { pulse = true }
    }

    private var oval: some View {
        ZStack {
            if camera.status == .running {
                CameraPreviewView(session: camera.session)
                    .frame(width: ovalSize.width, height: ovalSize.height)
                    .clipShape(Ellipse())
                    .opacity(0.55)
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
            .offset(y: camera.status == .running ? (sweepDown ? ovalSize.height * 0.36 : -ovalSize.height * 0.36) : 0)
            .animation(
                camera.status == .running ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true) : .default,
                value: sweepDown
            )
        }
        .frame(width: ovalSize.width, height: ovalSize.height)
        .animation(.easeOut(duration: 0.6), value: camera.status)
    }

    private var scanningState: some View {
        VStack(spacing: 0) {
            Text("Hold still while we read your skin.")
                .font(FLFont.sans(14.1, .light))
                .tracking(0.4)
                .foregroundStyle(Palette.nightBody)

            ZStack(alignment: .leading) {
                Capsule().fill(Palette.nightTrack)
                Capsule()
                    .fill(Palette.rose)
                    .frame(width: 120 * progress)
            }
            .frame(width: 120, height: 2)
            .padding(.top, 38)
        }
    }

    private var deniedState: some View {
        VStack(spacing: 18) {
            Text("Camera access is off.\nAllow it to read your skin.")
                .font(FLFont.sans(14, .light))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .foregroundStyle(Palette.nightBody)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text("Open Settings")
                    .font(FLFont.sans(14))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 46)
                    .background(Palette.rose, in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var unavailableState: some View {
        VStack(spacing: 18) {
            Text("No camera found on this device.")
                .font(FLFont.sans(14, .light))
                .foregroundStyle(Palette.nightBody)
            Button {
                close()
            } label: {
                Text("Close")
                    .font(FLFont.sans(14))
                    .foregroundStyle(Palette.rose)
                    .frame(width: 200, height: 46)
                    .overlay(Capsule().stroke(Palette.rose.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(PressableStyle())
        }
    }

    private func runScan() async {
        sweepDown = true
        let steps = 100
        for step in 1...steps {
            try? await Task.sleep(for: .seconds(scanDuration / Double(steps)))
            if Task.isCancelled { return }
            withAnimation(.linear(duration: scanDuration / Double(steps))) {
                progress = Double(step) / Double(steps)
            }
        }
        didFinish = true
        try? await Task.sleep(for: .milliseconds(450))
        if Task.isCancelled { return }
        store.completeScan()
    }

    private func close() {
        camera.stop()
        store.isScanning = false
    }
}
