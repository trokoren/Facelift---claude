import SwiftUI

/// Skin profile summary and a timeline of past scans.
struct MySkinView: View {
    @Environment(AppStore.self) private var store

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
                            isFirst: offset == 0,
                            isLast: offset == store.scans.count - 1
                        )
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
    let isFirst: Bool
    let isLast: Bool

    private let avatarSize: CGFloat = 47

    var body: some View {
        NavigationLink(value: MySkinRoute.scan(id: scan.id, isFresh: false)) {
            HStack(alignment: .center, spacing: 14) {
                avatar
                card
            }
            .padding(.vertical, 6)
            .background(alignment: .leading) {
                timeline
            }
        }
        .buttonStyle(CardPressStyle())
    }

    private var avatar: some View {
        Circle()
            .fill(Palette.blush)
            .overlay {
                if let name = scan.portraitName {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    FaceLineIcon()
                        .stroke(Palette.rose, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                        .frame(width: 17, height: 23)
                }
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Palette.rose, lineWidth: 1.4))
            .frame(width: avatarSize, height: avatarSize)
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
                Text(scan.formattedDate)
                    .font(FLFont.serif(19.9))
                    .foregroundStyle(Palette.ink)
                FlowLayout(spacing: 5, lineSpacing: 5) {
                    ForEach(scan.shortConcerns, id: \.self) { concern in
                        ConcernChip(text: concern)
                    }
                }
                .padding(.top, 5)
                Text(scan.metaLine)
                    .font(FLFont.serifItalic(11))
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
}
