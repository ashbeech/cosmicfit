# Cosmic Fit iOS Surface Map — Android Port Prep (Pass 1)

> Inventory & classification only. No Android recommendations. Layers: **A** = product/domain (1:1 behaviour parity required), **B** = iOS shell (remap), **C** = shared backend (likely reusable), **D** = dev-only/non-shipped.
> Repo root: `/Users/ash/dev/mobile_apps/cosmicfit`. App source: `Cosmic Fit/` (157 Swift files). Branch at time of mapping: `refactor/style-guide` (SG-4 work in flight, see §H/§I).
> Method: read `AGENTS.md` + root `README.md` + `docs/README.md`, then walked source with three parallel deep passes (shell/screens; components/platform APIs; services/contracts/backend). Source was preferred over docs wherever they conflict.

## README deltas (source beats docs — the planner must not trust README §3 verbatim)

Root `README.md` (audited June 2026) is the canonical handoff but is stale in these verified places:

- `Core/Services/FeedbackService.swift` exists (not in README): authenticated POST to edge function `send-feedback` with `{message, metadata:{displayDate, deviceModel, iosVersion, appVersion}}`; requires valid session; handles 429.
- Supabase migrations run `001`–`011` (README says 001–009): adds `010_promo_user_scoped_access.sql`, `011_unique_slot_numbers.sql`.
- Edge functions: 9 + `_shared`/`_tests` (README lists 8; `send-feedback` missing).
- VCs not in README §3: `LegalDocumentViewController`, `PrivacyPolicyViewController`, `TermsOfUseViewController` (legal copy is **Swift-embedded** in `Cosmic Fit/Legal/*Content.swift`, not remote/webview).
- Views not in README §3: `CosmicFitLoaderView`, `CosmicFitLoadingOverlay`, `CosmicFitLogoMarkView`, `MotionSheenView`, `TornPaperEdgeView`, `CosmicNavigationArrow`.
- Services/utilities not in README §3: `ClientInstallIdentity.swift`, `CompAccessStorage.swift`, `FeedbackService.swift`, `DailyFitSkyAnchor.swift`.
- README calls `AuthGateViewController` "legacy" — **wrong**: it is live with 4 call sites (see §C).
- Bundle symlinks now also include `ranked_domain_tables.json` and `style_guide_rules.json` (SG-4).
- **IAP amended after the original mapping (commit `08a3afe`, 2026-07-12):** annual plan now carries a **7-day free trial** (StoreKit 2 introductory offer). See the "Monetization / trial contract" subsection in §F and the dedicated handoff `docs/handoff/IAP_TRIAL_HANDOFF_2026-07-12.md` — note `docs/README.md` classes `docs/handoff/` as historical, but this one file is **current** and written specifically for the Android conversion; treat it as a first-class parity source. The same commit also committed the SG-4 validator/tests/rules (previously untracked).
- Build system: `project.pbxproj` uses Xcode 16 **`fileSystemSynchronizedGroups`** with no exception sets — every `.swift` under `Cosmic Fit/` auto-compiles into the app target and everything under `Resources/` auto-bundles, including untracked files. "Is it in the target?" is answered by the filesystem, not the pbxproj.

---

## Section A — Executive inventory

| Count | What |
|---|---|
| **22** VC files | ~19 in the shipped nav graph; 1 confirmed dead (`CardPresentationController`), 2 debug/placeholder-only (`NatalChartViewController`, `InterpretationViewController`) |
| **21** custom view files | 17–18 live (`UI/Views/` + `Palette/`); dead: `StarView`, `LocationResultTableViewCell`, `ColourCell` (as a cell — hosts load-bearing `UIColor(hex:)`) |
| **~12** platform integrations | StoreKit 2, CoreLocation, MapKit, Keychain, CryptoKit, CoreMotion, CoreImage, MessageUI, Supabase Swift SDK, Open-Meteo (raw URLSession), CSwissEphemeris (SPM C module), custom URL scheme |
| **3 + 2 + ~12** persistence stores | 3 Documents JSON stores (profile, blueprint, frozen Daily Fit dir), 2 app Keychain items (+ SDK-managed session), ~12 UserDefaults key families (5 recency trackers, reveal flags, caches, launch health, flags) |
| **9** edge functions called | send-otp, verify-otp, signup-with-profile, delete-account, redeem-code, check-comp-access, revoke-comp-access, send-feedback (+ `app-store-notifications` server-only, 0 client refs) |
| **2** Postgres tables used by client | `profiles`, `user_blueprints` (`user_preferences` touched only by a dead method) |

**Shell vs engine.** The "engine" is a large, deterministic, UI-free Swift core: chart math (`Core/Calculations/` + VSOP87/Swiss Ephemeris data), the Style Guide composer (`BlueprintTokenGenerator` → `BlueprintComposer` + `ColourEngineV4` → `CosmicBlueprint`), and the Sky Forward Daily Fit pipeline (`DailyEnergyEngine` → `DailyFitPipeline` → `DailyNarrativeSelector` → `BlueprintLensEngine` → `DailyFitPayload`), all keyed by deterministic seeds (SHA256 of profileHash+day) and UserDefaults-persisted recency state namespaced by engine id. It compiles into a macOS inspector unchanged, which proves it has no UIKit dependency (except `ColourMath`/`PaletteGridViewModel`, which are Foundation-only anyway). The "shell" is a programmatic-UIKit, AppDelegate-only (no SceneDelegate), single-window, portrait-only, 2-tab app whose signature surfaces are heavy custom drawing/animation: tarot 3D flip with motion-driven holographic sheen, torn-paper paywalls, rune-scroll backgrounds, a 14-axis essence radar, a morphing brand loader, and an SVG-path logo reveal. Auth (email OTP), sync, StoreKit entitlements, and promo/comp grants glue the two together via NotificationCenter.

---

## Section B — Feature × layer matrix

| Feature | User-visible? | Primary files | Layer | iOS-only APIs | Parity risk | Notes |
|---|---|---|---|---|---|---|
| Launch routing (5 states) | Yes | `App/AppDelegate.swift` (`performLaunchRouting` L86), `AnimatedLaunchScreenViewController` | B | UIWindow, no SceneDelegate | Med | Crash-loop guard wipes blueprint+frozen caches after 3 rapid failures (L114–132); launch VC is always root, real root cross-dissolves in |
| Animated launch/intro | Yes | `AnimatedLaunchScreenViewController`, `AnimatedWelcomeIntroViewController`, `CosmicFitLogoMarkView`, `ScrollingRunesBackgroundView` | B | CAShapeLayer, CAGradientLayer, embedded SVG parser | Med | First launch 3.9s slow reveal, later 0.605s; UserDefaults `hasShownAnimatedLaunchIntro` |
| Auth / OTP | Yes | `CosmicFitAuthService`, `AuthGateViewController`, `OTPVerifyViewController`, `AuthDeepLinkRouter` | A (flow) + B (UI) + C | Keychain (SDK session), URL scheme | Med | Edge functions send-otp/verify-otp; `cosmicfit://login?email=&code=` deep link auto-fills OTP; fresh-install signOut clears stale Keychain session; user-switch triggers local purge |
| Onboarding (birth data + location) | Yes | `OnboardingFormViewController` (4 pages; 3 in postAuth mode), `LocationAutocompleteView` | A (data contract) + B (UI) | **MapKit** MKLocalSearchCompleter/MKLocalSearch, CLGeocoder (timezone) | **High** | Birth place resolution → lat/lon/timezone feeds chart determinism; page 4 = email signup (`signup-with-profile`); "unknown birth time" flag; `performMysticalTransitionToMainApp` 4.8s dissolve + chrome intro |
| Daily Fit (reveal + payload surfaces) | Yes | `DailyFitViewController` (~228 KB god-VC), `CosmicFitTabBarController` (orchestration), `DailyFitFrozenPayloadStorage` | A (payload/freeze/reveal logic) + B (rendering) | CATransform3D, CoreMotion, CoreImage, CAKeyframe | **High** | Freeze-before-reveal invariant: payload written to disk **before** reveal flag set; per-day per-engine reveal flags; first-ever revealed day stays free; today/tomorrow toggle; feedback section entitled-only |
| Style Guide hub + detail | Yes | `StyleGuideViewController` (8-tile grid), `StyleGuideDetailViewController`, `ColourPaletteView`, `PaletteGridViewModel` | A (content/`CosmicBlueprint`) + B (UI) | TornPaperEdgeView (Core Graphics) | Med | Sections: Blueprint, Palette, Textures, Occasions, Hardware, Code, Accessory, Pattern; gated tear at ~0.48 of content when un-entitled; guest auth-nudge banner |
| Natal Chart wheel | Debug only | `NatalChartViewController`, `ChartWheelView` | D (currently) | Core Graphics | Low | **Not in the shipping nav graph** — only reachable via debug menu paths; confirm product intent before porting (§I) |
| Profile / edit | Yes | `ProfileViewController` (64 KB) | A (flows) + B | — | Med | Edit name/birth/location → re-generates everything; sub status; promo redeem; restore; sign in/out; delete profile vs delete account; DEBUG engine picker |
| Menu / FAQ / Legal | Yes | `MenuViewController`, `FAQViewController`, `LegalDocumentViewController` + `Legal/*Content.swift` | B | MessageUI (mail), blur overlay | Low | Legal + FAQ are native-rendered Swift string models; menu → Account/FAQ/Help(mail)/TikTok/Instagram |
| Purchases / entitlements / promo | Yes | `StoreKitManager`, `EntitlementManager`, `PromoCodeService`, `CompAccessStorage`, `PurchaseViewController`, `StyleCalendarUnlockViewController` | A (entitlement logic) + B (StoreKit) + C | **StoreKit 2** (`Product`, `Transaction.currentEntitlements`, `AppStore.sync`, `SubscriptionInfo.isEligibleForIntroOffer`) | **High** | Product IDs hard-coded: `com.cosmicfit.full.monthly` / `com.cosmicfit.full.annual`; **annual has a 7-day free trial** (intro offer; eligibility store-tracked per subscription group, **fails closed** to non-trial UI); `hasFullAccess = StoreKit ∨ comp-grant` — trial transactions count as active, no trial special-casing in gating; no server receipt validation in client; comp grants keyed by Keychain install id. Full contract in §F "Monetization / trial contract" + `docs/handoff/IAP_TRIAL_HANDOFF_2026-07-12.md` |
| Sync (profile + blueprint) | Indirect | `SupabaseSyncService` | A (contract) + C | — | Med | Upserts to `profiles` / `user_blueprints` (blueprint = JSON string column); last-write-wins; pull-epoch optimistic guard on blueprint pull; frozen Daily Fit payloads are **local-only** |
| Account deletion | Yes | `ProfileViewController` L1165→L1286, `CosmicFitAuthService.deleteAccount` | A + C | — | Low | Edge `delete-account` (Bearer session), then local wipe + route to onboarding |
| Feedback | Yes (entitled) | `FeedbackService`, DailyFit feedback section | A (flow) + C | — | Low | Edge `send-feedback`; requires session; rate-limited (429) |
| Deep links | Yes | `AuthDeepLinkRouter`, Info.plist `CFBundleURLTypes` | B (mechanism) / A (flow) | Custom URL scheme only, **no Universal Links** | Low | Single route: `cosmicfit://login?email=&code=` |
| Weather (Daily Fit context) | Indirect | `WeatherService` (Open-Meteo, no key), callers `CosmicFitTabBarController:1248,1364`, `NatalChartViewController:168,187` | A (if output-affecting — see §I) | CoreLocation | Med | Live in shipped code path; `WeatherFabricFilter` is confirmed dead — verify whether weather actually alters payload or is display-only (§I) |
| Animations / brand chrome | Yes | `MotionSheenView`, `TornPaperEdgeView`, `CosmicFitLoaderView`, `ScrollingRunesBackgroundView`, `MenuButton`, transitions | B | CoreMotion, CAGradientLayer blend modes (colorDodge/screen), CAShapeLayer path morphing, SplitMix64 seeded tear | **High** (visual 1:1) | The brand feel lives here; each is precisely parameterised (durations/curves documented in §D) |

---

## Section C — Screen catalog

Presentation convention: authenticated-shell detail pages are **child VCs overlaid inside `CosmicFitTabBarController`** (`presentDetailViewController`, slide-up 0.2625s, dimming view, tab bar + menu bar stay visible), usually wrapped in `GenericDetailViewController` (card sheet with swipe-down dismiss + internal push stack). They are not UIKit modals.

### CosmicFitTabBarController (`UI/ViewControllers/CosmicFitTabBarController.swift`, ~1474 lines) — authenticated shell
2 tabs only: index 0 `DailyFitViewController`, index 1 `StyleGuideViewController` (Profile has a hidden tab item). Custom horizontal `SlideTabTransitionAnimator` via `tabBarController(_:animationControllerForTransitionFrom:to:)` (L1448). Owns: `MenuBarView` pinned top + status-bar backdrop; detail overlay container + dimming; menu present/dismiss; weather fetch kickoff; blueprint generation (`BlueprintComposer` call at L1038) and Daily Fit payload generation (supplies DailyFit a `payloadGenerator` closure + `persistenceProfileKey`); profile-update regeneration (`handleProfileUpdate` L773 — recalculates charts, regenerates blueprint + daily fit, clears reveal flags); auth-change hydration (L862); onboarding "chrome intro" choreography (L464–559, nav/tab bars slide in on first card tap); DEBUG force-refresh / engine-override handling. God-controller (README §7.4) — behaviour, not structure, is the parity target.

### DailyFitViewController (~228 KB) — primary screen
- **State machine:** `CardState {unrevealed, revealing, revealed}`; per-day reveal flag `DailyFitRevealPersistence.revealedFlagKey(forCalendarDay:engineId:)` (production engine id elided from key).
- **Reveal flow (`cardTapped` L4128):** freeze payload to disk **first** (`DailyFitFrozenPayloadStorage.save`), set reveal flag + `markFirstDailyFitRevealed` only on confirmed write, then `perform3DCardFlip` (L4168; 0.33s Y-flip, perspective m34=−1/500, glow squeeze keyed to |cos θ| on a Newton-Raphson-solved cubic bezier), `completeCardReveal` staggered fade-in.
- **Entitlement:** observes `entitlementDidChange`; un-entitled users get gated obscuration (glyph field + masked cutoff + unlock CTA → Purchase); first-ever revealed day remains free (`shouldObscureContentForRestrictedUser`); feedback section entitled-only (L1883); tomorrow tease → `StyleCalendarUnlockViewController`.
- **Trial CTA (commit `08a3afe`):** `configureRestrictedUnlockButton()` styles "Unlock Your Daily Fit", then fires an async task (loads products if needed → `isEligibleForAnnualIntroOffer()` + `annualTrialIsOneWeek`) and swaps to "Try 7 Days Free" only on confirmed one-week eligibility — fails closed to the default copy, no spinner.
- **Surfaces rendered from `DailyFitPayload`:** tarot card + numeral + style-edit variant, daily palette (`DailyColourPaletteView`), vibrancy/contrast/metal-tone envelope sliders + optional silhouette sliders (6 constraint-driven tracks), essence radar (`EssenceTriangleView` with chart-anchor ghost), textures/pattern, transit list, lunar context.
- **Refresh:** observes `.dailyVibeNeedsRefresh`, `.dailyFitDisplayPreferencesChanged`, day-rollover observers (L403). Today/tomorrow toggle via tab-bar-supplied generator.
- Known dead members per README (unused `cardTitleLabel`, `setupScrollIndicator`, etc.) — do not treat as features.

### StyleGuideViewController (~41 KB)
Tab 1. 2×4 grid: The Blueprint, Palette, Textures, Occasions, Hardware, Code, Accessory, Pattern (`StyleGuideGridButton`, glyph assets). Tile → `StyleGuideDetailViewController.configure(with:)` via tab-bar overlay. Guest gating: `AuthNudgeBannerView` (hidden when authenticated or dismissed flag `CosmicFitDismissedAuthNudge`); banner tap → `AuthGateViewController` (pageSheet). Live palette preview from `BlueprintStorage` → `PaletteGridViewModel.build`.

### StyleGuideDetailViewController (~59 KB)
One section page. `isGated = !EntitlementManager.hasFullAccess` (L127): content cut at tear fraction ≈0.48 with `TornPaperEdgeView` + rune glyph field + unlock CTA → dismiss + present `GenericDetailViewController(PurchaseViewController())` via tab bar (L1088). Observes `entitlementDidChange`. **Trial CTA (commit `08a3afe`):** `setupGatedCTA()` mirrors DailyFit — async eligibility check swaps "Unlock Your Style Guide" → "Try 7 Days Free" only on confirmed one-week eligibility, fail-closed. Several declared-but-unused properties (README-listed) — ignore for parity.

### OnboardingFormViewController (~64 KB)
`init(initialPage:postAuthMode:)`; 4 pages (3 in postAuth): 1 name (≥2 chars) → 2 birth date/time + "unknown time" checkbox → 3 location (`LocationAutocompleteView`; postAuth finishes here) → 4 email. `finishWithEmail` (L1036): save profile → `signUpWithProfile` → `performFullSync` → `performMysticalTransitionToMainApp()` (L1212: window snapshot, root swap to `AppDelegate.makeConfiguredTabBarController()`, 4.8s quintic dissolve, tab-bar chrome intro). Handles `EMAIL_EXISTS` → sign-in path (`AuthGateViewController` fullScreen). Sets `CosmicFitOnboardingPendingAuth` before page 4 so relaunch resumes at page 4.

### AnimatedLaunchScreenViewController (438 lines)
Always the initial root. Rune columns + `CosmicFitLogoMarkView` reveal; `setMainViewController(_:)` + `attemptTransitionToMainApp()` cross-dissolve fullScreen-presents the routed root after min duration (3.9s first run / 0.605s after; flag `hasShownAnimatedLaunchIntro`).

### AnimatedWelcomeIntroViewController (343 lines)
First-run only. 2 pages (dark welcome → light cascade of 8 elements, auto-advance after 1s); tap → `markWelcomeSeen()` → replaces nav stack with onboarding form.

### SignedOutLandingViewController (275 lines)
Root when profile complete but signed out. "Sign In" → `AuthGateViewController` with `onAuthenticationSuccess` → pull profile from Supabase → tab bar (or postAuth onboarding if pull incomplete). "Start Fresh" → confirm → sign out + wipe + fresh onboarding. Uses rune background (launch fade style) + loading overlay.

### AuthGateViewController (301 lines) — ACTIVE (not legacy)
Email entry → `sendOTP` → push `OTPVerifyViewController`. 4 live call sites: SignedOutLanding L138, OnboardingForm L874, StyleGuide nudge L175, Profile L844. Consumes pending deep links (auto-push OTP with prefilled code). "Not now" dismisses.

### OTPVerifyViewController (215 lines)
`init(email:prefillCode:)`; 6-digit verify → `verifyOTP`; auto-verify on prefill; observes `.cosmicFitDeepLinkReceived` to auto-fill matching email; `onVerified` callback else `performFullSync`.

### ProfileViewController (~64 KB) — "Account"
Reached: Menu → Account (`GenericDetailViewController` wrap, tab bar L614); Purchase "Have a code?" (L396, `focusPromoCodeField`). Edit name/birth/location (LocationAutocompleteView); save posts `.userProfileUpdated` (tab bar regenerates everything). Subscription status UI (`updateEntitlementUI` L879: Subscribed / comp message / debug unlock / Free), restore purchases, manage-subscription link (apps.apple.com), promo redeem/revoke, sign in/out, delete profile (local) vs delete account (edge function → `.userProfileDeleted` → onboarding). DEBUG-only Daily Fit engine picker (posts `.dailyFitEngineOverrideChanged`, `.devForceRefreshRequested`; gated by `allowsDevEngineTools`).

### PurchaseViewController (~561 lines, post-trial)
Paywall: annual/monthly `SubscriptionOptionCard`s + savings badge, subscribe → `StoreKitManager.purchase` → dismiss when `hasFullAccess`; restore; "Have a code?" → Profile with promo focus; legal links push `TermsOfUse`/`PrivacyPolicy` VCs inside the same `GenericDetailViewController`. Entry: StyleGuideDetail unlock, DailyFit gated CTA (L2529).
**Trial amendments (commit `08a3afe`):** `showTrialOffer` state set **once per presentation** from an async `isEligibleForAnnualIntroOffer()` fetch (no caching — eligibility flips after trial purchase/restore); when true, annual card reads "7 days free, then \<price\>/year", CTA becomes "Start Free Week" (annual selected), and a trial disclosure is prepended to the standard auto-renew disclosure. Also fixed: CTA title no longer force-resets to "Subscribe Now" after a cancelled/failed purchase; price label gained a leading constraint + autoshrink for the longer trial string. Ineligible/unknown/slow eligibility ⇒ byte-identical pre-trial paywall.

### StyleCalendarUnlockViewController (253 lines)
Coming-soon Style Calendar teaser. `PresentationMode {unlockPreview, subscribedComingSoon}` chosen by entitlement; 5-day row with one tappable day → `onDaySelected` → switch today/tomorrow; CTA disabled "Coming Soon".

### MenuViewController (401 lines)
Full-screen blur overlay (`.overFullScreen`, cross-dissolve, internal show/hide animation). Items: Account, FAQs, Help (MFMailComposeViewController → help@cosmicfit.app), TikTok `@mariacosmicfit`, Instagram `cosmicfitapp` (app scheme then web). Callbacks (`onNavigateToProfile`/`onNavigateToFAQ`/`onDismiss`) fire after dismissal so the tab bar performs navigation.

### FAQViewController (~18 KB)
Static native FAQ stack; wrapped in GenericDetail. No gating.

### GenericDetailViewController (366 lines)
Reusable card-sheet host: `init(contentViewController:)`, internal `pushContentViewController`/`pop` stack, chevron/xmark close, pan-gesture interactive dismiss with velocity thresholds, walks parent chain to `CosmicFitTabBarController.dismissDetailViewController`.

### LegalDocumentViewController (409 lines) + PrivacyPolicyViewController / TermsOfUseViewController (17 lines each)
Base renderer (eyebrow/title/date/notice/sections/bullets/inline links via UITextViewDelegate) fed by `Legal/PrivacyPolicyContent.swift` (21 KB) / `TermsOfUseContent.swift` (26 KB) configurations. Reached from Purchase legal links.

### NatalChartViewController (~31 KB) — DEBUG-only
Table of planets/houses/transits + today's weather + `ChartWheelView`. Only instantiated via `createDebugChartViewController()` (tab bar L1225) and debug menu options. Its interpretation pushes are placeholder text. **Tag: debug; not shipping nav graph.**

### InterpretationViewController (358 lines) — LEGACY/PLACEHOLDER
Text renderer reached only from NatalChartVC debug methods with placeholder copy. Contains the app's only `UIActivityViewController` (share) at L350. **Tag: legacy/dead in production.**

### CardPresentationController (55 lines) — DEAD (verified: zero references).

---

## Section D — Component catalog

### Design system — `UI/CosmicFitTheme.swift` (757 lines, all-static namespace)
- **Colours:** cosmicGrey `#DEDEDE` (main bg); darkerCosmicGrey rgb(106,106,115) sub-page bg; darkCosmicGrey `#B8B8B8` nav bar; cosmicBlue `#000210` primary text / tab-bar bg / borders; cosmicLilac `#7E69E6` accent / active tab; lightCosmicLilac rgb(196,182,248) + lightCosmicBlue rgb(88,92,112) button-confirm flashes; tabBarInactive white; divider cosmicBlue @0.3.
- **Interface style:** app **forced Dark** globally (`INFOPLIST_KEY_UIUserInterfaceStyle = Dark`) yet surfaces are light grey; UISwitches forced `.light`. No adaptive light/dark palette. (Parity note: do not rely on system theming.)
- **Type:** sizes — pageTitle 48, largeTitle 35, title1 28, title2/subheadline 22, title3 20, body 18, headline 17, callout/sectionHeader 16, footnote 13, caption 12/11. DM Sans body (6 mapped faces: Light/Regular/Medium/SemiBold/Bold/ExtraBold). **Misnomer trap:** `DMSerifTextFont(size:weight:)` actually returns PT Serif regular/italic/bold-italic and falls back to *system serif* for bold; genuine DM Serif Text only via `dmSerifTextDisplayFont` (tab titles, palette headers). Attributed presets: PageEyebrow (15pt, 4% tracking), PageMainTitle (48pt DM Serif, 0.78 line-height), StyleGuideSubPageTitle, DailyFitCardTitle (7.7% kern), DailyFitDate (14% kern).
- **Layout:** maxContentWidth 520 (iPad), scrollContentBottomInset 100, HeaderGlyphLayout 60×44, hub glyph 86/44. Corner radii inline: 12 content, 8 buttons/fields, 6 onboardingAction, 16 switch, 4 swatches — no shared token. No gradient tokens (gradients live in views).
- **Helpers:** nav/tab bar appearance styling (selection indicator cleared, title offset −10, 1px white@0.2 tab dividers), `ButtonStyle {primary, onboardingAction, secondary, text}` + gated-paywall button, `flashFilledButtonConfirmed` (flash + optional SF checkmark), `styleDatePicker` (wheels; fragile KVO `setValue(forKey:"textColor")`), `makePickerInputView`, text field/view styling, `createAttributedText`.

### Transitions & nav chrome
- `SlideTabTransitionAnimator` — horizontal tab slide, ~0.2625s, spring damping 0.9; special-cases DailyFit (`prepareForTransition`/`finishTransition`).
- `VerticalSlideAnimator` — vertical push-up/pop-down `.overCurrentContext` (tab bar visible), 0.2625s easeOut/easeIn. (Style Guide nav-delegate wiring effectively unused per README; the live vertical slide is the tab bar's own detail-overlay animation.)
- `CosmicNavigationArrow` — chevron drawn via UIGraphicsImageRenderer + UIBezierPath, template image, configures `UIButton.Configuration`.

### Live custom views (`UI/Views/`)
| View | Renders / behaviour | Inputs | Technique |
|---|---|---|---|
| ChartWheelView | zodiac wedges, 5° ticks, dashed house spokes, numerals I–XII, planet glyphs, aspect net | `NatalChartCalculator.NatalChart` | Core Graphics `draw(_:)`; calls `AstronomicalCalculator.calculateAspect` |
| ColourPaletteView (545 ln) | 2-section swatch grid (Core/Accent, 4-col); tap-to-focus expanding overlay with colour name; `setSwatchInteractionEnabled` for paywall | `PaletteGrid` | manual frames in `layoutSubviews`; spring focus 0.4s damping 0.85 |
| DailyColourPaletteView | full-width daily swatch + centred name (h = w/3) | `[DailyColourPick]` | UIKit Auto Layout |
| EssenceTriangleView | 14-axis radar → top-3 solid triangle + dashed chart-anchor ghost, star vertices, custom label-collision solver; intrinsic 220×220 | `StyleEssenceProfile` + `EssencePresentationDirective` | CAShapeLayer ×2 |
| DosAndDontsSectionView | star-headed heading + bullet rows (`bulletPointRow` reused by StyleCalendar) | title + bullets | UIStackView |
| LocationAutocompleteView | birth-place field + ≤3-row dropdown; inner `LocationSuggestionCell` (SF Symbol category icons); hitTest routing | delegate | MapKit `MKLocalSearchCompleter` + `MKLocalSearch`; `CLGeocoder` reverse-geocode → TimeZone (fallback `.current`) |
| AuthNudgeBannerView | sign-in pill + arrow + dismiss (48px); writes `CosmicFitDismissedAuthNudge` | closures | UIKit + CosmicNavigationArrow |
| MenuBarView / MenuButton | sticky 60px top bar (logo 30px + button); 4-dot ↔ X morph burger (0.1/0.2s) | `onMenuTapped` | UIView dots + CGAffineTransform |
| ScrollingRunesBackgroundView | 5 scrolling rune columns + breathing edge-fade bands; styles `{dailyFit, launch}` | `EdgeFadeStyle` | tiled UIImageViews + CABasicAnimation translation + CAGradientLayer waves |
| CosmicFitLoaderView | brand div-star morphing loader, drop-in activity-indicator replacement (44×44); `Fill {light, dark}` | — | CAShapeLayer path-morph CAKeyframeAnimation between parametric star shapes |
| CosmicFitLoadingOverlay | scrim + loader + message; static `show(in:)`/`dismiss`, 0.2s fade | message/fill/dim | wraps loader |
| CosmicFitLogoMarkView | "Cosmic Fit" lockup, per-element CAShapeLayers, staggered opacity reveal | hard-coded SVG path strings | embedded `SVGPathParser` (M/L/H/V/C/S/Q/T/Z) |
| MotionSheenView | holographic foil sheen + specular highlight alpha-masked to card art; 3D tilt via `MotionParallaxBinding` | `cardImage`, intensity | CAGradientLayer ×2 (**colorDodge/screen** blend), CALayer mask, **CoreMotion** deviceMotion via shared `MotionSheenDriver`, simd matrices |
| TornPaperEdgeView | procedural torn-paper edge (h 44) for gated content; deterministic tear via SplitMix64 `SeededGenerator`; file also hosts `PassthroughContainerView` + `GatedPaywallScrollView` | `fillColor` | Core Graphics + UIBezierPath |

### Palette subsystem (`UI/Views/Palette/`)
- `PaletteGrid.swift` — data model (`Section`, `PaletteCell = .filled(hex, anchorName) | .empty`).
- `PaletteGridViewModel.swift` — builds 2-section grid ("Core Palette" / "Accent Colours"); CIE-Lab greedy nearest-neighbour ordering + 2-opt refinement + ΔE dedup (threshold² 16). **Golden-tested** (`palette_grid_golden_user_{1,2}.json`) — this ordering algorithm is part of the visual parity contract.
- `ColourMath.swift` — Foundation-only: hex↔HSL, hex↔Lab/LCH (D65 sRGB↔XYZ↔Lab), ΔE² . Shared engine+UI; portable as-is.

### VC-embedded drawing (must-parity visuals)
- Tarot flip: two image views, `isDoubleSided = false`, container `sublayerTransform.m34 = -1/500`, rotations 0→π / π→2π, 0.33s easeOut, front pre-rotated 180°; glow halo CAKeyframe `scale.x` = |cos θ| along flip; shadow + pulse animations.
- MotionSheen attached to card front and back; parallax on the card container.
- Silhouette bars: 6 constraint-driven slider tracks (indicator label + track + constraint tuples).
- CoreImage: reused `CIContext`, `CIGaussianBlur` (card blur), `CIColorInvert` (Purchase + StyleCalendarUnlock glyph inversion).

### Dead components (verified)
`StarView` (0 refs), `LocationResultTableViewCell` (0 refs; superseded by inner `LocationSuggestionCell`), `ColourCell` (0 refs as a cell — **but its `UIColor(hex:)` extension is load-bearing app-wide**), `CardPresentationController` (0 refs), `WeatherFabricFilter` (0 refs outside own file).

---

## Section E — Platform API catalog

Imports across app target: Foundation 110, UIKit 46, CoreLocation 9, Supabase 5, CSwissEphemeris 4, StoreKit 3, Security 2, MapKit 2, CryptoKit 2, simd/QuartzCore/MessageUI/CoreMotion/CoreImage ×1. **Absent:** UserNotifications (no push, no local notifications), WebKit, SafariServices, Photos, AVFoundation, ATT, PassKit, widgets/extensions.

| API | Call sites | Purpose / data | Failure modes / notes |
|---|---|---|---|
| **StoreKit 2** | `StoreKitManager.swift`; bootstrap `AppDelegate:43–44`; `PurchaseViewController`; `ProfileViewController:857`; gated CTAs in DailyFitVC/StyleGuideDetailVC | Product IDs **hard-coded in code**: `com.cosmicfit.full.monthly`, `com.cosmicfit.full.annual` (no subscription-group ref in client). `Product.products(for:)`, `purchase()` → verified → `finish()` → entitlement recheck; `.pending`/`.unverified` throw; restore = `AppStore.sync()`; detached `Transaction.updates` listener. **Intro-offer API (commit `08a3afe`, `StoreKitManager.swift:111–166`):** `annualFreeTrialOffer` (returns only `paymentMode == .freeTrial` offers), `annualTrialIsOneWeek` (1 week or 7 days), pure-static duration formatters `trialDurationText`/`trialDurationAdjective` (unit-tested in `TrialCopyTests`), `isEligibleForAnnualIntroOffer()` (async `subscription.isEligibleForIntroOffer`, fails closed, **never cached** — refetched per paywall/teaser presentation) | Client-side verification only (`currentEntitlements`, `revocationDate == nil`); no server receipt validation; `app-store-notifications` webhook is server-side only. A `Cosmic Fit.storekit` local store config now exists at **repo root** (deliberately outside auto-bundling `Cosmic Fit/`) + shared scheme wiring — simulator testing only, never ships |
| **Keychain (Security)** | `ClientInstallIdentity.swift` (svc `com.cosmicfit.install-identity`, acct `client_install_id`, AfterFirstUnlockThisDeviceOnly); `CompAccessStorage.swift` (svc `com.cosmicfit.comp-access`, acct `current_grant`, JSON `CompAccessGrant` ISO8601) | Stable per-install UUID (survives reinstall; **not** cleared on sign-out/profile delete) anchoring promo/comp grants; comp grant persistence | Supabase SDK separately persists sessions in its own Keychain store (service name SDK-internal — runtime confirm); fresh install (`CosmicFitAppInstalled` unset) → `signOut()` to purge stale session |
| **CoreLocation** | `LocationManager.swift` (singleton; hundredMeters accuracy, 50m filter, whenInUse; caches lat/lon/timestamp/accuracy in UserDefaults); early request at `AppDelegate:31`; re-fetch on foreground if >30 min stale | Current location for Daily Fit weather/transit context. Usage string in build settings (`INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`): "Your location is used for Daily Fit weather features and related calculations based on where you are now." | Permission denial → app still works (weather optional); **not** used for birth place |
| **MapKit** | `LocationAutocompleteView.swift` | Birth-place autocomplete: `MKLocalSearchCompleter` (address+POI) → `MKLocalSearch` for coordinates → `CLGeocoder.reverseGeocodeLocation` for TimeZone | Timezone fallback `.current` (a determinism hazard if geocode fails — chart depends on tz) |
| **CoreMotion** | `MotionSheenView.swift` (`CMMotionManager` deviceMotion, shared driver) | Holographic sheen + card parallax | Motion unavailable → static sheen |
| **CoreImage** | DailyFitVC (CIGaussianBlur), Purchase/StyleCalendarUnlock (CIColorInvert) | Card blur, glyph inversion | — |
| **CryptoKit** | `DailySeedGenerator.swift:48`, `DailyFitEngineRegistry.swift:113` | SHA256 daily seeds + calibration fingerprints — **part of the determinism contract** | — |
| **MessageUI** | `MenuViewController` | Help mail composer (help@cosmicfit.app); `canSendMail()` guard | No mail account → button no-ops per guard |
| **URL scheme** | Info.plist `CFBundleURLTypes` scheme `cosmicfit`; `AppDelegate:77` → `AuthDeepLinkRouter` | `cosmicfit://login?email=&code=` (both params required); Supabase `redirectToURL: cosmicfit://login`, flow `.implicit` | No Universal Links; `LSApplicationQueriesSchemes: instagram` |
| **ATS** | Info.plist | **`NSAllowsArbitraryLoads = true`** (ATS fully disabled) | Flag for security review at port time |
| **Weather (network)** | `WeatherService.swift` → Open-Meteo `https://api.open-meteo.com/v1/forecast` (current_weather + hourly humidity, timezone=auto), **no API key**, raw URLSession | Callers: `CosmicFitTabBarController:1248,1364` (Daily Fit flow), `NatalChartViewController:168,187` (debug) | `WeatherError.badResponse/.decode`; see §I on whether output-affecting |
| **Fonts** | Info.plist `UIAppFonts` (22 entries: PT Serif ×3, DM Serif Text ×2, DM Sans ×17); `Resources/Fonts/` 24 ttf; no runtime registration | Theme maps only 6 DM Sans faces | Registered-but-unmapped weights bundled |
| **Ephemeris (C lib)** | `SwissEphemerisBootstrap.swift` (`CSwissEphemeris` SPM module): locates `seas_18.se1` in Bundle.main, **`fatalError` if missing**, `swe_set_ephe_path`. Called **lazily** from `AsteroidCalculator.swift:79`, not at launch. `VSOP87Parser.swift`: bundle `Resources/VSOP87Data/VSOP87D.{mer,ven,ear,mar,jup,sat,ura,nep}`, thread-safe once-load; **any failure → Keplerian mean-longitude fallback for all planets (~1–2°), silent** | Chiron/Lilith/NorthNode via Swiss Ephemeris; Sun–Pluto via VSOP87 | Two very different failure modes: crash vs silent accuracy degrade |
| **SF Symbols** | ~20 uses: `xmark` ×7, `mappin.circle.fill` ×5, location-category icons, checkmark in button flash | decorative/UI chrome | low coupling |
| **Share sheet** | `InterpretationViewController:350` only (debug-only VC) | effectively unshipped | — |
| **Haptics / UIPasteboard / WebKit / notifications** | **none** | — | — |
| **Capabilities** | No `.entitlements` file, no App Groups, no background modes, no associated domains. Portrait-only, `UIRequiresFullScreen`, forced Dark, LaunchScreen storyboard only, category lifestyle, `ITSAppUsesNonExemptEncryption=false` | — | — |
| **Config injection** | xcconfig (`Dev`/`Prod`, gitignored) → Info.plist `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `DAILY_FIT_ENGINE_ID` → `SupabaseConfig` / `DailyFitEngineConfig`; placeholder Supabase client if unconfigured | — | Release ignores non-production engine ids |

---

## Section F — Portable engine / data contracts (Layer A — must behave 1:1)

### Entry points (signatures as shipped)
- `DailyFitPipeline.generate(blueprint:snapshot:calibration:dailyFitEngineId:) -> DailyFitPayload` (`DailyFitPipeline.swift:13`) — **sole assembly point** (app, inspector, tests). stage1Experimental → `DailyNarrativeSelector.select` → `BlueprintLensEngine.generatePayloadFromPlan` (:1473); `.standard` legacy → `generatePayload` (:472). `+generateWithTrace`.
- `DailyEnergyEngine.generateSnapshot(natalChart:progressedChart:transits:moonPhaseDegrees:profileHash:date:calibration:mode:dailyFitEngineId:) -> DailyEnergySnapshot` (:42).
- `BlueprintComposer.compose(chart:birthDate:birthLocation:dataset:narrativeCache:) -> CosmicBlueprint` (:32; `composeFull` :50 via `ChartAnalyser.analyse` + `ChartInputAdapter.adapt`; `composeCore` :73 is the SG-4 seam). App call site: `CosmicFitTabBarController:1038`.
- `BlueprintTokenGenerator.generate(analysis:dataset:) -> TokenGenerationResult` (:265); `loadDataset(from:)` (:350/:365).
- `ColourEngine.evaluateStrict/evaluateProduction(input: BirthChartColourInput) -> ColourEngineResult` (`ColourEngineV4/ColourEngine.swift:18/24`).
- `NatalChartCalculator`: typed `NatalChart {planets: [PlanetPosition], ascendant, midheaven, descendant, imumCoeli, houseCusps, wholeSignHouseCusps, northNode, southNode, vertex, partOfFortune, lilith, chiron, lunarPhase}`; APIs `calculateNatalChart(birthDate:latitude:longitude:timeZone:)`, `calculateProgressedChart(...)`, `calculateTransits(natalChart:date:overrideDeviceLocation:) -> [TransitAspect]`; legacy `[String: Any]` bridges (`formatNatalChart` etc.) still feed some UI text.

### Determinism contract
- `DailySeedGenerator.generateDailySeed(profileHash:for:)`: `combined = "{profileHash}_{yyyyMMdd (UTC, en_GB)}"` → seed = first 8 hex chars of SHA256(combined) as Int (32-bit); fallback `abs(hashValue)`. RNG = LCG (mul 6364136223846793005, inc 1442695040888963407).
- **profileHash is not a hash** — it is `UserProfile.id` (UUID string), with `ClientInstallIdentity.id` fallback at call sites (`CosmicFitTabBarController:1088/1161`). Same user + same day + same engine ⇒ same payload, *modulo recency state*.
- Engine id folded in at `DailyEnergyEngine.dailySeed` per registry `dailySeedPolicy` (`sharedProfileDate` vs `includesEngineId` — production uses `includesEngineId`).
- Day-string timezone conventions vary by store: seed uses UTC; frozen filenames + reveal flags use `.current` timezone (`en_GB_POSIX`); tarot recency uses `en_US_POSIX` `.current`. **Replicate exactly** — mixed-tz behaviour around midnight is part of observed behaviour.

### Engine registry / config
`DailyFitEngineRegistry.swift`: presets `production` (Sky Forward v1.0.1, mode `.stage1Experimental`, seed policy includesEngineId), `stage1_experimental` (DEBUG alias, same calibration/fingerprint, different state namespaces), `legacy_baseline`, `stage2_legacy` (DEBUG regression, mode `.standard`). Fingerprint = SHA256 of canonical `%.6f` calibration serialization (locked by `ProductionFingerprintGuard_Tests`). `DailyFitEngineConfig.effectiveEngineId`: Release **always** `production`; DEBUG allows UserDefaults override `dailyFitEngineIdRuntimeOverride` only when xcconfig selects non-production.

### `DailyFitPayload` (exact UI-bound fields; custom Codable w/ legacy `essenceTriangle` fallback)
`tarotCard: TarotCard`, `styleEditVariant: StyleEditVariant`, `dailyPalette: DailyPaletteSelection {colours: [DailyColourPick {name, hexValue, role}], allPaletteHexes: [String]}`, `vibrancy/contrast/metalTone: Double`, `essenceProfile: StyleEssenceProfile`, `silhouetteProfile: SilhouetteProfile`, `vibeBreakdown: VibeBreakdown`, `axes: DerivedAxes`, `dominantTransits: [DailyTransitSummary {transitPlanet, natalPlanet, aspect, strength}]`, `lunarContext: LunarContext {phaseName, isWaxing, element, phaseDegrees}`, `dailyTextures: [String]`, `dailyPattern: String?`, `generatedAt: Date`, `scalePresentation: PersonalScalePresentation?`, `narrativeBrief: DailyNarrativeBrief?` (deprecated decode-only), `dailyFitEngineId: String?` (missing → `production` via `resolvedDailyFitEngineId`).

Supporting types:
- `StyleEssenceProfile {allScores, visibleCategories, chartAnchorScores?}`; `StyleEssenceCategory` = 14 fixed-angle cases: edgy, romantic, classic, utility, drama, playful, polished, effortless, sensual, magnetic, grounded, eclectic, minimal, maximalist.
- `SilhouetteProfile {masculineFeminine, angularRounded, structuredDraped: Double (0–1)} + chartAnchorMF/AR/SD?`.
- `VibeBreakdown` — Ints classic/playful/romantic/utility/drama/edge, each 0–10, **sum = 21**. (`VibeBreakdown .swift` — trailing space in filename.)
- `DerivedAxes` — Doubles action/tempo/strategy/visibility clamped 1–10.
- `PersonalScaleEnvelope {kind, floor, ceiling, baseline, value, displayPosition, baselinePosition}`; `PersonalScalePresentation` = vibrancy/contrast/metalTone (+ optional 3 silhouette envelopes); kinds: vibrancy, contrast, metalTone, masculineFeminine, angularRounded, structuredDraped.
- `DailyEnergySnapshot {vibeProfile, axes, dominantTransits, lunarContext, dailySeed: Int, profileHash, generatedAt}` + stage1 optionals `chartVibeProfile?, skyVibeProfile?, chartAxes?, vibeRawScores?, skySalience?`.
- `DailyFitCalibration` (code-only, Equatable, not serialised): sourceWeights {natal .16, transits .44, lunar .30, progressed .07, currentSun .03 for Sky Forward}, signEnergyMap, signMultiplierPolicy, planetAxisMap, selectionWeights, axisTuning {sigmoidSpread, jitterRange}, stage2Sensitivity, narrativeSelection.

### `CosmicBlueprint` (persisted Style Guide; schemaVersion 4)
`userInfo {birthDate, birthLocation, generationDate}`, `styleCore`, `textures {goodText, badText, sweetSpotText, recommendedTextures, avoidTextures, sweetSpotKeywords}`, `palette` (PaletteSection: `neutrals?/coreColours/accentColours/supportColours?` as `BlueprintColour {name, hexValue, role: ColourRole (neutral/core/accent/statement/support/anchor/signature), provenance: ColourProvenance (chartDerived/crossPoolEscalation/libraryFallback/v4Template/chartDerivedAccent; decode-tolerant fallback), semanticLabel?}`, `lightAnchor?/deepAnchor?/luminarySignature?/rulerSignature?`, `family?/cluster?/variables?/secondaryPull?/overrideFlags?`, legacy `swatchFamilies`, `narrativeText`; `isV4 = family != nil`), `occasions {workText, intimateText, dailyText}`, `hardware {metalsText, stonesText, tipText, recommendedMetals, personalMetals?, structuralMetals?, excludedFinishes?, recommendedStones}`, `code {leanInto, avoid, consider, aiFraming? (SG-3)}`, `accessory {paragraphs ×3}`, `pattern {narrativeText, tipText, recommendedPatterns, avoidPatterns}`, `generatedAt`, `engineVersion`, `coreFormula?`, `closing?`. Every section additionally carries SG-2.5 optionals `{sectionIntro?, rankedItems: [RankedItem {name, role, useCase?}]?, tests: [String]?, traps: [Trap {failure, fix}]?}`. All newer fields `decodeIfPresent` — old persisted blueprints decode unchanged. `BlueprintArchetypeKey {section, archetypeCluster, variant}`; `BlueprintSection` rawValues are the narrative-cache JSON keys (style_core, textures_good/bad/sweet_spot, palette_narrative, occasions_work/intimate/daily, hardware_metals/stones/tip, accessory_1/2/3, pattern_narrative/tip).

### Recency / rotation state (UserDefaults; behaviour-affecting, must-parity)
| Tracker | Key shape | Rules |
|---|---|---|
| TarotRecencyTracker | `tarot.recency.{engineId}.{profileHash}.{yyyy-MM-dd}` + dates list | window 10d; **hard cooldown 3 days** (`getCooldownCards` blocks daysAgo ≤ 3); yesterday penalty base 0.18, floor 0.55; `en_US_POSIX`, `.current` tz; legacy→namespaced migration (`TarotEngineNamespaceMigration`) |
| TarotVariantRotationTracker | per (card, profile, engine) index + lastShown | rotates style-edit variants |
| VisibleEssenceRecencyTracker | prefix `essence.visible.recency`, engine-namespaced | retention 10d; cooldown param (stage1 default 2), excludes today |
| ColourRecencyTracker | shown-set + hero keys, engine-namespaced | coverage-floor / hero-rotation gates |
| AccentRecencyTracker | `{profileHash}.{date}` — **NOT engine-namespaced** (only asymmetry; see §I) | accent repetition guard |

### Freeze / reveal contract (`DailyFitFrozenPayloadStorage` + `DailyFitRevealPersistence`)
- Frozen payloads: `Documents/DailyFitFrozen/{sanitizedProfileKey}_{engineId}_{yyyy-MM-dd}.json` (legacy fallback without engineId), atomic, ISO8601; on load, stale artifacts purged when `effectiveEngineId` changed (embedded `resolvedDailyFitEngineId` mismatch ⇒ delete file + clear matching reveal flags).
- Reveal flags: `CardRevealed_{day}` (production) / `CardRevealed_{engineId}_{day}` (others) + `SliderEntrancePlayed_…`.
- First-free-day: `CosmicFit_FirstFreeDailyFitDate` (+ migration flag) — the first-ever revealed day stays un-gated for un-entitled users (`shouldObscureContentForRestrictedUser`).
- Invariant: payload is frozen to disk **before** the reveal flag is set, so a cold launch can never show "revealed" with a regenerated (different) card.

### Monetization / trial contract (Layer A — amended by commit `08a3afe`, 2026-07-12)
Canonical source: `docs/handoff/IAP_TRIAL_HANDOFF_2026-07-12.md` (written for the Android conversion; platform-agnostic product model). Key rules the port must replicate exactly:
- **Free tier unchanged:** first-ever revealed Daily Fit is free permanently for that calendar day only; Style Guide always gated for free users; no other free content.
- **Paid tier "Full Access":** one subscription group, two auto-renewing plans — monthly `com.cosmicfit.full.monthly` (£/$7.99, no intro offer) and annual `com.cosmicfit.full.annual` (£/$49.99, **7-day free trial**). Framing: "start free week, charged nothing; annual price charged once at day 7 unless cancelled; paid year runs from trial end" — never "pay up front, get 7 free days".
- **Eligibility:** one trial per user per subscription group, enforced by the store. **Fail closed everywhere**: eligibility unknown/slow/products-not-loaded ⇒ non-trial UI, byte-identical to the pre-trial app; no spinners waiting on eligibility. Never cached (flips after trial purchase/restore).
- **Entitlement rule unchanged:** `hasFullAccess = activeStoreSubscription(either product) ∨ validCompGrant`; trial-period transactions count as active — **no trial special-casing anywhere in gating**; comp-grant users never see teasers/paywall; trial→paid conversion needs no app-side handling.
- **Exact copy (shared across platforms):** teaser buttons "Try 7 Days Free" (eligible) vs "Unlock Your Daily Fit"/"Unlock Your Style Guide"; annual card "7 days free, then \<price\>/year" vs "\<price\>/year"; CTA "Start Free Week" (annual+eligible) vs "Subscribe Now"; badge "Save \<n\>%" where n = (12×monthly − annual)/(12×monthly)×100 from **live store prices** (currently 47%). Trial disclosure (prepended when eligible): "Annual plan starts with a 7-day free trial. You will not be charged until the trial ends; £49.99/year is then charged unless you cancel at least 24 hours before the trial ends." Standard disclosure always shown.
- **Durations derived from the store's offer object, not hardcoded** — a 1-week offer renders "7 days"/"7-day"; reconfigured offers flow through automatically; non-1-week trials use CTA fallback "Start Free Trial". (Handoff notes Play's `pricingPhases` ISO-8601 periods, e.g. `P1W`, as the equivalent derivation source.)
- **Edge cases to preserve:** pending purchase (Ask to Buy) → "Your purchase is waiting for approval.", CTA restored, no unlock; cancelled purchase → paywall unchanged, CTA restored; restore → recheck entitlement, restored in-trial subscription unlocks.
- **Store config state:** ASC done 2026-07-12 (intro offer Free / 1 week / 175 territories / no end date) but some metadata still flagged missing — while flagged, sandbox may return zero products; Google Play equivalent is documented in handoff §4 as to-do (facts only; not a plan).

### Bundled runtime data
- `Resources/TarotCards.json` — real file (8,306 lines): JSON array of 78 cards `{name, imagePath, arcana, suit, number, keywords, themes, energyAffinity, axesAffinity, description, reversedKeywords, symbolism, styleEdits: [StyleEditVariant {variant, title, description, energyEmphasis: [String: Double], axesEmphasis: [String: Int], dailyRitual?, wardrobeReflection?}]}`.
- Symlinks → `data/style_guide/`: `astrological_style_dataset.json` (BlueprintTokenGenerator), `blueprint_narrative_cache.json` (**this base file is what `NarrativeCacheLoader.loadFromBundle` actually loads** — the `-2-clusters` variant is bundled but only tools/tests reference it; dual-shape decode v1 flat / v2 structured), `ranked_domain_tables.json` (`RankedDomainTables.swift` + SG-4 validator), `style_guide_rules.json` (SG-4 validator only, untracked).
- `Resources/VSOP87Data/` (8 planet files) + `seas_18.se1` (Swiss Ephemeris) — binary parity inputs for chart math.

---

## Section G — Backend touchpoints (client-visible only)

Transport: hand-rolled `URLSession` POST to `{SUPABASE_URL}/functions/v1/{name}` (NOT SDK `functions.invoke`); headers `Content-Type: application/json`, `apikey: {publishableKey}`, `Authorization: Bearer {publishableKey}` — replaced with `Bearer {session.accessToken}` when a valid session exists. Two duplicate helpers: `CosmicFitAuthService.invokeEdgeFunction`, `PromoCodeService.invokeEdgeFunction` (+ FeedbackService's own).

| Edge function | Request | Response | Caller |
|---|---|---|---|
| `send-otp` | `{email}` | `{success}` | AuthGateVC:266 |
| `verify-otp` | `{email, code}` | `{access_token, refresh_token, expires_in?}` → `supabase.auth.setSession` | OTPVerifyVC:178 |
| `signup-with-profile` | `{email, profile: {first_name, birth_date (ISO8601), birth_location, latitude, longitude, timezone_identifier, birth_time_is_unknown}}` | session tokens; 409 `{error: {code: "EMAIL_EXISTS"}}` | OnboardingFormVC:1056 |
| `delete-account` | `{}` (Bearer session) | `{success}` | ProfileVC → AuthService |
| `redeem-code` | `{code, clientInstallId, isDevBuild? (DEBUG)}` | `{ok, grant: {code, grantedAt, expiresAt?, redemptionPosition?}}`; errors INVALID_CODE / CODE_EXPIRED / RATE_LIMITED | ProfileVC:1113 |
| `check-comp-access` | `{clientInstallId}` (requires session) | `{hasCompAccess, grant}` | AppDelegate:54, TabBar:886, ProfileVC:165 |
| `revoke-comp-access` | `{clientInstallId}` | ignored | ProfileVC:984 |
| `send-feedback` | `{message, metadata: {displayDate?, deviceModel, iosVersion, appVersion}}` (Bearer session) | error body on ≥400; 429 rate limit | DailyFit feedback (via `FeedbackService`) |
| `app-store-notifications` | — | — | **zero client references**; server-side webhook only. Client entitlements come from StoreKit 2 locally |

Direct Postgres (SDK Postgrest):
- `profiles`: upsert onConflict `id` / select by `id` — columns `id, first_name, birth_date, birth_location, latitude, longitude, timezone_identifier, birth_time_is_unknown`.
- `user_blueprints`: upsert onConflict `user_id` / select `blueprint_json` — columns `user_id, blueprint_json` (full `CosmicBlueprint` as JSON string), `generated_at, engine_version`.
- `user_preferences`: `{id}` only via dead `syncPreferencesToSupabase()` — no callers.
- **No Supabase Storage buckets anywhere.**

Sync semantics: `performFullSync` = push-if-local-else-pull for profile + blueprint; last-write-wins upserts (no field merge); blueprint pull guarded by `BlueprintStorage.remoteBlueprintPullEpoch` (refuses overwrite if local changed mid-fetch). **Local-only (never synced):** Daily Fit frozen payloads, reveal flags, all recency trackers, comp grant (Keychain, restored via `check-comp-access`), install identity.

Session storage on device: Supabase Swift SDK default Keychain-backed store; app mirrors only `CosmicFitLastUserId` / `CosmicFitAccountEmail` / `CosmicFitAppInstalled` in UserDefaults. Fresh-install detection signs out to kill Keychain-surviving sessions. User-switch (`lastUserId` ≠ new id) triggers full local purge.

Migrations (server, client-relevant contracts): `001`–`011` — profiles, birth_time_is_unknown, subscription status/events, promo codes + redemption position, comp revoke, promo user-scoped access (010), unique slot numbers (011).

---

## Section H — Non-goals / excluded from the Android app binary

- **`inspector/`** — macOS-only SPM package (Hummingbird server, port 7777) compiling the same engine via symlinks; dev inspection UI. Not shipped. Useful later as a cross-platform parity oracle, but out of scope for the app binary.
- **`tools/`** — ~60 Python scripts: dataset authoring/validation (`generate_dataset.py`, `validate_dataset.py`), narrative generation/QA (`backfill_narratives.py`, `review_tool.py`, `sg_generate.py`, `sg_validation.py`, `sg3_audit.py`), calibration/regression harnesses, production audit harness, SynthID image tooling. Never compiled into the app. `sg_validation.py` defines the paragraph-gate rules the SG-4 Swift validator mirrors (a *contract* worth knowing about, not app code).
- **`Cosmic FitTests/`** — ~70 suites (engine parity, fingerprint guard, SG contract tests, recency isolation, goldens). Test-only env flags: `REGENERATE_BLUEPRINT_FIXTURES`, `REGENERATE_V4_*`, `REGENERATE_PALETTE_GRID_GOLDENS`, `CALIBRATION_CI_GATE`, `CALIBRATION_REPORT_DIR`, `PALETTE_CALIBRATION_DIAGNOSTIC`. The *fixtures* that encode behavioural contracts (goldens, `MariaAshLocked_Tests`, `ProductionFingerprintGuard_Tests`, palette-grid goldens) are parity assets even though the tests themselves don't ship.
- **`docs/fixtures/`, `docs/house_sect_regression/`, generated reports** — QA artefacts, not architecture.
- **Dead/legacy code (verified this pass):** `CardPresentationController`, `StarView`, `LocationResultTableViewCell`, `ColourCell` (as cell), `WeatherFabricFilter`, `AppDelegate.configureAppearance()` + `handleDailyVibeUpdate()`, `SupabaseSyncService.syncPreferencesToSupabase()`, `InterpretationViewController` (placeholder, debug-reachable only), `NatalChartViewController` (debug-only). Additional README §7.1 dead-file list (ParagraphBlock, StructuralAxes, ColourScoring, TransitWeightCalculator, TarotSelectionMonitor, Ephemeris+Helpers, AstrologicalInterpreter, InterpretationTextLibrary prose tables, `_archive/`) — spot-consistent with this pass; treat all as non-requirements.
- **SG-4 work-in-progress (committed in `08a3afe`):** `StyleGuideCoherenceValidator.swift` auto-compiles into the app target (folder-synchronized project) but has **no production call site** — only `SG4ComposedContractTests` / `SG4ValidatorParityTests` use it; `style_guide_rules.json` is bundled but consumed only by that validator. Compiled-but-dormant; not a shipped feature yet (SG-4 gate pending owner sign-off).
- **IAP dev-only artifacts (commit `08a3afe`):** `Cosmic Fit.storekit` at repo root (kept outside `Cosmic Fit/` precisely so the folder-synchronized project doesn't bundle it) + shared scheme `Cosmic Fit.xcscheme` wiring it into the Run action only — simulator trial testing; never ships. `Cosmic FitTests/TrialCopyTests.swift` (4 tests on the duration formatters) is test-only, but the formatter behaviour it locks is part of the copy contract in §F.

---

## Section I — Open questions & unknowns (needs product confirmation or runtime probing)

1. **Is weather output-affecting or display-only?** `WeatherService` is called in the shipped Daily Fit flow (`CosmicFitTabBarController:1248,1364`), but `WeatherFabricFilter` is dead. Determine whether the fetched weather alters `DailyFitPayload` content or only ambient UI/logging — this decides whether weather belongs to the determinism contract.
2. **Natal Chart wheel product intent.** `NatalChartViewController` + `ChartWheelView` are debug-only today. Is a chart screen part of the Android 1:1 scope, or is chart math backend-only?
3. **Which narrative cache generation ships at cutover.** Symlink currently targets base `blueprint_narrative_cache.json` (git-modified); `blueprint_narrative_cache_sg4.json` exists untracked. The SG-4 gate (169-section regen, owner sign-off pending) will decide — Android planning should pin against the post-cutover cache.
4. **StoreKit server-side story.** Client trusts `Transaction.currentEntitlements` only; `app-store-notifications` exists server-side with zero client coupling. Confirm what subscription state (if any) the backend is expected to know for a second platform (migrations 003/006 have subscription tables the iOS client never reads).
5. **Subscription group + price display.** Group defined only in App Store Connect; prices come from `Product`. Savings badge + all trial copy derived at runtime from live store offer objects (formula and exact strings now pinned in §F "Monetization / trial contract").
5a. **Trial verification pending on iOS.** Code complete + unit tests pass, but per the handoff: manual simulator pass with the local `.storekit` config, device sandbox pass, and ASC metadata completion (localizations/review screenshot) are still outstanding — while metadata is flagged, sandbox may return zero products. Android planning should not treat trial behaviour as store-verified yet.
6. **AccentRecencyTracker not engine-namespaced** — intended or latent bug? Affects cross-engine state bleed (only matters for DEBUG presets, but it's an asymmetry in the contract).
7. **Timezone-mix behaviour at midnight** — seed day is UTC; reveal/frozen/recency days are device-local. Confirm this is accepted product behaviour to replicate (users crossing timezones can see edge effects).
8. **Supabase SDK Keychain storage details** (service name / migration behaviour) — SDK-internal; relevant only for understanding session-survival semantics to mirror.
9. **`blueprintDidUpdate` consumers** — declared and posted by `BlueprintStorage`; observer(s) not located in the VC layer this pass. Runtime confirm who listens.
10. **Location usage copy source** — set via `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` in build settings (copy captured in §E), not in the plist file; confirm final App Store copy if it must match on Android.
11. **Ephemeris init timing** — Swiss Ephemeris bootstraps lazily from `AsteroidCalculator` (crash-on-missing-file), VSOP87 degrades silently to Keplerian fallback. Confirm the asteroid path is exercised on every chart calc (Chiron/Lilith/NN appear in `NatalChart`, so likely yes) and decide which failure semantics parity requires.
12. **`SavedChartStorage` does not exist** despite README mentions — `SavedChart` lives only inside `NatalChartManager` (UserDefaults `Chart_<name>`, orphaned methods). Confirm multi-chart save is a non-feature.
13. **First-free-day migration flag semantics** for existing users (`CosmicFit_FirstFreeMigrationDone`) — confirm how a fresh-platform user base should initialize (no migration needed, but the free-first-reveal rule itself is product behaviour).

---

## Section J — Handoff checklist for the planning AI

The next AI (Android planner) must produce — using this map, without re-walking the iOS tree:

- Architecture options and module boundaries (engine core vs shell vs backend client), honouring the Layer A/B/C/D split above.
- Language/runtime strategy for the deterministic engine (port vs shared core), preserving every contract in §F bit-for-bit where user-visible (seeds, SHA256 fingerprints, 21-point vibe budget, recency windows, freeze-before-reveal, envelope math, palette ordering).
- API replacements for each §E item (StoreKit→billing, Keychain→keystore, CoreMotion/CoreImage/CA* equivalents, MapKit autocomplete + timezone resolution, URL scheme, mail, forced-dark theming).
- Asset & data migration plan: fonts, 79 card imagesets, 41 glyphs, intro/onboarding art, TarotCards.json, style-guide JSON symlink strategy, VSOP87 + `seas_18.se1` bundling.
- Backend/client plan for §G: reuse edge functions + tables as-is vs additions (note `clientInstallId` device-grant model and the OTP/implicit-flow assumptions).
- Persistence mapping for §F stores (Documents JSON / Keychain / UserDefaults families, engine-id namespacing, migration-free fresh start).
- Parity test strategy: leverage the inspector as an oracle, golden fixtures (`MariaAshLocked`, palette-grid goldens, production fingerprint), and define same-user/same-day cross-platform payload equivalence checks.
- Resolution plan for each §I open question before implementation lock.
