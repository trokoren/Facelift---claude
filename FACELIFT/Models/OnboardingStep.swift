import Foundation

/// Every screen of the first-run flow, in order.
enum OnboardingStep: Int, CaseIterable, Hashable {
    case splash
    case tracking
    case hero
    case age
    case skinType
    case science
    case painPoints
    case sensitivity
    case notAlone
    case mainGoal
    case results28
    case budget
    case healthContext
    case reviewAsk
    case spfHabits
    case currentRoutine
    case location
    case notifications
    case readyToScan
    case scanInstructions
    case cameraPermission
    case scanLoading
    case paywallPreview
    case paywall

    /// Steps that draw the thin rose progress bar along the top edge.
    var showsProgress: Bool {
        switch self {
        case .splash, .tracking, .readyToScan, .cameraPermission, .scanLoading, .paywallPreview, .paywall:
            false
        default:
            true
        }
    }

    /// Steps with a back chevron in the top-left corner.
    var showsBack: Bool {
        switch self {
        case .splash, .tracking, .hero, .readyToScan, .scanInstructions, .scanLoading, .paywallPreview, .paywall:
            false
        default:
            true
        }
    }

    /// Steps rendered on the dark palette (status bar becomes light).
    var isDark: Bool {
        switch self {
        case .splash, .tracking, .hero, .notAlone, .reviewAsk, .cameraPermission, .scanLoading:
            true
        default:
            false
        }
    }
}
