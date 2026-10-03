import Foundation

/// Her answer to "How's it going?" about one product in her routine.
struct ProductCheckIn: Identifiable, Hashable, Codable {
    enum Answer: String, CaseIterable, Codable {
        case loving
        case unsure
        case irritating
        case stopped

        var label: String {
            switch self {
            case .loving: "Loving it"
            case .unsure: "Not sure yet"
            case .irritating: "Irritating"
            case .stopped: "Stopped using"
            }
        }
    }

    var id: UUID = UUID()
    let productID: UUID
    let productName: String
    var date: Date = Date()
    let answer: Answer
    var note: String = ""
}
