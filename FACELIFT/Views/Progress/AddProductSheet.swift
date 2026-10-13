import SwiftUI

/// "Add a product" for What I'm using: search FACELIFT's products and tap to add, so her
/// routine carries photos, prices and shop links. Anything we don't carry, she adds herself
/// with "Don't see it? Add it yourself", which opens the manual form with her search filled in.
struct AddProductSheet: View {
    let onAddManually: (String) -> Void

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var addedCount = 0
    @FocusState private var searchFocused: Bool

    private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Her current picks, as catalog products.
    private var picks: [CatalogProduct] {
        guard let latest = store.scans.first(where: { !$0.isSample && !$0.recommendations.isEmpty }) else { return [] }
        let names = latest.recommendations.flatMap { $0.products.map(\.name) }
        var seen = Set<String>()
        return names.compactMap { name in
            guard seen.insert(name).inserted else { return nil }
            return ProductCatalog.shared.products.first { $0.fullName == name }
        }
    }

    /// Every product once, by brand.
    private var allProducts: [CatalogProduct] {
        var seen = Set<String>()
        return ProductCatalog.shared.products
            .filter { seen.insert($0.fullName).inserted }
            .sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add a product")
                    .font(FLFont.serif(28))
                    .foregroundStyle(Palette.ink)
                Text("Tap anything you already use.")
                    .font(FLFont.sans(13))
                    .foregroundStyle(Palette.stone)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            SearchField(text: $query, prompt: "Search brands, products, ingredients", focused: $searchFocused)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Always in view, so a product we don't carry is never a dead end.
            manualButton
                .padding(.horizontal, 24)
                .padding(.top, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if isSearching {
                        let matches = CatalogSearch.results(for: query, in: ProductCatalog.shared.products)
                        if matches.isEmpty {
                            Text("We don't carry that one yet.")
                                .font(FLFont.sans(13))
                                .foregroundStyle(Palette.stone)
                                .padding(.top, 8)
                        } else {
                            list(matches)
                        }
                    } else {
                        if !picks.isEmpty {
                            label("FROM YOUR PICKS").padding(.top, 8)
                            list(picks)
                        }
                        label("ALL PRODUCTS").padding(.top, picks.isEmpty ? 8 : 20)
                        list(allProducts)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)

            OnboardingCTA(title: "Done") { dismiss() }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: addedCount)
    }

    private func list(_ products: [CatalogProduct]) -> some View {
        ForEach(Array(products.enumerated()), id: \.element.fullName) { offset, product in
            if offset > 0 { Rectangle().fill(Palette.rowDivider).frame(height: 1) }
            row(product)
        }
    }

    private func row(_ product: CatalogProduct) -> some View {
        let item = product.asRecommendation
        let owned = store.isInRoutine(item)
        return Button {
            withAnimation(.snappy) { store.toggleRoutine(item) }
            if !owned { addedCount += 1 }
        } label: {
            ProductSearchRow(product: product) {
                Group {
                    if owned {
                        Label("Added", systemImage: "checkmark")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(Palette.sage)
                    } else {
                        Text("Add")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 32)
                            .background(Palette.rose, in: Capsule())
                    }
                }
                .font(FLFont.sans(12, .medium))
            }
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .accessibilityHint(owned ? "Removes it from What I'm using" : "Adds it to What I'm using")
    }

    private var manualButton: some View {
        Button {
            onAddManually(query.trimmingCharacters(in: .whitespaces))
            dismiss()
        } label: {
            HStack(spacing: 6) {
                Text("Don't see it?")
                    .foregroundStyle(Palette.stone)
                Text("Add it yourself")
                    .foregroundStyle(Palette.rose)
                    .underline()
            }
            .font(FLFont.sans(13))
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(FLFont.sans(9.5, .semibold))
            .tracking(1.4)
            .foregroundStyle(Palette.stone)
            .padding(.bottom, 2)
    }
}

extension CatalogProduct {
    /// The same product in the shape picks and What I'm using work with.
    var asRecommendation: Recommendation.Product {
        Recommendation.Product(
            tier: tier, name: fullName, price: price,
            imageName: imageName ?? "serum_bottle_dropper",
            brand: brand, url: url.flatMap(URL.init(string:)),
            essentialOils: essentialOils == true ? true : nil
        )
    }
}

/// "Add it yourself": one empty product card (brand, name, price, link) and Save.
/// Whatever she searched for starts in the name.
struct ManualProductSheet: View {
    let startingName: String

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ProductDraft()

    private var canSave: Bool {
        !draft.brand.trimmingCharacters(in: .whitespaces).isEmpty
            || !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add your product")
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 24)
                .padding(.top, 28)

            ScrollView {
                ProductDraftCard(draft: $draft) { dismiss() }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            OnboardingCTA(title: "Save") {
                let existing = store.usedProducts.map(ProductDraft.init)
                withAnimation(.snappy) { store.saveUsedProducts([draft] + existing) }
                dismiss()
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.5)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear { if draft.name.isEmpty { draft.name = startingName } }
    }
}
