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

        // The funnel may save a short code ("trying_to_conceive", "25_to_34") instead of the
        // text she saw, so each answer is matched to the app's own wording.
        func one(_ key: String, _ options: [String]) -> String? { text(key).flatMap { match($0, options) } }
        func many(_ key: String, _ options: [String]) -> [String] {
            var found: [String] = []
            for value in list(key) { if let hit = match(value, options), !found.contains(hit) { found.append(hit) } }
            return found
        }

        // The answers that keep her picks safe and personal must all be there, or she
        // answers them in the app as usual.
        var health = many("health_context", Options.health)
        if health.count > 1 { health.removeAll { $0 == "None of these" } }
        guard let age = one("age_range", Options.age),
              let sensitivity = one("sensitivity", Options.sensitivity),
              !health.isEmpty else { return false }
        answers.ageRange = age
        answers.sensitivity = sensitivity
        answers.healthContext = health
        if let skinType = one("skin_type", Options.skinType) { answers.skinType = skinType }
        let concerns = many("concerns", Options.concerns)
        if !concerns.isEmpty { answers.concerns = concerns }
        let feelings = many("feelings", Options.feelings)
        if !feelings.isEmpty { answers.feelings = feelings }
        if let budget = one("budget", Options.budget) { answers.budget = budget }
        if let approach = one("approach", SkincareApproach.allCases.map(\.title)),
           let found = SkincareApproach.allCases.first(where: { $0.title == approach }) {
            answers.approach = found
        }
        return true
    }

    /// The app's own answer wording, as the onboarding screens store it.
    enum Options {
        static let age = ["Under 25", "25–34", "35–44", "45–60", "Over 60"]
        static let skinType = ["Dry", "Oily", "Combination", "I don't really know"]
        static let sensitivity = ["Yes, very sensitive", "Sometimes", "Not really"]
        static let budget = ["Under $30", "$30 to $75", "$75 to $150", "No limit"]
        static let concerns = ["Fine Lines", "Dark Circles", "Dark Spots", "Redness", "Texture", "Large Pores", "Dehydration", "Oiliness"]
        static let feelings = [
            "Seen as beautiful", "Younger, fresher-faced", "Desired and attractive", "Glowing, lit from within",
            "Confident with no makeup", "Camera-ready from any angle", "Calm, not hiding redness", "Noticed when I walk in"
        ]
        static let health = ["Pregnant", "Trying to conceive", "Breastfeeding", "Menopause", "Hormonal imbalances", "Autoimmune condition", "None of these"]
    }

    /// Letters and digits only, with ranges written out ("25–34" and "25_to_34" both become "25to34").
    private static func key(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "–", with: "to")
            .filter { $0.isLetter || $0.isNumber }
    }

    /// The app wording for a saved answer: an exact match first, then a short code that starts
    /// an option ("none" for "None of these").
    static func match(_ value: String, _ options: [String]) -> String? {
        let wanted = key(value)
        guard !wanted.isEmpty else { return nil }
        if let exact = options.first(where: { key($0) == wanted }) { return exact }
        let starts = options.filter { key($0).hasPrefix(wanted) }
        return starts.count == 1 ? starts[0] : nil
    }
}
