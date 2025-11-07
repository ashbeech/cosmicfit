//
//  TokenMerger.swift
//  Cosmic Fit
//
//  Created for Phase 1: Axis Token Source Implementation (v1.1)
//  Merges duplicate tokens by name, combining weights and prioritizing axis origin
//

import Foundation

/// Utility for merging duplicate tokens in the token pool
final class TokenMerger {
    
    // MARK: - Configuration
    
    /// Soft cap for individual token weights to prevent extreme influence
    /// Weights above this are gently compressed using square root normalization
    private static let perLabelSoftCap: Double = 3.0
    
    // MARK: - Token Merging
    
    /// Merge tokens with duplicate names, combining weights
    /// Prioritizes .axis origin type when merging
    /// - Parameter tokens: Array of tokens to merge
    /// - Returns: Array of merged tokens with no duplicates
    static func mergeTokensByName(_ tokens: [StyleToken]) -> [StyleToken] {
        var tokensByName: [String: [StyleToken]] = [:]
        
        // Group tokens by name
        for token in tokens {
            let key = token.name.lowercased()
            if tokensByName[key] == nil {
                tokensByName[key] = []
            }
            tokensByName[key]?.append(token)
        }
        
        var mergedTokens: [StyleToken] = []
        
        for (name, duplicates) in tokensByName {
            if duplicates.count == 1 {
                // No duplicates - add as-is
                mergedTokens.append(duplicates[0])
            } else {
                // Merge duplicates
                let merged = mergeDuplicateTokens(duplicates)
                mergedTokens.append(merged)
                
                if EngineConfig.enableMergeDebug {
                    print("  🔀 Merged \(duplicates.count) tokens named '\(name)' → weight: \(String(format: "%.2f", merged.weight))")
                }
            }
        }
        
        // Apply soft cap to prevent extreme weights from dominating
        let normalized = applySoftCap(to: mergedTokens)
        
        return normalized
    }
    
    // MARK: - Private Methods
    
    /// Apply soft cap to token weights to prevent extreme values
    /// Uses sqrt compression for weights above threshold to preserve ranking but tame extremes
    /// - Parameter tokens: Tokens to normalize
    /// - Returns: Tokens with soft-capped weights
    private static func applySoftCap(to tokens: [StyleToken]) -> [StyleToken] {
        return tokens.map { token in
            guard token.weight > perLabelSoftCap else { return token }
            
            // Gentle compression: sqrt keeps ranking but tames extremes
            let cappedWeight = sqrt(token.weight * perLabelSoftCap)
            
            if EngineConfig.enableMergeDebug {
                print("  📏 Soft-capped '\(token.name)': \(String(format: "%.2f", token.weight)) → \(String(format: "%.2f", cappedWeight))")
            }
            
            return StyleToken(
                name: token.name,
                type: token.type,
                weight: cappedWeight,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                originType: token.originType
            )
        }
    }
    
    /// Merge an array of duplicate tokens into a single token
    /// - Parameter duplicates: Array of tokens with the same name
    /// - Returns: A single merged token
    private static func mergeDuplicateTokens(_ duplicates: [StyleToken]) -> StyleToken {
        guard !duplicates.isEmpty else {
            fatalError("Cannot merge empty array of tokens")
        }
        
        // Prioritize axis tokens for origin preservation
        let axisTokens = duplicates.filter { $0.originType == .axis }
        let preferredToken = axisTokens.first ?? duplicates[0]
        
        // Sum all weights
        let combinedWeight = duplicates.reduce(0.0) { $0 + $1.weight }
        
        // Create merged token preserving preferred origin
        return StyleToken(
            name: preferredToken.name,
            type: preferredToken.type,
            weight: combinedWeight,
            planetarySource: preferredToken.planetarySource,
            signSource: preferredToken.signSource,
            houseSource: preferredToken.houseSource,
            aspectSource: preferredToken.aspectSource,
            originType: preferredToken.originType
        )
    }
}

