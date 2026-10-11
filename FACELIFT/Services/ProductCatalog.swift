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
    /// "gentle" (fine for very sensitive skin), "regular" or "strong" (never for sensitive skin).
    var strength: String? = nil
    /// Skin types it suits ("dry", "oily", "combination", "normal"). Empty means all.
    var skinTypes: [String]? = nil
    /// "clinical", "natural" or "both". Empty is clinical.
    var approach: String? = nil
    /// Contains essential oils or fragrant botanicals.
    var essentialOils: Bool? = nil

    enum CodingKeys: String, CodingKey {
        case concern, tier, rank, brand, name, price, url, strength, approach
        case imageName = "image_name"
        case pregnancySafe = "pregnancy_safe"
        case skinTypes = "skin_types"
        case essentialOils = "essential_oils"
    }

    /// Which side of the Clinical to Natural slider it belongs to.
    func fits(side: String) -> Bool {
        let mine = approach ?? "clinical"
        return mine == "both" || mine == side
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
              let url = URL(string: "\(Backend.supabaseURL)/rest/v1/product_catalog?select=concern,tier,rank,brand,name,price,url,image_name,pregnancy_safe,strength,skin_types,approach,essential_oils&active=eq.true&order=concern,tier,rank")
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
        .init(concern: "moisture", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Hyaluronic Acid 2% + B5 (with Ceramides)", price: 10, url: "https://theordinary.com/en-us/hyaluronic-acid-2-b5-serum-with-ceramides-100637.html", imageName: "serum_bottle_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "moisture", tier: "Budget", rank: 2, brand: "The INKEY List", name: "Hyaluronic Acid Serum", price: 13, url: "https://www.theinkeylist.com/products/hyaluronic-acid-serum", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "moisture", tier: "Budget", rank: 3, brand: "Neutrogena", name: "Hydro Boost Water Gel", price: 30, url: "https://www.ulta.com/p/hydro-boost-hyaluronic-acid-water-gel-moisturizer-xlsImpprod12041835?sku=2284291", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle", skinTypes: ["oily", "combination", "normal"]),
        .init(concern: "moisture", tier: "Balanced", rank: 1, brand: "La Roche-Posay", name: "Hyalu B5 Pure Hyaluronic Acid Serum", price: 54, url: "https://www.laroche-posay.us/our-products/face/face-serum/hyalu-b5-pure-hyaluronic-acid-serum-hyaluB5serum.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "moisture", tier: "Balanced", rank: 2, brand: "Kiehl's", name: "Ultra Facial Cream with Squalane", price: 39, url: "https://www.kiehls.com/skincare/face-moisturizers/ultra-facial-cream-with-squalane/622.html", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle"),
        .init(concern: "moisture", tier: "Balanced", rank: 3, brand: "First Aid Beauty", name: "Ultra Repair Cream", price: 42, url: "https://www.dermstore.com/p/first-aid-beauty-ultra-repair-cream-6oz/17659261/", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle", skinTypes: ["dry", "normal"]),
        .init(concern: "moisture", tier: "Luxury", rank: 1, brand: "SkinCeuticals", name: "Hydrating B5 Gel", price: 95, url: "https://www.skinceuticals.com/skincare/hydrating-serums/hydrating-b5-gel/S39.html", imageName: "skincare_products_shower", pregnancySafe: true, strength: "gentle"),
        .init(concern: "moisture", tier: "Luxury", rank: 2, brand: "Tatcha", name: "The Dewy Skin Cream", price: 74, url: "https://www.sephora.com/product/the-dewy-skin-cream-P441101", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle", skinTypes: ["dry", "normal"]),
        .init(concern: "moisture", tier: "Luxury", rank: 3, brand: "Tatcha", name: "The Water Cream", price: 74, url: "https://www.sephora.com/product/the-water-cream-P418218", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle", skinTypes: ["oily", "combination", "normal"]),
        .init(concern: "wrinkle", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Granactive Retinoid 2% Emulsion", price: 12, url: "https://theordinary.com/en-us/granactive-retinoid-2-emulsion-serum-100419.html", imageName: "skincare_tube_box", pregnancySafe: false, strength: "regular"),
        .init(concern: "wrinkle", tier: "Budget", rank: 2, brand: "The Ordinary", name: "Multi-Peptide + HA Serum", price: 20, imageName: "serum_bottle_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "wrinkle", tier: "Budget", rank: 3, brand: "CeraVe", name: "Resurfacing Retinol Serum", price: 22, url: "https://www.dermstore.com/p/cerave-resurfacing-retinol-serum-1-oz/13906946/", imageName: "serum_bottle_dropper", pregnancySafe: false, strength: "regular"),
        .init(concern: "wrinkle", tier: "Balanced", rank: 1, brand: "RoC", name: "Retinol Correxion Line Smoothing Night Serum Capsules", price: 25, url: "https://www.rocskincare.com/products/retinol-correxion-line-smoothing-night-serum-capsules", imageName: "skincare_box_jar", pregnancySafe: false, strength: "regular"),
        .init(concern: "wrinkle", tier: "Balanced", rank: 2, brand: "Drunk Elephant", name: "Protini Polypeptide Cream", price: 72, url: "https://www.drunkelephant.com/collections/moisturizers/protini-polypeptide-cream-856556004739.html", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle"),
        .init(concern: "wrinkle", tier: "Balanced", rank: 3, brand: "Olay", name: "Regenerist Micro-Sculpting Cream Fragrance Free", price: 37, url: "https://www.olay.com/products/regenerist-micro-sculpting-cream-moisturizer-fragrance-free", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle"),
        .init(concern: "wrinkle", tier: "Balanced", rank: 4, brand: "Paula's Choice", name: "CLINICAL 1% Retinol Treatment", price: 65, url: "https://www.dermstore.com/p/paula-s-choice-clinical-1-retinol-treatment-30ml/11174243/", imageName: "skincare_jar_serum_dropper", pregnancySafe: false, strength: "strong"),
        .init(concern: "wrinkle", tier: "Luxury", rank: 1, brand: "Drunk Elephant", name: "A-Passioni Retinol Cream", price: 76, url: "https://drunkelephant.com/collections/retinols/a-passioni-retinol-cream-812343032392.html", imageName: "eye_cream_jar_gold_lid", pregnancySafe: false, strength: "strong"),
        .init(concern: "wrinkle", tier: "Luxury", rank: 2, brand: "Estée Lauder", name: "Advanced Night Repair Serum", price: 88, url: "https://www.esteelauder.com/product/689/77491/product-catalog/skincare/repair-serum/advanced-night-repair-serum/synchronized-multi-recovery-complex", imageName: "skincare_bottles_gold", pregnancySafe: true, strength: "gentle"),
        .init(concern: "wrinkle", tier: "Luxury", rank: 3, brand: "Shani Darden", name: "Retinol Reform with 1% Encapsulated Retinol", price: 75, url: "https://www.sephora.com/product/retinol-reform-with-1-encapsulated-retinol-P517668", imageName: "serum_bottle_dropper", pregnancySafe: false, strength: "strong"),
        .init(concern: "dark_circle", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Caffeine Solution 5% + EGCG Eye Serum", price: 9, url: "https://theordinary.com/en-us/caffeine-solution-5-egcg-eye-serum-100412.html", imageName: "serum_bottle_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "dark_circle", tier: "Budget", rank: 2, brand: "CeraVe", name: "Eye Repair Cream", price: 20, url: "https://www.dermstore.com/p/cerave-eye-repair-cream-0.5-oz./12901642/", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle"),
        .init(concern: "dark_circle", tier: "Budget", rank: 3, brand: "The INKEY List", name: "Caffeine Eye Cream", price: 14, url: "https://www.theinkeylist.com/products/caffeine-eye-cream", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle"),
        .init(concern: "dark_circle", tier: "Balanced", rank: 1, brand: "Clinique", name: "All About Eyes Eye Cream with Vitamin C", price: 39, url: "https://www.clinique.com/product/1683/4769/skincare/eye-care/all-about-eyestm-eye-cream-with-vitamin-c", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle"),
        .init(concern: "dark_circle", tier: "Balanced", rank: 2, brand: "Kiehl's", name: "Creamy Eye Treatment with Avocado", price: 40, url: "https://www.ulta.com/p/creamy-eye-treatment-with-avocado-pimprod2002975?sku=2536674", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle"),
        .init(concern: "dark_circle", tier: "Luxury", rank: 1, brand: "Estée Lauder", name: "Advanced Night Repair Eye Supercharged Gel-Creme", price: 78, url: "https://www.esteelauder.com/product/685/104163/product-catalog/skincare/eye-cream-treatment/advanced-night-repair-eye-supercharged-gel-creme/synchronized-multi-recovery-eye-cream", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "dark_circle", tier: "Luxury", rank: 2, brand: "Tatcha", name: "The Silk Peony Line-Smoothing Eye Cream", price: 69, url: "https://www.sephora.com/product/tatcha-the-silk-peony-melting-eye-cream-P509794", imageName: "eye_cream_jar_gold_lid", pregnancySafe: true, strength: "gentle"),
        .init(concern: "age_spot", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Alpha Arbutin 2% + HA", price: 12, imageName: "serum_bottle_dropper", pregnancySafe: false, strength: "regular"),
        .init(concern: "age_spot", tier: "Budget", rank: 2, brand: "The Ordinary", name: "Vitamin C Suspension 23% + HA Spheres 2%", price: 8, imageName: "skincare_tube_box", pregnancySafe: true, strength: "strong"),
        .init(concern: "age_spot", tier: "Budget", rank: 3, brand: "Good Molecules", name: "Discoloration Correcting Serum", price: 12, url: "https://www.ulta.com/p/discoloration-correcting-serum-pimprod2023928?sku=2582306", imageName: "serum_bottle_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "age_spot", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "C15 Super Booster", price: 59, url: "https://www.paulaschoice.com/c15-brightening-super-booster/808.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "regular"),
        .init(concern: "age_spot", tier: "Luxury", rank: 1, brand: "SkinCeuticals", name: "C E Ferulic", price: 185, url: "https://www.skinceuticals.com/skincare/vitamin-c-serums/c-e-ferulic-with-15-l-ascorbic-acid/S17.html", imageName: "skincare_bottles_gold", pregnancySafe: true, strength: "regular"),
        .init(concern: "age_spot", tier: "Luxury", rank: 2, brand: "Drunk Elephant", name: "C-Firma Fresh Vitamin-C Day Serum", price: 79, url: "https://www.sephora.com/product/c-firma-day-serum-P400259", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "regular"),
        .init(concern: "age_spot", tier: "Luxury", rank: 3, brand: "SkinCeuticals", name: "Discoloration Defense", price: 115, url: "https://www.skinceuticals.com/skincare/serums/discoloration-defense/S25.html", imageName: "skincare_bottles_gold", pregnancySafe: true, strength: "regular"),
        .init(concern: "age_spot", tier: "Luxury", rank: 4, brand: "Murad", name: "Rapid Dark Spot Correcting Serum", price: 88, url: "https://www.dermstore.com/p/murad-rapid-dark-spot-correcting-serum-30ml/12739129/", imageName: "serum_bottle_dropper", pregnancySafe: false, strength: "regular"),
        .init(concern: "redness", tier: "Budget", rank: 1, brand: "La Roche-Posay", name: "Cicaplast Balm B5+", price: 21, url: "https://www.laroche-posay.us/our-products/body/body-lotion/cicaplast-balm-b5-for-dry-skin-irritations-cicaplastbalmb5.html", imageName: "skincare_tube_box", pregnancySafe: true, strength: "gentle"),
        .init(concern: "redness", tier: "Budget", rank: 2, brand: "La Roche-Posay", name: "Toleriane Double Repair Face Moisturizer", price: 25, url: "https://www.laroche-posay.us/our-products/face/face-moisturizer/toleriane-double-repair-face-moisturizer-tolerianedoublerepair.html", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle"),
        .init(concern: "redness", tier: "Budget", rank: 3, brand: "The Ordinary", name: "Azelaic Acid Suspension 10%", price: 12, imageName: "skincare_tube_box", pregnancySafe: true, strength: "regular"),
        .init(concern: "redness", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "10% Azelaic Acid Booster", price: 42, url: "https://www.paulaschoice.com/10pct-azelaic-acid-booster/775.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "regular"),
        .init(concern: "redness", tier: "Balanced", rank: 2, brand: "Avène", name: "Tolerance Control Soothing Skin Recovery Cream", price: 40, url: "https://www.dermstore.com/p/avene-tolerance-control-soothing-skin-recovery-cream-for-sensitive-skin-40ml/13169864/", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle"),
        .init(concern: "redness", tier: "Luxury", rank: 1, brand: "Dr. Jart+", name: "Cicapair Soothing Color Correcting Treatment SPF 30", price: 54, url: "https://www.sephora.com/product/cicapair-soothing-color-correcting-treatment-spf-30-with-centella-asiatica-extracts-P517003", imageName: "skincare_box_jar", pregnancySafe: true, strength: "gentle"),
        .init(concern: "redness", tier: "Luxury", rank: 2, brand: "SkinCeuticals", name: "Phyto Corrective Gel", price: 85, url: "https://www.skinceuticals.com/skincare/hydrating-serums/phyto-corrective-gel/S58.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "gentle"),
        .init(concern: "texture", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Lactic Acid 10% + HA", price: 9, imageName: "serum_bottle_dropper", pregnancySafe: true, strength: "regular"),
        .init(concern: "texture", tier: "Budget", rank: 2, brand: "The INKEY List", name: "PHA Toner", price: 18, url: "https://www.theinkeylist.com/products/pha-toner", imageName: "skincare_products_shower", pregnancySafe: true, strength: "gentle"),
        .init(concern: "texture", tier: "Budget", rank: 3, brand: "The Ordinary", name: "Glycolic Acid 7% Exfoliating Toner", price: 9, imageName: "skincare_products_shower", pregnancySafe: true, strength: "regular"),
        .init(concern: "texture", tier: "Budget", rank: 4, brand: "Glow Recipe", name: "Watermelon Glow PHA + BHA Pore-Tight Toner", price: 16, url: "https://www.sephora.com/product/glow-recipe-watermelon-glow-pha-bha-pore-tight-toner-P458219", imageName: "skincare_products_shower", pregnancySafe: false, strength: "regular", skinTypes: ["oily", "combination", "normal"]),
        .init(concern: "texture", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "Skin Perfecting 2% BHA Liquid Exfoliant", price: 37, url: "https://www.paulaschoice.com/skin-perfecting-2pct-bha-liquid-exfoliant/201-2010.html", imageName: "skincare_products_shower", pregnancySafe: false, strength: "regular"),
        .init(concern: "texture", tier: "Balanced", rank: 2, brand: "Pixi", name: "Glow Tonic", price: 29, imageName: "skincare_products_shower", pregnancySafe: true, strength: "regular"),
        .init(concern: "texture", tier: "Balanced", rank: 3, brand: "Paula's Choice", name: "Skin Perfecting 8% AHA Gel Exfoliant", price: 34, url: "https://www.dermstore.com/p/paula-s-choice-skin-perfecting-8-percent-aha-gel-exfoliant/11289059/", imageName: "skincare_tube_box", pregnancySafe: true, strength: "regular", skinTypes: ["oily", "combination", "normal"]),
        .init(concern: "texture", tier: "Luxury", rank: 1, brand: "Dr. Dennis Gross", name: "Alpha Beta Universal Daily Peel", price: 94, url: "https://www.drdennisgross.com/alpha-beta-universal-daily-peel/999DDG0000001.html", imageName: "exfoliating_pads_skincare", pregnancySafe: false, strength: "strong"),
        .init(concern: "texture", tier: "Luxury", rank: 2, brand: "Sunday Riley", name: "Good Genes Lactic Acid Treatment", price: 85, url: "https://sundayriley.com/products/good-genes-lactic-acid-treatment", imageName: "skincare_jar_stone_branch", pregnancySafe: true, strength: "regular"),
        .init(concern: "texture", tier: "Luxury", rank: 3, brand: "Tatcha", name: "The Rice Polish Foaming Enzyme Powder", price: 69, url: "https://www.sephora.com/product/polished-rice-enzyme-powder-P426340", imageName: "skincare_jar_stone_branch", pregnancySafe: true, strength: "gentle"),
        .init(concern: "pore", tier: "Budget", rank: 1, brand: "The Ordinary", name: "Niacinamide 10% + Zinc 1%", price: 6, imageName: "serum_bottle_dropper", pregnancySafe: true, strength: "regular"),
        .init(concern: "pore", tier: "Budget", rank: 2, brand: "CeraVe", name: "Renewing SA Cleanser", price: 16, url: "https://www.dermstore.com/p/cerave-renewing-sa-facial-cleanser-8-oz/13906957/", imageName: "skincare_products_shower", pregnancySafe: true, strength: "regular"),
        .init(concern: "pore", tier: "Budget", rank: 3, brand: "The Ordinary", name: "Salicylic Acid 2% Solution", price: 7, imageName: "serum_bottle_dropper", pregnancySafe: false, strength: "regular", skinTypes: ["oily", "combination"]),
        .init(concern: "pore", tier: "Budget", rank: 4, brand: "Glow Recipe", name: "Watermelon Glow PHA + BHA Pore-Tight Toner", price: 16, url: "https://www.sephora.com/product/glow-recipe-watermelon-glow-pha-bha-pore-tight-toner-P458219", imageName: "skincare_products_shower", pregnancySafe: false, strength: "regular", skinTypes: ["oily", "combination", "normal"]),
        .init(concern: "pore", tier: "Balanced", rank: 1, brand: "Paula's Choice", name: "10% Niacinamide Booster", price: 53, url: "https://www.paulaschoice.com/10pct-niacinamide-booster/798.html", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "regular"),
        .init(concern: "pore", tier: "Balanced", rank: 2, brand: "Paula's Choice", name: "CLINICAL Niacinamide 20% Treatment", price: 59, url: "https://www.dermstore.com/p/paula-s-choice-clinical-20-niacinamide-treatment-20ml/12902766/", imageName: "skincare_jar_serum_dropper", pregnancySafe: true, strength: "regular", skinTypes: ["oily", "combination", "normal"]),
        .init(concern: "pore", tier: "Luxury", rank: 1, brand: "Drunk Elephant", name: "T.L.C. Framboos Glycolic Resurfacing Night Serum", price: 90, url: "https://www.drunkelephant.com/collections/serums/t.l.c.-framboos-glycolic-night-serum-999DE00000104.html", imageName: "skincare_jar_stone_branch", pregnancySafe: false, strength: "strong"),
        .init(concern: "pore", tier: "Luxury", rank: 2, brand: "Tatcha", name: "The Rice Polish Foaming Enzyme Powder", price: 69, url: "https://www.sephora.com/product/polished-rice-enzyme-powder-P426340", imageName: "skincare_jar_stone_branch", pregnancySafe: true, strength: "gentle"),
        .init(concern: "pore", tier: "Luxury", rank: 3, brand: "SkinCeuticals", name: "Blemish + Age Defense", price: 115, url: "https://www.dermstore.com/p/skinceuticals-blemish-and-age-defense-serum/11289606/", imageName: "serum_bottle_dropper", pregnancySafe: false, strength: "regular", skinTypes: ["oily", "combination"]),
    ]
}

/// Picks "What your skin needs": her three areas most in need of care, each with a Budget,
/// Balanced and Luxury product from the catalog that suits her skin type, sensitivity and
/// health context. When a tier has several good fits, scans take turns between them so she
/// sees fresh options over time.
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
        rotation: Int = 0,
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

        // Skin type: what the consult measured, else what she told us.
        let typeWords = ["dry", "oily", "combination", "normal"]
        let measured = consult?.skinType.label.lowercased() ?? ""
        let told = profile?.skinType?.lowercased() ?? ""
        let skinType = typeWords.first { measured.contains($0) } ?? typeWords.first { told.contains($0) }
        // Sensitive skin never sees strong products; very sensitive skin sees gentle ones first.
        let verySensitive = profile?.sensitivity == "Yes, very sensitive" || measured.contains("sensitive") || told.contains("sensitive")
        let sensitive = verySensitive || profile?.sensitivity == "Sometimes"
        // Essential oils: never for sensitive skin or pregnancy, and never for redness (the
        // advice there is a simple, fragrance-free routine). Everyone else sees a patch-test note.
        let avoidEssentialOils = sensitive || avoidActives
        let approach = profile?.approach ?? .balanced

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
            let products: [Recommendation.Product] = tiers.enumerated().compactMap { tierIndex, tier in
                let eligible = catalog
                    .filter { $0.concern == key && $0.tier == tier }
                    .filter { p in
                        let oils = p.essentialOils == true
                        return (!avoidActives || p.pregnancySafe)
                            && !(oils && (avoidEssentialOils || key == "redness"))
                            && !(sensitive && p.strength == "strong")
                            && (skinType == nil || (p.skinTypes ?? []).isEmpty || p.skinTypes!.contains(skinType!))
                            && !matches(p, using) && !matches(p, avoided)
                            && !shown.contains(p.fullName)
                    }
                    .sorted { a, b in
                        if verySensitive, (a.strength == "gentle") != (b.strength == "gentle") { return a.strength == "gentle" }
                        return a.rank < b.rank
                    }
                // Her Clinical to Natural setting.
                var fits = eligible
                if let side = approach.side(forTierAt: tierIndex, slot: picked.count + rotation) {
                    let onSide = eligible.filter { $0.fits(side: side) }
                    fits = onSide.isEmpty && !approach.isStrict ? eligible : onSide
                }
                // Very sensitive skin: only the gentle ones, when the tier has any.
                if verySensitive, fits.contains(where: { $0.strength == "gentle" }) {
                    fits = fits.filter { $0.strength == "gentle" }
                }
                guard !fits.isEmpty else { return nil }
                return Optional(fits[rotation % fits.count])
                    .map { p in
                        Recommendation.Product(
                            tier: tier, name: p.fullName, price: p.price,
                            imageName: p.imageName ?? "serum_bottle_dropper",
                            brand: p.brand, url: p.url.flatMap(URL.init(string:)),
                            essentialOils: p.essentialOils == true ? true : nil
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
