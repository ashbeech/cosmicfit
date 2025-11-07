//
//  AstroFeaturesBuilder.swift
//  Cosmic Fit
//
//  Created for Phase 1: Axis Token Source Implementation
//  Builds AstroFeatures struct from natal chart, progressed chart, and transits
//

import Foundation

/// Utility for building AstroFeatures from chart data
final class AstroFeaturesBuilder {
    
    // MARK: - Build Astro Features
    
    /// Build AstroFeatures from chart data
    /// - Parameters:
    ///   - natalChart: Natal chart
    ///   - progressedChart: Progressed chart
    ///   - transits: Array of typed TransitAspect structs (not dictionaries!)
    ///   - lunarPhase: Current lunar phase (EXPECTED: 0-1 range where 0=new moon, 0.5=full moon)
    ///   - weather: Optional weather data
    /// - Returns: AstroFeatures struct
    static func buildFeatures(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        lunarPhase: Double,
        weather: TodayWeather?
    ) -> AstroFeatures {
        
        // Convert natal chart aspects
        let natalAspects = extractAspectsFromChart(natalChart)
        
        // Convert progressed chart aspects
        let progressedAspects = extractAspectsFromChart(progressedChart)
        
        // Convert transit aspects from typed structs
        let transitAspects = extractAspectsFromTypedTransits(transits)
        
        // LUNAR PHASE: Input is expected to be 0-1 range already (0=new, 0.5=full, 1=new)
        // No conversion needed - use as-is
        let normalisedLunarPhase = lunarPhase
        
        if normalisedLunarPhase < 0 || normalisedLunarPhase > 1 {
            print("⚠️ WARNING: Lunar phase \(lunarPhase) outside expected 0-1 range")
        }
        
        return AstroFeatures(
            natalAspects: natalAspects,
            transitAspects: transitAspects,
            progressedAspects: progressedAspects,
            lunarPhase: normalisedLunarPhase,
            weatherConditions: weather
        )
    }
    
    // MARK: - Private Extraction Methods
    
    /// Extract aspects from a natal/progressed chart by calculating them from planet positions
    private static func extractAspectsFromChart(_ chart: NatalChartCalculator.NatalChart) -> [Aspect] {
        var aspects: [Aspect] = []
        
        let planets = chart.planets
        
        // Calculate aspects between all pairs of planets
        for i in 0..<planets.count {
            for j in (i+1)..<planets.count {
                let planet1 = planets[i]
                let planet2 = planets[j]
                
                // Calculate angular separation using longitudes
                var separation = abs(planet1.longitude - planet2.longitude)
                if separation > 180 {
                    separation = 360 - separation
                }
                
                // Check for major aspects
                if let aspect = identifyAspect(separation: separation) {
                    let orb = abs(separation - aspect.exactDegrees)
                    
                    // Only include if within orb tolerance
                    if orb <= aspect.orbTolerance {
                        aspects.append(Aspect(
                            planet1: planet1.name,
                            planet2: planet2.name,
                            type: aspect.name,
                            orb: orb,
                            isApplying: true  // Can't determine from static positions
                        ))
                    }
                }
            }
        }
        
        return aspects
    }
    
    /// Extract aspects from typed TransitAspect structs (PREFERRED)
    private static func extractAspectsFromTypedTransits(_ transits: [NatalChartCalculator.TransitAspect]) -> [Aspect] {
        #if DEBUG
        print("🔍 AstroFeaturesBuilder: extractAspectsFromTypedTransits called with \(transits.count) transit entries")
        #endif
        
        return transits.map { transit in
            Aspect(
                planet1: transit.transitPlanet,
                planet2: transit.natalPlanet,
                type: transit.aspectType,
                orb: abs(transit.orb),
                isApplying: transit.applying
            )
        }
    }
    
    /// Extract aspects from transit dictionaries (DEPRECATED - kept for compatibility)
    /// Use extractAspectsFromTypedTransits instead
    private static func extractAspectsFromTransits(_ transits: [[String: Any]]) -> [Aspect] {
        var aspects: [Aspect] = []
        
        #if DEBUG
        print("⚠️ AstroFeaturesBuilder: Using DEPRECATED dictionary-based transit parsing")
        print("   Called with \(transits.count) transit entries")
        if transits.isEmpty {
            print("  ⚠️ Transit array is EMPTY - this means aspects won't be included in axis calculation")
        } else if transits.count > 0 {
            print("  📋 First transit entry keys: \(transits[0].keys.joined(separator: ", "))")
        }
        #endif
        
        for transit in transits {
            // Try both camelCase and snake_case keys for compatibility
            let transitPlanet = transit["transitPlanet"] as? String ?? transit["transit_planet"] as? String
            let natalPlanet = transit["natalPlanet"] as? String ?? transit["natal_planet"] as? String
            let aspectType = transit["aspectType"] as? String ?? transit["aspect_type"] as? String
            let orb = transit["orb"] as? Double
            
            guard let transitPlanet = transitPlanet,
                  let natalPlanet = natalPlanet,
                  let aspectType = aspectType,
                  let orb = orb else {
                #if DEBUG
                if !transit.isEmpty {
                    print("  ❌ Failed to parse transit: \(transit.keys.joined(separator: ", "))")
                }
                #endif
                continue
            }
            
            let isApplying = (transit["applying"] as? Bool) ?? (transit["is_applying"] as? Bool) ?? true
            
            let aspect = Aspect(
                planet1: transitPlanet,
                planet2: natalPlanet,
                type: aspectType,
                orb: abs(orb),
                isApplying: isApplying
            )
            
            aspects.append(aspect)
        }
        
        return aspects
    }
    
    // MARK: - Aspect Detection
    
    /// Identify which aspect (if any) a given angular separation represents
    private static func identifyAspect(separation: Double) -> (name: String, exactDegrees: Double, orbTolerance: Double)? {
        let aspectDefinitions: [(name: String, degrees: Double, orb: Double)] = [
            ("Conjunction", 0, 8),
            ("Sextile", 60, 6),
            ("Square", 90, 8),
            ("Trine", 120, 8),
            ("Opposition", 180, 8),
            ("Quincunx", 150, 3)
        ]
        
        for aspectDef in aspectDefinitions {
            let diff = abs(separation - aspectDef.degrees)
            if diff <= aspectDef.orb {
                return (aspectDef.name, aspectDef.degrees, aspectDef.orb)
            }
        }
        
        return nil
    }
}

