//
//  TarotCardSelector.swift
//  Cosmic Fit
//
//  FINAL CORRECTED VERSION - Hard-block cooldown filtering with VibeBreakdown fix
//

import Foundation

/// Main engine for selecting Tarot cards that align with daily vibe energy
class TarotCardSelector {
    
    // MARK: - Properties
    
    private static var tarotDeck: [TarotCard] = []
    private static var isLoaded = false
    
    // MARK: - Public Methods
    
    /// Select the most aligned Tarot card for the day's energy
    /// - Parameters:
    ///   - tokens: StyleTokens from SemanticTokenGenerator
    ///   - theme: Optional CompositeTheme name for additional context
    ///   - vibeBreakdown: Optional VibeBreakdown for energy alignment
    ///   - seed: Optional daily seed for deterministic variation
    ///   - profileHash: User profile identifier for recency tracking
    /// - Returns: The best matching TarotCard or nil if no good match
    static func selectCard(
        for tokens: [StyleToken],
        theme: String? = nil,
        vibeBreakdown: VibeBreakdown? = nil,
        derivedAxes: DerivedAxes,
        seed: Int? = nil,
        profileHash: String? = nil
    ) -> TarotCard? {
        
        print("\n🔮 TAROT CARD SELECTION 🔮")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Load deck if needed
        loadTarotDeckIfNeeded()
        
        guard !tarotDeck.isEmpty else {
            print("❌ Failed to load Tarot deck")
            return nil
        }
        
        print("📊 Input Analysis:")
        print("  • Tokens: \(tokens.count)")
        if let theme = theme {
            print("  • Theme: \(theme)")
        }
        if let vibeBreakdown = vibeBreakdown {
            print("  • Dominant Energy: \(vibeBreakdown.dominantEnergy ?? "Unknown")")
        }
        if let seed = seed {
            print("  • Daily Seed: \(seed)")
        }
        if let profileId = profileHash {
            print("  • Profile Hash: \(profileId.prefix(8))...")
            
            // Migrate old storage if needed
            TarotRecencyTracker.shared.migrateOldStorage(profileHash: profileId)
            
            // Show recent history
            TarotRecencyTracker.shared.debugShowHistory(profileHash: profileId)
            
            // Clean up old entries
            TarotRecencyTracker.shared.cleanupOldEntries(profileHash: profileId)
        }
        
        print("  • Derived Axes:")
        print("      Action: \(String(format: "%.1f", derivedAxes.action))/10")
        print("      Tempo: \(String(format: "%.1f", derivedAxes.tempo))/10")
        print("      Strategy: \(String(format: "%.1f", derivedAxes.strategy))/10")
        print("      Visibility: \(String(format: "%.1f", derivedAxes.visibility))/10")
        
        // Apply daily seed variation if provided
        var deckToScore = tarotDeck
        if let dailySeed = seed {
            deckToScore = tarotDeck.shuffled(seed: dailySeed)
            print("  • Applied daily shuffle (seed: \(dailySeed))")
        }
        
        // Calculate scores for all cards
        let scoredCards = calculateCardScores(
            tokens: tokens,
            theme: theme,
            vibeBreakdown: vibeBreakdown,
            derivedAxes: derivedAxes,
            profileHash: profileHash,
            deck: deckToScore
        )
        
        // Apply seed-based tie-breaking for cards with similar scores
        let tiebrokenCards = applySeedTieBreaking(scoredCards: scoredCards, seed: seed)
        
        // CRITICAL: Apply 3-day hard-block filtering BEFORE final selection
        let filteredCards = applyRecencyCooldown(
            scoredCards: tiebrokenCards,
            profileHash: profileHash
        )
        
        // Debug: Show top scoring cards after filtering
        let topCards = filteredCards.prefix(5)
        print("\n🏆 Top 5 Scoring Cards (after cooldown filtering):")
        for (index, (card, score)) in topCards.enumerated() {
            print("  \(index + 1). \(card.displayName) - Score: \(String(format: "%.2f", score)) (\(card.category))")
        }
        
        // Select the best card
        guard let bestCard = filteredCards.first?.0, filteredCards.first?.1 ?? 0 > 0 else {
            print("❌ No suitable card found (all scores were 0)")
            return getFallbackCard(for: vibeBreakdown)
        }
        
        let bestScore = filteredCards.first?.1 ?? 0
        print("\n✨ Selected Card: \(bestCard.displayName)")
        print("  • Category: \(bestCard.category)")
        print("  • Score: \(String(format: "%.2f", bestScore))")
        print("  • Keywords: \(bestCard.keywords.prefix(5).joined(separator: ", "))")
        if let dominantEnergy = bestCard.dominantEnergy {
            print("  • Dominant Energy: \(dominantEnergy)")
        }
        
        // Show match analysis
        analyzeCardMatch(card: bestCard, tokens: tokens, vibeBreakdown: vibeBreakdown, derivedAxes: derivedAxes)

        // Store selected card using recency tracker
        if let profileId = profileHash {
            TarotRecencyTracker.shared.storeCardSelection(
                bestCard.name,
                profileHash: profileId,
                date: Date()
            )
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return bestCard
    }
    
    // MARK: - Recency Cooldown Filtering
    
    /// Apply 3-day hard-block filtering to prevent recent card repetition
    /// - Parameters:
    ///   - scoredCards: Array of (TarotCard, Score) tuples sorted by score
    ///   - profileHash: User profile identifier for recency tracking
    /// - Returns: Filtered array with recent cards removed or penalised
    private static func applyRecencyCooldown(
        scoredCards: [(TarotCard, Double)],
        profileHash: String?
    ) -> [(TarotCard, Double)] {
        
        guard let profileId = profileHash else {
            // No profile tracking, return as-is
            return scoredCards
        }
        
        print("\n🚫 APPLYING 3-DAY COOLDOWN FILTER")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Get cards within 3-day cooldown period
        let cooldownCards = TarotRecencyTracker.shared.getCooldownCards(profileHash: profileId)
        
        // Get yesterday's card specifically for steep penalty
        let yesterdayCard = TarotRecencyTracker.shared.getYesterdayCard(profileHash: profileId)
        
        // Filter out cards in cooldown period
        var availableCards = scoredCards.filter { card, _ in
            !cooldownCards.contains(card.name)
        }
        
        print("  • Total candidates: \(scoredCards.count)")
        print("  • Blocked by cooldown: \(cooldownCards.count)")
        print("  • Available after filtering: \(availableCards.count)")
        
        // If ALL cards are in cooldown (edge case), apply steep penalty to yesterday's card only
        if availableCards.isEmpty {
            print("  ⚠️ ALL cards in cooldown - applying steep penalty to yesterday's card")
            
            availableCards = scoredCards.map { card, score in
                if let yesterday = yesterdayCard, card.name.lowercased() == yesterday.lowercased() {
                    let penalisedScore = score * 0.2  // 80% penalty
                    print("     • Penalising '\(card.name)': \(String(format: "%.2f", score)) → \(String(format: "%.2f", penalisedScore))")
                    return (card, penalisedScore)
                }
                return (card, score)
            }
            
            // Re-sort after penalty
            availableCards.sort { $0.1 > $1.1 }
        } else {
            print("  ✅ \(availableCards.count) cards available after cooldown filtering")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return availableCards
    }
    
    // MARK: - Seed-Based Tie Breaking

    /// Apply seed-based tie-breaking for cards with similar scores
    /// - Parameters:
    ///   - scoredCards: Array of (TarotCard, Score) tuples
    ///   - seed: Optional daily seed for tie-breaking
    /// - Returns: Sorted array with tie-breaking applied
    private static func applySeedTieBreaking(
        scoredCards: [(TarotCard, Double)],
        seed: Int?
    ) -> [(TarotCard, Double)] {
        
        guard let dailySeed = seed else {
            // No seed provided, return as-is
            return scoredCards
        }
        
        // Define similarity threshold (cards within 10% of each other are "tied")
        let similarityThreshold: Double = 0.10
        
        var result: [(TarotCard, Double)] = []
        var currentGroup: [(TarotCard, Double)] = []
        
        for (card, score) in scoredCards {
            if currentGroup.isEmpty {
                currentGroup.append((card, score))
            } else {
                let groupScore = currentGroup.first!.1
                let scoreDifference = abs(score - groupScore) / max(groupScore, 0.001)
                
                if scoreDifference <= similarityThreshold {
                    // Scores are similar, add to current group
                    currentGroup.append((card, score))
                } else {
                    // Score difference is significant, process current group
                    if currentGroup.count > 1 {
                        // Multiple cards in tie - apply seed-based ordering
                        let shuffledGroup = currentGroup.shuffled(seed: dailySeed + currentGroup.count)
                        result.append(contentsOf: shuffledGroup)
                    } else {
                        result.append(contentsOf: currentGroup)
                    }
                    
                    // Start new group
                    currentGroup = [(card, score)]
                }
            }
        }
        
        // Process final group
        if currentGroup.count > 1 {
            let shuffledGroup = currentGroup.shuffled(seed: dailySeed + currentGroup.count)
            result.append(contentsOf: shuffledGroup)
        } else {
            result.append(contentsOf: currentGroup)
        }
        
        return result
    }
    
    // MARK: - Card Scoring
    
    /// Calculate scores for all cards based on tokens and energy alignment
    private static func calculateCardScores(
        tokens: [StyleToken],
        theme: String?,
        vibeBreakdown: VibeBreakdown?,
        derivedAxes: DerivedAxes,
        profileHash: String?,
        deck: [TarotCard]
    ) -> [(TarotCard, Double)] {
        
        var scoredCards: [(TarotCard, Double)] = []
        
        for card in deck {
            let score = card.calculateMatchScore(
                for: tokens,
                theme: theme,
                vibeBreakdown: vibeBreakdown,
                derivedAxes: derivedAxes,
                profileHash: profileHash
            )
            scoredCards.append((card, score))
        }
        
        // Sort by score descending
        scoredCards.sort { $0.1 > $1.1 }
        
        return scoredCards
    }
    
    /// Analyse how the selected card matches the input tokens and energy
    private static func analyzeCardMatch(
        card: TarotCard,
        tokens: [StyleToken],
        vibeBreakdown: VibeBreakdown?,
        derivedAxes: DerivedAxes
    ) {
        print("\n🔍 Match Analysis:")
        
        // Find matching tokens
        let matchingTokens = tokens.filter { token in
            card.keywords.contains { keyword in
                keyword.lowercased() == token.name.lowercased()
            }
        }
        
        if matchingTokens.isEmpty {
            print("  • No direct token matches (score from other factors)")
        } else {
            print("  • Direct token matches:")
            for token in matchingTokens.prefix(3) {
                print("     - '\(token.name)' (weight: \(String(format: "%.2f", token.weight)))")
            }
        }
        
        // Show energy alignment - FIXED: Use helper method instead of points(for:)
        if let vibe = vibeBreakdown,
           let dominantEnergy = vibe.dominantEnergy,
           let affinity = card.energyAffinity[dominantEnergy.lowercased()] {
            let alignmentPercent = affinity * 100
            let energyPoints = getEnergyPoints(from: vibe, for: dominantEnergy)
            print("  • Energy Alignment: \(dominantEnergy)(\(energyPoints)pts, \(String(format: "%.0f", alignmentPercent))%)")
        }
        
        // Show card strengths
        let topEnergies = card.energyAffinity
            .sorted { $0.value > $1.value }
            .prefix(2)
        
        if !topEnergies.isEmpty {
            print("  • Card Strengths:", terminator: "")
            for (energy, affinity) in topEnergies {
                print(" \(energy)(\(String(format: "%.1f", affinity)))", terminator: "")
            }
            print()
        }
        
        if let cardAxes = card.axesAffinity {
            print("  • Axes Affinity:")
            print("      Card axes (0-100 scale):")
            print("        Action: \(String(format: "%.0f", cardAxes["action"] ?? 50))")
            print("        Tempo: \(String(format: "%.0f", cardAxes["tempo"] ?? 50))")
            print("        Strategy: \(String(format: "%.0f", cardAxes["strategy"] ?? 50))")
            print("        Visibility: \(String(format: "%.0f", cardAxes["visibility"] ?? 50))")
            print("      Derived axes (1-10 scale):")
            print("        Action: \(String(format: "%.1f", derivedAxes.action))")
            print("        Tempo: \(String(format: "%.1f", derivedAxes.tempo))")
            print("        Strategy: \(String(format: "%.1f", derivedAxes.strategy))")
            print("        Visibility: \(String(format: "%.1f", derivedAxes.visibility))")
        } else {
            print("  • No axes affinity data for this card")
        }
        
        // Show energy alignment
        if let vibe = vibeBreakdown {
            let alignedEnergies = card.energyAffinity.filter { $0.value >= 0.6 }
                .map { energy, affinity in
                    let points = getEnergyPoints(from: vibe, for: energy)
                    return "\(energy)(\(points)pts, \(String(format: "%.1f", affinity)))"
                }
            
            if !alignedEnergies.isEmpty {
                print("  • Energy Alignment: \(alignedEnergies.joined(separator: ", "))")
            }
        }
    }
    
    /// Helper method to get energy points from VibeBreakdown
    /// ADDED TO FIX: Value of type 'VibeBreakdown' has no member 'points'
    private static func getEnergyPoints(from vibe: VibeBreakdown, for energy: String) -> Int {
        switch energy.lowercased() {
        case "classic": return vibe.classic
        case "playful": return vibe.playful
        case "romantic": return vibe.romantic
        case "utility": return vibe.utility
        case "drama": return vibe.drama
        case "edge": return vibe.edge
        default: return 0
        }
    }
    
    /// Get a fallback card when no good match is found
    private static func getFallbackCard(for vibeBreakdown: VibeBreakdown?) -> TarotCard? {
        // Try to match dominant energy
        if let vibe = vibeBreakdown,
           let dominantEnergy = vibe.dominantEnergy {
            
            let energyMatchedCards = tarotDeck.filter { card in
                (card.energyAffinity[dominantEnergy.lowercased()] ?? 0) > 0.6
            }
            
            if !energyMatchedCards.isEmpty {
                return energyMatchedCards.randomElement()
            }
        }
        
        // Ultimate fallback: The Fool (new beginnings)
        return tarotDeck.first { $0.name == "The Fool" } ?? tarotDeck.first
    }
    
    // MARK: - Deck Loading
    
    private static func loadTarotDeckIfNeeded() {
        guard !isLoaded else { return }
        
        print("\n🔍 TAROT JSON VALIDATION 🔍")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        guard let jsonPath = Bundle.main.path(forResource: "TarotCards", ofType: "json") else {
            print("❌ TarotCards.json not found in bundle")
            return
        }
        
        print("✅ Found TarotCards.json at: \(jsonPath)")
        
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
            print("✅ Read \(jsonData.count) bytes from JSON file")
            
            let decoder = JSONDecoder()
            tarotDeck = try decoder.decode([TarotCard].self, from: jsonData)
            
            print("✅ Successfully decoded \(tarotDeck.count) Tarot cards")
            let majorCount = tarotDeck.filter { $0.arcana == .major }.count
            let minorCount = tarotDeck.filter { $0.arcana == .minor }.count
            print("  • Major Arcana: \(majorCount)")
            print("  • Minor Arcana: \(minorCount)")
            
            isLoaded = true
            
        } catch {
            print("❌ Failed to decode Tarot cards: \(error)")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
}
