import SwiftUI

struct ChartPoint: Identifiable, Hashable {
    let id: UUID
    let label: String
    let value: Int
    let color: Color

    init(label: String, value: Int, color: Color) {
        self.id = UUID()
        self.label = label
        self.value = value
        self.color = color
    }
}
