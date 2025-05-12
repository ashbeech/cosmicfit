//
//  CosmicFitInterpretationEngine.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 11/05/2025.
//

import Foundation

/// Main entry point for the Cosmic Fit Interpretation Engine
class CosmicFitInterpretationEngine {
    
    // MARK: - Public Methods
    
    /// Generate a complete natal chart interpretation (Cosmic Blueprint)
    /// - Parameter chart: The natal chart to interpret
    /// - Returns: An interpretation result with the cosmic blueprint
    static func generateBlueprintInterpretation(from chart: NatalChartCalculator.NatalChart) -> InterpretationResult {
        // Generate tokens from natal chart
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart)
        
        // Score tokens against themes to find the best-fit theme
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        // Get paragraph blocks for the selected theme
        let paragraphBlocks = ParagraphAssembler.getBlocksForTheme(themeName)
        
        // Generate the complete blueprint interpretation
        let stitchedParagraph = ParagraphAssembler.generateBlueprintInterpretation(
            themeName: themeName,
            tokens: tokens
        )
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: stitchedParagraph,
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
        
        // Generate tokens from progressed chart, transits, and weather
        let tokens = SemanticTokenGenerator.generateDailyVibeTokens(
            progressed: progressedChart,
            transits: transits,
            weather: weather
        )
        
        // Score tokens against themes to find the best-fit theme
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        // Generate the daily vibe interpretation
        let stitchedParagraph = ParagraphAssembler.generateDailyVibeInterpretation(
            themeName: themeName,
            tokens: tokens,
            weather: weather
        )
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: stitchedParagraph,
            tokensUsed: tokens,
            isBlueprintReport: false,
            reportDate: Date()
        )
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
