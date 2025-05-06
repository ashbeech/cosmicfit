//
//  AstronomicalUtils.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

class AstronomicalUtils {
    // Constants
    static let J2000: Double = 2451545.0 // Julian date for J2000.0 epoch
    static let DEG_TO_RAD: Double = .pi / 180.0
    static let RAD_TO_DEG: Double = 180.0 / .pi
    static let SIDEREAL_YEAR_DAYS: Double = 365.25636
    
    // Normalize an angle to the range 0-360 degrees
    static func normalizeAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 360.0)
        if result < 0.0 {
            result += 360.0
        }
        return result
    }
    
    // Convert degrees to radians
    static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * DEG_TO_RAD
    }
    
    // Convert radians to degrees
    static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * RAD_TO_DEG
    }
    
    // Calculate the Julian Day from a date
    static func julianDay(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        
        let jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + Double(day) + b - 1524.5
        
        // Add time of day
        let timeInHours = Double(hour) + Double(minute) / 60.0 + Double(second) / 3600.0
        return jd + timeInHours / 24.0
    }
    
    // Calculate Julian Day from a Date object
    static func julianDay(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        return julianDay(
            year: components.year!,
            month: components.month!,
            day: components.day!,
            hour: components.hour!,
            minute: components.minute!,
            second: components.second!
        )
    }
    
    // Calculate the Delta T (difference between terrestrial time and universal time)
    static func deltaT(jd: Double) -> Double {
        let year = 2000.0 + (jd - J2000) / 365.25
        
        if year >= 1986 && year < 2005 {
            // Polynomial approximation for 1986-2005 period
            let t = year - 2000
            return 63.86 + 0.3345 * t - 0.060374 * t * t + 0.0017275 * t * t * t + 0.000651814 * t * t * t * t + 0.00002373599 * t * t * t * t * t
        } else if year >= 2005 && year < 2050 {
            // Polynomial approximation for 2005-2050 period
            let t = year - 2000
            return 62.92 + 0.32217 * t + 0.005589 * t * t
        } else {
            // Default for other periods
            return 0
        }
    }
    
    // Calculate the obliquity of the ecliptic (angle between Earth's equator and orbital plane)
    static func obliquityOfEcliptic(jd: Double) -> Double {
        let t = (jd - J2000) / 36525.0
        
        // IAU 1980 formula with adjustments
        let eps0 = 23.43929111 - 0.01300416667 * t - 0.00000164 * t * t + 0.00000504 * t * t * t
        
        // Add nutation correction (simplified)
        let omega = 125.04 - 1934.136 * t
        let l = 280.47 + 36000.770 * t
        let lp = 218.32 + 481267.883 * t
        
        let deltaEpsilon = 9.2 * cos(degreesToRadians(omega)) + 0.57 * cos(degreesToRadians(2 * l)) + 0.1 * cos(degreesToRadians(2 * lp)) - 0.09 * cos(degreesToRadians(2 * omega))
        
        return eps0 + deltaEpsilon / 3600.0
    }
    
    // Calculate equatorial coordinates from ecliptic coordinates
    static func eclipticToEquatorial(eclipticLongitude: Double, eclipticLatitude: Double, obliquity: Double) -> (rightAscension: Double, declination: Double) {
        let lambdaRad = degreesToRadians(eclipticLongitude)
        let betaRad = degreesToRadians(eclipticLatitude)
        let epsRad = degreesToRadians(obliquity)
        
        let sinDec = sin(betaRad) * cos(epsRad) + cos(betaRad) * sin(epsRad) * sin(lambdaRad)
        let dec = radiansToDegrees(asin(sinDec))
        
        let y = sin(lambdaRad) * cos(epsRad) - tan(betaRad) * sin(epsRad)
        let x = cos(lambdaRad)
        var ra = radiansToDegrees(atan2(y, x))
        
        ra = normalizeAngle(ra)
        
        return (ra, dec)
    }
    
    // Convert equatorial to ecliptic coordinates
    static func equatorialToEcliptic(rightAscension: Double, declination: Double, obliquity: Double) -> (longitude: Double, latitude: Double) {
        let raRad = degreesToRadians(rightAscension)
        let decRad = degreesToRadians(declination)
        let oblRad = degreesToRadians(obliquity)
        
        let sinLat = sin(decRad) * cos(oblRad) - cos(decRad) * sin(oblRad) * sin(raRad)
        let lat = radiansToDegrees(asin(sinLat))
        
        let y = sin(raRad) * cos(oblRad) + tan(decRad) * sin(oblRad)
        let x = cos(raRad)
        var lon = radiansToDegrees(atan2(y, x))
        
        lon = normalizeAngle(lon)
        
        return (lon, lat)
    }
}
