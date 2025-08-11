//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    
    // MARK: - Core Chart Weights
    // Reduced natal weight to prevent dominance
    static let natalWeight: Double = 0.15 // Reduced from 0.2
    
    // MARK: - Age-Based Weighting
    static let progressedWeight: Double = 0.08 // Increased from 0.05
    
    // MARK: - Current Sun Sign Background Energy
    // Keep reduced as per previous fix
    static let currentSunSignBackgroundWeight: Double = 0.15
    
    // MARK: - Daily Fit Weights
    struct DailyFit {
        // Rebalanced for more reasonable initial distribution
        static let transitWeight: Double = 0.8 // Reduced from 1.2 (was too aggressive)
        static let progressedWeight: Double = 0.6 // Reduced from 0.8
        static let weatherWeight: Double = 0.05 // Keep as is
        static let moonPhaseWeight: Double = 0.15 // Slight increase from 0.1
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
