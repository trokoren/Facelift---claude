import SwiftUI
import Observation

/// Shared app state: navigation, scans, products and profile preferences.
@Observable
final class AppStore {
    private static let onboardingKey = "facelift.hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: AppStore.onboardingKey)
    var selectedTab: AppTab = .scan
    var mySkinPath: [MySkinRoute] = []
    var accountPath: [AccountRoute] = []
    var isScanning: Bool = false

    var scans: [Scan] = SampleData.scans
    var usedProducts: [UsedProduct] = SampleData.usedProducts
    var chartPoints: [ChartPoint] = SampleData.chartPoints
    let progressUpdate: String = SampleData.progressUpdate

    var name: String = "Sophia Chen"
    var email: String = "sophia@email.com"
    var skinType: String = "Combination"
    var skinGoals: [String] = ["Anti-aging", "Hydration"]
    var remindersOn: Bool = true

    var latestScan: Scan? { scans.first }

    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    var lastScannedText: String {
        guard let date = latestScan?.date else { return "Never" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    var visibleChartPoints: [ChartPoint] {
        Array(chartPoints.suffix(4))
    }

    func scan(with id: UUID) -> Scan? {
        scans.first { $0.id == id }
    }

    func startScan() {
        isScanning = true
    }

    func goHome() {
        mySkinPath = []
        selectedTab = .mySkin
    }

    /// Finishes a camera scan: records the result and shows the fresh analysis.
    func completeScan() {
        let base = latestScan
        let scan = Scan(
            id: UUID(),
            date: Date(),
            portraitName: nil,
            concerns: base?.concerns ?? ["Dehydration", "Fine Lines", "Texture"],
            productsShopped: 0,
            categories: SampleData.categories(shift: 2),
            recommendations: SampleData.recommendations
        )
        scans.insert(scan, at: 0)

        let colors: [Color] = [Palette.sky, Palette.rose, Palette.sage, Palette.gold]
        let color = colors[chartPoints.count % colors.count]
        chartPoints.append(ChartPoint(label: scan.date.formatted(.dateTime.month(.abbreviated).day()), value: scan.overallScore, color: color))

        mySkinPath = [.scan(id: scan.id, isFresh: true)]
        selectedTab = .mySkin
        isScanning = false
    }

    func finishResults() {
        mySkinPath = []
    }

    func recordShop(_ product: Recommendation.Product, scanID: UUID) {
        if let index = scans.firstIndex(where: { $0.id == scanID }) {
            scans[index].productsShopped += 1
        }
        let alreadyUsing = usedProducts.contains { product.name.localizedCaseInsensitiveContains($0.name) }
        guard !alreadyUsing else { return }
        let words = product.name.split(separator: " ")
        let brandWordCount = product.name.hasPrefix("The ") || product.name.hasPrefix("Sunday ") || product.name.hasPrefix("Dr. ") || product.name.hasPrefix("Drunk ") ? 2 : 1
        let brand = words.prefix(brandWordCount).joined(separator: " ")
        let name = words.dropFirst(brandWordCount).joined(separator: " ")
        let tint = UsedProduct.Tint.allCases[usedProducts.count % UsedProduct.Tint.allCases.count]
        usedProducts.insert(UsedProduct(id: UUID(), brand: brand, name: name, price: product.price, tint: tint), at: 0)
    }

    func removeUsed(_ product: UsedProduct) {
        usedProducts.removeAll { $0.id == product.id }
    }

    func toggleGoal(_ goal: String) {
        if skinGoals.contains(goal) {
            skinGoals.removeAll { $0 == goal }
        } else {
            skinGoals.append(goal)
        }
    }

    func deleteHistory() {
        scans = Array(scans.prefix(1))
    }

    func signOut() {
        mySkinPath = []
        accountPath = []
        selectedTab = .scan
    }

    /// Applies the onboarding answers to the profile and enters the main app.
    func completeOnboarding(with answers: OnboardingAnswers, signIn: Bool) {
        if !signIn {
            skinType = answers.resolvedSkinType
            skinGoals = answers.skinGoals
            remindersOn = answers.notificationsRequested
            if let first = scans.first {
                scans[0] = Scan(
                    id: first.id,
                    date: first.date,
                    portraitName: first.portraitName,
                    concerns: answers.topConcerns,
                    productsShopped: first.productsShopped,
                    categories: first.categories,
                    recommendations: first.recommendations
                )
            }
        }
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        mySkinPath = []
        selectedTab = signIn ? .scan : .mySkin
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = true
        }
    }

    /// Restarts the skin profile tour from the beginning.
    func restartOnboarding() {
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
        accountPath = []
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompletedOnboarding = false
        }
    }
}
