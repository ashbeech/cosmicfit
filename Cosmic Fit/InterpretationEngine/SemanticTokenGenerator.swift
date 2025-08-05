//
//  SemanticTokenGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Enhanced with source tracking, improved weighting, and color handling
//  Refactored to use InterpretationTextLibrary

import Foundation

class SemanticTokenGenerator {
    
    // MARK: - Blueprint Specific Token Generation
    
    /// Generate Blueprint tokens with Whole Sign house system according to specification
    static func generateBlueprintTokens(natal: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets with updated weighting and source tracking - using Whole Sign houses
        for planet in natal.planets {
            // Default base weight for natal placements
            let baseWeight: Double = 2.0
            
            // Apply weighting using WeightingModel natal weight FIRST
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Sun": priorityMultiplier = 1.1  // Core identity
            case "Venus": priorityMultiplier = 1.5  // Aesthetic preferences
            case "Moon": priorityMultiplier = 1.3   // Emotional comfort
            case "Mars": priorityMultiplier = 1.2   // Energy and cut
            case "Mercury": priorityMultiplier = 1.0  // Communication style
            case "Jupiter": priorityMultiplier = 0.9  // Philosophy of style
            case "Saturn": priorityMultiplier = 0.8   // Structure and boundaries
            case "Uranus": priorityMultiplier = 0.7   // Unconventional elements
            case "Neptune": priorityMultiplier = 0.6  // Dreamy, ethereal qualities
            case "Pluto": priorityMultiplier = 0.5    // Transformative undercurrents
            default: priorityMultiplier = 0.4
            }
            
            // Apply WeightingModel natal weight at the base level
            let weight = baseWeight * priorityMultiplier * WeightingModel.natalWeight
            
            // Generate tokens for this planet in its sign
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight)
            
            // Apply age-dependent weighting
            let ageWeightedTokens = planetTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedTokens)
        }
        
        // Process ascendant - using WeightingModel natal weight
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign
        
        print("✅ Ascendant tokens generated for sign: \(CoordinateTransformations.getZodiacSignName(sign: ascendantSign))")
        
        let ascendantTokens = tokenizeForPlanetInSign(
            planet: "Ascendant",
            sign: ascendantSign,
            isRetrograde: false,
            weight: 2.5 * WeightingModel.natalWeight)
        
        let ageWeightedAscTokens = ascendantTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAscTokens)
        
        // Add house cusps using WeightingModel natal weight
        let houseCuspTokens = generateHouseCuspTokens(chart: natal, weight: WeightingModel.natalWeight)
        tokens.append(contentsOf: houseCuspTokens)
        
        // Process aspects using WeightingModel natal weight
        let aspectTokens = generateAspectTokens(chart: natal, baseWeight: WeightingModel.natalWeight)
        tokens.append(contentsOf: aspectTokens)
        
        return tokens
    }
    
    // MARK: - Daily Token Generation
    
    /// Generate tokens from transits using the specialized TransitWeightCalculator
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
                
                // Skip insignificant transits
                if transitWeight < 0.5 {
                    continue
                }
                
                // Apply WeightingModel transit weight
                let adjustedTransitWeight: Double = transitWeight * WeightingModel.DailyFit.transitWeight
                
                // Apply tight orb boost for high-impact daily transits
                let tightOrbBoost = orb < 1.0 ? 3.0 : 1.0
                let finalAdjustedTransitWeight = adjustedTransitWeight * tightOrbBoost
                
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
    /// based on day of week and time of day for Daily Fit output
    static func generateDailySignature() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate temporal rhythm tokens
        let calendar = Calendar.current
        let now = Date()
        let dayOfWeek = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        
        // Day of week influence - Enhanced with more nuanced energy patterns
        switch dayOfWeek {
        case 1: // Sunday - Rest and reflection
            tokens.append(StyleToken(
                name: "relaxed",
                type: "mood",
                weight: 0.7,
                aspectSource: "Sunday Energy",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "comfortable",
                type: "texture",
                weight: 0.6,
                aspectSource: "Sunday Energy",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "restorative",
                type: "color_quality",
                weight: 0.5,
                aspectSource: "Sunday Energy",
                originType: .phase
            ))
            
        case 2: // Monday - New beginnings and structure
            tokens.append(StyleToken(
                name: "structured",
                type: "structure",
                weight: 0.8,
                aspectSource: "Monday Momentum",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "purposeful",
                type: "expression",
                weight: 0.7,
                aspectSource: "Monday Momentum",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "crisp",
                type: "texture",
                weight: 0.6,
                aspectSource: "Monday Momentum",
                originType: .phase
            ))
            
        case 3: // Tuesday - Dynamic action and courage
            tokens.append(StyleToken(
                name: "dynamic",
                type: "expression",
                weight: 0.8,
                aspectSource: "Tuesday Drive",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "bold",
                type: "color_quality",
                weight: 0.7,
                aspectSource: "Tuesday Drive",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "energetic",
                type: "mood",
                weight: 0.6,
                aspectSource: "Tuesday Drive",
                originType: .phase
            ))
            
        case 4: // Wednesday - Communication and versatility
            tokens.append(StyleToken(
                name: "versatile",
                type: "structure",
                weight: 0.7,
                aspectSource: "Wednesday Flow",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "articulate",
                type: "expression",
                weight: 0.6,
                aspectSource: "Wednesday Flow",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "adaptable",
                type: "mood",
                weight: 0.5,
                aspectSource: "Wednesday Flow",
                originType: .phase
            ))
            
        case 5: // Thursday - Expansion and wisdom
            tokens.append(StyleToken(
                name: "expansive",
                type: "structure",
                weight: 0.7,
                aspectSource: "Thursday Vision",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "confident",
                type: "expression",
                weight: 0.8,
                aspectSource: "Thursday Vision",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "optimistic",
                type: "mood",
                weight: 0.6,
                aspectSource: "Thursday Vision",
                originType: .phase
            ))
            
        case 6: // Friday - Beauty and social connection
            tokens.append(StyleToken(
                name: "expressive",
                type: "expression",
                weight: 0.9,
                aspectSource: "Friday Magnetism",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "harmonious",
                type: "color_quality",
                weight: 0.8,
                aspectSource: "Friday Magnetism",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "magnetic",
                type: "mood",
                weight: 0.7,
                aspectSource: "Friday Magnetism",
                originType: .phase
            ))
            
        case 7: // Saturday - Discipline meets celebration
            tokens.append(StyleToken(
                name: "balanced",
                type: "structure",
                weight: 0.8,
                aspectSource: "Saturday Balance",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "grounded",
                type: "mood",
                weight: 0.7,
                aspectSource: "Saturday Balance",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "refined",
                type: "texture",
                weight: 0.6,
                aspectSource: "Saturday Balance",
                originType: .phase
            ))
            
        default:
            tokens.append(StyleToken(
                name: "neutral",
                type: "mood",
                weight: 0.4,
                aspectSource: "Default Rhythm",
                originType: .phase
            ))
        }
        
        // Time of day influence - Enhanced with energy transitions
        switch hour {
        case 5..<9: // Early morning - Fresh beginnings
            tokens.append(StyleToken(
                name: "fresh",
                type: "color_quality",
                weight: 0.8,
                aspectSource: "Dawn Energy",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "awakening",
                type: "mood",
                weight: 0.6,
                aspectSource: "Dawn Energy",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "light",
                type: "texture",
                weight: 0.5,
                aspectSource: "Dawn Energy",
                originType: .phase
            ))
            
        case 9..<12: // Late morning - Peak clarity
            tokens.append(StyleToken(
                name: "clear",
                type: "expression",
                weight: 0.7,
                aspectSource: "Morning Clarity",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "focused",
                type: "mood",
                weight: 0.8,
                aspectSource: "Morning Clarity",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "precise",
                type: "structure",
                weight: 0.6,
                aspectSource: "Morning Clarity",
                originType: .phase
            ))
            
        case 12..<15: // Midday - Peak energy and presence
            tokens.append(StyleToken(
                name: "radiant",
                type: "color_quality",
                weight: 0.9,
                aspectSource: "Midday Power",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "powerful",
                type: "expression",
                weight: 0.8,
                aspectSource: "Midday Power",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "commanding",
                type: "mood",
                weight: 0.7,
                aspectSource: "Midday Power",
                originType: .phase
            ))
            
        case 15..<18: // Afternoon - Sustained confidence
            tokens.append(StyleToken(
                name: "confident",
                type: "expression",
                weight: 0.8,
                aspectSource: "Afternoon Strength",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "steady",
                type: "mood",
                weight: 0.7,
                aspectSource: "Afternoon Strength",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "substantial",
                type: "texture",
                weight: 0.6,
                aspectSource: "Afternoon Strength",
                originType: .phase
            ))
            
        case 18..<21: // Evening - Sophistication and transition
            tokens.append(StyleToken(
                name: "sophisticated",
                type: "expression",
                weight: 0.9,
                aspectSource: "Evening Elegance",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "rich",
                type: "color_quality",
                weight: 0.8,
                aspectSource: "Evening Elegance",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "transitional",
                type: "mood",
                weight: 0.6,
                aspectSource: "Evening Elegance",
                originType: .phase
            ))
            
        case 21..<24, 0..<5: // Night - Depth and mystery
            tokens.append(StyleToken(
                name: "mysterious",
                type: "mood",
                weight: 0.8,
                aspectSource: "Night Depth",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "deep",
                type: "color_quality",
                weight: 0.7,
                aspectSource: "Night Depth",
                originType: .phase
            ))
            tokens.append(StyleToken(
                name: "intimate",
                type: "expression",
                weight: 0.6,
                aspectSource: "Night Depth",
                originType: .phase
            ))
            
        default:
            tokens.append(StyleToken(
                name: "neutral",
                type: "mood",
                weight: 0.4,
                aspectSource: "Default Time",
                originType: .phase
            ))
        }
        
        // Add seasonal micro-influence based on month
        let month = calendar.component(.month, from: now)
        switch month {
        case 3, 4, 5: // Spring
            tokens.append(StyleToken(
                name: "renewing",
                type: "mood",
                weight: 0.3,
                aspectSource: "Spring Renewal",
                originType: .phase
            ))
        case 6, 7, 8: // Summer
            tokens.append(StyleToken(
                name: "vibrant",
                type: "color_quality",
                weight: 0.3,
                aspectSource: "Summer Vitality",
                originType: .phase
            ))
        case 9, 10, 11: // Autumn
            tokens.append(StyleToken(
                name: "transformative",
                type: "mood",
                weight: 0.3,
                aspectSource: "Autumn Transformation",
                originType: .phase
            ))
        case 12, 1, 2: // Winter
            tokens.append(StyleToken(
                name: "contemplative",
                type: "mood",
                weight: 0.3,
                aspectSource: "Winter Reflection",
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
            
            var tokens: [StyleToken] = []
            
            // Add all token types for daily fit with debug logging
            DebugLogger.info("🌟 GENERATING COMPLETE DAILY FIT TOKEN SET 🌟")
            
            // Base style resonance - heavily reduced weight for daily fit
            let baseStyleTokens = generateBaseStyleTokens(natal: natal)
            for token in baseStyleTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * WeightingModel.natalWeight, // Apply natal weight
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .natal
                )
                tokens.append(adjustedToken)
            }
            
            // Emotional vibe from progressed chart
            let emotionalTokens = generateEmotionalVibeTokens(natal: natal, progressed: progressed)
            for token in emotionalTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * WeightingModel.progressedWeight, // Apply progressed weight
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .progressed
                )
                tokens.append(adjustedToken)
            }
            
            // Current transit influences
            let transitTokens = generateTransitTokens(transits: transits, natal: natal)
            tokens.append(contentsOf: transitTokens)
            
            // Weather-based practical considerations
            if let weather = weather {
                let weatherTokens = generateWeatherTokens(weather: weather)
                tokens.append(contentsOf: weatherTokens)
            }
            
            // Current Sun sign background energy
            let currentSunTokens = generateCurrentSunSignBackgroundTokens()
            tokens.append(contentsOf: currentSunTokens)
            
            // Moon phase energy
            let moonPhaseTokens = generateMoonPhaseTokens()
            for token in moonPhaseTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * WeightingModel.DailyFit.moonPhaseWeight, // Apply moon phase weight
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .phase
                )
                tokens.append(adjustedToken)
            }
            
            // Daily signature (day of week, time of day)
            let dailySignatureTokens = generateDailySignature()
            tokens.append(contentsOf: dailySignatureTokens)
            
            DebugLogger.info("✅ Complete Daily Fit token set generated: \(tokens.count) tokens")
            
            return tokens
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
        
        // Generate tokens based on moon phase
        switch phasePercentage {
        case 0...12.5: // New Moon
            tokens.append(StyleToken(name: "minimal", type: "structure", weight: 1.5, aspectSource: "New Moon", originType: .phase))
            tokens.append(StyleToken(name: "introspective", type: "mood", weight: 1.3, aspectSource: "New Moon", originType: .phase))
            tokens.append(StyleToken(name: "dark", type: "color", weight: 1.0, aspectSource: "New Moon", originType: .phase))
        case 12.5...37.5: // Waxing Crescent
            tokens.append(StyleToken(name: "emerging", type: "expression", weight: 1.2, aspectSource: "Waxing Crescent", originType: .phase))
            tokens.append(StyleToken(name: "hopeful", type: "mood", weight: 1.0, aspectSource: "Waxing Crescent", originType: .phase))
            tokens.append(StyleToken(name: "subtle", type: "color_quality", weight: 0.8, aspectSource: "Waxing Crescent", originType: .phase))
        case 37.5...62.5: // First Quarter
            tokens.append(StyleToken(name: "decisive", type: "expression", weight: 1.4, aspectSource: "First Quarter", originType: .phase))
            tokens.append(StyleToken(name: "bold", type: "color_quality", weight: 1.2, aspectSource: "First Quarter", originType: .phase))
            tokens.append(StyleToken(name: "structured", type: "structure", weight: 1.0, aspectSource: "First Quarter", originType: .phase))
        case 62.5...87.5: // Waxing Gibbous
            tokens.append(StyleToken(name: "refined", type: "expression", weight: 1.3, aspectSource: "Waxing Gibbous", originType: .phase))
            tokens.append(StyleToken(name: "perfecting", type: "mood", weight: 1.1, aspectSource: "Waxing Gibbous", originType: .phase))
            tokens.append(StyleToken(name: "polished", type: "texture", weight: 0.9, aspectSource: "Waxing Gibbous", originType: .phase))
        case 87.5...100, 0...12.5: // Full Moon (including overlap)
            tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: 1.8, aspectSource: "Full Moon", originType: .phase))
            tokens.append(StyleToken(name: "expressive", type: "expression", weight: 1.6, aspectSource: "Full Moon", originType: .phase))
            tokens.append(StyleToken(name: "luminous", type: "texture", weight: 1.4, aspectSource: "Full Moon", originType: .phase))
        default: // Waning phases
            tokens.append(StyleToken(name: "wise", type: "mood", weight: 1.2, aspectSource: "Waning Moon", originType: .phase))
            tokens.append(StyleToken(name: "reflective", type: "expression", weight: 1.0, aspectSource: "Waning Moon", originType: .phase))
            tokens.append(StyleToken(name: "muted", type: "color_quality", weight: 0.8, aspectSource: "Waning Moon", originType: .phase))
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
    
    /// Generate tokens for the current Sun sign as a background energy influence
    static func generateCurrentSunSignTokens() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Calculate current Sun position
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let sunPosition = AstronomicalCalculator.calculateSunPosition(julianDay: currentJulianDay)
        let (currentSunSign, _) = CoordinateTransformations.decimalDegreesToZodiac(sunPosition.longitude)
        let currentSunSignName = CoordinateTransformations.getZodiacSignName(sign: currentSunSign)
        
        // Get tokens for current Sun sign with appropriate background weight
        let backgroundWeight = WeightingModel.currentSunSignBackgroundWeight
        let sunSignTokens = tokenizeForCurrentSunSign(
            sign: currentSunSign,
            signName: currentSunSignName,
            weight: backgroundWeight
        )
        
        tokens.append(contentsOf: sunSignTokens)
        
        // Debug logging
        DebugLogger.info("🌞 CURRENT SUN SIGN BACKGROUND ENERGY:")
        DebugLogger.info("  • Current Sun in: \(currentSunSignName)")
        DebugLogger.info("  • Background tokens generated: \(sunSignTokens.count)")
        DebugLogger.info("  • Background weight applied: \(backgroundWeight)")
        
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
    
    /// Generate tokens from current weather conditions
    static func generateWeatherTokens(weather: TodayWeather?) -> [StyleToken] {
        guard let weather = weather else { return [] }
        
        var tokens: [StyleToken] = []
        
        // Calculate temperature-based weight (sophisticated logic from generateBaseWeatherTokens)
        let tempWeight = calculateTemperatureWeight(temp: weather.temperature)
        
        // Wind speed processing
        if weather.windKph > 20 { // High wind
            tokens.append(StyleToken(name: "wind-resistant", type: "fabric", weight: 4.0, originType: .weather))
            tokens.append(StyleToken(name: "structured", type: "structure", weight: 3.5, originType: .weather))
            tokens.append(StyleToken(name: "secure", type: "mood", weight: 3.0, originType: .weather))
            tokens.append(StyleToken(name: "protective", type: "texture", weight: 2.5, originType: .weather))
        } else if weather.windKph > 10 { // Moderate wind
            tokens.append(StyleToken(name: "stable", type: "structure", weight: 2.0, originType: .weather))
            tokens.append(StyleToken(name: "reliable", type: "mood", weight: 1.5, originType: .weather))
        }
        
        // Temperature-based tokens with calculated weights
        if weather.temperature < 10 {
            tokens.append(StyleToken(name: "insulating", type: "fabric", weight: tempWeight, originType: .weather))
            tokens.append(StyleToken(name: "layerable", type: "structure", weight: tempWeight * 0.8, originType: .weather))
            tokens.append(StyleToken(name: "protective", type: "texture", weight: tempWeight * 0.7, originType: .weather))
            tokens.append(StyleToken(name: "warm", type: "texture", weight: tempWeight * 0.6, originType: .weather))
            tokens.append(StyleToken(name: "cozy", type: "mood", weight: tempWeight * 0.5, originType: .weather))
        } else if weather.temperature > 25 {
            tokens.append(StyleToken(name: "breathable", type: "fabric", weight: tempWeight, originType: .weather))
            tokens.append(StyleToken(name: "lightweight", type: "texture", weight: tempWeight * 0.8, originType: .weather))
            tokens.append(StyleToken(name: "airy", type: "structure", weight: tempWeight * 0.7, originType: .weather))
            tokens.append(StyleToken(name: "cool", type: "texture", weight: tempWeight * 0.6, originType: .weather))
            tokens.append(StyleToken(name: "breathable", type: "structure", weight: tempWeight * 0.5, originType: .weather))
        }
        
        // Weather condition-based tokens
        switch weather.condition.lowercased() {
        case let condition where condition.contains("rain") || condition.contains("shower"):
            tokens.append(StyleToken(name: "waterproof", type: "fabric", weight: 3.0, originType: .weather))
            tokens.append(StyleToken(name: "practical", type: "structure", weight: 2.5, originType: .weather))
            tokens.append(StyleToken(name: "protective", type: "texture", weight: 0.8, originType: .weather))
        case let condition where condition.contains("drizzle"):
            tokens.append(StyleToken(name: "water-resistant", type: "fabric", weight: 2.0, originType: .weather))
            tokens.append(StyleToken(name: "practical", type: "structure", weight: 1.5, originType: .weather))
        case let condition where condition.contains("sun") || condition.contains("clear"):
            tokens.append(StyleToken(name: "light-reflecting", type: "texture", weight: 2.0, originType: .weather))
            tokens.append(StyleToken(name: "cooling", type: "structure", weight: 1.8, originType: .weather))
            tokens.append(StyleToken(name: "bright", type: "color_quality", weight: 0.8, originType: .weather))
            tokens.append(StyleToken(name: "light", type: "texture", weight: 0.7, originType: .weather))
        case let condition where condition.contains("cloud") || condition.contains("overcast"):
            tokens.append(StyleToken(name: "layered", type: "structure", weight: 0.6, originType: .weather))
            tokens.append(StyleToken(name: "muted", type: "color_quality", weight: 0.5, originType: .weather))
        default:
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: 1.0, originType: .weather))
        }
        
        // Apply WeightingModel weather weight to all tokens
        return tokens.map { token in
            StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * WeightingModel.DailyFit.weatherWeight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .weather
            )
        }
    }
    
    private static func calculateTemperatureWeight(temp: Double) -> Double {
        switch temp {
        case ...0:      return 8.0  // Freezing - MUST override cosmic suggestions
        case 1...10:    return 6.0  // Cold - strong override
        case 11...15:   return 3.0  // Cool - moderate influence
        case 16...24:   return 1.0  // Mild - minimal influence
        case 25...29:   return 3.0  // Warm - moderate influence
        case 30...34:   return 6.0  // Hot - strong override
        default:        return 8.0  // Scorching - MUST override
        }
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
    
    private static func getCurrentSunSignBackgroundTokens(sunSign: String) -> [(String, String)] {
        switch sunSign {
        case "Aries":
            return [("energetic", "mood"), ("bold", "color_quality"), ("dynamic", "expression"), ("fiery", "texture")]
        case "Taurus":
            return [("grounded", "mood"), ("luxurious", "texture"), ("sensual", "color_quality"), ("stable", "structure")]
        case "Gemini":
            return [("versatile", "expression"), ("bright", "color_quality"), ("communicative", "mood"), ("airy", "texture")]
        case "Cancer":
            return [("nurturing", "mood"), ("protective", "structure"), ("pearl", "color"), ("emotional", "expression")]
        case "Leo":
            return [("radiant", "color_quality"), ("bold", "expression"), ("warm", "texture"), ("dramatic", "mood")]
        case "Virgo":
            return [("precise", "structure"), ("refined", "texture"), ("practical", "mood"), ("earthy", "color_quality")]
        case "Libra":
            return [("harmonious", "mood"), ("elegant", "expression"), ("balanced", "structure"), ("beautiful", "color_quality")]
        case "Scorpio":
            return [("intense", "mood"), ("transformative", "expression"), ("mysterious", "color_quality"), ("deep", "texture")]
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
                    
                    if orb < 1.0 {
                        aspectWeight += 0.5
                    } else if orb > 3.0 {
                        aspectWeight -= 0.3
                    }
                    
                    tokens.append(StyleToken(
                        name: getAspectMoodToken(aspectType: aspectType),
                        type: "mood",
                        weight: aspectWeight,
                        planetarySource: "\(planet1.name)-\(planet2.name)",
                        aspectSource: aspectSource
                    ))
                }
            }
        }
        
        return tokens
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
}
