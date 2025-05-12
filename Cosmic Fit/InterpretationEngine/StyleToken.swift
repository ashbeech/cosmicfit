//
//  StyleToken.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Updated with origin tracking for Blueprint

import Foundation

struct StyleToken {
    let name: String         // e.g., "earthy", "bold", "fluid"
    let type: String         // e.g., "fabric", "mood", "color", "texture"
    let weight: Double       // numerical weight based on source importance
    
    // Origin tracking for Blueprint generation
    let planetarySource: String?  // e.g., "Sun", "Venus", "Moon"
    let signSource: String?       // e.g., "Aries", "Taurus"
    let houseSource: Int?         // House number 1-12
    let aspectSource: String?     // e.g., "Sun trine Venus"
    
    // Convenience initializer with default values
    init(name: String,
         type: String,
         weight: Double = 1.0,
         planetarySource: String? = nil,
         signSource: String? = nil,
         houseSource: Int? = nil,
         aspectSource: String? = nil) {
        
        self.name = name
        self.type = type
        self.weight = weight
        self.planetarySource = planetarySource
        self.signSource = signSource
        self.houseSource = houseSource
        self.aspectSource = aspectSource
    }
    
    // Helper for debugging and validation
    func description() -> String {
        var desc = "\(name) (\(type), weight: \(weight))"
        
        if let planet = planetarySource {
            desc += " from \(planet)"
        }
        
        if let sign = signSource {
            desc += " in \(sign)"
        }
        
        if let house = houseSource {
            desc += " in house \(house)"
        }
        
        if let aspect = aspectSource {
            desc += " via \(aspect)"
        }
        
        return desc
    }
}
