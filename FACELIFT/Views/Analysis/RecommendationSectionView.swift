import SwiftUI

struct RecommendationSectionView: View {
    let recommendation: Recommendation
    let onShop: (Recommendation.Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(recommendation.numeral).")
                        .font(FLFont.serif(21))
                        .foregroundStyle(Palette.rose)
                    Text("ISSUE")
                        .font(FLFont.sans(10.5, .medium))
                        .tracking(1.6)
                        .foregroundStyle(Palette.label)
                    Text(recommendation.issue)
                        .font(FLFont.serif(22))
                        .foregroundStyle(Palette.ink)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("SOLUTION")
                        .font(FLFont.sans(10.5, .medium))
                        .tracking(1.6)
                        .foregroundStyle(Palette.rose)
                    Text(recommendation.solution)
                        .font(FLFont.serifItalic(22))
                        .foregroundStyle(Palette.rose)
                }
                Text(recommendation.summary)
                    .font(FLFont.sans(13))
                    .foregroundStyle(Palette.pebble)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(recommendation.products.enumerated()), id: \.element.id) { offset, product in
                        ProductCardView(product: product, index: offset + 1) {
                            onShop(product)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 10)
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .padding(.top, 8)
        }
    }
}
