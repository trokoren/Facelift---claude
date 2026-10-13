import SwiftUI

/// One status message at a time, with a soft light sweeping across the text while it works.
/// Each new message rises in as the last one lifts away. Used on the loading screens.
struct StatusLine: View {
    let text: String
    var isDone: Bool = false
    var font: Font = FLFont.sans(17)

    var body: some View {
        HStack(spacing: 12) {
            StatusOrb(isDone: isDone)
            ZStack {
                ShimmerText(text: text, font: font, isActive: !isDone)
                    .id(text)
                    .transition(.statusLine)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(height: 30)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

/// Text with a slow band of light moving across it (still for Reduce Motion).
struct ShimmerText: View {
    let text: String
    var font: Font = FLFont.sans(17)
    var isActive: Bool = true
    var base: Color = .white.opacity(0.5)
    var highlight: Color = .white

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion || !isActive {
            Text(text)
                .font(font)
                .foregroundStyle(isActive ? highlight.opacity(0.85) : highlight)
        } else {
            TimelineView(.animation) { context in
                let period = 1.9
                let time = context.date.timeIntervalSinceReferenceDate
                let phase = time.truncatingRemainder(dividingBy: period) / period
                // The band starts just off the left edge and leaves off the right.
                let center = -0.35 + phase * 1.7
                Text(text)
                    .font(font)
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: base, location: 0),
                                .init(color: base, location: clamp(center - 0.22)),
                                .init(color: highlight, location: clamp(center)),
                                .init(color: base, location: clamp(center + 0.22)),
                                .init(color: base, location: 1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}

/// A small rose light that breathes while working and becomes a check when done.
struct StatusOrb: View {
    var isDone: Bool = false
    @State private var breathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(Palette.rose)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                Circle()
                    .fill(Palette.rose.opacity(0.28))
                    .frame(width: 20, height: 20)
                    .blur(radius: 4)
                    .scaleEffect(breathe ? 1.15 : 0.7)
                    .opacity(breathe ? 1 : 0.5)
                Circle()
                    .fill(Palette.rose)
                    .frame(width: 8, height: 8)
                    .scaleEffect(breathe ? 1 : 0.82)
            }
        }
        .frame(width: 22, height: 22)
        .animation(.spring(duration: 0.45, bounce: 0.3), value: isDone)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

private struct StatusLineMotion: ViewModifier {
    let y: CGFloat
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(y: y)
            .blur(radius: blur)
            .opacity(opacity)
    }
}

extension AnyTransition {
    /// New status rises in from below; the old one lifts away and softens.
    static var statusLine: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: StatusLineMotion(y: 14, blur: 6, opacity: 0),
                identity: StatusLineMotion(y: 0, blur: 0, opacity: 1)
            ),
            removal: .modifier(
                active: StatusLineMotion(y: -14, blur: 6, opacity: 0),
                identity: StatusLineMotion(y: 0, blur: 0, opacity: 1)
            )
        )
    }
}
