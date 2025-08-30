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
        
        // Apply minimum threshold - transits below 0.5 are considered background noise
        return finalWeight >= 0.5 ? finalWeight : 0.0
    }
    
    /// Get weight multiplier based on aspect type and orb
    private static func getAspectWeight(aspectType: String, orb: Double) -> Double {
        // Professional fashion-focused aspect weights (strengthened for daily variety)
        var baseWeight: Double
        switch aspectType {
        case "Conjunction":
            baseWeight = 2.5  // Increased for fashion impact
        case "Opposition":
            baseWeight = 2.0  // Increased for daily tension/balance
        case "Square":
            baseWeight = 2.0  // Increased for dynamic styling challenges
        case "Trine":
            baseWeight = 1.5  // Increased for harmonious daily flow
        case "Sextile":
            baseWeight = 1.2  // Increased for styling opportunities
        case "Quincunx", "Inconjunct":
            baseWeight = 0.8  // Increased for adjustment styling
        case "Semisextile", "Semisquare", "Sesquisquare", "Quintile", "BiQuintile":
            baseWeight = 0.5  // Increased for subtle daily accents
        default:
            baseWeight = 0.2  // Increased background influence
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
        case "Pluto":
            return 1.0  // Maximum transformative power
        case "Neptune":
            return 0.9  // Dreams, ideals, dissolution
        case "Uranus":
            return 0.9  // Revolution, innovation, liberation
        case "Saturn":
            return 0.8  // Structure, discipline, limitation
        case "Jupiter":
            return 0.7  // Expansion, opportunity, abundance
        case "Mars":
            return 0.6  // Action, energy, conflict
        case "Venus":
            return 0.6  // Harmony, beauty, relationships
        case "Sun":
            return 0.5  // Identity, vitality, purpose
        case "Mercury":
            return 0.4  // Communication, thought, movement
        case "Moon":
            return 0.4  // Emotion, instinct, daily rhythms
        case "Chiron":
            return 0.3  // Healing, teaching, wound-wisdom
        case "North Node", "South Node":
            return 0.2  // Karmic direction, evolutionary pressure
        default:
            return 0.1  // Minor asteroids or other points
        }
    }
    
    /// Calculate fashion relevance score for planet combinations
    internal static func getFashionRelevanceScore(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String
    ) -> Double {
        
        // HIGH FASHION RELEVANCE COMBINATIONS
        if (transitPlanet == "Venus" && ["Venus", "Moon", "Sun", "Ascendant"].contains(natalPlanet)) ||
           (transitPlanet == "Mars" && ["Venus", "Mars", "Ascendant"].contains(natalPlanet)) ||
           (transitPlanet == "Neptune" && ["Venus", "Moon"].contains(natalPlanet)) ||
           (transitPlanet == "Uranus" && ["Venus", "Sun", "Ascendant"].contains(natalPlanet)) {
            return 1.2  // Boost for highly fashion-relevant combinations
        }
        
        // MEDIUM FASHION RELEVANCE
        if (transitPlanet == "Jupiter" && ["Venus", "Sun"].contains(natalPlanet)) ||
           (transitPlanet == "Saturn" && ["Venus", "Mars", "Ascendant"].contains(natalPlanet)) ||
           (transitPlanet == "Pluto" && ["Venus", "Moon", "Sun"].contains(natalPlanet)) {
            return 1.0  // Standard relevance
        }
        
        // MODERATE FASHION RELEVANCE
        if (transitPlanet == "Sun" && ["Venus", "Moon"].contains(natalPlanet)) ||
           (transitPlanet == "Moon" && ["Venus", "Sun"].contains(natalPlanet)) ||
           (transitPlanet == "Mercury" && ["Venus", "Ascendant"].contains(natalPlanet)) {
            return 0.8  // Moderate relevance
        }
        
        // CHECK FOR STYLE-LESS COMBINATIONS
        let nonStylePlanets = ["IC", "MC", "North Node", "South Node"]
        if nonStylePlanets.contains(transitPlanet) || nonStylePlanets.contains(natalPlanet) {
            return 0.3  // Reduced relevance for non-style planets
        }
        
        // DEFAULT FASHION RELEVANCE
        return 0.6  // Default moderate relevance
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
        
        // Threshold for transit significance
        return weight >= 0.5
    }
    
    /// Generate style influence category based on transit weight
    static func getStyleInfluenceCategory(weight: Double) -> StyleInfluenceCategory {
        if weight >= 2.0 {
            return .major
        } else if weight >= 1.0 {
            return .significant
        } else if weight >= 0.5 {
            return .moderate
        } else {
            return .minimal
        }
    }
    
    /// Get recommended token weight scaling based on influence category
    static func getTokenWeightScale(for category: StyleInfluenceCategory) -> Double {
        switch category {
        case .major:
            return 1.0  // Full weight
        case .significant:
            return 0.7  // Significant influence
        case .moderate:
            return 0.4  // Moderate influence
        case .minimal:
            return 0.1  // Background influence
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
    case major      // Weight >= 2.0: Dominant influence on style
    case significant // Weight >= 1.0: Notable style shift
    case moderate   // Weight >= 0.5: Subtle style adjustment
    case minimal    // Weight < 0.5: Background influence only
}

