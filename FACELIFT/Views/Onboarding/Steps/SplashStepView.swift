import SwiftUI

/// Full-bleed hero photo that holds for a beat, then hands off to the tracking prompt.
struct SplashStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var hasAppeared: Bool = false

    var body: some View {
        GeometryReader { geo in
            Image("woman_portrait_clean")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(hasAppeared ? 1.0 : 1.05)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .background(Color(hex: 0x2A1A14))
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 1.6)) { hasAppeared = true }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(1400))
            if !Task.isCancelled { flow.next() }
        }
    }
}
