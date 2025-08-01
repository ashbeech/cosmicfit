# Cosmic Fit

**An astrological fashion guidance iOS application that translates natal charts into personalized style recommendations.**

Cosmic Fit combines astronomical precision with fashion intelligence, generating two core experiences: a foundational **Cosmic Blueprint** based on your natal chart, and a dynamic **Daily Fit** that adapts to current transits, weather, and lunar phases.

## 🌟 Features

### Cosmic Blueprint
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
- `generateBlueprintInterpretation(from:currentAge:)`
- `generateDailyVibeInterpretation(from:progressedChart:transits:weather:)`
- `generateFullInterpretation(...)`

#### `SemanticTokenGenerator`
Core logic hub converting chart data into weighted `StyleToken`s:
- **Blueprint tokens**: 100% natal chart analysis using Whole Sign system
- **Daily tokens**: Transit analysis with sophisticated weighting
- **Color frequency tokens**: 70% natal, 30% progressed for color guidance
- **Emotional vibe tokens**: Progressed Moon integration for mood styling

#### `StyleToken`
Fundamental unit representing weighted style attributes:
```swift
struct StyleToken {
    let name: String           // e.g., "earthy", "vibrant", "structured"
    let type: String           // e.g., "texture", "color", "mood"
    let weight: Double         // Influence strength (0.0-5.0+)
    let planetarySource: String?
    let signSource: String?
    let aspectSource: String?
    let originType: OriginType // .natal, .progressed, .transit, .weather
}
```

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

#### `ParagraphAssembler`
Transforms semantic tokens into human-readable guidance:

**Blueprint Sections:**
- Style Essence
- Celestial Style ID (Core/Expression/Magnetism)
- Emotional Dressing
- Planetary Frequency
- Style Tensions
- Energetic Fabric Guide

**Daily Fit Sections:**
- Dynamic title generation
- Weather-integrated guidance
- Textile recommendations
- Color and pattern suggestions
- Accessory guidance

#### `ThemeSelector`
Matches token patterns to predefined style themes:
- **Composite themes** with required and optional tokens
- **Scoring algorithms** for theme matching
- **Style profiles** like "Dream Layering", "Grounded Glamour", "Comfort at the Core"

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
Cosmic Blueprint display:
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

### Token-Driven Generation
- **No hardcoded content** - All interpretations built from semantic tokens
- **Modular composition** - Tokens → Themes → Paragraphs
- **Weighted influence** - Sophisticated algorithms determine token strength
- **Origin tracking** - Full traceability of style recommendations

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
- **Token validation** and weight analysis
- **Paragraph assembly** tracing
- **Transit calculation** verification
- **Performance monitoring** for optimization

### Logging Infrastructure
```swift
class DebugLogger {
    static func tokenSet(_ label: String, _ tokens: [StyleToken])
    static func paragraphAssembly(sectionName: String, ...)
    static func transitCalculation(...)
}
```

## 🚀 Extension Architecture

### Adding New Features

**New Token Types:**
Extend `SemanticTokenGenerator` with additional logic patterns

**New Interpretation Sections:**
Add generator methods to `ParagraphAssembler`

**New Transit Rules:**
Modify `TransitWeightCalculator` weighting algorithms

**New Planetary Bonuses:**
Update `PlanetPowerEvaluator` scoring system

**New Style Themes:**
Extend `CompositeTheme` definitions in `ThemeSelector`

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

## 🎯 Design Philosophy

**"Read the current, not the cables"** - All astrological complexity is elegantly translated into intuitive, emotionally resonant fashion guidance without exposing technical jargon to users.

The engine serves as a **dynamic foundation** for extending stylistic intelligence into other domains like interior design, branding, or wellness aesthetics while maintaining the core principle of authentic, personalized guidance.

---

*Cosmic Fit represents the intersection of ancient wisdom and modern technology, delivering personalized style guidance that honors both astronomical precision and individual expression.*
