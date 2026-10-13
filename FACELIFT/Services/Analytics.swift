import Foundation
import Mixpanel
import MixpanelSessionReplay

/// Product analytics and session replay through Mixpanel (organization Ocean Park, project
/// FACELIFT). What we send: which screens she reaches and what she taps, never her name,
/// email, photos, face or health answers.
///
/// Session replay keeps Mixpanel's default masking (all text and images are hidden) and stops
/// completely while the camera is open.
enum Analytics {
    /// Public project token. Safe to ship in the app.
    private static let token = "31611c4f7aa763b2ebfbc3729b5c6e95"

    /// Event properties (Mixpanel's type), so other files don't need to import Mixpanel.
    typealias Properties = [String: any MixpanelType]

    /// Every event name in one place, `object_verb` in snake_case.
    enum Event: String {
        case onboardingStepViewed = "onboarding_step_viewed"
        case notificationsAnswered = "notifications_answered"
        case notificationsSkipped = "notifications_skipped"
        case scanCompleted = "scan_completed"
        case scanFailed = "scan_failed"
        case paywallViewed = "paywall_viewed"
        case purchaseCompleted = "purchase_completed"
        case purchaseRestored = "purchase_restored"
        case productViewed = "product_viewed"
        case productShopTapped = "product_shop_tapped"
        case productAddedToRoutine = "product_added_to_routine"
        case productRemovedFromRoutine = "product_removed_from_routine"
        case approachChanged = "approach_changed"
        case remindersToggled = "reminders_toggled"
        case onboardingCompleted = "onboarding_completed"
        case paywallPlanSelected = "paywall_plan_selected"
        case purchaseStarted = "purchase_started"
        case purchaseCancelled = "purchase_cancelled"
        case purchaseFailed = "purchase_failed"
        case tabViewed = "tab_viewed"
        case scanStarted = "scan_started"
    }

    static func start() {
        Mixpanel.initialize(token: token, trackAutomaticEvents: false)
        #if DEBUG
        Mixpanel.mainInstance().registerSuperProperties(["environment": "debug"])
        #else
        Mixpanel.mainInstance().registerSuperProperties(["environment": "production"])
        #endif
        MPSessionReplay.initialize(
            token: token,
            distinctId: Mixpanel.mainInstance().distinctId,
            config: MPSessionReplayConfig(wifiOnly: true)
        )
    }

    static func track(_ event: Event, _ properties: Properties = [:]) {
        Mixpanel.mainInstance().track(event: event.rawValue, properties: properties)
    }

    /// After sign in: her FACELIFT account id (never her email).
    static func identify(_ accountID: String) {
        Mixpanel.mainInstance().identify(distinctId: accountID)
        MPSessionReplay.getInstance()?.identify(distinctId: accountID)
    }

    /// After sign out or account deletion.
    static func reset() {
        Mixpanel.mainInstance().reset()
        MPSessionReplay.getInstance()?.identify(distinctId: Mixpanel.mainInstance().distinctId)
    }

    /// The camera is open: nothing is recorded until it closes.
    static func pauseReplay() { MPSessionReplay.getInstance()?.stopRecording() }
    static func resumeReplay() { MPSessionReplay.getInstance()?.startRecording() }
}
