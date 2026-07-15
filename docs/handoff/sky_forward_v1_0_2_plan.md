# Plan — Sky Forward v1.0.1 → v1.0.2 Calibration Refactor (Daily Fit engine)

> **Status:** Implementation plan, pending audit. Not yet approved for execution.
> **Author:** Claude (planning pass, 2026-07-13)
> **Scope:** Fix audit findings F1, F2, F3, F5, F6, F7 (F4 is "working" — preserved as the reference model).
> **Source audit:** [`docs/daily_fit_calibration_audit_2026-07-11.md`](../daily_fit_calibration_audit_2026-07-11.md)
> **Companion doc:** `docs/handoff/SKY_FORWARD_V1_0_2_KICKOFF_PROMPT.md` (self-contained kickoff for the implementing dev — generated separately).

### Revision log
- **rev 2 (2026-07-13, post audit round 1):** Fixed all three blockers and both decisions from the first review.
  - **B1** — fidelity gates (a) and (d) given disjoint measurement bases (off-syzygy vs on-syzygy); nudge order rewritten so `skyVibeWeights.lunar` and `k` map to different gates and never loop. See "Two axes…" note + Phase 6 + nudge order.
  - **B2** — supermoon distance series made ≥5 terms (**required, not optional**); documented that leading-term-only fires zero supermoons; threshold now satisfiable; added as a separate `calculateMoonDistance` (zero blast radius).
  - **B3** — cache invalidation promoted from "risk" to a **Phase-7 blocking gate** with a Phase-0 trace and a required proof test; remedy A (fingerprint-in-key) vs B (id-bump).
  - **D1** — target mix ratified **lunar-dominant 0.60/0.25/0.15** (was an unratified transit-forward 0.45/0.40); gate (a) now targets ~0.60 off-syzygy.
  - **D2** — `LunarEventDetector` **overrides the phase label** near syzygy (F2 label half); gate (b) reaches ≥90% via the labelled path.
  - Yellow flags folded in: separate `calculateMoonDistance` (blast radius), Phase 3+4 joint-validation note, gate (b) label-path dependency, new-moon boost confirmed intended.
- **rev 1 (2026-07-13):** initial plan.

## Context

An engineering audit ([`docs/daily_fit_calibration_audit_2026-07-11.md`](../daily_fit_calibration_audit_2026-07-11.md)) proved that the shipped Daily Fit engine (**Sky Forward v1.0.1**) runs proportions nobody designed: the daily *vibe* is **94% transits / 4.6% lunar** against a nominal intent of 25% / 60%, because in-orb transits accumulate un-normalised (41–83/day) while the moon adds a fixed step vector. Half of all full moons are never labelled, the lunar vibe is a step function with only 3 distinct outputs per cycle, and seeded jitter (±0.40) is louder than the full-moon signal. The axis path already handles the moon correctly (continuous `fullMoonProximity`) and is the reference model.

This plan produces v1.0.2, fixing findings **F1, F2, F3, F5, F6, F7** (F4 is "working" — preserved as the model). The goal: make nominal weights real, make the moon audible and legible (including named eclipse/supermoon events), cut jitter below the signal floor, and fix the evidence layer — while keeping **v1.0.1 fully recoverable** (git tag + file-snapshot backup + in-code selectable preset).

### Findings addressed (from the audit §3)
| Finding | Severity | Summary | Phase |
|---|---|---|---|
| **F1** | High | Moon's vibe influence is a step function that barely steps (3 distinct vibes/cycle) | 3 |
| **F2** | High | ~½ of full moons missed outright (6° bucket vs ~12.2°/day elongation) | 3 + 5 |
| **F3** | High | Full-moon days indistinguishable from ordinary churn in the vibe | 3 |
| F4 | Positive | Axes path treats moon correctly (continuous) — **preserved as reference model, not changed** | — |
| **F5** | Med-high | Random jitter (±0.40) louder than the moon; minors/slow planets undiscounted in vibe | 4 |
| **F6** | Medium | Daily variation real but provenance is churn + noise, not "the moon waxed" | 4 (follows from normalisation) |
| **F7** | Medium/docs | Docs + `AstrologicalSoundness_Tests` describe a different engine; `golden_cases.json` missing → goldens silently inert | 6 |

### Decisions locked with the product owner (2026-07-13)
1. **Rollback = in-code dual-mode.** New algorithm behind a NEW engine `mode`; v1.0.1's calibration *and* algorithm retained as a selectable preset. Plus git tag + file backups. Triple rollback.
2. **Plan prescribes fixed starting weights, ratified as lunar-dominant per audit intent** — seed **lunar 0.60 / transits 0.25 / currentSun 0.15**. Fidelity gates are the acceptance bar; a documented nudge order handles gate misses. The target is a lunar-*led* daily read (moon is the lead signal; transits texture), matching the audit's stated design intent.
3. **Full validation ladder before cutover** (unit → 12×60 → 216×60 → 223×60), all freshness + new fidelity gates green before production flips.
4. **Eclipses + supermoons in scope** as first-class named events (void-of-course still deferred).
5. **The date-based `LunarEventDetector` overrides the user-facing phase label near syzygy** (D2) — a true full moon is always named "Full Moon", never mislabelled "Waning Gibbous". This is the second half of the F2 fix (the label half; the vibe-peak half is Phase 3).

### Two axes the significance amplification runs on — read before Phase 3/6
The design deliberately does **two opposing things** and gates each on a **different measurement basis** (this resolves the apparent contradiction between "swelling on full moons" and "share within ±0.1 of nominal"):
- **Baseline mix** (non-syzygy / cycle-average): lunar share should sit near the configured nominal (~0.60). This is what fidelity gate **(a)** measures.
- **Syzygy swell** (full/new days): lunar weight is amplified by `1 + k·syzygyProximity`, so the moon spikes above baseline. This is what fidelity gate **(d)** measures (full-moon vs baseline delta separable).
- Gate (a) is measured on **non-syzygy days only** (or cycle-averaged with syzygy days excluded); gate (d) is measured on **syzygy days**. The nudge order (below) is written so the two coefficients (`skyVibeWeights.lunar` and `k`) are tuned against **different gates** and never fight in a loop.

---

## Reference map (verified against source, 2026-07-13)

**Engine (one source of truth; the inspector package symlinks the app engine dir):**

| Concern | Symbol | Location |
|---|---|---|
| Vibe transit accumulate (no norm/damp/top-N) | `accumulateTransitContribution` | [DailyEnergyEngine.swift:244](../../Cosmic%20Fit/InterpretationEngine/DailyEnergyEngine.swift#L244) |
| Lunar 8-bucket step lookup | `lunarPhaseEnergies` / `accumulateLunarContribution` | DailyEnergyEngine.swift:178 / :295 |
| Vibe sky mix (hardcoded, **outside** the fingerprint) | `stage1SkySourceWeights` = transits 0.25 / lunar 0.60 / sun 0.15 | DailyEnergyEngine.swift:453 |
| Weighted-sum orchestrator | `accumulateWeightedVibeScores` | DailyEnergyEngine.swift:384 |
| 21-point normalisation | `normaliseToTwentyOne` | DailyEnergyEngine.swift:564 |
| **Reference axis path (F4)** — tightest-per-planet → top-5 → `orbStrength·speedDamp` | `computeAxisRawScoreSkyOnly` | DailyEnergyEngine.swift:992 |
| Speed-damping table | `axisSpeedDamping` | DailyEnergyEngine.swift:1244 |
| Continuous moon | `moonPhaseAxisModulations` / `fullMoonProximity` | DailyEnergyEngine.swift:1165 |
| Sigmoid map (1–10) | `scaleToAxis` | DailyEnergyEngine.swift:1180 |
| Jitter draw (±range, pre-sigmoid, seeded) | `evaluateAxes` | DailyEnergyEngine.swift:935 |
| Minors flow into vibe at full strength; hard/soft ×1.3 only | (confirmed) | DailyEnergyEngine.swift:254–265 |
| Dead phase-amplified weighting (0 call sites) | `MoonPhaseInterpreter.tokensForDailyVibe` (baseWeight 2.0) | MoonPhaseInterpreter.swift:177 |
| Phase buckets (full moon = 177–183°) | `Phase.fromDegrees` | MoonPhaseInterpreter.swift:23 |

**Registry / versioning** ([DailyFitEngineRegistry.swift](../../Cosmic%20Fit/InterpretationEngine/DailyFitEngineRegistry.swift)):
- `DailyFitEngineMode` enum (line 12); `productionMarketingVersion="1.0.1"` (line 45); hardcoded `"(v1.0.1)"` in the production `summary` (line 149).
- Fingerprint = SHA-256 over `canonicalCalibrationString` (lines 111, 224) — covers `sourceWeights`, `axisTuning`, `stage2Sensitivity`, `narrativeSelection`, etc. **Does NOT cover the hardcoded `stage1SkySourceWeights`** (a provenance wart — fixed in Phase 2).
- Old calibrations retained as DEBUG comparators = the precedent for keeping v1.0.1 in-code (`legacyBaseline` line 120, `stage2Legacy` line 144).
- Engine selection ([Core/Config/DailyFitEngineConfig.swift](../../Cosmic%20Fit/Core/Config/DailyFitEngineConfig.swift)): build-time `DAILY_FIT_ENGINE_ID` (Info.plist/xcconfig), DEBUG UserDefaults override `dailyFitEngineIdRuntimeOverride`, Release pins `productionId`.
- Version asserted by test [DailyFitEngineRegistry_Tests.swift:36](../../Cosmic%20FitTests/DailyFitEngineRegistry_Tests.swift#L36); UI stamp [ProfileViewController.swift:740](../../Cosmic%20Fit/UI/ViewControllers/ProfileViewController.swift#L740) auto-derives from `productionVersionDisplayText`.

**Ephemeris (custom analytic — NOT Swiss Ephemeris):**
- Moon **ecliptic latitude available** ([AstronomicalCalculator.swift:200](../../Cosmic%20Fit/Core/Calculations/AstronomicalCalculator.swift#L200), 5.128189·sin(F)… series); **lunar nodes available** (`calculateLunarNodes`, [:429](../../Cosmic%20Fit/Core/Calculations/AstronomicalCalculator.swift#L429)); **moon distance NOT computed anywhere** → must add a leading-term distance from the mean anomaly M′ already inside `calculateMoonPosition`.

**Tests / docs / validation ladder:**
- CI gate `CALIBRATION_CI_GATE` via `CalibrationTier.current` ([CalibrationReportHelper.swift:22](../../Cosmic%20FitTests/CalibrationReportHelper.swift#L22)) — **app target only** (inspector target has no `CalibrationTier`).
- `AstrologicalSoundness_Tests` 6C.1/6C.2/6C.5 assert the **`.default` config vector** (natal 0.40 / transits 0.25 / …), **not** the production calibration — the F7 repoint target.
- `DailyFitGoldens_Tests` loads `docs/fixtures/golden_cases.json` (via `FixtureLocator.fixtureURL`); **file absent → each `@Test` throws `GoldenLoadError.fixtureNotFound` before any `#expect` → suite is silently inert**; **no generator exists** (`tools/generate_golden_fixtures.py` builds a *different* style-guide golden system).
- New harness `inspector/Tests/InspectorEngineTests/CalibrationAudit_Tests.swift` (A1–A5, **structural asserts only** today) → outputs `docs/fixtures/calibration_audit_2026-07-11/`.
- Ladder harnesses: **12×60** `SliderSignalValidation_Tests` + A1–A5; **216×60** `tools/synthetic_cohort.py` (216 charts) + `tools/slider_day_variation_audit.py` (60 days) + `NarrativeCohesionReport_Tests`; **223×60** `tools/production_audit_harness.py` + `tools/production_audit_analyze.py` (→ `docs/fixtures/production_audit_v2/`).
- Docs: `README.md` §4.1 weight table (lines ~367–375), §5.3 ladder (~494–501); `docs/calibration_signoff.md` (marked superseded/historical).
- Backup protocol: `tools/backup_content_sources.py` → dated `data/content_backups/{YYYY-MM-DD}_{label}/` with `manifest.json` (bytes+sha256+restore cmd) + `LATEST.txt`. Precedent rollback (commit `bab5477`, SG-4): snapshot the overwritten file into a retained `_v1_pre_*` copy, cut over in place, one-line `cp` revert.

---

## Implementation phases

### Phase 0 — Backup & rollback scaffolding (do FIRST, before any edit)
- **Git tag** the pre-change commit: annotated `sky-forward-v1.0.1`. Never deleted.
- **File-snapshot backup** using the repo protocol: create `data/content_backups/2026-07-13_pre-sky-forward-v1.0.2/` with a `manifest.json` (created_at, label, purpose, per-file bytes+sha256, one-line restore command) snapshotting **every file to be modified**: `DailyEnergyEngine.swift`, `DailyFitEngineRegistry.swift`, `DailyFitTypes.swift`, `MoonPhaseInterpreter.swift`, `AstronomicalCalculator.swift`, `README.md`, `docs/calibration_signoff.md`, `AstrologicalSoundness_Tests.swift`, `DailyFitGoldens_Tests.swift`, `CalibrationAudit_Tests.swift`. Update `data/content_backups/LATEST.txt`.
- **In-code retention** is added in Phase 1. Net result = **triple rollback**: git tag / file snapshot / runtime-selectable preset.
- **Cache-key trace (pre-work for the Phase-7 cutover gate, B3):** before touching anything, trace how the daily-output / frozen-payload cache is keyed. The audit (§6.8) states namespacing is "handled by engine-id" — and Phase 7 keeps `productionId = "production"` unchanged while only the fingerprint moves. If the cache key is **id-based only**, the fingerprint change will NOT bust it and post-cutover users will see **no change at all**. Record which of the two Phase-7 remedies applies (fingerprint-in-key vs id-bump). Start points: `DailyFitDiagnostics.calibrationSummary`, any daily-payload persistence / `FrozenPayload` store, and every reference to `DailyFitEngineRegistry.productionId`.

### Phase 1 — New engine mode + rollback preset (registry)
- Add `case stage2SkyFidelity` to `DailyFitEngineMode`.
- Add a `sky_forward_v1_0_1` descriptor (`skyForwardV101Id`) pointing at the **current, unchanged** `stage1ExperimentalCalibration` + `.stage1Experimental` mode, `isExperimental: true`, `marketingVersion: "1.0.1"` retained; add it to `allDescriptors`. Leave `stage1ExperimentalCalibration` byte-for-byte unchanged.
- **Do NOT flip production yet.** Add the v1.0.2 work as a new experimental descriptor `sky_forward_v1_0_2` first; validate; flip in Phase 7 (cutover). This mirrors the SG-4 "develop alongside, cut over in one commit, retain old" precedent.

### Phase 2 — Promote vibe sky-mix into the fingerprinted calibration (provenance fix)
- The vibe weights live in a hardcoded constant *outside* the fingerprint, so two different v1.0.2 tunings would share a fingerprint. Fix: add an **optional** `skyVibeWeights` (+ `lunarSignificanceCoeff`) to `DailyFitCalibration` ([DailyFitTypes.swift]); `nil` → fall back to legacy `stage1SkySourceWeights` (retained v1.0.1 mode unchanged). Extend `canonicalCalibrationString` to serialise it. Update `Codable` + `Equatable` + all existing presets (nil).
- **Flag:** because only `.stage2SkyFidelity` sets it (nil branch elsewhere), every existing preset's fingerprint must remain byte-identical — add a regression test asserting the pre-existing fingerprints are unchanged.

### Phase 3 — F1 + F2 + F3: continuous, significance-weighted lunar (new mode only)
- **Continuous vibe vector:** in the `.stage2SkyFidelity` branch, replace the bucket lookup with a **cosine / raised-cosine (smoothstep) blend** between the two adjacent anchors of `lunarPhaseEnergies`, anchored at canonical centres (new 0°, waxingCrescent 45°, firstQuarter 90°, waxingGibbous 135°, full 180°, waningGibbous 225°, lastQuarter 270°, waningCrescent 315°). Peaks exactly at 180° regardless of sample timing → kills the step function (F1) and the missed-full-moon window (F2). **Edge case:** handle modular wrap 315°↔0/360°.
- **Significance amplification (F3 / "should proportions move?"):** multiply the lunar contribution weight by `1 + k · syzygyProximity`, where `syzygyProximity = |cos(radians(moonPhaseDegrees))|` (=1 at exact full AND new, =0 at quarters). Starting `k = 0.8`. **New moons are boosted equally to full moons — this is intended** (syzygy = both; the audit notes new moons are also missed, 3–4/13). If the owner later wants full-only emphasis, split into `kFull`/`kNew`.
- Keep the `.stage1Experimental` branch untouched (rollback path).
- **⚠ Not independently testable-for-effect — validate Phases 3 + 4 together.** Amplifying lunar ×1.8 while transits are still 94% of the vibe (pre-Phase-4) leaves lunar at ~8% — still invisible. Do **not** chase a "Phase 3 had no effect" ghost: the lunar signal only becomes audible once Phase 4's transit normalisation lands. Gate the *effect* checks (A2/A5) after Phase 4, not after Phase 3.

### Phase 4 — §2.2 + F5 + F6: transit normalisation + minor/speed discount + jitter cut
- **Normalise transit accumulation (the core fix, Rec 1):** in the `.stage2SkyFidelity` vibe branch, mirror the axis path — extract a shared helper `dominantTransits(_:limit:)` (tightest-orb per planet → top-5) **reused by both** the vibe path and `computeAxisRawScoreSkyOnly` (removes duplication). For each dominant transit apply `orbStrength · speedDamp(axisSpeedDamping) · minorAspectDiscount` as a scalar strength before distributing across the 6-energy base vector. This bounds the transit sum (≤5 hits) so the fixed lunar contribution stops being swamped → makes nominal weights real (fixes F6's "churn soup" provenance as a consequence).
- **Minor-aspect discount (Rec 5):** reuse the salience `transitAspectWeights` map (`?? 0.5` fallback for minors) so quintiles/semi-sextiles no longer equal a Mars–Sun conjunction.
- **Jitter (F5):** in `skyFidelityCalibration`, set `axisTuning.jitterRange 0.40 → 0.18` (legacy floor, below the ±0.3 full-moon axis nudge). Keep `sigmoidSpread 0.8` initially; flag it as a tuning knob if freshness/variation gates regress. (Inverse-salience jitter scaling is noted as a deferred enhancement to keep the fingerprint deterministic.)

### Phase 5 — Eclipses + supermoons (new `LunarEventDetector`)
- New `Cosmic Fit/InterpretationEngine/LunarEventDetector.swift`, keyed on the **actual date's** ephemeris (NOT the swept elongation), returning a `LunarEvent?` (`.solarEclipse` / `.lunarEclipse` / `.supermoon` / `.micromoon` / `.fullMoon` / `.newMoon`, each with a strength scalar).
  - **Eclipse:** at syzygy (elongation near 0°/180°), use the **already-computed moon ecliptic latitude** + node proximity — `|moonLat| < ~1.4°` near new → solar eclipse; near full → lunar eclipse.
  - **Supermoon (B2 — the math is specified so it actually fires):** add a **separate** `AstronomicalCalculator.calculateMoonDistance(julianDay:) -> Double` (km). Do **NOT** change the signature of `calculateMoonPosition` (see blast-radius flag below). The **leading term alone is insufficient**: `385000.56 − 20905·cos(M′)` bottoms out at **364,096 km**, which never drops below a 361,000 km threshold — a leading-term-only detector fires **zero** supermoons. The evection/variation terms are **REQUIRED**, not optional. Use the standard low-order lunar-distance series (Meeus, ≥5 terms), km:
    ```
    dist = 385000.56
         − 20905.355·cos(M′)
         −  3699.111·cos(2D − M′)
         −  2955.968·cos(2D)
         −   569.925·cos(2M′)
         +    48.888·cos(M)      // + further terms optional; these five reach perigee ≈ 356,500 km
    ```
    where `D` = mean elongation, `M` = Sun mean anomaly, `M′` = Moon mean anomaly (all already available in `calculateMoonPosition`). **Supermoon = full moon with `dist < 361,000 km`; micromoon = full moon with `dist > 405,000 km`.** With the five terms above, perigee reaches ~356,500 km so the threshold is satisfiable. **Flag:** analytic ephemeris (not Swiss) — document the accuracy bound and cross-check the detected 2026 eclipse/supermoon dates against a published almanac inside the harness (a `LunarEventDetector` test that asserts the known 2026 eclipse + supermoon dates within a tolerance).
- **Label override (D2 — second half of the F2 fix):** near syzygy, the detector's `.fullMoon` / `.newMoon` result **overrides** `MoonPhaseInterpreter.Phase.fromDegrees` for the **user-facing phase name**, so a true full moon is always labelled "Full Moon" instead of the 6°-bucket's "Waning Gibbous". Route the displayed phase name through the detector; keep `fromDegrees` only for the continuous vibe-vector anchoring (Phase 3). This is what lets fidelity gate (b) reach ≥90% via the *labelled-event* path, not only the *output-peak* path.
- **Surfacing:** attach the event to the snapshot and route it through the existing sky-salience / accent / narrative pathway as a first-class named event; apply an optional lunar-weight significance boost while an eclipse/supermoon is active. **Flag:** the narrative-accent wiring is not fully mapped in this plan — the implementer must trace it and keep it as an explicit sub-task with its own test.
- **Blast-radius flag:** `calculateMoonPosition` returns `(longitude, latitude)` and has ~6 destructuring callers across `NatalChartManager` + `NatalChartCalculator`. Adding distance there would break all of them — hence the **separate `calculateMoonDistance(julianDay:)`** function (zero blast radius; it is shared core ephemeris, not Daily-Fit-local).
- Void-of-course remains out of scope (documented in README §5.2).

### Phase 6 — F7: evidence layer (docs, tests, goldens) + fidelity gates
- **README §4.1:** document the two-mix runtime truth + v1.0.2 measured effective shares; update the §5.3 ladder note and the engine-preset table (add `sky_forward_v1_0_1` retention + v1.0.2 production).
- **`docs/calibration_signoff.md`:** add a v1.0.2 supersession pointer.
- **`AstrologicalSoundness_Tests` 6C.1/6C.2/6C.5:** repoint from the static `.default` vector to **measured effective shares** of the production (v1.0.2) engine via a mini-cohort (reuse the A1 machinery); keep the normalisation/sum sanity check.
- **`golden_cases.json`:** write a generator (`tools/generate_daily_fit_goldens.py` or a Swift test-mode emitter) producing `docs/fixtures/golden_cases.json` to the `GoldenFixture` schema, stamped `engineVersion "Sky Forward v1.0.2"`. **Harden** `DailyFitGoldens_Tests` so a missing fixture is a hard `XCTFail`, never a swallowed throw (can never silently go inert again).
- **Fidelity gates (Rec 7):** convert the A1–A5 structural asserts into thresholds behind a new `CALIBRATION_FIDELITY_GATE=1` env (inspector target — define a local gate, since `CalibrationTier` lives only in the app target). **Each gate names its measurement basis** so (a) and (d) can never contradict each other (B1):
  - **(a) Baseline lunar share — measured on NON-SYZYGY days only** (exclude days within the syzygy window used by `k`, i.e. `syzygyProximity` above a small cutoff), or equivalently cycle-averaged with syzygy days excluded: effective lunar share within **±0.1 of the configured nominal (~0.60)**. This gate constrains `skyVibeWeights.lunar`, NOT `k`.
  - **(b) Full-moon labelling — ≥90%** of 2026 full moons produce a **labelled "Full Moon" event** (via the Phase-5 detector override, D2) **or** a measurable output peak. With D2 the labelled path alone should clear ≥90%; the peak clause is a backstop, not the primary mechanism.
  - **(c) Jitter share** of day-over-day axis motion **< 15%** (A4 basis, unchanged).
  - **(d) Syzygy swell — measured on SYZYGY days:** full-moon (and new-moon) vibe delta vs the non-syzygy baseline is **statistically separable** (e.g. into-full delta > baseline mean + 1σ, or a two-sample test at p<0.05). This gate is what the `k` coefficient is tuned against, NOT `skyVibeWeights.lunar`.
  - Update **A2's** now-obsolete `distinctVibes ≤ 8` assertion to require *many* distinct outputs + smoothness + a peak at 180°.
  - **Why (a) and (d) don't fight:** (a) is off-syzygy, (d) is on-syzygy; `k` moves (d) without moving (a) (because `syzygyProximity ≈ 0` on (a)'s days), and `skyVibeWeights.lunar` moves both baselines together. Two knobs, two disjoint gates — no tuning loop.

### Phase 7 — Cutover (single reviewable commit) + full ladder
- Flip `productionDescriptor` → `skyFidelityCalibration` + `.stage2SkyFidelity`; `productionMarketingVersion = "1.0.2"`; update the hardcoded `"(v1.0.2)"` summary; update `DailyFitEngineRegistry_Tests` expected version and add assertions that `sky_forward_v1_0_1` retains `"1.0.1"` and a **distinct fingerprint** from production.
- **🔴 BLOCKING GATE — cache invalidation (B3, owned here, not a "risk"):** using the Phase-0 cache-key trace, guarantee post-cutover output actually changes. Because `productionId` stays `"production"` and only the fingerprint moves, an id-based cache key will **not** bust and users will see **no change** (the single most likely way to ship an invisible release). Apply exactly one remedy and prove it:
  - **Remedy A (recommended):** incorporate the fingerprint (or `marketingVersion`) into the daily-output / frozen-payload cache key. Least disruptive to the many `productionId` references.
  - **Remedy B (fallback):** bump the production engine id (versioned id) so id-namespacing busts naturally — only if id is genuinely the sole namespacing dimension used elsewhere.
  - **Proof required:** a test that seeds a v1.0.1-cached daily payload for a profile+date, cuts over, and asserts the served output is the **v1.0.2** result (not the stale cache). This test must be green before merge.
- **Run the full ladder, all green before merge:** unit gates (`CALIBRATION_CI_GATE=1`) → 12×60 (A1–A5 + `CALIBRATION_FIDELITY_GATE=1`) → 216×60 → 223×60 (`production_audit_v2`).
- **Snapshot tests will move (expected):** regenerate `DailyEnergyEngine_Snapshot_Tests` fixtures deliberately, with diff review — not blindly.

### Proposed fixed starting values (v1.0.2) — ratified lunar-dominant
- `skyVibeWeights`: **lunar 0.60 / transits 0.25 / currentSun 0.15** (natal/prog 0, anchor-only) — the audit's stated design intent, ratified by the product owner 2026-07-13.
- `lunarSignificanceCoeff k = 0.8`; `axisTuning.jitterRange = 0.18` (spread 0.8); transit top-K = 5; minor-aspect discount = 0.5.
- **Nudge order if a gate fails (each knob maps to ONE gate — they do not fight):**
  1. **Baseline lunar share gate (a)** off by too much → adjust `skyVibeWeights.lunar` (and rebalance transits/sun). This does NOT touch syzygy separation because gate (a) is measured off-syzygy.
  2. **Syzygy-swell gate (d)** too weak → adjust `k`. This does NOT move gate (a) because `syzygyProximity ≈ 0` on gate (a)'s days.
  3. **Jitter-share gate (c)** too high → lower `jitterRange`.
  4. **Only if axis distribution is wrong** → touch `sigmoidSpread` (last resort — it perturbs the F4 axis path).
  - Each nudge = a new fingerprint → re-run from 12×60. The number is a seed; **the gates are the acceptance bar** (owner-blessed), but the *ratio intent* (lunar-led) is fixed — do not re-invert to transit-dominant without owner sign-off.

---

## Concerns / risks (must be surfaced to the implementer)
1. **Daily-payload / frozen cache invalidation** — **now OWNED as the Phase-7 blocking gate (B3)** with a Phase-0 trace and a required proof test; no longer an open risk. Restated here only because it is the highest-severity item: an id-based cache key makes the whole release invisible.
2. **Supermoon distance** — **now resolved in Phase 5 (B2)** with the required ≥5-term distance series and a satisfiable threshold; leading-term-only would fire zero supermoons. Still analytic (not Swiss) — the almanac cross-check test bounds the accuracy.
3. **Re-tuning uncertainty** — the fixed weights are a seed; the **fidelity gates are the true acceptance bar**. The *ratio* (lunar-led 0.60/0.25/0.15) is owner-ratified; the exact number is nudgeable within that intent.
4. **Downstream Stage-2 drift** — reduced transit magnitude perturbs sliders/palette/silhouette/narrative; the full ladder + deliberate snapshot regeneration catch it.
5. **`AstrologicalSoundness_Tests` read `.default`, not production** — the repoint must target the right calibration.
6. **Determinism / timezone** — eclipse/supermoon detection must use the engine's existing UTC date handling; the new mode stays fully seeded/deterministic.
7. **Scope risk** — eclipses/supermoons are the largest new surface; gated in their own phase with their own tests; the rest can ship if that phase slips (documented fallback).
8. **Phase 3 has no measurable effect until Phase 4 lands** — validate them together; do not chase a "no effect" ghost after Phase 3 alone.

## Verification (end-to-end, before cutover merge)
- **Fidelity harness:** `cd inspector && CALIBRATION_AUDIT_DIR=../docs/fixtures/calibration_audit_2026-07-11 CALIBRATION_FIDELITY_GATE=1 swift test --filter CalibrationAudit_Tests` → all fidelity gates green: (a) **off-syzygy** lunar share within ±0.1 of ~0.60; (b) ≥90% full moons labelled (detector override); (c) jitter <15%; (d) **on-syzygy** full/new delta separable; A2 smooth/peaked at 180°.
- **Eclipse/supermoon almanac test:** `LunarEventDetector` asserts the known 2026 eclipse + supermoon dates within tolerance (guards the analytic-ephemeris approximation and the B2 threshold).
- **Cache-invalidation proof (Phase-7 blocking):** the seed-v1.0.1-cache → cutover → assert-v1.0.2-output test is green.
- **App suites** under `CALIBRATION_CI_GATE=1 -parallel-testing-enabled NO`: `DailyFitVariation_Tests`, `DailyFitCoherence_Tests`, `AstrologicalSoundness_Tests`, `DailyEnergyEngine_Snapshot_Tests`, `DailyFitGoldens_Tests` (now live), `DailyFitEngineRegistry_Tests` (version 1.0.2 + retained-preset fingerprint).
- **Ladder:** 12×60 → 216×60 (`synthetic_cohort.py`, `slider_day_variation_audit.py`, `NarrativeCohesionReport_Tests`) → 223×60 (`production_audit_harness.py` + `production_audit_analyze.py` → `production_audit_v2`).
- **Rollback drill:** flip `DAILY_FIT_ENGINE_ID=sky_forward_v1_0_1` (DEBUG override), confirm byte-identical v1.0.1 output; confirm the file-snapshot restore command in the manifest works.
- **UI:** Profile stamp reads "Sky Forward v1.0.2".

---

## What is explicitly NOT changed
- The axis path (F4) — preserved as the reference model.
- The `.stage1Experimental` code branch and `stage1ExperimentalCalibration` — retained byte-for-byte for rollback.
- Void-of-course modelling — deferred.
- The `MoonPhaseInterpreter.tokensForDailyVibe` dead code — left as-is (out of scope; note for a future cleanup).
