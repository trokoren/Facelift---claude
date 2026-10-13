import SwiftUI

/// The Shop tab: every product in the catalog by outcome, then Dermatologist Recommends and
/// Natural Favorites. Tapping a product opens its details sheet.
/// Uses the same safety rules as her picks (pregnancy, sensitivity, essential oils), and
/// starts on her Clinical to Natural setting. Open to everyone, lapsed members included.
struct ShopScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var side: Side?
    @State private var tier: String?
    /// The product whose details sheet is open.
    @State private var selected: CatalogProduct?
    /// The Clinical / Natural filter starts on her setting once, then stays where she puts it.
    @State private var hasSetDefault = false
    @State private var query = ""

    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    /// The Clinical / Natural filter. Nil shows both.
    enum Side: String, CaseIterable {
        case clinical = "Clinical"
        case natural = "Natural"
        var key: String { rawValue.lowercased() }
    }

    private var latestScan: Scan? {
        store.scans.first { !$0.isSample && !$0.recommendations.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Shop.")

                SearchField(text: $query, prompt: "Search brands, products, ingredients")
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                if isSearching {
                    searchResults
                        .padding(.top, 12)
                } else {
                    filters
                        .padding(.top, 14)

                    ForEach(sections, id: \.key) { section in
                        outcomeRow(section)
                            .padding(.top, 28)
                    }

                    if sections.isEmpty {
                        Text("Nothing matches these filters yet. Try All.")
                            .font(FLFont.sans(13))
                            .foregroundStyle(Palette.stone)
                            .padding(.horizontal, 24)
                            .padding(.top, 28)
                    }

                    ForEach([FeaturedPicksRow.Kind.dermatologist, .natural], id: \.key) { kind in
                        let picks = featured(kind)
                        if !picks.isEmpty {
                            FeaturedPicksRow(
                                kind: kind, products: picks,
                                onSelect: { selected = $0 },
                                onShop: { product in open(product.url.flatMap(URL.init(string:)), name: product.fullName) },
                                onSource: { openURL($0) }
                            )
                            .padding(.top, 36)
                        }
                    }
                }

                Text("Prices can change at the store. We may earn a small commission when you shop through FACELIFT, at no extra cost to you.")
                    .font(FLFont.sans(11))
                    .foregroundStyle(Palette.faint)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
            }
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.canvas.ignoresSafeArea())
        .sheet(item: $selected) { product in
            ProductSheet(product: product)
                .environment(store)
        }
        .onAppear {
            guard !hasSetDefault else { return }
            hasSetDefault = true
            side = Self.defaultSide(for: store.approach)
        }
        .onChange(of: store.approach) { _, new in side = Self.defaultSide(for: new) }
    }

    // MARK: - Search

    /// While she's searching, the filters and rows step aside for one list of matches.
    /// Search looks at every product (her Clinical / Natural and price filters don't apply),
    /// but the same safety rules do.
    private var searchResults: some View {
        let safety = ProductSafety(profile: store.profile, consult: latestScan?.consult)
        let matches = CatalogSearch.results(for: query, in: ProductCatalog.shared.products.filter { safety.allows($0) })
        return VStack(alignment: .leading, spacing: 0) {
            Text(matches.isEmpty ? "No matches yet. Try a brand, or an ingredient like niacinamide."
                                 : (matches.count == 1 ? "1 product" : "\(matches.count) products"))
                .font(FLFont.sans(12))
                .foregroundStyle(Palette.stone)
                .padding(.bottom, 4)
            ForEach(Array(matches.enumerated()), id: \.element.fullName) { offset, product in
                if offset > 0 { Rectangle().fill(Palette.rowDivider).frame(height: 1) }
                Button { selected = product } label: {
                    ProductSearchRow(product: product) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Palette.faint)
                    }
                }
                .buttonStyle(PressableStyle(scale: 0.98))
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Filters

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    chip("All", isOn: side == nil) { side = nil }
                    ForEach(Side.allCases, id: \.self) { option in
                        chip(option.rawValue, isOn: side == option) { side = option }
                    }
                    Rectangle()
                        .fill(Palette.roseLine)
                        .frame(width: 1, height: 20)
                        .padding(.horizontal, 4)
                    chip("Any price", isOn: tier == nil) { tier = nil }
                    ForEach(ProductPicker.tiers, id: \.self) { option in
                        chip(option, isOn: tier == option) { tier = option }
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
        .sensoryFeedback(.selection, trigger: side)
        .sensoryFeedback(.selection, trigger: tier)
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FLFont.sans(12.5, isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? .white : Palette.ink)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isOn ? Palette.rose : Palette.chip, in: Capsule())
        }
        .buttonStyle(PressableStyle(scale: 0.94))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    /// Clinical-leaning settings start on Clinical, natural-leaning on Natural, Balanced on All.
    private static func defaultSide(for approach: SkincareApproach) -> Side? {
        switch approach {
        case .clinical, .leaningClinical: .clinical
        case .natural, .leaningNatural: .natural
        case .balanced: nil
        }
    }

    // MARK: - Outcome sections

    private struct Section {
        let key: String
        let name: String
        let products: [CatalogProduct]
    }

    /// Her neediest areas first when she has a scan; otherwise a fixed order.
    private var sections: [Section] {
        let safety = ProductSafety(profile: store.profile, consult: latestScan?.consult)
        let measures = store.scans.first { !$0.isSample && !$0.measures.isEmpty }?.measures ?? [:]
        let outcomes = ProductPicker.outcomes.sorted { a, b in
            (measures[a.key] ?? 100) < (measures[b.key] ?? 100)
        }
        return outcomes.compactMap { outcome in
            var seen = Set<String>()
            let products = ProductCatalog.shared.products
                .filter { $0.concern == outcome.key }
                .filter { safety.allows($0) }
                .filter { side == nil || $0.fits(side: side!.key) }
                .filter { tier == nil || $0.tier == tier }
                .sorted { a, b in
                    let ta = ProductPicker.tiers.firstIndex(of: a.tier) ?? 0
                    let tb = ProductPicker.tiers.firstIndex(of: b.tier) ?? 0
                    return ta != tb ? ta < tb : a.rank < b.rank
                }
                .filter { seen.insert($0.fullName).inserted }
            return products.isEmpty ? nil : Section(key: outcome.key, name: outcome.name, products: products)
        }
    }

    private func outcomeRow(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(section.name)
                    .font(FLFont.serif(22))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if let score = latestMeasure(section.key) {
                    Text("Your score \(score)")
                        .font(FLFont.sans(11.5))
                        .foregroundStyle(Palette.stone)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(section.products.enumerated()), id: \.element.fullName) { offset, product in
                        let item = Recommendation.Product(
                            tier: product.tier, name: product.fullName, price: product.price,
                            imageName: product.imageName ?? "serum_bottle_dropper",
                            brand: product.brand, url: product.url.flatMap(URL.init(string:)),
                            essentialOils: product.essentialOils == true ? true : nil
                        )
                        ProductCardView(product: item, index: offset + 1) {
                            open(item.url, name: item.name)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selected = product }
                        .accessibilityAction(named: "Details") { selected = product }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Featured picks of one kind, safe for her, in their curated order, each product once.
    private func featured(_ kind: FeaturedPicksRow.Kind) -> [CatalogProduct] {
        let safety = ProductSafety(profile: store.profile, consult: latestScan?.consult)
        var seen = Set<String>()
        return ProductCatalog.shared.products
            .filter { $0.featured == kind.key && safety.allows($0) }
            .filter { kind == .natural || ($0.expertName != nil && $0.sourceURL != nil) }
            .sorted { ($0.featuredRank ?? 99) < ($1.featuredRank ?? 99) }
            .filter { seen.insert($0.fullName).inserted }
    }

    private func latestMeasure(_ key: String) -> Int? {
        store.scans.first { !$0.isSample && !$0.measures.isEmpty }?.measures[key]
    }

    private func open(_ url: URL?, name: String) {
        Analytics.track(.productShopTapped, ["product": name, "source": "shop"])
        if let url = url ?? ShopLink.url(for: name) { openURL(url) }
    }
}
