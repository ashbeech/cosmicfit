# Cosmic Fit

**An astrological fashion guidance iOS application that translates natal charts into personalized style recommendations.**

Cosmic Fit combines astronomical precision with fashion intelligence, generating two core experiences: a foundational **Cosmic Style Guide** based on your natal chart, and a dynamic **Daily Fit** that adapts to current transits, weather, and lunar phases.

## 🌟 Features

### Cosmic Style Guide

- **Personality-rooted style profiles** derived from natal chart analysis
- **Whole Sign house system** for authentic astrological interpretation
- **Age-weighted influences** that evolve as you mature
- **Comprehensive style guidance** including essence, expression, and fabric recommendations

### Daily Fit

- **Real-time style guidance** based on current astrological transits
- **Weather-integrated recommendations** for practical styling
- **Lunar phase considerations** for energetic alignment
- **Progressive chart integration** for emotional styling nuances

### Technical Highlights

- **Swiss Ephemeris integration** for astronomical precision
- **VSOP87 planetary calculations** for accurate positioning
- **Semantic token architecture** for modular interpretation building
- **Advanced weighting algorithms** for nuanced astrological influence

## 🏗️ Architecture

### Core Engine Components

#### `CosmicFitInterpretationEngine`

Central orchestrator exposing public methods:

- `generateStyleGuideInterpretation(from:currentAge:)` - Returns `InterpretationResult` with placeholder for template system
- `generateDailyVibeInterpretation(from:progressedChart:transits:weather:profileHash:date:)` - Fully functional Daily Fit generation
- `generateCustomStyleGuidance(for:query:currentAge:)` - Situation-specific style recommendations

#### `SemanticTokenGenerator`

Core logic hub converting chart data into weighted `StyleToken`s:

- **Style Guide tokens**: 100% natal chart analysis using Whole Sign system
- **Daily tokens**: Transit analysis with sophisticated weighting
- **Color frequency tokens**: 70% natal, 30% progressed for color guidance
- **Emotional vibe tokens**: Progressed Moon integration for mood styling

#### `StyleToken`

Fundamental unit representing weighted style attributes (Tier 1: Energetic Foundation):

```swift
struct StyleToken {
    let name: String           // e.g., "earthy", "vibrant", "structured"
    let type: String           // e.g., "texture", "color", "mood"
    let weight: Double         // Influence strength (0.0-5.0+)
    let planetarySource: String?
    let signSource: String?
    let aspectSource: String?
    let originType: OriginType // .natal, .progressed, .transit, .weather
    let tier: TokenTier        // .tier1_energetic (only tier currently used)
}
```

**Token Usage:**

- **Vibe Breakdown Generation**: Tier 1 tokens → 6 energies (classic, playful, romantic, utility, drama, edge)
- **Color Palette Selection**: Tier 1 color tokens scored against today's vibes
- **Template Selection**: Tier 1 patterns matched to appropriate pre-written content

**Note:** A Tier 2 "Applied Style" token system exists (see `Tier2TokenLibrary.swift`) but is not currently active. Current architecture uses template selection instead of dynamic generation.

#### `TransitWeightCalculator`

Sophisticated transit influence scoring based on:

- **Aspect strength**: Conjunction > Square > Trine > Sextile
- **Orb tightness**: Closer aspects carry more weight
- **Planetary power**: Pluto > Saturn > Jupiter > Mars > Venus > Sun > Mercury > Moon
- **Natal planet strength**: Dignity, angularity, rulership bonuses
- **Fashion relevance**: Venus, Moon, Ascendant emphasis

#### `PlanetPowerEvaluator`

Natal planet strength assessment:

- Base planetary power ratings
- Dignity bonuses (domicile, exaltation)
- Angular house presence
- Chart ruler and sect light roles

### Interpretation Assembly

#### **Template-Based Architecture (Dec 2025)**

Both Style Guide and Daily Fit now use **pre-written template selection** rather than dynamic generation:

**STYLE GUIDE:**
Pre-written paragraph templates selected via Tier 1 token pattern matching:

1. **Style Core** - Foundational style identity and wardrobe philosophy

   - Formality baseline (elevated casual, polished minimal, etc.)
   - Aesthetic approach (monochromatic, eclectic, maximalist, etc.)
   - Styling methodology (uniform dressing, intuitive, planned, etc.)
   - Body relationship and comfort preferences

2. **Fabric Guide** - Material and texture recommendations

   - Fabric behavior preferences (holds shape, cascades, ripples, etc.)
   - Tactile qualities (smooth hand, cooling sensation, grit, etc.)
   - Fabric weight guidance (substantial, airy, dense, etc.)
   - Surface finish preferences (matte, pearlescent, subtle sheen, etc.)
   - Specific fabric types (silk, linen, cotton, cashmere, etc.)

3. **Colour Guide** - Personal color palette with visual palette component

   - Base colors (foundation palette for everyday)
   - Accent colors (flexibility and variety)
   - Statement colors (impact moments)
   - Color application strategy (as statement, accent, or foundation)

4. **Do's & Don'ts** - Specific actionable recommendations
   - Silhouette preferences (structured, draped, oversized, fitted, etc.)
   - Proportion guidance (dramatic, understated, balanced, etc.)
   - Garment specifics (wide-leg pants, fitted pieces, midi lengths, etc.)
   - Neckline recommendations (v-neck, cowl, high neck, etc.)
   - Pattern preferences (geometric, organic, scale, density)
   - Anti-recommendations (opposites to avoid)

**DAILY FIT:**

- Static paragraphs attached to each Tarot card (78 cards × 3 versions = 234 total)
- Version selection based on day's energy characteristics
- Tarot card selected from Vibe Breakdown
- Additional elements: Vibe Breakdown bars, Colour Palette (3 colors), Derived Axes

**Token Flow:**

```
STYLE GUIDE (Static, per-user):
  Natal Chart → Tier 1 Tokens → Pattern Analysis → Template Selection
                                                  ↓
                                            Style Guide Sections:
                                            • Style Core
                                            • Fabric Guide
                                            • Colour Guide
                                            • Do's & Don'ts

DAILY FIT (Dynamic, changes daily):
  Natal + Transits + Weather → Tier 1 Tokens
                                     ↓
                              Vibe Breakdown (6 energies, 21 points)
                                     ↓
                              Tarot Card Selection
                                     ↓
                              Static Paragraph (1 of 3 versions)
                                     ↓
                              Additional Elements:
                              • Colour Palette (3 colors from Style Guide)
                              • Vibe Breakdown Bars (visual)
                              • Derived Axes (Action/Tempo/Strategy/Visibility)
```

#### `ParagraphAssembler` (LEGACY - Being Replaced)

Original dynamic paragraph generation system:

- Transforms semantic tokens into generated sentences
- Being replaced with template selection approach
- Kept for reference during transition

#### `ThemeSelector` (LEGACY - Being Replaced)

Original theme matching system:

- Pattern matching for style archetypes
- Being replaced with simpler template selection
- Composite themes replaced with direct template matching

#### `VibeBreakdownGenerator`

Converts Tier 1 tokens into 6 core style energies for Daily Fit:

**The 6 Style Energies:**

1. **Classic** - Timeless, refined, traditional
2. **Playful** - Fun, experimental, youthful
3. **Romantic** - Soft, flowing, feminine
4. **Utility** - Practical, functional, purposeful
5. **Drama** - Bold, theatrical, attention-grabbing
6. **Edge** - Modern, unconventional, rebellious

**21-Point Distribution:**

- Each energy scored 0-10 points
- Total always equals 21 points
- Distribution reflects today's dominant energies

**Process:**

```swift
Tier 1 Tokens → Pattern Analysis → Energy Scoring → 21-Point Distribution
              ↓
          Dominant Energy (highest points)
              ↓
          Tarot Card Selection (best vibe match)
```

#### `DailyColourPaletteGenerator`

Selects 3 colors from Style Guide for today's Daily Fit:

**Selection Criteria:**

1. **Vibe Alignment** - Colors matching today's dominant energy (primary factor)
2. **Planetary Transit Amplification** - Boost colors if their planetary source has strong transits
3. **Derived Axes Influence** - Consider Action/Tempo/Strategy/Visibility scores
4. **Diversity Check** - Ensure palette has variety (avoid 3 similar colors)

**Process:**

```swift
Style Guide Colors (Tier 1) + Today's Vibe Breakdown + Transits
                      ↓
              Score Each Color for Today
                      ↓
         Select Top 3 with Diversity Check
                      ↓
           3-Color Daily Palette
```

#### `TarotCardLibrary`

Manages 78 Tarot cards and their associated paragraphs:

**Structure:**

- 78 Tarot cards, each with unique energy signature
- 3 paragraph versions per card (234 total paragraphs)
- Version selection based on day's characteristics

**Matching Process:**

```swift
Vibe Breakdown (6 energies) → Calculate similarity to each Tarot's energy signature
                             ↓
                      Select closest match
                             ↓
               Choose 1 of 3 paragraph versions
                             ↓
                      Today's Daily Fit text
```

### Astronomical Calculations

#### `VSOP87Parser`

Handles precise planetary position calculations:

- **Bureau des Longitudes VSOP87D format** parsing
- **Fallback orbital elements** for reduced accuracy scenarios
- **Multi-century precision** for historical and future dates

#### `SwissEphemerisBootstrap`

Manages Swiss Ephemeris initialization:

- **High-precision ephemeris data** integration
- **seas_18.se1 file** management
- **Memory-efficient** resource handling

#### `JulianDateCalculator`

Core astronomical date conversions:

- **Gregorian to Julian** date transformation
- **UTC coordination** for global accuracy
- **Sidereal time calculations** for house systems

### User Interface

#### `MainViewController`

Entry point for birth data collection:

- Location geocoding
- Date/time input validation
- Chart generation initiation

#### `NatalChartViewController`

Data orchestration hub:

- Natal and progressed chart calculation
- Weather API integration
- Transit compilation
- Interpretation routing

#### `InterpretationViewController`

Cosmic Style Guide display:

- **Markdown-style formatting** for structured text
- Header with birth location and date
- Export and sharing capabilities
- **Responsive typography** for readability

#### `DailyVibeInterpretationViewController`

Daily Fit experience:

- **Interactive sliders** for brightness and vibrancy
- Weather integration with emoji indicators
- Segmented guidance (textiles, colors, patterns, shapes)
- **Custom gradient visualizations**

## 🔧 Key Architectural Principles

### Astrological Integrity

- **Natal chart defines essence** - Always the foundational layer
- **Progressed chart modulates tone** - Never overrides natal patterns
- **Ascendant influence fades with maturity** - Age-weighted calculations
- **Transit importance varies** - Dynamic weighting based on multiple factors

### Token-Driven Analysis

- **Semantic token foundation** - Chart data converted to weighted style attributes (Tier 1)
- **Pattern recognition** - Token combinations analyzed for style profiles
- **Template selection** - Pre-written content matched to token patterns
- **Weighted influence** - Sophisticated algorithms determine token strength
- **Origin tracking** - Full traceability from recommendations back to natal chart

### Technical Excellence

- **Astronomical precision** - Swiss Ephemeris and VSOP87 integration
- **Performance optimization** - Efficient calculations and caching
- **Memory management** - Resource-conscious design
- **Debug infrastructure** - Comprehensive logging and validation

## 🔄 Daily Refresh System

### Automatic Updates

- **Midnight detection** across time zones
- **App lifecycle integration** for seamless updates
- **Cached storage** for offline accessibility
- **Background refresh** when returning to foreground

### Weather Integration

```swift
struct TodayWeather {
    let condition: String
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
}
```

## 🧪 Development Tools

### Debug Configuration

Controlled via `DebugConfiguration.isDebugEnabled` flag:

- **Token validation** - Detailed weight analysis and categorization
- **Vibe breakdown** - Energy distribution tracking
- **Transit calculation** - Aspect scoring verification
- **Performance monitoring** - Timing and optimization metrics

### Logging Infrastructure

```swift
class DebugLogger {
    static func info(_ message: String)
    static func error(_ message: String)
    static func styleGuideGenerationStart(natal:currentAge:)
    static func dailyVibeGenerationStart(natal:progressed:transits:)
    static func logTokenAnalysisForStyleGuide(tokens:)
}
```

### System Validation

```swift
// Built-in validation suite
CosmicFitInterpretationEngine.runSystemValidation()  // Returns true if all tests pass
CosmicFitInterpretationEngine.verifySystemIntegration()  // Comprehensive system check
```

## 🚀 Extension Architecture

### Adding New Features

**New Tier 1 Token Types:**
Extend `SemanticTokenGenerator` with additional astrological interpretation logic patterns

**New Style Guide Templates:**
Create pre-written paragraph templates and add pattern matching rules to select them based on token combinations

**New Daily Fit Paragraphs:**
Write additional versions for existing Tarot cards or add new Tarot cards with associated paragraphs (78 cards × 3 versions)

**New Transit Weighting Rules:**
Modify `TransitWeightCalculator` algorithms to adjust how planetary transits influence daily recommendations

**New Planetary Bonuses:**
Update `PlanetPowerEvaluator` scoring system to refine natal planet strength calculations

**New Vibe Breakdown Mappings:**
Extend `VibeBreakdownGenerator` to refine how tokens map to the 6 core energies (classic, playful, romantic, utility, drama, edge)

### Dependencies

#### Internal

- `NatalChartCalculator` - Chart computation engine
- `JulianDateCalculator` - Astronomical date handling
- `AstronomicalCalculator` - Celestial mechanics
- `TodayWeather` - Weather data integration

#### External

- **Swiss Ephemeris** (CSwissEphemeris SPM)
- **CoreLocation** - Geocoding and location services
- **UIKit** - iOS user interface framework

## 📊 Performance Characteristics

### Calculation Efficiency

- **Cached chart data** prevents redundant calculations
- **Optimized token generation** with early filtering
- **Lazy loading** of astronomical data files
- **Memory pooling** for frequent operations

### User Experience

- **Sub-second interpretation generation** for most queries
- **Smooth UI transitions** with activity indicators
- **Offline capability** with cached daily content
- **Responsive design** across device sizes

## 📈 Implementation Status

### ✅ Fully Implemented & Working

- **Tier 1 Token Generation** - Complete natal, progressed, and transit analysis (~200-300 tokens per chart)
- **Vibe Breakdown System** - 6 energies with 21-point distribution
- **Tarot Card Selection** - Pattern matching from vibe to card
- **Daily Color Palette** - 3-color selection from Style Guide colors
- **Derived Axes** - Action/Tempo/Strategy/Visibility calculations
- **Weather Integration** - Real-time weather data with fabric filtering
- **Daily Fit UI** - Complete visual display with all elements
- **Style Guide UI** - Framework ready for content population
- **Transit Calculations** - Full Swiss Ephemeris integration
- **Chart Generation** - Natal and progressed charts with Whole Sign houses
- **Storage System** - Daily content caching and persistence

### 🚧 Pending Implementation

**Style Guide Content:**

- Pattern matching system for template selection
- Pre-written template library (Style Core, Fabric Guide, Colour Guide, Do's & Don'ts)
- Template assembly and display logic

**Daily Fit Content:**

- 234 pre-written paragraphs (78 Tarot cards × 3 versions)
- Paragraph version selection logic based on day characteristics
- Integration into Daily Fit display

**Both Systems:**

- Content delivery through template selection is the only missing piece
- All underlying data generation (tokens, vibes, colors, axes) is complete
- UI frameworks are ready to receive content

### 🔮 Architecture Benefits

**Current Approach:**

- **Consistent Quality** - Pre-written content ensures polished, on-brand copy
- **Performance** - Template selection is fast (no generation overhead)
- **Maintainability** - Copy can be refined without code changes
- **Scalability** - Easy to add new templates or variations
- **Traceability** - Full lineage from natal chart → tokens → pattern → template

## 🎯 Design Philosophy

**"Read the current, not the cables"** - All astrological complexity is elegantly translated into intuitive, emotionally resonant fashion guidance without exposing technical jargon to users.

The engine serves as a **dynamic foundation** for extending stylistic intelligence into other domains like interior design, branding, or wellness aesthetics while maintaining the core principle of authentic, personalized guidance.

---

## Cosmic Blueprint Rebuild (v2.3)

The Cosmic Blueprint is the app's core personalised style output. It is generated offline from pre-computed data so the app works without an internet connection. The rebuild replaces the old template-selection system with a deterministic engine backed by a rich astrological dataset and AI-generated narrative paragraphs.

### How it fits together

```
astrological_style_dataset.json          (WP4 — the meaning layer)
        │
        ├──► Swift runtime engine (WP3)
        │      ChartAnalyser
        │      BlueprintTokenGenerator
        │      DeterministicResolver       ──► deterministic Blueprint fields
        │      ArchetypeKeyGenerator       ──► cluster key for narrative lookup
        │      NarrativeTemplateRenderer   ──► fills {placeholders} in Group B sections
        │
        └──► backfill_narratives.py        (one-time Gemini API run)
               │
               ▼
        blueprint_narrative_cache.json     (AI-generated paragraph templates)
               │
               ▼
        NarrativeCacheLoader.swift         ──► narrative Blueprint fields
```

At runtime, the Swift engine reads the dataset to resolve structured fields (palette, textures, metals, stones, code directives, patterns) and looks up pre-generated narrative paragraphs from the cache. Factual sections (Group B) contain named placeholders like `{core_colour_1}` that are filled with the user's actual resolved values by `NarrativeTemplateRenderer` before final assembly. No API calls happen on-device.

### Plain-English Blueprint explainer

This section is written for non-developers who want to understand, in ordinary language, how a Blueprint is made.

#### The short version

The Blueprint is built from two ingredients:

1. A hand-authored astrology-to-style dataset.
2. A bank of AI-written paragraph templates for broad archetypes.

When a real user enters their birth date, birth time, and birth location, the app calculates their natal chart, maps that chart onto the dataset, and then combines:

- deterministic style logic from the dataset
- archetype paragraph templates from the AI cache (with placeholders for factual sections filled at runtime from the user's resolved data)
- chart-specific house and sect overlays added at runtime

So the final Blueprint is not "free-written" from scratch by AI on the phone. It is a controlled assembly of:

- pre-defined astrology meanings
- deterministic weighting rules
- pre-generated narrative templates with runtime placeholder substitution
- chart-specific overlays

#### Diagram: how the Blueprint data is created

```text
Human-authored astrology rules
    in generate_dataset.py
        |
        |  planet-sign meanings
        |  aspect meanings
        |  house placement meanings
        |  element balance meanings
        |  colour library
        v
astrological_style_dataset.json
        |
        |  used in two ways
        |------------------------------.
        |                              |
        v                              v
Swift runtime engine              backfill_narratives.py
        |                              |
        |                              |  asks AI to write general
        |                              |  archetype paragraphs
        |                              |  without assuming houses/sect
        |                              v
        |                       blueprint_narrative_cache.json
        |                              |
        '--------------.               |
                       |               |
                       v               v
                  BlueprintComposer combines both
                              |
                              v
                    Final CosmicBlueprint
```

#### What is inside the dataset

The dataset is generated programmatically from `generate_dataset.py`, not typed by hand as one giant JSON file. That Python file acts like the source-of-truth workbook for the Blueprint system and produces `astrological_style_dataset.json`.

In plain English, it contains:

- `planet_sign`: what a placement like Venus in Libra or Moon in Capricorn means for style, textures, colours, metals, stones, patterns, silhouette language, and "lean into / avoid / consider" guidance
- `aspects`: what important natal aspects add or subtract from the core style signal
- `house_placements`: what it means when Venus or Moon land in a given whole-sign house, including narrative modifiers and local biases for code/hardware outputs
- `element_balance`: what overall fire / earth / air / water emphasis does to tone and palette
- `colour_library`: named colours and their associations, so colour recommendations stay controlled and consistent

#### How the AI paragraph dataset is created

The AI paragraph cache is a second layer, separate from the main astrology dataset.

It is created like this:

1. The system groups people into broad narrative archetypes based on three stable chart features:
   - Venus sign
   - Moon sign
   - dominant element balance
2. `backfill_narratives.py` sends those archetypes to Gemini and asks for 16 Blueprint paragraphs per archetype.
3. The results are saved into `blueprint_narrative_cache.json`.
4. A human can review and approve those paragraphs in `review_tool.py`.

Important: these paragraphs are intentionally general. They are not supposed to include chart-specific house placements or day/night sect in the AI output itself. That detail is added later at runtime for the real user.

#### Diagram: how one user's chart maps to the data

```text
Birth date + birth time + birth location
                |
                v
        Natal chart calculation
                |
                v
           ChartAnalyser
                |
                |  works out:
                |  - planet signs
                |  - Ascendant sign
                |  - whole-sign houses
                |  - chart ruler
                |  - dignities
                |  - natal aspects
                |  - sect (day or night)
                |  - dominant houses
                v
      BlueprintTokenGenerator
                |
                |  base weighting:
                |  - planet importance
                |  - dignity
                |  - chart ruler boost
                |  - aspect strength
                |
                |  extra combo weighting:
                |  - whole-sign house modifier
                |  - sect modifier
                v
        DeterministicResolver
                |
                |  produces structured outputs
                |  such as:
                |  - colours
                |  - textures
                |  - metals / stones
                |  - code guidance
                v
      ArchetypeKeyGenerator + narrative cache lookup
                |
                v
      HouseSectOverlayGenerator
                |
                |  appends chart-specific paragraph detail
                v
         Final CosmicBlueprint
```

#### Where whole-sign houses come in

Whole-sign houses enter during chart analysis.

The rule is simple:

- the sign rising on the Ascendant becomes house 1
- the next sign becomes house 2
- and so on around the chart

This gives every planet a whole-sign house placement. Those house placements then affect the Blueprint in two main ways:

- they influence some deterministic weighting through house modifiers
- they provide chart-specific narrative overlays, especially through Venus house, Moon house, and dominant house emphasis

In other words, houses do not replace the core archetype. They personalise it.

#### Where sect comes in

Sect is the day/night condition of the chart.

In plain English:

- a day chart and a night chart do not emphasise planets in quite the same way
- some planets become slightly more at home or more effective in one sect than the other

In the Blueprint pipeline, sect affects:

- combo weighting in the token-generation stage
- the final overlay tone appended to certain narrative paragraphs

So sect helps tilt the final result toward a more day-chart or night-chart expression without rewriting the entire Blueprint from scratch.

#### The most important distinction: AI writing vs deterministic output

There are two different jobs happening in the Blueprint system:

- AI writing creates the base paragraph library
- deterministic logic personalises the final result for a real user

That means:

- the AI cache provides the general voice and archetype prose
- the deterministic runtime decides the specific output for this person's chart
- whole-sign houses and sect mostly act at runtime, not in the one-time backfill

#### What is expected to be deterministic

For the same:

- birth data
- dataset JSON
- narrative cache JSON
- engine version

the Blueprint should come out the same every time.

That is the expectation for:

- structured outputs such as palette, code guidance, hardware, and pattern recommendations
- narrative lookup selection
- house/sect overlay generation

Important guardrail: house and sect are allowed to influence some runtime outputs, but they are not allowed to leak everywhere. In particular, the pattern path is intentionally kept on the token-derived route so pattern recommendations remain stable and do not pick up house/sect drift.

No live AI call happens when the user generates their Blueprint in the app.

#### What the user is really getting

In plain English, the user is getting:

- a natal chart calculated from their real birth data
- a style interpretation built from a curated astrology-to-style dataset
- a deterministic weighted resolution of that chart into concrete style guidance
- a matching set of pre-written narrative paragraphs
- final chart-specific narrative details added from houses and sect

So the Blueprint is best understood as a guided translation system, not a chatbot answer.

### Placeholder template pipeline

The narrative cache contains two kinds of sections:

**Group A (general prose, no placeholders):**
`style_core`, `occasions_work`, `occasions_intimate`, `occasions_daily`, `accessory_1`, `accessory_2`, `accessory_3`

These sections contain fully baked prose with no user-specific references to colours, patterns, metals, stones, or textures. They pass through to the final Blueprint unmodified.

**Group B (templated with placeholders):**
`palette_narrative`, `pattern_narrative`, `pattern_tip`, `hardware_metals`, `hardware_stones`, `hardware_tip`, `textures_good`, `textures_bad`, `textures_sweet_spot`

These sections contain named placeholders that are filled at runtime with the user's actual resolved deterministic values by `NarrativeTemplateRenderer`.

**Placeholder vocabulary:**

| Category | Placeholders |
|----------|-------------|
| Palette | `{core_colour_1}` .. `{core_colour_4}`, `{accent_colour_1}` .. `{accent_colour_2}` |
| Pattern | `{recommended_pattern_1}` .. `{recommended_pattern_4}`, `{avoid_pattern_1}` .. `{avoid_pattern_2}` |
| Hardware | `{metal_1}` .. `{metal_3}`, `{stone_1}` .. `{stone_3}` |
| Textures | `{texture_good_1}` .. `{texture_good_4}`, `{texture_bad_1}` .. `{texture_bad_3}`, `{sweet_spot_keyword_1}` .. `{sweet_spot_keyword_2}` |

If a placeholder has no resolved value (e.g. the user only has 2 core colours but the template uses `{core_colour_3}`), the renderer substitutes a safe fallback. Unrecognised `{...}` tokens log a warning but do not crash.

**Important:** The narrative cache must be regenerated after any changes to the placeholder vocabulary or section group assignments. Run the backfill script to regenerate.

### Files

| File | Purpose |
|------|---------|
| `astrological_style_dataset.json` | Complete astrological-to-style mapping dataset (132 planet-sign entries, 30 aspects, 48 house placements, 7 element balances, 162-colour library) |
| `generate_dataset.py` | Generates the dataset programmatically from hardcoded astrological mappings. Run this whenever you edit the dataset source. |
| `validate_dataset.py` | Validates the dataset against the WP3 schema contract and cross-references colours. |
| `backfill_narratives.py` | One-time script that calls the Gemini API to generate narrative paragraph templates for every archetype cluster. Group B sections contain `{placeholder}` tokens filled at runtime. |
| `review_tool.py` | Local web UI for reviewing, approving, and flagging generated paragraphs. Displays templates with placeholders as-is so reviewers see the template structure. |
| `blueprint_narrative_cache.json` | Output of the backfill — all AI-generated paragraph templates keyed by archetype cluster. Bundled into the app at `Cosmic Fit/Resources/`. Must be regenerated after placeholder vocabulary changes. |
| `review_notes.json` | Auto-saved review state from the review tool. The backfill script reads this on re-run to skip approved paragraphs and regenerate flagged ones. |
| `docs/blueprint_examples.md` | Voice reference — two complete example Blueprints plus 234 tarot-style paragraphs that define the target writing style. |
| `BLUEPRINT_REBUILD_SPEC_v2.3.md` | Full architecture specification for the rebuild. |

### Setup

```bash
cd /Users/ash/dev/mobile_apps/cosmicfit

# Create and activate the virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

Copy `.env.example` to `.env` and add your Gemini API key:

```
GEMINI_API_KEY=your_key_here
```

### Generating the dataset

If you edit `generate_dataset.py` (the astrological mappings, colours, textures, etc.), regenerate and validate the JSON:

```bash
source .venv/bin/activate
python3 generate_dataset.py
python3 validate_dataset.py
```

`generate_dataset.py` writes `astrological_style_dataset.json`. `validate_dataset.py` checks it against the WP3 contract (correct keys, cardinalities, colour cross-references) and prints a PASS/FAIL report.

For post-rollout strict schema enforcement (Phase 4d), run:

```bash
source .venv/bin/activate && python3 validate_dataset.py astrological_style_dataset.json --strict-house-schema
```

This fails if any house placement is missing:

- `keywords`
- `code_consider_bias`
- `occasion_bias`
- `lean_into_bias`

### Running the narrative backfill

The backfill script generates AI paragraphs by calling the Gemini API. Each archetype cluster gets 16 paragraphs (one per Blueprint section). The script saves progress after every paragraph, so it is safe to interrupt and resume.

Important: the backfill output is intentionally archetype-level, not chart-specific. House and sect influences are applied later by the runtime Blueprint pipeline through resolver weighting and narrative overlays, so `blueprint_narrative_cache.json` should remain general-purpose.

**Cluster modes:**

| Mode | Clusters | Paragraphs | API calls |
|------|----------|------------|-----------|
| `representative` | 192 | 3,072 | 3,072 |
| `full` | 576 | 9,216 | 9,216 |

**Test a small batch first:**

```bash
source .venv/bin/activate && python3 backfill_narratives.py \
  --dataset astrological_style_dataset.json \
  --output blueprint_narrative_cache.json \
  --clusters representative \
  --limit 3
```

`--limit N` caps the run at N clusters. Use this to test output quality before committing to a full run.

**Resume after interruption:**

```bash
source .venv/bin/activate && python3 backfill_narratives.py \
  --dataset astrological_style_dataset.json \
  --output blueprint_narrative_cache.json \
  --clusters representative \
  --resume
```

`--resume` skips clusters that already have content, so you can stop and restart without losing progress.

### House/Sect regression snapshots

Golden regression snapshots and scorecard tooling live in `docs/house_sect_regression/`.

Build snapshot bundles from before/after Blueprint JSON:

```bash
source .venv/bin/activate && python3 generate_house_sect_regression.py \
  --fixture ash \
  --before docs/fixtures/blueprint_input_user_1.json \
  --after docs/house_sect_regression/input_after/ash.json
```

Auto-generate `input_after/*.json` from runtime fixtures:

```bash
source .venv/bin/activate && python3 export_input_after_fixtures.py
```

This exporter now fails fast if `blueprint_narrative_cache.json` is still `{}`. Run a limited or full backfill first so the runtime fixtures include real narrative content.

Generate the human review scorecard from snapshot bundles:

```bash
source .venv/bin/activate && python3 review_house_sect_regression.py \
  --snapshots-dir docs/house_sect_regression \
  --output docs/house_sect_regression/REPORT.md
```

**Dry run (no API calls):**

```bash
source .venv/bin/activate && python3 backfill_narratives.py \
  --dataset astrological_style_dataset.json \
  --output blueprint_narrative_cache.json \
  --clusters full \
  --dry-run
```

Prints the cluster list and paragraph count without making any API calls.

**All flags:**

| Flag | Description |
|------|-------------|
| `--dataset` | Path to `astrological_style_dataset.json` (required) |
| `--output` | Path to `blueprint_narrative_cache.json` (required) |
| `--clusters` | `representative` (192 clusters) or `full` (576 clusters). Default: `representative` |
| `--limit N` | Generate at most N clusters. 0 or omitted means all. |
| `--resume` | Skip clusters that already exist in the output file. |
| `--dry-run` | Print the plan without making API calls. |
| `--model` | Override the Gemini model name (default: `gemini-2.0-flash`, or set `GEMINI_MODEL` in `.env`). |
| `--api-key` | Override the API key (default: reads `GEMINI_API_KEY` from `.env` or environment). |

### Reviewing generated paragraphs

The review tool is a local web UI for inspecting and approving the AI output.

```bash
source .venv/bin/activate
python3 review_tool.py --cache blueprint_narrative_cache.json --port 8420
```

Then open `http://localhost:8420` in your browser.

**What it shows:**

- Left sidebar: every archetype cluster, with a progress badge (e.g. `12/16` approved).
- Main panel: all 16 narrative sections for the selected cluster. Each section shows the paragraph text, automated validation results (word count, banned-word check, hedging check, second-person check, British spelling flags), and review controls.
- Top bar: global stats and a Pause Pipeline button.

**Keyboard shortcuts:**

| Key | Action |
|-----|--------|
| `a` | Approve the focused paragraph |
| `r` | Mark as needs revision |
| `x` | Reject |
| `j` / `↓` | Focus next section |
| `k` / `↑` | Focus previous section |
| `]` | Next cluster |
| `[` | Previous cluster |

**Live updates:** The backfill writes `blueprint_narrative_cache.json` after every paragraph, and the review tool polls for changes every 2 seconds. You can run the backfill in one terminal and watch new paragraphs appear in the browser without manually refreshing the page.

**How review notes feed back into the backfill:**

Every approve/revise/reject action is auto-saved to `review_notes.json`. When you re-run the backfill with `--resume`:

- `approved` paragraphs are preserved (not regenerated).
- `needs_revision` paragraphs are regenerated with your reviewer note appended to the prompt as extra guidance.
- `rejected` paragraphs are regenerated from scratch.
- Paragraphs with no review entry are preserved as-is.

The **Pause Pipeline** button writes a `pause_signal.json` file. The backfill script checks for this before each API call and halts if paused. Click **Resume Pipeline** to remove the signal and allow the backfill to continue.

### Typical workflow

1. **Edit the dataset** — change astrological mappings in `generate_dataset.py`, then run `python3 generate_dataset.py && python3 validate_dataset.py`.
2. **Test the backfill** — run with `--limit 3` to generate a small batch. Open the review tool and inspect the output quality.
3. **Iterate on quality** — flag bad paragraphs in the review tool, re-run with `--resume` to regenerate them with your notes as guidance.
4. **Run the full backfill** — once satisfied, run with `--clusters representative` (or `full`) without `--limit`.
5. **Review all output** — work through the review tool until all paragraphs are approved.
6. **Bundle into the app** — copy the final `blueprint_narrative_cache.json` to `Cosmic Fit/Resources/blueprint_narrative_cache.json`.

### Archetype cluster keys

Each cluster key has the format:

```
venus_<sign>__moon_<sign>__<element>_dominant
```

For example: `venus_scorpio__moon_capricorn__fire_dominant`

- **Venus sign** drives primary aesthetic preference.
- **Moon sign** drives comfort and emotional style.
- **Dominant element** (fire, earth, air, water) shapes overall energy.

In representative mode, the 12 Moon signs are collapsed into 4 element representatives (Aries for fire, Taurus for earth, Gemini for air, Cancer for water), giving 12 Venus x 4 Moon x 4 elements = 192 clusters. Full mode uses all 12 Moon signs for 576 clusters.

### Blueprint sections (16 per cluster)

Each archetype cluster entry contains 16 narrative paragraphs, one per `BlueprintSection`:

| Section key | Display name | Content |
|-------------|-------------|---------|
| `style_core` | Style Core | Foundational style identity |
| `textures_good` | Textures — Good | Recommended fabrics and materials |
| `textures_bad` | Textures — Bad | Fabrics to avoid |
| `textures_sweet_spot` | Textures — Sweet Spot | The ideal tactile experience |
| `palette_narrative` | Palette | Core colour story |
| `occasions_work` | Occasions — Work | Professional dressing guidance |
| `occasions_intimate` | Occasions — Intimate | Close-range and evening style |
| `occasions_daily` | Occasions — Daily | Everyday wardrobe approach |
| `hardware_metals` | Hardware — Metals | Metal and finish preferences |
| `hardware_stones` | Hardware — Stones | Gemstone recommendations |
| `hardware_tip` | Hardware — Tip | Accessory hardware rule |
| `accessory_1` | Accessory 1 | Accessory guidance paragraph 1 |
| `accessory_2` | Accessory 2 | Accessory guidance paragraph 2 |
| `accessory_3` | Accessory 3 | Accessory guidance paragraph 3 |
| `pattern_narrative` | Pattern | Pattern and print guidance |
| `pattern_tip` | Pattern — Tip | Pattern application rule |

---

## Version History

**April 2026 — Placeholder Template Pipeline**

- Converted Group B narrative sections to placeholder-based templates filled at runtime
- Added deterministic texture resolution (recommendedTextures, avoidTextures, sweetSpotKeywords)
- Built NarrativeTemplateRenderer for runtime placeholder substitution
- Updated backfill prompts with Group A/B constraints and placeholder validation
- Narrative cache must be regenerated after this change

**April 2026 — Blueprint Rebuild v2.3**

- Replaced template-selection system with deterministic token engine (WP3)
- Built complete astrological-to-style dataset with 132 planet-sign entries (WP4)
- Added AI narrative backfill pipeline with Gemini API
- Added local review tool for paragraph quality control
- Frozen `CosmicBlueprint` Swift model contract (WP2)

**December 2025 — Template-Based Architecture**

- Transitioned from dynamic paragraph generation to template selection
- Implemented Vibe Breakdown system (6 energies, 21 points)
- Integrated Tarot card matching for Daily Fit
- Established 3-color daily palette selection
- Renamed "Blueprint" to "Style Guide" throughout codebase
- Marked legacy systems (ParagraphAssembler, ThemeSelector, InterpretationTextLibrary)
- Created Tier 2 token system (inactive but available for future use)

---

_Cosmic Fit represents the intersection of ancient wisdom and modern technology, delivering personalised style guidance that honours both astronomical precision and individual expression._
