import SwiftUI

// MARK: - Age

struct AgeStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [String] = ["Under 25", "25–34", "35–44", "45–60", "Over 60"]

    var body: some View {
        OnboardingPage(title: "How old is your skin?", subtitle: "At different ages your skin needs\na different approach.", showsSparkle: true, titleTop: 16) {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.ageRange == option) {
                        flow.choose(option, into: \.ageRange)
                    }
                }
            }
            .padding(.top, 28)
        }
    }
}

// MARK: - Skin type

struct SkinTypeStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [(String, Color)] = [
        ("Dry", Palette.sky), ("Oily", Palette.gold), ("Combination", Palette.rose), ("I don't really know", Palette.sage)
    ]

    var body: some View {
        OnboardingPage(title: "What's your skin type?", subtitle: "This helps us calibrate your analysis\nto your baseline.", showsSparkle: true, titleTop: 16) {
            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option, color in
                    OnboardingOption(title: option, isSelected: flow.answers.skinType == option) {
                        flow.choose(option, into: \.skinType)
                    } leading: {
                        Circle().fill(color).frame(width: 11, height: 11)
                    }
                }
            }
            .padding(.top, 28)
        }
    }
}

// MARK: - Pain points (multi)

struct PainPointsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    /// (concern key sent with her consult, what she sees, icon, color). One for each of the
    /// 7 areas every scan measures, plus shine, which her skin type reading covers.
    private let options: [(String, String, String, Color)] = [
        ("Fine Lines", "Fine lines and wrinkles", "water.waves", Palette.gold),
        ("Dark Circles", "Dark circles under my eyes", "eye", Color(hex: 0x8F7BD8)),
        ("Dark Spots", "Dark spots and uneven tone", "circle.hexagongrid", Color(hex: 0xA88B5A)),
        ("Redness", "Redness that won't calm down", "flame", Color(hex: 0xD8636B)),
        ("Texture", "Rough, uneven texture", "circle.grid.3x3", Palette.ember),
        ("Large Pores", "Pores I can see in the mirror", "circle.dotted.circle", Palette.sky),
        ("Dehydration", "Dry, tight, thirsty skin", "drop", Palette.sky),
        ("Oiliness", "Shine and oily patches", "sun.max", Color(hex: 0xE39A3B))
    ]

    var body: some View {
        OnboardingPage(title: "What worries you most\nabout your skin?", subtitle: "Pick all that feel true.", titleSize: 33, titleTop: 4) {
            VStack(spacing: 10) {
                ForEach(options, id: \.0) { key, label, symbol, color in
                    OnboardingOption(title: label, isSelected: flow.answers.concerns.contains(key), alignment: .leading, height: 58) {
                        flow.toggle(key, in: \.concerns)
                    } leading: {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(color)
                            .frame(width: 28)
                    }
                }
            }
            .padding(.top, 24)
        } footer: {
            OnboardingCTA(title: "Continue", isEnabled: !flow.answers.concerns.isEmpty) { flow.next() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
    }
}

// MARK: - Sensitivity

struct SensitivityStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [String] = ["Yes, very sensitive", "Sometimes", "Not really"]

    var body: some View {
        OnboardingPage(title: "Would you consider your\nskin sensitive?", subtitle: "We'll adjust our recommendations to be gentle\nwhere needed.", titleSize: 33, titleTop: 4) {
            VStack(spacing: 10) {
                Capsule()
                    .fill(LinearGradient(colors: [Palette.sage, Color(hex: 0xC9B6A8), Palette.ember], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 10)
                HStack {
                    Text("Not sensitive")
                    Spacer()
                    Text("Very sensitive")
                }
                .font(FLFont.sans(13.5))
                .foregroundStyle(Palette.mist)
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.sensitivity == option) {
                        flow.choose(option, into: \.sensitivity)
                    }
                }
            }
            .padding(.top, 34)
        }
    }
}

// MARK: - Main goal

struct MainGoalStepView: View {
    @Environment(OnboardingStore.self) private var flow
    /// What she really wants from her skin: to be seen, desired, young. Each one ties to
    /// something the scan measures (tone, lines, hydration, texture, pores, redness).
    private let options: [(String, String, Color)] = [
        ("Seen as beautiful", "eye", Color(hex: 0xD8636B)),
        ("Younger, fresher-faced", "leaf", Palette.sage),
        ("Desired and attractive", "heart", Palette.rose),
        ("Glowing, lit from within", "sun.max", Palette.gold),
        ("Confident with no makeup", "face.smiling", Color(hex: 0x8F7BD8)),
        ("Camera-ready from any angle", "camera", Palette.sky),
        ("Calm, not hiding redness", "drop", Color(hex: 0xE39A3B)),
        ("Noticed when I walk in", "sparkles", Color(hex: 0xA88B5A))
    ]

    var body: some View {
        OnboardingPage(title: "How do you want to feel in\n28 days?", subtitle: "Pick all that feel true.", titleSize: 33, titleTop: 4) {
            timeline
                .padding(.top, 26)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(options, id: \.0) { option, symbol, color in
                    OnboardingOption(title: option, isSelected: flow.answers.feelings.contains(option), alignment: .leading, height: 56) {
                        flow.toggle(option, in: \.feelings)
                    } leading: {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(color)
                            .frame(width: 28)
                    }
                }
            }
            .padding(.top, 26)
        } footer: {
            OnboardingCTA(title: "Continue", isEnabled: !flow.answers.feelings.isEmpty) { flow.next() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
    }

    private var timeline: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Circle()
                    .fill(Palette.rose)
                    .frame(width: 14, height: 14)
                    .padding(6)
                    .overlay(Circle().stroke(Palette.rose, lineWidth: 1.6))
                Rectangle()
                    .fill(Palette.roseLine)
                    .frame(height: 1.5)
                    .mask(HStack(spacing: 5) { ForEach(0..<40, id: \.self) { _ in Rectangle().frame(width: 6) } })
                Circle()
                    .fill(Palette.rose.opacity(0.35))
                    .frame(width: 14, height: 14)
                    .padding(6)
                    .overlay(Circle().stroke(Palette.rose.opacity(0.7), lineWidth: 1.6))
                    .background(Circle().fill(Palette.rose.opacity(0.18)).padding(-6))
            }
            HStack {
                Text("Today").foregroundStyle(Palette.mist)
                Spacer()
                Text("Day 28").foregroundStyle(Palette.rose)
            }
            .font(FLFont.sans(14))
        }
    }
}

// MARK: - Budget

struct BudgetStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [String] = ["Under $30", "$30 to $75", "$75 to $150", "No limit"]

    var body: some View {
        OnboardingPage(title: "What's your monthly\nskincare budget?", subtitle: "We'll recommend products that fit what you're\ncomfortable spending.", titleSize: 33, titleTop: 4) {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.budget == option, height: 64) {
                        flow.choose(option, into: \.budget)
                    }
                }
            }
            .padding(.top, 36)
        }
    }
}

// MARK: - Health context (multi)

struct HealthContextStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [String] = ["Pregnant", "Trying to conceive", "Breastfeeding", "Menopause", "Hormonal imbalances", "Autoimmune condition", "None of these"]

    var body: some View {
        OnboardingPage(title: "Anything specific we\nshould know about you?", subtitle: "This helps us keep your recommendations safe and\npersonal.", titleSize: 33, titleTop: 4) {
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.healthContext.contains(option), alignment: .leading, height: 56) {
                        flow.toggle(option, in: \.healthContext, exclusive: "None of these")
                    }
                }
            }
            .padding(.top, 30)
        } footer: {
            OnboardingCTA(title: "Continue", isEnabled: !flow.answers.healthContext.isEmpty) { flow.next() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
    }
}

// MARK: - SPF

struct SPFStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [String] = ["Every single day", "Most days", "Only in summer", "Rarely", "Never"]

    var body: some View {
        OnboardingPage(title: "How often do you\nwear SPF?", subtitle: "No judgment here, just learning about you", titleSize: 33, titleTop: 4) {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.spfHabit == option, height: 54) {
                        flow.choose(option, into: \.spfHabit)
                    }
                }
            }
            .padding(.top, 56)
        }
    }
}

// MARK: - Current routine (grid, multi)

struct RoutineStepView: View {
    @Environment(OnboardingStore.self) private var flow
    private let options: [String] = [
        "Cleanser", "Moisturizer", "Serum", "Eye Cream", "Toner", "Face Oil",
        "Retinol", "Exfoliant", "Vitamin C", "Face Mask", "Spot Treatment", "Other"
    ]
    private let columns: [GridItem] = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        OnboardingPage(title: "What else do you use?", titleSize: 34, titleTop: 4) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.routine.contains(option), height: 64) {
                        flow.toggle(option, in: \.routine)
                    }
                }
            }
            .padding(.top, 28)
        } footer: {
            OnboardingCTA(title: "Continue") { flow.next() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
    }
}

// MARK: - Location

struct LocationStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var query: String = ""
    @State private var search = CitySearch()
    @State private var selectedTitle: String?
    @State private var conditions: SkinConditions?
    @State private var isLoading: Bool = false
    @FocusState private var isFocused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }
    private var showsSuggestions: Bool { selectedTitle == nil && !trimmed.isEmpty && !search.results.isEmpty }

    var body: some View {
        OnboardingPage(title: "Where do you live?", subtitle: "Your local UV index, humidity, and pollution\naffect your skin daily.", titleSize: 34, titleTop: 4) {
            searchField
                .padding(.top, 30)

            if showsSuggestions {
                suggestions
                    .padding(.top, 12)
            }

            if selectedTitle != nil {
                conditionsSection
                    .padding(.top, 14)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } footer: {
            footer
        }
        .animation(.easeOut(duration: 0.35), value: conditions)
        .animation(.easeOut(duration: 0.25), value: selectedTitle)
        .onChange(of: query) { _, newValue in
            // Typing again after a pick starts a fresh search.
            guard newValue != selectedTitle else { return }
            selectedTitle = nil
            conditions = nil
            search.update(newValue)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            isFocused = true
        }
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(Palette.mist)
            TextField("Search city…", text: $query)
                .font(FLFont.sans(17.5))
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit(commitTyped)
            if !query.isEmpty {
                Button {
                    query = ""
                    isFocused = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Palette.stone)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Clear")
            }
        }
        .padding(.leading, 22)
        .padding(.trailing, 12)
        .frame(height: 72)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: 0xEFEBE7), lineWidth: 1))
    }

    private var suggestions: some View {
        VStack(spacing: 0) {
            ForEach(search.results) { suggestion in
                Button {
                    select(suggestion)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(FLFont.sans(17))
                                .foregroundStyle(Palette.ink)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(FLFont.sans(13))
                                    .foregroundStyle(Palette.stone)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Palette.faint)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(CardPressStyle())
                if suggestion.id != search.results.last?.id { RowDivider() }
            }
        }
        .cardSurface(radius: 22)
    }

    // MARK: Conditions

    @ViewBuilder
    private var conditionsSection: some View {
        if let conditions {
            VStack(spacing: 14) {
                UVCard(conditions: conditions)
                HumidityCard(conditions: conditions)
                PollutionCard(conditions: conditions)
            }
        } else if isLoading {
            HStack(spacing: 10) {
                ProgressView()
                Text("Looking up your local climate…")
                    .font(FLFont.sans(14))
                    .foregroundStyle(Palette.stone)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        } else {
            Text("We couldn't load your local climate, but we saved your city.")
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.stone)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        if selectedTitle != nil {
            OnboardingCTA(title: "Continue") { flow.next() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        } else if !trimmed.isEmpty && search.results.isEmpty {
            OnboardingCTA(title: "Use \"\(trimmed)\"") { commitTyped() }
                .padding(.top, 8)
                .padding(.bottom, 10)
        } else {
            Button { flow.next() } label: {
                Text("Skip for now")
                    .font(FLFont.sans(15))
                    .foregroundStyle(Palette.stone)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .padding(.bottom, 10)
        }
    }

    // MARK: Actions

    private func select(_ suggestion: CitySearch.Suggestion) {
        isFocused = false
        selectedTitle = suggestion.title
        query = suggestion.title
        flow.answers.city = suggestion.fullName
        conditions = nil
        isLoading = true
        Task {
            if let coordinate = await search.coordinate(for: suggestion) {
                conditions = await SkinConditionsService.fetch(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
            isLoading = false
        }
    }

    private func commitTyped() {
        if let first = search.results.first {
            select(first)
        } else if !trimmed.isEmpty {
            flow.answers.city = trimmed
            isFocused = false
            flow.next()
        }
    }
}

// MARK: - Condition cards

private let uvColor = Color(hex: 0xDD8A55)

private struct ConditionCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: 0xEFEBE7), lineWidth: 1))
    }
}

private struct CardTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(FLFont.serifItalic(22))
            .foregroundStyle(Palette.stone)
    }
}

private struct UVCard: View {
    let conditions: SkinConditions

    var body: some View {
        ConditionCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    CardTitle(text: "Avg. UV Index")
                    Text("\(conditions.uvIndex)")
                        .font(FLFont.serif(44))
                        .foregroundStyle(uvColor)
                        .padding(.top, 6)
                    Text(conditions.uvLevel)
                        .font(FLFont.sans(16, .semibold))
                        .foregroundStyle(uvColor)
                    Text(conditions.uvAdvice)
                        .font(FLFont.sans(14))
                        .foregroundStyle(Palette.stone)
                        .padding(.top, 6)
                }
                Spacer()
                ZStack {
                    Circle().fill(uvColor.opacity(0.12)).frame(width: 64, height: 64)
                    Image(systemName: "sun.max")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(uvColor)
                }
                .padding(.top, 8)
            }
        }
    }
}

private struct HumidityCard: View {
    let conditions: SkinConditions

    var body: some View {
        ConditionCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    CardTitle(text: "Avg. Humidity")
                    Text("\(conditions.humidity)%")
                        .font(FLFont.serif(44))
                        .foregroundStyle(Palette.sky)
                        .padding(.top, 6)
                    Text(conditions.humidityLevel)
                        .font(FLFont.sans(16, .semibold))
                        .foregroundStyle(Palette.sky)
                }
                Spacer()
                Text(conditions.humidityNote)
                    .font(FLFont.sans(14))
                    .foregroundStyle(Palette.stone)
                    .multilineTextAlignment(.trailing)
                    .padding(.top, 20)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let value = CGFloat(min(max(conditions.humidity, 0), 100)) / 100
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.track)
                    Capsule()
                        .fill(Palette.sky.opacity(0.22))
                        .frame(width: width * 0.2)
                        .offset(x: width * 0.4)
                    Circle()
                        .fill(Palette.sky)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: Palette.sky.opacity(0.3), radius: 4)
                        .offset(x: width * value - 9)
                }
            }
            .frame(height: 18)
            .padding(.top, 18)

            HStack {
                Text("0%")
                Spacer()
                Text("Optimal").foregroundStyle(Palette.sky)
                Spacer()
                Text("100%")
            }
            .font(FLFont.sans(12))
            .foregroundStyle(Palette.mist)
            .padding(.top, 6)
        }
    }
}

private struct PollutionCard: View {
    let conditions: SkinConditions

    var body: some View {
        ConditionCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    CardTitle(text: "Air Pollution")
                    Text(conditions.pollutionLevel)
                        .font(FLFont.serif(44))
                        .foregroundStyle(Palette.sage)
                        .padding(.top, 6)
                    Text("AQI Classification")
                        .font(FLFont.sans(16, .semibold))
                        .foregroundStyle(Palette.sage)
                }
                Spacer()
                Text(conditions.pollutionNote)
                    .font(FLFont.sans(14))
                    .foregroundStyle(Palette.stone)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 130, alignment: .trailing)
                    .padding(.top, 20)
            }

            HStack(spacing: 8) {
                ForEach(Array(SkinConditions.pollutionLevels.enumerated()), id: \.offset) { index, level in
                    VStack(spacing: 8) {
                        Capsule()
                            .fill(index == conditions.pollutionIndex ? Palette.sage : Palette.track)
                            .frame(height: 10)
                        Text(level)
                            .font(FLFont.sans(12, index == conditions.pollutionIndex ? .semibold : .regular))
                            .foregroundStyle(index == conditions.pollutionIndex ? Palette.sage : Palette.mist)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(.top, 18)
        }
    }
}
