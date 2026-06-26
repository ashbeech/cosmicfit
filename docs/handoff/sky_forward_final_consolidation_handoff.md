# Sky Forward — Final Consolidation Handoff

**Date:** 2026-06-25  
**Audience:** AI developer (fresh context window)  
**Goal:** Produce **one final, authoritative Sky Forward engine** (`DailyFitEngineMode.stage1Experimental`) containing all passing elements — without losing work, duplicating paths, or overwriting legacy regression presets.

**Status at handoff:** Engine logic is largely consolidated in code, but **slider fixes from 25 Jun session are uncommitted**, and **full 216×60 / 223×60 cohort re-audits have not been run on the latest slider amends**.

---

## 1. Executive summary (read this first)

Sky Forward **already ships as `production`** in Release builds. It is **not** a separate fork from `stage1_experimental`:

| Registry entry | Engine ID | Display name | Mode | Calibration | Shipped? |
|---|---|---|---|---|---|
| `productionDescriptor` | `production` | **Sky Forward v1.0.0** | `.stage1Experimental` | `stage1ExperimentalCalibration` | **Yes (Release)** |
| `stage1ExperimentalDescriptor` | `stage1_experimental` | DEBUG alias | `.stage1Experimental` | Same | DEBUG only |
| `legacyBaselineDescriptor` | `legacy_baseline` | Legacy Baseline | `.standard` | Pre–Stage 2 weights | DEBUG regression |
| `stage2LegacyDescriptor` | `stage2_legacy` | Pre-Sky Forward | `.standard` | `.default` / dramaSlots | DEBUG regression |

**Promotion model used (Jun 19, commit `2290f86`):** Repointed `production` to use stage1 calibration + mode. **`if mode == .stage1Experimental` guards were NOT removed** — production passes through them.

**Your job:** Merge the **latest passing slider amends** (uncommitted) into a clean commit, re-run full cohort audits, confirm gates, and optionally bump marketing version — **without** breaking fingerprint guards or deleting `.standard` legacy paths.

---

## 2. What “single final version” means

There is **one math pipeline** for shipped users:

```
Release app
  → DailyFitEngineConfig.effectiveEngineId == "production"
  → DailyFitEngineRegistry.mode(for: "production") == .stage1Experimental
  → DailyFitPipeline.generate → DailyNarrativePlan path
  → All stage1Experimental branches in DailyEnergyEngine + BlueprintLensEngine
```

There are **two ID strings** (`production` vs `stage1_experimental`) that differ only in:
- UserDefaults keys (tarot recency, variant rotation, frozen payloads)
- DEBUG tab banner

**Do not** build a third parallel engine path. **Do not** assume `stage1_experimental` is the “real” engine and `production` is old Stage 2.

---

## 3. Version timeline (git commits)

| Commit | Date | Engine significance |
|---|---|---|
| `2290f86` | 2026-06-19 | **Sky Forward promotion:** `production` → `stage1ExperimentalCalibration`, `mode: .stage1Experimental`, marketing v1.0.0 |
| `6e63d02` / narrative PR | 2026-06-10–14 | Narrative layer (DailyNarrativePlan, cohesion, plan-driven payloads) |
| `ec9f7d8` | 2026-06-25 08:45 | **Slider tuning wave 1:** contrast sky vibe/tempo (0.20/0.12), envelope 0.22; metal (0.40/0.24/0.36); silhouette half-spans 0.34; `computeStage1ContrastRaw` |
| `04b24e2` | 2026-06-25 11:57 | **Last committed HEAD** for big audits; no further `InterpretationEngine/` changes vs `ec9f7d8` |
| **Working tree (uncommitted)** | 2026-06-25 ~19:00 | **Slider tuning wave 2:** contrast 0.32/0.18, envelope 0.28; M/F two-driver + axis speed damping; `SliderSignalValidation_Tests.swift` |

### Marketing / product version

- `DailyFitEngineRegistry.productionMarketingVersion` = **`"1.0.0"`**
- Profile line: `"Sky Forward v1.0.0"`

Consider bumping to **v1.0.1** (or v1.1.0) only after full cohort re-audit passes with wave-2 slider constants.

---

## 4. Audit results (what passed on which code)

### 4.1 Production audit — 223 users × 60 days

**Run:** 2026-06-25, summary at 13:51  
**Engine ID:** `production` (see `docs/fixtures/production_audit_v2/manifest.json`)  
**Code:** commit `04b24e2` (wave-1 slider constants)  
**Window:** 2026-04-26 → 60 days  

**Passed:**
- 66,900 / 66,900 verdict checks
- 0 gap days, 0 tarot adjacent repeats, 0 hard-block violations
- Cohesion 1.0, essences max streak 1

**Slider display-range stuck users (wave-1 code):**
- vibrancy: 0, contrast: 0, metalTone: 1
- **masculineFeminine: 15**, angularRounded: 0, **structuredDraped: 7**

**Artifacts:** `docs/fixtures/production_audit_v2/summary.txt`, `summary.json`, `raw/`, `blueprints/`

### 4.2 Narrative cohesion — 216 users × 60 days

**Run:** 2026-06-25, fixtures at 12:35  
**Engine label in report:** `stage1_experimental` (same math/fingerprint as `production`)  
**Code:** commit `04b24e2` (wave-1 slider constants)  

**Hard gate assertions (Swift test):**
```swift
#expect(aggOppositions == 0)
#expect(crossSurfaceRate < 0.001)  // 7/12960 ≈ 0.054% → passes rate gate
#expect(meanCoherence >= 0.85)     // 1.0 → passes
```

**Report metrics (not all green):**
- Opposition: 0 ✓
- Cross-surface: **7 violations** (zero-tolerance line in report says FAIL; rate gate passes)
- Distinct #1 essences: **4.7** (target ≥ 6 — WEAK; documented exception in promotion doc)
- **Slider stuck (display range < 0.33 over 60d):** contrast **30%**, M/F **44%**

**Artifacts:** `docs/fixtures/narrative_cohesion_report.txt`, `.json`, `slider_range_report.json`

### 4.3 Quick validation — 12 users × 60 days (wave-2 code)

**Test:** `Cosmic FitTests/SliderSignalValidation_Tests.swift` (**uncommitted**, must add to Xcode project if not already)  
**Code:** working tree (wave-2 slider amends)  
**Result:** **PASSED** (2026-06-25)

| Slider | meanRange | stuck % |
|---|---|---|
| contrast | 0.441 | 8% |
| metalTone | 0.705 | 0% |
| masculineFeminine | 0.498 | 0% |
| angularRounded | 0.597 | 0% |
| structuredDraped | 0.512 | 0% |

**Not yet run on 216/223 cohort with wave-2 code.**

---

## 5. Uncommitted work you MUST preserve (wave-2 slider amends)

### 5.1 Files changed (engine — commit these)

| File | Changes |
|---|---|
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Contrast scales, envelope, M/F two-driver formula, `Stage1ScaleSensitivity` constants |
| `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` | `axisSpeedDamping` + apply in `computeAxisRawScoreSkyOnly` |

### 5.2 New test file (add to target + commit)

| File | Purpose |
|---|---|
| `Cosmic FitTests/SliderSignalValidation_Tests.swift` | Fast 12×60 slider gate; asserts contrast/MF/AR/SD targets |

**Note:** `Cosmic FitTests` uses `PBXFileSystemSynchronizedRootGroup` — new `*Tests.swift` files under `Cosmic FitTests/` are picked up automatically (no manual `pbxproj` entry required).

### 5.3 Target constants after wave-2 (final slider tuning)

In `Stage1ScaleSensitivity` (`BlueprintLensEngine.swift`):

```swift
// Contrast
contrastVibeScale = 0.32      // was 0.20 at 04b24e2
contrastTempoScale = 0.18     // was 0.12
contrastPracticalHalfSpan = 0.28  // was 0.22

// Metal (unchanged in wave-2 — keep)
metalVibeScale = 0.40
metalTempoScale = 0.24
metalPracticalHalfSpan = 0.36

// Vibrancy (unchanged — keep)
vibrancyPracticalHalfSpan = 0.22

// Silhouette envelopes (unchanged — keep)
silhouetteMFARPracticalHalfSpan = 0.34
silhouetteSDPracticalHalfSpan = 0.34

// M/F two-driver (new in wave-2)
mfVisibilityScale = 0.24
mfVisibilityDivisor = 2.5     // tanh divisor; was effectively 4.5 via shared skyMod
mfTempoScale = 0.20
```

M/F formula (`deriveSilhouetteProfile`, `mode == .stage1Experimental`):
```swift
mfVisMod = tanh((visibility - 5.5) / mfVisibilityDivisor) * mfVisibilityScale
mfTempoMod = (tempo/10 - 0.5) * mfTempoScale
mf = clamp(mfBase + mfVisMod + mfTempoMod)
// AR/SD unchanged: single-axis tanh × 0.28 on action/strategy
```

In `DailyEnergyEngine.swift` — `axisSpeedDamping` (sqrt-dampened, applied in `computeAxisRawScoreSkyOnly` only):
```swift
Moon: 1.0, Mercury: 0.95, Venus: 0.92, Sun: 0.89, Mars: 0.84,
Jupiter: 0.63, Saturn: 0.55, Uranus: 0.45, Neptune: 0.39, Pluto: 0.32
```

**Separate from axis damping:** `salienceSpeedFactors` in essence selection (more aggressive de-weighting of outers) — **do not conflate or overwrite**.

---

## 6. Code map — where Sky Forward logic lives

### 6.1 Registry & config (start here)

| File | Role |
|---|---|
| `Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift` | **Single source of truth** for presets, calibration, mode, fingerprint |
| `Cosmic Fit/Core/Config/DailyFitEngineConfig.swift` | Release → always `productionId` |
| `Cosmic Fit/InterpretationEngine/DailyFitPipeline.swift` | Routes `.stage1Experimental` → plan-driven payload |

### 6.2 Stage 1 energy (DailyEnergyEngine.swift)

Gated on `effectiveMode == .stage1Experimental` (production uses this):

- Chart vs sky vibe split (`chartVibeProfile`, `skyVibeProfile`)
- Daily vibe = sky only; sign multipliers via `.stage1OptionA` (daily OFF, chart ON)
- Sky-only axes via `computeAxisRawScoreSkyOnly` (+ **axisSpeedDamping** in wave-2)
- Adaptive sky salience (`computeSkySalience`) for narrative selection
- Daily seed policy `.includesEngineId` for production

### 6.3 Narrative & payload (plan-driven)

| File | Role |
|---|---|
| `Cosmic Fit/InterpretationEngine/DailyNarrativeSelector.swift` | Single daily narrative plan |
| `Cosmic Fit/InterpretationEngine/DailyNarrativeCoherence.swift` | Coherence validation |
| `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` | Essence, palette, tarot, scales, silhouette, `generatePayloadFromPlan` |
| `Cosmic Fit/InterpretationEngine/NarrativeTarotBridgeSelector.swift` | Joint tarot/variant bridge |
| `Cosmic Fit/InterpretationEngine/NarrativeIntentEngine.swift` | Legacy intent (DEBUG trace only; plan supersedes for payload) |

### 6.4 Sliders (derivation + display)

| File | Role |
|---|---|
| `BlueprintLensEngine.swift` → `Stage1ScaleSensitivity` | **All tuning constants** (derivation) |
| `BlueprintLensEngine.swift` → `computeStage1ContrastRaw` | Contrast raw value |
| `BlueprintLensEngine.swift` → `deriveSilhouetteProfile` | M/F, AR, SD |
| `Cosmic Fit/InterpretationEngine/PersonalScaleEnvelope.swift` | Display envelopes + `displayPosition` (UI reads this) |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | `refreshDiamondScalePositions()` uses `scalePresentation` |

### 6.5 Recency / persistence (engine-ID-sensitive)

| File | production-specific behaviour |
|---|---|
| `TarotRecencyTracker.swift` | Legacy namespace migration only when `dailyFitEngineId == productionId` |
| `TarotVariantRotationTracker.swift` | Same pattern |
| `DailyFitFrozenPayloadStorage.swift` | Reveal keys omit engine prefix for `production` |
| `VisibleEssenceRecencyTracker.swift` | Keys include engine id |

### 6.6 Legacy paths — DO NOT DELETE OR “CONSOLIDATE AWAY”

These run only for `mode == .standard` (`legacy_baseline`, `stage2_legacy`):

- `DailyFitPipeline.generate` → `generatePayload` (non-plan path)
- `deriveContrast` standard branch (visibility-only linear)
- `deriveSilhouetteProfile` standard branch (linear, no tempo)
- `computeAxisRawScore` (full natal+progressed mix)
- `deriveStyleEssenceProfile` (non-stage1)

**Required for:** `ProductionFingerprintGuard_Tests`, `DailyFitEngineRegistry_Tests`, DEBUG engine picker regression.

---

## 7. DO NOT overwrite (common mistakes)

| Mistake | Why it's wrong |
|---|---|
| Revert wave-2 slider amends because 216-report shows old stuck % | Report is **stale** (pre wave-2); re-run audits first |
| Copy slider fixes into `.standard` branches “for production” | Shipped production **already uses** `.stage1Experimental` |
| Remove `if mode == .stage1Experimental` guards | Promotion doc suggested this but **was not done**; production depends on these branches |
| Point `production` back to `.standard` / `.default` calibration | Would undo Sky Forward entirely |
| Change `stage1ExperimentalCalibration` without updating fingerprint + `ProductionFingerprintGuard_Tests` | Fingerprint guard will fail |
| Gate math on `engineId == stage1ExperimentalId` | Would **exclude** shipped `production` users |
| Over-tighten AR/SD when fixing M/F | AR/SD were 0% stuck on 216 cohort; wave-2 axis damping affects them — monitor in re-audit |

---

## 8. Stale or misleading docs (do not trust blindly)

| Doc / comment | Issue |
|---|---|
| `docs/fixtures/narrative_layer_promotion_recommendation.md` | Says “remove guards”; actual promotion was registry repoint |
| `DailyFitTypes.swift` comment on `skySalience` | Says “nil in production”; **wrong** — Sky Forward populates it |
| `docs/fixtures/narrative_cohesion_report.txt` | Generated 12:35 on wave-1 code; slider stuck % outdated |
| `docs/fixtures/production_audit_v2/summary.txt` | Generated 13:51 on wave-1 code; MF/SD stuck counts outdated |
| `tools/regenerate_cohesion_report.sh` | Uses `-only-testing:.../generateCohesionReport` — **may run 0 tests** with Swift Testing; use suite-level filter (see §9) |

---

## 9. Validation checklist (run in order)

### Step 1 — Unit / integration (fast)

```bash
# Build tests
xcodebuild build-for-testing -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Slider quick gate (wave-2)
xcodebuild test-without-building -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing "Cosmic FitTests/SliderSignalValidation_Tests" \
  -parallel-testing-enabled NO

# Regression suites
xcodebuild test-without-building ... \
  -only-testing "Cosmic FitTests/PersonalScaleEnvelope_Tests" \
  -only-testing "Cosmic FitTests/BlueprintLensEngine_Payload_Tests" \
  -only-testing "Cosmic FitTests/DailyFitCoherence_Tests" \
  -only-testing "Cosmic FitTests/DailyFitEngineRegistry_Tests" \
  -only-testing "Cosmic FitTests/ProductionFingerprintGuard_Tests"
```

### Step 2 — Narrative cohesion 216×60 (plan-level, ~30 min)

Use **suite-level** filter (not `/generateCohesionReport` — that ran 0 tests in CLI):

```bash
xcodebuild test -workspace "Cosmic Fit.xcworkspace" -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing "Cosmic FitTests/NarrativeCohesionReport_Tests" \
  -parallel-testing-enabled NO \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 1800
```

**Expect:** Updates `docs/fixtures/narrative_cohesion_report.{txt,json}` and `slider_range_report.json`.

**Hard gates:** opposition == 0, crossSurfaceRate < 0.001, coherence ≥ 0.85.

**Review:** Slider stuck % for contrast and M/F should improve vs wave-1 report (30%/44%).

### Step 3 — Production audit 223×60 (payload-level, ~4+ hours)

Requires inspector running (`cd inspector && ./run-inspector.sh`).

```bash
python3 tools/production_audit_harness.py \
  --days 60 --start 2026-04-26 --synthetic-stride 1 \
  --parallel 5 --out docs/fixtures/production_audit_v2

python3 tools/production_audit_analyze.py --in docs/fixtures/production_audit_v2
```

**Engine:** `production` (hardcoded in harness — correct for shipped simulation).

**Target improvements vs wave-1 summary:** MF stuck 15→ lower, SD stuck 7→ lower; maintain 0 verdict failures.

---

## 10. Consolidation tasks (recommended order)

1. **Commit wave-2 engine changes** — `BlueprintLensEngine.swift`, `DailyEnergyEngine.swift`, `SliderSignalValidation_Tests.swift`.

2. **Do NOT merge** unrelated UI/legal changes in the same commit unless Ash requests it (current working tree has many non-engine mods).

3. **Re-run Step 2 + Step 3** (§9) on committed wave-2 code; refresh fixtures.

4. **Compare** wave-2 cohesion slider metrics to wave-1; confirm contrast stuck < 20%, M/F stuck < 25% (or better).

5. **Run `ProductionFingerprintGuard_Tests`** — if calibration constants changed, fingerprint may need bumping in registry (only if intentional).

6. **Optional:** Bump `productionMarketingVersion` to reflect slider fix release.

7. **Optional long-term:** Remove redundant `stage1_experimental` DEBUG alias once frozen-payload migration complete — **not required for beta**.

---

## 11. Passing elements inventory (what “all passing” should include)

### Must pass (hard gates)

- [ ] Opposition violations == 0 (216×60 cohesion)
- [ ] Cross-surface rate < 0.1% (216×60 cohesion test assertion)
- [ ] Coherence ≥ 0.85 (216×60)
- [ ] Production fingerprint guard (450/450 or current baseline)
- [ ] Production audit verdicts == 0 failures (223×60)
- [ ] Tarot adjacent repeats == 0, hard-block violations == 0
- [ ] Zero gap days (complete payloads)

### Should pass (product quality — wave-2 targets)

- [ ] Contrast slider stuck < 20% on 216 cohort (was 30% wave-1)
- [ ] M/F slider stuck < 25% on 216 cohort (was 44% wave-1)
- [ ] MF stuck users on 223 audit materially below 15
- [ ] SD stuck users on 223 audit materially below 7
- [ ] AR/SD remain healthy (0% stuck on wave-1; do not regress)

### Documented exceptions (acceptable if re-audit confirms)

- [ ] Distinct #1 essences mean < 6 (synthetic cohort limitation — see `docs/fixtures/narrative_layer_promotion_recommendation.md`)
- [ ] Cross-surface absolute count > 0 but rate < 0.1% (7 events on 12960 days)

---

## 12. Key related handoffs (read if touching that area)

| Doc | When to read |
|---|---|
| `docs/handoff/unified_daily_fit_audit_handoff.md` | Audit harness fixes, production_audit_v2 results |
| `docs/handoff/daily_fit_stage1_experimental_app_readiness_handoff.md` | App/inspector parity, payload fields |
| `docs/handoff/daily_fit_personal_scale_sliders_handoff.md` | Envelope design intent |
| `docs/handoff/dailyfit_production_audit_fix_handoff.md` | Tarot variant recency, broad release gates |
| `docs/fixtures/narrative_layer_promotion_recommendation.md` | Narrative promotion exceptions |
| `docs/handoff/daily_fit_narrative_unification_v1_cleanup_v1_1_handoff.md` | Narrative plan architecture |

---

## 13. Architecture diagram

```
                    DailyFitEngineRegistry
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
    production          stage1_experimental   stage2_legacy / legacy_baseline
    (Sky Forward)       (DEBUG alias)         (DEBUG regression)
    mode: stage1Exp     mode: stage1Exp       mode: standard
         │                    │                    │
         └──────────┬─────────┘                    │
                    ▼                              ▼
           DailyFitPipeline                 legacy generatePayload
                    │
                    ▼
         DailyNarrativeSelector → DailyNarrativePlan
                    │
                    ▼
         BlueprintLensEngine.generatePayloadFromPlan
                    │
      ┌─────────────┼─────────────┐
      ▼             ▼             ▼
 DailyEnergy    Essence/       PersonalScaleEnvelope
 (snapshot)     Palette/Tarot   (displayPosition → UI)
```

---

## 14. One-line answer for Ash

**The last big cohort tests ran on Sky Forward v1.0.0 @ commit `04b24e2` (wave-1 sliders). Wave-2 slider fixes are uncommitted and only proven on 12×60. Your job: commit wave-2, re-run 216×60 + 223×60, confirm all gates, ship one final Sky Forward — without touching legacy `.standard` presets or duplicating engine paths.**

---

*End of handoff.*
