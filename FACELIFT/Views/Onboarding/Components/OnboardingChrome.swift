import SwiftUI

/// Thin rose progress bar pinned to the very top edge of the screen.
struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color(hex: 0xEDE9E6))
                Rectangle()
                    .fill(Palette.rose)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 4)
        .ignoresSafeArea(edges: .top)
    }
}

/// Light "<" chevron used on every question screen.
struct OnboardingBackButton: View {
    var tint: Color = Palette.faint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .accessibilityLabel("Back")
    }
}

/// Serif headline + sans subtitle centered at the top of a question screen.
struct OnboardingTitle: View {
    let title: String
    var subtitle: String? = nil
    var titleSize: CGFloat = 32
    var showsSparkle: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if showsSparkle {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Palette.rose)
                    .padding(.bottom, 26)
            }
            Text(title)
                .font(FLFont.serif(titleSize))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(-2)
            if let subtitle {
                Text(subtitle)
                    .font(FLFont.sans(15))
                    .foregroundStyle(Palette.mist)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Full-width rose pill call to action.
struct OnboardingCTA: View {
    let title: String
    var isEnabled: Bool = true
    var fill: Color = Palette.rose
    var foreground: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FLFont.sans(17))
                .tracking(0.4)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(fill, in: Capsule())
        }
        .buttonStyle(PressableStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

/// White option row with a soft border. Optional leading accessory (dot / icon) and centered or leading text.
struct OnboardingOption<Leading: View>: View {
    let title: String
    let isSelected: Bool
    var alignment: HorizontalAlignment = .center
    var height: CGFloat = 62
    let action: () -> Void
    @ViewBuilder var leading: () -> Leading

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 0) {
                    leading()
                    Spacer(minLength: 0)
                }
                .padding(.leading, 24)

                HStack(spacing: 0) {
                    Text(title)
                        .font(FLFont.sans(17.5))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if alignment == .leading { Spacer(minLength: 0) }
                }
                .padding(.leading, alignment == .leading ? leadingInset : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Palette.blush : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Palette.rose : Color(hex: 0xEFEBE7), lineWidth: isSelected ? 1.4 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .animation(.easeOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(CardPressStyle())
    }

    private var leadingInset: CGFloat {
        Leading.self == EmptyView.self ? 30 : 84
    }
}

extension OnboardingOption where Leading == EmptyView {
    init(title: String, isSelected: Bool, alignment: HorizontalAlignment = .center, height: CGFloat = 62, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.alignment = alignment
        self.height = height
        self.action = action
        self.leading = { EmptyView() }
    }
}

/// Standard light question page: progress bar, back chevron, title and content.
struct OnboardingPage<Content: View, Footer: View>: View {
    @Environment(OnboardingStore.self) private var flow
    let title: String
    var subtitle: String? = nil
    var titleSize: CGFloat = 32
    var showsSparkle: Bool = false
    var titleTop: CGFloat = 12
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if flow.step.showsBack {
                    OnboardingBackButton { flow.back() }
                        .padding(.leading, 10)
                }
                Spacer()
            }
            .frame(height: 44)

            ScrollView {
                VStack(spacing: 0) {
                    OnboardingTitle(title: title, subtitle: subtitle, titleSize: titleSize, showsSparkle: showsSparkle)
                        .padding(.horizontal, 24)
                        .padding(.top, titleTop)
                    content()
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            footer()
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.canvas.ignoresSafeArea())
    }
}

extension OnboardingPage where Footer == EmptyView {
    init(title: String, subtitle: String? = nil, titleSize: CGFloat = 32, showsSparkle: Bool = false, titleTop: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.titleSize = titleSize
        self.showsSparkle = showsSparkle
        self.titleTop = titleTop
        self.content = content
        self.footer = { EmptyView() }
    }
}

/// Row of five gold stars.
struct GoldStars: View {
    var size: CGFloat = 28
    var spacing: CGFloat = 12
    var color: Color = Palette.gold

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(color)
            }
        }
        .accessibilityLabel("Five stars")
    }
}
