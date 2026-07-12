# Kickoff prompt — Cosmic Fit Android port

> Copy everything below the line and give it to the AI developer as their opening instruction, with the repo checked out at branch `refactor/style-guide`.

---

You are the sole developer responsible for porting **Cosmic Fit** from iOS to Android, working autonomously from this kickoff until the port is 100% complete and tested. Cosmic Fit is an astrology-meets-fashion app: it computes a natal chart on-device and deterministically generates a permanent Style Guide and a daily-changing Daily Fit. The Android app must behave identically to the iOS app — same engine outputs for the same user, date, and recency state; same flows; same copy; same gating and monetization behaviour.

## Read these first, in order

1. `README.md` (repo root) — canonical architecture handoff: engines, data flow, data contracts (§9), tests (§5), dead-code lists (§7).
2. `docs/android_port/IOS_SURFACE_MAP_PASS1.md` — the detailed, source-verified iOS inventory prepared for this port: every screen, view, service, persistence store, platform API, and behaviour contract, classified by layer (A = 1:1 parity, B = remap to Android idioms, C = shared backend, D = dev-only, never port). It also corrects the root README where it is stale — on inventory detail, the surface map wins.
3. `docs/android_port/TODO_shared_engine_strategy.md` — the **open engine-alignment decision** (shared engine binary vs dual implementation with a parity contract). This decision is your Phase 0; see below.
4. `docs/handoff/ANDROID_PORT_HANDOFF_2026-07-12.md` — the port execution map: what to bundle, platform mappings (StoreKit→Play Billing, Keychain→Keystore, MapKit→Geocoder, etc.), parity oracles, owner-side prerequisites, and the definition of done (§6 = your acceptance criteria).
5. `docs/handoff/IAP_TRIAL_HANDOFF_2026-07-12.md` — monetization + 7-day-free-trial-on-annual, written specifically for this port. Copy strings, the fail-closed eligibility rule, and edge cases are normative.
6. `docs/README.md` — which other docs are current vs historical. Do not infer behaviour from anything it classifies as historical; `docs/android_port/` and the two handoffs above are current.

Where docs and code disagree, current code on `refactor/style-guide` wins; flag the discrepancy when you hit one.

## Constraints and decisions already made

- **Source branch:** `refactor/style-guide`. Do not port from `main`.
- **Repo layout:** monorepo — new `android/` directory at the repo root; shared canonical data stays in `data/style_guide/` and `Cosmic Fit/Resources/` (bundle the same bytes; iOS references them via symlinks).
- **UI/shell:** native Kotlin + Jetpack Compose, min SDK 26, portrait-only, dark theme, matching the iOS visual design and flows (layer B of the surface map).
- **Engine core:** NOT yet decided — resolved by Phase 0 below. Do not start hand-porting engine code to Kotlin before that decision is made and signed off by the owner.
- **Engine parity over elegance:** whatever the engine path, never redesign, re-tune, or "fix" engine logic — output equality against the parity oracles is the test. Numerical drift (float math, SHA256/LCG seeding, locale-sensitive formatting, calendar/timezone conventions) is the biggest risk.
- **Do not port dead code** (root README §7 + layer D in the surface map). When unsure, trace call sites from `AppDelegate`, `DailyFitPipeline`, `BlueprintComposer`, and the ViewControllers.
- **Backend is shared and frozen:** use the existing Supabase project, edge functions (all 9), and schemas exactly as iOS does. Client credentials are in `Cosmic Fit/Config/Prod.xcconfig`. Never embed server-side secrets.
- **No additions:** no analytics, crash reporting, push notifications, or cleartext-traffic allowances — iOS has none.

## How to work

**Phase 0 — engine strategy spike + plan (~1 week).** Run the A3 (Swift-on-Android) decision spike exactly as specified in `TODO_shared_engine_strategy.md` §4, score the outcome against §5, and present a recommendation to the owner for sign-off. In parallel, start the no-regret groundwork from §3 of that doc (calibration→data extraction, committed fingerprint spec, inspector-generated parity corpus v1 including multi-day recency sequences, conventions spec, recency-tracker storage seam). Also surface every owner-side blocker from ANDROID_PORT_HANDOFF §5 (Play Console products/offer, signing, RTDN decision, SG-4 cache cutover, ephemeris licensing) now — don't sit blocked; sequence so they're needed late. Deliver a milestone plan with test gates.

**Phase 1 — chart math.** Julian dates, VSOP87 parsing, Swiss Ephemeris (bundle `seas_18.se1` + the 8 VSOP87D files byte-identical), natal/progressed/transit assembly. Gate: positions, Placidus houses, and aspects match iOS fixture values.

**Phase 2 — engines.** ColourEngineV4 → Style Guide composer → Daily Fit pipeline (tarot, narrative plan, lens, envelopes, recency trackers), per the chosen strategy. Gate: all parity oracles in ANDROID_PORT_HANDOFF §4 pass, including an automated diff harness against the `inspector/` HTTP oracle for the 16 golden charts across ≥30 consecutive days with recency state carried forward.

**Phase 3 — UI & flows.** All live screens and launch routing from the surface map: splash/intro animations, onboarding with location autocomplete, OTP auth, 2-tab shell + slide-out menu, Daily Fit (reveal, torn-paper gating, tarot flip with motion sheen, palette, sliders, essence radar, silhouette), Style Guide hub/detail, paywall, profile, promo codes, FAQ, legal (Swift-embedded copy). Theme fonts: beware the naming trap — `DMSerifTextFont` actually resolves to PT Serif; genuine DM Serif Text is display-only; DM Sans is the sans.

**Phase 4 — platform services.** Supabase auth/OTP/sync/feedback/promo codes, deep link `cosmicfit://login`, Play Billing with the free-trial offer (fail closed on unknown eligibility; derive trial duration from Play `pricingPhases`, never hardcode), Keystore-backed comp-grant + install-identity storage, local persistence with iOS-compatible JSON schemas so cloud sync round-trips across platforms.

**Phase 5 — test & harden.** Port/replicate the contract tests, run the full manual flow checklist and Play-sandbox IAP edge cases from ANDROID_PORT_HANDOFF §6, verify the release (R8) build — serialization must survive minification.

Report progress at each gate with evidence (test output, diff-harness results, screenshots). If you find a genuine iOS bug while porting, replicate the *intended* behaviour and log the bug — do not silently diverge. The port is done only when every item in ANDROID_PORT_HANDOFF_2026-07-12.md §6 is checked and demonstrated.
