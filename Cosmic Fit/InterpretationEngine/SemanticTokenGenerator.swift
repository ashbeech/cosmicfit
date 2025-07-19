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
    
    // MARK: - Enhanced Color Token Generation
    
    /// Fixed generateAspectColorTokens method
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
                    
                    // Generate color tokens based on the aspect using FIXED library lookup
                    if let aspectColors = getAspectColorTokens(aspectType: aspectType, planet1: planet1.name, planet2: planet2.name) {
                        for (colorName, colorType) in aspectColors {
                            tokens.append(StyleToken(
                                name: colorName,
                                type: colorType,
                                weight: aspectWeight,
                                planetarySource: "\(planet1.name)-\(planet2.name)",
                                aspectSource: aspectSource
                            ))
                            aspectWeight -= 0.2 // Decrease weight for subsequent tokens
                        }
                    }
                }
            }
        }
        
        return tokens
    }
    
    /// Enhanced generateColorTokensForPlanetInSign using library data
    private static func generateColorTokensForPlanetInSign(
        planet: String,
        sign: Int,
        weight: Double,
        isProgressed: Bool = false,
        isRetrograde: Bool = false) -> [StyleToken] {
            
        var tokens: [StyleToken] = []
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        let source = isProgressed ? "Progressed \(planet)" : planet
        
        // Get color descriptions from library - NOW PROPERLY IMPLEMENTED
        if let planetColorDescriptions = getPlanetColorDescriptions(planet: planet, signName: signName) {
            var currentWeight = weight
            for (colorName, colorType) in planetColorDescriptions {
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: currentWeight,
                    planetarySource: source,
                    signSource: signName
                ))
                currentWeight -= 0.1 // Decrease weight for subsequent colors
            }
        } else {
            // Fallback to elemental colors
            let elementalColors = getElementalColorTokens(signName: signName)
            var currentWeight = weight * 0.8
            for (colorName, colorType) in elementalColors {
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: currentWeight,
                    planetarySource: source,
                    signSource: signName
                ))
                currentWeight -= 0.1
            }
        }
        
        // Add retrograde tokens if applicable
        if isRetrograde {
            let retrogradeColors = InterpretationTextLibrary.TokenGeneration.PlanetInSign.Retrograde.general
            for (colorName, colorType) in retrogradeColors {
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: weight * 0.8,
                    planetarySource: source,
                    signSource: signName,
                    aspectSource: "Retrograde"
                ))
            }
            
            // Add specific retrograde color modifications
            if let specificRetrograde = getRetrogradeColorTokens(planet: planet) {
                for (colorName, colorType) in specificRetrograde {
                    tokens.append(StyleToken(
                        name: colorName,
                        type: colorType,
                        weight: weight * 0.7,
                        planetarySource: source,
                        signSource: signName,
                        aspectSource: "Retrograde"
                    ))
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
            
            // Get ascendant color descriptions from library
            if let ascendantDescriptions = InterpretationTextLibrary.TokenGeneration.Ascendant.descriptions[signName] {
                var currentWeight = weight
                for (tokenName, tokenType) in ascendantDescriptions {
                    tokens.append(StyleToken(
                        name: tokenName,
                        type: tokenType,
                        weight: currentWeight,
                        planetarySource: "Ascendant",
                        signSource: signName
                    ))
                    currentWeight -= 0.1
                }
            }
            
            // Add elemental token based on the sign
            let elementName = getElementForSign(signName)
            tokens.append(StyleToken(
                name: elementName,
                type: "element",
                weight: weight * 0.9,
                planetarySource: "Ascendant",
                signSource: signName
            ))
            
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
        
        // Use library for elemental color descriptions
        if fireCount > threshold + 1 {
            let fireDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["fire"] ?? []
            for (colorName, colorType) in fireDescriptions {
                let weight = colorType == "color" ? 2.5 : (colorType == "color_quality" ? 2.3 : 2.2)
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Fire Signs"
                ))
            }
        }
        
        if earthCount > threshold + 1 {
            let earthDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["earth"] ?? []
            for (colorName, colorType) in earthDescriptions {
                let weight = colorType == "color" ? 2.5 : (colorType == "color_quality" ? 2.3 : 2.2)
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Earth Signs"
                ))
            }
        }
        
        if airCount > threshold + 1 {
            let airDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["air"] ?? []
            for (colorName, colorType) in airDescriptions {
                let weight = colorType == "color" ? 2.5 : (colorType == "color_quality" ? 2.3 : 2.2)
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Air Signs"
                ))
            }
        }
        
        if waterCount > threshold + 1 {
            let waterDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["water"] ?? []
            for (colorName, colorType) in waterDescriptions {
                let weight = colorType == "color" ? 2.5 : (colorType == "color_quality" ? 2.3 : 2.2)
                tokens.append(StyleToken(
                    name: colorName,
                    type: colorType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Water Signs"
                ))
            }
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
            
            // Add color tokens based on dignity status using library
            if let dignityColors = getDignityColorTokens(planet: planet.name, dignity: dignity) {
                for (colorName, colorType) in dignityColors {
                    let weight = dignity == .domicile ? 2.2 : (dignity == .exaltation ? 2.0 : 1.8)
                    tokens.append(StyleToken(
                        name: colorName,
                        type: colorType,
                        weight: weight,
                        planetarySource: planet.name,
                        signSource: signName,
                        aspectSource: dignity.rawValue.capitalized
                    ))
                }
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
    enum DignityStatus: String {
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
                    
                    // Generate color nuance based on the aspect type and planet using library
                    if let aspectColors = getColorNuanceTokens(aspectType: aspectType, planet: planet.name) {
                        for (colorName, colorType) in aspectColors {
                            tokens.append(StyleToken(
                                name: colorName,
                                type: colorType,
                                weight: weight,
                                planetarySource: "Venus-\(planet.name)",
                                aspectSource: aspectName
                            ))
                            weight -= 0.2
                        }
                    }
                }
            }
        }
        
        return tokens
    }
    
    // MARK: - Wardrobe Storyline Token Generation
    
    /// Generate tokens for Wardrobe Storyline (60% progressed using Placidus, 40% natal)
    static func generateWardrobeStorylineTokens(
        natal: NatalChartCalculator.NatalChart,
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
            }
            
            return tokens
        }
    
    // MARK: - Token Generation from Weather
    
    static func generateWeatherTokens(weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // ONLY temperature-based tokens - ignore conditions completely
        let temperatureDescriptions = InterpretationTextLibrary.Weather.Temperature.descriptions
        for (threshold, weatherType, textureType, _) in temperatureDescriptions {
            if weather.temp < Double(threshold) {
                // Calculate weight based on temperature extremity
                let extremityWeight = calculateTemperatureWeight(temp: weather.temp, threshold: threshold)
                
                tokens.append(StyleToken(name: weatherType, type: "weather", weight: extremityWeight,
                                       planetarySource: nil, signSource: nil, houseSource: nil,
                                       aspectSource: "Temperature Safety", originType: .weather))
                tokens.append(StyleToken(name: textureType, type: "texture", weight: extremityWeight,
                                       planetarySource: nil, signSource: nil, houseSource: nil,
                                       aspectSource: "Temperature Safety", originType: .weather))
                break
            }
        }
        
        // Remove all condition-based logic (rain, storms, etc.)
        return tokens
    }
    
    /*
    /// Generate enhanced weather tokens with daily variation
    static func generateWeatherTokens(weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Base weight for weather
        let baseWeight: Double = 1.0
        
        // Temperature tokens with enhanced nuance using library
        let temperatureDescriptions = InterpretationTextLibrary.Weather.Temperature.descriptions
        for (threshold, weatherType, textureType, _) in temperatureDescriptions {
            if weather.temp < Double(threshold) {
                tokens.append(StyleToken(name: weatherType, type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
                tokens.append(StyleToken(name: textureType, type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
                break
            }
        }
        
        // Expanded condition tokens using library
        let weatherConditions = InterpretationTextLibrary.Weather.Conditions.weatherConditions
        let lowerConditions = weather.conditions.lowercased()
        
        for (condition, (weatherType, structureType)) in weatherConditions {
            if lowerConditions.contains(condition) {
                tokens.append(StyleToken(name: weatherType, type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
                tokens.append(StyleToken(name: structureType, type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
                break
            }
        }
        
        // If no specific condition found, add default
        if tokens.isEmpty || !tokens.contains(where: { $0.type == "weather" && $0.name != temperatureDescriptions.first(where: { weather.temp < Double($0.0) })?.1 }) {
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather", originType: .weather))
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
    */
    
    private static func calculateTemperatureWeight(temp: Double, threshold: Int) -> Double {
        let thresholdTemp = Double(threshold)
        
        switch threshold {
        case ...0:      return 8.0  // Freezing - MUST override cosmic suggestions
        case 1...10:    return 6.0  // Cold - strong override
        case 11...15:   return 3.0  // Cool - moderate influence
        case 16...24:   return 1.0  // Mild - minimal influence
        case 25...29:   return 3.0  // Warm - moderate influence
        case 30...34:   return 6.0  // Hot - strong override
        default:        return 8.0  // Scorching - MUST override
        }
    }
    
    // Enhanced temperature conflict resolution
    static func resolveTemperatureConflicts(tokens: [StyleToken], weather: TodayWeather) -> [StyleToken] {
        var resolvedTokens = tokens
        
        // Define comprehensive conflicting elements by temperature ranges
        let hotWeatherConflicts = [
            // Fabric types
            "wool", "cashmere", "fleece", "velvet", "corduroy", "tweed", "mohair", "alpaca",
            // Texture descriptors
            "thick", "heavy", "insulated", "cozy", "plush", "padded", "quilted", "lined",
            // Style descriptors
            "luxurious", "layered", "bundled", "wrapped", "covered", "enclosed",
            // Coverage levels
            "full-coverage", "high-coverage", "conservative", "modest"
        ]
        
        let coldWeatherConflicts = [
            // Fabric types
            "chiffon", "voile", "organza", "tulle", "mesh", "lace", "gauze", "silk charmeuse",
            // Texture descriptors
            "sheer", "translucent", "transparent", "breathable", "airy", "lightweight", "delicate",
            // Style descriptors
            "minimal", "exposed", "open", "flowing", "loose", "breezy",
            // Coverage levels
            "minimal-coverage", "low-coverage", "revealing", "bare"
        ]
        
        // Temperature-based conflict resolution with graduated responses
        if weather.temp >= 32 {  // Scorching (32°C+)
            resolvedTokens = suppressConflictingTokens(resolvedTokens, hotWeatherConflicts, 0.05) // Extreme suppression
        } else if weather.temp >= 28 {  // Hot (28-31°C)
            resolvedTokens = suppressConflictingTokens(resolvedTokens, hotWeatherConflicts, 0.15) // Heavy suppression
        } else if weather.temp >= 25 {  // Warm (25-27°C)
            let lightConflicts = ["thick", "heavy", "insulated", "cozy", "wool", "cashmere", "fleece"]
            resolvedTokens = suppressConflictingTokens(resolvedTokens, lightConflicts, 0.4) // Moderate suppression
        } else if weather.temp <= 2 {  // Freezing (2°C and below)
            resolvedTokens = suppressConflictingTokens(resolvedTokens, coldWeatherConflicts, 0.05) // Extreme suppression
        } else if weather.temp <= 8 {  // Cold (3-8°C)
            resolvedTokens = suppressConflictingTokens(resolvedTokens, coldWeatherConflicts, 0.15) // Heavy suppression
        } else if weather.temp <= 12 {  // Cool (9-12°C)
            let lightConflicts = ["sheer", "translucent", "minimal", "lightweight", "chiffon", "voile"]
            resolvedTokens = suppressConflictingTokens(resolvedTokens, lightConflicts, 0.4) // Moderate suppression
        }
        
        // Add temperature-appropriate enhancement tokens
        resolvedTokens = addTemperatureAppropriateTokens(resolvedTokens, weather.temp)
        
        return resolvedTokens
    }
    
    private static func suppressConflictingTokens(_ tokens: [StyleToken], _ conflicts: [String], _ suppressionFactor: Double) -> [StyleToken] {
        return tokens.map { token in
            if conflicts.contains(token.name.lowercased()) {
                return StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * suppressionFactor,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: "Temperature Safety Override",
                    originType: token.originType
                )
            }
            return token
        }
    }

    // Helper function to add temperature-appropriate tokens
    private static func addTemperatureAppropriateTokens(_ tokens: [StyleToken], _ temperature: Double) -> [StyleToken] {
        var enhancedTokens = tokens
        
        if temperature >= 28 {  // Hot weather - add cooling elements
            let coolingTokens = [
                StyleToken(name: "breathable", type: "fabric", weight: 4.0, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Temperature Safety", originType: .weather),
                StyleToken(name: "lightweight", type: "texture", weight: 4.0, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Temperature Safety", originType: .weather),
                StyleToken(name: "airy", type: "structure", weight: 3.5, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Temperature Safety", originType: .weather)
            ]
            enhancedTokens.append(contentsOf: coolingTokens)
        } else if temperature <= 8 {  // Cold weather - add warming elements
            let warmingTokens = [
                StyleToken(name: "insulating", type: "fabric", weight: 4.0, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Temperature Safety", originType: .weather),
                StyleToken(name: "layerable", type: "structure", weight: 4.0, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Temperature Safety", originType: .weather),
                StyleToken(name: "protective", type: "texture", weight: 3.5, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Temperature Safety", originType: .weather)
            ]
            enhancedTokens.append(contentsOf: warmingTokens)
        }
        
        return enhancedTokens
    }
    
    // MARK: - Helper Methods for Token Generation
    
    /// Helper function to get daily pattern seed
    private static func getDailyPatternSeed() -> Int {
        // Generate a unique but stable seed for each day
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return (components.day ?? 1) + ((components.month ?? 1) * 31) +
        ((components.year ?? 2025) * 366)
    }
    
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
                    currentWeight -= 0.1 // Decrease weight for subsequent tokens
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
            
            // Add retrograde tokens if applicable with source tracking
            if isRetrograde {
                let retrogradeTokens = InterpretationTextLibrary.TokenGeneration.PlanetInSign.Retrograde.general
                for (tokenName, tokenType) in retrogradeTokens {
                    tokens.append(StyleToken(
                        name: tokenName,
                        type: tokenType,
                        weight: weight * 0.9,
                        planetarySource: planetSource,
                        signSource: signName,
                        aspectSource: "Retrograde",
                        originType: originType
                    ))
                }
                
                // Add specific retrograde modifications for certain planets
                if let specificRetrograde = getRetrogradeTokens(planet: planet) {
                    for (tokenName, tokenType) in specificRetrograde {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: weight * 0.7,
                            planetarySource: planetSource,
                            signSource: signName,
                            aspectSource: "Retrograde",
                            originType: originType
                        ))
                    }
                }
            }
            
            return tokens
        }
    
    /// Generate tokens for Ascendant (Rising Sign) with source tracking
    static func tokenizeForAscendant(sign: Int, signName: String, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate tokens based on rising sign using library
        if let ascendantDescriptions = InterpretationTextLibrary.TokenGeneration.Ascendant.descriptions[signName] {
            var currentWeight = weight
            for (tokenName, tokenType) in ascendantDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: currentWeight,
                    planetarySource: "Ascendant",
                    signSource: signName,
                    originType: .natal
                ))
                currentWeight -= 0.1
            }
        }
        
        // Add elemental token based on the sign using library
        let elementName = getElementForSign(signName)
        tokens.append(StyleToken(
            name: elementName,
            type: "element",
            weight: weight * 0.9,
            planetarySource: "Ascendant",
            signSource: signName,
            originType: .natal
        ))
        
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
            
            // Get house descriptions from library
            if let houseDescriptions = InterpretationTextLibrary.TokenGeneration.Houses.descriptions[house] {
                var currentWeight = weight
                for (tokenName, tokenType) in houseDescriptions {
                    tokens.append(StyleToken(
                        name: tokenName,
                        type: tokenType,
                        weight: currentWeight,
                        planetarySource: planetSource,
                        houseSource: house,
                        originType: originType
                    ))
                    currentWeight -= 0.1
                }
            }
            
            // Special case for planets in houses that particularly affect appearance
            if [1, 5, 7, 10].contains(house) && ["Sun", "Venus", "Moon", "Mars"].contains(planet) {
                tokens.append(StyleToken(
                    name: "appearance-focused",
                    type: "expression",
                    weight: weight * 1.2,
                    planetarySource: planetSource,
                    houseSource: house,
                    originType: originType
                ))
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
            
            // Major transits to fashion-relevant planets using library
            if ["Venus", "Moon", "Sun", "Mars"].contains(natalPlanet) {
                if let transitDescriptions = getTransitDescriptions(aspectType: aspectType, transitPlanet: transitPlanet) {
                    var currentWeight = weight
                    for (tokenName, tokenType) in transitDescriptions {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: currentWeight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource,
                            originType: .transit
                        ))
                        currentWeight -= 0.2
                    }
                } else {
                    // Fallback to general transit tokens
                    let generalTransits = InterpretationTextLibrary.TokenGeneration.Transits.general
                    for (tokenName, tokenType) in generalTransits {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: weight * 0.6,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource,
                            originType: .transit
                        ))
                    }
                }
            } else {
                // For transits to less fashion-relevant planets, add general tokens
                if ["Conjunction", "Opposition", "Trine", "Square", "Sextile"].contains(aspectType) {
                    let generalTransits = InterpretationTextLibrary.TokenGeneration.Transits.general
                    for (tokenName, tokenType) in generalTransits {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: weight * 0.6,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource,
                            originType: .transit
                        ))
                    }
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
        
        // Add elemental tokens based on dominance using library
        let total = fireCount + earthCount + airCount + waterCount
        let threshold = total / 4
        
        if fireCount > threshold + 1 {
            let fireDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["fire"] ?? []
            for (tokenName, tokenType) in fireDescriptions {
                let weight = tokenType.contains("color") ? 2.5 : 2.8
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Fire Signs",
                    originType: .natal
                ))
            }
        }
        
        if earthCount > threshold + 1 {
            let earthDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["earth"] ?? []
            for (tokenName, tokenType) in earthDescriptions {
                let weight = tokenType.contains("color") ? 2.5 : 2.8
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Earth Signs",
                    originType: .natal
                ))
            }
        }
        
        if airCount > threshold + 1 {
            let airDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["air"] ?? []
            for (tokenName, tokenType) in airDescriptions {
                let weight = tokenType.contains("color") ? 2.5 : 2.8
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Air Signs",
                    originType: .natal
                ))
            }
        }
        
        if waterCount > threshold + 1 {
            let waterDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.descriptions["water"] ?? []
            for (tokenName, tokenType) in waterDescriptions {
                let weight = tokenType.contains("color") ? 2.5 : 2.8
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: weight,
                    planetarySource: "Elemental Balance",
                    signSource: "Water Signs",
                    originType: .natal
                ))
            }
        }
        
        // Handle lacking elements using library
        if fireCount < threshold - 1 {
            let lackDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.lack["fire"] ?? []
            for (tokenName, tokenType) in lackDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: 2.0,
                    planetarySource: "Elemental Balance",
                    signSource: "Lack of Fire",
                    originType: .natal
                ))
            }
        }
        
        if earthCount < threshold - 1 {
            let lackDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.lack["earth"] ?? []
            for (tokenName, tokenType) in lackDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: 2.0,
                    planetarySource: "Elemental Balance",
                    signSource: "Lack of Earth",
                    originType: .natal
                ))
            }
        }
        
        if airCount < threshold - 1 {
            let lackDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.lack["air"] ?? []
            for (tokenName, tokenType) in lackDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: 2.0,
                    planetarySource: "Elemental Balance",
                    signSource: "Lack of Air",
                    originType: .natal
                ))
            }
        }
        
        if waterCount < threshold - 1 {
            let lackDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.lack["water"] ?? []
            for (tokenName, tokenType) in lackDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: 2.0,
                    planetarySource: "Elemental Balance",
                    signSource: "Lack of Water",
                    originType: .natal
                ))
            }
        }
        
        // If no clear elemental dominance, add balanced tokens
        if fireCount <= threshold + 1 && earthCount <= threshold + 1 &&
            airCount <= threshold + 1 && waterCount <= threshold + 1 {
            let balancedDescriptions = InterpretationTextLibrary.TokenGeneration.ElementalBalance.balanced
            for (tokenName, tokenType) in balancedDescriptions {
                tokens.append(StyleToken(
                    name: tokenName,
                    type: tokenType,
                    weight: 2.5,
                    planetarySource: "Elemental Balance",
                    signSource: "All Elements",
                    originType: .natal
                ))
            }
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
                    
                    // Generate aspect-specific tokens using library
                    // Note: This would need more complex logic to match specific planet combinations
                    // For now, using general aspect descriptions
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
                
                // Add emotional style tokens based on Moon sign with 40% weight using library
                if let moonDescriptions = InterpretationTextLibrary.TokenGeneration.PlanetInSign.Moon.descriptions[signName] {
                    for (tokenName, tokenType) in moonDescriptions {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: 2.0 * 0.4,
                            planetarySource: "Moon",
                            signSource: signName,
                            houseSource: moonHouse
                        ))
                    }
                }
                
                // Add tokens based on Placidus house placement using library
                if let houseDescriptions = InterpretationTextLibrary.TokenGeneration.Houses.descriptions[moonHouse] {
                    for (tokenName, tokenType) in houseDescriptions {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: 1.5 * 0.4,
                            planetarySource: "Moon",
                            signSource: signName,
                            houseSource: moonHouse
                        ))
                    }
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
                
                // Add emotional style tokens based on progressed Moon sign with 60% weight using library
                if let moonDescriptions = InterpretationTextLibrary.TokenGeneration.PlanetInSign.Moon.descriptions[signName] {
                    for (tokenName, tokenType) in moonDescriptions {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: 2.0 * 0.6,
                            planetarySource: "Progressed Moon",
                            signSource: signName,
                            houseSource: moonHouse
                        ))
                    }
                }
                
                // Add tokens based on Placidus house placement for progressed Moon using library
                if let houseDescriptions = InterpretationTextLibrary.TokenGeneration.Houses.descriptions[moonHouse] {
                    for (tokenName, tokenType) in houseDescriptions {
                        tokens.append(StyleToken(
                            name: tokenName,
                            type: tokenType,
                            weight: 1.5 * 0.6,
                            planetarySource: "Progressed Moon",
                            signSource: signName,
                            houseSource: moonHouse
                        ))
                    }
                }
            }
            
            return tokens
        }
    
    /// Generate tokens for moon phase with enhanced daily influence
    static func generateMoonPhaseTokens(moonPhase: Double) -> [StyleToken] {
        // Get the moon phase interpretation
        let phase = MoonPhaseInterpreter.Phase.fromDegrees(moonPhase)
        
        // Get tokens for daily vibe
        let baseTokens = MoonPhaseInterpreter.tokensForDailyVibe(phase: phase)
        
        // Update tokens with originType
        var tokens = baseTokens.map { token in
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
        
        // Add daily lunar specific color variations based on exact degree
        // This provides nuanced daily changes even within the same phase
        let lunarDegree = Int(moonPhase) % 30
        
        // Add specific color/mood based on degree within sign
        if lunarDegree < 10 {
            // Early degrees
            tokens.append(StyleToken(
                name: "emerging",
                type: "mood",
                weight: 1.8,
                planetarySource: "Moon Phase",
                aspectSource: "Lunar degree \(lunarDegree)",
                originType: .phase
            ))
        } else if lunarDegree < 20 {
            // Middle degrees
            tokens.append(StyleToken(
                name: "established",
                type: "mood",
                weight: 1.8,
                planetarySource: "Moon Phase",
                aspectSource: "Lunar degree \(lunarDegree)",
                originType: .phase
            ))
        } else {
            // Late degrees
            tokens.append(StyleToken(
                name: "completing",
                type: "mood",
                weight: 1.8,
                planetarySource: "Moon Phase",
                aspectSource: "Lunar degree \(lunarDegree)",
                originType: .phase
            ))
        }
        
        return tokens
    }
    
    // MARK: - Public Interface Methods
    
    /*
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
            
            // 🔥⚔️❄️ Apply temperature conflict resolution
            tokens = resolveTemperatureConflicts(tokens: tokens, weather: weather)
        }
        
        return tokens
    }*/
    
    // MARK: - Library Helper Methods
    
    /// Get planet in sign descriptions from library
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
        case "Neptune":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.neptune
        case "Pluto":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.pluto
        case "Jupiter":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.jupiter
        case "Saturn":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.saturn
        case "Uranus":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.uranus
        default:
            return nil
        }
    }
    
    // MARK: - Fixed Library Helper Methods for SemanticTokenGenerator.swift

    /// Get planet color descriptions from library
    private static func getPlanetColorDescriptions(planet: String, signName: String) -> [(String, String)]? {
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
        case "Neptune":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.neptune
        case "Pluto":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.pluto
        case "Jupiter":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.jupiter
        case "Saturn":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.saturn
        case "Uranus":
            return InterpretationTextLibrary.TokenGeneration.PlanetInSign.OuterPlanets.uranus
        default:
            return nil
        }
    }

    /// Get aspect color tokens from library with proper key matching
    private static func getAspectColorTokens(aspectType: String, planet1: String, planet2: String) -> [(String, String)]? {
        // Try both planet order combinations
        let key1 = "\(planet1)\(planet2)"
        let key2 = "\(planet2)\(planet1)"
        
        switch aspectType {
        case "Conjunction":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.conjunction[key1] ??
                   InterpretationTextLibrary.TokenGeneration.AspectColors.conjunction[key2]
        case "Trine":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.trine[key1] ??
                   InterpretationTextLibrary.TokenGeneration.AspectColors.trine[key2]
        case "Square":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.square[key1] ??
                   InterpretationTextLibrary.TokenGeneration.AspectColors.square[key2]
        case "Opposition":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.opposition[key1] ??
                   InterpretationTextLibrary.TokenGeneration.AspectColors.opposition[key2]
        default:
            return InterpretationTextLibrary.TokenGeneration.AspectColors.minor
        }
    }

    /// Get elemental fallback tokens from library
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
    
    /// Get elemental color tokens from library
    private static func getElementalColorTokens(signName: String) -> [(String, String)] {
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
    
    /// Get retrograde tokens from library
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
    
    /// Get retrograde color tokens from library
    private static func getRetrogradeColorTokens(planet: String) -> [(String, String)]? {
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
    
    /// Get element for sign
    private static func getElementForSign(_ signName: String) -> String {
        if ["Aries", "Leo", "Sagittarius"].contains(signName) {
            return "fiery"
        } else if ["Taurus", "Virgo", "Capricorn"].contains(signName) {
            return "earthy"
        } else if ["Gemini", "Libra", "Aquarius"].contains(signName) {
            return "airy"
        } else if ["Cancer", "Scorpio", "Pisces"].contains(signName) {
            return "watery"
        } else {
            return "balanced"
        }
    }
    
    /// Get aspect color tokens from library
    private static func getAspectColorTokens(aspectType: String, planetKey: String) -> [(String, String)]? {
        switch aspectType {
        case "Conjunction":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.conjunction[planetKey]
        case "Trine":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.trine[planetKey]
        case "Square":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.square[planetKey]
        case "Opposition":
            return InterpretationTextLibrary.TokenGeneration.AspectColors.opposition[planetKey]
        default:
            return InterpretationTextLibrary.TokenGeneration.AspectColors.minor
        }
    }
    
    /// Get dignity color tokens from library
    private static func getDignityColorTokens(planet: String, dignity: DignityStatus) -> [(String, String)]? {
        switch dignity {
        case .domicile:
            return InterpretationTextLibrary.TokenGeneration.DignityColors.domicile[planet]
        case .exaltation:
            return InterpretationTextLibrary.TokenGeneration.DignityColors.exaltation[planet]
        case .fall:
            return InterpretationTextLibrary.TokenGeneration.DignityColors.fall[planet]
        case .detriment:
            return InterpretationTextLibrary.TokenGeneration.DignityColors.detriment[planet]
        case .peregrine:
            return nil
        }
    }
    
    /// Get color nuance tokens from library
    private static func getColorNuanceTokens(aspectType: String, planet: String) -> [(String, String)]? {
        switch aspectType {
        case "Conjunction":
            return InterpretationTextLibrary.TokenGeneration.ColorNuance.conjunction[planet]
        case "Trine":
            return InterpretationTextLibrary.TokenGeneration.ColorNuance.trine[planet]
        case "Square":
            return InterpretationTextLibrary.TokenGeneration.ColorNuance.square[planet]
        case "Opposition":
            return InterpretationTextLibrary.TokenGeneration.ColorNuance.opposition[planet]
        case "Sextile":
            return InterpretationTextLibrary.TokenGeneration.ColorNuance.sextile[planet]
        default:
            return InterpretationTextLibrary.TokenGeneration.ColorNuance.minor
        }
    }
    
    /// Get transit descriptions from library
    private static func getTransitDescriptions(aspectType: String, transitPlanet: String) -> [(String, String)]? {
        switch aspectType {
        case "Conjunction":
            return InterpretationTextLibrary.TokenGeneration.Transits.conjunction[transitPlanet]
        case "Opposition":
            return InterpretationTextLibrary.TokenGeneration.Transits.opposition[transitPlanet]
        case "Trine":
            return InterpretationTextLibrary.TokenGeneration.Transits.trine[transitPlanet]
        case "Square":
            return InterpretationTextLibrary.TokenGeneration.Transits.square[transitPlanet]
        case "Sextile":
            return InterpretationTextLibrary.TokenGeneration.Transits.sextile[transitPlanet]
        default:
            return InterpretationTextLibrary.TokenGeneration.Transits.minor
        }
    }
    
    /// Get aspect mood token from library
    private static func getAspectMoodToken(aspectType: String) -> String {
        switch aspectType {
        case "Conjunction":
            return InterpretationTextLibrary.TokenGeneration.Aspects.conjunction.first?.0 ?? "intensified"
        case "Opposition":
            return InterpretationTextLibrary.TokenGeneration.Aspects.opposition.first?.0 ?? "balanced"
        case "Trine":
            return InterpretationTextLibrary.TokenGeneration.Aspects.trine.first?.0 ?? "flowing"
        case "Square":
            return InterpretationTextLibrary.TokenGeneration.Aspects.square.first?.0 ?? "dynamic"
        case "Sextile":
            return InterpretationTextLibrary.TokenGeneration.Aspects.sextile.first?.0 ?? "harmonious"
        default:
            return InterpretationTextLibrary.TokenGeneration.Aspects.minor.first?.0 ?? "nuanced"
        }
    }
}
