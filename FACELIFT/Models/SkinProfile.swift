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

    /// Saved in a file protected while the phone is locked (it can hold health answers).
    private static let fileName = "profile.json"
    /// Where older builds kept it; moved into the protected file on first load.
    private static let legacyKey = "facelift.profile"

    static func load() -> SkinProfile? {
        if let profile = LocalFile.load(SkinProfile.self, from: fileName) { return profile }
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let profile = try? JSONDecoder().decode(SkinProfile.self, from: data) else { return nil }
        profile.save()
        UserDefaults.standard.removeObject(forKey: legacyKey)
        return profile
    }

    func save() {
        LocalFile.save(self, to: Self.fileName)
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
