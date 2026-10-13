import SwiftUI

/// Rounded search box used on Shop and in Add a product.
struct SearchField: View {
    @Binding var text: String
    var prompt: String = "Search"
    var focused: FocusState<Bool>.Binding? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Palette.stone)
            field
                .font(FLFont.sans(14))
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.faint)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .frame(height: 44)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().stroke(Palette.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private var field: some View {
        if let focused {
            TextField(prompt, text: $text).focused(focused)
        } else {
            TextField(prompt, text: $text)
        }
    }
}

/// One product in a search list: photo, brand, name, price. Trailing content is up to the caller.
struct ProductSearchRow<Trailing: View>: View {
    let product: CatalogProduct
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 14) {
            Color(hex: 0xF1EEEA)
                .frame(width: 56, height: 56)
                .overlay {
                    ProductPhoto(name: product.fullName, fallback: product.imageName ?? "serum_bottle_dropper", inset: 4)
                }
                .clipShape(.rect(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(product.brand.uppercased())
                    .font(FLFont.sans(9.5, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Palette.stone)
                    .lineLimit(1)
                Text(product.name)
                    .font(FLFont.serif(15))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("$\(product.price) · \(product.tier)")
                    .font(FLFont.sans(11.5))
                    .foregroundStyle(Palette.pebble)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
