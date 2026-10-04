import SwiftUI

/// "Real results in 28 days." — score chart, before/after and the 93% stat.
struct Results28StepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var isRevealed: Bool = false

    var body: some View {
        OnboardingPage(title: "Real results in 28 days.", subtitle: "93% of women see visible improvement.", titleSize: 33, titleTop: 4) {
            scoreCard
                .padding(.top, 18)

            HStack(spacing: 14) {
                BeforeAfterTile(imageName: "onb_before", dayLabel: "Day 1", caption: "BEFORE", captionColor: Palette.stone)
                BeforeAfterTile(imageName: "onb_after", dayLabel: "Day 28", caption: "AFTER", captionColor: Palette.rose)
            }
            .padding(.top, 16)
        } footer: {
            // The 93% sits right above the button, the last thing she reads before tapping.
            VStack(spacing: 0) {
                Text("93%")
                    .font(FLFont.serif(64))
                    .foregroundStyle(Palette.ink)
                    .frame(height: 62)
                Text("of women see visible results.")
                    .font(FLFont.sans(16))
                    .foregroundStyle(Palette.body)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            OnboardingCTA(title: "Next") { flow.next() }
                .padding(.top, 16)
                .padding(.bottom, 10)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.3).delay(0.2)) { isRevealed = true }
        }
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SKIN SCORE")
                .font(FLFont.sans(11))
                .tracking(2)
                .foregroundStyle(Palette.label)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let pts = wavePoints(width: w, height: h)

                ZStack(alignment: .topLeading) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h))
                        p.addLine(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: w, y: h))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Palette.rose.opacity(0.3), Palette.rose.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    .opacity(isRevealed ? 1 : 0)

                    Path { p in
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .trim(from: 0, to: isRevealed ? 1 : 0)
                    .stroke(Palette.rose, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    Text("59")
                        .font(FLFont.sans(14))
                        .foregroundStyle(Palette.rose)
                        .position(x: 12, y: pts[0].y - 18)

                    Circle()
                        .fill(Palette.rose)
                        .frame(width: 14, height: 14)
                        .position(x: w, y: pts.last?.y ?? 0)
                        .opacity(isRevealed ? 1 : 0)
                    Text("71")
                        .font(FLFont.sans(14))
                        .foregroundStyle(Palette.rose)
                        .position(x: w - 14, y: (pts.last?.y ?? 0) + 20)
                        .opacity(isRevealed ? 1 : 0)
                    Text("+12 pts")
                        .font(FLFont.sans(12, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Palette.rose, in: Capsule())
                        .position(x: w - 50, y: -6)
                        .opacity(isRevealed ? 1 : 0)
                }
            }
            .frame(height: 120)
            .padding(.top, 30)

            HStack {
                Text("Day 1"); Text("Day 7").padding(.leading, 8); Text("Day 14")
                Spacer()
                Text("Day 21")
                Spacer()
                Text("Day 28")
            }
            .font(FLFont.sans(12))
            .foregroundStyle(Palette.stone)
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .cardSurface(radius: 28)
    }

    private func wavePoints(width w: CGFloat, height h: CGFloat) -> [CGPoint] {
        let levels: [CGFloat] = [0.18, 0.22, 0.25, 0.30, 0.42, 0.46, 0.50, 0.56, 0.64, 0.66, 0.70, 0.78, 0.82, 0.86, 0.96, 1.0]
        return levels.enumerated().map { i, level in
            let x = w * CGFloat(i) / CGFloat(levels.count - 1)
            let y = h - h * level * 0.9 - 6
            return CGPoint(x: x, y: y)
        }
    }
}

/// Rounded photo tile with a day badge and a footer caption.
struct BeforeAfterTile: View {
    let imageName: String
    let dayLabel: String
    let caption: String
    let captionColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Color(hex: 0xE9E4E0)
                .aspectRatio(0.95, contentMode: .fit)
                .overlay {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(dayLabel)
                        .font(FLFont.sans(13, .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Color.black.opacity(0.32), in: Capsule())
                        .padding(12)
                }
            Text(caption)
                .font(FLFont.sans(13, .medium))
                .tracking(2)
                .foregroundStyle(captionColor)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color(hex: 0xEDEAE6))
        }
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
    }
}
