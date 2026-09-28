import SwiftUI

/// Category score card: frosted glass with a soft blush sheen, rose accents and animated bars.
struct AnalysisCardView: View {
    let category: AnalysisCategory
    let onLearnMore: () -> Void

    @State private var isRevealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(category.title.uppercased())
                    .font(FLFont.sans(11, .semibold))
                    .tracking(2.3)
                    .foregroundStyle(category.accent)
                Spacer(minLength: 8)
                CategoryIcon(kind: category.kind, tint: category.iconTint)
                    .padding(.top, -8)
            }

            HStack(alignment: .top) {
                HStack(alignment: .bottom, spacing: 9) {
                    Text("\(category.score)")
                        .font(FLFont.serif(54))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("/ 100")
                            .font(FLFont.sans(9.5, .light))
                            .tracking(1)
                            .foregroundStyle(Palette.faint)
                        Text(category.rating)
                            .font(FLFont.serifItalic(15))
                            .foregroundStyle(category.accent)
                    }
                    .padding(.bottom, 9)
                }
                Spacer(minLength: 8)
                Button(action: onLearnMore) {
                    HStack(spacing: 4) {
                        Text("Learn more")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .regular))
                    }
                    .font(FLFont.sans(11.4))
                    .foregroundStyle(category.accent)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 8)
            }
            .padding(.top, 14)

            Rectangle()
                .fill(Palette.rowDivider)
                .frame(height: 1)
                .padding(.top, 10)
                .padding(.trailing, 2)

            VStack(spacing: 15) {
                ForEach(category.metrics) { metric in
                    MetricRow(metric: metric, tint: category.tint(for: metric), isRevealed: isRevealed)
                }
            }
            .padding(.top, 16)
        }
        .padding(.leading, 22)
        .padding(.trailing, 16)
        .padding(.top, 17)
        .padding(.bottom, 15)
        .background(GlassCardBackground(accent: category.accent))
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
                isRevealed = true
            }
        }
    }
}

private struct MetricRow: View {
    let metric: AnalysisCategory.Metric
    let tint: Color
    let isRevealed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(metric.name)
                    .font(FLFont.sans(13, .medium))
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                Text("\(metric.score)")
                    .font(FLFont.sans(12.5, .semibold))
                    .foregroundStyle(tint)
            }
            Text(metric.detail)
                .font(FLFont.sans(10.9))
                .foregroundStyle(Palette.pebble)
                .padding(.top, 3)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.track)
                    Capsule()
                        .fill(tint)
                        .frame(width: geo.size.width * (isRevealed ? CGFloat(metric.score) / 100 : 0))
                }
            }
            .frame(height: 3)
            .padding(.top, 7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.name), \(metric.score) out of 100")
    }
}
