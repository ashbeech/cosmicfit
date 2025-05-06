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
    
    // Calculate the Julian centuries since J2000.0
    static func julianCenturies(jd: Double) -> Double {
        return (jd - 2451545.0) / 36525.0
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
        } else if year >= 1961 && year < 1986 {
            // Polynomial approximation for 1961-1986
            let t = year - 1975
            return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718
        } else if year >= 1941 && year < 1961 {
            // Polynomial approximation for 1941-1961
            let t = year - 1950
            return 29.07 + 0.407 * t - t * t / 233 + t * t * t / 2547
        } else {
            // Default approximation for other periods
            let t = (year - 2000) / 100
            return 102 + 102 * t + 25.3 * t * t
        }
    }
    
    // Calculate the obliquity of the ecliptic (angle between Earth's equator and orbital plane)
    static func obliquityOfEcliptic(jd: Double) -> Double {
        let t = julianCenturies(jd: jd)
        
        // IAU 2006 formula
        let eps0 = 23.439291 - 0.01300417 * t - 0.00000616 * t * t + 0.00000081 * t * t * t
        
        // Add nutation correction (simplified)
        let omega = 125.04452 - 1934.136261 * t
        let l = 280.4665 + 36000.7698 * t
        let lp = 218.3165 + 481267.8813 * t
        
        let omegaRad = degreesToRadians(omega)
        let lRad = degreesToRadians(l)
        let lpRad = degreesToRadians(lp)
        
        let deltaEpsilon = 9.20 * cos(omegaRad) + 0.57 * cos(2 * lRad) + 0.10 * cos(2 * lpRad) - 0.09 * cos(2 * omegaRad)
        
        return eps0 + deltaEpsilon / 3600.0
    }
    
    // Calculate the apparent sidereal time at Greenwich
    static func greenwichSiderealTime(jd: Double) -> Double {
        let t = julianCenturies(jd: jd)
        let jdMidnight = floor(jd - 0.5) + 0.5
        let H = (jd - jdMidnight) * 24.0 // Hours since midnight
        
        // Mean sidereal time
        var theta = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
                   0.000387933 * t * t - t * t * t / 38710000.0
        
        // Add nutation correction
        let omega = 125.04452 - 1934.136261 * t
        let L = 280.4665 + 36000.7698 * t
        let L1 = 218.3165 + 481267.8813 * t
        
        let omegaRad = degreesToRadians(omega)
        let lRad = degreesToRadians(L)
        
        let dpsi = -17.2 * sin(omegaRad) - 1.32 * sin(2 * lRad) - 0.23 * sin(2 * degreesToRadians(L1)) + 0.21 * sin(2 * omegaRad)
        let eps = obliquityOfEcliptic(jd: jd)
        
        theta += dpsi * cos(degreesToRadians(eps)) / 3600.0
        
        return normalizeAngle(theta)
    }
    
    // Calculate Local Sidereal Time
    static func localSiderealTime(jd: Double, longitude: Double) -> Double {
        let gst = greenwichSiderealTime(jd: jd)
        let lst = gst + longitude
        
        return normalizeAngle(lst)
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
    
    // Calculate the equation of time (difference between apparent and mean solar time)
    static func equationOfTime(jd: Double) -> Double {
        let t = julianCenturies(jd: jd)
        
        // Mean longitude of the Sun
        let L0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        
        // Mean anomaly of the Sun
        let M = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let e = 0.016708634 - 0.000042037 * t
        
        // Sun's equation of center
        let C = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(degreesToRadians(M)) +
                (0.019993 - 0.000101 * t) * sin(degreesToRadians(2 * M)) +
                0.000289 * sin(degreesToRadians(3 * M))
        
        // Sun's true longitude
        let lambda = L0 + C
        
        // Sun's apparent longitude
        let omega = 125.04 - 1934.136 * t
        let lambda_apparent = lambda - 0.00569 - 0.00478 * sin(degreesToRadians(omega))
        
        // Mean obliquity of the ecliptic
        let epsilon = 23.439291 - 0.0130042 * t - 0.00000016 * t * t + 0.000000504 * t * t * t
        
        // Right ascension
        let alpha = radiansToDegrees(atan2(
            cos(degreesToRadians(epsilon)) * sin(degreesToRadians(lambda_apparent)),
            cos(degreesToRadians(lambda_apparent))
        ))
        
        // Equation of time (in minutes of time)
        let E = (L0 - alpha) * 4.0
        
        // Wrap to [-20, 20] minutes
        var E_wrapped = E
        while E_wrapped > 20.0 {
            E_wrapped -= 1440.0
        }
        while E_wrapped < -20.0 {
            E_wrapped += 1440.0
        }
        
        return E_wrapped / 60.0 // Convert to hours
    }
    
    // Convert local time to sidereal time
    static func localTimeToSidereal(jd: Double, longitude: Double) -> Double {
        // Get the Greenwich Sidereal Time
        let gst = greenwichSiderealTime(jd: jd)
        
        // Add the longitude to get Local Sidereal Time
        let lst = normalizeAngle(gst + longitude)
        
        return lst
    }
    
    // Calculate the refraction correction for an altitude
    static func refractionCorrection(altitude: Double) -> Double {
        if altitude > 85.0 {
            return 0.0
        }
        
        let altRad = degreesToRadians(altitude)
        let tan = tan(altRad)
        
        var correction: Double
        if altitude > 5.0 {
            correction = 58.1 / tan - 0.07 / (tan * tan * tan) + 0.000086 / (tan * tan * tan * tan * tan)
        } else {
            let altDeg = altitude
            correction = 1735.0 - 518.2 * altDeg + 103.4 * altDeg * altDeg - 12.79 * altDeg * altDeg * altDeg + 0.711 * altDeg * altDeg * altDeg * altDeg
        }
        
        return correction / 3600.0 // Convert from arcseconds to degrees
    }
}
