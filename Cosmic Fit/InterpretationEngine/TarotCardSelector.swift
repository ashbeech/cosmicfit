//
//  TarotCardSelector.swift
//  Cosmic Fit
//
//  Created by AI Assistant on 12/05/2025.
//  Main engine for selecting Tarot cards based on semantic tokens and themes
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
    /// - Returns: The best matching TarotCard or nil if no good match
    static func selectCard(
        for tokens: [StyleToken],
        theme: String? = nil,
        vibeBreakdown: VibeBreakdown? = nil
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
        
        // Get last selected card to avoid repetition
        let lastSelectedCard = getLastSelectedCard()
        
        // Calculate scores for all cards
        let scoredCards = calculateCardScores(tokens: tokens, theme: theme, vibeBreakdown: vibeBreakdown, lastSelectedCard: lastSelectedCard)
        
        // Debug: Show top scoring cards
        let topCards = scoredCards.prefix(5)
        print("\n🏆 Top 5 Scoring Cards:")
        for (index, (card, score)) in topCards.enumerated() {
            print("  \(index + 1). \(card.displayName) - Score: \(String(format: "%.2f", score)) (\(card.category))")
        }
        
        // Select the best card
        guard let bestCard = scoredCards.first?.0, scoredCards.first?.1 ?? 0 > 0 else {
            print("❌ No suitable card found (all scores were 0)")
            return getFallbackCard(for: vibeBreakdown)
        }
        
        let bestScore = scoredCards.first?.1 ?? 0
        print("\n✨ Selected Card: \(bestCard.displayName)")
        print("  • Category: \(bestCard.category)")
        print("  • Score: \(String(format: "%.2f", bestScore))")
        print("  • Keywords: \(bestCard.keywords.prefix(5).joined(separator: ", "))")
        if let dominantEnergy = bestCard.dominantEnergy {
            print("  • Dominant Energy: \(dominantEnergy)")
        }
        
        // Show match analysis
        analyzeCardMatch(card: bestCard, tokens: tokens, vibeBreakdown: vibeBreakdown)
        
        // Store selected card to avoid repetition
        storeLastSelectedCard(bestCard.name)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return bestCard
    }
    
    /// Get top N card suggestions for testing/comparison
    /// - Parameters:
    ///   - tokens: StyleTokens from SemanticTokenGenerator
    ///   - theme: Optional CompositeTheme name
    ///   - vibeBreakdown: Optional VibeBreakdown
    ///   - count: Number of top cards to return (default: 3)
    /// - Returns: Array of TarotCards sorted by score
    static func getTopCardSuggestions(
        for tokens: [StyleToken],
        theme: String? = nil,
        vibeBreakdown: VibeBreakdown? = nil,
        count: Int = 3
    ) -> [TarotCard] {
        
        loadTarotDeckIfNeeded()
        
        let scoredCards = calculateCardScores(tokens: tokens, theme: theme, vibeBreakdown: vibeBreakdown, lastSelectedCard: nil)
        return Array(scoredCards.prefix(count).map { $0.0 })
    }
    
    // MARK: - Private Methods
    
    /// Load the Tarot deck from JSON file
    private static func loadTarotDeckIfNeeded() {
        guard !isLoaded else { return }
        
        // Run validation first for debugging
        TarotCardValidator.validateJSONFile()
        
        // Debug: List all JSON files in the bundle
        if let bundlePath = Bundle.main.resourcePath {
            print("🔍 Bundle resource path: \(bundlePath)")
            let fileManager = FileManager.default
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                print("🔍 JSON files in bundle: \(jsonFiles)")
            } catch {
                print("❌ Could not list bundle contents: \(error)")
            }
        }
        
        guard let url = Bundle.main.url(forResource: "TarotCards", withExtension: "json") else {
            print("❌ Could not find TarotCards.json in bundle")
            
            // Try alternative approaches
            if let bundlePath = Bundle.main.resourcePath {
                let directPath = bundlePath + "/TarotCards.json"
                print("🔍 Trying direct path: \(directPath)")
                if FileManager.default.fileExists(atPath: directPath) {
                    print("✅ File exists at direct path")
                    
                    // Try to load from direct path
                    do {
                        let data = try Data(contentsOf: URL(fileURLWithPath: directPath))
                        tarotDeck = try JSONDecoder().decode([TarotCard].self, from: data)
                        isLoaded = true
                        print("✅ Loaded \(tarotDeck.count) Tarot cards from direct path")
                        return
                    } catch {
                        print("❌ Failed to load from direct path: \(error)")
                    }
                } else {
                    print("❌ File does not exist at direct path")
                }
            }
            
            // Ultimate fallback: create a minimal deck programmatically
            createFallbackDeck()
            return
        }
        
        print("✅ Found TarotCards.json at: \(url.path)")
        
        do {
            let data = try Data(contentsOf: url)
            print("✅ Successfully read \(data.count) bytes from JSON file")
            
            // Try to decode
            let decoder = JSONDecoder()
            tarotDeck = try decoder.decode([TarotCard].self, from: data)
            isLoaded = true
            print("✅ Loaded \(tarotDeck.count) Tarot cards from JSON")
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            
            // Provide more detailed error information
            switch decodingError {
            case .dataCorrupted(let context):
                print("  Data corrupted at: \(context.codingPath)")
                print("  Description: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("  Key '\(key)' not found at: \(context.codingPath)")
                print("  Description: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("  Type mismatch for \(type) at: \(context.codingPath)")
                print("  Description: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("  Value not found for \(type) at: \(context.codingPath)")
                print("  Description: \(context.debugDescription)")
            @unknown default:
                print("  Unknown decoding error")
            }
        } catch {
            print("❌ Failed to load Tarot deck: \(error)")
        }
    }
    
    /// Calculate match scores for all cards
    /// - Parameters:
    ///   - tokens: StyleTokens to match against
    ///   - theme: Optional theme for bonus scoring
    ///   - vibeBreakdown: Optional energy breakdown for alignment
    ///   - lastSelectedCard: Last selected card name to avoid repetition
    /// - Returns: Array of (TarotCard, Score) tuples sorted by score descending
    private static func calculateCardScores(
        tokens: [StyleToken],
        theme: String?,
        vibeBreakdown: VibeBreakdown?,
        lastSelectedCard: String?
    ) -> [(TarotCard, Double)] {
        
        var cardScores: [(TarotCard, Double)] = []
        
        for card in tarotDeck {
            let score = card.calculateMatchScore(for: tokens, theme: theme, vibeBreakdown: vibeBreakdown, lastSelectedCardName: lastSelectedCard)
            cardScores.append((card, score))
        }
        
        // Sort by score descending, then by priority for tie-breaking
        return cardScores.sorted { (first, second) in
            if first.1 == second.1 {
                return first.0.priority > second.0.priority
            }
            return first.1 > second.1
        }
    }
    
    /// Get a fallback card when no good matches are found
    /// - Parameter vibeBreakdown: Optional energy breakdown to guide fallback
    /// - Returns: A sensible default card
    private static func getFallbackCard(for vibeBreakdown: VibeBreakdown?) -> TarotCard? {
        // Try to find cards that match the dominant energy
        if let vibeBreakdown = vibeBreakdown,
           let dominantEnergy = vibeBreakdown.dominantEnergy {
            
            let energyCards = tarotDeck.filter { card in
                card.hasStrongAffinityFor(energy: dominantEnergy)
            }
            
            if !energyCards.isEmpty {
                print("🎯 Using energy-based fallback for \(dominantEnergy) energy")
                return energyCards.randomElement()
            }
        }
        
        // Ultimate fallback: The Fool (new beginnings, universal)
        let fallbackCard = tarotDeck.first { $0.name == "The Fool" } ?? tarotDeck.randomElement()
        print("🔄 Using universal fallback card")
        return fallbackCard
    }
    
    /// Analyze and explain why a card was selected
    /// - Parameters:
    ///   - card: The selected TarotCard
    ///   - tokens: The input StyleTokens
    ///   - vibeBreakdown: Optional VibeBreakdown
    private static func analyzeCardMatch(
        card: TarotCard,
        tokens: [StyleToken],
        vibeBreakdown: VibeBreakdown?
    ) {
        print("\n🔍 Match Analysis:")
        
        // Find token matches
        let tokenNames = Set(tokens.map { $0.name.lowercased() })
        let keywordMatches = card.keywords.filter { tokenNames.contains($0.lowercased()) }
        
        if !keywordMatches.isEmpty {
            print("  • Token Matches: \(keywordMatches.joined(separator: ", "))")
            
            // Show weights of matching tokens with dampening applied
            let matchingTokens = tokens.filter { token in
                keywordMatches.contains { keyword in
                    token.name.lowercased() == keyword.lowercased()
                }
            }
            
            if !matchingTokens.isEmpty {
                var tokenAnalysis: [String] = []
                for token in matchingTokens {
                    let originalWeight = token.weight
                    let dampenedWeight = pow(originalWeight, 0.9)
                    let hasOverride = TokenEnergyOverrides.hasCustomMapping(for: token.name)
                    let marker = hasOverride ? "🔄" : ""
                    tokenAnalysis.append("\(token.name)\(marker)(\(String(format: "%.1f", originalWeight))→\(String(format: "%.1f", dampenedWeight)))")
                }
                print("  • Token Weights: \(tokenAnalysis.joined(separator: ", "))")
                print("  • 🔄 = Custom energy mapping applied")
            }
        } else {
            print("  • No direct token matches (score from other factors)")
        }
        
        // Show redundancy penalty if applied
        if let lastCard = getLastSelectedCard() {
            if card.name.lowercased() == lastCard.lowercased() {
                print("  • ⚠️ Redundancy Penalty: 30% reduction (repeated from last selection)")
            } else {
                print("  • ✅ No Redundancy: Different from last card '\(lastCard)'")
            }
        }
        
        // Show energy alignment
        if let vibeBreakdown = vibeBreakdown {
            let alignedEnergies = card.energyAffinity.filter { $0.value >= 0.6 }
                .map { energy, affinity in
                    let points = getEnergyPoints(energy: energy, from: vibeBreakdown)
                    return "\(energy)(\(points)pts, \(String(format: "%.1f", affinity)))"
                }
            
            if !alignedEnergies.isEmpty {
                print("  • Energy Alignment: \(alignedEnergies.joined(separator: ", "))")
            }
        }
        
        // Show card's natural strengths
        let strongEnergies = card.energyAffinity.filter { $0.value >= 0.7 }
            .sorted { $0.value > $1.value }
            .map { "\($0.key)(\(String(format: "%.1f", $0.value)))" }
        
        if !strongEnergies.isEmpty {
            print("  • Card Strengths: \(strongEnergies.joined(separator: ", "))")
        }
    }
    
    /// Helper to get energy points from VibeBreakdown
    /// - Parameters:
    ///   - energy: Energy name
    ///   - vibeBreakdown: VibeBreakdown to extract from
    /// - Returns: Points for that energy
    private static func getEnergyPoints(energy: String, from vibeBreakdown: VibeBreakdown) -> Int {
        switch energy.lowercased() {
        case "classic": return vibeBreakdown.classic
        case "playful": return vibeBreakdown.playful
        case "romantic": return vibeBreakdown.romantic
        case "utility": return vibeBreakdown.utility
        case "drama": return vibeBreakdown.drama
        case "edge": return vibeBreakdown.edge
        default: return 0
        }
    }
    
    // MARK: - Testing & Validation Methods
    
    /// Run validation tests on the card selection system
    /// - Returns: Test results summary
    static func runValidationTests() -> String {
        print("\n🧪 TAROT CARD SELECTOR VALIDATION TESTS 🧪")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        loadTarotDeckIfNeeded()
        
        var results: [String] = []
        
        // Test 1: Deck Loading
        results.append("✅ Deck Loading: \(tarotDeck.count) cards loaded")
        
        // Test 2: Energy Coverage
        let energyTypes = ["classic", "playful", "romantic", "utility", "drama", "edge"]
        for energy in energyTypes {
            let strongCards = tarotDeck.filter { card in
                (card.energyAffinity[energy] ?? 0.0) >= 0.7
            }
            results.append("  • \(energy.capitalized): \(strongCards.count) strong matches")
        }
        
        // Test 3: Major vs Minor distribution
        let majorCount = tarotDeck.filter { $0.arcana == .major }.count
        let minorCount = tarotDeck.filter { $0.arcana == .minor }.count
        results.append("✅ Arcana Distribution: \(majorCount) Major, \(minorCount) Minor")
        
        // Test 4: Test with sample token sets
        let testScenarios = createTestScenarios()
        
        for (name, tokens, expectedType) in testScenarios {
            if let selectedCard = selectCard(for: tokens) {
                let match = (selectedCard.arcana.rawValue == expectedType) ? "✅" : "⚠️"
                results.append("\(match) \(name): Selected \(selectedCard.displayName) (\(selectedCard.arcana.rawValue))")
            } else {
                results.append("❌ \(name): No card selected")
            }
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return results.joined(separator: "\n")
    }
    
    /// Create test scenarios with known token patterns
    /// - Returns: Array of (name, tokens, expectedArcanaType) tuples
    private static func createTestScenarios() -> [(String, [StyleToken], String)] {
        return [
            ("High Drama Energy", [
                StyleToken(name: "intense", type: "mood", weight: 4.0, planetarySource: "Pluto", originType: .natal),
                StyleToken(name: "powerful", type: "expression", weight: 3.5, planetarySource: "Mars", originType: .transit),
                StyleToken(name: "transformative", type: "mood", weight: 3.0, planetarySource: "Pluto", originType: .progressed)
            ], "Major"),
            
            ("Classic Professional", [
                StyleToken(name: "structured", type: "form", weight: 3.0, planetarySource: "Saturn", originType: .natal),
                StyleToken(name: "authoritative", type: "mood", weight: 2.5, planetarySource: "Saturn", originType: .natal),
                StyleToken(name: "disciplined", type: "expression", weight: 2.0, planetarySource: "Capricorn", originType: .natal)
            ], "Major"),
            
            ("Romantic Flow", [
                StyleToken(name: "flowing", type: "texture", weight: 2.5, planetarySource: "Venus", originType: .natal),
                StyleToken(name: "soft", type: "texture", weight: 2.0, planetarySource: "Moon", originType: .progressed),
                StyleToken(name: "harmonious", type: "mood", weight: 2.0, planetarySource: "Libra", originType: .natal)
            ], "Major"),
            
            ("Practical Weather", [
                StyleToken(name: "practical", type: "function", weight: 3.5, originType: .weather),
                StyleToken(name: "waterproof", type: "function", weight: 3.0, originType: .weather),
                StyleToken(name: "secure", type: "structure", weight: 2.5, originType: .weather)
            ], "Minor")
        ]
    }
    
    /// Manual override for testing specific cards
    /// - Parameters:
    ///   - cardName: Name of the card to force select
    ///   - tokens: Tokens for context (for scoring display)
    /// - Returns: The specified card if found
    static func selectSpecificCard(named cardName: String, for tokens: [StyleToken]) -> TarotCard? {
        loadTarotDeckIfNeeded()
        
        let card = tarotDeck.first { $0.name.lowercased() == cardName.lowercased() }
        
        if let card = card {
            print("🎯 Manual Override: Selected \(card.displayName)")
            analyzeCardMatch(card: card, tokens: tokens, vibeBreakdown: nil)
        } else {
            print("❌ Card '\(cardName)' not found in deck")
        }
        
        return card
    }
    
    /// Create a minimal fallback deck when JSON fails to load
    private static func createFallbackDeck() {
        print("🔄 Creating minimal fallback Tarot deck...")
        
        tarotDeck = [
            TarotCard(
                name: "The Fool",
                arcana: .major,
                suit: nil,
                number: nil,
                keywords: ["spontaneous", "new", "optimistic"],
                themes: ["Fresh Start"],
                energyAffinity: ["playful": 0.9, "edge": 0.6, "classic": 0.2],
                description: "New beginnings and spontaneous energy",
                reversedKeywords: ["reckless"],
                symbolism: ["cliff", "rose"]
            ),
            TarotCard(
                name: "The Magician",
                arcana: .major,
                suit: nil,
                number: nil,
                keywords: ["focused", "powerful", "skillful"],
                themes: ["Focused Power"],
                energyAffinity: ["drama": 0.8, "classic": 0.7, "utility": 0.8],
                description: "Focused will and manifestation power",
                reversedKeywords: ["unfocused"],
                symbolism: ["infinity", "tools"]
            ),
            TarotCard(
                name: "The Empress",
                arcana: .major,
                suit: nil,
                number: nil,
                keywords: ["abundant", "creative", "nurturing", "luxurious"],
                themes: ["Creative Abundance"],
                energyAffinity: ["romantic": 1.0, "classic": 0.6, "playful": 0.7],
                description: "Abundance, creativity, and nurturing energy",
                reversedKeywords: ["blocked"],
                symbolism: ["crown", "wheat"]
            ),
            TarotCard(
                name: "The Emperor",
                arcana: .major,
                suit: nil,
                number: nil,
                keywords: ["structured", "authoritative", "disciplined"],
                themes: ["Structured Authority"],
                energyAffinity: ["classic": 1.0, "drama": 0.8, "utility": 0.9],
                description: "Authority, structure, and disciplined power",
                reversedKeywords: ["tyrannical"],
                symbolism: ["throne", "ram"]
            ),
            TarotCard(
                name: "Ace of Cups",
                arcana: .minor,
                suit: .cups,
                number: 1,
                keywords: ["emotional", "new", "love", "overflowing"],
                themes: ["Emotional Beginning"],
                energyAffinity: ["romantic": 1.0, "playful": 0.6, "drama": 0.5],
                description: "New emotional beginnings and overflowing love",
                reversedKeywords: ["emptiness"],
                symbolism: ["cup", "dove"]
            ),
            TarotCard(
                name: "Ten of Wands",
                arcana: .minor,
                suit: .wands,
                number: 10,
                keywords: ["burden", "responsibility", "practical", "achievement"],
                themes: ["Heavy Responsibility"],
                energyAffinity: ["utility": 0.9, "classic": 0.7, "drama": 0.6],
                description: "Heavy burdens and practical achievement",
                reversedKeywords: ["release"],
                symbolism: ["ten wands", "burden"]
            )
        ]
        
        isLoaded = true
        print("✅ Created fallback deck with \(tarotDeck.count) cards")
    }
    
    /// Get the last selected card name to avoid repetition
    /// - Returns: Last selected card name or nil
    private static func getLastSelectedCard() -> String? {
        return UserDefaults.standard.string(forKey: "LastSelectedTarotCard")
    }
    
    /// Store the selected card name to avoid repetition
    /// - Parameter cardName: Name of the selected card
    private static func storeLastSelectedCard(_ cardName: String) {
        UserDefaults.standard.set(cardName, forKey: "LastSelectedTarotCard")
    }
    
    /// Clear the last selected card (useful for testing)
    static func clearLastSelectedCard() {
        UserDefaults.standard.removeObject(forKey: "LastSelectedTarotCard")
    }
    
    /// Debug method to show all cards with strong affinity for a specific energy
    /// - Parameter energy: Energy type to filter by
    /// - Returns: Array of cards with strong affinity (≥0.7) for that energy
    static func getCardsForEnergy(_ energy: String) -> [TarotCard] {
        loadTarotDeckIfNeeded()
        
        return tarotDeck.filter { card in
            (card.energyAffinity[energy.lowercased()] ?? 0.0) >= 0.7
        }.sorted { first, second in
            let firstAffinity = first.energyAffinity[energy.lowercased()] ?? 0.0
            let secondAffinity = second.energyAffinity[energy.lowercased()] ?? 0.0
            return firstAffinity > secondAffinity
        }
    }
}

// MARK: - Extensions for Testing

extension TarotCardSelector {
    
    /// Quick test method for development
    static func quickTest() {
        print("🔮 Quick Tarot Selector Test")
        
        // Test tokens representing a dramatic, transformative day
        let testTokens = [
            StyleToken(name: "dramatic", type: "mood", weight: 3.0, planetarySource: "Pluto", originType: .natal),
            StyleToken(name: "transformative", type: "expression", weight: 2.5, planetarySource: "Pluto", originType: .transit),
            StyleToken(name: "bold", type: "color", weight: 2.0, planetarySource: "Mars", originType: .progressed)
        ]
        
        let testVibe = VibeBreakdown(classic: 2, playful: 3, romantic: 2, utility: 3, drama: 8, edge: 3)
        
        if let selectedCard = selectCard(for: testTokens, theme: "Transformative Power", vibeBreakdown: testVibe) {
            print("Selected: \(selectedCard.displayName)")
            print("Description: \(selectedCard.description)")
        } else {
            print("No card selected")
        }
    }
}
