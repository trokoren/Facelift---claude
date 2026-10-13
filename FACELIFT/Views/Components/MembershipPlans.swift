import SwiftUI
import RevenueCat

/// One plan on a paywall. Shared by the onboarding paywall and the renew screen, so both
/// always show the same RevenueCat offering (and any paywall test runs on both).
struct MembershipPlan: Identifiable {
    let name: String
    let price: String
    var perMonth: String? = nil
    var badge: String? = nil
    /// What she'll be charged and when, shown under the button (App Store guideline 3.1.2).
    var renewal: String = ""
    /// What's for sale in the App Store (nil for the built-in plans).
    var package: Package? = nil
    var id: String { package?.identifier ?? name }

    /// What the free trial includes, shown on the trial plan and wherever the trial limit applies.
    static let trialScanNote = "Your free trial includes 1 scan a day."
    /// The line on the trial plan card: the scan limit, and the promise that we'll remind her
    /// before she's charged (the reminder is scheduled in `Reminders`).
    static let trialPlanNote = "1 scan a day. We'll remind you before it ends."

    /// Live plans from RevenueCat when available, else the built-in ones.
    /// Order: free trial, weekly, annual. `showsIntro` is off on the renew screen: Apple gives
    /// the free trial only once, and a returning member has already had it.
    static func current(from packages: [Package], showsIntro: Bool = true) -> [MembershipPlan] {
        let weekly = packages.first { $0.isWeekly }
        let live = packages.compactMap { package -> MembershipPlan? in
            if package.hasFreeTrial {
                guard showsIntro else { return nil }
                return MembershipPlan(
                    name: package.trialName ?? "Free Trial",
                    price: "Free, then \(package.priceLine)",
                    perMonth: trialPlanNote,
                    renewal: package.renewalLine,
                    package: package
                )
            }
            if package.isYearly {
                return MembershipPlan(
                    name: package.planName,
                    price: package.monthlyEquivalent.map { "\($0)/month" } ?? package.priceLine,
                    perMonth: "\(package.storeProduct.localizedPriceString) billed yearly",
                    badge: savingsBadge(annual: package, weekly: weekly),
                    renewal: "\(package.priceLine). Renews automatically. Cancel anytime in Settings.",
                    package: package
                )
            }
            return MembershipPlan(
                name: package.planName,
                price: package.priceLine,
                renewal: "\(package.priceLine). Renews automatically. Cancel anytime in Settings.",
                package: package
            )
        }
        if !live.isEmpty { return live }
        return showsIntro ? fallback : fallbackWithoutIntro
    }

    /// "SAVE 89%": annual against a year of weekly, rounded down so it never overstates.
    private static func savingsBadge(annual: Package, weekly: Package?) -> String? {
        guard let weekly else { return "BEST VALUE" }
        let yearOfWeekly = (weekly.storeProduct.price as NSDecimalNumber).doubleValue * 52
        let annualPrice = (annual.storeProduct.price as NSDecimalNumber).doubleValue
        guard yearOfWeekly > 0, annualPrice < yearOfWeekly else { return "BEST VALUE" }
        return "SAVE \(Int((1 - annualPrice / yearOfWeekly) * 100))%"
    }

    /// Mirrors the App Store setup: the free 3-day trial (converts to annual), weekly, annual.
    static let fallback: [MembershipPlan] = [
        MembershipPlan(name: "3-Day Free Trial", price: "Free, then $49.99/year", perMonth: trialPlanNote,
                       renewal: "3 days free, then $49.99/year. Renews automatically. Cancel anytime in Settings."),
        MembershipPlan(name: "Weekly", price: "$8.99/week",
                       renewal: "$8.99/week. Renews automatically. Cancel anytime in Settings."),
        MembershipPlan(name: "Annual", price: "$4.16/month", perMonth: "$49.99 billed yearly", badge: "SAVE 89%",
                       renewal: "$49.99/year. Renews automatically. Cancel anytime in Settings.")
    ]

    static let fallbackWithoutIntro: [MembershipPlan] = Array(fallback.dropFirst())

    /// The plan to select first: the free trial when there is one, else the one with a badge.
    static func defaultID(in plans: [MembershipPlan]) -> String {
        plans.first(where: { $0.package?.hasFreeTrial == true || $0.name.contains("Free Trial") })?.id
            ?? plans.first(where: { $0.badge != nil })?.id
            ?? plans.first?.id ?? ""
    }
}

/// A selectable plan card.
struct MembershipPlanRow: View {
    let plan: MembershipPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(isSelected ? Palette.rose : Color(hex: 0xD6D2CF), lineWidth: 2.2)
                    if isSelected {
                        Circle().fill(Palette.rose).padding(5)
                    }
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 10) {
                        Text(plan.name)
                            .font(FLFont.sans(17, .medium))
                            .foregroundStyle(Palette.ink)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(FLFont.sans(11, .semibold))
                                .tracking(0.8)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .frame(height: 22)
                                .background(Palette.rose, in: Capsule())
                        }
                    }
                    Text(plan.price)
                        .font(FLFont.sans(15, .medium))
                        .foregroundStyle(Palette.body)
                    if let perMonth = plan.perMonth {
                        Text(perMonth)
                            .font(FLFont.sans(13.5))
                            .foregroundStyle(Palette.stone)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .frame(minHeight: 68)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Color(hex: 0xFBF1EF) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Palette.rose : Color(hex: 0xE8E3DF), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.easeOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(CardPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
