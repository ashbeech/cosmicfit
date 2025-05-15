//
//  StyleToken.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Updated with origin tracking for Blueprint and age-dependent weighting

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
    
    // Age-dependent weighting
    func applyingAgeWeight(currentAge: Int) -> StyleToken {
        var adjustedWeight = self.weight
        
        if let planet = planetarySource {
            // Ascendant influence gradually diminishes with age
            if planet == "Ascendant" || planet == "Rising" {
                if currentAge > 30 {
                    let reductionFactor = min(0.5, Double(currentAge - 30) * 0.02)
                    adjustedWeight *= (1.0 - reductionFactor)
                }
            }
            // Sun, Saturn, Pluto, and Chiron influence increases with age
            else if planet == "Sun" {
                if currentAge > 25 {
                    let increaseFactor = min(0.4, Double(currentAge - 25) * 0.02)
                    adjustedWeight *= (1.0 + increaseFactor)
                }
            }
            else if planet == "Saturn" {
                // Saturn becomes especially important during Saturn returns (around 28-30, 56-60)
                if (currentAge >= 28 && currentAge <= 32) || (currentAge >= 56 && currentAge <= 60) {
                    adjustedWeight *= 1.4
                } else if currentAge > 30 {
                    adjustedWeight *= 1.2
                }
            }
            else if planet == "Pluto" && currentAge > 40 {
                adjustedWeight *= 1.15
            }
            else if planet == "Chiron" && currentAge >= 50 {
                adjustedWeight *= 1.25
            }
            // Moon and Venus influence remains fairly consistent throughout life
            else if planet == "Moon" || planet == "Venus" {
                // Slight adjustment based on life phases
                if currentAge < 20 {
                    adjustedWeight *= 1.1 // Slightly higher in youth
                } else if currentAge > 60 {
                    adjustedWeight *= 1.08 // Slightly higher in later years
                }
            }
            // Mars influence slightly decreases with age
            else if planet == "Mars" && currentAge > 35 {
                let reductionFactor = min(0.25, Double(currentAge - 35) * 0.01)
                adjustedWeight *= (1.0 - reductionFactor)
            }
        }
        
        return StyleToken(
            name: name,
            type: type,
            weight: adjustedWeight,
            planetarySource: planetarySource,
            signSource: signSource,
            houseSource: houseSource,
            aspectSource: aspectSource
        )
    }
}
