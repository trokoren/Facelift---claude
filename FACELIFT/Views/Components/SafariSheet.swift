import SwiftUI
import SafariServices

/// In-app browser sheet (Safari view) so links like the privacy policy open without
/// leaving FACELIFT.
struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(red: 0.83, green: 0.63, blue: 0.63, alpha: 1)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

enum LegalLinks {
    /// Single source of truth for the privacy policy. Update the website, not the app.
    static let privacyPolicy = URL(string: "https://faceliftai.app/privacy")!
    static let terms = URL(string: "https://faceliftai.app/terms")!
}

/// Lets a SafariSheet be driven by an optional URL (`.sheet(item:)`).
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
