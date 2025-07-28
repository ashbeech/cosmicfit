//
//  PlanetPowerEvaluator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Evaluates the power/importance of planets for transit weighting

import Foundation

class PlanetPowerEvaluator {
    
    /// Evaluate the power score of a planet for transit sensitivity
    /// - Parameters:
    ///   - planetName: Name of the planet
    ///   - sign: Zodiac sign the planet is in
    ///   - house: House number (1-12)
    ///   - isAngular: Whether the planet is in an angular house (1, 4, 7, 10)
    ///   - isChartRuler: Whether this planet rules the Ascendant
    ///   - isSectLight: Whether this is the sect light (Sun for day charts, Moon for night)
    /// - Returns: Power score (0.0 to 3.0+)
    static func evaluatePower(
        for planetName: String,
        sign: String? = nil,
        house: Int? = nil,
        isAngular: Bool = false,
        isChartRuler: Bool = false,
        isSectLight: Bool = false
    ) -> Double {
        var powerScore: Double = 0.0
        
        // BASE SCORE: Intrinsic planet importance for style/fashion
        switch planetName {
        case "Sun":
            powerScore = 1.5  // Core identity
        case "Moon":
            powerScore = 1.8  // Emotional/instinctive style
        case "Venus":
            powerScore = 2.0  // Primary style/aesthetic planet
        case "Mars":
            powerScore = 1.3  // Energy/cut/approach
        case "Mercury":
            powerScore = 1.0  // Communication through style
        case "Jupiter":
            powerScore = 0.8  // Expansion of style
        case "Saturn":
            powerScore = 0.9  // Structure/discipline in style
        case "Uranus":
            powerScore = 0.7  // Innovation/rebellion in style
        case "Neptune":
            powerScore = 0.6  // Dreams/ideals in style
        case "Pluto":
            powerScore = 0.5  // Transformation through style
        case "Chiron":
            powerScore = 0.4  // Healing through style expression
        case "North Node", "South Node":
            powerScore = 0.3  // Karmic style evolution
        default:
            powerScore = 0.2  // Asteroids or other points
        }
        
        // DIGNITY BONUS: Essential dignity in sign
        if let sign = sign {
            let dignityBonus = calculateDignityBonus(planet: planetName, sign: sign)
            powerScore += dignityBonus
        }
        
        // ANGULAR HOUSE BONUS: Planets in angular houses are more prominent
        if isAngular {
            powerScore += 0.5
            
            // Extra bonus for specific angular houses
            if let house = house {
                switch house {
                case 1:  // Ascendant - maximum visibility
                    powerScore += 0.3
                case 10: // Midheaven - public image
                    powerScore += 0.2
                case 7:  // Descendant - relationships/partnership style
                    powerScore += 0.15
                case 4:  // IC - emotional foundation
                    powerScore += 0.1
                default:
                    break
                }
            }
        }
        
        // SPECIAL ROLE BONUSES
        if isChartRuler {
            powerScore += 0.4  // Chart ruler gets significant boost
        }
        
        if isSectLight {
            powerScore += 0.3  // Sect light (diurnal/nocturnal luminary)
        }
        
        // HOUSE CONTEXT: Some houses are more style-relevant
        if let house = house, !isAngular {
            switch house {
            case 2:  // Values, possessions, personal style
                powerScore += 0.2
            case 5:  // Creative self-expression
                powerScore += 0.15
            case 6:  // Daily life, work style
                powerScore += 0.1
            case 8:  // Transformation, hidden style
                powerScore += 0.1
            case 11: // Social identity, aspirational style
                powerScore += 0.05
            default:
                break
            }
        }
        
        // Ensure minimum base score for any planet
        powerScore = max(powerScore, 0.1)
        
        return powerScore
    }
    
    /// Calculate dignity bonus based on planet's position in sign
    private static func calculateDignityBonus(planet: String, sign: String) -> Double {
        let dignity = getDignityStatus(planet: planet, sign: sign)
        
        switch dignity {
        case .domicile:
            return 0.6  // Planet in own sign
        case .exaltation:
            return 0.5  // Planet exalted
        case .detriment:
            return -0.2 // Planet in detriment
        case .fall:
            return -0.3 // Planet in fall
        case .peregrine:
            return 0.0  // Neutral
        }
    }
    
    /// Determine dignity status of planet in sign
    internal static func getDignityStatus(planet: String, sign: String) -> DignityStatus {
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
    
    /// Check if a planet is targeting a particularly sensitive natal point
    static func isSensitiveTarget(natalPlanet: String) -> Bool {
        let sensitivePlanets = ["Moon", "Venus", "Ascendant", "IC", "Sun", "Mars"]
        return sensitivePlanets.contains(natalPlanet)
    }
    
    /// Get context-specific power multiplier
    static func getContextMultiplier(
        natalPlanet: String,
        transitPlanet: String,
        aspectType: String
    ) -> Double {
        var multiplier: Double = 1.0
        
        // MOON as target: Extra sensitive to emotional transits
        if natalPlanet == "Moon" {
            if ["Venus", "Neptune", "Pluto"].contains(transitPlanet) {
                multiplier += 0.2
            }
        }
        
        // VENUS as target: Extra sensitive to style-affecting transits
        if natalPlanet == "Venus" {
            if ["Mars", "Jupiter", "Saturn", "Uranus"].contains(transitPlanet) {
                multiplier += 0.3
            }
        }
        
        // ASCENDANT as target: Affects immediate presentation
        if natalPlanet == "Ascendant" {
            if ["Sun", "Moon", "Venus", "Mars"].contains(transitPlanet) {
                multiplier += 0.25
            }
        }
        
        // MARS as target: Affects energy and approach
        if natalPlanet == "Mars" {
            if ["Venus", "Saturn", "Uranus", "Pluto"].contains(transitPlanet) {
                multiplier += 0.15
            }
        }
        
        // Special aspect considerations
        if aspectType == "Opposition" && natalPlanet == "Venus" {
            // Venus oppositions create style tensions worth noting
            multiplier += 0.1
        }
        
        return multiplier
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
