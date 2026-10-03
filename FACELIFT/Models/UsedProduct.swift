import SwiftUI

struct UsedProduct: Identifiable, Hashable, Codable {
    enum Tint: String, Hashable, CaseIterable, Codable {
        case sky
        case sage
        case rose

        var color: Color {
            switch self {
            case .sky: Palette.sky
            case .sage: Palette.sage
            case .rose: Palette.rose
            }
        }
    }

    let id: UUID
    let brand: String
    let name: String
    let price: Int
    let tint: Tint
    /// Where "Shop Again" goes. Falls back to a shopping search when empty.
    var url: URL? = nil
    /// When she added it to her routine (check-ins and "since you started" use this).
    var addedAt: Date = Date()

    /// How we refer to it in a question: the product name, or the brand if that's all we have.
    var shortName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? brand : trimmed
    }

    var shopURL: URL? {
        url ?? ShopLink.url(for: "\(brand) \(name)")
    }
}
