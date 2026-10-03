import SwiftUI

/// A shareable picture of one scan: Skin Score, skin type and highlights. Never her photo
/// and never anything she told us about her health. Shared through the iPhone share sheet.
struct ShareScanSheet: View {
    let scan: Scan

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    private let message = "My skin score on FACELIFT. Get yours at https://faceliftai.app"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SHARE YOUR SCAN")
                    .font(FLFont.sans(12, .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Palette.stone)
                Spacer()
                Button("Close") { dismiss() }
                    .font(FLFont.sans(16, .medium))
                    .foregroundStyle(Palette.rose)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer(minLength: 16)

            ScanShareCard(scan: scan)
                .frame(width: ScanShareCard.size.width, height: ScanShareCard.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Palette.ink.opacity(0.10), radius: 18, y: 8)
                .scaleEffect(0.86)

            Text("Only your score and highlights are shared. Never your photo.")
                .font(FLFont.sans(12))
                .foregroundStyle(Palette.pebble)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer(minLength: 16)

            if let image {
                ShareLink(
                    item: Image(uiImage: image),
                    message: Text(message),
                    preview: SharePreview("My FACELIFT Skin Score", image: Image(uiImage: image))
                ) {
                    Text("Share")
                        .font(FLFont.sans(17, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(Palette.rose))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            } else {
                ProgressView()
                    .tint(Palette.rose)
                    .frame(height: 56)
                    .padding(.bottom, 12)
            }
        }
        .background(Palette.canvas.ignoresSafeArea())
        .task { render() }
    }

    /// Renders the card at 3x (1080 x 1350, a portrait Instagram size).
    private func render() {
        let renderer = ImageRenderer(content:
            ScanShareCard(scan: scan)
                .frame(width: ScanShareCard.size.width, height: ScanShareCard.size.height)
        )
        renderer.scale = 3
        image = renderer.uiImage
    }
}

/// The card itself, drawn at 360 x 450 points.
struct ScanShareCard: View {
    let scan: Scan
    static let size = CGSize(width: 360, height: 450)

    private var strengths: [String] {
        (scan.consult?.strengths ?? []).prefix(2).map(\.title)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFBF5F3), Palette.canvas, Color(hex: 0xF6E7E4)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Palette.rose.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 260)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("FACELIFT")
                        .font(FLFont.serif(18))
                        .tracking(5)
                        .foregroundStyle(Palette.rose)
                    Spacer()
                    Text(scan.date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(FLFont.sans(10.5, .medium))
                        .foregroundStyle(Palette.stone)
                }

                Text("MY SKIN SCORE")
                    .font(FLFont.sans(10, .semibold))
                    .tracking(2.2)
                    .foregroundStyle(Palette.stone)
                    .padding(.top, 34)

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("\(scan.overallScore)")
                        .font(FLFont.serif(104))
                        .foregroundStyle(Palette.ink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("/100")
                            .font(FLFont.sans(13))
                            .foregroundStyle(Palette.stone)
                        Text(SampleData.rating(for: scan.overallScore))
                            .font(FLFont.serifItalic(18))
                            .foregroundStyle(Palette.rose)
                    }
                    .padding(.bottom, 14)
                }

                if let type = scan.measuredSkinType {
                    Text("\(type) skin")
                        .font(FLFont.sans(12.5, .medium))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.7)))
                }

                Spacer(minLength: 16)

                if !strengths.isEmpty {
                    section("WHAT'S WORKING", items: strengths)
                }
                if !scan.shortConcerns.isEmpty {
                    section("FOCUSING ON", items: Array(scan.shortConcerns.prefix(3)))
                        .padding(.top, 14)
                }

                Spacer(minLength: 16)

                Rectangle().fill(Palette.roseLine).frame(height: 1)
                Text("Get your skin score at faceliftai.app")
                    .font(FLFont.sans(11, .medium))
                    .foregroundStyle(Palette.stone)
                    .padding(.top, 10)
            }
            .padding(28)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    private func section(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FLFont.sans(9.5, .semibold))
                .tracking(1.8)
                .foregroundStyle(Palette.rose)
            ForEach(items, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 9))
                        .foregroundStyle(Palette.rose)
                    Text(item)
                        .font(FLFont.sans(13))
                        .foregroundStyle(Palette.body)
                        .lineLimit(1)
                }
            }
        }
    }
}
