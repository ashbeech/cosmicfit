//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    // Professional astrological standards: natal chart dominance (45-55%)
    static let natalWeight: Double = 0.75  // Increased to achieve 45-55% natal target
    static let currentSunSignBackgroundWeight: Double = 0.10  // Further reduced to rebalance
    
    // Professional standard: 20-25% total daily variation
    struct DailyFit {
        static let transitWeight: Double = 0.5   // Further reduced to achieve 20-25% daily variation
        static let weatherWeight: Double = 0.4   // Reduced for modulation role, not dominance
        static let moonPhaseWeight: Double = 0.3  // Reduced for appropriate lunar influence
        static let dailySignatureWeight: Double = 0.15  // Minimal day-of-week energy
    }
    
    // Professional range: 15-20% progressed influence
    static let progressedWeight: Double = 0.25  // Reduced to fit within 15-20% professional range

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
    static let maxNatalInfluence: Double = 55.0       // Professional standard: 45-55%
    static let minNatalInfluence: Double = 45.0       // Ensure natal dominance
    static let targetTransitInfluence: Double = 18.0  // Professional standard: 15-20%
    static let maxMoonPhaseInfluence: Double = 12.0   // Reduced for balanced influence
    static let maxDayOfWeekInfluence: Double = 8.0    // Reduced for subtle daily signature
    static let targetWeatherInfluence: Double = 8.0   // Professional standard: 8-12%
    static let minProgressedInfluence: Double = 15.0  // Professional minimum
    static let maxProgressedInfluence: Double = 20.0  // Professional maximum (reduced from 35)
    
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
