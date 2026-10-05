import SwiftUI
import RevenueCat

/// Final paywall: before/after, the plan cards and "Start My Skin Journey".
/// Plans and prices come live from RevenueCat once it's set up; until then, the built-in plans.
struct PaywallStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(AppStore.self) private var store
    @State private var isReading = false
    @State private var openLink: URL?
    @State private var isPurchasing = false
    @State private var notice: String?
    private let subscriptions = Subscriptions.shared

    private struct Plan: Identifiable {
        let name: String
        let price: String
        var perMonth: String? = nil
        var badge: String? = nil
        /// What she'll be charged and when, shown under the button (App Store guideline 3.1.2).
        var renewal: String = ""
        /// What's for sale in the App Store (nil for the built-in plans).
        var package: Package? = nil
        var id: String { package?.identifier ?? name }
    }

    /// Live plans from RevenueCat when available, else the built-in ones.
    private var plans: [Plan] {
        let live = subscriptions.packages.map { package -> Plan in
            let isAnnual = package.packageType == .annual
            let intro = package.introLine
            return Plan(
                name: package.planName,
                price: intro.map { "\($0.capitalizedFirst), then \(package.priceLine)" }
                    ?? (isAnnual ? package.storeProduct.localizedPricePerMonth.map { "\($0)/month" } : nil)
                    ?? package.priceLine,
                perMonth: intro == nil && isAnnual ? "\(package.storeProduct.localizedPriceString) billed yearly" : nil,
                badge: isAnnual ? "BEST VALUE" : nil,
                renewal: package.renewalLine,
                package: package
            )
        }
        return live.isEmpty ? fallbackPlans : live
    }

    private let fallbackPlans: [Plan] = [
        Plan(name: "3-Day Trial", price: "Only $3.99 for 3 days", perMonth: "Then $49.99/year",
             renewal: "$3.99 for 3 days, then $49.99/year. Renews automatically. Cancel anytime in Settings."),
        Plan(name: "Weekly", price: "$8.99/week",
             renewal: "$8.99/week. Renews automatically. Cancel anytime in Settings."),
        Plan(name: "Annual", price: "$4.16/month", perMonth: "$49.99 billed yearly", badge: "SAVE 90%",
             renewal: "$49.99/year. Renews automatically. Cancel anytime in Settings.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        PaywallPhoto(imageName: "onb_before", label: "BEFORE", labelFill: Color(hex: 0x6E6866))
                        PaywallPhoto(imageName: "onb_after", label: "AFTER", labelFill: Palette.rose)
                    }
                    .padding(.top, 12)

                    Text("Improve your skin\nin 4 weeks.")
                        .font(FLFont.serif(30))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                        .padding(.top, 20)
                    Text("Get 40% off FACELIFT")
                        .font(FLFont.sans(15.5))
                        .foregroundStyle(Palette.body)
                        .padding(.top, 6)

                    VStack(spacing: 12) {
                        ForEach(plans) { plan in
                            planRow(plan)
                        }
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("What you'll get")
                            .font(FLFont.sans(14, .semibold))
                            .foregroundStyle(Palette.ink)
                        benefit("Your full skin consultation: 7 scores")
                        benefit("Products matched to your skin and budget")
                        benefit("Weekly scans to track your progress")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 26)
                    .padding(.horizontal, 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 12) {
                OnboardingCTA(title: isPurchasing ? "One moment…" : "Start My Skin Journey", isEnabled: !isPurchasing) {
                    startTapped()
                }
                Text(plans.first { $0.id == flow.answers.selectedPlan }?.renewal ?? "Renews automatically. Cancel anytime in Settings.")
                    .font(FLFont.sans(12.5))
                    .foregroundStyle(Palette.mist)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: flow.answers.selectedPlan)
                HStack(spacing: 6) {
                    if Subscriptions.isAvailable {
                        Button { restoreTapped() } label: {
                            Text("Restore")
                                .underline()
                                .frame(minHeight: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isPurchasing)
                        Text("·")
                    }
                    legalLink("Terms", LegalLinks.terms)
                    Text("·")
                    legalLink("Privacy", LegalLinks.privacyPolicy)
                }
                .font(FLFont.sans(12))
                .foregroundStyle(Palette.mist)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: flow.answers.selectedPlan)
        .task {
            await subscriptions.refresh()
            selectDefaultPlan()
        }
        .onChange(of: subscriptions.packages.count) { _, _ in selectDefaultPlan() }
        .alert("Membership", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notice ?? "")
        }
        .sheet(item: $openLink) { url in
            SafariSheet(url: url)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isReading) {
            FirstReadView {
                isReading = false
                store.completeOnboarding(with: flow.answers, signIn: false)
            }
            .environment(store)
        }
    }

    /// Keeps a valid plan selected: the annual plan (listed first) when the live plans arrive.
    private func selectDefaultPlan() {
        guard !plans.contains(where: { $0.id == flow.answers.selectedPlan }) else { return }
        flow.answers.selectedPlan = plans.first(where: { $0.badge != nil })?.id ?? plans.first?.id ?? ""
    }

    private func startTapped() {
        guard let package = plans.first(where: { $0.id == flow.answers.selectedPlan })?.package else {
            // No live plans (RevenueCat not set up yet): continue as before.
            beginMembership()
            return
        }
        isPurchasing = true
        Task {
            let outcome = await subscriptions.purchase(package)
            isPurchasing = false
            switch outcome {
            case .purchased: beginMembership()
            case .cancelled: break
            case .failed(let message): notice = message
            }
        }
    }

    private func restoreTapped() {
        isPurchasing = true
        Task {
            let found = await subscriptions.restore()
            isPurchasing = false
            if found {
                beginMembership()
            } else {
                notice = "We couldn't find an active membership for this Apple ID."
            }
        }
    }

    /// Her scan is read now, right after she subscribes, using her answers.
    private func beginMembership() {
        store.skinType = flow.answers.resolvedSkinType
        store.skinGoals = flow.answers.skinGoals
        store.saveProfile(flow.answers)
        isReading = true
    }

    private func legalLink(_ title: String, _ url: URL) -> some View {
        Button { openLink = url } label: {
            Text(title)
                .underline()
                .frame(minHeight: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func benefit(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.rose)
            Text(text)
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.body)
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        let isSelected = flow.answers.selectedPlan == plan.id
        return Button {
            flow.answers.selectedPlan = plan.id
        } label: {
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
    }
}

private struct PaywallPhoto: View {
    let imageName: String
    let label: String
    let labelFill: Color

    var body: some View {
        Color(hex: 0xE9E4E0)
            .aspectRatio(1.5, contentMode: .fit)
            .overlay {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: 26, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Text(label)
                    .font(FLFont.sans(11.5, .semibold))
                    .tracking(2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .frame(height: 30)
                    .background(labelFill, in: Capsule())
                    .padding(14)
            }
    }
}
