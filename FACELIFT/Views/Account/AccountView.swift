import SwiftUI
import StoreKit

struct AccountView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.requestReview) private var requestReview
    @State private var isShowingGoals: Bool = false
    @State private var isShowingApproach: Bool = false
    @State private var isConfirmingSignOut: Bool = false
    @State private var isSigningIn: Bool = false
    @State private var isConfirmingDelete: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deleteFailed: Bool = false
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
                            text: "Your FACELIFT membership includes up to two skin scans a day, a full consultation across seven measures of your skin, product recommendations matched to your results and progress tracking over time. You can manage or cancel it any time from your device's subscription settings."
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

                if !account.isSignedIn {
                    signInCard
                        .padding(.top, 22)
                }

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
                    Button { isShowingApproach = true } label: {
                        SettingsRow(title: "Skincare Approach", value: store.approach.title)
                    }
                    .buttonStyle(CardPressStyle())
                    RowDivider()
                    SettingsRow(title: "Scan Reminders", showsChevron: false) {
                        Toggle("Scan Reminders", isOn: Binding(
                            get: { store.remindersOn },
                            set: { on in Task { await store.setReminders(on) } }
                        ))
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

                if account.isSignedIn {
                    Button {
                        isConfirmingSignOut = true
                    } label: {
                        Text("Sign out")
                            .font(FLFont.sans(13.5))
                            .tracking(0.3)
                            .foregroundStyle(Palette.taupe)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .overlay(Capsule().stroke(Palette.roseBorder, lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 18)

                    Button {
                        isConfirmingDelete = true
                    } label: {
                        Text(isDeleting ? "Deleting account..." : "Delete account")
                            .font(FLFont.sans(12))
                            .foregroundStyle(Palette.faint)
                            .underline()
                            .frame(height: 40)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(isDeleting)
                    .padding(.top, 6)
                }

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
        .sheet(isPresented: $isShowingApproach) {
            ApproachSheet()
        }
        .sheet(item: $insight) { item in
            InsightSheet(content: item)
        }
        .confirmationDialog("Sign out of FACELIFT?", isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { Task { await store.signOut() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your scans stay on this phone and in your account. Sign back in any time to reconnect.")
        }
        .confirmationDialog("Delete your account?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Task {
                    isDeleting = true
                    let deleted = await Account.shared.deleteAccount()
                    isDeleting = false
                    if deleted { await store.signOut() } else { deleteFailed = true }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your FACELIFT account and the scans saved to it. Your scans on this phone are not affected. Deleting your account does not cancel your membership; manage that in Settings > Apple ID > Subscriptions.")
        }
        .alert("We couldn't delete your account", isPresented: $deleteFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check your connection and try again.")
        }
        .sheet(isPresented: $isSigningIn) {
            SignInSheet(purpose: .keepMembership)
        }
        .sensoryFeedback(.selection, trigger: store.remindersOn)
    }

    private var account: Account { Account.shared }

    private var profileHeader: some View {
        let user = account.user
        let title = user?.name ?? (user == nil ? "Your Account" : "FACELIFT Member")
        return VStack(spacing: 0) {
            Group {
                if let letter = user?.name?.first {
                    Text(String(letter).uppercased())
                        .font(FLFont.serif(30))
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 26, weight: .light))
                }
            }
            .foregroundStyle(Palette.rose)
            .frame(width: 79, height: 79)
            .background(Palette.blush, in: Circle())
            .overlay(Circle().stroke(Palette.rose, lineWidth: 1.4))
            Text(title)
                .font(FLFont.serifMedium(21.3))
                .foregroundStyle(Palette.ink)
                .padding(.top, 14)
            Text(user?.displayEmail ?? (user == nil ? "Not signed in" : "Signed in with Apple"))
                .font(FLFont.sans(12.1))
                .foregroundStyle(Palette.taupe)
                .padding(.top, 2)
        }
    }

    private var signInCard: some View {
        Button { isSigningIn = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(Palette.blush, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sign in with Apple")
                        .font(FLFont.sans(14, .medium))
                        .foregroundStyle(Palette.ink)
                    Text("Keep your membership on any iPhone.")
                        .font(FLFont.sans(12))
                        .foregroundStyle(Palette.taupe)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.whisper)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .cardSurface()
        }
        .buttonStyle(CardPressStyle())
    }
}
