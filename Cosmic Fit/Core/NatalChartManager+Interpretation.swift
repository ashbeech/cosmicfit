//
//  NatalChartManager+Interpretation.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 11/05/2025.
//  Updated with Blueprint specification implementation

import Foundation
import CoreLocation

// Extension to integrate the Cosmic Fit Interpretation Engine
extension NatalChartManager {
    
    /// Generate a cosmic blueprint interpretation based on natal chart
    /// - Parameter chart: The natal chart to interpret
    /// - Returns: A string containing the blueprint interpretation
    func generateBlueprintInterpretation(for chart: NatalChartCalculator.NatalChart) -> String {
        let interpretation = CosmicFitInterpretationEngine.generateBlueprintInterpretation(from: chart)
        return interpretation.stitchedParagraph
    }
    
    /// Generate a daily vibe interpretation
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart (can be the same as natal chart if needed)
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A string containing the daily vibe interpretation
    func generateDailyVibeInterpretation(
        for natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> String {
        
        let interpretation = CosmicFitInterpretationEngine.generateDailyVibeInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather
        )
        
        return interpretation.stitchedParagraph
    }
    
    /// Generate a complete interpretation including both blueprint and daily vibe
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A string containing the full interpretation
    func generateFullInterpretation(
        for natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> String {
        
        return CosmicFitInterpretationEngine.generateFullInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather
        )
    }
    
    /// Generate a custom style guidance for a specific situation
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - query: The styling situation/query (e.g., "job interview", "date night")
    /// - Returns: A string containing customized style guidance
    func generateCustomStyleGuidance(
        for natalChart: NatalChartCalculator.NatalChart,
        query: String) -> String {
        
        // Generate tokens from natal chart
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: natalChart)
        
        // Score tokens against themes to find the best-fit theme
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        // Generate custom guidance based on the query and theme
        var guidance = "Custom Style Guidance: \(query)\n\n"
        
        // Add theme-specific recommendations
        guidance += "Based on your Cosmic Blueprint theme of \"\(themeName)\", here are styling recommendations for \(query):\n\n"
        
        // Add situation-specific guidance
        let situationGuidance = generateSituationGuidance(query: query, tokens: tokens, themeName: themeName)
        guidance += situationGuidance
        
        return guidance
    }
    
    // MARK: - Helper Methods
    
    /// Generate situation-specific style guidance
    private func generateSituationGuidance(query: String, tokens: [StyleToken], themeName: String) -> String {
        // This would be expanded to handle various types of situations
        // For now, a simple implementation
        
        // Look for dominant style characteristics
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 2.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 2.0 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 2.0 }
        let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 2.0 }
        
        let query = query.lowercased()
        
        if query.contains("interview") || query.contains("professional") || query.contains("work") {
            if hasStructured {
                return "For this professional setting, lean into your natural affinity for structure with a well-tailored silhouette. Choose pieces with clean lines and subtle details that communicate competence and attention to detail."
            } else if hasFluid {
                return "While maintaining professional standards, incorporate your natural fluidity through softer tailoring and layers that move with intention. Balance structure with flow for a unique professional presence."
            } else if hasBold {
                return "Channel your bold energy into statement pieces with strong lines, while keeping the overall look professionally appropriate. Consider a distinctive jacket or accessory that expresses your confident presence."
            } else {
                return "Create a professional silhouette that honors your authentic style essence. Focus on quality materials and thoughtful details that reflect your attention to both appearance and substance."
            }
        } else if query.contains("date") || query.contains("romantic") {
            if hasBold {
                return "Express your natural confidence through one bold element that draws attention - perhaps color, texture, or an interesting silhouette. Balance this with more subtle complementary pieces."
            } else if hasSubtle {
                return "Your subtle style shines in intimate settings. Focus on textures that invite closeness and details that reveal themselves only upon closer inspection. Quality and thoughtfulness will speak louder than obvious statements."
            } else {
                return "Choose pieces that make you feel most authentically yourself, focusing on comfort and personal expression. Your genuine presence is the most attractive element you can bring to this occasion."
            }
        } else if query.contains("casual") || query.contains("weekend") || query.contains("relax") {
            if hasStructured {
                return "Even in casual settings, your structured essence appreciates some intentional form. Look for relaxed pieces with thoughtful details and a more refined cut than standard casual wear."
            } else if hasFluid {
                return "Your natural fluidity thrives in casual settings. Embrace layered, easy-wearing pieces that move with you and transition gracefully between activities."
            } else {
                return "Casual doesn't mean careless for you. Select pieces that feel like an authentic extension of your style essence, focusing on comfort without sacrificing your personal aesthetic standards."
            }
        } else {
            // Generic guidance
            return "Consider this occasion as an opportunity to express your authentic style essence. Select pieces that align with your Blueprint theme of \"\(themeName)\", focusing on your natural affinities while adapting appropriately to the specific context."
        }
    }
}
