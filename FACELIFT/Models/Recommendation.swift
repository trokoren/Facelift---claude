import Foundation

/// An issue detected in a scan, the recommended solution, and three product tiers.
struct Recommendation: Identifiable, Hashable {
    struct Product: Identifiable, Hashable {
        let tier: String
        let name: String
        let price: Int
        let imageName: String

        var id: String { name }
    }

    let numeral: String
    let issue: String
    let solution: String
    let summary: String
    let products: [Product]

    var id: String { issue }
}
