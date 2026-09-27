import Foundation

enum AppTab: Hashable, CaseIterable {
    case scan
    case mySkin
    case progress
    case account

    var title: String {
        switch self {
        case .scan: "Scan"
        case .mySkin: "My Skin"
        case .progress: "Progress"
        case .account: "Account"
        }
    }
}
