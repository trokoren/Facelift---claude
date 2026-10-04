import SwiftUI
import StoreKit

/// Full skin analysis: category cards + "What your skin needs." recommendations.
/// Fresh results show a sticky "Next" button; history shows "Back to My Skin".
struct AnalysisView: View {
    let scanID: UUID
    let isFresh: Bool

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var insight: InsightContent?
    @State private var shopCount: Int = 0

    var body: some View {
        Group {
            if let scan = store.scan(with: scanID) {
                content(for: scan)
            } else {
                Palette.canvas.ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $insight) { item in
            InsightSheet(content: item)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: shopCount)
        .task {
            // Happy moment: a fresh scan that beat her last one. Let the scores animate in first.
            guard isFresh, store.shouldAskForReviewAfterScan else { return }
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            store.markReviewAsked()
            requestReview()
        }
    }

    private func content(for scan: Scan) -> some View {
        ScrollView {
            // The FACELIFT header scrolls away; on past scans the "Back to My Skin" bar
            // sits just under it and then sticks to the top once it gets there.
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                BrandHeader(subtitle: scan.consult == nil ? "Your Skin Analysis." : "Your Skin Consultation.")

                Section {
                    if let consult = scan.consult {
                        // Current scans: the consultation.
                        ConsultView(scan: scan, consult: consult)
                    } else {
                        // Older and sample scans: the category cards.
                        SectionLabel("YOUR ANALYSIS")
                            .padding(.top, 22)
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(scan.categories) { category in
                                AnalysisCardView(category: category) {
                                    insight = InsightContent(category: category)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }

                    if scan.consult != nil || scan.isSample {
                        needsBanner
                            .padding(.top, 20)
                    }

                    if let consult = scan.consult, !(consult.plan.morning.isEmpty && consult.plan.evening.isEmpty) {
                        // Current scans: shop the steps of her own plan.
                        RoutineShopView(plan: consult.plan) { step in
                            shopStep(step, scanID: scan.id)
                        }
                        .padding(.top, 24)
                    } else if scan.isSample {
                        // Placeholder scans only: the illustrative picks.
                        VStack(alignment: .leading, spacing: 26) {
                            ForEach(scan.recommendations) { recommendation in
                                RecommendationSectionView(recommendation: recommendation) { product in
                                    shop(product, scanID: scan.id)
                                }
                            }
                        }
                        .padding(.top, 32)
                    }
                } header: {
                    if !isFresh {
                        backRow(date: scan.formattedDate)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background { GlassBackdrop() }
        // Solid strip behind the status bar so scrolled content never shows above the
        // pinned back bar.
        .overlay(alignment: .top) {
            Color.clear
                .frame(height: 0)
                .background(Palette.canvas.ignoresSafeArea(edges: .top))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Pinned so the next step is always visible, not buried under the recommendations.
            if isFresh {
                nextButton
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(colors: [Palette.canvas.opacity(0), Palette.canvas, Palette.canvas], startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                    )
            }
        }
    }

    private func backRow(date: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 13, weight: .regular))
                        Text("Back to My Skin")
                            .font(FLFont.sans(14, .medium))
                    }
                    .foregroundStyle(Palette.rose)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.98))

                Spacer()

                Text(date)
                    .font(FLFont.serifItalic(15))
                    .foregroundStyle(Palette.stone)
            }
            .padding(.horizontal, 24)

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
        }
        .background(Palette.canvas)
    }

    private var needsBanner: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.divider).frame(height: 1)
            Text("What your skin needs.")
                .font(FLFont.serif(20.5))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    private var nextButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.35)) {
                store.finishResults()
            }
        } label: {
            // Her very first results: reassure her they're kept before she moves on.
            Text(store.scans.filter { !$0.isSample }.count <= 1 ? "Save & Continue" : "Continue to My Skin")
                .font(FLFont.sans(16.5, .medium))
                .tracking(0.6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Palette.rose, in: Capsule())
                .shadow(color: Palette.rose.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableStyle())
        .padding(.horizontal, 24)
        .sensoryFeedback(.impact(weight: .medium), trigger: store.mySkinPath.isEmpty)
    }

    /// A plan step ("Hyaluronic acid serum (damp skin)"): search for that kind of product.
    private func shopStep(_ step: String, scanID: UUID) {
        shopCount += 1
        store.recordRoutineShop(scanID: scanID)
        let query = step.replacingOccurrences(of: #"\s*\(.*?\)"#, with: "", options: .regularExpression)
        if let url = ShopLink.url(for: query) {
            openURL(url)
        }
    }

    private func shop(_ product: Recommendation.Product, scanID: UUID) {
        shopCount += 1
        store.recordShop(product, scanID: scanID)
        if let url = ShopLink.url(for: product.name) {
            openURL(url)
        }
    }
}
