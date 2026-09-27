import Foundation

struct Scan: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let portraitName: String?
    let concerns: [String]
    var productsShopped: Int
    let categories: [AnalysisCategory]
    let recommendations: [Recommendation]

    var formattedDate: String {
        date.formatted(.dateTime.month(.wide).day().year())
    }

    var metaLine: String {
        let recs = recommendations.count
        let recWord = recs == 1 ? "recommendation" : "recommendations"
        let productWord = productsShopped == 1 ? "product" : "products"
        return "\(recs) \(recWord) · \(productsShopped) \(productWord) shopped"
    }

    /// Mean of the category scores, used for the progress chart.
    var overallScore: Int {
        guard !categories.isEmpty else { return 0 }
        let total = categories.map(\.score).reduce(0, +)
        return Int((Double(total) / Double(categories.count)).rounded())
    }
}
