# Phase 7: Legacy Code Audit & Removal

**Dependency:** Phase 5 (new pipeline wired and working) + Phase 6 (calibration validated).
**Produces:** A clean codebase with all Daily Fit-only legacy code removed. The new pipeline is the sole path.
**Estimated scope:** File deletions and targeted edits across ~10 files. No new logic.

---

## 1. Context

After Phases 0–6, the new 2-stage pipeline is live, calibrated, and tested. The legacy `DailyVibeGenerator` → `DailyVibeContent` path is dead code kept only as a fallback during transition. This phase removes all legacy Daily Fit code that has zero remaining references from the live pipeline.

### Critical Safety Principle

> **Search before you delete.** Every file and type on the removal list must be verified with a project-wide search before deletion. Some components listed here may still be referenced by the Blueprint/Style Guide pipeline, `CosmicFitInterpretationEngine`, or tests. Remove ONLY what has zero remaining references from non-legacy, non-archived code.

The `SemanticTokenGenerator.swift` file is the most dangerous case — it hosts BOTH Daily Fit token generation (`generateDailyFitTokens`) AND Style Guide/Blueprint token generation (`generateStyleGuideTokens` and related APIs). **Do not delete the entire file** without verifying that nothing outside the Daily Fit pipeline calls it.

---

## 2. Methodology

For every item on the removal list:

1. **Search the project** with `grep -r "TypeName" "Cosmic Fit/" --include="*.swift"` (excluding `_archive/`).
2. **Categorise references:**
   - References from files already on the removal list → ignore (they're going too).
   - References from test files that test the legacy component → those tests should be removed too.
   - References from live production code (tab bar, VCs, Blueprint engine, etc.) → **STOP. Do not remove this component.** It's still in use.
3. **Remove or edit:**
   - If zero live references: delete the file.
   - If the file has mixed concerns (some parts still referenced): edit the file to remove only the dead portions.

---

## 3. Removal List

### Tier 1: Files to Delete (Daily Fit-only, no shared concerns)

These files exist solely to serve the legacy Daily Fit pipeline. After Phase 5's wiring, nothing in the live app should reference them.

| File | Lines | Verify Before Deleting |
|---|---|---|
| `Cosmic Fit/InterpretationEngine/DailyVibeGenerator.swift` | 1,351 | Contains `DailyVibeGenerator` class AND `DailyVibeContent` struct. Search for `DailyVibeContent` and `DailyVibeGenerator` — after Phase 5, these should only be referenced by the legacy fallback code in the tab bar/VC (which you remove in Tier 3). |
| `Cosmic Fit/InterpretationEngine/WeightingModel.swift` | 112 | Contains `WeightingModel` and `DistributionTargets`. Search for both names. Should only be referenced by `DailyVibeGenerator` and `SemanticTokenGenerator` and `VibeBreakdown .swift`. |
| `Cosmic Fit/InterpretationEngine/AxisVolatilityEngine.swift` | 127 | Only referenced by `DailyVibeGenerator`. |
| `Cosmic Fit/InterpretationEngine/AxisBalancer.swift` | 138 | Search for `AxisBalancer`. Referenced by `SemanticTokenGenerator`. If STG is being slimmed, this can go. |
| `Cosmic Fit/InterpretationEngine/AxisTokenGenerator.swift` | 408 | Search for `AxisTokenGenerator`. Referenced by `SemanticTokenGenerator`. |
| `Cosmic Fit/InterpretationEngine/TransitCapper.swift` | 89 | Search for `TransitCapper`. Referenced by `SemanticTokenGenerator`. |
| `Cosmic Fit/InterpretationEngine/TokenMerger.swift` | 164 | Search for `TokenMerger`. Referenced by `SemanticTokenGenerator`. |
| `Cosmic Fit/InterpretationEngine/AstroFeaturesBuilder.swift` | 190 | Search for `AstroFeaturesBuilder`. Referenced by `SemanticTokenGenerator`. |
| `Cosmic Fit/InterpretationEngine/AstroFeatures.swift` | 177 | Search for `AstroFeatures`. Referenced by `AstroFeaturesBuilder` and `SemanticTokenGenerator`. |
| `Cosmic Fit/InterpretationEngine/InterpretationTextLibraryShim.swift` | 66 | Search for `InterpretationTextLibraryShim`. Referenced by `SemanticTokenGenerator` and `CosmicFitInterpretationEngine`. If CFIE still uses it, do NOT delete — edit CFIE instead. |
| `Cosmic Fit/Core/Utilities/DailyVibeStorage.swift` | ~100 | Search for `DailyVibeStorage`. Referenced by tab bar, profile VC, natal chart VC, AppDelegate. All references must be removed first (Tier 3). |

### Tier 2: Files to Edit (Mixed concerns — remove only Daily Fit portions)

| File | What to Remove | What to Keep |
|---|---|---|
| `Cosmic Fit/InterpretationEngine/SemanticTokenGenerator.swift` (4,123 lines) | All Daily Fit token generation: `generateDailyFitTokens()` and any private methods only called by it. Search for `generateStyleGuideTokens` — if it exists and has live callers, the file stays (slimmed). If nothing outside Daily Fit calls STG, delete the entire file. |  Any methods still called by `CosmicFitInterpretationEngine`, Blueprint, or Style Guide paths. |
| `Cosmic Fit/InterpretationEngine/TarotCardSelector.swift` (1,059 lines) | The entire legacy selector. The new `BlueprintLensEngine` has its own tarot selection. | Nothing — but verify no other code calls `TarotCardSelector` before deleting. |
| `Cosmic Fit/InterpretationEngine/DailyColourPaletteGenerator.swift` (338 lines) | The entire legacy generator. The new `BlueprintLensEngine` handles palette selection. BUT: check if the `selectV4DailyColours` static method or `V4DailyPalette` struct is referenced by anything other than `DailyVibeGenerator`. | If `V4DailyPalette` is referenced elsewhere, keep just that struct and the V4 method. |
| `Cosmic Fit/InterpretationEngine/DerivedAxesEvaluator.swift` (263 lines) | The `DerivedAxesEvaluator` class. The new `DailyEnergyEngine` has its own axes evaluation. | **Keep the `DerivedAxes` struct** — it's used by the new pipeline (Phase 0 types reference it). Move it to `DailyFitTypes.swift` if needed, or leave it here. |
| `Cosmic Fit/InterpretationEngine/VibeBreakdown .swift` (887 lines) | The `VibeBreakdownGenerator` class and all its private methods/token sets. | **Keep the `Energy` enum, `VibeBreakdown` struct, and `DistributionTargets` removal.** The `Energy` and `VibeBreakdown` types are used by the new pipeline. If `DistributionTargets` is only referenced by `VibeBreakdownGenerator` and `WeightingModel`, remove it. The file should shrink from ~887 lines to ~100 lines (just the types). |
| `Cosmic Fit/InterpretationEngine/EngineConfig.swift` (109 lines) | Check what `EngineConfig` contains. If it's only transit caps and legacy configuration, delete. If it has config used by other systems, keep those parts. |

### Tier 3: Files to Edit (Remove legacy references from live code)

| File | What to Change |
|---|---|
| `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift` | Remove the `dailyVibeContent` property. Remove the legacy fallback branch in VC creation. Remove `DailyVibeStorage` save calls. The `generateAndCacheDailyVibe` method should only use the new pipeline (no fallback). |
| `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift` | Remove the `dailyVibeContent: DailyVibeContent?` property. Remove the legacy `configure(with: DailyVibeContent, ...)` method. Remove the legacy `updateContent()` method. Remove `extractTokensFromContent()` helper. Remove `StyleToken` imports/references. Remove the legacy `setupPillSlidersSection()` code, old `vibeContainer` / `VibeBreakdownBarsView` references, legacy `setupSilhouetteSection()` with hardcoded values, and `takeawayLabel`. The only content path should be `DailyFitPayload` with the new Figma layout. |
| `Cosmic Fit/UI/ViewControllers/DailyVibeInterpretationViewController.swift` | Check if this VC is still used. If it only displays legacy `DailyVibeContent`, it may be dead. Search for instantiation across the project. |
| `Cosmic Fit/UI/ViewControllers/NatalChartViewController.swift` | Search for `DailyVibeStorage` or `DailyVibeContent` references. Remove if present. |
| `Cosmic Fit/UI/ViewControllers/ProfileViewController.swift` | Search for `DailyVibeStorage` references. Remove if present. |
| `Cosmic Fit/App/AppDelegate.swift` | Search for `DailyVibeStorage` references. Remove if present. |
| `Cosmic Fit/Core/NatalChartManager+Interpretation.swift` | Search for `DailyVibeContent` or `DailyVibeGenerator` references. Remove if present. |
| `Cosmic Fit/InterpretationEngine/CosmicFitInterpretationEngine.swift` | Search for references to legacy components (STG, token generators, etc.). This file orchestrates interpretation — it may need surgical edits. |

### Tier 4: Views to Audit

| File | Action |
|---|---|
| `Cosmic Fit/UI/Views/DailyColourPaletteView.swift` | Keep. But remove the `configure(with: [StyleToken])` method if no callers remain. Keep `configure(dailyHexes:allPaletteHexes:)`. |
| `Cosmic Fit/UI/Views/VibeBreakdownBarsView.swift` | Check if anything still references this after Phase 5 replaced it with `EssenceTriangleView`. If the Style Guide tab or other screens use it, keep. If Daily Fit was the sole consumer, delete. |
| `Cosmic Fit/Core/Utilities/ColourMapper.swift` | Check if anything still calls it after removing the `StyleToken`-based colour path from `DailyColourPaletteView`. If not, delete. |

### Tier 5: Test Files to Remove

| File | Action |
|---|---|
| `Cosmic Fit/InterpretationEngine/SystemValidationTests.swift` | Check contents. If it tests legacy pipeline components, delete. |
| Any test file that only tests removed components | Delete after confirming no shared test infrastructure is lost. |

---

## 4. Execution Order

**Do not delete files in random order.** Follow this sequence to avoid breaking the build at intermediate steps:

1. **Tier 3 first** — Edit live files to remove legacy references. After this step, no live code should reference legacy types.
2. **Tier 2 — mixed-concern files** — Edit files to remove dead portions while keeping shared types.
3. **Tier 1 — pure deletions** — Delete files that are now completely unreferenced.
4. **Tier 4 — view cleanup** — Remove dead configure methods.
5. **Tier 5 — test cleanup** — Remove tests for removed components.
6. **Build and run all tests** — The project must compile and all remaining tests must pass.

---

## 5. What You Must NOT Do

- **Do not delete a file without searching for references first.** This is the most important rule.
- **Do not delete `VibeBreakdown` or `DerivedAxes` structs.** They are used by the new pipeline.
- **Do not delete `Energy` enum.** It's used by the new pipeline.
- **Do not delete `TarotCard.swift` or `TarotRecencyTracker.swift`.** They are used by the new pipeline.
- **Do not delete `DailySeedGenerator.swift`.** It's used by the new pipeline.
- **Do not delete `BlueprintModels.swift` or any Blueprint-layer file.**
- **Do not delete `MoonPhaseInterpreter.swift`.** It's used by the new pipeline.
- **Do not delete `StyleToken.swift` without checking.** The `StyleToken` type may still be referenced by Blueprint/Style Guide paths, `ColourScoring.swift`, `InterpretationResult.swift`, and other non-Daily-Fit code. Only delete if truly unreferenced.
- **Do not modify any Phase 0–4 files** (the new pipeline).

---

## 6. Acceptance Tests

### Required Tests

| # | Test | What It Validates |
|---|---|---|
| T7.1 | `testProjectCompiles` | `xcodebuild build` succeeds with zero errors. |
| T7.2 | `testAllExistingTestsPass` | Every test file that remains in the project passes. |
| T7.3 | `testNoReferenceToDeletedTypes` | Grep for every deleted type name across `Cosmic Fit/**/*.swift` (excluding `_archive/`). Zero matches. |
| T7.4 | `testDailyFitPayloadPipelineStillWorks` | The Phase 6 calibration test suite (`DailyFitCalibration_Tests.swift`) still passes — the new pipeline is unaffected by removals. |
| T7.5 | `testDailyFitVCRendersFromPayload` | Instantiate `DailyFitViewController`, configure with a fixture `DailyFitPayload`, assert no crash. |
| T7.6 | `testNoLegacyFallbackPath` | Search for `DailyVibeContent` in `CosmicFitTabBarController.swift` and `DailyFitViewController.swift` — zero matches. |
| T7.7 | `testBlueprintPipelineUnaffected` | If `CosmicFitInterpretationEngine` is used for Style Guide generation, verify it still works. Run any existing Blueprint/Style Guide tests. |

### Manual Verification

- [ ] App launches without crash.
- [ ] Daily Fit tab renders correctly (tarot card, paragraph, ritual, palette, vibrancy, contrast, metal tone, essence triangle, silhouette, reflection, tomorrow teaser).
- [ ] Style Guide tab still works (Blueprint pipeline unaffected).
- [ ] Profile tab loads without errors.
- [ ] No console errors or warnings related to missing types.

---

## 7. Post-Removal Metrics

After completion, report:

| Metric | Value |
|---|---|
| Files deleted | (count) |
| Lines removed | (count, approximate) |
| Files edited | (count) |
| Remaining `InterpretationEngine/` file count | (count) |
| Test file count before | (count) |
| Test file count after | (count) |

Expected removals: ~8–12 files, ~7,000–8,000 lines of legacy code.

---

## 8. Definition of Done

- [ ] Project compiles with zero errors and zero warnings related to removed code.
- [ ] All remaining tests pass.
- [ ] No references to deleted types exist in live code.
- [ ] The new Daily Fit pipeline (Phases 0–6) is completely unaffected.
- [ ] Blueprint/Style Guide functionality is completely unaffected.
- [ ] `DailyFitViewController` only has one content path: `DailyFitPayload`.
- [ ] Post-removal metrics documented.

---

## 9. Standards

- **Search before delete.** Every. Single. Time.
- **Build after each tier.** Don't batch all deletions then hope it compiles.
- **Git commit after each tier.** This gives rollback points if something breaks.
- **No force-unwraps in edited code.**
- **Preserve code style** in edited files — match the surrounding code's conventions.
