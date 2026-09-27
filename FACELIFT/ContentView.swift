//
//  ContentView.swift
//  FACELIFT
//
//  Created by Rork on September 24, 2026.
//

import SwiftUI

struct ContentView: View {
    @State private var store = AppStore()

    var body: some View {
        ZStack {
            if store.hasCompletedOnboarding {
                mainApp
                    .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environment(store)
        .fullScreenCover(isPresented: $store.isScanning) {
            ScanCameraView()
                .environment(store)
        }
    }

    private var mainApp: some View {
        // Every tab stays alive so switching tabs keeps each one's scroll position
        // and navigation stack instead of rebuilding the screen from scratch.
        ZStack {
            ScanHomeView()
                .tabVisible(store.selectedTab == .scan)
            MySkinTab()
                .tabVisible(store.selectedTab == .mySkin)
            ProgressScreen()
                .tabVisible(store.selectedTab == .progress)
            AccountTab()
                .tabVisible(store.selectedTab == .account)
        }
        .animation(.easeInOut(duration: 0.2), value: store.selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.selectedTab != .scan {
                FLTabBar()
            }
        }
        .preferredColorScheme(.light)
    }
}

private extension View {
    /// Hides an inactive tab without destroying it.
    func tabVisible(_ isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
            .zIndex(isVisible ? 1 : 0)
    }
}

#Preview {
    ContentView()
}
