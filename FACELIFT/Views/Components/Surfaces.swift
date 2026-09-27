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

/// Soft, blurred color fields behind the analysis so glass cards have something to refract.
/// Stays fixed while the cards scroll over it.
struct GlassBackdrop: View {
    var body: some View {
        ZStack {
            Palette.canvas
            Circle()
                .fill(Palette.rose.opacity(0.38))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: -150, y: -250)
            Circle()
                .fill(Palette.gold.opacity(0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 170, y: 60)
            Circle()
                .fill(Palette.sage.opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 100)
                .offset(x: -120, y: 380)
        }
        .drawingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Frosted glass card: blurred material, a light top-left sheen tinted with the category
/// color, and a bright hairline edge.
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
                    RadialGradient(colors: [accent.opacity(0.20), .clear], center: .topLeading, startRadius: 0, endRadius: 240)
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
            .shadow(color: accent.opacity(0.14), radius: 22, x: 0, y: 10)
    }
}
