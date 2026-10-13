import Foundation

/// Search across the product catalog: brand, product name, key ingredients and the areas it
/// helps ("dark spots", "redness"). Every word she types has to match somewhere.
/// Each product appears once, best matches first.
enum CatalogSearch {
    static func results(for query: String, in products: [CatalogProduct]) -> [CatalogProduct] {
        let words = normalize(query).split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }
        let areaNames = Dictionary(uniqueKeysWithValues: ProductPicker.outcomes.map { ($0.key, $0.name) })

        // Gather every area a product helps, since a product can have several catalog rows.
        var areasByProduct: [String: Set<String>] = [:]
        for product in products {
            areasByProduct[product.fullName, default: []].insert(areaNames[product.concern] ?? product.concern)
        }

        var seen = Set<String>()
        var scored: [(CatalogProduct, Int)] = []
        for product in products where seen.insert(product.fullName).inserted {
            let title = normalize(product.fullName)
            let extras = [
                (product.keyIngredients ?? []).joined(separator: " "),
                (areasByProduct[product.fullName] ?? []).joined(separator: " "),
                product.approach == "natural" || product.approach == "both" ? "natural" : "clinical",
                product.tier,
            ].map(normalize).joined(separator: " ")
            let haystack = title + " " + extras
            guard words.allSatisfy({ haystack.contains($0) }) else { continue }
            // Brand or name matches rank above ingredient or area matches.
            let score = words.filter { title.contains($0) }.count * 10
                + (title.hasPrefix(words[0]) ? 5 : 0)
            scored.append((product, score))
        }
        return scored
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.fullName < $1.0.fullName }
            .map(\.0)
    }

    /// Lowercased, accents removed ("Avène" matches "avene"), punctuation as spaces.
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .map { $0.isLetter || $0.isNumber || $0 == "%" ? $0 : " " }
            .reduce(into: "") { $0.append($1) }
    }
}
