import SwiftUI

struct ChartPoint: Identifiable, Hashable {
    let id: UUID
    let label: String
    let value: Int
    let color: Color
    /// When the scan was taken. Nil for placeholder points (spaced evenly).
    let date: Date?

    init(id: UUID = UUID(), label: String, value: Int, color: Color, date: Date? = nil) {
        self.id = id
        self.date = date
        self.label = label
        self.value = value
        self.color = color
    }
}
