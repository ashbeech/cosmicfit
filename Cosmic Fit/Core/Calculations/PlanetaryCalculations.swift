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
        // Time in Julian centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0
        
        // Mean longitude of the Sun
        var L0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        
        // Mean anomaly of the Sun
        let M = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let MRad = AstronomicalUtils.degreesToRadians(M)
        
        // Eccentricity of Earth's orbit
        let e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t
        
        // Sun's equation of center
        let C = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(MRad) +
                (0.019993 - 0.000101 * t) * sin(2 * MRad) +
                0.000289 * sin(3 * MRad)
        
        // True longitude of the Sun
        let sunLongitude = L0 + C
        
        return AstronomicalUtils.normalizeAngle(sunLongitude)
    }
    
    // Calculate the position of the Moon
    static func calculateMoonPosition(jd: Double) -> Double {
        // Time in Julian centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0
        
        // Mean longitude of the Moon
        let L0 = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t + t * t * t / 538841.0 - t * t * t * t / 65194000.0
        
        // Mean elongation of the Moon
        let D = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t + t * t * t / 545868.0 - t * t * t * t / 113065000.0
        let DRad = AstronomicalUtils.degreesToRadians(D)
        
        // Mean anomaly of the Sun
        let M = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t + t * t * t / 24490000.0
        let MRad = AstronomicalUtils.degreesToRadians(M)
        
        // Mean anomaly of the Moon
        let M1 = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t + t * t * t / 69699.0 - t * t * t * t / 14712000.0
        let M1Rad = AstronomicalUtils.degreesToRadians(M1)
        
        // Moon's argument of latitude
        let F = 93.2720950 + 483202.0175233 * t - 0.0036539 * t * t - t * t * t / 3526000.0 + t * t * t * t / 863310000.0
        let FRad = AstronomicalUtils.degreesToRadians(F)
        
        // Correction for eccentricity
        let E1 = 1.0 - 0.002516 * t - 0.0000074 * t * t
        
        // Ecliptic longitude of the Moon (simplified)
        let moonLongitude = L0 +
            6.288774 * sin(M1Rad) +
            1.274027 * sin(2 * DRad - M1Rad) +
            0.658314 * sin(2 * DRad) +
            0.213618 * sin(2 * M1Rad) -
            0.185116 * sin(MRad) * E1 -
            0.114332 * sin(2 * FRad)
        
        return AstronomicalUtils.normalizeAngle(moonLongitude)
    }
    
    // Calculate the latitude of the Moon
    static func calculateMoonLatitude(jd: Double) -> Double {
        // Time in Julian centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0
        
        // Mean elongation of the Moon
        let D = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t + t * t * t / 545868.0 - t * t * t * t / 113065000.0
        let DRad = AstronomicalUtils.degreesToRadians(D)
        
        // Mean anomaly of the Sun
        let M = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t + t * t * t / 24490000.0
        let MRad = AstronomicalUtils.degreesToRadians(M)
        
        // Mean anomaly of the Moon
        let M1 = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t + t * t * t / 69699.0 - t * t * t * t / 14712000.0
        let M1Rad = AstronomicalUtils.degreesToRadians(M1)
        
        // Moon's argument of latitude
        let F = 93.2720950 + 483202.0175233 * t - 0.0036539 * t * t - t * t * t / 3526000.0 + t * t * t * t / 863310000.0
        let FRad = AstronomicalUtils.degreesToRadians(F)
        
        // Correction for eccentricity
        let E1 = 1.0 - 0.002516 * t - 0.0000074 * t * t
        
        // Ecliptic latitude of the Moon (simplified)
        let moonLatitude =
            5.128122 * sin(FRad) +
            0.280602 * sin(M1Rad + FRad) +
            0.277693 * sin(M1Rad - FRad) +
            0.173237 * sin(2 * DRad - FRad) +
            0.055413 * sin(2 * DRad - M1Rad + FRad) +
            0.046271 * sin(2 * DRad - M1Rad - FRad)
        
        return moonLatitude
    }
    
    // Placeholder planetary position calculations (simplified)
    // Real implementations would use more accurate planetary theory
    
    static func calculateMercuryPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 252.250906 + 149472.6746358 * t
        let position = L + 6.0 * sin(AstronomicalUtils.degreesToRadians(L - 252.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculateVenusPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 181.979801 + 58517.8156760 * t
        let position = L + 2.0 * sin(AstronomicalUtils.degreesToRadians(L - 181.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculateMarsPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 355.433000 + 19140.2993039 * t
        let position = L + 10.0 * sin(AstronomicalUtils.degreesToRadians(L - 355.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculateJupiterPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 34.351519 + 3034.9056606 * t
        let position = L + 5.0 * sin(AstronomicalUtils.degreesToRadians(L - 34.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculateSaturnPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 50.077471 + 1222.1138488 * t
        let position = L + 7.0 * sin(AstronomicalUtils.degreesToRadians(L - 50.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculateUranusPosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 314.055005 + 429.8640561 * t
        let position = L + 7.0 * sin(AstronomicalUtils.degreesToRadians(L - 314.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculateNeptunePosition(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let L = 304.348665 + 219.8833092 * t
        let position = L + 3.5 * sin(AstronomicalUtils.degreesToRadians(L - 304.0))
        return AstronomicalUtils.normalizeAngle(position)
    }
    
    static func calculatePlutoPosition(jd: Double) -> Double {
            let t = (jd - 2451545.0) / 36525.0
            let L = 238.92903833 + 145.20780515 * t
            let position = L + 4.0 * sin(AstronomicalUtils.degreesToRadians(L - 238.0))
            return AstronomicalUtils.normalizeAngle(position)
        }
        
        static func calculateNorthNode(jd: Double) -> Double {
            // Simplified calculation for North Node position
            let t = (jd - 2451545.0) / 36525.0
            
            // Mean longitude of the Moon's node
            let omega = 125.04452 - 1934.136261 * t
            
            return AstronomicalUtils.normalizeAngle(omega)
        }
        
        static func calculatePlanetLatitude(_ planet: PlanetType, jd: Double) -> Double {
            // Simplified calculation of planetary latitudes
            // Real implementations would use more complex formulas specific to each planet
            
            // Time in Julian centuries since J2000.0
            let t = (jd - 2451545.0) / 36525.0
            
            // Different simplified formulas depending on the planet
            switch planet {
            case .mercury:
                return 7.0 * sin(t * 4000.0 * .pi / 180.0)
            case .venus:
                return 3.0 * sin(t * 2000.0 * .pi / 180.0)
            case .mars:
                return 2.0 * sin(t * 1000.0 * .pi / 180.0)
            case .jupiter:
                return 1.0 * sin(t * 200.0 * .pi / 180.0)
            case .saturn:
                return 2.5 * sin(t * 80.0 * .pi / 180.0)
            case .uranus:
                return 0.8 * sin(t * 40.0 * .pi / 180.0)
            case .neptune:
                return 1.2 * sin(t * 20.0 * .pi / 180.0)
            case .pluto:
                return 17.0 * sin(t * 10.0 * .pi / 180.0)
            default:
                return 0.0
            }
        }
    }
