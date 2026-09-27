import SwiftUI

/// Seed content taken from the FACELIFT designs.
enum SampleData {
    static func rating(for score: Int) -> String {
        switch score {
        case 80...: "Very Good"
        case 70..<80: "Good"
        case 60..<70: "Fair"
        default: "Needs Care"
        }
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 1), 99)
    }

    /// Analysis categories, optionally shifted to represent an older or newer scan.
    static func categories(shift: Int = 0) -> [AnalysisCategory] {
        func metric(_ name: String, _ detail: String, _ score: Int) -> AnalysisCategory.Metric {
            AnalysisCategory.Metric(name: name, detail: detail, score: clamp(score + shift))
        }
        func category(_ kind: AnalysisCategory.Kind, _ title: String, _ score: Int, _ metrics: [AnalysisCategory.Metric], _ insight: String) -> AnalysisCategory {
            let shifted = clamp(score + shift)
            return AnalysisCategory(kind: kind, title: title, score: shifted, rating: rating(for: shifted), metrics: metrics, insight: insight)
        }

        return [
            category(.aging, "Aging & Structure", 74, [
                metric("Fine lines & wrinkles", "forehead, crow's feet, smile lines", 71),
                metric("Firmness & elasticity", "skin sagging, loss of bounce", 78),
                metric("Volume loss", "hollowing, contour changes", 82),
                metric("Under-eye", "dark circles, puffiness, fine lines", 65)
            ], "Honestly, your skin is holding up really well - think of it as being in its prime. You've got solid elasticity and good volume retention, which means things are bouncing back the way they should. The fine lines starting to show near your eyes and forehead are completely normal, and more importantly, you're catching them at exactly the right moment. A consistent retinol a few nights a week and daily SPF is genuinely all you need here. You're not behind - you're right on time."),
            category(.tone, "Tone & Clarity", 81, [
                metric("Hyperpigmentation & dark spots", "post-acne marks, hormonal patches", 84),
                metric("Sun spots & sun damage", "UV-induced discoloration, photoaging", 79),
                metric("Redness & rosacea", "flushing, visible capillaries, irritation", 77),
                metric("Dullness & radiance", "lackluster, tired-looking skin", 83)
            ], "Your tone is one of your strongest areas - it's even, clear and has a natural brightness a lot of people work hard for. There's a little early sun damage along your cheekbones and some mild redness around the nose, but nothing that's settled in. Daily SPF is doing the heavy lifting here, and a vitamin C in the morning will keep that glow exactly where it is. Protect what you've got and it'll stay this way."),
            category(.health, "Skin Health", 68, [
                metric("Hydration & barrier health", "dehydration, tight or flaky skin", 58),
                metric("Dryness vs. oiliness", "sebum balance, shine, dry patches", 72),
                metric("Pore size & congestion", "enlarged pores, blackheads, buildup", 65),
                metric("Acne & breakouts", "active pimples, cysts, hormonal acne", 74),
                metric("Skin texture", "roughness, bumps, unevenness", 63),
                metric("Sensitivity & reactivity", "stinging, redness from products", 70)
            ], "This is where your biggest opportunity is, and the good news is it moves fast. Your skin is thirsty - hydration and barrier health are pulling your score down, and that dehydration is also making texture and pores look more obvious than they really are. Think of it as the foundation: once your barrier is happy, everything else looks better too. A hyaluronic serum on damp skin and a simple moisturiser morning and night will show a visible difference within a couple of weeks.")
        ]
    }

    static let recommendations: [Recommendation] = [
        Recommendation(
            numeral: "I",
            issue: "Dehydration",
            solution: "Hyaluronic Acid Serum",
            summary: "Your scan detected significant moisture loss along your cheek zone, showing reduced water retention compared to baseline. Dehydration weakens your skin barrier and accelerates the appearance of fine lines - addressing it now will have the most immediate visible impact..",
            products: [
                .init(tier: "Budget", name: "The Ordinary Hyaluronic Acid 2% + B5", price: 9, imageName: "skincare_products_shower"),
                .init(tier: "Balanced", name: "Laneige Water Bank Hyaluronic Serum", price: 42, imageName: "skincare_jar_serum_dropper"),
                .init(tier: "Luxury", name: "SkinCeuticals Hydrating B5 Gel", price: 78, imageName: "serum_bottle_dropper")
            ]
        ),
        Recommendation(
            numeral: "II",
            issue: "Fine Lines",
            solution: "Retinol Eye Treatment",
            summary: "Early-stage dynamic lines were detected in the orbital area around both eyes, forming from repetitive expression movement and gradual collagen decline. At this stage they respond exceptionally well to targeted treatment - acting now meaningfully slows their development..",
            products: [
                .init(tier: "Budget", name: "Neutrogena Rapid Wrinkle Repair Retinol Eye Cream", price: 17, imageName: "skincare_bottles_gold"),
                .init(tier: "Balanced", name: "RoC Retinol Correxion Eye Cream", price: 34, imageName: "skincare_box_jar"),
                .init(tier: "Luxury", name: "Drunk Elephant A-Passioni Retinol Cream", price: 74, imageName: "eye_cream_jar_gold_lid")
            ]
        ),
        Recommendation(
            numeral: "III",
            issue: "Texture",
            solution: "Exfoliating Treatment",
            summary: "Uneven surface texture was detected around your nose and forehead, caused by buildup of dead skin cells and excess sebum. This is very treatable and typically responds visibly within two to three weeks of consistent chemical exfoliation..",
            products: [
                .init(tier: "Budget", name: "The Ordinary Glycolic Acid 7% Toning Solution", price: 10, imageName: "skincare_tube_box"),
                .init(tier: "Balanced", name: "Sunday Riley Good Genes Glycolic Treatment", price: 85, imageName: "skincare_jar_stone_branch"),
                .init(tier: "Luxury", name: "Dr. Dennis Gross Alpha Beta Peel Pads", price: 92, imageName: "exfoliating_pads_skincare")
            ]
        )
    ]

    static let scans: [Scan] = [
        Scan(id: UUID(), date: date(2026, 8, 28), portraitName: "blonde_woman_smiling_portrait",
             concerns: ["Dehydration", "Fine Lines", "Texture"], productsShopped: 2,
             categories: categories(), recommendations: recommendations),
        Scan(id: UUID(), date: date(2024, 4, 18), portraitName: "woman_touching_hair_portrait",
             concerns: ["Fine Lines", "Texture", "Dullness"], productsShopped: 1,
             categories: categories(shift: -6), recommendations: recommendations),
        Scan(id: UUID(), date: date(2024, 3, 2), portraitName: "woman_headshot_bangs",
             concerns: ["Dehydration", "Fine Lines", "Texture"], productsShopped: 0,
             categories: categories(shift: -14), recommendations: recommendations)
    ]

    static let chartPoints: [ChartPoint] = [
        ChartPoint(label: "Mar 2", value: 58, color: Palette.sky),
        ChartPoint(label: "Apr 18", value: 67, color: Palette.rose),
        ChartPoint(label: "Aug 12", value: 74, color: Palette.sage)
    ]

    static let usedProducts: [UsedProduct] = [
        UsedProduct(id: UUID(), brand: "Laneige", name: "Water Bank Serum", price: 38, tint: .sky),
        UsedProduct(id: UUID(), brand: "Sunday Riley", name: "Good Genes Treatment", price: 85, tint: .sage),
        UsedProduct(id: UUID(), brand: "CeraVe", name: "Eye Repair Cream", price: 16, tint: .rose)
    ]

    static let progressUpdate = "Your hydration has improved the most since your last scan - the Laneige serum is doing its job. Your cheek zone dehydration is down noticeably and your skin barrier feels stronger, which is already softening the look of texture around your nose. Keep your routine consistent for the next few weeks, and let the under-eye area be your next focus - that's where a gentle retinol will make the biggest difference."

    static let faq: [FAQItem] = [
        FAQItem(question: "How does the scan work?", answer: "FACELIFT reads your face through the front camera and looks at twelve markers across three areas - aging and structure, tone and clarity, and overall skin health. Each marker is scored from 0 to 100, and we turn those scores into plain-language insights and product recommendations matched to what your skin actually needs."),
        FAQItem(question: "How often should I scan?", answer: "Every two to four weeks is the sweet spot. Skin renews itself roughly every 28 days, so scanning on that rhythm shows real change instead of day-to-day noise. For the most accurate comparison, scan in similar lighting with a clean, bare face."),
        FAQItem(question: "What does my score mean?", answer: "Scores are relative to healthy skin for your age. 80 and above is Very Good, 70 to 79 is Good, and 60 to 69 is Fair. A lower score isn't a judgement - it simply points to where a small change in your routine will make the biggest visible difference."),
        FAQItem(question: "How do I cancel?", answer: "You can cancel any time from your device's subscription settings: open Settings, tap your name, choose Subscriptions, then select FACELIFT. You'll keep access until the end of your current billing period."),
        FAQItem(question: "Is my photo stored?", answer: "Your camera feed is analysed in the moment. We keep your scores and recommendations so you can track progress over time, but you're always in control - you can delete your scan history at any time from Privacy & Data.")
    ]

    static let skinGoalOptions: [String] = [
        "Anti-aging", "Hydration", "Even tone", "Clear skin", "Minimize pores", "Calm sensitivity", "Glow"
    ]
}
