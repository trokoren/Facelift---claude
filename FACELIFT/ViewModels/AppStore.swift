import SwiftUI
import Observation
import UserNotifications

/// Shared app state: navigation, scans, products and profile preferences.
@Observable
final class AppStore {
    private static let onboardingKey = "facelift.hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: AppStore.onboardingKey)
    var selectedTab: AppTab = .scan
    var mySkinPath: [MySkinRoute] = []
    var accountPath: [AccountRoute] = []
    var isScanning: Bool = false
    /// Photos from the most recent scan. Memory only (never written to disk); cleared once analyzed.
    var lastCaptures: [UIImage] = []
    /// Real results from the most recent scan, until they're saved into a Scan.
    var latestReport: SkinReport?

    var scans: [Scan] = SampleData.scans
    var usedProducts: [UsedProduct] = SampleData.usedProducts
    var chartPoints: [ChartPoint] = SampleData.chartPoints

    var name: String = "Sophia Chen"
    var email: String = "sophia@email.com"
    var skinType: String = "Combination"
    var skinGoals: [String] = ["Anti-aging", "Hydration"]
    var remindersOn: Bool = true

    var latestScan: Scan? { scans.first }

    /// Plain-language "what changed" summary. Every scan is kept (nothing resets): this compares
    /// the newest scan with the one right before it, while the chart shows the full history.
    var progressUpdate: String {
        guard let latest = scans.first else {
            return "Scan your skin to start tracking how it changes."
        }
        guard scans.count > 1 else {
            return "This first scan is your baseline. Scan again in about 10 days and we'll show you exactly what changed."
        }
        let previous = scans[1]
        var parts: [String] = []

        let now = latest.overallScore
        let before = previous.overallScore
        let delta = now - before
        if delta > 0 {
            parts.append("Your overall skin score is up \(delta) \(delta == 1 ? "point" : "points") since your last scan (\(before) to \(now)).")
        } else if delta < 0 {
            parts.append("Your overall skin score dipped \(-delta) \(delta == -1 ? "point" : "points") since your last scan (\(before) to \(now)). Small swings are normal with sleep, stress and your cycle.")
        } else {
            parts.append("Your overall skin score held steady at \(now) since your last scan.")
        }

        let changes: [(category: AnalysisCategory, change: Int)] = latest.categories.compactMap { category in
            guard let old = previous.categories.first(where: { $0.kind == category.kind }) else { return nil }
            return (category, category.score - old.score)
        }
        let best = changes.max { $0.change < $1.change }
        let worst = changes.min { $0.change < $1.change }

        if let best, best.change > 0 {
            parts.append("\(best.category.title) improved the most, up \(best.change).")
        }
        if let worst, worst.change < 0, worst.category.kind != best?.category.kind {
            parts.append("\(worst.category.title) slipped \(-worst.change), so that's the area to focus on next.")
        } else if let weakest = latest.categories.min(by: { $0.score < $1.score }) {
            parts.append("\(weakest.title) is your lowest area at \(weakest.score), so it's the best place to focus next.")
        }
        return parts.joined(separator: " ")
    }

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

    /// Keeps the "Scan Reminders" switch honest: it's only on if iOS actually allows notifications.
    func refreshReminderPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if !allowed { remindersOn = false }
    }

    func startScan() {
        isScanning = true
    }

    func goHome() {
        mySkinPath = []
        selectedTab = .mySkin
    }

    /// Reads the straight-on photo from the last scan. Returns nil on success, or a message to
    /// show her. Without a server set up (Backend), it succeeds with sample results.
    func analyzeLastScan() async -> String? {
        latestReport = nil
        guard Backend.isConfigured else {
            lastCaptures = []
            return nil
        }
        guard let photo = lastCaptures.first else {
            return "Let's take a quick scan so we can read your skin."
        }
        let mode = ScanLab.shared.mode
        let context: [String: Any] = ["skin_type": skinType, "skin_goals": skinGoals]

        let report: SkinReport
        do {
            report = try await SkinAnalysisService.analyze(photo, mode: mode, context: context)
        } catch {
            return (error as? SkinAnalysisError)?.message ?? SkinAnalysisError.generic.message
        }
        ScanLab.shared.record(report, mode: mode)
        #if DEBUG
        print("Scan read with \(mode.title), \(report.resolution ?? "?") photo", report.youcamError.map { "(YouCam unavailable: \($0))" } ?? "")
        #endif
        latestReport = report
        lastCaptures = []
        return nil
    }

    /// Finishes a camera scan: records the result and shows the fresh analysis.
    func completeScan() {
        let base = latestScan
        let report = latestReport
        latestReport = nil
        let scan = Scan(
            id: UUID(),
            date: Date(),
            portraitName: nil,
            concerns: report?.topConcerns ?? base?.concerns ?? ["Dehydration", "Fine Lines", "Texture"],
            productsShopped: 0,
            categories: report?.categories ?? SampleData.categories(shift: 2),
            recommendations: SampleData.recommendations,
            consult: report?.consult,
            measures: report?.measures ?? [:]
        )
        scans.insert(scan, at: 0)

        let colors: [Color] = [Palette.sky, Palette.rose, Palette.sage, Palette.gold]
        let color = colors[chartPoints.count % colors.count]
        chartPoints.append(ChartPoint(label: scan.date.formatted(.dateTime.month(.abbreviated).day()), value: scan.overallScore, color: color))

        mySkinPath = [.scan(id: scan.id, isFresh: true)]
        selectedTab = .mySkin
        isScanning = false
    }

    /// True right after a scan that beat the previous one: the best moment to ask for a rating.
    /// Asks at most once every 120 days (Apple also caps the popup at 3 times a year).
    var shouldAskForReviewAfterScan: Bool {
        guard scans.count >= 2, scans[0].overallScore > scans[1].overallScore else { return false }
        let key = "facelift.lastReviewAsk"
        let last = UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
        return Date().timeIntervalSince(last) > 120 * 24 * 60 * 60
    }

    func markReviewAsked() {
        UserDefaults.standard.set(Date(), forKey: "facelift.lastReviewAsk")
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

    /// Replaces "What I'm using" with the edited list from the editor sheet. Blank rows are dropped.
    func saveUsedProducts(_ drafts: [ProductDraft]) {
        let tints = UsedProduct.Tint.allCases
        usedProducts = drafts.enumerated().compactMap { offset, draft in
            let brand = draft.brand.trimmingCharacters(in: .whitespaces)
            let name = draft.name.trimmingCharacters(in: .whitespaces)
            guard !brand.isEmpty || !name.isEmpty else { return nil }
            let existing = usedProducts.first { $0.id == draft.id }
            return UsedProduct(
                id: draft.id,
                brand: brand,
                name: name,
                price: Int(draft.price.filter(\.isNumber)) ?? 0,
                tint: existing?.tint ?? tints[offset % tints.count],
                url: ProductDraft.cleanURL(draft.url)
            )
        }
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
                    date: latestReport == nil ? first.date : Date(),
                    portraitName: first.portraitName,
                    concerns: latestReport?.topConcerns ?? answers.topConcerns,
                    productsShopped: first.productsShopped,
                    categories: latestReport?.categories ?? first.categories,
                    recommendations: first.recommendations,
                    consult: latestReport?.consult ?? first.consult,
                    measures: latestReport?.measures ?? first.measures
                )
            }
        }
        latestReport = nil
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        // A new member lands straight on the results of the scan she just took.
        if !signIn, let first = scans.first {
            mySkinPath = [.scan(id: first.id, isFresh: true)]
        } else {
            mySkinPath = []
        }
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
