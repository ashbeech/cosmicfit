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
    static func generateBlueprintInterpretation(from chart: NatalChartCalculator.NatalChart) -> InterpretationResult {
        print("\n🧩 GENERATING COSMIC FIT BLUEPRINT 🧩")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate tokens from natal chart with Whole Sign houses for Blueprint
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart)
        
        // Format birth info for display in the blueprint header
        var birthInfoText: String? = nil
        
        // Find the Sun position for sign information
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
            birthInfoText = "Natal Chart: \(sunSignName) Energy"
        }
        
        // Generate the complete blueprint with all sections according to spec
        let blueprintText = ParagraphAssembler.generateBlueprintInterpretation(
            tokens: tokens,
            birthInfo: birthInfoText
        )
        
        // Determine the dominant theme from tokens
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        print("✅ Blueprint generated successfully!")
        print("Theme: \(themeName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: blueprintText,
            tokensUsed: tokens,
            isBlueprintReport: true
        )
    }
    
    /// Generate a daily vibe interpretation
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart (can be the same as natal chart if needed)
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A daily vibe content object with formatted sections
    static func generateDailyVibeInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> DailyVibeContent {
            
            // Get current lunar phase
            let currentDate = Date()
            let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
            let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
            
            // Generate the daily vibe content using the DailyVibeGenerator
            let dailyVibeContent = DailyVibeGenerator.generateDailyVibe(
                natalChart: natalChart,
                progressedChart: progressedChart,
                transits: transits,
                weather: weather,
                moonPhase: lunarPhase
            )
            
            return dailyVibeContent
        }
    
    /// Generate a combined interpretation including both blueprint and daily vibe
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A combined interpretation string
    static func generateFullInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> String {
            
            // Generate blueprint (using Whole Sign)
            let blueprint = generateBlueprintInterpretation(from: natalChart)
            
            // Generate daily vibe content
            let dailyVibe = generateDailyVibeInterpretation(
                from: natalChart,
                progressedChart: progressedChart,
                transits: transits,
                weather: weather
            )
            
            // Format the date for display
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: Date())
            
            // Combine the two interpretations
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
        progressedChart: NatalChartCalculator.NatalChart) -> String {
            
            // Generate tokens with specific weighting (70% natal, 30% progressed)
            let tokens = SemanticTokenGenerator.generateColorFrequencyTokens(
                natal: natalChart,
                progressed: progressedChart)
            
            // Here we'd pass these tokens to a specific color interpretation function
            // For now we'll use the standard ParagraphAssembler method
            return ParagraphAssembler.generateColorRecommendations(from: tokens)
        }
    
    /// Generate wardrobe storyline interpretation (60% progressed with Placidus, 40% natal)
    static func generateWardrobeStorylineInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart) -> String {
            
            // Generate tokens with specific weighting (60% progressed using Placidus, 40% natal)
            let tokens = SemanticTokenGenerator.generateWardrobeStorylineTokens(
                natal: natalChart,
                progressed: progressedChart)
            
            return ParagraphAssembler.generateWardrobeStoryline(from: tokens)
        }
        
    // MARK: - Debug Methods
    
    /// Generate a blueprint interpretation with detailed debug information
    static func generateBlueprintInterpretationWithDebug(from chart: NatalChartCalculator.NatalChart) -> InterpretationResult {
        print("\n🔍 GENERATING BLUEPRINT WITH DETAILED DEBUG INFO 🔍")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate tokens from natal chart with Whole Sign houses for Blueprint
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart)
        
        // Identify style tensions/conflicts in the token set
        let styleTensions = ParagraphAssembler.detectStylePushPullConflicts(from: tokens)
        if !styleTensions.isEmpty {
            print("\n🔄 STYLE TENSIONS DETECTED 🔄")
            for tension in styleTensions {
                print("  • \(tension)")
            }
            print("")
        } else {
            print("\n✅ No significant style tensions detected")
        }
        
        // Format birth info for display in the blueprint header
        var birthInfoText: String? = nil
        
        // Find the Sun position for sign information
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
            birthInfoText = "Natal Chart: \(sunSignName) Energy"
        }
        
        // Generate the complete blueprint with all sections according to spec
        let blueprintText = ParagraphAssembler.generateBlueprintInterpretation(
            tokens: tokens,
            birthInfo: birthInfoText
        )
        
        // Determine the dominant theme from tokens
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        // Get ranking of top themes for debug info
        let topThemes = ThemeSelector.rankThemes(tokens: tokens, topCount: 3)
        print("\n🔝 TOP SCORING THEMES:")
        for (i, theme) in topThemes.enumerated() {
            print("  \(i+1). \(theme.name): \(String(format: "%.2f", theme.score))")
        }
        
        print("\n✅ Debug blueprint generation complete!")
        print("Theme: \(themeName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: blueprintText,
            tokensUsed: tokens,
            isBlueprintReport: true
        )
    }
    
    /// Generate a daily vibe interpretation with detailed debug information
    static func generateDailyVibeInterpretationWithDebug(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> DailyVibeContent {
            
            print("\n🔍 GENERATING DAILY VIBE WITH DETAILED DEBUG INFO 🔍")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // Get current lunar phase
            let currentDate = Date()
            let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
            let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
            let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
            
            print("\n🌙 CURRENT MOON PHASE:")
            print("  • Phase: \(moonPhase.description)")
            print("  • Degrees: \(String(format: "%.1f", lunarPhase))°")
            
            if let weather = weather {
                print("\n☁️ CURRENT WEATHER:")
                print("  • Conditions: \(weather.conditions)")
                print("  • Temperature: \(String(format: "%.1f", weather.temp))°C")
                print("  • Humidity: \(weather.humidity)%")
                print("  • Wind: \(String(format: "%.1f", weather.windKph)) km/h")
            } else {
                print("\n⚠️ No weather data available")
            }
            
            // Generate base style tokens with Whole Sign
            let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
            
            // Generate emotional vibe tokens (60% progressed, 40% natal)
            let emotionalTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
                natal: natalChart,
                progressed: progressedChart
            )
            
            // Generate transit tokens with Placidus
            let transitTokens = SemanticTokenGenerator.generateTransitTokens(
                transits: transits,
                natal: natalChart
            )
            
            // Combine all tokens
            var allTokens = baseStyleTokens + emotionalTokens + transitTokens
            
            // Add moon phase tokens
            let moonPhaseTokens = MoonPhaseInterpreter.tokensForDailyVibe(phase: moonPhase)
            allTokens.append(contentsOf: moonPhaseTokens)
            
            // Add weather tokens if available
            if let weather = weather {
                let weatherTokens = SemanticTokenGenerator.generateWeatherTokens(weather: weather)
                allTokens.append(contentsOf: weatherTokens)
            }
            
            // Check for style tensions/conflicts
            let styleTensions = ParagraphAssembler.detectStylePushPullConflicts(from: allTokens)
            if !styleTensions.isEmpty {
                print("\n🔄 DAILY STYLE TENSIONS DETECTED 🔄")
                for tension in styleTensions {
                    print("  • \(tension)")
                }
                print("")
            } else {
                print("\n✅ No significant daily style tensions detected")
            }
            
            // Generate daily vibe content
            let dailyVibeContent = DailyVibeGenerator.generateDailyVibe(
                natalChart: natalChart,
                progressedChart: progressedChart,
                transits: transits,
                weather: weather,
                moonPhase: lunarPhase
            )
            
            // Extra debug info about the daily vibe content
            print("\n📊 DAILY VIBE CONTENT SUMMARY:")
            print("  • Title: \(dailyVibeContent.title)")
            print("  • Brightness: \(dailyVibeContent.brightness)%")
            print("  • Vibrancy: \(dailyVibeContent.vibrancy)%")
            
            print("\n✅ Debug daily vibe generation complete!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return dailyVibeContent
        }
}
