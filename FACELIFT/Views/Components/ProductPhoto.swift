import SwiftUI

/// A product's photo, looked up by name in the catalog (`image_url`, edited in Supabase).
/// Shows the photo whole on white. Until it loads, or if the link fails, shows the placeholder art.
struct ProductPhoto: View {
    /// The product's full name ("Brand Name"), as used across the app.
    let name: String
    let fallback: String
    var inset: CGFloat = 8

    private var url: URL? {
        ProductCatalog.shared.products
            .first { $0.fullName == name && $0.imageURL != nil }?
            .imageURL.flatMap(URL.init(string:))
    }

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        Color.white.overlay {
                            image.resizable().aspectRatio(contentMode: .fit).padding(inset)
                        }
                    case .failure:
                        placeholder
                    default:
                        Color(hex: 0xF1EEEA)
                    }
                }
            } else {
                placeholder
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(fallback).resizable().aspectRatio(contentMode: .fill)
    }
}
