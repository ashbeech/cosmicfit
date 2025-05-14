//
//  SemanticTokenGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Enhanced with source tracking and improved weighting

import Foundation

class SemanticTokenGenerator {
    
    // MARK: - Blueprint Specific Token Generation
    
    /// Generate Blueprint tokens with Whole Sign house system according to specification
    static func generateBlueprintTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
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
            tokens.append(contentsOf: planetTokens)
        }
        
        // Process rising sign (ascendant) - high influence on appearance
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascendantSign)
        let ascendantTokens = tokenizeForAscendant(
            sign: ascendantSign,
            signName: ascSignName,
            weight: 3.0)
        tokens.append(contentsOf: ascendantTokens)
        
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
            tokens.append(contentsOf: houseTokens)
        }
        
        // Generate elemental balance tokens
        let elementalTokens = generateElementalTokens(chart: natal)
        tokens.append(contentsOf: elementalTokens)
        
        // Generate aspect-based tokens
        let aspectTokens = generateAspectTokens(chart: natal)
        tokens.append(contentsOf: aspectTokens)
        
        return tokens
    }
    
    // MARK: - Color Frequency Token Generation
    
    /// Generate tokens for Color Frequency section (70% natal, 30% progressed)
    static func generateColorFrequencyTokens(natal: NatalChartCalculator.NatalChart,
                                             progressed: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate natal tokens with 70% weight
        let natalTokens = generateTokensFromNatalChart(natal)
        for token in natalTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.7,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource
            )
            tokens.append(adjustedToken)
        }
        
        // Generate progressed tokens with 30% weight
        let progressedTokens = generateTokensFromProgressedChart(progressed)
        for token in progressedTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.3,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource
            )
            tokens.append(adjustedToken)
        }
        
        return tokens
    }
    
    // MARK: - Wardrobe Storyline Token Generation
    
    /// Generate tokens for Wardrobe Storyline (60% progressed using Placidus, 40% natal)
    static func generateWardrobeStorylineTokens(natal: NatalChartCalculator.NatalChart,
                                                progressed: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate natal tokens with 40% weight using Whole Sign
        let natalTokens = generateBlueprintTokens(natal: natal)
        for token in natalTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.4,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource
            )
            tokens.append(adjustedToken)
        }
        
        // Generate progressed tokens with 60% weight using Placidus house system
        let progressedTokens = generateProgressedTokensForWardrobeStoryline(progressed)
        for token in progressedTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.6,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource
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
                                         progressed: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate natal tokens with 90% weight
        let natalTokens = generateBlueprintTokens(natal: natal)
        for token in natalTokens {
            // Create a new token with adjusted weight
            let adjustedToken = StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * 0.9,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource
            )
            tokens.append(adjustedToken)
        }
        
        // Add just a flavor of progressed chart (10%)
        // Focus on Moon (emotional evolution) and Venus (style evolution)
        for planet in progressed.planets {
            if planet.name == "Moon" || planet.name == "Venus" {
                let flavorTokens = tokenizeForPlanetInSign(
                    planet: planet.name,
                    sign: planet.zodiacSign,
                    isRetrograde: planet.isRetrograde,
                    weight: 1.0 * 0.1, // Reduced weight for just flavor
                    isProgressed: true)
                tokens.append(contentsOf: flavorTokens)
            }
        }
        
        return tokens
    }
    
    // MARK: - Token Generation from Natal Chart
    
    static func generateTokensFromNatalChart(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
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
            tokens.append(contentsOf: planetTokens)
        }
        
        // Process rising sign (ascendant) - high influence on appearance
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascendantSign)
        let ascendantTokens = tokenizeForAscendant(
            sign: ascendantSign,
            signName: ascSignName,
            weight: 3.0)
        tokens.append(contentsOf: ascendantTokens)
        
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
            tokens.append(contentsOf: houseTokens)
        }
        
        // Generate elemental balance tokens
        let elementalTokens = generateElementalTokens(chart: chart)
        tokens.append(contentsOf: elementalTokens)
        
        // Generate aspect-based tokens
        let aspectTokens = generateAspectTokens(chart: chart)
        tokens.append(contentsOf: aspectTokens)
        
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
    
    // MARK: - Token Generation from Transits
    
    static func generateTokensFromTransits(_ transits: [[String: Any]]) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        for transit in transits {
            let transitPlanet = transit["transitPlanet"] as? String ?? ""
            let natalPlanet = transit["natalPlanet"] as? String ?? ""
            let aspectType = transit["aspectType"] as? String ?? ""
            let applying = transit["applying"] as? Bool ?? false
            
            // Determine base weight
            var baseWeight: Double = 1.5 // Default for loose aspects
            
            // Major aspects get higher weight
            if ["Conjunction", "Opposition", "Trine", "Square", "Sextile"].contains(aspectType) {
                baseWeight = 2.5
            }
            
            // Applying aspects get slightly higher weight
            if applying {
                baseWeight += 0.5
            }
            
            // Modulate by planet importance for fashion
            var planetMultiplier: Double = 1.0
            if ["Venus", "Moon", "Sun"].contains(transitPlanet) {
                planetMultiplier = 1.2
            }
            
            let weight = baseWeight * planetMultiplier
            
            // Generate tokens based on the transit with aspect source tracking
            let aspectSource = "\(transitPlanet) \(aspectType) \(natalPlanet)"
            let transitTokens = tokenizeForTransit(
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                weight: weight,
                aspectSource: aspectSource)
            tokens.append(contentsOf: transitTokens)
        }
        
        return tokens
    }
    
    // MARK: - Token Generation from Weather
    
    static func generateTokensFromWeather(_ weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Base weight for weather
        let baseWeight: Double = 1.0
        
        // Temperature tokens
        if weather.temp < 10 {
            tokens.append(StyleToken(name: "cold", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "cozy", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        } else if weather.temp < 20 {
            tokens.append(StyleToken(name: "cool", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "layered", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        } else if weather.temp < 30 {
            tokens.append(StyleToken(name: "warm", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "breathable", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        } else {
            tokens.append(StyleToken(name: "hot", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "light", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        }
        
        // Condition tokens
        switch weather.conditions.lowercased() {
        case let c where c.contains("rain") || c.contains("drizzle") || c.contains("shower"):
            tokens.append(StyleToken(name: "damp", type: "weather", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "protected", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        case let c where c.contains("cloud"):
            tokens.append(StyleToken(name: "muted", type: "color", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "subdued", type: "mood", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        case let c where c.contains("snow") || c.contains("ice"):
            tokens.append(StyleToken(name: "crisp", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "insulated", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        case let c where c.contains("fog"):
            tokens.append(StyleToken(name: "diffused", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "soft", type: "edges", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        case let c where c.contains("sun") || c.contains("clear"):
            tokens.append(StyleToken(name: "bright", type: "color", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "vibrant", type: "mood", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        case let c where c.contains("wind"):
            tokens.append(StyleToken(name: "anchored", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
            tokens.append(StyleToken(name: "secure", type: "fabric", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        default:
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        }
        
        // Humidity tokens
        if weather.humidity > 80 {
            tokens.append(StyleToken(name: "moisture-wicking", type: "fabric", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        } else if weather.humidity < 30 {
            tokens.append(StyleToken(name: "hydrating", type: "texture", weight: baseWeight, planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: "Current Weather"))
        }
        
        return tokens
    }
    
    // MARK: - Helper Methods for Token Generation
    
    /// Generate tokens for a planet in a specific sign with source tracking
    private static func tokenizeForPlanetInSign(
        planet: String,
        sign: Int,
        isRetrograde: Bool,
        weight: Double,
        isProgressed: Bool = false) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Get zodiac sign name
            let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
            let planetSource = isProgressed ? "Progressed \(planet)" : planet
            
            // Generate tokens based on planet and sign
            switch planet {
            case "Sun":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "bold", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "dynamic", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "sensual", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "earthy", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "playful", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "protective", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "comfortable", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "radiant", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "refined", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "practical", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "harmonious", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "intense", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "transformative", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "adventurous", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "structured", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "distinctive", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "dreamy", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                default:
                    break
                }
                
            case "Moon":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "energetic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "impulsive", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "comforting", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "stable", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "adaptable", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "communicative", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "emotional", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "warm", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "dramatic", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "detailed", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "thoughtful", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "elegant", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "social", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "deep", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "emotional", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "optimistic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "free-spirited", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "grounded", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "reserved", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "unique", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "independent", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "soft", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "intuitive", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                default:
                    break
                }
                
            case "Venus":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "spontaneous", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "bold", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "luxurious", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "sensual", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "eclectic", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "playful", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "nostalgic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "glamorous", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "vibrant", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "subtle", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "refined", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "harmonious", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "balanced", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "magnetic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "exuberant", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "expansive", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "elegant", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "classic", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "unconventional", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "futuristic", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "romantic", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "dreamy", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                default:
                    break
                }
                
            case "Mars":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "assertive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "energetic", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "substantial", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "quick", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "protective", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "confident", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "bold", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "precise", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "detailed", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "harmonious", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "intense", type: "color", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "powerful", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "adventurous", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "expansive", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "disciplined", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "progressive", type: "mood", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "fluid", type: "texture", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "adaptive", type: "structure", weight: weight, planetarySource: planetSource, signSource: signName))
                default:
                    break
                }
                
            case "Mercury":
                switch signName {
                case "Aries":
                    tokens.append(StyleToken(name: "direct", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "quick", type: "pace", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Taurus":
                    tokens.append(StyleToken(name: "deliberate", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "practical", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Gemini":
                    tokens.append(StyleToken(name: "versatile", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "curious", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Cancer":
                    tokens.append(StyleToken(name: "intuitive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "receptive", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Leo":
                    tokens.append(StyleToken(name: "expressive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "confident", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Virgo":
                    tokens.append(StyleToken(name: "precise", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "analytical", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Libra":
                    tokens.append(StyleToken(name: "balanced", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "diplomatic", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Scorpio":
                    tokens.append(StyleToken(name: "penetrating", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "strategic", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Sagittarius":
                    tokens.append(StyleToken(name: "expansive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "optimistic", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Capricorn":
                    tokens.append(StyleToken(name: "structured", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "disciplined", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Aquarius":
                    tokens.append(StyleToken(name: "innovative", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "objective", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                case "Pisces":
                    tokens.append(StyleToken(name: "intuitive", type: "communication", weight: weight, planetarySource: planetSource, signSource: signName))
                    tokens.append(StyleToken(name: "imaginative", type: "approach", weight: weight, planetarySource: planetSource, signSource: signName))
                default:
                    break
                }
                
            default:
                // For other planets, add elemental tokens
                switch signName {
                case "Aries", "Leo", "Sagittarius":
                    tokens.append(StyleToken(name: "fiery", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName))
                    
                case "Taurus", "Virgo", "Capricorn":
                    tokens.append(StyleToken(name: "earthy", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName))
                    
                case "Gemini", "Libra", "Aquarius":
                    tokens.append(StyleToken(name: "airy", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName))
                    
                case "Cancer", "Scorpio", "Pisces":
                    tokens.append(StyleToken(name: "watery", type: "mood", weight: weight * 0.8, planetarySource: planetSource, signSource: signName))
                    
                default:
                    break
                }
            }
            
            // Add retrograde tokens if applicable with source tracking
            if isRetrograde {
                tokens.append(StyleToken(name: "reflective", type: "mood", weight: weight * 0.9, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde"))
                tokens.append(StyleToken(name: "introspective", type: "structure", weight: weight * 0.9, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde"))
                tokens.append(StyleToken(name: "nonlinear", type: "approach", weight: weight * 0.8, planetarySource: planetSource, signSource: signName, aspectSource: "Retrograde"))
            }
            
            return tokens
        }
    
    /// Generate tokens for Ascendant (Rising Sign) with source tracking
    private static func tokenizeForAscendant(sign: Int, signName: String, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate tokens based on rising sign - heavily weighted
        switch signName {
        case "Aries":
            tokens.append(StyleToken(name: "bold", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "direct", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Taurus":
            tokens.append(StyleToken(name: "stable", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "sensual", type: "texture", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Gemini":
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "communicative", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Cancer":
            tokens.append(StyleToken(name: "protective", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "nurturing", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Leo":
            tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "radiant", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Virgo":
            tokens.append(StyleToken(name: "precise", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "refined", type: "texture", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Libra":
            tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "harmonious", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Scorpio":
            tokens.append(StyleToken(name: "intense", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Sagittarius":
            tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "adventurous", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Capricorn":
            tokens.append(StyleToken(name: "structured", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "disciplined", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Aquarius":
            tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "unique", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
        case "Pisces":
            tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight, planetarySource: "Ascendant", signSource: signName))
            tokens.append(StyleToken(name: "intuitive", type: "expression", weight: weight, planetarySource: "Ascendant", signSource: signName))
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
    
    /// Generate tokens for a planet in a specific house with source tracking
    private static func tokenizeForPlanetInHouse(
        planet: String,
        house: Int,
        weight: Double,
        isProgressed: Bool = false) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            let planetSource = isProgressed ? "Progressed \(planet)" : planet
            
            // Different house meanings
            switch house {
            case 1: // 1st house - Self, appearance
                tokens.append(StyleToken(name: "visible", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "defining", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 2: // 2nd house - Values, possessions
                tokens.append(StyleToken(name: "tactile", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "substantial", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 3: // 3rd house - Communication, local environment
                tokens.append(StyleToken(name: "communicative", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "adaptable", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 4: // 4th house - Home, roots, security
                tokens.append(StyleToken(name: "comforting", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "grounded", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 5: // 5th house - Creativity, pleasure
                tokens.append(StyleToken(name: "playful", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 6: // 6th house - Work, health, service
                tokens.append(StyleToken(name: "practical", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "functional", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 7: // 7th house - Partnerships, relationships
                tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "harmonious", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 8: // 8th house - Transformation, shared resources
                tokens.append(StyleToken(name: "intense", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 9: // 9th house - Philosophy, travel, higher learning
                tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "cultural", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 10: // 10th house - Career, public image
                tokens.append(StyleToken(name: "authoritative", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "polished", type: "texture", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 11: // 11th house - Friends, groups, aspirations
                tokens.append(StyleToken(name: "unconventional", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "innovative", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                
            case 12: // 12th house - Spirituality, unconscious
                tokens.append(StyleToken(name: "mystical", type: "expression", weight: weight, planetarySource: planetSource, houseSource: house))
                tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight, planetarySource: planetSource, houseSource: house))
                
            default:
                break
            }
            
            // Special case for planets in houses that particularly affect appearance
            if [1, 5, 7, 10].contains(house) && ["Sun", "Venus", "Moon", "Mars"].contains(planet) {
                tokens.append(StyleToken(name: "appearance-focused", type: "expression", weight: weight * 1.2, planetarySource: planetSource, houseSource: house))
            }
            
            return tokens
        }
    
    /// Generate tokens based on transit aspects with source tracking
    private static func tokenizeForTransit(
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
                    tokens.append(StyleToken(name: "intensified", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "emotional", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "harmonious", type: "color", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "energetic", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    }
                    
                case "Opposition":
                    tokens.append(StyleToken(name: "contrasting", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "reflective", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "balanced", type: "color", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "dynamic", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    }
                    
                case "Trine":
                    tokens.append(StyleToken(name: "flowing", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "intuitive", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "attractive", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "confident", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    }
                    
                case "Square":
                    tokens.append(StyleToken(name: "structured", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "challenging", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "creative", type: "color", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "bold", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    }
                    
                case "Sextile":
                    tokens.append(StyleToken(name: "harmonious", type: "structure", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "supportive", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "pleasant", type: "texture", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "active", type: "mood", weight: weight, planetarySource: transitPlanet, aspectSource: aspectSource))
                    }
                    
                default:
                    // For minor aspects, add less specific tokens
                    if transitPlanet == "Moon" {
                        tokens.append(StyleToken(name: "subtle", type: "texture", weight: weight * 0.7, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Venus" {
                        tokens.append(StyleToken(name: "nuanced", type: "color", weight: weight * 0.7, planetarySource: transitPlanet, aspectSource: aspectSource))
                    } else if transitPlanet == "Mars" {
                        tokens.append(StyleToken(name: "gentle", type: "structure", weight: weight * 0.7, planetarySource: transitPlanet, aspectSource: aspectSource))
                    }
                }
            } else {
                // For transits to less fashion-relevant planets, add more general tokens
                if ["Conjunction", "Opposition", "Trine", "Square", "Sextile"].contains(aspectType) {
                    tokens.append(StyleToken(name: "shifting", type: "mood", weight: weight * 0.6, planetarySource: transitPlanet, aspectSource: aspectSource))
                }
            }
            
            return tokens
        }
    
    // MARK: - Additional Token Generation Methods
    
    /// Generate tokens based on elemental balance in chart
    private static func generateElementalTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
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
            tokens.append(StyleToken(name: "fiery", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
            tokens.append(StyleToken(name: "passionate", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
            tokens.append(StyleToken(name: "dynamic", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Fire Signs"))
        }
        
        if earthCount > threshold + 1 {
            tokens.append(StyleToken(name: "earthy", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
            tokens.append(StyleToken(name: "grounded", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
            tokens.append(StyleToken(name: "stable", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Earth Signs"))
        }
        
        if airCount > threshold + 1 {
            tokens.append(StyleToken(name: "airy", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Air Signs"))
            tokens.append(StyleToken(name: "intellectual", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Air Signs"))
            tokens.append(StyleToken(name: "communicative", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Air Signs"))
        }
        
        if waterCount > threshold + 1 {
            tokens.append(StyleToken(name: "watery", type: "element", weight: 3.0, planetarySource: "Elemental Balance", signSource: "Water Signs"))
            tokens.append(StyleToken(name: "emotional", type: "mood", weight: 2.8, planetarySource: "Elemental Balance", signSource: "Water Signs"))
            tokens.append(StyleToken(name: "intuitive", type: "structure", weight: 2.7, planetarySource: "Elemental Balance", signSource: "Water Signs"))
        }
        
        // Balanced or lacking elements
        if fireCount < threshold - 1 {
            tokens.append(StyleToken(name: "reserved", type: "mood", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Fire"))
        }
        
        if earthCount < threshold - 1 {
            tokens.append(StyleToken(name: "ethereal", type: "texture", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Earth"))
        }
        
        if airCount < threshold - 1 {
            tokens.append(StyleToken(name: "instinctive", type: "approach", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Air"))
        }
        
        if waterCount < threshold - 1 {
            tokens.append(StyleToken(name: "structured", type: "approach", weight: 2.0, planetarySource: "Elemental Balance", signSource: "Lack of Water"))
        }
        
        // If no clear elemental dominance, add a balanced token
        if fireCount <= threshold + 1 && earthCount <= threshold + 1 &&
            airCount <= threshold + 1 && waterCount <= threshold + 1 {
            tokens.append(StyleToken(name: "balanced", type: "element", weight: 2.5, planetarySource: "Elemental Balance", signSource: "All Elements"))
        }
        
        return tokens
    }
    
    /// Generate tokens based on aspects in the chart
    private static func generateAspectTokens(chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
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
                        
                        // Venus-Mars conjunction can indicate style with sensuality
                        if (planet1.name == "Venus" && planet2.name == "Mars") ||
                            (planet1.name == "Mars" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "sensual", type: "expression", weight: aspectWeight,
                                                     planetarySource: "Venus-Mars", aspectSource: aspectSource))
                        }
                        
                        // Sun-Moon conjunction can indicate harmony between conscious and unconscious
                        if (planet1.name == "Sun" && planet2.name == "Moon") ||
                            (planet1.name == "Moon" && planet2.name == "Sun") {
                            tokens.append(StyleToken(name: "integrated", type: "mood", weight: aspectWeight,
                                                     planetarySource: "Sun-Moon", aspectSource: aspectSource))
                        }
                        
                    case "Opposition":
                        // Planets in polarity - balance or tension
                        tokens.append(StyleToken(name: "balanced", type: "structure", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Venus-Mars opposition can indicate style with contrasting elements
                        if (planet1.name == "Venus" && planet2.name == "Mars") ||
                            (planet1.name == "Mars" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "contrasting", type: "expression", weight: aspectWeight,
                                                     planetarySource: "Venus-Mars", aspectSource: aspectSource))
                        }
                        
                    case "Trine":
                        // Planets in harmony - flow and ease
                        tokens.append(StyleToken(name: "flowing", type: "structure", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Venus-Moon trine can indicate style with emotional harmony
                        if (planet1.name == "Venus" && planet2.name == "Moon") ||
                            (planet1.name == "Moon" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "harmonious", type: "mood", weight: aspectWeight,
                                                     planetarySource: "Venus-Moon", aspectSource: aspectSource))
                        }
                        
                    case "Square":
                        // Planets in tension - dynamic energy
                        tokens.append(StyleToken(name: "dynamic", type: "structure", weight: aspectWeight,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                        
                        // Venus-Saturn square can indicate style with structured restraint
                        if (planet1.name == "Venus" && planet2.name == "Saturn") ||
                            (planet1.name == "Saturn" && planet2.name == "Venus") {
                            tokens.append(StyleToken(name: "restrained", type: "expression", weight: aspectWeight,
                                                     planetarySource: "Venus-Saturn", aspectSource: aspectSource))
                        }
                        
                    default:
                        // Minor aspects - subtler influence
                        tokens.append(StyleToken(name: "nuanced", type: "mood", weight: aspectWeight * 0.8,
                                                 planetarySource: "\(planet1.name)-\(planet2.name)", aspectSource: aspectSource))
                    }
                }
            }
        }
        
        return tokens
    }
    
    // MARK: - Public Interface Methods
    
    /// Generates tokens from natal chart, progressed chart, transits, and weather data
    static func generateAllTokens(natal: NatalChartCalculator.NatalChart,
                                  progressed: NatalChartCalculator.NatalChart,
                                  transits: [[String: Any]],
                                  weather: TodayWeather?) -> [StyleToken] {
        
        var allTokens: [StyleToken] = []
        
        // Generate tokens from natal chart
        let natalTokens = generateTokensFromNatalChart(natal)
        allTokens.append(contentsOf: natalTokens)
        
        // Generate tokens from progressed chart
        let progressedTokens = generateTokensFromProgressedChart(progressed)
        allTokens.append(contentsOf: progressedTokens)
        
        // Generate tokens from transits
        let transitTokens = generateTokensFromTransits(transits)
        allTokens.append(contentsOf: transitTokens)
        
        // Generate tokens from weather if available
        if let weather = weather {
            let weatherTokens = generateTokensFromWeather(weather)
            allTokens.append(contentsOf: weatherTokens)
        }
        
        return allTokens
    }
    
    /// Helper to generate tokens for daily vibe (progressed, transits, weather)
    static func generateDailyVibeTokens(progressed: NatalChartCalculator.NatalChart,
                                        transits: [[String: Any]],
                                        weather: TodayWeather?) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate tokens from progressed chart
        let progressedTokens = generateTokensFromProgressedChart(progressed)
        tokens.append(contentsOf: progressedTokens)
        
        // Generate tokens from transits
        let transitTokens = generateTokensFromTransits(transits)
        tokens.append(contentsOf: transitTokens)
        
        // Generate tokens from weather if available
        if let weather = weather {
            let weatherTokens = generateTokensFromWeather(weather)
            tokens.append(contentsOf: weatherTokens)
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
    
    /// Generate tokens from planetary transits (Placidus houses)
    static func generateTransitTokens(
        transits: [[String: Any]],
        natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            for transit in transits {
                let transitPlanet = transit["transitPlanet"] as? String ?? ""
                let natalPlanet = transit["natalPlanet"] as? String ?? ""
                let aspectType = transit["aspectType"] as? String ?? ""
                let orb = transit["orb"] as? Double ?? 5.0
                
                // Calculate weight based on orb and aspect type
                var weight = 2.0
                
                // Adjust weight based on orb (closer orb = higher weight)
                if orb < 1.0 {
                    weight += 0.5 // Very tight aspect
                } else if orb > 3.0 {
                    weight -= 0.5 // Wide aspect
                }
                
                // Adjust weight based on aspect type
                switch aspectType {
                case "Conjunction":
                    weight += 0.5
                case "Opposition":
                    weight += 0.3
                case "Square":
                    weight += 0.2
                case "Trine":
                    weight += 0.1
                default:
                    break // No adjustment for minor aspects
                }
                
                // Craft a transit aspect source description
                let aspectSource = "transit \(transitPlanet) \(aspectType) natal \(natalPlanet)"
                
                // Generate tokens specific to this transit
                switch transitPlanet {
                case "Sun":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "illuminated",
                            type: "mood",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "conscious",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "relational",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "expressive",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "energetic",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Moon":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "emotional",
                            type: "mood",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "responsive",
                            type: "texture",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "reflective",
                            type: "mood",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "processed",
                            type: "texture",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "intuitive",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "changeable",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Mercury":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "communicative",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "detailed",
                            type: "structure",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "interactive",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "conversational",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "expressive",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "articulate",
                            type: "structure",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "quick",
                            type: "pace",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Venus":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "harmonious",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "attractive",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "relational",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "pleasing",
                            type: "texture",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "creative",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "structure",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Mars":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "energetic",
                            type: "mood",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "active",
                            type: "structure",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "forceful",
                            type: "texture",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "assertive",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "edgy",
                            type: "texture",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "bold",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Jupiter":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "expansive",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "optimistic",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "philosophical",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "generous",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "bold",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "exuberant",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Saturn":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "structured",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "disciplined",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "mature",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "stable",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "enduring",
                            type: "texture",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "structured",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "restrained",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Uranus":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "innovative",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "unexpected",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "original",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "expressive",
                            type: "expression",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "progressive",
                            type: "structure",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "disruptive",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "unconventional",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Neptune":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "dreamy",
                            type: "mood",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "fluid",
                            type: "structure",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "ethereal",
                            type: "texture",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "intuitive",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "spiritual",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "diffused",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "sensitive",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                case "Pluto":
                    switch aspectType {
                    case "Conjunction":
                        tokens.append(StyleToken(
                            name: "transformative",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "intense",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Opposition":
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "powerful",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Trine":
                        tokens.append(StyleToken(
                            name: "flowing",
                            type: "structure",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "transformative",
                            type: "expression",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    case "Square":
                        tokens.append(StyleToken(
                            name: "edgy",
                            type: "texture",
                            weight: weight,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                        tokens.append(StyleToken(
                            name: "potent",
                            type: "mood",
                            weight: weight - 0.2,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "subtle",
                            type: "expression",
                            weight: weight - 0.3,
                            planetarySource: transitPlanet,
                            aspectSource: aspectSource
                        ))
                    }
                default:
                    tokens.append(StyleToken(
                        name: "influential",
                        type: "expression",
                        weight: weight - 0.3,
                        planetarySource: transitPlanet,
                        aspectSource: aspectSource
                    ))
                }
            }
            
            return tokens
        }
    
    /// Generate tokens from moon phase
    static func generateMoonPhaseTokens(moonPhase: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Base weight for moon phase tokens
        let baseWeight = 1.5
        
        // Create tokens based on moon phase
        if moonPhase < 45.0 {
            // New Moon
            tokens.append(StyleToken(
                name: "minimal",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "introspective",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "subtle",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
        } else if moonPhase < 90.0 {
            // Waxing Crescent
            tokens.append(StyleToken(
                name: "emerging",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Crescent"
            ))
            tokens.append(StyleToken(
                name: "intentional",
                type: "expression",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Crescent"
            ))
            tokens.append(StyleToken(
                name: "forming",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Crescent"
            ))
        } else if moonPhase < 135.0 {
            // First Quarter
            tokens.append(StyleToken(
                name: "decisive",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "First Quarter"
            ))
            tokens.append(StyleToken(
                name: "active",
                type: "expression",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "First Quarter"
            ))
            tokens.append(StyleToken(
                name: "dynamic",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "First Quarter"
            ))
        } else if moonPhase < 180.0 {
            // Waxing Gibbous
            tokens.append(StyleToken(
                name: "developing",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Gibbous"
            ))
            tokens.append(StyleToken(
                name: "refining",
                type: "expression",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Gibbous"
            ))
            tokens.append(StyleToken(
                name: "detailed",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Gibbous"
            ))
        } else if moonPhase < 225.0 {
            // Full Moon
            tokens.append(StyleToken(
                name: "expressive",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "illuminated",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "vibrant",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
        } else if moonPhase < 270.0 {
            // Waning Gibbous
            tokens.append(StyleToken(
                name: "substantial",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Gibbous"
            ))
            tokens.append(StyleToken(
                name: "sharing",
                type: "expression",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Gibbous"
            ))
            tokens.append(StyleToken(
                name: "fulfilling",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Gibbous"
            ))
        } else if moonPhase < 315.0 {
            // Last Quarter
            tokens.append(StyleToken(
                name: "releasing",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Last Quarter"
            ))
            tokens.append(StyleToken(
                name: "resolving",
                type: "expression",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Last Quarter"
            ))
            tokens.append(StyleToken(
                name: "transitional",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Last Quarter"
            ))
        } else {
            // Waning Crescent
            tokens.append(StyleToken(
                name: "diminishing",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Crescent"
            ))
            tokens.append(StyleToken(
                name: "reflective",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Crescent"
            ))
            tokens.append(StyleToken(
                name: "subtle",
                type: "texture",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Crescent"
            ))
        }
        
        return tokens
    }
    
    /// Generate tokens from weather conditions
    static func generateWeatherTokens(weather: TodayWeather) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Base weight for weather tokens
        let baseWeight = 1.5
        
        // Temperature tokens
        if weather.temp < 10 {
            tokens.append(StyleToken(
                name: "insulating",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cold Weather"
            ))
            tokens.append(StyleToken(
                name: "layered",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cold Weather"
            ))
            tokens.append(StyleToken(
                name: "protective",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cold Weather"
            ))
        } else if weather.temp < 20 {
            tokens.append(StyleToken(
                name: "adaptable",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cool Weather"
            ))
            tokens.append(StyleToken(
                name: "layered",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cool Weather"
            ))
            tokens.append(StyleToken(
                name: "versatile",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cool Weather"
            ))
        } else if weather.temp < 30 {
            tokens.append(StyleToken(
                name: "breathable",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Warm Weather"
            ))
            tokens.append(StyleToken(
                name: "light",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Warm Weather"
            ))
            tokens.append(StyleToken(
                name: "fluid",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Warm Weather"
            ))
        } else {
            tokens.append(StyleToken(
                name: "minimal",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Hot Weather"
            ))
            tokens.append(StyleToken(
                name: "breathable",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Hot Weather"
            ))
            tokens.append(StyleToken(
                name: "light",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Hot Weather"
            ))
        }
        
        // Weather condition tokens
        let conditions = weather.conditions.lowercased()
        
        if conditions.contains("rain") || conditions.contains("shower") {
            tokens.append(StyleToken(
                name: "protective",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Rainy Weather"
            ))
            tokens.append(StyleToken(
                name: "water-resistant",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Rainy Weather"
            ))
            tokens.append(StyleToken(
                name: "adaptable",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Rainy Weather"
            ))
        } else if conditions.contains("snow") {
            tokens.append(StyleToken(
                name: "insulating",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Snowy Weather"
            ))
            tokens.append(StyleToken(
                name: "protective",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Snowy Weather"
            ))
            tokens.append(StyleToken(
                name: "layered",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Snowy Weather"
            ))
        } else if conditions.contains("cloud") {
            tokens.append(StyleToken(
                name: "muted",
                type: "color",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cloudy Weather"
            ))
            tokens.append(StyleToken(
                name: "textured",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cloudy Weather"
            ))
            tokens.append(StyleToken(
                name: "thoughtful",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Cloudy Weather"
            ))
        } else if conditions.contains("sun") || conditions.contains("clear") {
            tokens.append(StyleToken(
                name: "bright",
                type: "color",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Sunny Weather"
            ))
            tokens.append(StyleToken(
                name: "structured",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Sunny Weather"
            ))
            tokens.append(StyleToken(
                name: "defined",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Sunny Weather"
            ))
        } else if conditions.contains("wind") {
            tokens.append(StyleToken(
                name: "anchored",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Windy Weather"
            ))
            tokens.append(StyleToken(
                name: "secured",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Windy Weather"
            ))
            tokens.append(StyleToken(
                name: "dynamic",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Windy Weather"
            ))
        } else if conditions.contains("fog") {
            tokens.append(StyleToken(
                name: "diffused",
                type: "structure",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Foggy Weather"
            ))
            tokens.append(StyleToken(
                name: "layered",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Foggy Weather"
            ))
            tokens.append(StyleToken(
                name: "mysterious",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Foggy Weather"
            ))
        }
        
        // Humidity tokens
        if weather.humidity > 80 {
            tokens.append(StyleToken(
                name: "breathable",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "High Humidity"
            ))
        } else if weather.humidity < 30 {
            tokens.append(StyleToken(
                name: "moisturizing",
                type: "texture",
                weight: baseWeight,
                planetarySource: nil,
                signSource: nil,
                houseSource: nil,
                aspectSource: "Low Humidity"
            ))
        }
        
        return tokens
    }
}
