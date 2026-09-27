import SwiftUI

/// Annotated portrait + "Let's analyze your skin." sheet with the Scan My Skin CTA.
struct ReadyToScanStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @Environment(AppStore.self) private var store
    @State private var isRevealed: Bool = false

    var body: some View {
        GeometryReader { geo in
            let photoHeight = geo.size.height * 0.5 + geo.safeAreaInsets.top

            VStack(spacing: 0) {
                ZStack {
                    Image("onb_ready_scan")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: photoHeight)
                        .clipped()

                    callouts(width: geo.size.width, height: photoHeight)
                }
                .frame(width: geo.size.width, height: photoHeight)

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            store.completeOnboarding(with: flow.answers, signIn: false)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Palette.ink)
                                .frame(width: 48, height: 48)
                                .background(Color(hex: 0xEDE9E5), in: Circle())
                        }
                        .buttonStyle(PressableStyle(scale: 0.92))
                        .accessibilityLabel("Skip scan")
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 20)

                    Text("Let's analyze your skin.")
                        .font(FLFont.serif(34))
                        .foregroundStyle(Palette.ink)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                        .padding(.top, 2)
                    Text("You'll be able to track your skin's changes\nover time.")
                        .font(FLFont.sans(15))
                        .foregroundStyle(Palette.mist)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 10)

                    Spacer(minLength: 0)

                    OnboardingCTA(title: "Scan My Skin") { flow.next() }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .background(Palette.canvas)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) { isRevealed = true }
        }
    }

    private func callouts(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            Callout(title: "Hydration", chip: "Your Focus", chipStyle: .rose)
                .position(x: w - 108, y: h * 0.19)
            CalloutLine(from: CGPoint(x: w * 0.56, y: h * 0.27), to: CGPoint(x: w - 218, y: h * 0.20))

            Callout(title: "Fine Lines", chip: "Strength", chipStyle: .sage)
                .position(x: 108, y: h * 0.42)
            CalloutLine(from: CGPoint(x: w * 0.38, y: h * 0.43), to: CGPoint(x: w * 0.29, y: h * 0.50))

            Callout(title: "Combination", subtitle: "Your Skin Type")
                .position(x: w - 122, y: h * 0.65)
            CalloutLine(from: CGPoint(x: w * 0.53, y: h * 0.72), to: CGPoint(x: w * 0.69, y: h * 0.74))
        }
        .opacity(isRevealed ? 1 : 0)
        .scaleEffect(isRevealed ? 1 : 0.96)
        .allowsHitTesting(false)
    }
}

private struct Callout: View {
    enum ChipStyle { case rose, sage }

    let title: String
    var chip: String? = nil
    var chipStyle: ChipStyle = .rose
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FLFont.sans(15.5, .medium))
                .foregroundStyle(Palette.ink)
            if let chip {
                Text(chip)
                    .font(FLFont.sans(13))
                    .foregroundStyle(chipStyle == .rose ? Palette.rose : Color(hex: 0x4E8F6A))
                    .padding(.horizontal, 11)
                    .frame(height: 27)
                    .background(chipStyle == .rose ? Palette.blush : Color(hex: 0xE4EFE7), in: Capsule())
            }
            if let subtitle {
                Text(subtitle)
                    .font(FLFont.sans(13))
                    .foregroundStyle(Palette.stone)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CalloutLine: View {
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: from)
                p.addLine(to: to)
            }
            .stroke(Color(hex: 0xE7B7B5), lineWidth: 2)
            Circle().fill(Color(hex: 0xE7B7B5)).frame(width: 8, height: 8).position(from)
            Circle().stroke(Color(hex: 0xE7B7B5), lineWidth: 2).frame(width: 16, height: 16).position(to)
        }
    }
}
