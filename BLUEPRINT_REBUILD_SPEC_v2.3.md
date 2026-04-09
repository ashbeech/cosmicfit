# Cosmic Fit: Blueprint System Rebuild Specification v2.3

### Changelog

| Version | Date | Summary |
|---------|------|---------|
| v2.3 | 2026-04-09 | Audit fixes: resolved WP5 scope contradiction (moved to Phase 2), corrected WP1 disconnection callsite inventory, inlined WP2 example-provision requirement, reconciled "UI DO NOT MODIFY" policy with scoped exceptions, fixed WP4 planet-sign cardinality (132 not 120), defined canonical archetype-key-to-JSON mapping, specified deterministic algorithms (normalisation, nearest-match, tie-breaks, fallbacks, conflict resolution), added anti-token/opposite schema to WP4, clarified natal vs transit aspect extraction for WP3, corrected version reference typo, added filename-space warning, added pgcrypto/pg_cron prerequisite to WP5 SQL. |
| v2.2 | — | Initial comprehensive rebuild specification. |

---

## Preface: Why This Rebuild Is Necessary

### Background

Cosmic Fit is an astrological fashion guidance iOS app that translates natal charts into personalised style recommendations. It produces two core experiences: a foundational **Cosmic Blueprint** (a one-off, per-user style profile derived from their natal chart) and a dynamic **Daily Fit** (which adapts to current transits, weather, and lunar phases).

### What Went Wrong

The existing codebase was built iteratively while figuring out the product direction. This resulted in an interpretation engine that is a patchwork of experiments, with each layer of tweaking fixing one problem while introducing another. Specifically:

1. **The `SemanticTokenGenerator` is a 4,100-line monolith** that handles Style Guide tokens, Daily Fit tokens, transit tokens, colour tokens, emotional tokens, textile tokens, pattern tokens, accessory tokens, house cusp tokens, aspect tokens, current sun sign tokens, daily signature tokens, moon phase tokens, colour season analysis, colour frequency tokens, wardrobe storyline tokens, and more. It became a catch-all dumping ground.

2. **The weighting system uses inconsistent units.** `WeightingModel.natalWeight` is `0.6` while `WeightingModel.progressedWeight` is `20`. A `DistributionTargets` struct tries to post-hoc correct imbalances by scaling factors -- a band-aid over inputs that were never properly normalised.

3. **Multiple competing colour systems** exist (at least five overlapping generation paths) with no clear hierarchy for which source wins when they conflict.

4. **Astrological-to-style mappings are too thin.** Each planet-sign combination maps to exactly 4 generic tuples (e.g., Venus in Scorpio produces `("magnetic", "mood"), ("power", "structure"), ("black", "colour"), ("controlled", "colour_quality")`). This is far too sparse to produce the rich, distinctive Blueprints the product requires. Outer planets have no sign-specific mappings at all.

5. **The Style Guide output is a literal placeholder string** saying `"STYLE GUIDE PLACEHOLDER"`. The old dynamic generation system (`ParagraphAssembler`) was deprecated before its replacement was built, and the replacement (a template selection system described throughout the README and code comments) was designed but never implemented.

6. **The Blueprint sections have changed.** The old code targeted sections like Style Essence, Celestial Style ID, Expression, Magnetism, Emotional Dressing, Planetary Frequency, Style Tensions, Fabric Guide, Style Pulse, Fashion Dos & Don'ts, Elemental Colours, and Wardrobe Storyline. The new Blueprint has different sections: Style Core, The Textures, The Palette, The Occasions, The Hardware, The Code, The Accessory, The Pattern.

### What Is Solid and Worth Keeping

1. **The astronomical calculation layer is rock solid.** `NatalChartCalculator`, `AstronomicalCalculator`, `JulianDateCalculator`, `VSOP87Parser`, `SwissEphemerisBootstrap`, and `CoordinateTransformations` produce accurate raw astrological data. The `NatalChart` struct is clean and well-defined.

2. **The UI/UX layer works well.** Theming, custom views, navigation, transitions, onboarding -- all solid. It needs section renaming to match the new Blueprint, but that is out of scope for now.

3. **`PlanetPowerEvaluator`** has clean, astrologically sound dignity calculations (domicile, exaltation, detriment, fall), correct base power scores, and proper angular house / chart ruler / sect light bonuses.

4. **The `StyleToken` concept** (weighted tokens with origin tracking) is sound, but needs to be redesigned with a leaner struct and explicit, finite enum for token categories that map to the new Blueprint sections.

5. **`TransitWeightCalculator`** has sophisticated, largely correct transit weighting logic, but is only needed for Daily Fit (out of scope for this rebuild).

### The Rebuild Strategy

- Keep the foundation layer (astronomical calculations) untouched
- Keep the UI layer untouched (separate concern, will be connected later)
- Completely rebuild the interpretation engine from scratch, designed around the new Blueprint sections
- Use deterministic computation for all structured data (palettes, texture lists, metal/stone recommendations, code lists)
- Use AI-generated paragraphs via a one-time backfill script (Gemini API) for all narrative text, with carefully crafted prompts that capture the exact writing style required
- Cache everything in the app bundle so there are zero API calls at runtime and the app works fully offline

---

## Architecture Overview

### The Pipeline

```
NatalChart (raw data from foundation layer)
    |
    v
ChartAnalyser (element balance, dignity, chart ruler, aspect patterns, house contexts)
    |
    v
BlueprintTokens (section-aware tokens from the astrological meaning dataset)
    |
    v
BlueprintComposer (applies weightings, resolves conflicts, selects content per section)
    |
    v
CosmicBlueprint (typed struct with all sections populated -- structured data + cached narrative keys)
    |
    v
[UI layer consumes CosmicBlueprint directly -- out of scope for now]
```

### Key Design Principles

- **Blueprint-first**: The Blueprint is the foundation for the user's entire experience. The Daily Fit and all future features derive from it.
- **Modular pipeline**: Each stage consumes only the output of the previous stage. No circular dependencies. Each can be developed, tested, and replaced independently.
- **Deterministic where possible**: Colour palettes, texture lists, metal/stone recommendations, and code directives are computed deterministically from the astrological dataset with zero AI involvement.
- **AI-generated narrative, cached at build time**: Paragraphs for Style Core, Textures descriptions, Occasions text, Accessory philosophy, and Pattern guidance are generated via Gemini API through a one-time backfill script, cached as JSON in the app bundle, and retrieved at runtime by key. No API calls at runtime.
- **Offline-first**: The app must function fully without an internet connection. All Blueprint content is bundled.
- **`NatalChart` is the contract**: The handoff point between the foundation layer and the interpretation engine is the `NatalChartCalculator.NatalChart` struct. Nothing downstream imports from `Core/Calculations/` except through this struct.

---

## Work Packages

### WP1: Foundation Isolation & Housekeeping

**Goal:** Ensure the astronomical calculation layer is cleanly isolated, disconnect the UI from the live interpretation engine so the app runs as a safe dummy, and strip dead code.

**Owner:** One AI dev (fast model sufficient)

**Context for the developer:**

The foundation layer (`Core/Calculations/`) is already cleanly separated. `NatalChartCalculator`, `AstronomicalCalculator`, `JulianDateCalculator`, `VSOP87Parser`, `SwissEphemerisBootstrap`, and `CoordinateTransformations` have zero imports from the InterpretationEngine. Data flows one way: `NatalChartCalculator.NatalChart` is a pure data struct passed into the engine. No circular dependencies exist. This package formalises that isolation, disconnects the UI, and removes dead code.

#### Tasks

##### 1a. Formalise the Foundation Layer contract

- Add a header comment to `NatalChartCalculator.swift` documenting the `NatalChart` struct as the explicit API contract between the foundation layer and all downstream consumers.
- Verify that no file in `Core/Calculations/` imports from `InterpretationEngine/`. If any do, refactor to remove the dependency.
- Document in a comment block: "This struct is the sole handoff point. The interpretation engine consumes NatalChart and nothing else from this layer."

##### 1b. Disconnect UI from live interpretation engine

There are two categories of callsites that invoke `CosmicFitInterpretationEngine`:

**Category A — Direct UI calls (bypass the manager extension):**
- `NatalChartViewController.swift` — 5 direct calls:
  - Line ~381: `CosmicFitInterpretationEngine.generateDailyVibeInterpretation(...)` in `getDailyVibeContent()`
  - Line ~426: `CosmicFitInterpretationEngine.generateDailyVibeInterpretation(...)` in `getDailyVibeContentWithDebug()`
  - Line ~494: `CosmicFitInterpretationEngine.generateStyleGuideInterpretationWithDebug(...)` in `showStyleGuideInterpretationWithDebug()`
  - Line ~588: `CosmicFitInterpretationEngine.generateDailyVibeInterpretation(...)` in `showDailyVibeInterpretationWithDebug()`
  - Line ~818: (if present) additional debug/generation call
- `CosmicFitTabBarController.swift` — 2 direct calls:
  - Line ~618: `CosmicFitInterpretationEngine.generateStyleGuideInterpretation(from:)` in content generation block
  - Line ~675: `CosmicFitInterpretationEngine.generateDailyVibeInterpretation(...)` in daily fit generation block

**Category B — Manager extension wrapper (thin proxy):**
- `NatalChartManager+Interpretation.swift` — 3 active methods that delegate to the engine:
  - `generateStyleGuideInterpretation(for:)` → `CosmicFitInterpretationEngine.generateStyleGuideInterpretation(from:)`
  - `generateDailyVibeInterpretation(for:...)` → `CosmicFitInterpretationEngine.generateDailyVibeInterpretation(...)`
  - `generateCustomStyleGuidance(for:query:)` → `CosmicFitInterpretationEngine.generateCustomStyleGuidance(...)`
  - (Note: `generateFullInterpretation` is already commented out)

**The approach — both categories must be addressed:**

1. **Category A (direct calls):** In `NatalChartViewController.swift` and `CosmicFitTabBarController.swift`, replace every `CosmicFitInterpretationEngine.generate*` call with inline placeholder returns:
   - For `generateStyleGuideInterpretation` / `generateStyleGuideInterpretationWithDebug`: Replace with a dummy `InterpretationResult` containing `stitchedParagraph: "Blueprint content will be generated by the new interpretation engine. This is a placeholder."` and `themeName: "Placeholder"`.
   - For `generateDailyVibeInterpretation`: Replace with a hardcoded `DailyVibeContent` with a static tarot card (e.g., The Star), dummy `styleEdit` text, zeroed `vibeBreakdown`, neutral `derivedAxes`, and empty `styleTokens`/`paletteColours`.

2. **Category B (manager extension):** Replace the body of `NatalChartManager+Interpretation.swift` methods with the same static placeholder returns as above, so any indirect callers also get placeholders.

3. The UI continues to display, navigate, animate — everything works visually. It just shows placeholder content.

4. Add a comment at the top of `NatalChartManager+Interpretation.swift`: `// PLACEHOLDER: Live engine disconnected pending Blueprint rebuild. See BLUEPRINT_REBUILD_SPEC_v2.3.md`

**Important:** Do NOT simply stub the manager extension and assume the UI is covered. The UI view controllers call the engine directly — the manager extension is not in the call path for those invocations.

##### 1c. Mark transit-specific code as Daily Fit only

- Add header comments to `TransitWeightCalculator.swift`: `// DAILY FIT ONLY -- Not in scope for Blueprint rebuild. Do not modify during Blueprint work.`
- Same for all files exclusively used by the Daily Fit path: `DailyVibeGenerator.swift`, `TarotCardSelector.swift`, `TarotCard.swift`, `TarotCardValidator.swift`, `TarotRecencyTracker.swift`, `TarotSelectionMonitor.swift`, `VibeBreakdown .swift` **(note: filename contains a space before `.swift` — this is the actual on-disk name; use quotes in scripts: `"VibeBreakdown .swift"`)**, `DailyColourPaletteGenerator.swift`, `DailySeedGenerator.swift`, `AxisBalancer.swift`, `AxisTokenGenerator.swift`, `AxisVolatilityEngine.swift`, `AstroFeatures.swift`, `AstroFeaturesBuilder.swift`, `DerivedAxesConfiguration.swift`, `DerivedAxesEvaluator.swift`, `StructuralAxes.swift`, `MoonPhaseInterpreter.swift`, `WeatherFabricFilter.swift`, `ColourScoring.swift`, `TokenMerger.swift`, `TransitCapper.swift`.
- Do NOT delete these files. They will be revisited when Daily Fit is rebuilt.

##### 1d. Strip dead/legacy code

Move these files to a new `_archive/` directory at project root (do not delete, in case anything needs referencing later):

- `InterpretationEngine/ParagraphAssembler.swift` (~91KB, legacy dynamic generation)
- `InterpretationEngine/InterpretationTextLibrary.swift` (~98KB, legacy text library)
- `InterpretationEngine/ThemeSelector.swift` (obsolete theme matching)
- `InterpretationEngine/CompositeTheme.swift` (obsolete theme model)
- `InterpretationEngine/Tier2TokenLibrary.swift` (~97KB, never activated)
- `InterpretationEngine/TokenEnergyOverrides.swift` (patching mechanism)
- `InterpretationEngine/TokenPrefixMatrix.swift` (patching mechanism)

**Before archiving `InterpretationTextLibrary.swift`:** Extract the `TokenGeneration.PlanetInSign` data tables (Sun/Moon/Venus/Mars/Mercury descriptions for all 12 signs, plus OuterPlanets, ElementalFallbacks, and Retrograde tables) into a standalone reference file called `_archive/extracted_planet_sign_token_tables.json`. This data will be used as a starting point for WP4 (the astrological meaning dataset).

##### 1e. Update Xcode project

- Remove archived files from the Xcode build target (but keep them in the project navigator under an `_archive` group for reference).
- Ensure the project builds and runs cleanly with placeholder content.
- Verify the app launches, navigates between tabs, shows placeholder text in Style Guide and Daily Fit views.

**Deliverables:**
- Clean-building project with placeholder content
- Documented foundation layer contract
- All dead code archived with extracted token tables
- All Daily Fit files marked as out of scope

---

### WP2: Blueprint Data Model

**Goal:** Define the exact typed Swift data structures for the Blueprint output. This is the "what does the result look like" contract that WP3 and WP4 depend on.

**Owner:** One AI dev (fast model sufficient)

**Context for the developer:**

The Blueprint is a one-off, per-user style profile generated from their natal chart. It consists of 8 sections. Below are two complete examples of what the final Blueprint content looks like for real users. Your job is to define Swift structs that can represent these examples exactly, with both structured data (colours as hex values, lists of directives) and narrative text (the paragraphs the user reads) cleanly separated.

#### Reference: Test User Examples

**Test User 1 (12/11/1984, London, UK)** -- Sections: Style Core, The Textures (Good/Bad/Sweet Spot), The Palette (visual + text), The Occasions (Work/Intimate/Daily), The Hardware (Metals/Stones/Tip), The Code (Lean Into/Avoid/Consider), The Accessory (3 paragraphs), The Pattern (philosophy + tip).

**Test User 2 (28/04/1989)** -- Same sections, completely different content reflecting different natal chart.

**Provision requirement:** The full text of both examples MUST be provided in-repo before WP2 begins. Create a file `_reference/blueprint_examples.md` containing the complete output text for both test users. This file is a hard dependency for WP2 — the developer cannot design accurate structs without seeing the exact content they must represent. Do NOT rely on the developer "requesting" them; the examples must be committed to the repository alongside this spec.

If the examples have not yet been committed, the WP2 developer should treat this as a **blocker** and escalate immediately rather than guessing at the data shape.

#### Tasks

##### 2a. Define the root `CosmicBlueprint` struct

```swift
struct CosmicBlueprint: Codable {
    let userInfo: BlueprintUserInfo
    let styleCore: StyleCoreSection
    let textures: TexturesSection
    let palette: PaletteSection
    let occasions: OccasionsSection
    let hardware: HardwareSection
    let code: CodeSection
    let accessory: AccessorySection
    let pattern: PatternSection
    let generatedAt: Date
    let engineVersion: String
}
```

##### 2b. Define each section struct

Each section must have:
- Typed fields for structured data (colour arrays, directive lists, etc.)
- A `narrativeText` field (or multiple, e.g., `goodText`, `badText`, `sweetSpotText`) for AI-generated paragraphs
- Codable conformance for JSON serialisation

Key structs to define:

- `BlueprintUserInfo` -- birth date, location string, generation date
- `StyleCoreSection` -- `narrativeText: String` (the opening paragraph)
- `TexturesSection` -- `goodText: String`, `badText: String`, `sweetSpotText: String`
- `PaletteSection` -- `coreColours: [BlueprintColour]`, `accentColours: [BlueprintColour]`, `narrativeText: String` (the descriptive paragraph about their palette)
- `BlueprintColour` -- `name: String` (e.g., "midnight"), `hexValue: String`, `role: ColourRole` (enum: `.core`, `.accent`, `.statement`)
- `OccasionsSection` -- `workText: String`, `intimateText: String`, `dailyText: String`
- `HardwareSection` -- `metalsText: String`, `stonesText: String`, `tipText: String`, plus `recommendedMetals: [String]`, `recommendedStones: [String]`
- `CodeSection` -- `leanInto: [String]` (list of directives), `avoid: [String]`, `consider: [String]`
- `AccessorySection` -- `paragraphs: [String]` (3 paragraphs)
- `PatternSection` -- `narrativeText: String`, `tipText: String`, `recommendedPatterns: [String]`, `avoidPatterns: [String]`

##### 2c. Define the `BlueprintToken` struct

This replaces the old `StyleToken`. It is leaner and section-aware:

```swift
struct BlueprintToken: Codable {
    let name: String
    let category: TokenCategory      // Finite enum, not free-form string
    let weight: Double
    let planetarySource: String?
    let signSource: String?
    let houseSource: Int?
    let aspectSource: String?

    enum TokenCategory: String, Codable, CaseIterable {
        case texture        // Feeds: TexturesSection
        case colour         // Feeds: PaletteSection
        case silhouette     // Feeds: OccasionsSection, CodeSection
        case metal          // Feeds: HardwareSection (metals)
        case stone          // Feeds: HardwareSection (stones)
        case pattern        // Feeds: PatternSection
        case accessory      // Feeds: AccessorySection
        case mood           // Feeds: StyleCoreSection, OccasionsSection
        case structure      // Feeds: CodeSection, TexturesSection
        case expression     // Feeds: StyleCoreSection
    }
}
```

##### 2d. Define a `BlueprintArchetypeKey` system

Since narrative paragraphs are pre-generated and cached, each Blueprint section needs a way to look up its narrative content. Define a key system:

```swift
struct BlueprintArchetypeKey: Codable, Hashable {
    let section: BlueprintSection       // Which section this key addresses
    let archetypeCluster: String        // e.g., "venus_scorpio_saturn_capricorn_fire_dominant"
    let variant: Int                    // For sections that have multiple sub-parts (0 = default)

    enum BlueprintSection: String, Codable, CaseIterable {
        case styleCore = "style_core"
        case texturesGood = "textures_good"
        case texturesBad = "textures_bad"
        case texturesSweetSpot = "textures_sweet_spot"
        case paletteNarrative = "palette_narrative"
        case occasionsWork = "occasions_work"
        case occasionsIntimate = "occasions_intimate"
        case occasionsDaily = "occasions_daily"
        case hardwareMetals = "hardware_metals"
        case hardwareStones = "hardware_stones"
        case hardwareTip = "hardware_tip"
        case accessoryParagraph1 = "accessory_1"
        case accessoryParagraph2 = "accessory_2"
        case accessoryParagraph3 = "accessory_3"
        case patternNarrative = "pattern_narrative"
        case patternTip = "pattern_tip"
    }
}
```

**Canonical key mapping rule:** The `BlueprintSection` enum raw values are the **canonical keys** used in `blueprint_narrative_cache.json`. The enum uses explicit `snake_case` raw values that match the JSON keys exactly. Swift code accesses cache entries via `section.rawValue` — no separate mapping table or string conversion is needed. The JSON example in §3e uses these same keys.
```

**Deliverables:**
- A single Swift file: `BlueprintModels.swift` containing all structs, enums, and protocols
- The file compiles standalone (no dependencies on existing codebase beyond Foundation)
- A brief companion document listing which fields are deterministic vs AI-generated

---

### WP3: The Interpretation Engine

**Goal:** Build the system that takes a `NatalChartCalculator.NatalChart` and produces a `CosmicBlueprint`.

**Owner:** One AI dev (capable model, large context window)

**Context for the developer:**

This is the largest work package. You are building the core engine that converts raw astrological chart data into a complete, personalised style Blueprint. The engine has two distinct content generation paths:

1. **Deterministic path** -- for structured data (colour palettes, texture lists, metal/stone recommendations, code directives, pattern lists). These are computed directly from the astrological meaning dataset (provided by WP4) using weighted token analysis. No AI involvement.

2. **Cached narrative path** -- for paragraph text (Style Core, Textures descriptions, Occasions, Hardware descriptions, Accessory paragraphs, Pattern narrative). These are pre-generated by a Gemini API backfill script (also part of this package) and cached as a JSON file in the app bundle. At runtime, the engine looks up the appropriate cached paragraph by archetype key.

#### Dependencies

- **WP2 output:** The `CosmicBlueprint` struct and all section structs, `BlueprintToken`, `BlueprintArchetypeKey`
- **WP4 output:** The astrological meaning dataset (`astrological_style_dataset.json`)
- **Existing code (read-only reference):** `PlanetPowerEvaluator.swift` for dignity calculations and power scoring logic

#### Architecture

```
                         ┌─────────────────────────┐
                         │   NatalChart (input)     │
                         └────────────┬────────────┘
                                      │
                         ┌────────────▼────────────┐
                         │     ChartAnalyser        │
                         │  - element balance       │
                         │  - dignity evaluation    │
                         │  - chart ruler ID        │
                         │  - aspect pattern scan   │
                         │  - house context map     │
                         └────────────┬────────────┘
                                      │
                         ┌────────────▼────────────┐
                         │  BlueprintTokenGenerator  │
                         │  - loads WP4 dataset     │
                         │  - generates section-    │
                         │    aware BlueprintTokens │
                         │  - applies weightings    │
                         └────────────┬────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                  │
         ┌──────────▼──────┐  ┌──────▼───────┐  ┌──────▼───────┐
         │ DeterministicRes│  │ ArchetypeKey  │  │   Narrative   │
         │  - palette      │  │  Generator    │  │   Cache       │
         │  - textures list│  │  - clusters   │  │   Lookup      │
         │  - metals/stones│  │    tokens     │  │  (JSON file)  │
         │  - code lists   │  │  - produces   │  │               │
         │  - pattern lists│  │    lookup key  │  │               │
         └────────┬────────┘  └──────┬────────┘  └──────┬────────┘
                  │                  │                   │
                  └──────────────────┼───────────────────┘
                                     │
                         ┌───────────▼───────────┐
                         │   BlueprintComposer    │
                         │  - assembles struct    │
                         │  - merges deterministic│
                         │    + cached narrative  │
                         └───────────┬───────────┘
                                     │
                         ┌───────────▼───────────┐
                         │   CosmicBlueprint      │
                         │   (complete output)    │
                         └───────────────────────┘
```

#### Tasks

##### 3a. `ChartAnalyser`

A new, clean module that takes a `NatalChart` and produces a `ChartAnalysis` struct:

```swift
struct ChartAnalysis {
    let elementBalance: ElementBalance       // fire/earth/air/water counts and percentages
    let modalityBalance: ModalityBalance     // cardinal/fixed/mutable
    let chartRuler: String                   // ruling planet of Ascendant sign
    let sunSign: String
    let moonSign: String
    let ascendantSign: String
    let venusSign: String
    let marsSign: String
    let planetDignities: [String: DignityStatus]   // planet name -> dignity
    let planetHouses: [String: Int]                 // planet name -> house number
    let significantAspects: [ChartAspect]           // filtered to meaningful aspects only
    let dominantPlanets: [String]                   // top 3 planets by power score
}
```

Port the dignity logic from `PlanetPowerEvaluator` (it is correct) and the chart ruler lookup from `SemanticTokenGenerator.getChartRuler()` (also correct).

**Aspect detection — important distinction:**

The existing `NatalChartCalculator.calculateTransits()` computes **transit aspects** (current transiting planets aspecting natal positions). This is NOT what WP3 needs.

`ChartAnalyser` requires **natal-natal aspects**: aspects between planets *within the birth chart itself* (e.g., "natal Venus square natal Saturn"). These represent permanent personality/style tensions, not transient daily influences.

**What to port:** The underlying geometric calculation in `AstronomicalCalculator.calculateAspect(point1:point2:orb:)` (which computes aspect type and exactness from two ecliptic longitudes) is correct and reusable. Port this math, but apply it to **pairs of natal planet longitudes** from the `NatalChart` struct, not to transit-vs-natal pairs.

**Implementation:**
1. Extract all planet longitudes from `NatalChart.planets` (a `[String: PlanetPosition]` dictionary where each `PlanetPosition` has a `longitude` field)
2. For each unique pair of planets, call `AstronomicalCalculator.calculateAspect(point1: planet1.longitude, point2: planet2.longitude, orb:)`
3. Filter to major aspects only (conjunction, opposition, trine, square, sextile) involving at least one of: Venus, Moon, Sun, Mars, Ascendant
4. Store as `[ChartAspect]` in the `ChartAnalysis` struct

**Do NOT import or call** `NatalChartCalculator.calculateTransits()` — that function is for the Daily Fit transit path and has device-location dependencies (topocentric Moon) that are irrelevant to natal chart analysis.

##### 3b. `BlueprintTokenGenerator`

Loads the astrological meaning dataset (WP4) and generates `BlueprintToken` arrays for each section. Key rules:

- Venus, Moon, and Ascendant are the primary drivers for style/aesthetic sections
- Chart ruler gets a significant weight multiplier (carry over the 2.5x from existing code)
- Dignity status modifies weight (domicile +0.6, exaltation +0.5, detriment -0.2, fall -0.3 -- same as existing `PlanetPowerEvaluator`)
- House placement provides contextual application (Venus in 2nd vs Venus in 10th)
- Aspects create modifications and tensions (Venus square Saturn = style restraint, Venus trine Jupiter = style expansion)
- Each token has a `category` that maps it to specific Blueprint sections
- The weighting system must use normalised units (0.0-1.0 scale for all multipliers)

**Token weight normalisation formula:**

All raw token weights are normalised to a 0.0–1.0 scale before downstream use. The formula:

```
normalisedWeight = rawWeight / maxRawWeightInCategory
```

Where `maxRawWeightInCategory` is the highest raw weight among all tokens in the same `TokenCategory`. This ensures cross-category comparisons are meaningful (a 0.8 texture token and a 0.8 colour token represent equivalent relative strength within their domains).

Raw weight is computed as:

```
rawWeight = basePlanetWeight × dignityModifier × chartRulerMultiplier × aspectModifier
```

Where:
- `basePlanetWeight`: Venus = 1.0, Moon = 0.9, Ascendant = 0.85, Sun = 0.8, Mars = 0.7, Saturn = 0.5, Jupiter/Mercury = 0.4, Uranus/Neptune/Pluto = 0.3
- `dignityModifier`: domicile = 1.6, exaltation = 1.5, peregrine = 1.0, detriment = 0.8, fall = 0.7
- `chartRulerMultiplier`: 2.5 if this planet is the chart ruler, 1.0 otherwise
- `aspectModifier`: conjunction = 1.3, trine/sextile = 1.15, square/opposition = 0.85, no significant aspect = 1.0

**Token conflict resolution rules:**

When tokens from different planetary sources produce contradictory directives for the same section (e.g., Venus says "flowy" textures, Saturn says "structured" textures):

1. Higher normalised weight wins for list ordering (the stronger influence appears first / is prioritised)
2. Contradictory tokens are NOT removed — they surface as creative tension in the Blueprint (e.g., "good textures" might include both structured and flowy items, ordered by weight)
3. Exception: for `CodeSection.avoid`, a token explicitly tagged as `avoid` in the dataset always appears in the avoid list regardless of weight, unless the same item also appears in `leanInto` with higher weight (in which case it is moved to `consider`)

##### 3c. `DeterministicResolver`

Takes the token arrays and resolves each structured data field. All resolution uses normalised weights (0.0–1.0) from §3b.

**Palette resolution:**
1. Collect all tokens with `category == .colour`, sorted by normalised weight descending.
2. For each token, look up the corresponding colour entry in the WP4 `colour_library`.
3. Select up to 4 core colours (top weighted) and 2 accent colours (next tier).
4. **Diversity constraint:** No two selected colours may have hue distance < 15° on the HSL colour wheel. If a candidate colour is too close to an already-selected colour, skip it and take the next candidate. (Hue distance = `min(|h1 - h2|, 360 - |h1 - h2|)`.)
5. **Tie-break rule (applies to all lists):** When two tokens have identical normalised weight, prefer the token whose planetary source has higher `basePlanetWeight` (Venus > Moon > Ascendant > etc.). If still tied, prefer the token that appears first in the dataset entry's array order (stable sort).

**Textures resolution:**
1. Tokens with `category == .texture`, sorted by normalised weight descending.
2. "Good" list: top 5–8 items (weight ≥ 0.4 after normalisation).
3. "Bad" list: items explicitly tagged `"bad"` in the WP4 dataset entry's `textures.bad` array for any planet-sign combo contributing tokens with weight ≥ 0.3.
4. "Sweet spot" list: items from `textures.sweet_spot_keywords` in the dataset, filtered to those whose corresponding tokens have weight ≥ 0.5.

**Metals/Stones resolution:**
1. For each of the top 3 dominant planet-sign combos (by aggregate token weight), look up `metals` and `stones` arrays in the dataset.
2. Merge lists, de-duplicate, order by frequency of appearance across the top combos (most-mentioned first). Tie-break: prefer entry from the highest-weighted planet-sign combo.

**Code directives resolution:**
1. "Lean Into": Top 4–6 items from `code_leaninto` arrays across contributing planet-sign combos, ordered by the combo's aggregate weight.
2. "Avoid": Items from `code_avoid` arrays, PLUS anti-tokens generated from the `opposites` mapping in the dataset (see §4a addendum). Anti-tokens are the stylistic opposites of the top 3 "Lean Into" directives.
3. "Consider": Items from `code_consider` arrays of planet-sign combos with moderate weight (0.3–0.6 normalised range). These represent secondary influences that add nuance without dominating.

**Pattern resolution:**
1. Recommended patterns from `patterns.recommended` arrays, weighted by element balance modifier AND Venus-sign combo weight.
2. Avoid patterns from `patterns.avoid` arrays, same weighting logic.
3. Select top 4–6 recommended, top 3–4 avoid.

**Section-level fallback order:** If a section has fewer than the minimum required items after resolution (e.g., < 3 core colours), fall back in this order:
1. Widen the weight threshold by 0.1 (e.g., 0.4 → 0.3) and re-resolve
2. Include entries from the chart's element balance modifier (e.g., `fire_dominant` colour defaults)
3. Include entries from the Sun sign planet-sign combo (always available as a baseline)
4. If still insufficient, use the Sun sign's full dataset entry as a default fill

##### 3d. `ArchetypeKeyGenerator`

Analyses the token distribution to produce a `BlueprintArchetypeKey` for each narrative section. The key encodes the dominant astrological configuration that drives that section's content.

The archetype clustering approach:

1. For each narrative section, identify the 2-3 most influential planet-sign combinations (by token weight)
2. Combine these into a cluster key: e.g., `"venus_scorpio__moon_capricorn__fire_dominant"`
3. This key maps to a pre-generated paragraph in the narrative cache

**Nearest-match fallback algorithm:**

Because we're clustering ~infinite chart possibilities into ~80-100 bins, some users will have charts that don't perfectly match any single cluster. The engine picks the nearest match using this concrete algorithm:

1. **Exact match first:** If the generated key exists in the cache, use it directly. Done.
2. **Component distance:** If no exact match, decompose the key into its 3 components: `(venus_sign, moon_sign, element_group)`. Compute a distance score against every cached key:
   ```
   distance = (venus_match ? 0 : 3) + (moon_match ? 0 : 2) + (element_match ? 0 : 1)
   ```
   Venus mismatch is costliest because it is the primary fashion driver. Element mismatch is cheapest because it provides ambient flavour rather than specific style directives.
3. **Sign-affinity sub-scoring:** When Venus or Moon signs don't match exactly, prefer the cluster whose mismatched sign shares the same **element** as the user's sign (e.g., user has Moon in Gemini → prefer a cluster with Moon in Libra or Aquarius over Moon in Cancer). This adds a fractional bonus: subtract 0.5 from the distance for each same-element near-miss.
4. **Tie-break:** If multiple clusters have the same distance score, prefer the cluster whose Venus sign matches (even if Moon doesn't). If still tied, prefer the cluster that appears first alphabetically (deterministic, reproducible).
5. **Logging:** When a fallback is used, log the original key, the matched key, and the distance score. This data informs future cluster expansion decisions.

This is a deliberate tradeoff — not a flaw. If certain chart types are getting noticeably imprecise matches, you can add more clusters to that region and re-run the backfill script for just the new clusters without regenerating everything.

The number of unique archetype clusters needs to be manageable. Estimated coverage:
- 12 Venus signs x 12 Moon signs = 144 core combinations
- Grouped by element dominance (4 groups) and chart ruler influence (reduces to ~80-100 meaningful clusters)
- Each cluster has content for ~15 narrative sub-sections = **~1,200-1,500 total paragraphs**

##### 3e. Narrative Backfill Script

A command-line Swift script (or Python script, whichever is more practical for Gemini API calls) that:

1. Iterates through all archetype clusters
2. For each cluster, for each narrative section, makes a Gemini API call
3. Caches the response in a JSON file

**Critical: The prompt engineering**

The prompt must produce paragraphs that match the exact writing style of the human-written examples. The strategy:

- **System prompt**: Contains the consolidated style guide (extracted from analysing the human-written Tarot interpretations and Blueprint examples). This defines: vocabulary to use, vocabulary to avoid, sentence structure patterns, paragraph length targets, tone (direct, confident, slightly irreverent, fashion-insider), the "fashion-girly naturalistic" voice. This system prompt stays the same for every API call to keep context window efficient.

- **Per-call user prompt**: Contains only the specific astrological configuration for this archetype cluster and section, plus 2-3 example paragraphs of the exact section being generated (pulled from the human-written test user examples). This keeps each call focused and small.

- **Response constraints**: Each paragraph should be 3-6 sentences. No astro jargon in the output. No hedging language ("you might", "perhaps"). Direct second-person address ("You", "Your"). British English spelling.

- **Batch strategy**: One API call per section per archetype cluster. Do NOT batch multiple sections into one call. This keeps each response focused and prevents degradation from context window depth. Estimated total calls: ~1,200-1,500. At Gemini API rates this is very affordable.

- **Quality control**: The script should include a validation pass that checks each generated paragraph for: minimum length (50 words), maximum length (150 words), absence of banned words (e.g., "delve", "tapestry", "resonate", "elevate", "curate" -- common AI tells), presence of required style markers.

- **Output**: A single `blueprint_narrative_cache.json` file structured as:
```json
{
  "venus_scorpio__moon_capricorn__fire_dominant": {
    "style_core": "Your presence is a study in...",
    "textures_good": "You need materials that feel like...",
    "textures_bad": "Anything fluffy or...",
    "textures_sweet_spot": "The stiff and the sharp...",
    "palette_narrative": "Your core colours are...",
    "occasions_work": "Sharp tailoring and...",
    "occasions_intimate": "When you relax, keep it...",
    "occasions_daily": "Even off-duty, things need...",
    "hardware_metals": "You need cold power...",
    "hardware_stones": "Choose stones that look like...",
    "hardware_tip": "Precision is your law...",
    "accessory_1": "One significant piece carries...",
    "accessory_2": "Accessories are where you...",
    "accessory_3": "Consider the click and the weight...",
    "pattern_narrative": "Patterns are often a distraction...",
    "pattern_tip": "Keep it monochromatic..."
  }
}
```

##### 3f. `BlueprintComposer`

The final assembly step. Takes:
- `ChartAnalysis` (from 3a)
- Deterministic resolved data (from 3c)
- Archetype keys (from 3d)
- Narrative cache (loaded from JSON)

Assembles and returns a complete `CosmicBlueprint` struct.

##### 3g. `NarrativeCacheLoader`

A utility that loads `blueprint_narrative_cache.json` from the app bundle at startup and provides lookup by `BlueprintArchetypeKey`. Handles:
- Cache miss gracefully (falls back to nearest matching archetype)
- Memory-efficient loading (lazy or on-demand if the JSON is large)

#### Files to Create

| File | Purpose |
|------|---------|
| `ChartAnalyser.swift` | Natal chart analysis |
| `BlueprintTokenGenerator.swift` | Section-aware token generation |
| `DeterministicResolver.swift` | Structured data resolution |
| `ArchetypeKeyGenerator.swift` | Archetype clustering for narrative lookup |
| `BlueprintComposer.swift` | Final assembly |
| `NarrativeCacheLoader.swift` | JSON cache loading and lookup |
| `backfill_narratives.py` (or `.swift`) | One-time Gemini API script |
| `blueprint_narrative_cache.json` | Cached narrative paragraphs (app bundle resource) |

**Deliverables:**
- All engine files, compiling and tested
- Backfill script that can be run from terminal: `python3 backfill_narratives.py --api-key <KEY> --dataset astrological_style_dataset.json --output blueprint_narrative_cache.json`
- The generated `blueprint_narrative_cache.json`
- A test harness that takes a birth date + location and prints the resulting `CosmicBlueprint` to console

---

### WP4: Astrological Meaning Dataset

**Goal:** Build the comprehensive dataset that maps astrological configurations to style dimensions for every Blueprint section.

**Owner:** One AI dev (capable model, large context window)

**Context for the developer:**

This dataset is the "knowledge base" of the interpretation engine. It replaces the thin 4-tuple mappings in the old `InterpretationTextLibrary`. It maps every meaningful astrological configuration to style attributes that directly feed each Blueprint section.

#### Dependencies

- **WP2 output:** Blueprint section definitions and `BlueprintToken.TokenCategory` enum (to know what categories to populate)
- **Reference input:** Extracted planet-sign token tables from the old `InterpretationTextLibrary` (provided by WP1 as `extracted_planet_sign_token_tables.json`)

#### Dataset Structure

A single JSON file: `astrological_style_dataset.json`

```json
{
  "planet_sign": {
    "venus_aries": {
      "style_philosophy": "spontaneous, direct, bold first impressions",
      "textures": {
        "good": ["lightweight cotton", "crisp poplin", "tech fabrics"],
        "bad": ["heavy brocade", "stiff formal fabrics"],
        "sweet_spot_keywords": ["movement", "freedom", "athletic"]
      },
      "colours": {
        "primary": [
          {"name": "coral", "hex": "#FF6F61"},
          {"name": "bright red", "hex": "#CC0000"}
        ],
        "accent": [
          {"name": "warm white", "hex": "#FAF0E6"}
        ],
        "avoid": ["muted pastels", "grey-heavy palettes"]
      },
      "metals": ["rose gold", "polished brass"],
      "stones": ["carnelian", "red jasper", "garnet"],
      "patterns": {
        "recommended": ["bold stripes", "colour blocking", "athletic details"],
        "avoid": ["tiny florals", "paisley", "fussy prints"]
      },
      "silhouette_keywords": ["sharp shoulders", "cropped", "streamlined"],
      "occasion_modifiers": {
        "work": "decisive, sharp, no-nonsense",
        "intimate": "direct, warm, confident",
        "daily": "athletic, purposeful, ready to move"
      },
      "code_leaninto": ["first impressions matter -- dress for impact", "bold colour over safe neutral"],
      "code_avoid": ["anything that requires fussing or adjusting", "overly delicate pieces"],
      "code_consider": ["one statement piece rather than layered complexity"],
      "opposites": {
        "textures": ["heavy brocade", "stiff formal fabrics", "delicate lace"],
        "colours": ["muted pastels", "grey-heavy palettes"],
        "silhouettes": ["restrictive tailoring", "overly layered"],
        "mood": ["cautious", "restrained", "overly deliberate"]
      }
    }
  },

  "aspects": {
    "venus_square_saturn": {
      "effect": "tension between desire for beauty and need for restraint",
      "texture_modifier": "adds structure, reduces flowy",
      "colour_modifier": "darkens palette, adds formality",
      "code_addition_leaninto": "investing in fewer, better pieces",
      "code_addition_avoid": "impulse shopping or trend-chasing"
    }
  },

  "house_placements": {
    "venus_house_2": {
      "context": "values, possessions, self-worth through style",
      "modifier": "emphasises quality, investment pieces, tactile pleasure"
    },
    "venus_house_10": {
      "context": "public image, career, visible identity",
      "modifier": "emphasises polished presentation, power dressing, reputation"
    }
  },

  "element_balance": {
    "fire_dominant": {
      "overall_energy": "bold, warm, expressive",
      "palette_bias": "warm tones, high contrast",
      "texture_bias": "lightweight, movement-friendly"
    }
  },

  "colour_library": {
    "midnight": {"hex": "#191970", "associations": ["scorpio", "capricorn", "saturn"]},
    "oxblood": {"hex": "#4A0000", "associations": ["scorpio", "pluto", "mars"]},
    "sage green": {"hex": "#9CAF88", "associations": ["taurus", "venus", "earth"]},
    "coral": {"hex": "#FF6F61", "associations": ["aries", "mars", "venus_aries"]}
  }
}
```

#### Tasks

##### 4a. Planet-Sign entries (132 entries)

For each of the 11 chart bodies (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, **Ascendant**) in each of the 12 signs, create a complete entry covering all Blueprint section dimensions. This yields **11 × 12 = 132 entries**.

The Ascendant is treated as a "planet" entry in the dataset (keyed as e.g. `ascendant_aries`, `ascendant_taurus`, etc.) because it drives presentation style independently of any planetary placement.

Priority weighting for data richness:
- **Venus in each sign** (12 entries) — most detail (primary fashion planet)
- **Moon in each sign** (12 entries) — high detail (emotional/comfort style driver)
- **Sun in each sign** (12 entries) — good detail (core identity)
- **Mars in each sign** (12 entries) — moderate detail (energy/approach)
- **Ascendant in each sign** (12 entries) — moderate detail (presentation style)
- **Saturn in each sign** (12 entries) — moderate detail (structure/discipline)
- **Jupiter, Mercury, Uranus, Neptune, Pluto** (60 entries) — lighter detail (supporting influences)

**Required `opposites` field:** Each planet-sign entry MUST include an `opposites` object with keys: `textures`, `colours`, `silhouettes`, `mood`. These are the stylistic antitheses of the planet-sign's dominant energy and are consumed by the `DeterministicResolver` to generate `CodeSection.avoid` anti-tokens. Without this field, the "Avoid" directives in The Code section will be incomplete.

**Starting point:** Use the extracted token tables from the old `InterpretationTextLibrary` as a skeleton, but expand each entry from 4 generic tuples to the full section-specific structure shown above.

**Validation:** Cross-reference with professional astrological sources. Key checks:
- Venus in Taurus should map to luxurious textures, earth tones, quality over quantity
- Venus in Scorpio should map to dark palettes, power dressing, concealment/revelation
- Moon in Cancer should map to comfort fabrics, nostalgic pieces, protective layering
- Mars in Aries should map to athletic cuts, bold colours, decisive silhouettes
- Saturn in Capricorn should map to structured tailoring, dark neutrals, investment pieces

##### 4b. Aspect entries (~30 key aspects)

Focus on aspects involving Venus, Moon, Sun, Mars, and Ascendant with each other and with Saturn, Jupiter, Uranus, Neptune, Pluto. Each entry describes how the aspect modifies the base planet-sign interpretation.

Priority aspects:
- Venus-Saturn (any aspect type)
- Venus-Jupiter
- Venus-Mars
- Venus-Uranus
- Venus-Neptune
- Moon-Saturn
- Moon-Venus
- Sun-Saturn
- Mars-Saturn
- Ascendant-Venus

For each, provide modification effects for: texture, colour, silhouette, code directives.

##### 4c. House placement entries (12 houses x key planets)

Focus on Venus, Moon, Sun, Mars placements in each of the 12 houses. Each entry describes how house context modifies the style application.

##### 4d. Element/modality balance entries

4 element dominance patterns (fire/earth/air/water dominant) and 3 modality dominance patterns (cardinal/fixed/mutable dominant). These provide the overall "feel" that ties the Blueprint together.

##### 4e. Colour library

A comprehensive named colour database with hex values and astrological associations. Target: 60-80 named colours covering the full range needed across all Blueprint palettes.

**Sources for colour-astrology mapping:**
- Traditional planetary colour correspondences (Sun = gold, Moon = silver, Mars = red, Venus = green/pink, etc.)
- Traditional sign colour correspondences (already partially in the existing `TraditionalColours.signColours`)
- The `ColourSeasonAnalyzer` logic (warm/cool determination from element balance) can inform palette groupings

##### 4f. AI-assisted expansion

Use a script to fill gaps in the dataset where manual entry would be too time-consuming (particularly outer planet sign combinations and less common aspect pairings). This is factual astrological mapping work, not creative prose, so AI inference is appropriate and low-risk here.

**Deliverables:**
- `astrological_style_dataset.json` -- the complete dataset
- A validation report confirming key astrological correspondences are correct
- Documentation of sources used for astrological mappings

---

## Dependency Graph & Execution Order

### Phase 1: Blueprint Core (this spec)

```
    WP1 (Housekeeping)          WP2 (Data Model)
         |                           |
         |   ┌───────────────────────┘
         |   |
         v   v
    WP4 (Astrological Dataset)
         |
         v
    WP3 (Interpretation Engine)
```

- **WP1 and WP2** can start immediately, in parallel.
- **WP4** needs WP2's section definitions to know what categories to populate. Can start as soon as WP2 delivers `BlueprintModels.swift`.
- **WP3** needs both WP2 (data model) and WP4 (dataset) to be complete before the engine can be built.
- **WP1** should be done first or in parallel with WP2, as it cleans the codebase for the other packages to work in.

### Phase 2: Auth & Backend (separate execution, after Phase 1)

WP5 (Auth & Supabase) is documented in this spec for architectural context but is **not part of the Phase 1 execution run**. It has hard dependencies on Phase 1 outputs:
- WP5 needs WP2's `CosmicBlueprint` struct for the sync schema.
- WP5's content gating needs WP3 to produce the Blueprint before the auth modal triggers.
- WP5's UI work requires scoped exceptions to the "UI DO NOT MODIFY" policy (see Appendix A).

Phase 2 should begin only after Phase 1 is verified: the app builds, runs, and produces correct Blueprint content with placeholder UI.

### Phase 1 Concurrent Execution Controls (Required for Multi-Dev Run)

> **Runbook (Kickoff for 5 parallel AI developers):** Assign one owner per WP (WP1-WP4 active now, WP5 deferred), require each owner to post a start note listing dependencies and owned files, and enforce Start Gates before coding (`_reference/blueprint_examples.md` for WP2, frozen WP2 contract for WP4, merged WP2+WP4 for WP3). During execution, each owner commits only within their file boundary, reports any cross-boundary touch as a blocker, and rebases at each dependency handoff. Merge in this order: WP2 -> WP4 -> WP3, with WP1 merged first or rebased before final integration if project references moved. Accept Phase 1 only when build is green, fixture/schema checks are green, and deterministic Blueprint spot checks are logged.

The following controls are mandatory when WP1-WP4 are assigned to separate AI developers in parallel. They are designed to prevent merge conflict churn and behavioural drift.

#### A) WP Dependency Matrix (authoritative)

| Work Package | Depends On | Blocks | Can Run In Parallel With | Start Gate |
|---|---|---|---|---|
| WP1 | None | None (but unblocks cleaner integration) | WP2 | Immediate |
| WP2 | `_reference/blueprint_examples.md` present in repo | WP4, WP3 | WP1 | Examples file committed and reviewed |
| WP4 | WP2 (`BlueprintModels.swift` and section/category contracts) | WP3 | WP1 | WP2 model contracts frozen |
| WP3 | WP2 + WP4 complete | Phase 1 completion | None (integration-heavy) | WP2+WP4 merged into integration branch |

Rules:
- If a WP's Start Gate is not satisfied, that WP is blocked and must not proceed on assumptions.
- "Can run in parallel" does not override file ownership boundaries below.

#### B) File Ownership and Edit Boundaries (Phase 1)

Each WP owns the following file zones for write access. Cross-zone edits require explicit sign-off in the handoff note.

| WP | Primary write ownership | Must not modify without sign-off |
|---|---|---|
| WP1 | `Core/Calculations/NatalChartCalculator.swift`, `NatalChartViewController.swift`, `CosmicFitTabBarController.swift`, `NatalChartManager+Interpretation.swift`, listed Daily Fit-only files (comments only), `_archive/*`, project file references for archival cleanup | WP2 model structs, WP3 engine logic, WP4 dataset semantics |
| WP2 | New/updated Blueprint model files (for example `BlueprintModels.swift`, `BlueprintToken`, `BlueprintArchetypeKey`), `_reference/blueprint_examples.md` verification | WP1 UI placeholder behavior, WP3 algorithm implementation, WP4 content population |
| WP4 | `astrological_style_dataset.json` and dataset validation/report artifacts | WP1 archive/migration mechanics, WP2 public model contract shape, WP3 engine execution logic |
| WP3 | Engine/runtime files that consume `CosmicBlueprint` + WP4 dataset, deterministic resolver/generation pipeline, logging for fallback events | WP2 contract-breaking model changes, WP4 source-of-truth dataset edits (except schema-alignment fixes approved by WP4 owner), unrelated UI behavior |

Rules:
- Treat the Phase 1 model contract from WP2 as frozen once WP4 begins.
- If a contract break is unavoidable, raise a blocking integration note and update all downstream WPs in the same cycle.

#### C) Definition of Done by WP (minimum acceptance)

| WP | Done when all are true |
|---|---|
| WP1 | Project builds; placeholder content appears in targeted UI flows; direct and manager-wrapped engine calls are disconnected; required Daily Fit-only headers are added; archive + extracted token table delivered |
| WP2 | `CosmicBlueprint` and all section structs compile; enum/raw-value keying rules are implemented exactly; sample decode/encode against `_reference/blueprint_examples.md` succeeds; no guessed fields |
| WP4 | Dataset passes cardinality/schema checks (including `opposites`); 132 planet-sign entries present; key naming matches canonical WP2 keys; validation report committed |
| WP3 | Deterministic algorithms implemented exactly per spec formulas/rules; nearest-match fallback + logging active; engine output populates all required Blueprint sections from dataset; build/tests pass |

#### D) Shared Test Fixture Pack (single source of truth)

Before WP3 finalization, commit and use a common fixture pack under `_reference/fixtures/`:
- `blueprint_input_user_1.json`
- `blueprint_input_user_2.json`
- `blueprint_expected_shape_checklist.md` (section presence/types, not prose exact-match)
- `dataset_schema_checklist.md` (required keys/cardinality/opposites)

Fixture rules:
- All WPs must validate against the same fixture files.
- No WP may create a private fixture variant with divergent field names.
- Fixture updates require a short changelog entry in `_reference/fixtures/CHANGELOG.md`.

#### E) Integration and Merge Order (Phase 1)

Use this sequence to reduce conflicts:
1. Merge WP2 first (contract source of truth).
2. Merge WP4 second (dataset built against WP2 contract).
3. Rebase WP3 onto merged WP2+WP4, then merge WP3.
4. Merge WP1 either first or in parallel, but rebase it before final merge if project-file references changed.

Operational guardrails:
- Each WP PR must include: owned files list, non-owned files touched (if any), and explicit dependency status.
- If two WPs edit the same non-generated file, pause and resolve ownership before additional commits.
- Final Phase 1 sign-off requires: clean build, fixture checks green, and deterministic-output spot checks recorded.

---

## Out of Scope (Deferred to Phase 2 or Later)

The following are explicitly NOT part of the Phase 1 execution run (WP1–WP4):

- **WP5 (Auth & Supabase)** — documented below for architectural context and advance planning, but execution is deferred to Phase 2 after the Blueprint engine is verified working. See "Phase 2" in the dependency graph above.
- **Daily Fit** — will be rebuilt after Blueprint is solid, using Blueprint as its foundation
- **UI changes** — the UI layer is left untouched during Phase 1; connecting it to the new Blueprint output is a separate task. WP5 (Phase 2) will require scoped UI exceptions — see Appendix A.
- **Transit calculations** — only needed for Daily Fit
- **Tarot card system** — only needed for Daily Fit
- **Weather integration** — only needed for Daily Fit
- **Progressed chart** — only needed for Daily Fit and possibly a future Blueprint evolution feature
- **App Store deployment** — not in scope

---

---

### WP5: User Accounts, Authentication & Supabase Backend *(Phase 2 — Deferred)*

> **Execution note:** This work package is included in this spec for architectural context and to allow advance backend preparation. However, its iOS-side integration (auth modal, content gating, sync layer) MUST NOT be executed until Phase 1 (WP1–WP4) is complete and verified. The `CosmicBlueprint` struct and working engine are hard prerequisites.

**Goal:** Add email OTP authentication (ported from the What's for Dinner app), Supabase backend for cross-device sync, and an auth gate that presents after the Blueprint is generated -- unlocking the Daily Fit and all further content.

**Owner:** One AI dev (capable model)

**Context for the developer:**

#### Current State of Data & Accounts

The Cosmic Fit app is currently 100% local. There is no backend whatsoever.

**Storage mechanism:** Everything uses `UserDefaults` (the simplest iOS key-value store). There is no database -- no CoreData, no SQLite, no Realm. There is no Supabase, no Firebase, no CloudKit, no backend server of any kind.

**What's currently stored locally:**

| Data | Storage Key | Stored In | Notes |
|---|---|---|---|
| User profile (name, DOB, location, lat/lng, timezone) | `CosmicFitUserProfile` | `UserDefaults` | Single user, JSON-encoded `UserProfile` struct |
| Saved natal charts | `Chart_<name>` + index in `NatalChartKeys` | `UserDefaults` | JSON-encoded `SavedChart` structs |
| Daily vibe content | `DailyVibe_<date>_<chartId>` | `UserDefaults` | JSON-encoded `DailyVibeContent`, date-keyed |
| Welcome screen seen flag | `CosmicFitHasSeenWelcome` | `UserDefaults` | Boolean |

**There is no user authentication.** No email, no password, no OTP, no session tokens. The app doesn't know who the user is beyond what's stored locally on that single device. If they delete the app or get a new phone, everything is gone.

**The only network call in the entire app** is the weather fetch to Open-Meteo (a free, no-auth API).

**There is nothing to snapshot or migrate.** No existing database. We're building the Supabase schema from scratch.

#### Reference Implementation: What's for Dinner OTP Pattern

The auth flow is ported from the What's for Dinner iOS app (`/Users/ash/dev/mobile_apps/whatsfordinner`). This is a **custom/proprietary OTP flow** that bypasses Supabase's built-in email OTP. It uses:

- **Two Supabase Edge Functions** (`send-otp`, `verify-otp`) running on Deno
- **Resend API** as the email delivery provider
- **Supabase Auth admin API** for user provisioning and session creation
- **Supabase's native session/token management** for the JWT lifecycle after login

Key files to port from What's for Dinner (adapt branding, keep logic identical):

| Source File | Purpose |
|---|---|
| `supabase/functions/send-otp/index.ts` | Generates 6-digit OTP, stores SHA-256 hash, sends email via Resend |
| `supabase/functions/verify-otp/index.ts` | Verifies hash, creates Supabase Auth user if new, generates magic-link token, exchanges for session |
| `supabase/functions/_shared/otp-helpers.ts` | `generateOTP()`, `hashOTP()`, TTL/attempt constants |
| `supabase/functions/_shared/otp-email.ts` | Branded HTML email template (rebrand for Cosmic Fit) |
| `supabase/functions/_shared/rate-limit.ts` | Persistent rate limiter backed by `rate_limit_hits` table |
| `supabase/functions/_shared/supabase-client.ts` | Service client and user client factories |
| `supabase/functions/_shared/cors.ts` | CORS headers |
| `supabase/functions/_shared/error-response.ts` | Standard error/JSON response helpers |

#### User-Facing Flow

1. User completes onboarding (enters name, DOB, location) -- works exactly as now, stored locally
2. Blueprint is generated and displayed (the full Cosmic Blueprint -- this is their free content)
3. **Auth modal appears** as a sheet over the Blueprint: "Sign up to unlock your Daily Fit and sync your profile across devices"
4. User can **dismiss** the modal. If they do, they keep their Blueprint but have no access to Daily Fit or any other content. The modal will reappear each time they try to access gated content.
5. If they proceed: **Screen 1 -- Email entry** (text field + "Send code" button, styled with `CosmicFitTheme`)
6. **Screen 2 -- OTP entry** ("Check your email" + 6-digit code input with `.oneTimeCode` content type for iOS autofill + "Verify" button + "Use a different email" link)
7. On successful verification: Supabase creates the user, the app upserts their profile to `profiles` table, stores session token in Keychain, upserts their Blueprint JSON to `user_blueprints`
8. Auth modal dismisses, Daily Fit and all further content is unlocked

**There is no separate signup vs login.** The same OTP flow creates the user if they don't exist and logs them in if they do.

#### Content Gating Rules

| Content | Requires Auth? | Notes |
|---|---|---|
| Onboarding (enter birth data) | No | Always accessible |
| Blueprint generation & display | No | Free content, always accessible |
| Daily Fit | **Yes** | Auth modal appears if user tries to access without being authenticated |
| Profile editing | **Yes** | Must be logged in to edit (changes sync to Supabase) |
| Any future content | **Yes** | Default: gated behind auth |

#### Tasks

##### 5a. Supabase Project Setup

Create the Supabase project with a single migration file (`supabase/migrations/001_initial_schema.sql`) containing the full schema. This file must be portable -- copy-paste into any new Supabase project's SQL editor to spin up a fresh instance.

**Complete schema:**

```sql
-- ════════════════════════════════════════════════════════════
-- Cosmic Fit: Full Database Schema
-- ════════════════════════════════════════════════════════════

-- 0. Required Extensions
-- ────────────────────────────────────────────────────────────
-- pgcrypto: provides gen_random_uuid() used for primary keys.
-- Supabase enables this by default, but include explicitly for portability.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- pg_cron: provides cron.schedule() used for scheduled cleanup jobs (§5 below).
-- On Supabase, pg_cron is available on Pro plan and above.
-- On self-hosted Postgres, install pg_cron extension separately.
-- If pg_cron is NOT available, the scheduled jobs in §5 will fail silently —
-- you must run the prune functions manually or via an external scheduler.
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ────────────────────────────────────────────────────────────
-- Infrastructure assumptions:
--   • Postgres 14+ (for gen_random_uuid() without pgcrypto on PG13+, but we include pgcrypto for safety)
--   • Supabase project with Auth enabled (auth.users table exists)
--   • Supabase Pro plan if using pg_cron (free tier does not include pg_cron)
--   • If deploying outside Supabase: ensure auth.users table/schema exists or adapt triggers
-- ────────────────────────────────────────────────────────────

-- 1. Tables
-- ────────────────────────────────────────────────────────────

-- 1a. profiles (extended user data, auto-created on signup)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    first_name text NOT NULL,
    birth_date timestamptz NOT NULL,
    birth_location text NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    timezone_identifier text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 1b. user_preferences (app settings that sync between devices)
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    has_seen_welcome boolean DEFAULT false,
    notification_enabled boolean DEFAULT false,
    updated_at timestamptz DEFAULT now()
);

-- 1c. user_blueprints (cached Blueprint for cross-device sync)
CREATE TABLE IF NOT EXISTS public.user_blueprints (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    blueprint_json jsonb NOT NULL,
    engine_version text NOT NULL,
    generated_at timestamptz DEFAULT now(),
    UNIQUE(user_id)
);

-- 1d. otp_codes (custom OTP flow)
CREATE TABLE IF NOT EXISTS public.otp_codes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    email text NOT NULL,
    code_hash text NOT NULL,
    attempts int DEFAULT 0,
    max_attempts int DEFAULT 3,
    expires_at timestamptz NOT NULL,
    used_at timestamptz,
    created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_otp_active ON otp_codes (email, expires_at DESC)
    WHERE used_at IS NULL;

-- 1e. rate_limit_hits (persistent rate-limit tracking)
CREATE TABLE IF NOT EXISTS public.rate_limit_hits (
    key text NOT NULL,
    "window" timestamptz NOT NULL,
    count integer NOT NULL DEFAULT 1,
    PRIMARY KEY (key, "window")
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_hits_window
    ON rate_limit_hits("window");


-- 2. Functions
-- ────────────────────────────────────────────────────────────

-- 2a. Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, first_name, birth_date, birth_location, latitude, longitude, timezone_identifier)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'first_name', ''),
        COALESCE((NEW.raw_user_meta_data ->> 'birth_date')::timestamptz, now()),
        COALESCE(NEW.raw_user_meta_data ->> 'birth_location', ''),
        COALESCE((NEW.raw_user_meta_data ->> 'latitude')::double precision, 0.0),
        COALESCE((NEW.raw_user_meta_data ->> 'longitude')::double precision, 0.0),
        COALESCE(NEW.raw_user_meta_data ->> 'timezone_identifier', 'UTC')
    );
    INSERT INTO public.user_preferences (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2b. updated_at trigger helper
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2c. Atomic rate-limit check
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_key text,
    p_window timestamptz,
    p_max int
) RETURNS boolean AS $$
    INSERT INTO rate_limit_hits (key, "window", count)
    VALUES (p_key, p_window, 1)
    ON CONFLICT (key, "window")
        DO UPDATE SET count = rate_limit_hits.count + 1
    RETURNING count <= p_max;
$$ LANGUAGE sql;

-- 2d. Prune old rate-limit hits
CREATE OR REPLACE FUNCTION prune_rate_limit_hits() RETURNS void AS $$
    DELETE FROM rate_limit_hits
    WHERE "window" < now() - INTERVAL '10 minutes';
$$ LANGUAGE sql;


-- 3. Triggers
-- ────────────────────────────────────────────────────────────

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- 4. Row Level Security
-- ────────────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = id);

ALTER TABLE public.user_blueprints ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own blueprint" ON public.user_blueprints
    FOR ALL USING (auth.uid() = user_id);

-- otp_codes: service role only, no public policies
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

-- rate_limit_hits: service role only, no public policies
ALTER TABLE public.rate_limit_hits ENABLE ROW LEVEL SECURITY;


-- 5. Scheduled Jobs (pg_cron)
-- ────────────────────────────────────────────────────────────

-- Prune rate_limit_hits older than 10 min -- every 2 minutes
SELECT cron.schedule(
    'prune-rate-limit-hits',
    '*/2 * * * *',
    $$SELECT prune_rate_limit_hits()$$
);

-- Prune expired OTP codes older than 1 hour -- every 10 minutes
SELECT cron.schedule(
    'prune-expired-otp-codes',
    '*/10 * * * *',
    $$DELETE FROM otp_codes WHERE expires_at < now() - interval '1 hour'$$
);
```

##### 5b. Port Edge Functions from What's for Dinner

Port these edge functions, changing only branding/email content:

1. **`send-otp/index.ts`** -- Change email subject to `"Your Cosmic Fit login code"`, update `RESEND_FROM` default
2. **`verify-otp/index.ts`** -- No logic changes needed, port verbatim
3. **`_shared/otp-helpers.ts`** -- Port verbatim
4. **`_shared/otp-email.ts`** -- Rebrand entirely for Cosmic Fit:
   - Background colour: use `CosmicFitTheme.Colours.cosmicGrey` equivalent (dark theme)
   - Logo: Cosmic Fit logo or star glyph
   - Code display: styled with cosmic theme colours
   - Deep link: `cosmicfit://login?code={code}&email={email}`
   - Footer text: `"Cosmic Fit -- Your style, written in the stars."`
5. **`_shared/rate-limit.ts`** -- Port verbatim
6. **`_shared/supabase-client.ts`** -- Port verbatim
7. **`_shared/cors.ts`** -- Port verbatim
8. **`_shared/error-response.ts`** -- Port verbatim

**Supabase config.toml note:** Edge function JWT verification must be disabled (same as What's for Dinner) because the custom OTP flow produces JWTs that the Supabase relay rejects. Security is maintained via `getUser()` checks in authenticated functions.

**Required Supabase secrets:**
- `RESEND_API_KEY`
- `RESEND_FROM_EMAIL` (e.g., `login@cosmicfit.app`)
- `OTP_EMAIL_PROVIDER` (set to `"dev"` for testing, `"resend"` for production)

##### 5c. iOS Auth Service

Create `CosmicFitAuthService.swift` (UIKit, not SwiftUI -- Cosmic Fit uses UIKit). Modelled on What's for Dinner's `AuthService.swift`:

```swift
class CosmicFitAuthService {
    static let shared = CosmicFitAuthService()

    // Published state for UI observation
    private(set) var isAuthenticated: Bool = false
    private(set) var currentUserId: String?

    // Send OTP: calls send-otp edge function
    func sendOTP(email: String) async throws

    // Verify OTP: calls verify-otp edge function, sets Supabase session
    func verifyOTP(email: String, code: String) async throws

    // Check existing session on launch
    func checkSession() async

    // Listen for auth state changes (token refresh, sign-out)
    func listenForAuthChanges()

    // Sign out
    func signOut() async throws

    // Sync profile to Supabase after auth
    func syncProfileToSupabase(profile: UserProfile) async throws

    // Sync Blueprint to Supabase after generation
    func syncBlueprintToSupabase(blueprint: CosmicBlueprint) async throws
}
```

Key implementation details:
- Session tokens stored in **iOS Keychain** via Supabase Swift SDK (not UserDefaults)
- Fresh-install detection: check a UserDefaults flag at launch; if missing, wipe Keychain (iOS Keychain persists across reinstalls)
- Multi-user safety: if a different userId is detected on session restore, purge all local data
- Auth state changes propagated via `NotificationCenter` (UIKit pattern) for the tab bar and other VCs to observe

##### 5d. iOS Auth UI (UIKit Modal)

Create two view controllers styled with `CosmicFitTheme`:

1. **`AuthModalViewController`** -- Container that presents as a modal sheet after Blueprint is displayed. Has a dismiss button (X) in the top corner. Contains:
   - Hero text: "Unlock your Daily Fit"
   - Subtitle: "Sign up with your email to get daily personalised style guidance and sync your profile across devices"
   - Email text field
   - "Send code" button
   - "Not now" dismissal link at the bottom

2. **`OTPVerifyViewController`** -- Pushed or swapped in after OTP is sent:
   - "Check your email" heading
   - Subtitle showing the email address
   - 6-digit code input field (`.oneTimeCode` textContentType for iOS autofill)
   - "Verify" button
   - "Use a different email" link
   - Error display for incorrect code / too many attempts

Both views follow existing `CosmicFitTheme` patterns: `cosmicGrey` background, `cosmicBlue` accents, DM Sans / DM Serif typography, the same spacing and border radius conventions used throughout the app.

##### 5e. Content Gating Logic

Modify `CosmicFitTabBarController` to check auth state before allowing navigation to Daily Fit tab:

- If authenticated: navigate normally
- If not authenticated: present `AuthModalViewController` as a modal sheet
- If user dismisses: stay on Blueprint tab, Daily Fit tab shows a locked state

The Blueprint tab always works, authenticated or not.

##### 5f. Offline-First Sync Layer

The local storage remains the primary data source. Supabase is a secondary sync target.

- **On launch**: Load everything from local storage. App is immediately usable.
- **If authenticated + online**: Background-sync profile and Blueprint with Supabase. Pull any server-side updates (e.g., profile edited on another device). Push any local changes.
- **If authenticated + offline**: App works normally from local data. No error states. Changes queued for sync when connectivity returns.
- **If not authenticated**: App works with local data only. No Supabase calls whatsoever except weather (Open-Meteo).

Storage migration:
- Keep `UserDefaults` for simple flags (`hasSeenWelcome`, etc.)
- Move `UserProfile` to a local JSON file in the app's documents directory (easier to sync)
- Store the generated `CosmicBlueprint` as a local JSON file
- The Supabase sync layer reads/writes these same JSON files

##### 5g. Supabase Swift SDK Integration

Add the Supabase Swift SDK as an SPM dependency:
- Package: `https://github.com/supabase-community/supabase-swift`
- Create `SupabaseConfig.swift` that reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from xcconfig files (Dev.xcconfig / Prod.xcconfig), following the What's for Dinner pattern

**Deliverables:**
- `supabase/migrations/001_initial_schema.sql` -- complete, portable schema
- `supabase/functions/send-otp/` and `supabase/functions/verify-otp/` with all shared helpers
- `CosmicFitAuthService.swift` -- auth service with OTP, session management, sync
- `AuthModalViewController.swift` and `OTPVerifyViewController.swift` -- UIKit auth UI
- `SupabaseConfig.swift` -- client configuration
- Content gating integrated into `CosmicFitTabBarController`
- Dev.xcconfig / Prod.xcconfig with Supabase credential placeholders
- Documentation: how to spin up a new Supabase instance (create project, paste migration SQL, set secrets, deploy edge functions)

---

## Appendix A: Files to Keep (Reference)

### Foundation Layer (DO NOT MODIFY)
- `Core/Calculations/NatalChartCalculator.swift`
- `Core/Calculations/AstronomicalCalculator.swift`
- `Core/Calculations/JulianDateCalculator.swift`
- `Core/Calculations/AsteroidCalculator.swift`
- `Core/Utilities/VSOP87Parser.swift`
- `Core/Utilities/SwissEphemerisBootstrap.swift`
- `Core/Utilities/CoordinateTransformations.swift`
- `Core/Utilities/Ephemeris+Helpers.swift`

### Reference (Read-Only During Rebuild)
- `InterpretationEngine/PlanetPowerEvaluator.swift` -- dignity logic to port into ChartAnalyser
- `InterpretationEngine/StyleToken.swift` -- conceptual reference for BlueprintToken design

### UI Layer (DO NOT MODIFY — with scoped exceptions)
- All files in `UI/` directory
- `Core/NatalChartManager.swift` (except the interpretation extension)
- `Core/Utilities/LocationManager.swift`
- `Core/Utilities/WeatherService.swift`
- `Core/Utilities/UserProfileStorage.swift`
- `Core/Utilities/DailyVibeStorage.swift`
- `Core/Config/DebugConfiguration.swift`
- `Core/Utilities/DebugLogger.swift`
- `App/AppDelegate.swift`

**Scoped exceptions (Phase 1 only — WP1b):**

The following UI files require **minimal, surgical changes** during WP1 to disconnect the live interpretation engine. These changes replace engine call expressions with inline placeholder returns. No layout, navigation, styling, or structural UI code should be modified:

| File | Permitted Change | Scope |
|------|-----------------|-------|
| `UI/ViewControllers/NatalChartViewController.swift` | Replace `CosmicFitInterpretationEngine.generate*()` calls with placeholder returns | Expression-level only |
| `UI/ViewControllers/CosmicFitTabBarController.swift` | Replace `CosmicFitInterpretationEngine.generate*()` calls with placeholder returns | Expression-level only |

**Scoped exceptions (Phase 2 only — WP5):**

| File | Permitted Change | Scope |
|------|-----------------|-------|
| `UI/ViewControllers/CosmicFitTabBarController.swift` | Add auth-state check before Daily Fit tab navigation; present `AuthModalViewController` if unauthenticated | Navigation gating logic only |
| `App/AppDelegate.swift` | Add Supabase SDK initialisation and auth session restore on launch | Startup hook only |
| **New files** (`AuthModalViewController.swift`, `OTPVerifyViewController.swift`) | These are new UI additions, not modifications to existing files | N/A |

Any change beyond these scoped exceptions requires explicit sign-off. An AI implementer encountering an unlisted UI change should flag it as a spec gap rather than proceeding.

## Appendix B: Files to Archive

- `InterpretationEngine/ParagraphAssembler.swift`
- `InterpretationEngine/InterpretationTextLibrary.swift`
- `InterpretationEngine/ThemeSelector.swift`
- `InterpretationEngine/CompositeTheme.swift`
- `InterpretationEngine/Tier2TokenLibrary.swift`
- `InterpretationEngine/TokenEnergyOverrides.swift`
- `InterpretationEngine/TokenPrefixMatrix.swift`

## Appendix C: Files Marked as Daily Fit Only (Do Not Touch)

- `InterpretationEngine/DailyVibeGenerator.swift`
- `InterpretationEngine/TarotCardSelector.swift`
- `InterpretationEngine/TarotCard.swift`
- `InterpretationEngine/TarotCardValidator.swift`
- `InterpretationEngine/TarotRecencyTracker.swift`
- `InterpretationEngine/TarotSelectionMonitor.swift`
- `InterpretationEngine/VibeBreakdown .swift` **(space in filename — use quotes in all scripts/tooling)**
- `InterpretationEngine/DailyColourPaletteGenerator.swift`
- `InterpretationEngine/DailySeedGenerator.swift`
- `InterpretationEngine/AxisBalancer.swift`
- `InterpretationEngine/AxisTokenGenerator.swift`
- `InterpretationEngine/AxisVolatilityEngine.swift`
- `InterpretationEngine/AstroFeatures.swift`
- `InterpretationEngine/AstroFeaturesBuilder.swift`
- `InterpretationEngine/DerivedAxesConfiguration.swift`
- `InterpretationEngine/DerivedAxesEvaluator.swift`
- `InterpretationEngine/StructuralAxes.swift`
- `InterpretationEngine/MoonPhaseInterpreter.swift`
- `InterpretationEngine/WeatherFabricFilter.swift`
- `InterpretationEngine/ColourScoring.swift`
- `InterpretationEngine/TokenMerger.swift`
- `InterpretationEngine/TransitCapper.swift`
- `InterpretationEngine/TransitWeightCalculator.swift`
- `InterpretationEngine/EngineConfig.swift` (mostly tarot/axis config)
- `InterpretationEngine/WeightingModel.swift` (to be replaced by new normalised system)
