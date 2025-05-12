//
//  NatalChartManager+Interpretation.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 11/05/2025.
//

import Foundation
import CoreLocation

// Extension to integrate the Cosmic Fit Interpretation Engine
extension NatalChartManager {
    
    /// Generate a cosmic blueprint interpretation
    /// - Parameter chart: The natal chart to interpret
    /// - Returns: A string containing the blueprint interpretation
    func generateBlueprintInterpretation(for chart: NatalChartCalculator.NatalChart) -> String {
        let interpretation = CosmicFitInterpretationEngine.generateBlueprintInterpretation(from: chart)
        return interpretation.stitchedParagraph
    }
    
    /// Generate a daily vibe interpretation
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
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
}
