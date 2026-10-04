import SwiftUI
import StoreKit

/// Black-and-white profile with the review request.
struct ReviewAskStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @State private var didAsk: Bool = false
    @State private var promptAppeared: Bool = false
    @State private var didAdvance: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Image("onb_review")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height * 0.64)
                        .clipped()
                    Spacer(minLength: 0)
                }
            }
            .background(Color(hex: 0x0B0A0A))
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.38),
                    .init(color: Color(hex: 0x0B0A0A).opacity(0.9), location: 0.6),
                    .init(color: Color(hex: 0x0B0A0A), location: 0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            HStack {
                OnboardingBackButton(tint: .white.opacity(0.85)) { flow.back() }
                    .padding(.leading, 10)
                Spacer()
            }
            .frame(height: 44)
            .zIndex(1)

            VStack(spacing: 0) {
                Spacer()

                Text("Be kind and leave a review.")
                    .font(FLFont.serifItalic(33))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                Text("HELP US GROW")
                    .font(FLFont.sans(15))
                    .tracking(3)
                    .foregroundStyle(Color(hex: 0xC8C2BE))
                    .padding(.top, 14)

                GoldStars(size: 22, spacing: 10)
                    .padding(.top, 14)

                // A note from us, not a customer quote: real reviews only, once she and others leave them.
                Text("We're a small team building FACELIFT for women who want better skin, not more makeup. A quick rating helps more women find us.")
                    .font(FLFont.serifItalic(16.5))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 14)
                    .padding(.horizontal, 18)

                Text("THE FACELIFT TEAM")
                    .font(FLFont.sans(12))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0x8F8A87))
                    .padding(.top, 12)

                // Tap shows Apple's rating popup over this screen. Once she rates or taps
                // "Not Now", onboarding moves on by itself. If Apple doesn't show the popup
                // (it limits how often it appears), we move on after a short beat.
                OnboardingCTA(title: "Next") {
                    if didAsk {
                        advance()
                    } else {
                        didAsk = true
                        requestReview()
                        Task {
                            try? await Task.sleep(for: .seconds(2.5))
                            if !promptAppeared { advance() }
                        }
                    }
                }
                .padding(.top, 26)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
        }
        .onChange(of: scenePhase) { _, phase in
            guard didAsk else { return }
            // The rating popup makes the app briefly inactive; coming back means it was answered.
            if phase == .inactive { promptAppeared = true }
            if phase == .active && promptAppeared { advance() }
        }
    }

    private func advance() {
        guard !didAdvance else { return }
        didAdvance = true
        flow.next()
    }
}
