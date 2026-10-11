import SwiftUI

/// "Your picks": one product per area she needs most, at the tier that fits her budget.
/// Shown under the Skin Score on her results and at the top of My Skin, so the products are
/// never more than a glance away. "See all options" leads to every tier.
struct PicksCard: View {
    let recommendations: [Recommendation]
    let budget: String?
    var subtitle: String? = nil
    let onShop: (Recommendation.Product) -> Void
    /// My Skin only: lets her mark a pick as something she already uses.
    var onHaveIt: ((Recommendation.Product) -> Void)? = nil
    var isOwned: (Recommendation.Product) -> Bool = { _ in false }
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    SectionLabel("YOUR PICKS")
                    if let subtitle {
                        Text(subtitle)
                            .font(FLFont.sans(11.5))
                            .foregroundStyle(Palette.faint)
                    }
                }
                Spacer()
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text("See all options")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .regular))
                    }
                    .font(FLFont.sans(11.4))
                    .foregroundStyle(Palette.rose)
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }

            VStack(spacing: 0) {
                ForEach(Array(recommendations.enumerated()), id: \.element.id) { offset, recommendation in
                    if let product = recommendation.featured(for: budget) {
                        if offset > 0 {
                            Rectangle().fill(Palette.rowDivider).frame(height: 1)
                        }
                        row(recommendation, product)
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding(18)
        .cardSurface(radius: 20)
    }

    private func row(_ recommendation: Recommendation, _ product: Recommendation.Product) -> some View {
        let owned = isOwned(product)
        return HStack(alignment: .center, spacing: 14) {
            Color(hex: 0xF1EEEA)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(product.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(recommendation.issue.uppercased())
                    .font(FLFont.sans(9.5, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.rose)
                Text(product.name)
                    .font(FLFont.serif(15))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text("$\(product.price)")
                        .font(FLFont.sans(11.5, .semibold))
                        .foregroundStyle(Palette.pebble)
                    if let onHaveIt {
                        if owned {
                            Label("In your routine", systemImage: "checkmark")
                                .font(FLFont.sans(11.5))
                                .foregroundStyle(Palette.sage)
                                .labelStyle(.titleAndIcon)
                        } else {
                            Button { onHaveIt(product) } label: {
                                Text("I have this")
                                    .font(FLFont.sans(11.5))
                                    .foregroundStyle(Palette.taupe)
                                    .underline()
                                    .frame(minHeight: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button { onShop(product) } label: {
                Text("Shop")
                    .font(FLFont.sans(12))
                    .tracking(0.4)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 32)
                    .background(Palette.rose, in: Capsule())
            }
            .buttonStyle(PressableStyle(scale: 0.93))
        }
        .padding(.vertical, 12)
    }
}

extension Recommendation {
    /// The product to lead with for her budget answer: Under $30 leads with Budget,
    /// $75 and up with Luxury, everyone else with Balanced. Falls back to the nearest tier.
    func featured(for budget: String?) -> Product? {
        let order: [String]
        switch budget {
        case "Under $30": order = ["Budget", "Balanced", "Luxury"]
        case "$75 to $150", "No limit": order = ["Luxury", "Balanced", "Budget"]
        default: order = ["Balanced", "Budget", "Luxury"]
        }
        for tier in order {
            if let product = products.first(where: { $0.tier == tier }) { return product }
        }
        return products.first
    }
}
