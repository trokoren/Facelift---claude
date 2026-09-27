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
            .frame(height: 21)
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
            .frame(height: 18)
            .background(Palette.chipSoft, in: Capsule())
    }
}
