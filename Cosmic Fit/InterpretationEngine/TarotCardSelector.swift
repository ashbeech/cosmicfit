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
    
    /// PHASE 2: Select tarot card using multi-stage filtering and scoring
    /// Stage 1: Filter by axis similarity floor
    /// Stage 2: Score with axes (60%) + vibes (25%) + boosts (15%)
    /// Stage 3: Tie-break by axis similarity if scores within epsilon
    /// - Parameters:
    ///   - tokens: StyleTokens from SemanticTokenGenerator (kept for compatibility)
    ///   - theme: Optional CompositeTheme name for additional context (kept for compatibility)
    ///   - vibeBreakdown: VibeBreakdown for energy alignment
    ///   - derivedAxes: Derived axes (primary driver in Phase 2)
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
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎴 TAROT SELECTION - PHASE 2")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Load deck if needed
        loadTarotDeckIfNeeded()
        
        guard !tarotDeck.isEmpty else {
            print("❌ Failed to load Tarot deck")
            return nil
        }
        
        #if DEBUG
        print("📊 Day Profile:")
        print("   Axes: A:\(String(format: "%.1f", derivedAxes.action)) " +
              "T:\(String(format: "%.1f", derivedAxes.tempo)) " +
              "S:\(String(format: "%.1f", derivedAxes.strategy)) " +
              "V:\(String(format: "%.1f", derivedAxes.visibility))")
        if let vibes = vibeBreakdown {
            // Use the unambiguous enum-based property
            let dom: Energy = vibes.dominantEnergy
            let domName = dom.rawValue
            let domValue = vibes.value(for: dom)
            print("   Dominant Vibe: \(domName) (\(domValue)/21)")
        }
        #endif
        
        // Manage recency tracking
        if let profileId = profileHash {
            TarotRecencyTracker.shared.migrateOldStorage(profileHash: profileId)
            TarotRecencyTracker.shared.debugShowHistory(profileHash: profileId)
            TarotRecencyTracker.shared.cleanupOldEntries(profileHash: profileId)
        }
        
        // STAGE 1: VIBE-ADAPTIVE AXIS FILTERING
        // CRITICAL: Cards with strong vibe alignment get relaxed axis requirements
        // This allows romantic/emotional cards (which often have lower axes) to pass through
        print("🚪 Stage 1: Vibe-Adaptive Axis Filter")
        
        let baseAxisFloor = EngineConfig.axisFloorBase
        let passedFilter: [(TarotCard, Double)]
        
        if EngineConfig.enableVibeAdaptiveFiltering, let vibes = vibeBreakdown {
            passedFilter = tarotDeck.compactMap { card -> (TarotCard, Double)? in
                let axisSimilarity = calculateAxisSimilarity(card: card, dayAxes: derivedAxes)
                let vibeAlignment = calculateEnhancedVibeAlignment(card: card, vibes: vibes)
                
                // Calculate adaptive axis floor based on vibe alignment
                // Strong vibe match → much lower axis requirement
                // Medium vibe match → slightly lower axis requirement
                // Weak vibe match → standard axis requirement
                let adaptiveFloor: Double
                if vibeAlignment >= EngineConfig.vibeAdaptiveStrongThreshold {
                    // Strong vibe: reduce floor significantly
                    adaptiveFloor = max(EngineConfig.axisFloorMinimum, 
                                       baseAxisFloor - EngineConfig.vibeAdaptiveStrongReduction)
                } else if vibeAlignment >= EngineConfig.vibeAdaptiveMediumThreshold {
                    // Medium vibe: reduce floor moderately
                    adaptiveFloor = max(EngineConfig.axisFloorMinimum, 
                                       baseAxisFloor - EngineConfig.vibeAdaptiveMediumReduction)
                } else {
                    // Weak vibe: use standard floor
                    adaptiveFloor = baseAxisFloor
                }
                
                if axisSimilarity >= adaptiveFloor {
                    #if DEBUG
                    if adaptiveFloor < baseAxisFloor {
                        print("      🎭 \(card.displayName): vibe \(String(format: "%.2f", vibeAlignment)) → floor \(String(format: "%.2f", adaptiveFloor))")
                    }
                    #endif
                    return (card, axisSimilarity)
                }
                return nil
            }
            
            print("   Cards passed adaptive filter: \(passedFilter.count)/\(tarotDeck.count)")
            
        } else {
            // No vibe breakdown or adaptive filtering disabled: use standard axis filter
            passedFilter = tarotDeck.compactMap { card in
                let similarity = calculateAxisSimilarity(card: card, dayAxes: derivedAxes)
                return similarity >= baseAxisFloor ? (card, similarity) : nil
            }
            
            print("   Cards passed standard axis filter: \(passedFilter.count)/\(tarotDeck.count)")
        }
        
        // Fallback if filter too strict (eliminated all cards)
        guard !passedFilter.isEmpty else {
            print("   ⚠️ WARNING: Adaptive filter eliminated all cards, using fallback selection")
            return selectCardFallback(vibes: vibeBreakdown, profileHash: profileHash)
        }
        
        // STAGE 2: SCORE WITH VIBE (50%) + AXES (35%) + BOOSTS (15%)
        print("🎯 Stage 2: Multi-Factor Scoring (Vibe: 50%, Axes: 35%, Boost: 15%)")
        
        // Fetch recency data ONCE for all cards (avoid N duplicate queries)
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(profileHash: profileHash ?? "")
        
        let scored = passedFilter.map { (card, axisSimilarity) -> (TarotCard, Double, ScoreBreakdown) in
            // Use multi-factor scoring with NEW distribution
            let scores = calculateMultiFactorScore(
                card: card,
                axes: derivedAxes,
                vibeBreakdown: vibeBreakdown,
                tokens: tokens
            )
            
            let recencyPenalty = calculateRecencyPenalty(card: card, recentSelections: recentSelections)
            
            let totalScore = scores.total - recencyPenalty
            
            let breakdown = ScoreBreakdown(
                axisSimilarity: axisSimilarity,
                axisScore: scores.axis,
                vibeScore: scores.vibe,
                boostScore: scores.boost,
                recencyPenalty: recencyPenalty,
                totalScore: totalScore
            )
            
            return (card, totalScore, breakdown)
        }
        
        // Add axis-based randomization for close scores to increase variety
        let randomizedScored: [(TarotCard, Double, ScoreBreakdown)]
        if let seed = seed {
            randomizedScored = addAxisBasedRandomization(
                scoredCards: scored,
                axes: derivedAxes,
                seed: seed
            )
        } else {
            randomizedScored = scored
        }
        
        // Sort by score descending
        let sortedScored = randomizedScored.sorted { $0.1 > $1.1 }
        
        // Log top 5 candidates with NEW weight breakdown
        print("   Top 5 candidates:")
        for (index, (card, score, breakdown)) in sortedScored.prefix(5).enumerated() {
            print("   \(index + 1). \(card.displayName) - Total: \(String(format: "%.2f", score))")
            print("      Vibe: \(String(format: "%.2f", breakdown.vibeScore)) (50%) | " +
                  "Axis: \(String(format: "%.2f", breakdown.axisScore)) (35%) | " +
                  "Boost: \(String(format: "%.2f", breakdown.boostScore)) (15%) | " +
                  "Recency: -\(String(format: "%.2f", breakdown.recencyPenalty))")
        }
        
        // STAGE 3: VIBE-FIRST TIE-BREAKING
        // When scores are close, prioritize: vibe → dominant energy match → axes
        print("🏆 Stage 3: Vibe-First Tie-Breaking")
        
        let epsilon = EngineConfig.tarotTieBreakEpsilon
        let maxScore = sortedScored[0].1
        
        let winner: TarotCard
        
        if EngineConfig.enableVibeFirstTieBreaking && vibeBreakdown != nil {
            // Sort with vibe-first priority
            let vibeRanked = sortedScored.sorted { a, b in
                let (cardA, totalA, breakdownA) = a
                let (cardB, totalB, breakdownB) = b
                
                // 1. If total scores differ significantly, use total score
                if abs(totalA - totalB) > epsilon {
                    return totalA > totalB
                }
                
                // 2. Scores within epsilon: prefer higher vibe score
                if abs(breakdownA.vibeScore - breakdownB.vibeScore) > 0.05 {
                    return breakdownA.vibeScore > breakdownB.vibeScore
                }
                
                // 3. Still tied on vibe: prefer card with better dominant energy match
                let domMatchA = calculateDominantEnergyMatch(card: cardA, vibes: vibeBreakdown)
                let domMatchB = calculateDominantEnergyMatch(card: cardB, vibes: vibeBreakdown)
                if abs(domMatchA - domMatchB) > 0.1 {
                    return domMatchA > domMatchB
                }
                
                // 4. Last resort: use axis score
                return breakdownA.axisScore > breakdownB.axisScore
            }
            
            let topCards = vibeRanked.filter { abs($0.1 - maxScore) < epsilon }
            print("   Cards within epsilon (\(epsilon)): \(topCards.count)")
            
            if topCards.count > 1 {
                print("   Tie-break sequence: vibe → dominant energy → axes")
                #if DEBUG
                for (index, (card, _, breakdown)) in topCards.prefix(3).enumerated() {
                    let domMatch = calculateDominantEnergyMatch(card: card, vibes: vibeBreakdown)
                    print("      \(index + 1). \(card.displayName): vibe \(String(format: "%.2f", breakdown.vibeScore)), dom \(String(format: "%.2f", domMatch)), axis \(String(format: "%.2f", breakdown.axisScore))")
                }
                #endif
            }
            
            winner = vibeRanked.first?.0 ?? sortedScored.first!.0
            
        } else {
            // Fallback: use standard selection (highest score)
            let topCards = sortedScored.filter { abs($0.1 - maxScore) < epsilon }
            print("   Cards within epsilon (\(epsilon)): \(topCards.count)")
            
            if topCards.count > 1 {
                // Add small randomization based on axis similarity as before
                let randomizedTop = addAxisBasedRandomization(
                    scoredCards: Array(topCards),
                    axes: derivedAxes,
                    seed: seed ?? 0
                )
                winner = randomizedTop.sorted { $0.1 > $1.1 }.first?.0 ?? topCards.first!.0
            } else {
                winner = topCards.first?.0 ?? sortedScored.first!.0
            }
        }
        
        print("   Winner: \(winner.displayName)")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Store selected card
        if let profileId = profileHash {
            TarotRecencyTracker.shared.storeCardSelection(
                winner.name,
                profileHash: profileId,
                date: Date()
            )
        }
        
        // Log selection process for monitoring and analysis
        let topCandidatesForMonitoring = sortedScored.prefix(10).map { card, score, breakdown in
            (card, score, breakdown.axisScore, breakdown.vibeScore, breakdown.boostScore)
        }
        TarotSelectionMonitor.logSelectionProcess(
            selectedCard: winner,
            topCandidates: topCandidatesForMonitoring,
            axes: derivedAxes,
            vibeBreakdown: vibeBreakdown,
            date: Date()
        )
        
        // Track selection pattern
        TarotSelectionMonitor.trackSelectionPattern(
            card: winner,
            profileId: profileHash ?? "unknown"
        )
        
        // Show match analysis
        analyzeCardMatch(card: winner, tokens: tokens, vibeBreakdown: vibeBreakdown, derivedAxes: derivedAxes)
        
        return winner
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
    
    // MARK: - Phase 2: Score Breakdown Helper
    
    private struct ScoreBreakdown {
        let axisSimilarity: Double  // 0-1
        let axisScore: Double       // 0-60
        let vibeScore: Double       // 0-25
        let boostScore: Double      // typically 0-3
        let recencyPenalty: Double  // 0-10
        let totalScore: Double
    }
    
    // MARK: - Phase 2: Fallback Selection
    
    /// Fallback selection if axis filter is too strict
    /// Uses vibe alignment only (no axis filtering)
    private static func selectCardFallback(
        vibes: VibeBreakdown?,
        profileHash: String?
    ) -> TarotCard? {
        // Fetch recency data once
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(profileHash: profileHash ?? "")
        
        let scored = tarotDeck.map { card -> (TarotCard, Double) in
            let vibeScore = calculateVibeAlignment(card: card, vibes: vibes) * 100.0
            let recencyPenalty = calculateRecencyPenalty(card: card, recentSelections: recentSelections)
            return (card, vibeScore - recencyPenalty)
        }
        
        let sorted = scored.sorted { $0.1 > $1.1 }
        return sorted.first?.0
    }
    
    // MARK: - Phase 2: Multi-Factor Scoring (CORRECTED WEIGHTS)
    
    /// Calculate multi-factor score with CORRECTED distribution: 35% axis, 50% vibe, 15% token boost
    /// NEW APPROACH: Vibe-driven selection with axes as secondary consideration
    /// - Parameters:
    ///   - card: The tarot card to score
    ///   - axes: Derived axes for the day
    ///   - vibeBreakdown: Vibe breakdown for energy alignment (NOW PRIMARY DRIVER)
    ///   - tokens: Style tokens for keyword matching
    /// - Returns: Tuple with total score and component scores
    private static func calculateMultiFactorScore(
        card: TarotCard,
        axes: DerivedAxes,
        vibeBreakdown: VibeBreakdown?,
        tokens: [StyleToken]
    ) -> (total: Double, axis: Double, vibe: Double, boost: Double) {
        
        // 1. Axis similarity (NOW 35% of total score - secondary consideration)
        let axisSimilarity = calculateAxisSimilarity(card: card, dayAxes: axes)
        let axisScore = axisSimilarity * EngineConfig.tarotAxisWeight
        
        // 2. Vibe alignment (NOW 50% of total score - PRIMARY DRIVER)
        let vibeAlignment = calculateEnhancedVibeAlignment(card: card, vibes: vibeBreakdown)
        let vibeScore = vibeAlignment * EngineConfig.tarotVibeWeight
        
        // 3. Token boost (15% of total score - unchanged)
        let tokenBoost = calculateTokenBoosts(card: card, tokens: tokens, dayAxes: axes)
        let boostScore = tokenBoost * EngineConfig.tarotTokenBoostWeight
        
        let totalScore = axisScore + vibeScore + boostScore
        
        #if DEBUG
        // Log pre-normalization values for debugging saturation
        if vibeAlignment > 0.8 {
            print("      ⚠️ High vibe alignment: \(String(format: "%.2f", vibeAlignment)) for \(card.displayName)")
        }
        #endif
        
        return (total: totalScore, axis: axisScore, vibe: vibeScore, boost: boostScore)
    }
    
    // MARK: - Phase 2: Axis Similarity Calculation
    
    /// Calculate how similar a card's axes are to the day's axes
    /// Returns 0.0-1.0 where 1.0 = perfect match
    /// Uses Euclidean distance in 4D space (Action, Tempo, Strategy, Visibility)
    private static func calculateAxisSimilarity(
        card: TarotCard,
        dayAxes: DerivedAxes
    ) -> Double {
        // Normalize card axes from 0-100 scale to 1-10 scale to match dayAxes
        let cardAction = card.axes.action / 10.0
        let cardTempo = card.axes.tempo / 10.0
        let cardStrategy = card.axes.strategy / 10.0
        let cardVisibility = card.axes.visibility / 10.0
        
        // Calculate Euclidean distance in 4D space
        let actionDiff = dayAxes.action - cardAction
        let tempoDiff = dayAxes.tempo - cardTempo
        let strategyDiff = dayAxes.strategy - cardStrategy
        let visibilityDiff = dayAxes.visibility - cardVisibility
        
        let distance = sqrt(
            pow(actionDiff, 2) +
            pow(tempoDiff, 2) +
            pow(strategyDiff, 2) +
            pow(visibilityDiff, 2)
        )
        
        // Convert distance to similarity score
        // Maximum possible distance in 4D space with range 1-10 is sqrt(4 * 81) ≈ 18
        let maxDistance = sqrt(4 * pow(9.0, 2))  // 18.0
        let similarity = 1.0 - (distance / maxDistance)
        
        // Clamp to 0-1 range
        return max(0.0, min(1.0, similarity))
    }
    
    /// Determine axis similarity floor based on day's kinetic energy
    /// Higher floor on very kinetic days (prevents static cards from being selected)
    private static func calculateAxisFloor(for dayAxes: DerivedAxes) -> Double {
        // Calculate kinetic score (average of Action and Tempo)
        let kineticScore = (dayAxes.action + dayAxes.tempo) / 2.0
        
        // Higher kinetic energy = stricter filter
        if kineticScore >= 8.0 {
            return 0.60  // Very kinetic: strict filter
        } else if kineticScore >= 6.5 {
            return 0.50  // Moderately kinetic: medium filter
        } else if kineticScore <= 3.5 {
            return 0.60  // Very static: also strict (no kinetic cards on calm days)
        } else {
            return 0.40  // Neutral: relaxed filter
        }
    }
    
    // MARK: - Phase 2: Suit & Archetype Boosts
    
    /// Calculate suit-aware boost based on day's axes
    /// Returns bonus points (typically 0-3 points) to add to card's score
    private static func calculateSuitBoost(
        card: TarotCard,
        dayAxes: DerivedAxes
    ) -> Double {
        var boost: Double = 0.0
        
        // KINETIC ENERGY (Action + Tempo)
        let kineticScore = (dayAxes.action + dayAxes.tempo) / 2.0
        
        if kineticScore >= 7.0 {
            // High kinetic days favor Wands (action) and Swords (mental speed)
            switch card.suitString {
            case "Wands":
                boost += 2.0  // Strongest boost for fire/action suit
            case "Swords":
                boost += 1.5  // Strong boost for air/mental suit
            case "Pentacles":
                boost -= 1.0  // Penalize earth/stability suit
            case "Cups":
                boost -= 0.5  // Slight penalty for water/emotion suit
            case "Major Arcana":
                boost += 0.0  // Neutral (handled separately below)
            default:
                break
            }
        } else if kineticScore <= 3.5 {
            // Low kinetic days favor Pentacles (grounded) and Cups (receptive)
            switch card.suitString {
            case "Pentacles":
                boost += 2.0  // Strongest boost for stability
            case "Cups":
                boost += 1.5  // Strong boost for receptivity
            case "Wands":
                boost -= 1.0  // Penalize high-action suit
            case "Swords":
                boost -= 0.5  // Slight penalty for mental speed
            case "Major Arcana":
                boost += 0.0  // Neutral
            default:
                break
            }
        }
        
        // STRATEGY (Structure vs Spontaneity)
        if dayAxes.strategy >= 7.5 {
            // High strategy days favor:
            // - Major Arcana (structured archetypes)
            // - Court cards (deliberate roles)
            // - Pentacles (practical planning)
            if card.suitString == "Major Arcana" {
                boost += 1.0
            }
            if card.isCourtCard {
                boost += 0.5
            }
            if card.suitString == "Pentacles" {
                boost += 0.5
            }
        } else if dayAxes.strategy <= 3.5 {
            // Low strategy (spontaneous) days favor:
            // - Aces (new beginnings, unplanned)
            // - Pages (exploration, curiosity)
            // - Wands (impulsive action)
            if card.rank == "Ace" {
                boost += 1.0
            }
            if card.rank == "Page" {
                boost += 0.5
            }
            if card.suitString == "Wands" {
                boost += 0.5
            }
        }
        
        // VISIBILITY (Bold vs Subtle)
        if dayAxes.visibility >= 7.5 {
            // High visibility days favor cards with public/performance themes
            let publicCards: Set<String> = [
                "The Sun", "The Star", "The World",
                "Six of Wands", "Three of Cups", "Three of Pentacles",
                "Queen of Wands", "King of Wands"
            ]
            if publicCards.contains(card.name) {
                boost += 1.5
            }
            
            // Also favor major arcana on visible days
            if card.suitString == "Major Arcana" {
                boost += 0.5
            }
        } else if dayAxes.visibility <= 3.5 {
            // Low visibility days favor introspective/private cards
            let privateCards: Set<String> = [
                "The Hermit", "The Hanged Man", "Four of Swords",
                "Nine of Pentacles", "Four of Cups", "Seven of Cups"
            ]
            if privateCards.contains(card.name) {
                boost += 1.5
            }
        }
        
        return boost
    }
    
    // MARK: - Phase 2: Vibe Alignment
    
    /// Calculate how well a card aligns with the day's dominant vibe
    /// Returns 0.0-1.0 score
    private static func calculateVibeAlignment(
        card: TarotCard,
        vibes: VibeBreakdown?
    ) -> Double {
        guard let vibes = vibes else { return 0.5 }
        
        // Get dominant and secondary energies (enum-based, unambiguous)
        let dominant: Energy = vibes.dominantEnergy
        let dominantValue = Double(vibes.value(for: dominant)) / 21.0  // Normalize to 0-1
        
        let secondary: Energy = vibes.secondaryEnergy
        let secondaryValue = Double(vibes.value(for: secondary)) / 21.0
        
        // Get card's strength in these energies
        let cardDominantStrength = card.energyAffinity[dominant.rawValue.lowercased()] ?? 0.0
        let cardSecondaryStrength = card.energyAffinity[secondary.rawValue.lowercased()] ?? 0.0
        
        // Calculate alignment (weighted toward dominant energy)
        let dominantAlignment = dominantValue * cardDominantStrength * 0.7
        let secondaryAlignment = secondaryValue * cardSecondaryStrength * 0.3
        
        return dominantAlignment + secondaryAlignment
    }
    
    /// Enhanced vibe alignment with DOMINANT ENERGY EMPHASIS
    /// Returns 0.0-1.0 score with heavy weighting toward dominant energy match
    /// Uses 60/25/15 split for dominant/secondary/tertiary energy alignment
    private static func calculateEnhancedVibeAlignment(
        card: TarotCard,
        vibes: VibeBreakdown?
    ) -> Double {
        guard let vibes = vibes else { return 0.5 }
        
        // Get all six energies with their values, sorted by strength
        let energyScores: [(Energy, Int)] = Energy.allCases.map { ($0, vibes.value(for: $0)) }
        let sortedEnergies = energyScores.sorted { $0.1 > $1.1 }
        
        // Extract dominant, secondary, and tertiary
        let dominant = sortedEnergies[0]
        let secondary = sortedEnergies.count > 1 ? sortedEnergies[1] : dominant
        let tertiary = sortedEnergies.count > 2 ? sortedEnergies[2] : secondary
        
        // Normalize to 0-1 scale (divide by 21 to get share of total energy)
        let dominantValue = Double(dominant.1) / 21.0
        let secondaryValue = Double(secondary.1) / 21.0
        let tertiaryValue = Double(tertiary.1) / 21.0
        
        // Get card's affinity for these energies
        let cardDominantAffinity = card.energyAffinity[dominant.0.rawValue.lowercased()] ?? 0.0
        let cardSecondaryAffinity = card.energyAffinity[secondary.0.rawValue.lowercased()] ?? 0.0
        let cardTertiaryAffinity = card.energyAffinity[tertiary.0.rawValue.lowercased()] ?? 0.0
        
        // CRITICAL: Weight heavily toward dominant energy (60% of vibe score)
        // This ensures romantic days get romantic cards, not structural cards
        let dominantAlignment = dominantValue * cardDominantAffinity * 0.60
        let secondaryAlignment = secondaryValue * cardSecondaryAffinity * 0.25
        let tertiaryAlignment = tertiaryValue * cardTertiaryAffinity * 0.15
        
        var totalAlignment = dominantAlignment + secondaryAlignment + tertiaryAlignment
        
        // Apply dominant energy multiplier if card has strong affinity (>=0.7)
        // This gives a significant boost to cards that truly match the day's energy
        if cardDominantAffinity >= 0.7 {
            let preMultiplier = totalAlignment
            totalAlignment *= EngineConfig.dominantEnergyMultiplier
            
            #if DEBUG
            print("      ✨ Dominant energy boost for \(card.displayName): \(String(format: "%.2f", preMultiplier)) → \(String(format: "%.2f", totalAlignment))")
            #endif
        }
        
        // Clamp to 0-1 range (may saturate for perfect matches - this is intentional)
        return min(1.0, max(0.0, totalAlignment))
    }
    
    // MARK: - Phase 2: Dominant Energy Match Helper
    
    /// Calculate how well a card matches the dominant energy
    /// Used for tie-breaking when multiple cards have similar total scores
    /// - Parameters:
    ///   - card: The tarot card to evaluate
    ///   - vibes: The vibe breakdown containing dominant energy
    /// - Returns: Card's affinity for the dominant energy (0.0-1.0)
    private static func calculateDominantEnergyMatch(
        card: TarotCard,
        vibes: VibeBreakdown?
    ) -> Double {
        guard let vibes = vibes else { return 0.0 }
        let dominant: Energy = vibes.dominantEnergy
        return card.energyAffinity[dominant.rawValue.lowercased()] ?? 0.0
    }
    
    /// Get card's affinity for specific vibe energy (0.0-2.0 scale)
    private static func getCardVibeAffinity(_ card: TarotCard, energy: String) -> Double {
        switch (card.displayName, energy) {
        // Major Arcana affinities
        case ("The Emperor", "classic"): return 2.0
        case ("The Emperor", "utility"): return 1.8
        case ("The Emperor", "drama"): return 0.8
        case ("The Magician", "classic"): return 1.5
        case ("The Magician", "drama"): return 1.2
        case ("The Magician", "edge"): return 1.0
        case ("The High Priestess", "romantic"): return 1.8
        case ("The High Priestess", "classic"): return 1.5
        case ("The Fool", "playful"): return 2.0
        case ("The Fool", "edge"): return 1.3
            
        // Court Cards affinities
        case (let name, "classic") where name.contains("King"): return 1.8
        case (let name, "utility") where name.contains("King"): return 1.5
        case (let name, "playful") where name.contains("Page"): return 1.8
        case (let name, "romantic") where name.contains("Queen"): return 1.6
        case (let name, "edge") where name.contains("Knight"): return 1.4
            
        // Suit-based affinities
        case (let name, "utility") where name.contains("Pentacles"): return 1.5
        case (let name, "drama") where name.contains("Swords"): return 1.3
        case (let name, "romantic") where name.contains("Cups"): return 1.4
        case (let name, "playful") where name.contains("Wands"): return 1.2
            
        default:
            // Use card's energyAffinity dictionary as fallback
            return card.energyAffinity[energy.lowercased()] ?? 0.8 // Default moderate affinity
        }
    }
    
    /// Calculate token boosts combining suit boost and token keyword matching
    /// Returns 0.0-1.0 score for normalization
    private static func calculateTokenBoosts(
        card: TarotCard,
        tokens: [StyleToken],
        dayAxes: DerivedAxes
    ) -> Double {
        // 1. Suit boost (0-3 points, normalized to 0-1)
        let suitBoost = calculateSuitBoost(card: card, dayAxes: dayAxes) / 3.0
        
        // 2. Token keyword matching (0-1 scale)
        let tokenMatchScore = calculateTokenKeywordMatch(card: card, tokens: tokens)
        
        // Combine: 60% suit boost, 40% token matching
        return (suitBoost * 0.6) + (tokenMatchScore * 0.4)
    }
    
    /// Calculate how well card keywords match style tokens
    /// Returns 0.0-1.0 score
    private static func calculateTokenKeywordMatch(
        card: TarotCard,
        tokens: [StyleToken]
    ) -> Double {
        guard !tokens.isEmpty else { return 0.5 }
        
        let cardKeywords = Set(card.keywords.map { $0.lowercased() })
        let tokenNames = Set(tokens.map { $0.name.lowercased() })
        
        // Count matching keywords (weighted by token weight)
        var matchScore: Double = 0.0
        var totalWeight: Double = 0.0
        
        for token in tokens {
            let tokenName = token.name.lowercased()
            totalWeight += token.weight
            
            if cardKeywords.contains(tokenName) {
                matchScore += token.weight
            }
        }
        
        // Normalize by total weight
        return totalWeight > 0 ? matchScore / totalWeight : 0.0
    }
    
    // MARK: - Phase 2: Recency Penalty
    
    /// Calculate penalty for recently used cards
    /// Returns penalty points to SUBTRACT from score (0-100 points)
    /// - Parameters:
    ///   - card: The tarot card to check
    ///   - recentSelections: Pre-fetched recent selections (pass empty array if no tracking)
    private static func calculateRecencyPenalty(
        card: TarotCard,
        recentSelections: [(cardName: String, daysAgo: Int)]
    ) -> Double {
        // Find this card in recent selections
        if let recentUse = recentSelections.first(where: { $0.cardName.lowercased() == card.name.lowercased() }) {
            let daysSinceUsed = recentUse.daysAgo
            
            // Graduated penalty based on recency
            if daysSinceUsed == 0 {
                return 100.0  // Massive penalty for same-day reuse
            } else if daysSinceUsed == 1 {
                return 50.0   // Strong penalty for next-day reuse
            } else if daysSinceUsed == 2 {
                return 20.0   // Medium penalty
            } else if daysSinceUsed == 3 {
                return 10.0   // Light penalty
            }
        }
        
        return 0.0  // No penalty after 3+ days or not found
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
        
        // Show energy alignment - FIXED: Use enum-based API
        if let vibe = vibeBreakdown {
            let dominantVibeEnergy: Energy = vibe.dominantEnergy
            let dominantVibeEnergyName = dominantVibeEnergy.rawValue
            if let affinity = card.energyAffinity[dominantVibeEnergyName.lowercased()] {
                let alignmentPercent = affinity * 100
                let energyPoints = vibe.value(for: dominantVibeEnergy)
                print("  • Energy Alignment: \(dominantVibeEnergyName)(\(energyPoints)pts, \(String(format: "%.0f", alignmentPercent))%)")
            }
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
                    let points = vibe.value(for: energy)  // Use the String-based bridging method
                    return "\(energy)(\(points)pts, \(String(format: "%.1f", affinity)))"
                }
            
            if !alignedEnergies.isEmpty {
                print("  • Energy Alignment: \(alignedEnergies.joined(separator: ", "))")
            }
        }
    }
    
    // MARK: - Helper removed (now redundant)
    // The getEnergyPoints helper has been replaced by VibeBreakdown.value(for:) enum-based method
    
    /// Add axis-based randomization for close scores to break ties
    /// Adds small axis-dependent variation to scores for cards with similar axis alignments
    /// - Parameters:
    ///   - scoredCards: Array of (TarotCard, Score, ScoreBreakdown) tuples
    ///   - axes: Derived axes for the day (1-10 scale)
    ///   - seed: Daily seed for deterministic variation
    /// - Returns: Array with axis-based variation applied to scores
    private static func addAxisBasedRandomization(
        scoredCards: [(TarotCard, Double, ScoreBreakdown)],
        axes: DerivedAxes,
        seed: Int
    ) -> [(TarotCard, Double, ScoreBreakdown)] {
        
        return scoredCards.map { (card, score, breakdown) in
            // Calculate axis-dependent variation based on how closely card axes match day axes
            // Card axes are 0-100, day axes are 1-10
            // Use simple scaling: multiply day axes by 10 to approximate 0-100 range
            // The small multiplier (0.001) means exact scaling doesn't matter much
            let axisVariation = (
                abs(card.axes.action - axes.action * 10.0) * 0.001 +
                abs(card.axes.tempo - axes.tempo * 10.0) * 0.001 +
                abs(card.axes.strategy - axes.strategy * 10.0) * 0.001 +
                abs(card.axes.visibility - axes.visibility * 10.0) * 0.001
            ) * sin(Double(seed) * 0.1)
            
            // Add small variation to break ties (positive or negative)
            let adjustedScore = score + axisVariation
            
            return (card, adjustedScore, breakdown)
        }
    }
    
    /// Get a fallback card when no good match is found
    private static func getFallbackCard(for vibeBreakdown: VibeBreakdown?) -> TarotCard? {
        // Try to match dominant energy
        if let vibe = vibeBreakdown {
            let dominantVibeEnergy: Energy = vibe.dominantEnergy
            let dominantVibeEnergyName = dominantVibeEnergy.rawValue
            
            let energyMatchedCards = tarotDeck.filter { card in
                (card.energyAffinity[dominantVibeEnergyName.lowercased()] ?? 0) > 0.6
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
