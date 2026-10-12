import Foundation

enum AppTab: Hashable, CaseIterable {
    case scan
    case mySkin
    case shop
    case progress
    case account

    var title: String {
        switch self {
        case .scan: "Scan"
        case .mySkin: "My Skin"
        case .shop: "Shop"
        case .progress: "Progress"
        case .account: "Account"
        }
    }
}
