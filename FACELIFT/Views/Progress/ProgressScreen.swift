import SwiftUI

/// Progress update, skin health chart and the products currently in the routine.
struct ProgressScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var insight: InsightContent?
    @State private var showsReview = false
    @State private var isEditingProducts: Bool = false
    @State private var range: ChartRange = .recent
    /// The product we're asking about this visit (kept steady while she answers).
    @State private var checkInProduct: UsedProduct?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Your Progress.")

                updateCard
                    .padding(.top, 18)

                chartCard
                    .padding(.top, 18)

                if let product = checkInProduct {
                    CheckInCard(product: product) { checkInProduct = nil }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                usingCard
                    .padding(.top, 18)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear {
            if checkInProduct == nil { checkInProduct = store.dueCheckIn }
        }
        .sheet(item: $insight) { item in
            InsightSheet(content: item)
        }
        .sheet(isPresented: $showsReview) {
            ProgressReviewSheet()
        }
        // Catches up if a review was due but couldn't be written last time.
        .task { await store.refreshProgressReviewIfDue() }
        .sheet(isPresented: $isEditingProducts) {
            EditProductsSheet()
                .presentationDetents([.large])
                .presentationCornerRadius(32)
                .presentationDragIndicator(.visible)
        }
    }

    private var updateCard: some View {
        Button {
            showsReview = true
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
        let points = chartPoints
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SKIN HEALTH OVER TIME")
                    .font(FLFont.sans(9.5, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.stone)
                Spacer()
                Menu {
                    Picker("Time range", selection: $range) {
                        ForEach(ChartRange.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(range.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .font(FLFont.sans(11.5, .semibold))
                    .foregroundStyle(Palette.rose)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Capsule().fill(Palette.blush.opacity(0.7)))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Time range, \(range.title)")
                .padding(.vertical, -10)
            }
            .sensoryFeedback(.selection, trigger: range)

            if !store.hasRealScans {
                emptyChart
                    .padding(.top, 20)
            } else if points.isEmpty {
                Text("No scans in this period yet. Try a longer range.")
                    .font(FLFont.sans(12.5))
                    .foregroundStyle(Palette.pebble)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                SkinHealthChart(points: points, evenlySpaced: range.days == nil) { id in store.openScan(id) }
                    .id(range)
                    .padding(.top, 20)
            }

            if store.hasRealScans {
                Text("Each dot is a scan. The rose line is your trend. Tap a dot to see that consultation.")
                    .font(FLFont.sans(11))
                    .foregroundStyle(Palette.pebble)
                    .padding(.top, 14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .cardSurface()
        .padding(.horizontal, 24)
    }

    /// Before any scans: faint gridlines and a dotted line waiting to be filled, no fake numbers.
    private var emptyChart: some View {
        VStack(spacing: 14) {
            ZStack {
                VStack(spacing: 30) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(Palette.divider).frame(height: 1)
                    }
                }
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 52))
                    p.addCurve(to: CGPoint(x: 300, y: 18), control1: CGPoint(x: 110, y: 60), control2: CGPoint(x: 190, y: 14))
                }
                .stroke(Palette.roseLine, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 6]))
                .frame(width: 300, height: 70)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)

            Text("Your Skin Score appears here after your first scan.")
                .font(FLFont.sans(12.5))
                .foregroundStyle(Palette.stone)
                .multilineTextAlignment(.center)
            Button {
                store.selectedTab = .scan
            } label: {
                Text("Scan my face")
                    .font(FLFont.sans(13.5, .semibold))
                    .foregroundStyle(Palette.rose)
                    .padding(.horizontal, 18)
                    .frame(height: 36)
                    .background(Palette.blush.opacity(0.7), in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.bottom, 4)
    }

    /// The points inside the chosen range (placeholders until she has a real scan).
    private var chartPoints: [ChartPoint] {
        guard store.hasRealScans else { return store.chartPoints }
        if range == .recent { return Array(store.chartPoints.suffix(6)) }
        guard let days = range.days else { return store.chartPoints }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return store.chartPoints.filter { ($0.date ?? .distantPast) >= cutoff }
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
            if let last = store.latestCheckIn(for: product) {
                Text("\(last.answer.label) · \(last.date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(FLFont.sans(11))
                    .foregroundStyle(Palette.pebble)
            }
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

/// Time ranges for the skin health chart.
enum ChartRange: String, CaseIterable {
    case recent = "Recent"
    case week = "7D"
    case month = "30D"
    case quarter = "90D"
    case year = "1Y"
    case all = "All"

    var title: String {
        switch self {
        case .recent: "Last 6 scans"
        case .week: "Last 7 days"
        case .month: "Last 30 days"
        case .quarter: "Last 90 days"
        case .year: "Last year"
        case .all: "All time"
        }
    }

    var days: Int? {
        switch self {
        case .recent: nil
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .year: 365
        case .all: nil
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
