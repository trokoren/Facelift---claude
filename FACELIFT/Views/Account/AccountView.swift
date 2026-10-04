import SwiftUI
import StoreKit

struct AccountView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.requestReview) private var requestReview
    @State private var isShowingGoals: Bool = false
    @State private var insight: InsightContent?

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(spacing: 0) {
                BrandHeader(subtitle: "Your Account.", onBack: nil) {
                    Button {
                        insight = InsightContent(
                            label: "MEMBERSHIP",
                            accent: Palette.rose,
                            title: "FACELIFT Premium",
                            text: "You're a FACELIFT member. Your membership includes unlimited skin scans, full analysis across all twelve markers, personalised product recommendations and progress tracking over time. You can manage or cancel your membership any time from your device's subscription settings."
                        )
                    } label: {
                        Text("$")
                            .font(FLFont.sans(13, .medium))
                            .foregroundStyle(Palette.rose)
                            .frame(width: 28, height: 28)
                            .background(Palette.blush, in: Circle())
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                    .padding(.trailing, -8)
                    .accessibilityLabel("Membership")
                }

                profileHeader
                    .padding(.top, 26)

                SectionLabel("PREFERENCES")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 22)

                VStack(spacing: 0) {
                    Button { isShowingGoals = true } label: {
                        SettingsRow(title: "Skin Goals", value: store.skinGoals.isEmpty ? "None" : store.skinGoals.joined(separator: ", "))
                    }
                    .buttonStyle(CardPressStyle())
                    RowDivider()
                    SettingsRow(title: "Scan Reminders", showsChevron: false) {
                        Toggle("Scan Reminders", isOn: $store.remindersOn)
                            .labelsHidden()
                            .tint(Palette.rose)
                            .scaleEffect(0.86, anchor: .trailing)
                    }
                    RowDivider()
                    NavigationLink(value: AccountRoute.privacy) {
                        SettingsRow(title: "Privacy & Data")
                    }
                    .buttonStyle(CardPressStyle())
                    RowDivider()
                    NavigationLink(value: AccountRoute.help) {
                        SettingsRow(title: "Help & Feedback")
                    }
                    .buttonStyle(CardPressStyle())
                    RowDivider()
                    Button { requestReview() } label: {
                        SettingsRow(title: "Rate FACELIFT")
                    }
                    .buttonStyle(CardPressStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .cardSurface()
                .padding(.top, 12)

                Button {
                    store.restartOnboarding()
                } label: {
                    SettingsRow(title: "Skin Profile Tour", value: "Retake")
                        .padding(.horizontal, 20)
                        .cardSurface()
                }
                .buttonStyle(CardPressStyle())
                .padding(.top, 14)

                #if DEBUG
                NavigationLink(value: AccountRoute.scanLab) {
                    SettingsRow(title: "Scan Lab")
                        .padding(.horizontal, 20)
                        .cardSurface()
                }
                .buttonStyle(CardPressStyle())
                .padding(.top, 14)
                #endif

                Text("Facelift · v1.0.0")
                    .font(FLFont.serifItalic(10))
                    .foregroundStyle(Palette.whisper)
                    .padding(.top, 22)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(Palette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingGoals) {
            SkinGoalsSheet()
        }
        .sheet(item: $insight) { item in
            InsightSheet(content: item)
        }
        .sensoryFeedback(.selection, trigger: store.remindersOn)
    }

    private var profileHeader: some View {
        VStack(spacing: 0) {
            // No accounts yet: no name or email to show, so a quiet member badge instead.
            Image(systemName: "sparkle")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Palette.rose)
                .frame(width: 79, height: 79)
                .background(Palette.blush, in: Circle())
                .overlay(Circle().stroke(Palette.rose, lineWidth: 1.4))
            Text("FACELIFT member")
                .font(FLFont.serifMedium(21.3))
                .foregroundStyle(Palette.ink)
                .padding(.top, 14)
            Text("Your scans and answers are kept on this iPhone.")
                .font(FLFont.sans(12.1))
                .foregroundStyle(Palette.taupe)
                .padding(.top, 2)
        }
    }
}
