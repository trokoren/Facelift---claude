import Foundation

struct FAQItem: Identifiable, Hashable {
    let question: String
    let answer: String

    var id: String { question }
}
