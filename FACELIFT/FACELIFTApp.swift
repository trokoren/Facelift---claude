//
//  FACELIFTApp.swift
//  FACELIFT
//
//  Created by Rork on September 24, 2026.
//

import SwiftUI

@main
struct FACELIFTApp: App {
    /// Meta's SDK starts from an app delegate (see `MetaAds`).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        CrashReporting.start()
        Analytics.start()
        FontRegistrar.registerAll()
        Subscriptions.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
