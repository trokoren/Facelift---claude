import SwiftUI

/// Results as a consultation: Skin Score and a short read, her skin type, what's working,
/// what we're seeing (tap for the deeper read), what to keep an eye on, and her plan.
struct ConsultView: View {
    let scan: Scan
    let consult: Consult

    @Environment(AppStore.self) private var store
    @State private var openConcern: Consult.Concern?
    @State private var showsMeasurements = false
    @State private var showsSkinType = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            scoreCard
                .padding(.top, 18)

            section("YOUR SKIN TYPE") {
                Button { showsSkinType = true } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(consult.skinType.label.capitalizedFirst)
                                .font(FLFont.serif(28))
                                .foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            DiveInLabel()
                                .padding(.top, 8)
                        }
                        Text(consult.skinType.explanation)
                            .font(FLFont.sans(14))
                            .foregroundStyle(Palette.body)
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(GlassCardBackground(accent: Palette.rose))
                    .contentShape(Rectangle())
                }
                .buttonStyle(CardPressStyle())
            }

            section("WHAT'S WORKING") {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(consult.strengths) { strength in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Palette.rose)
                                .padding(.top, 3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(strength.title)
                                    .font(FLFont.sans(14.5, .semibold))
                                    .foregroundStyle(Palette.ink)
                                Text(strength.detail)
                                    .font(FLFont.sans(13.5))
                                    .foregroundStyle(Palette.body)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(GlassCardBackground(accent: Palette.rose))
            }

            section("WHAT WE'RE SEEING") {
                VStack(spacing: 12) {
                    ForEach(consult.concerns) { concern in
                        Button { openConcern = concern } label: {
                            ConcernCard(concern: concern, score: scan.measures[concern.key])
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
            }

            if let watch = consult.watch {
                section("KEEP AN EYE ON") {
                    VStack(alignment: .leading, spacing: 6) {
                        if !watch.title.isEmpty {
                            Text(watch.title)
                                .font(FLFont.sans(14.5, .semibold))
                                .foregroundStyle(Palette.ink)
                        }
                        Text(watch.detail)
                            .font(FLFont.sans(13.5))
                            .foregroundStyle(Palette.body)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(GlassCardBackground(accent: Palette.rose))
                }
            }

            section("YOUR PLAN") {
                VStack(alignment: .leading, spacing: 18) {
                    Text(consult.plan.focus)
                        .font(FLFont.serif(22))
                        .foregroundStyle(Palette.ink)
                    routine("Morning", steps: consult.plan.morning, icon: "sun.max")
                    routine("Evening", steps: consult.plan.evening, icon: "moon")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(GlassCardBackground(accent: Palette.rose))
            }

            Text("For cosmetic guidance only, not medical advice. Check with your doctor before starting new products if you're pregnant, nursing or have a skin condition.")
                .font(FLFont.sans(11.5))
                .foregroundStyle(Palette.stone)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
        }
        .padding(.horizontal, 24)
        .sheet(item: $openConcern) { concern in
            ConcernSheet(scanID: scan.id, initial: concern, score: scan.measures[concern.key])
        }
        // Older scans, or a read that didn't finish: write the deep reads now.
        .task { await store.loadDeepReads(for: scan.id) }
        .sheet(isPresented: $showsSkinType) {
            SkinTypeSheet(label: consult.skinType.label, explanation: consult.skinType.explanation)
        }
        .sheet(isPresented: $showsMeasurements) {
            MeasurementsSheet(measures: scan.measures)
        }
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("SKIN SCORE")
                    .font(FLFont.sans(11, .semibold))
                    .tracking(2.3)
                    .foregroundStyle(Palette.rose)
                Spacer()
                if !scan.measures.isEmpty {
                    Button { showsMeasurements = true } label: {
                        HStack(spacing: 4) {
                            Text("See my scores")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .regular))
                        }
                        .font(FLFont.sans(11.4))
                        .foregroundStyle(Palette.rose)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            HStack(alignment: .bottom, spacing: 9) {
                Text("\(scan.overallScore)")
                    .font(FLFont.serif(54))
                    .foregroundStyle(Palette.ink)
                VStack(alignment: .leading, spacing: 1) {
                    Text("/ 100")
                        .font(FLFont.sans(9.5, .light))
                        .tracking(1)
                        .foregroundStyle(Palette.faint)
                    Text(SampleData.rating(for: scan.overallScore))
                        .font(FLFont.serifItalic(15))
                        .foregroundStyle(Palette.rose)
                }
                .padding(.bottom, 9)
            }
            .padding(.top, 8)
            Text(consult.intro)
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.body)
                .lineSpacing(5)
                .padding(.top, 10)
        }
        .padding(20)
        .background(GlassCardBackground(accent: Palette.rose))
    }

    private func section<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(label)
            content()
        }
        .padding(.top, 30)
    }

    private func routine(_ title: String, steps: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .regular))
                Text(title.uppercased())
                    .font(FLFont.sans(10.5, .semibold))
                    .tracking(2)
            }
            .foregroundStyle(Palette.rose)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(FLFont.sans(12, .semibold))
                        .foregroundStyle(Palette.rose)
                        .frame(width: 16, alignment: .leading)
                    Text(step)
                        .font(FLFont.sans(13.5))
                        .foregroundStyle(Palette.body)
                        .lineSpacing(3)
                }
            }
        }
    }
}

/// One concern: title, severity, its measurement and a short summary. Tap for the full read.
private struct ConcernCard: View {
    let concern: Consult.Concern
    let score: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(concern.title)
                    .font(FLFont.serif(22))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                DiveInLabel()
            }
            HStack(spacing: 8) {
                Text(concern.severityLabel)
                    .font(FLFont.sans(10.5, .semibold))
                    .foregroundStyle(Palette.rose)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Palette.chip, in: Capsule())
                if let score {
                    Text("\(Measure.name(concern.key)) · \(score)/100")
                        .font(FLFont.sans(11))
                        .foregroundStyle(Palette.pebble)
                }
            }
            .padding(.top, 8)
            Text(concern.summary)
                .font(FLFont.sans(13.5))
                .foregroundStyle(Palette.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(GlassCardBackground(accent: Palette.rose))
        .contentShape(Rectangle())
    }
}

/// Soft shimmering lines where the deep read will appear, while it's being written.
private struct DeepReadPlaceholder: View {
    @State private var glow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(0..<3, id: \.self) { block in
                VStack(alignment: .leading, spacing: 9) {
                    bar(width: 110, height: 12)
                    bar(width: nil, height: 9)
                    bar(width: nil, height: 9)
                    bar(width: block == 1 ? 150 : 210, height: 9)
                }
            }
        }
        .opacity(glow ? 1 : 0.45)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: glow)
        .onAppear { glow = true }
        .accessibilityLabel("Loading")
    }

    private func bar(width: CGFloat?, height: CGFloat) -> some View {
        Capsule()
            .fill(Palette.blush)
            .frame(maxWidth: width ?? .infinity, alignment: .leading)
            .frame(width: width, height: height)
    }
}

/// "Dive in →": the invitation to open a deeper read.
private struct DiveInLabel: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Dive in")
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .regular))
        }
        .font(FLFont.sans(11.4, .medium))
        .foregroundStyle(Palette.rose)
        .fixedSize()
    }
}

/// Her skin type in depth: what her consultation said, then the general guide to that type.
private struct SkinTypeSheet: View {
    let label: String
    let explanation: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR SKIN TYPE")
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)
            Text(label.capitalizedFirst)
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
                .padding(.top, 10)
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    part("Your skin", explanation)
                    ForEach(SkinTypeGuide.parts(for: label), id: \.self) { item in
                        part(item.title, item.text)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            Button { dismiss() } label: {
                Text("Got it")
                    .font(FLFont.sans(14, .medium))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: 0xF6EAE8), in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 14)
        }
        .padding(.horizontal, 28)
        .padding(.top, 40)
        .padding(.bottom, 8)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(Palette.sheet)
    }

    private func part(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FLFont.sans(14, .semibold))
                .foregroundStyle(Palette.ink)
            Text(text)
                .font(FLFont.sans(13.9))
                .foregroundStyle(Palette.body)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The deeper read on one concern. Reads live from the store, so it fills in as soon as the
/// background writing finishes.
private struct ConcernSheet: View {
    let scanID: UUID
    let initial: Consult.Concern
    let score: Int?
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var store

    private var concern: Consult.Concern {
        store.scan(with: scanID)?.consult?.concerns.first { $0.key == initial.key } ?? initial
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(concern.severityLabel.uppercased())
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)
            Text(concern.title)
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
                .padding(.top, 10)
            if let score {
                MeasureBar(name: Measure.name(concern.key), score: score)
                    .padding(.top, 16)
            }
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    part("What we see", concern.seen)
                    if concern.hasDeepRead {
                        part("Why it happens", concern.why)
                        part("What to do", concern.todo)
                        part("What to expect", concern.expect)
                    } else if store.deepReadsFailed.contains(scanID) && !store.deepReadsLoading.contains(scanID) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("We couldn't finish your deep dive just now.")
                                .font(FLFont.sans(13.9))
                                .foregroundStyle(Palette.body)
                            Button("Try again") {
                                Task { await store.loadDeepReads(for: scanID, retry: true) }
                            }
                            .font(FLFont.sans(14, .semibold))
                            .foregroundStyle(Palette.rose)
                        }
                    } else {
                        DeepReadPlaceholder()
                    }
                }
                .animation(.easeOut(duration: 0.3), value: concern.hasDeepRead)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            Button { dismiss() } label: {
                Text("Got it")
                    .font(FLFont.sans(14, .medium))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: 0xF6EAE8), in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 14)
        }
        .padding(.horizontal, 28)
        .padding(.top, 40)
        .padding(.bottom, 8)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(Palette.sheet)
    }

    private func part(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FLFont.sans(14, .semibold))
                .foregroundStyle(Palette.ink)
            Text(text)
                .font(FLFont.sans(13.9))
                .foregroundStyle(Palette.body)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Every measurement from this scan, for anyone who wants the numbers.
private struct MeasurementsSheet: View {
    let measures: [String: Int]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ALL MEASUREMENTS")
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)
            Text("Higher is healthier.")
                .font(FLFont.sans(13))
                .foregroundStyle(Palette.pebble)
                .padding(.top, 8)
            VStack(spacing: 18) {
                ForEach(Measure.order.filter { measures[$0] != nil }, id: \.self) { key in
                    MeasureBar(name: Measure.name(key), score: measures[key] ?? 0)
                }
            }
            .padding(.top, 22)
            Spacer(minLength: 12)
            Button { dismiss() } label: {
                Text("Done")
                    .font(FLFont.sans(14, .medium))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: 0xF6EAE8), in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, 28)
        .padding(.top, 40)
        .padding(.bottom, 8)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(Palette.sheet)
    }
}

private struct MeasureBar: View {
    let name: String
    let score: Int
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(name)
                    .font(FLFont.sans(13, .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text("\(score)")
                    .font(FLFont.sans(12.5, .semibold))
                    .foregroundStyle(Palette.rose)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.track)
                    Capsule()
                        .fill(Palette.rose)
                        .frame(width: geo.size.width * (isRevealed ? CGFloat(score) / 100 : 0))
                }
            }
            .frame(height: 3)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) { isRevealed = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(score) out of 100")
    }
}

private extension String {
    /// "combination skin" -> "Combination skin"
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
