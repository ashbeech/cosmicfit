# Cosmic Fit Interpretation Engine

## Overview

The Cosmic Fit Interpretation Engine translates astrological data into stylistic and emotional fashion guidance. It is designed to produce two core outputs:

1. **Cosmic Blueprint** – a foundational, personality-rooted style profile based on the natal chart.
2. **Daily Fit (formerly Daily Vibe)** – a day-specific energetic style guide based on transits, progressed chart, lunar phase, and weather.

Outputs are constructed using modular "StyleTokens" and scored theme composites, which are assembled into poetic but structured interpretations.

---

## Core Components

### 1. `CosmicFitInterpretationEngine.swift`

**Role**: Orchestrator of interpretation flow. Exposes public methods:

* `generateBlueprintInterpretation(from:currentAge:)`
* `generateDailyVibeInterpretation(from:progressedChart:transits:weather:)`
* `generateFullInterpretation(...)`
* `generateColorFrequencyInterpretation(...)`
* `generateWardrobeStorylineInterpretation(...)`

Delegates token creation to `SemanticTokenGenerator` and assembly to `ParagraphAssembler`.

---

### 2. `SemanticTokenGenerator.swift`

**Role**: Core logic hub. Converts chart data into weighted `StyleToken`s.

#### Main Token Generators:

* `generateBlueprintTokens` – 100% natal, Whole Sign
* `generateColorFrequencyTokens` – 70% natal, 30% progressed, restricted to modulating types
* `generateWardrobeStorylineTokens` – 60% progressed, 40% natal
* `generateTransitTokens` – day-specific tokens using `TransitWeightCalculator`
* `generateEmotionalVibeTokens` – 60% progressed Moon, 40% natal Moon
* `generateMoonPhaseTokens`, `generateWeatherTokens`

#### Token Filtering Rules:

* **Progressed tokens**:

  * Only allowed for `texture`, `structure`, `color_quality`, `mood`, `expression`
  * Never introduce new `color` tokens
  * Weight capped at 0.3 (Color Frequency), 0.6 (Wardrobe), 0.2 (Daily)

* **Ascendant weighting**:

  * Age-faded using `StyleToken.applyingAgeWeight()`
  * Full weight under age 30, gradually diminishing

* **Planetary weighting**:

  * Based on planet importance (e.g. Venus = 2.0, Sun = 1.5)
  * Bonuses for dignity, angularity, rulership

---

### 3. `StyleToken.swift`

Defines the core unit of meaning. A `StyleToken` represents a weighted attribute, e.g. `earthy`, `fluid`, `vibrant`, etc.

Attributes:

* `name`, `type`, `weight`
* `planetarySource`, `signSource`, `houseSource`, `aspectSource`
* `originType` (.natal, .progressed, .transit, .phase, .weather)

Supports age-based weight adjustments via:

* `applyingAgeWeight(currentAge:)`

---

### 4. `TransitWeightCalculator.swift`

Calculates influence score for each transit based on:

* Aspect strength (conjunction > square > trine > sextile, etc.)
* Orb tightness
* Transit planet power (e.g. Pluto > Mars > Mercury)
* Natal planet power (via `PlanetPowerEvaluator`)
* Context multiplier (e.g. Moon hit by Pluto = boost)
* Fashion relevance filter (Venus, Moon, Ascendant emphasized)

Returns a weight from 0.0 to 5.0+, used to scale token weights.

---

### 5. `PlanetPowerEvaluator.swift`

Provides natal planet strength scoring:

* Base power by planet
* Bonus for dignity (domicile, exaltation)
* Angular house presence
* Role: ruler of Ascendant, sect light

Used to calculate `natalPowerScore` in transit weighting.

---

### 6. `ParagraphAssembler.swift`

Builds human-readable interpretation from tokens.

Sections include:

* Style Essence
* Celestial Style ID (Core / Expression / Magnetism / Emotional Dressing / Frequency)
* Style Tensions
* Energetic Fabric Guide
* Style Pulse
* Fashion Dos & Don'ts
* Color Frequency
* Wardrobe Storyline

Also generates Daily Fit content:

* Title, Main Paragraph, Textiles, Colors, Patterns, Shape, Accessories, Takeaway

---

### 7. `ThemeSelector.swift`

Matches tokens against predefined style themes (`CompositeTheme`). Each theme has:

* Required tokens (must match all)
* Optional tokens (score bonus if matched)
* Minimum threshold score

Used to:

* Set Daily Fit theme label
* Select dominant blueprint style profile

---

### 8. `ParagraphBlock.swift`

Used to format final text blocks with tonal and positional metadata. Types include:

* Tones: `warm`, `grounded`, `playful`, `poetic`, `bold`, `minimal`
* Positions: `opener`, `middle`, `closer`

Not yet used dynamically, but available for future layout enhancements.

---

### 9. `CompositeTheme.swift`

Struct definition for themes:

```swift
struct CompositeTheme {
  let name: String
  let required: [String]
  let optional: [String]
  let minimumScore: Double
}
```

Defined themes include `Dream Layering`, `Comfort at the Core`, `Grounded Glamour`, etc.

---

## Summary of Key Architectural Principles

* **Natal chart defines essence**. Always remains the foundation.
* **Progressed chart modulates tone only**. Never overrides or contradicts natal essence.
* **Ascendant influence fades with maturity**. Modulated by age.
* **Transits vary in importance**. Weight based on angle + planet strength + relevance.
* **All content is generated from tokens**, not hardcoded. Tokens → Theme → Paragraphs.

---

## Adding New Features

To extend or adjust:

* **New token types**: Add logic in `SemanticTokenGenerator`
* **New interpretation sections**: Add generator method in `ParagraphAssembler`
* **New transit rules**: Modify `TransitWeightCalculator`
* **New planetary bonuses**: Update `PlanetPowerEvaluator`
* **New themes**: Extend `CompositeTheme` array in `ThemeSelector`

---

## Dependencies

* `NatalChartCalculator` (not included in this upload): must provide sign, house, aspect, and progressed placements.
* `JulianDateCalculator` and `AstronomicalCalculator`: used for Moon Phase.
* `TodayWeather`: input struct for real-world weather token integration.

---

## For Debugging

Use `logTokenSet(...)` in `DailyVibeGenerator.swift` and `ParagraphAssembler.swift` to print tokens by type and weight. Inspect `themeName` from `ThemeSelector.scoreThemes(...)` to trace theme logic.

---

## Final Note

The Cosmic Fit engine is designed to "read the current, not the cables." All astrological logic is embedded and translated into intuitive, emotionally honest fashion guidance—without referencing astrology explicitly in output.

Use this engine as a dynamic base to extend stylistic intelligence, integrate user prompts, or expand to non-fashion domains like interiors, branding, or wellness aesthetics.

# Cosmic Fit UI Integration Layer — Interpretation Display System

This document explains how the Interpretation Engine results (Blueprint and Daily Fit) are routed and rendered across the front-end components in **Cosmic Fit**. This layer ensures users see the correct output, styled and segmented appropriately.

---

## Display Architecture Overview

1. **MainViewController** – User inputs birth data.
2. **NatalChartViewController** – Generates natal/progressed charts + transits + weather.
3. **Interpretation Engine** – Called via `NatalChartManager+Interpretation.swift`.
4. **DailyVibeInterpretationViewController** – Renders Daily Fit.
5. **InterpretationViewController** – Renders Blueprint.

All user interpretations are passed from the engine via `InterpretationResult` or `DailyVibeContent` structs.

---

## Key ViewControllers

### 1. `MainViewController.swift`

* Initial screen where users enter date, time, and location.
* Geocodes the location and sends the data to `NatalChartViewController`.

### 2. `NatalChartViewController.swift`

* Performs all data orchestration:

  * Calculates natal and progressed charts
  * Retrieves weather info
  * Prepares transits
  * Generates interpretations by calling methods in `NatalChartManager+Interpretation.swift`
* Has methods:

  * `showDailyVibeInterpretation()` → pushes `DailyVibeInterpretationViewController`
  * `showBlueprintInterpretation()` → pushes `InterpretationViewController`

Also manages daily caching via `DailyVibeStorage`.

### 3. `NatalChartManager+Interpretation.swift`

This extension is the bridge to the Interpretation Engine:

* Calls:

  * `generateBlueprintInterpretation(...)`
  * `generateDailyVibeInterpretation(...)`
  * `generateFullInterpretation(...)`
* Returns either a full stitched string or a `DailyVibeContent` object

---

## Rendering Blueprint

### `InterpretationViewController.swift`

* Renders the **Cosmic Blueprint** output
* Consumes:

  * `InterpretationResult.stitchedParagraph`
  * `themeName`
  * Birth data for display
* Features:

  * Header with city, date, country
  * Black background, white typography
  * Uses Markdown-like parsing in `setupTextViewStyling()` to style sections (`##`, `---`, etc.)
  * Formats sections: headings, body, dividers
  * Adds export/share button

---

## Rendering Daily Fit

### `DailyVibeInterpretationViewController.swift`

* Renders the **Daily Fit** experience using `DailyVibeContent`

* Displayed fields:

  * Title
  * Main paragraph
  * Textiles
  * Colors
  * Brightness (with slider)
  * Vibrancy (with slider)
  * Patterns
  * Shape
  * Accessories
  * Takeaway

* Weather is displayed at the top (with emoji)

* Sliders drawn with custom gradient layers

* Has `shareInterpretation()` to export as text/image

---

## Interpretation Flow

### Blueprint

1. User generates chart
2. `NatalChartViewController` calls:

```swift
let interpretation = CosmicFitInterpretationEngine.generateBlueprintInterpretation(from: natalChart)
```

3. Passes to `InterpretationViewController.configure(...)`
4. `setupTextViewStyling()` formats Markdown-style text visually

### Daily Fit

1. User opens Daily Vibe
2. `getDailyVibeContent()` runs engine call:

```swift
CosmicFitInterpretationEngine.generateDailyVibeInterpretation(from: natal, progressedChart, transits, weather)
```

3. Results passed to `DailyVibeInterpretationViewController.configure(...)`
4. Fields mapped to labels + gradient sliders drawn

---

## Daily Refresh Logic

Handled in:

* `AppDelegate.swift` → observes midnight + time zone changes
* `NatalChartViewController` → observes `.dailyVibeNeedsRefresh` and regenerates content

---

## Debugging Tools

* `generateDailyVibeInterpretationWithDebug()` available
* `generateBlueprintInterpretationWithDebug()` available
* ViewController logs token counts, parsing steps

---

## Summary

* **Blueprints** → displayed in `InterpretationViewController` with styled Markdown
* **Daily Fits** → displayed in `DailyVibeInterpretationViewController` with labeled sections and visual sliders
* ViewControllers respond to date, location, and chart changes dynamically
* Interpretation Engine content **is fully routed and displayed correctly**

✅ Everything from the Interpretation Engine is reaching the front-end and displaying as expected.

To add new interpretations:

* Add tokens → engine
* Add content to `DailyVibeContent` or `.stitchedParagraph`
* Extend UI to reflect new sections or sliders.

