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
    /// Prioritizes .axis and .transit origin types when merging
    /// Preserves transit token nuance by including source info in grouping key
    /// - Parameter tokens: Array of tokens to merge
    /// - Returns: Array of merged tokens with no duplicates
    static func mergeTokensByName(_ tokens: [StyleToken]) -> [StyleToken] {
        var tokensByName: [String: [StyleToken]] = [:]
        
        // Group tokens by name + origin type for transit preservation
        // This preserves meaningful differences between transit tokens from different sources
        for token in tokens {
            var key = token.name.lowercased()
            
            // Preserve transit token uniqueness by including source info
            if token.originType == .transit {
                let sourceInfo = token.planetarySource ?? token.aspectSource ?? "unknown"
                key += "_\(token.originType.rawValue)_\(sourceInfo.lowercased())"
            }
            
            if tokensByName[key] == nil {
                tokensByName[key] = []
            }
            tokensByName[key]?.append(token)
        }
        
        var mergedTokens: [StyleToken] = []
        
        for (key, duplicates) in tokensByName {
            if duplicates.count == 1 {
                // No duplicates - add as-is
                mergedTokens.append(duplicates[0])
            } else {
                // Merge duplicates using priority-based weighted merging
                let merged = mergeDuplicateTokens(duplicates)
                mergedTokens.append(merged)
                
                if EngineConfig.enableMergeDebug {
                    let name = duplicates[0].name
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
    /// Uses priority-based selection to preserve transit and axis tokens for daily variation
    /// - Parameter duplicates: Array of tokens with the same name
    /// - Returns: A single merged token
    private static func mergeDuplicateTokens(_ duplicates: [StyleToken]) -> StyleToken {
        guard !duplicates.isEmpty else {
            fatalError("Cannot merge empty array of tokens")
        }
        
        // Calculate total weight
        let totalWeight = duplicates.reduce(0.0) { $0 + $1.weight }
        
        // Prioritize tokens by origin type for daily variation
        // Transit tokens get highest priority, then axis, then phase
        let priorityToken = duplicates.max { a, b in
            let aPriority = getPriorityScore(a)
            let bPriority = getPriorityScore(b)
            return aPriority < bPriority
        } ?? duplicates[0]
        
        // Use weighted average with slight reduction to prevent weight explosion
        // But preserve more weight for transit/axis tokens to maintain daily variation
        let finalWeight: Double
        if priorityToken.originType == .transit || priorityToken.originType == .axis {
            finalWeight = totalWeight * 0.9  // Preserve more weight for daily variation sources
        } else {
            finalWeight = totalWeight * 0.8  // Slight reduction for other sources
        }
        
        // Create merged token preserving priority origin
        return StyleToken(
            name: priorityToken.name,
            type: priorityToken.type,
            weight: finalWeight,
            planetarySource: priorityToken.planetarySource,
            signSource: priorityToken.signSource,
            houseSource: priorityToken.houseSource,
            aspectSource: priorityToken.aspectSource,
            originType: priorityToken.originType
        )
    }
    
    /// Get priority score for token origin type
    /// Higher scores indicate tokens that should be preserved for daily variation
    /// - Parameter token: Token to score
    /// - Returns: Priority score (higher = more important for daily variation)
    private static func getPriorityScore(_ token: StyleToken) -> Double {
        switch token.originType {
        case .transit: return 10.0  // Highest priority - daily variation drivers
        case .axis: return 9.0      // High priority - structural variation
        case .phase: return 8.0     // Moderate-high - moon phase variation
        case .weather: return 7.0   // Moderate - environmental variation
        case .progressed: return 5.0 // Lower - slower changes
        case .natal: return 3.0     // Low - static baseline
        case .currentSun: return 1.0 // Lowest - seasonal baseline
        }
    }
}

