import SwiftUI

/// Bottom sheet with a plain-language explanation ("Learn more", FAQ, progress update).
struct InsightSheet: View {
    let content: InsightContent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(content.label)
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(content.accent)

            if let score = content.score {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(score)")
                        .font(FLFont.serif(46))
                        .foregroundStyle(Palette.ink)
                    Text(content.rating ?? "")
                        .font(FLFont.serifItalic(17))
                        .foregroundStyle(content.accent)
                }
                .padding(.top, 10)
            } else if let title = content.title {
                Text(title)
                    .font(FLFont.serif(26))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 12)
            }

            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 14)

            ScrollView {
                Text(content.text)
                    .font(FLFont.sans(13.9))
                    .foregroundStyle(Palette.body)
                    .lineSpacing(7.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            Button {
                dismiss()
            } label: {
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
        .presentationDetents([.fraction(0.62), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(Palette.sheet)
        .presentationContentInteraction(.scrolls)
    }
}
