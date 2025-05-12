//
//  CosmicFitInterpretationEngine.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 11/05/2025.
//  Updated with detailed Blueprint specification implementation

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
        
        // Generate tokens from natal chart with enhanced source tracking
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart)
        
        // Format birth info for display in the blueprint header
        var birthInfoText: String? = nil
        
        // Find the Sun position for sign information
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSign = sunPlanet.zodiacSign
            let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunSign)
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
    
    /// Generate a daily vibe interpretation based on current transits, progressions, and weather
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: An interpretation result with the daily cosmic vibe
    static func generateDailyVibeInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> InterpretationResult {
        
        print("\n☀️ GENERATING DAILY COSMIC VIBE ☀️")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate tokens focused on daily influences
        let tokens = SemanticTokenGenerator.generateDailyVibeTokens(
            progressed: progressedChart,
            transits: transits,
            weather: weather
        )
        
        // Score tokens against themes to find the best-fit theme
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        // Create opening line based on weather if available
        var fullText = ""
        if let weather = weather {
            let tempFeeling = weather.temp < 15 ? "cool" : (weather.temp > 25 ? "warm" : "mild")
            let conditions = weather.conditions.lowercased()
            
            if conditions.contains("rain") || conditions.contains("shower") {
                fullText += "With today's wet weather and \(tempFeeling) temperatures, your cosmic vibe calls for:\n\n"
            } else if conditions.contains("cloud") {
                fullText += "Under today's cloudy skies and \(tempFeeling) air, your cosmic style suggests:\n\n"
            } else if conditions.contains("sun") || conditions.contains("clear") {
                fullText += "With today's sunny conditions and \(tempFeeling) temperatures, your cosmic fit is:\n\n"
            } else if conditions.contains("snow") {
                fullText += "In today's snowy conditions, your cosmic protection layer is:\n\n"
            } else if conditions.contains("wind") {
                fullText += "Against today's winds and \(tempFeeling) temperatures, your cosmic armor is:\n\n"
            } else {
                fullText += "Today's cosmic currents suggest:\n\n"
            }
        } else {
            fullText += "Today's cosmic currents suggest:\n\n"
        }
        
        // Generate a simpler daily vibe paragraph
        let vibeText = generateDailyVibeText(from: tokens, weather: weather)
        fullText += vibeText
        
        print("✅ Daily vibe generated successfully!")
        print("Theme: \(themeName)")
        print("Weather included: \(weather != nil)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: fullText,
            tokensUsed: tokens,
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
    
    /// Generate a combined full interpretation (blueprint + daily vibe)
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A combined interpretation with both blueprint and daily vibe
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
        
        // Format the date for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: dailyVibe.reportDate)
        
        // Combine the two interpretations
        return """
        YOUR COSMIC BLUEPRINT
        ====================
        
        \(blueprint.stitchedParagraph)
        
        
        TODAY'S COSMIC VIBE (\(dateString))
        ====================
        
        \(dailyVibe.stitchedParagraph)
        """
    }
}
