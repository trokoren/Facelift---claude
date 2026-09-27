import SwiftUI

/// Progress update, skin health chart and the products currently in the routine.
struct ProgressScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var insight: InsightContent?
    @State private var isEditingProducts: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Your Progress.")

                updateCard
                    .padding(.top, 18)

                chartCard
                    .padding(.top, 18)

                usingCard
                    .padding(.top, 18)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(Palette.canvas.ignoresSafeArea())
        .sheet(item: $insight) { item in
            InsightSheet(content: item)
        }
        .sheet(isPresented: $isEditingProducts) {
            EditProductsSheet()
                .presentationDetents([.large])
                .presentationCornerRadius(32)
                .presentationDragIndicator(.visible)
        }
    }

    private var updateCard: some View {
        Button {
            insight = InsightContent(label: "YOUR PROGRESS UPDATE", accent: Palette.rose, title: "Since your last scan", text: store.progressUpdate)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR PROGRESS UPDATE")
                        .font(FLFont.sans(9.5, .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Palette.stone)
                    Text(store.progressUpdate)
                        .font(FLFont.sans(12.9))
                        .foregroundStyle(Palette.body)
                        .lineSpacing(4.5)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Palette.quiet)
            }
            .padding(.leading, 24)
            .padding(.trailing, 20)
            .padding(.vertical, 22)
            .background(AccentEdgeBackground(accent: Palette.rose))
        }
        .buttonStyle(CardPressStyle())
        .padding(.horizontal, 24)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SKIN HEALTH OVER TIME")
                .font(FLFont.sans(9.5, .semibold))
                .tracking(1.4)
                .foregroundStyle(Palette.stone)
            SkinHealthChart(points: store.visibleChartPoints)
                .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .cardSurface()
        .padding(.horizontal, 24)
    }

    private var usingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("WHAT I'M USING")
                    .font(FLFont.sans(9.5, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.stone)
                Spacer()
                Button {
                    isEditingProducts = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Palette.stone)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Edit products")
            }
            .padding(.top, -12)

            if store.usedProducts.isEmpty {
                Button {
                    isEditingProducts = true
                } label: {
                    Text("Add the products in your routine so we can track what's working.")
                        .font(FLFont.sans(12))
                        .foregroundStyle(Palette.pebble)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PressableStyle(scale: 0.98))
            }

            ForEach(Array(store.usedProducts.enumerated()), id: \.element.id) { offset, product in
                if offset > 0 {
                    Rectangle().fill(Palette.rowDivider).frame(height: 1)
                }
                usedRow(product)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 6)
        .cardSurface()
        .padding(.horizontal, 24)
    }

    private func usedRow(_ product: UsedProduct) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(product.brand.uppercased())
                .font(FLFont.sans(9.5, .semibold))
                .tracking(1.4)
                .foregroundStyle(Palette.stone)
            Text(product.name)
                .font(FLFont.sans(12.9, .bold))
                .foregroundStyle(Palette.ink)
            HStack(spacing: 10) {
                if product.price > 0 {
                    Text("$\(product.price)")
                        .font(FLFont.sans(12.5))
                        .foregroundStyle(Palette.stone)
                }
                Button {
                    if let url = product.shopURL { openURL(url) }
                } label: {
                    HStack(spacing: 5) {
                        Text("Shop Again")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .font(FLFont.sans(11.5))
                    .foregroundStyle(product.tint.color)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        // Long-press a product to get a Remove option.
        .background(Color.white)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.snappy) { store.removeUsed(product) }
            } label: {
                Label("Remove from my routine", systemImage: "trash")
            }
        }
    }
}

/// Full-height editor: one card per product (brand, name, price, link), delete with X,
/// dashed "+ Add Product", and Save / Done to keep changes. Swiping down discards them.
private struct EditProductsSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [ProductDraft] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("WHAT I'M USING")
                    .font(FLFont.sans(12, .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Palette.stone)
                Spacer()
                Button("Save") { save() }
                    .font(FLFont.sans(17, .semibold))
                    .foregroundStyle(Palette.rose)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(drafts) { draft in
                        ProductDraftCard(draft: binding(for: draft.id)) {
                            withAnimation(.snappy) { drafts.removeAll { $0.id == draft.id } }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }

                    Button {
                        withAnimation(.snappy) { drafts.append(ProductDraft()) }
                    } label: {
                        Text("+ Add Product")
                            .font(FLFont.sans(17, .medium))
                            .foregroundStyle(Palette.rose)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Palette.blush.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Palette.roseLine, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                            )
                    }
                    .buttonStyle(PressableStyle(scale: 0.98))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            OnboardingCTA(title: "Done") { save() }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear {
            drafts = store.usedProducts.map(ProductDraft.init)
        }
    }

    private func binding(for id: UUID) -> Binding<ProductDraft> {
        Binding(
            get: { drafts.first { $0.id == id } ?? ProductDraft() },
            set: { updated in
                if let index = drafts.firstIndex(where: { $0.id == id }) {
                    drafts[index] = updated
                }
            }
        )
    }

    private func save() {
        withAnimation(.snappy) { store.saveUsedProducts(drafts) }
        dismiss()
    }
}

private struct ProductDraftCard: View {
    @Binding var draft: ProductDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            field("BRAND", text: $draft.brand, placeholder: "e.g. Laneige")
            field("PRODUCT NAME", text: $draft.name, placeholder: "e.g. Water Bank Serum")
            field("PRICE", text: $draft.price, placeholder: "$0", keyboard: .numbersAndPunctuation)
            field("URL", text: $draft.url, placeholder: "brand.com", keyboard: .URL)
        }
        .padding(.horizontal, 26)
        .padding(.top, 26)
        .padding(.bottom, 24)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Palette.stone)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.9))
            .padding(.top, 10)
            .padding(.trailing, 12)
            .accessibilityLabel("Remove product")
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(FLFont.sans(12, .medium))
                .tracking(1.6)
                .foregroundStyle(Palette.stone)
            TextField(placeholder, text: text)
                .font(FLFont.sans(17))
                .foregroundStyle(Palette.ink)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .URL ? TextInputAutocapitalization.never : TextInputAutocapitalization.words)
                .autocorrectionDisabled(keyboard == .URL)
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
        }
    }
}
