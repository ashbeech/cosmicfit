# Phase 6: Calibration & Diagnostic Tooling

**Dependency:** Phase 5 (pipeline wired into UI, app runs on the new pipeline).
**Produces:** Structured diagnostic logging, calibration analysis tools, and a multi-user/multi-date test harness for tuning `DailyFitCalibration` weights.
**Estimated scope:** ~250–350 lines across 2 new files.

---

## 1. Context

After Phase 5, the new Daily Fit pipeline is live. But the initial calibration weights (set in Phase 0's `DailyFitCalibration.default`) are educated guesses based on the legacy system's values. Real calibration requires:

1. **Visibility:** being able to see exactly what the pipeline computed and why.
2. **Multi-user sweep:** running the pipeline across multiple test user profiles and dates to check variation and correctness.
3. **Structured comparison:** comparing outputs across different calibration settings to understand the effect of weight changes.

The legacy system had no calibration infrastructure — weights were scattered across 10+ files, and the only debugging tool was `print()` statements. This phase builds proper tooling.

---

## 2. File Locations

Create two new files:

```
Cosmic Fit/InterpretationEngine/DailyFitDiagnostics.swift
Cosmic FitTests/DailyFitCalibration_Tests.swift
```

---

## 3. What You Are Building

### 3.1 `DailyFitDiagnostics` — Structured Diagnostic Logger

A diagnostic struct that captures a complete trace of one pipeline run. This is **not** `print()` logging — it's a structured data object that can be inspected, serialised, and compared.

```swift
struct DailyFitDiagnosticReport: Codable {
    let timestamp: Date
    let profileIdentifier: String

    // Stage 1 trace
    let sourceContributions: SourceContributionBreakdown
    let rawEnergyScores: [String: Double]          // Pre-normalisation, pre-multiplier
    let postMultiplierScores: [String: Double]      // After sun-sign multipliers
    let finalVibeBreakdown: VibeBreakdown           // The 21-point output
    let rawAxisScores: [String: Double]             // Pre-scaling axis scores
    let finalAxes: DerivedAxes                      // The 1–10 output
    let transitSummaries: [DailyTransitSummary]
    let lunarContext: LunarContext
    let dailySeed: Int

    // Stage 2 trace
    let tarotCardScores: [TarotScoreEntry]          // Top 10 cards with scores
    let selectedTarotCard: String                   // Name of chosen card
    let variantRotationIndex: Int                   // Which variant index was selected (0, 1, or 2)
    let selectedStyleEdit: String                   // Name of chosen variant
    let paletteSelectionTrace: PaletteTrace
    let textureSelectionTrace: TextureTrace
    let patternDecision: PatternDecision

    // Blueprint-anchored scale traces (NEW)
    let vibrancyTrace: ScaleDerivationTrace
    let contrastTrace: ScaleDerivationTrace
    let metalToneTrace: ScaleDerivationTrace
    let essenceTriangle: EssenceTriangle            // Direct from payload
    let silhouetteTrace: SilhouetteDerivationTrace

    // Calibration used
    let calibrationSnapshot: CalibrationSummary
}
```

#### Nested types

```swift
struct SourceContributionBreakdown: Codable {
    let natalShare: Double       // What % of the final vibe came from natal
    let transitShare: Double
    let lunarShare: Double
    let progressedShare: Double
    let currentSunShare: Double
}

struct TarotScoreEntry: Codable {
    let cardName: String
    let vibeScore: Double
    let axisScore: Double
    let transitBoost: Double
    let recencyPenalty: Double
    let totalScore: Double
}

struct ScaleDerivationTrace: Codable {
    let blueprintBaseline: Double       // The value from the Blueprint (before modulation)
    let modulation: Double              // The daily energy/axes shift applied
    let finalValue: Double              // The clamped output value
}

struct SilhouetteDerivationTrace: Codable {
    let baselineMF: Double              // Blueprint baseline for masculine/feminine
    let baselineAR: Double              // Blueprint baseline for angular/rounded
    let baselineSD: Double              // Blueprint baseline for structured/draped
    let finalMF: Double                 // After axes modulation
    let finalAR: Double
    let finalSD: Double
}

struct ScoredColourEntry: Codable {
    let name: String
    let role: String
    let score: Double
}

struct ScoredTextureEntry: Codable {
    let name: String
    let score: Double
}

struct PaletteTrace: Codable {
    let candidateCount: Int
    let topScoredColours: [ScoredColourEntry]
    let selectedColours: [DailyColourPick]
    let diversitySwapApplied: Bool
}

struct TextureTrace: Codable {
    let availableTextures: [String]
    let scores: [ScoredTextureEntry]
    let selected: [String]
}

struct PatternDecision: Codable {
    let gateCheckPassed: Bool
    let visibilityValue: Double
    let dominantEnergy: String
    let selectedPattern: String?
}

struct CalibrationSummary: Codable {
    let sourceWeights: [String: Double]
    let selectionWeights: [String: Double]
}
```

All nested types use concrete `Codable` structs (`ScoredColourEntry`, `ScoredTextureEntry`) — no tuples.

#### Diagnostic Generation

Add an optional diagnostic parameter to the pipeline entry points. The diagnostic report should be populated as a **side-effect** of the pipeline run — not by re-running the pipeline. The cleanest approach:

Add a static method to `DailyFitDiagnostics`:

```swift
enum DailyFitDiagnostics {
    static func generateReport(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        profileHash: String,
        blueprint: CosmicBlueprint,
        date: Date = Date(),
        calibration: DailyFitCalibration = .default
    ) -> (payload: DailyFitPayload, report: DailyFitDiagnosticReport)
}
```

This method runs the full pipeline and captures intermediate values at each step. It's used for testing and calibration, **not** in the production path. The production path (Phase 5 wiring) continues to call `DailyEnergyEngine.generateSnapshot` and `BlueprintLensEngine.generatePayload` directly.

To capture intermediate values, **you are permitted to add targeted `internal` hooks to the engine files** (`DailyEnergyEngine.swift` and `BlueprintLensEngine.swift`). These hooks should:
- Have `internal` (default) visibility — not `public`.
- Return the existing result **plus** intermediate data as a tuple. For example, an internal method that returns `(VibeBreakdown, rawScores: [String: Double])`.
- Not change the behaviour or signature of any existing `public` or `private` method.
- Total additions to engine files should stay under 30 lines per file.

This is the preferred approach. Do NOT re-derive values independently — that creates a second source of truth that can drift.

---

### 3.2 Calibration Test Harness

Create a comprehensive calibration test suite in:

```
Cosmic FitTests/DailyFitCalibration_Tests.swift
```

#### Test User Profiles

Define at least 5 test profiles that span a range of astrological signatures:

| Profile | Sun | Moon | Ascendant | Element Balance | Expected Personality |
|---|---|---|---|---|---|
| `ashProfile` | Leo | (check your own chart) | (check) | Fire-heavy | Drama + Playful dominant |
| `waterDominant` | Cancer | Scorpio | Pisces | Water-heavy | Romantic + Drama dominant |
| `earthGrounded` | Virgo | Taurus | Capricorn | Earth-heavy | Classic + Utility dominant |
| `airIntellectual` | Gemini | Aquarius | Libra | Air-heavy | Playful + Edge dominant |
| `fireExplosive` | Aries | Leo | Sagittarius | Fire-heavy | Drama + Playful dominant |

For each profile, create fixture `NatalChart` and `NatalChart` (progressed) objects. Use the test fixture pattern from Phase 1.

#### Test Date Range

For each profile, run the pipeline across a 7-day date range (e.g. 2026-05-10 through 2026-05-16) to verify daily variation.

#### Required Tests

| # | Test | What It Validates |
|---|---|---|
| T6.1 | `testAllProfilesProduceValidOutput` | All 5 profiles produce valid `DailyFitPayload` (21-point vibes, axes in range, tarot selected, 3 colours). |
| T6.2 | `testDailyVariationAcross7Days` | For each profile, the 7-day run produces at least 3 different tarot cards and at least 2 different dominant energies. The pipeline isn't stuck. |
| T6.3 | `testPersonalityConsistency` | Across 7 days, each profile's dominant energy should align with expectation at least 5/7 times (e.g. Leo should be Drama-dominant most days). |
| T6.4 | `testTransitImpactVisible` | Run the same profile on the same date with and without transits. The outputs should differ. |
| T6.5 | `testMoonCycleVariation` | Run the same profile at new moon (0°), first quarter (90°), full moon (180°), last quarter (270°). The axes and vibe should shift noticeably across the cycle. |
| T6.6 | `testCalibrationWeightSensitivity` | Change `sourceWeights.transits` from 0.25 to 0.50 (rebalancing others). Verify the output changes. This proves calibration is actually connected. |
| T6.7 | `testNoProfileProducesMonoEnergy` | No profile on any test date has a single energy exceeding 12/21 points. Output is always a meaningful distribution. |
| T6.8 | `testAxesSpreadAcrossProfiles` | Across all 5 profiles × 7 dates (35 data points), the action axis has a min ≤ 3.0 and max ≥ 7.0. Same for tempo, strategy, visibility. Axes use their range. |
| T6.9 | `testPaletteFromBlueprintOnly` | For every generated payload, every colour hex exists in the corresponding Blueprint's palette. |
| T6.10 | `testDiagnosticReportComplete` | Generate a diagnostic report. Assert every field is populated (no nil, no empty arrays where data is expected). |
| T6.11 | `testDiagnosticReportSourceContributionsSum` | `sourceContributions` shares sum to approximately 1.0 (±0.05). |
| T6.12 | `testDiagnosticReportTarotScoresOrdered` | `tarotCardScores` are sorted by `totalScore` descending. |

#### Diagnostic Output

Add a test that writes a human-readable calibration report to disk:

```swift
func testGenerateCalibrationReport() {
    // Run all 5 profiles × 7 days
    // Write results to docs/fixtures/daily_fit_calibration_report.txt
    // Format: one section per profile, showing each day's vibe, axes, tarot card, and palette
}
```

This report is not a pass/fail test — it's a diagnostic artifact for human review. The test always passes; its value is the output file.

---

## 4. What You Must NOT Do

- **Targeted `internal` hooks in engine files are permitted** (see §3.1), but do not change existing public API signatures, method behaviour, or `DailyFitTypes.swift`. No hook should alter production-path output.
- **Do not add `print()` to production code.** All diagnostics go through the structured `DailyFitDiagnosticReport`.
- **Do not hardcode calibration changes.** If you find the weights need adjustment, document the recommended changes in the calibration report output — do not modify `DailyFitCalibration.default` yourself.
- **Do not modify UI code.**

---

## 5. Calibration Adjustment Process (For Human Review)

After this phase is complete, a human reviewer should:

1. Read `docs/fixtures/daily_fit_calibration_report.txt`.
2. Check each profile: does the dominant energy match astrological expectations?
3. Check daily variation: is there enough change day-to-day, or is it too static?
4. Check axes: are they meaningfully different across profiles and dates?
5. If adjustments are needed, modify the values in `DailyFitCalibration.default` (in `DailyFitTypes.swift`) and re-run the test suite.

The diagnostic report should make it obvious what needs changing. For example, if the Earth-Grounded profile consistently shows Drama as dominant, the `SignEnergyMap` for Virgo/Taurus/Capricorn needs stronger Classic/Utility multipliers.

---

## 6. Definition of Done

- [ ] `DailyFitDiagnostics.swift` exists and compiles.
- [ ] `DailyFitDiagnosticReport` captures both Stage 1 and Stage 2 intermediate values.
- [ ] All 12 calibration tests pass.
- [ ] `docs/fixtures/daily_fit_calibration_report.txt` is generated and contains readable data for all 5 profiles × 7 days.
- [ ] Only targeted `internal` hooks added to engine files (≤30 lines each), no public API changes, no UI code modifications.
- [ ] The diagnostic report makes calibration issues visible and actionable.

---

## 7. What Comes Next

Phase 7 removes all legacy Daily Fit code that is no longer referenced by the live pipeline.

---

## 8. Standards

- **No print statements in production files.**
- **Test file print/write to disk is acceptable** for the diagnostic report.
- **All diagnostic types conform to `Codable`** for easy serialisation.
- **Indentation:** 4 spaces.
- **Line length:** prefer under 120 characters.
