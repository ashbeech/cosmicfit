//
//  AxisBalancer.swift
//  Cosmic Fit
//
//  Prevents single-axis dominance while maintaining astrological authenticity
//

import Foundation

/// Prevents single-axis dominance while maintaining astrological authenticity
class AxisBalancer {
    
    // Configuration constants
    private static let maxAxisValue: Double = 8.5
    private static let minAxisValue: Double = 2.0
    private static let redistributionEfficiency: Double = 0.7
    
    /// Balance axes to prevent single-axis dominance
    static func balanceAxes(_ axes: DerivedAxes) -> DerivedAxes {
        var balanced = axes
        var redistributionPool: Double = 0.0
        
        // Step 1: Cap overly dominant axes and collect excess energy
        if balanced.action > maxAxisValue {
            redistributionPool += (balanced.action - maxAxisValue) * redistributionEfficiency
            balanced = DerivedAxes(
                action: maxAxisValue,
                tempo: balanced.tempo,
                strategy: balanced.strategy,
                visibility: balanced.visibility
            )
        }
        if balanced.tempo > maxAxisValue {
            redistributionPool += (balanced.tempo - maxAxisValue) * redistributionEfficiency
            balanced = DerivedAxes(
                action: balanced.action,
                tempo: maxAxisValue,
                strategy: balanced.strategy,
                visibility: balanced.visibility
            )
        }
        if balanced.strategy > maxAxisValue {
            redistributionPool += (balanced.strategy - maxAxisValue) * redistributionEfficiency
            balanced = DerivedAxes(
                action: balanced.action,
                tempo: balanced.tempo,
                strategy: maxAxisValue,
                visibility: balanced.visibility
            )
        }
        if balanced.visibility > maxAxisValue {
            redistributionPool += (balanced.visibility - maxAxisValue) * redistributionEfficiency
            balanced = DerivedAxes(
                action: balanced.action,
                tempo: balanced.tempo,
                strategy: balanced.strategy,
                visibility: maxAxisValue
            )
        }
        
        // Step 2: Redistribute excess energy to lower axes
        let allAxes = [balanced.action, balanced.tempo, balanced.strategy, balanced.visibility]
        let belowAverage = allAxes.filter { $0 < 6.0 }
        
        if !belowAverage.isEmpty && redistributionPool > 0 {
            let redistributionPerAxis = redistributionPool / Double(belowAverage.count)
            
            var newAction = balanced.action
            var newTempo = balanced.tempo
            var newStrategy = balanced.strategy
            var newVisibility = balanced.visibility
            
            if balanced.action < 6.0 {
                newAction = min(maxAxisValue, balanced.action + redistributionPerAxis)
            }
            if balanced.tempo < 6.0 {
                newTempo = min(maxAxisValue, balanced.tempo + redistributionPerAxis)
            }
            if balanced.strategy < 6.0 {
                newStrategy = min(maxAxisValue, balanced.strategy + redistributionPerAxis)
            }
            if balanced.visibility < 6.0 {
                newVisibility = min(maxAxisValue, balanced.visibility + redistributionPerAxis)
            }
            
            balanced = DerivedAxes(
                action: newAction,
                tempo: newTempo,
                strategy: newStrategy,
                visibility: newVisibility
            )
        }
        
        // Step 3: Ensure minimum thresholds
        balanced = DerivedAxes(
            action: max(minAxisValue, balanced.action),
            tempo: max(minAxisValue, balanced.tempo),
            strategy: max(minAxisValue, balanced.strategy),
            visibility: max(minAxisValue, balanced.visibility)
        )
        
        return balanced
    }
    
    /// Add controlled volatility to prevent repetitive profiles
    static func addDailyVolatility(to axes: DerivedAxes, seed: Int) -> DerivedAxes {
        let seedDouble = Double(seed)
        
        // Generate deterministic but varying daily offsets (smaller than before)
        let actionOffset = sin(seedDouble * 0.0731) * 0.8   // ±0.8 point swing
        let tempoOffset = sin(seedDouble * 0.1047) * 1.0    // ±1.0 point swing
        let strategyOffset = sin(seedDouble * 0.0613) * 0.6 // ±0.6 point swing
        let visibilityOffset = sin(seedDouble * 0.0891) * 0.9 // ±0.9 point swing
        
        let volatile = DerivedAxes(
            action: axes.action + actionOffset,
            tempo: axes.tempo + tempoOffset,
            strategy: axes.strategy + strategyOffset,
            visibility: axes.visibility + visibilityOffset
        )
        
        // Re-balance after adding volatility
        return balanceAxes(volatile)
    }
    
    /// Debug logging for axis changes
    static func logAxisBalancing(original: DerivedAxes, balanced: DerivedAxes) {
        print("🎚️ AXIS BALANCING:")
        print("  Original:  A:\(String(format: "%.1f", original.action)) T:\(String(format: "%.1f", original.tempo)) S:\(String(format: "%.1f", original.strategy)) V:\(String(format: "%.1f", original.visibility))")
        print("  Balanced:  A:\(String(format: "%.1f", balanced.action)) T:\(String(format: "%.1f", balanced.tempo)) S:\(String(format: "%.1f", balanced.strategy)) V:\(String(format: "%.1f", balanced.visibility))")
        
        let maxOriginal = max(original.action, original.tempo, original.strategy, original.visibility)
        let maxBalanced = max(balanced.action, balanced.tempo, balanced.strategy, balanced.visibility)
        print("  Max Axis Reduced: \(String(format: "%.1f", maxOriginal)) → \(String(format: "%.1f", maxBalanced))")
    }
}

