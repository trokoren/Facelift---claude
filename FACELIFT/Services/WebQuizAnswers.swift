import Foundation
import RevenueCat

/// The answers she gave in the web quiz (RevenueCat Funnel), read back after she opens her
/// redemption link so onboarding can skip the questions she already answered.
/// The funnel saves each answer on her RevenueCat profile; the `web-quiz-answers` function
/// reads them with a server key that never lives in the app.
enum WebQuizAnswers {
    /// Fills in `answers` from the web quiz. Returns true when the quiz answers arrived.
    static func load(into answers: inout OnboardingAnswers) async -> Bool {
        guard Purchases.isConfigured, let url = Backend.functionURL("web-quiz-answers") else { return false }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Backend.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["app_user_id": Purchases.shared.appUserID])
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let web = body["answers"] as? [String: Any] else { return false }

        func text(_ key: String) -> String? { (web[key] as? String).flatMap { $0.isEmpty ? nil : $0 } }
        func list(_ key: String) -> [String] { web[key] as? [String] ?? [] }

        // The answers that keep her picks safe and personal must all be there, or she
        // answers them in the app as usual.
        guard let age = text("age_range"), let sensitivity = text("sensitivity"), !list("health_context").isEmpty else {
            return false
        }
        // The web shows "25 to 34"; the app stores "25–34".
        answers.ageRange = age.replacingOccurrences(of: " to ", with: "–")
        answers.sensitivity = sensitivity
        answers.healthContext = list("health_context")
        if let skinType = text("skin_type") { answers.skinType = skinType }
        if !list("concerns").isEmpty { answers.concerns = list("concerns") }
        if !list("feelings").isEmpty { answers.feelings = list("feelings") }
        if let budget = text("budget") { answers.budget = budget }
        if let approach = text("approach"),
           let match = SkincareApproach.allCases.first(where: { $0.title.caseInsensitiveCompare(approach) == .orderedSame }) {
            answers.approach = match
        }
        return true
    }
}
