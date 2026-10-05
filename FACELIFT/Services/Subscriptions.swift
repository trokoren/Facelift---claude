import Foundation
import Observation
import RevenueCat

/// Membership through RevenueCat: what's for sale (the current offering), buying, restoring,
/// and whether she has the `premium` entitlement.
///
/// Until the RevenueCat key is filled in, nothing here talks to RevenueCat and the paywall
/// falls back to its built-in plans.
@Observable
final class Subscriptions {
    static let shared = Subscriptions()

    /// RevenueCat → Project settings → API keys → the Apple key (starts with "appl_").
    /// A public key, meant to ship inside the app.
    static let apiKey = ""
    /// RevenueCat → Product catalog → Entitlements.
    static let entitlement = "premium"

    static var isAvailable: Bool { !apiKey.isEmpty }

    /// The plans on sale, in the order the paywall shows them (annual first).
    private(set) var packages: [Package] = []
    private(set) var isPremium: Bool = false

    private init() {}

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
                isPremium = info.entitlements[Self.entitlement]?.isActive == true
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
            isPremium = info.entitlements[Self.entitlement]?.isActive == true
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
            isPremium = result.customerInfo.entitlements[Self.entitlement]?.isActive == true
            return isPremium ? .purchased : .failed("Your purchase went through, but we couldn't confirm it yet. Try Restore Purchases in a moment.")
        } catch {
            if (error as NSError).code == ErrorCode.purchaseCancelledError.rawValue { return .cancelled }
            return .failed("The purchase didn't go through. Please try again.")
        }
    }

    /// True when a restore found an active membership.
    func restore() async -> Bool {
        guard Purchases.isConfigured,
              let info = try? await Purchases.shared.restorePurchases() else { return false }
        isPremium = info.entitlements[Self.entitlement]?.isActive == true
        return isPremium
    }

    private func order(_ package: Package) -> Int {
        switch package.packageType {
        case .annual: 0
        case .sixMonth: 1
        case .threeMonth: 2
        case .monthly: 3
        case .weekly: 4
        default: 5
        }
    }
}

// MARK: - Plan wording

extension Package {
    /// "Annual", "Weekly"...
    var planName: String {
        switch packageType {
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
