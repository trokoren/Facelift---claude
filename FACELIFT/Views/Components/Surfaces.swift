import SwiftUI

struct CardSurface: ViewModifier {
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background {
                // Shadow lives on the shape only, so text/images aren't re-rasterised while scrolling.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Palette.ink.opacity(0.035), radius: 14, x: 0, y: 5)
            }
    }
}

extension View {
    func cardSurface(radius: CGFloat = 22) -> some View {
        modifier(CardSurface(radius: radius))
    }
}

/// White card with a colored left edge that follows the rounded corners (CSS border-left look).
struct AccentEdgeBackground: View {
    let accent: Color
    var radius: CGFloat = 22
    var edge: CGFloat = 3

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(accent)
            .overlay {
                shape.fill(Color.white).padding(.leading, edge)
            }
            .clipShape(shape)
            .shadow(color: Palette.ink.opacity(0.035), radius: 14, x: 0, y: 5)
    }
}

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(FLFont.sans(9.5))
            .tracking(1.5)
            .foregroundStyle(Palette.label)
    }
}

struct ProfileChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FLFont.sans(11))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 11)
            .frame(height: 23)
            .background(Palette.chip, in: Capsule())
    }
}

struct ConcernChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FLFont.sans(10.5))
            .foregroundStyle(Palette.stone)
            .padding(.horizontal, 9)
            .frame(height: 20)
            .background(Palette.chipSoft, in: Capsule())
    }
}

/// Plain cream canvas behind the analysis (the colored wash was removed).
struct GlassBackdrop: View {
    var body: some View {
        Palette.canvas
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

/// Frosted glass card: blurred material, the same soft blush sheen in the top-left on every
/// card (so gold and blue cards don't get a heavy tint), and a bright hairline edge.
/// The category color still shows in the label, numbers and bars.
struct GlassCardBackground: View {
    let accent: Color
    var radius: CGFloat = 24

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(.ultraThinMaterial)
            .overlay(
                shape.fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                shape.fill(
                    RadialGradient(colors: [Palette.rose.opacity(0.20), .clear], center: .topLeading, startRadius: 0, endRadius: 240)
                )
            )
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: Palette.rose.opacity(0.14), radius: 22, x: 0, y: 10)
    }
}
