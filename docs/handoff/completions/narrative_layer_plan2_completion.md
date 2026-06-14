# Narrative Layer — Plan 2 Completion

**Developer**: 2 of 3 (sequential relay)  
**Date**: 2026-06-09  
**Engine scope**: `stage1_experimental` only. Production byte-identical.

---

## Objective

Implement a **narrative decision layer** with a **hard coherence contract** so that all visible surfaces on a given day derive from a single `DailyNarrativePlan`, and no plan ever contains essence opposition violations or cross-surface contradictions.

## Exit Gate Status

| # | Gate | Target | Result | Status |
|---|------|--------|--------|--------|
| G1 | Coherence contract implemented | `DailyNarrativeCoherence.validate` | Implemented: opposition + cross-surface + dimension scoring | PASS |
| G2 | `DailyNarrativePlan` type | All fields, Codable | 16 fields, Codable, Equatable | PASS |
| G3 | `DailyNarrativeSelector` functional | Valid plans for all presets | 300/300 valid (5 presets × 60 days) | PASS |
| G4 | Opposition violations == 0 | Zero across all plan-days | 0 | PASS |
| G5 | Cross-surface violations == 0 | Zero across all plan-days | 0 | PASS |
| G6 | Coherence score ≥ 0.85 | Mean ≥ 0.85 | 1.00 (all presets) | PASS |
| G7 | Plan 1 variation maintained | Briar: flip ≥ 40%, distinct ≥ 4 | Briar passes both (unit tested) | PASS |
| G8 | All surfaces routed through plan | 9 surfaces | All 9 routed | PASS |
| G9 | Stage1 no longer calls resolveEssenceConflicts | `essenceConflictTrace == nil` | Verified in test | PASS |
| G10 | Production fingerprint unchanged | Byte-identical | `ProductionFingerprintGuard_Tests` passing | PASS |
| G11 | Full test suite green | 0 failures | 441/441 pass | PASS |
| G12 | Plan 2 unit tests | ≥ 12 | 16 tests + 1 report generator | PASS |
| G13 | Coherence harness report | JSON + TXT | Committed | PASS |
| G14 | Shadow canvas | For Ash review | `narrative-layer-phase2-shadow.canvas.tsx` | PASS |
| G15 | Exit canvas | For Ash review | `narrative-layer-phase2-exit.canvas.tsx` | PASS |
| G16 | Completion doc | Committed | This document | PASS |

**Result: 16/16 gates PASS.**

---

## Architecture Delivered

### New Files
- `DailyNarrativeCoherence.swift` — Hard coherence contract: opposition validation, cross-surface compatibility, polarity profiling, dimension scoring.
- `DailyNarrativeSelector.swift` — Plan generation: relationship classification, intensity/tempo derivation, accent ranking with salience, candidate rejection, fallback.

### Modified Files
- `DailyFitTypes.swift` — Added `DailyNarrativePlan`, `IntensityLevel`, `TempoEmphasis`, `TextureDirective`, `PatternDirective`.
- `DailyFitPipeline.swift` — `stage1Experimental` routes through `DailyNarrativeSelector.select` → `BlueprintLensEngine.generatePayloadFromPlan`.
- `BlueprintLensEngine.swift` — Added `generatePayloadFromPlan`, `planDrivenEssence`, `planToIntent`, `selectDailyTexturesFromPlan`, `selectDailyPatternFromPlan`, `deriveMetalTonePublic`.
- `NarrativeSelectionDirectives.swift` — Added `Codable` to `TarotDirective`, `PaletteDirective`, `ScaleDirective`. Deprecated header.
- `NarrativeIntentEngine.swift` — Deprecated header (superseded by `DailyNarrativeSelector`).
- `NarrativeTarotBridgeSelector.swift` — Deprecated header (plan reads via `planToIntent` bridge).

### Test Files
- `DailyNarrativePlan_Tests.swift` — 16 tests across 5 suites (determinism, completeness, coherence contract, surface routing, variation) + 1 report generator.

### Harness & Fixtures
- `tools/narrative_coherence_harness.py` — Python harness for inspector-based coherence sweep.
- `docs/fixtures/narrative_coherence_report.json` — Full 300 plan-day report.
- `docs/fixtures/narrative_coherence_report.txt` — Human-readable summary with exit gate checks.

### Canvases
- `narrative-layer-phase2-shadow.canvas.tsx` — Shadow-mode report: hard gates, accent distribution, relationship distribution, routing comparison table.
- `narrative-layer-phase2-exit.canvas.tsx` — Exit gate dashboard: 16 gates, routing checklist, hard gate panel, artifact list, known gaps.

---

## Surface Routing Summary

| Surface | Old Path | Plan-Driven Path |
|---------|----------|-----------------|
| Essence top-3 | Independent scoring + post-hoc `resolveEssenceConflicts` | Plan accent + 2 supporting (opposition-free by construction) |
| Palette | Sky scoring + narrative slot bias | Plan `paletteDirective` via `planToIntent` bridge |
| Tarot | Bridge selector with intent bias | Plan `tarotDirective` target vector via `planToIntent` |
| Vibrancy | Blueprint baseline + sky vibe | Plan `targetVibrancy` (sky modulation + intensity modifier) |
| Contrast | Blueprint baseline + axis modulation | Plan `targetContrast` (axis modulation + relationship modifier) |
| Metal Tone | Blueprint baseline + transit/lunar | Plan `targetMetalTone` (same derivation) |
| Silhouette | Blueprint baseline + sky axes | Plan `targetSilhouette` (precomputed from sky axes) |
| Textures | Axis affinity + vibe bonus | Plan `textureDirective` (preferred affinities + intensity bias) |
| Pattern | Visibility gate + energy keywords | Plan `patternDirective` (gate + preferred energy) |

---

## Coherence Report Summary

| Preset | Plans | Oppositions | Cross-Sfc | Coherence | Flip Rate | Distinct #1 |
|--------|-------|-------------|-----------|-----------|-----------|-------------|
| fire   | 60    | 0           | 0         | 1.00      | 61.0%     | 3           |
| earth  | 60    | 0           | 0         | 1.00      | 0.0%      | 1           |
| air    | 60    | 0           | 0         | 1.00      | 20.3%     | 2           |
| water  | 60    | 0           | 0         | 1.00      | 25.4%     | 2           |
| leo    | 60    | 0           | 0         | 1.00      | 33.9%     | 3           |
| **Agg**| 300   | **0**       | **0**     | **1.00**  | 28.1%     | 2.2         |

---

## Known Gaps for Plan 3

1. **Synthetic preset flip rate < 40%**: Uniform-sign synthetic charts are less diverse than real birth charts. Briar (real) passes ≥ 40%. Six-slider normalization (Plan 3) may help.
2. **Earth preset locked to drama ×60**: Taurus-heavy charts strongly bias to `drama` via transit-to-essence category mapping. More diverse accent selection could improve with Plan 3 normalization.
3. **Plan-to-intent bridge still active**: Palette and tarot selection use `planToIntent` adapter. Full native plan routing for these surfaces is deferred to Plan 3.
4. **Distinct #1 for simple presets**: Earth=1, air=2, water=2 on synthetic charts. Briar=4+ on real chart. Plan 3 normalization should address.

---

## Plan 3 Handoff Notes

- `DailyNarrativePlan` is the single source of truth for all stage1 surfaces. Plan 3 can refine slider normalization without changing the plan structure.
- The coherence contract (`DailyNarrativeCoherence.validate`) runs at plan creation time. Any Plan 3 changes to accent selection must preserve the zero-violation invariant.
- Old guardrails (`NarrativeIntentEngine.resolve`, `resolveEssenceConflicts`) are deprecated but retained for production compatibility. Plan 3 may remove if production migrates to stage1.
- The `planToIntent` bridge is a temporary adapter. Plan 3 should evaluate whether palette and tarot can read directly from plan directives without the NarrativeIntent indirection.

---

**Developer 2 — STOP. Do not implement Plan 3.**
