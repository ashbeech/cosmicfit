//
//  DailyVibeGenerator.swift
//  Cosmic Fit
//
//  Created for Daily Vibe implementation - TRANSIT-PRIMARY WEIGHT DISTRIBUTION
//  Fixed proper weight distribution: Transit analysis creates PRIMARY influences, Natal provides BASE foundation
//

import Foundation

class DailyVibeGenerator {
    
    // MARK: - Public Methods
    
    /// Generate a complete daily vibe interpretation with transit-primary weight distribution
    /// - Parameters:
    ///   - natalChart: The natal chart (for base style resonance using Whole Sign)
    ///   - progressedChart: The progressed chart (for emotional vibe using Placidus)
    ///   - transits: Array of transit aspects to natal chart
    ///   - weather: Optional current weather conditions
    ///   - moonPhase: Current lunar phase (0-360)
    /// - Returns: A formatted daily vibe interpretation
    static func generateDailyVibe(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        moonPhase: Double) -> DailyVibeContent {
            
            print("\n☀️ GENERATING DAILY COSMIC VIBE - TRANSIT-PRIMARY SYSTEM ☀️")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎯 NEW WEIGHT DISTRIBUTION STRATEGY:")
            print("  • Transit Analysis: PRIMARY INFLUENCES (70% total weight)")
            print("  • Natal Foundation: CONSISTENT BASE (20% normalized weight)")
            print("  • Environmental Factors: SUPPORTING (10% total weight)")
            print("  • Result: Increased daily variation with stable foundation")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // 1. Generate tokens for base style resonance (100% natal, Whole Sign)
            let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
            logTokenSet("BASE STYLE TOKENS (WHOLE SIGN)", baseStyleTokens)
            
            // 2. Generate tokens for emotional vibe of day (60% progressed Moon, 40% natal Moon, Placidus)
            let emotionalVibeTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
                natal: natalChart,
                progressed: progressedChart
            )
            logTokenSet("EMOTIONAL VIBE TOKENS (PLACIDUS - 60% PROGRESSED, 40% NATAL)", emotionalVibeTokens)
            
            // 3. Generate DIVERSE tokens from planetary transits (fixed token generation)
            let rawTransitTokens = generateDiverseTransitTokens(
                transits: transits,
                natal: natalChart
            )
            
            // 3a. Separate fast and slow transit tokens and apply freshness boost
            var fastTransitTokens: [StyleToken] = []
            var slowTransitTokens: [StyleToken] = []

            for token in rawTransitTokens {
                if let planetarySource = token.planetarySource {
                    let freshnessBoost = applyFreshnessBoost(transitPlanet: planetarySource, aspectType: token.aspectSource ?? "")
                    
                    if ["Sun", "Moon", "Mercury", "Venus", "Mars"].contains(planetarySource) {
                        // Fast-moving planets
                        let boostedToken = StyleToken(
                            name: token.name,
                            type: token.type,
                            weight: token.weight * freshnessBoost,
                            planetarySource: token.planetarySource,
                            signSource: token.signSource,
                            houseSource: token.houseSource,
                            aspectSource: token.aspectSource,
                            originType: token.originType
                        )
                        fastTransitTokens.append(boostedToken)
                    } else {
                        // Slow-moving planets
                        slowTransitTokens.append(token)
                    }
                } else {
                    // Default to slow if no planetary source
                    slowTransitTokens.append(token)
                }
            }
            
            logTokenSet("FAST TRANSIT TOKENS (with freshness boost)", fastTransitTokens)
            logTokenSet("SLOW TRANSIT TOKENS", slowTransitTokens)
            
            // 4. Generate tokens for current weather
            let weatherTokens = generateWeatherTokens(weather: weather)
            logTokenSet("WEATHER TOKENS", weatherTokens)
            
            // 5. Generate daily signature tokens (includes temporal markers - NO DUPLICATION)
            let dailySignatureTokens = generateDailySignature()
            logTokenSet("DAILY SIGNATURE TOKENS (includes temporal markers)", dailySignatureTokens)
            
            // 6. APPLY NEW TRANSIT-PRIMARY WEIGHT DISTRIBUTION
            var allTokens: [StyleToken] = []
            
            // NEW WEIGHT DISTRIBUTION: AGGRESSIVE but BALANCED Transit-Primary System
            // NATAL FOUNDATION: Balanced normalized base (20% total)
            let natalBaseWeight = 0.20
            
            // TRANSIT INFLUENCES: Strong primary drivers (65% total)
            let fastTransitWeight = 0.50    // 50% for fast transits (strong boost)
            let slowTransitWeight = 0.15    // 15% for slow transits (moderate boost)
            
            // OTHER INFLUENCES: Supporting elements (15% total)
            let emotionalWeight = 0.08      // 8% for emotional/progressed
            let weatherWeight = 0.04        // 4% for weather
            let dailySignatureWeight = 0.03 // 3% for daily signature
            
            print("\n🎯 APPLYING AGGRESSIVE but BALANCED TRANSIT-PRIMARY SYSTEM:")
            print("  • Natal Base: \(natalBaseWeight * 100)% (balanced foundation)")
            print("  • Fast Transits: \(fastTransitWeight * 100)% (3x boost - primary drivers)")
            print("  • Slow Transits: \(slowTransitWeight * 100)% (2x boost - background themes)")
            print("  • Emotional: \(emotionalWeight * 100)% (moderate mood influence)")
            print("  • Weather: \(weatherWeight * 100)% (practical adjustment)")
            print("  • Daily Signature: \(dailySignatureWeight * 100)% (temporal rhythm)")
            
            // Apply AGGRESSIVE but BALANCED natal normalization
            for token in baseStyleTokens {
                // Balanced normalization: Reduce natal dominance but keep foundation
                let normalizedWeight = min(token.weight * 0.4, 1.0) // Moderate reduction
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: normalizedWeight * natalBaseWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to emotional vibe tokens
            for token in emotionalVibeTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * emotionalWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply STRONG but BALANCED weights to fast transit tokens (PRIMARY DRIVERS)
            for token in fastTransitTokens {
                // Apply 3x boost to ensure strong transit influence
                let strongBoostedWeight = token.weight * 3.0
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: strongBoostedWeight * fastTransitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply MODERATE weights to slow transit tokens (BACKGROUND THEMES)
            for token in slowTransitTokens {
                // Apply 2x boost to slow transits
                let moderateBoostedWeight = token.weight * 2.0
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: moderateBoostedWeight * slowTransitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to weather tokens
            for token in weatherTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * weatherWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to daily signature tokens
            for token in dailySignatureTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * dailySignatureWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Log combined weighted tokens
            logTokenSet("COMBINED WEIGHTED TOKENS (TRANSIT-PRIMARY)", allTokens)
            
            // Log top weighted tokens to verify transit dominance
            let topTokens = allTokens.sorted { $0.weight > $1.weight }.prefix(15)
            print("\n⭐ TOP 15 WEIGHTED TOKENS (Transit-Primary System) ⭐")
            for (index, token) in topTokens.enumerated() {
                let originLabel = getOriginLabel(token: token)
                print("\(index + 1). \(token.name) (\(token.type), weight: \(String(format: "%.3f", token.weight))) [\(originLabel)]")
            }
            
            // Verify weight distribution is working correctly
            verifyWeightDistribution(tokens: allTokens)
            
            // 7. Generate interpretative elements
            let analysis = analyzeTokens(allTokens)
            let patternSeed = getDailyPatternSeed()
            let styleBrief = generateStyleBrief(tokens: allTokens, moonPhase: moonPhase, patternSeed: patternSeed)
            
            // 8. Generate specific fashion elements
            let textiles = generateTextiles(tokens: allTokens)
            let colors = generateColors(tokens: allTokens)
            let patterns = generatePatterns(tokens: allTokens)
            let shape = generateShape(tokens: allTokens)
            let brightness = calculateBrightness(tokens: allTokens, moonPhase: moonPhase)
            let vibrancy = calculateVibrancy(tokens: allTokens)
            
            print("✅ Daily Vibe generated successfully with Transit-Primary system!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            // Create the DailyVibeContent using the original structure
            var content = DailyVibeContent()
            content.styleBrief = styleBrief
            content.textiles = textiles
            content.colors = colors
            content.patterns = patterns
            content.shape = shape
            content.brightness = brightness
            content.vibrancy = vibrancy
            content.accessories = generateAccessories(tokens: allTokens)
            content.takeaway = generateTakeaway(tokens: allTokens, moonPhase: moonPhase, patternSeed: patternSeed)
            
            // Add weather information if available
            if let weather = weather {
                content.temperature = weather.temp
                content.weatherCondition = weather.conditions
            }
            
            return content
        }
    
    // MARK: - Helper Methods
    
    /// Get origin label for token for debugging
    private static func getOriginLabel(token: StyleToken) -> String {
        switch token.originType {
        case .natal:
            return "NATAL"
        case .transit:
            if let planet = token.planetarySource {
                if ["Sun", "Moon", "Mercury", "Venus", "Mars"].contains(planet) {
                    return "FAST TRANSIT"
                } else {
                    return "SLOW TRANSIT"
                }
            }
            return "TRANSIT"
        case .progressed:
            return "PROGRESSED"
        case .weather:
            return "WEATHER"
        case .phase:
            return "DAILY SIG"
        }
    }
    
    /// Verify the weight distribution is working as intended
    private static func verifyWeightDistribution(tokens: [StyleToken]) {
        let natalTokens = tokens.filter { $0.originType == .natal }
        let transitTokens = tokens.filter { $0.originType == .transit }
        let progressedTokens = tokens.filter { $0.originType == .progressed }
        let weatherTokens = tokens.filter { $0.originType == .weather }
        let phaseTokens = tokens.filter { $0.originType == .phase }
        
        let natalWeight = natalTokens.reduce(0) { $0 + $1.weight }
        let transitWeight = transitTokens.reduce(0) { $0 + $1.weight }
        let progressedWeight = progressedTokens.reduce(0) { $0 + $1.weight }
        let weatherWeight = weatherTokens.reduce(0) { $0 + $1.weight }
        let phaseWeight = phaseTokens.reduce(0) { $0 + $1.weight }
        
        let totalWeight = natalWeight + transitWeight + progressedWeight + weatherWeight + phaseWeight
        
        print("\n📊 WEIGHT DISTRIBUTION VERIFICATION:")
        print("  • Natal: \(String(format: "%.1f%%", (natalWeight/totalWeight) * 100)) (target: ~20%)")
        print("  • Transit: \(String(format: "%.1f%%", (transitWeight/totalWeight) * 100)) (target: ~65%)")
        print("  • Progressed: \(String(format: "%.1f%%", (progressedWeight/totalWeight) * 100)) (target: ~8%)")
        print("  • Weather: \(String(format: "%.1f%%", (weatherWeight/totalWeight) * 100)) (target: ~4%)")
        print("  • Daily Signature: \(String(format: "%.1f%%", (phaseWeight/totalWeight) * 100)) (target: ~3%)")
        
        // Check if transit weight is actually dominating
        if transitWeight > natalWeight * 2.5 { // Should be at least 2.5x natal
            print("✅ SUCCESS: Transit influence STRONGLY DOMINATES (balanced aggressive system working)")
        } else if transitWeight > natalWeight * 1.5 {
            print("⚠️  PARTIAL: Transit influence dominates moderately - good balance achieved")
        } else if transitWeight > natalWeight {
            print("⚠️  WEAK: Transit influence dominates but could be stronger")
        } else {
            print("❌ FAILURE: Transit influence still insufficient")
        }
    }
    
    /// Apply freshness boost for recent aspects
    private static func applyFreshnessBoost(transitPlanet: String, aspectType: String?) -> Double {
        // Boost for aspects that are particularly "fresh" or impactful for daily style
        var boost = 1.0
        
        // Enhanced boost for fashion-relevant planets
        switch transitPlanet {
        case "Venus":
            boost = 1.4  // Venus is key for fashion/beauty
        case "Mars":
            boost = 1.3  // Mars drives energy and action
        case "Mercury":
            boost = 1.2  // Mercury affects communication style
        case "Sun":
            boost = 1.2  // Sun affects overall expression
        case "Moon":
            boost = 1.1  // Moon affects mood and comfort
        default:
            boost = 1.0
        }
        
        // Additional boost for powerful aspects
        if let aspect = aspectType {
            if aspect.contains("Conjunction") || aspect.contains("Opposition") {
                boost *= 1.2
            } else if aspect.contains("Square") {
                boost *= 1.1
            }
        }
        
        return boost
    }
    
    /// Log token set for debugging
    private static func logTokenSet(_ label: String, _ tokens: [StyleToken]) {
        print("\n🎭 \(label) (\(tokens.count) tokens)")
        for token in tokens.prefix(5) {
            print("  • \(token.name) (\(token.type), weight: \(String(format: "%.2f", token.weight)))")
            if let source = token.planetarySource {
                print("    Source: \(source)")
            }
        }
        if tokens.count > 5 {
            print("    ... and \(tokens.count - 5) more")
        }
    }
    
    /// Generate weather-based tokens (using original logic)
    private static func generateWeatherTokens(weather: TodayWeather?) -> [StyleToken] {
        guard let weather = weather else { return [] }
        
        var tokens: [StyleToken] = []
        
        // Base weight for weather
        let baseWeight: Double = 1.0
        
        // Temperature tokens using InterpretationTextLibrary
        let temperatureDescriptions = InterpretationTextLibrary.Weather.Temperature.descriptions
        for (threshold, weatherType, textureType, _) in temperatureDescriptions {
            if weather.temp < Double(threshold) {
                // Calculate weight based on temperature extremity
                let extremityWeight = calculateTemperatureWeight(temp: weather.temp)
                
                tokens.append(StyleToken(name: weatherType, type: "weather", weight: extremityWeight,
                                       planetarySource: nil, signSource: nil, houseSource: nil,
                                       aspectSource: "Temperature Safety", originType: .weather))
                tokens.append(StyleToken(name: textureType, type: "texture", weight: extremityWeight,
                                       planetarySource: nil, signSource: nil, houseSource: nil,
                                       aspectSource: "Temperature Safety", originType: .weather))
                break
            }
        }
        
        // Humidity tokens using library
        let humidityDescriptions = InterpretationTextLibrary.Weather.Humidity.descriptions
        for (threshold, fabricType) in humidityDescriptions {
            if (threshold > 80 && weather.humidity > Int(Double(threshold))) ||
                (threshold <= 80 && weather.humidity > Int(Double(threshold)) && weather.humidity <= Int(Double(threshold + 20))) {
                tokens.append(StyleToken(name: fabricType, type: "fabric", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
                break
            }
        }
        
        // Add daily variation based on exact conditions
        let patternSeed = getDailyPatternSeed()
        let dailyVariations = InterpretationTextLibrary.Weather.DailyVariations.patternVariations
        let selectedVariation = dailyVariations[patternSeed % dailyVariations.count]
        
        tokens.append(StyleToken(name: selectedVariation, type: "structure", weight: baseWeight * 0.9, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Weather Nuance", originType: .weather))
        
        return tokens
    }
    
    /// Calculate temperature weight based on extremity
    private static func calculateTemperatureWeight(temp: Double) -> Double {
        // Higher weight for more extreme temperatures
        let tempCelsius = temp
        if tempCelsius < 0 || tempCelsius > 35 {
            return 1.3  // Extreme temperatures
        } else if tempCelsius < 10 || tempCelsius > 28 {
            return 1.2  // Uncomfortable temperatures
        } else {
            return 1.0  // Comfortable temperatures
        }
    }
    
    /// Get daily pattern seed for consistent variation
    internal static func getDailyPatternSeed() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return (components.year ?? 2025) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
    }
    
    // MARK: - Enhanced Daily Signature Generation (NO DUPLICATION)
    static func generateDailySignature() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Day of week influence
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let seed = getDailyPatternSeed()
        
        // Use seed for daily weight variations (subtle but consistent)
        let weightVariation = 1.0 + (Double(seed % 21) - 10.0) / 100.0 // ±10% variation
        
        switch weekday {
        case 1: // Sunday (Sun)
            tokens.append(StyleToken(
                name: "illuminated",
                type: "texture",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Sun Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "radiant",
                type: "color_quality",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Sun Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "amber gold",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Sun Day",
                originType: .phase
            ))
            
        case 2: // Monday (Moon)
            tokens.append(StyleToken(
                name: "reflective",
                type: "mood",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Moon Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "intuitive",
                type: "structure",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Moon Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "pearl silver",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Moon Day",
                originType: .phase
            ))
            
        case 3: // Tuesday (Mars)
            tokens.append(StyleToken(
                name: "energetic",
                type: "mood",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Mars Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "dynamic",
                type: "structure",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Mars Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "ruby red",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Mars Day",
                originType: .phase
            ))
            
        case 4: // Wednesday (Mercury)
            tokens.append(StyleToken(
                name: "communicative",
                type: "mood",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Mercury Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "versatile",
                type: "structure",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Mercury Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "quicksilver",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Mercury Day",
                originType: .phase
            ))
            
        case 5: // Thursday (Jupiter)
            tokens.append(StyleToken(
                name: "expansive",
                type: "mood",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Jupiter Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "abundant",
                type: "expression",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Jupiter Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "royal blue",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Jupiter Day",
                originType: .phase
            ))
            
        case 6: // Friday (Venus)
            tokens.append(StyleToken(
                name: "harmonious",
                type: "mood",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Venus Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "beautiful",
                type: "color_quality",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Venus Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "emerald green",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Venus Day",
                originType: .phase
            ))
            
        case 7: // Saturday (Saturn)
            tokens.append(StyleToken(
                name: "structured",
                type: "structure",
                weight: 2.2 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Saturn Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "disciplined",
                type: "mood",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Saturn Day",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "deep charcoal",
                type: "color",
                weight: 2.0 * weightVariation,
                planetarySource: "Daily Signature",
                aspectSource: "Saturn Day",
                originType: .phase
            ))
            
        default:
            break
        }
        
        // Add monthly and yearly progression markers (subtle)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let yearProgress = Double(dayOfYear) / 365.0
        
        if yearProgress < 0.33 {
            // First third of year - Growing Phase
            tokens.append(StyleToken(
                name: "emerging",
                type: "expression",
                weight: 1.4 * weightVariation,
                planetarySource: "Yearly Cycle",
                aspectSource: "Year Growth Phase",
                originType: .phase
            ))
        } else if yearProgress < 0.66 {
            // Middle third of year - Expressing Phase
            tokens.append(StyleToken(
                name: "manifesting",
                type: "expression",
                weight: 1.6 * weightVariation,
                planetarySource: "Yearly Cycle",
                aspectSource: "Year Expression Phase",
                originType: .phase
            ))
        } else {
            // Final third of year - Integrating Phase
            tokens.append(StyleToken(
                name: "completing",
                type: "expression",
                weight: 1.5 * weightVariation,
                planetarySource: "Yearly Cycle",
                aspectSource: "Year Integration Phase",
                originType: .phase
            ))
        }

        return tokens
    }
    
    // MARK: - Token Analysis Functions
    
    /// Analyze tokens to determine dominant characteristics and combinations
    private static func analyzeTokens(_ tokens: [StyleToken]) -> TokenAnalysis {
        // Get tokens by category
        let structureTokens = tokens.filter { $0.type == "structure" }
        let moodTokens = tokens.filter { $0.type == "mood" }
        let textureTokens = tokens.filter { $0.type == "texture" }
        let colorQualityTokens = tokens.filter { $0.type == "color_quality" }
        let expressionTokens = tokens.filter { $0.type == "expression" }
        let colorTokens = tokens.filter { $0.type == "color" }
        
        // Calculate primary elements
        let primaryStructure = structureTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryMood = moodTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryTexture = textureTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryColorQuality = colorQualityTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryExpression = expressionTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryColor = colorTokens.max(by: { $0.weight < $1.weight })?.name
        
        // Calculate overall weight
        let overallWeight = tokens.reduce(0) { $0 + $1.weight }
        
        // Determine energy direction
        let energyDirection = determineEnergyDirection(
            structure: primaryStructure,
            mood: primaryMood,
            texture: primaryTexture,
            combinations: [:]  // Simplified for this implementation
        )
        
        // Analyze combinations (simplified)
        let minWeight = 0.3
        let isFluidAndIntuitive = hasTokenCombination(tokens, ["fluid", "intuitive"], minWeight: minWeight)
        let isBoldAndDynamic = hasTokenCombination(tokens, ["bold", "dynamic"], minWeight: minWeight)
        let isLuxuriousAndComforting = hasTokenCombination(tokens, ["luxurious", "comforting"], minWeight: minWeight)
        let isStructuredAndMinimal = hasTokenCombination(tokens, ["structured", "minimal"], minWeight: minWeight)
        let isGroundedAndSensual = hasTokenCombination(tokens, ["grounded", "sensual"], minWeight: minWeight)
        
        return TokenAnalysis(
            isFluidAndIntuitive: isFluidAndIntuitive,
            isBoldAndDynamic: isBoldAndDynamic,
            isLuxuriousAndComforting: isLuxuriousAndComforting,
            isStructuredAndMinimal: isStructuredAndMinimal,
            isGroundedAndSensual: isGroundedAndSensual,
            isHarmoniousAndBalanced: false, // Simplified
            isCalibratedAndSubtle: false,   // Simplified
            isExpansiveAndFresh: false,     // Simplified
            isCompletingAndSubstantial: false, // Simplified
            isEmergingAndElevated: false,   // Simplified
            isExpansiveAndAbundant: false,  // Simplified
            isSensualAndLuxurious: false,   // Simplified
            isInnovativeAndUnconventional: false, // Simplified
            
            primaryStructure: primaryStructure,
            primaryMood: primaryMood,
            primaryTexture: primaryTexture,
            primaryColorQuality: primaryColorQuality,
            primaryExpression: primaryExpression,
            primaryColor: primaryColor,
            
            overallWeight: overallWeight,
            energyDirection: energyDirection,
            
        )
    }
    
    // MARK: - Helper Functions
    
    private static func hasTokenCombination(_ tokens: [StyleToken], _ names: [String], minWeight: Double) -> Bool {
        return names.allSatisfy { name in
            tokens.contains { token in
                token.name.lowercased() == name.lowercased() && token.weight >= minWeight
            }
        }
    }
    
    private static func determineEnergyDirection(structure: String?, mood: String?, texture: String?, combinations: [String: Bool]) -> String {
        if combinations["fluid_intuitive"] == true || structure == "fluid" {
            return "flowing"
        }
        if combinations["grounded_practical"] == true || mood == "grounded" {
            return "grounded"
        }
        if combinations["innovative_unconventional"] == true || structure == "unconventional" {
            return "innovative"
        }
        if combinations["responsive_adaptable"] == true || texture == "comforting" {
            return "nurturing"
        }
        if texture == "luxurious" || mood == "sensual" {
            return "intense"
        }
        return "balanced"
    }
    
    // MARK: - Style Brief Generation WITH TOKEN PREFIX MATRIX
    internal static func generateStyleBrief(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
        
        print("\n🎯 GENERATING STYLE BRIEF WITH TOKEN PREFIX MATRIX (Transit-Primary)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // STEP 1: Create token context for prefix determination
        let tokenContext = TokenContext(moonPhase: moonPhase)
        
        // STEP 2: Analyze token categories and weights
        let tokenAnalysis = analyzeTokens(tokens)
        
        // STEP 3: Create daily signature for uniqueness
        let dailySignature = createDailySignature(from: tokenAnalysis, moonPhase: moonPhase, patternSeed: patternSeed)
        
        // STEP 4: Get prefixed tokens for primary style elements
        let prefixedTokens = getPrefixedTokens(tokens: tokens, context: tokenContext)
        
        // DEBUG: Output token analysis and prefixes to console
        debugTokenAnalysis(tokenAnalysis, dailySignature: dailySignature)
        debugPrefixedTokens(prefixedTokens)
        
        // STEP 5: Find the precise combination that matches today's unique energy
        let styleBrief = selectPreciseStyleBriefWithPrefixes(
            from: tokenAnalysis,
            dailySignature: dailySignature,
            prefixedTokens: prefixedTokens,
            context: tokenContext,
            patternSeed: patternSeed
        )
        
        print("✅ Style Brief with prefixes generated successfully!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return styleBrief
    }
    
    // MARK: - Supporting Structures and Functions
    
    private struct TokenContext {
        let moonPhase: Double
        
        var isMoonWaxing: Bool {
            return moonPhase > 0 && moonPhase < 180
        }
        
        var isMoonWaning: Bool {
            return moonPhase > 180 && moonPhase < 360
        }
        
        var isMoonNew: Bool {
            return moonPhase >= 0 && moonPhase < 45
        }
        
        var isMoonFull: Bool {
            return moonPhase >= 135 && moonPhase < 225
        }
    }
    
    private struct DailySignature {
        let moonPhaseEnergy: String
        let planetaryDay: String
        let dominantMood: String
        let energyIntensity: String
        let dailyTokens: [String: Double]
    }
    
    private static func createDailySignature(from analysis: TokenAnalysis, moonPhase: Double, patternSeed: Int) -> DailySignature {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        let planetaryDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let planetaryDay = planetaryDays[weekday - 1]
        
        let moonPhaseEnergy: String
        if moonPhase >= 0 && moonPhase < 45 {
            moonPhaseEnergy = "New Moon"
        } else if moonPhase >= 45 && moonPhase < 90 {
            moonPhaseEnergy = "Waxing Crescent"
        } else if moonPhase >= 90 && moonPhase < 135 {
            moonPhaseEnergy = "First Quarter"
        } else if moonPhase >= 135 && moonPhase < 180 {
            moonPhaseEnergy = "Waxing Gibbous"
        } else if moonPhase >= 180 && moonPhase < 225 {
            moonPhaseEnergy = "Full Moon"
        } else if moonPhase >= 225 && moonPhase < 270 {
            moonPhaseEnergy = "Waning Gibbous"
        } else if moonPhase >= 270 && moonPhase < 315 {
            moonPhaseEnergy = "Last Quarter"
        } else {
            moonPhaseEnergy = "Waning Crescent"
        }
        
        let dominantMood = analysis.primaryMood ?? "balanced"
        let energyIntensity = analysis.overallWeight > 10 ? "high" : analysis.overallWeight > 5 ? "moderate" : "low"
        
        return DailySignature(
            moonPhaseEnergy: moonPhaseEnergy,
            planetaryDay: planetaryDay,
            dominantMood: dominantMood,
            energyIntensity: energyIntensity,
            dailyTokens: [:]
        )
    }
    
    private static func getPrefixedTokens(tokens: [StyleToken], context: TokenContext) -> [(token: StyleToken, prefix: String)] {
        var prefixedTokens: [(token: StyleToken, prefix: String)] = []
        
        // Get top weighted tokens for prefix assignment
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(5)
        
        for token in topTokens {
            let prefix = getPrefixForToken(token: token, context: context)
            prefixedTokens.append((token: token, prefix: prefix))
        }
        
        return prefixedTokens
    }
    
    private static func getPrefixForToken(token: StyleToken, context: TokenContext) -> String {
        // Generate context-aware prefixes based on token properties and lunar phase
        if token.originType == .transit && token.weight > 0.2 {
            if context.isMoonWaxing {
                return "Today's energy says"
            } else if context.isMoonWaning {
                return "The vibe right now"
            } else {
                return "This moment calls for"
            }
        } else if token.originType == .natal {
            return "Your natural style foundation"
        } else {
            return "The current flow suggests"
        }
    }
    
    private static func selectPreciseStyleBriefWithPrefixes(
        from analysis: TokenAnalysis,
        dailySignature: DailySignature,
        prefixedTokens: [(token: StyleToken, prefix: String)],
        context: TokenContext,
        patternSeed: Int) -> String {
        
        // Use the dominant prefix from the highest weighted token
        let dominantPrefix = prefixedTokens.first?.prefix ?? "Today's the day"
        
        // Create style brief using transit-primary analysis
        if analysis.isBoldAndDynamic {
            return "\(dominantPrefix): bold, dynamic pieces that command attention and express your confidence."
        } else if analysis.isFluidAndIntuitive {
            return "\(dominantPrefix): fluid, intuitive choices that move with your natural rhythm."
        } else if analysis.isLuxuriousAndComforting {
            return "\(dominantPrefix): luxurious, comforting textures that feel as good as they look."
        } else if analysis.isStructuredAndMinimal {
            return "\(dominantPrefix): clean, structured lines that speak with quiet authority."
        } else if analysis.isGroundedAndSensual {
            return "\(dominantPrefix): grounded, sensual pieces that connect you to your authentic self."
        } else {
            // Default with primary elements
            let mood = analysis.primaryMood ?? "balanced"
            let structure = analysis.primaryStructure ?? "fluid"
            return "\(dominantPrefix): \(mood), \(structure) pieces that reflect your current cosmic moment."
        }
    }
    
    /// Debug token analysis
    private static func debugTokenAnalysis(_ analysis: TokenAnalysis, dailySignature: DailySignature) {
        print("🎭 STYLE BRIEF TOKEN ANALYSIS (Transit-Primary):")
        print("Primary Structure: \(analysis.primaryStructure ?? "none")")
        print("Primary Mood: \(analysis.primaryMood ?? "none")")
        print("Primary Texture: \(analysis.primaryTexture ?? "none")")
        print("Primary Color: \(analysis.primaryColor ?? "none")")
        print("Energy Direction: \(analysis.energyDirection)")
        print("Moon Phase Energy: \(dailySignature.moonPhaseEnergy)")
        print("Planetary Day: \(dailySignature.planetaryDay)")
        print("Dominant Mood: \(dailySignature.dominantMood)")
        print("Energy Intensity: \(dailySignature.energyIntensity)")
    }
    
    /// Debug prefixed tokens
    private static func debugPrefixedTokens(_ prefixedTokens: [(token: StyleToken, prefix: String)]) {
        print("🏷️  PREFIXED TOKENS:")
        for (token, prefix) in prefixedTokens.prefix(3) {
            print("  • \(prefix): \(token.name) (weight: \(String(format: "%.3f", token.weight)))")
        }
    }
    
    // MARK: - Section Generation Methods
    
    static func generateTextiles(tokens: [StyleToken]) -> String {
        let textureTokens = tokens.filter { $0.type == "texture" }
        let dominantTexture = textureTokens.max(by: { $0.weight < $1.weight })?.name ?? "substantial"
        
        return "Textures that feel \(dominantTexture) and authentic, with natural depth and character."
    }
    
    static func generateColors(tokens: [StyleToken]) -> String {
        let colorTokens = tokens.filter { $0.type == "color" || $0.type == "color_quality" }
        let dominantColor = colorTokens.max(by: { $0.weight < $1.weight })?.name ?? "rich"
        
        return "\(dominantColor.capitalized) tones with depth and natural resonance."
    }
    
    static func calculateBrightness(tokens: [StyleToken], moonPhase: Double) -> Int {
        let brightnessBase = 50
        let phaseAdjustment = Int(moonPhase / 360.0 * 30) // 0-30 based on moon phase
        let tokenBrightness = tokens.filter { $0.name.contains("bright") || $0.name.contains("radiant") }.reduce(0) { $0 + Int($1.weight * 10) }
        
        return min(100, max(20, brightnessBase + phaseAdjustment + tokenBrightness))
    }
    
    static func calculateVibrancy(tokens: [StyleToken]) -> Int {
        let vibrancyTokens = tokens.filter { $0.type == "color_quality" || $0.name.contains("vibrant") }
        let vibrancyBase = 60
        let tokenVibrancy = vibrancyTokens.reduce(0) { $0 + Int($1.weight * 15) }
        
        return min(100, max(30, vibrancyBase + tokenVibrancy))
    }
    
    static func generatePatterns(tokens: [StyleToken]) -> String {
        let structureTokens = tokens.filter { $0.type == "structure" }
        let dominantStructure = structureTokens.max(by: { $0.weight < $1.weight })?.name ?? "balanced"
        
        return "Patterns that reflect \(dominantStructure) energy with natural flow."
    }
    
    static func generateShape(tokens: [StyleToken]) -> String {
        let structureTokens = tokens.filter { $0.type == "structure" }
        let moodTokens = tokens.filter { $0.type == "mood" }
        
        let dominantStructure = structureTokens.max(by: { $0.weight < $1.weight })?.name ?? "fluid"
        let dominantMood = moodTokens.max(by: { $0.weight < $1.weight })?.name ?? "balanced"
        
        return "\(dominantStructure.capitalized) silhouettes with \(dominantMood) proportions."
    }
    
    static func generateAccessories(tokens: [StyleToken]) -> String {
        let expressionTokens = tokens.filter { $0.type == "expression" }
        let colorTokens = tokens.filter { $0.type == "color" }
        
        let dominantExpression = expressionTokens.max(by: { $0.weight < $1.weight })?.name ?? "balanced"
        let accentColor = colorTokens.max(by: { $0.weight < $1.weight })?.name ?? "natural"
        
        return "Accessories that \(dominantExpression) your look with \(accentColor) accents."
    }
    
    static func generateTakeaway(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
        let moodTokens = tokens.filter { $0.type == "mood" }
        let dominantMood = moodTokens.max(by: { $0.weight < $1.weight })?.name ?? "balanced"
        
        return "Today's cosmic energy supports \(dominantMood) self-expression through your style choices."
    }
    
    // MARK: - Enhanced Transit Token Generation
    
    /// Generate diverse transit tokens based on actual planetary combinations
    private static func generateDiverseTransitTokens(
        transits: [[String: Any]],
        natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
            
        var tokens: [StyleToken] = []
        
        for transit in transits {
            // Extract transit data
            let transitPlanet = transit["transitPlanet"] as? String ?? ""
            let natalPlanet = transit["natalPlanet"] as? String ?? ""
            let aspectType = transit["aspectType"] as? String ?? ""
            let orb = transit["orb"] as? Double ?? 1.0
            
            // Skip weak aspects
            if orb > 5.0 { continue }
            
            // Calculate base weight
            let baseWeight = calculateTransitBaseWeight(
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                orb: orb
            )
            
            // Skip insignificant transits
            if baseWeight < 0.1 { continue }
            
            // Generate diverse tokens for this transit
            let aspectSource = "\(transitPlanet) \(aspectType) \(natalPlanet)"
            let transitTokens = createDiverseTokensForTransit(
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            )
            
            tokens.append(contentsOf: transitTokens)
        }
        
        return tokens
    }
    
    /// Create diverse tokens for a specific transit
    private static func createDiverseTokensForTransit(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String,
        baseWeight: Double,
        aspectSource: String) -> [StyleToken] {
        
        var tokens: [StyleToken] = []
        
        // Generate tokens based on transit planet energy
        switch transitPlanet {
        case "Venus":
            tokens.append(contentsOf: createVenusTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        case "Mars":
            tokens.append(contentsOf: createMarsTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        case "Mercury":
            tokens.append(contentsOf: createMercuryTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        case "Sun":
            tokens.append(contentsOf: createSunTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        case "Moon":
            tokens.append(contentsOf: createMoonTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        case "Jupiter":
            tokens.append(contentsOf: createJupiterTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        case "Saturn":
            tokens.append(contentsOf: createSaturnTransitTokens(
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
            
        default:
            // Generic outer planet transits
            tokens.append(contentsOf: createGenericTransitTokens(
                transitPlanet: transitPlanet,
                aspectType: aspectType,
                baseWeight: baseWeight,
                aspectSource: aspectSource
            ))
        }
        
        return tokens
    }
    
    // MARK: - Planet-Specific Transit Token Generators
    
    private static func createVenusTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "harmonious", type: "mood", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "beautiful", type: "color_quality", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "luxurious", type: "texture", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "indulgent", type: "mood", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "rich", type: "color_quality", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "plush", type: "texture", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "aesthetic", type: "expression", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createMarsTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "dynamic", type: "structure", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "energetic", type: "mood", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "assertive", type: "structure", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "bold", type: "mood", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "intense", type: "color_quality", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "active", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createMercuryTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "communicative", type: "mood", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "bright", type: "color_quality", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "expressive", type: "mood", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "sharp", type: "color_quality", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "intellectual", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createSunTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "confident", type: "mood", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "expressive", type: "structure", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "dramatic", type: "structure", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "proud", type: "mood", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "warm", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "vital", type: "expression", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createMoonTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "intuitive", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "flowing", type: "structure", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "soft", type: "texture", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "protective", type: "structure", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "emotional", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "cozy", type: "texture", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "reflective", type: "expression", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createJupiterTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "expansive", type: "structure", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "optimistic", type: "mood", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "abundant", type: "expression", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "generous", type: "structure", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "adventurous", type: "mood", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "philosophical", type: "expression", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createSaturnTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "structured", type: "structure", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "disciplined", type: "mood", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "refined", type: "texture", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "minimal", type: "structure", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "serious", type: "mood", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "matte", type: "texture", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "authoritative", type: "expression", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func createGenericTransitTokens(transitPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // For outer planets (Uranus, Neptune, Pluto) and minor aspects
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "transformative", type: "mood", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "evolving", type: "expression", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "subtle", type: "texture", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    /// Calculate base weight for transit
    private static func calculateTransitBaseWeight(transitPlanet: String, natalPlanet: String, aspectType: String, orb: Double) -> Double {
        // Base aspect strength
        var baseWeight: Double
        switch aspectType {
        case "Conjunction": baseWeight = 1.0
        case "Opposition": baseWeight = 0.8
        case "Square": baseWeight = 0.8
        case "Trine": baseWeight = 0.6
        case "Sextile": baseWeight = 0.4
        default: baseWeight = 0.2
        }
        
        // Adjust for orb tightness
        let orbAdjustment = max(0.3, 1.0 - (orb / 5.0))
        
        // Adjust for transit planet importance
        let planetWeight: Double
        switch transitPlanet {
        case "Venus", "Mars": planetWeight = 1.2
        case "Mercury", "Sun", "Moon": planetWeight = 1.0
        case "Jupiter": planetWeight = 0.8
        case "Saturn": planetWeight = 0.7
        default: planetWeight = 0.5
        }
        
        return baseWeight * orbAdjustment * planetWeight
    }
}

// MARK: - Daily Vibe Content Structure
struct DailyVibeContent: Codable {
    // Main content - Style Brief replaces title and mainParagraph
    var styleBrief: String = ""
    
    // Style guidance sections
    var textiles: String = ""
    var colors: String = ""
    var brightness: Int = 50 // Percentage (0-100)
    var vibrancy: Int = 50   // Percentage (0-100)
    var patterns: String = ""
    var shape: String = ""
    var accessories: String = ""

    // Final line
    var takeaway: String = ""

    // Weather information (optional)
    var temperature: Double? = nil
    var weatherCondition: String? = nil
}

// MARK: - Internal Token Analysis Structure
private struct TokenAnalysis {
    let isFluidAndIntuitive: Bool
    let isBoldAndDynamic: Bool
    let isLuxuriousAndComforting: Bool
    let isStructuredAndMinimal: Bool
    let isGroundedAndSensual: Bool
    let isHarmoniousAndBalanced: Bool
    let isCalibratedAndSubtle: Bool
    let isExpansiveAndFresh: Bool
    let isCompletingAndSubstantial: Bool
    let isEmergingAndElevated: Bool
    let isExpansiveAndAbundant: Bool
    let isSensualAndLuxurious: Bool
    let isInnovativeAndUnconventional: Bool
    
    let primaryStructure: String?
    let primaryMood: String?
    let primaryTexture: String?
    let primaryColorQuality: String?
    let primaryExpression: String?
    let primaryColor: String?
    
    let overallWeight: Double
    let energyDirection: String
}
