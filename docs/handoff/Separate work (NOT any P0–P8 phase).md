## Task: Add variation candidate preset (OUT OF SELECTOR SPEC PHASES P0–P9)

**Prerequisites:** Selector P0 merged (inspector testable). Prefer P1–P3 for app + clean tarot A/B.

**This is NOT a selector phase (P0–P9).** Do not touch inspector wiring, tab bar config, or frozen storage unless a bug requires it.

### Deliverables

1. New row in `DailyFitEngineRegistry.swift`: e.g. `variation_v1` (`isExperimental: true`)
2. Copy `production` calibration; change **only** intended fields (likely `sourceWeights`, `axisTuning` first)
3. Add/update exploration tests proving ≥1 output surface differs from `production` on fixed fixtures
4. Validate in inspector via dropdown — no `.default` value changes

### Do NOT

- Change `DailyFitCalibration.default` (promotion is separate per §13.1)
- Refactor engine algorithms (that's P7 + separate design work)
- Combine with selector infrastructure in the same PR