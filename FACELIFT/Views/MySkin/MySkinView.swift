import SwiftUI

/// Skin profile summary and a timeline of past scans.
struct MySkinView: View {
    @Environment(AppStore.self) private var store
    @State private var sharing: Scan?
    @State private var deleting: Scan?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Your Skin Analysis.")

                profileCard
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                HStack(spacing: 12) {
                    Text("YOUR SCANS")
                        .font(FLFont.sans(10, .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Palette.stone)
                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                VStack(spacing: 0) {
                    ForEach(Array(store.scans.enumerated()), id: \.element.id) { offset, scan in
                        ScanTimelineRow(
                            scan: scan,
                            previousScore: store.scans.indices.contains(offset + 1) ? store.scans[offset + 1].overallScore : nil,
                            isFirst: offset == 0,
                            isLast: offset == store.scans.count - 1
                        )
                        // Long-press a scan to share it as a picture or delete it.
                        .contextMenu {
                            if !scan.isSample {
                                Button {
                                    sharing = scan
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }
                            Button(role: .destructive) {
                                deleting = scan
                            } label: {
                                Label("Delete scan", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(Palette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $sharing) { scan in
            ShareScanSheet(scan: scan)
                .presentationDetents([.large])
                .presentationCornerRadius(32)
        }
        .confirmationDialog(
            "Delete this scan? This can't be undone.",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible,
            presenting: deleting
        ) { scan in
            Button("Delete scan", role: .destructive) {
                withAnimation(.snappy) { store.deleteScan(scan.id) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("YOUR SKIN PROFILE")
                .padding(.bottom, 12)

            HStack {
                profileLabel("Skin Type")
                Spacer()
                ProfileChip(text: store.profileSkinType)
            }
            .padding(.bottom, 13)

            Rectangle().fill(Palette.rowDivider).frame(height: 1)

            HStack(alignment: .top, spacing: 12) {
                profileLabel("Top Concerns")
                    .padding(.top, 2)
                Spacer(minLength: 0)
                FlowLayout(spacing: 5, lineSpacing: 6, alignTrailing: true) {
                    ForEach(store.latestScan?.shortConcerns ?? [], id: \.self) { concern in
                        ProfileChip(text: concern)
                    }
                }
                .frame(maxWidth: 180)
            }
            .padding(.vertical, 13)

            Rectangle().fill(Palette.rowDivider).frame(height: 1)

            HStack {
                profileLabel("Last Scanned")
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Palette.rose)
                    Text(store.lastScannedText)
                        .font(FLFont.sans(11.7, .medium))
                        .foregroundStyle(Palette.ink)
                }
            }
            .padding(.top, 15)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .cardSurface()
    }

    private func profileLabel(_ text: String) -> some View {
        Text(text)
            .font(FLFont.sans(11.8))
            .foregroundStyle(Palette.stone)
    }
}

private struct ScanTimelineRow: View {
    let scan: Scan
    /// The scan before this one, for the change badge.
    let previousScore: Int?
    let isFirst: Bool
    let isLast: Bool

    private let avatarSize: CGFloat = 52

    var body: some View {
        NavigationLink(value: MySkinRoute.scan(id: scan.id, isFresh: false)) {
            HStack(alignment: .center, spacing: 14) {
                scoreRing
                card
            }
            .padding(.vertical, 6)
            .background(alignment: .leading) {
                timeline
            }
        }
        .buttonStyle(CardPressStyle())
    }

    /// The Skin Score at a glance: the number inside a ring filled to the score.
    private var scoreRing: some View {
        let score = scan.overallScore
        return ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Palette.roseLine, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(score, 0), 100)) / 100)
                .stroke(Palette.rose, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(FLFont.serif(21))
                .foregroundStyle(Palette.ink)
                .monospacedDigit()
        }
        .frame(width: avatarSize, height: avatarSize)
        .accessibilityElement()
        .accessibilityLabel("Skin Score \(score)")
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : Palette.roseLine)
                .frame(width: 1)
            Color.clear.frame(height: avatarSize)
            Rectangle()
                .fill(isLast ? Color.clear : Palette.roseLine)
                .frame(width: 1)
        }
        .frame(width: avatarSize)
        .allowsHitTesting(false)
    }

    private var card: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(scan.formattedDate)
                        .font(FLFont.serif(19.9))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 0)
                    if let change {
                        changeBadge(change)
                    }
                }
                FlowLayout(spacing: 5, lineSpacing: 5) {
                    ForEach(scan.shortConcerns, id: \.self) { concern in
                        ConcernChip(text: concern)
                    }
                }
                .padding(.top, 5)
                Text(ratingLine)
                    .font(FLFont.serifItalic(12))
                    .foregroundStyle(Palette.faint)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Palette.quiet)
        }
        .padding(.leading, 15)
        .padding(.trailing, 18)
        .padding(.vertical, 15)
        .cardSurface(radius: 20)
    }

    private var change: Int? {
        previousScore.map { scan.overallScore - $0 }
    }

    /// "Good · 2 products shopped"
    private var ratingLine: String {
        let shopped = scan.productsShopped > 0 ? " · \(scan.productsShopped) \(scan.productsShopped == 1 ? "product" : "products") shopped" : ""
        return SampleData.rating(for: scan.overallScore) + shopped
    }

    /// Up, down or steady since the scan before.
    private func changeBadge(_ change: Int) -> some View {
        let up = change > 0, down = change < 0
        return HStack(spacing: 3) {
            if up || down {
                Image(systemName: up ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
            }
            Text(up || down ? "\(abs(change))" : "Steady")
                .font(FLFont.sans(11.5, .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(up ? Palette.sage : Palette.stone)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background((up ? Palette.sage : Palette.stone).opacity(0.1), in: Capsule())
        .accessibilityLabel(up ? "Up \(change)" : down ? "Down \(-change)" : "Steady")
    }
}
