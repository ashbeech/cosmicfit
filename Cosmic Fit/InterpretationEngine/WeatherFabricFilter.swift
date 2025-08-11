//
// WeatherFabricFilter.swift
// Cosmic Fit
//
// Hard filtering system for weather-based fabric recommendations
// Replaces weighted weather tokens with conditional logic
//

import Foundation

class WeatherFabricFilter {
    
    // MARK: - Temperature Thresholds
    private static let hotThreshold: Double = 25.0 // Celsius
    private static let coldThreshold: Double = 10.0 // Celsius
    private static let windyThreshold: Double = 20.0 // km/h
    
    // MARK: - Fabric Categories
    struct FabricCategories {
        static let warmFabrics = ["knits", "wool", "cashmere", "fleece", "thick cotton", "heavy jersey"]
        static let coolFabrics = ["linen", "silk", "light cotton", "gauze", "lightweight modal", "bamboo"]
        static let waterproofFabrics = ["waterproof", "water-resistant", "coated cotton", "rain-ready"]
        static let windResistantFabrics = ["wind-resistant", "tightly woven", "structured canvas"]
    }
    
    // MARK: - Hard Filter Methods
    
    /// Apply hard weather filters to fabric recommendations
    /// - Parameters:
    ///   - weather: Current weather conditions
    ///   - baseFabrics: Base fabric recommendations from chart analysis
    /// - Returns: Filtered fabric recommendations with weather practicality applied
    static func applyWeatherFilters(
        weather: TodayWeather?,
        baseFabrics: [String]) -> [String] {
        
        guard let weather = weather else {
            return baseFabrics // No weather data, return unfiltered
        }
        
        var filteredFabrics = baseFabrics
        var requiredFabrics: [String] = []
        var excludedFabrics: [String] = []
        
        // Temperature-based hard filters
        if weather.temperature > hotThreshold {
            excludedFabrics.append(contentsOf: FabricCategories.warmFabrics)
            requiredFabrics.append(contentsOf: FabricCategories.coolFabrics)
            
            DebugLogger.info("🌡️ HOT WEATHER FILTER: Excluded warm fabrics, prioritized cool fabrics")
        } else if weather.temperature < coldThreshold {
            excludedFabrics.append(contentsOf: FabricCategories.coolFabrics)
            requiredFabrics.append(contentsOf: FabricCategories.warmFabrics)
            
            DebugLogger.info("❄️ COLD WEATHER FILTER: Excluded cool fabrics, prioritized warm fabrics")
        }
        
        // Condition-based hard filters
        let condition = weather.condition.lowercased()
        if condition.contains("rain") || condition.contains("shower") || condition.contains("storm") {
            requiredFabrics.append(contentsOf: FabricCategories.waterproofFabrics)
            DebugLogger.info("☔️ RAIN FILTER: Added waterproof fabric requirements")
        }
        
        // Wind-based hard filters
        if weather.windKph > windyThreshold {
            requiredFabrics.append(contentsOf: FabricCategories.windResistantFabrics)
            DebugLogger.info("💨 WIND FILTER: Added wind-resistant fabric requirements")
        }
        
        // Apply exclusions
        filteredFabrics = filteredFabrics.filter { fabric in
            !excludedFabrics.contains { excluded in
                fabric.lowercased().contains(excluded.lowercased())
            }
        }
        
        // Add required fabrics (but avoid duplicates)
        for required in requiredFabrics {
            if !filteredFabrics.contains(where: { $0.lowercased().contains(required.lowercased()) }) {
                filteredFabrics.append(required)
            }
        }
        
        return filteredFabrics
    }
    
    /// Generate weather-specific fabric guidance text
    /// - Parameter weather: Current weather conditions
    /// - Returns: Human-readable fabric guidance based on weather
    static func generateWeatherFabricGuidance(weather: TodayWeather?) -> String {
        guard let weather = weather else {
            return "" // No additional weather guidance
        }
        
        var guidance: [String] = []
        
        // Temperature guidance
        if weather.temperature > hotThreshold {
            guidance.append("Choose breathable, lightweight fabrics to stay cool")
        } else if weather.temperature < coldThreshold {
            guidance.append("Opt for insulating, warm fabrics for comfort")
        }
        
        // Condition guidance
        let condition = weather.condition.lowercased()
        if condition.contains("rain") || condition.contains("shower") {
            guidance.append("Prioritize water-resistant materials")
        }
        
        if weather.windKph > windyThreshold {
            guidance.append("Select wind-resistant, structured pieces")
        }
        
        return guidance.isEmpty ? "" : " Weather note: " + guidance.joined(separator: "; ") + "."
    }
    
    /// Check if weather should override chart-based fabric preferences
    /// - Parameter weather: Current weather conditions
    /// - Returns: True if weather conditions require hard overrides
    static func requiresWeatherOverride(weather: TodayWeather?) -> Bool {
        guard let weather = weather else { return false }
        
        return weather.temperature > hotThreshold ||
               weather.temperature < coldThreshold ||
               weather.condition.lowercased().contains("rain") ||
               weather.condition.lowercased().contains("storm") ||
               weather.windKph > windyThreshold
    }
    
    /// Resolve conflicts between chart preferences and weather requirements
    /// - Parameters:
    ///   - chartPreferences: Base preferences from astrological analysis
    ///   - weatherRequirements: Weather-based practical requirements
    /// - Returns: Merged recommendations prioritizing chart aesthetics with weather practicality
    static func resolveChartWeatherConflicts(
        chartPreferences: [String],
        weatherRequirements: [String]) -> [String] {
        
        // Start with chart preferences (aesthetic priority)
        var mergedRecommendations = chartPreferences
        
        // Add weather requirements that don't conflict aesthetically
        for requirement in weatherRequirements {
            let conflicts = mergedRecommendations.contains { preference in
                // Check for direct contradictions
                (requirement.contains("warm") && preference.contains("cool")) ||
                (requirement.contains("cool") && preference.contains("warm")) ||
                (requirement.contains("heavy") && preference.contains("light")) ||
                (requirement.contains("light") && preference.contains("heavy"))
            }
            
            if !conflicts {
                mergedRecommendations.append(requirement)
            } else {
                // For conflicts, add as practical guidance note
                mergedRecommendations.append("practical: \(requirement)")
            }
        }
        
        return mergedRecommendations
    }
}
