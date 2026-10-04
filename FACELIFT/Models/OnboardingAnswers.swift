import Foundation

/// Everything the user tells us during the skin profile tour.
struct OnboardingAnswers: Equatable {
    var ageRange: String?
    var skinType: String?
    var concerns: [String] = []
    var sensitivity: String?
    /// How she wants to feel in 28 days (pick any).
    var feelings: [String] = []
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

    /// Her 28-day feelings as one line for the consult ("Younger, Desired").
    var mainGoal: String? {
        feelings.isEmpty ? nil : feelings.joined(separator: ", ")
    }

    /// Goals for the account screen, from what each feeling depends on in her skin.
    var skinGoals: [String] {
        var goals: [String] = []
        for feeling in feelings {
            let mapped: [String] = switch feeling {
            case "Seen as beautiful": ["Even tone", "Glow"]
            case "Younger, fresher-faced": ["Anti-aging", "Hydration"]
            case "Desired and attractive": ["Glow", "Clear skin"]
            case "Glowing, lit from within": ["Glow", "Hydration"]
            case "Confident with no makeup": ["Even tone", "Minimize pores"]
            case "Camera-ready from any angle": ["Clear skin", "Minimize pores"]
            case "Calm, not hiding redness": ["Calm sensitivity", "Even tone"]
            case "Noticed when I walk in": ["Glow", "Anti-aging"]
            default: []
            }
            for goal in mapped where !goals.contains(goal) { goals.append(goal) }
        }
        return goals.isEmpty ? ["Anti-aging", "Hydration"] : Array(goals.prefix(4))
    }
}
