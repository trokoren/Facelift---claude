import SwiftUI

struct HelpFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedback: String = ""
    @State private var insight: InsightContent?
    @State private var sentCount: Int = 0
    @State private var didSend: Bool = false
    @FocusState private var isEditorFocused: Bool

    private var canSend: Bool {
        !feedback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Help & Feedback.", onBack: { dismiss() })

                SectionLabel("FAQ")
                    .padding(.horizontal, 28)
                    .padding(.top, 22)

                VStack(spacing: 0) {
                    ForEach(Array(SampleData.faq.enumerated()), id: \.element.id) { offset, item in
                        if offset > 0 { RowDivider() }
                        Button {
                            insight = InsightContent(label: "FAQ", accent: Palette.rose, title: item.question, text: item.answer)
                        } label: {
                            SettingsRow(title: item.question)
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .cardSurface()
                .padding(.horizontal, 24)
                .padding(.top, 12)

                SectionLabel("SEND FEEDBACK")
                    .padding(.horizontal, 28)
                    .padding(.top, 22)

                feedbackCard
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $insight) { item in
            InsightSheet(content: item)
        }
        .sensoryFeedback(.success, trigger: sentCount)
    }

    private var feedbackCard: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $feedback)
                    .font(FLFont.sans(12.9))
                    .foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .focused($isEditorFocused)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                if feedback.isEmpty {
                    Text(didSend ? "Thank you - we read every note." : "Tell us anything.")
                        .font(FLFont.sans(12.9))
                        .foregroundStyle(Palette.stone)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 128)
            .background(Color.white, in: .rect(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isEditorFocused ? Palette.rose.opacity(0.6) : Palette.roseBorder.opacity(0.7), lineWidth: 1)
            )

            Button {
                send()
            } label: {
                Text(didSend && !canSend ? "Sent" : "Send")
                    .font(FLFont.sans(13.5))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Palette.rose, in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .opacity(canSend || !didSend ? 1 : 0.7)
        }
        .padding(16)
        .cardSurface()
    }

    private func send() {
        guard canSend else {
            isEditorFocused = true
            return
        }
        feedback = ""
        isEditorFocused = false
        didSend = true
        sentCount += 1
    }
}
