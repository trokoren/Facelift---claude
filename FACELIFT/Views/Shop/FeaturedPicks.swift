import SwiftUI

/// "Dermatologist Recommends" and "Natural Favorites" on the Shop tab. Dermatologist picks
/// always name the dermatologist and link the article they were quoted in, so the claim can be
/// checked. Natural Favorites are FACELIFT's own picks and say so.
struct FeaturedPicksRow: View {
    enum Kind {
        case dermatologist
        case natural

        var key: String { self == .dermatologist ? "dermatologist" : "natural" }
        var title: String { self == .dermatologist ? "Dermatologist Recommends" : "Natural Favorites" }
        var subtitle: String {
            self == .dermatologist
                ? "Recommended by board-certified dermatologists in published interviews."
                : "Plant-based picks, chosen by FACELIFT."
        }
    }

    let kind: Kind
    let products: [CatalogProduct]
    let onSelect: (CatalogProduct) -> Void
    let onShop: (CatalogProduct) -> Void
    let onSource: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(FLFont.serif(22))
                    .foregroundStyle(Palette.ink)
                Text(kind.subtitle)
                    .font(FLFont.sans(12))
                    .foregroundStyle(Palette.stone)
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(products, id: \.fullName) { product in
                        FeaturedPickCard(product: product, kind: kind,
                                         onShop: { onShop(product) },
                                         onSource: onSource)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(product) }
                            .accessibilityAction(named: "Details") { onSelect(product) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct FeaturedPickCard: View {
    let product: CatalogProduct
    let kind: FeaturedPicksRow.Kind
    let onShop: () -> Void
    let onSource: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color(hex: 0xF1EEEA)
                .frame(height: 96)
                .overlay {
                    ProductPhoto(name: product.fullName, fallback: product.imageName ?? "serum_bottle_dropper", inset: 6)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 0) {
                Text(product.brand.uppercased())
                    .font(FLFont.sans(9))
                    .tracking(1.2)
                    .foregroundStyle(Palette.faint)
                    .lineLimit(1)
                Text(product.name)
                    .font(FLFont.serif(14))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2, reservesSpace: true)
                    .padding(.top, 4)

                attribution
                    .padding(.top, 8)

                if product.essentialOils == true {
                    Text("Essential oils. Patch test first.")
                        .font(FLFont.sans(9.5))
                        .foregroundStyle(Palette.stone)
                        .padding(.top, 4)
                }

                Spacer(minLength: 10)

                HStack {
                    Button(action: onShop) {
                        Text("Shop")
                            .font(FLFont.sans(11.5))
                            .tracking(0.4)
                            .foregroundStyle(.white)
                            .frame(width: 62, height: 30)
                            .background(Palette.rose, in: Capsule())
                    }
                    .buttonStyle(PressableStyle(scale: 0.93))
                    Spacer(minLength: 4)
                    Text("$\(product.price)")
                        .font(FLFont.sans(11, .semibold))
                        .foregroundStyle(Palette.pebble)
                }
            }
            .padding(12)
        }
        .frame(width: 200, height: 270)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .shadow(color: Palette.ink.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var attribution: some View {
        if kind == .dermatologist, let name = product.expertName {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(FLFont.sans(10.5, .semibold))
                    .foregroundStyle(Palette.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(product.expertTitle ?? "Dermatologist")
                    .font(FLFont.sans(10))
                    .foregroundStyle(Palette.stone)
                    .lineLimit(1)
                if let raw = product.sourceURL, let url = URL(string: raw) {
                    Button { onSource(url) } label: {
                        Text("Source: \(product.sourceName ?? "article")")
                            .font(FLFont.sans(10))
                            .foregroundStyle(Palette.rose)
                            .underline()
                            .frame(minHeight: 24, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Source, \(product.sourceName ?? "article")")
                }
            }
        } else {
            Text(product.tier)
                .font(FLFont.sans(10))
                .foregroundStyle(Palette.stone)
        }
    }
}
