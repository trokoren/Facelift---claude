import SwiftUI

/// The "reading your skin" moment after the circle scan: black with slow, glowing rose
/// streaks, a four-step checklist and a progress bar. No camera.
struct SkinAnalyzingView: View {
    let onFinished: () -> Void

    @State private var completed: Int = 0
    @State private var progress: Double = 0

    private let stages: [String] = [
        "Mapping your face",
        "Reading 14 skin markers",
        "Scoring your results",
        "Matching products to your skin"
    ]
    /// Seconds each step stays on screen.
    private let stageDuration: Double = 2.0

    var body: some View {
        ZStack {
            Palette.night.ignoresSafeArea()

            RoseStreaks()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Keep the text readable over the brightest streaks.
            RadialGradient(
                colors: [Palette.night.opacity(0.75), Palette.night.opacity(0)],
                center: .center,
                startRadius: 40,
                endRadius: 320
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                PrivacyNote(tint: Color(hex: 0xD9D1CF))
                    .frame(height: 44)

                Spacer()

                Text("Reading your skin")
                    .font(FLFont.serif(38))
                    .foregroundStyle(.white)
                Text("This takes a few seconds.")
                    .font(FLFont.sans(15))
                    .foregroundStyle(Palette.nightBody)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        HStack(spacing: 16) {
                            ZStack {
                                if index < completed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundStyle(Palette.rose)
                                        .transition(.scale.combined(with: .opacity))
                                } else if index == completed {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(Palette.rose)
                                } else {
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            .frame(width: 22, height: 22)

                            Text(stage)
                                .font(FLFont.sans(17))
                                .foregroundStyle(index <= completed ? .white : Color.white.opacity(0.4))
                        }
                        .animation(.easeOut(duration: 0.3), value: completed)
                    }
                }
                .padding(.top, 40)

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(Palette.rose)
                        .frame(width: 180 * progress)
                }
                .frame(width: 180, height: 3)
                .padding(.top, 36)

                Spacer()
                Spacer()
                    .frame(height: 44)
            }
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: completed == stages.count)
        .task { await run() }
    }

    private func run() async {
        let total = Double(stages.count) * stageDuration
        let ticks = 100
        for tick in 1...ticks {
            try? await Task.sleep(for: .seconds(total / Double(ticks)))
            if Task.isCancelled { return }
            let fraction = Double(tick) / Double(ticks)
            withAnimation(.linear(duration: total / Double(ticks))) { progress = fraction }
            let stage = min(stages.count, Int(fraction * Double(stages.count) + 0.0001))
            if stage != completed {
                withAnimation(.easeOut(duration: 0.3)) { completed = stage }
            }
        }
        try? await Task.sleep(for: .milliseconds(500))
        if Task.isCancelled { return }
        onFinished()
    }
}

/// Slow, flowing ribbons of rose light: a soft blurred glow with fine bright lines on top.
struct RoseStreaks: View {
    private let ribbons = 6

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                canvas.drawLayer { glow in
                    glow.addFilter(.blur(radius: 22))
                    for index in 0..<ribbons {
                        glow.stroke(
                            ribbon(index: index, time: time, size: size),
                            with: shading(for: size, strength: 0.55),
                            lineWidth: 18
                        )
                    }
                }
                for index in 0..<ribbons {
                    canvas.stroke(
                        ribbon(index: index, time: time, size: size),
                        with: shading(for: size, strength: 0.8),
                        lineWidth: index.isMultiple(of: 2) ? 1.2 : 0.7
                    )
                }
            }
        }
    }

    private func ribbon(index: Int, time: Double, size: CGSize) -> Path {
        let i = Double(index)
        let speed = 0.18 + i * 0.045
        let phase = time * speed + i * 1.7
        let baseY = size.height * (0.12 + 0.15 * i)
        let amplitude = size.height * (0.05 + 0.025 * Double(index % 3))
        // Slight diagonal so the streaks sweep across rather than sit flat.
        let tilt = size.height * 0.18

        var path = Path()
        var x: CGFloat = -40
        var isFirst = true
        while x <= size.width + 40 {
            let progress = Double(x / size.width)
            let y = baseY
                + CGFloat(sin(progress * .pi * 2.2 + phase)) * amplitude
                + CGFloat(sin(progress * .pi * 5 - phase * 0.8)) * amplitude * 0.3
                - CGFloat(progress) * tilt
            let point = CGPoint(x: x, y: y)
            if isFirst {
                path.move(to: point)
                isFirst = false
            } else {
                path.addLine(to: point)
            }
            x += 6
        }
        return path
    }

    private func shading(for size: CGSize, strength: Double) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [
                Palette.rose.opacity(0),
                Palette.rose.opacity(strength),
                Color(hex: 0xF4C9C4).opacity(strength),
                Palette.rose.opacity(0)
            ]),
            startPoint: CGPoint(x: 0, y: size.height * 0.5),
            endPoint: CGPoint(x: size.width, y: size.height * 0.5)
        )
    }
}
