import SwiftUI

/// Onboarding, right after the scan: a short "got it" moment before the results preview.
/// Nothing is read yet. The photo waits in memory and is read after she subscribes.
struct ScanCompleteView: View {
    let onFinished: () -> Void

    @State private var isShown = false

    var body: some View {
        ZStack {
            Palette.night.ignoresSafeArea()

            RoseStreaks()
                .ignoresSafeArea()
                .opacity(0.55)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                PrivacyNote(tint: Color(hex: 0xD9D1CF))
                    .frame(height: 44)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Palette.rose.opacity(0.35), lineWidth: 1.2)
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Palette.rose)
                        .scaleEffect(isShown ? 1 : 0.6)
                }
                .opacity(isShown ? 1 : 0)

                Text("Scan complete")
                    .font(FLFont.serif(38))
                    .foregroundStyle(.white)
                    .padding(.top, 28)
                Text("Your face map is ready for its 14-marker read.")
                    .font(FLFont.sans(15))
                    .foregroundStyle(Palette.nightBody)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: isShown)
        .task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { isShown = true }
            try? await Task.sleep(for: .seconds(2.2))
            if Task.isCancelled { return }
            onFinished()
        }
    }
}

/// After she subscribes: the real read of her onboarding scan (pink streaks), with a rescan
/// if the photo is gone (app was closed) or couldn't be read.
struct FirstReadView: View {
    let onFinished: () -> Void

    @Environment(AppStore.self) private var store
    @State private var isRescanning = false
    /// Changing this restarts the reading screen after a rescan.
    @State private var attempt = 0

    var body: some View {
        ZStack {
            if isRescanning {
                CircleScanView(onComplete: { images in
                    store.lastCaptures = images
                    attempt += 1
                    withAnimation(.easeInOut(duration: 0.4)) { isRescanning = false }
                }, onCancel: {
                    withAnimation(.easeInOut(duration: 0.4)) { isRescanning = false }
                })
                .transition(.opacity)
            } else {
                SkinAnalyzingView(onFinished: onFinished, onRetry: {
                    withAnimation(.easeInOut(duration: 0.4)) { isRescanning = true }
                })
                .id(attempt)
                .transition(.opacity)
            }
        }
    }
}
