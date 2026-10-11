# FACELIFT: handoff for Claude

Read this first. It is everything a new session needs to keep building FACELIFT with Trevor.

## The product

FACELIFT is an iOS skincare app for women. She scans her face, gets a Skin Score across 7 measures plus a written consultation, sees products matched to her results (affiliate links), and tracks progress over time. Subscription: RevenueCat (weekly and annual plans).

- Pricing (decided 2026-10-11): Weekly $8.99, Annual $49.99 with a free 3-day trial (introductory offer on `facelift_annual` in App Store Connect). Trevor will test many paywall setups in the first months, so plans, prices and trials come from the RevenueCat offering (Experiments), not from code. The built-in plans in `PaywallStepView` are only a fallback for when RevenueCat isn't live.

- Owner: Trevor Okoren, solo founder. Publisher (pending): **Ocean Park LLC**, a Colorado LLC formed 10/08/2026 (Colorado ID 20268253892). The app will ship under the Ocean Park Apple Developer account, NOT Faver, Inc.
- Domain faceliftai.app. Email trevor@faceliftai.app (trevor@oceanpark.la planned). Instagram @faceliftai.
- Bundle ID: `app.faceliftai.facelift` (register it only in the Ocean Park developer account).

## How Trevor wants to work

- **Talk before building** when he asks a question or brainstorms. Build when he says go.
- **Never remove a feature he expects to be built** (e.g. sign-in) without asking. Ask first.
- One clear change per push; say plainly what you could not verify on a device.
- Short, direct answers. He is a founder, not an engineer; avoid jargon.
- **Never use em dashes** in anything you write (copy, messages, docs).
- **Never use the word "AI" in in-app copy.**
- Server keys never go in chat or the repo, only in Supabase secrets. Public keys (Supabase anon key, RevenueCat `appl_` key, Meta App ID/Client Token) may live in the app.
- Photos are never stored by FACELIFT.

## Brand

- Fonts: Cormorant Garamond (headlines, `FLFont.serif*`), Plus Jakarta Sans (body, `FLFont.sans`).
- Colors: background #FAF8F5, accent blush rose #D4A0A0, text #1C1210. All tokens in `FACELIFT/Utilities/Theme.swift` (`Palette`).
- Tone of consult copy: a seasoned, polished esthetician. Warm, never chatty, no slang, no exclamation points.

## Stack and layout

- **App:** native SwiftUI, iOS 18, Xcode project `FACELIFT.xcodeproj` with file-system synced groups (new files in `FACELIFT/` are included automatically). Default MainActor, Swift 5 mode.
  - `FACELIFT/Views/` by tab: `Scan`, `MySkin`, `Analysis` (results/consult), `Progress`, `Account`, `Onboarding` (25-step flow + paywall), `Components`.
  - `FACELIFT/ViewModels/AppStore.swift`: main app state (scans, products, profile, navigation).
  - `FACELIFT/Services/`: `Backend.swift` (Supabase URL + anon key), `SkinAnalysisService`, `FaceScanController` (ARKit face tracking, light check), `Subscriptions` (RevenueCat), `Account` (Sign in with Apple via Supabase Auth), `ProductCatalog` (catalog + `ProductPicker`), `ProgressReviewService`, `LocalFile`/`Keychain`/`ScanArchive` (on-device storage).
  - Packages: RevenueCat `purchases-ios-spm`.
- **Server:** Supabase project `mrpdyksjydzxujaniflu`. Edge functions in `supabase/functions/` (deploy with full file content, `verify_jwt` true):
  - `analyze-skin`: photo to Perfect Corp YouCam (7 measures + skin type) then Claude (`claude-sonnet-5`) writes the consult. Retries the consult once; if it still fails, returns scores only.
  - `progress-review`: numbers only, writes a short progress review on cadence (first, every 5 scans, meaningful change, monthly).
  - `delete-account`: deletes the signed-in user (App Store requirement).
  - Removed 2026-10-11: `deep-read` and `consult-preview` (both retired stubs returning 410, unused by the app). Do not redeploy them.
  - Secrets in Supabase: `ANTHROPIC_API_KEY`, the YouCam key.
- **Database:** `public.product_catalog` (60 products; columns concern, tier, rank, brand, name, price, url, image_name, pregnancy_safe, strength, skin_types, active). Public read of active rows only. Migrations in `supabase/migrations/`.
- **Auth:** Supabase Auth, Apple provider ON with client ID `app.faceliftai.facelift` (no secret needed for native).

## Build, test, ship

1. Edit code, commit, push to `main` on GitHub (`trokoren/Facelift---claude`).
2. GitHub Actions (`.github/workflows/build.yml`) builds for the iOS Simulator and runs `ci/ConsultDecodeCheck`. It fails on real compile errors; check the run before telling Trevor it's ready.
3. Trevor pulls in Xcode and runs on his iPhone (currently on his free Personal Team).
- The sandbox cannot reach supabase.co with curl; use the Supabase connector for SQL, deploys and logs.
- Commit as `Trevor Okoren <trokoren@users.noreply.github.com>`.

## How key features work

- **Scan:** ARKit maps the face, one photo is captured and cropped. Scan won't start when light is dark (ARKit ambient < ~400). Consent sheet: "We never store your photos." (partners named only in the privacy policy).
- **Scan limits:** 2 per day, 4 on day one; warning before the 2nd ("Scan anyway"), blocked after. Off in DEBUG. On-device only for now.
- **Skin type** is re-measured on every scan; shows "Confirmed" or "Changed from X".
- **Recommendations:** `ProductPicker` picks her 3 neediest areas (consult priorities, then lowest scores), one product per Budget/Balanced/Luxury tier. Filters: pregnancy/TTC/breastfeeding (no retinoids, arbutin, strong BHA), sensitivity (no "strong"; very sensitive gets "gentle"), skin type, products she uses or marked irritating. Rotates between scans. Her onboarding budget decides which tier leads.
  - Results: slim "N picks for your skin" preview under the score, scrolls to the full section.
  - My Skin: full "Your picks" card with Shop and "I have this" (only "I have this" adds to What I'm using; Shop just opens the link).
  - Product links/prices are edited in Supabase (`product_catalog`), no app update needed. Affiliate links go in `url`.
- **Progress:** chart defaults to the last 6 scans evenly spaced; progress review sheet; "What I'm using" with check-ins.
- **Sign in:** Sign in with Apple built, needs the Xcode capability (paid team only). Sign out and Delete account work.

## Status (as of 2026-10-11)

Done recently: real sign-in code, product catalog (60, verified prices), picks preview + My Skin card, placeholder data removed, accurate FAQ/membership copy, privacy manifest, paywall compliance (restore, terms, renewal wording), consent copy, skin type every scan, stricter low light.

Waiting on Trevor (business):
- EIN: IRS online gave reference 101 (name match). Call 1-800-829-4933 weekdays 7am MT.
- D-U-N-S: requested via Apple's lookup with the Highlands Ranch address (~5 business days). Then enroll Apple Developer as an organization (Ocean Park LLC).
- Sign the Operating Agreement. Open a business bank account after the EIN.

Next to build (ask before starting):
1. Lapsed membership: gate with the paywall when `premium` is inactive (decide whether past scans stay viewable).
2. Server-side scan limits + subscriber check in `analyze-skin` (after RevenueCat is live).
3. RevenueCat live: needs the `appl_` key in `Subscriptions.apiKey`, App Store Connect products (`facelift_annual`, `facelift_weekly`, offering `default`, entitlement `premium`).
4. Sign in with Apple capability once the Ocean Park team is in Xcode; add Apple token revocation on delete (needs a Sign in with Apple key).
5. Scan sync to the account (scores and consults only, not photos or health answers) before paid ads.
6. Tracking prompt wording + Meta SDK (needs Meta App ID and Client Token).
7. Real product photos (from affiliate networks).

Open questions Trevor still owns: the 93% stat, the "Jamie L." review, and "70,000+ scans" claims; Anthropic data retention (zero retention or say 30 days in the privacy policy).
