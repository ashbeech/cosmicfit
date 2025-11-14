//
//  ColourScoring.swift
//  Cosmic Fit
//
//  Created for Daily System colour scoring implementation
//

import Foundation

/// Handles colour scoring algorithms for the Daily System format
class ColourScoring {
    
    // MARK: - Public Colour Scoring Methods
    
    /// Calculate colour scores based on astrological chart influences
    /// - Parameter tokens: Array of style tokens
    /// - Returns: ColourScores with darkness, vibrancy, and contrast ratings (1-10)
    static func calculateColourScores(from tokens: [StyleToken]) -> ColourScores {
        let darkness = calculateDarknessScore(tokens: tokens)
        let vibrancy = calculateVibrancyScore(tokens: tokens)
        let contrast = calculateContrastScore(tokens: tokens)
        
        return ColourScores(
            darkness: max(1, min(10, darkness)),
            vibrancy: max(1, min(10, vibrancy)),
            contrast: max(1, min(10, contrast))
        )
    }
    
    // MARK: - Individual Scoring Algorithms
    
    /// Calculate darkness score (1-10, where 1 = very light, 10 = very dark)
    private static func calculateDarknessScore(tokens: [StyleToken]) -> Int {
        var score: Double = 5.0 // Start at middle
        
        // Venus influences on darkness preference
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        for token in venusTokens {
            switch token.signSource {
            case "Scorpio", "Capricorn":
                score += token.weight * 0.8 // Darker preference
            case "Cancer", "Pisces":
                score += token.weight * 0.5 // Moderately darker
            case "Virgo", "Taurus":
                score += token.weight * 0.2 // Slightly darker
            case "Leo", "Aries", "Sagittarius":
                score -= token.weight * 0.3 // Brighter preference
            case "Gemini", "Libra", "Aquarius":
                score -= token.weight * 0.5 // Lighter preference
            default:
                break
            }
        }
        
        // Mars energy influences
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        for token in marsTokens {
            switch token.signSource {
            case "Scorpio", "Aries":
                score += token.weight * 0.4 // Intense darker
            case "Capricorn":
                score += token.weight * 0.3 // Serious darker
            case "Leo", "Sagittarius":
                score -= token.weight * 0.2 // Bright energy
            default:
                break
            }
        }
        
        // Moon emotional influences
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        for token in moonTokens {
            switch token.signSource {
            case "Scorpio", "Capricorn":
                score += token.weight * 0.6 // Deep emotional preference
            case "Cancer", "Pisces":
                score += token.weight * 0.3 // Soft depth
            case "Leo", "Aries":
                score -= token.weight * 0.4 // Bright emotional expression
            default:
                break
            }
        }
        
        // Sun core identity influences
        let sunTokens = tokens.filter { $0.planetarySource == "Sun" }
        for token in sunTokens {
            switch token.signSource {
            case "Leo", "Aries", "Sagittarius":
                score -= token.weight * 0.3 // Bright self-expression
            case "Scorpio":
                score += token.weight * 0.4 // Intense self-expression
            default:
                break
            }
        }
        
        // Environmental modifiers
        let weatherTokens = tokens.filter { $0.originType == .weather }
        let moonPhaseTokens = tokens.filter { $0.originType == .phase }
        
        for token in weatherTokens {
            if token.name.contains("cloudy") || token.name.contains("overcast") {
                score += 0.5
            } else if token.name.contains("sunny") || token.name.contains("bright") {
                score -= 0.5
            }
        }
        
        for token in moonPhaseTokens {
            if token.aspectSource?.contains("New Moon") == true {
                score += 0.8
            } else if token.aspectSource?.contains("Full Moon") == true {
                score -= 0.6
            }
        }
        
        return Int(round(score))
    }
    
    /// Calculate vibrancy score (1-10, where 1 = muted, 10 = highly saturated)
    private static func calculateVibrancyScore(tokens: [StyleToken]) -> Int {
        var score: Double = 5.0 // Start at middle
        
        // Venus aesthetic preferences
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        for token in venusTokens {
            switch token.signSource {
            case "Leo", "Aries", "Sagittarius":
                score += token.weight * 0.7 // High vibrancy preference
            case "Scorpio", "Taurus":
                score += token.weight * 0.5 // Rich but controlled vibrancy
            case "Pisces", "Cancer":
                score += token.weight * 0.3 // Soft vibrancy
            case "Virgo", "Capricorn":
                score -= token.weight * 0.4 // Muted preference
            case "Libra":
                score -= token.weight * 0.2 // Balanced, not extreme
            case "Gemini", "Aquarius":
                score += token.weight * 0.4 // Interesting but not overwhelming
            default:
                break
            }
        }
        
        // Mars energy expression
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        for token in marsTokens {
            switch token.signSource {
            case "Aries", "Leo", "Sagittarius":
                score += token.weight * 0.6 // Bold, vibrant energy
            case "Scorpio":
                score += token.weight * 0.4 // Intense but controlled
            case "Capricorn", "Virgo":
                score -= token.weight * 0.3 // Controlled, less vibrant
            default:
                break
            }
        }
        
        // Jupiter expansion influences
        let jupiterTokens = tokens.filter { $0.planetarySource == "Jupiter" }
        for token in jupiterTokens {
            score += token.weight * 0.3 // Generally increases vibrancy
        }
        
        // Saturn structure influences
        let saturnTokens = tokens.filter { $0.planetarySource == "Saturn" }
        for token in saturnTokens {
            score -= token.weight * 0.4 // Generally decreases vibrancy for structure
        }
        
        // Environmental modifiers
        let transitTokens = tokens.filter { $0.originType == .transit }
        for token in transitTokens {
            if token.aspectSource?.contains("Jupiter") == true {
                score += 0.3
            } else if token.aspectSource?.contains("Saturn") == true {
                score -= 0.3
            }
        }
        
        return Int(round(score))
    }
    
    /// Calculate contrast score (1-10, where 1 = low contrast/tonal, 10 = high contrast)
    private static func calculateContrastScore(tokens: [StyleToken]) -> Int {
        var score: Double = 5.0 // Start at middle
        
        // Venus harmony vs contrast preferences
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        for token in venusTokens {
            switch token.signSource {
            case "Libra":
                score -= token.weight * 0.6 // Harmony preference, lower contrast
            case "Taurus", "Pisces":
                score -= token.weight * 0.4 // Gentle harmony preference
            case "Leo", "Aries":
                score += token.weight * 0.5 // Bold contrast preference
            case "Scorpio":
                score += token.weight * 0.7 // High drama contrast
            case "Gemini", "Aquarius":
                score += token.weight * 0.3 // Interesting contrasts
            default:
                break
            }
        }
        
        // Mars dynamic energy
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        for token in marsTokens {
            switch token.signSource {
            case "Aries", "Scorpio":
                score += token.weight * 0.6 // High contrast energy
            case "Leo":
                score += token.weight * 0.4 // Bold but harmonious
            case "Cancer", "Pisces":
                score -= token.weight * 0.3 // Softer approach
            default:
                break
            }
        }
        
        // Sun self-expression
        let sunTokens = tokens.filter { $0.planetarySource == "Sun" }
        for token in sunTokens {
            switch token.signSource {
            case "Leo", "Aries":
                score += token.weight * 0.4 // Bold self-expression
            case "Scorpio":
                score += token.weight * 0.5 // Dramatic self-expression
            case "Libra", "Pisces":
                score -= token.weight * 0.4 // Harmonious self-expression
            default:
                break
            }
        }
        
        // Moon emotional comfort
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        for token in moonTokens {
            switch token.signSource {
            case "Cancer", "Taurus", "Pisces":
                score -= token.weight * 0.5 // Comfort through harmony
            case "Scorpio", "Aries":
                score += token.weight * 0.4 // Emotional intensity
            default:
                break
            }
        }
        
        // Aspect patterns influencing contrast
        let aspectTokens = tokens.filter { $0.aspectSource != nil }
        for token in aspectTokens {
            if token.aspectSource?.contains("Square") == true || token.aspectSource?.contains("Opposition") == true {
                score += 0.4 // Dynamic aspects increase contrast
            } else if token.aspectSource?.contains("Trine") == true || token.aspectSource?.contains("Sextile") == true {
                score -= 0.3 // Harmonious aspects decrease contrast
            }
        }
        
        return Int(round(score))
    }
}

/// Structure to hold colour scoring results
struct ColourScores: Codable {
    let darkness: Int      // 1-10 scale
    let vibrancy: Int      // 1-10 scale  
    let contrast: Int      // 1-10 scale
    
    /// Get user-friendly descriptions
    var darknessDescription: String {
        switch darkness {
        case 1...3: return "Light & bright"
        case 4...6: return "Balanced tones"
        case 7...10: return "Rich & deep"
        default: return "Balanced tones"
        }
    }
    
    var vibrancyDescription: String {
        switch vibrancy {
        case 1...3: return "Muted & subtle"
        case 4...6: return "Moderately saturated"
        case 7...10: return "Vibrant & bold"
        default: return "Moderately saturated"
        }
    }
    
    var contrastDescription: String {
        switch contrast {
        case 1...3: return "Tonal & harmonious"
        case 4...6: return "Balanced contrast"
        case 7...10: return "High contrast & dramatic"
        default: return "Balanced contrast"
        }
    }
}
