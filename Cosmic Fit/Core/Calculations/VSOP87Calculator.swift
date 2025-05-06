//
//  VSOP87Calculator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

class VSOP87Calculator {
    /// Calculate the Sun's position
    /// - Parameter jd: Julian Day
    /// - Returns: Sun's longitude in degrees
    static func calculateSunPosition(jd: Double) -> Double {
        // The sun's ecliptic position is the opposite of Earth's heliocentric position
        let t = (jd - 2451545.0) / 36525.0
        
        // Get Earth's heliocentric position
        guard let earthLTerms = VSOP87Parser.parseCoefficients(for: "ear", coordinate: "L") else {
            print("Error: Failed to load Earth longitude terms")
            return 0.0
        }
        
        let earthLon = calculateEclipticLongitude(vsopTerms: earthLTerms, julianCenturies: t)
        
        // Sun's geocentric longitude is Earth's heliocentric longitude + 180°
        let sunLon = (earthLon * 180.0 / .pi) + 180.0
        
        return AstronomicalUtils.normalizeAngle(sunLon)
    }
    
    /// Calculate the Moon's position
    /// - Parameter jd: Julian Day
    /// - Returns: Moon's position (longitude, latitude)
    static func calculateMoonPosition(jd: Double) -> (longitude: Double, latitude: Double) {
        // Moon calculation requires a different algorithm than VSOP87
        // Using ELP2000 algorithm simplified
        
        let t = (jd - 2451545.0) / 36525.0
        
        // Mean elements of lunar orbit
        let L0 = 218.3164477 + 481267.88123421 * t
        let D = 297.8501921 + 445267.1114034 * t
        let M = 357.5291092 + 35999.0502909 * t
        let M1 = 134.9633964 + 477198.8675055 * t
        let F = 93.2720950 + 483202.0175233 * t
        
        // Convert to radians
        let DRad = D * .pi / 180.0
        let MRad = M * .pi / 180.0
        let M1Rad = M1 * .pi / 180.0
        let FRad = F * .pi / 180.0
        
        // Calculate corrections
        let E = 1.0 - 0.002516 * t - 0.0000074 * t * t
        
        // Longitude calculation
        let lon = L0 +
                  6.288774 * sin(M1Rad) +
                  1.274027 * sin(2 * DRad - M1Rad) +
                  0.658314 * sin(2 * DRad) +
                  0.213618 * sin(2 * M1Rad) -
                  0.185116 * sin(MRad) * E -
                  0.114332 * sin(2 * FRad)
        
        // Latitude calculation
        let lat = 5.128122 * sin(FRad) +
                  0.280602 * sin(M1Rad + FRad) +
                  0.277693 * sin(M1Rad - FRad) +
                  0.173237 * sin(2 * DRad - FRad) +
                  0.055413 * sin(2 * DRad - M1Rad + FRad) +
                  0.046271 * sin(2 * DRad - M1Rad - FRad)
        
        return (AstronomicalUtils.normalizeAngle(lon), lat)
    }
    
    /// Calculate the North Node position
    /// - Parameter jd: Julian Day
    /// - Returns: North Node longitude in degrees
    static func calculateNorthNodePosition(jd: Double) -> Double {
        // Calculate mean longitude of the Moon's node
        let t = (jd - 2451545.0) / 36525.0
        let omega = 125.04452 - 1934.136261 * t
        return AstronomicalUtils.normalizeAngle(omega)
    }
    
    /// Calculate a planet's position
    /// - Parameters:
    ///   - planet: The planet type
    ///   - jd: Julian Day
    /// - Returns: Planet's position (longitude, latitude)
    static func calculatePlanetPosition(planet: PlanetType, jd: Double) -> (longitude: Double, latitude: Double) {
        // Convert JD to Julian centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0
        
        // Get planet code for VSOP87
        let planetCode: String
        switch planet {
        case .mercury: planetCode = "mer"
        case .venus: planetCode = "ven"
        case .mars: planetCode = "mar"
        case .jupiter: planetCode = "jup"
        case .saturn: planetCode = "sat"
        case .uranus: planetCode = "ura"
        case .neptune: planetCode = "nep"
        case .pluto: return calculatePlutoPosition(jd: jd) // Pluto not in VSOP87
        default: return (0.0, 0.0) // Other bodies not supported
        }
        
        // Get VSOP87 terms for the planet
        guard let lTerms = VSOP87Parser.parseCoefficients(for: planetCode, coordinate: "L"),
              let bTerms = VSOP87Parser.parseCoefficients(for: planetCode, coordinate: "B"),
              let rTerms = VSOP87Parser.parseCoefficients(for: planetCode, coordinate: "R"),
              let earthLTerms = VSOP87Parser.parseCoefficients(for: "ear", coordinate: "L"),
              let earthBTerms = VSOP87Parser.parseCoefficients(for: "ear", coordinate: "B"),
              let earthRTerms = VSOP87Parser.parseCoefficients(for: "ear", coordinate: "R") else {
            print("Error: Failed to load VSOP87 terms for planet \(planetCode)")
            return (0.0, 0.0)
        }
        
        // Calculate heliocentric coordinates
        let hLon = calculateEclipticLongitude(vsopTerms: lTerms, julianCenturies: t)
        let hLat = calculateEclipticLatitude(vsopTerms: bTerms, julianCenturies: t)
        let hRad = calculateRadiusVector(vsopTerms: rTerms, julianCenturies: t)
        
        // Calculate Earth's heliocentric coordinates
        let earthLon = calculateEclipticLongitude(vsopTerms: earthLTerms, julianCenturies: t)
        let earthLat = calculateEclipticLatitude(vsopTerms: earthBTerms, julianCenturies: t)
        let earthRad = calculateRadiusVector(vsopTerms: earthRTerms, julianCenturies: t)
        
        // Convert to geocentric coordinates
        let geocentric = heliocentricToGeocentric(
            planetLon: hLon, planetLat: hLat, planetRadius: hRad,
            earthLon: earthLon, earthLat: earthLat, earthRadius: earthRad
        )
        
        // Convert radians to degrees
        let lonDegrees = geocentric.longitude * 180.0 / .pi
        let latDegrees = geocentric.latitude * 180.0 / .pi
        
        // Normalize longitude to 0-360 range
        let normalizedLon = AstronomicalUtils.normalizeAngle(lonDegrees)
        
        return (normalizedLon, latDegrees)
    }
    
    /// Calculate Pluto's position (not in VSOP87)
    /// - Parameter jd: Julian Day
    /// - Returns: Pluto's position (longitude, latitude)
    private static func calculatePlutoPosition(jd: Double) -> (longitude: Double, latitude: Double) {
        // Simplified algorithm for Pluto
        let t = (jd - 2451545.0) / 36525.0
        
        // Approximate formula for Pluto's longitude
        let lon = 238.9581 + 144.9600 * t
        
        // Approximate formula for Pluto's latitude
        let lat = 17.1673 - 0.4247 * t
        
        return (AstronomicalUtils.normalizeAngle(lon), lat)
    }
    
    /// Calculate the heliocentric ecliptic longitude
    /// - Parameters:
    ///   - vsopTerms: VSOP87 terms for longitude
    ///   - julianCenturies: Time in Julian centuries since J2000.0
    /// - Returns: Longitude in radians
    private static func calculateEclipticLongitude(vsopTerms: [[VSOP87Term]], julianCenturies: Double) -> Double {
        return calculateVSOP87Value(terms: vsopTerms, t: julianCenturies)
    }
    
    /// Calculate the heliocentric ecliptic latitude
    /// - Parameters:
    ///   - vsopTerms: VSOP87 terms for latitude
    ///   - julianCenturies: Time in Julian centuries since J2000.0
    /// - Returns: Latitude in radians
    private static func calculateEclipticLatitude(vsopTerms: [[VSOP87Term]], julianCenturies: Double) -> Double {
        return calculateVSOP87Value(terms: vsopTerms, t: julianCenturies)
    }
    
    /// Calculate the heliocentric radius vector
    /// - Parameters:
    ///   - vsopTerms: VSOP87 terms for radius
    ///   - julianCenturies: Time in Julian centuries since J2000.0
    /// - Returns: Radius in AU
    private static func calculateRadiusVector(vsopTerms: [[VSOP87Term]], julianCenturies: Double) -> Double {
        return calculateVSOP87Value(terms: vsopTerms, t: julianCenturies)
    }
    
    /// Calculate a VSOP87 value using the series expansion
    /// - Parameters:
    ///   - terms: VSOP87 terms
    ///   - t: Time in Julian centuries since J2000.0
    /// - Returns: Calculated value in radians for angles, AU for radius
    private static func calculateVSOP87Value(terms: [[VSOP87Term]], t: Double) -> Double {
        var result = 0.0
        
        for (power, series) in terms.enumerated() {
            var sum = 0.0
            for term in series {
                sum += term.a * cos(term.b + term.c * t)
            }
            result += sum * pow(t, Double(power))
        }
        
        return result
    }
    
    /// Convert heliocentric coordinates to geocentric coordinates
    /// - Parameters:
    ///   - planetLon: Planet's heliocentric longitude in radians
    ///   - planetLat: Planet's heliocentric latitude in radians
    ///   - planetRadius: Planet's heliocentric radius in AU
    ///   - earthLon: Earth's heliocentric longitude in radians
    ///   - earthLat: Earth's heliocentric latitude in radians
    ///   - earthRadius: Earth's heliocentric radius in AU
    /// - Returns: Geocentric ecliptic coordinates (longitude, latitude, distance)
    private static func heliocentricToGeocentric(
        planetLon: Double, planetLat: Double, planetRadius: Double,
        earthLon: Double, earthLat: Double, earthRadius: Double
    ) -> (longitude: Double, latitude: Double, distance: Double) {
        // Convert to rectangular coordinates
        let (xh, yh, zh) = sphericalToRectangular(lon: planetLon, lat: planetLat, r: planetRadius)
        let (xe, ye, ze) = sphericalToRectangular(lon: earthLon, lat: earthLat, r: earthRadius)
        
        // Calculate geocentric rectangular coordinates
        let xg = xh - xe
        let yg = yh - ye
        let zg = zh - ze
        
        // Convert back to spherical coordinates
        let (lon, lat, r) = rectangularToSpherical(x: xg, y: yg, z: zg)
        
        return (lon, lat, r)
    }
    
    /// Convert spherical coordinates to rectangular coordinates
    private static func sphericalToRectangular(lon: Double, lat: Double, r: Double) -> (x: Double, y: Double, z: Double) {
        let x = r * cos(lat) * cos(lon)
        let y = r * cos(lat) * sin(lon)
        let z = r * sin(lat)
        return (x, y, z)
    }
    
    /// Convert rectangular coordinates to spherical coordinates
    private static func rectangularToSpherical(x: Double, y: Double, z: Double) -> (lon: Double, lat: Double, r: Double) {
        let r = sqrt(x*x + y*y + z*z)
        let lon = atan2(y, x)
        let lat = asin(z / r)
        return (lon, lat, r)
    }
}
