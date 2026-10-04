import Foundation

/// The general guide to each skin type, shown when she taps "Dive in" on her skin type.
/// Written once (free and instant), and paired in the app with what her own consultation said.
enum SkinTypeGuide {
    struct Part: Hashable {
        let title: String
        let text: String
    }

    /// Picks the guide that matches the consultation's label ("Combination, oily-leaning...").
    static func parts(for label: String) -> [Part] {
        let lower = label.lowercased()
        if lower.contains("combination") { return combination }
        if lower.contains("oily") { return oily }
        if lower.contains("dry") { return dry }
        if lower.contains("sensitive") { return sensitive }
        return normal
    }

    static let combination: [Part] = [
        Part(title: "What it means", text: "Combination skin runs two ways at once. The T-zone (forehead, nose and chin) has more active oil glands, so it gets shiny and congested, while the cheeks and jawline produce less oil and can feel normal, or even dry and tight. It is one of the most common skin types, and it is very manageable once your routine treats each zone for what it needs."),
        Part(title: "How it shows up day to day", text: "You may look fresh in the morning and shiny through the center of your face by midday. Pores tend to look larger on the nose and forehead, and that is where clogged pores and the odd breakout like to appear. Your cheeks might soak up moisturizer quickly, or feel tight after cleansing."),
        Part(title: "What it loves", text: "Gentle, non-stripping cleansers. Lightweight hydration like hyaluronic acid and gel creams that never feel heavy. Niacinamide, which helps balance oil and refine the look of pores. A little exfoliation on the T-zone a few times a week, such as salicylic acid or lactic acid. Many people with combination skin do best with a lighter moisturizer on the T-zone and a richer one on the cheeks."),
        Part(title: "What to go easy on", text: "Harsh, foaming cleansers and alcohol-heavy toners. Stripping the oily zones makes them produce more oil, and it leaves the drier areas tighter. Heavy oils and thick creams all over the face can congest the T-zone, so keep the richer textures where your skin is drier."),
        Part(title: "Through the seasons", text: "Combination skin shifts with the weather. Summer heat tends to push it oilier, so lighter textures and more balancing steps help. Cold, dry air can make the cheeks flaky, so add hydration there. Adjusting your routine a little each season is normal and keeps everything in balance."),
    ]

    static let oily: [Part] = [
        Part(title: "What it means", text: "Oily skin makes more sebum, the natural oil that keeps skin soft and protected. A bit of extra oil is not a flaw. It often means your skin keeps its bounce longer and shows fine lines later. The goal is balance, not dryness."),
        Part(title: "How it shows up day to day", text: "Shine can appear across your whole face, not just the T-zone, often within a few hours of washing. Pores tend to look more visible, and makeup can slide or fade by the afternoon. Clogged pores and occasional breakouts are more likely when oil and dead skin build up together."),
        Part(title: "What it loves", text: "A gentle gel or foam cleanser morning and night. Salicylic acid, which works inside the pore to keep it clear. Niacinamide to balance oil and refine texture. Lightweight, oil-free hydration, because oily skin still needs water, and skipping moisturizer often makes it produce more oil."),
        Part(title: "What to go easy on", text: "Scrubbing hard, over-washing or stacking several drying products at once. These can irritate the skin and trigger more oil. Very rich creams and heavy oils can clog pores, so choose textures labeled non-comedogenic."),
        Part(title: "Through the seasons", text: "Heat and humidity usually bring more shine, so summer is a good time for lighter layers and an extra exfoliating night. In winter you may need a slightly richer moisturizer, even with oily skin. Oil production also tends to ease gradually over the years."),
    ]

    static let dry: [Part] = [
        Part(title: "What it means", text: "Dry skin makes less natural oil, so its protective barrier has less to hold water in. That can leave it feeling tight, looking a little dull and showing fine lines more easily. With the right care it can look soft, smooth and luminous."),
        Part(title: "How it shows up day to day", text: "Tightness after cleansing is the classic sign, along with rough or flaky patches, especially around the nose, cheeks and mouth. Makeup can cling to dry spots. Pores usually look small, and breakouts are less common."),
        Part(title: "What it loves", text: "Cream or milk cleansers that leave skin feeling comfortable. Layering: a hydrating serum with hyaluronic acid or glycerin on damp skin, then a moisturizer with ceramides and fatty acids to seal it in. Gentle lactic acid once or twice a week to soften flakes. Facial oils or balms at night can be lovely for dry skin."),
        Part(title: "What to go easy on", text: "Foaming cleansers, hot water, fragranced products and strong exfoliants, which strip what little oil your skin has. Introduce retinoids or acids slowly and buffer them with moisturizer so the barrier stays calm."),
        Part(title: "Through the seasons", text: "Cold air and indoor heating are the hardest on dry skin, so winter is the time for richer creams and an extra layer of hydration. A humidifier at night helps too. In warmer, humid weather you can lighten up a little."),
    ]

    static let sensitive: [Part] = [
        Part(title: "What it means", text: "Sensitive skin reacts more easily to products, weather and friction. It usually means the skin's barrier is more delicate, so irritants get in more easily and moisture gets out. Sensitive skin can also be dry, oily or combination at the same time."),
        Part(title: "How it shows up day to day", text: "Redness, flushing, stinging or itching after new products, temperature changes or rubbing. Some products feel fine one day and tingle the next. Your skin may need longer to calm down after a reaction."),
        Part(title: "What it loves", text: "Short, simple routines with few ingredients. Fragrance-free, gentle cleansers and moisturizers. Calming ingredients like centella, panthenol, niacinamide at low strength, oat and ceramides. Patch testing anything new on a small area for a few days first."),
        Part(title: "What to go easy on", text: "Fragrance, essential oils, high-strength acids, physical scrubs and alcohol-heavy toners. Add actives one at a time, at the lowest strength, a couple of nights a week, and build up only if your skin stays calm."),
        Part(title: "Through the seasons", text: "Wind, cold and sudden temperature changes can all trigger flare-ups, so a protective moisturizer matters more in winter. Heat can bring flushing in summer. Keeping your routine steady, rather than changing many products at once, keeps sensitive skin happiest."),
    ]

    static let normal: [Part] = [
        Part(title: "What it means", text: "Normal skin is well balanced: not very oily, not very dry and rarely reactive. Its barrier is doing its job, holding water in and keeping irritants out. The goal is to keep it that way."),
        Part(title: "How it shows up day to day", text: "Skin feels comfortable through the day, with little shine or tightness. Pores are small to medium, and breakouts are occasional. Texture and tone usually look even."),
        Part(title: "What it loves", text: "A gentle cleanser, a hydrating serum, a moisturizer suited to the season and consistency. Antioxidants like vitamin C in the morning help protect your skin's glow, and a retinoid or gentle exfoliant a few nights a week keeps texture smooth as you go."),
        Part(title: "What to go easy on", text: "Over-complicating it. Piling on many actives at once is the most common way to throw balanced skin off. Add one new thing at a time and give it a few weeks."),
        Part(title: "Through the seasons", text: "Normal skin can lean a little dry in winter and a little oily in summer. Swapping to a richer moisturizer in the cold months and a lighter one in the warm months is usually all it needs."),
    ]
}
