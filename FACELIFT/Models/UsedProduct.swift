import SwiftUI

struct UsedProduct: Identifiable, Hashable {
    enum Tint: Hashable, CaseIterable {
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

    var shopURL: URL? {
        ShopLink.url(for: "\(brand) \(name)")
    }
}
