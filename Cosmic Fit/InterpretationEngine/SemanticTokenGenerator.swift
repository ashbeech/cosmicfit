//
//  SemanticTokenGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Enhanced with source tracking, improved weighting, and color handling
//  Refactored to use InterpretationTextLibrary

/**
 * INTEGRATION CHECKLIST - NEW INFLUENCE HIERARCHY SYSTEM
 *
 * ✅ 1. Seasonal aesthetic tokens removed from generateDailySignature()
 * ✅ 2. Current Sun sign tokens filtered to remove color_quality
 * ✅ 3. Venus/Mars/Moon weights enhanced in generateBlueprintTokens()
 * ✅ 4. Weather tokens reduced to practical only
 * ✅ 5. Hard weather filtering system implemented (WeatherFabricFilter)
 * ✅ 6. WeightingModel updated with new hierarchy weights
 * ✅ 7. Debug logging added for influence hierarchy using DebugLogger
 * ✅ 8. Validation tests created and integrated
 * ✅ 9. Method signature updates completed for fabric recommendations
 * ✅ 10. Integration verification methods added
 *
 * EXPECTED RESULTS:
 * - Venus in Scorpio dominates over summer seasonal influence
 * - Weather provides practical fabric filtering, not aesthetic direction
 * - Chart-based expression preferences take priority over environmental factors
 * - Hard temperature thresholds filter inappropriate fabrics
 * - Enhanced Venus/Mars/Moon weights create stronger personal expression
 * - System gracefully handles missing data or component failures
 */

import Foundation

class SemanticTokenGenerator {
    
    // MARK: - Blueprint Specific Token Generation
    
    /// Generate Blueprint tokens with enhanced but balanced Venus/Mars/Moon priority
    static func generateBlueprintTokens(natal: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Get chart ruler for dominant influence
        let chartRuler = getChartRuler(ascendantSign: CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign)
        
        // Process planets with enhanced weighting for Venus, Mars, Moon + Chart Ruler dominance
        for planet in natal.planets {
            // Professional base weights with proper hierarchy
            let baseWeight: Double
            var priorityMultiplier: Double = 1.0
            
            // Chart ruler gets significant multiplier but Venus retains fashion dominance
            var chartRulerMultiplier: Double = 1.0
            if planet.name == chartRuler {
                chartRulerMultiplier = 2.5  // Strong but not overwhelming
                DebugLogger.info("🔱 CHART RULER DOMINANCE: \(planet.name) receives 2.5x multiplier for personal expression")
            }
            
            switch planet.name {
            case "Venus":
                baseWeight = 4.0 // Maximum for fashion authority
                priorityMultiplier = 2.0 // Venus dominates fashion choices
                // Final: 4.0 × 2.0 × chart_ruler × natal_weight = Venus fashion authority
            case "Mars":
                baseWeight = 2.2 // Strong but secondary to Venus for fashion
                priorityMultiplier = 1.3 // Energy expression role
                // Final: 2.2 × 1.3 × chart_ruler × natal_weight = Mars energy expression
            case "Moon":
                baseWeight = 2.5 // Strong for emotional comfort
                priorityMultiplier = 1.5 // Enhanced for emotional style preferences
                // Final: 2.5 × 1.5 × chart_ruler × natal_weight = Moon emotional resonance
            case "Sun":
                baseWeight = 2.0 // Core identity
                priorityMultiplier = 1.2 // Self-expression
            case "Mercury":
                baseWeight = 1.5 // Communication style
                priorityMultiplier = 0.9 // Supporting role
            case "Jupiter":
                baseWeight = 1.4 // Expansion and growth
                priorityMultiplier = 0.8 // Supporting role
            case "Saturn":
                baseWeight = 1.6 // Structure and discipline
                priorityMultiplier = 1.0 // Practical grounding
            case "Uranus", "Neptune", "Pluto":
                baseWeight = 1.3 // Transformative but background
                priorityMultiplier = 0.6 // Subtle influence
            default:
                baseWeight = 1.0 // Minor points
                priorityMultiplier = 0.3 // Minimal influence
            }
            
            // Apply WeightingModel natal weight with chart ruler dominance
            let weight = baseWeight * priorityMultiplier * chartRulerMultiplier * WeightingModel.natalWeight
            
            // Generate tokens using existing InterpretationTextLibrary
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight
            )
            
            // For Venus, Mars, Moon - more moderate boost for specific token types
            let enhancedTokens = planetTokens.map { token in
                var enhancedWeight = token.weight
                
                if planet.name == "Venus" && (token.type == "color" || token.type == "color_quality") {
                    enhancedWeight *= 2.0 // Enhanced for Venus fashion authority
                } else if planet.name == "Mars" && (token.type == "structure" || token.type == "expression") {
                    enhancedWeight *= 1.3 // Mars energy expression enhancement
                } else if planet.name == "Moon" && (token.type == "texture" || token.type == "mood") {
                    enhancedWeight *= 1.5 // Enhanced for Moon emotional comfort priority
                }
                
                return StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: enhancedWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
            }
            
            // Apply age-dependent weighting
            let ageWeightedTokens = enhancedTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedTokens)
        }
        
        // Process ascendant with reduced weight
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign
        
        print("✅ Ascendant tokens generated for sign: \(CoordinateTransformations.getZodiacSignName(sign: ascendantSign))")
        
        let ascendantTokens = tokenizeForPlanetInSign(
            planet: "Ascendant",
            sign: ascendantSign,
            isRetrograde: false,
            weight: 1.8 * WeightingModel.natalWeight) // Reduced from 2.5
        
        let ageWeightedAscTokens = ascendantTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAscTokens)
        
        // Add house cusps with reduced weight
        let houseCuspTokens = generateHouseCuspTokens(chart: natal, weight: WeightingModel.natalWeight * 0.7) // Reduced by 30%
        tokens.append(contentsOf: houseCuspTokens)
        
        // Process aspects with reduced weight
        let aspectTokens = generateAspectTokens(chart: natal, baseWeight: WeightingModel.natalWeight * 0.8) // Reduced by 20%
        tokens.append(contentsOf: aspectTokens)
        
        // Add Color Season tokens for consistent fashion guidance (Partner's Feature)
        let colorSeason = ColorSeasonAnalyzer.determineColorSeason(chart: natal)
        let seasonalTokens = ColorSeasonAnalyzer.getSeasonalPalette(season: colorSeason)
        tokens.append(contentsOf: seasonalTokens)
        
        DebugLogger.info("🎨 COLOR SEASON ANALYSIS: \(colorSeason.rawValue) with \(seasonalTokens.count) palette tokens")
        
        // Add expanded textile tokens for Daily System
        let textileTokens = generateExpandedTextileTokens(chart: natal)
        tokens.append(contentsOf: textileTokens)
        
        // Add pattern tokens for Daily System
        let patternTokens = generatePatternTokens(chart: natal)
        tokens.append(contentsOf: patternTokens)
        
        // Add accessory tokens for Daily System
        let accessoryTokens = generateAccessoryTokens(chart: natal)
        tokens.append(contentsOf: accessoryTokens)
        
        // Add debug logging for Venus/Mars/Moon dominance
        DebugLogger.info("🌟 BALANCED EXPRESSION PLANET WEIGHTS:")
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        
        DebugLogger.info("  • Venus: \(venusTokens.count) tokens, max weight: \(String(format: "%.2f", venusTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0))")
        DebugLogger.info("  • Mars: \(marsTokens.count) tokens, max weight: \(String(format: "%.2f", marsTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0))")
        DebugLogger.info("  • Moon: \(moonTokens.count) tokens, max weight: \(String(format: "%.2f", moonTokens.max(by: { $0.weight < $1.weight })?.weight ?? 0))")
        
        return tokens
    }
    
    // MARK: - Daily Token Generation
    
    /// Generate LIMITED natal tokens specifically for Daily Fit
    static func generateDailyFitNatalTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Only process major planets (no asteroids)
        let majorPlanets = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                           "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
        
        for planet in natal.planets {
            guard majorPlanets.contains(planet.name) else { continue }
            
            // Lighter weights for Daily Fit
            let baseWeight: Double
            let maxTokens: Int
            
            switch planet.name {
            case "Venus":
                baseWeight = 1.5
                maxTokens = 2
            case "Mars":
                baseWeight = 1.4
                maxTokens = 2
            case "Moon":
                baseWeight = 1.3
                maxTokens = 2
            case "Sun":
                baseWeight = 1.0
                maxTokens = 1
            case "Mercury":
                baseWeight = 0.8
                maxTokens = 1
            case "Jupiter", "Saturn":
                baseWeight = 0.6
                maxTokens = 1
            case "Uranus", "Neptune", "Pluto":
                baseWeight = 0.4
                maxTokens = 1
            default:
                baseWeight = 0.3
                maxTokens = 1
            }
            
            // Generate tokens with reduced weight
            let weight = baseWeight * WeightingModel.natalWeight
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight
            )
            
            // Sort by weight and apply strict limits
            let sortedTokens = planetTokens.sorted { $0.weight > $1.weight }
            tokens.append(contentsOf: Array(sortedTokens.prefix(maxTokens)))
        }
        
        // Add ONE Ascendant token
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign
        let ascTokens = tokenizeForPlanetInSign(
            planet: "Ascendant",
            sign: ascendantSign,
            isRetrograde: false,
            weight: 0.8 * WeightingModel.natalWeight
        )
        let sortedAscTokens = ascTokens.sorted { $0.weight > $1.weight }
        tokens.append(contentsOf: Array(sortedAscTokens.prefix(1)))
        
        // Only 4 angular house tokens
        for house in [1, 4, 7, 10] {
            let cuspLongitude = natal.houseCusps[house]
            let cuspSign = Int(cuspLongitude / 30.0) % 12 + 1
            let signName = CoordinateTransformations.getZodiacSignName(sign: cuspSign)
            
            let houseKeyword: String
            switch house {
            case 1:
                houseKeyword = "personal"
            case 4:
                houseKeyword = "foundational"
            case 7:
                houseKeyword = "relational"
            case 10:
                houseKeyword = "professional"
            default:
                houseKeyword = "structural"
            }
            
            tokens.append(StyleToken(
                name: houseKeyword,
                type: "structure",
                weight: 0.3 * WeightingModel.natalWeight,
                signSource: signName,
                houseSource: house,
                originType: .natal
            ))
        }
        
        // Log the limited token generation
        DebugLogger.info("📉 DAILY FIT LIMITED NATAL TOKENS:")
        DebugLogger.info("  • Total natal tokens: \(tokens.count) (limited from full Blueprint)")
        DebugLogger.info("  • Venus tokens: \(tokens.filter { $0.planetarySource == "Venus" }.count)")
        DebugLogger.info("  • Mars tokens: \(tokens.filter { $0.planetarySource == "Mars" }.count)")
        DebugLogger.info("  • Moon tokens: \(tokens.filter { $0.planetarySource == "Moon" }.count)")
        DebugLogger.info("  • House tokens: 4 (angular houses only)")
        
        return tokens
    }
    
    static func generateTransitTokens(
        transits: [[String: Any]],
        natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            for transit in transits {
                // Extract transit data
                let transitPlanet = transit["transitPlanet"] as? String ?? ""
                let natalPlanet = transit["natalPlanet"] as? String ?? ""
                let aspectType = transit["aspectType"] as? String ?? ""
                let orb = transit["orb"] as? Double ?? 1.0
                let isSensitivePoint = PlanetPowerEvaluator.isSensitiveTarget(natalPlanet: natalPlanet)
                
                // Get natal planet power score
                let natalPowerScore = getNatalPlanetPowerScore(natalPlanet, chart: natal)
                
                // Calculate transit weight using the specialized calculator
                let transitWeight = TransitWeightCalculator.calculateTransitWeight(
                    aspectType: aspectType,
                    orb: orb,
                    transitPlanet: transitPlanet,
                    natalPlanet: natalPlanet,
                    natalPowerScore: natalPowerScore,
                    hitsSensitivePoint: isSensitivePoint
                )
                
                // Enhanced threshold system for daily Moon movement
                let threshold: Double
                if transitPlanet == "Moon" {
                    threshold = 0.08  // Very low threshold for Moon transits (daily drivers)
                } else if transitPlanet == "Mercury" {
                    threshold = 0.12  // Low threshold for Mercury (weekly changes)
                } else {
                    threshold = 0.15  // Standard threshold for other planets
                }
                
                if transitWeight < threshold {
                    continue
                }
                
                // Apply WeightingModel transit weight with daily variation enhancements
                var adjustedTransitWeight: Double = transitWeight * WeightingModel.DailyFit.transitWeight
                
                // Special boost for daily drivers (Moon and fast-moving planets)
                if transitPlanet == "Moon" {
                    if orb < 0.5 {
                        adjustedTransitWeight *= 2.0  // Major boost for exact Moon aspects
                    } else if orb < 1.0 {
                        adjustedTransitWeight *= 1.6  // Good boost for close Moon aspects
                    } else {
                        adjustedTransitWeight *= 1.3  // Moderate boost for wider Moon aspects
                    }
                } else if transitPlanet == "Mercury" && orb < 1.5 {
                    adjustedTransitWeight *= 1.4  // Boost Mercury for daily mental shifts
                } else if (transitPlanet == "Venus" || transitPlanet == "Mars") && orb < 2.0 {
                    adjustedTransitWeight *= 1.2  // Moderate boost for personal planets
                }
                
                let finalAdjustedTransitWeight = adjustedTransitWeight
                
                // Get influence category and token weight scale
                let influenceCategory = TransitWeightCalculator.getStyleInfluenceCategory(weight: finalAdjustedTransitWeight)
                let tokenScale: Double = TransitWeightCalculator.getTokenWeightScale(for: influenceCategory)
                
                // Generate tokens based on the transit with aspect source tracking
                let aspectSource = "\(transitPlanet) \(aspectType) \(natalPlanet)"
                let finalWeight: Double = finalAdjustedTransitWeight * tokenScale
                let transitTokens = tokenizeForTransit(
                    transitPlanet: transitPlanet,
                    natalPlanet: natalPlanet,
                    aspectType: aspectType,
                    weight: finalWeight,
                    aspectSource: aspectSource)
                
                tokens.append(contentsOf: transitTokens)
            }
            
            // [KEEP ALL THE MULTI-TRANSIT ADJUSTMENT LOGIC AS-IS]
            // Group tokens by natal planet for multi-transit adjustment
            var tokensByNatalPlanet: [String: [StyleToken]] = [:]
            for token in tokens {
                if let aspectSource = token.aspectSource,
                   let natalPlanet = extractNatalPlanet(from: aspectSource) {
                    if tokensByNatalPlanet[natalPlanet] == nil {
                        tokensByNatalPlanet[natalPlanet] = []
                    }
                    tokensByNatalPlanet[natalPlanet]?.append(token)
                }
            }
            
            // Apply multi-transit adjustment for planets with multiple hits
            for (_, planetTokens) in tokensByNatalPlanet {
                if planetTokens.count > 1 {
                    let weights = planetTokens.map { $0.weight }
                    let combinedWeight = TransitWeightCalculator.calculateCombinedTransitWeight(
                        transitWeights: weights,
                        sameTargetPlanet: true
                    )
                    
                    // Adjust token weights
                    let adjustmentFactor = combinedWeight / weights.reduce(0, +)
                    for token in planetTokens {
                        // Find the token in the original array and adjust its weight
                        if let index = tokens.firstIndex(where: { $0.aspectSource == token.aspectSource }) {
                            tokens[index] = StyleToken(
                                name: token.name,
                                type: token.type,
                                weight: token.weight * adjustmentFactor,
                                planetarySource: token.planetarySource,
                                signSource: token.signSource,
                                houseSource: token.houseSource,
                                aspectSource: token.aspectSource,
                                originType: .transit
                            )
                        }
                    }
                }
            }
            
            return tokens
        }
    
    /// Generate daily signature tokens that provide temporal context and energy patterns
    /// based on day of week for Daily Fit output
    static func generateDailySignature() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate temporal rhythm tokens
        let calendar = Calendar.current
        let now = Date()
        let dayOfWeek = calendar.component(.weekday, from: now)
        
        // Apply WeightingModel daily signature weight
        let baseDailyWeight = WeightingModel.DailyFit.dailySignatureWeight
        
        // Day of week influence - Enhanced with more nuanced energy patterns
        switch dayOfWeek {
        case 1: // Sunday
            tokens.append(StyleToken(name: "relaxed", type: "mood", weight: 0.4 * baseDailyWeight, aspectSource: "Sunday Energy", originType: .phase))
        case 2: // Monday
            tokens.append(StyleToken(name: "fresh", type: "expression", weight: 0.5 * baseDailyWeight, aspectSource: "Monday Energy", originType: .phase))
        case 3: // Tuesday
            tokens.append(StyleToken(name: "dynamic", type: "expression", weight: 0.5 * baseDailyWeight, aspectSource: "Tuesday Energy", originType: .phase))
        case 4: // Wednesday
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: 0.4 * baseDailyWeight, aspectSource: "Wednesday Energy", originType: .phase))
        case 5: // Thursday
            tokens.append(StyleToken(name: "expansive", type: "mood", weight: 0.5 * baseDailyWeight, aspectSource: "Thursday Energy", originType: .phase))
        case 6: // Friday
            tokens.append(StyleToken(name: "social", type: "expression", weight: 0.5 * baseDailyWeight, aspectSource: "Friday Energy", originType: .phase))
        case 7: // Saturday
            tokens.append(StyleToken(name: "playful", type: "mood", weight: 0.4 * baseDailyWeight, aspectSource: "Saturday Energy", originType: .phase))
        default:
            break
        }
        
        // Add moon phase tokens for enhanced daily variation
        let moonPhaseTokens = generateMoonPhaseTokens()
        tokens.append(contentsOf: moonPhaseTokens)
        
        // Add seasonal micro-influence based on month - PRACTICAL ONLY
        let month = calendar.component(.month, from: now)
        switch month {
        case 3, 4, 5: // Spring
            tokens.append(StyleToken(
                name: "transitional",
                type: "structure", // Changed from any aesthetic type to structure
                weight: 0.2, // Minimal weight
                aspectSource: "Spring Practicality",
                originType: .phase
            ))
        case 6, 7, 8: // Summer
            tokens.append(StyleToken(
                name: "breathable",
                type: "fabric", // Practical fabric guidance only
                weight: 0.2,
                aspectSource: "Summer Practicality",
                originType: .phase
            ))
        case 9, 10, 11: // Autumn
            tokens.append(StyleToken(
                name: "layerable",
                type: "structure", // Practical structure guidance
                weight: 0.2,
                aspectSource: "Autumn Practicality",
                originType: .phase
            ))
        case 12, 1, 2: // Winter
            tokens.append(StyleToken(
                name: "insulating",
                type: "fabric", // Practical fabric guidance only
                weight: 0.2,
                aspectSource: "Winter Practicality",
                originType: .phase
            ))
        default:
            break
        }

        return tokens
    }
    
    /// Convenience method to generate all Daily Fit tokens in one call
    static func generateDailyFitTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> [StyleToken] {
        
        var allTokens: [StyleToken] = []
        
        DebugLogger.info("🌟 GENERATING COMPLETE DAILY FIT TOKEN SET 🌟")
        
        // Generate LIMITED natal tokens for Daily Fit (not full Blueprint tokens)
        let baseTokens = generateDailyFitNatalTokens(natal: natal)
        DebugLogger.tokenSet("BASE STYLE TOKENS (LIMITED FOR DAILY FIT)", baseTokens)
        allTokens.append(contentsOf: baseTokens)
        
        // Generate current Sun sign background energy tokens (REDUCED)
        let currentSunTokens = generateCurrentSunSignTokens()
        DebugLogger.tokenSet("CURRENT SUN SIGN BACKGROUND (REDUCED)", currentSunTokens)
        allTokens.append(contentsOf: currentSunTokens)
        
            // Generate LIMITED emotional vibe tokens
            let emotionalTokens = generateLimitedEmotionalVibeTokens(natal: natal, progressed: progressed)
            DebugLogger.tokenSet("EMOTIONAL VIBE TOKENS (LIMITED)", emotionalTokens)
            allTokens.append(contentsOf: emotionalTokens)
        
        // Generate transit tokens
        let transitTokens = generateTransitTokens(transits: transits, natal: natal)
        DebugLogger.tokenSet("TRANSIT TOKENS", transitTokens)
        allTokens.append(contentsOf: transitTokens)
        
        // Generate weather tokens (REDUCED)
        let weatherTokens = generateWeatherTokens(weather: weather)
        DebugLogger.tokenSet("WEATHER TOKENS (PRACTICAL ONLY)", weatherTokens)
        allTokens.append(contentsOf: weatherTokens)
        
        // Generate daily signature tokens (REDUCED SEASONAL)
        let dailyTokens = generateDailySignature()
        DebugLogger.tokenSet("DAILY SIGNATURE TOKENS", dailyTokens)
        allTokens.append(contentsOf: dailyTokens)
        
        DebugLogger.info("✅ Complete Daily Fit token set generated: \(allTokens.count) tokens")
        
        return allTokens
    }
    
    /// Generate enhanced emotional vibe tokens for Daily Fit - targeting ~30% progressed influence
    static func generateLimitedEmotionalVibeTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart) -> [StyleToken] {
        
        var tokens: [StyleToken] = []
        
        // Process major progressed planets with enhanced weights to achieve ~30% influence
        let progressedPlanets = ["Moon", "Sun", "Mercury", "Venus", "Mars"]
        
        for planetName in progressedPlanets {
            if let progressedPlanet = progressed.planets.first(where: { $0.name == planetName }) {
                
                // Enhanced weights based on planet importance for style expression
                let baseWeight: Double
                let maxTokens: Int
                
                switch planetName {
                case "Moon":
                    baseWeight = 0.6
                    maxTokens = 3
                case "Venus":
                    baseWeight = 0.5
                    maxTokens = 2
                case "Mars":
                    baseWeight = 0.4
                    maxTokens = 2
                case "Sun":
                    baseWeight = 0.8  // Core identity evolution
                    maxTokens = 3
                case "Mercury":
                    baseWeight = 0.7  // Communication and style expression evolution
                    maxTokens = 2
                default:
                    baseWeight = 0.5
                    maxTokens = 2
                }
                
                let progressedTokens = tokenizeForPlanetInSign(
                    planet: planetName,
                    sign: progressedPlanet.zodiacSign,
                    isRetrograde: progressedPlanet.isRetrograde,
                    weight: baseWeight,
                    isProgressed: true)
                
                // Take up to maxTokens, prioritizing higher weights
                let limitedTokens = Array(progressedTokens.prefix(maxTokens))
                tokens.append(contentsOf: limitedTokens)
            }
        }
        
        // Add progressed aspects if they exist (for additional nuance)
        if let progressedMoon = progressed.planets.first(where: { $0.name == "Moon" }),
           let progressedSun = progressed.planets.first(where: { $0.name == "Sun" }) {
            
            // Check for progressed Moon-Sun aspect evolution
            let moonSunAspect = calculateProgressedAspect(
                planet1: progressedMoon,
                planet2: progressedSun)
            
            if let aspectToken = generateProgressedAspectToken(
                aspect: moonSunAspect,
                weight: 0.5) {
                tokens.append(aspectToken)
            }
        }
        
        DebugLogger.info("🌙 PROGRESSED TOKENS GENERATED:")
        DebugLogger.info("  • Total progressed tokens: \(tokens.count)")
        DebugLogger.info("  • Total progressed weight: \(String(format: "%.2f", tokens.map { $0.weight }.reduce(0, +)))")
        DebugLogger.info("  • Average progressed weight: \(String(format: "%.2f", tokens.isEmpty ? 0 : tokens.map { $0.weight }.reduce(0, +) / Double(tokens.count)))")
        
        return tokens
    }

    // MARK: - Helper Methods for Progressed Chart Enhancement

    /// Calculate aspect between two progressed planets
    private static func calculateProgressedAspect(
        planet1: NatalChartCalculator.PlanetPosition,
        planet2: NatalChartCalculator.PlanetPosition) -> String? {
        
        let orb = abs(planet1.longitude - planet2.longitude)
        let normalizedOrb = min(orb, 360 - orb)
        
        // Only return major aspects with tight orbs for progressed
        if normalizedOrb <= 3 {
            return "conjunction"
        } else if abs(normalizedOrb - 60) <= 2 {
            return "sextile"
        } else if abs(normalizedOrb - 90) <= 2 {
            return "square"
        } else if abs(normalizedOrb - 120) <= 2 {
            return "trine"
        } else if abs(normalizedOrb - 180) <= 2 {
            return "opposition"
        }
        
        return nil
    }

    /// Generate a token from a progressed aspect
    private static func generateProgressedAspectToken(
        aspect: String?,
        weight: Double) -> StyleToken? {
        
        guard let aspect = aspect else { return nil }
        
        let tokenName: String
        let tokenType: String
        
        switch aspect {
        case "conjunction":
            tokenName = "unified"
            tokenType = "mood"
        case "sextile":
            tokenName = "harmonious"
            tokenType = "mood"
        case "square":
            tokenName = "dynamic"
            tokenType = "expression"
        case "trine":
            tokenName = "flowing"
            tokenType = "structure"
        case "opposition":
            tokenName = "balanced"
            tokenType = "expression"
        default:
            return nil
        }
        
        return StyleToken(
            name: tokenName,
            type: tokenType,
            weight: weight,
            aspectSource: "Progressed \(aspect.capitalized)",
            originType: .progressed)
    }
    
    /// Generate current Sun sign background energy tokens
    static func generateCurrentSunSignBackgroundTokens() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        
        // Determine current Sun sign based on date
        let currentSunSign = getCurrentSunSign(month: month, day: day)
        
        DebugLogger.info("🌞 CURRENT SUN SIGN BACKGROUND ENERGY:")
        DebugLogger.info("  • Current Sun in: \(currentSunSign)")
        DebugLogger.info("  • Background tokens generated: 4")
        DebugLogger.info("  • Background weight applied: \(WeightingModel.currentSunSignBackgroundWeight)")
        
        // Generate background energy tokens for current Sun sign
        let backgroundTokens = getCurrentSunSignBackgroundTokens(sunSign: currentSunSign)
        
        for (tokenName, tokenType) in backgroundTokens {
            tokens.append(StyleToken(
                name: tokenName,
                type: tokenType,
                weight: WeightingModel.currentSunSignBackgroundWeight,
                planetarySource: "CurrentSun",
                signSource: currentSunSign,
                originType: .currentSun
            ))
        }
        
        return tokens
    }
    
    /// Generate Moon phase energy tokens
    static func generateMoonPhaseTokens() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Calculate current moon phase
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        
        // Convert lunar phase to percentage for easier processing
        let phasePercentage = (lunarPhase / 360.0) * 100.0
        
        // Apply WeightingModel moon phase weight
        let basePhaseWeight = WeightingModel.DailyFit.moonPhaseWeight
        
        // Generate tokens based on moon phase
        switch phasePercentage {
        case 0...12.5: // New Moon
            tokens.append(StyleToken(name: "minimal", type: "structure", weight: 1.5 * basePhaseWeight, aspectSource: "New Moon", originType: .phase))
            tokens.append(StyleToken(name: "introspective", type: "mood", weight: 1.3 * basePhaseWeight, aspectSource: "New Moon", originType: .phase))
            tokens.append(StyleToken(name: "dark", type: "color", weight: 1.0 * basePhaseWeight, aspectSource: "New Moon", originType: .phase))
        case 12.5...37.5: // Waxing Crescent
            tokens.append(StyleToken(name: "emerging", type: "expression", weight: 1.2 * basePhaseWeight, aspectSource: "Waxing Crescent", originType: .phase))
            tokens.append(StyleToken(name: "hopeful", type: "mood", weight: 1.0 * basePhaseWeight, aspectSource: "Waxing Crescent", originType: .phase))
            tokens.append(StyleToken(name: "subtle", type: "color_quality", weight: 0.8 * basePhaseWeight, aspectSource: "Waxing Crescent", originType: .phase))
        case 37.5...62.5: // First Quarter
            tokens.append(StyleToken(name: "decisive", type: "expression", weight: 1.4 * basePhaseWeight, aspectSource: "First Quarter", originType: .phase))
            tokens.append(StyleToken(name: "bold", type: "color_quality", weight: 1.2 * basePhaseWeight, aspectSource: "First Quarter", originType: .phase))
            tokens.append(StyleToken(name: "structured", type: "structure", weight: 1.0 * basePhaseWeight, aspectSource: "First Quarter", originType: .phase))
        case 62.5...87.5: // Waxing Gibbous
            tokens.append(StyleToken(name: "refined", type: "expression", weight: 1.3 * basePhaseWeight, aspectSource: "Waxing Gibbous", originType: .phase))
            tokens.append(StyleToken(name: "perfecting", type: "mood", weight: 1.1 * basePhaseWeight, aspectSource: "Waxing Gibbous", originType: .phase))
            tokens.append(StyleToken(name: "polished", type: "texture", weight: 0.9 * basePhaseWeight, aspectSource: "Waxing Gibbous", originType: .phase))
        case 87.5...100, 0...12.5: // Full Moon (including overlap)
            tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: 1.8 * basePhaseWeight, aspectSource: "Full Moon", originType: .phase))
            tokens.append(StyleToken(name: "expressive", type: "expression", weight: 1.6 * basePhaseWeight, aspectSource: "Full Moon", originType: .phase))
            tokens.append(StyleToken(name: "luminous", type: "texture", weight: 1.4 * basePhaseWeight, aspectSource: "Full Moon", originType: .phase))
        default: // Waning phases
            tokens.append(StyleToken(name: "wise", type: "mood", weight: 1.2 * basePhaseWeight, aspectSource: "Waning Moon", originType: .phase))
            tokens.append(StyleToken(name: "reflective", type: "expression", weight: 1.0 * basePhaseWeight, aspectSource: "Waning Moon", originType: .phase))
            tokens.append(StyleToken(name: "muted", type: "color_quality", weight: 0.8 * basePhaseWeight, aspectSource: "Waning Moon", originType: .phase))
        }
        
        return tokens
    }
    
    /// Generate base style resonance tokens using natal chart
    private static func generateBaseStyleTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return generateBlueprintTokens(natal: natal)
    }
  
    /*
    /// Convenience method to generate all Daily Fit tokens in one call
    static func generateDailyFitTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> [StyleToken] {
            
            var allTokens: [StyleToken] = []
            
            DebugLogger.info("🌟 GENERATING COMPLETE DAILY FIT TOKEN SET 🌟")
            
            // Generate base style tokens
            let baseTokens = generateBlueprintTokens(natal: natal)
            DebugLogger.tokenSet("BASE STYLE TOKENS", baseTokens)
            allTokens.append(contentsOf: baseTokens)
            
            //Generate current Sun sign background energy tokens ***
            let currentSunTokens = generateCurrentSunSignTokens()
            DebugLogger.tokenSet("CURRENT SUN SIGN BACKGROUND", currentSunTokens)
            allTokens.append(contentsOf: currentSunTokens)
            
            // Generate emotional vibe tokens
            let emotionalTokens = generateEmotionalVibeTokens(natal: natal, progressed: progressed)
            DebugLogger.tokenSet("EMOTIONAL VIBE TOKENS", emotionalTokens)
            allTokens.append(contentsOf: emotionalTokens)
            
            // Generate transit tokens
            let transitTokens = generateTransitTokens(transits: transits, natal: natal)
            DebugLogger.tokenSet("TRANSIT TOKENS", transitTokens)
            allTokens.append(contentsOf: transitTokens)
            
            // Generate weather tokens
            let weatherTokens = generateWeatherTokens(weather: weather)
            DebugLogger.tokenSet("WEATHER TOKENS", weatherTokens)
            allTokens.append(contentsOf: weatherTokens)
            
            // Generate daily signature tokens
            let dailyTokens = generateDailySignature()
            DebugLogger.tokenSet("DAILY SIGNATURE TOKENS", dailyTokens)
            allTokens.append(contentsOf: dailyTokens)
            
            DebugLogger.info("✅ Complete Daily Fit token set generated: \(allTokens.count) tokens")
            
            return allTokens
        }
     */
    
    /// Generate tokens for the current Sun sign as a subtle background energy
    static func generateCurrentSunSignTokens() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Calculate current Sun position
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let sunPosition = AstronomicalCalculator.calculateSunPosition(julianDay: currentJulianDay)
        let (currentSunSign, _) = CoordinateTransformations.decimalDegreesToZodiac(sunPosition.longitude)
        let currentSunSignName = CoordinateTransformations.getZodiacSignName(sign: currentSunSign)
        
        // REDUCED weight for background energy
        let backgroundWeight = WeightingModel.currentSunSignBackgroundWeight * 0.6 // Further reduced
        
        // Generate ONLY energy/mood tokens, no color_quality tokens
        let sunSignTokens = tokenizeForCurrentSunSign(
            sign: currentSunSign,
            signName: currentSunSignName,
            weight: backgroundWeight
        )
        
        // Filter out any color_quality tokens to prevent seasonal aesthetic override
        let filteredTokens = sunSignTokens.filter { token in
            token.type != "color_quality" && token.type != "color"
        }
        
        tokens.append(contentsOf: filteredTokens)
        
        DebugLogger.info("🌞 CURRENT SUN SIGN BACKGROUND (REDUCED):")
        DebugLogger.info("  • Current Sun in: \(currentSunSignName)")
        DebugLogger.info("  • Background tokens generated: \(filteredTokens.count)")
        DebugLogger.info("  • Reduced weight applied: \(backgroundWeight)")
        
        return tokens
    }
    
    /// Generate style tokens for the current Sun sign as background energy
    private static func tokenizeForCurrentSunSign(
        sign: Int,
        signName: String,
        weight: Double) -> [StyleToken] {
            
        var tokens: [StyleToken] = []
        
        // Get Sun in sign tokens from the text library
        if let tokenDescriptions = InterpretationTextLibrary.TokenGeneration.PlanetInSign.Sun.descriptions[signName] {
            for (tokenName, tokenType) in tokenDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: weight,
                    planetarySource: "CurrentSun",
                    signSource: signName,
                    aspectSource: "Current Sun in \(signName)",
                    originType: .currentSun
                ))
            }
        }
        
        return tokens
    }
    
    // MARK: - Transit Token Helper Methods
    
    /// Generate style tokens for a specific transit
    private static func generateTransitStyleTokens(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String,
        baseWeight: Double,
        aspectSource: String) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Generate tokens based on transit planet energy
            switch transitPlanet {
            case "Sun":
                tokens.append(contentsOf: generateSunTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Moon":
                tokens.append(contentsOf: generateMoonTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Mercury":
                tokens.append(contentsOf: generateMercuryTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Venus":
                tokens.append(contentsOf: generateVenusTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Mars":
                tokens.append(contentsOf: generateMarsTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Jupiter":
                tokens.append(contentsOf: generateJupiterTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Saturn":
                tokens.append(contentsOf: generateSaturnTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Uranus":
                tokens.append(contentsOf: generateUranusTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Neptune":
                tokens.append(contentsOf: generateNeptuneTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Pluto":
                tokens.append(contentsOf: generatePlutoTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            default:
                tokens.append(contentsOf: generateOtherTransitTokens(transitPlanet: transitPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            }
            
            return tokens
        }
    
    // MARK: - Individual Planet Transit Token Generators
    
    private static func generateSunTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "confident", type: "expression", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "creative", type: "mood", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "authoritative", type: "structure", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "bold", type: "expression", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "dramatic", type: "structure", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "challenging", type: "mood", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "warm", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "expressive", type: "expression", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateMoonTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "flowing", type: "structure", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "soft", type: "texture", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "nurturing", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "comfortable", type: "expression", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "changeable", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "protective", type: "structure", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "emotional", type: "expression", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "intuitive", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "responsive", type: "expression", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateMercuryTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "articulate", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "precise", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "clever", type: "mood", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "scattered", type: "mood", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "restless", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "complex", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "communicative", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "detailed", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateVenusTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "harmonious", type: "mood", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "beautiful", type: "expression", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "luxurious", type: "texture", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "dramatic", type: "expression", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "indulgent", type: "texture", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "pleasing", type: "mood", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateMarsTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "dynamic", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "energetic", type: "mood", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "sharp", type: "structure", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "aggressive", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "intense", type: "mood", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "assertive", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateJupiterTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "generous", type: "structure", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "optimistic", type: "mood", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "expansive", type: "expression", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "excessive", type: "structure", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "dramatic", type: "expression", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "optimistic", type: "mood", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateSaturnTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "structured", type: "structure", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "disciplined", type: "expression", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "refined", type: "texture", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "restrictive", type: "structure", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "serious", type: "mood", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "conservative", type: "expression", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateUranusTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "innovative", type: "expression", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "unconventional", type: "structure", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "electric", type: "color_quality", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "rebellious", type: "expression", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "disruptive", type: "mood", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "unique", type: "expression", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateNeptuneTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "dreamy", type: "mood", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "ethereal", type: "texture", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "flowing", type: "structure", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "confused", type: "mood", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "elusive", type: "expression", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "mystical", type: "mood", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generatePlutoTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "transformative", type: "expression", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "powerful", type: "mood", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "intense", type: "texture", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "obsessive", type: "mood", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "extreme", type: "expression", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
        default:
            tokens.append(StyleToken(name: "magnetic", type: "expression", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateOtherTransitTokens(transitPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generic fallback tokens
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "harmonious", type: "mood", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "dynamic", type: "expression", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
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
    
    /// Check if a planet is considered fast-moving
    private static func isFastPlanet(_ planet: String) -> Bool {
        return ["Moon", "Mercury", "Venus", "Sun", "Mars"].contains(planet)
    }
    
    // MARK: - Color Frequency Token Generation
    
    /// Generate tokens for Color Frequency section using WeightingModel weights
    static func generateColorFrequencyTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Normalized weights for natal vs progressed (natal + progressed = 0.70 total)
            let totalWeight = WeightingModel.natalWeight + WeightingModel.progressedWeight
            let normalizedNatalWeight = WeightingModel.natalWeight / totalWeight
            let normalizedProgressedWeight = WeightingModel.progressedWeight / totalWeight
            
            // Generate natal tokens with normalized weight
            let natalTokens = generateNatalColorTokens(natal, currentAge: currentAge)
            for token in natalTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * normalizedNatalWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .natal
                )
                tokens.append(adjustedToken)
            }
            
            // Generate progressed tokens with normalized weight
            let progressedTokens = generateProgressedColorTokens(progressed)
            for token in progressedTokens {
                // Skip tokens that introduce new colors - only keep modulating tokens
                if token.type == "color" {
                    continue
                }
                
                // Keep only tokens that modulate finish, tone, and pairing logic
                if ["texture", "color_quality", "structure"].contains(token.type) {
                    let adjustedToken = StyleToken(
                        name: token.name,
                        type: token.type,
                        weight: token.weight * normalizedProgressedWeight,
                        planetarySource: token.planetarySource,
                        signSource: token.signSource,
                        houseSource: token.houseSource,
                        aspectSource: token.aspectSource,
                        originType: .progressed
                    )
                    tokens.append(adjustedToken)
                }
            }
            
            return tokens
        }
    
    /*
     /// Generate tokens for base style resonance (100% natal, Whole Sign)
     static func generateBaseStyleTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
     return generateBlueprintTokens(natal: natal)
     }
     */
    
    /// Generate tokens for emotional vibe of the day using WeightingModel weights
    static func generateEmotionalVibeTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Normalized weights for natal vs progressed
            let totalWeight = WeightingModel.natalWeight + WeightingModel.progressedWeight
            let normalizedNatalWeight = WeightingModel.natalWeight / totalWeight
            let normalizedProgressedWeight = WeightingModel.progressedWeight / totalWeight
            
            // Find natal Moon
            if let natalMoon = natal.planets.first(where: { $0.name == "Moon" }) {
                let natalMoonTokens = tokenizeForPlanetInSign(
                    planet: "Moon",
                    sign: natalMoon.zodiacSign,
                    isRetrograde: natalMoon.isRetrograde,
                    weight: 2.0 * normalizedNatalWeight)
                tokens.append(contentsOf: natalMoonTokens)
            }
            
            // Find progressed Moon
            if let progressedMoon = progressed.planets.first(where: { $0.name == "Moon" }) {
                let progressedMoonTokens = tokenizeForPlanetInSign(
                    planet: "Moon",
                    sign: progressedMoon.zodiacSign,
                    isRetrograde: progressedMoon.isRetrograde,
                    weight: 2.0 * normalizedProgressedWeight,
                    isProgressed: true)
                tokens.append(contentsOf: progressedMoonTokens)
            }
            
            return tokens
        }
    
    // MARK: - Wardrobe Storyline Token Generation
    
    /// Generate tokens for Wardrobe Storyline using WeightingModel weights
    static func generateWardrobeStorylineTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> [StyleToken] {
            var tokens: [StyleToken] = []
            
            // Normalized weights for natal vs progressed
            let totalWeight = WeightingModel.natalWeight + WeightingModel.progressedWeight
            let normalizedNatalWeight = WeightingModel.natalWeight / totalWeight
            let normalizedProgressedWeight = WeightingModel.progressedWeight / totalWeight
            
            // Generate natal tokens with normalized weight using Whole Sign
            let natalTokens = generateBlueprintTokens(natal: natal, currentAge: currentAge)
            for token in natalTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * normalizedNatalWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .natal
                )
                tokens.append(adjustedToken)
            }
            
            // Generate progressed tokens with normalized weight using Placidus house system
            let progressedTokens = generateProgressedTokensForWardrobeStoryline(progressed)
            for token in progressedTokens {
                if ["texture", "color_quality", "structure", "mood", "expression"].contains(token.type) {
                    let adjustedToken = StyleToken(
                        name: token.name,
                        type: token.type,
                        weight: token.weight * normalizedProgressedWeight,
                        planetarySource: token.planetarySource,
                        signSource: token.signSource,
                        houseSource: token.houseSource,
                        aspectSource: token.aspectSource,
                        originType: .progressed
                    )
                    tokens.append(adjustedToken)
                }
            }
            
            return tokens
        }
    
    // MARK: - Style Pulse Token Generation
    
    /// Generate tokens for Style Pulse using WeightingModel weights
    static func generateStylePulseTokens(natal: NatalChartCalculator.NatalChart,
                                         progressed: NatalChartCalculator.NatalChart,
                                         currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Normalized weights for natal vs progressed - Style Pulse is heavily natal-focused
        let totalWeight = WeightingModel.natalWeight + WeightingModel.progressedWeight
        let normalizedNatalWeight = WeightingModel.natalWeight / totalWeight
        let normalizedProgressedWeight = WeightingModel.progressedWeight / totalWeight
        
        // Weight heavily towards natal (90% equivalent)
        let styleNatalWeight = normalizedNatalWeight * 0.9 / normalizedNatalWeight
        let styleProgressedWeight = normalizedProgressedWeight * 0.1 / normalizedProgressedWeight
        
        // Generate natal tokens with heavy weighting
        let natalTokens = generateBlueprintTokens(natal: natal, currentAge: currentAge)
        for token in natalTokens {
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * styleNatalWeight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .natal
            )
            tokens.append(adjustedToken)
        }
        
        // Add just a flavor of progressed chart (10% equivalent)
        for planet in progressed.planets {
            if planet.name == "Moon" || planet.name == "Venus" {
                let flavorTokens = tokenizeForPlanetInSign(
                    planet: planet.name,
                    sign: planet.zodiacSign,
                    isRetrograde: planet.isRetrograde,
                    weight: 1.0,
                    isProgressed: true)
                
                for token in flavorTokens {
                    if ["texture", "color_quality", "structure"].contains(token.type) {
                        let modulatingToken = StyleToken(
                            name: token.name,
                            type: token.type,
                            weight: token.weight * styleProgressedWeight,
                            planetarySource: token.planetarySource,
                            signSource: token.signSource,
                            houseSource: token.houseSource,
                            aspectSource: token.aspectSource,
                            originType: .progressed
                        )
                        tokens.append(modulatingToken)
                    }
                }
            }
        }
        
        return tokens
    }
    
    // MARK: - Transit Token Generation
    
    // MARK: - Helper Methods
    
    /// Generate tokens for a planet in a specific sign with source tracking
    static func tokenizeForPlanetInSign(
        planet: String,
        sign: Int,
        isRetrograde: Bool,
        weight: Double,
        isProgressed: Bool = false) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Get zodiac sign name
            let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
            let planetSource = isProgressed ? "Progressed \(planet)" : planet
            let originType: OriginType = isProgressed ? .progressed : .natal
            
            // Generate tokens based on planet and sign using library
            if let planetDescriptions = getPlanetSignDescriptions(planet: planet, signName: signName) {
                var currentWeight = weight
                for (tokenName, tokenType) in planetDescriptions {
                    tokens.append(StyleToken(
                        name: tokenName,
                        type: tokenType,
                        weight: currentWeight,
                        planetarySource: planetSource,
                        signSource: signName,
                        originType: originType
                    ))
                    currentWeight -= 0.1
                }
            } else {
                // Fallback to elemental tokens using library
                let elementalTokens = getElementalFallbackTokens(signName: signName)
                var currentWeight = weight * 0.8
                for (tokenName, tokenType) in elementalTokens {
                    tokens.append(StyleToken(
                        name: tokenName,
                        type: tokenType,
                        weight: currentWeight,
                        planetarySource: planetSource,
                        signSource: signName,
                        originType: originType
                    ))
                    currentWeight -= 0.1
                }
            }
            
            // Add retrograde tokens if applicable
            if isRetrograde {
                if let retrogradeTokens = getRetrogradeTokens(planet: planet) {
                    var retroWeight = weight * 0.6
                    for (tokenName, tokenType) in retrogradeTokens {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: retroWeight,
                            planetarySource: planetSource,
                            signSource: signName,
                            aspectSource: "Retrograde",
                            originType: originType
                        ))
                        retroWeight -= 0.1
                    }
                }
            }
            
            // LIMIT TOKEN GENERATION to prevent natal dominance
            // Determine max tokens based on planet importance
            let maxTokens: Int
            switch planet {
            case "Venus", "Mars", "Moon":
                maxTokens = 4 // Expression planets get more tokens (priority planets)
            case "Sun":
                maxTokens = 3 // Core identity gets moderate tokens
            case "Mercury", "Ascendant":
                maxTokens = 3 // Communication/appearance planets
            case "Jupiter", "Saturn":
                maxTokens = 2 // Social planets get fewer tokens
            case "Uranus", "Neptune", "Pluto":
                maxTokens = 1 // Outer planets get minimal tokens
            case let p where p.contains("Progressed"):
                // Progressed planets get limited tokens
                if p.contains("Moon") {
                    maxTokens = 3 // Progressed Moon is important
                } else {
                    maxTokens = 2 // Other progressed planets
                }
            default:
                maxTokens = 1 // Any other celestial bodies (Chiron, etc.)
            }
            
            // Sort tokens by weight (highest first) and limit to maxTokens
            tokens = tokens.sorted { $0.weight > $1.weight }
            
            // Apply the limit
            if tokens.count > maxTokens {
                tokens = Array(tokens.prefix(maxTokens))
                
                // Debug logging for token limiting
                DebugLogger.info("  ⚠️ Token limiting applied for \(planet): \(tokens.count) tokens (was unlimited)")
            }
            
            return tokens
        }
    
    /// Generate specialized color tokens from natal chart
    private static func generateNatalColorTokens(_ chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets with focus on color attributes
        for planet in chart.planets {
            let baseWeight: Double = 2.0
            var priorityMultiplier: Double = 1.0
            
            switch planet.name {
            case "Venus": priorityMultiplier = 1.6
            case "Moon": priorityMultiplier = 1.4
            case "Sun": priorityMultiplier = 1.2
            case "Mars": priorityMultiplier = 1.1
            case "Neptune": priorityMultiplier = 1.0
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            let colorTokens = generateColorTokensForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                weight: weight,
                isRetrograde: planet.isRetrograde)
            
            let ageWeightedTokens = colorTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedTokens)
        }
        
        // Process ascendant for color tokens
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascendantSign)
        
        let ascendantColorTokens = generateColorTokensForAscendant(
            sign: ascendantSign,
            signName: ascSignName,
            weight: 2.5)
        
        let ageWeightedAscTokens = ascendantColorTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAscTokens)
        
        let elementalTokens = generateElementalColorTokens(chart: chart)
        tokens.append(contentsOf: elementalTokens)
        
        let aspectColorTokens = generateAspectColorTokens(chart: chart)
        tokens.append(contentsOf: aspectColorTokens)
        
        tokens.append(contentsOf: generateColorNuanceFromAspects(chart: chart))
        tokens.append(contentsOf: generateColorTokensFromDignities(chart: chart))
        
        return tokens
    }
    
    /// Generate color tokens from progressed chart
    private static func generateProgressedColorTokens(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        let relevantPlanets = ["Moon", "Venus", "Sun"]
        
        for planet in chart.planets where relevantPlanets.contains(planet.name) {
            let baseWeight: Double = 1.8
            
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Venus": priorityMultiplier = 1.5
            case "Moon": priorityMultiplier = 1.3
            case "Sun": priorityMultiplier = 1.2
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            let colorTokens = generateColorTokensForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                weight: weight,
                isProgressed: true)
            
            tokens.append(contentsOf: colorTokens)
        }
        
        tokens.append(StyleToken(
            name: "evolving",
            type: "color_quality",
            weight: 1.5,
            planetarySource: "Progressed Chart",
            aspectSource: "Current Progression"
        ))
        
        tokens.append(StyleToken(
            name: "transitional",
            type: "color_quality",
            weight: 1.3,
            planetarySource: "Progressed Chart",
            aspectSource: "Current Progression"
        ))
        
        return tokens
    }
    
    private static func generateProgressedTokensForWardrobeStoryline(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        for planet in chart.planets {
            let baseWeight: Double = 1.8
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Moon": priorityMultiplier = 1.4
            case "Venus": priorityMultiplier = 1.3
            case "Sun": priorityMultiplier = 1.2
            case "Mars": priorityMultiplier = 1.1
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight,
                isProgressed: true)
            
            tokens.append(contentsOf: planetTokens)
        }
        
        let progressedAscendantSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: progressedAscendantSign)
        
        tokens.append(StyleToken(
            name: "evolving",
            type: "expression",
            weight: 2.0,
            planetarySource: "Progressed Ascendant",
            signSource: ascSignName
        ))
        
        return tokens
    }
    
    // MARK: - Weather Token Generation
    
    /// Generate enhanced weather tokens for meaningful daily variation
    static func generateWeatherTokens(weather: TodayWeather?) -> [StyleToken] {
        guard let weather = weather else { 
            // Return minimal fallback tokens to prevent 0% weather influence
            return [
                StyleToken(name: "adaptable", type: "structure", weight: 0.4, originType: .weather),
                StyleToken(name: "versatile", type: "expression", weight: 0.3, originType: .weather)
            ]
        }
        
        var tokens: [StyleToken] = []
        
        // Base weight for weather influence (reduced to prevent excessive stacking)
        let baseWeatherWeight = WeightingModel.DailyFit.weatherWeight * 1.5
        let tempWeight = calculateTemperatureWeight(temp: weather.temperature)
        
        // TEMPERATURE INFLUENCE - Enhanced for daily variation
        if weather.temperature > 25 { // Hot weather
            tokens.append(StyleToken(name: "breathable", type: "fabric", weight: tempWeight * baseWeatherWeight * 1.5, originType: .weather))
            tokens.append(StyleToken(name: "lightweight", type: "structure", weight: tempWeight * baseWeatherWeight * 1.2, originType: .weather))
            tokens.append(StyleToken(name: "flowing", type: "structure", weight: tempWeight * baseWeatherWeight, originType: .weather))
            tokens.append(StyleToken(name: "cooling", type: "mood", weight: tempWeight * baseWeatherWeight * 0.8, originType: .weather))
            
        } else if weather.temperature < 10 { // Cold weather
            tokens.append(StyleToken(name: "insulating", type: "fabric", weight: tempWeight * baseWeatherWeight * 1.5, originType: .weather))
            tokens.append(StyleToken(name: "layerable", type: "structure", weight: tempWeight * baseWeatherWeight * 1.3, originType: .weather))
            tokens.append(StyleToken(name: "warming", type: "mood", weight: tempWeight * baseWeatherWeight, originType: .weather))
            tokens.append(StyleToken(name: "cozy", type: "texture", weight: tempWeight * baseWeatherWeight, originType: .weather))
            
        } else { // Moderate temperature
            tokens.append(StyleToken(name: "comfortable", type: "mood", weight: tempWeight * baseWeatherWeight * 0.8, originType: .weather))
            tokens.append(StyleToken(name: "balanced", type: "structure", weight: tempWeight * baseWeatherWeight * 0.6, originType: .weather))
        }
        
        // CONDITION INFLUENCE - Enhanced for daily mood variation
        let condition = weather.condition.lowercased()
        let conditionWeight = baseWeatherWeight * 1.2
        
        if condition.contains("clear") || condition.contains("sunny") {
            tokens.append(StyleToken(name: "radiant", type: "mood", weight: conditionWeight, originType: .weather))
            tokens.append(StyleToken(name: "confident", type: "expression", weight: conditionWeight * 0.8, originType: .weather))
            
        } else if condition.contains("cloudy") || condition.contains("overcast") {
            tokens.append(StyleToken(name: "subdued", type: "mood", weight: conditionWeight, originType: .weather))
            tokens.append(StyleToken(name: "introspective", type: "expression", weight: conditionWeight * 0.7, originType: .weather))
            
        } else if condition.contains("rain") || condition.contains("shower") {
            tokens.append(StyleToken(name: "protective", type: "structure", weight: conditionWeight * 1.3, originType: .weather))
            tokens.append(StyleToken(name: "waterproof", type: "fabric", weight: conditionWeight * 1.5, originType: .weather))
            tokens.append(StyleToken(name: "contemplative", type: "mood", weight: conditionWeight * 0.8, originType: .weather))
            
        } else if condition.contains("storm") || condition.contains("thunder") {
            tokens.append(StyleToken(name: "dramatic", type: "expression", weight: conditionWeight * 1.4, originType: .weather))
            tokens.append(StyleToken(name: "powerful", type: "mood", weight: conditionWeight * 1.2, originType: .weather))
            tokens.append(StyleToken(name: "secure", type: "structure", weight: conditionWeight * 1.1, originType: .weather))
        }
        
        // WIND INFLUENCE
        if weather.windKph > 20 {
            let windWeight = (weather.windKph / 50.0) * baseWeatherWeight
            tokens.append(StyleToken(name: "wind-resistant", type: "fabric", weight: windWeight * 1.3, originType: .weather))
            tokens.append(StyleToken(name: "structured", type: "structure", weight: windWeight * 1.1, originType: .weather))
            tokens.append(StyleToken(name: "dynamic", type: "expression", weight: windWeight * 0.9, originType: .weather))
        }
        
        return tokens
    }
    
    private static func calculateTemperatureWeight(temp: Double) -> Double {
        // Sophisticated temperature weight calculation
        let deviation = abs(temp - 20.0) // 20°C as ideal
        return min(3.0, 1.0 + (deviation / 10.0))
    }
    
    /// Generate tokens from house cusps based on the signs on each house cusp
    /// Uses Placidus house system for precise cusp calculations
    private static func generateHouseCuspTokens(chart: NatalChartCalculator.NatalChart, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process each house cusp (1-12)
        for houseNumber in 1...12 {
            let cuspLongitude = chart.houseCusps[houseNumber]
            let cuspSign = Int(cuspLongitude / 30.0) % 12 + 1
            let signName = CoordinateTransformations.getZodiacSignName(sign: cuspSign)
            
            // Determine house type and base weight
            let houseType = getHouseType(houseNumber: houseNumber)
            let baseWeight = getHouseWeight(houseNumber: houseNumber, houseType: houseType) * weight
            
            // Generate tokens based on house significance and sign combination
            let houseTokens = generateTokensForHouseCusp(
                houseNumber: houseNumber,
                signName: signName,
                houseType: houseType,
                baseWeight: baseWeight
            )
            
            tokens.append(contentsOf: houseTokens)
            
            // Add angular house emphasis tokens for most important houses
            if houseType == .angular {
                let angularTokens = generateAngularHouseTokens(
                    houseNumber: houseNumber,
                    signName: signName,
                    weight: baseWeight * 0.8
                )
                tokens.append(contentsOf: angularTokens)
            }
        }
        
        return tokens
    }
    
    /// Determine the type of house (angular, succedent, cadent)
    private static func getHouseType(houseNumber: Int) -> HouseType {
        switch houseNumber {
        case 1, 4, 7, 10:    return .angular     // Most important - ASC, IC, DSC, MC
        case 2, 5, 8, 11:    return .succedent   // Fixed, stable energy
        case 3, 6, 9, 12:    return .cadent      // Mutable, transitional energy
        default:             return .cadent
        }
    }
    
    /// Calculate weight multiplier based on house importance
    private static func getHouseWeight(houseNumber: Int, houseType: HouseType) -> Double {
        switch houseType {
        case .angular:
            // Angular houses get highest weight, with 1st and 10th being most prominent
            switch houseNumber {
            case 1:  return 1.0    // Ascendant - identity and appearance
            case 10: return 0.9    // Midheaven - public image and reputation
            case 7:  return 0.8    // Descendant - partnerships and others' perception
            case 4:  return 0.7    // IC - roots and private self
            default: return 0.7
            }
        case .succedent:
            // Succedent houses moderate weight
            switch houseNumber {
            case 2:  return 0.6    // Values and resources - affects style choices
            case 5:  return 0.5    // Creativity and self-expression
            case 8:  return 0.4    // Transformation style
            case 11: return 0.4    // Groups and aspirations
            default: return 0.5
            }
        case .cadent:
            // Cadent houses lighter weight but still influential
            switch houseNumber {
            case 3:  return 0.4    // Communication style
            case 6:  return 0.5    // Daily routine and health - practical style
            case 9:  return 0.3    // Philosophy and expansion
            case 12: return 0.3    // Subconscious expression
            default: return 0.3
            }
        }
    }
    
    /// Generate specific tokens for a house cusp based on house meaning + sign combination
    private static func generateTokensForHouseCusp(
        houseNumber: Int,
        signName: String,
        houseType: HouseType,
        baseWeight: Double
    ) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Get house-specific style influence
        let houseInfluence = getHouseStyleInfluence(houseNumber: houseNumber)
        let signTokens = getSignTokensForHouse(signName: signName, houseNumber: houseNumber)
        
        // Combine house meaning with sign expression
        for (tokenName, tokenType) in signTokens {
            let adjustedWeight = baseWeight * getTokenTypeMultiplier(tokenType: tokenType, houseNumber: houseNumber)
            
            tokens.append(StyleToken(
                name: tokenName,
                type: tokenType,
                weight: adjustedWeight,
                signSource: signName,
                houseSource: houseNumber,
                originType: .natal
            ))
        }
        
        // Add house-specific structural tokens
        if let structuralToken = houseInfluence.structural {
            tokens.append(StyleToken(
                name: structuralToken,
                type: "structure",
                weight: baseWeight * 0.8,
                houseSource: houseNumber,
                originType: .natal
            ))
        }
        
        return tokens
    }
    
    /// Generate specialized tokens for angular houses (most visible influence)
    private static func generateAngularHouseTokens(
        houseNumber: Int,
        signName: String,
        weight: Double
    ) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch houseNumber {
        case 1: // Ascendant - Primary identity and first impressions
            tokens.append(StyleToken(
                name: "defining",
                type: "expression",
                weight: weight,
                signSource: signName,
                houseSource: 1,
                originType: .natal
            ))
            tokens.append(StyleToken(
                name: "visible",
                type: "structure",
                weight: weight * 0.9,
                signSource: signName,
                houseSource: 1,
                originType: .natal
            ))
            
        case 4: // IC - Private self and emotional foundation
            tokens.append(StyleToken(
                name: "foundational",
                type: "mood",
                weight: weight,
                signSource: signName,
                houseSource: 4,
                originType: .natal
            ))
            tokens.append(StyleToken(
                name: "comforting",
                type: "texture",
                weight: weight * 0.8,
                signSource: signName,
                houseSource: 4,
                originType: .natal
            ))
            
        case 7: // Descendant - Partnerships and social presentation
            tokens.append(StyleToken(
                name: "harmonious",
                type: "expression",
                weight: weight,
                signSource: signName,
                houseSource: 7,
                originType: .natal
            ))
            tokens.append(StyleToken(
                name: "balanced",
                type: "structure",
                weight: weight * 0.8,
                signSource: signName,
                houseSource: 7,
                originType: .natal
            ))
            
        case 10: // Midheaven - Public image and professional presentation
            tokens.append(StyleToken(
                name: "authoritative",
                type: "expression",
                weight: weight,
                signSource: signName,
                houseSource: 10,
                originType: .natal
            ))
            tokens.append(StyleToken(
                name: "polished",
                type: "texture",
                weight: weight * 0.9,
                signSource: signName,
                houseSource: 10,
                originType: .natal
            ))
            
        default:
            break
        }
        
        return tokens
    }
    
    private static func getCurrentSunSign(month: Int, day: Int) -> String {
        switch (month, day) {
        case (3, 21...), (4, 1...19): return "Aries"
        case (4, 20...), (5, 1...20): return "Taurus"
        case (5, 21...), (6, 1...20): return "Gemini"
        case (6, 21...), (7, 1...22): return "Cancer"
        case (7, 23...), (8, 1...22): return "Leo"
        case (8, 23...), (9, 1...22): return "Virgo"
        case (9, 23...), (10, 1...22): return "Libra"
        case (10, 23...), (11, 1...21): return "Scorpio"
        case (11, 22...), (12, 1...21): return "Sagittarius"
        case (12, 22...), (12, 31), (1, 1...19): return "Capricorn"
        case (1, 20...), (2, 1...18): return "Aquarius"
        case (2, 19...), (3, 1...20): return "Pisces"
        default: return "Leo" // Default fallback
        }
    }
    
    // MARK: - Color Season System (Partner's Feature Request)
    
    /// Professional color season analysis based on astrological chart
    enum ColorSeason: String, CaseIterable {
        case brightSpring = "Bright Spring"
        case lightSpring = "Light Spring" 
        case warmSpring = "Warm Spring"
        case brightSummer = "Bright Summer"
        case lightSummer = "Light Summer"
        case coolSummer = "Cool Summer"
        case brightAutumn = "Bright Autumn"
        case warmAutumn = "Warm Autumn"
        case deepAutumn = "Deep Autumn"
        case brightWinter = "Bright Winter"
        case coolWinter = "Cool Winter"
        case deepWinter = "Deep Winter"
    }
    
    /// Color Season Analyzer for professional fashion guidance
    struct ColorSeasonAnalyzer {
        
        /// Determine color season based on astrological chart factors
        static func determineColorSeason(chart: NatalChartCalculator.NatalChart) -> ColorSeason {
            // Analyze elemental balance for warmth/coolness
            let fireCount = countFirePlacements(chart: chart)
            let earthCount = countEarthPlacements(chart: chart)
            let airCount = countAirPlacements(chart: chart)
            let waterCount = countWaterPlacements(chart: chart)
            
            // Determine undertone (warm vs cool)
            let isWarmUndertone = (fireCount + earthCount) > (airCount + waterCount)
            
            // Determine intensity (bright vs muted vs deep)
            let venusIntensity = calculateVenusIntensity(chart: chart)
            
            // Determine lightness (light vs deep)
            let isLightExpression = hasLightExpression(chart: chart)
            
            // Professional color season determination (fixed redundant cases)
            switch (isWarmUndertone, venusIntensity, isLightExpression) {
            case (true, .bright, true): return .brightSpring
            case (true, .muted, true): return .lightSpring
            case (true, .bright, false): return .warmSpring
            case (true, .muted, false): return .warmAutumn
            case (true, .deep, false): return .deepAutumn
            case (false, .bright, true): return .brightSummer
            case (false, .muted, true): return .lightSummer
            case (false, .muted, false): return .coolSummer
            case (false, .bright, false): return .brightWinter
            case (false, .deep, false): return .deepWinter
            default: return .deepAutumn // Fallback
            }
        }
        
        /// Get seasonal color palette for consistent fashion guidance
        static func getSeasonalPalette(season: ColorSeason) -> [StyleToken] {
            let baseColors = seasonalColorMappings[season] ?? []
            return baseColors.map { (colorName, intensity) in
                StyleToken(
                    name: colorName,
                    type: "color",
                    weight: intensity,
                    planetarySource: "ColorSeason",
                    aspectSource: "Color Season: \(season.rawValue)",
                    originType: .natal
                )
            }
        }
        
        /// Modulate daily intensity while maintaining seasonal coherence
        static func modulateForDaily(palette: [StyleToken], transits: [Any]) -> [StyleToken] {
            // Maintain palette but adjust intensity based on daily transits
            return palette.map { token in
                let dailyIntensity = calculateDailyIntensityModulation(transits: transits)
                return token.withWeight(token.weight * dailyIntensity)
            }
        }
        
        // MARK: - Helper Methods
        
        private enum VenusIntensity {
            case bright, muted, deep
        }
        
        private static let seasonalColorMappings: [ColorSeason: [(String, Double)]] = [
            .deepAutumn: [("rust", 2.0), ("olive", 1.8), ("burgundy", 1.9), ("golden_brown", 1.7), ("deep_orange", 1.6)],
            .brightWinter: [("royal_blue", 2.0), ("emerald", 1.9), ("magenta", 1.8), ("black", 2.0), ("white", 1.7)],
            .warmSpring: [("coral", 1.8), ("golden_yellow", 1.9), ("warm_green", 1.6), ("peach", 1.7), ("camel", 1.5)],
            .coolSummer: [("lavender", 1.6), ("soft_blue", 1.7), ("rose", 1.5), ("mint", 1.4), ("pearl_gray", 1.6)]
            // Add more seasonal mappings as needed
        ]
        

        
        private static func countFirePlacements(chart: NatalChartCalculator.NatalChart) -> Int {
            return chart.planets.filter { [1, 5, 9].contains($0.zodiacSign) }.count
        }
        
        private static func countEarthPlacements(chart: NatalChartCalculator.NatalChart) -> Int {
            return chart.planets.filter { [2, 6, 10].contains($0.zodiacSign) }.count
        }
        
        private static func countAirPlacements(chart: NatalChartCalculator.NatalChart) -> Int {
            return chart.planets.filter { [3, 7, 11].contains($0.zodiacSign) }.count
        }
        
        private static func countWaterPlacements(chart: NatalChartCalculator.NatalChart) -> Int {
            return chart.planets.filter { [4, 8, 12].contains($0.zodiacSign) }.count
        }
        
        private static func calculateVenusIntensity(chart: NatalChartCalculator.NatalChart) -> VenusIntensity {
            guard let venus = chart.planets.first(where: { $0.name == "Venus" }) else { return .muted }
            
            // Fire/Mars aspects = bright, Earth/Saturn = deep, Water/Air = muted
            switch venus.zodiacSign {
            case 1, 5, 9: return .bright  // Fire signs
            case 2, 6, 10: return .deep   // Earth signs  
            default: return .muted        // Air/Water signs
            }
        }
        
        private static func hasLightExpression(chart: NatalChartCalculator.NatalChart) -> Bool {
            // Light expression = more air/fire, fewer planets in deep signs
            let lightSigns = [1, 3, 5, 7, 9, 11] // Fire and Air
            let lightPlacements = chart.planets.filter { lightSigns.contains($0.zodiacSign) }.count
            return lightPlacements > 3
        }
        
        private static func calculateDailyIntensityModulation(transits: [Any]) -> Double {
            // Placeholder for daily transit intensity calculation
            return 1.0 + (Double.random(in: -0.2...0.2)) // ±20% daily variation
        }
    }
    
    // MARK: - Traditional Astrological Color Correspondences
    
    /// Traditional astrological color mappings per professional standards
    struct TraditionalColors {
        static let signColors: [String: [(String, String)]] = [
            "Aries": [("red", "color"), ("bright_orange", "color"), ("bold_contrast", "color_quality")],
            "Taurus": [("sage_green", "color"), ("rose", "color"), ("warm_brown", "color"), ("cream", "color")],
            "Gemini": [("yellow", "color"), ("bright_patterns", "color_quality"), ("mixed_combinations", "color_quality")],
            "Cancer": [("white", "color"), ("silver", "color"), ("pearl", "color"), ("nautical_themes", "color_quality")],
            "Leo": [("gold", "color"), ("orange", "color"), ("red", "color"), ("purple", "color"), ("crimson", "color"), ("royal", "color_quality")],
            "Virgo": [("navy", "color"), ("wheat", "color"), ("brown", "color"), ("precisely_tailored", "color_quality")],
            "Libra": [("rose_pink", "color"), ("pastels", "color"), ("harmonious_combinations", "color_quality"), ("balanced_proportions", "color_quality")],
            "Scorpio": [("black", "color"), ("burgundy", "color"), ("deep_colors", "color_quality"), ("power_silhouettes", "color_quality")],
            "Sagittarius": [("purple", "color"), ("royal_blue", "color"), ("international_influences", "color_quality"), ("travel_ready", "color_quality")],
            "Capricorn": [("charcoal", "color"), ("brown", "color"), ("black", "color"), ("classic_business", "color_quality")],
            "Aquarius": [("electric_blue", "color"), ("unexpected_combinations", "color_quality"), ("technical_fabrics", "color_quality")],
            "Pisces": [("sea_colors", "color_quality"), ("flowing_fabrics", "color_quality"), ("ethereal_elements", "color_quality")]
        ]
    }
    
    /// Enhanced traditional token generation with professional astrological accuracy
    private static func generateTraditionalSignTokens(signName: String) -> [(String, String)] {
        return TraditionalColors.signColors[signName] ?? [("neutral", "color")]
    }
    
    /// Get chart ruler (ruling planet of Ascendant) for dominant personal expression
    private static func getChartRuler(ascendantSign: Int) -> String {
        switch ascendantSign {
        case 1: return "Mars"      // Aries
        case 2: return "Venus"     // Taurus
        case 3: return "Mercury"   // Gemini
        case 4: return "Moon"      // Cancer
        case 5: return "Sun"       // Leo
        case 6: return "Mercury"   // Virgo
        case 7: return "Venus"     // Libra
        case 8: return "Mars"      // Scorpio (traditional ruler)
        case 9: return "Jupiter"   // Sagittarius
        case 10: return "Saturn"   // Capricorn
        case 11: return "Saturn"   // Aquarius (traditional ruler)
        case 12: return "Jupiter"  // Pisces (traditional ruler)
        default: return "Sun"      // Fallback
        }
    }
    
    /// Professional aggressive orb-based weighting for precise astrological accuracy
    private static func calculateProfessionalOrbMultiplier(orb: Double) -> Double {
        switch orb {
        case 0.0..<1.0:
            return 2.0    // Exact aspects (like 0.11°) = 100% strength × 2x multiplier
        case 1.0..<2.0:
            return 1.5    // Tight aspects = 80% strength × 1.5x multiplier  
        case 2.0..<3.0:
            return 1.0    // Normal aspects = 50% strength × 1x multiplier
        case 3.0..<4.0:
            return 0.7    // Wide aspects = 30% strength × 0.7x multiplier
        default:
            return 0.3    // Very wide aspects = 20% strength × 0.3x multiplier
        }
    }
    
    // MARK: - Professional Astrological Validation
    
    /// Validation warnings for astrological accuracy
    enum ValidationWarning {
        case venusUnderwhelming
        case dailyVariationExcessive
        case natalInfluenceTooLow
        case traditionalColorMismatch
        case aspectMeaningMissing
    }
    
    /// Professional astrological validation system
    struct AstrologicalValidation {
        
        /// Validate token mappings against professional astrological standards
        static func validateTokenMappings(tokens: [StyleToken], chart: NatalChartCalculator.NatalChart) -> [ValidationWarning] {
            var warnings: [ValidationWarning] = []
            
            // Check Venus dominance for fashion
            let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
            let totalWeight = tokens.reduce(0) { $0 + $1.weight }
            let venusPercentage = venusTokens.reduce(0) { $0 + $1.weight } / totalWeight
            
            if venusPercentage < 0.3 {
                warnings.append(.venusUnderwhelming)
            }
            
            // Check daily variation target
            let natalTokens = tokens.filter { $0.originType == .natal }
            let dailyTokens = tokens.filter { [.transit, .weather, .phase].contains($0.originType) }
            let natalPercentage = natalTokens.reduce(0) { $0 + $1.weight } / totalWeight
            let dailyPercentage = dailyTokens.reduce(0) { $0 + $1.weight } / totalWeight
            
            if natalPercentage < 0.45 {
                warnings.append(.natalInfluenceTooLow)
            }
            
            if dailyPercentage > 0.25 {
                warnings.append(.dailyVariationExcessive)
            }
            
            return warnings
        }
        
        /// Validate traditional sign-color alignment
        static func validateTraditionalAlignment(tokens: [StyleToken]) -> Bool {
            // Check that traditional color mappings are being used
            let taurusTokens = tokens.filter { $0.signSource == "Taurus" }
            let hasTraditionalTaurusColors = taurusTokens.contains { token in
                ["sage_green", "rose", "warm_brown", "cream"].contains(token.name)
            }
            
            let scorpioTokens = tokens.filter { $0.signSource == "Scorpio" }
            let hasTraditionalScorpioElements = scorpioTokens.contains { token in
                ["black", "burgundy", "leather", "power", "magnetic"].contains(token.name)
            }
            
            return hasTraditionalTaurusColors && hasTraditionalScorpioElements
        }
    }

    private static func getCurrentSunSignBackgroundTokens(sunSign: String) -> [(String, String)] {
        switch sunSign {
        case "Aries":
            return [("energetic", "mood"), ("bold", "color_quality"), ("dynamic", "expression"), ("fiery", "texture")]
        case "Taurus":
            return [("grounded", "mood"), ("luxurious", "texture"), ("sage_green", "color"), ("quality", "structure")]
        case "Gemini":
            return [("versatile", "expression"), ("bright", "color_quality"), ("communicative", "mood"), ("airy", "texture")]
        case "Cancer":
            return [("nurturing", "mood"), ("protective", "structure"), ("pearl", "color"), ("flowing", "texture")]
        case "Leo":
            return [("radiant", "color_quality"), ("bold", "expression"), ("warm", "texture"), ("dramatic", "mood")]
        case "Virgo":
            return [("precise", "structure"), ("refined", "texture"), ("practical", "mood"), ("earthy", "color_quality")]
        case "Libra":
            return [("harmonious", "mood"), ("elegant", "expression"), ("balanced", "structure"), ("beautiful", "color_quality")]
        case "Scorpio":
            return [("magnetic", "mood"), ("leather", "texture"), ("black", "color"), ("power", "structure")]
        case "Sagittarius":
            return [("adventurous", "mood"), ("expansive", "expression"), ("optimistic", "color_quality"), ("free", "structure")]
        case "Capricorn":
            return [("structured", "structure"), ("authoritative", "mood"), ("disciplined", "expression"), ("enduring", "texture")]
        case "Aquarius":
            return [("innovative", "expression"), ("unique", "structure"), ("electric", "color_quality"), ("progressive", "mood")]
        case "Pisces":
            return [("dreamy", "mood"), ("fluid", "texture"), ("intuitive", "expression"), ("ethereal", "color_quality")]
        default:
            return [("balanced", "mood"), ("harmonious", "expression"), ("neutral", "color_quality"), ("adaptable", "structure")]
        }
    }
    
    /// Get sign-specific tokens modified by house context
    private static func getSignTokensForHouse(signName: String, houseNumber: Int) -> [(String, String)] {
        // Base sign tokens from interpretation library - use Sun sign descriptions as general baseline
        let baseSignTokens = InterpretationTextLibrary.TokenGeneration.PlanetInSign.Sun.descriptions[signName] ?? []
        
        // Filter and modify tokens based on house context
        var houseModifiedTokens: [(String, String)] = []
        
        for (tokenName, tokenType) in baseSignTokens {
            // Modify token based on house influence
            let modifiedToken = modifyTokenForHouseContext(
                tokenName: tokenName,
                tokenType: tokenType,
                houseNumber: houseNumber
            )
            houseModifiedTokens.append(modifiedToken)
        }
        
        return houseModifiedTokens
    }
    
    /// Modify tokens based on house context
    private static func modifyTokenForHouseContext(
        tokenName: String,
        tokenType: String,
        houseNumber: Int
    ) -> (String, String) {
        
        // House-specific modifications to make tokens more relevant
        switch houseNumber {
        case 1: // Identity house - emphasize expression
            if tokenType == "mood" { return (tokenName, "expression") }
        case 2: // Values house - emphasize texture and substance
            if tokenType == "expression" { return (tokenName, "texture") }
        case 6: // Service house - emphasize practical structure
            if tokenType == "color_quality" { return ("practical-\(tokenName)", "structure") }
        case 10: // Career house - emphasize professional expression
            if tokenType == "mood" { return ("professional-\(tokenName)", "expression") }
        default:
            break
        }
        
        return (tokenName, tokenType)
    }
    
    /// Get house-specific style influences
    private static func getHouseStyleInfluence(houseNumber: Int) -> (structural: String?, expressive: String?) {
        switch houseNumber {
        case 1:  return (structural: "prominent", expressive: "defining")
        case 2:  return (structural: "substantial", expressive: "tactile")
        case 3:  return (structural: "versatile", expressive: "communicative")
        case 4:  return (structural: "grounded", expressive: "nurturing")
        case 5:  return (structural: "expressive", expressive: "creative")
        case 6:  return (structural: "functional", expressive: "practical")
        case 7:  return (structural: "balanced", expressive: "harmonious")
        case 8:  return (structural: "transformative", expressive: "intense")
        case 9:  return (structural: "expansive", expressive: "worldly")
        case 10: return (structural: "structured", expressive: "authoritative")
        case 11: return (structural: "innovative", expressive: "unconventional")
        case 12: return (structural: "subtle", expressive: "mystical")
        default: return (structural: nil, expressive: nil)
        }
    }
    
    /// Adjust token weight based on type and house combination
    private static func getTokenTypeMultiplier(tokenType: String, houseNumber: Int) -> Double {
        switch houseNumber {
        case 1, 10: // Most visible houses
            switch tokenType {
            case "expression": return 1.2
            case "structure": return 1.1
            case "color_quality": return 1.0
            default: return 0.9
            }
        case 2, 6: // Practical houses
            switch tokenType {
            case "texture": return 1.2
            case "structure": return 1.1
            default: return 1.0
            }
        case 4, 7: // Relationship houses
            switch tokenType {
            case "mood": return 1.1
            case "expression": return 1.0
            default: return 0.9
            }
        default:
            return 1.0
        }
    }
    
    /// House type enumeration
    private enum HouseType {
        case angular    // 1, 4, 7, 10 - Most active and prominent
        case succedent  // 2, 5, 8, 11 - Fixed and stable
        case cadent     // 3, 6, 9, 12 - Mutable and transitional
    }
    
    /// Enhanced aspect token generation with professional astrological meaning
    private static func generateAspectTokens(chart: NatalChartCalculator.NatalChart, baseWeight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        for i in 0..<chart.planets.count {
            let planet1 = chart.planets[i]
            for j in (i+1)..<chart.planets.count {
                let planet2 = chart.planets[j]
                
                if let (aspectType, orb) = AstronomicalCalculator.calculateAspect(
                    point1: planet1.longitude,
                    point2: planet2.longitude,
                    orb: 5.0) {
                    
                    let aspectSource = "\(planet1.name) \(aspectType) \(planet2.name)"
                    var aspectWeight = baseWeight * 2.0
                    
                    // Professional aggressive orb-based weighting
                    let orbMultiplier = calculateProfessionalOrbMultiplier(orb: orb)
                    aspectWeight *= orbMultiplier
                    
                    // Generate aspect-specific tokens with professional meanings
                    let aspectSpecificTokens = generateAspectSpecificTokens(
                        planet1: planet1.name,
                        planet2: planet2.name,
                        aspectType: aspectType,
                        baseWeight: aspectWeight
                    )
                    
                    for aspectToken in aspectSpecificTokens {
                        tokens.append(StyleToken(
                            name: aspectToken.name,
                            type: aspectToken.type,
                            weight: aspectToken.weight,
                            planetarySource: "\(planet1.name)-\(planet2.name)",
                            aspectSource: aspectSource,
                            originType: .natal
                        ))
                    }
                }
            }
        }
        
        return tokens
    }
    
    /// Professional aspect-specific token generation based on astrological meaning
    private static func generateAspectSpecificTokens(
        planet1: String,
        planet2: String,
        aspectType: String,
        baseWeight: Double
    ) -> [(name: String, type: String, weight: Double)] {
        
        // Focus on Venus aspects for fashion authority
        if (planet1 == "Venus" || planet2 == "Venus") {
            let otherPlanet = planet1 == "Venus" ? planet2 : planet1
            return generateVenusAspectTokens(otherPlanet: otherPlanet, aspectType: aspectType, baseWeight: baseWeight)
        }
        
        // Focus on Moon aspects for emotional comfort
        if (planet1 == "Moon" || planet2 == "Moon") {
            let otherPlanet = planet1 == "Moon" ? planet2 : planet1
            return generateMoonAspectTokens(otherPlanet: otherPlanet, aspectType: aspectType, baseWeight: baseWeight)
        }
        
        // Focus on Mars aspects for energy expression
        if (planet1 == "Mars" || planet2 == "Mars") {
            let otherPlanet = planet1 == "Mars" ? planet2 : planet1
            return generateMarsAspectTokens(otherPlanet: otherPlanet, aspectType: aspectType, baseWeight: baseWeight)
        }
        
        // Default generic aspect token
        return [(name: getAspectMoodToken(aspectType: aspectType), type: "mood", weight: baseWeight)]
    }
    
    /// Venus aspect tokens with professional fashion implications
    private static func generateVenusAspectTokens(otherPlanet: String, aspectType: String, baseWeight: Double) -> [(name: String, type: String, weight: Double)] {
        switch (otherPlanet, aspectType) {
        case ("Moon", "Trine"):
            return [("effortless_beauty", "expression", baseWeight * 1.5), ("comfortable_luxury", "texture", baseWeight)]
        case ("Moon", "Square"):
            return [("polished_comfort", "approach", baseWeight), ("strategic_softness", "texture", baseWeight)]
        case ("Moon", "Opposition"):
            return [("sophisticated_comfort", "approach", baseWeight), ("public_private_balance", "structure", baseWeight)]
        case ("Mars", "Trine"):
            return [("confident_sensuality", "expression", baseWeight * 1.3), ("dynamic_beauty", "mood", baseWeight)]
        case ("Mars", "Square"):
            return [("tension_resolution", "approach", baseWeight), ("bold_refinement", "expression", baseWeight)]
        case ("Jupiter", "Trine"):
            return [("abundant_style", "approach", baseWeight), ("generous_beauty", "expression", baseWeight)]
        case ("Saturn", "Trine"):
            return [("timeless_elegance", "approach", baseWeight * 1.2), ("structured_beauty", "structure", baseWeight)]
        case ("Saturn", "Square"):
            return [("refined_discipline", "approach", baseWeight), ("earned_elegance", "expression", baseWeight)]
        default:
            return [(name: "harmonious", type: "mood", weight: baseWeight)]
        }
    }
    
    /// Moon aspect tokens with emotional comfort implications
    private static func generateMoonAspectTokens(otherPlanet: String, aspectType: String, baseWeight: Double) -> [(name: String, type: String, weight: Double)] {
        switch (otherPlanet, aspectType) {
        case ("Venus", _): // Handled in Venus aspects
            return []
        case ("Mars", "Trine"):
            return [("emotionally_dynamic", "expression", baseWeight), ("protective_strength", "structure", baseWeight)]
        case ("Mars", "Square"):
            return [("emotional_armor", "structure", baseWeight), ("defensive_style", "approach", baseWeight)]
        case ("Saturn", "Trine"):
            return [("emotional_security", "approach", baseWeight), ("stable_comfort", "texture", baseWeight)]
        default:
            return [(name: "emotionally_responsive", type: "mood", weight: baseWeight)]
        }
    }
    
    /// Mars aspect tokens with energy expression implications
    private static func generateMarsAspectTokens(otherPlanet: String, aspectType: String, baseWeight: Double) -> [(name: String, type: String, weight: Double)] {
        switch (otherPlanet, aspectType) {
        case ("Venus", _), ("Moon", _): // Handled in other aspect functions
            return []
        case ("Jupiter", "Trine"):
            return [("expansive_energy", "expression", baseWeight), ("confident_action", "structure", baseWeight)]
        case ("Saturn", "Square"):
            return [("disciplined_energy", "approach", baseWeight), ("strategic_action", "structure", baseWeight)]
        case ("Uranus", "Trine"):
            return [("innovative_action", "expression", baseWeight), ("electric_energy", "mood", baseWeight)]
        default:
            return [(name: "energetic", type: "mood", weight: baseWeight)]
        }
    }
    
    private static func generateMoonPhaseColorTokens(moonPhase: Double, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        let phase = MoonPhaseInterpreter.Phase.fromDegrees(moonPhase)
        let colorPalette = MoonPhaseInterpreter.colorPaletteForPhase(phase: phase)
        
        for (index, color) in colorPalette.enumerated() {
            let colorWeight = weight * (1.5 - (Double(index) * 0.2))
            tokens.append(StyleToken(
                name: color,
                type: "color",
                weight: colorWeight,
                aspectSource: "Moon Phase: \(phase.description)",
                originType: .phase
            ))
        }
        
        return tokens
    }
    
    private static func tokenizeForTransit(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String,
        weight: Double,
        aspectSource: String) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            switch transitPlanet {
            case "Sun":
                tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            case "Moon":
                tokens.append(StyleToken(name: "flowing", type: "structure", weight: weight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            case "Venus":
                tokens.append(StyleToken(name: "harmonious", type: "mood", weight: weight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            case "Mars":
                tokens.append(StyleToken(name: "dynamic", type: "expression", weight: weight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            default:
                tokens.append(StyleToken(name: "transformative", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
            }
            
            return tokens
        }
    
    private static func getNatalPlanetPowerScore(_ planet: String, chart: NatalChartCalculator.NatalChart) -> Double {
        // Get additional context for better power evaluation
        var sign: String? = nil
        var house: Int? = nil
        var isAngular = false
        var isChartRuler = false
        
        // Find planet in chart
        if let natalPlanet = chart.planets.first(where: { $0.name == planet }) {
            sign = CoordinateTransformations.getZodiacSignName(sign: natalPlanet.zodiacSign)
            
            house = NatalChartCalculator.determineHouse(longitude: natalPlanet.longitude, houseCusps: chart.houseCusps)
            isAngular = [1, 4, 7, 10].contains(house ?? 0)
            
            if let ascendant = chart.planets.first(where: { $0.name == "Ascendant" }) {
                let risingSign = ascendant.zodiacSign
                let rulingPlanet = getRulingPlanet(for: risingSign)
                isChartRuler = (rulingPlanet == planet)
            }
        }
        
        // Use PlanetPowerEvaluator for accurate power calculation
        return PlanetPowerEvaluator.evaluatePower(
            for: planet,
            sign: sign,
            house: house,
            isAngular: isAngular,
            isChartRuler: isChartRuler
        )
    }
    
    private static func getRulingPlanet(for sign: Int) -> String? {
        switch sign {
        case 1: return "Mars"      // Aries
        case 2: return "Venus"     // Taurus
        case 3: return "Mercury"   // Gemini
        case 4: return "Moon"      // Cancer
        case 5: return "Sun"       // Leo
        case 6: return "Mercury"   // Virgo
        case 7: return "Venus"     // Libra
        case 8: return "Mars"      // Scorpio (traditional ruler)
        case 9: return "Jupiter"   // Sagittarius
        case 10: return "Saturn"   // Capricorn
        case 11: return "Saturn"   // Aquarius (traditional ruler)
        case 12: return "Jupiter"  // Pisces (traditional ruler)
        default: return nil
        }
    }
    
    private static func extractNatalPlanet(from aspectSource: String) -> String? {
        let parts = aspectSource.components(separatedBy: " ")
        return parts.count >= 3 ? parts[2] : nil
    }
    
    private static func generateColorTokensForPlanetInSign(planet: String, sign: Int, weight: Double, isRetrograde: Bool = false, isProgressed: Bool = false) -> [StyleToken] {
        return []
    }
    
    private static func generateColorTokensForAscendant(sign: Int, signName: String, weight: Double) -> [StyleToken] {
        return []
    }
    
    private static func generateElementalColorTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return []
    }
    
    private static func generateAspectColorTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return []
    }
    
    private static func generateColorNuanceFromAspects(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return []
    }
    
    private static func generateColorTokensFromDignities(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return []
    }
    
    private static func getPlanetSignDescriptions(planet: String, signName: String) -> [(String, String)]? {
        switch planet {
        case "Sun":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Sun.descriptions[signName]
        case "Moon":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Moon.descriptions[signName]
        case "Venus":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Venus.descriptions[signName]
        case "Mars":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Mars.descriptions[signName]
        case "Mercury":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Mercury.descriptions[signName]
        case "Jupiter":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.jupiter
        case "Saturn":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.saturn
        case "Uranus":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.uranus
        case "Neptune":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.neptune
        case "Pluto":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.pluto
        default:
            return nil
        }
    }
    
    private static func getElementalFallbackTokens(signName: String) -> [(String, String)] {
        if ["Aries", "Leo", "Sagittarius"].contains(signName) {
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.ElementalFallbacks.fire
        } else if ["Taurus", "Virgo", "Capricorn"].contains(signName) {
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.ElementalFallbacks.earth
        } else if ["Gemini", "Libra", "Aquarius"].contains(signName) {
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.ElementalFallbacks.air
        } else if ["Cancer", "Scorpio", "Pisces"].contains(signName) {
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.ElementalFallbacks.water
        } else {
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.ElementalFallbacks.fire
        }
    }
    
    private static func getRetrogradeTokens(planet: String) -> [(String, String)]? {
        switch planet {
        case "Venus":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Retrograde.venus
        case "Mars":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Retrograde.mars
        case "Mercury":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.Retrograde.mercury
        default:
            return nil
        }
    }
    
    private static func getAspectMoodToken(aspectType: String) -> String {
        switch aspectType {
        case "Conjunction", "Trine": return "harmonious"
        case "Square", "Opposition": return "dynamic"
        case "Sextile": return "supportive"
        default: return "subtle"
        }
    }
    
    // MARK: - Expanded Token Generation for Daily System
    
    /// Generate comprehensive textile tokens based on chart elements and planets
    static func generateExpandedTextileTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Get dominant elements for textile guidance
        let elementWeights = calculateElementalWeights(chart: chart)
        let _ = elementWeights.max(by: { $0.value < $1.value })?.key ?? "balanced"
        
        // Venus-based textile preferences
        if let venus = chart.planets.first(where: { $0.name == "Venus" }) {
            let venusElement = getSignElement(sign: venus.zodiacSign)
            let venusModality = getSignModality(sign: venus.zodiacSign)
            
            switch venusElement {
            case "fire":
                tokens.append(StyleToken(name: "lightweight", type: "textile", weight: 1.2, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "breathable", type: "textile", weight: 1.0, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "energetic", type: "textile", weight: 0.8, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
            case "earth":
                tokens.append(StyleToken(name: "structured", type: "textile", weight: 1.3, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "textured", type: "textile", weight: 1.1, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "substantial", type: "textile", weight: 0.9, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
            case "air":
                tokens.append(StyleToken(name: "flowing", type: "textile", weight: 1.2, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "airy", type: "textile", weight: 1.0, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "versatile", type: "textile", weight: 0.8, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
            case "water":
                tokens.append(StyleToken(name: "soft", type: "textile", weight: 1.3, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "draping", type: "textile", weight: 1.1, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
                tokens.append(StyleToken(name: "fluid", type: "textile", weight: 0.9, planetarySource: "Venus", signSource: CoordinateTransformations.getZodiacSignName(sign: venus.zodiacSign), originType: .natal))
            default:
                tokens.append(StyleToken(name: "adaptable", type: "textile", weight: 1.0, planetarySource: "Venus", originType: .natal))
            }
            
            // Modality-based additions
            switch venusModality {
            case "cardinal":
                tokens.append(StyleToken(name: "crisp", type: "textile", weight: 0.8, planetarySource: "Venus", originType: .natal))
            case "fixed":
                tokens.append(StyleToken(name: "substantial", type: "textile", weight: 0.9, planetarySource: "Venus", originType: .natal))
            case "mutable":
                tokens.append(StyleToken(name: "adaptable", type: "textile", weight: 0.7, planetarySource: "Venus", originType: .natal))
            default:
                break
            }
        }
        
        // Mars-based energy textile preferences
        if let mars = chart.planets.first(where: { $0.name == "Mars" }) {
            let marsElement = getSignElement(sign: mars.zodiacSign)
            
            switch marsElement {
            case "fire":
                tokens.append(StyleToken(name: "dynamic", type: "textile", weight: 0.8, planetarySource: "Mars", originType: .natal))
            case "earth":
                tokens.append(StyleToken(name: "durable", type: "textile", weight: 0.7, planetarySource: "Mars", originType: .natal))
            case "air":
                tokens.append(StyleToken(name: "movement-friendly", type: "textile", weight: 0.6, planetarySource: "Mars", originType: .natal))
            case "water":
                tokens.append(StyleToken(name: "comfort-focused", type: "textile", weight: 0.7, planetarySource: "Mars", originType: .natal))
            default:
                break
            }
        }
        
        return tokens
    }
    
    /// Generate pattern tokens based on planetary and elemental influences
    static func generatePatternTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Venus pattern preferences
        if let venus = chart.planets.first(where: { $0.name == "Venus" }) {
            let venusElement = getSignElement(sign: venus.zodiacSign)
            let venusModality = getSignModality(sign: venus.zodiacSign)
            
            switch venusElement {
            case "fire":
                tokens.append(StyleToken(name: "geometric", type: "pattern", weight: 1.0, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "angular", type: "pattern", weight: 0.8, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "bold", type: "pattern", weight: 0.7, planetarySource: "Venus", originType: .natal))
            case "earth":
                tokens.append(StyleToken(name: "organic", type: "pattern", weight: 1.1, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "natural", type: "pattern", weight: 0.9, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "textural", type: "pattern", weight: 0.8, planetarySource: "Venus", originType: .natal))
            case "air":
                tokens.append(StyleToken(name: "abstract", type: "pattern", weight: 1.0, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "scattered", type: "pattern", weight: 0.8, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "versatile", type: "pattern", weight: 0.7, planetarySource: "Venus", originType: .natal))
            case "water":
                tokens.append(StyleToken(name: "flowing", type: "pattern", weight: 1.1, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "soft-edged", type: "pattern", weight: 0.9, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "organic", type: "pattern", weight: 0.8, planetarySource: "Venus", originType: .natal))
            default:
                tokens.append(StyleToken(name: "balanced", type: "pattern", weight: 0.8, planetarySource: "Venus", originType: .natal))
            }
            
            // Modality pattern additions
            switch venusModality {
            case "cardinal":
                tokens.append(StyleToken(name: "directional", type: "pattern", weight: 0.7, planetarySource: "Venus", originType: .natal))
            case "fixed":
                tokens.append(StyleToken(name: "symmetrical", type: "pattern", weight: 0.8, planetarySource: "Venus", originType: .natal))
            case "mutable":
                tokens.append(StyleToken(name: "irregular", type: "pattern", weight: 0.6, planetarySource: "Venus", originType: .natal))
            default:
                break
            }
        }
        
        // Mercury pattern communication
        if let mercury = chart.planets.first(where: { $0.name == "Mercury" }) {
            let mercuryElement = getSignElement(sign: mercury.zodiacSign)
            switch mercuryElement {
            case "fire", "air":
                tokens.append(StyleToken(name: "communicative", type: "pattern", weight: 0.6, planetarySource: "Mercury", originType: .natal))
            case "earth", "water":
                tokens.append(StyleToken(name: "subtle", type: "pattern", weight: 0.5, planetarySource: "Mercury", originType: .natal))
            default:
                break
            }
        }
        
        return tokens
    }
    
    /// Generate accessory tokens based on planetary influences
    static func generateAccessoryTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Venus accessory preferences
        if let venus = chart.planets.first(where: { $0.name == "Venus" }) {
            let venusElement = getSignElement(sign: venus.zodiacSign)
            
            switch venusElement {
            case "fire":
                tokens.append(StyleToken(name: "eye-catching", type: "accessory", weight: 1.0, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "dramatic", type: "accessory", weight: 0.8, planetarySource: "Venus", originType: .natal))
            case "earth":
                tokens.append(StyleToken(name: "grounding", type: "accessory", weight: 1.1, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "substantial", type: "accessory", weight: 0.9, planetarySource: "Venus", originType: .natal))
            case "air":
                tokens.append(StyleToken(name: "conversational", type: "accessory", weight: 0.9, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "versatile", type: "accessory", weight: 0.7, planetarySource: "Venus", originType: .natal))
            case "water":
                tokens.append(StyleToken(name: "romantic", type: "accessory", weight: 1.0, planetarySource: "Venus", originType: .natal))
                tokens.append(StyleToken(name: "nostalgic", type: "accessory", weight: 0.8, planetarySource: "Venus", originType: .natal))
            default:
                tokens.append(StyleToken(name: "personal", type: "accessory", weight: 0.8, planetarySource: "Venus", originType: .natal))
            }
        }
        
        // Mars energy accessories
        if let mars = chart.planets.first(where: { $0.name == "Mars" }) {
            let marsElement = getSignElement(sign: mars.zodiacSign)
            
            switch marsElement {
            case "fire":
                tokens.append(StyleToken(name: "bold", type: "accessory", weight: 0.8, planetarySource: "Mars", originType: .natal))
            case "earth":
                tokens.append(StyleToken(name: "functional", type: "accessory", weight: 0.7, planetarySource: "Mars", originType: .natal))
            case "air":
                tokens.append(StyleToken(name: "expressive", type: "accessory", weight: 0.6, planetarySource: "Mars", originType: .natal))
            case "water":
                tokens.append(StyleToken(name: "protective", type: "accessory", weight: 0.7, planetarySource: "Mars", originType: .natal))
            default:
                break
            }
        }
        
        // Jupiter expansion accessories
        if chart.planets.contains(where: { $0.name == "Jupiter" }) {
            tokens.append(StyleToken(name: "generous", type: "accessory", weight: 0.5, planetarySource: "Jupiter", originType: .natal))
        }
        
        return tokens
    }
    
    // Helper methods for elemental and modal analysis
    private static func getSignElement(sign: Int) -> String {
        let elements = ["fire", "earth", "air", "water"]
        return elements[sign % 4]
    }
    
    private static func getSignModality(sign: Int) -> String {
        let modalities = ["cardinal", "fixed", "mutable"]
        return modalities[(sign / 4) % 3]
    }
    
    private static func calculateElementalWeights(chart: NatalChartCalculator.NatalChart) -> [String: Double] {
        var weights: [String: Double] = ["fire": 0, "earth": 0, "air": 0, "water": 0]
        
        for planet in chart.planets {
            let element = getSignElement(sign: planet.zodiacSign)
            let planetWeight: Double
            
            switch planet.name {
            case "Sun": planetWeight = 2.0
            case "Moon": planetWeight = 2.0
            case "Venus": planetWeight = 1.8
            case "Mars": planetWeight = 1.5
            case "Mercury": planetWeight = 1.2
            default: planetWeight = 1.0
            }
            
            weights[element, default: 0] += planetWeight
        }
        
        return weights
    }
}
