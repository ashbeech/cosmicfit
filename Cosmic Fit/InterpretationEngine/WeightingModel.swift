//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//  Enhanced with Current Sun Sign Background Energy support
//

struct WeightingModel {
    
    // MARK: - Core Chart Weights
    static let natalWeight: Double = 0.30
    // MARK: - Age-Based Weighting
    static let progressedWeight: Double = 0.15
    
    // MARK: - Current Sun Sign Background Energy (NEW)
    /// Weight for the current Sun's zodiacal sign as a subtle background energy influence
    /// This provides the monthly seasonal backdrop (Leo season, Virgo season, etc.)
    /// Applied as a gentle but consistent backdrop to daily interpretations
    static let currentSunSignBackgroundWeight: Double = 0.20
        
    // MARK: - Planet Base Weights by Age
    static func getBaseWeight(for planet: String, currentAge: Int) -> Double {
        switch planet {
        case "Sun":
            return 2.5 + (Double(currentAge) / 100.0) // Increases with age
        case "Moon":
            if currentAge < 35 {
                return 2.8 // Higher in younger years
            } else {
                return 2.3 // Slightly lower but still important with maturity
            }
        case "Mercury":
            return 1.8
        case "Venus":
            if currentAge < 40 {
                return 3.0 // Peak Venus influence in relationship/aesthetic years
            } else {
                return 2.5 // Still important but refined with age
            }
        case "Mars":
            if currentAge < 30 {
                return 2.2 // Higher energy expression when younger
            } else {
                return 1.8 // More focused energy with maturity
            }
        case "Jupiter":
            if currentAge > 35 {
                return 2.0 // Increases with life experience
            } else {
                return 1.5
            }
        case "Saturn":
            if currentAge > 29 {
                return 2.2 // Post-Saturn return integration
            } else {
                return 1.5 // Less integrated before Saturn return
            }
        case "Ascendant":
            if currentAge < 25 {
                return 3.5 // Peak influence during identity formation
            } else if currentAge < 40 {
                return 2.8 // Still significant but integrating
            } else {
                return 2.0 // More integrated, less externally defining
            }
        case "Uranus", "Neptune", "Pluto":
            return 1.0 // Generational influences
        case "Chiron":
            if currentAge > 30 {
                return 1.5 // Healing integration increases with age
            } else {
                return 1.0
            }
        default:
            return 1.0
        }
    }
    
    // MARK: - Blueprint Section Weights
    struct Blueprint {
        // Blueprint uses 100% natal chart data
        // Individual section weights are handled by paragraph assemblers
    }

    // MARK: - Daily Fit Weights
    struct DailyFit {
        static let transitWeight: Double = 0.35
        static let moonPhaseWeight: Double = 0.30
        static let weatherWeight: Double = 0.40
    }
    
    // MARK: - Helper Methods
    
    /// Calculate total weight allocation to ensure proper balance
    static var totalCoreWeight: Double {
        return natalWeight + progressedWeight + currentSunSignBackgroundWeight +
               DailyFit.transitWeight + DailyFit.moonPhaseWeight + DailyFit.weatherWeight
    }
    
    /// Validate that weights sum to reasonable totals (should be around 1.4-1.6 for overlapping influences)
    static func validateWeights() -> Bool {
        let total = totalCoreWeight
        return total >= 1.2 && total <= 1.8 // Allow for intentional weight overlap
    }
    
    /// Get a descriptive breakdown of current weight allocation
    static func getWeightBreakdown() -> String {
        return """
        Core Chart Weights:
        • Natal: \(natalWeight) (\(Int(natalWeight * 100))%)
        • Progressed: \(progressedWeight) (\(Int(progressedWeight * 100))%)
        • Current Sun Background: \(currentSunSignBackgroundWeight) (\(Int(currentSunSignBackgroundWeight * 100))%)
        
        Daily Fit Modifiers:
        • Transits: \(DailyFit.transitWeight) (\(Int(DailyFit.transitWeight * 100))%)
        • Moon Phase: \(DailyFit.moonPhaseWeight) (\(Int(DailyFit.moonPhaseWeight * 100))%)
        • Weather: \(DailyFit.weatherWeight) (\(Int(DailyFit.weatherWeight * 100))%)
        
        Total Weight: \(totalCoreWeight) (\(Int(totalCoreWeight * 100))%)
        """
    }
}
