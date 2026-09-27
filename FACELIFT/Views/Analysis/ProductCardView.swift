import SwiftUI

struct ProductCardView: View {
    let product: Recommendation.Product
    let index: Int
    let onShop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color(hex: 0xF1EEEA)
                .frame(height: 78)
                .overlay {
                    Image(product.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(product.tier.uppercased())
                        .font(FLFont.sans(9))
                        .tracking(1.4)
                        .foregroundStyle(Palette.faint)
                    Spacer(minLength: 4)
                    Text("\(index).")
                        .font(FLFont.serif(10))
                        .foregroundStyle(Palette.rose)
                }
                Text(product.name)
                    .font(FLFont.serif(12.5))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2, reservesSpace: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                HStack {
                    Button(action: onShop) {
                        Text("Shop")
                            .font(FLFont.sans(11.5))
                            .tracking(0.4)
                            .foregroundStyle(.white)
                            .frame(width: 62, height: 30)
                            .background(Palette.rose, in: Capsule())
                    }
                    .buttonStyle(PressableStyle(scale: 0.93))
                    Spacer(minLength: 4)
                    Text("$\(product.price)")
                        .font(FLFont.sans(10.6, .semibold))
                        .foregroundStyle(Palette.pebble)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 5)
        }
        .frame(width: 156)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 14, style: .continuous))
        .shadow(color: Palette.ink.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}
