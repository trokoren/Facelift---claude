import SwiftUI

/// Skin Score over time: one dot per scan, with a soft trend line once there are enough scans
/// to smooth out day-to-day wobble. Tap a dot to open that consultation.
/// Evenly spaced for "Recent" and "All" (every scan gets equal room); placed by date for the
/// time ranges (so real gaps show).
struct SkinHealthChart: View {
    let points: [ChartPoint]
    var evenlySpaced: Bool = false
    var onSelect: ((UUID) -> Void)? = nil

    @State private var reveal: CGFloat = 0

    private let axisWidth: CGFloat = 32
    private let plotHeight: CGFloat = 96
    private let topInset: CGFloat = 24

    /// Scores usually sit in a narrow band, so the axis zooms to them (at least 20 points tall).
    private var yRange: (low: Double, high: Double) {
        let values = points.map { Double($0.value) }
        guard let minValue = values.min(), let maxValue = values.max() else { return (0, 100) }
        var low = max(0, minValue - 8)
        var high = min(100, maxValue + 8)
        if high - low < 20 {
            let middle = (high + low) / 2
            low = max(0, middle - 10)
            high = min(100, low + 20)
            low = max(0, high - 20)
        }
        return (low.rounded(.down), high.rounded(.up))
    }

    /// Three-scan moving average, only when there are enough scans for it to mean something.
    private var trend: [Double]? {
        guard points.count >= 4 else { return nil }
        let values = points.map { Double($0.value) }
        return values.indices.map { i in
            let window = values[max(0, i - 1)...min(values.count - 1, i + 1)]
            return window.reduce(0, +) / Double(window.count)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let plotRect = CGRect(x: axisWidth, y: topInset, width: geo.size.width - axisWidth - 12, height: plotHeight)
                let coords = positions(in: plotRect, values: points.map { Double($0.value) })
                let range = yRange

                ZStack(alignment: .topLeading) {
                    ForEach([range.high, (range.high + range.low) / 2, range.low], id: \.self) { value in
                        Text("\(Int(value.rounded()))")
                            .font(FLFont.sans(8))
                            .foregroundStyle(Palette.faint)
                            .frame(width: 22, alignment: .trailing)
                            .position(x: 12, y: y(for: value, in: plotRect))
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

                    if let trend {
                        linePath(positions(in: plotRect, values: trend))
                            .trim(from: 0, to: reveal)
                            .stroke(Palette.rose, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    }

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
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect?(point.id) }
                        .scaleEffect(reveal > 0.95 ? 1 : 0.2)
                        .position(coord)

                        if showsValue(at: index) {
                            Text("\(point.value)")
                                .font(FLFont.sans(10, .semibold))
                                .foregroundStyle(point.color)
                                .position(x: coord.x, y: coord.y - 16)
                                .opacity(reveal)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .frame(height: topInset + plotHeight)

            GeometryReader { geo in
                let plotRect = CGRect(x: axisWidth, y: 0, width: geo.size.width - axisWidth - 12, height: 1)
                let coords = positions(in: plotRect, values: points.map { Double($0.value) })
                ZStack(alignment: .topLeading) {
                    ForEach(labelIndices, id: \.self) { index in
                        Text(points[index].label)
                            .font(FLFont.sans(9.5, .medium))
                            .foregroundStyle(Palette.body)
                            .fixedSize()
                            .position(x: coords[index].x, y: 8)
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

    /// Every value when there are a few scans; otherwise just the latest, to keep it clean.
    private func showsValue(at index: Int) -> Bool {
        points.count <= 6 || index == points.count - 1
    }

    /// Up to four date labels, spread out so they never overlap.
    private var labelIndices: [Int] {
        let count = points.count
        // Evenly spaced and few enough to fit: a date under every dot.
        if evenlySpaced && count <= 6 { return Array(0..<count) }
        let candidates = count > 4 ? Array(Set([0, count / 3, (2 * count) / 3, count - 1])).sorted() : Array(0..<count)
        // Several scans on one day share a label: show it once.
        var shown: [Int] = []
        for index in candidates where !shown.contains(where: { points[$0].label == points[index].label }) {
            shown.append(index)
        }
        return shown
    }

    private func y(for value: Double, in rect: CGRect) -> CGFloat {
        let range = yRange
        let fraction = (value - range.low) / max(1, range.high - range.low)
        return rect.maxY - rect.height * CGFloat(fraction)
    }

    /// Placed by date when every point has one (so gaps between scans show), else evenly.
    private func positions(in rect: CGRect, values: [Double]) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let count = points.count
        let dates = points.compactMap(\.date)
        let span = (dates.max()?.timeIntervalSince1970 ?? 0) - (dates.min()?.timeIntervalSince1970 ?? 0)
        let byDate = !evenlySpaced && dates.count == count && span > 0
        let start = dates.min()?.timeIntervalSince1970 ?? 0
        return values.enumerated().map { index, value in
            let x: CGFloat
            if count == 1 {
                x = rect.midX
            } else if byDate, let date = points[index].date {
                x = rect.minX + rect.width * CGFloat((date.timeIntervalSince1970 - start) / span)
            } else {
                x = rect.minX + rect.width * CGFloat(index) / CGFloat(count - 1)
            }
            return CGPoint(x: x, y: y(for: value, in: rect))
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
