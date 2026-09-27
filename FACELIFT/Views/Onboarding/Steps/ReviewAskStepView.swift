import SwiftUI
import StoreKit

/// Black-and-white profile with the review request.
struct ReviewAskStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(\.requestReview) private var requestReview

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
                    .padding(.top, 20)

                GoldStars(size: 26, spacing: 12)
                    .padding(.top, 18)

                Text("\"I finally understand my skin. The recommendations actually worked and my texture improved in two weeks.\"")
                    .font(FLFont.serifItalic(17.5))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.top, 22)
                    .padding(.horizontal, 10)

                Text("— SOFIA M., 34")
                    .font(FLFont.sans(12.5))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0x8F8A87))
                    .padding(.top, 24)

                OnboardingCTA(title: "Next") {
                    requestReview()
                    flow.next()
                }
                .padding(.top, 34)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
        }
    }
}
