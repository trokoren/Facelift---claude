import SwiftUI

/// First screen: "Your skin, finally understood." The headline and button fade in over the photo.
struct HeroStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(AppStore.self) private var store
    @State private var hasAppeared: Bool = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("woman_portrait_clean")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .background(Color(hex: 0x2A1A14))
            .ignoresSafeArea()
            .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.5),
                    .init(color: Color(hex: 0x1E100B).opacity(0.55), location: 0.8),
                    .init(color: Color(hex: 0x1E100B).opacity(0.8), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: -4) {
                    Text("Your skin,")
                        .font(FLFont.serif(38))
                    Text("finally understood.")
                        .font(FLFont.serifItalic(39))
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 14)

                OnboardingCTA(title: "Next") { flow.next() }
                    .padding(.top, 26)
                    .padding(.bottom, 52)
                    .opacity(hasAppeared ? 1 : 0)
            }
            .padding(.horizontal, 28)
        }
        .task {
            // Let the photo land for a beat, then bring in the words.
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeOut(duration: 0.9)) { hasAppeared = true }
        }
    }
}
