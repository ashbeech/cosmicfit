//
//  DerivedAxesEvaluator.swift
//  Cosmic Fit
//
//  Created for Derived Axes System implementation
//

import Foundation

// MARK: - Derived Axes Model

/// Represents the four orthogonal derived axes that describe how style energy manifests
struct DerivedAxes: Codable {
    let action: Double      // 1-10: Movement, drive, direction (driven by Mars/Jupiter/Fire tokens)
    let tempo: Double       // 1-10: Speed, emotional temperature (driven by Lunar phase, aspect density)
    let strategy: Double    // 1-10: Structure, discipline (driven by Saturn/Mercury tokens)
    let visibility: Double  // 1-10: Outward vs inward energy (driven by Sun/MC/Jupiter tokens)
    
    init(action: Double, tempo: Double, strategy: Double, visibility: Double) {
        // Clamp all values to 1-10 range
        self.action = min(max(action, 1.0), 10.0)
        self.tempo = min(max(tempo, 1.0), 10.0)
        self.strategy = min(max(strategy, 1.0), 10.0)
        self.visibility = min(max(visibility, 1.0), 10.0)
    }
    
    /// Get a debug description of the axes
    func debugDescription() -> String {
        return String(format: "Action: %.1f, Tempo: %.1f, Strategy: %.1f, Visibility: %.1f",
                      action, tempo, strategy, visibility)
    }
}

// MARK: - Derived Axes Evaluator

/// Evaluates StyleTokens to generate deterministic derived axes scores
final class DerivedAxesEvaluator {
    
    // MARK: - Main Evaluation Method
    
    /// Evaluate tokens to generate derived axes scores
    /// - Parameter tokens: Array of StyleTokens from SemanticTokenGenerator
    /// - Returns: DerivedAxes with action, tempo, strategy, and visibility scores (1-10 each)
    static func evaluate(tokens: [StyleToken]) -> DerivedAxes {
        
        let action = evaluateActionAxis(tokens: tokens)
        let tempo = evaluateTempoAxis(tokens: tokens)
        let strategy = evaluateStrategyAxis(tokens: tokens)
        let visibility = evaluateVisibilityAxis(tokens: tokens)
        
        if DerivedAxesConfiguration.Debug.logEvaluation {
            print("\n📐 DERIVED AXES EVALUATION")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(String(format: "  Action:     %.1f/10", action))
            print(String(format: "  Tempo:      %.1f/10", tempo))
            print(String(format: "  Strategy:   %.1f/10", strategy))
            print(String(format: "  Visibility: %.1f/10", visibility))
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
        
        return DerivedAxes(action: action, tempo: tempo, strategy: strategy, visibility: visibility)
    }
    
    // MARK: - Individual Axis Evaluation
    
    /// Evaluate Action axis: Movement, drive, direction
    /// Driven by: Mars, Jupiter, Fire element tokens
    /// Evaluate Action axis: Movement, drive, direction
    /// Driven by: Mars, Jupiter, Fire element tokens
    private static func evaluateActionAxis(tokens: [StyleToken]) -> Double {
        var rawScore: Double = 0.0
        
        // Mars tokens - primary driver of action
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        for token in marsTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.strongTokenMultiplier
            rawScore += weight
        }
        
        // Jupiter tokens - expansion and momentum
        let jupiterTokens = tokens.filter { $0.planetarySource == "Jupiter" }
        for token in jupiterTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.moderateTokenMultiplier
            rawScore += weight * 0.7
        }
        
        // Fire element tokens
        let fireTokens = tokens.filter { token in
            guard let signSource = token.signSource else { return false }
            return ["Aries", "Leo", "Sagittarius"].contains(signSource)
        }
        for token in fireTokens {
            rawScore += token.weight * 0.5
        }
        
        // Action-related keywords
        let actionKeywords = ["drive", "motion", "momentum", "direction", "dynamic", "energetic",
                              "bold", "assertive", "active", "decisive", "powerful"]
        let actionTokens = tokens.filter { token in
            actionKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in actionTokens {
            rawScore += token.weight * 0.4
        }
        
        // Normalize: Scale raw score (typically 0-20) to 1-10 range
        // Use a scaling factor that maps typical ranges sensibly
        let scaledScore = 5.0 + (rawScore * 0.5) // Base 5 + scaled contribution
        
        return min(10.0, max(1.0, scaledScore))
    }
    
    /// Evaluate Tempo axis: Speed, emotional temperature
    /// Driven by: Lunar phase, aspect density, Air element
    private static func evaluateTempoAxis(tokens: [StyleToken]) -> Double {
        var rawScore: Double = 0.0
        
        // Moon phase tokens affect tempo
        let moonPhaseTokens = tokens.filter { $0.originType == .phase }
        for token in moonPhaseTokens {
            // New moon = slower tempo (negative), Full moon = faster tempo (positive)
            let multiplier = token.name.lowercased().contains("new") ? -0.6 : 0.6
            rawScore += token.weight * multiplier
        }
        
        // Air element tokens increase tempo
        let airTokens = tokens.filter { token in
            guard let signSource = token.signSource else { return false }
            return ["Gemini", "Libra", "Aquarius"].contains(signSource)
        }
        for token in airTokens {
            rawScore += token.weight * 0.7
        }
        
        // Tempo-related keywords
        let tempoKeywords = ["quick", "fast", "rapid", "swift", "slow", "languid", "measured"]
        let tempoTokens = tokens.filter { token in
            tempoKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in tempoTokens {
            // Fast = positive, slow = negative
            let multiplier = token.name.lowercased().contains("slow") ? -0.5 : 0.5
            rawScore += token.weight * multiplier
        }
        
        // Aspect density (more transit tokens = higher tempo)
        let transitTokens = tokens.filter { $0.originType == .transit }
        let densityBonus = Double(transitTokens.count) * 0.05 // Small bonus for density
        rawScore += densityBonus
        
        // Normalize: Scale raw score (typically -5 to +15) to 1-10 range
        let scaledScore = 5.0 + (rawScore * 0.4) // Base 5 + scaled contribution
        
        return min(10.0, max(1.0, scaledScore))
    }
    
    /// Evaluate Strategy axis: Structure, discipline
    /// Driven by: Saturn, Mercury, Earth element tokens
    private static func evaluateStrategyAxis(tokens: [StyleToken]) -> Double {
        var rawScore: Double = 0.0
        
        // Saturn tokens - primary driver of strategy
        let saturnTokens = tokens.filter { $0.planetarySource == "Saturn" }
        for token in saturnTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.strongTokenMultiplier
            rawScore += weight
        }
        
        // Mercury tokens - planning and precision
        let mercuryTokens = tokens.filter { $0.planetarySource == "Mercury" }
        for token in mercuryTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.moderateTokenMultiplier
            rawScore += weight * 0.8
        }
        
        // Earth element tokens
        let earthTokens = tokens.filter { token in
            guard let signSource = token.signSource else { return false }
            return ["Taurus", "Virgo", "Capricorn"].contains(signSource)
        }
        for token in earthTokens {
            rawScore += token.weight * 0.6
        }
        
        // Strategy-related keywords
        let strategyKeywords = ["structure", "discipline", "control", "precision", "organised",
                               "planned", "methodical", "systematic", "ordered", "strategic",
                               "structured", "disciplined", "grounded", "practical"]
        let strategyTokens = tokens.filter { token in
            strategyKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in strategyTokens {
            rawScore += token.weight * 0.5
        }
        
        // Normalize: Scale raw score (typically 0-20) to 1-10 range
        let scaledScore = 5.0 + (rawScore * 0.5) // Base 5 + scaled contribution
        
        return min(10.0, max(1.0, scaledScore))
    }
    
    /// Evaluate Visibility axis: Outward vs inward energy
    /// Driven by: Sun, MC (Midheaven), Jupiter, Leo energy
    private static func evaluateVisibilityAxis(tokens: [StyleToken]) -> Double {
        var rawScore: Double = 0.0
        
        // Sun tokens - core visibility driver
        let sunTokens = tokens.filter { $0.planetarySource == "Sun" }
        for token in sunTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.strongTokenMultiplier
            rawScore += weight
        }
        
        // Jupiter tokens - expansion and presence
        let jupiterTokens = tokens.filter { $0.planetarySource == "Jupiter" }
        for token in jupiterTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.moderateTokenMultiplier
            rawScore += weight * 0.9
        }
        
        // Leo energy (Sun-ruled sign)
        let leoTokens = tokens.filter { $0.signSource == "Leo" }
        for token in leoTokens {
            rawScore += token.weight * 0.8
        }
        
        // Visibility-related keywords
        let visibilityKeywords = ["visible", "prominent", "bold", "radiant", "luminous", "expressive",
                                 "statement", "attention", "striking", "commanding"]
        let visibilityTokens = tokens.filter { token in
            visibilityKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in visibilityTokens {
            rawScore += token.weight * 0.6
        }
        
        // House 1 and 10 tokens (Ascendant/MC - public visibility)
        let visibilityHouses = tokens.filter { token in
            // Check if token is from house 1 or 10
            if let aspectSource = token.aspectSource {
                return aspectSource.contains("house 1") || aspectSource.contains("house 10")
            }
            return false
        }
        for token in visibilityHouses {
            rawScore += token.weight * 0.7
        }
        
        // Normalize: Scale raw score (typically 0-20) to 1-10 range
        let scaledScore = 5.0 + (rawScore * 0.5) // Base 5 + scaled contribution
        
        return min(10.0, max(1.0, scaledScore))
    }
}
