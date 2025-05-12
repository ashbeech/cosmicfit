
//
//  SemanticTokenGenerator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 11/05/2025.
//

import Foundation

class SemanticTokenGenerator {
    
    // MARK: - Token Generation from Natal Chart
    
    static func generateTokensFromNatalChart(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets
        for planet in chart.planets {
            // Base weight for natal placements
            let baseWeight: Double = 3.0
            
            // Prioritize fashion-relevant planets
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Venus": priorityMultiplier = 1.5  // Aesthetic preferences
            case "Moon": priorityMultiplier = 1.3   // Emotional comfort
            case "Mars": priorityMultiplier = 1.2   // Energy and cut
            case "Sun": priorityMultiplier = 1.1    // Identity
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            // Get tokens based on planet in sign
            let planetTokens = tokenizeForPlanetInSign(planet: planet.name,
                                                     sign: planet.zodiacSign,
                                                     isRetrograde: planet.isRetrograde,
                                                     weight: weight)
            tokens.append(contentsOf: planetTokens)
        }
        
        // Process rising sign (ascendant)
        let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascendantTokens = tokenizeForAscendant(sign: ascendantSign, weight: 3.0)
        tokens.append(contentsOf: ascendantTokens)
        
        // Process house placements for fashion-relevant planets
        for planet in chart.planets {
            if ["Venus", "Sun", "Moon", "Mars"].contains(planet.name) {
                // Determine house by comparing planet longitude to house cusps
                let house = NatalChartCalculator.determineHouse(longitude: planet.longitude, houseCusps: chart.houseCusps)
                let houseTokens = tokenizeForPlanetInHouse(planet: planet.name, house: house, weight: 2.0)
                tokens.append(contentsOf: houseTokens)
            }
        }
        
        return tokens
    }
    
    // MARK: - Token Generation from Progressed Chart
    
    static func generateTokensFromProgressedChart(_ chart: NatalChartCalculator.NatalChart) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Process planets with progressed weight
        for planet in chart.planets {
            // Base weight for progressed placements
            let baseWeight: Double = 2.5
            
            // Prioritize fashion-relevant planets
            var priorityMultiplier: Double = 1.0
            switch planet.name {
            case "Venus": priorityMultiplier = 1.5
            case "Moon": priorityMultiplier = 1.3
            case "Mars": priorityMultiplier = 1.2
            case "Sun": priorityMultiplier = 1.1
            default: priorityMultiplier = 0.8
            }
            
            let weight = baseWeight * priorityMultiplier
            
            let planetTokens = tokenizeForPlanetInSign(planet: planet.name,
                                                     sign: planet.zodiacSign,
                                                     isRetrograde: planet.isRetrograde,
                                                     weight: weight)
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
                baseWeight = 3.5
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
            
            // Generate tokens based on the transit
            let transitTokens = tokenizeForTransit(transitPlanet: transitPlanet,
                                                 natalPlanet: natalPlanet,
                                                 aspectType: aspectType,
                                                 weight: weight)
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
            tokens.append(StyleToken(name: "cold", type: "weather", weight: baseWeight))
            tokens.append(StyleToken(name: "cozy", type: "texture", weight: baseWeight))
        } else if weather.temp < 20 {
            tokens.append(StyleToken(name: "cool", type: "weather", weight: baseWeight))
            tokens.append(StyleToken(name: "layered", type: "structure", weight: baseWeight))
        } else if weather.temp < 30 {
            tokens.append(StyleToken(name: "warm", type: "weather", weight: baseWeight))
            tokens.append(StyleToken(name: "breathable", type: "texture", weight: baseWeight))
        } else {
            tokens.append(StyleToken(name: "hot", type: "weather", weight: baseWeight))
            tokens.append(StyleToken(name: "light", type: "texture", weight: baseWeight))
        }
        
        // Condition tokens
        switch weather.conditions.lowercased() {
        case let c where c.contains("rain") || c.contains("drizzle") || c.contains("shower"):
            tokens.append(StyleToken(name: "damp", type: "weather", weight: baseWeight))
            tokens.append(StyleToken(name: "protected", type: "structure", weight: baseWeight))
        case let c where c.contains("cloud"):
            tokens.append(StyleToken(name: "muted", type: "color", weight: baseWeight))
            tokens.append(StyleToken(name: "subdued", type: "mood", weight: baseWeight))
        case let c where c.contains("snow") || c.contains("ice"):
            tokens.append(StyleToken(name: "crisp", type: "texture", weight: baseWeight))
            tokens.append(StyleToken(name: "insulated", type: "structure", weight: baseWeight))
        case let c where c.contains("fog"):
            tokens.append(StyleToken(name: "diffused", type: "texture", weight: baseWeight))
            tokens.append(StyleToken(name: "soft", type: "edges", weight: baseWeight))
        case let c where c.contains("sun") || c.contains("clear"):
            tokens.append(StyleToken(name: "bright", type: "color", weight: baseWeight))
            tokens.append(StyleToken(name: "vibrant", type: "mood", weight: baseWeight))
        case let c where c.contains("wind"):
            tokens.append(StyleToken(name: "anchored", type: "structure", weight: baseWeight))
            tokens.append(StyleToken(name: "secure", type: "fabric", weight: baseWeight))
        default:
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: baseWeight))
        }
        
        // Humidity tokens
        if weather.humidity > 80 {
            tokens.append(StyleToken(name: "moisture-wicking", type: "fabric", weight: baseWeight))
        } else if weather.humidity < 30 {
            tokens.append(StyleToken(name: "hydrating", type: "texture", weight: baseWeight))
        }
        
        return tokens
    }
    
    // MARK: - Helper Methods for Token Generation
    
    private static func tokenizeForPlanetInSign(planet: String, sign: Int, isRetrograde: Bool, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Get zodiac sign name
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        
        // Generate tokens based on planet and sign
        switch planet {
        case "Sun":
            switch signName {
            case "Aries":
                tokens.append(StyleToken(name: "bold", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "dynamic", type: "structure", weight: weight))
            case "Taurus":
                tokens.append(StyleToken(name: "sensual", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "earthy", type: "color", weight: weight))
            case "Gemini":
                tokens.append(StyleToken(name: "playful", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight))
            case "Cancer":
                tokens.append(StyleToken(name: "protective", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "comfortable", type: "texture", weight: weight))
            case "Leo":
                tokens.append(StyleToken(name: "radiant", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight))
            case "Virgo":
                tokens.append(StyleToken(name: "refined", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "practical", type: "structure", weight: weight))
            case "Libra":
                tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "harmonious", type: "color", weight: weight))
            case "Scorpio":
                tokens.append(StyleToken(name: "intense", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "transformative", type: "texture", weight: weight))
            case "Sagittarius":
                tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "adventurous", type: "mood", weight: weight))
            case "Capricorn":
                tokens.append(StyleToken(name: "structured", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight))
            case "Aquarius":
                tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "distinctive", type: "mood", weight: weight))
            case "Pisces":
                tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "dreamy", type: "mood", weight: weight))
            default:
                break
            }
            
        case "Moon":
            switch signName {
            case "Aries":
                tokens.append(StyleToken(name: "energetic", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "impulsive", type: "texture", weight: weight))
            case "Taurus":
                tokens.append(StyleToken(name: "comforting", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "stable", type: "mood", weight: weight))
            case "Gemini":
                tokens.append(StyleToken(name: "adaptable", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "communicative", type: "mood", weight: weight))
            case "Cancer":
                tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "emotional", type: "mood", weight: weight))
            case "Leo":
                tokens.append(StyleToken(name: "warm", type: "color", weight: weight))
                tokens.append(StyleToken(name: "dramatic", type: "structure", weight: weight))
            case "Virgo":
                tokens.append(StyleToken(name: "detailed", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "thoughtful", type: "mood", weight: weight))
            case "Libra":
                tokens.append(StyleToken(name: "elegant", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "social", type: "mood", weight: weight))
            case "Scorpio":
                tokens.append(StyleToken(name: "deep", type: "color", weight: weight))
                tokens.append(StyleToken(name: "emotional", type: "texture", weight: weight))
            case "Sagittarius":
                tokens.append(StyleToken(name: "optimistic", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "free-spirited", type: "structure", weight: weight))
            case "Capricorn":
                tokens.append(StyleToken(name: "grounded", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "reserved", type: "structure", weight: weight))
            case "Aquarius":
                tokens.append(StyleToken(name: "unique", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "independent", type: "mood", weight: weight))
            case "Pisces":
                tokens.append(StyleToken(name: "soft", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "intuitive", type: "mood", weight: weight))
            default:
                break
            }
            
        case "Venus":
            switch signName {
            case "Aries":
                tokens.append(StyleToken(name: "spontaneous", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "bold", type: "color", weight: weight))
            case "Taurus":
                tokens.append(StyleToken(name: "luxurious", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "sensual", type: "mood", weight: weight))
            case "Gemini":
                tokens.append(StyleToken(name: "eclectic", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "playful", type: "color", weight: weight))
            case "Cancer":
                tokens.append(StyleToken(name: "nostalgic", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight))
            case "Leo":
                tokens.append(StyleToken(name: "glamorous", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "vibrant", type: "color", weight: weight))
            case "Virgo":
                tokens.append(StyleToken(name: "subtle", type: "color", weight: weight))
                tokens.append(StyleToken(name: "refined", type: "structure", weight: weight))
            case "Libra":
                tokens.append(StyleToken(name: "harmonious", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "balanced", type: "color", weight: weight))
            case "Scorpio":
                tokens.append(StyleToken(name: "magnetic", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight))
            case "Sagittarius":
                tokens.append(StyleToken(name: "exuberant", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "expansive", type: "color", weight: weight))
            case "Capricorn":
                tokens.append(StyleToken(name: "elegant", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "classic", type: "texture", weight: weight))
            case "Aquarius":
                tokens.append(StyleToken(name: "unconventional", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "futuristic", type: "texture", weight: weight))
            case "Pisces":
                tokens.append(StyleToken(name: "romantic", type: "mood", weight: weight))
                tokens.append(StyleToken(name: "dreamy", type: "texture", weight: weight))
            default:
                break
            }
            
        case "Mars":
            switch signName {
            case "Aries":
                tokens.append(StyleToken(name: "assertive", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "energetic", type: "texture", weight: weight))
            case "Taurus":
                tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "substantial", type: "structure", weight: weight))
            case "Gemini":
                tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "quick", type: "texture", weight: weight))
            case "Cancer":
                tokens.append(StyleToken(name: "protective", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "nurturing", type: "texture", weight: weight))
            case "Leo":
                tokens.append(StyleToken(name: "confident", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "bold", type: "color", weight: weight))
            case "Virgo":
                tokens.append(StyleToken(name: "precise", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "detailed", type: "texture", weight: weight))
            case "Libra":
                tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "harmonious", type: "mood", weight: weight))
            case "Scorpio":
                tokens.append(StyleToken(name: "intense", type: "color", weight: weight))
                tokens.append(StyleToken(name: "powerful", type: "structure", weight: weight))
            case "Sagittarius":
                tokens.append(StyleToken(name: "adventurous", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "expansive", type: "texture", weight: weight))
            case "Capricorn":
                tokens.append(StyleToken(name: "disciplined", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "enduring", type: "texture", weight: weight))
            case "Aquarius":
                tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight))
                tokens.append(StyleToken(name: "progressive", type: "mood", weight: weight))
            case "Pisces":
                tokens.append(StyleToken(name: "fluid", type: "texture", weight: weight))
                tokens.append(StyleToken(name: "adaptive", type: "structure", weight: weight))
            default:
                break
            }
            
        default:
            // For other planets, less fashion-relevant tokens
            switch signName {
            case "Aries", "Leo", "Sagittarius":
                tokens.append(StyleToken(name: "fiery", type: "mood", weight: weight * 0.5))
                
            case "Taurus", "Virgo", "Capricorn":
                tokens.append(StyleToken(name: "earthy", type: "mood", weight: weight * 0.5))
                
            case "Gemini", "Libra", "Aquarius":
                tokens.append(StyleToken(name: "airy", type: "mood", weight: weight * 0.5))
                
            case "Cancer", "Scorpio", "Pisces":
                tokens.append(StyleToken(name: "watery", type: "mood", weight: weight * 0.5))
                
            default:
                break
            }
        }
        
        // Add retrograde tokens if applicable
        if isRetrograde {
            tokens.append(StyleToken(name: "reflective", type: "mood", weight: weight * 0.7))
            tokens.append(StyleToken(name: "introspective", type: "structure", weight: weight * 0.7))
        }
        
        return tokens
    }
    
    private static func tokenizeForAscendant(sign: Int, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Get zodiac sign name
        let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
        
        // Generate tokens based on rising sign
        switch signName {
        case "Aries":
            tokens.append(StyleToken(name: "bold", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "direct", type: "structure", weight: weight))
        case "Taurus":
            tokens.append(StyleToken(name: "stable", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "sensual", type: "texture", weight: weight))
        case "Gemini":
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "communicative", type: "expression", weight: weight))
        case "Cancer":
            tokens.append(StyleToken(name: "protective", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "nurturing", type: "expression", weight: weight))
        case "Leo":
            tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "radiant", type: "expression", weight: weight))
        case "Virgo":
            tokens.append(StyleToken(name: "precise", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "refined", type: "texture", weight: weight))
        case "Libra":
            tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "harmonious", type: "expression", weight: weight))
        case "Scorpio":
            tokens.append(StyleToken(name: "intense", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight))
        case "Sagittarius":
            tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "adventurous", type: "expression", weight: weight))
        case "Capricorn":
            tokens.append(StyleToken(name: "structured", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "disciplined", type: "expression", weight: weight))
        case "Aquarius":
            tokens.append(StyleToken(name: "innovative", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "unique", type: "expression", weight: weight))
        case "Pisces":
            tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "intuitive", type: "expression", weight: weight))
        default:
            break
        }
        
        return tokens
    }
    
    private static func tokenizeForPlanetInHouse(planet: String, house: Int, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Different house meanings
        switch house {
        case 1: // 1st house - Self, appearance
            tokens.append(StyleToken(name: "visible", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "defining", type: "structure", weight: weight))
            
        case 2: // 2nd house - Values, possessions
            tokens.append(StyleToken(name: "tactile", type: "texture", weight: weight))
            tokens.append(StyleToken(name: "substantial", type: "structure", weight: weight))
            
        case 3: // 3rd house - Communication, local environment
            tokens.append(StyleToken(name: "communicative", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "adaptable", type: "structure", weight: weight))
            
        case 4: // 4th house - Home, roots, security
            tokens.append(StyleToken(name: "comforting", type: "texture", weight: weight))
            tokens.append(StyleToken(name: "grounded", type: "structure", weight: weight))
            
        case 5: // 5th house - Creativity, pleasure
            tokens.append(StyleToken(name: "playful", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "expressive", type: "structure", weight: weight))
            
        case 6: // 6th house - Work, health, service
            tokens.append(StyleToken(name: "practical", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "functional", type: "texture", weight: weight))
            
        case 7: // 7th house - Partnerships, relationships
            tokens.append(StyleToken(name: "balanced", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "harmonious", type: "expression", weight: weight))
            
        case 8: // 8th house - Transformation, shared resources
            tokens.append(StyleToken(name: "intense", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "transformative", type: "structure", weight: weight))
            
        case 9: // 9th house - Philosophy, travel, higher learning
            tokens.append(StyleToken(name: "expansive", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "cultural", type: "expression", weight: weight))
            
        case 10: // 10th house - Career, public image
            tokens.append(StyleToken(name: "authoritative", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "polished", type: "texture", weight: weight))
            
        case 11: // 11th house - Friends, groups, aspirations
            tokens.append(StyleToken(name: "unconventional", type: "structure", weight: weight))
            tokens.append(StyleToken(name: "innovative", type: "expression", weight: weight))
            
        case 12: // 12th house - Spirituality, unconscious
            tokens.append(StyleToken(name: "mystical", type: "expression", weight: weight))
            tokens.append(StyleToken(name: "fluid", type: "structure", weight: weight))
            
        default:
            break
        }
        
        return tokens
    }
    
    private static func tokenizeForTransit(transitPlanet: String, natalPlanet: String, aspectType: String, weight: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Major transits to fashion-relevant planets
        if ["Venus", "Moon", "Sun", "Mars"].contains(natalPlanet) {
            switch aspectType {
            case "Conjunction":
                tokens.append(StyleToken(name: "intensified", type: "mood", weight: weight))
                if transitPlanet == "Moon" {
                    tokens.append(StyleToken(name: "emotional", type: "texture", weight: weight))
                } else if transitPlanet == "Venus" {
                    tokens.append(StyleToken(name: "harmonious", type: "color", weight: weight))
                } else if transitPlanet == "Mars" {
                    tokens.append(StyleToken(name: "energetic", type: "structure", weight: weight))
                }
                
            case "Opposition":
                tokens.append(StyleToken(name: "contrasting", type: "structure", weight: weight))
                if transitPlanet == "Moon" {
                    tokens.append(StyleToken(name: "reflective", type: "mood", weight: weight))
                } else if transitPlanet == "Venus" {
                    tokens.append(StyleToken(name: "balanced", type: "color", weight: weight))
                } else if transitPlanet == "Mars" {
                    tokens.append(StyleToken(name: "dynamic", type: "texture", weight: weight))
                }
                
            case "Trine":
                tokens.append(StyleToken(name: "flowing", type: "structure", weight: weight))
                if transitPlanet == "Moon" {
                    tokens.append(StyleToken(name: "intuitive", type: "mood", weight: weight))
                } else if transitPlanet == "Venus" {
                    tokens.append(StyleToken(name: "attractive", type: "texture", weight: weight))
                } else if transitPlanet == "Mars" {
                    tokens.append(StyleToken(name: "confident", type: "mood", weight: weight))
                }
                
            case "Square":
                tokens.append(StyleToken(name: "structured", type: "structure", weight: weight))
                if transitPlanet == "Moon" {
                    tokens.append(StyleToken(name: "challenging", type: "texture", weight: weight))
                } else if transitPlanet == "Venus" {
                    tokens.append(StyleToken(name: "creative", type: "color", weight: weight))
                } else if transitPlanet == "Mars" {
                    tokens.append(StyleToken(name: "bold", type: "structure", weight: weight))
                }
                
            case "Sextile":
                tokens.append(StyleToken(name: "harmonious", type: "structure", weight: weight))
                if transitPlanet == "Moon" {
                    tokens.append(StyleToken(name: "supportive", type: "mood", weight: weight))
                } else if transitPlanet == "Venus" {
                    tokens.append(StyleToken(name: "pleasant", type: "texture", weight: weight))
                } else if transitPlanet == "Mars" {
                    tokens.append(StyleToken(name: "active", type: "mood", weight: weight))
                }
                
            default:
                // For minor aspects, add less specific tokens
                if transitPlanet == "Moon" {
                    tokens.append(StyleToken(name: "subtle", type: "texture", weight: weight * 0.7))
                } else if transitPlanet == "Venus" {
                    tokens.append(StyleToken(name: "nuanced", type: "color", weight: weight * 0.7))
                } else if transitPlanet == "Mars" {
                    tokens.append(StyleToken(name: "gentle", type: "structure", weight: weight * 0.7))
                }
            }
        } else {
            // For transits to less fashion-relevant planets, add more general tokens
            if ["Conjunction", "Opposition", "Trine", "Square", "Sextile"].contains(aspectType) {
                tokens.append(StyleToken(name: "shifting", type: "mood", weight: weight * 0.6))
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
    
    /// Helper to generate tokens for blueprint (natal chart only)
    static func generateBlueprintTokens(natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
        return generateTokensFromNatalChart(natal)
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
}
