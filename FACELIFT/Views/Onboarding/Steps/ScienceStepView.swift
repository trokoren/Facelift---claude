import SwiftUI

/// "Built on real skin science.": stat chips, the 7 areas we measure, scan-to-scan consistency
/// and what her plan is built from. Every claim here is one we can back up.
struct ScienceStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var isRevealed: Bool = false

    var body: some View {
        OnboardingPage(title: "Built on real\nskin science.", titleSize: 32, titleTop: 0) {
            Text("Your scan is read by dermatologist-verified technology, developed from 70,000+ clinical-grade skin images.")
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.stone)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 6)

            HStack(spacing: 10) {
                statChip("70k+ images")
                statChip("Derm-verified")
                statChip("95% consistent")
            }
            .padding(.top, 10)

            measuresCard
                .padding(.top, 12)

            consistencyCard
                .padding(.top, 8)

            planCard
                .padding(.top, 8)
        } footer: {
            OnboardingCTA(title: "Continue") { flow.next() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .background(
            LinearGradient(colors: [Palette.canvas, Color(hex: 0xF7ECE9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.1).delay(0.25)) { isRevealed = true }
        }
    }

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(FLFont.sans(13, .medium))
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Color.white, in: Capsule())
    }

    // MARK: 7 areas, every scan

    private static let areas = ["Lines", "Dark circles", "Spots", "Redness", "Texture", "Pores", "Hydration"]

    private var measuresCard: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                ForEach(0..<7, id: \.self) { index in
                    let start = Double(index) / 7 + 0.014
                    let end = Double(index + 1) / 7 - 0.014
                    Circle()
                        .trim(from: start, to: end)
                        .stroke(Palette.roseLine, style: StrokeStyle(lineWidth: 9, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: start, to: isRevealed ? end : start)
                        .stroke(Palette.rose, style: StrokeStyle(lineWidth: 9, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.35).delay(0.3 + Double(index) * 0.09), value: isRevealed)
                }
                Text("7")
                    .font(FLFont.serif(30))
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text("areas measured on every scan")
                    .font(FLFont.sans(15.5, .medium))
                    .foregroundStyle(Palette.ink)
                    .lineSpacing(2)
                FlowLayout(spacing: 5) {
                    ForEach(Self.areas, id: \.self) { area in
                        Text(area)
                            .font(FLFont.sans(11.5))
                            .foregroundStyle(Palette.body)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(Palette.chip, in: Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 26)
    }

    // MARK: Consistency

    private var consistencyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SCAN-TO-SCAN CONSISTENCY")
                .font(FLFont.sans(11))
                .tracking(1.8)
                .foregroundStyle(Palette.label)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("95%")
                    .font(FLFont.serifItalic(30))
                    .foregroundStyle(Palette.ink)
                Text("Same face, same read. So when\nyour score moves, your skin did.")
                    .font(FLFont.sans(13))
                    .foregroundStyle(Palette.stone)
                    .lineSpacing(2)
            }
            .padding(.top, 4)

            consistencyChart
                .frame(height: 64)
                .padding(.top, 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 26)
    }

    /// Five repeat scans of one face, sitting inside a narrow band.
    private var consistencyChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let bandTop: CGFloat = 10
            let bandHeight: CGFloat = 26
            let offsets: [CGFloat] = [0.55, 0.35, 0.5, 0.62, 0.45]
            let points = offsets.enumerated().map { index, offset in
                CGPoint(x: 14 + (w - 28) * CGFloat(index) / 4, y: bandTop + bandHeight * offset)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Palette.rose.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Palette.roseLine, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    )
                    .frame(width: w, height: bandHeight)
                    .offset(y: bandTop)

                Path { p in
                    p.move(to: points[0])
                    for point in points.dropFirst() { p.addLine(to: point) }
                }
                .trim(from: 0, to: isRevealed ? 1 : 0)
                .stroke(Palette.rose, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Palette.rose, lineWidth: 2.5))
                        .frame(width: 11, height: 11)
                        .position(points[index])
                        .opacity(isRevealed ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.4 + Double(index) * 0.12), value: isRevealed)
                }

                HStack {
                    ForEach(1...5, id: \.self) { n in
                        Text("Scan \(n)")
                        if n < 5 { Spacer() }
                    }
                }
                .font(FLFont.sans(11.5))
                .foregroundStyle(Palette.faint)
                .frame(width: w)
                .offset(y: bandTop + bandHeight + 10)
            }
        }
    }

    // MARK: What shapes her plan

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR PLAN IS BUILT FROM")
                .font(FLFont.sans(11))
                .tracking(1.8)
                .foregroundStyle(Palette.label)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                planItem("viewfinder", "Your 7 measures", index: 0)
                planItem("drop", "Your skin type", index: 1)
                planItem("list.bullet", "Your routine", index: 2)
                planItem("sparkle", "Your goals", index: 3)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 26)
    }

    private func planItem(_ icon: String, _ text: String, index: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Palette.rose)
                .frame(width: 18)
            Text(text)
                .font(FLFont.sans(13.5, .medium))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Palette.chipSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 6)
        .animation(.easeOut(duration: 0.35).delay(0.5 + Double(index) * 0.08), value: isRevealed)
    }
}
