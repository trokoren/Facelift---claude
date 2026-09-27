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

    func tint(for metric: Metric) -> Color {
        if metric.score < 60 { return Palette.ember }
        return kind == .tone ? Palette.rose : Palette.gold
    }
}
