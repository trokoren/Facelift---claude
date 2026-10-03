import Foundation

/// Her results, written like a five-minute consult: skin type, what's working, what we're
/// seeing, what to keep an eye on, and her plan. Words come from Claude; every score shown
/// alongside them is a YouCam measurement.
struct Consult: Codable, Hashable {
    struct SkinType: Codable, Hashable {
        let label: String
        let explanation: String
    }

    struct Strength: Codable, Hashable, Identifiable {
        let title: String
        let detail: String
        var id: String { title }
    }

    struct Concern: Codable, Hashable, Identifiable {
        /// The measurement this concern is about (wrinkle, texture, ...).
        let key: String
        let title: String
        /// mild, moderate or notable
        let severity: String
        let summary: String
        let seen: String
        let why: String
        let todo: String
        let expect: String
        var id: String { key }

        var severityLabel: String {
            switch severity {
            case "mild": "Mild"
            case "moderate": "Moderate"
            default: "Worth addressing"
            }
        }
    }

    struct Note: Codable, Hashable {
        let title: String
        let detail: String
    }

    struct Plan: Codable, Hashable {
        let focus: String
        let morning: [String]
        let evening: [String]
    }

    let intro: String
    let skinType: SkinType
    let strengths: [Strength]
    let concerns: [Concern]
    let watch: Note?
    let plan: Plan
}

/// Plain names for the measurements YouCam takes.
enum Measure {
    static let order = ["wrinkle", "dark_circle", "age_spot", "redness", "texture", "pore", "moisture"]

    static func name(_ key: String) -> String {
        switch key {
        case "wrinkle": "Fine lines & wrinkles"
        case "dark_circle": "Dark circles"
        case "age_spot": "Dark spots"
        case "redness": "Redness"
        case "texture": "Texture"
        case "pore": "Pores"
        case "moisture": "Hydration"
        default: key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
