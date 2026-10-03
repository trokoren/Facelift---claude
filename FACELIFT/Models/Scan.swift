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

    var metaLine: String {
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
