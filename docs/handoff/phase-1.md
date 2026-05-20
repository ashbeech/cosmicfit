## Task: P1 — App engine config + Release hard-lock

**Prerequisites:** P0 merged (registry + inspector selector working).

**Phase:** P1 only. Do not implement P2+ (no frozen filename changes, no Profile picker).

### Deliverables (spec §6, §17.1)

1. **`Cosmic Fit/Core/Config/DailyFitEngineConfig.swift`** (new)
   - `buildTimeEngineId` from Info.plist `DAILY_FIT_ENGINE_ID`
   - `#if DEBUG`: `runtimeOverrideEngineId` from UserDefaults (stub/read only — picker is P5)
   - `effectiveEngineId`, `effectiveCalibration` via registry validation
   - **Release:** always `production` — ignore non-production plist values (§6.3)

2. **Build config**
   - `Cosmic-Fit-Info.plist`: `DAILY_FIT_ENGINE_ID` = `$(DAILY_FIT_ENGINE_ID)`
   - `Dev.xcconfig.example`, `.env.example`: document `DAILY_FIT_ENGINE_ID=production`
   - **`Prod.xcconfig`:** if the file exists, add `DAILY_FIT_ENGINE_ID = production` (§6.3). If it does not exist yet, document the same line in `Dev.xcconfig.example` / README so it is set when `Prod.xcconfig` is created — do not invent unrelated Prod keys
   - Do not overwrite existing Supabase or other keys

3. **`CosmicFitTabBarController.swift`** — minimal diff only (§6.5)
   - In `generateAndCacheDailyVibe` and `generateDailyPayload`:
     - `let cal = DailyFitEngineConfig.effectiveCalibration`
     - Pass `calibration: cal` to `DailyEnergyEngine.generateSnapshot` and `BlueprintLensEngine.generatePayload`
   - No other tab bar refactors

4. **Tests** for `DailyFitEngineConfig`: Release lock, unknown id fallback, DEBUG override read path

### Do NOT

- Add Profile engine picker or Daily Fit banner (P5)
- Change frozen storage format (P2)
- Change `.default` values
- Modify `DailyFitViewController`, Style Guide, onboarding

### Acceptance

- [ ] DEBUG build with plist `legacy_baseline` uses that calibration at tab bar call sites
- [ ] Release build always uses `production` regardless of plist
- [ ] `production` path bit-identical to pre-P1 behaviour
- [ ] Prod xcconfig documented or updated with `DAILY_FIT_ENGINE_ID=production` when applicable
- [ ] §22 checklist complete
