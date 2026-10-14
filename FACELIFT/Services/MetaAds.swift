import UIKit
import FacebookCore

/// Meta (Facebook and Instagram ads) measurement. Reports installs and app opens, and
/// (through the App Store, set in Meta's app settings) trials and purchases, so ads can be
/// measured and optimized. Only people who tap Allow on the tracking prompt are tracked;
/// for everyone else Meta gets anonymous, aggregated counts only (Apple's rules).
///
/// What we send: standard app events. Never her name, email, photos, face, scores or
/// health answers.
///
/// Meta app "Ocean Park Skin Scanner App" (Meta doesn't allow "face" in app names), business
/// portfolio Trevor Okoren Music (to be renamed Ocean Park). Both values are public keys.
enum MetaAds {
    private static let appID = "1549984706812764"
    private static let clientToken = "e4d06d0f91dd9c5b1a920a821efb2ff1"

    /// Call once at launch, from the app delegate.
    static func start(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        Settings.shared.appID = appID
        Settings.shared.clientToken = clientToken
        Settings.shared.displayName = "FACELIFT"
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        _ = ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// She finished onboarding (Meta's "Complete registration"), a good signal for ads to
    /// optimize toward before purchases have enough volume.
    static func onboardingCompleted() {
        AppEvents.shared.logEvent(.completedRegistration)
    }
}

/// Lets Meta's SDK start the way it expects, from an app delegate.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MetaAds.start(application, launchOptions: launchOptions)
        return true
    }
}
