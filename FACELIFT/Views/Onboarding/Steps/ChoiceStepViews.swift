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
    private let options: [(String, String, Color)] = [
        ("Dehydration", "drop", Palette.sky),
        ("Fine Lines", "water.waves", Palette.gold),
        ("Texture", "circle.grid.3x3", Palette.ember),
        ("Dullness", "sun.max", Color(hex: 0xE39A3B)),
        ("Redness", "face.smiling", Color(hex: 0xD8636B)),
        ("Firmness", "arrow.up.to.line", Color(hex: 0x8F7BD8)),
        ("Dark Spots", "circle.hexagongrid", Color(hex: 0xA88B5A)),
        ("Breakouts", "circle.circle", Palette.sage),
        ("Large Pores", "circle.dotted.circle", Palette.sky)
    ]

    var body: some View {
        OnboardingPage(title: "What worries you most\nabout your skin?", titleSize: 33, titleTop: 4) {
            VStack(spacing: 10) {
                ForEach(options, id: \.0) { option, symbol, color in
                    OnboardingOption(title: option, isSelected: flow.answers.concerns.contains(option), alignment: .leading, height: 58) {
                        flow.toggle(option, in: \.concerns)
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
    private let options: [(String, String, Color)] = [
        ("More Confident", "face.smiling", Color(hex: 0xD8636B)),
        ("Younger", "face.smiling.inverse", Palette.gold),
        ("Balanced & calm about my skin", "face.smiling", Palette.sage),
        ("I can go makeup free", "face.smiling.inverse", Color(hex: 0x8F7BD8)),
        ("All of the above", "star", Palette.rose)
    ]

    var body: some View {
        OnboardingPage(title: "How do you want to feel in\n28 days?", subtitle: "Your goal shapes everything we recommend.", titleSize: 33, titleTop: 4) {
            timeline
                .padding(.top, 26)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option, symbol, color in
                    OnboardingOption(title: option, isSelected: flow.answers.mainGoal == option, alignment: .leading, height: 64) {
                        flow.choose(option, into: \.mainGoal)
                    } leading: {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(color)
                            .frame(width: 28)
                    }
                }
            }
            .padding(.top, 30)
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
    private let options: [String] = ["Pregnant", "Breastfeeding", "Menopause", "Hormonal imbalances", "Autoimmune condition", "None of these"]

    var body: some View {
        OnboardingPage(title: "Anything specific we\nshould know about you?", subtitle: "This helps us keep your recommendations safe and\npersonal.", titleSize: 33, titleTop: 4) {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OnboardingOption(title: option, isSelected: flow.answers.healthContext.contains(option), alignment: .leading, height: 62) {
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
    @FocusState private var isFocused: Bool

    private let cities: [String] = [
        "New York, US", "Los Angeles, US", "London, UK", "Paris, FR", "Berlin, DE", "Madrid, ES",
        "Rome, IT", "Amsterdam, NL", "Dubai, AE", "Singapore, SG", "Sydney, AU", "Toronto, CA",
        "Miami, US", "Chicago, US", "San Francisco, US", "Tokyo, JP", "Seoul, KR", "Mumbai, IN",
        "São Paulo, BR", "Mexico City, MX", "Stockholm, SE", "Lisbon, PT", "Vienna, AT", "Zurich, CH"
    ]

    private var matches: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return cities.filter { $0.localizedStandardContains(trimmed) }
    }

    var body: some View {
        OnboardingPage(title: "Where do you live?", subtitle: "Your local UV index, humidity, and pollution\naffect your skin daily.", titleSize: 34, titleTop: 4) {
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
            }
            .padding(.horizontal, 22)
            .frame(height: 80)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: 0xEFEBE7), lineWidth: 1))
            .padding(.top, 30)

            if !matches.isEmpty {
                VStack(spacing: 0) {
                    ForEach(matches.prefix(6), id: \.self) { city in
                        Button {
                            select(city)
                        } label: {
                            HStack {
                                Text(city)
                                    .font(FLFont.sans(17))
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundStyle(Palette.faint)
                            }
                            .padding(.horizontal, 24)
                            .frame(height: 58)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(CardPressStyle())
                        if city != matches.prefix(6).last { RowDivider() }
                    }
                }
                .cardSurface(radius: 22)
                .padding(.top, 12)
            }
        } footer: {
            if matches.isEmpty && !query.trimmingCharacters(in: .whitespaces).isEmpty {
                OnboardingCTA(title: "Use \"\(query.trimmingCharacters(in: .whitespaces))\"") { commitTyped() }
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
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            isFocused = true
        }
    }

    private func select(_ city: String) {
        isFocused = false
        flow.answers.city = city
        query = city
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            flow.next()
        }
    }

    private func commitTyped() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        select(matches.first ?? trimmed)
    }
}
