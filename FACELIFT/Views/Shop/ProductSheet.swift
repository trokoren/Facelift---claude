import SwiftUI

/// Product details, opened by tapping a product in the Shop tab. A bottom sheet that opens at
/// 70% height and expands to full. Any detail the catalog doesn't have yet is simply left out.
struct ProductSheet: View {
    let product: CatalogProduct

    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var addedCount = 0
    @State private var position = ScrollPosition(edge: .top)
    /// The first product she ever opens rises a little and settles back, so she sees it scrolls.
    @AppStorage("facelift.productSheetNudged") private var nudged = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Every catalog row for this product (it can help several areas).
    private var rows: [CatalogProduct] {
        ProductCatalog.shared.products.filter { $0.fullName == product.fullName }
    }

    private var latestMeasures: [String: Int] {
        store.scans.first { !$0.isSample && !$0.measures.isEmpty }?.measures ?? [:]
    }

    private var asRecommendation: Recommendation.Product {
        Recommendation.Product(
            tier: product.tier, name: product.fullName, price: product.price,
            imageName: product.imageName ?? "serum_bottle_dropper",
            brand: product.brand, url: product.url.flatMap(URL.init(string:)),
            essentialOils: product.essentialOils == true ? true : nil
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color(hex: 0xF1EEEA)
                        .frame(height: 160)
                        .overlay {
                            Image(product.imageName ?? "serum_bottle_dropper")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipped()

                    VStack(alignment: .leading, spacing: 0) {
                        header
                        if let details = product.details, !details.isEmpty {
                            section("About") { paragraph(details) }
                        }
                        tags.padding(.top, 20)
                        forYourSkin.padding(.top, 24)
                        if let ingredients = product.keyIngredients, !ingredients.isEmpty {
                            section("Key ingredients") { paragraph(ingredients.joined(separator: " · ")) }
                        }
                        if let how = product.howToUse, !how.isEmpty {
                            section("How to use") { paragraph(how) }
                        }
                        if product.featured == "dermatologist", product.expertName != nil {
                            expert.padding(.top, 24)
                        }
                        if product.essentialOils == true {
                            Text(Recommendation.Product.patchTestNote)
                                .font(FLFont.sans(12.5))
                                .foregroundStyle(Palette.stone)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
            .scrollPosition($position)
            .overlay(alignment: .bottom) {
                // A soft fade above the buttons so the next section peeks through,
                // a quiet hint that there is more to read.
                LinearGradient(colors: [Palette.canvas.opacity(0), Palette.canvas],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 44)
                    .allowsHitTesting(false)
            }

            actions
        }
        .background(Palette.canvas.ignoresSafeArea())
        .presentationDetents([.fraction(0.7), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .sensoryFeedback(.success, trigger: addedCount)
        .task { await nudgeOnce() }
    }

    private func nudgeOnce() async {
        guard !nudged, !reduceMotion else { return }
        nudged = true
        try? await Task.sleep(for: .milliseconds(700))
        withAnimation(.smooth(duration: 0.6)) { position.scrollTo(y: 90) }
        try? await Task.sleep(for: .milliseconds(850))
        withAnimation(.smooth(duration: 0.6)) { position.scrollTo(edge: .top) }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.brand.uppercased())
                .font(FLFont.sans(10.5, .semibold))
                .tracking(1.6)
                .foregroundStyle(Palette.rose)
            Text(product.name)
                .font(FLFont.serif(26))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text("$\(product.price)")
                    .font(FLFont.sans(15, .semibold))
                    .foregroundStyle(Palette.ink)
                if let size = product.size, !size.isEmpty {
                    Text(size)
                        .font(FLFont.sans(13))
                        .foregroundStyle(Palette.stone)
                }
                Text(product.tier)
                    .font(FLFont.sans(13))
                    .foregroundStyle(Palette.stone)
            }
            .padding(.top, 2)
        }
    }

    private var tagList: [String] {
        var out: [String] = []
        switch product.approach ?? "clinical" {
        case "natural": out.append("Natural")
        case "both": out.append("Clinical + natural")
        default: out.append("Clinical")
        }
        if product.strength == "gentle" { out.append("Gentle") }
        if product.pregnancySafe { out.append("Pregnancy-friendly") }
        if let types = product.skinTypes, !types.isEmpty {
            out.append("For " + types.joined(separator: ", ") + " skin")
        }
        return out
    }

    private var tags: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(tagList, id: \.self) { tag in
                Text(tag)
                    .font(FLFont.sans(11.5))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(Palette.chip, in: Capsule())
            }
        }
    }

    /// The areas this product helps, with her score where she has one.
    private var forYourSkin: some View {
        let names = Dictionary(uniqueKeysWithValues: ProductPicker.outcomes.map { ($0.key, $0.name) })
        let areas = Array(Set(rows.map(\.concern))).sorted { (latestMeasures[$0] ?? 100) < (latestMeasures[$1] ?? 100) }
        return VStack(alignment: .leading, spacing: 10) {
            label(latestMeasures.isEmpty ? "Helps with" : "For your skin")
            ForEach(areas, id: \.self) { key in
                HStack {
                    Text(names[key] ?? key)
                        .font(FLFont.sans(14))
                        .foregroundStyle(Palette.body)
                    Spacer()
                    if let score = latestMeasures[key] {
                        Text("Your score \(score)")
                            .font(FLFont.sans(12.5))
                            .foregroundStyle(Palette.stone)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(16)
        .cardSurface(radius: 18)
    }

    private var expert: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Dermatologist recommends")
            if let quote = product.expertQuote, !quote.isEmpty {
                Text("\u{201C}\(quote)\u{201D}")
                    .font(FLFont.serifItalic(17))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text([product.expertName, product.expertTitle].compactMap { $0 }.joined(separator: ", "))
                .font(FLFont.sans(12.5, .semibold))
                .foregroundStyle(Palette.body)
            if let raw = product.sourceURL, let url = URL(string: raw) {
                Button { openURL(url) } label: {
                    Text("Source: \(product.sourceName ?? "article")")
                        .font(FLFont.sans(12))
                        .foregroundStyle(Palette.rose)
                        .underline()
                        .frame(minHeight: 32, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 18)
    }

    private var actions: some View {
        let owned = store.isInRoutine(asRecommendation)
        return HStack(spacing: 10) {
            Button {
                let adding = !owned
                withAnimation(.snappy) { store.toggleRoutine(asRecommendation) }
                if adding { addedCount += 1 }
            } label: {
                Label(owned ? "In your routine" : "I have this", systemImage: owned ? "checkmark" : "plus")
                    .font(FLFont.sans(14, .medium))
                    .foregroundStyle(owned ? Palette.sage : Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: 0xF6EAE8), in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint(owned ? "Removes it from What I'm using" : "Adds it to What I'm using")

            Button {
                if let url = product.url.flatMap(URL.init(string:)) ?? ShopLink.url(for: product.fullName) {
                    openURL(url)
                }
            } label: {
                Text("Shop \u{00B7} $\(product.price)")
                    .font(FLFont.sans(14, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Palette.rose, in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Palette.canvas)
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(FLFont.sans(9.5, .semibold))
            .tracking(1.4)
            .foregroundStyle(Palette.label)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(FLFont.sans(14))
            .foregroundStyle(Palette.body)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label(title)
            content()
        }
        .padding(.top, 24)
    }
}
