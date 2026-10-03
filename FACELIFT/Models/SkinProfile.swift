import Foundation

/// Her onboarding answers, kept on the phone so every consultation can quietly take them into
/// account (age, sensitivity, health context, routine, climate). Never sent anywhere but the
/// analysis request.
struct SkinProfile: Codable, Equatable {
    var ageRange: String?
    var skinType: String?
    var concerns: [String] = []
    var sensitivity: String?
    var mainGoal: String?
    var healthContext: [String] = []
    var spfHabit: String?
    var routine: [String] = []
    var city: String?

    init(_ answers: OnboardingAnswers) {
        ageRange = answers.ageRange
        skinType = answers.skinType
        concerns = answers.concerns
        sensitivity = answers.sensitivity
        mainGoal = answers.mainGoal
        healthContext = answers.healthContext.filter { $0 != "None of these" }
        spfHabit = answers.spfHabit
        routine = answers.routine
        city = answers.city
    }

    private static let key = "facelift.profile"

    static func load() -> SkinProfile? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SkinProfile.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    /// What the consultation receives. Empty answers are left out.
    var context: [String: Any] {
        var out: [String: Any] = [:]
        if let ageRange { out["age_range"] = ageRange }
        if let skinType { out["skin_type_she_chose"] = skinType }
        if !concerns.isEmpty { out["concerns_she_mentioned"] = concerns }
        if let sensitivity { out["sensitivity"] = sensitivity }
        if let mainGoal { out["main_goal"] = mainGoal }
        if !healthContext.isEmpty { out["health_context"] = healthContext }
        if let spfHabit { out["spf_habit"] = spfHabit }
        if !routine.isEmpty { out["current_routine"] = routine }
        if let city { out["city"] = city }
        return out
    }
}
