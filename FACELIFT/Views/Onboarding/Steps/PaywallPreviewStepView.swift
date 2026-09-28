import SwiftUI

/// Blurred analysis behind a "Your results are waiting." card and the unlock CTA.
struct PaywallPreviewStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(AppStore.self) private var store
    @State private var isRevealed: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Palette.canvas.ignoresSafeArea()

            // The real results layout (same cards as the analysis screen), blurred.
            // Only this layer scrolls, hinting at how much is waiting underneath.
            ScrollView {
                blurredAnalysis
                    .disabled(true)
                    .blur(radius: 6)
                    .padding(.bottom, 160)
            }
            .scrollIndicators(.hidden)
            .accessibilityHidden(true)

            // Original static overlay. Cards ignore touches so swipes reach the scroll view.
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text("scroll")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .font(FLFont.sans(13))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(Color(hex: 0x6E6866).opacity(0.85), in: Capsule())
                .padding(.top, 40)
                .allowsHitTesting(false)

                resultsCard
                    .padding(.top, 18)
                    .padding(.horizontal, 24)
                    .allowsHitTesting(false)

                Spacer()

                testimonial
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .allowsHitTesting(false)

                OnboardingCTA(title: "Unlock My Results") { flow.next() }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) { isRevealed = true }
        }
    }

    private var resultsCard: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().stroke(Palette.roseLine, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: isRevealed ? 0.71 : 0)
                    .stroke(Palette.rose, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("71")
                        .font(FLFont.serif(42))
                        .foregroundStyle(Palette.ink)
                    Text("OUT OF 100")
                        .font(FLFont.sans(10))
                        .tracking(2)
                        .foregroundStyle(Palette.stone)
                }
            }
            .frame(width: 156, height: 156)
            .padding(.top, 26)

            HStack(spacing: 8) {
                previewChip("Hydration")
                previewChip("Fine Lines")
                previewChip("Barrier")
                Text("+ 11 more")
                    .font(FLFont.sans(13.5))
                    .foregroundStyle(Palette.rose)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .overlay(Capsule().stroke(Palette.roseLine, lineWidth: 1))
            }
            .padding(.top, 30)

            Text("Your results are waiting.")
                .font(FLFont.serif(32))
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
                .padding(.top, 20)
            Text("14 scores · 3 breakdowns · 9 recommendations.")
                .font(FLFont.sans(14.5))
                .foregroundStyle(Palette.body)
                .padding(.top, 8)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color(hex: 0xFBE9E7), Color(hex: 0xFBF6F4)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: Palette.ink.opacity(0.06), radius: 24, x: 0, y: 10)
    }

    private func previewChip(_ text: String) -> some View {
        Text(text)
            .font(FLFont.sans(13.5))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(Palette.roseLine, lineWidth: 1))
    }

    private var testimonial: some View {
        VStack(spacing: 8) {
            GoldStars(size: 17, spacing: 5, color: Color(hex: 0xE9B34E))
            Text("\"This actually worked for me.\"")
                .font(FLFont.serifItalic(22))
                .foregroundStyle(Palette.ink)
            Text("- Jamie L., verified user")
                .font(FLFont.sans(13.5))
                .foregroundStyle(Palette.stone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Palette.sage)
                .frame(width: 8)
                .mask(RoundedRectangle(cornerRadius: 26, style: .continuous).frame(width: 26).offset(x: -9))
        }
        .shadow(color: Palette.ink.opacity(0.05), radius: 18, x: 0, y: 6)
    }

    private var blurredAnalysis: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandHeader(subtitle: "Your Skin Analysis.")

            SectionLabel("YOUR ANALYSIS")
                .padding(.top, 22)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(store.latestReport?.categories ?? SampleData.categories()) { category in
                    AnalysisCardView(category: category) {}
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 26) {
                ForEach(SampleData.recommendations) { recommendation in
                    RecommendationSectionView(recommendation: recommendation) { _ in }
                }
            }
            .padding(.top, 32)
        }
    }
}
