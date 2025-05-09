//
//  AstronomicalCalculator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation
#if canImport(CSwissEphemeris)
import CSwissEphemeris        // SwiftPM / CocoaPods module name
#endif

struct AstronomicalCalculator {
    
    // Calculate Earth's nutation
    static func calculateNutation(julianDay: Double) -> (nutationInLongitude: Double, nutationInObliquity: Double) {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean elongation of the Moon from the Sun
        //let D = 297.85036 + 445267.111480 * T - 0.0019142 * T * T + T * T * T / 189474.0
        
        // Mean anomaly of the Sun
        let M = 357.52772 + 35999.050340 * T - 0.0001603 * T * T - T * T * T / 300000.0
        
        // Mean anomaly of the Moon
        let Mprime = 134.96298 + 477198.867398 * T + 0.0086972 * T * T + T * T * T / 56250.0
        
        // Moon's argument of latitude
        //let F = 93.27191 + 483202.017538 * T - 0.0036825 * T * T + T * T * T / 327270.0
        
        // Longitude of the ascending node of the Moon's mean orbit
        let omega = 125.04452 - 1934.136261 * T + 0.0020708 * T * T + T * T * T / 450000.0
        
        // Convert to radians
        //let dRad = CoordinateTransformations.degreesToRadians(D)
        let mRad = CoordinateTransformations.degreesToRadians(M)
        let mPrimeRad = CoordinateTransformations.degreesToRadians(Mprime)
        //let fRad = CoordinateTransformations.degreesToRadians(F)
        let omegaRad = CoordinateTransformations.degreesToRadians(omega)
        
        // Calculate nutation in longitude (simplified)
        var deltaLongitude = -17.2 * sin(omegaRad) - 1.32 * sin(2 * mRad) - 0.23 * sin(2 * mPrimeRad) + 0.21 * sin(2 * omegaRad)
        deltaLongitude /= 3600.0 // Convert from arcseconds to degrees
        
        // Calculate nutation in obliquity (simplified)
        var deltaObliquity = 9.2 * cos(omegaRad) + 0.57 * cos(2 * mRad) + 0.1 * cos(2 * mPrimeRad) - 0.09 * cos(2 * omegaRad)
        deltaObliquity /= 3600.0 // Convert from arcseconds to degrees
        
        return (deltaLongitude, deltaObliquity)
    }
    
    // Calculate true obliquity (mean obliquity + nutation in obliquity)
    static func calculateTrueObliquity(julianDay: Double) -> Double {
        let meanObliquity = CoordinateTransformations.calculateObliquityOfEcliptic(julianDay: julianDay)
        let (_, nutationInObliquity) = calculateNutation(julianDay: julianDay)
        
        return meanObliquity + nutationInObliquity
    }
    
    // Calculate equation of time (difference between apparent and mean solar time)
    static func calculateEquationOfTime(julianDay: Double) -> Double {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean longitude of the Sun
        var L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        L0 = CoordinateTransformations.normalizeAngle(L0)
        
        // Mean anomaly of the Sun
        var M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        M = CoordinateTransformations.normalizeAngle(M)
        
        // Eccentricity of Earth's orbit
        //let e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T
        
        // Convert to radians
        //let L0Rad = CoordinateTransformations.degreesToRadians(L0)
        let MRad = CoordinateTransformations.degreesToRadians(M)
        
        // Calculate the equation of center
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(MRad) +
                (0.019993 - 0.000101 * T) * sin(2 * MRad) +
                0.000289 * sin(3 * MRad)
        
        // True longitude of the Sun
        let lambda = L0 + C
        
        // Calculate right ascension of the Sun
        let lambdaRad = CoordinateTransformations.degreesToRadians(lambda)
        let epsilon = CoordinateTransformations.calculateObliquityOfEcliptic(julianDay: julianDay)
        let epsilonRad = CoordinateTransformations.degreesToRadians(epsilon)
        
        var alpha = atan2(cos(epsilonRad) * sin(lambdaRad), cos(lambdaRad))
        alpha = CoordinateTransformations.radiansToDegrees(alpha)
        
        // Calculate equation of time in minutes
        var E = (L0 - alpha) * 4.0
        
        // Normalize to range [-20, 20]
        if E > 20.0 {
            E -= 1440.0
        } else if E < -20.0 {
            E += 1440.0
        }
        
        return E / 60.0 // Convert to hours
    }
    
    // Calculate solar position
    static func calculateSunPosition(julianDay: Double) -> (longitude: Double, latitude: Double) {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean longitude of the Sun
        var L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        L0 = CoordinateTransformations.normalizeAngle(L0)
        
        // Mean anomaly of the Sun
        var M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        M = CoordinateTransformations.normalizeAngle(M)
        
        // Eccentricity of Earth's orbit
        //let e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T
        
        // Convert to radians
        let MRad = CoordinateTransformations.degreesToRadians(M)
        
        // Calculate the equation of center
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(MRad) +
                (0.019993 - 0.000101 * T) * sin(2 * MRad) +
                0.000289 * sin(3 * MRad)
        
        // True longitude of the Sun
        let lambda = L0 + C
        
        // Apply nutation and aberration (simplified)
        let (nutationLongitude, _) = calculateNutation(julianDay: julianDay)
        let trueGeocentricLongitude = lambda + nutationLongitude
        
        // The Sun's latitude is very small, but not exactly zero
        // Usually for astrological purposes, it's considered to be zero
        let latitude = 0.0
        
        return (CoordinateTransformations.normalizeAngle(trueGeocentricLongitude), latitude)
    }
    
    // Calculate lunar position (simplified)
    static func calculateMoonPosition(julianDay: Double) -> (longitude: Double, latitude: Double) {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean longitude of the Moon
        var L = 218.3164477 + 481267.88123421 * T - 0.0015786 * T * T + T * T * T / 538841.0 - T * T * T * T / 65194000.0
        
        // Mean elongation of the Moon
        var D = 297.8501921 + 445267.1114034 * T - 0.0018819 * T * T + T * T * T / 545868.0 - T * T * T * T / 113065000.0
        
        // Mean anomaly of the Sun
        var M = 357.5291092 + 35999.0502909 * T - 0.0001536 * T * T + T * T * T / 24490000.0
        
        // Mean anomaly of the Moon
        var Mprime = 134.9633964 + 477198.8675055 * T + 0.0087414 * T * T + T * T * T / 69699.0 - T * T * T * T / 14712000.0
        
        // Mean distance of the Moon from its ascending node
        var F = 93.2720950 + 483202.0175233 * T - 0.0036539 * T * T - T * T * T / 3526000.0 + T * T * T * T / 863310000.0
        
        // Normalize angles
        L = CoordinateTransformations.normalizeAngle(L)
        D = CoordinateTransformations.normalizeAngle(D)
        M = CoordinateTransformations.normalizeAngle(M)
        Mprime = CoordinateTransformations.normalizeAngle(Mprime)
        F = CoordinateTransformations.normalizeAngle(F)
        
        // Convert to radians
        let DRad = CoordinateTransformations.degreesToRadians(D)
        let MRad = CoordinateTransformations.degreesToRadians(M)
        let MprimeRad = CoordinateTransformations.degreesToRadians(Mprime)
        let FRad = CoordinateTransformations.degreesToRadians(F)
        
        // Longitude perturbations (simplified)
        var longitude = L + 6.288774 * sin(MprimeRad) + 1.274027 * sin(2 * DRad - MprimeRad) +
                      0.658314 * sin(2 * DRad) + 0.213618 * sin(2 * MprimeRad) -
                      0.185116 * sin(MRad) - 0.114332 * sin(2 * FRad)
        
        // Latitude perturbations (simplified)
        let latitude = 5.128189 * sin(FRad) + 0.280606 * sin(MprimeRad + FRad) +
                     0.277693 * sin(MprimeRad - FRad) + 0.173238 * sin(2 * DRad - FRad)
        
        // Apply nutation
        let (nutationLongitude, _) = calculateNutation(julianDay: julianDay)
        longitude += nutationLongitude
        
        return (CoordinateTransformations.normalizeAngle(longitude), latitude)
    }
    
    // Calculate lunar phase
    static func calculateLunarPhase(julianDay: Double) -> Double {
        // Get Sun and Moon positions
        let (sunLongitude, _) = calculateSunPosition(julianDay: julianDay)
        let (moonLongitude, _) = calculateMoonPosition(julianDay: julianDay)
        
        // Calculate phase angle
        var phaseAngle = moonLongitude - sunLongitude
        if phaseAngle < 0 {
            phaseAngle += 360.0
        }
        
        return phaseAngle
    }
    
    // Calculate ascendant (rising sign)
    static func calculateAscendant(julianDay: Double, latitude: Double, longitude: Double) -> Double {
        // Local Sidereal Time
        let lst = JulianDateCalculator.calculateLocalSiderealTime(julianDay: julianDay, longitude: longitude)
        
        // Obliquity of the ecliptic
        let obliquity = calculateTrueObliquity(julianDay: julianDay)
        
        // Convert to radians
        let lstRad = CoordinateTransformations.degreesToRadians(lst)
        let latRad = CoordinateTransformations.degreesToRadians(latitude)
        let oblRad = CoordinateTransformations.degreesToRadians(obliquity)
        
        // Calculate ascendant
        let tanAsc = -cos(lstRad) / (sin(oblRad) * tan(latRad) + cos(oblRad) * sin(lstRad))
        var ascendant = CoordinateTransformations.radiansToDegrees(atan(tanAsc))
        
        // Adjust quadrant
        if cos(lstRad) > 0 {
            ascendant += 180.0
        }
        
        // Normalize
        ascendant = CoordinateTransformations.normalizeAngle(ascendant)
        
        return ascendant
    }
    
    // Calculate midheaven (MC)
    static func calculateMidheaven(julianDay: Double, longitude: Double) -> Double {
        // Local Sidereal Time
        let lst = JulianDateCalculator.calculateLocalSiderealTime(julianDay: julianDay, longitude: longitude)
        
        // Obliquity of the ecliptic
        let obliquity = calculateTrueObliquity(julianDay: julianDay)
        
        // Convert LST to radians
        let lstRad = CoordinateTransformations.degreesToRadians(lst)
        let oblRad = CoordinateTransformations.degreesToRadians(obliquity)
        
        // Calculate RAMC (Right Ascension of Midheaven)
        let ramc = lst
        
        // Convert RAMC to ecliptic longitude (Midheaven)
        let tanMC = tan(lstRad) / cos(oblRad)
        var mc = CoordinateTransformations.radiansToDegrees(atan(tanMC))
        
        // Adjust quadrant
        if ramc > 180 && ramc < 360 {
            mc += 180.0
        }
        
        // Normalize
        mc = CoordinateTransformations.normalizeAngle(mc)
        
        return mc
    }
    
    // Calculate vertex point (western horizon point)
    static func calculateVertex(julianDay: Double, latitude: Double, longitude: Double) -> Double {
        // Local Sidereal Time
        let lst = JulianDateCalculator.calculateLocalSiderealTime(julianDay: julianDay, longitude: longitude)
        
        // Obliquity of the ecliptic
        let obliquity = calculateTrueObliquity(julianDay: julianDay)
        
        // Convert to radians
        let lstRad = CoordinateTransformations.degreesToRadians(lst + 180.0) // Add 180° for the western horizon
        let latRad = CoordinateTransformations.degreesToRadians(latitude)
        let oblRad = CoordinateTransformations.degreesToRadians(obliquity)
        
        // Calculate vertex
        let tanVertex = -cos(lstRad) / (sin(oblRad) * tan(latRad) + cos(oblRad) * sin(lstRad))
        var vertex = CoordinateTransformations.radiansToDegrees(atan(tanVertex))
        
        // Adjust quadrant
        if cos(lstRad) > 0 {
            vertex += 180.0
        }
        
        // Normalize
        vertex = CoordinateTransformations.normalizeAngle(vertex)
        
        return vertex
    }
    
    // MARK: - House cusps --------------------------------------------------

    static func calculateHouseCusps(julianDay: Double,
                                    latitude: Double,
                                    longitude: Double) -> [Double] {
        
        var c = [Double](repeating: 0.0, count: 13)
        
        #if canImport(CSwissEphemeris)
        
            print("Natal Chart House Cusps: Using Swiss Ephem")
            // 1 · Tell Swiss Ephemeris where the .se1… files live
            if let path = Bundle.main.resourcePath {
                path.withCString { cStr in
                    swe_set_ephe_path(UnsafeMutablePointer(mutating: cStr))
                }
            }
            
            // 2 · Prepare buffers
            var ascmc = [Double](repeating: 0.0, count: 10)   // ASC, MC, etc.
            
            // 3 · Call swe_houses     (hsys 'P' = Placidus)
            let hsys = Int32(Character("P").asciiValue!)      // UInt8 → Int32
            
            c.withUnsafeMutableBufferPointer { cuspPtr -> Void in
                ascmc.withUnsafeMutableBufferPointer { ascmcPtr -> Void in
                    swe_houses(julianDay,
                               latitude,
                               longitude,
                               hsys,
                               cuspPtr.baseAddress!,   // arrays are non‑empty, safe force‑unwrap
                               ascmcPtr.baseAddress!)
                }
            }
            
        #else
       
        // ---------- fallback: equal‑house -------------------------------
        // Note: this is accurate aside from 2nd and 8th house cusps
         
        let asc = calculateAscendant(julianDay: julianDay,
                                     latitude: latitude,
                                     longitude: longitude)
        let mc  = calculateMidheaven(julianDay: julianDay,
                                     longitude: longitude)
        
        c[1]  = asc
        c[4]  = CoordinateTransformations.normalizeAngle(mc + 180)
        c[7]  = CoordinateTransformations.normalizeAngle(asc + 180)
        c[10] = mc
        
        for i in [2,3,5,6,8,9,11,12] {
            c[i] = CoordinateTransformations.normalizeAngle(c[i-1] + 30)
        }
        
        #endif
        
        return c

        
    }
    // Calculate aspects between two points
    static func calculateAspect(point1: Double, point2: Double, orb: Double = 5.0) -> (aspectType: String, exactness: Double)? {
        let angle = abs(point1 - point2).truncatingRemainder(dividingBy: 360.0)
        let normalizedAngle = min(angle, 360.0 - angle)
        
        // Define aspect types and their exact angles
        let aspects: [(type: String, angle: Double, defaultOrb: Double)] = [
            ("Conjunction", 0, 8.0),
            ("Opposition", 180, 8.0),
            ("Trine", 120, 8.0),
            ("Square", 90, 8.0),
            ("Sextile", 60, 6.0),
            ("Quincunx", 150, 3.0),
            ("Semi-sextile", 30, 3.0),
            ("Semi-square", 45, 3.0),
            ("Sesquiquadrate", 135, 3.0),
            ("Quintile", 72, 2.0),
            ("Bi-quintile", 144, 2.0)
        ]
        
        for aspect in aspects {
            let aspectOrb = orb == 5.0 ? aspect.defaultOrb : orb
            let difference = abs(normalizedAngle - aspect.angle)
            
            if difference <= aspectOrb {
                return (aspect.type, difference)
            }
        }
        
        return nil
    }
    
    // Calculate lunar nodes
    static func calculateLunarNodes(julianDay: Double) -> (north: Double, south: Double) {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean longitude of the node
        var omega = 125.04452 - 1934.136261 * T + 0.0020708 * T * T + T * T * T / 450000.0
        
        // Apply nutation
        let (nutationLongitude, _) = calculateNutation(julianDay: julianDay)
        omega += nutationLongitude
        
        // Normalize
        omega = CoordinateTransformations.normalizeAngle(omega)
        
        // The North Node is the calculated position
        let northNode = omega
        
        // The South Node is exactly opposite
        let southNode = CoordinateTransformations.normalizeAngle(northNode + 180.0)
        
        return (northNode, southNode)
    }
    
    // Calculate Chiron position (simplified)
    static func calculateChironPosition(julianDay: Double) -> Double {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Simplified orbital elements of Chiron at J2000
        //let a = 13.6518 // Semi-major axis in AU
        let e = 0.3814 // Eccentricity
        //let i = 6.923 * Double.pi / 180.0 // Inclination
        let w = 339.483 * Double.pi / 180.0 // Argument of perihelion
        let o = 209.365 * Double.pi / 180.0 // Longitude of the ascending node
        let meanLongitude = 224.598 * Double.pi / 180.0 // Mean longitude at epoch
        
        // Orbital period of Chiron (approximately 50.7 years)
        let period = 18736.22 // days
        
        // Mean motion (degrees per day)
        let n = 360.0 / period
        
        // Mean anomaly
        var M = meanLongitude - w - o + n * T * 36525.0
        M = M.truncatingRemainder(dividingBy: 2.0 * Double.pi)
        if M < 0 { M += 2.0 * Double.pi }
        
        // Solve Kepler's equation (simplified)
        var E = M
        for _ in 0..<10 {
            E = M + e * sin(E)
        }
        
        // True anomaly
        let v = 2.0 * atan(sqrt((1.0 + e) / (1.0 - e)) * tan(E / 2.0))
        
        // Heliocentric longitude
        let heliocLong = v + w
        
        // Convert to geocentric ecliptic longitude (very simplified)
        var geocentricLongitude = CoordinateTransformations.radiansToDegrees(heliocLong + o)
        
        // Normalize
        geocentricLongitude = CoordinateTransformations.normalizeAngle(geocentricLongitude)
        
        return geocentricLongitude
    }
}
