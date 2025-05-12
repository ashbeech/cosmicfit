//
//  StyleToken.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import Foundation

struct StyleToken {
    let name: String         // e.g., "earthy", "bold", "fluid"
    let type: String         // e.g., "fabric", "mood", "color", "texture"
    let weight: Double       // numerical weight based on source importance
    
    // Convenience initializer with default weight
    init(name: String, type: String, weight: Double = 1.0) {
        self.name = name
        self.type = type
        self.weight = weight
    }
}
