//
//  TarotDemo.swift
//  Cosmic Fit
//
//  Created by AI Assistant on 12/05/2025.
//  Demonstration script for Tarot card selection system
//

/*
import Foundation

/// Demonstration class to showcase the Tarot card selection system
class TarotDemo {
    
    /// Run a comprehensive demo showing different scenarios
    static func runFullDemo() {
        print("\n🌟 TAROT CARD SELECTION SYSTEM DEMO 🌟")
        print("═══════════════════════════════════════════════════════════════════════════════")
        
        // Demo 1: High Drama Energy Day
        print("\n🎭 DEMO 1: High Drama Energy Day")
        print("───────────────────────────────────────────────────────")
        
        let dramaTokens = [
            StyleToken(name: "intense", type: "mood", weight: 4.0, planetarySource: "Pluto", originType: .natal),
            StyleToken(name: "transformative", type: "expression", weight: 3.5, planetarySource: "Pluto", originType: .transit),
            StyleToken(name: "powerful", type: "mood", weight: 3.0, planetarySource: "Mars", originType: .progressed),
            StyleToken(name: "bold", type: "color", weight: 2.5, planetarySource: "Leo", signSource: "Leo", originType: .natal)
        ]
        
        let dramaVibe = VibeBreakdown(classic: 2, playful: 2, romantic: 2, utility: 3, drama: 8, edge: 4)
        
        demonstrateSelection(
            scenario: "High Drama Energy",
            tokens: dramaTokens,
            vibeBreakdown: dramaVibe,
            expectedCardTypes: ["Major Arcana with drama/transformation themes"]
        )
        
        // Demo 2: Classic Professional Day
        print("\n🏛️ DEMO 2: Classic Professional Day")
        print("───────────────────────────────────────────────────────")
        
        let classicTokens = [
            StyleToken(name: "structured", type: "form", weight: 3.0, planetarySource: "Saturn", originType: .natal),
            StyleToken(name: "authoritative", type: "mood", weight: 2.8, planetarySource: "Saturn", originType: .natal),
            StyleToken(name: "disciplined", type: "expression", weight: 2.5, signSource: "Capricorn", originType: .natal),
            StyleToken(name: "refined", type: "quality", weight: 2.0, planetarySource: "Venus", originType: .natal)
        ]
        
        let classicVibe = VibeBreakdown(classic: 9, playful: 2, romantic: 3, utility: 4, drama: 2, edge: 1)
        
        demonstrateSelection(
            scenario: "Classic Professional",
            tokens: classicTokens,
            vibeBreakdown: classicVibe,
            expectedCardTypes: ["Cards with structure/authority themes"]
        )
        
        // Demo 3: Romantic Flow Day
        print("\n💕 DEMO 3: Romantic Flow Day")
        print("───────────────────────────────────────────────────────")
        
        let romanticTokens = [
            StyleToken(name: "flowing", type: "texture", weight: 3.0, planetarySource: "Venus", originType: .natal),
            StyleToken(name: "soft", type: "texture", weight: 2.8, planetarySource: "Moon", originType: .progressed),
            StyleToken(name: "beautiful", type: "quality", weight: 2.5, planetarySource: "Venus", originType: .natal),
            StyleToken(name: "harmonious", type: "mood", weight: 2.2, signSource: "Libra", originType: .natal)
        ]
        
        let romanticVibe = VibeBreakdown(classic: 3, playful: 3, romantic: 9, utility: 2, drama: 2, edge: 2)
        
        demonstrateSelection(
            scenario: "Romantic Flow",
            tokens: romanticTokens,
            vibeBreakdown: romanticVibe,
            expectedCardTypes: ["Cards with love/harmony/beauty themes"]
        )
        
        // Demo 4: Weather-Driven Utility Day
        print("\n🌧️ DEMO 4: Weather-Driven Utility Day")
        print("───────────────────────────────────────────────────────")
        
        let utilityTokens = [
            StyleToken(name: "practical", type: "function", weight: 4.0, originType: .weather),
            StyleToken(name: "waterproof", type: "function", weight: 3.8, originType: .weather),
            StyleToken(name: "wind-resistant", type: "function", weight: 3.5, originType: .weather),
            StyleToken(name: "secure", type: "structure", weight: 3.0, originType: .weather)
        ]
        
        let utilityVibe = VibeBreakdown(classic: 3, playful: 2, romantic: 2, utility: 9, drama: 3, edge: 2)
        
        demonstrateSelection(
            scenario: "Weather-Driven Utility",
            tokens: utilityTokens,
            vibeBreakdown: utilityVibe,
            expectedCardTypes: ["Cards with practical/functional themes"]
        )
        
        // Demo 5: Creative Edge Day
        print("\n⚡ DEMO 5: Creative Edge Day")
        print("───────────────────────────────────────────────────────")
        
        let edgeTokens = [
            StyleToken(name: "innovative", type: "expression", weight: 3.5, planetarySource: "Uranus", originType: .transit),
            StyleToken(name: "unconventional", type: "mood", weight: 3.2, planetarySource: "Uranus", originType: .natal),
            StyleToken(name: "electric", type: "energy", weight: 3.0, signSource: "Aquarius", originType: .natal),
            StyleToken(name: "experimental", type: "approach", weight: 2.8, planetarySource: "Uranus", originType: .progressed)
        ]
        
        let edgeVibe = VibeBreakdown(classic: 1, playful: 4, romantic: 2, utility: 3, drama: 4, edge: 7)
        
        demonstrateSelection(
            scenario: "Creative Edge",
            tokens: edgeTokens,
            vibeBreakdown: edgeVibe,
            expectedCardTypes: ["Cards with innovation/change/rebellion themes"]
        )
        
        // Demo 6: Testing Suite
        print("\n🧪 DEMO 6: Testing Suite")
        print("───────────────────────────────────────────────────────")
        
        _ = TarotCardTester.runComprehensiveTests()
        
        print("\n═══════════════════════════════════════════════════════════════════════════════")
        print("🎯 DEMO COMPLETE - Tarot Card Selection System Ready for Use! 🎯")
        print("═══════════════════════════════════════════════════════════════════════════════\n")
    }
    
    /// Demonstrate card selection for a specific scenario
    /// - Parameters:
    ///   - scenario: Name of the scenario
    ///   - tokens: StyleTokens for the scenario
    ///   - vibeBreakdown: VibeBreakdown for energy context
    ///   - expectedCardTypes: Expected types of cards for validation
    private static func demonstrateSelection(
        scenario: String,
        tokens: [StyleToken],
        vibeBreakdown: VibeBreakdown,
        expectedCardTypes: [String]
    ) {
        print("📊 Scenario Input:")
        print("  • Tokens: \(tokens.map { $0.name }.joined(separator: ", "))")
        print("  • Dominant Energy: \(vibeBreakdown.dominantEnergy ?? "Unknown")")
        print("  • Expected: \(expectedCardTypes.joined(separator: ", "))")
        
        if let selectedCard = TarotCardSelector.selectCard(for: tokens, vibeBreakdown: vibeBreakdown) {
            print("\n✨ Selected Card: \(selectedCard.displayName)")
            print("  • Category: \(selectedCard.category)")
            print("  • Description: \(selectedCard.description)")
            
            // Show top matching keywords
            let tokenNames = Set(tokens.map { $0.name.lowercased() })
            let matchingKeywords = selectedCard.keywords.filter { tokenNames.contains($0.lowercased()) }
            if !matchingKeywords.isEmpty {
                print("  • Matching Keywords: \(matchingKeywords.joined(separator: ", "))")
            }
            
            // Show energy affinity
            if let dominantEnergy = vibeBreakdown.dominantEnergy {
                let affinity = selectedCard.energyAffinity[dominantEnergy] ?? 0.0
                print("  • \(dominantEnergy.capitalized) Energy Affinity: \(String(format: "%.2f", affinity))")
            }
            
            print("  • Score: \(String(format: "%.2f", selectedCard.calculateMatchScore(for: tokens, vibeBreakdown: vibeBreakdown)))")
        } else {
            print("\n❌ No card selected")
        }
        
        print()
    }
    
    /// Quick demo for development testing
    static func quickDemo() {
        print("🔮 Quick Tarot Demo")
        
        let testTokens = [
            StyleToken(name: "confident", type: "mood", weight: 2.0, originType: .natal),
            StyleToken(name: "elegant", type: "quality", weight: 1.8, planetarySource: "Venus", originType: .natal)
        ]
        
        let testVibe = VibeBreakdown(classic: 5, playful: 3, romantic: 6, utility: 3, drama: 2, edge: 2)
        
        if let card = TarotCardSelector.selectCard(for: testTokens, vibeBreakdown: testVibe) {
            print("Selected: \(card.displayName) - \(card.description)")
        } else {
            print("No card selected")
        }
    }
    
    /// Demo showing top suggestions instead of just one card
    static func showTopSuggestionsDemo() {
        print("\n🏆 Top Card Suggestions Demo")
        print("─────────────────────────────────────")
        
        let balancedTokens = [
            StyleToken(name: "balanced", type: "mood", weight: 2.0, originType: .natal),
            StyleToken(name: "creative", type: "expression", weight: 1.8, planetarySource: "Mercury", originType: .transit),
            StyleToken(name: "practical", type: "approach", weight: 1.5, originType: .weather)
        ]
        
        let balancedVibe = VibeBreakdown(classic: 4, playful: 4, romantic: 4, utility: 4, drama: 3, edge: 2)
        
        let topCards = TarotCardSelector.getTopCardSuggestions(
            for: balancedTokens,
            vibeBreakdown: balancedVibe,
            count: 5
        )
        
        print("Input: Balanced energy with creative and practical elements")
        print("\nTop 5 Card Suggestions:")
        
        for (index, card) in topCards.enumerated() {
            let score = card.calculateMatchScore(for: balancedTokens, vibeBreakdown: balancedVibe)
            print("  \(index + 1). \(card.displayName) - Score: \(String(format: "%.2f", score))")
            print("     \(card.description)")
            print()
        }
    }
}

// MARK: - Quick Usage Examples

extension TarotDemo {
    
    /// Example of how to integrate into daily vibe generation
    static func dailyVibeIntegrationExample() {
        print("📱 Daily Vibe Integration Example")
        print("──────────────────────────────────────")
        
        // Simulate token generation from SemanticTokenGenerator
        let dailyTokens = [
            StyleToken(name: "grounded", type: "mood", weight: 2.5, planetarySource: "Saturn", originType: .natal),
            StyleToken(name: "optimistic", type: "mood", weight: 2.0, planetarySource: "Jupiter", originType: .transit),
            StyleToken(name: "practical", type: "approach", weight: 3.0, originType: .weather),
            StyleToken(name: "warm", type: "quality", weight: 1.8, planetarySource: "Sun", originType: .progressed)
        ]
        
        // Generate vibe breakdown
        let vibeBreakdown = VibeBreakdownGenerator.generateVibeBreakdown(from: dailyTokens)
        
        // Select tarot card
        let dailyCard = TarotCardSelector.selectCard(for: dailyTokens, vibeBreakdown: vibeBreakdown)
        
        // Create daily vibe content (simulated)
        var dailyVibe = DailyVibeContent()
        dailyVibe.styleBrief = "Today calls for grounded, optimistic choices with practical touches."
        dailyVibe.vibeBreakdown = vibeBreakdown
        dailyVibe.tarotCard = dailyCard
        
        print("Daily Vibe Generated:")
        print("  Style Brief: \(dailyVibe.styleBrief)")
        print("  Dominant Energy: \(dailyVibe.dominantEnergy)")
        if let card = dailyVibe.tarotCard {
            print("  Tarot Card: \(card.displayName)")
            print("  Card Wisdom: \(card.description)")
        }
    }
}
*/
