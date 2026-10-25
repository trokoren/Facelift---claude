import Foundation
import Observation
import AuthenticationServices
import UIKit
import CryptoKit

/// Her FACELIFT account: Sign in with Apple, backed by Supabase Auth.
///
/// What an account does: it gives her membership (RevenueCat) a stable owner and backs up her
/// scans (`ScanSync`, scores and consultations only), so both follow her to a new iPhone.
///
/// Needs, outside the app:
/// - Xcode: Signing & Capabilities > + Capability > Sign in with Apple (paid developer team).
/// - Supabase: Authentication > Sign In / Providers > Apple > on, with the app's bundle ID
///   (app.faceliftai.facelift) under Client IDs. No secret key is needed for in-app sign-in.
@Observable
final class Account {
    static let shared = Account()

    struct User: Codable, Equatable {
        let id: String
        var email: String?
        var name: String?

        /// Apple's "Hide My Email" addresses aren't worth showing.
        var displayEmail: String? {
            guard let email, !email.isEmpty else { return nil }
            return email.hasSuffix("privaterelay.appleid.com") ? "Private email via Apple" : email
        }
    }

    private struct Session: Codable {
        var accessToken: String
        var refreshToken: String
        var expiresAt: Date
        var user: User
    }

    enum SignInError: LocalizedError {
        case cancelled
        case notSwitchedOn
        case failed

        var errorDescription: String? {
            switch self {
            case .cancelled: nil
            case .notSwitchedOn: "Sign in with Apple isn't switched on for this version of the app yet."
            case .failed: "We couldn't sign you in. Please check your connection and try again."
            }
        }
    }

    private(set) var user: User?
    var isSignedIn: Bool { user != nil }

    private static let sessionKey = "supabase.session"
    private var session: Session? {
        didSet {
            user = session?.user
            if let session, let data = try? JSONEncoder().encode(session) {
                Keychain.save(data, for: Self.sessionKey)
            } else {
                Keychain.remove(Self.sessionKey)
            }
        }
    }
    /// The unhashed nonce for the Apple request in flight (Supabase checks it against the token).
    private var pendingNonce: String?

    private init() {
        if let data = Keychain.load(Self.sessionKey),
           let saved = try? JSONDecoder().decode(Session.self, from: data) {
            session = saved
            user = saved.user
        }
    }

    // MARK: - Sign in with Apple

    /// Hand this to `SignInWithAppleButton(onRequest:)`.
    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        pendingNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Hand the button's result to this. Signs her in to Supabase, then ties her membership
    /// to the account.
    func completeSignIn(_ result: Result<ASAuthorization, Error>) async throws {
        let authorization: ASAuthorization
        switch result {
        case .success(let value):
            authorization = value
        case .failure(let error):
            let code = (error as? ASAuthorizationError)?.code
            if code == .canceled { throw SignInError.cancelled }
            #if DEBUG
            print("Sign in with Apple failed:", error)
            #endif
            // 1000 ("unknown") is what Apple returns when the capability is missing.
            throw code == .unknown ? SignInError.notSwitchedOn : SignInError.failed
        }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = pendingNonce else { throw SignInError.failed }
        pendingNonce = nil

        // Apple shares her name only the first time she signs in, so keep it on the account.
        let appleName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let body: [String: Any] = ["provider": "apple", "id_token": idToken, "nonce": nonce]
        guard let json = try await auth("token?grant_type=id_token", body: body),
              var newSession = Self.session(from: json) else { throw SignInError.failed }

        if !appleName.isEmpty {
            newSession.user.name = appleName
            if newSession.user.email == nil { newSession.user.email = credential.email }
            session = newSession
            _ = try? await auth("user", method: "PUT", body: ["data": ["full_name": appleName]], bearer: newSession.accessToken)
        } else {
            session = newSession
        }

        await Subscriptions.shared.identify(newSession.user.id)
    }

    // MARK: - Sign out and delete

    /// Signs out on this phone. Her scans stay here and in her account; her membership stays
    /// with her Apple ID.
    func signOut() async {
        if let token = session?.accessToken {
            _ = try? await auth("logout", body: [:], bearer: token)
        }
        session = nil
        await Subscriptions.shared.forget()
    }

    /// What came back when we asked her to confirm with Apple before deleting.
    enum AppleConfirmation {
        /// A fresh one-time code the server uses to revoke her Sign in with Apple token.
        case code(String)
        /// She closed Apple's sheet: she's having second thoughts, so don't delete.
        case cancelled
        /// Apple couldn't give us a code (no capability, offline). Delete anyway; revoking is best effort.
        case unavailable
    }

    /// Apple requires revoking her Sign in with Apple token when she deletes her account, which
    /// needs a fresh authorization code (they expire in 5 minutes), so we ask her to confirm
    /// with Apple right before deleting.
    func confirmWithApple() async -> AppleConfirmation {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []
        let helper = AppleCodeRequest()
        do {
            let authorization = try await helper.perform(request)
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.authorizationCode,
                  let code = String(data: data, encoding: .utf8) else { return .unavailable }
            return .code(code)
        } catch {
            if (error as? ASAuthorizationError)?.code == .canceled { return .cancelled }
            #if DEBUG
            print("Apple confirmation before delete failed:", error)
            #endif
            return .unavailable
        }
    }

    /// Permanently deletes her account on our server (her scan backup goes with it), then signs
    /// out here. Her scans on this phone stay until she deletes them. Pass the code from
    /// `confirmWithApple()` so the server can revoke her Sign in with Apple token too.
    /// Returns false if the server couldn't be reached (nothing is deleted then).
    func deleteAccount(appleAuthorizationCode: String? = nil) async -> Bool {
        guard let token = await accessToken(),
              let url = Backend.functionURL("delete-account") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        if let appleAuthorizationCode {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["apple_authorization_code": appleAuthorizationCode])
        }
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
        session = nil
        await Subscriptions.shared.forget()
        return true
    }

    /// A current access token for calling our server as her, refreshed when it's about to expire.
    func accessToken() async -> String? {
        guard let current = session else { return nil }
        if current.expiresAt > Date().addingTimeInterval(60) { return current.accessToken }
        guard let json = try? await auth("token?grant_type=refresh_token", body: ["refresh_token": current.refreshToken]),
              var refreshed = Self.session(from: json) else { return nil }
        refreshed.user.name = refreshed.user.name ?? current.user.name
        session = refreshed
        return refreshed.accessToken
    }

    // MARK: - Supabase Auth

    private func auth(_ path: String, method: String = "POST", body: [String: Any], bearer: String? = nil) async throws -> [String: Any]? {
        guard let url = URL(string: "\(Backend.supabaseURL)/auth/v1/\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        if let bearer { request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else {
            #if DEBUG
            print("Supabase auth \(path) failed:", String(data: data, encoding: .utf8) ?? "")
            #endif
            throw SignInError.failed
        }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private static func session(from json: [String: Any]) -> Session? {
        guard let access = json["access_token"] as? String,
              let refresh = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any],
              let id = user["id"] as? String else { return nil }
        let expiresIn = (json["expires_in"] as? Double) ?? 3600
        let metadata = user["user_metadata"] as? [String: Any]
        let name = (metadata?["full_name"] as? String) ?? (metadata?["name"] as? String)
        return Session(
            accessToken: access,
            refreshToken: refresh,
            expiresAt: Date().addingTimeInterval(expiresIn),
            user: User(id: id, email: user["email"] as? String, name: name?.isEmpty == true ? nil : name)
        )
    }

    // MARK: - Nonce

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Runs one Sign in with Apple request outside of a button and hands back the result.
private final class AppleCodeRequest: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private var controller: ASAuthorizationController?

    func perform(_ request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
        self.controller = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        self.controller = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
