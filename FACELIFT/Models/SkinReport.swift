import Foundation

/// Raw result from the analyze-skin function: one 0-100 score per concern (higher = healthier).
struct SkinReport: Decodable {
    struct Concern: Decodable {
        let ui: Double
        let raw: Double
    }

    /// Written by Claude for each card: aging, tone, health.
    struct Insights: Decodable {
        let aging: String?
        let tone: String?
        let health: String?
    }

    let mode: String?
    let resolution: String?
    /// Set when YouCam couldn't run and Claude read every marker instead.
    let youcamError: String?
    let concerns: [String: Concern]
    /// Which system read each marker: "youcam" or "claude".
    let sources: [String: String]?
    let insights: Insights?
    /// The written consult (current server). Nil from older responses.
    let consult: Consult?

    /// Measurements rounded for display, keyed by marker.
    var measures: [String: Int] {
        concerns.mapValues { min(100, max(1, Int($0.ui.rounded()))) }
    }
}

/// Turns the 14 measured markers into FACELIFT's three cards, insights and top concerns.
extension SkinReport {
    private struct Marker {
        let keys: [String]
        let name: String
        let detail: String
        let concern: String
        let tip: String
    }

    private static let aging: [Marker] = [
        Marker(keys: ["wrinkle"], name: "Fine lines & wrinkles", detail: "forehead, crow's feet, smile lines",
               concern: "Fine Lines", tip: "A retinol a few nights a week plus daily SPF is what moves fine lines the most."),
        Marker(keys: ["firmness"], name: "Firmness & elasticity", detail: "sagging, loss of bounce",
               concern: "Firmness", tip: "Peptides and a nightly retinoid help skin hold its shape, and SPF protects the collagen you have."),
        Marker(keys: ["eye_lift", "droopy_upper_eyelid", "droopy_lower_eyelid"], name: "Eye lift", detail: "upper and lower eyelid lift",
               concern: "Eye Lift", tip: "A peptide eye cream morning and night is the gentlest way to support the thin skin around your eyes."),
        Marker(keys: ["tear_trough"], name: "Under-eye hollows", detail: "tear trough depth, shadowing",
               concern: "Under-Eye Hollows", tip: "Hydrating the under-eye with a hyaluronic eye cream softens hollows and the shadows they cast.")
    ]

    private static let tone: [Marker] = [
        Marker(keys: ["age_spot"], name: "Dark spots", detail: "sun spots, post-acne marks",
               concern: "Dark Spots", tip: "Vitamin C in the morning and SPF every day stop spots from deepening and help them fade."),
        Marker(keys: ["radiance"], name: "Radiance", detail: "glow, dullness, tired-looking skin",
               concern: "Dullness", tip: "Gentle exfoliation twice a week and a vitamin C serum bring glow back fast."),
        Marker(keys: ["redness"], name: "Redness", detail: "flushing, irritation, visible capillaries",
               concern: "Redness", tip: "Calming ingredients like niacinamide and centella, and fewer harsh actives, settle redness."),
        Marker(keys: ["dark_circle"], name: "Dark circles", detail: "under-eye darkness",
               concern: "Dark Circles", tip: "A caffeine or vitamin C eye cream and consistent sleep make the biggest difference."),
        Marker(keys: ["eye_bag"], name: "Puffiness", detail: "under-eye bags, fluid retention",
               concern: "Puffiness", tip: "A cool caffeine eye gel in the morning and less salt late at night calm puffiness.")
    ]

    private static let health: [Marker] = [
        Marker(keys: ["moisture"], name: "Hydration", detail: "water content, tight or flaky skin",
               concern: "Dehydration", tip: "A hyaluronic serum on damp skin and a simple moisturizer morning and night show results within weeks."),
        Marker(keys: ["oiliness"], name: "Oil balance", detail: "sebum, shine, T-zone",
               concern: "Oiliness", tip: "A lightweight gel moisturizer and niacinamide balance oil without stripping your skin."),
        Marker(keys: ["pore"], name: "Pores", detail: "pore size and congestion",
               concern: "Pores", tip: "A BHA two or three nights a week keeps pores clear so they look smaller."),
        Marker(keys: ["texture"], name: "Texture", detail: "roughness, bumps, unevenness",
               concern: "Texture", tip: "A gentle chemical exfoliant a few nights a week smooths texture in two to three weeks."),
        Marker(keys: ["acne"], name: "Breakouts", detail: "active blemishes, congestion",
               concern: "Breakouts", tip: "Salicylic acid and a non-comedogenic moisturizer calm breakouts without drying you out.")
    ]

    private func score(for marker: Marker) -> Int? {
        let values = marker.keys.compactMap { concerns[$0]?.ui }
        guard !values.isEmpty else { return nil }
        let average = values.reduce(0, +) / Double(values.count)
        return min(100, max(1, Int(average.rounded())))
    }

    private func scored(_ markers: [Marker]) -> [(marker: Marker, score: Int)] {
        markers.compactMap { marker in score(for: marker).map { (marker, $0) } }
    }

    /// True when enough markers came back to build all three cards.
    var isUsable: Bool {
        !scored(Self.aging).isEmpty && !scored(Self.tone).isEmpty && !scored(Self.health).isEmpty
    }

    var categories: [AnalysisCategory] {
        [
            category(.aging, "Aging & Structure", Self.aging),
            category(.tone, "Tone & Clarity", Self.tone),
            category(.health, "Skin Health", Self.health)
        ]
    }

    /// Her three lowest markers, in plain words ("Dehydration", "Fine Lines", ...).
    var topConcerns: [String] {
        if let consult, !consult.concerns.isEmpty {
            return consult.concerns.map(\.title)
        }
        let all = scored(Self.aging) + scored(Self.tone) + scored(Self.health)
        return all.sorted { $0.score < $1.score }.prefix(3).map(\.marker.concern)
    }

    private func category(_ kind: AnalysisCategory.Kind, _ title: String, _ markers: [Marker]) -> AnalysisCategory {
        let results = scored(markers)
        let metrics = results.map { AnalysisCategory.Metric(name: $0.marker.name, detail: $0.marker.detail, score: $0.score) }
        let total = results.map(\.score).reduce(0, +)
        let score = results.isEmpty ? 0 : Int((Double(total) / Double(results.count)).rounded())
        return AnalysisCategory(
            kind: kind,
            title: title,
            score: score,
            rating: SampleData.rating(for: score),
            metrics: metrics,
            insight: writtenInsight(for: kind) ?? insight(score: score, results: results)
        )
    }

    private func writtenInsight(for kind: AnalysisCategory.Kind) -> String? {
        let text: String?
        switch kind {
        case .aging: text = insights?.aging
        case .tone: text = insights?.tone
        case .health: text = insights?.health
        }
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    private func insight(score: Int, results: [(marker: Marker, score: Int)]) -> String {
        guard let strongest = results.max(by: { $0.score < $1.score }),
              let weakest = results.min(by: { $0.score < $1.score }) else {
            return "Scan again in brighter, even light and we'll fill this in."
        }

        let opener: String
        switch score {
        case 80...: opener = "This is one of your strongest areas, and it shows."
        case 70..<80: opener = "This area is in good shape, with a little room to grow."
        case 60..<70: opener = "There's real opportunity here, and the good news is it tends to respond quickly."
        default: opener = "This is where your skin is asking for the most care, which also means it's where you'll see the biggest change."
        }

        if strongest.marker.name == weakest.marker.name || strongest.score - weakest.score < 4 {
            return "\(opener) Everything here scored about the same, so there's no single weak spot. \(weakest.marker.tip)"
        }
        return "\(opener) \(strongest.marker.name) is your strongest marker at \(strongest.score). \(weakest.marker.name) at \(weakest.score) is the one to focus on. \(weakest.marker.tip)"
    }
}
