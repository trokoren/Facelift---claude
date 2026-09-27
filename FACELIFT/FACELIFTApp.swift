//
//  FACELIFTApp.swift
//  FACELIFT
//
//  Created by Rork on September 24, 2026.
//

import SwiftUI

@main
struct FACELIFTApp: App {
    init() {
        FontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
