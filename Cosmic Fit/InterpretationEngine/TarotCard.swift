//
//  TarotCard.swift
//  Cosmic Fit
//
//  Created by AI Assistant on 12/05/2025.
//  Data model for Tarot cards with semantic token mapping
//

import Foundation

/// Data model representing a Tarot card with semantic matching capabilities
struct TarotCard: Codable, Identifiable {
    let name: String               // e.g., "The Chariot", "Three of Cups"
    let imagePath: String          // Path for Assets.xcassets (e.g., "Cards/00-TheFool")
    let arcana: ArcanaType         // Major or Minor
    let suit: SuitType?            // For Minor Arcana only
    let number: Int?               // For Minor Arcana: 1-14 (11=Page, 12=Knight, 13=Queen, 14=King)
    let keywords: [String]         // Semantic tokens that match this card
    let themes: [String]           // CompositeTheme matches
    let energyAffinity: [String: Double]  // Affinity scores for vibe breakdown energies
    let description: String        // Brief interpretation/meaning
    let reversedKeywords: [String] // For future reversal support
    let symbolism: [String]        // Key symbolic elements
    
    // MARK: - Enums
    
    enum ArcanaType: String, Codable, CaseIterable {
        case major = "Major"
        case minor = "Minor"
    }
    
    enum SuitType: String, Codable, CaseIterable {
        case cups = "Cups"
        case wands = "Wands"
        case swords = "Swords"
        case pentacles = "Pentacles"
    }
    
        // MARK: - Computed Properties

    /// Stable identifier for Identifiable conformance
    var id: String {
        return name
    }

    /// Full card identifier for display (e.g., "The Chariot", "Three of Cups")
    var displayName: String {
        return name
    }
    
    /// Card category for filtering/grouping
    var category: String {
        switch arcana {
        case .major:
            return "Major Arcana"
        case .minor:
            guard let suit = suit else { return "Minor Arcana" }
            return suit.rawValue
        }
    }
    
    /// Priority score for tie-breaking (Major Arcana generally preferred)
    var priority: Double {
        switch arcana {
        case .major:
            return 1.0
        case .minor:
            return 0.8
        }
    }
    
    /// Check if this card has strong affinity for a specific energy
    func hasStrongAffinityFor(energy: String) -> Bool {
        return (energyAffinity[energy.lowercased()] ?? 0.0) >= 0.7
    }
    
    /// Get the card's dominant energy
    var dominantEnergy: String? {
        return energyAffinity.max(by: { $0.value < $1.value })?.key
    }
    
    /// Calculate match score for this card based on tokens and theme
    /// - Parameters:
    ///   - tokens: Array of StyleTokens to match against
    ///   - theme: Optional theme name for bonus matching
    ///   - vibeBreakdown: Optional VibeBreakdown for energy alignment
    ///   - profileHash: User profile identifier for recency tracking
    /// - Returns: Total match score (higher is better)
    func calculateMatchScore(
            for tokens: [StyleToken],
            theme: String? = nil,
            vibeBreakdown: VibeBreakdown? = nil,
            profileHash: String? = nil  // This parameter is now unused but kept for compatibility
        ) -> Double {
            
            var score: Double = 0.0
            
            // 1. Token keyword matching (primary scoring mechanism)
            for token in tokens {
                // Check if any of this card's keywords match the token name
                let tokenLower = token.name.lowercased()
                let matchingKeywords = keywords.filter { $0.lowercased().contains(tokenLower) || tokenLower.contains($0.lowercased()) }
                
                if !matchingKeywords.isEmpty {
                    // Apply weight dampening to prevent over-indexing on high-weight tokens
                    let effectiveWeight = pow(token.weight, 0.9)
                    score += effectiveWeight * 2.0
                }
            }
            
            // 2. Theme matching (contextual bonus)
            if let themeName = theme {
                let themeLower = themeName.lowercased()
                for cardTheme in themes {
                    if cardTheme.lowercased().contains(themeLower) || themeLower.contains(cardTheme.lowercased()) {
                        score += 1.5
                    }
                }
            }
            
            // 3. Energy affinity alignment (secondary influence)
            if let vibe = vibeBreakdown {
                let energyMap: [(String, Int)] = [
                    ("classic", vibe.classic),
                    ("playful", vibe.playful),
                    ("romantic", vibe.romantic),
                    ("utility", vibe.utility),
                    ("drama", vibe.drama),
                    ("edge", vibe.edge)
                ]
                
                for (energyName, energyPoints) in energyMap {
                    if let affinity = energyAffinity[energyName], energyPoints > 0 {
                        score += Double(energyPoints) * affinity * 0.3
                    }
                }
            }
            
            // 4. Priority bonus for tie-breaking
            score += priority * 0.5
            
            // REMOVED: Step 5 (decay penalty) - now handled by hard-block cooldown in TarotCardSelector
            
            return score
        }
    
    /// Generate a contextual interpretation based on the day's energy
    func generateInterpretation(for vibeBreakdown: VibeBreakdown, tokens: [StyleToken]) -> String {
        guard let dominantEnergy = vibeBreakdown.dominantEnergy else {
            return description
        }
        
        // Create energy-specific interpretations
        let energyContext = getEnergyContext(for: dominantEnergy, breakdown: vibeBreakdown)
        let cardWisdom = getCardWisdom(for: tokens)
        
        return "\(name) appears today as a guide for \(energyContext). \(cardWisdom) \(description)"
    }
    
    // MARK: - Helper Methods
    
    private func getEnergyContext(for energy: String, breakdown: VibeBreakdown) -> String {
        switch energy.lowercased() {
        case "classic":
            return "grounding yourself in timeless wisdom"
        case "playful":
            return "embracing spontaneity and creative expression"
        case "romantic":
            return "connecting with beauty and emotional flow"
        case "utility":
            return "focusing on practical action and purposeful choices"
        case "drama":
            return "stepping boldly into your power"
        case "edge":
            return "breaking new ground and embracing innovation"
        default:
            return "finding balance in today's energy"
        }
    }
    
    private func getCardWisdom(for tokens: [StyleToken]) -> String {
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(3)
        let tokenNames = topTokens.map { $0.name }.joined(separator: ", ")
        
        return "Today's essence of \(tokenNames) aligns with this card's guidance."
    }
}

// MARK: - VibeBreakdown Extension

extension VibeBreakdown {
    /// Get the dominant energy name for tarot matching
    var dominantEnergy: String? {
        let energies = [
            ("classic", classic),
            ("playful", playful),
            ("romantic", romantic),
            ("utility", utility),
            ("drama", drama),
            ("edge", edge)
        ]
        
        return energies.max(by: { $0.1 < $1.1 })?.0
    }
}
