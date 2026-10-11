import Foundation
import Observation

/// One product FACELIFT can recommend, from the `product_catalog` table on the server.
struct CatalogProduct: Codable, Hashable {
    let concern: String
    let tier: String
    let rank: Int
    let brand: String
    let name: String
    let price: Int
    var url: String? = nil
    var imageName: String? = nil
    let pregnancySafe: Bool

    enum CodingKeys: String, CodingKey {
        case concern, tier, rank, brand, name, price, url
        case imageName = "image_name"
        case pregnancySafe = "pregnancy_safe"
    }

    var fullName: String { "\(brand) \(name)" }
}

/// The products she can be recommended. Loaded from the server at launch and kept on the
/// phone; the copy built into the app is used until the first load succeeds.
/// Edit products, prices and links in Supabase > Table Editor > product_catalog.
@Observable
final class ProductCatalog {
    static let shared = ProductCatalog()

    private(set) var products: [CatalogProduct]
    private static let fileName = "catalog.json"

    private init() {
        products = LocalFile.load([CatalogProduct].self, from: Self.fileName) ?? Self.builtIn
    }

    /// Fetches the latest catalog. Keeps what it has if the server can't be reached.
    func refresh() async {
        guard Backend.isConfigured,
              let url = URL(string: "\(Backend.supabaseURL)/rest/v1/product_catalog?select=concern,tier,rank,brand,name,price,url,image_name,pregnancy_safe&active=eq.true&order=concern,tier,rank")
        else { return }
        var request = URLRequest(url: url)
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Backend.anonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let fresh = try? JSONDecoder().decode([CatalogProduct].self, from: data),
              !fresh.isEmpty else { return }
        products = fresh
        LocalFile.save(fresh, to: Self.fileName)
    }

    /// The same list the server started with.
    static let builtIn: [CatalogProduct] = [
        .init(concern: "moisture", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Hyaluronic Acid 2% + B5 (with Ceramides)", price: 10, url: "https://theordinary.com/en-us/hyaluronic-acid-2-b5-serum-with-ceramides-100637.html", imageName: "serum_bottle_dropper", pregnancySafe: true),
        .init(concern: "moisture", tier: "Balanced", rank: 1, brand: "La Roche-Posay", name: "Hyalu B5 Pure Hyaluronic Acid Serum", price: 54, url: "https://www.laroche-posay.us/our-products/face/face-serum/hyalu-b5-pure-hyaluronic-acid-serum-hyaluB5serum.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true),
        .init(concern: "moisture", tier: "Luxury", rank: 1, brand: "SkinCeuticals", name: "Hydrating B5 Gel", price: 95, url: "https://www.skinceuticals.com/skincare/hydrating-serums/hydrating-b5-gel/S39.html", imageName: "skincare_products_shower", pregnancySafe: true),
        .init(concern: "wrinkle", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Granactive Retinoid 2% Emulsion", price: 12, url: "https://theordinary.com/en-us/granactive-retinoid-2-emulsion-serum-100419.html", imageName: "skincare_tube_box", pregnancySafe: false),
        .init(concern: "wrinkle", tier: "Budget", rank: 2, brand: "The Ordinary", name: "Multi-Peptide + HA Serum", price: 20, imageName: "serum_bottle_dropper", pregnancySafe: true),
        .init(concern: "wrinkle", tier: "Balanced", rank: 1, brand: "RoC", name: "Retinol Correxion Line Smoothing Night Serum Capsules", price: 25, url: "https://www.rocskincare.com/products/retinol-correxion-line-smoothing-night-serum-capsules", imageName: "skincare_box_jar", pregnancySafe: false),
        .init(concern: "wrinkle", tier: "Balanced", rank: 2, brand: "Drunk Elephant", name: "Protini Polypeptide Cream", price: 72, url: "https://www.drunkelephant.com/collections/moisturizers/protini-polypeptide-cream-856556004739.html", imageName: "skincare_box_jar", pregnancySafe: true),
        .init(concern: "wrinkle", tier: "Luxury", rank: 1, brand: "Drunk Elephant", name: "A-Passioni Retinol Cream", price: 76, url: "https://drunkelephant.com/collections/retinols/a-passioni-retinol-cream-812343032392.html", imageName: "eye_cream_jar_gold_lid", pregnancySafe: false),
        .init(concern: "wrinkle", tier: "Luxury", rank: 2, brand: "Estée Lauder", name: "Advanced Night Repair Serum", price: 88, url: "https://www.esteelauder.com/product/689/77491/product-catalog/skincare/repair-serum/advanced-night-repair-serum/synchronized-multi-recovery-complex", imageName: "skincare_bottles_gold", pregnancySafe: true),
        .init(concern: "dark_circle", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Caffeine Solution 5% + EGCG Eye Serum", price: 9, url: "https://theordinary.com/en-us/caffeine-solution-5-egcg-eye-serum-100412.html", imageName: "serum_bottle_dropper", pregnancySafe: true),
        .init(concern: "dark_circle", tier: "Balanced", rank: 1, brand: "Clinique", name: "All About Eyes Eye Cream with Vitamin C", price: 39, url: "https://www.clinique.com/product/1683/4769/skincare/eye-care/all-about-eyestm-eye-cream-with-vitamin-c", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true),
        .init(concern: "dark_circle", tier: "Luxury", rank: 1, brand: "Estée Lauder", name: "Advanced Night Repair Eye Supercharged Gel-Creme", price: 78, url: "https://www.esteelauder.com/product/685/104163/product-catalog/skincare/eye-cream-treatment/advanced-night-repair-eye-supercharged-gel-creme/synchronized-multi-recovery-eye-cream", imageName: "skincare_jar_serum_dropper", pregnancySafe: true),
        .init(concern: "age_spot", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Alpha Arbutin 2% + HA", price: 12, imageName: "serum_bottle_dropper", pregnancySafe: false),
        .init(concern: "age_spot", tier: "Budget", rank: 2, brand: "The Ordinary", name: "Vitamin C Suspension 23% + HA Spheres 2%", price: 8, imageName: "skincare_tube_box", pregnancySafe: true),
        .init(concern: "age_spot", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "C15 Super Booster", price: 59, url: "https://www.paulaschoice.com/c15-brightening-super-booster/808.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true),
        .init(concern: "age_spot", tier: "Luxury", rank: 1, brand: "SkinCeuticals", name: "C E Ferulic", price: 185, url: "https://www.skinceuticals.com/skincare/vitamin-c-serums/c-e-ferulic-with-15-l-ascorbic-acid/S17.html", imageName: "skincare_bottles_gold", pregnancySafe: true),
        .init(concern: "redness", tier: "Budget", rank: 1, brand: "La Roche-Posay", name: "Cicaplast Balm B5+", price: 21, url: "https://www.laroche-posay.us/our-products/body/body-lotion/cicaplast-balm-b5-for-dry-skin-irritations-cicaplastbalmb5.html", imageName: "skincare_tube_box", pregnancySafe: true),
        .init(concern: "redness", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "10% Azelaic Acid Booster", price: 42, url: "https://www.paulaschoice.com/10pct-azelaic-acid-booster/775.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true),
        .init(concern: "redness", tier: "Luxury", rank: 1, brand: "Dr. Jart+", name: "Cicapair Soothing Color Correcting Treatment SPF 30", price: 54, imageName: "skincare_box_jar", pregnancySafe: true),
        .init(concern: "texture", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Lactic Acid 10% + HA", price: 9, imageName: "serum_bottle_dropper", pregnancySafe: true),
        .init(concern: "texture", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "Skin Perfecting 2% BHA Liquid Exfoliant", price: 37, url: "https://www.paulaschoice.com/skin-perfecting-2pct-bha-liquid-exfoliant/201-2010.html", imageName: "skincare_products_shower", pregnancySafe: false),
        .init(concern: "texture", tier: "Balanced", rank: 2, brand: "Pixi", name: "Glow Tonic", price: 29, imageName: "skincare_products_shower", pregnancySafe: true),
        .init(concern: "texture", tier: "Luxury", rank: 1, brand: "Dr. Dennis Gross", name: "Alpha Beta Universal Daily Peel", price: 94, url: "https://www.drdennisgross.com/alpha-beta-universal-daily-peel/999DDG0000001.html", imageName: "exfoliating_pads_skincare", pregnancySafe: false),
        .init(concern: "texture", tier: "Luxury", rank: 2, brand: "Sunday Riley", name: "Good Genes Lactic Acid Treatment", price: 85, url: "https://sundayriley.com/products/good-genes-lactic-acid-treatment", imageName: "skincare_jar_stone_branch", pregnancySafe: true),
        .init(concern: "pore", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Niacinamide 10% + Zinc 1%", price: 6, imageName: "serum_bottle_dropper", pregnancySafe: true),
        .init(concern: "pore", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "10% Niacinamide Booster", price: 53, url: "https://www.paulaschoice.com/10pct-niacinamide-booster/798.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true),
        .init(concern: "pore", tier: "Luxury", rank: 1, brand: "Drunk Elephant", name: "T.L.C. Framboos Glycolic Resurfacing Night Serum", price: 90, url: "https://www.drunkelephant.com/collections/serums/t.l.c.-framboos-glycolic-night-serum-999DE00000104.html", imageName: "skincare_jar_stone_branch", pregnancySafe: false),
    ]
}

/// Picks "What your skin needs": her three areas most in need of care, each with a Budget,
/// Balanced and Luxury product from the catalog.
enum ProductPicker {
    private static let issueNames: [String: (issue: String, solution: String, summary: String)] = [
        "moisture": ("Hydration", "Hydrating Serum", "Hydration is one of your lowest scores. A hydrating serum on damp skin, sealed in with moisturizer, is usually the quickest visible change; most people notice softer, plumper skin within two weeks."),
        "wrinkle": ("Fine Lines", "Line-Smoothing Treatment", "Fine lines are one of the areas with the most room to improve. Consistent use of a targeted treatment a few nights a week, plus daily SPF, softens their look over six to twelve weeks."),
        "dark_circle": ("Dark Circles", "Brightening Eye Cream", "The under-eye area is one of your lower scores. A gentle eye treatment morning and night, along with good sleep and hydration, helps the area look brighter and more rested."),
        "age_spot": ("Dark Spots", "Brightening Serum", "Uneven pigment is one of the areas with the most room to improve. A brightening serum in the morning, always paired with SPF, fades spots gradually over eight to twelve weeks."),
        "redness": ("Redness", "Calming Treatment", "Redness is one of your lower scores. Calming, barrier-supporting ingredients and a simple, fragrance-free routine help your skin settle and look more even."),
        "texture": ("Texture", "Gentle Exfoliant", "Texture is one of the areas with the most room to improve. A gentle exfoliant two or three nights a week smooths the surface, usually within three to four weeks."),
        "pore": ("Pores", "Pore-Refining Serum", "Pores are one of your lower scores. Keeping them clear and balancing oil makes them look smaller over a few weeks of consistent use."),
    ]
    private static let tiers = ["Budget", "Balanced", "Luxury"]
    private static let numerals = ["I", "II", "III"]

    static func recommendations(
        measures: [String: Int],
        consult: Consult?,
        profile: SkinProfile?,
        usedProducts: [UsedProduct],
        checkIns: [ProductCheckIn],
        catalog: [CatalogProduct] = ProductCatalog.shared.products
    ) -> [Recommendation] {
        // Her areas in order of need: the consult's priorities first, then lowest scores.
        var order: [String] = (consult?.concerns.map(\.key) ?? []).filter { issueNames[$0] != nil }
        let byScore = measures.filter { issueNames[$0.key] != nil }.sorted { $0.value < $1.value }.map(\.key)
        for key in byScore where !order.contains(key) { order.append(key) }
        guard !order.isEmpty else { return [] }

        let avoidActives = !(profile?.healthContext ?? []).filter { ["Pregnant", "Trying to conceive", "Breastfeeding"].contains($0) }.isEmpty
        let using = usedProducts.map { "\($0.brand) \($0.name)".lowercased() }
        let latestAnswer = Dictionary(checkIns.map { ($0.productName.lowercased(), $0.answer) }, uniquingKeysWith: { _, last in last })
        let avoided = latestAnswer.filter { $0.value == .irritating || $0.value == .stopped }.map(\.key)

        func matches(_ product: CatalogProduct, _ names: [String]) -> Bool {
            let full = product.fullName.lowercased()
            let short = product.name.lowercased()
            return names.contains { name in
                let n = name.trimmingCharacters(in: .whitespaces)
                return !n.isEmpty && (full.contains(n) || n.contains(short))
            }
        }

        var picked: [Recommendation] = []
        var shown = Set<String>()
        for key in order where picked.count < 3 {
            guard let info = issueNames[key] else { continue }
            let products: [Recommendation.Product] = tiers.compactMap { tier in
                catalog
                    .filter { $0.concern == key && $0.tier == tier }
                    .sorted { $0.rank < $1.rank }
                    .first { p in
                        (!avoidActives || p.pregnancySafe)
                            && !matches(p, using) && !matches(p, avoided)
                            && !shown.contains(p.fullName)
                    }
                    .map { p in
                        Recommendation.Product(
                            tier: tier, name: p.fullName, price: p.price,
                            imageName: p.imageName ?? "serum_bottle_dropper",
                            brand: p.brand, url: p.url.flatMap(URL.init(string:))
                        )
                    }
            }
            guard !products.isEmpty else { continue }
            products.forEach { shown.insert($0.name) }
            let summary = consult?.concerns.first { $0.key == key }?.summary ?? info.summary
            picked.append(Recommendation(
                numeral: numerals[picked.count], issue: info.issue, solution: info.solution,
                summary: summary, products: products
            ))
        }
        return picked
    }
}
