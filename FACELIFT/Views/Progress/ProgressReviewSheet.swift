import SwiftUI

/// The deeper read behind "Your progress update": the short note on top, then the latest
/// full review (what's changing, what's holding, our focus, next scan). Reads the store live,
/// so a review that finishes while it's open appears in place.
struct ProgressReviewSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR PROGRESS UPDATE")
                .font(FLFont.sans(9.5, .semibold))
                .tracking(2.4)
                .foregroundStyle(Palette.rose)
            Text(store.progressReview?.title.capitalizedFirst ?? "Since your last scan")
                .font(FLFont.serif(28))
                .foregroundStyle(Palette.ink)
                .padding(.top, 12)
            Rectangle()
                .fill(Palette.hairline)
                .frame(height: 1)
                .padding(.top, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    part("Since your last scan", store.progressUpdate)

                    if let review = store.progressReview {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full review · \(review.date.formatted(.dateTime.month(.abbreviated).day())) · across \(review.scanCount) scans")
                                .font(FLFont.sans(11.5, .medium))
                                .foregroundStyle(Palette.stone)
                            Text(review.summary)
                                .font(FLFont.sans(14))
                                .foregroundStyle(Palette.body)
                                .lineSpacing(6)
                        }

                        if !review.changes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                heading("What's changing")
                                ForEach(review.changes) { change in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(Measure.name(change.area))
                                            .font(FLFont.sans(13.5, .semibold))
                                            .foregroundStyle(Palette.ink)
                                        Text(change.note)
                                            .font(FLFont.sans(13.9))
                                            .foregroundStyle(Palette.body)
                                            .lineSpacing(5)
                                    }
                                }
                            }
                        }
                        part("Holding steady", review.steady)
                        part("Our focus", review.focus)
                        part("Your next scan", review.next)
                    } else if store.isWritingReview {
                        HStack(spacing: 10) {
                            ProgressView().controlSize(.small).tint(Palette.rose)
                            Text("We're writing your full review. It will appear here in a moment.")
                                .font(FLFont.sans(13.5))
                                .foregroundStyle(Palette.stone)
                        }
                    } else if store.scans.filter({ !$0.isSample }).count >= 2 {
                        Text("Your full review will appear after your next scan.")
                            .font(FLFont.sans(13.5))
                            .foregroundStyle(Palette.stone)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .animation(.easeOut(duration: 0.3), value: store.progressReview)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            Button { dismiss() } label: {
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(Palette.sheet)
    }

    private func heading(_ text: String) -> some View {
        Text(text.uppercased())
            .font(FLFont.sans(10, .semibold))
            .tracking(1.8)
            .foregroundStyle(Palette.rose)
    }

    private func part(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            heading(title)
            Text(text)
                .font(FLFont.sans(13.9))
                .foregroundStyle(Palette.body)
                .lineSpacing(6)
        }
    }
}
