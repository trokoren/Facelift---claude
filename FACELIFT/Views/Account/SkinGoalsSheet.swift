import SwiftUI

struct SkinGoalsSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SKIN GOALS")
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)
            Text("What matters most to you?")
                .font(FLFont.serif(26))
                .foregroundStyle(Palette.ink)
                .padding(.top, 12)
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 14)

            FlowLayout(spacing: 8, lineSpacing: 10) {
                ForEach(SampleData.skinGoalOptions, id: \.self) { goal in
                    let isOn = store.skinGoals.contains(goal)
                    Button {
                        withAnimation(.snappy) { store.toggleGoal(goal) }
                    } label: {
                        Text(goal)
                            .font(FLFont.sans(13))
                            .foregroundStyle(isOn ? .white : Palette.ink)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(isOn ? Palette.rose : Palette.chip, in: Capsule())
                    }
                    .buttonStyle(PressableStyle(scale: 0.94))
                }
            }
            .padding(.top, 22)

            Spacer(minLength: 16)

            Button {
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
        .sensoryFeedback(.selection, trigger: store.skinGoals)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(Palette.sheet)
    }
}
