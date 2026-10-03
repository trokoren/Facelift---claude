import SwiftUI

/// "How's it going?" about one product in her routine: one tap to answer, a short reply,
/// and an optional note. Answers are saved on her phone and shape her next consultation.
struct CheckInCard: View {
    let product: UsedProduct
    let onClose: () -> Void

    @Environment(AppStore.self) private var store
    @State private var answer: ProductCheckIn.Answer?
    @State private var entryID: UUID?
    @State private var reply: String = ""
    @State private var note: String = ""
    @FocusState private var noteFocused: Bool

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("HOW'S IT GOING?")
                    .font(FLFont.sans(9.5, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.rose)
                Spacer()
                if answer == nil {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Palette.stone)
                            .frame(width: 44, height: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                    .accessibilityLabel("Not now")
                    .padding(.vertical, -14)
                }
            }

            Text("How's the \(product.shortName) going?")
                .font(FLFont.serif(24))
                .foregroundStyle(Palette.ink)
                .padding(.top, 8)

            if let answer {
                Text(reply)
                    .font(FLFont.sans(13.5))
                    .foregroundStyle(Palette.body)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .transition(.opacity)

                TextField("Add a note (optional)", text: $note, axis: .vertical)
                    .font(FLFont.sans(14))
                    .lineLimit(1...3)
                    .focused($noteFocused)
                    .padding(12)
                    .background(Palette.blush.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 14)

                if answer == .stopped || answer == .irritating {
                    Button {
                        finish()
                        withAnimation(.snappy) { store.removeUsed(product) }
                    } label: {
                        Text("Remove from my routine")
                            .font(FLFont.sans(13.5, .medium))
                            .foregroundStyle(Palette.rose)
                            .frame(height: 40)
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 6)
                }

                OnboardingCTA(title: "Done") { finish() }
                    .padding(.top, 10)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ProductCheckIn.Answer.allCases, id: \.self) { option in
                        Button {
                            choose(option)
                        } label: {
                            Text(option.label)
                                .font(FLFont.sans(14, .medium))
                                .foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Palette.blush.opacity(0.6), in: Capsule())
                        }
                        .buttonStyle(PressableStyle(scale: 0.96))
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .background(AccentEdgeBackground(accent: Palette.rose))
        .sensoryFeedback(.selection, trigger: answer)
    }

    private func choose(_ option: ProductCheckIn.Answer) {
        entryID = store.recordCheckIn(product, answer: option)
        reply = store.checkInReply(for: product, answer: option)
        withAnimation(.snappy) { answer = option }
    }

    private func finish() {
        noteFocused = false
        if let entryID, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.updateCheckInNote(entryID, note: note)
        }
        withAnimation(.snappy) { onClose() }
    }
}
