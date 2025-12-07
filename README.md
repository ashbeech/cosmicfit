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

## 📝 Version History

**December 2025 - Template-Based Architecture**

- Transitioned from dynamic paragraph generation to template selection
- Implemented Vibe Breakdown system (6 energies, 21 points)
- Integrated Tarot card matching for Daily Fit
- Established 3-color daily palette selection
- Renamed "Blueprint" to "Style Guide" throughout codebase
- Marked legacy systems (ParagraphAssembler, ThemeSelector, InterpretationTextLibrary)
- Created Tier 2 token system (inactive but available for future use)

---

_Cosmic Fit represents the intersection of ancient wisdom and modern technology, delivering personalized style guidance that honors both astronomical precision and individual expression._
