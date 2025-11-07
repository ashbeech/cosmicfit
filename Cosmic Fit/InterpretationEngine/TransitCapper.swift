//
//  TransitCapper.swift
//  Cosmic Fit
//
//  Created for Phase 1: Axis Token Source Implementation (v1.1)
//  Caps transit token dominance at 35% of total token pool weight
//

import Foundation

/// Utility for capping transit token share in the token pool
final class TransitCapper {
    
    // MARK: - Transit Capping
    
    /// Cap transit tokens to maximum 35% of total weight relative to other sources
    /// - Parameters:
    ///   - transitTokens: Array of transit tokens to potentially cap
    ///   - otherTokens: Array of all other (non-transit) tokens
    /// - Returns: Array of transit tokens with weights adjusted if necessary
    static func capTransitTokens(
        _ transitTokens: [StyleToken],
        relativeTo otherTokens: [StyleToken]
    ) -> [StyleToken] {
        
        guard !transitTokens.isEmpty && !otherTokens.isEmpty else {
            return transitTokens
        }
        
        let transitWeight = transitTokens.reduce(0.0) { $0 + $1.weight }
        let otherWeight = otherTokens.reduce(0.0) { $0 + $1.weight }
        let totalWeight = transitWeight + otherWeight
        
        let currentTransitShare = transitWeight / totalWeight
        
        // If transit share is within limits, no adjustment needed
        guard currentTransitShare > EngineConfig.transitCap else {
            if EngineConfig.enableTransitCapDebug {
                print("  ✅ Transit share: \(String(format: "%.1f%%", currentTransitShare * 100)) (within \(Int(EngineConfig.transitCap * 100))% cap)")
            }
            return transitTokens
        }
        
        // Calculate target transit weight to achieve cap
        // If transit = cap% of total, then: transit = cap * (transit + other)
        // Solving for transit: transit = cap * other / (1 - cap)
        let targetTransitWeight = (EngineConfig.transitCap / (1.0 - EngineConfig.transitCap)) * otherWeight
        let scalingFactor = targetTransitWeight / transitWeight
        
        if EngineConfig.enableTransitCapDebug {
            print("  ⚠️ Transit share: \(String(format: "%.1f%%", currentTransitShare * 100)) exceeds \(Int(EngineConfig.transitCap * 100))% cap")
            print("  📉 Scaling transit tokens by \(String(format: "%.2f", scalingFactor))x")
        }
        
        // Scale down all transit tokens proportionally
        return transitTokens.map { token in
            StyleToken(
                name: token.name,
                type: token.type,
                weight: token.weight * scalingFactor,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: token.originType
            )
        }
    }
    
    /// Calculate what the transit share would be with given tokens
    /// - Parameters:
    ///   - transitTokens: Array of transit tokens
    ///   - otherTokens: Array of all other tokens
    /// - Returns: Transit share as a percentage (0-100)
    static func calculateTransitShare(
        transitTokens: [StyleToken],
        otherTokens: [StyleToken]
    ) -> Double {
        let transitWeight = transitTokens.reduce(0.0) { $0 + $1.weight }
        let otherWeight = otherTokens.reduce(0.0) { $0 + $1.weight }
        let totalWeight = transitWeight + otherWeight
        
        guard totalWeight > 0 else { return 0 }
        
        return (transitWeight / totalWeight) * 100.0
    }
}

