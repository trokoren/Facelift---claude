import SwiftUI

/// Final paywall: before/after, three plan cards and "Start My Skin Journey".
struct PaywallStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(AppStore.self) private var store
    @State private var isReading = false

    private struct Plan: Identifiable {
        let name: String
        let price: String
        var perMonth: String? = nil
        var badge: String? = nil
        var id: String { name }
    }

    private let plans: [Plan] = [
        Plan(name: "Free Trial", price: "Only $3.99 for 3 days", perMonth: "Then $49.99/year"),
        Plan(name: "Weekly", price: "$8.99/week"),
        Plan(name: "Annual", price: "$4.16/month", perMonth: "$49.99 billed yearly", badge: "SAVE 90%")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        PaywallPhoto(imageName: "onb_before", label: "BEFORE", labelFill: Color(hex: 0x6E6866))
                        PaywallPhoto(imageName: "onb_after", label: "AFTER", labelFill: Palette.rose)
                    }
                    .padding(.top, 8)

                    Text("Improve your skin\nin 4 weeks.")
                        .font(FLFont.serif(30))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-2)
                        .padding(.top, 12)
                    Text("Get 40% off FACELIFT")
                        .font(FLFont.sans(15.5))
                        .foregroundStyle(Palette.body)
                        .padding(.top, 4)

                    VStack(spacing: 8) {
                        ForEach(plans) { plan in
                            planRow(plan)
                        }
                    }
                    .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("What you'll get")
                            .font(FLFont.sans(14, .semibold))
                            .foregroundStyle(Palette.ink)
                        benefit("Your full skin analysis: 14 scores")
                        benefit("Products matched to your skin and budget")
                        benefit("Weekly scans to track your progress")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.horizontal, 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 12) {
                OnboardingCTA(title: "Start My Skin Journey") {
                    // Her scan is read now, right after she subscribes, using her answers.
                    store.skinType = flow.answers.resolvedSkinType
                    store.skinGoals = flow.answers.skinGoals
                    isReading = true
                }
                Text("cancel anytime")
                    .font(FLFont.sans(13.5))
                    .foregroundStyle(Palette.mist)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: flow.answers.selectedPlan)
        .fullScreenCover(isPresented: $isReading) {
            FirstReadView {
                isReading = false
                store.completeOnboarding(with: flow.answers, signIn: false)
            }
            .environment(store)
        }
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
        let isSelected = flow.answers.selectedPlan == plan.name
        return Button {
            flow.answers.selectedPlan = plan.name
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
