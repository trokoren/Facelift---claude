import Foundation
import Sentry

/// Crash reports through Sentry (organization ocean-park). Crashes and errors only: no
/// screenshots, no screen recordings, no view snapshots, and no personal details, since the
/// app shows her face and her health answers.
enum CrashReporting {
    /// Public client key (DSN). Safe to ship in the app.
    private static let dsn = "https://23cc2639782c95f6c1d4550fcc00e293@o4512248412241920.ingest.us.sentry.io/4512248422465536"

    static func start() {
        SentrySDK.start { options in
            options.dsn = dsn
            options.sendDefaultPii = false
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.tracesSampleRate = 0.1
            #if DEBUG
            options.environment = "debug"
            #else
            options.environment = "production"
            #endif
        }
    }
}
