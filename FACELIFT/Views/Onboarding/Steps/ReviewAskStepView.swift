import SwiftUI
import StoreKit

/// Black-and-white profile with the review request.
struct ReviewAskStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.requestReview) private var requestReview
    @State private var showsSkip: Bool = false

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

                // Like GlamUp: "Next" shows Apple's rating popup and she stays here either way
                // (Apple doesn't tell us whether she rated). A quiet "I rated!" link then appears
                // above the button, and that's how she moves on. "Next" asks again if tapped.
                if showsSkip {
                    Button { flow.next() } label: {
                        Text("I rated!")
                            .font(FLFont.sans(15))
                            .underline()
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(minWidth: 120, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 14)
                    .transition(.opacity)
                }

                OnboardingCTA(title: "Next") {
                    requestReview()
                    Task {
                        try? await Task.sleep(for: .seconds(1.2))
                        withAnimation(.easeOut(duration: 0.3)) { showsSkip = true }
                    }
                }
                .padding(.top, showsSkip ? 4 : 26)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
        }
    }
}
