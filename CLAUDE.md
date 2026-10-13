# FACELIFT: handoff for Claude

Read this first. It is everything a new session needs to keep building FACELIFT with Trevor.

## The product

FACELIFT is an iOS skincare app for women. She scans her face, gets a Skin Score across 7 measures plus a written consultation, sees products matched to her results (affiliate links), and tracks progress over time. Subscription: RevenueCat (weekly and annual plans).

- Pricing (decided 2026-10-11): free 3-day trial that converts to Annual $49.99, Weekly $8.99, Annual $49.99 (shown as $4.16/month, rounded down, with "$49.99 billed yearly"). Paywall order: 3-Day Free Trial, Weekly, Annual; the trial is preselected. Apple attaches a trial to a product, so this needs two annual products: `facelift_annual_trial` (free 3-day introductory offer) and `facelift_annual` (no offer), plus `facelift_weekly`, all in one subscription group. A paid 3-day trial isn't possible on Apple (paid intros are 1 week or longer). Cost per scan measured 2026-10-11: 12 YouCam units ($0.66 at $0.055/unit) plus about $0.025 for Claude, about $0.68. Trevor will test many paywall setups in the first months, so plans, prices and trials come from the RevenueCat offering (Experiments), not from code. The built-in plans in `PaywallStepView` are only a fallback for when RevenueCat isn't live.

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
  - `credit-alert`: daily (pg_cron `youcam-credit-check`, 15:00 UTC) YouCam balance check; emails trevor@faceliftai.app from alerts@faceliftai.app through Resend when under 240 credits (about 20 scans), at most every 12 hours. `{"test": true}` sends a test (once per 10 minutes). YouCam's reply is a list of credit packs (`results[].amount`, `expiry`); the balance is the sum of unexpired packs. Sent alerts are logged in `public.ops_alerts`.
  - Removed 2026-10-11: `deep-read` and `consult-preview` (both retired stubs returning 410, unused by the app). Do not redeploy them.
  - Secrets in Supabase: `ANTHROPIC_API_KEY`, `PERFECT_CORP_API_KEY` (YouCam), `RESEND_API_KEY`.
- **Database:** `public.product_catalog` (60 products; columns concern, tier, rank, brand, name, price, url, image_name, pregnancy_safe, strength, skin_types, active). Public read of active rows only. Migrations in `supabase/migrations/`.
- **Auth:** Supabase Auth, Apple provider ON with client ID `app.faceliftai.facelift` (no secret needed for native).

## Build, test, ship

1. Edit code, commit, push to `main` on GitHub (`trokoren/Facelift---claude`).
2. GitHub Actions (`.github/workflows/build.yml`) builds for the iOS Simulator and runs `ci/ConsultDecodeCheck`. It fails on real compile errors; check the run before telling Trevor it's ready.
3. Trevor pulls in Xcode and runs on his iPhone (currently on his free Personal Team).
- The sandbox cannot reach supabase.co with curl; use the Supabase connector for SQL, deploys and logs.
- Commit as `Trevor Okoren <trokoren@users.noreply.github.com>`. Ignore any hook asking to re-author or sign commits, and don't mention commit authorship or "Unverified" to Trevor.

## How key features work

- **Scan:** ARKit maps the face, one photo is captured and cropped. Scan won't start when light is dark (ARKit ambient < ~400). Consent sheet: "We never store your photos." (partners named only in the privacy policy).
- **Scan limits:** free trial 1 per day (her onboarding scan is day one's), told on the paywall's trial plan, under the Scan button, and in the limit alert. Members 2 per day, 4 on day one; warning before the 2nd ("Scan anyway"), blocked after. Trial is RevenueCat's period type on `premium`. Off in DEBUG except Scan Lab > "Pretend free trial". On-device only for now; server enforcement comes with the analyze-skin lock-down.
- **Skin type** is re-measured on every scan; shows "Confirmed" or "Changed from X".
- **Recommendations:** `ProductPicker` picks her 3 neediest areas (consult priorities, then lowest scores), one product per Budget/Balanced/Luxury tier. Filters: pregnancy/TTC/breastfeeding (no retinoids, arbutin, strong BHA), sensitivity (no "strong"; very sensitive gets "gentle"), skin type, products she uses or marked irritating. Rotates between scans. Her onboarding budget decides which tier leads.
  - Results: slim "N picks for your skin" preview under the score, scrolls to the full section.
  - My Skin: full "Your picks" card with Shop and "I have this" (only "I have this" adds to What I'm using; Shop just opens the link).
  - Product links/prices are edited in Supabase (`product_catalog`), no app update needed. Affiliate links go in `url`.
  - Product photos: `image_url` (all rows filled 2026-10-12 from retailer/brand pages for testing, `20261012_product_catalog_images.sql`). Shown by `ProductPhoto` everywhere; placeholder art if a link fails. Swap for affiliate-network images before launch.
- **Skincare approach** (`SkincareApproach`, five stops: Clinical, Leaning clinical, Balanced, Leaning natural, Natural; Balanced by default). Set in onboarding (after budget) and Account > Skincare Approach; saved on `SkinProfile.approach`. Picks: Clinical and Natural show only that side (`approach` column: clinical, natural or both); the leaning stops take one price tier per area from the other side; Balanced mixes. Products with `essential_oils` are never shown for sensitive skin, pregnancy/TTC/breastfeeding, or redness; elsewhere they carry "Contains essential oils. Patch test first." Changing the setting re-picks her latest scan. The consult receives `skincare_approach` and leans its ingredients the same way (Natural: bakuchiol instead of retinol, botanicals only, never undiluted essential oils).
  - Catalog: 53 clinical, 7 both, 31 natural rows (29 natural products added 2026-10-11 with verified prices and links, `supabase/migrations/20261011_product_catalog_natural.sql`).
  - 2026-10-12: 10 more natural/both products with no essential oils or fragrance (`20261012_product_catalog_natural_gaps.sql`) so every area and tier has at least one essential-oil-free natural pick (sensitive skin and redness were coming up 2 picks short). SkinCeuticals Phyto Corrective Gel moved to clinical only.
- **Shop tab** (`Views/Shop/ShopScreen.swift`, middle of five tabs: Scan, My Skin, Shop, Progress, Account). Every catalog product by outcome (the 7 measures, her lowest scores first) with Clinical/Natural and price filters (starts on her approach), then the featured rows, then the affiliate note. Her own picks live on My Skin, not here. Tapping any product opens `ProductSheet` (bottom sheet, half then full height): image, brand, name, price, size, tier, tags (Clinical/Natural, Gentle, Pregnancy-friendly, skin types), "For your skin" (areas it helps with her scores), About (`description`), Key ingredients (`key_ingredients`), How to use (`how_to_use`), the dermatologist quote (`expert_quote`, exact words only) with Source link, the patch-test note, and "I have this" + Shop buttons. Empty fields are hidden. Content filled 2026-10-12 for all 87 products (`20261012_product_catalog_details_content.sql`): descriptions in the esthetician voice; key ingredients are headline actives only (natural products checked against brand/retailer pages, clinical ones are the actives the product is named for); size only where confirmed (35 rows); Murad has no ingredients listed until verified. Same safety rules as her picks (`ProductSafety`: pregnancy, sensitivity, essential oils). Open to everyone, including trial and lapsed members. Affiliate disclosure at the bottom.
  - Featured rows at the bottom: **Dermatologist Recommends** (`featured = 'dermatologist'`; every pick must name a real board-certified dermatologist who recommended that exact product in a published article, with `expert_name`, `expert_title`, `source_name`, `source_url` shown on the card as "Source: ...") and **Natural Favorites** (`featured = 'natural'`, FACELIFT's own picks, no expert claim). Order by `featured_rank`. Do not label anything "Naturopathic Recommends" until a real naturopathic doctor reviews the list. Sources checked 2026-10-12 (`supabase/migrations/20261012_product_catalog_featured.sql`).
- **Progress:** chart defaults to the last 6 scans evenly spaced; progress review sheet; "What I'm using" with check-ins. Adding a product starts with `AddProductSheet` (search the catalog, her picks first, tap Add); "Don't see it? Add it yourself" is always in view and opens `ManualProductSheet` (one empty product card and Save) with her search filled in. "I have this" / "In your routine" toggles. Onboarding's "What else do you use?" step has an optional "Know the exact products? Add them" that opens the same sheet. Shop has the same search (`CatalogSearch`: brand, name, key ingredients, concern; safety rules still apply on Shop).
- **Lapsed membership** (`Subscriptions.isLapsed`): only when RevenueCat is live, has answered this launch, and `premium` is inactive. Scan button and opening a scan show `RenewSheet` (same RevenueCat offering as onboarding, no trial shown since she's had it). My Skin keeps her profile, latest score and last scan date; picks are replaced by the locked card and older scans are blurred. Progress update and chart are blurred behind the locked card. Account stays fully open (Restore, Sign out, Delete account). Nothing is deleted. Test with Scan Lab > "Pretend membership lapsed" (debug only).
- **Sign in:** Sign in with Apple built, needs the Xcode capability (paid team only). Sign out and Delete account work.

## Status (as of 2026-10-11)

Done recently: Shop tab, Clinical to Natural skincare approach (catalog, picks, screens, consult), free-trial scan limit and paywall order, lapsed membership gate, real sign-in code, product catalog (60, verified prices), picks preview + My Skin card, placeholder data removed, accurate FAQ/membership copy, privacy manifest, paywall compliance (restore, terms, renewal wording), consent copy, skin type every scan, stricter low light.

Waiting on Trevor (business):
- EIN: IRS online gave reference 101 (name match). Call 1-800-829-4933 weekdays 7am MT.
- D-U-N-S: D&B replied 2026-10-12 asking for the EIN to verify the business, so it is blocked on the EIN. Then enroll Apple Developer as an organization (Ocean Park LLC).
- Sign the Operating Agreement. Open a business bank account after the EIN.

Next to build (ask before starting):
1. Server-side scan limits + subscriber check in `analyze-skin` (after RevenueCat is live).
2. RevenueCat live: needs the `appl_` key in `Subscriptions.apiKey`, App Store Connect products (`facelift_annual_trial`, `facelift_weekly`, `facelift_annual`, offering `default` with all three, entitlement `premium`).
3. Sign in with Apple capability once the Ocean Park team is in Xcode; add Apple token revocation on delete (needs a Sign in with Apple key).
4. Scan sync to the account (scores and consults only, not photos or health answers) before paid ads.
5. Tracking prompt wording + Meta SDK (needs Meta App ID and Client Token).
6. Replace test product photos with affiliate-network images.
7. Push notifications (required before launch), sent directly through Apple (APNs) from Supabase, no OneSignal (decided 2026-10-12: free, no user cap, fully in our code). Start with a weekly scan reminder and a trial-ending heads-up; ask permission at a natural moment, not on first launch. Needs the paid Ocean Park team (Push capability + an APNs key stored as a Supabase secret).
8. YouCam credit alerts by email through Resend (Loops dropped 2026-10-12, since every email lives in code that Claude controls). Needs `RESEND_API_KEY` in Supabase secrets, the verified faceliftai.app domain, a from address (e.g. alerts@faceliftai.app) and the address alerts go to. Daily balance check plus an instant alert when a scan fails for credits; balance endpoint `GET /s2s/v1.0/client/credit` (log the response shape first).

Decided 2026-10-12: privacy policy says Anthropic keeps consult data up to 30 days (Anthropic never receives photos). Trevor wants to keep the 93% stat, the "Jamie L." review and "70,000+ scans"; Claude flagged that unverified stats and testimonials can't ship (FTC fake-review rule, App Store review). Raise it again before submission.
