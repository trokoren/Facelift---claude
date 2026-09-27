import SwiftUI

/// Smooth line chart of overall skin health across scans (0–100).
struct SkinHealthChart: View {
    let points: [ChartPoint]

    @State private var reveal: CGFloat = 0

    private let axisWidth: CGFloat = 32
    private let plotHeight: CGFloat = 80
    private let topInset: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let plotRect = CGRect(
                    x: axisWidth,
                    y: topInset,
                    width: geo.size.width - axisWidth - 8,
                    height: plotHeight
                )
                let coords = positions(in: plotRect)

                ZStack(alignment: .topLeading) {
                    ForEach([100, 50, 0], id: \.self) { value in
                        Text("\(value)")
                            .font(FLFont.sans(8))
                            .foregroundStyle(Palette.faint)
                            .frame(width: 22, alignment: .trailing)
                            .position(x: 12, y: plotRect.maxY - plotRect.height * CGFloat(value) / 100)
                    }

                    Rectangle()
                        .fill(Palette.divider)
                        .frame(width: plotRect.width, height: 1)
                        .position(x: plotRect.midX, y: plotRect.maxY)

                    areaPath(coords, rect: plotRect)
                        .fill(Color(hex: 0xF5F4F4))
                        .opacity(reveal)

                    linePath(coords)
                        .trim(from: 0, to: reveal)
                        .stroke(Color(hex: 0xD6D4D3), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        let coord = coords[index]
                        ZStack {
                            Circle()
                                .fill(point.color.opacity(0.16))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(point.color)
                                .frame(width: 8, height: 8)
                        }
                        .scaleEffect(reveal > 0.95 ? 1 : 0.2)
                        .position(coord)

                        Text("\(point.value)")
                            .font(FLFont.sans(10, .semibold))
                            .foregroundStyle(point.color)
                            .position(x: coord.x, y: coord.y - 16)
                            .opacity(reveal)
                    }
                }
            }
            .frame(height: topInset + plotHeight)

            GeometryReader { geo in
                let plotRect = CGRect(x: axisWidth, y: 0, width: geo.size.width - axisWidth - 8, height: 1)
                let coords = positions(in: plotRect)
                ZStack(alignment: .topLeading) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        let coord = coords[index]
                        Text(point.label)
                            .font(FLFont.sans(9.5, .medium))
                            .foregroundStyle(Palette.body)
                            .fixedSize()
                            .position(x: coord.x, y: 8)
                    }
                }
            }
            .frame(height: 16)
            .padding(.top, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1).delay(0.1)) {
                reveal = 1
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(points.map { "\($0.label): \($0.value)" }.joined(separator: ", "))
    }

    private func positions(in rect: CGRect) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let count = points.count
        return points.enumerated().map { index, point in
            let x = count == 1 ? rect.midX : rect.minX + rect.width * CGFloat(index) / CGFloat(count - 1)
            let y = rect.maxY - rect.height * CGFloat(point.value) / 100
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(_ coords: [CGPoint]) -> Path {
        var path = Path()
        guard let first = coords.first else { return path }
        path.move(to: first)
        for (previous, next) in zip(coords, coords.dropFirst()) {
            let midX = (previous.x + next.x) / 2
            path.addCurve(to: next, control1: CGPoint(x: midX, y: previous.y), control2: CGPoint(x: midX, y: next.y))
        }
        return path
    }

    private func areaPath(_ coords: [CGPoint], rect: CGRect) -> Path {
        var path = linePath(coords)
        guard let first = coords.first, let last = coords.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
