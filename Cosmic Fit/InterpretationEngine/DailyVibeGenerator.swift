//
//  DailyVibeGenerator.swift
//  Cosmic Fit
//

import Foundation

class DailyVibeGenerator {
    
    // MARK: - Public Methods
    
    /// Generate a daily vibe interpretation focused solely on Style Brief generation
    /// - Parameters:
    ///   - natalChart: The natal chart for base style resonance
    ///   - progressedChart: The progressed chart for emotional vibe
    ///   - transits: Array of transit aspects to natal chart
    ///   - weather: Optional current weather conditions
    ///   - moonPhase: Current lunar phase (0-360)
    ///   - weights: Weighting model to use for calculations
    /// - Returns: A DailyVibeContent with Style Brief text in Maria's voice
    static func generateDailyVibe(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        moonPhase: Double,
        weights: WeightingModel.Type = WeightingModel.self) -> DailyVibeContent {
        
        print("\n🎯 DAILY VIBE GENERATOR - STYLE BRIEF FOCUS 🎯")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 STREAMLINED APPROACH:")
        print("  • Focus: Style Brief generation in Maria's voice")
        print("  • Input: All semantic tokens from interpretation engine")
        print("  • Process: Token analysis → Maria's actionable guidance")
        print("  • Output: Simplified DailyVibeContent with Style Brief")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Debug: Log input parameters
        debugLogInputs(natal: natalChart, progressed: progressedChart, transits: transits, weather: weather, moonPhase: moonPhase)
        
        // Get all semantic tokens from interpretation engine
        let allTokens = SemanticTokenGenerator.generateDailyFitTokens(
            natal: natalChart,
            progressed: progressedChart,
            transits: transits,
            weather: weather
        )
        
        // Debug: Analyze token composition
        debugAnalyzeTokens(allTokens)
        
        // Generate Maria's Style Brief from tokens
        let styleBrief = generateMariaStyleBrief(from: allTokens)
        
        print("\n✨ MARIA'S STYLE BRIEF GENERATED:")
        print("  \"\(styleBrief)\"")
        print("\n🎯 DAILY VIBE GENERATOR - COMPLETE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        // Return simplified DailyVibeContent with only Style Brief populated
        return DailyVibeContent(
            styleBrief: styleBrief,
            textiles: "",     // Empty - focused only on Style Brief
            colors: "",       // Empty - focused only on Style Brief
            brightness: 50,   // Default middle value
            vibrancy: 50,     // Default middle value
            patterns: "",     // Empty - focused only on Style Brief
            shape: "",        // Empty - focused only on Style Brief
            accessories: "",  // Empty - focused only on Style Brief
            takeaway: "",     // Empty - focused only on Style Brief
            temperature: weather?.temperature,
            weatherCondition: weather?.condition
        )
    }
    
    // MARK: - Debug Methods
    
    private static func debugLogInputs(
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        moonPhase: Double) {
        
        print("\n📊 INPUT ANALYSIS:")
        print("  🎂 Natal Chart:")
        print("    • Sun: \(CoordinateTransformations.getZodiacSignName(sign: natal.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0))")
        print("    • Moon: \(CoordinateTransformations.getZodiacSignName(sign: natal.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0))")
        print("    • Ascendant: \(CoordinateTransformations.getZodiacSignName(sign: CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign))")
        
        print("  🔄 Progressed Chart:")
        print("    • Progressed Moon: \(CoordinateTransformations.getZodiacSignName(sign: progressed.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0))")
        
            print("  🌟 Transits:")
            print("    • Total Transit Aspects: \(transits.count)")
            
            // Count transits by planet with detailed orb information
            var planetCounts: [String: Int] = [:]
            var detailedTransits: [String] = []
            
            for transit in transits {
                if let planet = transit["transitPlanet"] as? String {
                    planetCounts[planet, default: 0] += 1
                    
                    // Collect detailed information for debug
                    if let natalPlanet = transit["natalPlanet"] as? String,
                       let aspectType = transit["aspectType"] as? String,
                       let orb = transit["orb"] as? Double {
                        let orbStr = String(format: "%.2f", orb)
                        detailedTransits.append("      \(planet) \(aspectType) \(natalPlanet) (orb: \(orbStr)°)")
                    }
                }
            }
            
            for (planet, count) in planetCounts.sorted(by: { $0.key < $1.key }) {
                print("      - \(planet): \(count) aspects")
            }
            
            // Show detailed transit list if there are transits
            if !detailedTransits.isEmpty {
                print("    • Detailed Aspects:")
                for transitDetail in detailedTransits.sorted() {
                    print(transitDetail)
                }
            }
        
        print("  🌙 Moon Phase: \(MoonPhaseInterpreter.formatForConsole(moonPhase))")

        
        if let weather = weather {
            print("  🌤️ Weather: \(weather.condition) (\(weather.temperature)°C)")
        } else {
            print("  🌤️ Weather: Not available")
        }
    }
    
    private static func debugAnalyzeTokens(_ tokens: [StyleToken]) {
        print("\n🔤 TOKEN ANALYSIS:")
        print("  📊 Total Tokens: \(tokens.count)")
        
        // Group by origin type
        var byOriginType: [OriginType: [StyleToken]] = [:]
        for token in tokens {
            if byOriginType[token.originType] == nil {
                byOriginType[token.originType] = []
            }
            byOriginType[token.originType]?.append(token)
        }
        
        print("  🏷️ By Origin Type:")
        for (originType, tokenGroup) in byOriginType.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            print("    • \(originType.rawValue): \(tokenGroup.count) tokens")
        }
        
        // Group by type
        var byType: [String: [StyleToken]] = [:]
        for token in tokens {
            if byType[token.type] == nil {
                byType[token.type] = []
            }
            byType[token.type]?.append(token)
        }
        
        print("  🎭 By Token Type:")
        for (type, tokenGroup) in byType.sorted(by: { $0.key < $1.key }) {
            print("    • \(type): \(tokenGroup.count) tokens")
        }
        
        // Show top 10 tokens by weight
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(10)
        print("  ⭐ Top 10 Tokens by Weight:")
        for (index, token) in topTokens.enumerated() {
            let source = token.planetarySource ?? token.aspectSource ?? "Unknown"
            print("    \(index + 1). \(token.name) (\(token.type)) - Weight: \(String(format: "%.2f", token.weight)) - Source: \(source)")
        }
        
        // Show all unique token names for complete visibility
        let uniqueNames = Set(tokens.map { $0.name }).sorted()
        print("  📝 All Token Names (\(uniqueNames.count) unique):")
        let chunkedNames = uniqueNames.chunked(into: 8)
        for chunk in chunkedNames {
            print("    • \(chunk.joined(separator: ", "))")
        }
    }
    
    // MARK: - Maria's Style Brief Generation
    
    private static func generateMariaStyleBrief(from tokens: [StyleToken]) -> String {
        print("\n🗣️ GENERATING MARIA'S STYLE BRIEF:")
        
        // Analyze token composition to determine energy and themes
        let energyLevel = analyzeEnergyLevel(from: tokens)
        let primaryThemes = extractPrimaryThemes(from: tokens)
        let dominantElements = analyzeDominantElements(from: tokens)
        
        print("  🔋 Energy Level: \(energyLevel)")
        print("  🎯 Primary Themes: \(primaryThemes.joined(separator: ", "))")
        print("  🌟 Dominant Elements: \(dominantElements.joined(separator: ", "))")
        
        // Build Maria's Style Brief components
        let opening = generateMariaOpening(energy: energyLevel, themes: primaryThemes)
        let guidance = generateMariaGuidance(energy: energyLevel, themes: primaryThemes, elements: dominantElements)
        let closing = generateMariaClosing(energy: energyLevel)
        
        let styleBrief = "\(opening) \(guidance) \(closing)"
        
        print("  💬 Components:")
        print("    Opening: \(opening)")
        print("    Guidance: \(guidance)")
        print("    Closing: \(closing)")
        
        return styleBrief
    }
    
    private static func analyzeEnergyLevel(from tokens: [StyleToken]) -> String {
        let highEnergyWords = ["dynamic", "bold", "intense", "powerful", "vibrant", "electric", "active", "strong", "assertive"]
        let mediumEnergyWords = ["balanced", "harmonious", "centered", "confident", "stable", "grounded", "focused"]
        let lowEnergyWords = ["gentle", "soft", "calm", "serene", "peaceful", "subtle", "quiet", "contemplative", "intuitive"]
        
        let tokenNames = tokens.map { $0.name.lowercased() }
        
        let highCount = highEnergyWords.filter { word in tokenNames.contains { $0.contains(word) } }.count
        let mediumCount = mediumEnergyWords.filter { word in tokenNames.contains { $0.contains(word) } }.count
        let lowCount = lowEnergyWords.filter { word in tokenNames.contains { $0.contains(word) } }.count
        
        if highCount > mediumCount && highCount > lowCount {
            return "high"
        } else if lowCount > mediumCount && lowCount > highCount {
            return "low"
        } else {
            return "balanced"
        }
    }
    
    private static func extractPrimaryThemes(from tokens: [StyleToken]) -> [String] {
        let themeMap = [
            "confidence": ["confident", "bold", "strong", "powerful", "assertive", "commanding"],
            "creativity": ["creative", "artistic", "expressive", "imaginative", "inspired", "innovative"],
            "harmony": ["harmonious", "balanced", "peaceful", "centered", "serene", "aligned"],
            "transformation": ["transformative", "evolving", "changing", "renewing", "dynamic", "shifting"],
            "intuition": ["intuitive", "inner", "wise", "insightful", "aware", "perceptive"],
            "elegance": ["elegant", "refined", "sophisticated", "graceful", "polished", "elevated"],
            "authenticity": ["authentic", "genuine", "true", "honest", "real", "sincere"]
        ]
        
        let tokenNames = tokens.map { $0.name.lowercased() }
        var themeScores: [String: Int] = [:]
        
        for (theme, keywords) in themeMap {
            let score = keywords.filter { keyword in
                tokenNames.contains { $0.contains(keyword) }
            }.count
            if score > 0 {
                themeScores[theme] = score
            }
        }
        
        let sortedThemes = themeScores.sorted { $0.value > $1.value }
        return sortedThemes.prefix(3).map { $0.key }
    }
    
    private static func analyzeDominantElements(from tokens: [StyleToken]) -> [String] {
        // Look for elemental patterns in token types and names
        let elementalMap = [
            "fire": ["bold", "vibrant", "dynamic", "active", "intense", "passionate"],
            "earth": ["grounded", "practical", "stable", "structured", "natural", "textured"],
            "air": ["light", "airy", "intellectual", "social", "communicative", "versatile"],
            "water": ["flowing", "intuitive", "emotional", "deep", "mysterious", "fluid"]
        ]
        
        let tokenNames = tokens.map { $0.name.lowercased() }
        var elementScores: [String: Int] = [:]
        
        for (element, keywords) in elementalMap {
            let score = keywords.filter { keyword in
                tokenNames.contains { $0.contains(keyword) }
            }.count
            if score > 0 {
                elementScores[element] = score
            }
        }
        
        let sortedElements = elementScores.sorted { $0.value > $1.value }
        return sortedElements.prefix(2).map { $0.key }
    }
    
    private static func generateMariaOpening(energy: String, themes: [String]) -> String {
        let primaryTheme = themes.first ?? "balance"
        
        switch energy {
        case "high":
            switch primaryTheme {
            case "confidence":
                return "Today's cosmic energy is calling you to step boldly into your power."
            case "creativity":
                return "The universe is lighting up your creative channels—this is your moment to shine."
            case "transformation":
                return "Today carries the electric energy of transformation—embrace the shift."
            default:
                return "The stars are amplifying your energy today—time to make your mark."
            }
        case "low":
            switch primaryTheme {
            case "intuition":
                return "The cosmos is whispering gentle wisdom—tune into your inner knowing today."
            case "harmony":
                return "Today's energy invites you to find your center and move from a place of peace."
            default:
                return "The universe is offering you a softer, more contemplative energy today."
            }
        default:
            return "Today offers a beautiful balance of cosmic energies to work with."
        }
    }
    
    private static func generateMariaGuidance(energy: String, themes: [String], elements: [String]) -> String {
        let primaryTheme = themes.first ?? "authenticity"
        let primaryElement = elements.first ?? ""
        
        let guidanceMap = [
            "confidence": "Choose pieces that make you feel unstoppable—think structured silhouettes and rich textures that command attention.",
            "creativity": "Let your outfit be your canvas today. Mix unexpected elements and trust your artistic instincts to guide your choices.",
            "harmony": "Seek pieces that flow together naturally, creating a sense of effortless elegance that reflects your inner peace.",
            "transformation": "This is your moment to try something new. Break from routine and let your style evolve with today's shifting energy.",
            "intuition": "Trust your first instincts when getting dressed. Your inner wisdom knows exactly what will serve you best today.",
            "elegance": "Embrace refined pieces that elevate your presence while honoring your sophisticated sensibilities.",
            "authenticity": "Choose what feels most genuinely you—authenticity is your greatest style asset today."
        ]
        
        var guidance = guidanceMap[primaryTheme] ?? guidanceMap["authenticity"]!
        
        // Add elemental influence if present
        if !primaryElement.isEmpty {
            switch primaryElement {
            case "fire":
                guidance += " Let bold colors and dynamic shapes fuel your confidence."
            case "earth":
                guidance += " Ground yourself in natural textures and dependable pieces that feel substantial."
            case "air":
                guidance += " Embrace lighter fabrics and versatile pieces that move with you."
            case "water":
                guidance += " Flow with pieces that drape beautifully and honor your emotional depth."
            default:
                break
            }
        }
        
        return guidance
    }
    
    private static func generateMariaClosing(energy: String) -> String {
        let closings = [
            "Remember, your authentic self is your greatest accessory.",
            "Trust the process—you're exactly where you need to be style-wise.",
            "Let your outfit be an extension of your inner radiance today.",
            "Your intuition about what feels right is always spot-on.",
            "Today, let your style be a celebration of who you're becoming."
        ]
        
        // Choose closing based on energy level
        switch energy {
        case "high":
            return closings[0] // Authenticity emphasis for high energy
        case "low":
            return closings[3] // Intuition emphasis for low energy
        default:
            return closings[1] // Trust emphasis for balanced energy
        }
    }
}

// MARK: - Daily Vibe Content Structure

/// Structure for daily vibe content returned by DailyVibeGenerator
struct DailyVibeContent: Codable {
    // Main content - Style Brief replaces title and mainParagraph
    var styleBrief: String = ""
    
    // Style guidance sections
    var textiles: String = ""
    var colors: String = ""
    var brightness: Int = 50 // Percentage (0-100)
    var vibrancy: Int = 50   // Percentage (0-100)
    var patterns: String = ""
    var shape: String = ""
    var accessories: String = ""

    // Final line
    var takeaway: String = ""

    // Weather information (optional)
    var temperature: Double? = nil
    var weatherCondition: String? = nil
}

// MARK: - Helper Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
