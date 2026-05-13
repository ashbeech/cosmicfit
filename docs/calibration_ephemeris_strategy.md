# Calibration Ephemeris Strategy

**Status:** Decided  
**Date:** 2026-05-12  
**Covers:** Phase 0B of the Calibration Audit and Test Spec

---

## Decision

**Hybrid strategy: synthetic for CI, production ephemeris for local integration.**

| Context | Ephemeris source | Rationale |
|---------|-----------------|-----------|
| CI / `xcodebuild test` (default) | **Synthetic sign-array charts** via `CalibrationProfiles_Extended.allCharts` | Fast, deterministic, no VSOP87 bundle dependency. |
| Local integration / baseline runs | **Production ephemeris** via `NatalChartCalculator.calculateNatalChart` from `blueprint_birth_specs.json` | Astronomically consistent geometry (Mercury ≤28° from Sun, real houses, real aspects, proper retrogrades). |
| Goldens (`DailyFitGoldens_Tests`) | **Synthetic sign-array charts** with explicit transit specs | Goldens test engine *interpretation* of known inputs, not ephemeris accuracy. Synthetic charts make golden expectations stable across ephemeris upgrades. |

---

## Activation

Production-ephemeris charts are loaded when **all** of the following are true:

1. `blueprint_birth_specs.json` is present in `docs/fixtures/`.
2. VSOP87 bundle integrity passes (`VSOP87BundleIntegrity_Tests`).
3. `AsteroidCalculator.bootstrap()` succeeds (Swiss Ephemeris path is set).

If any condition fails, tests fall back to the existing 48 synthetic charts with a diagnostic log. No `fatalError` is reached.

---

## Implications

- **Tier 2 CI gating** (`CALIBRATION_CI_GATE=1`) uses synthetic charts until a future decision to add VSOP87 resources to the CI test bundle. This is intentional: Tier 2 thresholds are calibrated against the synthetic population, so switching to production ephemeris would require re-baselining.
- **Manifest auto-generation**: When production-ephemeris charts are available, a diagnostic test writes `blueprint_calibration_manifest_computed.json` with element balance, sect, dignity, stellium, and aspect properties derived from `ChartAnalyser.analyse`. This supersedes the hand-written manifest for those charts.
- **VSOP87 `fatalError` risk** (Phase 0B.2): Mitigated by the bundle-integrity preflight and the synthetic fallback. The long-term fix (replacing `fatalError` with `throws`) remains desirable but is not blocking.

---

## What This Closes

- **Phase 0B** in the calibration spec: ephemeris strategy is decided and documented.
- De-facto policy ("synthetic for CI, production not enabled") is now explicit.
