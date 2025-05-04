//
//  Aspect.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

struct Aspect {
    let planet1: PlanetType
    let planet2: PlanetType
    let type: AspectType
    let angle: Double
    let orb: Double
    
    // Is this aspect applying or separating?
    // (This would require speed information for planets, which we've simplified here)
    var applying: Bool?
    
    // How exact is this aspect?
    var exactness: String {
        let percentage = (1.0 - (orb / type.standardOrb)) * 100
        
        if percentage > 95 {
            return "Exact"
        } else if percentage > 80 {
            return "Strong"
        } else if percentage > 60 {
            return "Moderate"
        } else {
            return "Weak"
        }
    }
    
    // Formatted description of the aspect
    func description() -> String {
        return "\(planet1.rawValue) \(type.symbol) \(planet2.rawValue) (\(exactness), orb: \(String(format: "%.2f°", orb)))"
    }
}
