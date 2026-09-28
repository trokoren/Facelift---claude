import Foundation

enum MySkinRoute: Hashable {
    case scan(id: UUID, isFresh: Bool)
}

enum AccountRoute: Hashable {
    case help
    case privacy
    case policy
}
