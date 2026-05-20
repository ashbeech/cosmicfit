## Task: P5 — DEBUG Profile engine picker + Daily Fit banner

**Prerequisites:** P0–P4 merged (`DailyFitEngineConfig` exists from P1).

**Phase:** P5 only. No Release-visible engine UI.

### Deliverables (spec §6.6, §17.1)

1. **`ProfileViewController.swift`** (`#if DEBUG` only)
   - Dropdown populated from `DailyFitEngineRegistry.allDescriptors`
   - Writes `DailyFitEngineConfig.runtimeOverrideEngineId` to UserDefaults
   - Copy: engine is global per install, not per profile (§18.10); Release locked to production

2. **Daily Fit tab DEBUG banner** — **`CosmicFitTabBarController.swift`** only (§17.1, §17.2)
   - Implement via tab bar: tab badge and/or debug subtitle on the Daily Fit tab entry
   - Show `Engine: <displayName> (debug)` when effective id ≠ `production` (or per §6.6)
   - **Do not** modify `DailyFitViewController` layout or card UI

3. **On picker change:** trigger P2 invalidation immediately (today’s freeze cleared + regenerate) in addition to P2 launch-time mismatch handling

### Do NOT

- Any engine selector in Release builds
- Change `.default` values
- Modify `DailyFitViewController`, card rendering, radar, or animations

### Acceptance

- [ ] Profile change updates effective calibration without rebuild
- [ ] Banner on Daily Fit tab (via `CosmicFitTabBarController`) reflects selected engine
- [ ] Switching engine invalidates today’s card immediately
- [ ] Release build unchanged (no picker visible)
- [ ] §22 checklist complete
