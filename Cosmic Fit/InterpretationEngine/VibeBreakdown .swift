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
    let classic: Int
    let playful: Int
    let romantic: Int
    let utility: Int
    let drama: Int
    let edge: Int
    
    init(classic: Int, playful: Int, romantic: Int, utility: Int, drama: Int, edge: Int) {
        // Clamp values to their maximums to prevent crashes
        self.classic = min(max(classic, 0), 10)
        self.playful = min(max(playful, 0), 10)
        self.romantic = min(max(romantic, 0), 10)
        self.utility = min(max(utility, 0), 10)
        self.drama = min(max(drama, 0), 10)
        self.edge = min(max(edge, 0), 10)
    }
    
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
    
    /// Generate a 21-point vibe breakdown from StyleTokens - SIMPLIFIED VERSION
    /// - Parameter tokens: Array of StyleTokens from SemanticTokenGenerator
    /// - Returns: VibeBreakdown with points distributed across 6 energies (0-10 each)
    static func generateVibeBreakdown(from tokens: [StyleToken]) -> VibeBreakdown {
        
        print("\n🌟 GENERATING VIBE BREAKDOWN FROM TOKENS 🌟")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Input: \(tokens.count) tokens")
        
        // Get sun sign for personality-based adjustments
        let sunSign = extractSunSign(from: tokens)
        print("Sun Sign: \(sunSign)")
        
        // Step 1: Calculate raw scores for each energy
        let rawScores = calculateRawScores(from: tokens, sunSign: sunSign)
        print("\n🎯 Raw Scores:")
        for (energy, score) in rawScores {
            print("  • \(energy): \(String(format: "%.2f", score))")
        }
        
        // Step 2: Normalize to 21 points
        let breakdown = normalizeToTwentyOne(weightedScores: rawScores)
        print("\n✅ Final Breakdown: \(breakdown.debugDescription())")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return breakdown
    }
    
    private static func extractSunSign(from tokens: [StyleToken]) -> String {
        // Look for Sun planetary source tokens to determine natal sun sign
        for token in tokens {
            if token.planetarySource == "Sun", let signSource = token.signSource {
                return signSource
            }
        }
        return "NULL" // Default fallback
    }
    
    // MARK: - Helper Method for Water Sign Detection
    
    private static func countWaterPlacements(_ chart: NatalChartCalculator.NatalChart) -> Int {
        var count = 0
        
        // Check Sun sign
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSign = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
            if ["Cancer", "Scorpio", "Pisces"].contains(sunSign) { count += 1 }
        }
        
        // Check Moon sign
        if let moonPlanet = chart.planets.first(where: { $0.name == "Moon" }) {
            let moonSign = CoordinateTransformations.getZodiacSignName(sign: moonPlanet.zodiacSign)
            if ["Cancer", "Scorpio", "Pisces"].contains(moonSign) { count += 1 }
        }
        
        // Check Ascendant sign - FIXED
        let ascSign = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign
        let ascSignName = CoordinateTransformations.getZodiacSignName(sign: ascSign)
        if ["Cancer", "Scorpio", "Pisces"].contains(ascSignName) { count += 1 }
        
        return count
    }
    
    // MARK: - Raw Score Calculation
    
    // MARK: - Fixed Raw Score Calculation (REPLACE EXISTING)
    private static func calculateRawScores(from tokens: [StyleToken], sunSign: String) -> [String: Double] {
        var scores: [String: Double] = [
            "classic": 0.0,
            "playful": 0.0,
            "romantic": 0.0,
            "utility": 0.0,
            "drama": 0.0,
            "edge": 0.0
        ]
        
        // Enhanced weather detection for utility prioritization
        let hasWeatherTokens = tokens.contains { $0.originType == .weather }
        let hasHighWindTokens = tokens.contains { $0.name.contains("wind-resistant") || $0.name.contains("secure") }
        let hasRainTokens = tokens.contains { $0.name.contains("waterproof") || $0.name.contains("water-resistant") }
        
        for token in tokens {
            let tokenName = token.name.lowercased()
            let baseWeight = token.weight
            
            // Classic Energy Mapping
            if classicTokens.contains(tokenName) {
                let bonus = getClassicBonus(token: token)
                let sunSignBoost = getSunSignPersonalityBoost(token: token, sunSign: sunSign, energy: "classic")
                scores["classic"]! += (baseWeight * 2.0) + bonus + sunSignBoost
            }
            
            // Playful Energy Mapping
            if playfulTokens.contains(tokenName) {
                let bonus = getPlayfulBonus(token: token)
                let sunSignBoost = getSunSignPersonalityBoost(token: token, sunSign: sunSign, energy: "playful")
                scores["playful"]! += (baseWeight * 2.0) + bonus + sunSignBoost
            }
            
            // Romantic Energy Mapping - Reduced over-emphasis
            if romanticTokens.contains(tokenName) {
                let bonus = getRomanticBonus(token: token)
                let sunSignBoost = getSunSignPersonalityBoost(token: token, sunSign: sunSign, energy: "romantic")
                let romanticReduction = sunSign == "Scorpio" ? 0.7 : 1.0
                scores["romantic"]! += ((baseWeight * 1.5) + bonus + sunSignBoost) * romanticReduction
            }
            
            // Utility Energy Mapping - FIXED TO PREVENT OVER-WEIGHTING
            if utilityTokens.contains(tokenName) {
                let bonus = getUtilityBonus(token: token, hasWeatherTokens: hasWeatherTokens, hasHighWindTokens: hasHighWindTokens, hasRainTokens: hasRainTokens)
                let sunSignBoost = getSunSignPersonalityBoost(token: token, sunSign: sunSign, energy: "utility")
                scores["utility"]! += (baseWeight * 2.0) + bonus + sunSignBoost // Reduced from 3.0 to 2.0
            }
            
            // Drama Energy Mapping
            if dramaTokens.contains(tokenName) {
                let bonus = getDramaBonus(token: token)
                let sunSignBoost = getSunSignPersonalityBoost(token: token, sunSign: sunSign, energy: "drama")
                scores["drama"]! += (baseWeight * 2.0) + bonus + sunSignBoost
            }
            
            // Edge Energy Mapping
            if edgeTokens.contains(tokenName) {
                let bonus = getEdgeBonus(token: token)
                let sunSignBoost = getSunSignPersonalityBoost(token: token, sunSign: sunSign, energy: "edge")
                scores["edge"]! += (baseWeight * 2.0) + bonus + sunSignBoost
            }
        }
        
        // Apply sun sign energy preferences globally
        let sunSignPreferences = getSunSignEnergyPreference(sunSign: sunSign)
        for (energy, multiplier) in sunSignPreferences {
            scores[energy]! *= multiplier
        }
        
        // FIXED: Moderate weather-based utility boost (not extreme)
        if hasHighWindTokens || hasRainTokens {
            scores["utility"]! *= 1.3  // Reduced from 2.0 to 1.3
        }
        
        return scores
    }
    
    // MARK: - Sun Sign Personality Boost System
    
    private static func getSunSignPersonalityBoost(token: StyleToken, sunSign: String, energy: String) -> Double {
        let tokenName = token.name.lowercased()
        
        switch sunSign {
        case "Taurus":
            if energy == "classic" && ["practical", "grounded", "reliable", "luxurious", "sensual", "enduring"].contains(tokenName) { return 2.0 }
            if energy == "utility" && ["practical", "functional", "reliable", "durable"].contains(tokenName) { return 1.5 }
            if energy == "romantic" && ["luxurious", "sensual", "comfortable", "beautiful"].contains(tokenName) { return 1.2 }
            
        case "Scorpio":
            if energy == "drama" && ["intense", "transformative", "mysterious", "powerful", "deep", "magnetic"].contains(tokenName) { return 2.0 }
            if energy == "utility" && ["practical", "protective", "functional", "tactical"].contains(tokenName) { return 2.0 }
            if energy == "edge" && ["transformative", "intense", "mysterious", "powerful"].contains(tokenName) { return 1.5 }
            
        case "Cancer":
            if energy == "romantic" && ["nurturing", "protective", "comfortable", "intuitive", "soft", "gentle"].contains(tokenName) { return 2.0 }
            if energy == "utility" && ["protective", "practical", "comforting", "secure"].contains(tokenName) { return 1.5 }
            
        case "Leo":
            if energy == "drama" && ["bold", "dramatic", "radiant", "expressive", "powerful", "commanding"].contains(tokenName) { return 2.0 }
            if energy == "playful" && ["bold", "expressive", "creative", "dramatic"].contains(tokenName) { return 1.5 }
            
        case "Virgo":
            if energy == "classic" && ["practical", "refined", "precise", "structured", "disciplined"].contains(tokenName) { return 2.0 }
            if energy == "utility" && ["practical", "functional", "efficient", "precise"].contains(tokenName) { return 2.0 }
            
        case "Libra":
            if energy == "romantic" && ["harmonious", "beautiful", "elegant", "balanced", "refined"].contains(tokenName) { return 2.0 }
            if energy == "classic" && ["elegant", "refined", "balanced", "harmonious"].contains(tokenName) { return 1.5 }
            
        case "Aries":
            if energy == "drama" && ["bold", "energetic", "dynamic", "assertive", "intense"].contains(tokenName) { return 2.0 }
            if energy == "playful" && ["energetic", "dynamic", "bold", "active"].contains(tokenName) { return 1.5 }
            
        case "Gemini":
            if energy == "playful" && ["versatile", "communicative", "bright", "adaptable", "quick"].contains(tokenName) { return 2.0 }
            if energy == "edge" && ["innovative", "adaptable", "unique", "versatile"].contains(tokenName) { return 1.2 }
            
        case "Sagittarius":
            if energy == "playful" && ["adventurous", "expansive", "optimistic", "dynamic"].contains(tokenName) { return 2.0 }
            if energy == "drama" && ["bold", "expansive", "adventurous"].contains(tokenName) { return 1.5 }
            
        case "Capricorn":
            if energy == "classic" && ["structured", "authoritative", "disciplined", "enduring", "professional"].contains(tokenName) { return 2.0 }
            if energy == "utility" && ["practical", "functional", "structured", "reliable"].contains(tokenName) { return 1.5 }
            
        case "Aquarius":
            if energy == "edge" && ["innovative", "unique", "unconventional", "experimental", "electric"].contains(tokenName) { return 2.0 }
            if energy == "playful" && ["innovative", "unique", "creative", "experimental"].contains(tokenName) { return 1.2 }
            
        case "Pisces":
            if energy == "romantic" && ["dreamy", "ethereal", "intuitive", "flowing", "gentle", "mystical"].contains(tokenName) { return 2.0 }
            if energy == "edge" && ["ethereal", "mystical", "unconventional"].contains(tokenName) { return 1.2 }
            
        default:
            break
        }
        
        return 0.0
    }
    
    private static func getSunSignEnergyPreference(sunSign: String) -> [String: Double] {
        switch sunSign {
        case "Taurus":
            return ["classic": 1.5, "romantic": 1.3, "utility": 1.4, "playful": 0.8]  // Increased utility
        case "Scorpio":
            return ["drama": 1.8, "edge": 1.4, "utility": 1.6, "romantic": 0.6, "playful": 0.7]  // Increased utility, reduced romantic
        case "Cancer":
            return ["romantic": 1.4, "utility": 1.5, "classic": 1.1, "drama": 0.9]  // Increased utility (protective nature)
        case "Leo":
            return ["drama": 1.9, "playful": 1.4, "classic": 0.8, "utility": 0.8]
        case "Virgo":
            return ["classic": 1.7, "utility": 2.0, "romantic": 0.8, "drama": 0.7]  // Maximum utility preference
        case "Libra":
            return ["romantic": 1.6, "classic": 1.4, "playful": 1.2, "edge": 0.8]
        case "Aries":
            return ["drama": 1.7, "playful": 1.4, "edge": 1.2, "classic": 0.8]
        case "Gemini":
            return ["playful": 1.8, "edge": 1.2, "classic": 0.7, "utility": 1.0]
        case "Sagittarius":
            return ["playful": 1.6, "drama": 1.3, "edge": 1.2, "classic": 0.8]
        case "Capricorn":
            return ["classic": 1.8, "utility": 1.7, "drama": 1.1, "playful": 0.7]  // High utility (practical nature)
        case "Aquarius":
            return ["edge": 1.9, "playful": 1.3, "classic": 0.7, "romantic": 0.8]
        case "Pisces":
            return ["romantic": 1.7, "edge": 1.3, "playful": 1.1, "classic": 0.8]
        default:
            return [:]
        }
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
        "pale yellow", "seafoam", "opalescent blue", "fluid", "pearl",
        "intuitive", "compassionate", "receptive", "empathetic", "subtle"
    ]
    
    private static let utilityTokens: Set<String> = [
        "practical", "functional", "waterproof", "durable", "purposeful",
        "protective", "reliable", "tactical", "insulating", "layerable",
        "breathable", "weatherproof", "wind-resistant", "secure", "stable",
        "efficient", "versatile", "adaptable", "multi-purpose", "performance"
    ]
    
    private static let dramaTokens: Set<String> = [
        "bold", "intense", "powerful", "dramatic", "striking", "rich",
        "deep", "transformative", "commanding", "magnetic",
        "royal", "electric", "plutonium", "metallic", "royal purple",
        "deep burgundy", "plutonium purple", "radiant", "mysterious",
        "penetrating", "emotional", "passionate", "hypnotic", "profound"
    ]
    
    private static let edgeTokens: Set<String> = [
        "unconventional", "innovative", "unique", "unexpected", "electric",
        "neon", "metallic", "textured", "distinctive", "rebellious",
        "avant-garde", "edgy", "alternative", "disruptive", "experimental"
    ]
    
    // MARK: - Token Set Getters (for Debug Analysis) ⭐ ADD HERE ⭐
    
    static func getClassicTokens() -> Set<String> { return classicTokens }
    static func getPlayfulTokens() -> Set<String> { return playfulTokens }
    static func getRomanticTokens() -> Set<String> { return romanticTokens }
    static func getUtilityTokens() -> Set<String> { return utilityTokens }
    static func getDramaTokens() -> Set<String> { return dramaTokens }
    static func getEdgeTokens() -> Set<String> { return edgeTokens }
    
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
        if token.type == "texture" { bonus += 1.5 }
        
        // Venus planetary source (beauty, harmony)
        if token.planetarySource == "Venus" { bonus += 2.0 }
        
        // Moon planetary source (emotional comfort)
        if token.planetarySource == "Moon" { bonus += 1.5 }
        
        // Water signs boost romantic
        if let sign = token.signSource, ["Cancer", "Scorpio", "Pisces"].contains(sign) {
            bonus += 1.0
        }
        
        return bonus
    }
    
    private static func getUtilityBonus(token: StyleToken, hasWeatherTokens: Bool, hasHighWindTokens: Bool, hasRainTokens: Bool) -> Double {
        var bonus = 0.0
        
        // Weather origin tokens get moderate utility boost
        if token.originType == .weather { bonus += 1.5 } // Reduced from 3.0
        
        // Saturn planetary source (practical structure)
        if token.planetarySource == "Saturn" { bonus += 1.0 } // Reduced from 2.0
        
        // High weight weather-resistant tokens
        if token.weight > 3.0 && ["wind-resistant", "waterproof", "protective", "secure"].contains(token.name) {
            bonus += 1.5 // Reduced from 3.0
        }
        
        // Specific weather condition bonuses - REDUCED
        if hasHighWindTokens && ["wind-resistant", "secure", "stable", "structured"].contains(token.name) {
            bonus += 1.0 // Reduced from 2.5
        }
        
        if hasRainTokens && ["waterproof", "water-resistant", "protective", "practical"].contains(token.name) {
            bonus += 1.0 // Reduced from 2.5
        }
        
        // Earth sign amplification for practical tokens
        if let sign = token.signSource, ["Taurus", "Virgo", "Capricorn"].contains(sign) {
            if ["practical", "functional", "reliable", "structured"].contains(token.name) {
                bonus += 0.8 // Reduced from 1.5
            }
        }
        
        return bonus
    }
    
    /// Weather-based utility multiplier
    private static func getWeatherUtilityMultiplier(token: StyleToken, hasWeatherTokens: Bool) -> Double {
        if !hasWeatherTokens { return 1.0 }
        
        // Weather tokens get significant multiplier
        if token.originType == .weather { return 2.5 }
        
        // Weather-responsive tokens get moderate multiplier
        if ["practical", "protective", "structured", "reliable"].contains(token.name) {
            return 1.8
        }
        
        return 1.0
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
    
    // MARK: - Normalization to 21 Points
    
    // Normalize raw scores to exactly 21 points with consistent 0-10 scaling
    /// - Parameter weightedScores: Raw scores for each energy
    /// - Returns: VibeBreakdown with proper distribution
    private static func normalizeToTwentyOne(weightedScores: [String: Double]) -> VibeBreakdown {
        
         // Calculate total weighted score
         let totalScore = weightedScores.values.reduce(0, +)
         
         // If no scores, return balanced default
         guard totalScore > 0 else {
             return VibeBreakdown(classic: 4, playful: 3, romantic: 4, utility: 4, drama: 3, edge: 3)
         }
         
         // FIXED: Handle extreme outliers by capping individual energy maximums
         var cappedScores: [String: Double] = [:]
         let maxIndividualScore = totalScore * 0.6 // No single energy can be more than 60% of total
         
         for (energy, score) in weightedScores {
             cappedScores[energy] = min(score, maxIndividualScore)
         }
         
         let cappedTotal = cappedScores.values.reduce(0, +)
         
         // Apply proportional distribution to 21 points
         var distributedScores: [String: Double] = [:]
         for (energy, score) in cappedScores {
             distributedScores[energy] = (score / cappedTotal) * 21.0
         }
         
         // Convert to integers with rounding
         var integerScores: [String: Int] = [:]
         var remainingPoints = 21
         
         // First pass: round down and track points used
         for (energy, score) in distributedScores {
             let roundedDown = Int(score)
             integerScores[energy] = roundedDown
             remainingPoints -= roundedDown
         }
         
         // Second pass: distribute remaining points to highest fractional remainders
         let remainders = distributedScores.map { (energy, score) in
             (energy: energy, remainder: score - Double(integerScores[energy]!))
         }.sorted { $0.remainder > $1.remainder }
         
         for i in 0..<remainingPoints {
             if i < remainders.count {
                 integerScores[remainders[i].energy]! += 1
             }
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
    
    /*
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
     */
}
