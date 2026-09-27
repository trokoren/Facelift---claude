import Foundation

/// Builds a shopping search URL for a product.
enum ShopLink {
    static func url(for query: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [
            URLQueryItem(name: "tbm", value: "shop"),
            URLQueryItem(name: "q", value: query)
        ]
        return components?.url
    }
}
