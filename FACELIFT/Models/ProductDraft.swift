import Foundation

/// Editable copy of a `UsedProduct` for the "What I'm using" editor. Nothing changes in the
/// app until the sheet is saved.
struct ProductDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var brand: String = ""
    var name: String = ""
    var price: String = ""
    var url: String = ""

    init() {}

    init(_ product: UsedProduct) {
        id = product.id
        brand = product.brand
        name = product.name
        price = product.price > 0 ? "$\(product.price)" : ""
        url = product.url?.absoluteString ?? ""
    }

    /// Accepts "laneige.com" or a full link; returns nil for blanks or junk.
    static func cleanURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.lowercased().hasPrefix("http") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme), url.host?.contains(".") == true else { return nil }
        return url
    }
}
