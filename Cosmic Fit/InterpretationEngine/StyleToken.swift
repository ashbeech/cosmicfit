//
//  StyleToken.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Updated with origin tracking for Blueprint and age-dependent weighting
//  Enhanced with Current Sun Sign background energy support

import Foundation

// Origin type for better source-based filtering
enum OriginType: String, CaseIterable {
    case natal
    case progressed
    case transit
    case phase
    case weather
    case currentSun
    case axis  // PHASE 1: Derived axes tokens
}

struct StyleToken {
    let name: String         // e.g., "earthy", "bold", "fluid"
    let type: String         // e.g., "fabric", "mood", "color", "texture"
    let weight: Double       // numerical weight based on source importance
    
    // Origin tracking for Blueprint generation
    let planetarySource: String?  // e.g., "Sun", "Venus", "Moon", "CurrentSun"
    let signSource: String?       // e.g., "Aries", "Taurus", "Leo"
    let houseSource: Int?         // House number 1-12
    let aspectSource: String?     // e.g., "Sun trine Venus", "Current Sun in Leo"
    
    // Origin type for improved filtering and processing
    let originType: OriginType    // e.g., .natal, .progressed, .transit, .currentSun
    
    // Convenience initializer with default values
    init(name: String,
         type: String,
         weight: Double = 1.0,
         planetarySource: String? = nil,
         signSource: String? = nil,
         houseSource: Int? = nil,
         aspectSource: String? = nil,
         originType: OriginType = .natal) {
        
        self.name = name
        self.type = type
        self.weight = weight
        self.planetarySource = planetarySource
        self.signSource = signSource
        self.houseSource = houseSource
        self.aspectSource = aspectSource
        self.originType = originType
    }
    
    // Helper for debugging and validation
    func description() -> String {
        var desc = "\(name) (\(type), weight: \(String(format: "%.2f", weight)))"
        
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
        
        desc += " [\(originType.rawValue)]"
        
        return desc
    }
    
    // Age-dependent weighting
    func applyingAgeWeight(currentAge: Int) -> StyleToken {
        var adjustedWeight = self.weight
        
        if let planet = planetarySource {
            // Ascendant influence gradually diminishes with age
            if planet == "Ascendant" {
                if currentAge > 40 {
                    adjustedWeight *= 0.8
                } else if currentAge > 25 {
                    adjustedWeight *= 0.9
                }
            }
            
            // Venus influence peaks during relationship-focused years
            if planet == "Venus" {
                if currentAge >= 25 && currentAge <= 35 {
                    adjustedWeight *= 1.1
                }
            }
            
            // Saturn gains importance after Saturn return (age 29)
            if planet == "Saturn" {
                if currentAge > 29 {
                    adjustedWeight *= 1.2
                }
            }
            
            // Current Sun background energy maintains consistent influence regardless of age
            if planet == "CurrentSun" {
                // No age adjustment - this is a universal seasonal background
            }
        }
        
        return StyleToken(
            name: self.name,
            type: self.type,
            weight: adjustedWeight,
            planetarySource: self.planetarySource,
            signSource: self.signSource,
            houseSource: self.houseSource,
            aspectSource: self.aspectSource,
            originType: self.originType
        )
    }
    
    // MARK: - Token Analysis Helpers
    
    /// Check if this token represents background energy (like current Sun sign)
    var isBackgroundEnergy: Bool {
        return originType == .currentSun
    }
    
    /// Check if this token is from the natal chart
    var isNatal: Bool {
        return originType == .natal
    }
    
    /// Check if this token is from progressions
    var isProgressed: Bool {
        return originType == .progressed
    }
    
    /// Check if this token is from current transits
    var isTransit: Bool {
        return originType == .transit
    }
    
    /// Check if this token is from environmental factors (weather, phase, etc.)
    var isEnvironmental: Bool {
        return [.weather, .phase].contains(originType)
    }
    
    /// Get a user-friendly description of the token's origin
    var originDescription: String {
        switch originType {
        case .natal:
            return "Birth Chart"
        case .progressed:
            return "Life Evolution"
        case .transit:
            return "Current Cosmic Weather"
        case .phase:
            return "Daily Rhythm"
        case .weather:
            return "Environmental"
        case .currentSun:
            if let sign = signSource {
                return "\(sign) Season"
            } else {
                return "Current Season"
            }
        case .axis:
            return "Derived Kinetic Dimension"
        }
    }
    
    /// Create a copy of this token with a modified weight
    func withWeight(_ newWeight: Double) -> StyleToken {
        return StyleToken(
            name: self.name,
            type: self.type,
            weight: newWeight,
            planetarySource: self.planetarySource,
            signSource: self.signSource,
            houseSource: self.houseSource,
            aspectSource: self.aspectSource,
            originType: self.originType
        )
    }
}
