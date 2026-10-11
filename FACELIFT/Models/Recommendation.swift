import Foundation

/// An issue detected in a scan, the recommended solution, and three product tiers.
struct Recommendation: Identifiable, Hashable, Codable {
    struct Product: Identifiable, Hashable, Codable {
        let tier: String
        let name: String
        let price: Int
        let imageName: String
        /// Set for products from the catalog (older scans don't have them).
        var brand: String? = nil
        /// Affiliate or product link from the catalog. Empty means a shopping search.
        var url: URL? = nil

        var id: String { name }
    }

    let numeral: String
    let issue: String
    let solution: String
    let summary: String
    let products: [Product]

    var id: String { issue }
}
