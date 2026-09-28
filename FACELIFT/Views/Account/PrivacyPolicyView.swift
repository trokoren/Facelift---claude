import SwiftUI

/// FACELIFT's privacy policy, in plain language. Reached from Account → Privacy & Data and
/// from the scan consent card.
///
/// Before launch: confirm the analysis vendor's terms match "analyzed then deleted, never
/// stored or used for training", keep the vendor list current, and have a lawyer review (biometric privacy laws such as Illinois BIPA,
/// Texas and Washington apply to face scans). The same text should be published at
/// faceliftai.app/privacy for the App Store listing.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Section: Identifiable {
        let title: String
        var paragraphs: [String] = []
        var bullets: [String] = []
        var id: String { title }
    }

    private let lastUpdated = "September 27, 2026"

    private let sections: [Section] = [
        Section(
            title: "The short version",
            bullets: [
                "Your face photos are used only to analyze your skin, then deleted right away.",
                "We never store your photos, sell them, or use them to train any technology.",
                "The 3D map of your face that guides the scan never leaves your phone.",
                "We keep your results, like scores and recommendations, so you can track your progress.",
                "We never sell your personal information.",
                "You can delete your scan history or your whole account at any time."
            ]
        ),
        Section(
            title: "Your photos",
            paragraphs: [
                "During a scan, FACELIFT takes a few photos of your face from different angles. These photos are sent over an encrypted connection to our skin analysis partner, analyzed, and then deleted as soon as the analysis is complete.",
                "We do not keep copies of your photos, and our analysis partner is contractually required not to keep them either. Your photos are never sold, shared for advertising, or used to train artificial intelligence or any other technology."
            ]
        ),
        Section(
            title: "Your face geometry",
            paragraphs: [
                "To guide the scan, FACELIFT uses your iPhone's Face ID camera to map the shape and position of your face in real time. This face map is processed only on your phone, is used only to guide the scan, is never saved, and never leaves your device.",
                "We do not collect, store, or share biometric identifiers, such as face geometry used to identify you, and we never use your face to recognize or identify you."
            ]
        ),
        Section(
            title: "What we keep",
            bullets: [
                "Your scan results: skin scores, concerns and recommendations.",
                "What you tell us during setup, such as your age range, skin type, skin concerns, sensitivity, budget and goals.",
                "Health details you choose to share, such as pregnancy or menopause, used only to keep your recommendations safe. These are optional.",
                "Your city, used only to show your local climate. We don't track your location.",
                "Products you add to your routine or shop from your recommendations.",
                "Your account details, such as your email address, and your subscription status.",
                "How you use the app, such as which screens you visit, to help us improve FACELIFT."
            ]
        ),
        Section(
            title: "How we use it",
            bullets: [
                "To analyze your skin and show your results.",
                "To recommend products that fit your skin, budget and needs.",
                "To track your progress over time.",
                "To send the reminders you've turned on.",
                "To run, fix and improve the app.",
                "To manage your subscription."
            ]
        ),
        Section(
            title: "Who we share it with",
            paragraphs: [
                "We never sell your personal information. We share only what's needed with the service providers that help run FACELIFT, and they may use it only to provide their service to us:"
            ],
            bullets: [
                "Skin analysis: Perfect Corp. analyzes your photos and deletes them right away.",
                "Secure hosting: Supabase stores your account and results.",
                "Subscriptions: Apple and RevenueCat process and manage your subscription. We never see your payment details.",
                "App analytics: PostHog helps us understand how the app is used.",
                "Climate data: your city's location is sent to NASA POWER and Open-Meteo to look up local averages."
            ]
        ),
        Section(
            title: "Shopping links",
            paragraphs: [
                "When you tap to shop a product, you leave FACELIFT for the retailer's website. The retailer can see that you came from FACELIFT, and we may earn a commission if you buy. We don't share your skin data, photos or answers with brands or retailers. Their own privacy policies apply once you're on their site."
            ]
        ),
        Section(
            title: "Tracking",
            paragraphs: [
                "If you allow tracking when asked, we may use limited app activity to measure our marketing. If you don't, we won't. You can change this anytime in your iPhone's Settings. Either way, your photos, skin results and health details are never used for advertising."
            ]
        ),
        Section(
            title: "Your choices",
            bullets: [
                "Delete your scan history in Account → Privacy & Data.",
                "Delete your account and all your data by emailing us at trevor@faceliftai.app. We'll confirm within 30 days.",
                "Turn reminders, camera access or tracking on or off anytime in your iPhone's Settings.",
                "Ask us for a copy of your data, or to correct it, by emailing us."
            ]
        ),
        Section(
            title: "How long we keep it",
            paragraphs: [
                "Photos are deleted immediately after analysis. Your results and answers are kept until you delete them or your account. When you delete your account, we delete your data within 30 days, except anything we're required by law to keep."
            ]
        ),
        Section(
            title: "Keeping it safe",
            paragraphs: [
                "Your data is encrypted in transit and stored with providers that use industry-standard security. No system is perfect, but we work hard to protect your information and will tell you promptly if it is ever compromised."
            ]
        ),
        Section(
            title: "Children",
            paragraphs: [
                "FACELIFT is not intended for anyone under 18. We don't knowingly collect information from children. If you believe a child has used FACELIFT, email us and we'll delete their data."
            ]
        ),
        Section(
            title: "Changes",
            paragraphs: [
                "If we make meaningful changes to this policy, we'll let you know in the app before they take effect."
            ]
        ),
        Section(
            title: "Contact us",
            paragraphs: [
                "Questions or requests: trevor@faceliftai.app",
                "Facelift App, LLC, 2214 Weatherstone Circle, Highlands Ranch, CO 80126"
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(subtitle: "Privacy Policy.", onBack: { dismiss() })

                Text("Last updated \(lastUpdated)")
                    .font(FLFont.sans(12))
                    .foregroundStyle(Palette.stone)
                    .padding(.horizontal, 28)
                    .padding(.top, 18)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(FLFont.serif(24))
                            .foregroundStyle(Palette.ink)

                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(FLFont.sans(14.5))
                                .foregroundStyle(Palette.body)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(section.bullets, id: \.self) { bullet in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Circle()
                                    .fill(Palette.rose)
                                    .frame(width: 5, height: 5)
                                    .offset(y: -2)
                                Text(bullet)
                                    .font(FLFont.sans(14.5))
                                    .foregroundStyle(Palette.body)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 26)
                }
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Palette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
