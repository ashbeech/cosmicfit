//
//  TransitWeightCalculator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//  Calculates weighted importance of transits for style influence

import Foundation

class TransitWeightCalculator {
    
    /// Calculate the weight of a transit's influence on style
    /// - Parameters:
    ///   - aspectType: Type of aspect (Conjunction, Trine, etc.)
    ///   - orb: Orb of aspect in degrees
    ///   - transitPlanet: Planet making the transit
    ///   - natalPlanet: Natal planet being transited
    ///   - natalPowerScore: Power score of the natal planet
    ///   - hitsSensitivePoint: Whether transit hits a particularly sensitive point
    /// - Returns: Weighted transit influence (0.0 to 5.0+)
    static func calculateTransitWeight(
        aspectType: String,
        orb: Double = 1.0,
        transitPlanet: String,
        natalPlanet: String,
        natalPowerScore: Double,
        hitsSensitivePoint: Bool = false
    ) -> Double {
        
        // 1. BASE ASPECT WEIGHT
        let aspectWeight = getAspectWeight(aspectType: aspectType, orb: orb)
        
        // 2. TRANSIT PLANET POWER
        let transitPowerScore = getTransitPlanetPower(transitPlanet: transitPlanet)
        
        // 3. SENSITIVE TARGET BONUS
        let sensitivityBonus = hitsSensitivePoint ? 0.3 : 0.0
        
        // 4. CONTEXT-SPECIFIC MULTIPLIER
        let contextMultiplier = PlanetPowerEvaluator.getContextMultiplier(
            natalPlanet: natalPlanet,
            transitPlanet: transitPlanet,
            aspectType: aspectType
        )
        
        // 5. FASHION RELEVANCE FILTER
        let fashionRelevanceScore = getFashionRelevanceScore(
            transitPlanet: transitPlanet,
            natalPlanet: natalPlanet,
            aspectType: aspectType
        )
        
        // FINAL CALCULATION
        let baseWeight = aspectWeight * transitPowerScore * natalPowerScore
        let adjustedWeight = baseWeight * contextMultiplier * fashionRelevanceScore
        let finalWeight = adjustedWeight + sensitivityBonus
        
        // Lower threshold should capture more transits
        return finalWeight >= 0.15 ? finalWeight : 0.0
    }
    
    /// Get weight multiplier based on aspect type and orb
    private static func getAspectWeight(aspectType: String, orb: Double) -> Double {
        // ENHANCED: Increased all base weights for better daily variation
        var baseWeight: Double
        switch aspectType {
        case "Conjunction":
            baseWeight = 3.0  // Increased from 2.5
        case "Opposition":
            baseWeight = 2.5  // Increased from 2.0
        case "Square":
            baseWeight = 2.5  // Increased from 2.0
        case "Trine":
            baseWeight = 2.0  // Increased from 1.5
        case "Sextile":
            baseWeight = 1.5  // Increased from 1.2
        case "Quincunx", "Inconjunct":
            baseWeight = 1.0  // Increased from 0.8
        case "Semisextile", "Semisquare", "Sesquisquare", "Quintile", "BiQuintile":
            baseWeight = 0.7  // Increased from 0.5
        default:
            baseWeight = 0.3  // Increased from 0.2
        }
        
        // Adjust for orb tightness
        let orbWeight: Double
        if orb <= 1.0 {
            orbWeight = 1.0  // Exact aspect
        } else if orb <= 2.0 {
            orbWeight = 0.9  // Very tight
        } else if orb <= 3.0 {
            orbWeight = 0.7  // Tight
        } else if orb <= 5.0 {
            orbWeight = 0.5  // Wide
        } else {
            orbWeight = 0.3  // Very wide
        }
        
        return baseWeight * orbWeight
    }
    
    /// Get power score for transit planet
    private static func getTransitPlanetPower(transitPlanet: String) -> Double {
        switch transitPlanet {
        case "Pluto": return 1.5
        case "Neptune": return 1.3
        case "Uranus": return 1.3
        case "Saturn": return 1.4
        case "Jupiter": return 1.2
        case "Mars": return 1.1
        case "Venus": return 1.0
        case "Mercury": return 0.9
        case "Sun": return 0.9
        case "Moon": return 1.0  // Moon is important for daily changes
        default: return 0.5
        }
    }
    
    /// Get fashion relevance score for transit-natal combination
    private static func getFashionRelevanceScore(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String
    ) -> Double {
        
        // HIGH FASHION RELEVANCE - Primary style indicators
        if (transitPlanet == "Venus" && ["Moon", "Sun", "Ascendant", "Venus"].contains(natalPlanet)) ||
           (transitPlanet == "Mars" && ["Venus", "Sun", "Ascendant", "Mars"].contains(natalPlanet)) ||
           (transitPlanet == "Moon" && ["Venus", "Sun", "Ascendant", "Moon"].contains(natalPlanet)) ||
           (transitPlanet == "Neptune" && ["Venus", "Moon"].contains(natalPlanet)) ||
           (transitPlanet == "Uranus" && ["Venus", "Sun", "Ascendant"].contains(natalPlanet)) {
            return 1.5  // INCREASED from 1.2
        }
        
        // MEDIUM FASHION RELEVANCE
        if (transitPlanet == "Jupiter" && ["Venus", "Sun"].contains(natalPlanet)) ||
           (transitPlanet == "Saturn" && ["Venus", "Mars", "Ascendant"].contains(natalPlanet)) ||
           (transitPlanet == "Pluto" && ["Venus", "Moon", "Sun"].contains(natalPlanet)) {
            return 1.2  // INCREASED from 1.0
        }
        
        // MODERATE FASHION RELEVANCE
        if (transitPlanet == "Sun" && ["Venus", "Moon"].contains(natalPlanet)) ||
           (transitPlanet == "Moon" && ["Venus", "Sun"].contains(natalPlanet)) ||
           (transitPlanet == "Mercury" && ["Venus", "Ascendant"].contains(natalPlanet)) {
            return 1.0  // INCREASED from 0.8
        }
        
        // CHECK FOR STYLE-LESS COMBINATIONS
        let nonStylePlanets = ["IC", "MC", "North Node", "South Node"]
        if nonStylePlanets.contains(transitPlanet) || nonStylePlanets.contains(natalPlanet) {
            return 0.3  // Reduced relevance for non-style planets
        }
        
        // DEFAULT FASHION RELEVANCE - INCREASED
        return 0.7  // INCREASED from 0.6
    }
    
    /// Determine if a transit meets the significance threshold
    static func isSignificantTransit(
        aspectType: String,
        orb: Double,
        transitPlanet: String,
        natalPlanet: String,
        natalPowerScore: Double
    ) -> Bool {
        let weight = calculateTransitWeight(
            aspectType: aspectType,
            orb: orb,
            transitPlanet: transitPlanet,
            natalPlanet: natalPlanet,
            natalPowerScore: natalPowerScore,
            hitsSensitivePoint: PlanetPowerEvaluator.isSensitiveTarget(natalPlanet: natalPlanet)
        )
        
        // CRITICAL FIX: Lowered threshold from 0.5 to 0.3
        return weight >= 0.3
    }
    
    /// Generate style influence category based on transit weight
    static func getStyleInfluenceCategory(weight: Double) -> StyleInfluenceCategory {
        // CRITICAL FIX: Lowered thresholds to capture more transits
        if weight >= 1.5 {  // Reduced from 2.0
            return .major
        } else if weight >= 0.8 {  // Reduced from 1.0
            return .significant
        } else if weight >= 0.4 {  // Reduced from 0.5
            return .moderate
        } else {
            return .minimal
        }
    }
    
    /// Get recommended token weight scaling based on influence category
    /// CRITICAL FIX: Significantly increased all multipliers for better token generation
    static func getTokenWeightScale(for category: StyleInfluenceCategory) -> Double {
        switch category {
        case .major:
            return 1.5  // INCREASED from 1.0 (50% boost)
        case .significant:
            return 1.2  // INCREASED from 0.7 (71% boost)
        case .moderate:
            return 0.8  // INCREASED from 0.4 (100% boost)
        case .minimal:
            return 0.3  // INCREASED from 0.1 (200% boost)
        }
    }
    
    /// Calculate multiple transits interference/amplification
    static func calculateCombinedTransitWeight(
        transitWeights: [Double],
        sameTargetPlanet: Bool = false
    ) -> Double {
        guard !transitWeights.isEmpty else { return 0.0 }
        
        if sameTargetPlanet {
            // Multiple transits to same planet can amplify or interfere
            let maxWeight = transitWeights.max() ?? 0.0
            let totalWeight = transitWeights.reduce(0, +)
            
            if transitWeights.count == 2 {
                // Two transits: can amplify significantly
                return min(maxWeight * 1.5, totalWeight * 0.8)
            } else if transitWeights.count > 2 {
                // Multiple transits: diminishing returns due to interference
                return min(maxWeight * 1.3, totalWeight * 0.6)
            } else {
                return maxWeight
            }
        } else {
            // Transits to different planets: additive but with natural limits
            let totalWeight = transitWeights.reduce(0, +)
            let averageWeight = totalWeight / Double(transitWeights.count)
            
            // Natural limit prevents style chaos from too many influences
            return min(totalWeight, averageWeight * 2.5)
        }
    }
}

/// Categories of style influence strength
enum StyleInfluenceCategory {
    case major      // Weight >= 1.5: Dominant influence on style (reduced from 2.0)
    case significant // Weight >= 0.8: Notable style shift (reduced from 1.0)
    case moderate   // Weight >= 0.4: Subtle style adjustment (reduced from 0.5)
    case minimal    // Weight < 0.4: Background influence only
}
