import SwiftUI
import AppTrackingTransparency

/// Blurred hero behind the system App Tracking Transparency prompt.
struct TrackingStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var didRequest: Bool = false

    var body: some View {
        GeometryReader { geo in
            Image("woman_portrait_clean")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .blur(radius: 26)
                .overlay(Color.black.opacity(0.42))
        }
        .background(Color(hex: 0x2A1A14))
        .ignoresSafeArea()
        .overlay {
            Text("FACELIFT")
                .font(FLFont.serif(15))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.7))
                .offset(y: 172)
        }
        .task { await requestTracking() }
    }

    private func requestTracking() async {
        guard !didRequest else { return }
        didRequest = true
        try? await Task.sleep(for: .milliseconds(350))
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        try? await Task.sleep(for: .milliseconds(250))
        if !Task.isCancelled { flow.next() }
    }
}
