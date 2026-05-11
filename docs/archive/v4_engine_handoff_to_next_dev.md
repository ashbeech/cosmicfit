# V4 Colour Engine — Developer Handoff

**Date**: 2026-04-18  
**Plan file**: `.cursor/plans/colour_palette_v4_rework_feeeb9bb.plan.md`  
**Previous chat**: d93104cc-3c26-4cf1-a076-327653340bca

---

## 1. What's been built

The full `ColourEngineV4` module is implemented and compiles in:

```
Cosmic Fit/InterpretationEngine/ColourEngineV4/
  Domain.swift          — all enums, structs (PaletteFamily, DerivedVariables, etc.)
  DriverWeights.swift   — locked weights: 24/20/16/14/10/8/5/3 summing to 100
  SignContributions.swift — 12-sign contribution table (integers, matches TS spec §6)
  Normalize.swift       — normalizes 8 weighted drivers from BirthChartColourInput
  Scoring.swift         — raw score accumulation: Σ(delta × weight)
  Modifiers.swift       — 4 modifiers in locked order: Scorpio density, Cap/Virgo cooling, fire-air chroma, water softening
  Thresholds.swift      — bucket derivation (used for trace, NOT for final output)
  Overrides.swift       — earth-depth, winter compression, surface preservation, cool-leaning DA flag
  FamilyMapping.swift   — *** THIS IS THE FILE THAT NEEDS CALIBRATION WORK ***
  FamilyProfiles.swift  — canonical variable profiles per family (fixed lookup)
  ClusterMapping.swift  — cluster from variables + family
  SecondaryPull.swift   — metadata-only pull derivation
  PaletteLibrary.swift  — 12 palette templates + 132 colour name-to-hex mappings
  ColourEngine.swift    — top-level evaluateStrict/evaluateProduction entry points
  ChartInputAdapter.swift — converts NatalChart + ChartAnalysis → BirthChartColourInput
```

### Key architectural decision

Each PaletteFamily has a **fixed canonical variable profile** (see `FamilyProfiles.swift`). The V4 dataset confirms this: every row in a given family has the exact same depth/temperature/saturation/contrast/surface values. Therefore:

- The engine classifies **family** first
- Then looks up the **canonical variables** for that family
- Variables, cluster, and palette all flow from the family

This means the **only classification target** is the family. Getting the family right = getting everything right.

## 2. Test infrastructure

All in `Cosmic FitTests/`:

| File | Status | Purpose |
|------|--------|---------|
| `ColourEngineV4_UnitTests.swift` | **36/36 passing** | Modifier math, threshold edges, override logic, driver weights, palette completeness |
| `V4CalibrationRegression_Tests.swift` | **51/100 passing** | Hard-gate: exact match on all 8 fields across 100 V4 rows |
| `V4CalibrationDiagnostic_Tests.swift` | passing | Writes `docs/fixtures/v4_calibration_diagnostic.txt` with per-family score distributions |
| `V4CalibrationOptimizer_Tests.swift` | passing | Grid-searches scale factors for centroid classifier |
| `V4PlacementGenerator_Tests.swift` | guarded | Generates frozen placements (already committed) |
| `MariaAshLocked_Tests.swift` | skipped | Awaiting `v4_locked_placements_{maria,ash}.json` validation |

## 3. Frozen fixtures

All in `docs/fixtures/`:

| File | Contents |
|------|----------|
| `v4_dataset.json` | 100 rows: birth data, location, expected family/cluster/variables/palette/secondaryPull |
| `v4_placements.json` | 100 rows: frozen BirthChartColourInput from NatalChartCalculator |
| `v4_locked_placements_maria.json` | Maria's frozen chart input |
| `v4_locked_placements_ash.json` | Ash's frozen chart input |
| `v4_calibration_diagnostic.txt` | Per-family raw score distributions (critical for tuning) |
| `v4_optimizer_report.txt` | Best grid-search result and remaining mismatches |

## 4. The calibration problem (where you pick up)

### Current state: 51/100 family matches

The `FamilyMapping.swift` currently uses a **nearest-centroid classifier** with 7 features (depth, warmth, saturation, contrast, structure, fireAir, earthWater). This gets 51/100 correct.

### Why it's hard

Per-family raw score distributions overlap heavily (see `v4_calibration_diagnostic.txt`). For example:
- Deep Autumn depth: [46–142], warmth: [−57 to 105]  
- True Autumn depth: [42–100], warmth: [10–66]
- Deep Winter depth: [85–148], warmth: [−83 to 48]

Simple thresholds on individual dimensions cannot cleanly separate all 12 families. The TS spec's threshold values (§9) assume scores in ranges that don't match what our NatalChartCalculator produces for the V4 birth data.

### What the TS spec says (§11, lines 625–656)

The spec's family mapping is **variable-bucket-based**, not score-based:

```
Light + Warm + Rich + Medium + Soft → Light Spring
Light + Cool + Soft + Low + Soft → Light Summer
Medium + Neutral + Rich + High + Structured → Bright Spring
Medium + Cool + Soft + Low + Soft → True Summer
Medium + Cool + Muted + Low + Soft → Soft Summer
Medium + Warm + Muted + Low + Balanced → Soft Autumn
Medium + Warm + Rich + Medium + Balanced → True Spring or True Autumn (fire-air tie-break)
Deep + Warm/Neutral + Rich + Medium + Structured → Deep Autumn
Deep + Cool + Rich + Medium + Structured → Deep Winter
Deep + Cool + Rich + High + Structured → True Winter or Bright Winter (fire-air/chroma tie-break)
```

But the spec also says (§1, line 21): **"If a heuristic, weight, threshold, or tie-break produces an output that does not match V4, the implementation must be adjusted until it reproduces V4."**

### Recommended approach for the next developer

1. **Read `v4_calibration_diagnostic.txt` first** — it has the exact score distributions per family.

2. **The most promising classification strategy** is a hybrid:
   - Use `fireAir` / `earthWater` counts as primary separators (very clean signal)
   - Use score-based rules within each element-balance group
   - Add specific override rules for confused pairs (DA↔TA, BS↔BW, DA↔DW)

3. **Key observations from the data**:
   - `fireAir ≥ 4` cleanly selects {Light Spring, True Spring, Bright Spring, Bright Winter} — ALL rows in these families have fireAir ≥ 4
   - `earthWater ≥ 4` strongly indicates Soft Summer (all have earthWater ≥ 3) or Deep families
   - True Winter has ALL rows with fireAir=3, earthWater=3, contrast ≥ 102
   - Soft Summer has distinctively LOW saturation (≤ 50)
   - Deep Winter has the HIGHEST depth scores (≥ 85)

4. **Iterate**: modify `FamilyMapping.swift`, run `V4CalibrationRegression_Tests`, check `v4_regression.actual.json`, repeat. Each cycle takes ~80s (build + test).

5. **Don't change anything else** until the regression passes. The rest of the engine is locked.

## 5. Remaining plan todos (after calibration)

Once 100/100 regression passes, proceed with the plan in order:

- [ ] **Validate Maria/Ash locked tests** — confirm birth data is correct, check fixture outputs
- [ ] **Extend PaletteSection** in `BlueprintModels.swift` — add neutrals, family, cluster, variables, secondaryPull, overrideFlags; replace ColourProvenance with `.v4Template`; bump schema version
- [ ] **Blueprint invalidation** — in `BlueprintStorage.swift`, wipe stored blueprints on schema version mismatch
- [ ] **Rewire BlueprintComposer** — call ColourEngine via ChartInputAdapter, map result to new PaletteSection
- [ ] **Update UI** — PaletteGrid (12 rows), PaletteGridViewModel (neutral/core/accent bands), ColourRole enum
- [ ] **Rewrite narrative templates** — one per family with V4 placeholders
- [ ] **Rewire Daily Fit** — replace DailyColourPaletteGenerator with deterministic pick from V4 triad
- [ ] **Legacy removal** — delete DeterministicResolver palette code, PaletteSwatchGenerator, season logic in ColourMapper/ColourScoring, colour_library bits in BlueprintTokenGenerator
- [ ] **Archive old docs** — move palette_calibration/**, palette_grid_spec, review_palette_calibration.py to docs/archive/
- [ ] **Supabase round-trip** — verify new PaletteSection shape syncs correctly
- [ ] **Full smoke test** — real user birth chart through to Style Guide + Daily Fit render

## 6. Reference documents

The authoritative spec documents (provided by the user, stored locally):

- `/Users/ash/Downloads/TS_Spec_FINAL_COMPREHENSIVE.md` — canonical TS implementation contract
- `/Users/ash/Downloads/Handoff_Spec_FINAL_COMPREHENSIVE.md` — explanatory logic and rationale
- `/Users/ash/Downloads/Dataset_Usage_NOTE_FINAL_COMPREHENSIVE.md` — dataset usage guidance
- `/Users/ash/Downloads/colour_palette_engine_100_example_charts_v4 (1).md` — raw V4 dataset markdown

## 7. User constraints (non-negotiable)

1. Pipeline order: raw scores → modifiers → derive preliminary buckets → apply overrides → family mapping
2. Production boundary resolver must be fully deterministic and traceable
3. Regression acceptance: depth, temperature, saturation, contrast, surface, family, cluster, palette triad names only. NOT hex values, tonal expansion, or narrative text.
4. `secondaryPull` is metadata-only in v1 — never influences primary result
5. V4 engine is the single source of truth — no legacy palette logic on the execution path
6. No mixed-mode outputs during migration
7. Strict mode for calibration only (frozen fixtures); tolerant mode for production only
8. Existing stored blueprints invalidated on schema change
9. Regression suite is the release gate: 100/100 V4 + Maria/Ash locked tests + zero unexplained mismatches
