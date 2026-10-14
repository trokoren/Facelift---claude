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
  - Packages: RevenueCat `purchases-ios-spm` (RevenueCat + RevenueCatUI), Sentry `sentry-cocoa` (crash reports only, `Services/CrashReporting.swift`, org ocean-park; no screenshots, view snapshots, replays or personal details).
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
- **Scan limits:** free trial 1 per day (her onboarding scan is day one's), told on the paywall's trial plan, under the Scan button, and in the limit alert. Members 2 per day, 4 on day one; warning before the 2nd ("Scan anyway"), blocked after. Trial is RevenueCat's period type on `facelift_pro`. Off in DEBUG except Scan Lab > "Pretend free trial". On-device only for now; server enforcement comes with the analyze-skin lock-down.
- **Local climate** (onboarding "Where do you live?"): built into the app, no weather service. `Resources/climate.json` holds 2,537 cities (US over 30,000 people, world over 500,000): typical midday UV (yearly average and peak month), yearly humidity (NASA POWER), and US air quality (EPA median AQI for the metro, 2022 to 2024; nil outside the US, where the pollution card is hidden). Her city gets the nearest city in the table (within 400 km). NASA's UV is a 24-hour average, so the build converts it to midday UV using the sun's angle per month. Rebuild with the "Build climate data" GitHub workflow (`tools/climate/build_climate.py`). Credit line is on Account > Privacy & Data (GeoNames CC BY 4.0).
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
- **Lapsed membership** (`Subscriptions.isLapsed`): only when RevenueCat is live, has answered this launch, and `facelift_pro` is inactive. Scan button and opening a scan show `RenewSheet` (same RevenueCat offering as onboarding, no trial shown since she's had it). My Skin keeps her profile, latest score and last scan date; picks are replaced by the locked card and older scans are blurred. Progress update and chart are blurred behind the locked card. Account stays fully open (Restore, Sign out, Delete account). Nothing is deleted. Test with Scan Lab > "Pretend membership lapsed" (debug only).
- **Reminders** (`Services/Reminders.swift`, scheduled on the phone, no server): weekly scan reminder on the day and time she picked in onboarding (`ReminderTime`, Sun/Mon/Wed/Sat, morning 9am or evening 7pm, default Sunday 9am), at least 5 days after her latest scan (moves forward each scan, follows the Account "Scan Reminders" switch, saved in UserDefaults); and a "Your free trial ends tomorrow" heads-up 24 hours before `Subscriptions.trialEndDate` (RevenueCat trial expiration, only when it will renew). Permission is asked on the onboarding notifications step (simplified 2026-10-13: "We will remind you to scan every week.", one preview of the weekly reminder at her chosen time, day/time chips, "Turn on reminders" / "Not now"; Trevor wants it before the paywall for commitment; asking after the paywall is logged as a test); turning the switch on asks if never asked, or opens Settings if denied. Server push (APNs) is still to build for messages sent by hand.
- **Sign in:** Sign in with Apple built, needs the Xcode capability (paid team only). Sign out and Delete account work.

Launch checklist lives in the Facelift project as `claude/FACELIFT launch checklist.md`. Keep it updated as items finish, and delete it once every item is done (Trevor's request).

## Status (as of 2026-10-11)

Done recently: Shop tab, Clinical to Natural skincare approach (catalog, picks, screens, consult), free-trial scan limit and paywall order, lapsed membership gate, real sign-in code, product catalog (60, verified prices), picks preview + My Skin card, placeholder data removed, accurate FAQ/membership copy, privacy manifest, paywall compliance (restore, terms, renewal wording), consent copy, skin type every scan, stricter low light.

Waiting on Trevor (business):
- EIN: IRS online gave reference 101 (name match). Call 1-800-829-4933 weekdays 7am MT.
- D-U-N-S: D&B replied 2026-10-12 asking for the EIN to verify the business, so it is blocked on the EIN. Then enroll Apple Developer as an organization (Ocean Park LLC).
- Sign the Operating Agreement. Open a business bank account after the EIN.

Next to build (ask before starting):
1. Server-side scan limits + subscriber check in `analyze-skin` (after RevenueCat is live).
2. RevenueCat live: test builds use the Test Store key (`test_...`, DEBUG only, set 2026-10-13). Release needs the `appl_` key in `Subscriptions.apiKey`, App Store Connect products (`facelift_annual_trial`, `facelift_weekly`, `facelift_annual`, offering `default` with all three, entitlement `facelift_pro`). Plans are read by billing period (`isYearly`/`isWeekly`), so package names in RevenueCat don't matter.
3. Sign in with Apple capability once the Ocean Park team is in Xcode; add Apple token revocation on delete (needs a Sign in with Apple key).
4. Scan sync: BUILT 2026-10-13 (`Services/ScanSync.swift`, table `public.member_scans` from `supabase/migrations/20261013_member_scans.sql`, each member reads/writes only her rows, rows deleted with her account). Phone is the main copy; changes upload in the background when signed in; `AppStore.syncScans()` restores at launch and after sign-in (union by scan id). Can't be tested on a device until Sign in with Apple works (paid Ocean Park team). The migration must be applied in Supabase (two connector attempts were cancelled at approval).
5. Tracking prompt wording + Meta SDK (needs Meta App ID and Client Token).
6. Replace test product photos with affiliate-network images.
7. Server push notifications (scheduled scan and trial reminders already run on the phone), sent directly through Apple (APNs) from Supabase, no OneSignal (decided 2026-10-12: free, no user cap, fully in our code). Start with a weekly scan reminder and a trial-ending heads-up; ask permission at a natural moment, not on first launch. Needs the paid Ocean Park team (Push capability + an APNs key stored as a Supabase secret).
8. Customer Center: BUILT 2026-10-13. Account > Membership ("Manage") opens RevenueCat's Customer Center (`RevenueCatUI` product of purchases-ios-spm, `.presentCustomerCenter`), shown only when a RevenueCat key is set; refreshes membership when closed. Its screens, cancel survey and offers are set in the RevenueCat dashboard (Customer Center, on with defaults 2026-10-13). After launch: create Apple promotional offers and map them in RevenueCat Lifecycle > Retention (Rico's suggestion: 50% off 1 to 3 months for "Too expensive"). RevenueCat's App Store app for bundle `app.faceliftai.facelift` waits on the Apple account; App Store product IDs `facelift_weekly`, `facelift_annual`, `facelift_annual_trial`. Test Store has `weekly`, `yearly`, `yearly_trial` in offering `default` (packages `$rc_weekly`, `$rc_annual`, `annual_trial`).
9. RevenueCat to Mixpanel connection once RevenueCat is live, then add renewals, trial conversions, cancellations and refunds to the Revenue board.
10. Monthly product check-in: SET UP 2026-10-13 as scheduled task `trig_01ChuugpZYpPUdX36ftMdmdJ` (1st of each month, 8:56am Denver, push + email). Once a month it that checks every `product_catalog` row is still sold (link works, price current, not discontinued or reformulated) and suggests new top products per area and tier, with sources. It reports to Trevor; nothing in the catalog changes until he approves. Never recommend a product that isn't on the market.
11. YouCam credit alerts by email through Resend (Loops dropped 2026-10-12, since every email lives in code that Claude controls). Needs `RESEND_API_KEY` in Supabase secrets, the verified faceliftai.app domain, a from address (e.g. alerts@faceliftai.app) and the address alerts go to. Daily balance check plus an instant alert when a scan fails for credits; balance endpoint `GET /s2s/v1.0/client/credit` (log the response shape first).

Paywall testing (decided 2026-10-13): no Superwall. Prices/plans/trials through RevenueCat Experiments; design variants are built in the app and picked by offering metadata.

Analytics (decided 2026-10-13): Mixpanel for analytics, screen tests and session replay (Trevor finds its reports easier than PostHog's); Sentry for crash reports; RevenueCat Experiments for paywall and price tests. Session replay must fully mask the camera, scan and health-answer screens. Sentry is wired in (DSN in `CrashReporting.swift`). Mixpanel is wired in (`Services/Analytics.swift`, packages `mixpanel-swift` 7.x and `mixpanel-ios-session-replay-package` 2.x): event names live in `Analytics.Event` (object_verb, snake_case): onboarding_step_viewed, notifications_answered/skipped, scan_completed/failed, paywall_viewed (renew sheet; onboarding paywall too, source onboarding/renew), paywall_plan_selected, purchase_started/completed/cancelled/failed (plan, price, source)/restored, onboarding_started/completed, tab_viewed, scan_started, product_viewed, product_shop_tapped (source: picks/shop/product_sheet), product_added_to/removed_from_routine, approach_changed, reminders_toggled. Identify with the Supabase account id on sign in (never email), reset on sign out. Super property `environment` (debug/production). Mixpanel project 4073134 (org Ocean Park), Startup plan applied 2026-10-13. Boards: Daily Exec 11583491, Onboarding 11583540, Paywall 11583546, In-App 11583549, Revenue 11583552 (all unfiltered until launch; then filter environment = production). Session replay: default masking (all text and images), Wi-Fi only, paused while `CircleScanView` (camera) is open.

Parked (Trevor, 2026-10-12): a Monday "CEO Scorecard" email through Resend (scans, failures, YouCam spend, what shipped, what's next). Plan if revived: anonymous `scan_events` table written by analyze-skin, daily `credit_snapshots` from credit-alert, an `ops_outbox` table that send-report emails, and a weekly scheduled task that writes the report.

Decided 2026-10-12: privacy policy says Anthropic keeps consult data up to 30 days (Anthropic never receives photos). Trevor wants to keep the 93% stat, the "Jamie L." review and "70,000+ scans" (plus "70,000+ clinical references" on the loading screen); Claude flagged that unverified stats and testimonials can't ship (FTC fake-review rule, App Store review). 2026-10-13: Trevor is waiting on sources; do NOT bring the claims up again until he does.
