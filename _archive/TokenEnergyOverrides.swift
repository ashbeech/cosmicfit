//
//  TokenEnergyOverrides.swift
//  Cosmic Fit
//
//  Created by AI Assistant on 12/05/2025.
//  Custom token-to-energy mapping overrides for nuanced Tarot selection
//

import Foundation

/// Manages custom overrides for token-to-energy mappings
class TokenEnergyOverrides {
    
    /// Custom token-to-energy mappings for ambiguous or multi-faceted tokens
    private static let tokenOverrides: [String: [String: Double]] = [
        // Multi-faceted tokens that could map to multiple energies
        "versatile": [
            "playful": 0.5,
            "utility": 0.5
        ],
        "transformative": [
            "drama": 0.7,
            "romantic": 0.3
        ],
        "adaptable": [
            "utility": 0.6,
            "playful": 0.4
        ],
        "dynamic": [
            "playful": 0.6,
            "drama": 0.4
        ],
        "elegant": [
            "classic": 0.6,
            "romantic": 0.4
        ],
        "refined": [
            "classic": 0.7,
            "romantic": 0.3
        ],
        "bold": [
            "drama": 0.7,
            "playful": 0.3
        ],
        "expressive": [
            "playful": 0.6,
            "drama": 0.4
        ],
        "creative": [
            "playful": 0.5,
            "romantic": 0.3,
            "edge": 0.2
        ],
        "innovative": [
            "edge": 0.7,
            "playful": 0.3
        ],
        "sophisticated": [
            "classic": 0.8,
            "romantic": 0.2
        ],
        "comfortable": [
            "romantic": 0.6,
            "utility": 0.4
        ],
        "flowing": [
            "romantic": 0.8,
            "playful": 0.2
        ],
        "structured": [
            "classic": 0.7,
            "utility": 0.3
        ],
        "mysterious": [
            "drama": 0.6,
            "edge": 0.4
        ],
        "radiant": [
            "playful": 0.5,
            "drama": 0.5
        ],
        "electric": [
            "edge": 0.7,
            "playful": 0.3
        ],
        "powerful": [
            "drama": 0.8,
            "classic": 0.2
        ],
        "gentle": [
            "romantic": 0.8,
            "classic": 0.2
        ],
        "fresh": [
            "playful": 0.7,
            "edge": 0.3
        ],
        "timeless": [
            "classic": 0.9,
            "romantic": 0.1
        ]
    ]
    
    /// Get energy distribution for a token, considering both direct mappings and overrides
    /// - Parameter tokenName: The token name to evaluate
    /// - Returns: Dictionary of energy names to affinity scores (0.0-1.0)
    static func getEnergyDistribution(for tokenName: String) -> [String: Double] {
        let normalizedToken = tokenName.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check if we have a custom override for this token
        if let override = tokenOverrides[normalizedToken] {
            return override
        }
        
        // Fall back to direct energy mapping based on standard keywords
        return getStandardEnergyMapping(for: normalizedToken)
    }
    
    /// Calculate blended energy affinity score for a token against a card
    /// - Parameters:
    ///   - tokenName: The token to evaluate
    ///   - card: The tarot card to score against
    /// - Returns: Blended affinity score
    static func calculateBlendedAffinity(for tokenName: String, with card: TarotCard) -> Double {
        let energyDistribution = getEnergyDistribution(for: tokenName)
        var blendedScore = 0.0
        
        for (energyName, tokenEnergyWeight) in energyDistribution {
            let cardEnergyAffinity = card.energyAffinity[energyName] ?? 0.0
            blendedScore += tokenEnergyWeight * cardEnergyAffinity
        }
        
        return blendedScore
    }
    
    /// Standard energy mapping for tokens without custom overrides
    /// - Parameter tokenName: The token name
    /// - Returns: Dictionary with single energy mapping
    private static func getStandardEnergyMapping(for tokenName: String) -> [String: Double] {
        // Classic tokens
        if ["grounded", "reserved", "solid", "refined", "polished", "professional", 
            "timeless", "balanced", "harmonious", "elegant", "sophisticated", 
            "classic", "conservative", "traditional", "disciplined", "authoritative", 
            "enduring", "substantial", "commanding"].contains(tokenName) {
            return ["classic": 1.0]
        }
        
        // Playful tokens
        if ["bright", "vibrant", "dynamic", "energetic", "fun", "expressive", 
            "creative", "colourful", "light", "airy", "versatile", "quick", 
            "adaptable", "communicative", "cheerful", "playful", "lively", "spirited"].contains(tokenName) {
            return ["playful": 1.0]
        }
        
        // Romantic tokens
        if ["flowing", "soft", "gentle", "dreamy", "ethereal", "luxurious", 
            "sensual", "beautiful", "harmonious", "nurturing", "comfortable", 
            "warm", "delicate", "feminine", "graceful", "fluid", "pearl", 
            "intuitive", "compassionate", "receptive", "empathetic", "subtle"].contains(tokenName) {
            return ["romantic": 1.0]
        }
        
        // Utility tokens
        if ["practical", "functional", "waterproof", "durable", "purposeful", 
            "protective", "reliable", "tactical", "insulating", "layerable", 
            "breathable", "weatherproof", "wind-resistant", "secure", "stable", 
            "efficient", "versatile", "adaptable", "multi-purpose", "performance"].contains(tokenName) {
            return ["utility": 1.0]
        }
        
        // Drama tokens
        if ["bold", "intense", "powerful", "dramatic", "striking", "rich", 
            "deep", "transformative", "commanding", "magnetic", "royal", 
            "electric", "metallic", "radiant", "mysterious", "penetrating", 
            "emotional", "passionate", "hypnotic", "profound"].contains(tokenName) {
            return ["drama": 1.0]
        }
        
        // Edge tokens
        if ["unconventional", "innovative", "unique", "unexpected", "electric", 
            "neon", "metallic", "textured", "distinctive", "rebellious", 
            "avant-garde", "edgy", "alternative", "disruptive", "experimental"].contains(tokenName) {
            return ["edge": 1.0]
        }
        
        // Default: distribute evenly if no clear mapping
        return ["classic": 0.2, "playful": 0.2, "romantic": 0.2, "utility": 0.2, "drama": 0.1, "edge": 0.1]
    }
    
    /// Get all tokens that have custom overrides
    /// - Returns: Array of token names with custom mappings
    static func getCustomMappedTokens() -> [String] {
        return Array(tokenOverrides.keys).sorted()
    }
    
    /// Check if a token has a custom override mapping
    /// - Parameter tokenName: Token to check
    /// - Returns: True if custom mapping exists
    static func hasCustomMapping(for tokenName: String) -> Bool {
        return tokenOverrides[tokenName.lowercased()] != nil
    }
    
    /// Debug method to show how a token maps to energies
    /// - Parameter tokenName: Token to analyze
    /// - Returns: String description of energy mapping
    static func debugTokenMapping(for tokenName: String) -> String {
        let distribution = getEnergyDistribution(for: tokenName)
        let hasCustom = hasCustomMapping(for: tokenName)
        
        var result = "Token: '\(tokenName)' "
        result += hasCustom ? "(Custom Override)" : "(Standard Mapping)"
        result += "\n"
        
        for (energy, weight) in distribution.sorted(by: { $0.value > $1.value }) {
            let percentage = Int(weight * 100)
            result += "  • \(energy): \(percentage)%\n"
        }
        
        return result
    }
}
