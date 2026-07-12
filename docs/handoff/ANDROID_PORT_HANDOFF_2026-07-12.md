# Handoff: Android Port — Full App Map & Parity Requirements (2026-07-12)

Audience: the AI developer executing the Android port. This is the port-specific companion to the root `README.md` (the canonical iOS architecture handoff). Read the root README first; this doc tells you what to port, what to skip, what the parity oracles are, and what only the owner can provide.

Companion docs (read in this order):
- `../../README.md` — canonical app architecture, engines, data contracts, tests (§4, §5, §9 are essential).
- `../android_port/IOS_SURFACE_MAP_PASS1.md` — **the detailed, source-verified iOS inventory (Pass 1)**: every screen, view, service, persistence store, platform API, and behaviour contract, classified into layers A (1:1 parity) / B (remap) / C (shared backend) / D (dev-only). It also lists verified places where the root README is stale (e.g. `AuthGateViewController` is live, not legacy; `FeedbackService` + `send-feedback` exist; migrations run 001–011; CoreMotion drives the tarot holographic sheen). **Where this doc and the surface map disagree on inventory detail, the surface map wins.**
- `../android_port/TODO_shared_engine_strategy.md` — **OPEN DECISION** on how the deterministic engine is shared/aligned across platforms (A1 KMP / A2 Rust / A3 Swift-on-Android / B dual implementation + parity contract). This decision *is* the module boundary and must be made before implementation planning locks in. Recommended first step: the ~1-week A3 spike described there.
- `IAP_TRIAL_HANDOFF_2026-07-12.md` — monetization model, exact paywall/trial copy, Play Billing mapping, edge cases. Product behaviour there is normative for Android.
- `../README.md` (docs index) — which docs are current vs historical. `docs/handoff/` is normally "historical"; this file and the IAP handoff are current exceptions, as is `docs/android_port/`.

## 1. Source of truth

- **Branch:** `refactor/style-guide` (contains the Style Guide overhaul and all trial/IAP work; `main` is ~10 commits behind and must NOT be used).
- **Engine strategy is undecided.** Sections below describe *what* must behave identically, not *how* the engine code is shared — that's `../android_port/TODO_shared_engine_strategy.md`. Do not assume a hand-ported Kotlin engine until the spike/decision says so. The no-regret groundwork in that doc's §3 (calibration→data, committed fingerprint spec, parity corpus v1, conventions spec, storage seam) is safe to start regardless.
- **Narrative cache cutover pending:** the shipped bundle loads `blueprint_narrative_cache.json`. An SG-4 regenerated cache (`data/style_guide/blueprint_narrative_cache_sg4.json`) exists but has not been cut over (169-section regen awaiting owner approval). Build the Android data-loading layer so the cache file is swappable; confirm with the owner which cache is live before release.
- The app is **fully local/deterministic for all astrology + content generation** — no server round-trips except auth, profile/Style Guide sync, promo codes, and feedback. Backend (Supabase) is shared between platforms as-is; do not fork it.

## 2. What must be ported (behaviour-identical)

### 2.1 Chart computation (Core/Calculations, Core/Utilities)
Hybrid ephemeris, all on-device:
- **Swiss Ephemeris** (via SPM wrapper on iOS): Sun, Moon, Ascendant/MC/Vertex, Placidus house cusps, lunar nodes, Chiron/asteroids. Data file `Cosmic Fit/Resources/seas_18.se1` ships in the bundle. Android: use the Swiss Ephemeris Java port (`swisseph`) or NDK build of the C library; bundle the same `seas_18.se1`. Note Swiss Ephemeris dual licensing (AGPL vs commercial) — same terms the iOS app is subject to; flag to owner if the chosen distribution requires a licence decision.
- **VSOP87D** for Mercury–Neptune: `Core/Utilities/VSOP87Parser.swift` parses the 8 text files in `Resources/VSOP87Data/`. Port the parser; bundle the same files byte-identical.
- Chart assembly: `NatalChartCalculator.swift` (~1.4k LOC) — natal, secondary-progressed (solar arc), transits, aspects. Plus `AstronomicalCalculator`, `JulianDateCalculator`, `AsteroidCalculator`, `CoordinateTransformations`, `MoonPhaseInterpreter`.
- **Numerical parity is mandatory**: longitudes/house cusps must match iOS to the precision the downstream engines are sensitive to. Validate with the fixtures in §4 before building anything on top.

### 2.2 Deterministic engines (InterpretationEngine/ — the hard 80%)
~28k LOC of deterministic Swift. *How* this reaches Android (shared binary vs Kotlin re-implementation) is the open decision in `../android_port/TODO_shared_engine_strategy.md`; whichever path is chosen, do not "improve" logic — output equality against the oracles in §4 is the acceptance test.
- **Style Guide (CosmicBlueprint)**: `BlueprintTokenGenerator` → `DeterministicResolver` + `NarrativeCacheLoader`/`NarrativeTemplateRenderer` → `BlueprintComposer`; validation via `StyleGuideCoherenceValidator` (rules in `style_guide_rules.json`, tables in `ranked_domain_tables.json`). Generated once per user, persisted, synced.
- **ColourEngineV4** (23 files, ~4.3k LOC): chart → palette family/cluster → template + chart-derived accents → LCH normalisation → `PaletteSection`. All palette/token tables are **Swift code, not JSON** — port the tables exactly (`PaletteLibrary`, `FamilyProfiles`, `SignArchetypes`, `DriverWeights`, `Thresholds`, etc.).
- **Daily Fit (Sky Forward v1.0.1)**: `DailyFitPipeline` (sole entry point) → `DailyEnergyEngine` snapshot → `DailyNarrativeSelector` plan → `BlueprintLensEngine.generatePayloadFromPlan` (~2.5k LOC, largest file) → `PersonalScaleEnvelope`. Preset truth: `DailyFitEngineRegistry.swift` — Release uses `production` → `.stage1Experimental`. Gate logic on mode, never on engine-id string. Keep the legacy presets' code paths only if you port the regression tests that need them; otherwise port `production` behaviour and document the omission.
- **Tarot subsystem**: `TarotCard(+Scoring/Validator)`, recency/rotation trackers (`TarotRecencyTracker`, `TarotVariantRotationTracker`, `AccentRecencyTracker`, `ColourRecencyTracker`, `VisibleEssenceRecencyTracker`) — state namespaced by engine id; sequence-over-time behaviour must match.
- **Key data contracts** (README §9): VibeBreakdown 6 energies summing to exactly 21; DerivedAxes 1–10; `DailyFitPayload`; `CosmicBlueprint` (versioned V4–V4.4 fields, backward-compatible decoding).
- **Determinism trap**: `DailySeedGenerator` seeds from profileHash + date. Any hashing/PRNG/float behaviour must be reimplemented explicitly — do not rely on platform `hashCode()`/`Random` defaults.

### 2.3 Data files to ship (bundle in the Android app)
| File | Size | Note |
|---|---|---|
| `Resources/TarotCards.json` | 310 KB | real file |
| `data/style_guide/astrological_style_dataset.json` | 580 KB | iOS bundles via symlink from `Resources/` |
| `data/style_guide/blueprint_narrative_cache.json` | 5.65 MB | see SG-4 cutover note §1 |
| `data/style_guide/ranked_domain_tables.json` | 37 KB | |
| `data/style_guide/style_guide_rules.json` | 11 KB | |
| `Resources/VSOP87Data/VSOP87D.*` (8 files) | ~4.2 MB | |
| `Resources/seas_18.se1` | 223 KB | |
| `Resources/Fonts/` (23 TTFs) | ~1.9 MB | see §2.5 |
| `Resources/Assets.xcassets` | — | 78 tarot card PNGs, glyphs (SVG/PNG), onboarding/intro art, app icon |

Everything else under `data/`, `docs/`, `tools/`, `scripts/`, `inspector/`, `_archive/` is dev tooling — never bundle.

### 2.4 Screens & flows (UI/ViewControllers — 22 screens)
Programmatic UIKit, portrait-only, **forced dark mode**. Replicate flows and visual design:
- Launch routing (`AppDelegate.performLaunchRouting`): animated splash → first-run welcome intro → onboarding form (multi-page birth data with location autocomplete) → OTP auth; existing user → main shell; complete-profile-signed-out → signed-out landing; onboarding-pending-auth resumes at the auth page.
- Main shell: custom 2-tab bar (Daily Fit, Style Guide) + slide-out menu (Account/Profile, FAQs, Help email, legal). Natal chart & interpretation screens reached from menu/profile flows.
- Daily Fit screen: reveal state, torn-paper gating, tarot card, daily palette, sliders (vibrancy/contrast/metal tone), 14-category essence radar, silhouette bars, textures/pattern, transits, lunar phase. Daily refresh on app-active/day-change.
- Style Guide hub + section detail (gated), paywall (`PurchaseViewController` — see IAP handoff), profile edit, account deletion, promo-code entry, FAQ, legal docs (content hardcoded in `Legal/`).
- Theme: `CosmicFitTheme.swift`. **Font-naming trap**: `Typography.DMSerifTextFont(...)` actually resolves to **PT Serif** (main serif for titles/body); genuine DM Serif Text is only the display face (`dmSerifTextDisplayFont`); DM Sans is the sans (6 weights actually used). Map fonts by resolved face, not by iOS method name.

### 2.5 Platform integrations (iOS → Android mapping)
| iOS | Android |
|---|---|
| StoreKit 2, products `com.cosmicfit.full.monthly` / `com.cosmicfit.full.annual` | Play Billing Library, one subscription, two base plans (P1M / P1Y) + free P1W offer on the annual base plan, eligibility "new customer acquisition" — see IAP handoff §4 |
| Keychain: comp grant (`com.cosmicfit.comp-access`), install identity (`com.cosmicfit.install-identity`, survives reinstall) | Keystore-backed encrypted storage; note Android cannot guarantee reinstall survival — document the behavioural difference, keep server-side `check-comp-access` restore path |
| Supabase Swift SDK (auth `flowType: .implicit`, PostgREST upserts) + raw URLSession to `/functions/v1/*` | supabase-kt; same edge-function call pattern (headers: `apikey` + `Authorization: Bearer <publishable or session token>`); same error shape `{ error: { code, message } }` |
| Deep link `cosmicfit://login?email=&code=` (auth) | Intent filter for the same scheme; Supabase redirect URL must be registered |
| MapKit `MKLocalSearchCompleter` birth-location autocomplete + `CLGeocoder` | Android `Geocoder` first (free); Google Places API only if quality is insufficient (needs owner-provisioned key) |
| CoreLocation when-in-use (weather features) | Fused Location, `ACCESS_COARSE_LOCATION` sufficient |
| Weather: Open-Meteo `api.open-meteo.com` (keyless) | same |
| UserDefaults / JSON files in Documents (`cosmic_fit_profile.json`, `cosmic_fit_blueprint.json`, frozen Daily Fit payloads) | SharedPreferences/DataStore + app-files JSON; keep the same JSON schemas so Supabase sync payloads are cross-platform compatible |
| `NSAllowsArbitraryLoads = true` | do **not** replicate; all endpoints are HTTPS |
| No push, no analytics, no crash reporting, no background modes | same — do not add any |

Backend config (publishable, committed in `Cosmic Fit/Config/Prod.xcconfig`): `SUPABASE_URL = https://fkzxcxycyvzutbvgjzwu.supabase.co`, `SUPABASE_PUBLISHABLE_KEY = sb_publishable_g7uG0qHOGeZqC8iZD203rg_dwRacBb9`. Never embed any server-side secret (service role, Resend, Gemini) in the app.

## 3. What NOT to port
The root README §7 lists confirmed dead/legacy iOS code (e.g. `AstrologicalInterpreter`, `InterpretationTextLibrary` prose tables, `ParagraphAssembler` remnants, placeholder `CosmicFitInterpretationEngine.generateStyleGuideInterpretation`, `WeatherFabricFilter`, `TransitWeightCalculator`, various dead VC properties). **Do not port anything on that list.** When in doubt whether a file is live, trace call sites from `AppDelegate`, `DailyFitPipeline`, `BlueprintComposer`, and the ViewControllers.

## 4. Parity oracles (how "works like iOS from the first build" is proven)
The iOS repo already contains the cross-language verification kit. Android acceptance = these all pass against Android-computed output:

1. **Golden fixtures** — `docs/fixtures/golden_cases.json` (expert-reviewed Daily Fit goldens), `MariaAshLocked_Tests` fixtures (locked full outputs for canonical users "ash"/"maria"), `docs/fixtures/ash_today_tomorrow_combined.txt`, `docs/style_guide/golden/` (16 golden charts), `data/style_guide/sg4_parity_fixture.json` (validator parity — already proven Swift↔Python, extend to Kotlin).
2. **Production fingerprint** — `ProductionFingerprintGuard_Tests` hardcodes a fingerprint of production calibration; replicate the fingerprint computation and assert equality.
3. **The Inspector as live oracle** — `inspector/` (macOS, `./run-inspector.sh`, http://127.0.0.1:7777) runs the identical engine via HTTP (`POST /api/inspect`). Build an Android-side harness that feeds the same birth data/date and diffs full payload JSON against inspector output. This is the primary tool for chasing numeric drift.
4. **Contract tests to port** — at minimum: VibeBreakdown 21-budget, zodiac math (`SemanticTokenGenerator_ZodiacMath_Tests`), ColourEngineV4 unit suites, recency/rotation behaviour, frozen-payload storage semantics, `TrialCopyTests` equivalents for Play `pricingPhases` (ISO-8601 `P1W` → "7 days"/"7-day", non-1-week fallback).
5. **Copy parity** — every user-facing string in the IAP handoff §2 must match exactly.

## 5. Owner-provided prerequisites (blockers to surface early, not solve)
1. **Play Console**: app created, subscription + two base plans + free-trial offer configured per IAP handoff §4; licence-tester accounts for sandbox.
2. **Play billing server events**: an RTDN (Real-Time Developer Notifications) equivalent of the Apple-only `app-store-notifications` edge function (new Supabase function + Pub/Sub config); `subscription_status` is keyed by Apple `original_transaction_id` and needs a schema decision for Play purchase tokens. Owner decides scope (can ship v1 without server-side ledger since entitlement is client+store, matching iOS).
3. **Signing**: upload keystore / Play App Signing.
4. **Supabase**: redirect URL for `cosmicfit://login` on Android; nothing else should need changes.
5. **Engine-strategy sign-off** after the decision spike (`../android_port/TODO_shared_engine_strategy.md` §4–5).
6. **Swiss Ephemeris licence** decision if AGPL is unacceptable.
7. **SG-4 cache cutover** decision (§1).
8. Google Places API key — only if `Geocoder` autocomplete quality proves insufficient.

## 6. Definition of done
- All §4 oracles pass on Android (unit + fixture parity + inspector diff on ≥ the 16 golden charts across ≥ 30 consecutive days each).
- Full manual flow pass on device: first-run → onboarding → OTP signup → Style Guide generation → Daily Fit reveal (free first day) → gating next day → paywall trial + non-trial states → purchase (sandbox) → unlock mid-session → restore → promo code redeem/restore-after-reinstall → profile edit → account deletion → signed-out landing → re-auth.
- IAP edge cases from IAP handoff §5 verified in Play sandbox (pending purchase, cancel, restore, trial→paid via accelerated renewal, ineligible fallback).
- No secrets in the APK; ProGuard/R8 config doesn't break Codable-equivalent serialization; release build tested, not just debug.
