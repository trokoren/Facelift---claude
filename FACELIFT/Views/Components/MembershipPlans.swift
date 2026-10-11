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

    /// Live plans from RevenueCat when available, else the built-in ones.
    /// `showsIntro` is off on the renew screen: Apple gives the free trial only once, and a
    /// returning member has already had it.
    static func current(from packages: [Package], showsIntro: Bool = true) -> [MembershipPlan] {
        let live = packages.map { package -> MembershipPlan in
            let isAnnual = package.packageType == .annual
            let intro = showsIntro ? package.introLine : nil
            return MembershipPlan(
                name: package.planName,
                price: intro.map { "\($0.capitalizedFirst), then \(package.priceLine)" }
                    ?? (isAnnual ? package.storeProduct.localizedPricePerMonth.map { "\($0)/month" } : nil)
                    ?? package.priceLine,
                perMonth: intro == nil && isAnnual ? "\(package.storeProduct.localizedPriceString) billed yearly" : nil,
                badge: isAnnual ? "BEST VALUE" : nil,
                renewal: showsIntro ? package.renewalLine : "\(package.priceLine). Renews automatically. Cancel anytime in Settings.",
                package: package
            )
        }
        if !live.isEmpty { return live }
        return showsIntro ? fallback : fallbackWithoutIntro
    }

    /// Mirrors the App Store setup: Annual with a free 3-day trial, and Weekly.
    /// Worded the same way the live plans are, so the screen looks alike either way.
    static let fallback: [MembershipPlan] = [
        MembershipPlan(name: "Annual", price: "3 days free, then $49.99/year", badge: "BEST VALUE",
                       renewal: "3 days free, then $49.99/year. Renews automatically. Cancel anytime in Settings."),
        MembershipPlan(name: "Weekly", price: "$8.99/week",
                       renewal: "$8.99/week. Renews automatically. Cancel anytime in Settings.")
    ]

    static let fallbackWithoutIntro: [MembershipPlan] = [
        MembershipPlan(name: "Annual", price: "$4.17/month", perMonth: "$49.99 billed yearly", badge: "BEST VALUE",
                       renewal: "$49.99/year. Renews automatically. Cancel anytime in Settings."),
        MembershipPlan(name: "Weekly", price: "$8.99/week",
                       renewal: "$8.99/week. Renews automatically. Cancel anytime in Settings.")
    ]

    /// The plan to select first: the one with a badge (annual), else the first.
    static func defaultID(in plans: [MembershipPlan]) -> String {
        plans.first(where: { $0.badge != nil })?.id ?? plans.first?.id ?? ""
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
