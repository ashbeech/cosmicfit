//
//  AspectCalculations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

class AspectCalculations {
    // Calculate aspects between planets
    static func calculateAspects(planets: [Planet]) -> [Aspect] {
        var aspects: [Aspect] = []
        
        for i in 0..<planets.count {
            for j in (i+1)..<planets.count {
                if let aspect = calculateAspect(planet1: planets[i], planet2: planets[j]) {
                    aspects.append(aspect)
                }
            }
        }
        
        return aspects
    }
    
    // Calculate aspect between two planets
    static func calculateAspect(planet1: Planet, planet2: Planet) -> Aspect? {
        // Calculate the angle between two planets
        var angle = abs(planet1.longitude - planet2.longitude)
        if angle > 180.0 {
            angle = 360.0 - angle
        }
        
        // Define aspect types and their orbs (allowed deviation)
        let aspectTypes: [(type: AspectType, angle: Double, orb: Double)] = [
            (.conjunction, 0.0, 10.0),
            (.opposition, 180.0, 10.0),
            (.trine, 120.0, 8.0),
            (.square, 90.0, 8.0),
            (.sextile, 60.0, 6.0),
            (.quincunx, 150.0, 3.0),
            (.semisextile, 30.0, 3.0)
        ]
        
        // Find matching aspect type
        for aspectType in aspectTypes {
            let deviation = abs(angle - aspectType.angle)
            if deviation <= aspectType.orb {
                return Aspect(
                    planet1: planet1.type,
                    planet2: planet2.type,
                    type: aspectType.type,
                    angle: angle,
                    orb: deviation,
                    applying: nil
                )
            }
        }
        
        return nil // No aspect found within allowed orbs
    }
    
    // Filter aspects by strength
    static func filterAspectsByStrength(aspects: [Aspect], minimumStrength: Double = 0.5) -> [Aspect] {
        return aspects.filter { aspect in
            let strength = 1.0 - (aspect.orb / aspect.type.standardOrb)
            return strength >= minimumStrength
        }
    }
    
    // Get major aspects only (conjunction, opposition, trine, square, sextile)
    static func getMajorAspects(aspects: [Aspect]) -> [Aspect] {
        return aspects.filter { aspect in
            [.conjunction, .opposition, .trine, .square, .sextile].contains(aspect.type)
        }
    }
}
