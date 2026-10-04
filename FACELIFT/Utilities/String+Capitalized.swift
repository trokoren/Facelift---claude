import Foundation

extension String {
    /// "combination skin" -> "Combination skin"
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
