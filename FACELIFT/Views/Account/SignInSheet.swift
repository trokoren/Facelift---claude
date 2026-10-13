import SwiftUI
import AuthenticationServices

/// Sign in with Apple, in the app's sheet style. Used from the first screen ("Already a
/// user? Sign in") and from Account.
struct SignInSheet: View {
    enum Purpose {
        /// A returning member on a new or reset phone.
        case returning
        /// A member who wants her membership to follow her to other phones.
        case keepMembership
    }

    let purpose: Purpose
    /// Returning members: called once she's signed in with an active membership.
    var onUnlocked: () -> Void = {}
    /// Returning members with no active membership: carry on into the tour.
    var onContinue: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var isWorking: Bool = false
    @State private var errorText: String?
    @State private var hasNoMembership: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(hasNoMembership ? "SIGNED IN" : (purpose == .returning ? "WELCOME BACK" : "YOUR ACCOUNT"))
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)

            Text(title)
                .font(FLFont.serif(26))
                .foregroundStyle(Palette.ink)
                .padding(.top, 12)

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 14)

            Text(bodyText)
                .font(FLFont.sans(13.9))
                .foregroundStyle(Palette.body)
                .lineSpacing(7.5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            if let errorText {
                Text(errorText)
                    .font(FLFont.sans(12.5))
                    .foregroundStyle(Palette.ember)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }

            Spacer(minLength: 24)

            if hasNoMembership {
                noMembershipActions
            } else {
                SignInWithAppleButton(.signIn) { request in
                    Account.shared.prepare(request)
                } onCompletion: { result in
                    Task { await finish(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(Capsule())
                .disabled(isWorking)
                .opacity(isWorking ? 0.5 : 1)
                .overlay {
                    if isWorking { ProgressView().tint(.white) }
                }

                Text("Your scans are saved to your account, so they follow you to a new phone.")
                    .font(FLFont.sans(11.5))
                    .foregroundStyle(Palette.faint)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                #if DEBUG
                // Test builds only (run from Xcode): skip sign-in and go straight into the app,
                // keeping whatever scans and profile are on this phone. Never in App Store builds.
                if purpose == .returning {
                    Button {
                        dismiss()
                        onUnlocked()
                    } label: {
                        Text("Skip sign-in (test build)")
                            .font(FLFont.sans(12.5, .medium))
                            .foregroundStyle(Palette.rose)
                            .underline()
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 34)
        .padding(.bottom, 20)
        .background(Palette.sheet.ignoresSafeArea())
        .presentationDetents([.height(hasNoMembership ? 420 : Self.signInHeight)])
        .presentationDragIndicator(.visible)
    }

    #if DEBUG
    private static let signInHeight: CGFloat = 450
    #else
    private static let signInHeight: CGFloat = 400
    #endif

    private var title: String {
        if hasNoMembership { return "No membership found" }
        return purpose == .returning ? "Sign in to FACELIFT" : "Keep your membership with you"
    }

    private var bodyText: String {
        if hasNoMembership {
            return "You're signed in, but there's no active membership on this account. If you joined with a different Apple ID, try Restore Purchases. Otherwise, continue to set up your skin profile."
        }
        return purpose == .returning
            ? "Use the Apple ID you joined with and your membership comes with you."
            : "Sign in with Apple so your membership follows you to any iPhone."
    }

    private var noMembershipActions: some View {
        VStack(spacing: 10) {
            OnboardingCTA(title: "Continue") {
                dismiss()
                onContinue()
            }
            Button {
                Task { await restore() }
            } label: {
                Text(isWorking ? "Checking..." : "Restore Purchases")
                    .font(FLFont.sans(13.5))
                    .foregroundStyle(Palette.taupe)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .disabled(isWorking)
        }
    }

    private func finish(_ result: Result<ASAuthorization, Error>) async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        do {
            try await Account.shared.completeSignIn(result)
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription
            return
        }
        guard purpose == .returning else {
            dismiss()
            return
        }
        // Until RevenueCat is set up there's no membership to check, so she goes straight in.
        if Subscriptions.shared.isPremium || !Subscriptions.isAvailable {
            dismiss()
            onUnlocked()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { hasNoMembership = true }
        }
    }

    private func restore() async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }
        if await Subscriptions.shared.restore() {
            dismiss()
            onUnlocked()
        } else {
            errorText = "We couldn't find a membership on this Apple ID either."
        }
    }
}
