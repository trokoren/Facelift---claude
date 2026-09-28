import SwiftUI

/// Blurred analysis behind a "Your results are waiting." card and the unlock CTA.
struct PaywallPreviewStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var isRevealed: Bool = false

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            // Only the blurred report scrolls, hinting at how much is waiting underneath.
            ScrollView {
                VStack(spacing: 0) {
                    blurredAnalysis
                    blurredAnalysis
                    blurredAnalysis
                }
                .blur(radius: 5)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .accessibilityHidden(true)

            // Static overlay. Cards ignore touches so swipes pass through to the scroll view.
            VStack(spacing: 0) {
                resultsCard
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                    .allowsHitTesting(false)

                Spacer(minLength: 12)

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
            Text("FACELIFT")
                .font(FLFont.sans(13))
                .tracking(3)
                .foregroundStyle(Palette.rose.opacity(0.5))
                .padding(.top, 28)
            VStack(alignment: .leading, spacing: 14) {
                Text("TONE & CLARITY")
                    .font(FLFont.sans(12, .semibold))
                    .tracking(2.6)
                    .foregroundStyle(Palette.rose)
                HStack(alignment: .bottom, spacing: 12) {
                    Text("81")
                        .font(FLFont.serif(64))
                        .foregroundStyle(Palette.body)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("/ 100")
                            .font(FLFont.sans(11))
                            .foregroundStyle(Palette.faint)
                        Text("Very Good")
                            .font(FLFont.serifItalic(18))
                            .foregroundStyle(Palette.rose)
                    }
                    .padding(.bottom, 12)
                }
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule().fill(Palette.rose.opacity(0.35)).frame(width: 240, height: 12)
                        Capsule().fill(Palette.rose.opacity(0.25)).frame(height: 5)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AccentEdgeBackground(accent: Palette.rose, radius: 24))
            .padding(.top, 20)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .frame(height: 260)
                .padding(.top, 14)
        }
        .padding(.horizontal, 24)
    }
}
