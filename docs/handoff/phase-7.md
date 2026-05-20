## Task: P7 — DailyFitEngineMode + stage1_experimental (CONDITIONAL)

**Prerequisites:** P0–P5 merged (P6 optional).

**Implement only if** Stage 1 algorithm changes already exist or are part of this same approved PR. **Do not register `stage1_experimental` without implemented mode behaviour** (spec §5.4, §5.5).

**Phase:** P7 only.

### Deliverables (spec §5.4, §13.2, §17.1 P7)

1. **`DailyFitEngineMode`** enum on descriptor (`standard` | `stage1Experimental`) in `DailyFitEngineRegistry.swift`
2. **Central branches** (≤2 entry points, §17.1): `DailyEnergyEngine.swift`, optionally `BlueprintLensEngine.swift` — `generateSnapshot` / `generatePayload` mode dispatch only
   - `standard` branch = bit-identical to current production path
   - No scattered `if engineId == "..."` in scoring loops

3. **Registry:** `stage1_experimental` row with `mode != .standard` + distinct calibration if needed

4. **Daily seed policy S2** (§9.2): if mode diverges, seed may include engine id — document on descriptor

5. Tests: production mode path passes all existing tests unchanged

### Do NOT

- Fork engine into separate files per version
- Change `production` / `standard` behaviour without explicit promotion approval

### Acceptance

- [ ] `stage1_experimental` produces measurably different output than `production`
- [ ] `production` + `standard` mode still bit-identical to pre-P7 baseline
- [ ] §22 checklist complete