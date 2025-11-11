//
//  AxisVolatilityEngine.swift
//  Cosmic Fit
//
//  Creates meaningful daily axis variation based on astrological factors
//

import Foundation

/// Creates meaningful daily axis variation based on astrological factors
class AxisVolatilityEngine {
    
    /// Generate axis variation based on multiple daily factors
    static func generateDailyAxisModulation(
        baseAxes: DerivedAxes,
        tokens: [StyleToken],
        transitCount: Int,
        moonPhase: Double,
        dailySeed: Int
    ) -> DerivedAxes {
        
        var modulated = baseAxes
        
        // 1. Transit intensity modulation
        let transitModulation = calculateTransitModulation(transitCount: transitCount)
        
        // 2. Moon phase modulation
        let moonModulation = calculateMoonPhaseModulation(phase: moonPhase)
        
        // 3. Token diversity modulation
        let tokenModulation = calculateTokenDiversityModulation(tokens: tokens)
        
        // 4. Deterministic daily variation
        let seedModulation = calculateSeedModulation(seed: dailySeed)
        
        // Apply modulations
        let newAction = modulated.action * transitModulation.action * moonModulation.action * tokenModulation.action * seedModulation.action
        let newTempo = modulated.tempo * transitModulation.tempo * moonModulation.tempo * tokenModulation.tempo * seedModulation.tempo
        let newStrategy = modulated.strategy * transitModulation.strategy * moonModulation.strategy * tokenModulation.strategy * seedModulation.strategy
        let newVisibility = modulated.visibility * transitModulation.visibility * moonModulation.visibility * tokenModulation.visibility * seedModulation.visibility
        
        modulated = DerivedAxes(
            action: newAction,
            tempo: newTempo,
            strategy: newStrategy,
            visibility: newVisibility
        )
        
        // Ensure valid range and balanced distribution
        modulated = normalizeAxes(modulated)
        
        return modulated
    }
    
    private static func calculateTransitModulation(transitCount: Int) -> (action: Double, tempo: Double, strategy: Double, visibility: Double) {
        // More transits = higher tempo and action, lower strategy
        let transitIntensity = min(Double(transitCount) / 30.0, 2.0) // Cap at 2x
        
        return (
            action: 1.0 + (transitIntensity * 0.15),      // +0-30% action
            tempo: 1.0 + (transitIntensity * 0.20),       // +0-40% tempo
            strategy: 1.0 - (transitIntensity * 0.10),    // -0-20% strategy
            visibility: 1.0 + (transitIntensity * 0.05)   // +0-10% visibility
        )
    }
    
    private static func calculateMoonPhaseModulation(phase: Double) -> (action: Double, tempo: Double, strategy: Double, visibility: Double) {
        // Full moon = higher visibility/action, New moon = higher strategy
        // phase should be 0-1 where 0.0 = new moon, 0.5 = full moon
        let fullMoonFactor = abs(phase - 0.5) * 2.0 // 0-1 scale (1.0 at full/new moon)
        
        return (
            action: 1.0 + (fullMoonFactor * 0.10),
            tempo: 1.0 + (fullMoonFactor * 0.08),
            strategy: 1.0 + ((1.0 - fullMoonFactor) * 0.12),
            visibility: 1.0 + (fullMoonFactor * 0.15)
        )
    }
    
    private static func calculateTokenDiversityModulation(tokens: [StyleToken]) -> (action: Double, tempo: Double, strategy: Double, visibility: Double) {
        // Analyze token composition for axis hints
        let fastTokens = tokens.filter { ["quick", "rapid", "kinetic", "dynamic"].contains($0.name.lowercased()) }.count
        let slowTokens = tokens.filter { ["deliberate", "grounded", "enduring", "stable"].contains($0.name.lowercased()) }.count
        let strategicTokens = tokens.filter { ["structured", "planned", "methodical", "systematic"].contains($0.name.lowercased()) }.count
        let expressiveTokens = tokens.filter { ["expressive", "visible", "prominent", "bold"].contains($0.name.lowercased()) }.count
        
        let totalSpeedTokens = max(fastTokens + slowTokens, 1)
        let speedRatio = Double(fastTokens) / Double(totalSpeedTokens)
        let strategyRatio = tokens.isEmpty ? 0.0 : Double(strategicTokens) / Double(tokens.count)
        let expressionRatio = tokens.isEmpty ? 0.0 : Double(expressiveTokens) / Double(tokens.count)
        
        return (
            action: 1.0 + (speedRatio * 0.20 - 0.10),        // ±20% based on speed tokens
            tempo: 1.0 + (speedRatio * 0.25 - 0.125),        // ±25% based on speed tokens
            strategy: 1.0 + (strategyRatio * 0.30 - 0.15),   // ±30% based on strategy tokens
            visibility: 1.0 + (expressionRatio * 0.20 - 0.10) // ±20% based on expression tokens
        )
    }
    
    private static func calculateSeedModulation(seed: Int) -> (action: Double, tempo: Double, strategy: Double, visibility: Double) {
        let seedDouble = Double(seed)
        
        return (
            action: 1.0 + sin(seedDouble * 0.1234) * 0.12,     // ±12% daily variation
            tempo: 1.0 + sin(seedDouble * 0.2345) * 0.15,      // ±15% daily variation
            strategy: 1.0 + sin(seedDouble * 0.3456) * 0.10,   // ±10% daily variation
            visibility: 1.0 + sin(seedDouble * 0.4567) * 0.13  // ±13% daily variation
        )
    }
    
    private static func normalizeAxes(_ axes: DerivedAxes) -> DerivedAxes {
        // Clamp to valid range
        var clamped = DerivedAxes(
            action: max(1.0, min(10.0, axes.action)),
            tempo: max(1.0, min(10.0, axes.tempo)),
            strategy: max(1.0, min(10.0, axes.strategy)),
            visibility: max(1.0, min(10.0, axes.visibility))
        )
        
        // Apply balancing to prevent dominance
        clamped = AxisBalancer.balanceAxes(clamped)
        
        return clamped
    }
}

