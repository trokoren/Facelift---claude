import SwiftUI

/// The paywall for a returning member whose membership has ended. Opens from any locked
/// screen. Uses the same RevenueCat offering as the onboarding paywall.
struct RenewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var store
    @State private var selectedPlan = ""
    @State private var isPurchasing = false
    @State private var notice: String?
    @State private var openLink: URL?
    private let subscriptions = Subscriptions.shared

    /// No free trial here: Apple gives it only once, and she has already been a member.
    private var plans: [MembershipPlan] {
        MembershipPlan.current(from: subscriptions.packages, showsIntro: false)
    }

    private var realScanCount: Int { store.scans.filter { !$0.isSample }.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.stone)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 0) {
                    Text("Welcome back.")
                        .font(FLFont.serif(32))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(FLFont.sans(15))
                        .foregroundStyle(Palette.body)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.top, 8)
                        .padding(.horizontal, 12)

                    VStack(spacing: 12) {
                        ForEach(plans) { plan in
                            MembershipPlanRow(plan: plan, isSelected: selectedPlan == plan.id) {
                                selectedPlan = plan.id
                                Analytics.track(.paywallPlanSelected, ["plan": plan.name, "source": "renew"])
                            }
                        }
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your membership includes")
                            .font(FLFont.sans(14, .semibold))
                            .foregroundStyle(Palette.ink)
                        benefit("New scans and your full skin consultation")
                        benefit("Products matched to your skin and budget")
                        benefit("Your progress chart and reviews")
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
                OnboardingCTA(title: isPurchasing ? "One moment…" : "Renew my membership", isEnabled: !isPurchasing) {
                    renewTapped()
                }
                Text(plans.first { $0.id == selectedPlan }?.renewal ?? "Renews automatically. Cancel anytime in Settings.")
                    .font(FLFont.sans(12.5))
                    .foregroundStyle(Palette.mist)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: selectedPlan)
                HStack(spacing: 6) {
                    Button { restoreTapped() } label: {
                        Text("Restore")
                            .underline()
                            .frame(minHeight: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)
                    Text("·")
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
        .sensoryFeedback(.selection, trigger: selectedPlan)
        .task {
            await subscriptions.refresh()
            selectDefaultPlan()
        }
        .onAppear {
            selectDefaultPlan()
            Analytics.track(.paywallViewed, ["source": "renew"])
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
    }

    private var subtitle: String {
        switch realScanCount {
        case 0: "Renew to scan and get your full consultation."
        case 1: "Your first scan is saved. Renew to pick up where you left off."
        default: "Your \(realScanCount) scans are saved. Renew to pick up where you left off."
        }
    }

    private func selectDefaultPlan() {
        guard !plans.contains(where: { $0.id == selectedPlan }) else { return }
        selectedPlan = MembershipPlan.defaultID(in: plans)
    }

    private func renewTapped() {
        guard let package = plans.first(where: { $0.id == selectedPlan })?.package else {
            notice = "Memberships aren't available right now. Please try again in a moment."
            return
        }
        isPurchasing = true
        Task {
            let outcome = await subscriptions.purchase(package, source: "renew")
            isPurchasing = false
            switch outcome {
            case .purchased: dismiss()
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
                dismiss()
            } else {
                notice = "We couldn't find an active membership for this Apple ID."
            }
        }
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
}

/// "Your progress is waiting." Sits over blurred content on a locked screen.
struct LockedCard: View {
    var title: String = "Your progress is waiting."
    var message: String = "Renew to pick up where you left off. Everything you've built is saved."
    let onRenew: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Palette.rose)
            Text(title)
                .font(FLFont.serif(23))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(FLFont.sans(13))
                .foregroundStyle(Palette.stone)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onRenew) {
                Text("Renew")
                    .font(FLFont.sans(14.5, .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 180, height: 44)
                    .background(Palette.rose, in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 6)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }
}

extension View {
    /// Blurs and disables content when her membership has lapsed, with the locked card on top.
    func lockedWhenLapsed(_ isLapsed: Bool, title: String = "Your progress is waiting.",
                          message: String = "Renew to pick up where you left off. Everything you've built is saved.",
                          onRenew: @escaping () -> Void) -> some View {
        self
            .blur(radius: isLapsed ? 9 : 0)
            .allowsHitTesting(!isLapsed)
            .accessibilityHidden(isLapsed)
            .overlay(alignment: .top) {
                if isLapsed {
                    LockedCard(title: title, message: message, onRenew: onRenew)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
            }
    }
}
