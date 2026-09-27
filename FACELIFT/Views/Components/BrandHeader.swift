import SwiftUI

/// "FACELIFT  Your Skin Analysis." header with a rose hairline underneath.
struct BrandHeader<Trailing: View>: View {
    let subtitle: String
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("FACELIFT")
                        .font(FLFont.serifMedium(17))
                        .tracking(3.2)
                        .foregroundStyle(Palette.rose)
                    Text(subtitle)
                        .font(FLFont.serifItalic(14))
                        .foregroundStyle(Palette.mist)
                }
                HStack(spacing: 0) {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Palette.stone)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableStyle(scale: 0.9))
                        .padding(.leading, -15)
                        .accessibilityLabel("Back")
                    }
                    Spacer(minLength: 0)
                    trailing()
                }
            }
            .frame(height: 36)
            .padding(.horizontal, 24)

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 10)
                .padding(.horizontal, 24)
        }
        .padding(.top, 2)
    }
}

extension BrandHeader where Trailing == EmptyView {
    init(subtitle: String, onBack: (() -> Void)? = nil) {
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = { EmptyView() }
    }
}
