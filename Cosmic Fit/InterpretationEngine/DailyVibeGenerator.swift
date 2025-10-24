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
    ///   - profileHash: User profile identifier for daily seed generation (can be empty)
    ///   - date: Date for which to generate the vibe (defaults to today)
    ///   - weights: Weighting model to use for calculations
    /// - Returns: A DailyVibeContent with Style Brief text in Maria's voice
    static func generateDailyVibe(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        moonPhase: Double,
        profileHash: String = "",
        date: Date = Date(),
        weights: WeightingModel.Type = WeightingModel.self
    ) -> DailyVibeContent {

        print("\n🎯 DAILY VIBE GENERATOR - STYLE BRIEF FOCUS 🎯")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 STREAMLINED APPROACH:")
        print("  • Focus: Style Brief generation in Maria's voice")
        print("  • Input: All semantic tokens from interpretation engine")
        print("  • Process: Token analysis → Maria's actionable guidance")
        print("  • Output: Simplified DailyVibeContent with Style Brief")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Debug inputs
        debugLogInputs(
            natal: natalChart,
            progressed: progressedChart,
            transits: transits,
            weather: weather,
            moonPhase: moonPhase
        )

        // Build a stable seed. Prefer provided profileHash; otherwise fall back to Sun sign.
        let dailySeed: Int = {
            if !profileHash.isEmpty {
                return DailySeedGenerator.generateDailySeed(profileHash: profileHash, for: date)
            } else {
                // Fallback: derive from Sun sign + ascendant if no profileHash provided
                let sunSign = natalChart.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0
                let ascendantSign = CoordinateTransformations.decimalDegreesToZodiac(natalChart.ascendant).sign
                let fallbackId = "sun_\(sunSign)_asc_\(ascendantSign)"
                return DailySeedGenerator.generateDailySeed(profileHash: fallbackId, for: date)
            }
        }()
        print("🎲 Generated daily seed: \(dailySeed)")
        
        /*
        // Build a stable seed. Prefer provided profileHash; otherwise derive from natal chart content.
        let dailySeed: Int = {
            if !profileHash.isEmpty {
                return DailySeedGenerator.generateDailySeed(profileHash: profileHash, for: date)
            } else {
                // Derive a deterministic fingerprint from the natal chart planets that we know exist.
                // Using planet name + zodiacSign keeps it stable and privacy-safe.
                let planetFingerprint = natalChart.planets
                    .map { "\($0.name):\($0.zodiacSign)" }
                    .sorted()
                    .joined(separator: "|")
                let fallbackId = "pf_\(planetFingerprint)"
                return DailySeedGenerator.generateDailySeed(profileHash: fallbackId, for: date)
            }
        }()
        print("🎲 Generated daily seed: \(dailySeed)")
         */

        // Get all semantic tokens from interpretation engine
        let allTokens = SemanticTokenGenerator.generateDailyFitTokens(
            natal: natalChart,
            progressed: progressedChart,
            transits: transits,
            weather: weather
        )
        
        // Debug: Analyze token composition
        debugAnalyzeTokens(allTokens)
        
        // Generate all Daily System sections from tokens
        let styleBrief = generateMariaStyleBrief(from: allTokens)
        let vibeBreakdown = VibeBreakdownGenerator.generateVibeBreakdown(from: allTokens)
        
        debugVibeBreakdownAnalysis(breakdown: vibeBreakdown, tokens: allTokens)
        
        // Generate Tarot card selection with daily seed for variety
        let selectedTarotCard = TarotCardSelector.selectCard(
            for: allTokens,
            theme: nil,
            vibeBreakdown: vibeBreakdown,
            seed: dailySeed,
            profileHash: profileHash
        )
        let tarotKeywords = generateTarotKeywords(from: selectedTarotCard, tokens: allTokens)
        
        // Generate comprehensive sections
        let textiles = generateTextilesSection(from: allTokens)
        let colors = generateColorsSection(from: allTokens)
        let colorScores = ColorScoring.calculateColorScores(from: allTokens)
        let patterns = generatePatternsSection(from: allTokens)
        let shape = generateShapeSection(from: allTokens)
        let accessories = generateAccessoriesSection(from: allTokens)
        let (layering, layeringScore) = generateLayeringSection(from: allTokens, weather: weather)
        let angularCurvyScore = StructuralAxes.calculateAngularCurvyScore(from: allTokens)
        
        print("\n✨ COMPREHENSIVE DAILY SYSTEM GENERATED:")
        print("  Style Brief: \"\(styleBrief.prefix(50))...\"")
        print("  Dominant Energy: \(getDominantEnergyName(from: vibeBreakdown))")
        print("  Color Scores: D:\(colorScores.darkness) V:\(colorScores.vibrancy) C:\(colorScores.contrast)")
        print("  Angular/Curvy: \(angularCurvyScore.score)/10")
        print("  Layering Score: \(layeringScore)/10")
        if let tarotCard = selectedTarotCard {
            print("  Tarot Card: \(tarotCard.displayName)")
        }
        print("\n🎯 DAILY VIBE GENERATOR - COMPLETE")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        // Return complete DailyVibeContent with all sections populated
        var dailyContent = DailyVibeContent()
        dailyContent.tarotCard = selectedTarotCard
        dailyContent.tarotKeywords = tarotKeywords
        dailyContent.styleBrief = styleBrief
        dailyContent.textiles = textiles
        dailyContent.colors = colors
        dailyContent.colorScores = colorScores
        dailyContent.patterns = patterns
        dailyContent.shape = shape
        dailyContent.accessories = accessories
        dailyContent.layering = layering
        dailyContent.layeringScore = layeringScore
        dailyContent.vibeBreakdown = vibeBreakdown
        dailyContent.angularCurvyScore = angularCurvyScore
        dailyContent.temperature = weather?.temperature
        dailyContent.weatherCondition = weather?.condition
        
        return dailyContent
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
    
    // MARK: - Vibe Breakdown Debug Method

    private static func debugVibeBreakdownAnalysis(breakdown: VibeBreakdown, tokens: [StyleToken]) {
        
        print("\n🎨 VIBE BREAKDOWN ANALYSIS 🎨")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Show final distribution with visual bars
        print("📊 FINAL ENERGY DISTRIBUTION (21 points total):")
        printEnergyBar("Classic", breakdown.classic, 10, "🏛️")
        printEnergyBar("Playful", breakdown.playful, 10, "🎈")
        printEnergyBar("Romantic", breakdown.romantic, 10, "💕")
        printEnergyBar("Utility", breakdown.utility, 10, "🔧")
        printEnergyBar("Drama", breakdown.drama, 10, "🎭")
        printEnergyBar("Edge", breakdown.edge, 10, "⚡")
        
        // Validation check
        let total = breakdown.totalPoints
        if total == 21 {
            print("✅ Valid breakdown - Total: \(total) points")
        } else {
            print("❌ Invalid breakdown - Total: \(total) points (expected 21)")
        }
        
        // Show dominant energy
        let dominantEnergy = getDominantEnergyName(from: breakdown)
        print("⭐ Dominant Energy: \(dominantEnergy)")
        
        print("\n🔍 TOKEN MAPPING ANALYSIS:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Analyze each energy's contributing tokens
        analyzeEnergyContributors("🏛️ CLASSIC", breakdown.classic, tokens, VibeBreakdownGenerator.getClassicTokens())
        analyzeEnergyContributors("🎈 PLAYFUL", breakdown.playful, tokens, VibeBreakdownGenerator.getPlayfulTokens())
        analyzeEnergyContributors("💕 ROMANTIC", breakdown.romantic, tokens, VibeBreakdownGenerator.getRomanticTokens())
        analyzeEnergyContributors("🔧 UTILITY", breakdown.utility, tokens, VibeBreakdownGenerator.getUtilityTokens())
        analyzeEnergyContributors("🎭 DRAMA", breakdown.drama, tokens, VibeBreakdownGenerator.getDramaTokens())
        analyzeEnergyContributors("⚡ EDGE", breakdown.edge, tokens, VibeBreakdownGenerator.getEdgeTokens())
        
        print("\n📈 MAPPING LOGIC EXPLANATION:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        explainMappingLogic(breakdown: breakdown, tokens: tokens)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    // MARK: - Helper Methods for Debug Analysis

    private static func printEnergyBar(_ name: String, _ points: Int, _ maxPoints: Int, _ emoji: String) {
        let barLength = 20
        let filledLength = Int((Double(points) / Double(maxPoints)) * Double(barLength))
        let bar = String(repeating: "█", count: filledLength) + String(repeating: "░", count: barLength - filledLength)
        let percentage = points > 0 ? Int((Double(points) / 21.0) * 100) : 0
        print("  \(emoji) \(name.padding(toLength: 9, withPad: " ", startingAt: 0)): \(bar) \(points)/\(maxPoints) (\(percentage)%)")
    }

    private static func analyzeEnergyContributors(_ energyName: String, _ points: Int, _ tokens: [StyleToken], _ energyTokens: Set<String>) {
        print("\n\(energyName) ENERGY (\(points) points):")
        
        // Find tokens that contributed to this energy
        let contributors = tokens.filter { token in
            energyTokens.contains(token.name.lowercased())
        }.sorted { $0.weight > $1.weight }
        
        if contributors.isEmpty {
            print("  • No direct token matches (points from bonuses/scaling)")
        } else {
            print("  • Key Contributors:")
            for contributor in contributors.prefix(5) {
                // TODO: catch contributor.originType
                let source = contributor.planetarySource ?? contributor.aspectSource ?? "Unknown"
                print("    - \(contributor.name) (weight: \(String(format: "%.2f", contributor.weight))) from \(source)")
            }
            
            if contributors.count > 5 {
                print("    - ... and \(contributors.count - 5) more contributors")
            }
        }
        
        // Show bonus factors
        showBonusFactors(energyName, tokens)
    }

    private static func showBonusFactors(_ energyName: String, _ tokens: [StyleToken]) {
        print("  • Bonus Factors:")
        
        switch energyName.lowercased() {
        case let name where name.contains("classic"):
            let saturnTokens = tokens.filter { $0.planetarySource == "Saturn" }.count
            let highWeightTokens = tokens.filter { $0.weight > 2.0 }.count
            let earthSigns = tokens.filter {
                guard let sign = $0.signSource else { return false }
                return ["Taurus", "Virgo", "Capricorn"].contains(sign)
            }.count
            print("    - Saturn tokens: \(saturnTokens) (+1.5 each)")
            print("    - High weight tokens (>2.0): \(highWeightTokens) (+1.0 each)")
            print("    - Earth sign tokens: \(earthSigns) (+0.5 each)")
            
        case let name where name.contains("romantic"):
            let venusTokens = tokens.filter { $0.planetarySource == "Venus" }.count
            let moonTokens = tokens.filter { $0.planetarySource == "Moon" }.count
            let waterSigns = tokens.filter {
                guard let sign = $0.signSource else { return false }
                return ["Cancer", "Scorpio", "Pisces"].contains(sign)
            }.count
            print("    - Venus tokens: \(venusTokens) (+2.0 each)")
            print("    - Moon tokens: \(moonTokens) (+1.5 each)")
            print("    - Water sign tokens: \(waterSigns) (+1.0 each)")
            
        case let name where name.contains("utility"):
            let weatherTokens = tokens.filter { $0.originType == .weather }.count
            let saturnTokens = tokens.filter { $0.planetarySource == "Saturn" }.count
            print("    - Weather tokens: \(weatherTokens) (+2.0 each)")
            print("    - Saturn tokens: \(saturnTokens) (+1.5 each)")
            
        case let name where name.contains("drama"):
            let plutoTokens = tokens.filter { $0.planetarySource == "Pluto" }.count
            let marsTokens = tokens.filter { $0.planetarySource == "Mars" }.count
            let highWeightTokens = tokens.filter { $0.weight > 3.0 }.count
            let fireSigns = tokens.filter {
                guard let sign = $0.signSource else { return false }
                return ["Aries", "Leo", "Sagittarius"].contains(sign)
            }.count
            print("    - Pluto tokens: \(plutoTokens) (+2.0 each)")
            print("    - Mars tokens: \(marsTokens) (+1.0 each)")
            print("    - Very high weight tokens (>3.0): \(highWeightTokens) (+1.5 each)")
            print("    - Fire sign tokens: \(fireSigns) (+1.0 each)")
            
        case let name where name.contains("edge"):
            let uranusTokens = tokens.filter { $0.planetarySource == "Uranus" }.count
            let transitTokens = tokens.filter { token in
                token.originType == .transit &&
                ["innovative", "unexpected", "disruptive"].contains { keyword in
                    token.name.lowercased().contains(keyword)
                }
            }.count
            print("    - Uranus tokens: \(uranusTokens) (+2.5 each)")
            print("    - Innovative transit tokens: \(transitTokens) (+1.0 each)")
            
        case let name where name.contains("playful"):
            let mercuryTokens = tokens.filter { $0.planetarySource == "Mercury" }.count
            let airSigns = tokens.filter {
                guard let sign = $0.signSource else { return false }
                return ["Gemini", "Libra", "Aquarius"].contains(sign)
            }.count
            let brightColors = tokens.filter { token in
                token.type == "color_quality" &&
                ["bright", "vibrant", "electric"].contains { keyword in
                    token.name.lowercased().contains(keyword)
                }
            }.count
            print("    - Mercury tokens: \(mercuryTokens) (+1.0 each)")
            print("    - Air sign tokens: \(airSigns) (+0.5 each)")
            print("    - Bright color tokens: \(brightColors) (+1.5 each)")
            
        default:
            print("    - No specific bonus factors tracked")
        }
    }

    private static func explainMappingLogic(breakdown: VibeBreakdown, tokens: [StyleToken]) {
        
        // Explain the overall approach
        print("🔄 MAPPING PROCESS:")
        print("  1. Raw scores calculated from token matches + bonuses")
        print("  2. Weight scaling applied based on average token weight")
        print("  3. Proportional distribution to total 21 points")
        print("  4. Minimum thresholds applied (energies < 0.5 → 0)")
        print("  5. Final integer adjustment to ensure exactly 21 points")
        
        print("\n📊 TOKEN INFLUENCE SUMMARY:")
        
        // Show most influential tokens overall
        let sortedTokens = tokens.sorted { $0.weight > $1.weight }
        print("  🌟 Top 5 Most Influential Tokens:")
        for (index, token) in sortedTokens.prefix(5).enumerated() {
            let energies = getTokenEnergyMappings(token)
            let energyList = energies.isEmpty ? "none" : energies.joined(separator: ", ")
            print("    \(index + 1). \(token.name) (weight: \(String(format: "%.2f", token.weight))) → \(energyList)")
        }
        
        // Show planetary influence
        print("\n  🪐 Planetary Influence Distribution:")
        let planetaryGroups = Dictionary(grouping: tokens, by: { $0.planetarySource })
        
        for (planet, planetTokens) in planetaryGroups.sorted(by: { ($0.key ?? "") < ($1.key ?? "") }) {
            guard let planetName = planet else { continue }
            let tokenCount = planetTokens.count
            let avgWeight = planetTokens.map { $0.weight }.reduce(0, +) / Double(tokenCount)
            print("    - \(planetName): \(tokenCount) tokens (avg weight: \(String(format: "%.2f", avgWeight)))")
        }
        
        // Show origin type influence
        print("\n  📍 Origin Type Distribution:")
        let originGroups = Dictionary(grouping: tokens, by: { $0.originType })
        for (origin, originTokens) in originGroups.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let tokenCount = originTokens.count
            let totalWeight = originTokens.map { $0.weight }.reduce(0, +)
            print("    - \(origin.rawValue): \(tokenCount) tokens (total weight: \(String(format: "%.2f", totalWeight)))")
        }
    }

    private static func getTokenEnergyMappings(_ token: StyleToken) -> [String] {
        let tokenName = token.name.lowercased()
        var energies: [String] = []
        
        if VibeBreakdownGenerator.getClassicTokens().contains(tokenName) { energies.append("Classic") }
        if VibeBreakdownGenerator.getPlayfulTokens().contains(tokenName) { energies.append("Playful") }
        if VibeBreakdownGenerator.getRomanticTokens().contains(tokenName) { energies.append("Romantic") }
        if VibeBreakdownGenerator.getUtilityTokens().contains(tokenName) { energies.append("Utility") }
        if VibeBreakdownGenerator.getDramaTokens().contains(tokenName) { energies.append("Drama") }
        if VibeBreakdownGenerator.getEdgeTokens().contains(tokenName) { energies.append("Edge") }
        
        return energies
    }

    // MARK: - Maria's Style Brief Generation
    
    private static func generateMariaStyleBrief(from tokens: [StyleToken]) -> String {
        
        // Extract sun sign from tokens
        let sunSign = extractSunSignFromTokens(tokens)
        
        // Get top weighted tokens for personalization
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(3)
        let topTokenNames = topTokens.map { $0.name }
        
        // Get dominant energy context
        let vibeBreakdown = VibeBreakdownGenerator.generateVibeBreakdown(from: tokens)
        
        // Generate sun sign-specific style brief
        return generateSunSignSpecificBrief(
            sunSign: sunSign,
            topTokens: topTokenNames,
            vibeBreakdown: vibeBreakdown,
            allTokens: Array(tokens)
        )
    }
    
    // MARK: - Extract Sun Sign Helper (ADD NEW)
    private static func extractSunSignFromTokens(_ tokens: [StyleToken]) -> String {
        // Look for Sun planetary source tokens
        for token in tokens {
            if token.planetarySource == "Sun", let signSource = token.signSource {
                return signSource
            }
        }
        
        // Fallback: look for current sun sign
        for token in tokens {
            if token.planetarySource == "CurrentSun", let signSource = token.signSource {
                return signSource
            }
        }
        
        return "NULL" // Default fallback
    }
    
    // MARK: - Sun Sign Specific Brief Generator (ADD NEW)
    private static func generateSunSignSpecificBrief(
        sunSign: String,
        topTokens: [String],
        vibeBreakdown: VibeBreakdown,
        allTokens: [StyleToken]) -> String {
            
        let primaryToken = topTokens.first ?? "balanced"
        let secondaryTokens = Array(topTokens.dropFirst()).joined(separator: " and ")
        
        // Check for weather conditions
        let hasWeatherInfluence = allTokens.contains { $0.originType == .weather && $0.weight > 1.0 }
        let hasWindTokens = allTokens.contains { $0.name.contains("wind-resistant") || $0.name.contains("secure") }
        let hasRainTokens = allTokens.contains { $0.name.contains("waterproof") || $0.name.contains("practical") }
        
        switch sunSign {
        case "Taurus":
            if hasWeatherInfluence {
                return "Today calls for \(primaryToken) pieces that feel as good as they look, with practical touches for the weather. Your Taurus nature wants quality fabrics that handle whatever comes your way."
            } else if vibeBreakdown.utility > 3 {
                return "I'm sensing your practical Taurus energy today - choose \(primaryToken) pieces with \(secondaryTokens) elements. Trust your instincts on texture and lasting quality."
            } else {
                return "Today calls for \(primaryToken), luxurious pieces that feel as good as they look. Your Taurus sun wants quality fabrics with structure that speaks to your refined taste."
            }
            
        case "Scorpio":
            if hasWeatherInfluence && (hasWindTokens || hasRainTokens) {
                return "I'm sensing intense \(primaryToken) energy today, plus the weather demands strategic choices. Your Scorpio depth wants powerful pieces that protect and perform."
            } else if vibeBreakdown.utility > 4 {
                return "Your Scorpio intensity is calling for \(primaryToken) pieces with serious functionality. Choose items that reflect your depth while handling practical demands."
            } else if vibeBreakdown.drama > 5 {
                return "I'm sensing intense, transformative energy today. Your Scorpio power wants \(primaryToken) pieces that reflect your magnetic depth and inner strength."
            } else {
                return "The energy feels \(primaryToken) and mysterious today. Your Scorpio intuition knows exactly what pieces will make you feel powerfully authentic."
            }
            
        case "Cancer":
            if hasWeatherInfluence {
                return "Your intuition is spot-on today - lean into \(primaryToken) and \(secondaryTokens) pieces that make you feel emotionally secure, plus practical protection from the elements."
            } else if vibeBreakdown.romantic > 6 {
                return "Today feels deeply \(primaryToken) for you. Your Cancer moon wants pieces that feel like a warm hug while looking effortlessly beautiful."
            } else {
                return "Your intuition is spot-on today - lean into \(primaryToken) and \(secondaryTokens) pieces that make you feel emotionally secure and authentically you."
            }
            
        case "Leo":
            if vibeBreakdown.drama > 6 {
                return "Your Leo fire is blazing today! Go for \(primaryToken) and \(secondaryTokens) pieces that command attention and let your natural radiance shine through."
            } else if hasWeatherInfluence {
                return "Even with weather considerations, your Leo spirit wants to shine. Choose \(primaryToken) pieces that are both practical and gloriously you."
            } else {
                return "Today's energy is calling for bold \(primaryToken) choices. Your Leo heart wants pieces that celebrate your natural charisma and creative expression."
            }
            
        case "Virgo":
            if vibeBreakdown.utility > 5 {
                return "Your Virgo eye for perfection is in full focus today. Choose \(primaryToken) pieces with \(secondaryTokens) details that are both beautiful and brilliantly functional."
            } else if hasWeatherInfluence {
                return "Perfect timing for your practical Virgo nature - \(primaryToken) pieces that handle today's weather while maintaining your signature refined style."
            } else {
                return "Today calls for precisely \(primaryToken) pieces. Your Virgo attention to detail wants quality items that are both refined and perfectly practical."
            }
            
        case "Libra":
            if vibeBreakdown.romantic > 6 {
                return "The harmony feels perfect today for \(primaryToken) and \(secondaryTokens) pieces. Your Libra sense of beauty wants elegance that feels effortlessly balanced."
            } else if hasWeatherInfluence {
                return "Even practical weather calls for beauty - your Libra spirit wants \(primaryToken) pieces that balance function with your innate sense of style."
            } else {
                return "Today's energy feels beautifully \(primaryToken). Your Libra heart wants pieces that create perfect harmony between comfort and elegance."
            }
            
        case "Aries":
            if vibeBreakdown.drama > 5 || vibeBreakdown.playful > 5 {
                return "Your Aries fire is ready for action! Go bold with \(primaryToken) and \(secondaryTokens) pieces that match your dynamic energy and fearless spirit."
            } else if hasWeatherInfluence {
                return "Weather won't slow down your Aries energy - choose \(primaryToken) pieces that are ready for anything while keeping your pioneering spirit intact."
            } else {
                return "Today's calling for confident \(primaryToken) choices. Your Aries courage wants pieces that are as bold and direct as you are."
            }
            
        case "Gemini":
            if vibeBreakdown.playful > 5 {
                return "Your Gemini versatility is sparkling today! Mix \(primaryToken) with \(secondaryTokens) pieces - your quick wit wants options that keep things interesting."
            } else if hasWeatherInfluence {
                return "Perfect day for your adaptable Gemini nature - \(primaryToken) pieces that work with changing weather and your ever-changing mood."
            } else {
                return "Today feels mentally \(primaryToken) - your Gemini curiosity wants pieces that are as versatile and communicative as your bright mind."
            }
            
        case "Sagittarius":
            if vibeBreakdown.playful > 5 || vibeBreakdown.drama > 4 {
                return "Your Sagittarius adventure spirit is calling! Choose \(primaryToken) and \(secondaryTokens) pieces that are ready for whatever journey today brings."
            } else if hasWeatherInfluence {
                return "Weather just adds to the adventure - your Sagittarius spirit wants \(primaryToken) pieces that are optimistic, practical, and ready for anything."
            } else {
                return "The energy feels expansively \(primaryToken) today. Your Sagittarius heart wants pieces that reflect your philosophical approach to style."
            }
            
        case "Capricorn":
            if vibeBreakdown.classic > 5 || vibeBreakdown.utility > 4 {
                return "Your Capricorn mastery is in full effect today. Choose \(primaryToken) pieces with \(secondaryTokens) structure that command respect and get things done."
            } else if hasWeatherInfluence {
                return "Perfect match for your practical Capricorn nature - \(primaryToken) pieces that handle weather challenges while maintaining your authoritative presence."
            } else {
                return "Today calls for masterfully \(primaryToken) choices. Your Capricorn discipline wants pieces that are timeless, structured, and undeniably powerful."
            }
            
        case "Aquarius":
            if vibeBreakdown.edge > 3 || vibeBreakdown.playful > 5 {
                return "Your Aquarius innovation is electric today! Go for \(primaryToken) and \(secondaryTokens) pieces that express your unique vision and progressive spirit."
            } else if hasWeatherInfluence {
                return "Even weather bows to your Aquarius innovation - choose \(primaryToken) pieces that solve practical problems in your signature unconventional way."
            } else {
                return "The energy feels uniquely \(primaryToken) today. Your Aquarius originality wants pieces that are as forward-thinking and distinctive as you are."
            }
            
        case "Pisces":
            if vibeBreakdown.romantic > 6 {
                return "Your Pisces intuition is flowing beautifully today. Choose \(primaryToken) and \(secondaryTokens) pieces that feel like they're swimming in perfect harmony with your soul."
            } else if hasWeatherInfluence {
                return "Your Pisces sensitivity feels the weather shift perfectly - \(primaryToken) pieces that adapt fluidly while keeping your dreamy essence intact."
            } else {
                return "Today feels dreamily \(primaryToken). Your Pisces imagination wants pieces that are as fluid and intuitive as your compassionate heart."
            }
            
        default:
            // Generic fallback
            if hasWeatherInfluence {
                return "Today's energy feels \(primaryToken) with practical considerations. Choose pieces that balance your natural style with weather-smart functionality."
            } else {
                return "I'm sensing \(primaryToken) energy from you today. Trust yourself today - you've got this."
            }
        }
    }
    
    // MARK: - Vibe Breakdown Helper Methods
    
    private static func getDominantEnergyName(from breakdown: VibeBreakdown) -> String {
        let energies = [
            ("Classic", breakdown.classic),
            ("Playful", breakdown.playful),
            ("Romantic", breakdown.romantic),
            ("Utility", breakdown.utility),
            ("Drama", breakdown.drama),
            ("Edge", breakdown.edge)
        ]
        
        return energies.max(by: { $0.1 < $1.1 })?.0 ?? "Classic"
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
    // MARK: - Core Daily System Elements
    
    // Tarot Card Pull - represents day's overall energy
    var tarotCard: TarotCard? = nil
    var tarotKeywords: String = "" // 3 keywords separated by commas
    
    // Style Brief - 3-4 sentences in Maria's voice
    var styleBrief: String = ""
    
    // MARK: - Style Sections
    
    // Textiles Section - visual qualities and fabric feels (up to 2 sentences)
    var textiles: String = ""
    
    // Colors Section - tonal mood, palette, and scores
    var colors: String = ""
    var colorScores: ColorScores = ColorScores(darkness: 5, vibrancy: 5, contrast: 5)
    
    // Patterns Section - descriptive vocabulary for visual rhythm (up to 2 sentences)
    var patterns: String = ""
    
    // Shape Section - silhouettes and spatial flow (up to 2 sentences)
    var shape: String = ""
    
    // Accessories Section - 2-3 recommendations with texture/emotional function (up to 2 sentences)
    var accessories: String = ""
    
    // Layering Section - score out of 10 with weight/adaptability guidance (up to 2 sentences)
    var layering: String = ""
    var layeringScore: Int = 5
    
    // MARK: - Vibe Breakdown & Structural Axes
    
    // Vibe Breakdown - 21 points across 6 energies
    var vibeBreakdown: VibeBreakdown = VibeBreakdown(classic: 0, playful: 0, romantic: 0, utility: 0, drama: 0, edge: 0)
    
    // Angular vs Curvy structural axis (1-10)
    var angularCurvyScore: AngularCurvyScore = AngularCurvyScore(score: 5)
    
    // MARK: - Environmental Context
    
    // Weather information (optional)
    var temperature: Double? = nil
    var weatherCondition: String? = nil
    
    // MARK: - Legacy Properties (for transition compatibility)
    
    @available(*, deprecated, message: "Use colorScores.brightness instead")
    var brightness: Int {
        return 10 - colorScores.darkness // Inverse for backward compatibility
    }
    
    @available(*, deprecated, message: "Use colorScores.vibrancy instead")
    var vibrancy: Int {
        return colorScores.vibrancy
    }
    
    @available(*, deprecated, message: "Use styleBrief instead")
    var takeaway: String = ""
    
    // MARK: - Computed Properties
    
    // Validation method
    var isValid: Bool {
        return vibeBreakdown.isValid && !styleBrief.isEmpty
    }
    
    // Get dominant energy for UI highlighting
    var dominantEnergy: String {
        let energies = [
            ("classic", vibeBreakdown.classic),
            ("playful", vibeBreakdown.playful),
            ("romantic", vibeBreakdown.romantic),
            ("utility", vibeBreakdown.utility),
            ("drama", vibeBreakdown.drama),
            ("edge", vibeBreakdown.edge)
        ]
        
        return energies.max(by: { $0.1 < $1.1 })?.0 ?? "classic"
    }
    
    // MARK: - Daily System Formatted Output
    
    /// Generate complete Daily System formatted output
    var dailySystemOutput: String {
        var output = ""
        
        // Tarot Card Pull
        if let tarotCard = tarotCard {
            output += "🔮 TAROT CARD PULL\n"
            output += "\(tarotCard.displayName)\n"
            if !tarotKeywords.isEmpty {
                output += "\(tarotKeywords)\n\n"
            } else {
                output += "\n"
            }
        }
        
        // Style Brief
        output += "✨ STYLE BRIEF\n"
        output += "\(styleBrief)\n\n"
        
        // Textiles
        if !textiles.isEmpty {
            output += "🧵 TEXTILES\n"
            output += "\(textiles)\n\n"
        }
        
        // Colors
        if !colors.isEmpty {
            output += "🎨 COLORS\n"
            output += "\(colors)\n"
            output += "Darkness: \(colorScores.darkness)/10 (\(colorScores.darknessDescription))\n"
            output += "Vibrancy: \(colorScores.vibrancy)/10 (\(colorScores.vibrancyDescription))\n"
            output += "Contrast: \(colorScores.contrast)/10 (\(colorScores.contrastDescription))\n\n"
        }
        
        // Patterns
        if !patterns.isEmpty {
            output += "🌀 PATTERNS\n"
            output += "\(patterns)\n\n"
        }
        
        // Shape
        if !shape.isEmpty {
            output += "📐 SHAPE\n"
            output += "\(shape)\n\n"
        }
        
        // Accessories
        if !accessories.isEmpty {
            output += "💎 ACCESSORIES\n"
            output += "\(accessories)\n\n"
        }
        
        // Layering
        if !layering.isEmpty {
            output += "🧥 LAYERING\n"
            output += "Score: \(layeringScore)/10\n"
            output += "\(layering)\n\n"
        }
        
        // Vibe Breakdown
        output += "⚡ VIBE BREAKDOWN\n"
        output += "Classic: \(vibeBreakdown.classic), Playful: \(vibeBreakdown.playful), Romantic: \(vibeBreakdown.romantic)\n"
        output += "Utility: \(vibeBreakdown.utility), Drama: \(vibeBreakdown.drama), Edge: \(vibeBreakdown.edge)\n\n"
        
        // Structural Axes
        output += "📏 ANGULAR vs CURVY\n"
        output += "Score: \(angularCurvyScore.score)/10 (\(angularCurvyScore.description))\n"
        
        return output
    }
}

// MARK: - Helper Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Daily System Section Generation Extensions

extension DailyVibeGenerator {
    
    /// Generate tarot keywords (3 keywords separated by commas)
    private static func generateTarotKeywords(from tarotCard: TarotCard?, tokens: [StyleToken]) -> String {
        guard let tarotCard = tarotCard else { return "" }
        
        // Extract dominant mood tokens for keywords
        let moodTokens = tokens.filter { $0.type == "mood" }.sorted { $0.weight > $1.weight }
        let expressionTokens = tokens.filter { $0.type == "expression" }.sorted { $0.weight > $1.weight }
        
        var keywords: [String] = []
        
        // Try to get tarot-specific keywords first
        switch tarotCard.name.lowercased() {
        case "the fool":
            keywords = ["adventurous", "spontaneous", "fresh"]
        case "the magician":
            keywords = ["powerful", "focused", "transformative"]
        case "the high priestess":
            keywords = ["intuitive", "mysterious", "wise"]
        case "the empress":
            keywords = ["luxurious", "abundant", "nurturing"]
        case "the emperor":
            keywords = ["structured", "authoritative", "bold"]
        case "the hierophant":
            keywords = ["classic", "traditional", "refined"]
        case "the lovers":
            keywords = ["romantic", "harmonious", "connected"]
        case "the chariot":
            keywords = ["dynamic", "determined", "confident"]
        case "strength":
            keywords = ["powerful", "graceful", "controlled"]
        case "the hermit":
            keywords = ["introspective", "minimal", "wise"]
        case "wheel of fortune":
            keywords = ["transformative", "dynamic", "opportunistic"]
        case "justice":
            keywords = ["balanced", "structured", "purposeful"]
        case "the hanged man":
            keywords = ["flowing", "contemplative", "adaptive"]
        case "death":
            keywords = ["transformative", "dramatic", "powerful"]
        case "temperance":
            keywords = ["balanced", "harmonious", "flowing"]
        case "the devil":
            keywords = ["intense", "magnetic", "bold"]
        case "the tower":
            keywords = ["dramatic", "transformative", "striking"]
        case "the star":
            keywords = ["radiant", "hopeful", "luminous"]
        case "the moon":
            keywords = ["intuitive", "mysterious", "flowing"]
        case "the sun":
            keywords = ["radiant", "confident", "energetic"]
        case "judgement":
            keywords = ["transformative", "purposeful", "awakening"]
        case "the world":
            keywords = ["complete", "harmonious", "celebratory"]
        default:
            // Fall back to token-based keywords
            if moodTokens.count >= 2 {
                keywords.append(moodTokens[0].name)
                keywords.append(moodTokens[1].name)
            }
            if !expressionTokens.isEmpty {
                keywords.append(expressionTokens[0].name)
            }
        }
        
        // Ensure we have exactly 3 keywords
        while keywords.count < 3 && !moodTokens.isEmpty {
            for token in moodTokens {
                if !keywords.contains(token.name) {
                    keywords.append(token.name)
                    break
                }
            }
            break
        }
        
        while keywords.count < 3 && !expressionTokens.isEmpty {
            for token in expressionTokens {
                if !keywords.contains(token.name) {
                    keywords.append(token.name)
                    break
                }
            }
            break
        }
        
        // Default keywords if still insufficient
        if keywords.count < 3 {
            let defaults = ["intuitive", "expressive", "balanced"]
            for defaultKeyword in defaults {
                if keywords.count < 3 && !keywords.contains(defaultKeyword) {
                    keywords.append(defaultKeyword)
                }
            }
        }
        
        return Array(keywords.prefix(3)).joined(separator: ", ")
    }
    
    /// Generate textiles section (up to 2 sentences)
    private static func generateTextilesSection(from tokens: [StyleToken]) -> String {
        let textileTokens = tokens.filter { $0.type == "textile" }.sorted { $0.weight > $1.weight }
        let textureTokens = tokens.filter { $0.type == "texture" }.sorted { $0.weight > $1.weight }
        
        var qualities: [String] = []
        
        // Get top textile qualities
        for token in textileTokens.prefix(3) {
            qualities.append(token.name)
        }
        
        // Add texture qualities
        for token in textureTokens.prefix(2) {
            if !qualities.contains(token.name) {
                qualities.append(token.name)
            }
        }
        
        if qualities.isEmpty {
            return "Choose fabrics that feel right against your skin and move with your energy."
        }
        
        let qualitiesText = qualities.prefix(4).joined(separator: ", ")
        return "Focus on \(qualitiesText) textiles that support today's energy. Let fabric weight and surface feel guide your comfort and confidence."
    }
    
    /// Generate colors section with palette description
    private static func generateColorsSection(from tokens: [StyleToken]) -> String {
        let colorTokens = tokens.filter { $0.type == "color" || $0.type == "color_quality" }.sorted { $0.weight > $1.weight }
        
        var palette: [String] = []
        var mood = "balanced"
        
        // Extract color qualities and mood
        for token in colorTokens.prefix(3) {
            if token.type == "color_quality" {
                mood = token.name
            } else {
                palette.append(token.name)
            }
        }
        
        if palette.isEmpty {
            palette = ["natural", "harmonious"]
        }
        
        let paletteText = palette.prefix(3).joined(separator: ", ")
        return "Today's palette leans \(mood) with \(paletteText) tones that reflect your inner rhythm."
    }
    
    /// Generate patterns section (up to 2 sentences)
    private static func generatePatternsSection(from tokens: [StyleToken]) -> String {
        let patternTokens = tokens.filter { $0.type == "pattern" }.sorted { $0.weight > $1.weight }
        
        if patternTokens.isEmpty {
            return "Choose patterns that speak to your mood—whether that's clean minimalism or playful expression."
        }
        
        let topPattern = patternTokens[0].name
        var description = ""
        
        switch topPattern {
        case "geometric":
            description = "Geometric patterns with clean lines resonate with today's energy."
        case "organic":
            description = "Organic, natural patterns that flow with intuitive rhythm."
        case "abstract":
            description = "Abstract patterns that invite curiosity and conversation."
        case "flowing":
            description = "Flowing, curved patterns that move with graceful energy."
        case "angular":
            description = "Angular patterns with sharp precision and directional power."
        case "scattered":
            description = "Scattered, playful patterns that dance with spontaneous energy."
        case "symmetrical":
            description = "Symmetrical patterns that create grounding through balance."
        default:
            description = "\(topPattern.capitalized) patterns that align with your natural expression."
        }
        
        return "\(description) Look for visual rhythms that complement rather than compete with your presence."
    }
    
    /// Generate shape section (up to 2 sentences)
    private static func generateShapeSection(from tokens: [StyleToken]) -> String {
        let structureTokens = tokens.filter { $0.type == "structure" }.sorted { $0.weight > $1.weight }
        
        var shapes: [String] = []
        
        for token in structureTokens.prefix(3) {
            shapes.append(token.name)
        }
        
        if shapes.isEmpty {
            return "Choose silhouettes that honor your body's natural lines and today's energy flow."
        }
        
        let shapesText = shapes.joined(separator: ", ")
        return "Today's silhouettes lean toward \(shapesText) forms that create the right spatial relationship with your energy. Trust proportions that feel authentic to your inner rhythm."
    }
    
    /// Generate accessories section (up to 2 sentences)
    private static func generateAccessoriesSection(from tokens: [StyleToken]) -> String {
        let accessoryTokens = tokens.filter { $0.type == "accessory" }.sorted { $0.weight > $1.weight }
        
        if accessoryTokens.isEmpty {
            return "Choose accessories that add meaning rather than distraction—pieces that ground or uplift your energy."
        }
        
        var recommendations: [String] = []
        
        for token in accessoryTokens.prefix(3) {
            recommendations.append(token.name)
        }
        
        let recText = recommendations.joined(separator: ", ")
        return "Accessories with \(recText) energy will complete today's look. Choose pieces that feel like extensions of your inner state rather than afterthoughts."
    }
    
    /// Generate layering section with score (up to 2 sentences)
    private static func generateLayeringSection(from tokens: [StyleToken], weather: TodayWeather?) -> (String, Int) {
        var score = 5 // Default middle score
        
        // Weather influence on layering score
        if let weather = weather {
            if weather.temperature < 10 {
                score += 3 // Cold weather increases layering
            } else if weather.temperature < 20 {
                score += 1
            } else if weather.temperature > 25 {
                score -= 2 // Warm weather decreases layering
            }
        }
        
        // Astrological influences
        let earthTokens = tokens.filter { $0.signSource != nil && ["Taurus", "Virgo", "Capricorn"].contains($0.signSource!) }
        let waterTokens = tokens.filter { $0.signSource != nil && ["Cancer", "Scorpio", "Pisces"].contains($0.signSource!) }
        let airTokens = tokens.filter { $0.signSource != nil && ["Gemini", "Libra", "Aquarius"].contains($0.signSource!) }
        let fireTokens = tokens.filter { $0.signSource != nil && ["Aries", "Leo", "Sagittarius"].contains($0.signSource!) }
        
        // Earth signs like layering for comfort and structure
        score += min(2, earthTokens.count / 3)
        
        // Water signs like layering for emotional comfort
        score += min(1, waterTokens.count / 4)
        
        // Fire signs prefer less layering for freedom of movement
        score -= min(2, fireTokens.count / 3)
        
        // Air signs are adaptable but generally prefer lighter layering
        score -= min(1, airTokens.count / 4)
        
        // Constrain score to 1-10 range
        score = max(1, min(10, score))
        
        let guidance: String
        if score <= 3 {
            guidance = "Keep layering minimal and lightweight for freedom of movement. Choose pieces that can be easily adjusted as your energy shifts."
        } else if score <= 6 {
            guidance = "Moderate layering offers adaptability without overwhelm. Think strategic pieces that can transition with your day's rhythm."
        } else {
            guidance = "Embrace thoughtful layering that creates depth and comfort. Multiple layers can provide both practical warmth and emotional grounding."
        }
        
        return (guidance, score)
    }
}
