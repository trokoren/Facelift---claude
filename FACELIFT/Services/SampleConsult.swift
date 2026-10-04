import Foundation

/// A realistic consultation, used only as the blurred preview behind the paywall in
/// onboarding (before her own results exist). Never saved and never charted.
enum SampleConsult {
    static let scan: Scan = {
        var scan = Scan(
            id: UUID(),
            date: Date(),
            portraitName: nil,
            concerns: ["Hydration", "Pores", "Dark circles"],
            productsShopped: 0,
            categories: [],
            recommendations: SampleData.recommendations,
            isSample: true
        )
        scan.consult = consult
        scan.measures = ["moisture": 62, "pore": 68, "dark_circle": 71, "wrinkle": 78, "texture": 82, "redness": 84, "age_spot": 86]
        return scan
    }()

    static let consult: Consult? = try? JSONDecoder().decode(Consult.self, from: Data(json.utf8))

    private static let json = """
    {
      "intro": "Your skin has a healthy, even base with good elasticity. Our main focus is hydration, especially across the cheeks.",
      "skinType": {
        "label": "Combination",
        "explanation": "Your T-zone produces more sebum while your cheeks run drier. Balance will do more for you than strong actives."
      },
      "strengths": [
        { "title": "Even tone", "detail": "Pigmentation is minimal and evenly distributed." },
        { "title": "Refined texture", "detail": "The surface of your skin is smooth, with very little roughness." },
        { "title": "Calm skin", "detail": "Redness is low across your whole face." }
      ],
      "concerns": [
        {
          "key": "moisture", "title": "Hydration", "severity": "moderate",
          "summary": "Your cheeks are holding less water than the rest of your face.",
          "seen": "We see slight tightness and fine dehydration lines across both cheeks.",
          "why": "A stressed barrier lets water escape faster. Hot showers and foaming cleansers make it worse.",
          "todo": "Apply a hyaluronic acid serum to damp skin morning and evening, then seal it with a ceramide moisturizer.",
          "expect": "Skin should feel more comfortable by week 2, with visibly plumper cheeks by week 6."
        },
        {
          "key": "pore", "title": "Pores", "severity": "mild",
          "summary": "Pores are slightly more visible through the nose and inner cheeks.",
          "seen": "We see enlarged pores along the nose and where it meets the cheeks.",
          "why": "Excess sebum stretches the pore opening. Heavy, occlusive products can add to congestion.",
          "todo": "Use a 2% salicylic acid toner on the T-zone two to three evenings a week, before moisturizer.",
          "expect": "Pores should look clearer by week 2 and more refined by week 6."
        },
        {
          "key": "dark_circle", "title": "Dark circles", "severity": "mild",
          "summary": "Light shadowing under both eyes.",
          "seen": "We see soft shadowing in the inner corners under both eyes.",
          "why": "Thin under-eye skin shows what sits beneath it. Short sleep and screen strain deepen it.",
          "todo": "Pat on a caffeine and peptide eye cream each morning, using your ring finger.",
          "expect": "Expect a brighter look by week 2 and steadier improvement by week 6."
        }
      ],
      "watch": { "title": "Early fine lines", "detail": "Your skin is firm now. Steady hydration keeps the area around your eyes smooth." },
      "plan": {
        "focus": "Restore hydration and balance your T-zone.",
        "morning": ["Gentle cleanser", "Hyaluronic acid serum", "Caffeine eye cream", "Ceramide moisturizer"],
        "evening": ["Gentle cleanser", "Salicylic acid toner (T-zone)", "Hyaluronic acid serum", "Ceramide moisturizer"]
      }
    }
    """
}
