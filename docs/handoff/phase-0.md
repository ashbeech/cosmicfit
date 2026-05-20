## Task: P0 — Daily Fit Engine Registry + Inspector selector

**Phase:** P0 only. Do not implement P1+ (no app tab bar, no `DailyFitEngineConfig`, no frozen storage changes).

**Goal:** Selectable Daily Fit presets in the **inspector** via header dropdown. Same chart/transit/lunar inputs; different `DailyFitCalibration` passed into the pipeline.

**Interim behaviour:** Tarot recency/history is **not** namespaced per engine until P3 — switching presets in the inspector can bleed tarot state. Until P3, use manual `resetTarotHistory` when comparing presets.

### Deliverables (spec §16 P0, §17.1)

1. **`Cosmic Fit/InterpretationEngine/DailyFitEngineRegistry.swift`** (new)
   - Presets: `production` (= `DailyFitCalibration.default` by identity), `legacy_baseline` (§5.2 values verbatim)
   - `DailyFitEngineDescriptor`, `allDescriptors`, `calibration(for:)`, fingerprint per §5.3 algorithm
   - Unknown id → `production` + warning

2. **Tests**
   - Migrate `DailyFitCalibrationExploration_Tests.swift`: remove duplicate `CalibrationPresets`; use registry
   - **`Cosmic FitTests/DailyFitEngineRegistry_Tests.swift`** (new): ids resolve; unknown id → production + warning; fingerprints differ for `production` vs `legacy_baseline`

3. **Inspector lib**
   - `InspectorRequest.swift`: `options.dailyFitEngineId`
   - `InspectorDefaults.swift` (new): server default from `DAILY_FIT_ENGINE_ID` env, fallback `production`
   - `InspectorEngine.swift`: resolve calibration from request; pass to `DailyFitDiagnostics.generateReport(..., calibration:)`
   - `InspectorResponse.swift`: extend `ResponseMeta` with `dailyFitEngineId`, `dailyFitEngineDisplayName`, `dailyFitEngineFingerprint`

4. **Inspector server**
   - `Routes.swift`: `GET /api/daily-fit-engines`; extend `GET /api/health`
   - `Web/index.html`: engine dropdown first in row 1 (§7.1); `#engine-chip` with experimental preset styling + tooltip (§7.1, §5.5)
   - `Web/app.js`: populate dropdown; sync chip label; persist in `readFormInputs` / `applyFormInputs`; add to `buildRequest()` options; compare cache key `${dailyFitEngineId}:${dateISO}`; on engine change: clear cache, invalidate `state.data`, auto-resubmit if prior submit exists, reload compare if enabled (§11)
   - `Web/storage.js`: session includes `dailyFitEngineId`; **§18.6** on restore — if restored `dailyFitEngineId` differs from keys in `compareCache`, clear compare cache on load; **§18.7** — unknown/deprecated id in saved session → fallback to `production`, warning in status line, persist corrected id
   - Compare pane labels include engine id

5. **Inspector tests** (spec §15 — new test target or inspector test suite as repo convention allows)
   - `GET /api/daily-fit-engines` / inspect response meta includes correct `dailyFitEngineId`
   - Engine dropdown change clears compare cache (and re-submits when applicable)

### Do NOT

- Touch `CosmicFitTabBarController.swift`, `DailyFitEngineConfig`, frozen storage, tarot trackers, Profile UI
- Change `DailyFitCalibration.default` **values**
- Change `DailyEnergyEngine` / `BlueprintLensEngine` algorithm logic
- Register `stage1_experimental`

### Acceptance (§15.1 Inspector subset + §22)

- [ ] Dropdown lists registry presets; `#engine-chip` reflects selection; session persists selection
- [ ] Restored session with unknown engine id → `production` + status warning + corrected session write (§18.7)
- [ ] Restored session with engine/cache key mismatch clears compare cache (§18.6)
- [ ] Switching engine clears compare cache and re-submits target
- [ ] Response meta includes daily fit engine fields
- [ ] `legacy_baseline` produces different output than `production` on fixed fixture
- [ ] Inspector tests (or documented manual checklist) cover API meta + compare cache invalidation
- [ ] All existing tests pass; production output unchanged when id is `production` or omitted
