# Phase 0: Foundation Types & Contracts

**Dependency:** None — this is the first phase.
**Produces:** Three new Swift structs that every subsequent phase imports.
**Estimated scope:** ~150–200 lines of pure type definitions. No logic, no imports beyond Foundation.

---

## 1. Context You Need

Cosmic Fit's Daily Fit feature is being rebuilt from a legacy token-based pipeline to a clean 2-stage architecture:

1. **Stage 1 — DailyEnergyEngine** consumes raw astrology (natal chart, transits, moon, progressed chart) and produces a `DailyEnergySnapshot` — pure astrological distillation with zero style decisions.
2. **Stage 2 — BlueprintLensEngine** takes the user's persisted `CosmicBlueprint` (their permanent style identity) and the `DailyEnergySnapshot`, and selects today's style recommendations from the Blueprint. Output: `DailyFitPayload`.

Both stages are governed by a single, normalised calibration surface: `DailyFitCalibration`.

Your job in this phase is to define the **three output contracts** that all subsequent phases build against:

| Struct | Purpose |
|---|---|
| `DailyEnergySnapshot` | Stage 1 output — astrological state of the day |
| `DailyFitPayload` | Stage 2 output — everything the UI needs to render the Daily Fit |
| `DailyFitCalibration` | Single config surface — every tunable weight in one place |

---

## 2. File Location

Create one new file:

```
Cosmic Fit/InterpretationEngine/DailyFitTypes.swift
```

This file must compile standalone with `import Foundation` only. It must not import or depend on any other file in the project. It references existing types (`VibeBreakdown`, `DerivedAxes`, `TarotCard`, `StyleEditVariant`, `Energy`) by name — those types already exist in the project and will be resolved at compile time. Do **not** redefine them.

---

## 3. Existing Types You Must Reference (Do NOT Redefine)

These already exist in the codebase. Your structs will use them as field types:

| Type | Location | Notes |
|---|---|---|
| `VibeBreakdown` | `VibeBreakdown .swift` (note space in filename) | Struct with 6 `Int` fields (classic, playful, romantic, utility, drama, edge). 21-point budget. |
| `DerivedAxes` | `DerivedAxesEvaluator.swift` | Struct with 4 `Double` fields (action, tempo, strategy, visibility). Range 1–10. |
| `TarotCard` | `TarotCard.swift` | Codable struct. Has `energyAffinity`, `axesAffinity`, `keywords`, `themes`, etc. |
| `StyleEditVariant` | `TarotCard.swift` | Codable struct. Has `variant`, `title`, `description`, `energyEmphasis`, `axesEmphasis`. **Phase 3 will add `microRitual` and `wardrobeReflection` fields.** |
| `Energy` | `VibeBreakdown .swift` | Enum: `.classic`, `.playful`, `.romantic`, `.utility`, `.drama`, `.edge`. CaseIterable, Codable. |

---

## 4. Struct Specifications

### 4.1 `DailyEnergySnapshot`

This is the output of Stage 1. It captures the astrological energy for a given day for a given user. No style decisions. No Blueprint data. Pure astrology.

```swift
struct DailyEnergySnapshot: Codable {
    let vibeProfile: VibeBreakdown
    let axes: DerivedAxes
    let dominantTransits: [DailyTransitSummary]
    let lunarContext: LunarContext
    let dailySeed: Int
    let profileHash: String
    let generatedAt: Date         // Set from the supplied `date` parameter, NOT Date()
}
```

> **Why not `Equatable`?** The referenced types `VibeBreakdown` and `DerivedAxes` conform to `Codable` but not `Equatable` in the existing codebase, and Phase 0 must not modify existing files. Tests use field-level assertions instead of `==`.

#### Nested type: `DailyTransitSummary`

A lightweight summary of an active transit. Not the full `NatalChartCalculator.TransitAspect` — just the fields that Stage 2 and the UI need.

```swift
struct DailyTransitSummary: Codable, Equatable {
    let transitPlanet: String      // e.g. "Mars"
    let natalPlanet: String        // e.g. "Venus"
    let aspect: String             // e.g. "conjunction", "trine", "square"
    let strength: Double           // 0.0–1.0, normalised
}
```

#### Nested type: `LunarContext`

```swift
struct LunarContext: Codable, Equatable {
    let phaseName: String          // e.g. "Waxing Crescent", "Full Moon"
    let isWaxing: Bool
    let element: String            // Fire, Earth, Air, Water — derived from moon's sign
    let phaseDegrees: Double       // 0–360, raw value for computation
}
```

### 4.2 `DailyFitPayload`

This is the output of Stage 2. It is everything the `DailyFitViewController` needs to render the Daily Fit screen. Every field is populated; no optionals except `dailyPattern` (textures and patterns are computed but not displayed in the current UI — retained for diagnostics and future use).

```swift
struct DailyFitPayload: Codable {
    // MARK: - Headline content (from tarot card + selected variant)
    let tarotCard: TarotCard
    let styleEditVariant: StyleEditVariant   // .description = paragraph, .microRitual = ritual, .wardrobeReflection = question

    // MARK: - Outfit Breakdown
    let dailyPalette: DailyPaletteSelection  // 3 colours from Blueprint
    let vibrancy: Double                     // 0.0–1.0, Blueprint-anchored with energy modulation
    let contrast: Double                     // 0.0–1.0, Blueprint-anchored with axes modulation
    let metalTone: Double                    // 0.0–1.0 (0=cool, 0.5=mixed, 1.0=warm), Blueprint-anchored

    // MARK: - Essence & Silhouette
    let essenceTriangle: EssenceTriangle     // 3-vertex energy summary collapsed from 6-energy vibe
    let silhouetteProfile: SilhouetteProfile // 3 bipolar scales, Blueprint-anchored with axes modulation

    // MARK: - Passthrough from snapshot
    let vibeBreakdown: VibeBreakdown         // Full 6-energy profile (used internally, not displayed directly)
    let axes: DerivedAxes                    // Full 4-axis profile (used internally for derivation)
    let dominantTransits: [DailyTransitSummary]
    let lunarContext: LunarContext

    // MARK: - Computed but not displayed in current UI (retained for diagnostics/future)
    let dailyTextures: [String]              // 2–3 texture names from Blueprint
    let dailyPattern: String?                // Optional pattern from Blueprint

    let generatedAt: Date                    // Set from the supplied `date` parameter, NOT Date()
}
```

> **Why not `Equatable`?** `TarotCard` and `StyleEditVariant` do not conform to `Equatable` and live in files this phase must not modify. Tests use field-level assertions.

#### Nested type: `EssenceTriangle`

Collapses the 6-energy vibe profile into 3 meta-dimensions for the triangle chart UI. Values normalise to sum to 1.0.

```swift
struct EssenceTriangle: Codable, Equatable {
    let classic: Double     // Classic + Romantic energies (timeless, refined, polished)
    let edgy: Double        // Edge + Drama energies (bold, unconventional, high-impact)
    let grounded: Double    // Utility + Playful energies (practical, approachable, at ease)
}
```

#### Nested type: `SilhouetteProfile`

Three bipolar scales expressing the day's silhouette recommendation. Each is 0.0–1.0 where 0.0 = left label, 1.0 = right label. Blueprint provides the strong baseline (~70-80% influence); daily axes provide small modulation (~20-30%).

```swift
struct SilhouetteProfile: Codable, Equatable {
    let masculineFeminine: Double       // 0.0 = Masculine, 1.0 = Feminine
    let angularRounded: Double          // 0.0 = Angular, 1.0 = Rounded
    let structuredDraped: Double        // 0.0 = Structured, 1.0 = Draped
}
```

#### Nested type: `DailyPaletteSelection`

```swift
struct DailyPaletteSelection: Codable, Equatable {
    let colours: [DailyColourPick]          // Exactly 3
    let allPaletteHexes: [String]           // Full Blueprint palette for context ring
}
```

#### Nested type: `DailyColourPick`

```swift
struct DailyColourPick: Codable, Equatable {
    let name: String                        // e.g. "Burnt Sienna"
    let hexValue: String                    // e.g. "#A0522D" — matches BlueprintColour.hexValue naming
    let role: String                        // e.g. "core", "accent", "neutral", "support"
    // Note: BlueprintColour.role is a ColourRole enum. Use .rawValue when constructing DailyColourPick.
}
```

### 4.3 `DailyFitCalibration`

The single calibration surface. Every magic number that the legacy system scattered across 10+ files lives here. All weights are normalised and documented.

```swift
struct DailyFitCalibration {

    struct SourceWeights {
        let natal: Double               // ~0.40 — stable natal foundation
        let transits: Double            // ~0.25 — daily variation driver
        let lunarPhase: Double          // ~0.15 — emotional/cyclical rhythm
        let progressed: Double          // ~0.15 — slow personal evolution
        let currentSun: Double          // ~0.05 — seasonal background colour

        var isNormalised: Bool {
            abs((natal + transits + lunarPhase + progressed + currentSun) - 1.0) < 0.001
        }
    }

    struct SignEnergyMap {
        let multipliers: [String: [Energy: Double]]

        func multiplier(forSign sign: String, energy: Energy) -> Double {
            multipliers[sign]?[energy] ?? 1.0
        }
    }

    struct PlanetAxisMap {
        let weights: [String: [String: Double]]

        func weight(forPlanet planet: String, axis: String) -> Double {
            weights[planet]?[axis] ?? 0.0
        }
    }

    struct SelectionWeights {
        let vibeWeight: Double          // How much vibe breakdown influences Stage 2 selection
        let axisWeight: Double          // How much axes influence Stage 2 selection
        let transitBoost: Double        // Extra weight when a transit's planet aligns with selection
    }

    let sourceWeights: SourceWeights
    let signEnergyMap: SignEnergyMap
    let planetAxisMap: PlanetAxisMap
    let selectionWeights: SelectionWeights
}
```

### 4.4 Default Calibration Factory

Provide a single static factory that returns a sensible starting calibration. These values will be tuned in Phase 6, but they must be reasonable defaults so that Phases 1–5 can run without crashing.

```swift
extension DailyFitCalibration {
    static let `default`: DailyFitCalibration = {
        // ... populate with the values shown in the audit:
        // SourceWeights: natal 0.40, transits 0.25, lunar 0.15, progressed 0.15, currentSun 0.05
        // SignEnergyMap: all 12 signs, multipliers around 1.0 (0.85–1.5 range)
        // PlanetAxisMap: Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto
        // SelectionWeights: vibe 0.50, axis 0.35, transitBoost 0.15
    }()
}
```

For `SignEnergyMap`, use the existing sun-sign multiplier data from `VibeBreakdownGenerator.getSunSignEnergyPreference()` (lines 460–587 of `VibeBreakdown .swift`) as the starting values. Translate the dictionary format `[String: Double]` into `[String: [Energy: Double]]`.

For `PlanetAxisMap`, use the axis-to-planet mapping concepts from `DerivedAxesEvaluator.swift` (lines 55–200) and `DerivedAxesConfiguration.swift`. Translate the existing planet-checks into explicit numeric weights.

---

## 5. Architectural Constraints

1. **All types you define must conform to `Codable`.** Types that do NOT reference external non-Equatable types (`DailyTransitSummary`, `LunarContext`, `DailyPaletteSelection`, `DailyColourPick`) should also conform to `Equatable`. Top-level types that embed external non-Equatable types (`DailyEnergySnapshot`, `DailyFitPayload`) conform to `Codable` only — tests use field-level assertions. `DailyFitCalibration` and its nested structs do not need `Codable` (they are code-defined, not serialised) but should be `Equatable`.
2. **No logic in this file.** Pure data definitions, computed validation properties (like `isNormalised`), and the default factory. No scoring, no selection, no generation.
3. **No `import` beyond Foundation.** This file must not depend on UIKit, SwiftUI, or any third-party framework.
4. **Field naming must be explicit.** No abbreviations. `transitPlanet` not `tPlanet`. `phaseName` not `phase`.
5. **Doc comments on every public field.** One line explaining what the field is, its range, and its source.

---

## 6. Acceptance Tests

Create a test file:

```
Cosmic FitTests/DailyFitTypes_Tests.swift
```

### Required Tests (all must pass before this phase is considered complete):

| # | Test | What It Validates |
|---|---|---|
| T0.1 | `testDailyEnergySnapshotCodableRoundTrip` | Create a `DailyEnergySnapshot` with fixture data, encode to JSON, decode back. Assert each field matches (field-level, not `==`, since the struct is not `Equatable`). Verify `profileHash` survives the round-trip. |
| T0.2 | `testDailyFitPayloadCodableRoundTrip` | Same for `DailyFitPayload` — field-level assertions on every property including `tarotCard.name`, `styleEditVariant.title`, palette colours, textures, etc. |
| T0.3 | `testDailyTransitSummaryCodableRoundTrip` | Same for `DailyTransitSummary`. |
| T0.4 | `testLunarContextCodableRoundTrip` | Same for `LunarContext`. |
| T0.5 | `testDailyPaletteSelectionCodableRoundTrip` | Same for `DailyPaletteSelection`. |
| T0.6 | `testDailyColourPickCodableRoundTrip` | Same for `DailyColourPick`. |
| T0.7 | `testDefaultCalibrationSourceWeightsNormalised` | `DailyFitCalibration.default.sourceWeights.isNormalised` is `true`. |
| T0.8 | `testDefaultCalibrationHasAll12Signs` | `DailyFitCalibration.default.signEnergyMap.multipliers.count == 12`. |
| T0.9 | `testDefaultCalibrationHasAll10Planets` | `DailyFitCalibration.default.planetAxisMap.weights.count == 10` (Sun through Pluto). |
| T0.10 | `testDefaultCalibrationSignMultipliersInRange` | Every sign-energy multiplier in the default calibration is between 0.5 and 2.0. |
| T0.11 | `testDefaultCalibrationSelectionWeightsSumToOne` | `selectionWeights.vibeWeight + axisWeight + transitBoost == 1.0` (within 0.001). |
| T0.12 | `testVibeBreakdownFieldsAccessible` | Create a `DailyEnergySnapshot` and assert you can access `snapshot.vibeProfile.classic`, etc. Proves interop with existing `VibeBreakdown`. |
| T0.13 | `testDerivedAxesFieldsAccessible` | Create a `DailyEnergySnapshot` and assert you can access `snapshot.axes.action`, etc. Proves interop with existing `DerivedAxes`. |
| T0.14 | `testEssenceTriangleCodableRoundTrip` | Create an `EssenceTriangle`, encode/decode, assert equality (`Equatable`). |
| T0.15 | `testEssenceTriangleNormalisedToOne` | Create fixture with classic=0.4, edgy=0.35, grounded=0.25. Assert `classic + edgy + grounded ≈ 1.0`. |
| T0.16 | `testSilhouetteProfileCodableRoundTrip` | Create a `SilhouetteProfile`, encode/decode, assert equality. |
| T0.17 | `testSilhouetteProfileValuesInRange` | All 3 values are between 0.0 and 1.0 inclusive. |
| T0.18 | `testDailyFitPayloadContainsNewFields` | Create a `DailyFitPayload` fixture, assert `vibrancy`, `contrast`, `metalTone`, `essenceTriangle`, `silhouetteProfile` are all accessible and populated. |

### Test Fixture Pattern

Create fixtures as static factory methods on each type:

```swift
extension DailyEnergySnapshot {
    static func fixture(
        vibeProfile: VibeBreakdown = VibeBreakdown(classic: 5, playful: 3, romantic: 4, utility: 3, drama: 3, edge: 3),
        axes: DerivedAxes = DerivedAxes(action: 6.0, tempo: 5.0, strategy: 7.0, visibility: 4.0),
        dominantTransits: [DailyTransitSummary] = [],
        lunarContext: LunarContext = .fixture(),
        dailySeed: Int = 42,
        profileHash: String = "test-profile-hash",
        generatedAt: Date = Date(timeIntervalSince1970: 1_800_000_000) // Fixed date for determinism
    ) -> DailyEnergySnapshot { ... }
}
```

Do the same for every type. These fixtures will be reused by every subsequent phase's tests.

---

## 7. Definition of Done

- [ ] `DailyFitTypes.swift` compiles with zero warnings in the main target.
- [ ] `DailyFitTypes_Tests.swift` compiles and all 18 tests pass (green).
- [ ] No other file in the project has been modified.
- [ ] All types have doc comments on every field.
- [ ] `DailyFitCalibration.default` is populated with real starting values derived from the legacy codebase (not placeholder zeros).
- [ ] The file is under 300 lines (types are lean, not bloated).

---

## 8. What Comes Next

Phase 1 will build `DailyEnergyEngine` which produces `DailyEnergySnapshot`. Phase 2 extends that engine with axes and transit assembly. Both depend on the types you define here. Get them right and every subsequent phase has a clean contract to build against.

---

## 9. Standards

- **No print statements.** This is a types-only file.
- **No force-unwraps.** All code must be safe.
- **Swift naming conventions.** lowerCamelCase for properties, UpperCamelCase for types.
- **Indentation:** 4 spaces, no tabs.
- **Line length:** prefer under 120 characters.
