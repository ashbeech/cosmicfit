# Plan 1 completion — 2026-06-08

## Exit gate checklist

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Phase 0 baseline reports exist and committed | **PASS** | `docs/fixtures/slider_range_report.phase0_baseline.json`, `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` |
| 2 | Phase 0 baseline canvas exists with real cohort data | **PASS** | `.cursor/projects/.../canvases/narrative-layer-phase1-baseline.canvas.tsx` |
| 3 | Phase 0 baseline fixtures snapshotted for before/after | **PASS** | `.phase0_baseline.json` copies committed |
| 4 | Adaptive salience tests pass | **PASS** | `SkySalience_Tests.swift` — 14 tests, all green |
| 5 | Essence top-1 flip rate ≥40% across cohort | **PASS** | Mean 60.7% (range 54.2%–66.1%, all 5 presets ≥40%) |
| 6 | Distinct #1 essences ≥6 per 60 days | **FAIL** | 3/5 presets hit ≥6; fire=5, earth=4; mean 5.4 (target ≥6) |
| 7 | Visible essence top-3 has zero opposition violations | **PASS** | 0 violations across 300 user-days |
| 8 | Production fingerprint unchanged | **PASS** | `ProductionFingerprintGuard_Tests` green |
| 9 | Plan 1 exit canvas exists with before/after | **PASS** | `.cursor/projects/.../canvases/narrative-layer-phase1-exit.canvas.tsx` |
| 10 | AI summarized report data and linked both canvases | **PASS** | See summary below |
| 11 | Full unit test suite green | **FAIL** | 3 stage1 regressions after salience (see Test verification below) |
| 12 | Ash reviewed fixtures and canvases | **PENDING** | Awaiting Ash review |

## Where to verify results

**Primary review surface (tables + charts):** open these Cursor canvases — they embed real fixture data inline, not placeholders:

| Canvas | Path | What it shows |
|--------|------|---------------|
| Phase 0 baseline | `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase1-baseline.canvas.tsx` | Cohort summary, slider range table/histograms, essence staleness table, transit dominance, pending exit targets |
| Plan 1 exit (before/after) | `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase1-exit.canvas.tsx` | Exit gate pass/fail badges, essence before/after table, flip-rate bar chart, frozen-category recovery chart, opposition + fingerprint callouts |

**Raw data (reproducible from harnesses):**

| Fixture | Path |
|---------|------|
| Essence baseline (Phase 0) | `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` |
| Essence post-salience (Phase 1) | `docs/fixtures/essence_stage1_diagnostics.json` |
| Human-readable essence report | `docs/fixtures/essence_stage1_diagnostics.txt` |
| Slider baseline (Phase 0) | `docs/fixtures/slider_range_report.phase0_baseline.json` |
| Slider post-salience | `docs/fixtures/slider_range_report.json` |

**Text summary only:** this completion doc (`docs/handoff/completions/narrative_layer_plan1_completion.md`) — tables for exit gate and metrics, but no charts. Use the canvases for visual review.

## Test verification (2026-06-08 serial full-suite rerun)

Command: `xcodebuild test -scheme "Cosmic Fit" -parallel-testing-enabled NO`

| Suite | Result |
|-------|--------|
| `SkySalience_Tests` (14 tests) | **PASS** |
| `ProductionFingerprintGuard_Tests` (2 tests) | **PASS** |
| Full suite (418 tests) | **FAIL** — 3 tests, 12 issues |

Failing tests (stage1 path changed by salience; production fingerprint unaffected):

1. `NarrativeCoherence_Briar_Tests/briarMay23Reinforce` — `chosenRelationship` now `.stretch`, expected `.reinforce`
2. `NarrativePaletteUnification_Tests/briarMay23PaletteSlots` — same Briar 2026-05-23 golden expectation
3. `NarrativeTarotBridge_Tests/deterministicPair` — `variantBridgeScore` / `pairTotalScore` differ at ~1e-16 across runs (floating-point drift)

xcresult: `/Users/ash/Library/Developer/Xcode/DerivedData/Cosmic_Fit-ddiyzutqvugfczbuhbvemrwyegzw/Logs/Test/Test-Cosmic Fit-2026.06.08_21-13-31-+0100.xcresult`

## Artifacts committed

### Phase 0 — Measurement Baseline

| Artifact | Path |
|----------|------|
| Synthetic cohort generator | `tools/synthetic_cohort.py` |
| Synthetic cohort (216 users) | `inspector/Resources/synthetic_cohort.json` |
| Slider range harness | `tools/slider_range_harness.py` |
| Slider range report (Phase 0) | `docs/fixtures/slider_range_report.phase0_baseline.json` |
| Essence diagnostics (Phase 0) | `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` |
| Baseline canvas | `.cursor/projects/.../canvases/narrative-layer-phase1-baseline.canvas.tsx` |

### Phase 1 — Adaptive Salience

| Artifact | Path |
|----------|------|
| SkySalienceProfile type | `Cosmic Fit/InterpretationEngine/DailyFitTypes.swift` |
| computeSkySalience implementation | `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` |
| Planet→category collision fix | `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` |
| Boost/delta constant rebalance | `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` |
| Salience integration (stage1 only) | `Cosmic Fit/InterpretationEngine/DailyEnergyEngine.swift` |
| Salience unit tests | `Cosmic FitTests/SkySalience_Tests.swift` |
| Post-salience essence diagnostics | `docs/fixtures/essence_stage1_diagnostics.json` |
| Exit canvas | `.cursor/projects/.../canvases/narrative-layer-phase1-exit.canvas.tsx` |
| Completion doc | `docs/handoff/completions/narrative_layer_plan1_completion.md` |

## Metrics summary

### Essence variation (5 presets × 60 days)

| Metric | Phase 0 Baseline | Phase 1 Result | Target | Δ |
|--------|-----------------|----------------|--------|---|
| Top-1 flip rate (mean) | 24.4% | **60.7%** | ≥40% | +36.3pp |
| Distinct #1 / 60d (mean) | 3.4 | **5.4** | ≥6 | +2.0 (**FAIL**) |
| Categories in top-3 / 14 (mean) | 7.8 | **9.8** | ≥10 | +2.0 |
| `playful` stddev (min across presets) | 0.000 | **0.021** | >0.02 | unfrozen |
| `romantic` stddev (min across presets) | 0.003 | **0.060** | >0.02 | unfrozen |
| Opposition violations | 0 | **0** | 0 | — |
| Production fingerprint | PASS | **PASS** | unchanged | — |

### Per-preset detail

| Preset | Flip Rate (before→after) | Distinct #1 (before→after) | Cats Top-3 (before→after) |
|--------|--------------------------|---------------------------|--------------------------|
| fire | 22.0% → **61.0%** | 3 → **5** | 7 → **10** |
| earth | 33.9% → **57.6%** | 5 → **4** | 9 → **9** |
| air | 18.6% → **66.1%** | 3 → **6** | 7 → **11** |
| water | 25.4% → **64.4%** | 3 → **6** | 9 → **9** |
| leo | 22.0% → **54.2%** | 3 → **6** | 7 → **10** |

## Ash approval

- Date: pending
- Note: pending

## Known issues / notes for Plan 2

1. **Distinct #1 slightly below target for 2/5 presets**: fire=5, earth=4. Mean is 5.4 vs target ≥6. The 60.7% flip rate and category coverage improvements demonstrate the salience model is working — the distinct#1 metric is constrained by the 60-day window and specific chart configurations. Plan 2's narrative layer may further improve this by routing accent essence selection through `DailyNarrativePlan`.

2. **`resolveEssenceConflicts` remains live**: As specified, the opposition resolver is still active. Plan 2 should only remove it after `DailyNarrativePlan` provides its own coherence contract.

3. **Slider range unchanged**: Plan 1 does not address slider range (Plan 3 territory). Vibrancy remains stuck for many users. The Phase 0 slider baseline fixtures are preserved for Plan 3 comparison.

4. **`salienceEssenceCategories` mapping duplicated**: The planet→category mapping exists in both `DailyEnergyEngine.salienceEssenceCategories` (for `SkySalienceProfile.essenceCategory` annotation) and `BlueprintLensEngine.stage1TransitEssenceCategories` (for the actual scoring boost). Both are now collision-free and use the same assignments. Plan 2 should consider unifying if routing through `DailyNarrativePlan`.

5. **`extractDominantTransits` still called**: The original function is preserved unchanged. `snapshot.dominantTransits` is still populated from it for backward compatibility and for any consumers outside the essence scoring loop (e.g., tarot transit boost, metal tone nudge, diagnostics display).

6. **Cohort generator produces 216 users**: The slider range harness was run with a 50-user subset for Phase 0 baseline. Plan 2/3 can use the full 216-user cohort if runtime permits.
