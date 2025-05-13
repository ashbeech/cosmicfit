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
    
    /// Generate a daily vibe interpretation with hybrid house system approach
    /// - Parameters:
    ///   - natalChart: The natal chart for base style resonance (Whole Sign)
    ///   - progressedChart: The progressed chart for emotional vibe (Placidus)
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: An interpretation result with the daily vibe
    static func generateDailyVibeInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> InterpretationResult {
        
        print("\n☀️ GENERATING DAILY COSMIC VIBE ☀️")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Get the current lunar phase
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        
        // Generate the daily vibe using the DailyVibeGenerator
        let dailyVibeText = DailyVibeGenerator.generateDailyVibe(
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            moonPhase: lunarPhase
        )
        
        // Combine all token types for theme determination
        var allTokens: [StyleToken] = []
        
        // 1. Base style tokens (Whole Sign)
        let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
        allTokens.append(contentsOf: baseStyleTokens)
        
        // 2. Emotional vibe tokens (60% progressed Moon, 40% natal Moon, Placidus)
        let emotionalTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
            natal: natalChart,
            progressed: progressedChart
        )
        allTokens.append(contentsOf: emotionalTokens)
        
        // 3. Transit tokens (Placidus houses)
        let transitTokens = SemanticTokenGenerator.generateTransitTokens(
            transits: transits,
            natal: natalChart
        )
        allTokens.append(contentsOf: transitTokens)
        
        // Score tokens against themes to find the best-fit theme
        let themeName = ThemeSelector.scoreThemes(tokens: allTokens)
        
        print("✅ Daily vibe generated successfully!")
        print("Theme: \(themeName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: dailyVibeText,
            tokensUsed: allTokens,
            isBlueprintReport: false,
            reportDate: Date()
        )
    }
    
    // Helper method to generate daily vibe text
    private static func generateDailyVibeText(from tokens: [StyleToken], weather: TodayWeather?) -> String {
        // Get top tokens by weight
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(5)
        
        // Determine the overall mood based on tokens
        let hasBold = tokens.contains { $0.name == "bold" || $0.name == "dynamic" }
        let hasFluid = tokens.contains { $0.name == "fluid" || $0.name == "flowing" }
        let hasStructured = tokens.contains { $0.name == "structured" || $0.name == "grounded" }
        let hasEthereal = tokens.contains { $0.name == "dreamy" || $0.name == "intuitive" }
        
        var vibeText = ""
        
        // First paragraph - overall suggestion
        if hasBold {
            vibeText += "Express your dynamic energy today through pieces with presence and impact. "
            vibeText += "Choose fabrics and silhouettes that make a clear statement while maintaining your authentic comfort.\n\n"
        } else if hasFluid {
            vibeText += "Flow with today's shifting energies through pieces that move with grace and adaptability. "
            vibeText += "Embrace layers that can transition between different environments and emotional states.\n\n"
        } else if hasStructured {
            vibeText += "Ground yourself today through pieces with intentional form and substance. "
            vibeText += "Choose fabrics and silhouettes that provide a sense of stability and confidence.\n\n"
        } else if hasEthereal {
            vibeText += "Connect with your intuitive side today through pieces with subtle grace and fluidity. "
            vibeText += "Choose fabrics and silhouettes that hint at something beyond the obvious.\n\n"
        } else {
            vibeText += "Today's cosmic currents support balanced, intentional style choices that reflect your authentic self. "
            vibeText += "Choose pieces that allow you to move through the day with confidence and ease.\n\n"
        }
        
        // Second paragraph - specific elements
        vibeText += "Focus on "
        if !topTokens.isEmpty {
            let tokenNames = topTokens.map { $0.name }
            vibeText += tokenNames.joined(separator: ", ") + " elements today. "
        } else {
            vibeText += "comfortable yet expressive elements today. "
        }
        
        // Add weather-specific advice if available
        if let weather = weather {
            if weather.temp < 10 {
                vibeText += "Layer for warmth while maintaining your personal expression. "
            } else if weather.temp > 25 {
                vibeText += "Choose breathable fabrics that keep you cool while honoring your style essence. "
            }
            
            if weather.conditions.lowercased().contains("rain") {
                vibeText += "Include water-resistant pieces that protect without compromising your aesthetic."
            } else if weather.conditions.lowercased().contains("wind") {
                vibeText += "Secure your silhouette against the elements while maintaining its intentional shape."
            } else if weather.conditions.lowercased().contains("sun") {
                vibeText += "Incorporate protection from the sun that complements rather than compromises your look."
            }
        }
        
        return vibeText
    }
    
    /// Generate a combined interpretation including daily vibe and blueprint
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
        
        // Get current lunar phase
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        
        // Generate blueprint (using Whole Sign)
        let blueprint = generateBlueprintInterpretation(from: natalChart)
        
        // Generate daily vibe (using hybrid house system)
        let dailyVibe = DailyVibeGenerator.generateDailyVibe(
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            moonPhase: lunarPhase
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
        
        \(dailyVibe)
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
    
}
