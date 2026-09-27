import SwiftUI

/// Progress update, skin health chart and the products currently in the routine.
struct ProgressScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var insight: InsightContent?
    @State private var isEditing: Bool = false
    @State private var isAddingProduct: Bool = false

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
        .sheet(isPresented: $isAddingProduct) {
            AddProductSheet { brand, name, price in
                withAnimation(.snappy) { store.addUsed(brand: brand, name: name, price: price) }
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(28)
        }
        .sensoryFeedback(.selection, trigger: isEditing)
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
                    withAnimation(.snappy) { isEditing.toggle() }
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                        .font(FLFont.sans(13, .semibold))
                        .foregroundStyle(Palette.rose)
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel(isEditing ? "Done editing" : "Edit products")
            }
            .padding(.top, -12)

            if store.usedProducts.isEmpty {
                Text("Products you shop from your recommendations will appear here.")
                    .font(FLFont.sans(12))
                    .foregroundStyle(Palette.pebble)
                    .padding(.vertical, 16)
            }

            ForEach(Array(store.usedProducts.enumerated()), id: \.element.id) { offset, product in
                if offset > 0 {
                    Rectangle().fill(Palette.rowDivider).frame(height: 1)
                }
                usedRow(product)
            }

            if isEditing || store.usedProducts.isEmpty {
                Rectangle().fill(Palette.rowDivider).frame(height: 1)
                Button {
                    isAddingProduct = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 17, weight: .light))
                        Text("Add a product I use")
                            .font(FLFont.sans(13.5, .medium))
                        Spacer()
                    }
                    .foregroundStyle(Palette.rose)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.98))
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 6)
        .cardSurface()
        .padding(.horizontal, 24)
    }

    private func usedRow(_ product: UsedProduct) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(product.brand.uppercased())
                    .font(FLFont.sans(9.5, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.stone)
                Text(product.name)
                    .font(FLFont.sans(12.9, .bold))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 10) {
                    Text("$\(product.price)")
                        .font(FLFont.sans(12.5))
                        .foregroundStyle(Palette.stone)
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
            Spacer(minLength: 0)
            if isEditing {
                Button {
                    withAnimation(.snappy) { store.removeUsed(product) }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Palette.rose)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Remove \(product.name)")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
    }
}

/// Quick form to add something she already uses to her routine.
private struct AddProductSheet: View {
    let onAdd: (String, String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var brand: String = ""
    @State private var name: String = ""
    @State private var price: String = ""
    @FocusState private var focused: Field?

    private enum Field { case brand, name, price }

    private var canSave: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add a product")
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
            Text("Track what's already in your routine.")
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.stone)
                .padding(.top, 4)

            VStack(spacing: 10) {
                field("Brand (e.g. Laneige)", text: $brand, field: .brand)
                field("Product (e.g. Water Bank Serum)", text: $name, field: .name)
                field("Price (optional)", text: $price, field: .price)
                    .keyboardType(.numberPad)
            }
            .padding(.top, 20)

            Spacer(minLength: 16)

            OnboardingCTA(title: "Add to my routine", isEnabled: canSave) {
                let cleanPrice = Int(price.filter(\.isNumber)) ?? 0
                onAdd(brand.trimmingCharacters(in: .whitespaces), name.trimmingCharacters(in: .whitespaces), cleanPrice)
                dismiss()
            }
        }
        .padding(24)
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear { focused = .brand }
    }

    private func field(_ placeholder: String, text: Binding<String>, field: Field) -> some View {
        TextField(placeholder, text: text)
            .font(FLFont.sans(16))
            .foregroundStyle(Palette.ink)
            .focused($focused, equals: field)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Palette.divider, lineWidth: 1))
    }
}
