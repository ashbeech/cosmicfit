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
    private static func evaluateActionAxis(tokens: [StyleToken]) -> Double {
        var score: Double = 5.0 // Start at midpoint
        
        // Mars tokens - primary driver of action
        let marsTokens = tokens.filter { $0.planetarySource == "Mars" }
        for token in marsTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.strongTokenMultiplier
            score += weight
        }
        
        // Jupiter tokens - expansion and momentum
        let jupiterTokens = tokens.filter { $0.planetarySource == "Jupiter" }
        for token in jupiterTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.moderateTokenMultiplier
            score += weight * 0.7
        }
        
        // Fire element tokens
        let fireTokens = tokens.filter { token in
            guard let signSource = token.signSource else { return false }
            return ["Aries", "Leo", "Sagittarius"].contains(signSource)
        }
        for token in fireTokens {
            score += token.weight * 0.5
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
            score += token.weight * 0.4
        }
        
        return min(10.0, max(1.0, score))
    }
    
    /// Evaluate Tempo axis: Speed, emotional temperature
    /// Driven by: Lunar phase, aspect density, Air element
    private static func evaluateTempoAxis(tokens: [StyleToken]) -> Double {
        var score: Double = 5.0 // Start at midpoint
        
        // Moon phase tokens affect tempo
        let moonPhaseTokens = tokens.filter { $0.originType == .phase }
        for token in moonPhaseTokens {
            // Full Moon increases tempo, New Moon decreases it
            if token.aspectSource?.localizedCaseInsensitiveContains("Full Moon") == true {
                score += token.weight * 1.2
            } else if token.aspectSource?.localizedCaseInsensitiveContains("New Moon") == true {
                score -= token.weight * 0.8
            }
        }
        
        // Air element tokens increase tempo
        let airTokens = tokens.filter { token in
            guard let signSource = token.signSource else { return false }
            return ["Gemini", "Libra", "Aquarius"].contains(signSource)
        }
        for token in airTokens {
            score += token.weight * 0.8
        }
        
        // Aspect density - more aspects = higher tempo
        let aspectTokens = tokens.filter { $0.aspectSource != nil }
        let aspectDensity = Double(aspectTokens.count) / max(1.0, Double(tokens.count))
        score += aspectDensity * 3.0
        
        // Tempo-related keywords
        let tempoKeywords = ["speed", "quick", "fast", "slow", "pace", "flow", "intensity",
                            "rapid", "swift", "hurried", "leisurely", "rushed"]
        let tempoTokens = tokens.filter { token in
            tempoKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in tempoTokens {
            // Fast words increase tempo, slow words decrease it
            let slowWords = ["slow", "leisurely", "calm"]
            let multiplier = slowWords.contains { token.name.localizedCaseInsensitiveContains($0) } ? -0.6 : 0.6
            score += token.weight * multiplier
        }
        
        return min(10.0, max(1.0, score))
    }
    
    /// Evaluate Strategy axis: Structure, discipline
    /// Driven by: Saturn, Mercury, Earth element tokens
    private static func evaluateStrategyAxis(tokens: [StyleToken]) -> Double {
        var score: Double = 5.0 // Start at midpoint
        
        // Saturn tokens - primary driver of strategy
        let saturnTokens = tokens.filter { $0.planetarySource == "Saturn" }
        for token in saturnTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.strongTokenMultiplier
            score += weight
        }
        
        // Mercury tokens - planning and precision
        let mercuryTokens = tokens.filter { $0.planetarySource == "Mercury" }
        for token in mercuryTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.moderateTokenMultiplier
            score += weight * 0.8
        }
        
        // Earth element tokens
        let earthTokens = tokens.filter { token in
            guard let signSource = token.signSource else { return false }
            return ["Taurus", "Virgo", "Capricorn"].contains(signSource)
        }
        for token in earthTokens {
            score += token.weight * 0.6
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
            score += token.weight * 0.5
        }
        
        return min(10.0, max(1.0, score))
    }
    
    /// Evaluate Visibility axis: Outward vs inward energy
    /// Driven by: Sun, MC (Midheaven), Jupiter, Leo energy
    private static func evaluateVisibilityAxis(tokens: [StyleToken]) -> Double {
        var score: Double = 5.0 // Start at midpoint
        
        // Sun tokens - core visibility driver
        let sunTokens = tokens.filter { $0.planetarySource == "Sun" }
        for token in sunTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.strongTokenMultiplier
            score += weight
        }
        
        // Jupiter tokens - expansion and presence
        let jupiterTokens = tokens.filter { $0.planetarySource == "Jupiter" }
        for token in jupiterTokens {
            let weight = token.weight * DerivedAxesConfiguration.Evaluation.moderateTokenMultiplier
            score += weight * 0.9
        }
        
        // Leo energy (Sun-ruled sign)
        let leoTokens = tokens.filter { $0.signSource == "Leo" }
        for token in leoTokens {
            score += token.weight * 0.7
        }
        
        // MC (Midheaven) tokens if present
        let mcTokens = tokens.filter { token in
            token.aspectSource?.localizedCaseInsensitiveContains("MC") == true ||
            token.aspectSource?.localizedCaseInsensitiveContains("Midheaven") == true
        }
        for token in mcTokens {
            score += token.weight * 1.0
        }
        
        // Visibility-related keywords
        let visibilityKeywords = ["presence", "exposure", "confidence", "bold", "visible",
                                 "prominent", "standout", "noticeable", "dramatic", "striking",
                                 "radiant", "magnetic", "commanding"]
        let visibilityTokens = tokens.filter { token in
            visibilityKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in visibilityTokens {
            score += token.weight * 0.5
        }
        
        // Introversion keywords decrease visibility
        let introversionKeywords = ["subtle", "quiet", "reserved", "understated", "muted", "private"]
        let introversionTokens = tokens.filter { token in
            introversionKeywords.contains { keyword in
                token.name.localizedCaseInsensitiveContains(keyword)
            }
        }
        for token in introversionTokens {
            score -= token.weight * 0.4
        }
        
        return min(10.0, max(1.0, score))
    }
}
