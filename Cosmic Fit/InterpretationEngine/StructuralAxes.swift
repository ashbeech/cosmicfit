//
//  StructuralAxes.swift
//  Cosmic Fit
//
//  Created for Daily System structural axes implementation
//

import Foundation

/// Handles structural axes calculations for the Daily System format
class StructuralAxes {
    
    // MARK: - Angular vs Curvy Calculation
    
    /// Calculate Angular vs Curvy score based on astrological chart influences
    /// - Parameter tokens: Array of style tokens
    /// - Returns: AngularCurvyScore with rating (1-10, where 1 = fully angular, 10 = fully curvy)
    static func calculateAngularCurvyScore(from tokens: [StyleToken]) -> AngularCurvyScore {
        var score: Double = 5.0 // Start at balanced middle
        
        // Venus aesthetic influence (strongest factor)
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        for token in venusTokens {
            switch token.signSource {
            // Water signs - naturally curvy, flowing
            case "Cancer":
                score += token.weight * 1.2 // Nurturing curves
            case "Scorpio":
                score += token.weight * 0.8 // Powerful curves
            case "Pisces":
                score += token.weight * 1.4 // Fluid, soft curves
                
            // Earth signs - mixed, tends toward structure but with softness
            case "Taurus":
                score += token.weight * 0.6 // Sensual curves
            case "Virgo":
                score -= token.weight * 0.4 // Refined structure
            case "Capricorn":
                score -= token.weight * 0.8 // Strong structure
                
            // Fire signs - angular energy
            case "Aries":
                score -= token.weight * 1.0 // Sharp, direct lines
            case "Leo":
                score -= token.weight * 0.6 // Bold but can be curved
            case "Sagittarius":
                score -= token.weight * 0.8 // Dynamic angles
                
            // Air signs - angular but lighter
            case "Gemini":
                score -= token.weight * 0.7 // Quick, angular movement
            case "Libra":
                score += token.weight * 0.4 // Balanced with soft preference
            case "Aquarius":
                score -= token.weight * 0.9 // Innovative angles
                
            default:
                break
            }
        }
        
        // Mars energy expression influence
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        for token in marsTokens {
            switch token.signSource {
            case "Aries", "Capricorn", "Aquarius":
                score -= token.weight * 0.5 // Angular, direct energy
            case "Cancer", "Pisces":
                score += token.weight * 0.4 // Softer energy expression
            case "Scorpio":
                score += token.weight * 0.3 // Powerful but flowing
            case "Leo":
                score -= token.weight * 0.3 // Bold, defined energy
            default:
                break
            }
        }
        
        // Moon emotional comfort influence
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        for token in moonTokens {
            switch token.signSource {
            case "Cancer", "Pisces", "Taurus":
                score += token.weight * 0.8 // Comfort through curves
            case "Scorpio":
                score += token.weight * 0.5 // Deep curves
            case "Virgo", "Capricorn":
                score -= token.weight * 0.4 // Comfort through structure
            case "Aries", "Gemini":
                score -= token.weight * 0.3 // Dynamic comfort
            default:
                break
            }
        }
        
        // Sun core identity influence
        let sunTokens = tokens.filter { $0.planetarySource == "Sun" }
        for token in sunTokens {
            switch token.signSource {
            case "Leo", "Aries", "Sagittarius":
                score -= token.weight * 0.4 // Bold, angular self-expression
            case "Cancer", "Pisces":
                score += token.weight * 0.5 // Flowing self-expression
            case "Libra":
                score += token.weight * 0.3 // Harmonious, gentle curves
            case "Capricorn", "Aquarius":
                score -= token.weight * 0.5 // Structured self-expression
            default:
                break
            }
        }
        
        // Ascendant physical presentation influence
        let ascendantTokens = tokens.filter { $0.planetarySource == "Ascendant" }
        for token in ascendantTokens {
            switch token.signSource {
            case "Cancer", "Pisces", "Taurus":
                score += token.weight * 0.7 // Natural physical curves
            case "Scorpio":
                score += token.weight * 0.4 // Magnetic curves
            case "Aries", "Capricorn", "Aquarius":
                score -= token.weight * 0.6 // Angular physical presence
            case "Virgo":
                score -= token.weight * 0.4 // Refined, structured presence
            case "Leo":
                score -= token.weight * 0.3 // Bold, defined presence
            case "Libra":
                score += token.weight * 0.2 // Balanced with soft preference
            default:
                break
            }
        }
        
        // Element-based modifiers
        let fireTokens = tokens.filter { $0.type == "structure" && getElementFromToken($0) == "fire" }
        let earthTokens = tokens.filter { $0.type == "structure" && getElementFromToken($0) == "earth" }
        let airTokens = tokens.filter { $0.type == "structure" && getElementFromToken($0) == "air" }
        let waterTokens = tokens.filter { $0.type == "structure" && getElementFromToken($0) == "water" }
        
        for token in fireTokens {
            score -= token.weight * 0.2 // Fire adds angularity
        }
        
        for token in earthTokens {
            score -= token.weight * 0.1 // Earth adds slight structure
        }
        
        for token in airTokens {
            score -= token.weight * 0.15 // Air adds movement angles
        }
        
        for token in waterTokens {
            score += token.weight * 0.25 // Water adds curves
        }
        
        // Aspect pattern influences
        let aspectTokens = tokens.filter { $0.aspectSource != nil }
        for token in aspectTokens {
            if token.aspectSource?.contains("Square") == true {
                score -= 0.2 // Squares create angular tension
            } else if token.aspectSource?.contains("Trine") == true {
                score += 0.2 // Trines create flowing harmony
            } else if token.aspectSource?.contains("Opposition") == true {
                score -= 0.1 // Oppositions create angular dynamics
            } else if token.aspectSource?.contains("Sextile") == true {
                score += 0.1 // Sextiles create gentle flow
            }
        }
        
        // Constrain to 1-10 range
        let finalScore = max(1, min(10, Int(round(score))))
        
        return AngularCurvyScore(score: finalScore)
    }
    
    // MARK: - Helper Methods
    
    /// Extract element information from token
    private static func getElementFromToken(_ token: StyleToken) -> String? {
        guard let signSource = token.signSource else { return nil }
        
        switch signSource {
        case "Aries", "Leo", "Sagittarius":
            return "fire"
        case "Taurus", "Virgo", "Capricorn":
            return "earth"
        case "Gemini", "Libra", "Aquarius":
            return "air"
        case "Cancer", "Scorpio", "Pisces":
            return "water"
        default:
            return nil
        }
    }
}

/// Structure to hold Angular vs Curvy scoring results
struct AngularCurvyScore: Codable {
    let score: Int  // 1-10 where 1 = fully angular, 10 = fully curvy
    
    /// Get user-friendly description
    var description: String {
        switch score {
        case 1...2:
            return "Sharp, angular lines with geometric precision"
        case 3...4:
            return "Mostly angular with some softened edges"
        case 5...6:
            return "Balanced mix of angular and curved elements"
        case 7...8:
            return "Predominantly curved with gentle flowing lines"
        case 9...10:
            return "Fully curved, fluid, and organic shapes"
        default:
            return "Balanced structural elements"
        }
    }
    
    /// Get styling guidance based on score
    var stylingGuidance: String {
        switch score {
        case 1...3:
            return "Embrace structured blazers, sharp tailoring, geometric accessories, and clean architectural lines."
        case 4...6:
            return "Balance structured pieces with softer elements - mix tailored jackets with flowing scarves or curved jewelry."
        case 7...10:
            return "Choose flowing fabrics, draped silhouettes, rounded accessories, and organic shapes that follow natural body curves."
        default:
            return "Blend structured and flowing elements for versatile style expression."
        }
    }
    
    /// Check if angular-dominant
    var isAngular: Bool {
        return score <= 4
    }
    
    /// Check if curvy-dominant  
    var isCurvy: Bool {
        return score >= 7
    }
    
    /// Check if balanced
    var isBalanced: Bool {
        return score >= 5 && score <= 6
    }
}
