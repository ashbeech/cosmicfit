# Test suite green path — developer handoff

This document describes how to get **`Cosmic FitTests`** (and related checks) passing: fixture layout, crash fixes, and assertion-level work. It is written for any developer or AI agent picking up the calibration / test harness.

---

## 0. Verify and reproduce

From the repository root:

```bash
python3 tools/validate_dataset.py

xcodebuild test \
  -workspace "Cosmic Fit.xcworkspace" \
  -scheme "Cosmic Fit" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"Cosmic FitTests" \
  -parallel-testing-enabled NO
```

Use **`-parallel-testing-enabled NO`** if you hit clone / `UserDefaults` flakiness (see `docs/archive/test_handoff.md`).

Confirm failures align with: missing JSON under `docs/fixtures/`, `SemanticTokenGenerator` crashes in distribution tests, `DailyFitDistribution` tarot frequency cap, `DailyFitVariation` inter-user palette collision.

Optional stricter tier:

- Set **`CALIBRATION_CI_GATE=1`** for Tier 2 distribution / variation / coherence gates (`CalibrationReportHelper`, tests that branch on `CalibrationTier.current`).

---

## 1. Restore canonical fixtures under `docs/fixtures/` (highest leverage)

### Contract

Tests and `README.md` assume repo-root-relative paths such as:

- `docs/fixtures/blueprint_input_user_1.json` / `blueprint_input_user_2.json`
- `docs/fixtures/v4_dataset.json`, `v4_locked_placements_ash.json`, `v4_locked_placements_maria.json`
- `docs/fixtures/palette_grid_golden_user_1.json` / `palette_grid_golden_user_2.json`

Representative code paths:

- `Cosmic_FitTests.swift` — `fixturesURL()` → `docs/fixtures`
- `MariaAshLocked_Tests.locateFixture` → `docs/fixtures`
- `V4CalibrationRegression_Tests`, `V4CalibrationDiagnostic_Tests`, `V4CalibrationOptimizer_Tests`, `V4PlacementGenerator_Tests`
- `PaletteGridViewModel_Tests`, `FixtureRegeneration`

### Typical failure mode

`docs/fixtures/` may contain generated reports and some JSON (e.g. `golden_cases.json`, `blueprint_birth_specs.json`) while **committed goldens and V4 / blueprint user fixtures** were moved or only exist under **`docs/archive/fixtures/`**. Tests still resolve **`docs/fixtures/`** only → file-not-found and cascaded skips (e.g. MariaAsh locked tests report “fixture not yet generated” when the real issue is path).

### Work

1. Copy (or consolidate) from `docs/archive/fixtures/` into `docs/fixtures/` at minimum:

   - `blueprint_input_user_1.json`, `blueprint_input_user_2.json`
   - `v4_dataset.json`, `v4_placements.json` (if referenced)
   - `v4_locked_placements_ash.json`, `v4_locked_placements_maria.json`
   - `palette_grid_golden_user_1.json`, `palette_grid_golden_user_2.json`
   - Supporting assets as needed: `v4_markdown_reference.json` (for `V4ReferenceAudit_Tests` unless using `V4_REFERENCE_FIXTURE_PATH`), schema/checklist files if any test reads them from disk

2. Decide whether **`docs/archive/fixtures/`** remains a mirror, legacy snapshot, or is deprecated—many archived docs still mention both locations.

3. **Optional hardening:** Add a single helper (e.g. beside `CalibrationReportHelper`) that resolves fixture URLs as: prefer `docs/fixtures`, fall back `docs/archive/fixtures`, and migrate call sites so partial checkouts are less fragile.

### After step 1

Re-run the full `Cosmic FitTests` target. Expect a large improvement: `BlueprintModelTests`, `PaletteReworkTests`, most `PaletteGridViewModel` fixture-driven tests, `FixtureRegeneration` (default validation path), `V4CalibrationDiagnostic` / `Optimizer`, unskipped **`MariaAshLocked_Tests`** and **`V4CalibrationRegression_Tests`** once `v4_dataset.json` is visible at the expected path.

### Regeneration environment variables (only if outputs drift after engine changes)

Documented in `README.md` §2.2:

| Variable | Typical use |
|----------|-------------|
| `REGENERATE_BLUEPRINT_FIXTURES=1` | `FixtureRegeneration` — rewrite blueprint user JSON |
| `REGENERATE_V4_PLACEMENTS=1` | `V4PlacementGenerator_Tests` |
| `REGENERATE_V4_PALETTE_EXPECTATIONS=1` | `V4CalibrationRegression_Tests` — refresh rows in `v4_dataset.json` |
| `REGENERATE_PALETTE_GRID_GOLDENS=1` | Palette grid golden JSON when grid output intentionally changes |
| `V4_REFERENCE_FIXTURE_PATH` | Override path to markdown reference JSON for `V4ReferenceAudit_Tests` |

---

## 2. Fix `SemanticTokenGenerator` crash (`BlueprintDistribution_Tests`, Parts 3B–3E)

### Symptom

`Swift/ContiguousArrayBuffer.swift:690: Fatal error: Index out of range`, often near log output `✅ Ascendant tokens generated for sign: Cancer`.

Note: in `generateStyleGuideTokens`, that print runs **before** `tokenizeForPlanetInSign` for the Ascendant—the crash is likely in **Ascendant tokenization**, **`generateHouseCuspTokens`**, or the next few steps in `SemanticTokenGenerator.generateStyleGuideTokens` (`Cosmic Fit/InterpretationEngine/SemanticTokenGenerator.swift`).

### Repro

```bash
xcodebuild test ... \
  -only-testing:"Cosmic FitTests/BlueprintDistribution_Tests/tokenWeightDistribution"
```

Charts are supplied by `ExtendedCalibrationProfiles.allCharts` (synthetic charts and/or **real** charts from `blueprint_birth_specs.json` when ephemeris succeeds—see `CalibrationProfiles_Extended.swift`).

### Work

1. Isolate the first failing chart (e.g. Cancer ascendant from birth specs).
2. Find unsafe indexing (sign/house as array index, `prefix` + hard index, etc.).
3. Fix **off-by-one** or missing bounds; align **1-based** zodiac contract with any **0-based** table access.
4. Add a **minimal regression test**: one chart that previously crashed → `SemanticTokenGenerator.generateStyleGuideTokens(natal:)` must complete.
5. Re-run `BlueprintDistribution_Tests` until the log shows **no** “Restarting after unexpected exit, crash, or test timeout” for this suite.

---

## 3. `DailyFitDistribution_Tests` — “2E — Tarot card frequency” (`count <= 3`)

**Location:** `DailyFitDistribution_Tests.swift` — test `2E — Tarot card frequency per profile across 30 days`.

**Rule:** For each calibration profile and each tarot card name, appearances over `dayCount` days must be **`<= 3`**.

**Observed failure:** At least one `(profile, card)` reached **count 4**. After a run, inspect the written report `dist_2e_tarot_*.txt` under the calibration report directory (default `docs/fixtures/` via `CalibrationReportHelper` unless `CALIBRATION_REPORT_DIR` is set).

### Work (choose one coherent strategy)

- **Product fix:** Improve diversity / recency / anti-repeat in tarot selection so the 30-day sweep respects the cap (same code path the harness uses with `TarotCalibrationTestSupport`).
- **Spec / test change:** If four repeats in 30 days is acceptable, **raise the cap** or gate the assertion behind `CALIBRATION_CI_GATE=1`, and document the decision in the test and calibration docs.

---

## 4. `DailyFitVariation_Tests` — “4B — inter-user differentiation”

**Location:** `DailyFitVariation_Tests.swift` — `4B — inter-user differentiation on same date`.

**Rule:** For every pair of profiles in `VariationProfiles.allProfiles`, the **sorted** `dailyPalette.colours` **names** must not be identical.

**Observed failure:** Two profiles produced the same three names (e.g. `Champagne`, `Coral`, `Saffron`) on the shared `fixedBaseDate`.

### Work

1. Trace whether **`ProfileDef.hash`** / chart identity affects **palette** inputs (not only essence/tarot). If transit + lunar inputs are identical across profiles for that date, collision may be “correct” for the current pipeline—then the **test data** or **pipeline** must change.
2. **Preferred:** Fix palette generation so distinct calibration charts yield distinct daily palettes when the test requires it.
3. **Alternative:** Soften or re-scope the assertion only if product owners agree the current behaviour is valid (weakens the guarantee).

---

## 5. CI hygiene

- **`CALIBRATION_REPORT_DIR`:** Point to a temp or CI-specific directory so parallel jobs do not fight over `docs/fixtures/*.txt` (see `CalibrationReportHelper`).
- **Commits:** Commit stable JSON fixtures required by tests; avoid committing ephemeral `*_pid*_*.txt` reports unless you explicitly want them as baselines—consider `.gitignore` for generated report globs if noise becomes a problem.

---

## 6. Checklist summary

| Priority | Task | Unblocks |
|----------|------|----------|
| P0 | Ensure `docs/fixtures/` contains blueprint user JSON, V4 JSON, palette grid goldens (copy from `docs/archive/fixtures/` or add a single resolver with fallback) | Blueprint model, palette rework/grid, V4 diagnostics/optimizer/regression, MariaAsh locked, fixture regen |
| P0 | Fix `SemanticTokenGenerator` index crash on real charts | `BlueprintDistribution_Tests` stability; clean test runs without runner restarts |
| P1 | Align tarot selection with `count <= 3` or adjust the test/spec | `DailyFitDistribution_Tests` 2E |
| P1 | Differentiate `dailyPalette` by profile on the same date or adjust test | `DailyFitVariation_Tests` 4B |
| P2 | Regeneration env flags + goldens only when engine output **intentionally** changes | V4 rows, grid goldens |

---

## 7. Definition of done

- `python3 tools/validate_dataset.py` passes (document any intentional warnings).
- `xcodebuild test` with `-only-testing:"Cosmic FitTests"` ends with **TEST SUCCEEDED** and no crash restarts mid-suite.
- `Cosmic FitUITests` still pass if they are part of your CI scheme.
- Optional: full pass with **`CALIBRATION_CI_GATE=1`** per release policy.

---

## Related references

- `README.md` §2.2 — environment variables for regeneration and reports.
- `docs/archive/test_handoff.md` — parallel testing / flakiness notes.
- `docs/calibration_plan_closure_summary.md` — calibration reporting and gates.
