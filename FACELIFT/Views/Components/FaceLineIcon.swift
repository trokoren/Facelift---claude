import SwiftUI

/// Minimal line-art face used on the analysis cards.
struct FaceLineIcon: Shape {
    var sparkle: Bool = false

    nonisolated func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        var p = Path()
        p.move(to: pt(0.62, 0.02))
        p.addCurve(to: pt(0.98, 0.42), control1: pt(0.86, 0.06), control2: pt(1.0, 0.22))
        p.addCurve(to: pt(0.52, 0.99), control1: pt(0.96, 0.72), control2: pt(0.76, 0.97))
        p.addCurve(to: pt(0.05, 0.62), control1: pt(0.28, 0.99), control2: pt(0.08, 0.84))
        p.addCurve(to: pt(0.22, 0.12), control1: pt(0.0, 0.40), control2: pt(0.06, 0.22))
        p.addCurve(to: pt(0.62, 0.02), control1: pt(0.34, 0.04), control2: pt(0.5, 0.0))

        p.move(to: pt(0.14, 0.38))
        p.addCurve(to: pt(0.66, 0.06), control1: pt(0.28, 0.2), control2: pt(0.48, 0.08))

        p.move(to: pt(0.2, 0.46))
        p.addQuadCurve(to: pt(0.4, 0.46), control: pt(0.3, 0.53))
        p.move(to: pt(0.6, 0.44))
        p.addQuadCurve(to: pt(0.8, 0.44), control: pt(0.7, 0.37))

        p.move(to: pt(0.36, 0.77))
        p.addQuadCurve(to: pt(0.5, 0.75), control: pt(0.43, 0.71))
        p.addQuadCurve(to: pt(0.64, 0.77), control: pt(0.57, 0.71))
        p.addQuadCurve(to: pt(0.36, 0.77), control: pt(0.5, 0.87))

        if sparkle {
            let c = pt(1.02, 0.02)
            let r: CGFloat = w * 0.14
            p.move(to: CGPoint(x: c.x, y: c.y - r))
            p.addLine(to: CGPoint(x: c.x, y: c.y + r))
            p.move(to: CGPoint(x: c.x - r, y: c.y))
            p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        }
        return p
    }
}
