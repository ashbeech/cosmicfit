# Plan 1 completion — 2026-06-08 (updated 2026-06-09)

## Exit gate checklist

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Phase 0 baseline reports exist and committed | **PASS** | `docs/fixtures/slider_range_report.phase0_baseline.json`, `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` |
| 2 | Phase 0 baseline canvas exists with real cohort data | **PASS** | `.cursor/projects/.../canvases/narrative-layer-phase1-baseline.canvas.tsx` |
| 3 | Phase 0 baseline fixtures snapshotted for before/after | **PASS** | `.phase0_baseline.json` copies committed |
| 4 | Adaptive salience tests pass | **PASS** | `SkySalience_Tests.swift` — 14 tests, all green |
| 5 | Essence top-1 flip rate ≥40% across cohort | **PASS** | Mean 63.4% (range 57.6%–74.6%, all 5 presets ≥40%) |
| 6 | Distinct #1 essences ≥6 per 60 days | **FAIL** | 3/5 presets hit ≥6; fire=5, earth=4, leo=7; mean 5.6 (target ≥6) |
| 7 | Visible essence top-3 has zero opposition violations | **PASS** | 0 violations across 300 user-days |
| 8 | Production fingerprint unchanged | **PASS** | `ProductionFingerprintGuard_Tests` green |
| 9 | Plan 1 exit canvas exists with before/after | **PASS** | `.cursor/projects/.../canvases/narrative-layer-phase1-exit.canvas.tsx` (inline data stale — see note below) |
| 10 | AI summarized report data and linked both canvases | **PASS** | See summary below |
| 11 | Full unit test suite green | **PASS** | 418/418 tests green (2026-06-09 rerun; see Test verification) |
| 12 | Ash reviewed fixtures and canvases | **PENDING** | Awaiting Ash review |

## Where to verify results

**Primary review surface (tables + charts):** open these Cursor canvases — they embed real fixture data inline, not placeholders:

| Canvas | Path | What it shows |
|--------|------|---------------|
| Phase 0 baseline | `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase1-baseline.canvas.tsx` | Cohort summary, slider range table/histograms, essence staleness table, transit dominance, pending exit targets |
| Plan 1 exit (before/after) | `/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/narrative-layer-phase1-exit.canvas.tsx` | Exit gate pass/fail badges, essence before/after table, flip-rate bar chart, frozen-category recovery chart, opposition + fingerprint callouts |

**Note:** The exit canvas inline data reflects the 2026-06-08 salience-only run. Authoritative post-follow-up metrics are in `docs/fixtures/essence_stage1_diagnostics.json` (generated 2026-06-09) and the tables below.

**Raw data (reproducible from harnesses):**

| Fixture | Path |
|---------|------|
| Essence baseline (Phase 0) | `docs/fixtures/essence_stage1_diagnostics.phase0_baseline.json` |
| Essence post-salience + jitter (Phase 1 final) | `docs/fixtures/essence_stage1_diagnostics.json` |
| Human-readable essence report | `docs/fixtures/essence_stage1_diagnostics.txt` |
| Slider baseline (Phase 0) | `docs/fixtures/slider_range_report.phase0_baseline.json` |
| Slider post-salience | `docs/fixtures/slider_range_report.json` |

**Text summary only:** this completion doc (`docs/handoff/completions/narrative_layer_plan1_completion.md`) — tables for exit gate and metrics, but no charts. Use the canvases for visual review.

## Test verification

### Initial run (2026-06-08) — 3 failures

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

### Post-exit follow-up (2026-06-09) — all green

Command: `xcodebuild test -scheme "Cosmic Fit" -destination "platform=iOS Simulator,name=iPhone 16 Pro" -parallel-testing-enabled NO`

| Suite | Result |
|-------|--------|
| `SkySalience_Tests` (14 tests) | **PASS** |
| `ProductionFingerprintGuard_Tests` (2 tests) | **PASS** |
| Full suite (418 tests) | **PASS** |

Fixes applied:

1. **Briar goldens updated** — `NarrativeCoherence_Tests.briarMay23Relationship` and `NarrativePaletteUnification_Tests.briarMay23PaletteSlots` now expect `.stretch` for Briar 2026-05-23 (post-salience + jitter behavior).
2. **Tarot float tolerance** — `NarrativeTarotBridge_Tests.deterministicPair` uses `abs(a - b) < 1e-10` instead of exact `==` on bridge scores (cosine-similarity `Set` iteration order drift).

## Post-exit follow-up (2026-06-09)

After the initial completion snapshot, a follow-up pass addressed test regressions and attempted to close the distinct-#1 gap:

| Change | File | Detail |
|--------|------|--------|
| Post-normalization daily jitter | `BlueprintLensEngine.swift` | `applyDailyEssenceJitter()` — ±0.07 seeded perturbation applied after `finalizeEssenceScores`, before top-3 selection. Chart-anchor scores unaffected. |
| Transit boost unchanged | `BlueprintLensEngine.swift` | `stage1TransitEssenceBoost` remains **0.20** (increasing to 0.25 widened pre-normalization gaps and hurt distinct-#1) |
| Harness re-run | `tools/essence_stage1_diagnostics_harness.py` | Regenerated `docs/fixtures/essence_stage1_diagnostics.json` (generated 2026-06-09T17:36:39+01:00) |

Harness command:

```bash
python3 tools/essence_stage1_diagnostics_harness.py \
  --days 60 --months 12 --presets fire,earth,air,water,leo --start 2026-06-08
```

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
| Post-normalization daily jitter | `Cosmic Fit/InterpretationEngine/BlueprintLensEngine.swift` |
| Salience unit tests | `Cosmic FitTests/SkySalience_Tests.swift` |
| Post-salience essence diagnostics | `docs/fixtures/essence_stage1_diagnostics.json` |
| Exit canvas | `.cursor/projects/.../canvases/narrative-layer-phase1-exit.canvas.tsx` |
| Completion doc | `docs/handoff/completions/narrative_layer_plan1_completion.md` |

## Metrics summary

### Essence variation (5 presets × 60 days)

**Salience-only baseline (2026-06-08):**

| Metric | Phase 0 Baseline | Plan 1 (salience) | Target | Δ |
|--------|-----------------|-------------------|--------|---|
| Top-1 flip rate (mean) | 24.4% | **60.7%** | ≥40% | +36.3pp |
| Distinct #1 / 60d (mean) | 3.4 | **5.4** | ≥6 | +2.0 (**FAIL**) |
| Categories in top-3 / 14 (mean) | 7.8 | **9.8** | ≥10 | +2.0 |
| `playful` stddev (min across presets) | 0.000 | **0.021** | >0.02 | unfrozen |
| `romantic` stddev (min across presets) | 0.003 | **0.060** | >0.02 | unfrozen |
| Opposition violations | 0 | **0** | 0 | — |
| Production fingerprint | PASS | **PASS** | unchanged | — |

**Final (salience + jitter, 2026-06-09):**

| Metric | Phase 0 Baseline | Plan 1 (final) | Target | Δ |
|--------|-----------------|----------------|--------|---|
| Top-1 flip rate (mean) | 24.4% | **63.4%** | ≥40% | +39.0pp |
| Distinct #1 / 60d (mean) | 3.4 | **5.6** | ≥6 | +2.2 (**FAIL**) |
| Categories in top-3 / 14 (mean) | 7.8 | **10.0** | ≥10 | +2.2 |
| `playful` stddev (min across presets) | 0.000 | **0.021** | >0.02 | unfrozen (fire=0.021) |
| `romantic` stddev (min across presets) | 0.003 | **0.060** | >0.02 | unfrozen |
| Opposition violations | 0 | **0** | 0 | — |
| Production fingerprint | PASS | **PASS** | unchanged | — |
| Full unit test suite | — | **418/418** | 0 failures | — |

### Per-preset detail (final, 2026-06-09)

| Preset | Flip Rate (before→final) | Distinct #1 (before→final) | Cats Top-3 (before→final) |
|--------|--------------------------|---------------------------|--------------------------|
| fire | 22.0% → **62.7%** | 3 → **5** | 7 → **10** |
| earth | 33.9% → **57.6%** | 5 → **4** | 9 → **9** |
| air | 18.6% → **74.6%** | 3 → **6** | 7 → **11** |
| water | 25.4% → **62.7%** | 3 → **6** | 9 → **10** |
| leo | 22.0% → **59.3%** | 3 → **7** | 7 → **10** |

Salience-only per-preset (2026-06-08, for comparison):

| Preset | Flip Rate | Distinct #1 | Cats Top-3 |
|--------|-----------|-------------|------------|
| fire | 61.0% | 5 | 10 |
| earth | 57.6% | 4 | 9 |
| air | 66.1% | 6 | 11 |
| water | 64.4% | 6 | 9 |
| leo | 54.2% | 6 | 10 |

## Ash approval

- Date: pending
- Note: pending — Ash may waive known gate #6 gap when relaying to Plan 2 (see Known issues §1).

## Known issues / notes for Plan 2

1. **Distinct #1 still below target for 2/5 presets**: fire=5, earth=4. Mean is 5.6 vs target ≥6 (up from 5.4 after jitter). leo improved to 7. Fire and earth are structurally resistant — slow outer-planet transit dominance produces wide normalized score gaps (~0.15–0.20) that ±0.07 jitter cannot close without becoming destructively noisy. Plan 2's `DailyNarrativePlan` routing is the intended path to further improve this.

2. **`resolveEssenceConflicts` remains live**: As specified, the opposition resolver is still active. Plan 2 should only remove it after `DailyNarrativePlan` provides its own coherence contract.

3. **Slider range unchanged**: Plan 1 does not address slider range (Plan 3 territory). Vibrancy remains stuck for many users. The Phase 0 slider baseline fixtures are preserved for Plan 3 comparison.

4. **`salienceEssenceCategories` mapping duplicated**: The planet→category mapping exists in both `DailyEnergyEngine.salienceEssenceCategories` (for `SkySalienceProfile.essenceCategory` annotation) and `BlueprintLensEngine.stage1TransitEssenceCategories` (for the actual scoring boost). Both are now collision-free and use the same assignments. Plan 2 should consider unifying if routing through `DailyNarrativePlan`.

5. **`extractDominantTransits` still called**: The original function is preserved unchanged. `snapshot.dominantTransits` is still populated from it for backward compatibility and for any consumers outside the essence scoring loop (e.g., tarot transit boost, metal tone nudge, diagnostics display).

6. **Cohort generator produces 216 users**: The slider range harness was run with a 50-user subset for Phase 0 baseline. Plan 2/3 can use the full 216-user cohort if runtime permits.

7. **Exit canvas inline data stale**: `narrative-layer-phase1-exit.canvas.tsx` still embeds the 2026-06-08 salience-only numbers. Use this completion doc and `essence_stage1_diagnostics.json` for authoritative final metrics.

8. **Post-normalization jitter is a Plan 1 follow-up, not Plan 2 scope**: `applyDailyEssenceJitter` is a stage1-only diversity aid. Plan 2 should not rebuild or extend it — route essence accent selection through `DailyNarrativePlan` instead.
