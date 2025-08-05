//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    
    // MARK: - Core Chart Weights
    static let natalWeight: Double = 0.2
    // MARK: - Age-Based Weighting
    static let progressedWeight: Double = 0.05
    
    // MARK: - Current Sun Sign Background Energy (NEW)
    /// Weight for the current Sun's zodiacal sign as a subtle background energy influence
    /// This provides the monthly seasonal backdrop (Leo season, Virgo season, etc.)
    /// Applied as a gentle but consistent backdrop to daily interpretations
    static let currentSunSignBackgroundWeight: Double = 0.25
    
    // MARK: - Blueprint Section Weights
    struct Blueprint {
        // Blueprint uses 100% natal chart data
        // Individual section weights are handled by paragraph assemblers
    }

    // MARK: - Daily Fit Weights
    struct DailyFit {
        static let transitWeight: Double = 0.3
        static let moonPhaseWeight: Double = 0.1
        static let weatherWeight: Double = 0.1
    }
}

struct DistributionTargets {
    static let maxNatalInfluence: Double = 45.0
    static let targetTransitInfluence: Double = 20.0
    static let maxMoonPhaseInfluence: Double = 15.0
    static let maxDayOfWeekInfluence: Double = 10.0
    static let targetWeatherInfluence: Double = 10.0
    
    static func getScalingFactors(currentDistribution: [String: Double]) -> [String: Double] {
        var factors: [String: Double] = [:]
        
        if let natalPercent = currentDistribution["natal"], natalPercent > maxNatalInfluence {
            factors["natal"] = maxNatalInfluence / natalPercent
        } else {
            factors["natal"] = 1.0
        }
        
        if let transitPercent = currentDistribution["transit"], transitPercent < targetTransitInfluence {
            factors["transit"] = targetTransitInfluence / max(transitPercent, 1.0)
        } else {
            factors["transit"] = 1.0
        }
        
        if let phasePercent = currentDistribution["phase"], phasePercent > maxMoonPhaseInfluence {
            factors["phase"] = maxMoonPhaseInfluence / phasePercent
        } else {
            factors["phase"] = 1.0
        }
        
        if let weatherPercent = currentDistribution["weather"], weatherPercent < targetWeatherInfluence {
            factors["weather"] = targetWeatherInfluence / max(weatherPercent, 1.0)
        } else {
            factors["weather"] = 1.0
        }
        
        if let dayPercent = currentDistribution["dayOfWeek"], dayPercent > maxDayOfWeekInfluence {
            factors["dayOfWeek"] = maxDayOfWeekInfluence / dayPercent
        } else {
            factors["dayOfWeek"] = 1.0
        }
        
        return factors
    }
}
