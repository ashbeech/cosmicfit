## Task: P4 — Fix Daily Fit diagnostics + trace completeness

**Prerequisites:** P0–P3 merged.

**Phase:** P4 only. Do not add Profile UI or compare-two-engines column.

### Deliverables (spec §10, §17.1)

1. **`BlueprintLensEngine.logDailyFitDiagnostics`**
   - Add optional `calibration:` parameter
   - Use passed calibration for printed source weights and tarot re-score block (not hardcoded `.default`)
   - Wire from **`CosmicFitTabBarController.swift`** DEBUG path only (§17.1) — one-line pass of `DailyFitEngineConfig.effectiveCalibration`

2. **`DailyFitDiagnostics.swift`**
   - Extend `CalibrationSummary` (or report meta) to include `axisTuning`, `stage2Sensitivity`, and/or `dailyFitEngineId` + fingerprint

3. **Inspector Trace tab** (`app.js` trace rendering)
   - Show full calibration fingerprint / Stage 2 params from response

### Do NOT

- Rewrite entire diagnostics layout or console format beyond calibration accuracy
- Change engine algorithms
- Add Profile picker (P5)

### Acceptance

- [ ] DEBUG console diagnostics match active preset when non-production selected
- [ ] Inspector trace shows fingerprint and full calibration snapshot
- [ ] §22 checklist complete