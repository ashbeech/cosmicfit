//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    // Core weights for Blueprint and other interpretations
    static let natalWeight: Double = 0.65
    static let currentSunSignBackgroundWeight: Double = 0.57
    
    // Daily Fit specific weights
    struct DailyFit {
        static let transitWeight: Double = 0.65
        static let weatherWeight: Double = 0.12
        //static let moonPhaseWeight: Double = 0.8 // TODO: This should, but doesn't affect anything in the result so commenting-out for now
    }
    
    // DEV NOTE TODO: Should out this in Blueprint specific weight for now
    static let progressedWeight: Double = 0.66  // DEV NOTE: This only affects wardrobe storyline in blueprint at the mo, NOT the daily fit.

}

/*
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
}*/

struct DistributionTargets {
    static let maxNatalInfluence: Double = 45.0
    static let targetTransitInfluence: Double = 20.0
    static let maxMoonPhaseInfluence: Double = 15.0
    static let maxDayOfWeekInfluence: Double = 10.0
    static let targetWeatherInfluence: Double = 10.0
    static let minProgressedInfluence: Double = 15.0  // Add minimum threshold
    static let maxProgressedInfluence: Double = 35.0  // Add maximum threshold
    
    static func getScalingFactors(currentDistribution: [String: Double]) -> [String: Double] {
        var factors: [String: Double] = [:]
        
        // Scale natal if over limit
        if let natalPercent = currentDistribution["natal"], natalPercent > maxNatalInfluence {
            factors["natal"] = maxNatalInfluence / natalPercent
        } else {
            factors["natal"] = 1.0
        }
        
        // Ensure progressed is within bounds
        if let progressedPercent = currentDistribution["progressed"] {
            if progressedPercent < minProgressedInfluence {
                factors["progressed"] = minProgressedInfluence / progressedPercent
            } else if progressedPercent > maxProgressedInfluence {
                factors["progressed"] = maxProgressedInfluence / progressedPercent
            } else {
                factors["progressed"] = 1.0
            }
        }
        
        // Scale other factors
        if let transitPercent = currentDistribution["transit"] {
            let targetFactor = targetTransitInfluence / transitPercent
            factors["transit"] = min(max(targetFactor, 0.5), 1.5)
        }
        
        if let weatherPercent = currentDistribution["weather"] {
            let targetFactor = targetWeatherInfluence / weatherPercent
            factors["weather"] = min(max(targetFactor, 0.5), 2.0)
        }
        
        return factors
    }
}
