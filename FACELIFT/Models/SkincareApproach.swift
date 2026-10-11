import Foundation

/// How she likes her skincare: from proven clinical actives to plant-based natural care.
/// Five stops on one slider; everyone starts at Balanced. Decides which catalog products
/// she's shown (`ProductPicker`) and, later, the ingredients her consult leans on.
enum SkincareApproach: Int, Codable, CaseIterable, Identifiable {
    case clinical = 0
    case leaningClinical
    case balanced
    case leaningNatural
    case natural

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .clinical: "Clinical"
        case .leaningClinical: "Leaning clinical"
        case .balanced: "Balanced"
        case .leaningNatural: "Leaning natural"
        case .natural: "Natural"
        }
    }

    /// One line under the slider.
    var detail: String {
        switch self {
        case .clinical: "Proven actives only: retinol, acids, vitamin C and peptides."
        case .leaningClinical: "Mostly proven actives, with a natural pick in each area."
        case .balanced: "The best of both, chosen for what your skin needs."
        case .leaningNatural: "Mostly plant-based care, with one proven active in each area."
        case .natural: "Plant-based care only: botanical oils, extracts and gentle alternatives."
        }
    }

    /// Which catalog side a product slot draws from. Nil means either side.
    /// The leaning stops take one of the three price tiers from the other side, rotating
    /// which tier so she sees variety.
    func side(forTierAt tierIndex: Int, slot: Int) -> String? {
        let otherTier = slot % 3
        switch self {
        case .clinical: return "clinical"
        case .natural: return "natural"
        case .balanced: return nil
        case .leaningClinical: return tierIndex == otherTier ? "natural" : "clinical"
        case .leaningNatural: return tierIndex == otherTier ? "clinical" : "natural"
        }
    }

    /// The far ends are strict: only that side. The leaning stops fall back to anything that
    /// fits rather than leave a price tier empty.
    var isStrict: Bool { self == .clinical || self == .natural }
}
