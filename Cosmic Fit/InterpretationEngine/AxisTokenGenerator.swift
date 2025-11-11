//
//  AxisTokenGenerator.swift
//  Cosmic Fit
//
//  Created for Phase 1: Axis Token Source Implementation (v1.1)
//  Generates axis tokens from raw astrological features (NOT from semantic tokens)
//

import Foundation

/// Generates axis tokens that represent kinetic dimensions of daily energy
final class AxisTokenGenerator {
    
    // MARK: - Persistence
    
    /// UserDefaults key for storing last axis share for hysteresis
    private static let lastAxisShareKey = "CosmicFit.AxisTokenGenerator.lastAxisShare"
    
    /// Get last axis share from persistence, or default if first run
    private static func getLastAxisShare() -> Double {
        let stored = UserDefaults.standard.double(forKey: lastAxisShareKey)
        return stored > 0 ? stored : EngineConfig.axisShareDefault
    }
    
    /// Save axis share for next run's hysteresis
    private static func saveAxisShare(_ share: Double) {
        UserDefaults.standard.set(share, forKey: lastAxisShareKey)
    }
    
    // MARK: - Axis Vocabulary
    
    /// Minimal, focused vocabulary for each axis
    private struct AxisVocabulary {
        // Action axis (1-10: passive → active)
        static let action = [
            "kinetic",        // High action
            "momentum",       // High action
            "drive",          // High action
            "anchored",       // Low action
            "grounded",       // Low action
            "steady"          // Low action
        ]
        
        // Tempo axis (1-10: slow → fast)
        static let tempo = [
            "rapid",          // High tempo
            "quick",          // High tempo
            "pulsing",        // High tempo
            "measured",       // Low tempo
            "deliberate",     // Low tempo
            "sustained"       // Low tempo
        ]
        
        // Strategy axis (1-10: fluid → structured)
        static let strategy = [
            "structured",     // High strategy
            "precise",        // High strategy
            "organized",      // High strategy
            "flowing",        // Low strategy
            "fluid",          // Low strategy
            "adaptive"        // Low strategy
        ]
        
        // Visibility axis (1-10: subtle → prominent)
        static let visibility = [
            "prominent",      // High visibility
            "visible",        // High visibility
            "expressive",     // High visibility
            "understated",    // Low visibility
            "subtle",         // Low visibility
            "refined"         // Low visibility
        ]
    }
    
    // MARK: - Token Generation
    
    /// Generate axis tokens from raw astrological features
    /// - Parameters:
    ///   - features: Raw astrological features
    ///   - existingTokenWeight: Total weight of existing tokens (for gap calculation)
    ///   - targetAxisShare: Desired axis token share (will be adjusted based on gap)
    /// - Returns: Array of StyleTokens representing axis dimensions
    static func generateAxisTokens(
        from features: AstroFeatures,
        existingTokenWeight: Double,
        targetAxisShare: Double = EngineConfig.axisShareDefault
    ) -> [StyleToken] {
        
        // Calculate axes from features (NOT from tokens)
        let axes = calculateAxesFromFeatures(features)
        
        // Calculate semantic gap (how much the existing tokens miss the kinetic signal)
        let semanticGap = calculateSemanticGap(axes: axes, features: features)
        
        // Adjust axis weight based on gap (5-25%)
        let adjustedAxisShare = calculateGapDrivenWeight(
            baseShare: targetAxisShare,
            semanticGap: semanticGap
        )
        
        // Calculate target weight for axis tokens
        let targetAxisWeight = existingTokenWeight * adjustedAxisShare / (1.0 - adjustedAxisShare)
        
        // Generate tokens for each axis
        var tokens: [StyleToken] = []
        
        // Distribute weight across axes (equal distribution)
        let weightPerAxis = targetAxisWeight / 4.0
        
        // Action axis tokens
        tokens.append(contentsOf: generateActionTokens(
            axisValue: axes.action,
            weight: weightPerAxis
        ))
        
        // Tempo axis tokens
        tokens.append(contentsOf: generateTempoTokens(
            axisValue: axes.tempo,
            weight: weightPerAxis
        ))
        
        // Strategy axis tokens
        tokens.append(contentsOf: generateStrategyTokens(
            axisValue: axes.strategy,
            weight: weightPerAxis
        ))
        
        // Visibility axis tokens
        tokens.append(contentsOf: generateVisibilityTokens(
            axisValue: axes.visibility,
            weight: weightPerAxis
        ))
        
        // Debug logging
        if EngineConfig.enableAxisDebug {
            print("\n🎯 AXIS TOKEN GENERATION")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("  Axes: Action=\(String(format: "%.1f", axes.action)), Tempo=\(String(format: "%.1f", axes.tempo)), Strategy=\(String(format: "%.1f", axes.strategy)), Visibility=\(String(format: "%.1f", axes.visibility))")
            print("  Semantic Gap: \(String(format: "%.3f", semanticGap))")
            print("  Adjusted Axis Share: \(String(format: "%.1f%%", adjustedAxisShare * 100))")
            print("  Generated \(tokens.count) axis tokens")
            print("  Total axis weight: \(String(format: "%.2f", tokens.reduce(0) { $0 + $1.weight }))")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
        
        return tokens
    }
    
    // MARK: - Axis Calculation from Features
    
    /// Calculate derived axes from raw features (NOT tokens)
    private static func calculateAxesFromFeatures(_ features: AstroFeatures) -> DerivedAxes {
        // Action: driven by angular momentum and transit count
        let actionScore = calculateActionFromFeatures(features)
        
        // Tempo: driven by lunar phase and aspect density
        let tempoScore = calculateTempoFromFeatures(features)
        
        // Strategy: driven by structural tension
        let strategyScore = calculateStrategyFromFeatures(features)
        
        // Visibility: driven by visibility index
        let visibilityScore = calculateVisibilityFromFeatures(features)
        
        return DerivedAxes(
            action: actionScore,
            tempo: tempoScore,
            strategy: strategyScore,
            visibility: visibilityScore
        )
    }
    
    /// Add controlled daily variation to axes based on daily seed
    /// Creates deterministic but varying daily offsets for meaningful variation
    /// - Parameters:
    ///   - axes: Original derived axes
    ///   - seed: Daily seed for deterministic variation
    /// - Returns: Derived axes with daily variation applied
    static func addDailyVariation(to axes: DerivedAxes, seed: Int) -> DerivedAxes {
        // Generate deterministic but varying daily offsets using sine waves
        // Different frequencies for each axis create independent variation patterns
        let seedDouble = Double(seed)
        
        let actionOffset = sin(seedDouble * 0.0731) * 1.2  // ±1.2 point swing
        let tempoOffset = sin(seedDouble * 0.1047) * 1.5   // ±1.5 point swing
        let strategyOffset = sin(seedDouble * 0.0613) * 1.0 // ±1.0 point swing
        let visibilityOffset = sin(seedDouble * 0.0891) * 1.3 // ±1.3 point swing
        
        return DerivedAxes(
            action: clamp(axes.action + actionOffset, min: 1.0, max: 10.0),
            tempo: clamp(axes.tempo + tempoOffset, min: 1.0, max: 10.0),
            strategy: clamp(axes.strategy + strategyOffset, min: 1.0, max: 10.0),
            visibility: clamp(axes.visibility + visibilityOffset, min: 1.0, max: 10.0)
        )
    }
    
    /// Clamp value to min-max range
    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }
    
    /// Calculate action axis from features
    private static func calculateActionFromFeatures(_ features: AstroFeatures) -> Double {
        // High angular momentum + many transits = high action
        let momentumComponent = features.totalAngularMomentum * EngineConfig.angularMomentumScale
        let transitComponent = Double(features.transitAspects.count) * EngineConfig.transitContributionToAction
        
        let raw = momentumComponent + transitComponent
        return min(10.0, max(1.0, raw))
    }
    
    /// Calculate tempo axis from features
    private static func calculateTempoFromFeatures(_ features: AstroFeatures) -> Double {
        // Lunar phase affects tempo (new moon = low, full moon = high)
        let lunarComponent = (features.lunarPhase * 9.0) + 1.0  // Map 0-1 to 1-10
        
        // Aspect density (more aspects = higher tempo)
        let totalAspects = features.transitAspects.count + features.progressedAspects.count
        let densityComponent = Double(totalAspects) * EngineConfig.aspectDensityWeight
        
        let raw = (lunarComponent + densityComponent) / 2.0
        return min(10.0, max(1.0, raw))
    }
    
    /// Calculate strategy axis from features
    private static func calculateStrategyFromFeatures(_ features: AstroFeatures) -> Double {
        // Structural tension maps to strategy (high tension = high structure needed)
        let tensionComponent = (features.structuralTension * 9.0) + 1.0  // Map 0-1 to 1-10
        
        return min(10.0, max(1.0, tensionComponent))
    }
    
    /// Calculate visibility axis from features
    private static func calculateVisibilityFromFeatures(_ features: AstroFeatures) -> Double {
        // Visibility index directly maps to axis
        let visibilityComponent = (features.visibilityIndex * 9.0) + 1.0  // Map 0-1 to 1-10
        
        return min(10.0, max(1.0, visibilityComponent))
    }
    
    // MARK: - Semantic Gap Calculation
    
    /// Calculate how much existing tokens miss the kinetic signal
    /// Returns 0-1 where higher = larger gap = more correction needed
    private static func calculateSemanticGap(axes: DerivedAxes, features: AstroFeatures) -> Double {
        // If axes are extreme (far from neutral 5.5), there's likely a gap
        let actionGap = abs(axes.action - 5.5) / 4.5  // 0-1
        let tempoGap = abs(axes.tempo - 5.5) / 4.5
        let strategyGap = abs(axes.strategy - 5.5) / 4.5
        let visibilityGap = abs(axes.visibility - 5.5) / 4.5
        
        // Average gap across all axes
        let averageGap = (actionGap + tempoGap + strategyGap + visibilityGap) / 4.0
        
        return averageGap
    }
    
    /// Calculate gap-driven weight adjustment with hysteresis smoothing
    /// - Parameters:
    ///   - baseShare: Base target share (e.g., 0.15 = 15%)
    ///   - semanticGap: Gap value 0-1
    /// - Returns: Smoothed adjusted share between EngineConfig.axisShareMin and EngineConfig.axisShareMax
    private static func calculateGapDrivenWeight(
        baseShare: Double,
        semanticGap: Double
    ) -> Double {
        // Apply amplification to gap
        let amplifiedGap = semanticGap * EngineConfig.gapAmplificationFactor
        
        // Interpolate between min and max based on gap
        let range = EngineConfig.axisShareMax - EngineConfig.axisShareMin
        let adjustment = amplifiedGap * range
        
        let sRaw = baseShare + adjustment
        
        // Apply hysteresis smoothing: blend with last run's value
        let lastAxisShare = getLastAxisShare()
        let sSmoothed = lastAxisShare * EngineConfig.hysteresisAlpha + sRaw * (1.0 - EngineConfig.hysteresisAlpha)
        
        // Clamp to bounds
        let s = min(max(sSmoothed, EngineConfig.axisShareMin), EngineConfig.axisShareMax)
        
        // Persist for next run
        saveAxisShare(s)
        
        if EngineConfig.enableAxisDebug {
            print("  Axis Share: raw=\(String(format: "%.3f", sRaw)), smoothed=\(String(format: "%.3f", sSmoothed)), final=\(String(format: "%.3f", s))")
        }
        
        return s
    }
    
    // MARK: - Individual Axis Token Generators
    
    /// Generate action axis tokens
    private static func generateActionTokens(axisValue: Double, weight: Double) -> [StyleToken] {
        let tokens: [StyleToken]
        
        if axisValue >= 7.0 {
            // High action
            tokens = [
                StyleToken(name: "kinetic", type: "mood", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "momentum", type: "expression", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "drive", type: "mood", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else if axisValue <= 4.0 {
            // Low action
            tokens = [
                StyleToken(name: "anchored", type: "mood", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "grounded", type: "expression", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "steady", type: "structure", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else {
            // Moderate action - minimal tokens
            tokens = [
                StyleToken(name: "balanced", type: "mood", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis)
            ]
        }
        
        return tokens
    }
    
    /// Generate tempo axis tokens
    private static func generateTempoTokens(axisValue: Double, weight: Double) -> [StyleToken] {
        let tokens: [StyleToken]
        
        if axisValue >= 7.0 {
            // High tempo
            tokens = [
                StyleToken(name: "rapid", type: "expression", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "quick", type: "mood", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "pulsing", type: "texture", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else if axisValue <= 4.0 {
            // Low tempo
            tokens = [
                StyleToken(name: "measured", type: "expression", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "deliberate", type: "mood", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "sustained", type: "structure", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else {
            // Moderate tempo - minimal tokens
            tokens = [
                StyleToken(name: "rhythmic", type: "mood", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis)
            ]
        }
        
        return tokens
    }
    
    /// Generate strategy axis tokens
    private static func generateStrategyTokens(axisValue: Double, weight: Double) -> [StyleToken] {
        let tokens: [StyleToken]
        
        if axisValue >= 7.0 {
            // High strategy
            tokens = [
                StyleToken(name: "structured", type: "structure", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "precise", type: "expression", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "organized", type: "mood", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else if axisValue <= 4.0 {
            // Low strategy
            tokens = [
                StyleToken(name: "flowing", type: "structure", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "fluid", type: "texture", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "adaptive", type: "mood", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else {
            // Moderate strategy - minimal tokens
            tokens = [
                StyleToken(name: "flexible", type: "structure", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis)
            ]
        }
        
        return tokens
    }
    
    /// Generate visibility axis tokens
    private static func generateVisibilityTokens(axisValue: Double, weight: Double) -> [StyleToken] {
        let tokens: [StyleToken]
        
        if axisValue >= 7.0 {
            // High visibility
            tokens = [
                StyleToken(name: "prominent", type: "expression", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "visible", type: "structure", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "expressive", type: "mood", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else if axisValue <= 4.0 {
            // Low visibility
            tokens = [
                StyleToken(name: "understated", type: "expression", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "subtle", type: "texture", weight: weight * 0.3, planetarySource: "DerivedAxes", originType: .axis),
                StyleToken(name: "refined", type: "mood", weight: weight * 0.2, planetarySource: "DerivedAxes", originType: .axis)
            ]
        } else {
            // Moderate visibility - minimal tokens
            tokens = [
                StyleToken(name: "present", type: "expression", weight: weight * 0.5, planetarySource: "DerivedAxes", originType: .axis)
            ]
        }
        
        return tokens
    }
}

