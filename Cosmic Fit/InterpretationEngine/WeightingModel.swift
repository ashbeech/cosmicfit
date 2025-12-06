//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    // Professional astrological standards: natal chart dominance (45-55%)
    static let natalWeight: Double = 0.6  // Significantly increased to achieve 45-55% natal target
    static let currentSunSignBackgroundWeight: Double = 0.33  // Reduced to minimal seasonal background
    
    // Professional standard: 15-20% transit influence with meaningful daily variety
    struct DailyFit {
        static let transitWeight: Double = 0.55   // Significantly reduced to achieve 15-20% transit influence
        // ⚠️ weatherWeight REMOVED: Weather is now contextual only, not used in token distribution
        static let moonPhaseWeight: Double = 0.95  // ADJUSTED: Increased from 0.33 to achieve ~10% moon phase influence
        static let dailySignatureWeight: Double = 0.1  // Minimal day-of-week energy
    }
    
    // Professional range: 15-20% progressed influence  
    static let progressedWeight: Double = 20  // Maintained for 15-20% progressed influence

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
    static let minNatalInfluence: Double = 25.0
    static let targetTransitInfluence: Double = 35.0
    static let minTransitInfluence: Double = 20.0
    static let maxMoonPhaseInfluence: Double = 20.0
    static let maxDayOfWeekInfluence: Double = 10.0
    // ⚠️ targetWeatherInfluence REMOVED: Weather no longer used in distribution
    static let minProgressedInfluence: Double = 20.0
    static let maxProgressedInfluence: Double = 25.0
    
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
        
        // Ensure minimum transit influence for daily fashion variety
        if let transitPercent = currentDistribution["transit"] {
            if transitPercent < minTransitInfluence {
                // Boost transit influence to meet minimum threshold
                let targetFactor = targetTransitInfluence / max(transitPercent, 1.0)
                factors["transit"] = min(max(targetFactor, 1.0), 2.0)  // Reduced max boost from 3.0 to 2.0
            } else if transitPercent < targetTransitInfluence {
                // Moderate boost toward target
                let targetFactor = targetTransitInfluence / transitPercent
                factors["transit"] = min(max(targetFactor, 1.0), 1.3)  // Reduced max boost from 1.5 to 1.3
            } else {
                factors["transit"] = 1.0
            }
        }
        
        // ⚠️ WEATHER SCALING REMOVED: Weather no longer used in token distribution
        
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
