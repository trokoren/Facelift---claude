import SwiftUI

/// Golden portrait with "You're not alone." and the 14,000+ social proof.
struct NotAloneStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var count: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Image("onb_not_alone")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height * 0.66)
                        .clipped()
                    Spacer(minLength: 0)
                }
            }
            .background(Color(hex: 0x1A1210))
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.35),
                    .init(color: Color(hex: 0x1A1210).opacity(0.85), location: 0.62),
                    .init(color: Color(hex: 0x1A1210), location: 0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    OnboardingBackButton(tint: .white.opacity(0.8)) { flow.back() }
                        .padding(.leading, 10)
                    Spacer()
                }
                .frame(height: 44)

                Spacer()

                Text("You're not alone.")
                    .font(FLFont.serif(40))
                    .foregroundStyle(.white)

                GoldStars(size: 26, spacing: 12)
                    .padding(.top, 20)

                Text("\(count.formatted())+")
                    .font(FLFont.serif(44))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .padding(.top, 24)
                Text("WOMEN SCANNED")
                    .font(FLFont.sans(14))
                    .tracking(2.2)
                    .foregroundStyle(Color(hex: 0xC8C2BE))
                    .padding(.top, 2)

                OnboardingCTA(title: "Continue") { flow.next() }
                    .padding(.top, 26)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
        }
        .task {
            for step in 1...20 {
                try? await Task.sleep(for: .milliseconds(45))
                if Task.isCancelled { return }
                withAnimation(.easeOut(duration: 0.1)) {
                    count = Int(Double(14_000) * Double(step) / 20)
                }
            }
        }
    }
}
