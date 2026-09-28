import SwiftUI

/// Fine-line face in the style of the app icon (three-quarter view, eyes closed, flowing
/// hair), with a small motif for each score card's topic:
/// Aging & Structure = lift arcs, Tone & Clarity = sparkle, Skin Health = droplet.
struct CategoryIcon: View {
    let kind: AnalysisCategory.Kind
    var tint: Color = Palette.rose

    var body: some View {
        ZStack(alignment: .topLeading) {
            FaceSketch()
                .stroke(tint, style: StrokeStyle(lineWidth: 0.9, lineCap: .round, lineJoin: .round))

            motif
                .frame(width: 11, height: 11)
                .offset(x: -3, y: 0)
        }
        .frame(width: 34, height: 40)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var motif: some View {
        switch kind {
        case .aging:
            LiftArcs()
                .stroke(tint, style: StrokeStyle(lineWidth: 1, lineCap: .round))
        case .tone:
            Sparkle()
                .fill(tint)
        case .health:
            Droplet()
                .stroke(tint, style: StrokeStyle(lineWidth: 1, lineJoin: .round))
        }
    }
}

/// Three-quarter face turned slightly right, eyes closed, hair swept over one side.
struct FaceSketch: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        var p = Path()

        // Hair: sweep from the left side over the crown and down the right shoulder.
        p.move(to: pt(0.24, 0.62))
        p.addCurve(to: pt(0.30, 0.12), control1: pt(0.12, 0.44), control2: pt(0.16, 0.20))
        p.addCurve(to: pt(0.74, 0.12), control1: pt(0.44, 0.02), control2: pt(0.62, 0.02))
        p.addCurve(to: pt(0.90, 0.58), control1: pt(0.90, 0.24), control2: pt(0.86, 0.42))
        p.addCurve(to: pt(0.84, 0.90), control1: pt(0.94, 0.72), control2: pt(0.80, 0.78))

        // Inner hair strand across the forehead.
        p.move(to: pt(0.30, 0.34))
        p.addCurve(to: pt(0.70, 0.16), control1: pt(0.40, 0.22), control2: pt(0.56, 0.14))

        // Face contour: cheek, jaw and chin.
        p.move(to: pt(0.32, 0.42))
        p.addCurve(to: pt(0.46, 0.80), control1: pt(0.32, 0.60), control2: pt(0.38, 0.74))
        p.addCurve(to: pt(0.70, 0.78), control1: pt(0.54, 0.86), control2: pt(0.64, 0.84))
        p.addCurve(to: pt(0.78, 0.34), control1: pt(0.78, 0.66), control2: pt(0.80, 0.48))

        // Brows.
        p.move(to: pt(0.40, 0.40))
        p.addQuadCurve(to: pt(0.53, 0.39), control: pt(0.46, 0.36))
        p.move(to: pt(0.62, 0.39))
        p.addQuadCurve(to: pt(0.73, 0.41), control: pt(0.68, 0.37))

        // Closed eyes (lash curves).
        p.move(to: pt(0.41, 0.47))
        p.addQuadCurve(to: pt(0.53, 0.47), control: pt(0.47, 0.51))
        p.move(to: pt(0.62, 0.47))
        p.addQuadCurve(to: pt(0.72, 0.47), control: pt(0.67, 0.51))

        // Nose.
        p.move(to: pt(0.58, 0.49))
        p.addQuadCurve(to: pt(0.60, 0.61), control: pt(0.62, 0.56))
        p.addQuadCurve(to: pt(0.55, 0.62), control: pt(0.58, 0.64))

        // Lips.
        p.move(to: pt(0.50, 0.69))
        p.addQuadCurve(to: pt(0.58, 0.68), control: pt(0.54, 0.66))
        p.addQuadCurve(to: pt(0.65, 0.69), control: pt(0.62, 0.66))
        p.addQuadCurve(to: pt(0.50, 0.69), control: pt(0.58, 0.75))

        // Neck.
        p.move(to: pt(0.46, 0.80))
        p.addLine(to: pt(0.44, 1.0))
        p.move(to: pt(0.68, 0.81))
        p.addQuadCurve(to: pt(0.74, 1.0), control: pt(0.70, 0.92))

        return p
    }
}

/// Two upward arcs: lift and firmness.
struct LiftArcs: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()
        for offset in [0.15, 0.55] {
            let y = rect.minY + rect.height * offset
            p.move(to: CGPoint(x: rect.minX, y: y + rect.height * 0.3))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: y + rect.height * 0.3),
                control: CGPoint(x: rect.midX, y: y - rect.height * 0.15)
            )
        }
        return p
    }
}

/// Four-point sparkle: glow and clarity.
struct Sparkle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.22
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + inner, y: c.y - inner))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + inner, y: c.y + inner))
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - inner, y: c.y + inner))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - inner, y: c.y - inner))
        p.closeSubpath()
        return p
    }
}

/// Water droplet: hydration and barrier health.
struct Droplet: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.minX + w * 1.05, y: rect.minY + h * 0.55),
            control2: CGPoint(x: rect.minX + w * 0.95, y: rect.maxY)
        )
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX + w * 0.05, y: rect.maxY),
            control2: CGPoint(x: rect.minX - w * 0.05, y: rect.minY + h * 0.55)
        )
        p.closeSubpath()
        return p
    }
}
