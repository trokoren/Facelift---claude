import Foundation
import Observation
import RevenueCat

/// Membership through RevenueCat: what's for sale (the current offering), buying, restoring,
/// and whether she has the `facelift_pro` entitlement.
///
/// Until a RevenueCat key is filled in, nothing here talks to RevenueCat and the paywall
/// falls back to its built-in plans.
@Observable
final class Subscriptions {
    static let shared = Subscriptions()

    /// RevenueCat → Project settings → API keys. Public keys, meant to ship inside the app.
    /// Test builds use the Test Store key (fake purchases, no App Store needed). Release builds
    /// need the Apple key (starts with "appl_"); the Test Store key must never ship.
    #if DEBUG
    static let apiKey = "test_bsbaFTmTnPEmpTxQfEcMBQGuieW"
    #else
    static let apiKey = ""
    #endif
    /// RevenueCat → Product catalog → Entitlements.
    static let entitlement = "facelift_pro"

    static var isAvailable: Bool { !apiKey.isEmpty }

    /// The plans on sale, in the order the paywall shows them (see `order`).
    private(set) var packages: [Package] = []
    private(set) var isPremium: Bool = false
    /// True once RevenueCat has told us her membership status this launch (from its cache
    /// or the network). Until then we don't lock anything, so a member never sees a flash
    /// of the locked screens.
    private(set) var hasChecked: Bool = false

    /// True while her membership is in its free trial (RevenueCat's period type).
    private(set) var isTrialPeriod: Bool = false

    /// When her free trial becomes a paid membership (nil when she isn't on a trial).
    /// Used for the "trial ends tomorrow" reminder.
    private(set) var trialEndDate: Date?

    #if DEBUG
    /// Scan Lab switch: pretend her membership has lapsed, to see the locked screens.
    var debugLapsed: Bool = UserDefaults.standard.bool(forKey: "facelift.debugLapsed") {
        didSet { UserDefaults.standard.set(debugLapsed, forKey: "facelift.debugLapsed") }
    }
    /// Scan Lab switch: pretend she's on the free trial, to see the 1-a-day limit and its wording.
    var debugTrial: Bool = UserDefaults.standard.bool(forKey: "facelift.debugTrial") {
        didSet { UserDefaults.standard.set(debugTrial, forKey: "facelift.debugTrial") }
    }
    #endif

    /// She's on the free trial: 1 scan a day until she's a paying member.
    var isInTrial: Bool {
        #if DEBUG
        if debugTrial { return true }
        #endif
        return Self.isAvailable && isPremium && isTrialPeriod
    }

    /// Her membership has ended: new scans, consults, picks and progress are locked until
    /// she renews. Only once RevenueCat is live and has answered; her scans are never deleted.
    var isLapsed: Bool {
        #if DEBUG
        if debugLapsed { return true }
        #endif
        return Self.isAvailable && hasChecked && !isPremium
    }

    private init() {}

    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlement]
        isPremium = entitlement?.isActive == true
        isTrialPeriod = entitlement?.periodType == .trial
        trialEndDate = isTrialPeriod && entitlement?.willRenew == true ? entitlement?.expirationDate : nil
        hasChecked = true
    }

    /// Call once at launch.
    func configure() {
        guard Self.isAvailable, !Purchases.isConfigured else { return }
        #if DEBUG
        Purchases.logLevel = .warn
        #endif
        Purchases.configure(withAPIKey: Self.apiKey)
        // Apple Search Ads attribution (no tracking prompt needed for this).
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        Task { await refresh() }
        Task {
            for await info in Purchases.shared.customerInfoStream {
                apply(info)
            }
        }
    }

    /// Loads the current offering's plans.
    func refresh() async {
        guard Purchases.isConfigured else { return }
        if let offering = try? await Purchases.shared.offerings().current {
            packages = offering.availablePackages.sorted { order($0) < order($1) }
        }
        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }
    }

    enum Outcome {
        case purchased
        case cancelled
        case failed(String)
    }

    func purchase(_ package: Package) async -> Outcome {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            apply(result.customerInfo)
            Analytics.track(.purchaseCompleted, ["product_id": package.storeProduct.productIdentifier, "free_trial": package.hasFreeTrial])
            return isPremium ? .purchased : .failed("Your purchase went through, but we couldn't confirm it yet. Try Restore Purchases in a moment.")
        } catch {
            if (error as NSError).code == ErrorCode.purchaseCancelledError.rawValue { return .cancelled }
            return .failed("The purchase didn't go through. Please try again.")
        }
    }

    /// Ties her membership to her FACELIFT account, so it follows her to a new phone.
    func identify(_ accountID: String) async {
        Analytics.identify(accountID)
        guard Purchases.isConfigured,
              let result = try? await Purchases.shared.logIn(accountID) else { return }
        apply(result.customerInfo)
    }

    /// After sign out or account deletion: back to an anonymous buyer on this phone.
    func forget() async {
        Analytics.reset()
        guard Purchases.isConfigured, !Purchases.shared.isAnonymous,
              let info = try? await Purchases.shared.logOut() else { return }
        apply(info)
    }

    /// True when a restore found an active membership.
    func restore() async -> Bool {
        guard Purchases.isConfigured,
              let info = try? await Purchases.shared.restorePurchases() else { return false }
        apply(info)
        if isPremium { Analytics.track(.purchaseRestored) }
        return isPremium
    }

    /// Free trial first, then weekly, then annual (and anything else after).
    private func order(_ package: Package) -> Int {
        if package.hasFreeTrial { return -1 }
        if package.isWeekly { return 0 }
        if package.isYearly { return 1 }
        switch package.packageType {
        case .sixMonth: return 2
        case .threeMonth: return 3
        case .monthly: return 4
        default: return 5
        }
    }
}

// MARK: - Plan wording

extension Package {
    /// Read from the product's billing period, not the package name, so a second yearly plan
    /// (the one without the trial) still counts as yearly whatever it's called in RevenueCat.
    var isYearly: Bool {
        guard let period = storeProduct.subscriptionPeriod else { return false }
        return (period.unit == .year && period.value == 1) || (period.unit == .month && period.value == 12)
    }

    var isWeekly: Bool {
        guard let period = storeProduct.subscriptionPeriod else { return false }
        return (period.unit == .week && period.value == 1) || (period.unit == .day && period.value == 7)
    }

    /// The plan comes with a free trial (Apple's introductory offer).
    var hasFreeTrial: Bool { storeProduct.introductoryDiscount?.paymentMode == .freeTrial }

    /// "3-Day Free Trial"
    var trialName: String? {
        guard hasFreeTrial, let period = storeProduct.introductoryDiscount?.subscriptionPeriod else { return nil }
        return "\(period.value)-\(period.unitName.capitalized) Free Trial"
    }

    /// The yearly price split into months, rounded down so it never overstates: "$4.16".
    var monthlyEquivalent: String? {
        guard isYearly else { return nil }
        var perMonth = storeProduct.price / 12
        var rounded = Decimal()
        NSDecimalRound(&rounded, &perMonth, 2, .down)
        let formatter = storeProduct.priceFormatter ?? {
            let f = NumberFormatter()
            f.numberStyle = .currency
            return f
        }()
        return formatter.string(from: rounded as NSDecimalNumber)
    }

    /// "Annual", "Weekly"...
    var planName: String {
        if isYearly { return "Annual" }
        if isWeekly { return "Weekly" }
        return switch packageType {
        case .annual: "Annual"
        case .sixMonth: "6 Months"
        case .threeMonth: "3 Months"
        case .monthly: "Monthly"
        case .weekly: "Weekly"
        default: storeProduct.localizedTitle
        }
    }

    /// "$49.99/year"
    var priceLine: String {
        guard let period = storeProduct.subscriptionPeriod else { return storeProduct.localizedPriceString }
        return "\(storeProduct.localizedPriceString)/\(period.shortName)"
    }

    /// Her intro offer, if she's eligible-looking: "3 days free", "$2.99 for 1 month".
    var introLine: String? {
        guard let intro = storeProduct.introductoryDiscount else { return nil }
        let length = intro.subscriptionPeriod.longName
        switch intro.paymentMode {
        case .freeTrial: return "\(length) free"
        case .payUpFront: return "\(intro.localizedPriceString) for \(length)"
        case .payAsYouGo: return "\(intro.localizedPriceString)/\(intro.subscriptionPeriod.shortName) to start"
        @unknown default: return nil
        }
    }

    /// What she'll be charged and when (App Store guideline 3.1.2).
    var renewalLine: String {
        if let intro = introLine {
            return "\(intro), then \(priceLine). Renews automatically. Cancel anytime in Settings."
        }
        return "\(priceLine). Renews automatically. Cancel anytime in Settings."
    }
}

private extension SubscriptionPeriod {
    var unitName: String {
        switch unit {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        @unknown default: "period"
        }
    }

    /// "year", or "3 months"
    var shortName: String { value == 1 ? unitName : "\(value) \(unitName)s" }
    /// "1 year", "3 days"
    var longName: String { "\(value) \(unitName)\(value == 1 ? "" : "s")" }
}
