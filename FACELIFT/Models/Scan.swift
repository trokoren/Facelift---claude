import Foundation

struct Scan: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let portraitName: String?
    let concerns: [String]
    var productsShopped: Int
    let categories: [AnalysisCategory]
    let recommendations: [Recommendation]
    /// Written results (scans made with the consult). Older and sample scans have none.
    var consult: Consult? = nil
    /// YouCam measurements behind the consult, 0-100, higher is healthier.
    var measures: [String: Int] = [:]
    /// Placeholder scans shipped with the app. Never saved and never charted.
    var isSample: Bool = false

    var formattedDate: String {
        date.formatted(.dateTime.month(.wide).day().year())
    }

    /// Short concern names for chips ("Redness", "Pores"). Consult scans use the measured
    /// areas; older scans keep their saved names.
    var shortConcerns: [String] {
        guard let consult, !consult.concerns.isEmpty else { return concerns }
        var seen = Set<String>()
        return consult.concerns.map { Measure.name($0.key) }.filter { seen.insert($0).inserted }
    }

    /// The five-type answer from the consult ("Combination", "Oily"...), if it names one.
    var measuredSkinType: String? {
        guard let label = consult?.skinType.label.lowercased() else { return nil }
        for type in ["combination", "oily", "dry", "sensitive", "normal"] where label.contains(type) {
            return type.capitalized
        }
        return nil
    }

    var metaLine: String {
        if consult != nil {
            let shopped = productsShopped > 0 ? " · \(productsShopped) \(productsShopped == 1 ? "product" : "products") shopped" : ""
            return "Skin Score \(overallScore)" + shopped
        }
        let recs = recommendations.count
        let recWord = recs == 1 ? "recommendation" : "recommendations"
        let productWord = productsShopped == 1 ? "product" : "products"
        return "\(recs) \(recWord) · \(productsShopped) \(productWord) shopped"
    }

    /// The Skin Score: mean of the measurements (or of the category scores on older scans).
    /// Used for the results header and the progress chart.
    var overallScore: Int {
        if !measures.isEmpty {
            let total = measures.values.reduce(0, +)
            return Int((Double(total) / Double(measures.count)).rounded())
        }
        guard !categories.isEmpty else { return 0 }
        let total = categories.map(\.score).reduce(0, +)
        return Int((Double(total) / Double(categories.count)).rounded())
    }
}
