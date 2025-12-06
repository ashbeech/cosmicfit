//
//  StyleToken.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Updated with origin tracking for Style Guide and age-dependent weighting
//  Enhanced with Current Sun Sign background energy support

import Foundation

// Origin type for better source-based filtering
enum OriginType: String, CaseIterable, Codable {
    case natal
    case progressed
    case transit
    case phase
    case weather
    case currentSun
    case axis  // PHASE 1: Derived axes tokens
}

// MARK: - Tier 2 Related Enums (Currently Unused)
// NOTE: These properties support a Tier 2 token system that is implemented but not active.
// Current architecture uses pre-written templates instead of dynamic token generation.
// Properties kept for future flexibility. See Tier2TokenLibrary.swift for full implementation.

// Token tier for distinguishing foundational vs applied tokens
enum TokenTier: String, Codable {
    case tier1_energetic  // Foundational energy tokens (e.g., "fluid", "bold") - CURRENTLY USED
    case tier2_applied    // Applied style tokens (e.g., "bias_cut", "matte_finish") - NOT CURRENTLY USED
}

// Effort level for style variations (e.g., High Priestess low/medium/high effort)
enum EffortLevel: String, Codable {
    case low
    case medium
    case high
}

struct StyleToken: Codable {
    let name: String         // e.g., "earthy", "bold", "fluid" (Tier 1) OR "bias_cut", "matte_finish" (Tier 2)
    let type: String         // e.g., "fabric", "mood", "colour", "texture" (Tier 1) OR "silhouette", "surface_finish" (Tier 2)
    let weight: Double       // numerical weight based on source importance
    
    // Origin tracking for Style Guide generation
    let planetarySource: String?  // e.g., "Sun", "Venus", "Moon", "CurrentSun"
    let signSource: String?       // e.g., "Aries", "Taurus", "Leo"
    let houseSource: Int?         // House number 1-12
    let aspectSource: String?     // e.g., "Sun trine Venus", "Current Sun in Leo"
    
    // Origin type for improved filtering and processing
    let originType: OriginType    // e.g., .natal, .progressed, .transit, .currentSun
    
    // Tier 2 specific properties
    let tier: TokenTier           // .tier1_energetic or .tier2_applied
    let sourceEnergyTokens: [String]?  // For Tier 2: which Tier 1 tokens generated this (e.g., ["fluid", "soft"])
    let oppositeOf: String?       // For push-pull detection (e.g., "matte_finish" opposite of "shiny")
    let effortLevel: EffortLevel? // For style variations (e.g., High Priestess low/medium/high)
    let tags: [String]?           // Additional searchable metadata
    
    // Convenience initializer with default values (backward compatible for Tier 1)
    init(name: String,
         type: String,
         weight: Double = 1.0,
         planetarySource: String? = nil,
         signSource: String? = nil,
         houseSource: Int? = nil,
         aspectSource: String? = nil,
         originType: OriginType = .natal,
         tier: TokenTier = .tier1_energetic,
         sourceEnergyTokens: [String]? = nil,
         oppositeOf: String? = nil,
         effortLevel: EffortLevel? = nil,
         tags: [String]? = nil) {
        
        self.name = name
        self.type = type
        self.weight = weight
        self.planetarySource = planetarySource
        self.signSource = signSource
        self.houseSource = houseSource
        self.aspectSource = aspectSource
        self.originType = originType
        self.tier = tier
        self.sourceEnergyTokens = sourceEnergyTokens
        self.oppositeOf = oppositeOf
        self.effortLevel = effortLevel
        self.tags = tags
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
            originType: self.originType,
            tier: self.tier,
            sourceEnergyTokens: self.sourceEnergyTokens,
            oppositeOf: self.oppositeOf,
            effortLevel: self.effortLevel,
            tags: self.tags
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
            originType: self.originType,
            tier: self.tier,
            sourceEnergyTokens: self.sourceEnergyTokens,
            oppositeOf: self.oppositeOf,
            effortLevel: self.effortLevel,
            tags: self.tags
        )
    }
    
    // MARK: - Tier 2 Helpers
    
    /// Check if this is a Tier 1 energetic token
    var isTier1: Bool {
        return tier == .tier1_energetic
    }
    
    /// Check if this is a Tier 2 applied token
    var isTier2: Bool {
        return tier == .tier2_applied
    }
    
    /// Get a description that includes tier information
    func detailedDescription() -> String {
        var desc = description()
        desc += " [Tier: \(tier.rawValue)]"
        
        if let sourceEnergies = sourceEnergyTokens {
            desc += " (from: \(sourceEnergies.joined(separator: ", ")))"
        }
        
        if let opposite = oppositeOf {
            desc += " (opposite: \(opposite))"
        }
        
        if let effort = effortLevel {
            desc += " (effort: \(effort.rawValue))"
        }
        
        if let tokenTags = tags {
            desc += " [tags: \(tokenTags.joined(separator: ", "))]"
        }
        
        return desc
    }
}
