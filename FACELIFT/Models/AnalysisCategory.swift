import SwiftUI

/// One of the three analysis groups (Aging & Structure, Tone & Clarity, Skin Health).
struct AnalysisCategory: Identifiable, Hashable, Codable {
    enum Kind: String, Codable {
        case aging
        case tone
        case health
    }

    struct Metric: Identifiable, Hashable, Codable {
        let name: String
        let detail: String
        let score: Int

        var id: String { name }
    }

    let kind: Kind
    let title: String
    let score: Int
    let rating: String
    let metrics: [Metric]
    let insight: String

    var id: String { kind.rawValue }

    /// All three cards share the brand rose so they read as one set.
    var accent: Color { Palette.rose }

    /// Metric score + bar color: rose on every card.
    func tint(for metric: Metric) -> Color { Palette.rose }

    /// Face icon color in the card corner.
    var iconTint: Color { Palette.rose }
}
