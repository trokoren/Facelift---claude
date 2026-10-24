import SwiftUI

/// Dimmed portrait with a compact "Before you scan" card.
struct ScanInstructionsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var pulse: Bool = false

    var body: some View {
        // The card is only as tall as its content; the photo fills whatever space is left,
        // so there's no dead gap under the steps on taller phones.
        VStack(spacing: 0) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    Image("onb_ready_scan")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(Color.black.opacity(0.5))
                        .allowsHitTesting(false)
                }
                .clipped()
                .overlay(alignment: .top) {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(Palette.nightDot)
                            .frame(width: 8, height: 8)
                            .opacity(pulse ? 0.35 : 1)
                            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                        Text("CAMERA ACTIVE")
                            .font(FLFont.sans(15))
                            .tracking(1.6)
                            .foregroundStyle(Color(hex: 0xA79D99))
                    }
                    .padding(.top, 12)
                }
                .padding(.bottom, -40)
                .ignoresSafeArea(edges: .top)

            sheet
                .frame(maxWidth: .infinity)
                .background(Color.white.ignoresSafeArea(edges: .bottom))
                .clipShape(.rect(topLeadingRadius: 40, topTrailingRadius: 40, style: .continuous))
        }
        .background(Color.white.ignoresSafeArea())
        // Same place as every other onboarding screen: top left, under the status bar.
        .overlay(alignment: .topLeading) {
            OnboardingBackButton(tint: .white.opacity(0.85)) { flow.back() }
                .padding(.leading, 10)
        }
        .onAppear { pulse = true }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Before you scan")
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
                .padding(.top, 26)

            // One good photo and the most common mistakes, so she knows what a clear scan looks like.
            HStack(alignment: .top, spacing: 10) {
                PhotoExample(kind: .good)
                PhotoExample(kind: .dark)
                PhotoExample(kind: .blurry)
                PhotoExample(kind: .offCenter)
            }
            .padding(.top, 14)

            VStack(spacing: 12) {
                // Light leads: good, consistent light is what makes scan-to-scan progress real.
                InstructionRow(number: 1, image: "onb_step2", title: "Find a spot with good light", detail: "Never scan in the dark")
                InstructionRow(number: 2, image: "onb_step1", title: "Glasses off, look ahead", detail: "Keep your face in the circle")
                InstructionRow(number: 3, image: "onb_step3", title: "Move in a slow circle", detail: "Fill the ring all the way around")
            }
            .padding(.top, 16)

            PrivacyNote(tint: Palette.stone)
                .frame(maxWidth: .infinity)
                .padding(.top, 18)

            OnboardingCTA(title: "I'm ready") { flow.next() }
                .padding(.top, 22)
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 24)
    }
}

private struct InstructionRow: View {
    let number: Int
    var image: String? = nil
    /// Shown in place of a photo when there is none.
    var symbol: String? = nil
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 0) {
            Text("\(number)")
                .font(FLFont.sans(15, .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Palette.rose, in: Circle())

            Color(hex: 0xEAE7E4)
                .frame(width: 72, height: 72)
                .overlay {
                    if let image {
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else if let symbol {
                        ZStack {
                            LinearGradient(colors: [Color(hex: 0xFCF1E8), Color(hex: 0xF4DEDA)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            Image(systemName: symbol)
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(Palette.rose)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .padding(.leading, 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FLFont.sans(16, .medium))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(FLFont.sans(14.5))
                    .foregroundStyle(Palette.mist)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 14)

            Spacer(minLength: 0)
        }
    }
}

/// A small sample photo with a check or an X: what a good scan photo looks like, and what to avoid.
private struct PhotoExample: View {
    enum Kind {
        case good, dark, blurry, offCenter

        var label: String {
            switch self {
            case .good: "Clear"
            case .dark: "Too dark"
            case .blurry: "Blurry"
            case .offCenter: "Off center"
            }
        }
    }

    let kind: Kind

    var body: some View {
        VStack(spacing: 6) {
            Color(hex: 0xEAE7E4)
                .aspectRatio(1, contentMode: .fit)
                .overlay { photo }
                .clipShape(.rect(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(kind == .good ? Palette.sage : Color.clear, lineWidth: 2)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: kind == .good ? "checkmark" : "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(kind == .good ? Palette.sage : Palette.rose, in: Circle())
                        .padding(4)
                }

            Text(kind.label)
                .font(FLFont.sans(12.5, kind == .good ? .medium : .regular))
                .foregroundStyle(kind == .good ? Palette.ink : Palette.mist)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind == .good ? "Good example: \(kind.label)" : "Avoid: \(kind.label)")
    }

    /// The same front-facing photo, changed to show each mistake.
    @ViewBuilder
    private var photo: some View {
        let base = Image("onb_step1").resizable().aspectRatio(contentMode: .fill)
        switch kind {
        case .good:
            base
        case .dark:
            base.brightness(-0.42).saturation(0.6)
        case .blurry:
            base.blur(radius: 3.5)
        case .offCenter:
            base.scaleEffect(1.7).offset(x: 22, y: 18)
        }
    }
}
