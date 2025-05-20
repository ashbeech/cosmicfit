//
//  SemanticTokenGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Enhanced with source tracking, improved weighting, and color handling

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
            
            // Apply weighting according to spec
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Sun": priorityMultiplier = 1.1  // Core identity
            case "Venus": priorityMultiplier = 1.5  // Aesthetic preferences
            case "Moon": priorityMultiplier = 1.3   // Emotional comfort
            case "Mars": priorityMultiplier = 1.2   // Energy and cut
            case "Mercury": priorityMultiplier = 1.1 // Communication style
            case "Jupiter": priorityMultiplier = 0.9 // Expansion, principles
            case "Saturn": priorityMultiplier = 0.9  // Structure, discipline
            default: priorityMultiplier = 0.8        // Outer planets
            }
            
            let weight = baseWeight * priorityMultiplier
            
            // Get tokens based on planet in sign with source tracking
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight)
            
            // Apply age-dependent weighting for each token
            let ageWeightedTokens = planetTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedTokens)
        }
        
        // Process rising sign (ascendant) - high influence on appearance
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascendantSign)
        let ascendantTokens = tokenizeForAscendant(
            sign: ascendantSign,
            signName: ascSignName,
            weight: 3.0)
        
        // Apply age-dependent weighting for ascendant tokens
        let ageWeightedAscTokens = ascendantTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAscTokens)
        
        // Process Whole Sign house placements with source tracking
        for planet in natal.planets {
            // Determine house by using Whole Sign system for Blueprint
            let wholeSignHouse = NatalChartCalculator.determineWholeSignHouse(
                longitude: planet.longitude,
                ascendant: natal.ascendant)
            
            // Higher weight for fashion-relevant planets in visible houses
            let houseWeight = isVisibleHouse(wholeSignHouse) ? 2.5 : 2.0
            
            let houseTokens = tokenizeForPlanetInHouse(
                planet: planet.name,
                house: wholeSignHouse,
                weight: houseWeight)
            
            // Apply age-dependent weighting
            let ageWeightedHouseTokens = houseTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedHouseTokens)
        }
        
        // Generate elemental balance tokens with enhanced color tokens
        let elementalTokens = generateElementalColorTokens(chart: natal)
        let ageWeightedElementalTokens = elementalTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedElementalTokens)
        
        // Generate aspect-based tokens including aspect color tokens
        let aspectTokens = generateAspectTokens(chart: natal)
        let aspectColorTokens = generateAspectColorTokens(chart: natal)
        let ageWeightedAspectTokens = (aspectTokens + aspectColorTokens).map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAspectTokens)
        
        // Get current lunar phase and add moon phase tokens
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
        let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
        
        // Add color palette from moon phase
        let colorPalette = MoonPhaseInterpreter.colorPaletteForPhase(phase: moonPhase)
        var moonColorTokens: [StyleToken] = []
        for (index, color) in colorPalette.enumerated() {
            // Give higher weight to the first colors in the palette
            let weight = 1.5 - (Double(index) * 0.2)
            moonColorTokens.append(StyleToken(
                name: color,
                type: "color",
                weight: weight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Moon Phase: \(moonPhase.description)"
            ))
        }
        
        tokens.append(contentsOf: moonPhaseTokens)
        tokens.append(contentsOf: moonColorTokens)
        
        return tokens
    }
    
    // MARK: - Color Frequency Token Generation
    
    /// Generate tokens for Color Frequency section (70% natal, 30% progressed)
    static func generateColorFrequencyTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Generate natal tokens with 70% weight - these establish core colors
            let natalTokens = generateNatalColorTokens(natal, currentAge: currentAge)
            for token in natalTokens {
                // Create a new token with adjusted weight
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.7,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .natal
                )
                tokens.append(adjustedToken)
            }
            
            // Generate progressed tokens with 30% weight
            // MODULATION: Only apply progressed influences to texture, color_quality, and structure
            // This ensures progressed chart acts as a style modulator, not a replacer
            let progressedTokens = generateProgressedColorTokens(progressed)
            for token in progressedTokens {
                // Skip tokens that introduce new colors - only keep modulating tokens
                if token.type == "color" {
                    continue // Skip actual colors from progressed chart
                }
                
                // Keep only tokens that modulate finish, tone, and pairing logic
                if ["texture", "color_quality", "structure"].contains(token.type) {
                    let adjustedToken = StyleToken(
                        name: token.name,
                        type: token.type,
                        weight: token.weight * 0.3, // progressions limited to flavor
                        planetarySource: token.planetarySource,
                        signSource: token.signSource,
                        houseSource: token.houseSource,
                        aspectSource: token.aspectSource,
                        originType: .progressed
                    )
                    tokens.append(adjustedToken)
                }
            }
            
            // Add moon phase influence on colors
            let currentDate = Date()
            let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
            let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
            let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
            
            // Get color palette from moon phase
            let colorPalette = MoonPhaseInterpreter.colorPaletteForPhase(phase: moonPhase)
            
            // Convert color palette to tokens
            for (index, color) in colorPalette.enumerated() {
                // Give higher weight to the first colors in the palette
                let weight = 1.5 - (Double(index) * 0.2)
                tokens.append(StyleToken(
                    name: color,
                    type: "color",
                    weight: weight,
                    planetarySource: nil,
                    signSource: nil,
                    houseSource: nil,
                    aspectSource: "Moon Phase: \(moonPhase.description)",
                    originType: .phase
                ))
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
            
            // Prioritize color-relevant planets
            switch planet.name {
            case "Venus": priorityMultiplier = 1.6  // Highest influence on color preferences
            case "Moon": priorityMultiplier = 1.4   // Emotional color connections
            case "Sun": priorityMultiplier = 1.2    // Identity colors
            case "Mars": priorityMultiplier = 1.1   // Energy colors
            case "Neptune": priorityMultiplier = 1.0 // Dreamy color influences
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            // Generate specific color tokens based on planet in sign
            let colorTokens = generateColorTokensForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                weight: weight,
                isRetrograde: planet.isRetrograde)
            
            // Apply age-dependent weighting
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
        
        // Apply age-dependent weighting
        let ageWeightedAscTokens = ascendantColorTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAscTokens)
        
        // Add elemental color tokens
        let elementalTokens = generateElementalColorTokens(chart: chart)
        tokens.append(contentsOf: elementalTokens)
        
        // Add aspect-based color tokens - NEW
        let aspectColorTokens = generateAspectColorTokens(chart: chart)
        tokens.append(contentsOf: aspectColorTokens)
        
        // Process aspects with relevant planets for color nuance - NEW
        tokens.append(contentsOf: generateColorNuanceFromAspects(chart: chart))
        
        // Generate color palette based on planetary dignity - NEW
        tokens.append(contentsOf: generateColorTokensFromDignities(chart: chart))
        
        return tokens
    }
    
    /// Generate color tokens from progressed chart
    private static func generateProgressedColorTokens(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Focus on the most relevant progressed planets for color
        let relevantPlanets = ["Moon", "Venus", "Sun"]
        
        for planet in chart.planets where relevantPlanets.contains(planet.name) {
            let baseWeight: Double = 1.8  // Slightly lower than natal
            
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Venus": priorityMultiplier = 1.5
            case "Moon": priorityMultiplier = 1.3
            case "Sun": priorityMultiplier = 1.2
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            // Generate color tokens with progressed flag
            let colorTokens = generateColorTokensForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                weight: weight,
                isProgressed: true)
            
            tokens.append(contentsOf: colorTokens)
        }
        
        // Add a few general progressed energy tokens
        tokens.append(StyleToken(
            name: "evolving",
            type: "color_quality",
            weight:
                1.5,
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
    
    // MARK: - Enhanced Color Token Generation
    
    /// Generate aspect-based color tokens specifically for color nuance
    static func generateAspectColorTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Look for significant color-influencing aspects
        for i in 0..<chart.planets.count {
            let planet1 = chart.planets[i]
            // Focus on Venus, Moon, Sun, Neptune, and Mars for color aspects
            if !["Venus", "Moon", "Sun", "Neptune", "Mars"].contains(planet1.name) { continue }
            
            for j in (i+1)..<chart.planets.count {
                let planet2 = chart.planets[j]
                if !["Venus", "Moon", "Sun", "Neptune", "Mars"].contains(planet2.name) { continue }
                
                // Check for aspect
                if let (aspectType, orb) = AstronomicalCalculator.calculateAspect(
                    point1: planet1.longitude,
                    point2: planet2.longitude,
                    orb: 5.0) {
                    
                    let aspectSource = "\(planet1.name) \(aspectType) \(planet2.name)"
                    var aspectWeight = 1.8
                    
                    // Close orbs get higher weight
                    if orb < 1.0 {
                        aspectWeight += 0.4
                    }
                    
                    // Generate color tokens based on the aspect
                    switch aspectType {
                    case "Conjunction":
                        // Planets merged - intensified, pure color
                        if planet1.name == "Venus" && planet2.name == "Moon" {
                            tokens.append(StyleToken(
                                name: "iridescent pearl",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Venus-Moon",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "luminous",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Venus-Moon",
                                aspectSource: aspectSource
                            ))
                        } else if planet1.name == "Venus" && planet2.name == "Sun" {
                            tokens.append(StyleToken(
                                name: "radiant gold",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Venus-Sun",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "warm champagne",
                                type: "color",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Venus-Sun",
                                aspectSource: aspectSource
                            ))
                        } else if planet1.name == "Moon" && planet2.name == "Neptune" {
                            tokens.append(StyleToken(
                                name: "moonlit aqua",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Moon-Neptune",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "dream blue",
                                type: "color",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Moon-Neptune",
                                aspectSource: aspectSource
                            ))
                        } else if planet1.name == "Venus" && planet2.name == "Neptune" {
                            tokens.append(StyleToken(
                                name: "opalescent lavender",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Venus-Neptune",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "ethereal",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Venus-Neptune",
                                aspectSource: aspectSource
                            ))
                        } else if planet1.name == "Mars" && planet2.name == "Venus" {
                            tokens.append(StyleToken(
                                name: "passionate crimson",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Mars-Venus",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "dynamic",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Mars-Venus",
                                aspectSource: aspectSource
                            ))
                        }
                        
                    case "Trine":
                        // Harmonious flow between planets - blended colors
                        if (planet1.name == "Venus" || planet2.name == "Venus") &&
                            (planet1.name == "Neptune" || planet2.name == "Neptune") {
                            tokens.append(StyleToken(
                                name: "oceanic teal",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Venus-Neptune",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "flowing",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Venus-Neptune",
                                aspectSource: aspectSource
                            ))
                        } else if (planet1.name == "Moon" || planet2.name == "Moon") &&
                                    (planet1.name == "Venus" || planet2.name == "Venus") {
                            tokens.append(StyleToken(
                                name: "luminous mother of pearl",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Moon-Venus",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "harmonious",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Moon-Venus",
                                aspectSource: aspectSource
                            ))
                        } else if (planet1.name == "Sun" || planet2.name == "Sun") &&
                                    (planet1.name == "Venus" || planet2.name == "Venus") {
                            tokens.append(StyleToken(
                                name: "warm amber",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Sun-Venus",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "honeyed",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Sun-Venus",
                                aspectSource: aspectSource
                            ))
                        }
                        
                    case "Square":
                        // Tension between planets - contrasting colors
                        if (planet1.name == "Venus" || planet2.name == "Venus") &&
                            (planet1.name == "Mars" || planet2.name == "Mars") {
                            tokens.append(StyleToken(
                                name: "dynamic burgundy",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Venus-Mars",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "contrasting",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Venus-Mars",
                                aspectSource: aspectSource
                            ))
                        } else if (planet1.name == "Moon" || planet2.name == "Moon") &&
                                    (planet1.name == "Venus" || planet2.name == "Venus") {
                            tokens.append(StyleToken(
                                name: "complex slate blue",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Moon-Venus",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "dualistic",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Moon-Venus",
                                aspectSource: aspectSource
                            ))
                        }
                        
                    case "Opposition":
                        // Polarized planets - complementary colors
                        if (planet1.name == "Venus" || planet2.name == "Venus") &&
                            (planet1.name == "Neptune" || planet2.name == "Neptune") {
                            tokens.append(StyleToken(
                                name: "mysterious indigo",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Venus-Neptune",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "counterbalanced",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Venus-Neptune",
                                aspectSource: aspectSource
                            ))
                        } else if (planet1.name == "Sun" || planet2.name == "Sun") &&
                                    (planet1.name == "Moon" || planet2.name == "Moon") {
                            tokens.append(StyleToken(
                                name: "balanced silver-gold",
                                type: "color",
                                weight: aspectWeight,
                                planetarySource: "Sun-Moon",
                                aspectSource: aspectSource
                            ))
                            tokens.append(StyleToken(
                                name: "complementary",
                                type: "color_quality",
                                weight: aspectWeight - 0.2,
                                planetarySource: "Sun-Moon",
                                aspectSource: aspectSource
                            ))
                        }
                        
                    default:
                        // Minor aspects - subtle color influences
                        if (planet1.name == "Venus" || planet2.name == "Venus") {
                            tokens.append(StyleToken(
                                name: "subtle",
                                type: "color_quality",
                                weight: aspectWeight - 0.5,
                                planetarySource: "\(planet1.name)-\(planet2.name)",
                                aspectSource: aspectSource
                            ))
                        }
                    }
                }
            }
        }
        
        return tokens
    }
    
    /// Generate specialized color tokens based on planet in a sign
    private static func generateColorTokensForPlanetInSign(
        planet: String,
        sign: Int,
        weight: Double,
        isProgressed: Bool = false,
        isRetrograde: Bool = false) -> [StyleToken] {
            
            
            var tokens: [StyleToken] = []
            let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
            let source = isProgressed ? "Progressed \(planet)" : planet
            
            // ENHANCED: More detailed color palette based on planet and sign
            switch planet {
            case "Sun":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "bright vermilion", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "poppy red", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "energetic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "deep moss green", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "rich olive", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "earthy", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "substantial", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "bright canary yellow", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "citrine", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "bright", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "moonlit silver", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "mother of pearl", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "luminous", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "reflective", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "royal gold", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "burnished amber", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "regal", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "warm wheat", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "soft taupe", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "refined", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "delicate rose pink", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "soft mauve", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "deep oxblood", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "intense maroon", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "deep", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "mysterious", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "rich cobalt blue", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "royal purple", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "bold", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "deep graphite", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "slate grey", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "enduring", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "electric blue", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "neon turquoise", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "futuristic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "iridescent aqua", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "ocean teal", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "flowing", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "ethereal", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                default:
                    break
                }
                
            case "Moon":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "coral blush", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "warm terracotta", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "emotive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "vivid", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "soft sage green", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "mossy celadon", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "comforting", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "nurturing", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "pale buttercream", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "luminous primrose", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "versatile", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "adaptive", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "lustrous pearl", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "moonstone white", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "receptive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "iridescent", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "warm honey", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "amber gold", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "warm", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "glowing", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "stoneware taupe", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "soft chamois", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "careful", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "detailed", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "tender lavender", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "soft lilac", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "delicate", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "midnight plum", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "shadowed amethyst", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "profound", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "transformative", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "midnight sapphire", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "deepest azure", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "philosophical", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "smoky slate", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "graphite grey", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "disciplined", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "enduring", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "glacial turquoise", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "electric ice blue", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "visionary", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "mist seafoam", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "opalescent azure", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "dreamy", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "transcendent", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                default:
                    break
                }
                
            case "Venus":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "vibrant coral", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "warm peach", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "passionate", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "rich emerald", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "deep jade", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "luxurious", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "tactile", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "fresh apricot", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "luminous peach", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "playful", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "versatile", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "mother of pearl", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "soft cream", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "nurturing", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "protective", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "sunlit gold", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "burnished bronze", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "glamorous", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "soft sage", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "herbal green", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "refined", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "considerate", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "rose quartz", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "soft blush", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "elegant", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "deep wine", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "rich burgundy", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "magnetic", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "peacock teal", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "vibrant turquoise", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "optimistic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "burgundy wine", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "aged merlot", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "refined", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "timeless", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "lavender blue", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "periwinkle", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "futuristic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "misty lilac", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "opalescent lavender", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "dreamy", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "mystical", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                default:
                    break
                }
                
            case "Mars":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "blazing crimson", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "fire engine red", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "energetic", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "bold", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "terracotta rust", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "earthy sienna", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "substantial", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "zesty orange", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "bright coral", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "lively", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "quick", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "dark ruby", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "garnet", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "protective", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "defensive", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "burnished copper", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "fiery bronze", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "commanding", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "dramatic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "rustic brick", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "warm terracotta", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "efficient", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "dusty rose", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "balanced coral", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "purposeful", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "diplomatic", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "darkest burgundy", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "blood red", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "powerful", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "royal magenta", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "dynamic violet", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "adventurous", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "mahogany brown", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "deep cedar", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "disciplined", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "electric magenta", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "neon rust", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "progressive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "revolutionary", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "deep ocean blue", type: "color", weight: weight, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "complex teal", type: "color", weight: weight - 0.2, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "spiritual", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "intuitive", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                default:
                    break
                }
                
            case "Mercury":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "clear red", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "crisp", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "verdant olive", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "textured", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "bright lemon", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "varied", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "pearlescent silver", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "nuanced", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "bright amber", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "distinct", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "wheat brown", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced mauve", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "penetrating burgundy", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "incisive", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "clear sapphire", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "direct", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "defined graphite", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "electric cerulean", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "shifting aquamarine", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "fluid", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                default:
                    break
                }
                
            case "Neptune":
                // Neptune brings dreamy, ethereal colors
                tokens.append(StyleToken(name: "opalescent blue", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "mermaid teal", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "misty lavender", type: "color", weight: weight - 0.5, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "ethereal", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "dreamlike", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                
            case "Pluto":
                // Pluto brings intense, transformative colors
                tokens.append(StyleToken(name: "abyssal black", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "plutonium purple", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "transformative", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                
            case "Jupiter":
                // Jupiter brings abundant, expansive colors
                tokens.append(StyleToken(name: "royal purple", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "abundant indigo", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "abundant", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                
            case "Saturn":
                // Saturn brings structured, solid colors
                tokens.append(StyleToken(name: "structured charcoal", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "leaden grey", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "disciplined", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "enduring", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                
            case "Uranus":
                // Uranus brings electric, unexpected colors
                tokens.append(StyleToken(name: "electric blue", type: "color", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "neon turquoise", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "unexpected", type: "color_quality", weight: weight - 0.3, planetarySource: source, signSource: signName))
                tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.4, planetarySource: source, signSource: signName))
                
            default:
                // For other planets, add elemental tokens
                switch signName {
                case "Aries", "Leo", "Sagittarius":
                    tokens.append(StyleToken(name: "fiery", type: "mood", weight: weight * 0.8, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "warm bronze", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.5, planetarySource: source, signSource: signName))
                case "Taurus", "Virgo", "Capricorn":
                    tokens.append(StyleToken(name: "earthy", type: "mood", weight: weight * 0.8, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "rich brown", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: weight - 0.5, planetarySource: source, signSource: signName))
                case "Gemini", "Libra", "Aquarius":
                    tokens.append(StyleToken(name: "airy", type: "mood", weight: weight * 0.8, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "clear azure", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "light", type: "color_quality", weight: weight - 0.5, planetarySource: source, signSource: signName))
                case "Cancer", "Scorpio", "Pisces":
                    tokens.append(StyleToken(name: "watery", type: "mood", weight: weight * 0.8, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "oceanic teal", type: "color", weight: weight - 0.4, planetarySource: source, signSource: signName))
                    tokens.append(StyleToken(name: "fluid", type: "color_quality", weight: weight - 0.5, planetarySource: source, signSource: signName))
                default:
                    break
                }
            }
            
            // Add retrograde tokens if applicable with source tracking
            if isRetrograde {
                tokens.append(StyleToken(name: "muted", type: "color_quality", weight: weight * 0.8, planetarySource: source, signSource: signName, aspectSource: "Retrograde"))
                tokens.append(StyleToken(name: "contemplative", type: "color_quality", weight: weight * 0.7, planetarySource: source, signSource: signName, aspectSource: "Retrograde"))
                
                // Add specific retrograde color modifications
                if ["Venus", "Mercury", "Mars"].contains(planet) {
                    tokens.append(StyleToken(name: "vintage", type: "color_quality", weight: weight * 0.7, planetarySource: source, signSource: signName, aspectSource: "Retrograde"))
                    
                    // Add specific color modifications for retrograde planets
                    switch planet {
                    case "Venus":
                        tokens.append(StyleToken(name: "faded rose", type: "color", weight: weight * 0.7, planetarySource: source, signSource: signName, aspectSource: "Retrograde"))
                    case "Mars":
                        tokens.append(StyleToken(name: "smoldering brick", type: "color", weight: weight * 0.7, planetarySource: source, signSource: signName, aspectSource: "Retrograde"))
                    case "Mercury":
                        tokens.append(StyleToken(name: "misty grey", type: "color", weight: weight * 0.7, planetarySource: source, signSource: signName, aspectSource: "Retrograde"))
                    default:
                        break
                    }
                }
            }
            
            return tokens
        }
    
    /// Generate color tokens for Ascendant
    private static func generateColorTokensForAscendant(
        sign: Int,
        signName: String,
        weight: Double) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // ENHANCED: More specific color variations for ascendant
            switch signName {
            case "Aries":
                tokens.append(StyleToken(name: "vibrant crimson", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "dynamic vermilion", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "bold", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "energetic", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Taurus":
                tokens.append(StyleToken(name: "rich moss green", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "deep olive", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "substantial", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Gemini":
                tokens.append(StyleToken(name: "bright lemon yellow", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "vibrant citrine", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "versatile", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "communicative", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Cancer":
                tokens.append(StyleToken(name: "luminous silver", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "pearlescent white", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "protective", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "reflective", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Leo":
                tokens.append(StyleToken(name: "regal gold", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "sunlit amber", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "commanding", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Virgo":
                tokens.append(StyleToken(name: "warm taupe", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "soft beige", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "refined", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Libra":
                tokens.append(StyleToken(name: "delicate blush pink", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "balanced mauve", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "elegant", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Scorpio":
                tokens.append(StyleToken(name: "deep oxblood", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "intense burgundy", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "mysterious", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "magnetic", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Sagittarius":
                tokens.append(StyleToken(name: "rich indigo", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "deep royal purple", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "adventurous", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Capricorn":
                tokens.append(StyleToken(name: "polished graphite", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "deep charcoal", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "authoritative", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Aquarius":
                tokens.append(StyleToken(name: "electric cerulean", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "neon azure", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "futuristic", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            case "Pisces":
                tokens.append(StyleToken(name: "iridescent aqua", type: "color", weight: weight, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "misty seafoam", type: "color", weight: weight - 0.2, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "ethereal", type: "color_quality", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName))
                tokens.append(StyleToken(name: "dreamy", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName))
            default:
                break
            }
            
            // Add elemental token based on the sign
            if ["Aries", "Leo", "Sagittarius"].contains(signName) {
                tokens.append(StyleToken(name: "fiery", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName))
            } else if ["Taurus", "Virgo", "Capricorn"].contains(signName) {
                tokens.append(StyleToken(name: "earthy", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName))
            } else if ["Gemini", "Libra", "Aquarius"].contains(signName) {
                tokens.append(StyleToken(name: "airy", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName))
            } else if ["Cancer", "Scorpio", "Pisces"].contains(signName) {
                tokens.append(StyleToken(name: "watery", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName))
            }
            
            return tokens
        }
    
    /// Generate elemental color tokens from chart
    private static func generateElementalColorTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Count planets by element
        var fireCount = 0
        var earthCount = 0
        var airCount = 0
        var waterCount = 0
        
        for planet in chart.planets {
            let signName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            
            if ["Aries", "Leo", "Sagittarius"].contains(signName) {
                fireCount += 1
            } else if ["Taurus", "Virgo", "Capricorn"].contains(signName) {
                earthCount += 1
            } else if ["Gemini", "Libra", "Aquarius"].contains(signName) {
                airCount += 1
            } else if ["Cancer", "Scorpio", "Pisces"].contains(signName) {
                waterCount += 1
            }
        }
        
        // Add Ascendant to the count
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascSign)
        
        if ["Aries", "Leo", "Sagittarius"].contains(ascSignName) {
            fireCount += 1
        } else if ["Taurus", "Virgo", "Capricorn"].contains(ascSignName) {
            earthCount += 1
        } else if ["Gemini", "Libra", "Aquarius"].contains(ascSignName) {
            airCount += 1
        } else if ["Cancer", "Scorpio", "Pisces"].contains(ascSignName) {
            waterCount += 1
        }
        
        // Add elemental color tokens based on dominance
        let total = fireCount + earthCount + airCount + waterCount
        let threshold = total / 4
        
        // ENHANCED: More nuanced elemental color tokens
        if fireCount > threshold + 1 {
            tokens.append(StyleToken(name: "blazing vermilion", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
            tokens.append(StyleToken(name: "warm amber", type: "color", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
            tokens.append(StyleToken(name: "burnished copper", type: "color", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
            tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
            tokens.append(StyleToken(name: "energetic", type: "color_quality", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
        }
        
        if earthCount > threshold + 1 {
            tokens.append(StyleToken(name: "rich olive", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
            tokens.append(StyleToken(name: "warm terracotta", type: "color", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
            tokens.append(StyleToken(name: "deep moss", type: "color", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
            tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
            tokens.append(StyleToken(name: "tactile", type: "color_quality", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
        }
        
        if airCount > threshold + 1 {
            tokens.append(StyleToken(name: "clear azure", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Air Signs"))
            tokens.append(StyleToken(name: "luminous silver", type: "color", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Air Signs"))
            tokens.append(StyleToken(name: "pale citrine", type: "color", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Air Signs"))
            tokens.append(StyleToken(name: "light", type: "color_quality", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Air Signs"))
            tokens.append(StyleToken(name: "bright", type: "color_quality", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Air Signs"))
        }
        
        if waterCount > threshold + 1 {
            tokens.append(StyleToken(name: "deep sapphire", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Water Signs"))
            tokens.append(StyleToken(name: "oceanic teal", type: "color", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Water Signs"))
            tokens.append(StyleToken(name: "misty aquamarine", type: "color", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Water Signs"))
            tokens.append(StyleToken(name: "fluid", type: "color_quality", weight: 2.3, planetarySource: "Elemental Balance", signSource: "Water Signs"))
            tokens.append(StyleToken(name: "reflective", type: "color_quality", weight: 2.2, planetarySource: "Elemental Balance", signSource: "Water Signs"))
        }
        
        return tokens
    }
    
    // MARK: - New Color Interpretation Methods
    
    /// Generate color tokens based on planetary dignities and debilities
    static func generateColorTokensFromDignities(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        for planet in chart.planets {
            // Skip outer planets for this analysis
            if ["Uranus", "Neptune", "Pluto"].contains(planet.name) {
                continue
            }
            
            let signName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            let dignity = getDignityStatus(planet: planet.name, sign: signName)
            
            // Add color tokens based on dignity status
            switch dignity {
            case .domicile:
                // Planet in its own sign - pure, strong colors
                switch planet.name {
                case "Sun":
                    tokens.append(StyleToken(name: "pure gold", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                case "Moon":
                    tokens.append(StyleToken(name: "pure silver", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "luminous", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                case "Mercury":
                    tokens.append(StyleToken(name: "quicksilver", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "brilliant", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                case "Venus":
                    tokens.append(StyleToken(name: "purest rose", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "exquisite", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                case "Mars":
                    tokens.append(StyleToken(name: "perfect crimson", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                case "Jupiter":
                    tokens.append(StyleToken(name: "regal purple", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                case "Saturn":
                    tokens.append(StyleToken(name: "perfect obsidian", type: "color", weight: 2.2, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                    tokens.append(StyleToken(name: "enduring", type: "color_quality", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Domicile"))
                default:
                    break
                }
                
            case .exaltation:
                // Planet exalted - elevated, refined colors
                switch planet.name {
                case "Sun":
                    tokens.append(StyleToken(name: "exalted amber", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "noble", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                case "Moon":
                    tokens.append(StyleToken(name: "exalted pearl", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "sublime", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                case "Mercury":
                    tokens.append(StyleToken(name: "elevated citrine", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "refined", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                case "Venus":
                    tokens.append(StyleToken(name: "exalted jade", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                case "Mars":
                    tokens.append(StyleToken(name: "elevated garnet", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "powerful", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                case "Jupiter":
                    tokens.append(StyleToken(name: "exalted sapphire", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "abundant", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                case "Saturn":
                    tokens.append(StyleToken(name: "elevated graphite", type: "color", weight: 2.0, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                    tokens.append(StyleToken(name: "disciplined", type: "color_quality", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Exaltation"))
                default:
                    break
                }
            case .fall:
                // Planet in fall - subdued, muted colors
                switch planet.name {
                case "Sun":
                    tokens.append(StyleToken(name: "muted amber", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "subdued", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                case "Moon":
                    tokens.append(StyleToken(name: "clouded silver", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "diffused", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                case "Mercury":
                    tokens.append(StyleToken(name: "misty grey", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "complex", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                case "Venus":
                    tokens.append(StyleToken(name: "muted rose", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "subtle", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                case "Mars":
                    tokens.append(StyleToken(name: "subdued terracotta", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "tempered", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                case "Jupiter":
                    tokens.append(StyleToken(name: "muted indigo", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "restrained", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                case "Saturn":
                    tokens.append(StyleToken(name: "subtle charcoal", type: "color", weight: 1.8, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                    tokens.append(StyleToken(name: "introspective", type: "color_quality", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Fall"))
                default:
                    break
                }
                
            case .detriment:
                // Planet in detriment - challenging, complex colors
                switch planet.name {
                case "Sun":
                    tokens.append(StyleToken(name: "complex ochre", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "nuanced", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                case "Moon":
                    tokens.append(StyleToken(name: "shadowed pearl", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "reflective", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                case "Mercury":
                    tokens.append(StyleToken(name: "complex pewter", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "contemplative", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                case "Venus":
                    tokens.append(StyleToken(name: "complex mauve", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "interesting", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                case "Mars":
                    tokens.append(StyleToken(name: "complex rust", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "challenging", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                case "Jupiter":
                    tokens.append(StyleToken(name: "complex slate", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "transformative", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                case "Saturn":
                    tokens.append(StyleToken(name: "complex rust", type: "color", weight: 1.6, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                    tokens.append(StyleToken(name: "evolving", type: "color_quality", weight: 1.5, planetarySource: planet.name, signSource: signName, aspectSource: "Detriment"))
                default:
                    break
                }
                
            case .peregrine:
                // Planet peregrine (neutral) - standard colors
                // No special tokens for peregrine planets
                break
            }
        }
        
        return tokens
    }
    
    /// Get dignity status for a planet in a sign
    private static func getDignityStatus(planet: String, sign: String) -> DignityStatus {
        switch planet {
        case "Sun":
            if sign == "Leo" { return .domicile }
            else if sign == "Aries" { return .exaltation }
            else if sign == "Aquarius" { return .detriment }
            else if sign == "Libra" { return .fall }
            else { return .peregrine }
            
        case "Moon":
            if sign == "Cancer" { return .domicile }
            else if sign == "Taurus" { return .exaltation }
            else if sign == "Capricorn" { return .detriment }
            else if sign == "Scorpio" { return .fall }
            else { return .peregrine }
            
        case "Mercury":
            if sign == "Gemini" || sign == "Virgo" { return .domicile }
            else if sign == "Virgo" { return .exaltation }
            else if sign == "Sagittarius" || sign == "Pisces" { return .detriment }
            else if sign == "Pisces" { return .fall }
            else { return .peregrine }
            
        case "Venus":
            if sign == "Taurus" || sign == "Libra" { return .domicile }
            else if sign == "Pisces" { return .exaltation }
            else if sign == "Aries" || sign == "Scorpio" { return .detriment }
            else if sign == "Virgo" { return .fall }
            else { return .peregrine }
            
        case "Mars":
            if sign == "Aries" || sign == "Scorpio" { return .domicile }
            else if sign == "Capricorn" { return .exaltation }
            else if sign == "Taurus" || sign == "Libra" { return .detriment }
            else if sign == "Cancer" { return .fall }
            else { return .peregrine }
            
        case "Jupiter":
            if sign == "Sagittarius" || sign == "Pisces" { return .domicile }
            else if sign == "Cancer" { return .exaltation }
            else if sign == "Gemini" || sign == "Virgo" { return .detriment }
            else if sign == "Capricorn" { return .fall }
            else { return .peregrine }
            
        case "Saturn":
            if sign == "Capricorn" || sign == "Aquarius" { return .domicile }
            else if sign == "Libra" { return .exaltation }
            else if sign == "Cancer" || sign == "Leo" { return .detriment }
            else if sign == "Aries" { return .fall }
            else { return .peregrine }
            
        default:
            return .peregrine
        }
    }
    
    /// Represents the dignity status of a planet in a sign
    enum DignityStatus {
        case domicile  // Planet in its own sign (strongest)
        case exaltation // Planet exalted
        case peregrine // Planet in neutral sign
        case detriment // Planet in sign opposite its domicile
        case fall      // Planet in sign opposite its exaltation (weakest)
    }
    
    /// Generate color nuance tokens based on chart aspects
    static func generateColorNuanceFromAspects(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Look for aspects between Venus and other planets for color nuance
        // Venus is the planet most associated with aesthetics and color preferences
        if let venus = chart.planets.first(where: { $0.name == "Venus" }) {
            for planet in chart.planets {
                if planet.name == "Venus" { continue } // Skip self-aspect
                
                // Check for aspect
                if let (aspectType, orb) = AstronomicalCalculator.calculateAspect(
                    point1: venus.longitude,
                    point2: planet.longitude,
                    orb: 6.0) {
                    
                    let aspectName = "\(planet.name) \(aspectType) Venus"
                    var weight = 1.8
                    
                    // Tighter orbs get higher weight
                    if orb < 2.0 {
                        weight += 0.3
                    }
                    
                    // Generate color nuance based on the aspect type and planet
                    switch (aspectType, planet.name) {
                        // Sun aspects to Venus
                    case ("Conjunction", "Sun"):
                        tokens.append(StyleToken(name: "luminous gold", type: "color", weight: weight, planetarySource: "Venus-Sun", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "warm", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Sun", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.3, planetarySource: "Venus-Sun", aspectSource: aspectName))
                    case ("Trine", "Sun"):
                        tokens.append(StyleToken(name: "golden amber", type: "color", weight: weight, planetarySource: "Venus-Sun", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Sun", aspectSource: aspectName))
                    case ("Square", "Sun"):
                        tokens.append(StyleToken(name: "complex terracotta", type: "color", weight: weight, planetarySource: "Venus-Sun", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "contrasting", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Sun", aspectSource: aspectName))
                    case ("Opposition", "Sun"):
                        tokens.append(StyleToken(name: "gold and silver blend", type: "color", weight: weight, planetarySource: "Venus-Sun", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "complementary", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Sun", aspectSource: aspectName))
                        
                        // Moon aspects to Venus
                    case ("Conjunction", "Moon"):
                        tokens.append(StyleToken(name: "pearl luminescence", type: "color", weight: weight, planetarySource: "Venus-Moon", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "luminous", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Moon", aspectSource: aspectName))
                    case ("Trine", "Moon"):
                        tokens.append(StyleToken(name: "moonlit rose", type: "color", weight: weight, planetarySource: "Venus-Moon", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "nurturing", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Moon", aspectSource: aspectName))
                    case ("Square", "Moon"):
                        tokens.append(StyleToken(name: "complex mauve", type: "color", weight: weight, planetarySource: "Venus-Moon", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "emotionally dynamic", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Moon", aspectSource: aspectName))
                    case ("Opposition", "Moon"):
                        tokens.append(StyleToken(name: "silver-rose balance", type: "color", weight: weight, planetarySource: "Venus-Moon", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "emotionally complex", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Moon", aspectSource: aspectName))
                        
                        // Mars aspects to Venus
                    case ("Conjunction", "Mars"):
                        tokens.append(StyleToken(name: "passionate rose-red", type: "color", weight: weight, planetarySource: "Venus-Mars", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Mars", aspectSource: aspectName))
                    case ("Trine", "Mars"):
                        tokens.append(StyleToken(name: "harmonious crimson", type: "color", weight: weight, planetarySource: "Venus-Mars", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "energetic", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Mars", aspectSource: aspectName))
                    case ("Square", "Mars"):
                        tokens.append(StyleToken(name: "dynamic burgundy", type: "color", weight: weight, planetarySource: "Venus-Mars", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Mars", aspectSource: aspectName))
                    case ("Opposition", "Mars"):
                        tokens.append(StyleToken(name: "red-pink contrast", type: "color", weight: weight, planetarySource: "Venus-Mars", aspectSource: aspectName))
                        tokens.append(StyleToken(name: "dramatically balanced", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Mars", aspectSource: aspectName))
                        
                        // Neptune aspects to Venus (dreamy, ethereal qualities)
                    case (_, "Neptune"):
                        tokens.append(StyleToken(name: "opalescent", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Neptune", aspectSource: aspectName))
                        
                        if aspectType == "Conjunction" {
                            tokens.append(StyleToken(name: "ethereal aquamarine", type: "color", weight: weight, planetarySource: "Venus-Neptune", aspectSource: aspectName))
                            tokens.append(StyleToken(name: "dreamy", type: "color_quality", weight: weight - 0.3, planetarySource: "Venus-Neptune", aspectSource: aspectName))
                        } else if aspectType == "Trine" {
                            tokens.append(StyleToken(name: "flowing teal", type: "color", weight: weight, planetarySource: "Venus-Neptune", aspectSource: aspectName))
                            tokens.append(StyleToken(name: "imaginative", type: "color_quality", weight: weight - 0.3, planetarySource: "Venus-Neptune", aspectSource: aspectName))
                        }
                        
                        // Jupiter aspects to Venus (expansion, abundance)
                    case (_, "Jupiter"):
                        if ["Conjunction", "Trine"].contains(aspectType) {
                            tokens.append(StyleToken(name: "abundant", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Jupiter", aspectSource: aspectName))
                            tokens.append(StyleToken(name: "opulent", type: "color_quality", weight: weight - 0.3, planetarySource: "Venus-Jupiter", aspectSource: aspectName))
                        }
                        
                        // Saturn aspects to Venus (structure, restraint)
                    case (_, "Saturn"):
                        if ["Conjunction", "Square", "Opposition"].contains(aspectType) {
                            tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.2, planetarySource: "Venus-Saturn", aspectSource: aspectName))
                            tokens.append(StyleToken(name: "refined", type: "color_quality", weight: weight - 0.3, planetarySource: "Venus-Saturn", aspectSource: aspectName))
                        }
                        
                    default:
                        break
                    }
                }
            }
        }
        
        return tokens
    }
    
    // MARK: - Wardrobe Storyline Token Generation
    
    /// Generate tokens for Wardrobe Storyline (60% progressed using Placidus, 40% natal)
    static func generateWardrobeStorylineTokens(natal: NatalChartCalculator.NatalChart,
                                                progressed: NatalChartCalculator.NatalChart,
                                                currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate natal tokens with 40% weight using Whole Sign - these provide the foundation
        let natalTokens = generateBlueprintTokens(natal: natal, currentAge: currentAge)
        for token in natalTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.4,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .natal
            )
            tokens.append(adjustedToken)
        }
        
        // MODULATION: Generate progressed tokens with 60% weight using Placidus house system
        // But ensure progressed tokens only modulate rather than introduce conflicting elements
        let progressedTokens = generateProgressedTokensForWardrobeStoryline(progressed)
        for token in progressedTokens {
            // Movement through contrast - apply progressed chart for modulation
            // Only keep tokens that affect texture, color quality, and structure
            if ["texture", "color_quality", "structure", "mood", "expression"].contains(token.type) {
                // Air to structure - progressed chart provides dynamic evolution
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.6,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .progressed
                )
                tokens.append(adjustedToken)
            }
        }
        
        // Add moon phase influence
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
        let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
        
        // Add moon phase tokens with 0.5 weight multiplier (subtle influence)
        for token in moonPhaseTokens {
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.5,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .phase
            )
            tokens.append(adjustedToken)
        }
        
        return tokens
    }
    
    // Helper to generate progressed tokens for Wardrobe Storyline (Placidus system)
    private static func generateProgressedTokensForWardrobeStoryline(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets with progressed weight and emphasis on emotional arc with Placidus houses
        for planet in chart.planets {
            // Base weight for progressed placements
            let baseWeight: Double = 2.0
            
            // Prioritize fashion-relevant planets with emphasis on Moon for Wardrobe Storyline
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Moon": priorityMultiplier = 2.0 // Extra emphasis on progressed Moon for emotional arc
            case "Venus": priorityMultiplier = 1.4
            case "Mars": priorityMultiplier = 1.1
            case "Sun": priorityMultiplier = 1.0
            default: priorityMultiplier = 0.7
            }
            
            let weight = baseWeight * priorityMultiplier
            
            // Get tokens based on planet in sign
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight,
                isProgressed: true)
            tokens.append(contentsOf: planetTokens)
            
            // Get Placidus house tokens for progressed planets
            let placidusHouse = NatalChartCalculator.determineHouse(
                longitude: planet.longitude,
                houseCusps: chart.houseCusps)
            
            let houseTokens = tokenizeForPlanetInHouse(
                planet: planet.name,
                house: placidusHouse,
                weight: weight,
                isProgressed: true)
            tokens.append(contentsOf: houseTokens)
        }
        
        // Add extra tokens for progressed Ascendant/MC if needed
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascendantSign)
        
        tokens.append(StyleToken(
            name: "evolving",
            type: "expression",
            weight: 2.0,
            planetarySource: "Progressed Ascendant",
            signSource: ascSignName
        ))
        
        return tokens
    }
    
    // MARK: - Style Pulse Token Generation
    
    /// Generate tokens for Style Pulse (90% natal, 10% progressed flavor)
    static func generateStylePulseTokens(natal: NatalChartCalculator.NatalChart,
                                         progressed: NatalChartCalculator.NatalChart,
                                         currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate natal tokens with 90% weight - these establish the core style
        let natalTokens = generateBlueprintTokens(natal: natal, currentAge: currentAge)
        for token in natalTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.9,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .natal
            )
            tokens.append(adjustedToken)
        }
        
        // MODULATION: Add just a flavor of progressed chart (10%)
        // Focus on Moon (emotional evolution) and Venus (style evolution)
        // Only include tokens that modulate rather than replace
        for planet in progressed.planets {
            if planet.name == "Moon" || planet.name == "Venus" {
                let flavorTokens = tokenizeForPlanetInSign(
                    planet: planet.name,
                    sign: planet.zodiacSign,
                    isRetrograde: planet.isRetrograde,
                    weight: 1.0, // Base weight before adjustment
                    isProgressed: true)
                
                // Filter to keep only modulating token types
                for token in flavorTokens {
                    if ["texture", "color_quality", "structure"].contains(token.type) {
                        // Shimmer on earth - add modulation, not replacement
                        let modulatingToken = StyleToken(
                            name: token.name,
                            type: token.type,
                            weight: token.weight * 0.1, // Reduced weight for just flavor
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
        
        // Add moon phase influence
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
        let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
        
        // Add moon phase tokens with very subtle influence
        for token in moonPhaseTokens {
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.3, // Subtle influence
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .phase
            )
            tokens.append(adjustedToken)
        }
        
        return tokens
    }
    
    // MARK: - Token Generation from Natal Chart
    
    static func generateTokensFromNatalChart(_ chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets with updated weighting and source tracking
        for planet in chart.planets {
            // Default base weight for natal placements
            let baseWeight: Double = 2.0
            
            // Apply weighting according to spec
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Sun": priorityMultiplier = 1.1  // Core identity
            case "Venus": priorityMultiplier = 1.5  // Aesthetic preferences
            case "Moon": priorityMultiplier = 1.3   // Emotional comfort
            case "Mars": priorityMultiplier = 1.2   // Energy and cut
            case "Mercury": priorityMultiplier = 1.1 // Communication style
            case "Jupiter": priorityMultiplier = 0.9 // Expansion, principles
            case "Saturn": priorityMultiplier = 0.9  // Structure, discipline
            default: priorityMultiplier = 0.8        // Outer planets
            }
            
            let weight = baseWeight * priorityMultiplier
            
            // Get tokens based on planet in sign with source tracking
            let planetTokens = tokenizeForPlanetInSign(
                planet: planet.name,
                sign: planet.zodiacSign,
                isRetrograde: planet.isRetrograde,
                weight: weight)
            
            // Apply age-dependent weighting
            let ageWeightedTokens = planetTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedTokens)
        }
        
        // Process rising sign (ascendant) - high influence on appearance
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascendantSign)
        let ascendantTokens = tokenizeForAscendant(
            sign: ascendantSign,
            signName: ascSignName,
            weight: 3.0)
        
        // Apply age-dependent weighting
        let ageWeightedAscTokens = ascendantTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAscTokens)
        
        // Process house placements with source tracking - using Placidus by default for general use
        for planet in chart.planets {
            // Determine house by comparing planet longitude to house cusps
            let house = NatalChartCalculator.determineHouse(longitude: planet.longitude, houseCusps: chart.houseCusps)
            
            // Higher weight for fashion-relevant planets in visible houses
            let houseWeight = isVisibleHouse(house) ? 2.5 : 2.0
            
            let houseTokens = tokenizeForPlanetInHouse(
                planet: planet.name,
                house: house,
                weight: houseWeight)
            
            // Apply age-dependent weighting
            let ageWeightedHouseTokens = houseTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
            tokens.append(contentsOf: ageWeightedHouseTokens)
        }
        
        // Generate elemental balance tokens
        let elementalTokens = generateElementalTokens(chart: chart)
        let ageWeightedElementalTokens = elementalTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedElementalTokens)
        
        // Generate aspect-based tokens
        let aspectTokens = generateAspectTokens(chart: chart)
        let ageWeightedAspectTokens = aspectTokens.map { $0.applyingAgeWeight(currentAge: currentAge) }
        tokens.append(contentsOf: ageWeightedAspectTokens)
        
        // Add moon phase influence
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
        let moonPhaseTokens = MoonPhaseInterpreter.tokensForBlueprintRelevance(phase: moonPhase)
        tokens.append(contentsOf: moonPhaseTokens)
        
        return tokens
    }
    
    // Helper to determine if a house is visually significant
    private static func isVisibleHouse(_ house: Int) -> Bool {
        // Houses that influence appearance/style more directly
        return [1, 5, 7, 10].contains(house)
    }
    
    // MARK: - Token Generation from Progressed Chart
    
    static func generateTokensFromProgressedChart(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets with progressed weight and "progressed" tag for source tracking
        for planet in chart.planets {
            // Base weight for progressed placements (slightly lower than natal)
            let baseWeight: Double = 2.0
            
            // Prioritize fashion-relevant planets
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Venus": priorityMultiplier = 1.4
            case "Moon": priorityMultiplier = 1.2
            case "Mars": priorityMultiplier = 1.1
            case "Sun": priorityMultiplier = 1.0
            default: priorityMultiplier = 0.7
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
        
        return tokens
    }
    
    /// Helper method to get natal planet power score
    private static func getNatalPlanetPowerScore(_ planet: String, chart: NatalChartCalculator.NatalChart) -> Double {
        // Get additional context for better power evaluation
        var sign: String? = nil
        var house: Int? = nil
        var isAngular = false
        var isChartRuler = false
        // Find planet in chart
        if let natalPlanet = chart.planets.first(where: { $0.name == planet }) {
            // Get sign name
            sign = CoordinateTransformations.getZodiacSignName(sign: natalPlanet.zodiacSign)
            
            // Get house and check if angular
            house = NatalChartCalculator.determineHouse(longitude: natalPlanet.longitude, houseCusps: chart.houseCusps)
            isAngular = [1, 4, 7, 10].contains(house ?? 0)
            
            // Check if chart ruler
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
    
    /// Helper method to extract natal planet from aspect source
    private static func extractNatalPlanetFromAspect(_ aspectSource: String) -> String? {
    let parts = aspectSource.components(separatedBy: " ")
    return parts.count >= 3 ? parts[2] : nil
    }
    /// Helper method to get the ruling planet for a sign
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
    
    // MARK: - Token Generation from Transits
    
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
            let transitSign = transit["transitSign"] as? String
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
            
            // Get influence category and token weight scale
            let influenceCategory = TransitWeightCalculator.getStyleInfluenceCategory(weight: transitWeight)
            let tokenScale = TransitWeightCalculator.getTokenWeightScale(for: influenceCategory)
            
            // Generate tokens based on the transit with aspect source tracking
            let aspectSource = "\(transitPlanet) \(aspectType) \(natalPlanet)"
            let transitTokens = tokenizeForTransit(
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                weight: transitWeight * tokenScale,
                aspectSource: aspectSource)
            
            // Update the tokens with correct origin type
            let updatedTokens = transitTokens.map { token in
                return StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: .transit
                )
            }
            
            tokens.append(contentsOf: updatedTokens)
        }
        
        // Handle multiple transits to the same target
        if !tokens.isEmpty {
            // Group tokens by natal planet target
            var tokensByNatalPlanet: [String: [StyleToken]] = [:]
            for token in tokens {
                if let aspectSource = token.aspectSource,
                   let natalPlanet = extractNatalPlanetFromAspect(aspectSource) {
                    if tokensByNatalPlanet[natalPlanet] == nil {
                        tokensByNatalPlanet[natalPlanet] = []
                    }
                    tokensByNatalPlanet[natalPlanet]
                    tokensByNatalPlanet[natalPlanet]?.append(token)
                }
            }
            
            // Apply multi-transit adjustment for planets with multiple hits
            for (natalPlanet, planetTokens) in tokensByNatalPlanet {
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
        }

        return tokens
    }
    
    // MARK: - Token Generation from Weather
    
    static func generateWeatherTokens(weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Base weight for weather
        let baseWeight: Double = 1.0
        
        // Temperature tokens
        if weather.temp < 10 {
            tokens.append(StyleToken(name: "cold", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "cozy", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        } else if weather.temp < 20 {
            tokens.append(StyleToken(name: "cool", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "layered", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        } else if weather.temp < 30 {
            tokens.append(StyleToken(name: "warm", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "breathable", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        } else {
            tokens.append(StyleToken(name: "hot", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "light", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        }
        
        // Condition tokens
        switch weather.conditions.lowercased() {
        case let c where c.contains("rain") || c.contains("drizzle") || c.contains("shower"):
            tokens.append(StyleToken(name: "damp", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "protected", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        case let c where c.contains("cloud"):
            tokens.append(StyleToken(name: "muted", type: "color", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "subdued", type: "mood", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        case let c where c.contains("snow") || c.contains("ice"):
            tokens.append(StyleToken(name: "crisp", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "insulated", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        case let c where c.contains("fog"):
            tokens.append(StyleToken(name: "diffused", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "soft", type: "edges", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        case let c where c.contains("sun") || c.contains("clear"):
            tokens.append(StyleToken(name: "bright", type: "color", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "vibrant", type: "mood", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        case let c where c.contains("wind"):
            tokens.append(StyleToken(name: "anchored", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
            tokens.append(StyleToken(name: "secure", type: "fabric", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        default:
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        }
        
        // Humidity tokens
        if weather.humidity > 80 {
            tokens.append(StyleToken(name: "moisture-wicking", type: "fabric", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        } else if weather.humidity < 30 {
            tokens.append(StyleToken(name: "hydrating", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
        }
        
        return tokens
    }
    
    // MARK: - Helper Methods for Token Generation
    
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
            
            // Generate tokens based on planet and sign
            switch planet {
            case "Sun":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "bold", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dynamic", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bright red", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Taurus":
                    tokens.append(StyleToken(name: "sensual", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "earthy", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "forest green", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Gemini":
                    tokens.append(StyleToken(name: "playful", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "yellow", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bright", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Cancer":
                    tokens.append(StyleToken(name: "protective", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "comfortable", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "silver", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "gentle", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Leo":
                    tokens.append(StyleToken(name: "radiant", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "gold", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "warm", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Virgo":
                    tokens.append(StyleToken(name: "refined", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "practical", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "wheat", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "harmonious", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "rose pink", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "elegant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Scorpio":
                    tokens.append(StyleToken(name: "intense", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "transformative", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "deep burgundy", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "adventurous", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "royal blue", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Capricorn":
                    tokens.append(StyleToken(name: "structured", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "charcoal", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "classic", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Aquarius":
                    tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "distinctive", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "electric blue", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "unique", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Pisces":
                    tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dreamy", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "seafoam", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "flowing", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                default:
                    break
                }
                
            case "Moon":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "energetic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "impulsive", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "coral red", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "warm", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Taurus":
                    tokens.append(StyleToken(name: "comforting", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "stable", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "moss green", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "rich", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Gemini":
                    tokens.append(StyleToken(name: "adaptable", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "communicative", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "pale yellow", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bright", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Cancer":
                    tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "emotional", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "pearl", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "luminous", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Leo":
                    tokens.append(StyleToken(name: "warm", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dramatic", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "amber", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Virgo":
                    tokens.append(StyleToken(name: "detailed", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "thoughtful", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "taupe", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Libra":
                    tokens.append(StyleToken(name: "elegant", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "social", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "lavender", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Scorpio":
                    tokens.append(StyleToken(name: "deep", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "emotional", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "deep plum", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "mysterious", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "optimistic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "free-spirited", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "indigo", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "deep", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Capricorn":
                    tokens.append(StyleToken(name: "grounded", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "reserved", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "slate gray", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "solid", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Aquarius":
                    tokens.append(StyleToken(name: "unique", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "independent", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "turquoise", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Pisces":
                    tokens.append(StyleToken(name: "soft", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "intuitive", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "seafoam", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dreamy", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                default:
                    break
                }
                
            case "Venus":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "spontaneous", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bold", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "coral", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Taurus":
                    tokens.append(StyleToken(name: "luxurious", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "sensual", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "emerald", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "rich", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Gemini":
                    tokens.append(StyleToken(name: "eclectic", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "playful", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "peach", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "varied", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Cancer":
                    tokens.append(StyleToken(name: "nostalgic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "cream", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "soft", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Leo":
                    tokens.append(StyleToken(name: "glamorous", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "vibrant", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "warm gold", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Virgo":
                    tokens.append(StyleToken(name: "subtle", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "refined", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "sage", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Libra":
                    tokens.append(StyleToken(name: "harmonious", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "balanced", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "rose quartz", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "elegant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Scorpio":
                    tokens.append(StyleToken(name: "magnetic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "wine red", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "exuberant", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "expansive", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "teal", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "vivid", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Capricorn":
                    tokens.append(StyleToken(name: "elegant", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "classic", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "merlot", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "timeless", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Aquarius":
                    tokens.append(StyleToken(name: "unconventional", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "futuristic", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "periwinkle", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Pisces":
                    tokens.append(StyleToken(name: "romantic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dreamy", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "lilac", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "ethereal", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                default:
                    break
                }
                
            case "Mars":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "assertive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "energetic", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "crimson", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bold", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Taurus":
                    tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "substantial", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "rust", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "earthy", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Gemini":
                    tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "quick", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bright yellow", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Cancer":
                    tokens.append(StyleToken(name: "protective", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "burgundy", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "deep", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Leo":
                    tokens.append(StyleToken(name: "confident", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "bold", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "copper", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Virgo":
                    tokens.append(StyleToken(name: "precise", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "detailed", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "brick red", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "harmonious", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "rose", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Scorpio":
                    tokens.append(StyleToken(name: "intense", type: "color", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "powerful", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "deep red", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "adventurous", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "expansive", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "purple", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Capricorn":
                    tokens.append(StyleToken(name: "disciplined", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "dark brown", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Aquarius":
                    tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "progressive", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "electric blue", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "unique", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Pisces":
                    tokens.append(StyleToken(name: "fluid", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "adaptive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "sea blue", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "flowing", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                default:
                    break
                }
                
            case "Mercury":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "direct", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "quick", type: "pace", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "clear red", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "crisp", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Taurus":
                    tokens.append(StyleToken(name: "deliberate", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "practical", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "olive", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "textured", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Gemini":
                    tokens.append(StyleToken(name: "versatile", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "curious", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "yellow", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "varied", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Cancer":
                    tokens.append(StyleToken(name: "intuitive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "receptive", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "silver gray", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "nuanced", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Leo":
                    tokens.append(StyleToken(name: "expressive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "confident", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "golden yellow", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "distinct", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Virgo":
                    tokens.append(StyleToken(name: "precise", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "analytical", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "wheat", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "diplomatic", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "pastel pink", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Scorpio":
                    tokens.append(StyleToken(name: "penetrating", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "strategic", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "deep burgundy", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "expansive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "optimistic", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "blue", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "clear", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Capricorn":
                    tokens.append(StyleToken(name: "structured", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "disciplined", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "charcoal", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "defined", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Aquarius":
                    tokens.append(StyleToken(name: "innovative", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "objective", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "electric blue", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "unique", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                case "Pisces":
                    tokens.append(StyleToken(name: "intuitive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "imaginative", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "sea green", type: "color", weight: weight - 0.3, planetarySource: planetSource, signSource: signName, originType: originType))
                    tokens.append(StyleToken(name: "blended", type: "color_quality", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                default:
                    break
                }
                
            default:
                // For other planets, add elemental tokens
                switch signName {
                case "Aries", "Leo", "Sagittarius":
                    tokens.append(StyleToken(name: "fiery", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName, originType: originType))
                    if planet == "Jupiter" || planet == "Uranus" {
                        tokens.append(StyleToken(name: "warm orange", type: "color", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                        tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.5, planetarySource: planetSource, signSource: signName, originType: originType))
                    }
                case "Taurus", "Virgo", "Capricorn":
                    tokens.append(StyleToken(name: "earthy", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName, originType: originType))
                    if planet == "Saturn" {
                        tokens.append(StyleToken(name: "deep brown", type: "color", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                        tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: weight - 0.5, planetarySource: planetSource, signSource: signName, originType: originType))
                    }
                case "Gemini", "Libra", "Aquarius":
                    tokens.append(StyleToken(name: "airy", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName, originType: originType))
                    if planet == "Uranus" {
                        tokens.append(StyleToken(name: "bright blue", type: "color", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                        tokens.append(StyleToken(name: "electric", type: "color_quality", weight: weight - 0.5, planetarySource: planetSource, signSource: signName, originType: originType))
                    }
                case "Cancer", "Scorpio", "Pisces":
                    tokens.append(StyleToken(name: "watery", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName, originType: originType))
                    if planet == "Neptune" {
                        tokens.append(StyleToken(name: "deep teal", type: "color", weight: weight - 0.4, planetarySource: planetSource, signSource: signName, originType: originType))
                        tokens.append(StyleToken(name: "fluid", type: "color_quality", weight: weight - 0.5, planetarySource: planetSource, signSource: signName, originType: originType))
                    }
                default:
                    break
                }
            }
            
            // Add retrograde tokens if applicable with source tracking
            if isRetrograde {
                tokens.append(StyleToken(name: "reflective", type: "mood", weight: weight * 0.9, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde", originType: originType))
                tokens.append(StyleToken(name: "introspective", type: "structure", weight: weight * 0.9, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde", originType: originType))
                tokens.append(StyleToken(name: "nonlinear", type: "approach", weight: weight * 0.8, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde", originType: originType))
                // Add color quality for retrograde
                tokens.append(StyleToken(name: "muted", type: "color_quality", weight: weight * 0.7, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde", originType: originType))
            }
            
            return tokens
        }
    
    /// Generate tokens for Ascendant (Rising Sign) with source tracking
    static func tokenizeForAscendant(sign: Int, signName: String, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate tokens based on rising sign - heavily weighted
        switch signName {
        case "Aries":
            tokens.append(StyleToken(name: "bold", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "direct", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "bold red", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Taurus":
            tokens.append(StyleToken(name: "stable", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "sensual", type: "texture", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "earthy green", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Gemini":
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "communicative", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "bright yellow", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "vivid", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Cancer":
            tokens.append(StyleToken(name: "protective", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "nurturing", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "moonlit silver", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "reflective", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Leo":
            tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "radiant", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "royal gold", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Virgo":
            tokens.append(StyleToken(name: "precise", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "refined", type: "texture", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "wheat brown", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Libra":
            tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "harmonious", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "pastel pink", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Scorpio":
            tokens.append(StyleToken(name: "intense", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "deep burgundy", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Sagittarius":
            tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "adventurous", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "royal purple", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "expansive", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Capricorn":
            tokens.append(StyleToken(name: "structured", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "disciplined", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "deep charcoal", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Aquarius":
            tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "unique", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "electric blue", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "innovative", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        case "Pisces":
            tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "intuitive", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "aquamarine", type: "color", weight: weight - 0.3, planetarySource: "Ascendant", signSource: signName, originType: .natal))
            tokens.append(StyleToken(name: "fluid", type: "color_quality", weight: weight - 0.4, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        default:
            break
        }
        
        // Add elemental token based on the sign
        if ["Aries", "Leo", "Sagittarius"].contains(signName) {
            tokens.append(StyleToken(name: "fiery", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        } else if ["Taurus", "Virgo", "Capricorn"].contains(signName) {
            tokens.append(StyleToken(name: "earthy", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        } else if ["Gemini", "Libra", "Aquarius"].contains(signName) {
            tokens.append(StyleToken(name: "airy", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        } else if ["Cancer", "Scorpio", "Pisces"].contains(signName) {
            tokens.append(StyleToken(name: "watery", type: "element", weight: weight * 0.9, planetarySource: "Ascendant", signSource: signName, originType: .natal))
        }
        
        return tokens
    }
    
    /// Generate tokens for a planet in a specific house with source tracking
    static func tokenizeForPlanetInHouse(
        planet: String,
        house: Int,
        weight: Double,
        isProgressed: Bool = false) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            let planetSource = isProgressed ? "Progressed \(planet)" : planet
            let originType: OriginType = isProgressed ? .progressed : .natal
            
            // Different house meanings
            switch house {
            case 1: // 1st house - Self, appearance
                tokens.append(StyleToken(name: "visible", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "defining", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Venus" || planet == "Moon" || planet == "Sun" {
                    tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 2: // 2nd house - Values, possessions
                tokens.append(StyleToken(name: "tactile", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "substantial", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Venus" || planet == "Moon" {
                    tokens.append(StyleToken(name: "rich", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 3: // 3rd house - Communication, local environment
                tokens.append(StyleToken(name: "communicative", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "adaptable", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Mercury" {
                    tokens.append(StyleToken(name: "varied", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 4: // 4th house - Home, roots, security
                tokens.append(StyleToken(name: "comforting", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "grounded", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Moon" {
                    tokens.append(StyleToken(name: "soft", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 5: // 5th house - Creativity, pleasure
                tokens.append(StyleToken(name: "playful", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Sun" || planet == "Venus" {
                    tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 6: // 6th house - Work, health, service
                tokens.append(StyleToken(name: "practical", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "functional", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Mercury" {
                    tokens.append(StyleToken(name: "precise", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 7: // 7th house - Partnerships, relationships
                tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "harmonious", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Venus" {
                    tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 8: // 8th house - Transformation, shared resources
                tokens.append(StyleToken(name: "intense", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Pluto" || planet == "Mars" {
                    tokens.append(StyleToken(name: "deep", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 9: // 9th house - Philosophy, travel, higher learning
                tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "cultural", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Jupiter" {
                    tokens.append(StyleToken(name: "rich", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 10: // 10th house - Career, public image
                tokens.append(StyleToken(name: "authoritative", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "polished", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Saturn" || planet == "Sun" {
                    tokens.append(StyleToken(name: "structured", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 11: // 11th house - Friends, groups, aspirations
                tokens.append(StyleToken(name: "unconventional", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "innovative", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Uranus" {
                    tokens.append(StyleToken(name: "unique", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            case 12: // 12th house - Spirituality, unconscious
                tokens.append(StyleToken(name: "mystical", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house, originType: originType))
                if planet == "Neptune" {
                    tokens.append(StyleToken(name: "dreamy", type: "color_quality", weight: weight - 0.3, planetarySource: planetSource, houseSource: house, originType: originType))
                }
                
            default:
                break
            }
            
            // Special case for planets in houses that particularly affect appearance
            if [1, 5, 7, 10].contains(house) && ["Sun", "Venus", "Moon", "Mars"].contains(planet) {
                tokens.append(StyleToken(name: "appearance-focused", type: "expression", weight: weight * 1.2, planetarySource: planetSource, houseSource: house, originType: originType))
            }
            
            return tokens
        }
    
    /// Generate tokens based on transit aspects with source tracking
    static func tokenizeForTransit(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String,
        weight: Double,
        aspectSource: String) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Major transits to fashion-relevant planets
            if ["Venus", "Moon", "Sun", "Mars"].contains(natalPlanet) {
                switch aspectType {
                case "Conjunction":
                    tokens.append(StyleToken(name: "intensified", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "emotional", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "luminous", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "harmonious", type: "color", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "energetic", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    }
                    
                case "Opposition":
                    tokens.append(StyleToken(name: "contrasting", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "reflective", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "contrasting", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "balanced", type: "color", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "harmonizing", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "dynamic", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "bold", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    }
                    
                case "Trine":
                    tokens.append(StyleToken(name: "flowing", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "intuitive", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "flowing", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "attractive", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "confident", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "energetic", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    }
                    
                case "Square":
                    tokens.append(StyleToken(name: "structured", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "challenging", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "creative", type: "color", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "expressive", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "bold", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "intense", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    }
                    
                case "Sextile":
                    tokens.append(StyleToken(name: "harmonious", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "supportive", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "gentle", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "pleasant", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "balanced", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "active", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "dynamic", type: "color_quality", weight: weight - 0.3, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    }
                    
                default:
                    // For minor aspects, add less specific tokens
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "subtle", type: "texture", weight: weight * 0.7, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "nuanced", type: "color_quality", weight: weight * 0.6, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "nuanced", type: "color", weight: weight * 0.7, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "refined", type: "color_quality", weight: weight * 0.6, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "gentle", type: "structure", weight: weight * 0.7, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                        tokens.append(StyleToken(name: "subtle", type: "color_quality", weight: weight * 0.6, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    }
                }
            } else {
                // For transits to less fashion-relevant planets, add more general tokens
                if ["Conjunction", "Opposition", "Trine", "Square", "Sextile"].contains(aspectType) {
                    tokens.append(StyleToken(name: "shifting", type: "mood", weight: weight * 0.6, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                    tokens.append(StyleToken(name: "evolving", type: "color_quality", weight: weight * 0.5, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
                }
            }
            
            return tokens
        }
    
    // MARK: - Additional Token Generation Methods
    
    /// Generate tokens based on elemental balance in chart
    static func generateElementalTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Count planets by element
        var fireCount = 0
        var earthCount = 0
        var airCount = 0
        var waterCount = 0
        
        for planet in chart.planets {
            let signName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            
            if ["Aries", "Leo", "Sagittarius"].contains(signName) {
                fireCount += 1
            } else if ["Taurus", "Virgo", "Capricorn"].contains(signName) {
                earthCount += 1
            } else if ["Gemini", "Libra", "Aquarius"].contains(signName) {
                airCount += 1
            } else if ["Cancer", "Scorpio", "Pisces"].contains(signName) {
                waterCount += 1
            }
        }
        
        // Add Ascendant to the count
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascSign)
        
        if ["Aries", "Leo", "Sagittarius"].contains(ascSignName) {
            fireCount += 1
        } else if ["Taurus", "Virgo", "Capricorn"].contains(ascSignName) {
            earthCount += 1
        } else if ["Gemini", "Libra", "Aquarius"].contains(ascSignName) {
            airCount += 1
        } else if ["Cancer", "Scorpio", "Pisces"].contains(ascSignName) {
            waterCount += 1
        }
        
        // Add elemental tokens based on dominance
        let total = fireCount + earthCount + airCount + waterCount
        let threshold = total / 4
        
        if fireCount > threshold + 1 {
            tokens.append(StyleToken(name: "fiery", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Fire Signs", originType: .natal))
            tokens.append(StyleToken(name: "passionate", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Fire Signs", originType: .natal))
            tokens.append(StyleToken(name: "dynamic", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Fire Signs", originType: .natal))
            tokens.append(StyleToken(name: "warm red", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Fire Signs", originType: .natal))
            tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: 2.4, planetarySource: "Elemental Balance", signSource: "Fire Signs", originType: .natal))
        }
        
        if earthCount > threshold + 1 {
            tokens.append(StyleToken(name: "earthy", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Earth Signs", originType: .natal))
            tokens.append(StyleToken(name: "grounded", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Earth Signs", originType: .natal))
            tokens.append(StyleToken(name: "stable", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Earth Signs", originType: .natal))
            tokens.append(StyleToken(name: "forest green", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Earth Signs", originType: .natal))
            tokens.append(StyleToken(name: "grounded", type: "color_quality", weight: 2.4, planetarySource: "Elemental Balance", signSource: "Earth Signs", originType: .natal))
        }
        
        if airCount > threshold + 1 {
            tokens.append(StyleToken(name: "airy", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Air Signs", originType: .natal))
            tokens.append(StyleToken(name: "intellectual", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Air Signs", originType: .natal))
            tokens.append(StyleToken(name: "communicative", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Air Signs", originType: .natal))
            tokens.append(StyleToken(name: "sky blue", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Air Signs", originType: .natal))
            tokens.append(StyleToken(name: "bright", type: "color_quality", weight: 2.4, planetarySource: "Elemental Balance", signSource: "Air Signs", originType: .natal))
        }
        
        if waterCount > threshold + 1 {
            tokens.append(StyleToken(name: "watery", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Water Signs", originType: .natal))
            tokens.append(StyleToken(name: "emotional", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Water Signs", originType: .natal))
            tokens.append(StyleToken(name: "intuitive", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Water Signs", originType: .natal))
            tokens.append(StyleToken(name: "deep blue", type: "color", weight: 2.5, planetarySource: "Elemental Balance", signSource: "Water Signs", originType: .natal))
            tokens.append(StyleToken(name: "flowing", type: "color_quality", weight: 2.4, planetarySource: "Elemental Balance", signSource: "Water Signs", originType: .natal))
        }
        
        // Balanced or lacking elements
        if fireCount < threshold - 1 {
            tokens.append(StyleToken(name: "reserved", type: "mood", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Fire", originType: .natal))
            tokens.append(StyleToken(name: "muted", type: "color_quality", weight: 1.8, planetarySource: "Elemental Balance", signSource: "Lack of Fire", originType: .natal))
        }
        
        if earthCount < threshold - 1 {
            tokens.append(StyleToken(name: "ethereal", type: "texture", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Earth", originType: .natal))
            tokens.append(StyleToken(name: "light", type: "color_quality", weight: 1.8, planetarySource: "Elemental Balance", signSource: "Lack of Earth", originType: .natal))
        }
        
        if airCount < threshold - 1 {
            tokens.append(StyleToken(name: "instinctive", type: "approach", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Air", originType: .natal))
            tokens.append(StyleToken(name: "rich", type: "color_quality", weight: 1.8, planetarySource: "Elemental Balance", signSource: "Lack of Air", originType: .natal))
        }
        
        if waterCount < threshold - 1 {
            tokens.append(StyleToken(name: "structured", type: "approach", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Water", originType: .natal))
            tokens.append(StyleToken(name: "defined", type: "color_quality", weight: 1.8, planetarySource: "Elemental Balance", signSource: "Lack of Water", originType: .natal))
        }
        
        // If no clear elemental dominance, add a balanced token
        if fireCount <= threshold + 1 && earthCount <= threshold + 1 &&
            airCount <= threshold + 1 && waterCount <= threshold + 1 {
            tokens.append(StyleToken(name: "balanced", type: "element", weight: 2.5, planetarySource: "Elemental Balance", signSource: "All Elements", originType: .natal))
            tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: 2.3, planetarySource: "Elemental Balance", signSource: "All Elements", originType: .natal))
        }
        
        return tokens
    }
    
    /// Generate tokens based on aspects in the chart
    static func generateAspectTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Check for aspects between fashion-relevant planets
        let relevantPlanets = ["Sun", "Moon", "Venus", "Mars"]
        
        for i in 0..<chart.planets.count {
            let planet1 = chart.planets[i]
            if !relevantPlanets.contains(planet1.name) { continue }
            
            for j in (i+1)..<chart.planets.count {
                let planet2 = chart.planets[j]
                if !relevantPlanets.contains(planet2.name) { continue }
                
                // Check for aspect
                if let (aspectType, orb) = AstronomicalCalculator.calculateAspect(
                    point1: planet1.longitude,
                    point2: planet2.longitude,
                    orb: 5.0) {
                    
                    let aspectSource = "\(planet1.name) \(aspectType) \(planet2.name)"
                    var aspectWeight = 2.0
                    
                    // Adjust weight based on orb
                    if orb < 1.0 {
                        aspectWeight += 0.5 // Exact aspects
                    } else if orb > 3.0 {
                        aspectWeight -= 0.3 // Loose aspects
                    }
                    
                    // Generate aspect-specific tokens
                    switch aspectType {
                    case "Conjunction":
                        // Planets fused together - intensified energy
                        tokens.append(StyleToken(name: "intensified", type: "mood", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Add color quality for conjunction aspects
                        if (planet1.name == "Venus" || planet2.name == "Venus") &&
                            (planet1.name == "Moon" || planet2.name == "Moon") {
                            tokens.append(StyleToken(name: "luminous", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        }
                        
                        // Venus-Mars conjunction can indicate style with sensuality
                        if (planet1.name == "Venus" && planet2.name == "Mars") ||
                            (planet1.name == "Mars" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "sensual", type: "expression", weight: aspectWeight,
                                                     planetarySource: "Venus-Mars", aspectSource: aspectSource))
                            tokens.append(StyleToken(name: "vibrant", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "Venus-Mars", aspectSource: aspectSource))
                        }
                        
                        // Sun-Moon conjunction can indicate harmony between conscious and unconscious
                        if (planet1.name == "Sun" && planet2.name == "Moon") ||
                            (planet1.name == "Moon" && planet2.name == "Sun") {
                            tokens.append(StyleToken(name: "integrated", type: "mood", weight: aspectWeight,
                                                     planetarySource: "Sun-Moon", aspectSource: aspectSource))
                            tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "Sun-Moon", aspectSource: aspectSource))
                        }
                        
                    case "Opposition":
                        // Planets in polarity - balance or tension
                        tokens.append(StyleToken(name: "balanced", type: "structure", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Add color quality for opposition aspects
                        if (planet1.name == "Venus" || planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "contrasting", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        }
                        
                        // Venus-Mars opposition can indicate style with contrasting elements
                        if (planet1.name == "Venus" && planet2.name == "Mars") ||
                            (planet1.name == "Mars" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "contrasting", type: "expression", weight: aspectWeight,
                                                     planetarySource: "Venus-Mars", aspectSource: aspectSource))
                            tokens.append(StyleToken(name: "bold", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "Venus-Mars", aspectSource: aspectSource))
                        }
                        
                    case "Trine":
                        // Planets in harmony - flow and ease
                        tokens.append(StyleToken(name: "flowing", type: "structure", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Add color quality for trine aspects
                        if (planet1.name == "Sun" || planet2.name == "Sun") {
                            tokens.append(StyleToken(name: "harmonious", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        }
                        
                        // Venus-Moon trine can indicate style with emotional harmony
                        if (planet1.name == "Venus" && planet2.name == "Moon") ||
                            (planet1.name == "Moon" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "harmonious", type: "mood", weight: aspectWeight,
                                                     planetarySource: "Venus-Moon", aspectSource: aspectSource))
                            tokens.append(StyleToken(name: "flowing", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "Venus-Moon", aspectSource: aspectSource))
                        }
                        
                    case "Square":
                        // Planets in tension - dynamic energy
                        tokens.append(StyleToken(name: "dynamic", type: "structure", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Add color quality for square aspects
                        if (planet1.name == "Mars" || planet2.name == "Mars") {
                            tokens.append(StyleToken(name: "intense", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        }
                        
                        // Venus-Saturn square can indicate style with structured restraint
                        if (planet1.name == "Venus" && planet2.name == "Saturn") ||
                            (planet1.name == "Saturn" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "restrained", type: "expression", weight: aspectWeight,
                                                     planetarySource: "Venus-Saturn", aspectSource: aspectSource))
                            tokens.append(StyleToken(name: "structured", type: "color_quality", weight: aspectWeight - 0.2,
                                                     planetarySource: "Venus-Saturn", aspectSource: aspectSource))
                        }
                        
                    default:
                        // Minor aspects - subtler influence
                        tokens.append(StyleToken(name: "nuanced", type: "mood", weight: aspectWeight * 0.8,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Add subtle color quality for minor aspects
                        if (planet1.name == "Venus" || planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "subtle", type: "color_quality", weight: aspectWeight * 0.7,
                                                     planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        }
                    }
                }
            }
        }
        
        return tokens
    }
    
    // MARK: - Daily Vibe Token Generation
    
    /// Generate tokens for base style resonance (100% natal, Whole Sign)
    static func generateBaseStyleTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
        // Use the existing Blueprint tokens generation as base style resonance uses the same approach
        return generateBlueprintTokens(natal: natal)
    }
    
    /// Generate tokens for emotional vibe of the day (60% progressed Moon, 40% natal Moon, Placidus)
    static func generateEmotionalVibeTokens(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Find natal Moon
            if let natalMoon = natal.planets.first(where: { $0.name == "Moon" }) {
                // Generate tokens from natal Moon with 40% weight
                let moonSign = natalMoon.zodiacSign
                let signName = CoordinateTransformations.getZodiacSignName(sign: moonSign)
                
                // Determine house using Placidus system
                let moonHouse = NatalChartCalculator.determineHouse(
                    longitude: natalMoon.longitude,
                    houseCusps: natal.houseCusps)
                
                // Add emotional style tokens based on Moon sign with 40% weight
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(
                        name: "energetic",
                        type: "mood",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "direct",
                        type: "expression",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "coral red",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Taurus":
                    tokens.append(StyleToken(
                        name: "grounded",
                        type: "mood",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "sensual",
                        type: "texture",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "moss green",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Gemini":
                    tokens.append(StyleToken(
                        name: "versatile",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "communicative",
                        type: "expression",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "pale yellow",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Cancer":
                    tokens.append(StyleToken(
                        name: "protective",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "nurturing",
                        type: "mood",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "pearl",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Leo":
                    tokens.append(StyleToken(
                        name: "expressive",
                        type: "mood",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "warm",
                        type: "color",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "amber",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Virgo":
                    tokens.append(StyleToken(
                        name: "precise",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "refined",
                        type: "texture",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "taupe",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Libra":
                    tokens.append(StyleToken(
                        name: "balanced",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "harmonious",
                        type: "expression",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "lavender",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Scorpio":
                    tokens.append(StyleToken(
                        name: "intense",
                        type: "mood",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "transformative",
                        type: "structure",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "deep plum",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Sagittarius":
                    tokens.append(StyleToken(
                        name: "expansive",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "optimistic",
                        type: "mood",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "indigo",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Capricorn":
                    tokens.append(StyleToken(
                        name: "structured",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "disciplined",
                        type: "expression",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "slate gray",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Aquarius":
                    tokens.append(StyleToken(
                        name: "innovative",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "detached",
                        type: "mood",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "turquoise",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Pisces":
                    tokens.append(StyleToken(
                        name: "fluid",
                        type: "structure",
                        weight: 2.0 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "intuitive",
                        type: "mood",
                        weight: 1.8 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "seafoam",
                        type: "color",
                        weight: 1.7 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                default:
                    tokens.append(StyleToken(
                        name: "responsive",
                        type: "mood",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                }
                
                // Add tokens based on Placidus house placement
                switch moonHouse {
                case 1:
                    tokens.append(StyleToken(
                        name: "self-expressive",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 2:
                    tokens.append(StyleToken(
                        name: "value-oriented",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 3:
                    tokens.append(StyleToken(
                        name: "communicative",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 4:
                    tokens.append(StyleToken(
                        name: "nurturing",
                        type: "mood",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 5:
                    tokens.append(StyleToken(
                        name: "creative",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 6:
                    tokens.append(StyleToken(
                        name: "practical",
                        type: "structure",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 7:
                    tokens.append(StyleToken(
                        name: "relationship-oriented",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 8:
                    tokens.append(StyleToken(
                        name: "transformative",
                        type: "structure",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 9:
                    tokens.append(StyleToken(
                        name: "exploratory",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 10:
                    tokens.append(StyleToken(
                        name: "goal-oriented",
                        type: "structure",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 11:
                    tokens.append(StyleToken(
                        name: "community-minded",
                        type: "expression",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 12:
                    tokens.append(StyleToken(
                        name: "introspective",
                        type: "mood",
                        weight: 1.5 * 0.4,
                        planetarySource: "Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                default:
                    break
                }
            }
            
            // Find progressed Moon
            if let progressedMoon = progressed.planets.first(where: { $0.name == "Moon" }) {
                // Generate tokens from progressed Moon with 60% weight
                let moonSign = progressedMoon.zodiacSign
                let signName = CoordinateTransformations.getZodiacSignName(sign: moonSign)
                
                // Determine house using Placidus system
                let moonHouse = NatalChartCalculator.determineHouse(
                    longitude: progressedMoon.longitude,
                    houseCusps: progressed.houseCusps)
                
                // Add emotional style tokens based on progressed Moon sign with 60% weight
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(
                        name: "energetic",
                        type: "mood",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "direct",
                        type: "expression",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "coral red",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Taurus":
                    tokens.append(StyleToken(
                        name: "grounded",
                        type: "mood",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "sensual",
                        type: "texture",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "moss green",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Gemini":
                    tokens.append(StyleToken(
                        name: "versatile",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "communicative",
                        type: "expression",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "pale yellow",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Cancer":
                    tokens.append(StyleToken(
                        name: "protective",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "nurturing",
                        type: "mood",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "pearl",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Leo":
                    tokens.append(StyleToken(
                        name: "expressive",
                        type: "mood",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "warm",
                        type: "color",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "amber",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Virgo":
                    tokens.append(StyleToken(
                        name: "precise",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "refined",
                        type: "texture",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "taupe",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Libra":
                    tokens.append(StyleToken(
                        name: "balanced",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "harmonious",
                        type: "expression",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "lavender",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Scorpio":
                    tokens.append(StyleToken(
                        name: "intense",
                        type: "mood",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "transformative",
                        type: "structure",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "deep plum",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Sagittarius":
                    tokens.append(StyleToken(
                        name: "expansive",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "optimistic",
                        type: "mood",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "indigo",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Capricorn":
                    tokens.append(StyleToken(
                        name: "structured",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "disciplined",
                        type: "expression",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "slate gray",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Aquarius":
                    tokens.append(StyleToken(
                        name: "innovative",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "detached",
                        type: "mood",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "turquoise",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case "Pisces":
                    tokens.append(StyleToken(
                        name: "fluid",
                        type: "structure",
                        weight: 2.0 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "intuitive",
                        type: "mood",
                        weight: 1.8 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                    tokens.append(StyleToken(
                        name: "seafoam",
                        type: "color",
                        weight: 1.7 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                default:
                    tokens.append(StyleToken(
                        name: "responsive",
                        type: "mood",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                }
                
                // Add tokens based on Placidus house placement for progressed Moon
                switch moonHouse {
                case 1:
                    tokens.append(StyleToken(
                        name: "self-expressive",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 2:
                    tokens.append(StyleToken(
                        name: "value-oriented",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 3:
                    tokens.append(StyleToken(
                        name: "communicative",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 4:
                    tokens.append(StyleToken(
                        name: "nurturing",
                        type: "mood",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 5:
                    tokens.append(StyleToken(
                        name: "creative",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 6:
                    tokens.append(StyleToken(
                        name: "practical",
                        type: "structure",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 7:
                    tokens.append(StyleToken(
                        name: "relationship-oriented",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 8:
                    tokens.append(StyleToken(
                        name: "transformative",
                        type: "structure",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 9:
                    tokens.append(StyleToken(
                        name: "exploratory",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 10:
                    tokens.append(StyleToken(
                        name: "goal-oriented",
                        type: "structure",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 11:
                    tokens.append(StyleToken(
                        name: "community-minded",
                        type: "expression",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                case 12:
                    tokens.append(StyleToken(
                        name: "introspective",
                        type: "mood",
                        weight: 1.5 * 0.6,
                        planetarySource: "Progressed Moon",
                        signSource: signName,
                        houseSource: moonHouse
                    ))
                default:
                    break
                }
            }
            
            return tokens
        }
    
    /// Generate tokens from moon phase
    static func generateMoonPhaseTokens(moonPhase: Double) -> [StyleToken] {
        // Get the moon phase interpretation
        let phase = MoonPhaseInterpreter.Phase.fromDegrees(moonPhase)
        
        // Get tokens for daily vibe
        let baseTokens = MoonPhaseInterpreter.tokensForDailyVibe(phase: phase)
        
        // Update tokens with originType
        let tokens = baseTokens.map { token in
            return StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: .phase
            )
        }
        
        return tokens
    }
    
    // MARK: - Public Interface Methods
    
    /// Generates tokens from natal chart, progressed chart, transits, and weather data
    static func generateAllTokens(natal: NatalChartCalculator.NatalChart,
                                  progressed: NatalChartCalculator.NatalChart,
                                  transits: [[String: Any]],
                                  weather: TodayWeather?,
                                  currentAge: Int = 30) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate tokens from natal chart (base tokens)
        let natalTokens = generateTokensFromNatalChart(natal, currentAge: currentAge)
        tokens.append(contentsOf: natalTokens)
        
        // Generate tokens from progressed chart
        let progressedTokens = generateTokensFromProgressedChart(progressed)
        tokens.append(contentsOf: progressedTokens)
        
        // Generate tokens from transits
        let transitTokens = generateTransitTokens(transits: transits, natal: natal)
        tokens.append(contentsOf: transitTokens)
        
        // Generate tokens from moon phase
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        let moonPhaseTokens = generateMoonPhaseTokens(moonPhase: lunarPhase)
        tokens.append(contentsOf: moonPhaseTokens)
        
        // Generate tokens from weather if available
        if let weather = weather {
            let weatherTokens = generateWeatherTokens(weather: weather)
            tokens.append(contentsOf: weatherTokens)
        }
        
        return tokens
    }
}
