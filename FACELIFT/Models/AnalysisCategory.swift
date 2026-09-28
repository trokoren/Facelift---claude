import SwiftUI

/// One of the three analysis groups (Aging & Structure, Tone & Clarity, Skin Health).
struct AnalysisCategory: Identifiable, Hashable {
    enum Kind: String {
        case aging
        case tone
        case health
    }

    struct Metric: Identifiable, Hashable {
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

    var accent: Color {
        switch kind {
        case .aging: Palette.gold
        case .tone: Palette.rose
        case .health: Palette.sage
        }
    }

    var showsSparkle: Bool { kind == .health }

    /// Metric score + bar color. Skin Health stays fully green; the other cards flag scores
    /// under 60 in ember.
    func tint(for metric: Metric) -> Color {
        switch kind {
        case .health: return Palette.sage
        case .tone: return metric.score < 60 ? Palette.ember : Palette.rose
        case .aging: return metric.score < 60 ? Palette.ember : Palette.gold
        }
    }

    /// Face icon color in the card corner.
    var iconTint: Color { kind == .health ? Palette.sage : Palette.rose }
}
