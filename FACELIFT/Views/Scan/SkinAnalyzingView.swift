import SwiftUI

/// The "reading your skin" moment after the circle scan: black with slow, glowing rose
/// streaks, a four-step checklist and a progress bar. No camera.
///
/// The real analysis runs underneath. The checklist paces itself, then holds on the last step
/// until the results are in. If the photo can't be read, she gets a clear reason and a way
/// to scan again.
struct SkinAnalyzingView: View {
    let onFinished: () -> Void
    let onRetry: () -> Void

    @Environment(AppStore.self) private var store
    @State private var completed: Int = 0
    @State private var progress: Double = 0
    @State private var failure: String?

    private let stages: [String] = [
        "Mapping your face",
        "Measuring your skin",
        "Reading your skin type",
        "Writing your consultation"
    ]
    /// Seconds for each of the first three steps. The last one lasts as long as the read does.
    private let stageDuration: Double = 3.0

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

                if let failure {
                    failureView(failure)
                        .transition(.opacity)
                } else {
                    checklist
                        .transition(.opacity)
                }

                Spacer()
                Spacer()
                    .frame(height: 44)
            }
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: completed == stages.count)
        .sensoryFeedback(.error, trigger: failure != nil)
        .task { await run() }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.rose)
            Text("Let's try that again")
                .font(FLFont.serif(34))
                .foregroundStyle(.white)
                .padding(.top, 18)
            Text(message)
                .font(FLFont.sans(16))
                .foregroundStyle(Palette.nightBody)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)
            Button(action: onRetry) {
                Text("Scan again")
                    .font(FLFont.sans(17, .semibold))
                    .foregroundStyle(Palette.night)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(Palette.rose))
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 32)
        }
    }

    private var checklist: some View {
        VStack(spacing: 0) {
                Text("Reading your skin")
                    .font(FLFont.serif(38))
                    .foregroundStyle(.white)
                Text("This takes about 20 seconds.")
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
        }
    }

    private func run() async {
        let analysis = Task { await store.analyzeLastScan() }
        let count = Double(stages.count)

        // Every step but the last at a steady pace...
        await animate(from: 0, to: (count - 1) / count, duration: (count - 1) * stageDuration)
        if Task.isCancelled { return }

        // ...then the last step stays alive while the consultation is written: the bar keeps
        // creeping toward the end (never quite reaching it) so it never looks frozen.
        let creep = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                if Task.isCancelled { break }
                withAnimation(.linear(duration: 0.25)) { progress += (0.97 - progress) * 0.025 }
            }
        }
        let outcome = await analysis.value
        creep.cancel()
        if let message = outcome {
            withAnimation(.easeInOut(duration: 0.4)) { failure = message }
            return
        }
        await animate(from: progress, to: 1, duration: 0.6)
        try? await Task.sleep(for: .milliseconds(500))
        if Task.isCancelled { return }
        onFinished()
    }

    private func animate(from start: Double, to end: Double, duration: Double) async {
        let ticks = max(1, Int(duration * 12))
        for tick in 1...ticks {
            try? await Task.sleep(for: .seconds(duration / Double(ticks)))
            if Task.isCancelled { return }
            let fraction = start + (end - start) * Double(tick) / Double(ticks)
            withAnimation(.linear(duration: duration / Double(ticks))) { progress = fraction }
            let stage = min(stages.count, Int(fraction * Double(stages.count) + 0.0001))
            if stage != completed {
                withAnimation(.easeOut(duration: 0.3)) { completed = stage }
            }
        }
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
