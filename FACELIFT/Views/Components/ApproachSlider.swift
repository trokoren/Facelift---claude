import SwiftUI

/// Clinical to Natural, in five stops. Used in onboarding and in Account.
struct ApproachSlider: View {
    @Binding var approach: SkincareApproach

    private var position: Binding<Double> {
        Binding(
            get: { Double(approach.rawValue) },
            set: { approach = SkincareApproach(rawValue: Int($0.rounded())) ?? .balanced }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(approach.title)
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.18), value: approach)

            Text(approach.detail)
                .font(FLFont.sans(13.5))
                .foregroundStyle(Palette.stone)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(minHeight: 40, alignment: .top)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.18), value: approach)

            Slider(value: position, in: 0...4, step: 1)
                .tint(Palette.rose)
                .padding(.top, 22)
                .accessibilityLabel("Skincare approach")
                .accessibilityValue(approach.title)

            HStack(spacing: 0) {
                ForEach(SkincareApproach.allCases) { stop in
                    Circle()
                        .fill(stop == approach ? Palette.rose : Palette.roseLine)
                        .frame(width: 6, height: 6)
                    if stop != .natural { Spacer(minLength: 0) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .accessibilityHidden(true)

            HStack {
                Text("Clinical")
                Spacer()
                Text("Natural")
            }
            .font(FLFont.sans(12, .semibold))
            .tracking(0.6)
            .foregroundStyle(Palette.taupe)
            .padding(.top, 10)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .cardSurface()
        .sensoryFeedback(.selection, trigger: approach)
    }
}

/// Account > Skincare Approach. Changing it re-picks the products on her latest scan.
struct ApproachSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var approach: SkincareApproach = .balanced

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SKINCARE APPROACH")
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)
            Text("How do you like your skincare?")
                .font(FLFont.serif(26))
                .foregroundStyle(Palette.ink)
                .padding(.top, 12)
            Text("Your product picks follow this setting.")
                .font(FLFont.sans(13))
                .foregroundStyle(Palette.stone)
                .padding(.top, 6)

            ApproachSlider(approach: $approach)
                .padding(.top, 22)

            Spacer(minLength: 16)

            Button {
                store.setApproach(approach)
                dismiss()
            } label: {
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
        .onAppear { approach = store.approach }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
    }
}
