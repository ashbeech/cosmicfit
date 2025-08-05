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
