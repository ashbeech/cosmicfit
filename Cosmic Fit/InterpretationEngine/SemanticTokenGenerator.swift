//
//  SemanticTokenGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Enhanced with source tracking, improved weighting, and color handling
//  Refactored to use InterpretationTextLibrary

/*
 STYLE ENGINE HIERARCHY:
 
 | Layer                        | Role                               | Dynamic?             |
 | ---------------------------- | ---------------------------------- | -------------------- |
 | **Natal Sun/Moon/Venus**     | Core style signature               | ❌ No fade            |
 | **Ascendant**                | Early mask / social adaptation     | ✅ Fades with age     |
 | **Progressed Inner Planets** | Emotional tone, texture overlays   | ♻ Ongoing modulation |
 | **Transits**                 | Daily color/shape/emotional shifts | ✅ Weighted impact    |
 
 Progressed chart acts as a STYLE MODULATOR, not replacer:
 - Modifies *Finish*: matte vs glossy (→ texture tokens)
 - Shifts *Tone*: bright vs muted (→ color_quality tokens)
 - Adjusts *Pairing logic*: layered vs monochrome (→ structure tokens)
 
 Progressed tokens are never allowed to introduce colors or fabrics that directly conflict
 with natal base palette - they enhance rather than replace.
 */

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
            
            // Apply weighting using WeightingModel natal weight
            var priorityMultiplier: Double = WeightingModel.natalWeight
            switch planet.name {
            case "Sun": priorityMultiplier *= 1.1  // Core identity
            case "Venus": priorityMultiplier *= 1.5  // Aesthetic preferences
            case "Moon": priorityMultiplier *= 1.3   // Emotional comfort
            case "Mars": priorityMultiplier *= 1.2   // Energy and cut
            case "Mercury": priorityMultiplier *= 1.0  // Communication style
            case "Jupiter": priorityMultiplier *= 0.9  // Philosophy of style
            case "Saturn": priorityMultiplier *= 0.8   // Structure and boundaries
            case "Uranus": priorityMultiplier *= 0.7   // Unconventional elements
            case "Neptune": priorityMultiplier *= 0.6  // Dreamy, ethereal qualities
            case "Pluto": priorityMultiplier *= 0.5    // Transformative undercurrents
            default: priorityMultiplier *= 0.4
            }
            
            let weight = baseWeight * priorityMultiplier
            
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
        
        /*
        // Add moon phase influence using WeightingModel moon phase weight
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
        let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
        
        for token in moonPhaseTokens {
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * WeightingModel.moonPhaseWeight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .phase
            )
            tokens.append(adjustedToken)
        }
        
        // Generate moon phase color tokens using WeightingModel moon phase weight
        let moonColorTokens = generateMoonPhaseColorTokens(moonPhase: lunarPhase, weight: WeightingModel.moonPhaseWeight)
        tokens.append(contentsOf: moonColorTokens)
        */
        
        return tokens
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
        
    /// Generate tokens for base style resonance (100% natal, Whole Sign)
    static func generateBaseStyleTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return generateBlueprintTokens(natal: natal)
    }
    
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
            
            /*
            // Add moon phase influence using WeightingModel moon phase weight
            let currentDate = Date()
            let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
            let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
            let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
            let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
            
            for token in moonPhaseTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * WeightingModel.moonPhaseWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .phase
                )
                tokens.append(adjustedToken)
            }
             */
            
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
        
        /*
        // Add moon phase influence using WeightingModel moon phase weight
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
        let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
        
        for token in moonPhaseTokens {
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * WeightingModel.moonPhaseWeight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .phase
            )
            tokens.append(adjustedToken)
        }
         */
        
        return tokens
    }
    
    // MARK: - Transit Token Generation
    
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

                // Get influence category and token weight scale
                let influenceCategory = TransitWeightCalculator.getStyleInfluenceCategory(weight: adjustedTransitWeight)
                let tokenScale: Double = TransitWeightCalculator.getTokenWeightScale(for: influenceCategory)

                // Generate tokens based on the transit with aspect source tracking
                let aspectSource = "\(transitPlanet) \(aspectType) \(natalPlanet)"
                let finalWeight: Double = adjustedTransitWeight * tokenScale
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
    
    // MARK: - Weather Token Generation
    
    /// Generate weather tokens using WeightingModel weather weight
    static func generateWeatherTokens(weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate base weather tokens
        let baseTokens = generateBaseWeatherTokens(weather: weather)
        
        // Apply WeightingModel weather weight
        for token in baseTokens {
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * WeightingModel.DailyFit.weatherWeight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .weather
            )
            tokens.append(adjustedToken)
        }
        
        return tokens
    }
    
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
    
    private static func generateBaseWeatherTokens(weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        let tempWeight = calculateTemperatureWeight(temp: weather.temperature)
        
        if weather.temperature < 10 {
            tokens.append(StyleToken(name: "insulating", type: "fabric", weight: tempWeight, originType: .weather))
            tokens.append(StyleToken(name: "layerable", type: "structure", weight: tempWeight * 0.8, originType: .weather))
            tokens.append(StyleToken(name: "protective", type: "texture", weight: tempWeight * 0.7, originType: .weather))
        } else if weather.temperature > 25 {
            tokens.append(StyleToken(name: "breathable", type: "fabric", weight: tempWeight, originType: .weather))
            tokens.append(StyleToken(name: "lightweight", type: "texture", weight: tempWeight * 0.8, originType: .weather))
            tokens.append(StyleToken(name: "airy", type: "structure", weight: tempWeight * 0.7, originType: .weather))
        }
        
        switch weather.condition.lowercased() {
        case let condition where condition.contains("rain"):
            tokens.append(StyleToken(name: "waterproof", type: "fabric", weight: 3.0, originType: .weather))
            tokens.append(StyleToken(name: "practical", type: "structure", weight: 2.5, originType: .weather))
        case let condition where condition.contains("sun"):
            tokens.append(StyleToken(name: "light-reflecting", type: "texture", weight: 2.0, originType: .weather))
            tokens.append(StyleToken(name: "cooling", type: "structure", weight: 1.8, originType: .weather))
        default:
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: 1.0, originType: .weather))
        }
        
        return tokens
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
    
    private static func generateHouseCuspTokens(chart: NatalChartCalculator.NatalChart, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Sample implementation - would need actual house cusp calculation
        for i in 1...12 {
            if i == 1 || i == 7 || i == 4 || i == 10 {
                tokens.append(StyleToken(
                    name: "angular",
                    type: "structure",
                    weight: weight * 0.5,
                    houseSource: i,
                    originType: .natal
                ))
            }
        }
        
        return tokens
    }
    
    // Replace this function around line 784:
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
    
    // Replace this function around line 858:
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
