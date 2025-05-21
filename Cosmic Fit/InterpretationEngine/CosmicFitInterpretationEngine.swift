//
//  CosmicFitInterpretationEngine.swift
//  Cosmic Fit
//

import Foundation

/// Main entry point for the Cosmic Fit Interpretation Engine
class CosmicFitInterpretationEngine {
    
    // MARK: - Public Methods
    
    /// Generate a complete natal chart interpretation (Cosmic Blueprint)
    /// - Parameter chart: The natal chart to interpret
    /// - Returns: An interpretation result with the cosmic blueprint
    /// Generate a complete natal chart interpretation (Cosmic Blueprint)
    /// - Parameter chart: The natal chart to interpret
    /// - Parameter currentAge: User's current age for age-dependent weighting
    /// - Returns: An interpretation result with the cosmic blueprint
    static func generateBlueprintInterpretation(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
            // Debug logs
            print("\n🧩 GENERATING COSMIC FIT BLUEPRINT 🧩")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            let baseTokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart, currentAge: currentAge)
            let colorFrequencyTokens = SemanticTokenGenerator.generateColorFrequencyTokens(
                natal: chart,
                progressed: chart,
                currentAge: currentAge
            )

            var allTokens = baseTokens
            allTokens.append(contentsOf: colorFrequencyTokens)

            var birthInfoText: String? = nil
            if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
                let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
                birthInfoText = "Natal Chart: \(sunSignName) Energy"
            }

            let blueprintText = ParagraphAssembler.generateBlueprintInterpretation(
                tokens: allTokens,
                birthInfo: birthInfoText
            )

            let themeName = ThemeSelector.scoreThemes(tokens: allTokens)

            print("✅ Blueprint generated successfully!")
            print("Theme: \(themeName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

            return InterpretationResult(
                themeName: themeName,
                stitchedParagraph: blueprintText,
                tokensUsed: allTokens,
                isBlueprintReport: true
            )
        }
    
    /// Debug wrapper for blueprint generation
    static func generateBlueprintInterpretationWithDebug(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        return generateBlueprintInterpretation(from: chart, currentAge: currentAge)
    }
    
    /// Generate a daily vibe interpretation
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart (can be the same as natal chart if needed)
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A daily vibe content object with formatted sections
    /// Generate a daily vibe interpretation
    static func generateDailyVibeInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> DailyVibeContent {

        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)

        let dailyVibeContent = DailyVibeGenerator.generateDailyVibe(
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            moonPhase: lunarPhase
        )

        return dailyVibeContent
    }
    
    /// Debug wrapper for daily vibe generation
    static func generateDailyVibeInterpretationWithDebug(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> DailyVibeContent {
        return generateDailyVibeInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather
        )
    }
    
    /// Generate a combined interpretation including both blueprint and daily vibe
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A combined interpretation string
    /// Generate a combined interpretation including both blueprint and daily vibe
    static func generateFullInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> String {

        let blueprint = generateBlueprintInterpretation(from: natalChart)

        let dailyVibe = generateDailyVibeInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())

        return """
        YOUR COSMIC BLUEPRINT
        ====================

        \(blueprint.stitchedParagraph)


        TODAY'S COSMIC VIBE (\(dateString))
        ====================

        \(dailyVibe.title)

        \(dailyVibe.mainParagraph)

        TEXTILES: \(dailyVibe.textiles)

        COLORS: \(dailyVibe.colors)

        PATTERNS: \(dailyVibe.patterns)

        SHAPE: \(dailyVibe.shape)

        ACCESSORIES: \(dailyVibe.accessories)

        \(dailyVibe.takeaway)
        """
    }
    
    // MARK: - Specialized Section Generation Methods
    
    /// Generate color frequency interpretation (70% natal, 30% progressed)
    static func generateColorFrequencyInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateColorFrequencyTokens(
            natal: natalChart,
            progressed: progressedChart,
            currentAge: currentAge)

        return ParagraphAssembler.generateColorRecommendations(from: tokens)
    }
    
    /// Generate wardrobe storyline interpretation (60% progressed with Placidus, 40% natal)
    static func generateWardrobeStorylineInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateWardrobeStorylineTokens(
            natal: natalChart,
            progressed: progressedChart,
            currentAge: currentAge)

        return ParagraphAssembler.generateWardrobeStoryline(from: tokens)
    }
}
