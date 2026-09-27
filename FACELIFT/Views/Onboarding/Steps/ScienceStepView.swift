import SwiftUI

/// "Built on real skin science." — stats chips, donut, barrier chart and compatibility bars.
struct ScienceStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var isRevealed: Bool = false

    var body: some View {
        OnboardingPage(title: "Built on real\nskin science.", titleSize: 34, titleTop: 4) {
            Text("Our analysis draws from 14,000+ anonymized skin profiles and decades of peer-reviewed dermatology research.")
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.stone)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)

            HStack(spacing: 10) {
                statChip("92 studies")
                statChip("14k+ profiles")
                statChip("98% accuracy")
            }
            .padding(.top, 14)

            misidentifyCard
                .padding(.top, 16)

            barrierCard
                .padding(.top, 12)

            compatibilityCard
                .padding(.top, 12)
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
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color.white, in: Capsule())
    }

    private var misidentifyCard: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle().stroke(Palette.roseLine, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: isRevealed ? 0.63 : 0)
                    .stroke(Palette.rose, style: StrokeStyle(lineWidth: 9, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: -2) {
                    Text("63%")
                        .font(FLFont.sans(19, .semibold))
                        .foregroundStyle(Palette.ink)
                    Text("wrong")
                        .font(FLFont.sans(9.5))
                        .foregroundStyle(Palette.stone)
                }
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 4) {
                Text("of women misidentify their skin type")
                    .font(FLFont.sans(15.5, .medium))
                    .foregroundStyle(Palette.ink)
                    .lineSpacing(2)
                Text("FACELIFT's scan gets it right — instantly.")
                    .font(FLFont.sans(13.5))
                    .foregroundStyle(Palette.body)
                    .lineSpacing(2)
                Rectangle().fill(Palette.divider).frame(width: 150, height: 1).padding(.top, 4)
                Text("SOURCE: LABSKIN")
                    .font(FLFont.sans(10))
                    .tracking(1.6)
                    .foregroundStyle(Palette.label)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 26)
    }

    private var barrierCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SKIN BARRIER STRENGTH")
                        .font(FLFont.sans(11))
                        .tracking(1.8)
                        .foregroundStyle(Palette.label)
                    Text("+187%")
                        .font(FLFont.serifItalic(30))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 4)
                    Text("over 12 weeks")
                        .font(FLFont.sans(13))
                        .foregroundStyle(Palette.stone)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    legend("Targeted", dashed: false)
                    legend("Generic", dashed: true)
                }
                .padding(.top, 2)
            }

            barrierChart
                .frame(height: 112)
                .padding(.top, 8)
        }
        .padding(16)
        .cardSurface(radius: 26)
    }

    private func legend(_ text: String, dashed: Bool) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(dashed ? Palette.whisper : Palette.rose)
                .frame(width: 20, height: 2)
                .mask {
                    if dashed {
                        HStack(spacing: 3) {
                            Rectangle(); Rectangle(); Rectangle()
                        }
                    } else {
                        Rectangle()
                    }
                }
            Text(text)
                .font(FLFont.sans(13))
                .foregroundStyle(Palette.stone)
        }
    }

    private var barrierChart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let plotLeft: CGFloat = 40
            let plotBottom = h - 22
            let plotTop: CGFloat = 8
            let points: [CGPoint] = [
                CGPoint(x: plotLeft, y: plotBottom),
                CGPoint(x: plotLeft + (w - plotLeft) * 0.5, y: plotBottom - (plotBottom - plotTop) * 0.52),
                CGPoint(x: w - 6, y: plotTop + 6)
            ]

            ZStack(alignment: .topLeading) {
                ForEach([("100", 0.66), ("50", 0.33), ("0", 0.0)], id: \.0) { label, level in
                    let y = plotBottom - (plotBottom - plotTop) * level
                    Path { p in
                        p.move(to: CGPoint(x: plotLeft, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Palette.divider, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    Text(label)
                        .font(FLFont.sans(11))
                        .foregroundStyle(Palette.faint)
                        .position(x: 16, y: y)
                }

                Path { p in
                    p.move(to: CGPoint(x: plotLeft, y: plotBottom - 4))
                    p.addLine(to: CGPoint(x: w, y: plotBottom - 10))
                }
                .stroke(Palette.whisper, style: StrokeStyle(lineWidth: 1.6, dash: [5, 5]))

                Path { p in
                    p.move(to: points[0])
                    p.addLine(to: points[1])
                    p.addLine(to: points[2])
                    p.addLine(to: CGPoint(x: w - 6, y: plotBottom))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Palette.rose.opacity(0.14), Palette.rose.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                .opacity(isRevealed ? 1 : 0)

                Path { p in
                    p.move(to: points[0])
                    p.addLine(to: points[1])
                    p.addLine(to: points[2])
                }
                .trim(from: 0, to: isRevealed ? 1 : 0)
                .stroke(Palette.rose, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Palette.rose, lineWidth: 2.5))
                        .frame(width: 12, height: 12)
                        .position(points[i])
                        .opacity(isRevealed ? 1 : 0)
                }

                Text("+187%")
                    .font(FLFont.sans(12, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(Palette.rose, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .position(x: w - 30, y: plotTop + 6)
                    .opacity(isRevealed ? 1 : 0)

                HStack {
                    Text("Wk 0")
                    Spacer()
                    Text("Wk 6")
                    Spacer()
                    Text("Wk 12")
                }
                .font(FLFont.sans(12))
                .foregroundStyle(Palette.faint)
                .frame(width: w - plotLeft)
                .offset(x: plotLeft, y: h - 14)
            }
        }
    }

    private var compatibilityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("INGREDIENT COMPATIBILITY")
                .font(FLFont.sans(11))
                .tracking(1.8)
                .foregroundStyle(Palette.label)

            compatibilityRow(title: "Generic routine", value: 0.31, label: "31%", emphasized: false)
                .padding(.top, 14)
            compatibilityRow(title: "FACELIFT", value: 0.94, label: "94%", emphasized: true)
                .padding(.top, 12)
        }
        .padding(16)
        .cardSurface(radius: 26)
    }

    private func compatibilityRow(title: String, value: Double, label: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(FLFont.sans(15, emphasized ? .medium : .regular))
                    .foregroundStyle(emphasized ? Palette.ink : Palette.body)
                Spacer()
                Text(label)
                    .font(FLFont.sans(15, .medium))
                    .foregroundStyle(emphasized ? Palette.rose : Palette.stone)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.track)
                    Capsule()
                        .fill(
                            emphasized
                            ? LinearGradient(colors: [Palette.rose, Color(hex: 0xE8BCBA)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(hex: 0xE2CFCB), Color(hex: 0xE2CFCB)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * (isRevealed ? value : 0))
                }
            }
            .frame(height: emphasized ? 8 : 6)
        }
    }
}
