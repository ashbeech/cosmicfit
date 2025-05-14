
//
//  CoordinateTransformations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

struct CoordinateTransformations {
    // Convert degrees to radians
    static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }
    
    // Convert radians to degrees
    static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
    
    // Normalize angle to [0, 360) degrees
    static func normalizeAngle(_ degrees: Double) -> Double {
        var normalized = degrees.truncatingRemainder(dividingBy: 360.0)
        if normalized < 0 {
            normalized += 360.0
        }
        return normalized
    }
    
    // Normalize angle to [0, 2π) radians
    static func normalizeRadians(_ radians: Double) -> Double {
        var normalized = radians.truncatingRemainder(dividingBy: 2 * Double.pi)
        if normalized < 0 {
            normalized += 2 * Double.pi
        }
        return normalized
    }
    
    // Convert ecliptic to equatorial coordinates
    static func eclipticToEquatorial(longitude: Double, latitude: Double, obliquity: Double) -> (rightAscension: Double, declination: Double) {
        // Convert to radians
        let lon = degreesToRadians(longitude)
        let lat = degreesToRadians(latitude)
        let obl = degreesToRadians(obliquity)
        
        // Calculate right ascension and declination
        let sinDec = sin(lat) * cos(obl) + cos(lat) * sin(obl) * sin(lon)
        let declination = asin(sinDec)
        
        let y = sin(lon) * cos(obl) - tan(lat) * sin(obl)
        let x = cos(lon)
        let rightAscension = atan2(y, x)
        
        // Convert back to degrees and normalize
        let ra = normalizeAngle(radiansToDegrees(rightAscension))
        let dec = radiansToDegrees(declination)
        
        return (ra, dec)
    }
    
    // Convert equatorial to horizon coordinates (altitude and azimuth)
    static func equatorialToHorizon(rightAscension: Double, declination: Double, localSiderealTime: Double, latitude: Double) -> (altitude: Double, azimuth: Double) {
        // Convert inputs to radians
        let ra = degreesToRadians(rightAscension)
        let dec = degreesToRadians(declination)
        let lst = degreesToRadians(localSiderealTime)
        let lat = degreesToRadians(latitude)
        
        // Calculate hour angle in radians
        let hourAngle = lst - ra
        
        // Calculate altitude
        let sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(hourAngle)
        let altitude = asin(sinAlt)
        
        // Calculate azimuth
        let cosAz = (sin(dec) - sin(altitude) * sin(lat)) / (cos(altitude) * cos(lat))
        let sinAz = -sin(hourAngle) * cos(dec) / cos(altitude)
        let azimuth = atan2(sinAz, cosAz)
        
        // Convert back to degrees and normalize
        let alt = radiansToDegrees(altitude)
        let az = normalizeAngle(radiansToDegrees(azimuth))
        
        return (alt, az)
    }
    
    // Convert equatorial to ecliptic coordinates
    static func equatorialToEcliptic(rightAscension: Double, declination: Double, obliquity: Double) -> (longitude: Double, latitude: Double) {
        // Convert inputs to radians
        let ra = degreesToRadians(rightAscension)
        let dec = degreesToRadians(declination)
        let obl = degreesToRadians(obliquity)
        
        // Calculate ecliptic latitude
        let sinLat = sin(dec) * cos(obl) - cos(dec) * sin(obl) * sin(ra)
        let latitude = asin(sinLat)
        
        // Calculate ecliptic longitude
        let y = sin(ra) * cos(obl) + tan(dec) * sin(obl)
        let x = cos(ra)
        let longitude = atan2(y, x)
        
        // Convert back to degrees and normalize
        let lon = normalizeAngle(radiansToDegrees(longitude))
        let lat = radiansToDegrees(latitude)
        
        return (lon, lat)
    }
    
    // Convert geocentric to topocentric coordinates
    static func geocentricToTopocentric(longitude: Double, latitude: Double, distance: Double, observerLongitude: Double, observerLatitude: Double, height: Double, julianDay: Double) -> (longitude: Double, latitude: Double, distance: Double) {
        // This is a simplified implementation
        // For precise calculations, a more detailed correction would be needed
        
        // Earth's equatorial radius in AU
        let earthRadius = 6378.137 / 149597870.7
        
        // Calculate observer's geocentric position
        let lst = JulianDateCalculator.calculateLocalSiderealTime(julianDay: julianDay, longitude: observerLongitude)
        let lstRad = degreesToRadians(lst)
        let latRad = degreesToRadians(observerLatitude)
        
        // Simplified calculation (not accounting for Earth's ellipticity)
        let rho = earthRadius * cos(latRad)
        let heightAU = height / 149597870700.0 // Convert height to AU
        
        // Observer's position in rectangular coordinates (simplified)
        let xObs = (rho + heightAU) * cos(lstRad)
        let yObs = (rho + heightAU) * sin(lstRad)
        let zObs = earthRadius * sin(latRad)
        
        // Convert object's spherical coordinates to rectangular
        let lonRad = degreesToRadians(longitude)
        let latRad2 = degreesToRadians(latitude)
        
        let x = distance * cos(latRad2) * cos(lonRad)
        let y = distance * cos(latRad2) * sin(lonRad)
        let z = distance * sin(latRad2)
        
        // Calculate topocentric coordinates
        let xTop = x - xObs
        let yTop = y - yObs
        let zTop = z - zObs
        
        // Convert back to spherical coordinates
        let distanceTop = sqrt(xTop*xTop + yTop*yTop + zTop*zTop)
        let latitudeTop = radiansToDegrees(asin(zTop / distanceTop))
        let longitudeTop = radiansToDegrees(atan2(yTop, xTop))
        
        return (normalizeAngle(longitudeTop), latitudeTop, distanceTop)
    }
    
    // Calculate obliquity of the ecliptic
    static func calculateObliquityOfEcliptic(julianDay: Double) -> Double {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean obliquity in degrees (IAU 2006 formula)
        let epsilon = 23.439291 - 0.0130042 * T - 1.64e-7 * T * T + 5.04e-7 * T * T * T
        
        return epsilon
    }
    
    // Format degrees as astronomical notation (degrees, minutes, seconds)
    static func formatDegrees(_ degrees: Double, includeSeconds: Bool = true) -> String {
        let normalizedDegrees = normalizeAngle(degrees)
        
        let deg = Int(normalizedDegrees)
        let minDouble = (normalizedDegrees - Double(deg)) * 60.0
        let min = Int(minDouble)
        let sec = (minDouble - Double(min)) * 60.0
        
        if includeSeconds {
            return String(format: "%d°%02d'%02.0f\"", deg, min, sec)
        } else {
            return String(format: "%d°%02d'", deg, min)
        }
    }
    
    // Convert formatted degrees (like "15°30'45\"") to decimal degrees
    static func parseFormattedDegrees(_ formatted: String) -> Double? {
        // Define regex pattern to match degrees, minutes, seconds
        let pattern = "(-?\\d+)°\\s*(\\d+)'\\s*(\\d+(\\.\\d+)?)?\"?"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = formatted as NSString
            let matches = regex.matches(in: formatted, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                let degrees = Double(nsString.substring(with: match.range(at: 1))) ?? 0
                let minutes = Double(nsString.substring(with: match.range(at: 2))) ?? 0
                let seconds = Double(nsString.substring(with: match.range(at: 3))) ?? 0
                
                var result = abs(degrees) + minutes/60.0 + seconds/3600.0
                if degrees < 0 {
                    result = -result
                }
                
                return result
            }
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // Convert zodiac sign and position to decimal degrees
    static func zodiacToDecimalDegrees(sign: Int, degrees: Double, minutes: Double, seconds: Double = 0) -> Double {
        return (Double(sign - 1) * 30.0) + degrees + minutes/60.0 + seconds/3600.0
    }
    
    // Convert decimal degrees to zodiac position
    static func decimalDegreesToZodiac(_ degrees: Double) -> (sign: Int, position: String) {
        let normalized = normalizeAngle(degrees)
        let sign = Int(normalized / 30.0) + 1
        let position = normalized.truncatingRemainder(dividingBy: 30.0)
        
        let deg = Int(position)
        let min = Int((position - Double(deg)) * 60.0)
        //let sec = Int(((position - Double(deg)) * 60.0 - Double(min)) * 60.0)
        
        return (sign, String(format: "%d°%02d'", deg, min))
    }
    
    // Get zodiac sign name from sign number (1-12)
    static func getZodiacSignName(sign: Int) -> String {
        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                     "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        
        if sign >= 1 && sign <= 12 {
            return signs[sign - 1]
        }
        return "Unknown"
    }
    
    // Get zodiac sign symbol from sign number (1-12)
    static func getZodiacSignSymbol(sign: Int) -> String {
        let symbols = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]
        
        if sign >= 1 && sign <= 12 {
            return symbols[sign - 1]
        }
        return "?"
    }
}
