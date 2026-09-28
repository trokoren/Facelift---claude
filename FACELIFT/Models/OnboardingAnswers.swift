import Foundation

/// Everything the user tells us during the skin profile tour.
struct OnboardingAnswers: Equatable {
    var ageRange: String?
    var skinType: String?
    var concerns: [String] = []
    var sensitivity: String?
    var mainGoal: String?
    var budget: String?
    var healthContext: [String] = []
    var spfHabit: String?
    var routine: [String] = []
    var city: String?
    var notificationsRequested: Bool = false
    var selectedPlan: String = "Annual"

    /// Skin type as shown on the profile card ("I don't really know" becomes "Combination").
    var resolvedSkinType: String {
        guard let skinType, skinType != "I don't really know" else { return "Combination" }
        return skinType
    }

    /// Up to three concerns for the profile card, falling back to sensible defaults.
    var topConcerns: [String] {
        let picked = Array(concerns.prefix(3))
        return picked.isEmpty ? ["Dehydration", "Fine Lines", "Texture"] : picked
    }

    /// Goals for the account screen derived from the 28-day goal.
    var skinGoals: [String] {
        switch mainGoal {
        case "Younger": ["Anti-aging", "Firmness"]
        case "Balanced & calm about my skin": ["Calming", "Hydration"]
        case "I can go makeup free": ["Even tone", "Texture"]
        case "All of the above": ["Anti-aging", "Hydration", "Even tone"]
        default: ["Anti-aging", "Hydration"]
        }
    }
}
