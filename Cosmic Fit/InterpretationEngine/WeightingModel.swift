//
//  WeightingModel.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 23/07/2025.
//

import Foundation

struct WeightingModel {
    /// Natal chart dominance weight for Style Guide token generation
    static let natalWeight: Double = 0.6
    
    /// Progressed chart influence weight for Colour Frequency tokens
    static let progressedWeight: Double = 20
}
