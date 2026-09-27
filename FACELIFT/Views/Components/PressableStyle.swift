import SwiftUI

/// Soft scale-down press feedback for compact buttons (CTAs, chips, icons).
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Scroll-friendly feedback for large cards and rows inside scroll views:
/// a quick fade only, so starting a scroll on a card never makes it jump.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(configuration.isPressed ? nil : .easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
