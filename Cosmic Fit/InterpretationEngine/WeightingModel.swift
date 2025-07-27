//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//

struct WeightingModel {
    
    static let natalWeight: Double = 0.45
    static let progressedWeight: Double = 0.2
    
    struct Blueprint {
    }

    struct DailyFit {
        static let transitWeight: Double = 0.15
        static let moonPhaseWeight: Double = 0.2
        static let weatherWeight: Double = 0.2
    }
}
