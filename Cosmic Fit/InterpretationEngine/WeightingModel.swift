//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    // Reduced natal weight to allow more daily variation (was 0.65)
    static let natalWeight: Double = 0.35
    static let currentSunSignBackgroundWeight: Double = 0.25
    
    // Enhanced Daily Fit specific weights for meaningful daily variation
    struct DailyFit {
        static let transitWeight: Double = 1.2  // Increased from 0.65 for daily Moon movement
        static let weatherWeight: Double = 0.8  // Increased from 0.12 for meaningful weather influence
        static let moonPhaseWeight: Double = 0.6  // Activated from commented out state
        static let dailySignatureWeight: Double = 0.3  // New for day-of-week energy
    }
    
    // Reduced progressed weight to allow more daily responsiveness (was 0.66)
    static let progressedWeight: Double = 0.45

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
        
        // Enhanced transit scaling for daily Moon movement
        if let transitPercent = currentDistribution["transit"] {
            if transitPercent < targetTransitInfluence * 0.8 {
                // Boost transit influence to capture daily Moon movement
                let targetFactor = targetTransitInfluence / transitPercent
                factors["transit"] = min(max(targetFactor, 1.0), 2.5)  // Allow higher boost
            } else {
                factors["transit"] = 1.0
            }
        }
        
        if let weatherPercent = currentDistribution["weather"] {
            if weatherPercent < targetWeatherInfluence * 0.5 {
                // Aggressive boost for broken weather system
                let targetFactor = targetWeatherInfluence / max(weatherPercent, 0.1)
                factors["weather"] = min(targetFactor, 5.0)  // Allow up to 5x boost
            } else {
                let targetFactor = targetWeatherInfluence / weatherPercent
                factors["weather"] = min(max(targetFactor, 0.5), 2.0)
            }
        } else {
            // Maximum boost if no weather tokens at all
            factors["weather"] = 5.0
        }
        
        // Boost moon phase influence if too low
        if let phasePercent = currentDistribution["phase"] {
            if phasePercent < 5.0 {
                factors["phase"] = min(2.0, 8.0 / max(phasePercent, 0.1))
            } else {
                factors["phase"] = 1.0
            }
        }
        
        return factors
    }
}
