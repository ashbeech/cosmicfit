# TODO: Cross-Platform Engine Alignment Strategy (Android Port)

> **Status: OPEN DECISION — no approach selected yet.**
> **Decide before:** Android implementation planning locks module boundaries (this decision *is* the module boundary).
> **Written:** 2026-07-12, alongside the iOS Surface Map (Pass 1). Companion docs: `docs/handoff/IAP_TRIAL_HANDOFF_2026-07-12.md` (monetization parity), the Pass 1 surface map (external plan file), root `README.md` §4.
> **Audience:** whoever runs the decision spike + the Android planning AI.

---

## 1. The problem

Sky Forward (Daily Fit) and the Style Guide composer are **client-side, deterministic, and product-critical**. They cannot move server-side (offline generation, per-day freezing on device, App Review posture), so "keep it on the backend" is not the alignment mechanism. Once Android exists, any iOS engine change — e.g. a chart-input calibration retune — must land on Android with **zero behavioural drift**, or the same user sees different tarot cards / palettes / sliders per platform on the same day.

Drift can enter through four distinct vectors, which need different treatments:

| # | Vector | Today's form | Drift risk |
|---|---|---|---|
| 1 | **Calibration** | `DailyFitCalibration` struct literals in `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` — **code, not data** | **Highest.** A calibration change is currently a Swift edit; nothing forces a matching Kotlin edit |
| 2 | **Algorithms** | Seed derivation (`DailySeedGenerator`: SHA256 first-8-hex + LCG), 21-point vibe budget, recency/cooldown rules, `PersonalScaleEnvelope` math, narrative plan selection, ColourEngineV4, palette-grid ordering (CIE-Lab NN + 2-opt) | High — subtle numeric/ordering divergence |
| 3 | **Data** | `TarotCards.json`, `data/style_guide/*.json` (already canonicalised + symlinked), VSOP87 files, `seas_18.se1` | Low — already shared-by-file; just bundle the same bytes |
| 4 | **Conventions** | UTC seed-day vs device-local reveal/frozen/recency days; UserDefaults key namespacing by engine id; freeze-before-reveal invariant | Medium — easy to "fix" accidentally on Android |

Also cross-platform but non-engine (same alignment need, smaller surface): entitlement gating rules + trial copy (see IAP handoff §1–2 — copy strings and the fail-closed rule are explicitly shared contracts), promo/comp grant logic, sync payload shapes.

---

## 2. Options

### Option A — Single shared engine implementation (structural alignment)

Rewrite the engine once in a language both platforms consume. Drift becomes impossible rather than detected.

**A1. Kotlin Multiplatform (KMP).** Engine as a KMP module; Android consumes it natively; iOS consumes a generated XCFramework.
- Work: full Swift→Kotlin port of `InterpretationEngine/` + `Core/Calculations/` (~60+ files incl. ColourEngineV4's 20); re-plumb the iOS app to call the framework; port or re-host the ~70-suite test estate; rework the inspector (currently compiles Swift sources via symlink — it would need to consume the KMP artifact or be retired); C interop for Swiss Ephemeris from Kotlin/Native on iOS **and** JNI/NDK on Android.
- Pros: one engine forever; Android-native ergonomics; KMP is mature for pure-logic modules.
- Cons: **iOS ships a rewritten engine** — the highest-risk path for the existing product; invalidates locked goldens until re-baselined; Kotlin/Native↔Swift bridging friction for value types; two builds must still bundle identical data files.
- Effort shape: large up-front (engine port + iOS migration + re-baseline), small steady-state.

**A2. Rust (or C++) core with thin bindings.** Same shape as A1 with a systems language; both platforms bind.
- Pros: best numeric determinism story (no JVM float/locale surprises); Swiss Ephemeris is C already — natural fit.
- Cons: everything in A1's cons **plus** a third language nobody on the project currently writes, FFI surface for rich types (`DailyFitPayload` is deep), slowest iteration for calibration tuning.
- Effort shape: largest. Only worth it if we later want web/server reuse of the engine too.

**A3. Swift on Android (compile the existing engine).** The Swift project officially supports Android (Android workgroup + SDK). The engine is *exactly* the profile that cross-compiles well: pure Foundation + CryptoKit + one C library, zero UIKit (proven by the macOS inspector).
- Work: spike the toolchain; swap `CryptoKit` → `swift-crypto` (API-compatible for SHA256); verify Foundation-on-Android behaviour for the locale/calendar/timezone-sensitive code (`en_GB_POSIX` / `en_US_POSIX` formatters, `Calendar.current` — vector 4 above); build `CSwissEphemeris` for NDK ABIs; define a JNI/bridging layer (likely a small C-callable Swift surface returning JSON payloads); CI for the cross-build.
- Pros: **the existing, test-hardened Swift engine becomes the shared core; iOS changes nothing**; every existing golden/fingerprint test keeps guarding both platforms; calibration edits stay single-source automatically.
- Cons: toolchain maturity risk (debugging, binary size, app-store review of Swift runtime on Android is fine but tooling is younger); Android team must be able to at least read Swift; the UserDefaults-backed recency trackers live *inside* the engine tree — they need a storage abstraction seam (they already accept an injected `UserDefaults`; generalise that protocol) so Android can back them with its own storage.
- Effort shape: **small spike, medium integration, near-zero steady-state.** Highest payoff if the spike passes.

### Option B — Dual implementation + automated parity contract (detected alignment)

Keep Swift canonical; port the engine to Kotlin by hand; make drift mechanically impossible to miss. The repo already exercises every ingredient of this pattern:

- **Fingerprint gate.** `DailyFitEngineRegistry.fingerprint(for:)` = SHA256 of a canonical `%.6f` serialization of all calibration weights; `ProductionFingerprintGuard_Tests` locks it on iOS. Promote it: commit the expected fingerprint to a shared spec file; **both** platforms' CI recompute and assert it. A calibration change on one platform reds the other's CI until matched.
- **Calibration-as-data.** `DailyFitCalibration` is fully value-typed/`Equatable` → serialize to versioned `engine-spec/calibration/production.json` consumed (or codegen'd) by both platforms. A retune becomes a one-place data edit; most "engine changes" stop needing dual code edits at all.
- **Parity corpus.** Precedent already in-repo: SG-4 does Python↔Swift parity via a generated fixture (`tools/sg4_parity_fixture.py` → `data/style_guide/sg4_parity_fixture.json` → `SG4ValidatorParityTests` byte-match). Scale up: canonical Swift engine (the **inspector** is a ready oracle — same symlinked sources, deterministic `POST /api/inspect`) generates a committed corpus of full `DailyFitPayload` + `CosmicBlueprint` JSON. Cohort should come from the existing production audit harness population (223 users × 60 days machinery in `tools/production_audit_harness.py`), not hand-picked cases — coverage of the tails is the whole point. Android CI replays the corpus (fixed profiles/dates/recency state) and field-matches; iOS CI regenerates + diffs, so any output-changing edit forces a visible, reviewable corpus bump — that bump is the event Android tracks.
- **Contract versioning.** Android pins to `(engine marketing version, calibration fingerprint, corpus version)` — never to "whatever iOS main is."
- Work: full Kotlin engine port (same size as A1's port, minus iOS migration), plus the spec/corpus/CI harness (~small, mostly repackaging existing tools), plus permanent dual maintenance of algorithm code.
- Pros: shipped iOS app untouched; each platform fully native; failure mode is a red CI, not a silent divergence.
- Cons: **not faultless** — dual implementations can drift in paths the corpus doesn't exercise; every algorithm change is written twice forever; floating-point/locale parity across Swift↔JVM needs explicit care (define tolerances or integer-quantized comparisons per field).
- Effort shape: medium up-front, **permanent tax** on every engine change.

### Non-options (recorded so they aren't re-litigated)
- **Server-side engine:** breaks offline generation + on-device freezing; not pursued.
- **"Be careful" / manual sync:** the failure mode is silent user-visible divergence; rejected.

---

## 3. Groundwork to do regardless of choice (no-regret, start anytime)

1. **Extract calibration to data** (`engine-spec/` or `data/engine/`), with the canonical serialization + fingerprint as the schema contract. Valuable for iOS alone (tuning without recompiling registry literals is already a wish — cf. inspector workflow).
2. **Commit the expected production fingerprint as a spec artifact** (today it lives inside test expectations).
3. **Generate and commit a v1 parity corpus** from the inspector (needed as acceptance tests for *any* Android engine, shared or ported).
4. **Write down vector-4 conventions as a spec** (seed = UTC day; reveal/frozen/recency = device-local day; key formats; freeze-before-reveal) — currently implicit in code; Pass 1 surface map §F has the extraction.
5. **Storage seam for recency trackers**: generalise the injected-`UserDefaults` pattern into a protocol so the engine core is storage-agnostic (required by A3, helpful for A1/B).

---

## 4. Decision spike plan (~1 week, do first)

**Spike A3 (Swift-on-Android)** — it's the cheapest to test and the biggest payoff:
- [ ] Cross-compile `InterpretationEngine/` + `Core/Calculations/` + `swift-crypto` for arm64 Android; build `CSwissEphemeris` for NDK.
- [ ] Run `DailySeedGenerator` + one full `DailyFitPipeline.generate` on-device/emulator against 5 corpus rows; byte-compare payload JSON vs inspector output.
- [ ] Specifically verify locale/calendar formatters (`en_GB_POSIX`, `en_US_POSIX`, `Calendar.current` with device tz) behave identically on Android Foundation.
- [ ] Measure: binary/runtime size, build complexity, debuggability.
- **Pass ⇒ Option A3.** Fail/marginal ⇒ score A1 vs B on: team Kotlin/Swift capability, appetite for iOS engine migration risk (A1) vs permanent dual-maintenance tax (B), calibration-change frequency (high frequency favours A*, or at minimum groundwork #1).

## 5. Decision criteria checklist

- [ ] Same user + same day + same recency state ⇒ identical payload on both platforms (hard requirement, all options).
- [ ] A calibration retune reaches both platforms via **one** change, or fails CI loudly on the laggard.
- [ ] Existing iOS test estate (goldens, `MariaAshLocked`, fingerprint guard) keeps its guarding power.
- [ ] Inspector (or successor) remains a usable oracle/tuning surface.
- [ ] Engine iteration speed for calibration work is not materially worse than today.
- [ ] No shipped-iOS regression risk during the transition (weights heavily against A1/A2).

## 6. Open questions to resolve during the decision

- Who owns engine changes post-Android (one team both platforms, or per-platform)? Dual-maintenance (B) is only viable with a single owning team.
- Float determinism policy for B: exact byte-match (quantize all Doubles at defined precision, as fingerprints already do with `%.6f`) vs per-field tolerances.
- Does the parity corpus include recency-state evolution (multi-day sequences with tracker state carried forward), not just stateless single days? (It must — tarot cooldown/variant rotation are where drift would hide.)
- Repo strategy: monorepo with `android/` + shared `engine-spec/` (recommended default; symlink discipline already exists) vs separate repo with a published spec artifact.
- Non-engine shared surfaces to fold into the same spec mechanism: trial/paywall copy strings (IAP handoff §2), entitlement rules, edge-function payload shapes.
