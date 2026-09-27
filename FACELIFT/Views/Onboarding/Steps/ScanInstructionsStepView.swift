import SwiftUI

/// Dimmed portrait with the "Scan Instructions" sheet.
struct ScanInstructionsStepView: View {
    @Environment(OnboardingStore.self) private var flow
    @State private var pulse: Bool = false

    var body: some View {
        GeometryReader { geo in
            let photoHeight = geo.size.height * 0.26 + geo.safeAreaInsets.top

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Image("onb_ready_scan")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: photoHeight + 40)
                        .clipped()
                        .overlay(Color.black.opacity(0.5))

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
                    .padding(.top, geo.safeAreaInsets.top + 12)
                }
                .frame(width: geo.size.width, height: photoHeight)

                sheet
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .clipShape(.rect(topLeadingRadius: 40, topTrailingRadius: 40, style: .continuous))
                    .padding(.top, -40)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear { pulse = true }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Scan Instructions")
                    .font(FLFont.serif(30))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button {
                    flow.back()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Palette.mist)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .padding(.trailing, -12)
                .accessibilityLabel("Close")
            }
            .padding(.top, 26)

            VStack(spacing: 16) {
                InstructionRow(number: 1, image: "onb_step1", title: "Take glasses off", detail: "And find a well-lit area")
                InstructionRow(number: 2, image: "onb_step2", title: "Keep head straight", detail: "Then press the Start button")
                InstructionRow(number: 3, image: "onb_step3", title: "Make a full circle", detail: "Slowly rotating and closing all the segments")
            }
            .padding(.top, 24)

            Spacer(minLength: 12)

            OnboardingCTA(title: "Continue") { flow.next() }
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 24)
    }
}

private struct InstructionRow: View {
    let number: Int
    let image: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 0) {
            Text("\(number)")
                .font(FLFont.sans(15, .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Palette.rose, in: Circle())

            Color(hex: 0xEAE7E4)
                .frame(width: 104, height: 104)
                .overlay {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
                .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FLFont.sans(17.5, .medium))
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(FLFont.sans(14.5))
                    .foregroundStyle(Palette.mist)
                    .lineSpacing(2)
            }
            .padding(.leading, 20)

            Spacer(minLength: 0)
        }
    }
}
