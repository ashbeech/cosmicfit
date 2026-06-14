# Tarot Form Bridge — Sign-off Fixture

**Date:** 2026-06-11
**Author:** Implementation agent
**Spec:** `docs/handoff/tarot_narrative_form_bridge_handoff.md`

---

## Summary

Tarot variant selection now uses **both** narrative energy **and** narrative form (silhouette structure via the strategy emphasis axis). Two mechanisms:

1. **Soft cosine form channel** (`variantFormBridgeWeight = 0.20`) — scores `variant.axesEmphasis` against a plan-derived `targetAxesVector` blending sky axes and silhouette structure.
2. **Hard strategy-floor gate** — when `structuredDraped < 0.15`, variants with `axesEmphasis["strategy"] < 50` receive a -10.0 penalty, effectively excluding them from winning.

---

## Files changed

| File | Change |
|------|--------|
| `NarrativeSelectionDirectives.swift` | Extended `TarotDirective` with `targetAxesVector` + `structuredDraped`; added `targetAxesVector()`, `targetAxesVectorSkyOnly()`, `axesDictionary(from:)`, `cosineSimilarityAxes()` helpers |
| `DailyFitTypes.swift` | Extended `NarrativeSelectionTuning` with 6 form-bridge fields; extended `NarrativeBridgeTrace` with `variantFormBridgeSimilarity`, `formBridgePass`, `structureGateApplied` |
| `NarrativeTarotBridgeSelector.swift` | Extended `Candidate` with `variantFormBridgeScore`; added dual-channel scoring + hard strategy gate in Stage B; updated trace construction |
| `DailyNarrativeSelector.swift` | `buildPlan()` now emits `targetAxesVector` + `structuredDraped` on `TarotDirective` |
| `NarrativeIntentEngine.swift` | `buildIntent()` now emits `targetAxesVector` (silhouette-aware or sky-only fallback) + `structuredDraped` |
| `DailyNarrativeCoherence.swift` | `scorePayloadCoherence` tarotMatch now checks both energy and form; added `validateTarotForm()` structure gate |
| `DailyFitEngineRegistry.swift` | `canonicalCalibrationString` serializes new tuning fields (stage1 fingerprint changes; production/legacy unchanged) |
| `inspector/.../app.js` | Trace markdown renderer shows form similarity, form bridge pass, and structure gate applied |
| `NarrativeTarotBridge_Tests.swift` | 8 new tests: structure gate enforcement, inactivity above threshold, pool-never-empty, soft form preference, nil-safety, trace field population, coherence gate tests |

## Files NOT modified

- `TarotCards.json` (zero copy edits)
- Production/legacy preset calibrations
- `DailyFitViewController` or any UI layer

---

## Test results

| Test | Result |
|------|--------|
| `ProductionFingerprintGuard_Tests` | PASS — production fingerprint unchanged |
| `DailyFitEngineRegistry_Tests` | PASS — all descriptors resolve, fingerprints differ |
| `NarrativeTarotBridge_Tests` (full suite, 23 tests) | PASS |
| `structureGate_excludesLowStrategyVariant_whenStructured` | PASS — variant with strategy=21 excluded when structuredDraped=0.05 |
| `structureGate_inactiveAboveThreshold` | PASS — gate off when structuredDraped=0.5 |
| `structureGate_neverEmptiesPool` | PASS — returns candidate even with extreme gate |
| `structureGate_flagsDiplomatOnStructuredDay` | PASS — coherence validator flags contradiction |
| `structureGate_silentOnRelaxedDay` | PASS — no false positive on relaxed days |

---

## Wren 2026-06-11 expected outcome

With the hard structure gate active:

- `structuredDraped = 0.073` < threshold `0.15` → gate fires
- Diplomat `axesEmphasis.strategy = 21` < floor `50` → penalized by -10.0
- Diplomat cannot win pair total regardless of energy bridge advantage (+0.022 margin)
- A higher-strategy variant or different card will be selected

**Acceptance:** no selected variant with `axesEmphasis.strategy < 50` when `structuredDraped < 0.15`.

---

## Tuning parameters (stage1Default)

| Parameter | Value |
|-----------|-------|
| `variantBridgeWeight` | 0.25 (energy, unchanged) |
| `variantFormBridgeWeight` | 0.20 (form, new) |
| `structureSkyWeight` | 0.35 |
| `structureSilhouetteWeight` | 0.65 |
| `minFormBridgeSimilarity` | 0.45 |
| `structureVariantStrategyFloor` | 50 |
| `structureSliderThreshold` | 0.15 |

---

## Phase 2 — 216×60 cohesion harness (2026-06-11)

Ran `NarrativeCohesionReport_Tests/generateCohesionReport` (216 users × 60 days = 12,960 payloads).

| Metric | Result |
|--------|--------|
| Test outcome | PASS (~47s) |
| Mean coherence score | **1.0000** (target ≥ 0.85) |
| Opposition violations | 0 |
| Cross-surface violations | 0 |
| Structure contradictions (SD<0.15 ∧ strategy<50) | **0** (inferred via coherence tarotMatch dimension — harness does not yet emit dedicated form-bridge aggregates) |
| Accent-salience match | 37.4% (pre-existing; unrelated to form bridge) |

All 23 `NarrativeTarotBridge_Tests` pass including structure gate tests.

### Remaining Phase 2

- [ ] Extend cohesion harness to emit `structureGateApplied`, `variantFormBridgeSimilarity`, and explicit contradiction counts
- [ ] Run Wren 14-day inspector export with new trace fields
- [ ] Run Briar 14-day — document card/variant deltas
- [ ] Wire `formBridgePass` into `NarrativeCoherenceTrace.overallPass`
- [ ] Manual read: 3 high-structure days + 3 high-relaxed days — copy matches slider

---

*End of sign-off.*
