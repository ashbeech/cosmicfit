# V4 Per-User Palette Variation — Specification

**Date**: 2026-04-19  
**Depends on**: V4 Colour Engine (complete), V4 Production Hardening (complete)  
**Previous chat**: [V4 Hardening & Audit](34473ad7-65e4-41b4-8066-927dc1659c01)

---

## 1. Problem Statement

The V4 engine classifies every user into one of 12 `PaletteFamily` types and
returns the fixed palette template for that family. Two users in the same
family (e.g. Ash and Maria, both Deep Autumn) receive **identical** 12-colour
palettes despite having meaningfully different birth charts.

The family classification is directionally correct — a Spring user looks
different from an Autumn user — but within-family users are
indistinguishable. Users expect their palette to feel personal.

## 2. Design Constraints

| # | Constraint | Rationale |
|---|-----------|-----------|
| C1 | Family base palette remains the dominant visual identity (≥75% of slots unchanged) | "Directionally the same" per user feedback |
| C2 | Fully deterministic — same input always produces the same output | Core V4 contract |
| C3 | No new scoring, classification, or calibration data required | Builds on existing computed signals |
| C4 | Variation is visible in the UI (≥1 slot change for every user with a secondary pull) | Addresses "identical palette" feedback |
| C5 | Backward-compatible with existing `PaletteTriadV4` and `ColourEngineResult` types | No model layer churn |
| C6 | Testable with snapshot regression | Maintains CI gate integrity |
| C7 | Every substituted colour must be aesthetically coherent with the base palette | No blind slot borrowing; each substitution is hand-curated |

## 3. Existing Per-User Signals (Already Computed, Currently Unused)

The engine already computes these per-user signals in every
`ColourEngineResult.trace`, but they are treated as metadata today:

| Signal | Type | Example (Ash vs Maria) |
|--------|------|----------------------|
| `secondaryPull` | `PaletteFamily?` | Ash → Deep Winter, Maria → True Autumn |
| `overrideFlags` | `OverrideFlags` (8 bools) | Ash: `winterCompressionApplied=true`; Maria: `scorpioDensityApplied=true` |
| `rawScoresAfterModifiers` | `RawVariableScores` (5 ints) | Different depth/warmth/sat/contrast/structure scores |
| `variablesBeforeOverrides` | `DerivedVariables` | Individual bucket derivation before canonical snap |

The **`secondaryPull`** is the strongest variation signal. It identifies the
adjacent family the user tilts toward and is already derived from chart-specific
heuristics (element balance, warmth lean, chroma). Every family has 2–3
defined adjacent pulls in `SecondaryPullDerivation.adjacentPulls(for:)`.

## 4. Approach: Curated Secondary Pull Substitution

### 4.1 Core Idea

When a user has a `secondaryPull`, replace a small number of colour slots in
the base palette with hand-curated colours from the pull family's palette.
Each (primary family, pull family) pair has a dedicated substitution entry
specifying exactly which slots to swap and which source colours to use — chosen
for aesthetic harmony, not by mechanical index.

### 4.2 Why Curated, Not Mechanical

The v1 draft proposed "always swap index 3 in each band." Analysis of the
actual palette data showed this produces aesthetic clashes for several pairs:

- **Deep Autumn → Deep Winter**: Swapping accent[3] "deep amber" → DW "icy teal"
  drops a bright cool colour into an earth-toned palette. Jarring.
- **Soft Autumn → Bright Winter**: Swapping accent[3] "muted amber" → BW "true red"
  puts a vivid saturated red into a muted palette. Clashes.
- **Slot 3 is not universally low-identity**: In some families it carries
  significant character (e.g. Deep Autumn "bark brown", True Winter "icy grey").

A curated map solves this by selecting the right colour from the pull family
(not always slot 3) and placing it in the right slot of the base palette
(not always slot 3). Each entry is chosen so the borrowed colour shares enough
depth, saturation, or temperature with the base palette to sit harmoniously.

### 4.3 Pull Strength

The number of slots substituted depends on **pull strength**, derived from
the `overrideFlags`:

```
Pull strength = 1 (base)                     →  1 substitution  (accent only)
Pull strength = 2 (one aligned flag fires)   →  2 substitutions (accent + core)
Pull strength = 3 (two+ aligned flags fire)  →  3 substitutions (accent + core + neutral)
```

**Flag-to-pull alignment table:**

| Override flag | Aligns with pull toward |
|--------------|------------------------|
| `winterCompressionApplied` | Deep Winter, True Winter, Bright Winter |
| `coolLeanDeepAutumn` | Deep Winter |
| `scorpioDensityApplied` | Deep Autumn, Deep Winter (depth-adjacent) |
| `fireAirChromaApplied` | Bright Spring, Bright Winter |
| `waterSofteningApplied` | Soft Summer, True Summer, Light Summer |
| `capricornVirgoCoolingApplied` | Deep Winter, True Winter |
| `earthDepthOverrideApplied` | Deep Autumn, True Autumn |
| `surfacePreservationApplied` | Soft Autumn, Soft Summer |

Count how many of the user's `true` flags align with the `secondaryPull`
family. Add 1 (the base). Cap at 3.

### 4.4 Curated Substitution Map

Each entry below defines the substitutions applied at each strength level.
Strength 1 applies the first row only; strength 2 applies the first two;
strength 3 applies all three.

The format is: **target slot → source colour from pull family** (with hex).

---

#### Light Spring

| Pull → Bright Spring | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "fresh leaf" | → BS "bright gold" | `#FFD700` |
| Core[3] "lime" | → BS "vivid yellow" | `#FFE302` |
| Neutral[3] "light camel" | → BS "clear camel" | `#C19A6B` |

| Pull → Light Summer | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "fresh leaf" | → LSu "rose quartz" | `#F7CACA` |
| Core[3] "lime" | → LSu "seafoam" | `#93E9BE` |
| Neutral[3] "light camel" | → LSu "cool taupe" | `#B0A093` |

---

#### True Spring

| Pull → Bright Spring | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "clear aqua" | → BS "bright gold" | `#FFD700` |
| Core[3] "clear turquoise" | → BS "electric blue" | `#0080FF` |
| Neutral[3] "warm stone" | → BS "warm navy" | `#384C70` |

---

#### Bright Spring

| Pull → Bright Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "clear aqua" | → BW "clear cyan" | `#00FFFF` |
| Core[3] "electric blue" | → BW "royal blue" | `#4169E1` |
| Neutral[3] "clear camel" | → BW "steel grey" | `#71797E` |

| Pull → True Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "clear aqua" | → TA "bronze" | `#CD7F32` |
| Core[3] "electric blue" | → TA "deep teal" | `#014D4E` |
| Neutral[3] "clear camel" | → TA "cocoa" | `#7B5B3A` |

---

#### Light Summer

| Pull → True Summer | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "rose quartz" | → TSu "berry mauve" | `#966676` |
| Core[3] "lavender mist" | → TSu "soft violet" | `#9B87A4` |
| Neutral[3] "mist navy" | → TSu "cool stone" | `#8A8D8F` |

| Pull → Light Spring | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "rose quartz" | → LS "apricot" | `#FBCEB1` |
| Core[3] "lavender mist" | → LS "peach" | `#FFCBA4` |
| Neutral[3] "mist navy" | → LS "light camel" | `#C9A96E` |

---

#### True Summer

| Pull → Soft Summer | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "berry mauve" | → SSu "dusty plum" | `#7E6585` |
| Core[3] "soft violet" | → SSu "smoky periwinkle" | `#8E82A7` |
| Neutral[3] "cool stone" | → SSu "muted charcoal" | `#636B6F` |

| Pull → Soft Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "berry mauve" | → SA "soft copper" | `#BD7E55` |
| Core[3] "soft violet" | → SA "muted teal" | `#5E8E8E` |
| Neutral[3] "cool stone" | → SA "warm taupe" | `#AF9B88` |

| Pull → True Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[2] "lavender grey" | → TW "icy blue" | `#A5F2F3` |
| Core[0] "dusty blue" | → TW "cobalt" | `#0047AB` |
| Neutral[3] "cool stone" | → TW "icy grey" | `#D6D6D6` |

---

#### Soft Summer

| Pull → True Summer | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "faded mauve" | → TSu "berry mauve" | `#966676` |
| Core[3] "smoky periwinkle" | → TSu "soft violet" | `#9B87A4` |
| Neutral[3] "muted charcoal" | → TSu "cool stone" | `#8A8D8F` |

| Pull → Soft Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "faded mauve" | → SA "moss green" | `#6B7F3E` |
| Core[3] "smoky periwinkle" | → SA "olive sage" | `#8B8B4B` |
| Neutral[3] "muted charcoal" | → SA "olive beige" | `#B3A580` |

---

#### Soft Autumn

| Pull → True Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "muted amber" | → TA "bronze" | `#CD7F32` |
| Core[3] "soft rust" | → TA "ochre" | `#CC7722` |
| Neutral[3] "olive beige" | → TA "deep khaki" | `#786D4E` |

| Pull → Deep Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "muted amber" | → DA "copper" | `#B87333` |
| Core[3] "soft rust" | → DA "dark terracotta" | `#9E4E3A` |
| Neutral[3] "olive beige" | → DA "bark brown" | `#5C4033` |

| Pull → Bright Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[2] "moss green" | → BW "steel grey" | `#71797E` |
| Core[2] "muted teal" | → BW "icy teal" | `#5FADA5` |
| Neutral[3] "olive beige" | → BW "ink navy" | `#1B2A4A` |

---

#### True Autumn

| Pull → Deep Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "warm auburn" | → DA "deep amber" | `#A36D2A` |
| Core[3] "deep teal" | → DA "forest teal" | `#0B4F4A` |
| Neutral[3] "deep khaki" | → DA "espresso" | `#3C2415` |

| Pull → True Spring | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "warm auburn" | → TS "goldenrod" | `#DAA520` |
| Core[2] "ochre" | → TS "marigold" | `#EAA221` |
| Neutral[3] "deep khaki" | → TS "warm stone" | `#A89F91` |

---

#### Deep Autumn

| Pull → True Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "deep amber" | → TA "warm auburn" | `#A0522D` |
| Core[3] "dark terracotta" | → TA "ochre" | `#CC7722` |
| Neutral[3] "bark brown" | → TA "cocoa" | `#7B5B3A` |

| Pull → Deep Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[2] "copper" | → DW "cool ruby" | `#9B1B30` |
| Core[3] "dark terracotta" | → DW "petrol" | `#1B3A4B` |
| Neutral[1] "warm charcoal" | → DW "cool charcoal" | `#3B3F42` |

---

#### Deep Winter

| Pull → Deep Autumn | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "icy teal" | → DA "copper" | `#B87333` |
| Core[3] "blue-black" | → DA "oxblood" | `#4A1C20` |
| Neutral[3] "cool charcoal" | → DA "warm charcoal" | `#4A4244` |

| Pull → Bright Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "icy teal" | → BW "true red" | `#CC0000` |
| Core[3] "blue-black" | → BW "royal blue" | `#4169E1` |
| Neutral[3] "cool charcoal" | → BW "steel grey" | `#71797E` |

---

#### True Winter

| Pull → Bright Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "hard white" | → BW "clear cyan" | `#00FFFF` |
| Core[2] "blue-red" | → BW "magenta red" | `#CC0066` |
| Neutral[3] "icy grey" | → BW "ink navy" | `#1B2A4A` |

| Pull → True Summer | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "hard white" | → TSu "pewter" | `#8B8E90` |
| Core[3] "clear pine" | → TSu "sage aqua" | `#7DA98E` |
| Neutral[3] "icy grey" | → TSu "dove grey" | `#9C9A9A` |

---

#### Bright Winter

| Pull → Bright Spring | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "true red" | → BS "bright gold" | `#FFD700` |
| Core[3] "icy teal" | → BS "bright teal" | `#009B8D` |
| Neutral[3] "steel grey" | → BS "warm navy" | `#384C70` |

| Pull → True Winter | Target slot | Source colour | Hex |
|---|---|---|---|
| Accent[3] "true red" | → TW "fuchsia red" | `#C81585` |
| Core[3] "icy teal" | → TW "clear pine" | `#2E8B57` |
| Neutral[3] "steel grey" | → TW "icy grey" | `#D6D6D6` |

---

### 4.5 Concrete Example: Ash vs Maria (revised)

**Ash** (Deep Autumn → Deep Winter pull):
- `winterCompressionApplied = true` → aligns with DW → +1
- `coolLeanDeepAutumn = true` → aligns with DW → +1
- `capricornVirgoCoolingApplied = true` → aligns with DW → +1
- Pull strength = 1 (base) + 3 (flags) = **3** (capped) → accent + core + neutral
- Accent[2] "copper" `#B87333` → DW "cool ruby" `#9B1B30` — deep saturated red,
  sits between DA's oxblood and DW's drama
- Core[3] "dark terracotta" `#9E4E3A` → DW "petrol" `#1B3A4B` — deep blue-green,
  adds a cool undertone without being icy
- Neutral[1] "warm charcoal" `#4A4244` → DW "cool charcoal" `#3B3F42` — subtle
  temperature shift in the neutral band, reinforcing the winter edge
- **Result**: Deep Autumn with a dark, inky winter edge

**Maria** (Deep Autumn → True Autumn pull):
- `scorpioDensityApplied = true` → aligns with DA depth, not TA → +0
- Pull strength = 1 (base) + 0 (no aligned flags) = **1** → accent only
- Accent[3] "deep amber" `#A36D2A` → TA "warm auburn" `#A0522D` — warm earthy
  brown-red, fully harmonious with DA's earth palette
- **Result**: Deep Autumn with a warmer, earthier accent

**Side-by-side comparison:**

| Slot | Base DA | Ash (DW pull, str 3) | Maria (TA pull, str 1) |
|------|---------|---------------------|----------------------|
| N1 | espresso `#3C2415` | same | same |
| N2 | warm charcoal `#4A4244` | **cool charcoal** `#3B3F42` | same |
| N3 | deep olive `#3C4B27` | same | same |
| N4 | bark brown `#5C4033` | same | same |
| C1 | oxblood `#4A1C20` | same | same |
| C2 | forest teal `#0B4F4A` | same | same |
| C3 | forest green `#254D32` | same | same |
| C4 | dark terracotta `#9E4E3A` | **petrol** `#1B3A4B` | same |
| A1 | antique gold `#C9A84C` | same | same |
| A2 | aged brass `#8E7530` | same | same |
| A3 | copper `#B87333` | **cool ruby** `#9B1B30` | same |
| A4 | deep amber `#A36D2A` | same | **warm auburn** `#A0522D` |

9/12 shared, 3/12 differ. Both unmistakably Deep Autumn, but Ash's has a
cool undercurrent and Maria's has a warmer earthiness.

### 4.6 No Secondary Pull

If `secondaryPull` is `nil`, the palette is the pure base template with zero
substitutions. Currently every family has ≥2 adjacent pulls, so this would
only occur if the pull derivation heuristics all fail.

## 5. Variation Trace (Diagnostics)

Instead of logging just a substitution count, the trace captures the full
detail of what was changed and why. This makes "why does this palette feel
off?" diagnosable in seconds.

```swift
struct VariationSubstitution: Codable, Equatable {
    let band: String           // "neutral", "core", or "accent"
    let slotIndex: Int         // which slot in the base palette was replaced
    let originalColour: String // colour name before substitution
    let replacedWith: String   // colour name after substitution
    let fromFamily: String     // pull family raw value
}

struct VariationTrace: Codable, Equatable {
    let pullFamily: String?    // secondary pull family raw value, nil if none
    let pullStrength: Int      // 0–3
    let substitutions: [VariationSubstitution]
}
```

Added to `FamilyDecisionTrace`:

```swift
struct FamilyDecisionTrace {
    // ... existing fields ...
    let variation: VariationTrace
}
```

And to `ColourEngineResult`:

```swift
struct ColourEngineResult {
    // ... existing fields ...
    // (variation data is nested inside trace.variation)
}
```

**Example trace output for Ash:**

```json
{
  "pullFamily": "Deep Winter",
  "pullStrength": 2,
  "substitutions": [
    {
      "band": "accent",
      "slotIndex": 2,
      "originalColour": "copper",
      "replacedWith": "cool ruby",
      "fromFamily": "Deep Winter"
    },
    {
      "band": "core",
      "slotIndex": 3,
      "originalColour": "dark terracotta",
      "replacedWith": "petrol",
      "fromFamily": "Deep Winter"
    }
  ]
}
```

## 6. Implementation Plan

### Task 1: `VariationSlots.swift` — Substitution Logic (new file)

New file in `ColourEngineV4/`. Contains:

```swift
enum VariationSlots {

    struct CuratedSubstitution {
        let band: Band
        let targetIndex: Int
        let sourceColourName: String
    }

    enum Band: String {
        case neutral, core, accent
    }

    /// The full 24-entry curated map. Keyed by (primary, pull).
    /// Each value is an ordered array of up to 3 substitutions,
    /// applied in order based on pull strength.
    static let substitutionMap: [PaletteFamily: [PaletteFamily: [CuratedSubstitution]]]

    static func apply(
        base: PaletteTriadV4,
        family: PaletteFamily,
        secondaryPull: PaletteFamily?,
        overrideFlags: OverrideFlags
    ) -> (palette: PaletteTriadV4, trace: VariationTrace)

    static func pullStrength(
        secondaryPull: PaletteFamily,
        flags: OverrideFlags
    ) -> Int  // 1–3
}
```

~150 lines (map data + logic). Pure function, no side effects.

### Task 2: Wire into `ColourEngine.evaluate()`

Replace step 9 in the pipeline:

```
Before:  let palette = PaletteLibrary.palette(for: family)

After:   let basePalette = PaletteLibrary.palette(for: family)
         let (palette, variationTrace) = VariationSlots.apply(
             base: basePalette,
             family: family,
             secondaryPull: secondaryPull,
             overrideFlags: flags
         )
```

Pass `variationTrace` into the `FamilyDecisionTrace` constructor.

### Task 3: Extend `FamilyDecisionTrace` and `VariationTrace` in `Domain.swift`

Add the `VariationSubstitution`, `VariationTrace` structs and the
`variation: VariationTrace` field to `FamilyDecisionTrace`.

### Task 4: Update `MariaAshLocked_Tests`

- `testAshPaletteIsStandardDeepAutumn` → rename to `testAshPaletteIsDeepAutumnWithDWVariation`,
  assert accent[2] == "cool ruby" and core[3] == "petrol"
- `testMariaPaletteIsStandardDeepAutumn` → rename to `testMariaPaletteIsDeepAutumnWithTAVariation`,
  assert accent[3] == "warm auburn"
- **New**: `testAshAndMariaHaveDifferentPalettes` —
  `XCTAssertNotEqual(ashResult.palette, mariaResult.palette)`
- **New**: `testAshVariationTrace` — assert `pullStrength == 2`,
  `substitutions.count == 2`, correct band/slot/colour detail
- **New**: `testMariaVariationTrace` — assert `pullStrength == 1`,
  `substitutions.count == 1`

### Task 5: Add `VariationSlots_Tests.swift`

Unit tests for the substitution logic:
- No secondary pull → zero substitutions, palette unchanged, trace empty
- Pull strength 1 → exactly 1 substitution (accent band)
- Pull strength 2 → exactly 2 substitutions (accent + core)
- Pull strength 3 → exactly 3 substitutions (accent + core + neutral)
- Each substitution uses the curated colour, not mechanical slot-3
- Substitution map completeness: all 24 (family, pull) entries exist
- Round-trip: all substituted colour names resolve to valid hex in `PaletteLibrary.colourNameToHex`
- All 12 families exercised with at least one pull

### Task 6: Update V4 Calibration Regression

Split the regression into two independent gates:

- **Classification gate** — family, cluster, variables (unchanged, still 100/100).
  This never changes when variation rules evolve.
- **Palette gate** — update expected palette values for rows that now have
  variation. Regenerate from the engine and snapshot.

### Task 7: Update golden snapshots

Re-run `PaletteGridViewModel_Tests` with `REGENERATE_PALETTE_GRID_GOLDENS=1`
to capture the new varied palettes for user 1 and user 2.

## 7. Files Changed

| File | Change |
|------|--------|
| `ColourEngineV4/VariationSlots.swift` | **New** — curated substitution map + apply logic |
| `ColourEngineV4/Domain.swift` | Add `VariationSubstitution`, `VariationTrace`; extend `FamilyDecisionTrace` |
| `ColourEngineV4/ColourEngine.swift` | Wire variation into pipeline step 9, pass trace |
| `Cosmic FitTests/MariaAshLocked_Tests.swift` | Update palette expectations, add difference + trace tests |
| `Cosmic FitTests/VariationSlots_Tests.swift` | **New** — unit tests for substitution logic |
| `Cosmic FitTests/V4CalibrationRegression_Tests.swift` | Split classification vs palette gates |
| `Cosmic FitTests/PaletteGridViewModel_Tests.swift` | Regenerate goldens |

## 8. What This Does NOT Change

- Family classification logic (`FamilyMapping.swift`) — untouched
- Scoring, modifiers, thresholds, overrides — untouched
- PaletteLibrary base templates — untouched (still the source of truth)
- UI layer — untouched (still renders whatever `PaletteTriadV4` it receives)
- Narrative templates — untouched
- Daily Fit rotation — untouched (rotates across whatever 12 colours are in the palette)
- Supabase sync — untouched (serialises whatever `PaletteSection` contains)

## 9. Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| A curated substitution still feels off in context | Low | Every entry is hand-selected for depth/temp/sat match; the map is easy to patch per-entry without architectural change |
| Secondary pull is nil for some users → no variation | Low | Every family has ≥2 adjacent pulls; only occurs if all heuristics fail |
| Regression test churn from palette changes | Low | Classification and palette gates are split — classification stays frozen |
| Two same-family users with identical pull + strength collide | Medium | Acceptable for V1 — reduces collision from 100% to a small minority; continuous variation is a V2 concern |
| Curated map has a missing entry | None | Task 5 includes a completeness test asserting all 24 entries exist |

## 10. Future Extensions (Out of Scope)

These are deferred but the architecture supports them:

1. **HSL micro-shifts** — Apply small hue/saturation/lightness adjustments to
   ALL 12 slots based on raw score distance from canonical. Produces continuous
   variation but requires careful bounding to stay aesthetically safe.

2. **Degree-based tinting** — Use placement degrees (currently stored but unused)
   to add sub-sign variation. E.g., early Scorpio vs late Scorpio could shift
   warmth by ±2%.

3. **Extended palette pools** — Expand each family to 6–8 colours per band;
   select the final 4 based on chart signals. Maximum variation but requires
   significant colour curation effort.

4. **Weighted flag alignment** — Replace the flat +1 per aligned flag with
   per-flag weights (e.g., `winterCompressionApplied` contributes +2 while
   `capricornVirgoCoolingApplied` contributes +1). Would improve pull strength
   resolution for edge cases.
