import SwiftUI

/// Content shown in the bottom insight sheet.
struct InsightContent: Identifiable {
    let id = UUID()
    let label: String
    let accent: Color
    let score: Int?
    let rating: String?
    let title: String?
    let text: String

    init(category: AnalysisCategory) {
        label = category.title.uppercased()
        accent = category.accent
        score = category.score
        rating = category.rating
        title = nil
        text = category.insight
    }

    init(label: String, accent: Color, title: String, text: String) {
        self.label = label
        self.accent = accent
        self.score = nil
        self.rating = nil
        self.title = title
        self.text = text
    }
}
