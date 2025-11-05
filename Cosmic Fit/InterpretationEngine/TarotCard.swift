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
    let axesAffinity: [String: Double]?
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
        derivedAxes: DerivedAxes,
        profileHash: String? = nil
    ) -> Double {
        
        var score: Double = 0.0
        
        // 1. Token keyword matching (primary scoring mechanism)
        for token in tokens {
            let tokenLower = token.name.lowercased()
            
            // ✅ FIX 1: Filter out short keywords (< 4 characters) to prevent false matches
            let validKeywords = keywords.filter { $0.count >= 4 }
            
            // ✅ FIX 2: Use exact word matching instead of substring matching
            let matchingKeywords = validKeywords.filter { keyword in
                let keywordLower = keyword.lowercased()
                
                // Exact match
                if tokenLower == keywordLower {
                    return true
                }
                
                // Check if token is a word in the keyword
                if keywordLower.split(separator: " ").map(String.init).contains(tokenLower) {
                    return true
                }
                
                // Check if keyword is a word in the token
                if tokenLower.split(separator: " ").map(String.init).contains(keywordLower) {
                    return true
                }
                
                return false
            }
            
            if !matchingKeywords.isEmpty {
                // ✅ FIX 3: Add debug logging
                print("  ✅ TOKEN MATCH: '\(token.name)' (weight: \(String(format: "%.2f", token.weight))) matched keywords: \(matchingKeywords)")
                let effectiveWeight = pow(token.weight, 0.9)
                let points = effectiveWeight * 2.0
                print("     → Adding \(String(format: "%.2f", points)) points to '\(name)'")
                score += points
            }
        }
        
        // 2. Theme matching (contextual bonus)
        if let themeName = theme {
            let themeLower = themeName.lowercased()
            for cardTheme in themes {
                if cardTheme.lowercased().contains(themeLower) || themeLower.contains(cardTheme.lowercased()) {
                    print("  🎨 THEME MATCH: '\(themeName)' matched '\(cardTheme)' → +1.5 points")
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
            
            var energyScore = 0.0
            for (energyName, energyPoints) in energyMap {
                if let affinity = energyAffinity[energyName], energyPoints > 0 {
                    let energyBonus = Double(energyPoints) * affinity * 0.3
                    energyScore += energyBonus
                }
            }
            
            if energyScore > 0 {
                print("  ⚡ ENERGY ALIGNMENT: +\(String(format: "%.2f", energyScore)) points")
            }
            score += energyScore
        }
        
        //TODO: derivedAxes doesn't need to be back compatible
        // 4. Derived Axes affinity scoring
        if let axes = axesAffinity {
            let axesScore = calculateAxesSimilarity(cardAxes: axes, derivedAxes: derivedAxes)
            score += axesScore * DerivedAxesConfiguration.TarotAffinity.scoringWeight
            
            if DerivedAxesConfiguration.Debug.logTarotMatching {
                print("    🎯 Axes Similarity for \(name): \(String(format: "%.2f", axesScore)) (weighted: \(String(format: "%.2f", axesScore * DerivedAxesConfiguration.TarotAffinity.scoringWeight)))")
            }
        }
        
        // 5. Priority bonus for tie-breaking
        score += priority * 0.5
        
        /*
        // 6. Apply decay penalty based on recent selections
        if let profileId = profileHash {
            let decayMultiplier = TarotRecencyTracker.shared.calculateDecayPenalty(
                for: name,
                profileHash: profileId
            )
            
            if decayMultiplier < 1.0 {
                let penaltyPercent = (1.0 - decayMultiplier) * 100
                if DerivedAxesConfiguration.Debug.logTarotMatching {
                    print("    ⚠️ Applying \(String(format: "%.0f", penaltyPercent))% decay penalty to '\(name)'")
                }
                score *= decayMultiplier
            }
        }*/
        
        // REMOVED: Step 6 (decay penalty) - now handled by hard-block cooldown in TarotCardSelector
        
        return score
    }
    
    // MARK: - Axes Similarity Calculation (NEW)
    
    /// Calculate similarity between card's axes affinity and derived axes
    /// - Parameters:
    ///   - cardAxes: Card's axes affinity (from JSON, scaled 0-100)
    ///   - derivedAxes: Computed derived axes (scaled 1-10)
    /// - Returns: Similarity score (0-1 range, higher is better)
    private func calculateAxesSimilarity(cardAxes: [String: Double], derivedAxes: DerivedAxes) -> Double {
        // Normalize card axes from 0-100 scale to 1-10 scale
        let normalizedCardAxes = DerivedAxes(
            action: (cardAxes["action"] ?? 50.0) / 10.0,
            tempo: (cardAxes["tempo"] ?? 50.0) / 10.0,
            strategy: (cardAxes["strategy"] ?? 50.0) / 10.0,
            visibility: (cardAxes["visibility"] ?? 50.0) / 10.0
        )
        
        // Calculate Euclidean distance
        let actionDiff = derivedAxes.action - normalizedCardAxes.action
        let tempoDiff = derivedAxes.tempo - normalizedCardAxes.tempo
        let strategyDiff = derivedAxes.strategy - normalizedCardAxes.strategy
        let visibilityDiff = derivedAxes.visibility - normalizedCardAxes.visibility
        
        let distance = sqrt(
            pow(actionDiff, 2) +
            pow(tempoDiff, 2) +
            pow(strategyDiff, 2) +
            pow(visibilityDiff, 2)
        )
        
        // Convert distance to similarity score (closer = higher score)
        // Maximum possible distance is ~18 (sqrt(4 * 9^2))
        let maxDistance = DerivedAxesConfiguration.TarotAffinity.maxDistance
        let similarity = max(0.0, 1.0 - (distance / maxDistance))
        
        if DerivedAxesConfiguration.Debug.logTarotMatching {
            print("      Action: \(String(format: "%.1f", derivedAxes.action)) vs \(String(format: "%.1f", normalizedCardAxes.action)) (diff: \(String(format: "%.1f", actionDiff)))")
            print("      Tempo: \(String(format: "%.1f", derivedAxes.tempo)) vs \(String(format: "%.1f", normalizedCardAxes.tempo)) (diff: \(String(format: "%.1f", tempoDiff)))")
            print("      Strategy: \(String(format: "%.1f", derivedAxes.strategy)) vs \(String(format: "%.1f", normalizedCardAxes.strategy)) (diff: \(String(format: "%.1f", strategyDiff)))")
            print("      Visibility: \(String(format: "%.1f", derivedAxes.visibility)) vs \(String(format: "%.1f", normalizedCardAxes.visibility)) (diff: \(String(format: "%.1f", visibilityDiff)))")
            print("      Distance: \(String(format: "%.2f", distance)), Similarity: \(String(format: "%.2f", similarity))")
        }
        
        return similarity
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
