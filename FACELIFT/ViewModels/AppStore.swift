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
    /// Her onboarding answers, used to personalize every consultation.
    var profile: SkinProfile? = SkinProfile.load()

    /// Her scans, newest first. Saved on this phone after every change; until her first real
    /// scan, the app shows its placeholder scans (never saved).
    var scans: [Scan] = ScanArchive.load() ?? SampleData.scans {
        didSet { ScanArchive.save(scans) }
    }
    /// "What I'm using", saved on this phone.
    var usedProducts: [UsedProduct] = LocalFile.load([UsedProduct].self, from: "products.json") ?? SampleData.usedProducts {
        didSet { LocalFile.save(usedProducts, to: "products.json") }
    }
    /// Her "How's it going?" answers, newest last, saved on this phone.
    var checkIns: [ProductCheckIn] = LocalFile.load([ProductCheckIn].self, from: "checkins.json") ?? [] {
        didSet { LocalFile.save(checkIns, to: "checkins.json") }
    }

    /// The Skin Score over time, oldest first, from her real scans (placeholder points until
    /// she has one).
    var chartPoints: [ChartPoint] {
        let real = scans.filter { !$0.isSample }.reversed()
        guard !real.isEmpty else { return SampleData.chartPoints }
        let colors: [Color] = [Palette.sky, Palette.rose, Palette.sage, Palette.gold]
        return real.enumerated().map { index, scan in
            ChartPoint(id: scan.id,
                       label: scan.date.formatted(.dateTime.month(.abbreviated).day()),
                       value: scan.overallScore,
                       color: colors[index % colors.count],
                       date: scan.date)
        }
    }

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

    /// Skin type for her profile: what her latest consultation found, else what she told us.
    var profileSkinType: String {
        if let measured = scans.first(where: { !$0.isSample })?.measuredSkinType { return measured }
        if let chosen = profile?.skinType, chosen != "I don't really know" { return chosen }
        return skinType
    }

    /// True once she has at least one real scan (the chart stops showing placeholders).
    var hasRealScans: Bool {
        scans.contains { !$0.isSample }
    }

    /// Opens a past consultation from the progress chart.
    func openScan(_ id: UUID) {
        guard scan(with: id) != nil else { return }
        mySkinPath = [.scan(id: id, isFresh: false)]
        selectedTab = .mySkin
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

    /// Her answers, routine and product feedback, sent with each consultation.
    private var consultContext: [String: Any] {
        var context: [String: Any] = profile?.context ?? [:]
        if profile == nil { context["skin_type_she_chose"] = skinType }
        context["skin_goals"] = skinGoals
        let products = usedProducts.map { "\($0.brand) \($0.name)".trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if !products.isEmpty { context["products_she_uses"] = products }
        let feedback = productFeedback
        if !feedback.isEmpty { context["product_feedback"] = feedback }
        return context
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
        var context = consultContext
        // Her city and weather get named only in her first consultation, never again.
        let consultsKey = "facelift.consultCount"
        context["first_consult"] = UserDefaults.standard.integer(forKey: consultsKey) == 0

        let report: SkinReport
        do {
            report = try await SkinAnalysisService.analyze(photo, mode: mode, context: context)
        } catch {
            return (error as? SkinAnalysisError)?.message ?? SkinAnalysisError.generic(String(describing: error)).message
        }
        ScanLab.shared.record(report, mode: mode)
        if report.consult != nil {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: consultsKey) + 1, forKey: consultsKey)
        }
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
        // Her first real scan replaces the placeholders.
        scans = [scan] + scans.filter { !$0.isSample }

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
                url: ProductDraft.cleanURL(draft.url),
                addedAt: existing?.addedAt ?? Date()
            )
        }
    }

    func removeUsed(_ product: UsedProduct) {
        usedProducts.removeAll { $0.id == product.id }
    }

    // MARK: Product check-ins

    /// Days between "How's it going?" questions about the same product.
    private static let checkInInterval: Double = 10

    /// The product to ask about now, if any: the one waiting longest, once it has been in her
    /// routine (or since she last answered) for about 10 days. At most one question a day.
    var dueCheckIn: UsedProduct? {
        let now = Date()
        let day: Double = 86_400
        // Closed with the X: quiet for about 2.5 weeks.
        if let snoozed = UserDefaults.standard.object(forKey: Self.checkInSnoozeKey) as? Date, now < snoozed { return nil }
        // Answered one recently: give her a few days before the next question.
        if let last = checkIns.last, now.timeIntervalSince(last.date) < 3 * day { return nil }
        let waiting = usedProducts.compactMap { product -> (UsedProduct, Date)? in
            let last = latestCheckIn(for: product)
            #if DEBUG
            // Test builds: ask right away about anything never checked in on, so it can be tried.
            if last == nil { return (product, .distantPast) }
            #endif
            let since = last?.date ?? product.addedAt
            guard now.timeIntervalSince(since) >= Self.checkInInterval * day else { return nil }
            return (product, since)
        }
        return waiting.min { $0.1 < $1.1 }?.0
    }

    private static let checkInSnoozeKey = "facelift.checkInSnoozedUntil"

    /// She closed the question without answering: don't ask again for about 2.5 weeks.
    func snoozeCheckIns() {
        UserDefaults.standard.set(Date().addingTimeInterval(18 * 86_400), forKey: Self.checkInSnoozeKey)
    }

    func latestCheckIn(for product: UsedProduct) -> ProductCheckIn? {
        checkIns.last { $0.productID == product.id }
    }

    @discardableResult
    func recordCheckIn(_ product: UsedProduct, answer: ProductCheckIn.Answer) -> UUID {
        let entry = ProductCheckIn(productID: product.id, productName: "\(product.brand) \(product.name)".trimmingCharacters(in: .whitespaces), answer: answer)
        checkIns.append(entry)
        return entry.id
    }

    func updateCheckInNote(_ id: UUID, note: String) {
        guard let index = checkIns.firstIndex(where: { $0.id == id }) else { return }
        checkIns[index].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A short, warm reply to her answer, plus how her Skin Score moved since she added it.
    func checkInReply(for product: UsedProduct, answer: ProductCheckIn.Answer) -> String {
        let base: String
        switch answer {
        case .loving:
            base = "Love that. Keep it steady and we'll keep watching your scans for the change."
        case .unsure:
            base = "Totally normal. Most products take 4 to 6 weeks to show what they can do, so give it a little longer and we'll check back."
        case .irritating:
            base = "Thanks for telling us. Pause it and let your skin settle for a few days. We'll steer your next consultation around it."
        case .stopped:
            base = "Got it. We won't build your routine around it anymore."
        }
        guard let change = scoreChange(since: product.addedAt), change != 0 else { return base }
        let points = abs(change) == 1 ? "point" : "points"
        let movement = change > 0
            ? "Your Skin Score is up \(change) \(points) since you added it."
            : "Your Skin Score is down \(-change) \(points) since you added it, which can happen while skin adjusts."
        return base + " " + movement
    }

    /// Skin Score now versus her last scan before a date. Nil without a scan on each side.
    private func scoreChange(since date: Date) -> Int? {
        let real = scans.filter { !$0.isSample }
        guard let before = real.first(where: { $0.date <= date }),
              let latest = real.first, latest.date > date else { return nil }
        return latest.overallScore - before.overallScore
    }

    /// Her latest answer per product (last 90 days), for the next consultation.
    private var productFeedback: [String] {
        let cutoff = Date().addingTimeInterval(-90 * 86_400)
        var seen = Set<UUID>()
        return checkIns.reversed().compactMap { entry in
            guard entry.date >= cutoff, !seen.contains(entry.productID) else { return nil }
            seen.insert(entry.productID)
            let note = entry.note.isEmpty ? "" : " (\(entry.note))"
            return "\(entry.productName): \(entry.answer.label.lowercased())\(note)"
        }
    }

    func toggleGoal(_ goal: String) {
        if skinGoals.contains(goal) {
            skinGoals.removeAll { $0 == goal }
        } else {
            skinGoals.append(goal)
        }
    }

    func deleteScan(_ id: UUID) {
        scans.removeAll { $0.id == id }
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
    /// Keeps her onboarding answers for every future consultation.
    func saveProfile(_ answers: OnboardingAnswers) {
        let profile = SkinProfile(answers)
        profile.save()
        self.profile = profile
    }

    func completeOnboarding(with answers: OnboardingAnswers, signIn: Bool) {
        if !signIn {
            saveProfile(answers)
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
                    measures: latestReport?.measures ?? first.measures,
                    isSample: latestReport == nil && first.isSample
                )
                if !scans[0].isSample {
                    scans = [scans[0]] + scans.dropFirst().filter { !$0.isSample }
                }
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
