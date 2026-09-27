import SwiftUI

/// Progress update, skin health chart and the products currently in the routine.
struct ProgressScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var insight: InsightContent?
    @State private var isEditing: Bool = false

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
                    Group {
                        if isEditing {
                            Text("Done")
                                .font(FLFont.sans(11.5, .medium))
                                .foregroundStyle(Palette.rose)
                        } else {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Palette.stone)
                        }
                    }
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
