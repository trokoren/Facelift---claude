# FACELIFT

Native iOS app (SwiftUI, iOS 18+, iPhone only). Started from the Rork export in `trokoren/rork-facelift`; this repo is the source of truth from here on.

## Run it on your iPhone

1. Open `FACELIFT.xcodeproj` in Xcode.
2. Select the **FACELIFT** target → **Signing & Capabilities** → set **Team** to your Apple ID or developer account.
3. Plug in your iPhone, pick it as the run destination at the top of Xcode, press **Run** (⌘R).
4. First time only: on the iPhone, go to Settings → General → VPN & Device Management and trust your developer certificate. Also turn on Settings → Privacy & Security → Developer Mode if prompted.

## Project layout

- `FACELIFT/Models` data types (Scan, Recommendation, routes, tabs)
- `FACELIFT/ViewModels` app state (`AppStore`, `OnboardingStore`)
- `FACELIFT/Views` screens, grouped by tab plus Onboarding and shared Components
- `FACELIFT/Services` camera and (for now) sample data
- `FACELIFT/Utilities/Theme.swift` brand colors and fonts

## Status

UI and onboarding are built. Still placeholder: skin analysis (runs on sample data), accounts and storage (Supabase), purchases (RevenueCat), analytics (PostHog), affiliate links.

Bundle ID: `app.faceliftai.facelift`
