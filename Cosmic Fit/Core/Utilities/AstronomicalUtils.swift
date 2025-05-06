//
//  AstronomicalUtils.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

/*
import Foundation

class AstronomicalUtils {
    // Normalize an angle to the range 0-360 degrees
    static func normalizeAngle(_ angle: Double) -> Double {
        var result = angle
        while result < 0.0 {
            result += 360.0
        }
        while result >= 360.0 {
            result -= 360.0
        }
        return result
    }
    
    // Convert degrees to radians
    static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    // Convert radians to degrees
    static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
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
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        return julianDay(
            year: components.year!,
            month: components.month!,
            day: components.day!,
            hour: components.hour!,
            minute: components.minute!,
            second: components.second!
        )
    }
    
    // Calculate the obliquity of the ecliptic
    static func obliquityOfEcliptic(jd: Double) -> Double {
        // Calculate T (time in Julian centuries since J2000.0)
        let T = (jd - 2451545.0) / 36525.0
        
        // More accurate formula from Astronomical Algorithms by Jean Meeus
        let epsilon = 23.43929111 -
                      0.01300416667 * T -
                      0.00000163889 * T * T +
                      0.00000503611 * T * T * T -
                      0.00000001277778 * T * T * T * T -
                      0.00000000166667 * T * T * T * T * T
        
        return epsilon
    }
    
    // Calculate sidereal time at Greenwich
    static func greenwichSiderealTime(jd: Double) -> Double {
        // Time in Julian centuries since J2000.0
        let T = (jd - 2451545.0) / 36525.0
        
        // Mean sidereal time at Greenwich
        var theta = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
                   0.000387933 * T * T - T * T * T / 38710000.0
        
        // Normalize to 0-360 range
        theta = normalizeAngle(theta)
        
        return theta
    }
    
    // Calculate equation of time (difference between apparent and mean solar time)
    static func equationOfTime(jd: Double) -> Double {
        let T = (jd - 2451545.0) / 36525.0
        
        // Mean longitude of the Sun
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        
        // Mean anomaly of the Sun
        let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        
        // Eccentricity of Earth's orbit
        let e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T * T
        
        // Sun's equation of center
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(degreesToRadians(M)) +
                (0.019993 - 0.000101 * T) * sin(degreesToRadians(2 * M)) +
                0.000289 * sin(degreesToRadians(3 * M))
        
        // True longitude of the Sun
        let trueL = L0 + C
        
        // Right ascension of the Sun
        let ra = radiansToDegrees(atan2(cos(degreesToRadians(obliquityOfEcliptic(jd: jd))) *
                                        sin(degreesToRadians(trueL)),
                                        cos(degreesToRadians(trueL))))
        
        // Equation of time in minutes of time
        var E = (L0 - normalizeAngle(ra)) / 15.0
        
        // Adjust for quadrant
        if E > 12.0 {
            E -= 24.0
        } else if E < -12.0 {
            E += 24.0
        }
        
        return E
    }
    
    // Calculate nutation in longitude and obliquity
    static func nutation(jd: Double) -> (longitude: Double, obliquity: Double) {
        // Calculate T (time in Julian centuries since J2000.0)
        let T = (jd - 2451545.0) / 36525.0
        
        // Mean elongation of the Moon from the Sun
        let D = 297.85036 + 445267.111480 * T - 0.0019142 * T * T + T * T * T / 189474.0
        
        // Mean anomaly of the Sun
        let M = 357.52772 + 35999.050340 * T - 0.0001603 * T * T - T * T * T / 300000.0
        
        // Mean anomaly of the Moon
        let Mprime = 134.96298 + 477198.867398 * T + 0.0086972 * T * T + T * T * T / 56250.0
        
        // Moon's argument of latitude
        let F = 93.27191 + 483202.017538 * T - 0.0036825 * T * T + T * T * T / 327270.0
        
        // Longitude of the ascending node of the Moon's mean orbit
        let omega = 125.04452 - 1934.136261 * T + 0.0020708 * T * T + T * T * T / 450000.0
        
        // Convert to radians
        let Drad = degreesToRadians(D)
        let Mrad = degreesToRadians(M)
        let Mprimerad = degreesToRadians(Mprime)
        let Frad = degreesToRadians(F)
        let omegaRad = degreesToRadians(omega)
        
        // Nutation in longitude - more accurate formula
        let nutLong = (-17.2 * sin(omegaRad) - 1.32 * sin(2 * Drad) - 0.23 * sin(2 * Mrad) + 0.21 * sin(2 * omegaRad) +
                        0.57 * sin(2 * Drad - Mprimerad) + 0.10 * sin(2 * Drad + Mrad) + 0.09 * sin(2 * Mrad - Mprimerad) +
                        0.09 * sin(2 * Drad + Mprimerad)) / 3600.0
        
        // Nutation in obliquity - more accurate formula
        let nutObl = (9.2 * cos(omegaRad) + 0.57 * cos(2 * Drad) + 0.10 * cos(2 * Mrad) - 0.09 * cos(2 * omegaRad) +
                       0.09 * cos(2 * Drad - Mprimerad) + 0.09 * cos(2 * Drad + Mprimerad)) / 3600.0
        
        return (nutLong, nutObl)
    }
}
*/
