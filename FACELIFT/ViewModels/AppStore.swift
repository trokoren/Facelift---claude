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
    var usedProducts: [UsedProduct] = LocalFile.load([UsedProduct].self, from: "products.json") ?? [] {
        didSet { LocalFile.save(usedProducts, to: "products.json") }
    }
    /// Her "How's it going?" answers, newest last, saved on this phone.
    var checkIns: [ProductCheckIn] = LocalFile.load([ProductCheckIn].self, from: "checkins.json") ?? [] {
        didSet { LocalFile.save(checkIns, to: "checkins.json") }
    }
    /// The deeper progress review, rewritten only when one is due.
    var progressReview: ProgressReview? = LocalFile.load(ProgressReview.self, from: "progress_review.json") {
        didSet { if let progressReview { LocalFile.save(progressReview, to: "progress_review.json") } }
    }
    var isWritingReview: Bool = false

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

    var skinType: String = "Combination"
    var skinGoals: [String] = ["Anti-aging", "Hydration"]
    var remindersOn: Bool = true

    var latestScan: Scan? { scans.first }

    /// The short "what changed" note on the Progress card (four lines at most). Compares the
    /// newest scan with the one before it, and is honest about scans taken close together.
    var progressUpdate: String {
        guard let latest = scans.first else {
            return "Scan your skin to start tracking how it changes."
        }
        guard scans.count > 1 else {
            return "This first scan is your baseline. Scan again in a few days and we'll show you what's changing."
        }
        let previous = scans[1]
        let now = latest.overallScore
        let before = previous.overallScore
        let delta = now - before
        let close = latest.date.timeIntervalSince(previous.date) < 3 * 86_400
        let changes = Self.areaChanges(latest, previous)
        let best = changes.max { $0.change < $1.change }
        let weakest = changes.min { $0.score < $1.score }
        let focus = weakest.map { " \($0.name) is your lowest area at \($0.score), so it's the best place to focus." } ?? ""

        if abs(delta) <= 2 {
            return "Your Skin Score is steady at \(now)." + (close ? " Skin changes over weeks, so scans a few days apart show progress more clearly than daily ones." : focus)
        }
        if delta > 0 {
            if close {
                return "Your Skin Score is up \(delta) since your last scan (\(before) to \(now)). Readings shift a little day to day, so your next few scans will confirm the trend."
            }
            let lead = best.map { $0.change > 0 ? " \($0.name) improved the most, up \($0.change)." : "" } ?? ""
            return "Your Skin Score is up \(delta) since your last scan (\(before) to \(now))." + lead
        }
        return "Your Skin Score dipped \(-delta) since your last scan (\(before) to \(now))." + (close
            ? " Readings close together move with sleep, hydration and light, so one scan isn't a trend."
            : " Small swings are normal with sleep, stress and your cycle.")
    }

    /// Per-area change between two scans: measurements on current scans, categories on older ones.
    private static func areaChanges(_ latest: Scan, _ previous: Scan) -> [(name: String, change: Int, score: Int)] {
        if !latest.measures.isEmpty, !previous.measures.isEmpty {
            return Measure.order.compactMap { key in
                guard let now = latest.measures[key], let before = previous.measures[key] else { return nil }
                return (Measure.name(key), now - before, now)
            }
        }
        return latest.categories.compactMap { category in
            guard let old = previous.categories.first(where: { $0.kind == category.kind }) else { return nil }
            return (category.title, category.score - old.score, category.score)
        }
    }

    // MARK: Progress review (the deeper read behind the card)

    /// Real, measured scans, oldest first.
    private var reviewableScans: [Scan] {
        scans.filter { !$0.isSample && !$0.measures.isEmpty }.sorted { $0.date < $1.date }
    }

    /// Why a new review should be written now, or nil if the current one still stands.
    /// - first: her first review, once she has two measured scans.
    /// - five_scans: a check-in every 5 scans, even when little has changed.
    /// - meaningful_change: the score moved 5+ points (or one area 10+) over at least a week.
    ///   Big jumps over a few days are treated as day-to-day variation and wait.
    /// - monthly: 30+ days since the last review, with at least one new scan.
    var progressReviewReason: String? {
        let real = reviewableScans
        guard real.count >= 2, let latest = real.last else { return nil }
        guard let review = progressReview else { return "first" }
        guard review.scanID != latest.id else { return nil }
        let anchor = real.first { $0.id == review.scanID } ?? real[0]
        let newScans = real.filter { $0.date > anchor.date }.count
        let days = latest.date.timeIntervalSince(anchor.date) / 86_400
        let overall = abs(latest.overallScore - anchor.overallScore)
        let area = Measure.order.compactMap { key -> Int? in
            guard let now = latest.measures[key], let before = anchor.measures[key] else { return nil }
            return abs(now - before)
        }.max() ?? 0
        if newScans >= 5 { return "five_scans" }
        if days >= 7 && (overall >= 5 || area >= 10) { return "meaningful_change" }
        if Date().timeIntervalSince(review.date) >= 30 * 86_400 && newScans >= 1 { return "monthly" }
        return nil
    }

    /// Writes a new review in the background when one is due. Safe to call often.
    func refreshProgressReviewIfDue() async {
        guard !isWritingReview, let reason = progressReviewReason else { return }
        let real = reviewableScans
        guard let latest = real.last else { return }
        let anchorIndex = progressReview.flatMap { review in real.firstIndex { $0.id == review.scanID } } ?? 0
        var context: [String: Any] = ["skin_type": profileSkinType]
        let products = usedProducts.map { "\($0.brand) \($0.name)".trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if !products.isEmpty { context["products"] = products }
        if !productFeedback.isEmpty { context["product_feedback"] = productFeedback }

        isWritingReview = true
        defer { isWritingReview = false }
        do {
            var review = try await ProgressReviewService.write(scans: real, anchorIndex: anchorIndex, reason: reason, context: context)
            review.date = Date()
            review.scanID = latest.id
            review.scanCount = real.count
            progressReview = review
        } catch {
            #if DEBUG
            print("progress review failed:", error)
            #endif
        }
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
        // Skin type stays steady: re-read every 4th scan, otherwise reuse the established one.
        let skinTypeRecord = SkinTypeRecord.load()
        let reassess = SkinTypeRecord.isDue
        context["reassess_skin_type"] = reassess
        if let skinTypeRecord {
            context["established_skin_type"] = ["label": skinTypeRecord.label, "explanation": skinTypeRecord.explanation]
        }

        var report: SkinReport
        do {
            report = try await SkinAnalysisService.analyze(photo, mode: mode, context: context)
        } catch {
            return (error as? SkinAnalysisError)?.message ?? SkinAnalysisError.generic(String(describing: error)).message
        }
        ScanLab.shared.record(report, mode: mode)
        ScanAllowance.recordScan()
        if let consult = report.consult {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: consultsKey) + 1, forKey: consultsKey)
            if reassess || skinTypeRecord == nil {
                // Re-measured: note whether it held or moved since her last reading.
                if let earlier = skinTypeRecord {
                    let before = Consult.SkinType.base(earlier.label)
                    let now = Consult.SkinType.base(consult.skinType.label)
                    let changed = before != nil && now != nil && before != now
                    report.consult?.skinType.status = changed ? "changed" : "confirmed"
                    report.consult?.skinType.previous = changed ? before : nil
                }
                report.consult?.skinType.measuredOn = Date()
                SkinTypeRecord(label: consult.skinType.label, explanation: consult.skinType.explanation, date: Date(), scansSince: 0).save()
            } else if var record = skinTypeRecord {
                report.consult?.skinType.measuredOn = record.date
                record.scansSince += 1
                record.save()
            }
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
        Task { await refreshProgressReviewIfDue() }
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

    /// Counts a shop tap on a routine step. Generic steps aren't added to "What I'm using".
    func recordRoutineShop(scanID: UUID) {
        if let index = scans.firstIndex(where: { $0.id == scanID }) {
            scans[index].productsShopped += 1
        }
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

    /// Deletes every scan on this phone, plus what was built from them (her progress review
    /// and stored skin type). Daily scan counts are kept, so deleting doesn't give scans back.
    func deleteHistory() {
        scans = []
        progressReview = nil
        LocalFile.remove("progress_review.json")
        SkinTypeRecord.clear()
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
