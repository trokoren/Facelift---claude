import SwiftUI
import AVFoundation

/// Black screen: "Allow camera access to scan your skin." — Continue triggers the system prompt.
struct CameraPermissionStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.openURL) private var openURL
    @State private var isDenied: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    OnboardingBackButton(tint: .white.opacity(0.85)) { flow.back() }
                        .padding(.leading, 10)
                    Spacer()
                }
                .frame(height: 44)

                Spacer()

                Text(isDenied ? "Camera access is off.\nTurn it on in Settings." : "Allow camera access to\nscan your skin.")
                    .font(FLFont.serif(40))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 24)

                Spacer()

                OnboardingCTA(title: isDenied ? "Open Settings" : "Continue", fill: .white, foreground: Palette.ink) {
                    Task { await continueTapped() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 10)

                if isDenied {
                    Button { flow.next() } label: {
                        Text("Continue without camera")
                            .font(FLFont.sans(14))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(height: 44)
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.bottom, 6)
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: isDenied)
    }

    private func continueTapped() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            flow.next()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                flow.next()
            } else {
                isDenied = true
            }
        default:
            if isDenied, let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            } else {
                isDenied = true
            }
        }
    }
}
