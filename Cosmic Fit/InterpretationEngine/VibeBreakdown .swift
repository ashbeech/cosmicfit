//
//  VibeBreakdownGenerator.swift
//  Cosmic Fit
//
//  Created by AI Assistant
//  Maps sophisticated StyleTokens to 6 style energies with 21-point distribution
//

import Foundation

// MARK: - Vibe Breakdown Structure

struct VibeBreakdown: Codable {
    let classic: Int      // 0-10 points - structured, grounded, refined, timeless
    let playful: Int      // 0-8 points  - bright, dynamic, expressive, fun
    let romantic: Int     // 0-8 points  - flowing, soft, harmonious, dreamy
    let utility: Int      // 0-7 points  - practical, functional, protective
    let drama: Int        // 0-6 points  - bold, intense, powerful, striking
    let edge: Int         // 0-5 points  - unconventional, innovative, electric
    
    var totalPoints: Int {
        return classic + playful + romantic + utility + drama + edge
    }
    
    /// Verify the breakdown is valid (totals to 21)
    var isValid: Bool {
        return totalPoints == 21
    }
    
    /// Get a debug description of the breakdown
    func debugDescription() -> String {
        return "Classic: \(classic), Playful: \(playful), Romantic: \(romantic), Utility: \(utility), Drama: \(drama), Edge: \(edge) [Total: \(totalPoints)]"
    }
}

// MARK: - Vibe Breakdown Generator

class VibeBreakdownGenerator {
    
    // MARK: - Main Generation Method
    
    /// Generate a 21-point vibe breakdown from StyleTokens
    /// - Parameter tokens: Array of StyleTokens from SemanticTokenGenerator
    /// - Returns: VibeBreakdown with points distributed across 6 energies
    static func generateVibeBreakdown(from tokens: [StyleToken]) -> VibeBreakdown {
        
        print("\n🌟 GENERATING VIBE BREAKDOWN FROM TOKENS 🌟")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Input: \(tokens.count) tokens")
        
        // Step 1: Calculate raw scores for each energy
        let rawScores = calculateRawScores(from: tokens)
        print("\n🎯 Raw Scores:")
        for (energy, score) in rawScores {
            print("  • \(energy): \(String(format: "%.2f", score))")
        }
        
        // Step 2: Apply weight scaling
        let weightedScores = applyWeightScaling(rawScores: rawScores, tokens: tokens)
        print("\n⚖️ Weighted Scores:")
        for (energy, score) in weightedScores {
            print("  • \(energy): \(String(format: "%.2f", score))")
        }
        
        // Step 3: Normalize to 21 points with intelligent distribution
        let breakdown = normalizeToTwentyOne(weightedScores: weightedScores, tokens: tokens)
        print("\n✅ Final Breakdown: \(breakdown.debugDescription())")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return breakdown
    }
    
    // MARK: - Raw Score Calculation
    
    private static func calculateRawScores(from tokens: [StyleToken]) -> [String: Double] {
        var scores: [String: Double] = [
            "classic": 0.0,
            "playful": 0.0,
            "romantic": 0.0,
            "utility": 0.0,
            "drama": 0.0,
            "edge": 0.0
        ]
        
        for token in tokens {
            let tokenName = token.name.lowercased()
            let baseWeight = token.weight
            
            // Classic Energy Mapping
            if classicTokens.contains(tokenName) {
                let bonus = getClassicBonus(token: token)
                scores["classic"]! += (baseWeight * 2.0) + bonus
            }
            
            // Playful Energy Mapping
            if playfulTokens.contains(tokenName) {
                let bonus = getPlayfulBonus(token: token)
                scores["playful"]! += (baseWeight * 2.0) + bonus
            }
            
            // Romantic Energy Mapping
            if romanticTokens.contains(tokenName) {
                let bonus = getRomanticBonus(token: token)
                scores["romantic"]! += (baseWeight * 2.0) + bonus
            }
            
            // Utility Energy Mapping
            if utilityTokens.contains(tokenName) {
                let bonus = getUtilityBonus(token: token)
                scores["utility"]! += (baseWeight * 2.0) + bonus
            }
            
            // Drama Energy Mapping
            if dramaTokens.contains(tokenName) {
                let bonus = getDramaBonus(token: token)
                scores["drama"]! += (baseWeight * 2.0) + bonus
            }
            
            // Edge Energy Mapping
            if edgeTokens.contains(tokenName) {
                let bonus = getEdgeBonus(token: token)
                scores["edge"]! += (baseWeight * 2.0) + bonus
            }
        }
        
        return scores
    }
    
    // MARK: - Token Mapping Sets
    
    private static let classicTokens: Set<String> = [
        "structured", "grounded", "reserved", "solid", "refined", "polished",
        "professional", "timeless", "balanced", "harmonious", "elegant",
        "sophisticated", "classic", "conservative", "traditional", "disciplined",
        "authoritative", "enduring", "substantial", "commanding", "navy",
        "charcoal", "slate gray", "stone", "cream", "tailored", "crisp"
    ]
    
    private static let playfulTokens: Set<String> = [
        "bright", "vibrant", "dynamic", "energetic", "fun", "expressive",
        "creative", "colorful", "light", "airy", "versatile", "quick",
        "adaptable", "communicative", "cheerful", "bright yellow",
        "neon turquoise", "electric blue", "playful", "lively", "spirited"
    ]
    
    private static let romanticTokens: Set<String> = [
        "flowing", "soft", "gentle", "dreamy", "ethereal", "luxurious",
        "sensual", "beautiful", "harmonious", "nurturing", "comfortable",
        "warm", "delicate", "feminine", "graceful", "misty lavender",
        "pale yellow", "seafoam", "opalescent blue", "flowing", "fluid"
    ]
    
    private static let utilityTokens: Set<String> = [
        "practical", "functional", "comfortable", "waterproof", "durable",
        "purposeful", "protective", "substantial", "enduring", "reliable",
        "versatile", "structured", "tactical", "insulating", "layerable",
        "breathable", "weatherproof"
    ]
    
    private static let dramaTokens: Set<String> = [
        "bold", "intense", "powerful", "dramatic", "striking", "rich",
        "deep", "transformative", "commanding", "magnetic", "luxurious",
        "royal", "electric", "plutonium", "metallic", "royal purple",
        "deep burgundy", "electric blue", "plutonium purple", "radiant"
    ]
    
    private static let edgeTokens: Set<String> = [
        "unconventional", "innovative", "unique", "unexpected", "electric",
        "neon", "metallic", "textured", "distinctive", "rebellious",
        "avant-garde", "edgy", "alternative", "disruptive", "experimental"
    ]
    
    // MARK: - Bonus Calculation Methods
    
    private static func getClassicBonus(token: StyleToken) -> Double {
        var bonus = 0.0
        
        // Structure type tokens get extra classic points
        if token.type == "structure" { bonus += 1.0 }
        
        // High weight tokens (stability indicators)
        if token.weight > 2.0 { bonus += 1.0 }
        
        // Saturn planetary source (structure, discipline)
        if token.planetarySource == "Saturn" { bonus += 1.5 }
        
        // Earth signs boost classic
        if let sign = token.signSource, ["Taurus", "Virgo", "Capricorn"].contains(sign) {
            bonus += 0.5
        }
        
        return bonus
    }
    
    private static func getPlayfulBonus(token: StyleToken) -> Double {
        var bonus = 0.0
        
        // Expression type tokens boost playful
        if token.type == "expression" { bonus += 1.0 }
        
        // Bright color qualities
        if token.type == "color_quality" &&
           ["bright", "vibrant", "electric"].contains(where: { token.name.contains($0) }) {
            bonus += 1.5
        }
        
        // Mercury planetary source (communication, versatility)
        if token.planetarySource == "Mercury" { bonus += 1.0 }
        
        // Air signs boost playful
        if let sign = token.signSource, ["Gemini", "Libra", "Aquarius"].contains(sign) {
            bonus += 0.5
        }
        
        return bonus
    }
    
    private static func getRomanticBonus(token: StyleToken) -> Double {
        var bonus = 0.0
        
        // Texture type tokens boost romantic
        if token.type == "texture" { bonus += 1.0 }
        
        // Venus planetary source (beauty, harmony)
        if token.planetarySource == "Venus" { bonus += 2.0 }
        
        // Moon planetary source (nurturing, flowing)
        if token.planetarySource == "Moon" { bonus += 1.5 }
        
        // Water signs boost romantic
        if let sign = token.signSource, ["Cancer", "Scorpio", "Pisces"].contains(sign) {
            bonus += 1.0
        }
        
        return bonus
    }
    
    private static func getUtilityBonus(token: StyleToken) -> Double {
        var bonus = 0.0
        
        // Weather origin tokens heavily boost utility
        if token.originType == .weather { bonus += 2.0 }
        
        // Saturn aspects boost utility (practical discipline)
        if token.planetarySource == "Saturn" { bonus += 1.5 }
        
        // Mars aspects can boost utility (action-oriented)
        if token.planetarySource == "Mars" &&
           ["practical", "protective", "tactical"].contains(where: { token.name.contains($0) }) {
            bonus += 1.0
        }
        
        return bonus
    }
    
    private static func getDramaBonus(token: StyleToken) -> Double {
        var bonus = 0.0
        
        // High weight tokens create drama
        if token.weight > 3.0 { bonus += 1.5 }
        
        // Pluto planetary source (transformation, intensity)
        if token.planetarySource == "Pluto" { bonus += 2.0 }
        
        // Mars planetary source (action, boldness)
        if token.planetarySource == "Mars" { bonus += 1.0 }
        
        // Fire signs boost drama
        if let sign = token.signSource, ["Aries", "Leo", "Sagittarius"].contains(sign) {
            bonus += 1.0
        }
        
        return bonus
    }
    
    private static func getEdgeBonus(token: StyleToken) -> Double {
        var bonus = 0.0
        
        // Uranus planetary source (innovation, rebellion)
        if token.planetarySource == "Uranus" { bonus += 2.5 }
        
        // High weight unconventional tokens
        if token.weight > 2.5 && edgeTokens.contains(token.name.lowercased()) {
            bonus += 1.5
        }
        
        // Transit origin can boost edge (current cosmic weather)
        if token.originType == .transit &&
           ["innovative", "unexpected", "disruptive"].contains(where: { token.name.contains($0) }) {
            bonus += 1.0
        }
        
        return bonus
    }
    
    // MARK: - Weight Scaling
    
    private static func applyWeightScaling(rawScores: [String: Double], tokens: [StyleToken]) -> [String: Double] {
        var scaledScores = rawScores
        
        // Calculate average token weight as scaling factor
        let totalWeight = tokens.reduce(0.0) { $0 + $1.weight }
        let averageWeight = totalWeight / Double(tokens.count)
        let scaleFactor = max(averageWeight / 2.0, 0.5) // Minimum 0.5x scaling
        
        // Apply scaling to all energies
        for (energy, score) in scaledScores {
            scaledScores[energy] = score * scaleFactor
        }
        
        return scaledScores
    }
    
    // MARK: - Normalization to 21 Points
    
    private static func normalizeToTwentyOne(weightedScores: [String: Double], tokens: [StyleToken]) -> VibeBreakdown {
        
        // Calculate total weighted score
        let totalScore = weightedScores.values.reduce(0, +)
        
        // If no scores, return balanced default
        guard totalScore > 0 else {
            return VibeBreakdown(classic: 6, playful: 3, romantic: 4, utility: 4, drama: 2, edge: 2)
        }
        
        // Apply proportional distribution
        var distributedScores: [String: Double] = [:]
        for (energy, score) in weightedScores {
            distributedScores[energy] = (score / totalScore) * 21.0
        }
        
        // Apply minimum thresholds and convert to integers
        var integerScores: [String: Int] = [:]
        var remainingPoints = 21
        
        // First pass: assign minimum viable points or zero
        for (energy, score) in distributedScores {
            if score < 0.5 {
                integerScores[energy] = 0
            } else {
                let minPoints = Int(score.rounded(.down))
                integerScores[energy] = max(minPoints, 1)
                remainingPoints -= integerScores[energy]!
            }
        }
        
        // Second pass: distribute remaining points to highest scoring energies
        let sortedEnergies = distributedScores.sorted { $0.value > $1.value }
        var pointsToDistribute = max(0, remainingPoints)
        
        for (energy, _) in sortedEnergies {
            if pointsToDistribute <= 0 { break }
            if integerScores[energy]! > 0 { // Only boost active energies
                let maxForEnergy = getMaxPointsForEnergy(energy)
                if integerScores[energy]! < maxForEnergy {
                    let canAdd = min(pointsToDistribute, maxForEnergy - integerScores[energy]!)
                    integerScores[energy]! += canAdd
                    pointsToDistribute -= canAdd
                }
            }
        }
        
        // Final adjustment to ensure exactly 21 points
        let currentTotal = integerScores.values.reduce(0, +)
        if currentTotal != 21 {
            adjustToExactTotal(scores: &integerScores, targetTotal: 21)
        }
        
        return VibeBreakdown(
            classic: integerScores["classic"] ?? 0,
            playful: integerScores["playful"] ?? 0,
            romantic: integerScores["romantic"] ?? 0,
            utility: integerScores["utility"] ?? 0,
            drama: integerScores["drama"] ?? 0,
            edge: integerScores["edge"] ?? 0
        )
    }
    
    // MARK: - Helper Methods
    
    private static func getMaxPointsForEnergy(_ energy: String) -> Int {
        switch energy {
        case "classic": return 10
        case "playful": return 8
        case "romantic": return 8
        case "utility": return 7
        case "drama": return 6
        case "edge": return 5
        default: return 5
        }
    }
    
    private static func adjustToExactTotal(scores: inout [String: Int], targetTotal: Int) {
        let currentTotal = scores.values.reduce(0, +)
        let difference = targetTotal - currentTotal
        
        if difference == 0 { return }
        
        let energyOrder = ["classic", "romantic", "utility", "playful", "drama", "edge"]
        
        if difference > 0 {
            // Need to add points
            var pointsToAdd = difference
            for energy in energyOrder {
                if pointsToAdd <= 0 { break }
                let maxPoints = getMaxPointsForEnergy(energy)
                if scores[energy]! < maxPoints {
                    let canAdd = min(pointsToAdd, maxPoints - scores[energy]!)
                    scores[energy]! += canAdd
                    pointsToAdd -= canAdd
                }
            }
        } else {
            // Need to remove points
            var pointsToRemove = abs(difference)
            for energy in energyOrder.reversed() {
                if pointsToRemove <= 0 { break }
                if scores[energy]! > 0 {
                    let canRemove = min(pointsToRemove, scores[energy]!)
                    scores[energy]! -= canRemove
                    pointsToRemove -= canRemove
                }
            }
        }
    }
}
