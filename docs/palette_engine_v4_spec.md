# Colour Palette Engine V4 — Specification Index

This document serves as the entry point for the V4 colour palette engine.
The engine replaces all legacy palette logic (DeterministicResolver palette
path, PaletteSwatchGenerator, season-based scoring) with a deterministic
variable-based classification system.

## Reference Documents

1. **Technical Specification**: `docs/colour_palette_engine_technical_spec_v4.md`
   - Complete variable engine: driver weights, sign contributions, modifiers,
     thresholds, overrides.
   - Family mapping rules, cluster mapping, secondary pull derivation.
   - 12 palette templates (4 neutrals + 4 core + 4 accent per family).

2. **100-Chart Calibration Programme**: `docs/colour_palette_engine_100_example_charts_v4.md`
   - 100 example birth charts with expected family, cluster, variables, and
     palette output. Used as the frozen regression dataset.

3. **Handoff Document**: `docs/v4_engine_handoff_to_next_dev.md`
   - Implementation status, architecture overview, calibration methodology,
     file locations, and remaining work items.

## Module Location

`Cosmic Fit/InterpretationEngine/ColourEngineV4/`

14 Swift files — one per spec section:

| File | Responsibility |
|------|---------------|
| `Domain.swift` | All V4 types (enums, structs, result) |
| `DriverWeights.swift` | Canonical 24/20/16/14/10/8/5/3 weight table |
| `SignContributions.swift` | Integer sign contribution table |
| `Normalize.swift` | `normalizeDrivers(input:)` |
| `Scoring.swift` | `accumulateRawScores(normalized:)` |
| `Modifiers.swift` | Scorpio density, Cap/Virgo cooling, fire-air chroma, water softening |
| `Thresholds.swift` | Variable derivation with canonical boundaries |
| `Overrides.swift` | Earth-depth, surface preservation, winter compression, cool-lean DA |
| `FamilyMapping.swift` | Rule-based decision tree → PaletteFamily |
| `ClusterMapping.swift` | Variables → PaletteCluster |
| `PaletteLibrary.swift` | 12 fixed palette templates + colour-name-to-hex lookup |
| `SecondaryPull.swift` | Adjacent-family tilt derivation |
| `ColourEngine.swift` | Top-level orchestrator (strict + production entry points) |
| `ChartInputAdapter.swift` | NatalChart → BirthChartColourInput conversion |

## Test Coverage

| Test Suite | Purpose |
|-----------|---------|
| `ColourEngineV4_UnitTests` | Per-modifier, per-override, per-threshold edge cases |
| `V4CalibrationRegression_Tests` | 100-row exact-match regression gate |
| `MariaAshLocked_Tests` | Non-negotiable behavioural anchors for two real users |

## Archived Legacy Docs

Previous palette engine documentation has been moved to `docs/archive/`:
- `palette_engine_rework_spec_v1.md`
- `palette_grid_spec_v1.md`
- `palette_calibration/` (benchmarks and reports)
- `review_palette_calibration.py`
