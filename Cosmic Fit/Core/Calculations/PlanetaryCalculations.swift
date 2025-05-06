//
//  PlanetCalculations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

class PlanetCalculations {
    // Constants
    private static let DEG_TO_RAD = Double.pi / 180.0
    private static let RAD_TO_DEG = 180.0 / Double.pi
    
    // Calculate the position of the Sun
    static func calculateSunPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        
        // Mean longitude
        let L0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        
        // Mean anomaly
        let M = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let Mrad = M * DEG_TO_RAD
        
        // Equation of center
        let C = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(Mrad) +
                (0.019993 - 0.000101 * t) * sin(2 * Mrad) +
                0.000289 * sin(3 * Mrad)
        
        // True longitude
        let trueL = L0 + C
        
        // Convert to 0-360 range
        return normalizeAngle(trueL)
    }
    
    // Calculate the position of the Moon
    static func calculateMoonPosition(jd: Double) -> Double {
        let moonPos = calculateMoonPositionFull(jd: jd)
        return moonPos.longitude
    }
    
    // Calculate the latitude of the Moon
    static func calculateMoonLatitude(jd: Double) -> Double {
        let moonPos = calculateMoonPositionFull(jd: jd)
        return moonPos.latitude
    }
    
    // Full Moon position calculation
    static func calculateMoonPositionFull(jd: Double) -> (longitude: Double, latitude: Double) {
        let t = (jd - 2451545.0) / 36525.0
        
        // Mean elements
        let L0 = 218.3164477 + 481267.88123421 * t
        let D = 297.8501921 + 445267.1114034 * t - 0.0019142 * t * t
        let M = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t
        let M1 = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t
        let F = 93.2720950 + 483202.0175233 * t - 0.0036539 * t * t
        
        // Convert to radians
        let DRad = D * DEG_TO_RAD
        let MRad = M * DEG_TO_RAD
        let M1Rad = M1 * DEG_TO_RAD
        let FRad = F * DEG_TO_RAD
        
        // Calculate E factor (Earth orbit eccentricity)
        let E = 1.0 - 0.002516 * t - 0.0000074 * t * t
        
        // Longitude terms
        var lon = L0
        lon += 6.288774 * sin(M1Rad)
        lon += 1.274027 * sin(2 * DRad - M1Rad)
        lon += 0.658314 * sin(2 * DRad)
        lon += 0.213618 * sin(2 * M1Rad)
        lon -= 0.185116 * sin(MRad) * E
        lon -= 0.114332 * sin(2 * FRad)
        lon += 0.058793 * sin(2 * DRad - 2 * M1Rad)
        lon += 0.057066 * sin(2 * DRad - MRad - M1Rad) * E
        lon += 0.053322 * sin(2 * DRad + M1Rad)
        lon += 0.045758 * sin(2 * DRad - MRad) * E
        
        // Latitude terms
        var lat = 5.128122 * sin(FRad)
        lat += 0.280602 * sin(M1Rad + FRad)
        lat += 0.277693 * sin(M1Rad - FRad)
        lat += 0.173237 * sin(2 * DRad - FRad)
        lat += 0.055413 * sin(2 * DRad - M1Rad + FRad)
        lat += 0.046271 * sin(2 * DRad - M1Rad - FRad)
        lat += 0.032573 * sin(2 * M1Rad + FRad)
        
        return (normalizeAngle(lon), lat)
    }
    
    // Calculate Mercury position
    static func calculateMercuryPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .mercury, jd: jd)
        return pos.longitude
    }
    
    // Calculate Venus position
    static func calculateVenusPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .venus, jd: jd)
        return pos.longitude
    }
    
    // Calculate Mars position
    static func calculateMarsPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .mars, jd: jd)
        return pos.longitude
    }
    
    // Calculate Jupiter position
    static func calculateJupiterPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .jupiter, jd: jd)
        return pos.longitude
    }
    
    // Calculate Saturn position
    static func calculateSaturnPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .saturn, jd: jd)
        return pos.longitude
    }
    
    // Calculate Uranus position
    static func calculateUranusPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .uranus, jd: jd)
        return pos.longitude
    }
    
    // Calculate Neptune position
    static func calculateNeptunePosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .neptune, jd: jd)
        return pos.longitude
    }
    
    // Calculate Pluto position
    static func calculatePlutoPosition(jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: .pluto, jd: jd)
        return pos.longitude
    }
    
    // Calculate North Node position
    static func calculateNorthNode(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let omega = 125.04452 - 1934.136261 * t + 0.0020708 * t * t + t * t * t / 450000.0
        return normalizeAngle(omega)
    }
    
    // Calculate planetary latitude
    static func calculatePlanetLatitude(_ planet: PlanetType, jd: Double) -> Double {
        let pos = calculatePlanetPosition(planet: planet, jd: jd)
        return pos.latitude
    }
    
    // Calculate a planet's position using Moshier's algorithms
    static func calculatePlanetPosition(planet: PlanetType, jd: Double) -> (longitude: Double, latitude: Double) {
        // Time in Julian centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0
        
        switch planet {
        case .mercury:
            // Orbital elements for Mercury
            let L = 252.250906 + 149472.6746358 * t
            let a0 = 7.00497902
            let a1 = 77.45909175 * t
            let a2 = 0.00000892 * t * t
            let a3 = 0.00000157 * t * t * t
            let M = a0 + a1 + a2 - a3
            let e = 0.20561421 + 0.00002046 * t - 0.00000003 * t * t
            let perihelion = 77.45779628 + 0.16047689 * t + 0.00000713 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation iteratively
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Simplification: assume zero latitude for Mercury
            let lat = 0.0
            
            return (normalizeAngle(lon), lat)
            
        case .venus:
            // Orbital elements for Venus
            let L = 181.979801 + 58517.8156760 * t
            let a0 = 3.39471148
            let a1 = 30.32488886 * t
            let a2 = 0.00000291 * t * t
            let M = a0 + a1 + a2
            let e = 0.00682069 - 0.00004774 * t + 0.000000091 * t * t
            let perihelion = 131.563703 + 0.00000001 * t - 0.00000144 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Simplification: assume zero latitude for Venus
            let lat = 0.0
            
            return (normalizeAngle(lon), lat)
            
        case .mars:
            // Orbital elements for Mars
            let L = 355.433275 + 19140.2993313 * t
            let a0 = 19.3870967
            let a1 = 19139.4517732 * t
            let a2 = 0.00000261 * t * t
            let a3 = 0.000000003 * t * t * t
            let M = a0 + a1 + a2 + a3
            let e = 0.09340062 - 0.000090483 * t - 0.00000000802 * t * t
            let perihelion = 336.060234 + 0.44441088 * t - 0.0000012 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Mars inclination and node for latitude
            let I = 1.85 * DEG_TO_RAD
            let node = 49.558 + 0.7721 * t
            let nodeRad = node * DEG_TO_RAD
            
            // Calculate heliocentric latitude
            let sinLonNode = sin((lon - node) * DEG_TO_RAD)
            let lat = asin(sin(I) * sinLonNode) * RAD_TO_DEG
            
            return (normalizeAngle(lon), lat)
            
        case .jupiter:
            // Orbital elements for Jupiter
            let L = 34.351484 + 3034.9056746 * t
            let a0 = 238.049257
            let a1 = 3036.301986 * t
            let a2 = 0.0000056 * t * t
            let a3 = -0.00000001 * t * t * t
            let M = a0 + a1 + a2 + a3
            let e = 0.04849485 - 0.000163244 * t - 0.0000004719 * t * t
            let perihelion = 14.331309 + 1.6126668 * t + 0.00000323 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Jupiter inclination and node
            let I = 1.3 * DEG_TO_RAD
            let node = 100.464 + 0.1767 * t
            let nodeRad = node * DEG_TO_RAD
            
            // Calculate heliocentric latitude
            let sinLonNode = sin((lon - node) * DEG_TO_RAD)
            let lat = asin(sin(I) * sinLonNode) * RAD_TO_DEG
            
            return (normalizeAngle(lon), lat)
            
        case .saturn:
            // Orbital elements for Saturn
            let L = 50.077471 + 1222.1137943 * t
            let a0 = 266.564377
            let a1 = 1223.509884 * t
            let a2 = 0.0000023 * t * t
            let a3 = -0.0000000013 * t * t * t
            let M = a0 + a1 + a2 + a3
            let e = 0.05550862 - 0.000346818 * t - 0.0000006456 * t * t
            let perihelion = 93.057237 + 1.19637613 * t + 0.00000797 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Saturn inclination and node
            let I = 2.49 * DEG_TO_RAD
            let node = 113.665 + 0.2566 * t
            let nodeRad = node * DEG_TO_RAD
            
            // Calculate heliocentric latitude
            let sinLonNode = sin((lon - node) * DEG_TO_RAD)
            let lat = asin(sin(I) * sinLonNode) * RAD_TO_DEG
            
            return (normalizeAngle(lon), lat)
            
        case .uranus:
            // Orbital elements for Uranus
            let L = 314.055005 + 429.8640561 * t
            let a0 = 244.197470
            let a1 = 429.863546 * t
            let a2 = 0.00000323 * t * t
            let a3 = 0.00000000005 * t * t * t
            let M = a0 + a1 + a2 + a3
            let e = 0.04629590 - 0.000027337 * t + 0.0000000790 * t * t
            let perihelion = 173.005159 + 0.09806522 * t + 0.00001104 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Uranus inclination and node
            let I = 0.77 * DEG_TO_RAD
            let node = 74.005 + 0.0741 * t
            let nodeRad = node * DEG_TO_RAD
            
            // Calculate heliocentric latitude
            let sinLonNode = sin((lon - node) * DEG_TO_RAD)
            let lat = asin(sin(I) * sinLonNode) * RAD_TO_DEG
            
            return (normalizeAngle(lon), lat)
            
        case .neptune:
            // Orbital elements for Neptune
            let L = 304.348665 + 219.8833092 * t
            let a0 = 84.457994
            let a1 = 219.885914 * t
            let a2 = 0.00000269 * t * t
            let a3 = -0.00000016 * t * t * t
            let M = a0 + a1 + a2 + a3
            let e = 0.00898809 + 0.000006408 * t - 0.0000000008 * t * t
            let perihelion = 48.120276 + 0.0295031 * t + 0.00000060 * t * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Neptune inclination and node
            let I = 1.77 * DEG_TO_RAD
            let node = 131.784 + 0.0061 * t
            let nodeRad = node * DEG_TO_RAD
            
            // Calculate heliocentric latitude
            let sinLonNode = sin((lon - node) * DEG_TO_RAD)
            let lat = asin(sin(I) * sinLonNode) * RAD_TO_DEG
            
            return (normalizeAngle(lon), lat)
            
        case .pluto:
            // Simplified orbital elements for Pluto
            let L = 238.9581 + 145.1781 * t
            let a0 = 14.882
            let a1 = 145.1781 * t
            let M = a0 + a1
            let e = 0.24880766
            let perihelion = 224.06 + 0.15 * t
            let Mrad = M * DEG_TO_RAD
            
            // Solve Kepler's equation
            var E = M + e * RAD_TO_DEG * sin(Mrad) * (1.0 + e * cos(Mrad))
            var Erad = E * DEG_TO_RAD
            
            for _ in 0..<5 {
                E = E - (E - e * RAD_TO_DEG * sin(Erad) - M) / (1.0 - e * cos(Erad))
                Erad = E * DEG_TO_RAD
            }
            
            // Calculate true anomaly
            let xv = cos(Erad) - e
            let yv = sqrt(1.0 - e * e) * sin(Erad)
            let v = atan2(yv, xv) * RAD_TO_DEG
            
            // Calculate ecliptic longitude
            let lon = perihelion + v
            
            // Pluto inclination is ~17° but we'll simplify
            let lat = 0.0
            
            return (normalizeAngle(lon), lat)
            
        default:
            return (0.0, 0.0)
        }
    }
    
    // Normalize angle to 0-360 degrees
    private static func normalizeAngle(_ angle: Double) -> Double {
        var result = angle
        while result >= 360.0 {
            result -= 360.0
        }
        while result < 0.0 {
            result += 360.0
        }
        return result
    }
}
