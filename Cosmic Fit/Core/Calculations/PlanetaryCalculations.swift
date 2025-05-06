//
//  PlanetaryCalculations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

class PlanetaryCalculations {
    // Calculate the position of the Sun
    static func calculateSunPosition(jd: Double) -> Double {
        return VSOP87Calculator.calculateSunPosition(jd: jd)
    }
    
    // Calculate the position of the Moon
    static func calculateMoonPosition(jd: Double) -> Double {
        let moonPos = VSOP87Calculator.calculateMoonPosition(jd: jd)
        return moonPos.longitude
    }
    
    // Calculate the latitude of the Moon
    static func calculateMoonLatitude(jd: Double) -> Double {
        let moonPos = VSOP87Calculator.calculateMoonPosition(jd: jd)
        return moonPos.latitude
    }
    
    // Calculate Mercury position
    static func calculateMercuryPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .mercury, jd: jd)
        return pos.longitude
    }
    
    // Calculate Venus position
    static func calculateVenusPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .venus, jd: jd)
        return pos.longitude
    }
    
    // Calculate Mars position
    static func calculateMarsPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .mars, jd: jd)
        return pos.longitude
    }
    
    // Calculate Jupiter position
    static func calculateJupiterPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .jupiter, jd: jd)
        return pos.longitude
    }
    
    // Calculate Saturn position
    static func calculateSaturnPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .saturn, jd: jd)
        return pos.longitude
    }
    
    // Calculate Uranus position
    static func calculateUranusPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .uranus, jd: jd)
        return pos.longitude
    }
    
    // Calculate Neptune position
    static func calculateNeptunePosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .neptune, jd: jd)
        return pos.longitude
    }
    
    // Calculate Pluto position
    static func calculatePlutoPosition(jd: Double) -> Double {
        let pos = VSOP87Calculator.calculatePlanetPosition(planet: .pluto, jd: jd)
        return pos.longitude
    }
    
    // Calculate North Node position
    static func calculateNorthNode(jd: Double) -> Double {
        return VSOP87Calculator.calculateNorthNodePosition(jd: jd)
    }
    
    // Calculate planetary latitude
    static func calculatePlanetLatitude(_ planet: PlanetType, jd: Double) -> Double {
        switch planet {
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
            let pos = VSOP87Calculator.calculatePlanetPosition(planet: planet, jd: jd)
            return pos.latitude
        case .moon:
            return calculateMoonLatitude(jd: jd)
        default:
            return 0.0
        }
    }
}
