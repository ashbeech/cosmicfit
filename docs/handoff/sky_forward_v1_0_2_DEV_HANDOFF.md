# Sky Forward v1.0.2 — Complete Developer Handoff

> **Read this first, in full.** You are picking up a partially-completed release from another dev. This
> document is self-contained: it tells you exactly what exists, what is validated, the two open owner
> decisions you must test/confirm, and the precise remaining steps (Phase 6c → cutover) with file:line
> targets, commands, and acceptance criteria. **No omissions for brevity.**
>
> **Date handed off:** 2026-07-15 · **Branch:** `SFv102` · **Nothing is committed; production is NOT flipped.**

---

## 0. Orientation — what this release is

An engineering audit ([`docs/daily_fit_calibration_audit_2026-07-11.md`](../daily_fit_calibration_audit_2026-07-11.md))
proved the shipped **Sky Forward v1.0.1** Daily Fit engine ran a daily "vibe" that was **94% transits /
4.6% lunar** against a nominal intent of 25% / 60% — because in-orb transits accumulate un-normalised
(41–83/day) while the moon adds a fixed step vector; half of all full moons were never labelled; and
seeded jitter (±0.40) was louder than the full-moon signal.

**Sky Forward v1.0.2** fixes findings F1, F2, F3, F5, F6, F7 per the plan
([`docs/handoff/sky_forward_v1_0_2_plan.md`](sky_forward_v1_0_2_plan.md), rev 4 — the source of truth) and its
kickoff ([`docs/handoff/SKY_FORWARD_V1_0_2_KICKOFF_PROMPT.md`](SKY_FORWARD_V1_0_2_KICKOFF_PROMPT.md)).
**When the plan and this doc disagree, the plan wins; when the plan is silent, preserve v1.0.1 behaviour and ask.**

### Reference docs (read in this order)
1. [`sky_forward_v1_0_2_plan.md`](sky_forward_v1_0_2_plan.md) — the spec (7 phases, gates G0–G3, nudge order).
2. [`../daily_fit_calibration_audit_2026-07-11.md`](../daily_fit_calibration_audit_2026-07-11.md) — the "why" (findings F1–F7, experiments A1–A5).
3. [`sky_forward_v1_0_2_phase0_cache_trace.md`](sky_forward_v1_0_2_phase0_cache_trace.md) — the B3 cache-key trace + remedy decision.
4. [`sky_forward_v1_0_2_status.md`](sky_forward_v1_0_2_status.md) — the short status table (this doc supersedes it in detail).

### Repo orientation
- Engine: `Cosmic Fit/InterpretationEngine/` (single source of truth). The **inspector SwiftPM package**
  (`inspector/`) **symlinks** `Cosmic Fit/InterpretationEngine` and `Cosmic Fit/Core/Calculations` — so
  `swift build` in `inspector/` type-checks the engine **fast** (~8s), and the fidelity harness lives there.
- The Xcode project uses **synchronized folder groups** — new files under `Cosmic Fit/…` auto-include in the
  app target (no `project.pbxproj` editing needed). `LunarEventDetector.swift` was added this way.
- Engine selection: `Cosmic Fit/Core/Config/DailyFitEngineConfig.swift` (build-time `DAILY_FIT_ENGINE_ID`,
  DEBUG UserDefaults override, Release pins `productionId`). The inspector has its own concrete shim.

### Triple rollback already in place (Phase 0)
- git tag **`sky-forward-v1.0.1`** (annotated, on the pre-change commit `2b9be5f`).
- file snapshot **`data/content_backups/2026-07-15_pre-sky-forward-v1.0.2/`** with `manifest.json`
  (bytes+sha256+restore cmd). Restore: `python3 tools/backup_content_sources.py restore --backup-dir data/content_backups/2026-07-15_pre-sky-forward-v1.0.2`.
- in-code preset **`sky_forward_v1_0_1`** (proven byte-identical to v1.0.1 output — see §4).

---

## 1. ⚑ TWO OPEN OWNER DECISIONS — test/confirm these first (G0)

Both are **plan-default constants that were amended with evidence** during implementation. Per the plan's
governance (G0: the G1/constant numbers are "Claude's defaults, not owner-ratified"), these need an owner
glance + sign-off. Your job: **re-run the evidence, confirm the reasoning holds, and get sign-off (or revert).**

> **DECISION 1 — Supermoon threshold 361,000 → 363,300 km** — the plan's 361 k detects only 1 of the 3
> commonly-cited 2026 supermoons in this analytic ephemeris; 363.3 k catches exactly the almanac's three
> and cleanly excludes the next full moon.
>
> **DECISION 2 — A2 "no cliff" metric 0.15·range → 0.30·total-variation** — the plan's formulation
> mismeasures a legitimately steep-but-smooth lunar flank; mine captures the step-function-elimination intent.

### How to TEST Decision 1 (supermoon threshold)
- **Where:** `Cosmic Fit/InterpretationEngine/LunarEventDetector.swift`, `static let supermoonKm = 363_300.0`
  (has an `⚑ OWNER-FLAGGED AMENDMENT` comment). Plan's original value was `361_000`.
- **The evidence** (moon distances at each 2026 full moon, from the analytic `calculateMoonDistance`, sampled
  at noon UTC): Jan 3 ≈ **363,150** km, Nov 24 ≈ **361,596** km, Dec 24 ≈ **357,100** km are the three
  almanac supermoons; the next-closest full moon is Oct 26 ≈ **368,332** km. At 361,000 km only Dec 24 fires;
  at 363,300 km all three fire and Oct 26 is cleanly excluded (a ~5,000 km gap).
- **Re-run to verify:** `cd inspector && swift test --filter "LunarEventDetector_Tests"`. All 5 tests should
  pass. `testSupermoonsMatchAlmanac` asserts all 3 fixture supermoons detect as `.supermoon` under 363,300;
  it will **fail if you revert to 361,000** (Jan 3 / Nov 24 flip to `.fullMoon`).
- **To reproduce the raw distances** (a temporary scan): sample each 2026 full-moon date at noon UTC and print
  `AstronomicalCalculator.calculateMoonDistance(julianDay:)` — see §4 "how the numbers were obtained".
- **Fixture note:** the pinned almanac ([`docs/fixtures/lunar_events_2026.json`](../fixtures/lunar_events_2026.json))
  records `supermoonThresholdKm: 363300` + a rationale note, and lists the 3 supermoon dates. If the owner reverts
  to 361,000, update the threshold in **both** `LunarEventDetector.swift` and the fixture, and change
  `testSupermoonsMatchAlmanac` to expect only Dec 24 (or whatever the owner chooses).

### How to TEST Decision 2 (A2 "no cliff" metric)
- **Where:** `inspector/Tests/InspectorEngineTests/CalibrationAudit_Tests.swift`, in `testA2_LunarPhaseStepGranularity`,
  behind `if S.fidelityGateEnabled`. It computes `stepShare = maxStep / totalVariation` and asserts
  `stepShare < 0.30` (a `print("A2GATE …")` line emits the numbers). Plan's original: `maxStep ≤ 0.15·range`.
- **The reasoning:** the "lunar magnitude" signal used is the continuous blend's `drama + playful` (the
  full-moon signature). Its full→waning-gibbous flank drops 0.65 → 0.20 in one synodic day = **~34% of range**
  — yet the signal is fully continuous (301 distinct values across the cycle, peaks exactly at 180°). So
  "% of range" flags a smooth steep slope as a "cliff". A v1.0.1-style **step function** concentrates ~half
  the cycle's variation in one bucket-boundary jump (`maxStep/totalVariation ≈ 0.5`); the continuous blend
  spreads it (`≈ 0.17`). `stepShare < 0.30` cleanly separates the two — that is the actual "did we kill the
  step function" intent.
- **Re-run to verify:** `cd inspector && CALIBRATION_ENGINE_ID=sky_forward_v1_0_2 CALIBRATION_FIDELITY_GATE=1 swift test --filter "testA2_LunarPhaseStepGranularity"`.
  Passes; the `A2GATE` line shows `distinct=… maxStep=… totalVar=… stepShare=… peakDeg=180.0`.
- **The other two A2 conditions are unchanged from the plan** and pass: `distinctVibes ≥ 20`, `peakDeg` within
  ±1 synodic day of 180°. Only the "no cliff" formulation was amended.

### Also flag (G0, no change needed)
The **G1 gate constants** (0.30/0.90 syzygy cutoffs, [0.50, 0.70] share band, 12/13 labelling, jitter < 0.15,
+1σ swell, ≥20 distinct / ±1 day peak) were used **as pinned from the plan** and **all passed on the first
real cohort run without tuning**. Per G0, a quick owner glance at the G1 table is still worthwhile. Constants
live in `CalibrationAudit_Tests.swift` (`offSyzygyCutoff = 0.30`, `syzygyCutoff = 0.90`, the `[0.50, 0.70]`
in A1's gate, `≥ 12` in A3's gate, `< 0.15` in A4's gate, `+ off.std` in A5's gate).

---

## 2. Complete inventory of changes (working tree — 22 items, uncommitted)

### Engine source (production behaviour — the new mode only; v1.0.1 path untouched)

**`Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift`** (Phase 1 + 2)
- `enum DailyFitEngineMode` gains `case stage2SkyFidelity` + an extension with two computed helpers:
  - `var usesSkyForwardPipeline: Bool` → `true` for `.stage1Experimental` **and** `.stage2SkyFidelity` (both run
    the stage-1 chart-anchor + sky-vibe + salience pipeline). **All pipeline-structure gates use this.**
  - `var usesSkyFidelityVibe: Bool` → `true` **only** for `.stage2SkyFidelity` (gates the new vibe math).
- New ids `skyForwardV101Id = "sky_forward_v1_0_1"`, `skyForwardV102Id = "sky_forward_v1_0_2"`; retained
  `skyForwardV101MarketingVersion = "1.0.1"`.
- `allDescriptors` gains `skyForwardV101Descriptor` + `skyForwardV102Descriptor` (inserted **after**
  `productionDescriptor` so `engineId(for:mode:)` collapses same-calibration+mode aliases to `production`).
- `skyForwardV101Descriptor`: `stage1ExperimentalCalibration` + `.stage1Experimental` + `marketingVersion "1.0.1"`
  → the **rollback** preset (same calibration as production ⇒ byte-identical seed via collapse ⇒ byte-identical output).
- `skyFidelityCalibration`: the v1.0.2 calibration — same as `stage1ExperimentalCalibration` except
  `axisTuning.jitterRange 0.40 → 0.18` (F5) **plus** `skyVibeWeights(transits:0.25, lunar:0.60, currentSun:0.15)`
  and `lunarSignificanceCoeff: 0.8`.
- `skyForwardV102Descriptor`: `skyFidelityCalibration` + `.stage2SkyFidelity`, `isExperimental: true`,
  `dailySeedPolicy: .includesEngineId`, `marketingVersion: nil` (experimental until cutover).
- `canonicalCalibrationString` now serialises `skyVibeWeights` + `lunarSignificanceCoeff` **only when non-nil**
  → every pre-v1.0.2 preset's canonical string (and fingerprint) is **byte-identical** to before.

**`Cosmic Fit/InterpretationEngine/DailyFitTypes.swift`** (Phase 2 + B3)
- `struct DailyFitCalibration` gains a nested `struct SkyVibeWeights: Equatable { transits, lunar, currentSun }`
  + two optional stored props `skyVibeWeights: SkyVibeWeights?` and `lunarSignificanceCoeff: Double?`
  (init params default `nil`; `DailyFitCalibration` is **Equatable-only, not Codable**).
- `struct DailyFitPayload` gains `calibrationFingerprint: String?` (B3): added to `CodingKeys`,
  `init(from:)` via `decodeIfPresent`, `encode(to:)` via `encodeIfPresent`, the memberwise init, and preserved
  through `withDailyFitEngineId` + `withNarrativeBrief`; plus a new `withCalibrationFingerprint(_:)` copy-helper.

**`Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift`** (Phase 3 + 4 + 5 wiring; the big one)
- Extracted `static func dominantTransits(_:limit:)` **verbatim** from `computeAxisRawScoreSkyOnly` (tightest-orb
  per planet → top-5 by orb; no tie-break, so the v1.0.1 axis path stays byte-identical) and refactored the
  axis path to call it (shared by axis + new vibe path).
- New Phase-3 functions: `continuousLunarEnergies(moonPhaseDegrees:)` (raised-cosine blend of the two adjacent
  `lunarPhaseEnergies` anchors at every 45°, handles the 315°↔0° wrap, peaks at 180°); `syzygyProximity(moonPhaseDegrees:)`
  = `|cos(deg)|`; `accumulateContinuousLunarContribution(…significanceCoeff k…)` (weight × `1 + k·syzygyProximity`).
- New Phase-4 function: `accumulateDominantTransitContribution(…)` — top-5 dominant transits, each scaled by
  `orbStrength · speedDamp(axisSpeedDamping) · minorAspectDiscount(transitAspectWeights ?? 0.5)`, distributed
  across the 6-energy base vector.
- New `generateSkyFidelityVibeProfileWithRaw(…)` — the v1.0.2 sky-vibe generator (uses `skyVibeWeights` +
  the two new accumulators). **Wired into `generateSnapshot` AND `generateSnapshotWithTrace`**: the stage-1
  sky-vibe branch now does `if effectiveMode.usesSkyFidelityVibe { generateSkyFidelityVibeProfileWithRaw(…) } else { generatePartialVibeProfileWithRaw(…, stage1SkySourceWeights) }`.
- `generateSnapshotWithTrace`'s **source-decomposition** (the `attributionWeights` + accumulation that feeds
  `trace.sourceContributions`, which the A1 gate measures) now branches on `usesSkyFidelityVibe`: uses
  `skyVibeWeights` + `accumulateDominantTransitContribution` + `accumulateContinuousLunarContribution`, so A1
  measures the **real** v1.0.2 decomposition (this is why lunar reads 0.58, not the old 0.94).
- `buildLunarContext` gains `date:` + `applyEventLabelOverride:` params; for `usesSkyFidelityVibe` it consults
  `LunarEventDetector.detect(date:)` and overrides `phaseName` with `event.phaseLabel` (**D2**: a true full moon
  always reads "Full Moon", never the 6°-bucket "Waning Gibbous"). Both snapshot constructors pass
  `date: date, applyEventLabelOverride: effectiveMode.usesSkyFidelityVibe`.
- **~25 pipeline-structure gates broadened** `== .stage1Experimental` → `.usesSkyForwardPipeline` (behaviour-
  preserving for v1.0.1); the diagnostic mode label became a 3-way switch (adds `"stage2SkyFidelity"`).

**`Cosmic Fit/Core/Calculations/AstronomicalCalculator.swift`** (Phase 5)
- New `static func calculateMoonDistance(julianDay:) -> Double` (km) — the **≥5-term** Meeus low-order distance
  series (`385000.56 − 20905.355·cos M′ − 3699.111·cos(2D−M′) − 2955.968·cos 2D − 569.925·cos 2M′ + 48.888·cos M`),
  perigee ~356,500 km. **Separate** from `calculateMoonPosition` (which has 5 destructuring callers) → zero blast radius.
  The leading term alone floors at ~364,096 km and would fire **zero** supermoons — the extra terms are required (B2).

**`Cosmic Fit/InterpretationEngine/LunarEventDetector.swift`** (Phase 5 — NEW FILE)
- `enum LunarEvent` (`.solarEclipse/.lunarEclipse/.supermoon/.micromoon/.fullMoon/.newMoon`, each with a 0–1
  `strength`) + helpers `isFullMoonFamily`, `phaseLabel` ("Full Moon"/"New Moon" for D2), `eventLabel`, `isSpecialEvent`.
- `enum LunarEventDetector` with pinned thresholds (`syzygyWindowDeg = 7.0`, `eclipseLatitudeDeg = 1.4`,
  `eclipseNodeProximityDeg = 18.0`, `supermoonKm = 363_300.0` ⚑, `micromoonKm = 404_500.0`, `perigeeKm`, `apogeeKm`)
  and `detect(date:)` / `detect(julianDay:)`. Pure function of the date (deterministic). Uses
  `calculateLunarPhase` (elongation), `calculateMoonPosition` (latitude), `calculateLunarNodes` (node proximity),
  `calculateMoonDistance` (super/micro). Priority: eclipse > super/micro > plain full/new.

**`Cosmic Fit/Core/Utilities/DailyFitFrozenPayloadStorage.swift`** (Phase 7 — B3 Remedy A)
- New private `currentFingerprint(for engineId:)` (= descriptor's fingerprint) + `fingerprintMatches(_:engineId:)`
  (nil current fp → id-only fallback).
- `save` stamps the fingerprint: `payload.withDailyFitEngineId(engineId).withCalibrationFingerprint(currentFingerprint(for: engineId))`.
- `load`, `hasValidFrozenPayload`, and the **namespaced-file** branch of `purgeStaleArtifacts` now require a
  fingerprint match (same engine id but stale fingerprint ⇒ rejected + purged ⇒ the day recomputes to v1.0.2).
- **Legacy un-namespaced files are grandfathered** (id-only, no fp check) — they predate v1.0.1 and the field.
  This is why v1.0.1's *namespaced* payloads bust at cutover but the ancient-legacy-file-load feature survives.

### Broadening-only files (behaviour-preserving `== .stage1Experimental` → `.usesSkyForwardPipeline`)
`BlueprintLensEngine.swift`, `PersonalScaleEnvelope.swift` (also its 3 exhaustive `switch mode` gained
`case .stage1Experimental, .stage2SkyFidelity:`), `NarrativeIntentEngine.swift`, `DailyFitPipeline.swift`,
`UI/ViewControllers/CosmicFitTabBarController.swift`. (`BlueprintLensEngine.resolveEssenceProfile`'s exhaustive
switch also gained the new case.)

### Tests + fixtures + docs
- `Cosmic FitTests/DailyFitEngineRegistry_Tests.swift` — `enum PinnedFingerprints` + 4 new tests (byte-identical
  legacy fingerprints, `sky_forward_v1_0_1` rollback identity + collapse-to-production, `sky_forward_v1_0_2`
  distinct fingerprint + lunar-led mix + jitter 0.18, the `usesSkyForwardPipeline` helper). **21/21 green.**
- `Cosmic FitTests/AstrologicalSoundness_Tests.swift` — **6C.2 repointed** from the misleading `.default`
  transit-dominant vector to the lunar-led sky mix (`skyVibeWeights.lunar > transits`), cross-referencing the
  inspector fidelity gate (a) for measured effective shares; **6C.5** report documents the two-mix truth. **12/12 green.**
- `Cosmic FitTests/DailyFitFrozenPayloadStorage_Tests.swift` — new B3 proof test
  `staleFingerprintCacheIsBusted` (namespaced stale-fp rejected + purged; fresh fp served). **Green.**
- `inspector/Tests/InspectorEngineTests/CalibrationAudit_Tests.swift` — engine-selection statics
  (`auditEngineId`/`auditCalibration`/`auditMode` via `CALIBRATION_ENGINE_ID`), `fidelityGateEnabled`,
  `syzygyProx`, `offSyzygyCutoff`/`syzygyCutoff`, `fullMoonDates2026`/`noonUTC`; **A1→gate(a), A2→3 conditions,
  A3→gate(b), A4→gate(c), A5→gate(d)** converted from print-only to fail-closed behind `CALIBRATION_FIDELITY_GATE=1`.
- `inspector/Tests/InspectorEngineTests/LunarEventDetector_Tests.swift` — NEW; almanac cross-check (5 tests).
- `docs/fixtures/lunar_events_2026.json` — NEW; pinned 2026 almanac (13 full moons + 4 eclipses + supermoons/micromoons).
- `README.md` §4.1 (two-mix truth + v1.0.2 table + preset table), `docs/calibration_signoff.md` (supersession pointer).
- `docs/handoff/sky_forward_v1_0_2_phase0_cache_trace.md`, `sky_forward_v1_0_2_status.md` — NEW.
- `data/content_backups/2026-07-15_pre-sky-forward-v1.0.2/` + `LATEST.txt` — Phase 0 backup.

---

## 3. Architecture decisions you must respect

- **The new mode is a REFINEMENT of `.stage1Experimental`, not a new pipeline.** It runs the identical stage-1
  structure; only the vibe math (continuous lunar, normalised transits, significance amplification) and the
  named-event label override differ. That's why structure gates broadened to `usesSkyForwardPipeline` and the
  new math gates on `usesSkyFidelityVibe`. **Do not** duplicate the pipeline.
- **v1.0.1 is byte-for-byte preserved.** New vibe math lives in *new* functions reached only via the new mode.
  Proven: pre-v1.0.2 fingerprints identical to the tag; `sky_forward_v1_0_1` output identical to production over
  40 days. Never edit `stage1ExperimentalCalibration` or the `.stage1Experimental` branch.
- **`engineId(for:mode:)` collapse:** descriptors sharing a calibration+mode resolve to the **first** in
  `allDescriptors` (production). This is what makes `sky_forward_v1_0_1` seed-identical to production (byte-identical
  rollback) and what will make v1.0.2's seed use `"production"` **after** cutover (but `"sky_forward_v1_0_2"`
  before). Keep this in mind for goldens (§6d) — the seed's `resolvedEngineId` shifts at cutover.
- **Determinism is sacred.** `continuousLunarEnergies`, `LunarEventDetector`, `calculateMoonDistance` are pure
  functions of (chart, date). No wall-clock, no RNG outside the existing seeded jitter.

---

## 4. Validation already done — evidence + how to reproduce

All commands from repo root unless noted. The simulator id `148BC509-DCD4-4EED-AFC7-00495D1E0B06` is a booted
"Test iPhone" (iOS 26.5); substitute a valid `xcrun simctl list devices available` id — **do not** use
`name=iPhone 16` (resolves to `OS:latest`, which no iPhone-16 sim matches → 0 tests run).

| Check | Command | Result |
|---|---|---|
| Engine compiles (fast) | `cd inspector && swift build` | clean (~8s) |
| Fidelity gates (Rung 3) | `cd inspector && CALIBRATION_ENGINE_ID=sky_forward_v1_0_2 CALIBRATION_FIDELITY_GATE=1 swift test --filter CalibrationAudit_Tests` | **a/b/c/d/A2 all green** |
| Lunar almanac (Phase 5) | `cd inspector && swift test --filter LunarEventDetector_Tests` | 5/5 (4 eclipses, 13 full moons) |
| Registry + soundness (Rung 1 partial) | `xcodebuild test -scheme "Cosmic Fit" -destination 'platform=iOS Simulator,id=<sim>' -only-testing:"Cosmic FitTests/DailyFitEngineRegistry_Tests" -only-testing:"Cosmic FitTests/AstrologicalSoundness_Tests" -parallel-testing-enabled NO` | 33/33 |
| B3 proof (Rung 5) | same, `-only-testing:"Cosmic FitTests/DailyFitFrozenPayloadStorage_Tests"` | B3 test green (see §7 gotcha) |

**Measured effective shares (A1, 12×181):** lunar **0.5784** / transits **0.3123** / sun **0.1093**;
`r(transitCount, transitShare) = −0.071`; transits out-weigh lunar on **1.3%** of days. (v1.0.1: 0.046 / 0.94, r=0.94, 100%.)
Reports written to `$CALIBRATION_AUDIT_DIR` (set it, e.g. `CALIBRATION_AUDIT_DIR=/tmp/audit_v102`).

**24h variation (A5, the owner non-negotiable):** day-over-day vibe L1 delta **mean 3.56** (v1.0.1 audited: 1.17),
now moon-driven; full-moon axis legible (new 6.40 → quarter 7.08 → full 7.69).

**Byte-identical rollback + fingerprints:** proven by (a) re-building the `sky-forward-v1.0.1`-tagged
registry/types and diffing fingerprints, and (b) a 40-day snapshot diff of `sky_forward_v1_0_1` vs `production`
(0 mismatches). To reproduce a fingerprint dump, add a temp test in `inspector/Tests/…` that prints
`DailyFitEngineRegistry.allDescriptors[*].fingerprint` and `swift test --filter <it>`; pinned values are in
`DailyFitEngineRegistry_Tests.PinnedFingerprints`.

**How the supermoon numbers were obtained** (to re-verify Decision 1): a temporary XCTest in `inspector/Tests/…`
that bootstraps ephemeris (`CalibrationAuditSupport.bootstrapEphemeris()`), loops each 2026 day at noon UTC,
calls `LunarEventDetector.detect(date:)`, and prints `elong / lat / dist`. Delete it after. (This is how the
Jan 3 = 363,150 / Nov 24 = 361,596 / Dec 24 = 357,100 / Oct 26 = 368,332 figures were measured.)

---

## 5. The plan's validation ladder — what's green, what remains

| Rung | Content | Status |
|---|---|---|
| 1 Unit | `DailyFitEngineRegistry_Tests`, `AstrologicalSoundness_Tests` ✓ · `DailyFitGoldens_Tests` ✗ (no fixture — §6d) | **partial** |
| 2 Variation/coherence/snapshots | `DailyFitVariation_Tests`, `DailyFitCoherence_Tests`, `DailyEnergyEngine_Snapshot_Tests` | **not run** |
| 3 Fidelity gates | `CalibrationAudit_Tests` (a–d, A2) | **GREEN** |
| 4 Cohort ladder | 12×60, 216×60, 223×60 + `--gate` tools | **not run** (see §6) |
| 5 Cache proof | B3 test | **GREEN** |
| 6 Rollback drill | byte-identical + restore round-trip | **GREEN** |

**Cutover is gated on Rungs 1–6 all green** (plan §5 / kickoff §5). So the remaining work below must be done
**before** the production flip.

---

## 6. REMAINING WORK — do these in order, to completion

### 6a. Confirm the two G0 decisions (§1) with the owner
Re-run the two verifications in §1, present the evidence, and record the sign-off (or revert) in the plan's
revision log. Do not proceed to cutover with unratified constants.

### 6b. Phase 6c — make the cohort-ladder gates fail-closed (plan G2 items 2, 3, 4 + owner-priority items)
These are **print-only today** and must become hard failures. None require the cutover; they gate the ladder.

1. **`Cosmic FitTests/NarrativeCohesionReport_Tests.swift`** — promote the six §4.3 "TARGET EVALUATION" lines
   (currently `txt += … PASS/FAIL` strings at ~lines 471–477) to real `#expect`s:
   `[6] flip rate ≥ 0.40`, `[7] distinct-#1 ≥ 6`, `[8] category coverage ≥ 10/14`, `[9] slider range ≥ 0.5/user`,
   `[10] no slider stuck 60d`, `[12] accent-salience match ≥ 0.70`. Keep the three existing hard asserts
   (oppositions == 0, cross-surface < 0.1%, coherence ≥ 0.85). The variables are already computed
   (`meanFlipRate`, `meanDistinct`, `meanCategories`, `salienceMatchRate`, per-slider `ranges`/`pctStuck`).
   **Run against v1.0.2** (this suite is app-target; point it at the v1.0.2 engine the same way the other app
   tests will after cutover, or add an engine-id hook). **Owner priority:** these variation targets **outrank**
   the lunar-fidelity gates if they ever conflict (plan G0). Given A5 shows variation *improved* (3.56 vs 1.17),
   they should pass — but verify.
2. **`Cosmic FitTests/DailyFitVariation_Tests.swift`** — make test **4A** (population-level day-over-day drift:
   essence drift + palette churn + tarot uniqueness) run **unconditionally** for v1.0.2 (today it's opt-in behind
   `CALIBRATION_CI_GATE`). This is the only population drift gate.
3. **`Cosmic FitTests/DailyFitAshTodayTomorrow_Tests.swift`** — fix the tautological assert: its `seedDiffers`
   OR-clause is always true by construction; drop `seedDiffers` from the OR so the test can actually fail on a
   frozen palette+vibe.
4. **`tools/production_audit_analyze.py`** — add a `--gate` mode that (i) diffs cohort metrics against the pinned
   baseline `docs/fixtures/calibration_audit_2026-07-11/` (or a v1.0.2 baseline you write) and (ii) `sys.exit(1)`
   on regression in mean coherence, slider-variation coverage, narrative-cohesion pass rate, or tarot repeat-gap.
   **Today it only writes `summary.json` and returns 0.** (It already imports `sys`; the existing `exit(1)` calls
   are for arg errors, not regression gating.)
5. **`tools/slider_day_variation_audit.py`** — add a `--gate` mode that `sys.exit(1)` when slider range < 0.5/user
   or any slider is stuck across the 60-day window (it already computes `MEANINGFUL_DELTA = 0.05`; assert on it).

### 6c. Run the cohort ladder (Rung 4) against v1.0.2
The Python harnesses invoke the engine; run them pointed at v1.0.2 (via `DAILY_FIT_ENGINE_ID=sky_forward_v1_0_2`
where the tool honours it, or after cutover). Sequence (plan/kickoff §4 Rung 4):
- **12×60:** `SliderSignalValidation_Tests` + the A1–A5 harness (already green under the fidelity gate).
- **216×60:** `python3 tools/synthetic_cohort.py --verify` → `python3 tools/slider_day_variation_audit.py --start 2026-04-23 --days 60 --subset --parallel 6` (with `--gate`) → `NarrativeCohesionReport_Tests`.
- **223×60:** `python3 tools/production_audit_harness.py --out docs/fixtures/production_audit_v2` → `python3 tools/production_audit_analyze.py --in docs/fixtures/production_audit_v2 --gate`.
- These are **expensive** (hundreds of profiles × 60 days of ephemeris). Budget time. A **red gate is a signal
  to keep developing** (apply the plan's nudge order — each knob maps to one gate, they don't fight), not to stop.

### 6d. Generate `docs/fixtures/golden_cases.json` (do this AT cutover, not before)
`DailyFitGoldens_Tests` hard-fails on the missing fixture (that is the F7 signal, not silent inertia — confirm the
suite is in the CI run target). The goldens characterise the **shipping** engine, and the seed's `resolvedEngineId`
only becomes `"production"` **after** the flip — so generate the fixture **immediately after** cutover:
- Write a small generator (a Swift test-mode emitter, or `tools/generate_daily_fit_goldens.py`) that runs each
  synthetic golden case (see `DailyFitGoldens_Tests.makeChart`/`makeTransits`) through
  `DailyFitDiagnostics.generateReport(…, calibration: production, dailyFitEngineId: production)` and records the
  observed `dominantEnergy`, essence top-3 (as a **generous band** so it tolerates seed jitter), palette
  temperature, and silhouette lean. Stamp `engineVersion: "Sky Forward v1.0.2"` + `baseDate`.
- Schema: `GoldenFixture { goldens: [GoldenCaseData], baseDate }` (see the private structs in
  `Cosmic FitTests/DailyFitGoldens_Tests.swift`). Then `DailyFitGoldens_Tests` goes green.

### 6e. Regenerate snapshots (Rung 2) — deliberately, with diff review
`DailyEnergyEngine_Snapshot_Tests` fixtures **will move** (the vibe changed). Regenerate **only after** the
fidelity gates (§4) are green, review the diff, and **attach the `CALIBRATION_FIDELITY_GATE=1` green output beside
the regenerated fixtures** in the cutover commit (plan G2 item 6 — a moved snapshot with no attached green
fidelity run is a rejected diff).

### 6f. Phase 7 — the cutover (ONE reviewable commit, ONLY after Rungs 1–6 are all green)
Edit `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift`:
- `productionDescriptor` (line ~173): `calibration: stage1ExperimentalCalibration` → `skyFidelityCalibration`;
  `mode: .stage1Experimental` → `.stage2SkyFidelity`; `fingerprint: fingerprint(for: skyFidelityCalibration)`;
  `summary:` "(v1.0.1)" → "(v1.0.2)" (line ~176 — the **productionDescriptor** one only; leave the rollback
  descriptor's "(v1.0.1)" at ~256 and the comment at ~22).
- `productionMarketingVersion = "1.0.1"` → `"1.0.2"` (line ~68). (`productionVersionDisplayText` /
  `productionEngineDisplayLine` auto-derive → the Profile stamp reads "Sky Forward v1.0.2"; no UI edit needed.)
- **Consider** demoting `skyForwardV102Descriptor` (it now duplicates production) or leave it as a DEBUG alias —
  either is fine, but ensure production is **first** in `allDescriptors` for the seed collapse.

Edit `Cosmic FitTests/DailyFitEngineRegistry_Tests.swift`:
- **Replace the tautological version check** at line 36 (`#expect(production?.marketingVersion == DailyFitEngineRegistry.productionMarketingVersion)`
  — constant vs itself, passes for any version) with a **real literal**: `#expect(production?.marketingVersion == "1.0.2")`.
- Add: production `mode == .stage2SkyFidelity`; production fingerprint == the pinned v1.0.2 fingerprint
  (`PinnedFingerprints.skyForwardV102`); `sky_forward_v1_0_1` still `"1.0.1"` with a **distinct** fingerprint.

The **B3 remedy is already implemented** (§2), so post-cutover output actually changes (the fingerprint moves →
namespaced v1.0.1 caches bust → users see v1.0.2). The B3 proof test already covers this.

**Reveal-flag note (verify at cutover):** reveal flags (`DailyFitRevealPersistence.revealedFlagKey`) are
un-namespaced for the production id, so a cutover day's payload recomputes but the card may still read "revealed"
(cosmetic — the served *content* is correctly v1.0.2). If you want a cutover day to re-reveal/re-animate, also
incorporate the fingerprint into the reveal-flag keys. Not required for the B3 "output changes" gate.

### 6g. Definition of Done (from the kickoff §6 — check every box)
- [ ] Phase 0 backup dir + `manifest.json` + `sky-forward-v1.0.1` tag exist. **(done)**
- [ ] v1.0.1 runnable via `sky_forward_v1_0_1`; rollback drill byte-identical. **(done)**
- [ ] All 6 test rungs green; snapshots regenerated with reviewed diffs. **(Rungs 1/3/5/6 done; 2/4 remain)**
- [ ] Owner's 24h-variation: `DailyFitVariation_Tests` 4A unconditional + §4.3 targets promoted + `AshTodayTomorrow` fixed. **(6b)**
- [ ] G1 constants assessed + owner-glanced (2 amendments flagged). **(§1 — needs sign-off)**
- [ ] `golden_cases.json` generated; `DailyFitGoldens_Tests` green in CI. **(6d)**
- [ ] `AstrologicalSoundness_Tests` assert effective/lunar-led mix, not `.default`. **(done)**
- [ ] Fidelity gates (a)–(d) green on correct off/on-syzygy bases. **(done)**
- [ ] Eclipse/supermoon detector matches almanac; label override works. **(done)**
- [ ] B3 cache-invalidation proof green; cutover output verifiably changes. **(done)**
- [ ] Version bumped to 1.0.2; Inspector fingerprint + Profile stamp reflect it. **(6f)**
- [ ] README §4.1 + `calibration_signoff.md` updated. **(done)**
- [ ] Cutover is one clean commit; revision-log decisions honoured. **(6f)**

### 6h. Scoped follow-up (not blocking cutover)
Route the `LunarEventDetector` **named event** (Supermoon / Solar Eclipse / Lunar Eclipse) into the
narrative/accent surface so the device build shows "named eclipse/supermoon days" beyond the corrected phase
label. The detector is ready and its `eventLabel`/`isSpecialEvent`/`strength` are the hooks. The D2 **phase-label**
override is already done and gate-covered; this is the richer surfacing the plan flagged as an explicit sub-task
(trace the sky-salience/accent/narrative path in `BlueprintLensEngine`/`DailyNarrativeSelector` and add a test).

---

## 7. Gotchas / non-obvious knowledge (read before you touch tests)

- **DEBUG engine-override tests fail under a plain `xcodebuild test`.** Three pre-existing
  `DailyFitFrozenPayloadStorage_Tests` (`saveUsesNamespacedPathAndStampsEngineId`,
  `legacyFileRejectedForLegacyBaseline`, `Migration backfills earliest CardRevealed key`) fail because the DEBUG
  runtime override only applies when `DailyFitEngineConfig.allowsDevEngineTools` is true, which requires a build
  where `DAILY_FIT_ENGINE_ID` ≠ production. **Verified identical on the untouched `sky-forward-v1.0.1` tag** — not
  a regression. The B3 proof test was written to **not** depend on the override for this reason. Run the app suite
  with the CI dev-engine build config to exercise those three.
- **Swift Testing vs XCTest reporting.** The `import Testing` suites report `◇/✔/✘` lines; xcodebuild's "Executed
  0 tests" summary line refers only to XCTest. Grep for `✔ Test`/`✘ Test`/`Test run with … passed`.
- **The fidelity harness measures `CALIBRATION_ENGINE_ID`.** Default is `production` (still v1.0.1). Always set
  `CALIBRATION_ENGINE_ID=sky_forward_v1_0_2` when validating v1.0.2 **before** cutover; after cutover the default works.
- **`dominantTransits` has no tie-break** (dictionary-iteration order on equal orbs) — this is intentional to keep
  the v1.0.1 axis path byte-identical. Do not "fix" it (it would change the v1.0.1 fingerprint/output).
- **`DailyFitCalibration` is Equatable-only, not Codable.** Adding fields is safe for auto-synthesised Equatable.
- **Nudge order if a gate goes red** (plan §"Proposed fixed starting values"): gate (a) low → `skyVibeWeights.lunar`;
  gate (d) weak → `lunarSignificanceCoeff k`; gate (c) high → `axisTuning.jitterRange`; last resort `sigmoidSpread`.
  Each knob maps to one gate — they don't fight (a is off-syzygy, d is on-syzygy). **If a variation floor (owner
  priority) drops from the jitter cut, raise `jitterRange` back toward 0.40 / widen top-K — variation wins over
  the jitter-share target.** Each nudge = a new fingerprint = re-run from 12×60. **Never edit a G1 constant just
  to pass** (that's an owner escalation, G0).

---

## 8. One-shot command reference
```bash
# Fast engine type-check
cd inspector && swift build

# Fidelity gates (Rung 3) — v1.0.2
cd inspector && CALIBRATION_ENGINE_ID=sky_forward_v1_0_2 CALIBRATION_FIDELITY_GATE=1 \
  CALIBRATION_AUDIT_DIR=/tmp/audit_v102 swift test --filter CalibrationAudit_Tests

# Lunar almanac cross-check (Phase 5)
cd inspector && swift test --filter LunarEventDetector_Tests

# App unit rungs (pick a real sim id from: xcrun simctl list devices available)
SIM=148BC509-DCD4-4EED-AFC7-00495D1E0B06
xcodebuild test -scheme "Cosmic Fit" -destination "platform=iOS Simulator,id=$SIM" -parallel-testing-enabled NO \
  -only-testing:"Cosmic FitTests/DailyFitEngineRegistry_Tests" \
  -only-testing:"Cosmic FitTests/AstrologicalSoundness_Tests" \
  -only-testing:"Cosmic FitTests/DailyFitFrozenPayloadStorage_Tests"

# Rollback: verify byte-identical v1.0.1
#   set DAILY_FIT_ENGINE_ID=sky_forward_v1_0_1 (DEBUG override) and diff output vs production.
# Restore Phase-0 snapshot:
python3 tools/backup_content_sources.py restore --backup-dir data/content_backups/2026-07-15_pre-sky-forward-v1.0.2
```
