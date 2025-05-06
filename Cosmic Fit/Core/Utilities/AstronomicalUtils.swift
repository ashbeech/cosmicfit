//
//  AstronomicalUtils.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

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
        let t = (jd - 2451545.0) / 36525.0
        let epsilon = 23.43929111 - 0.01300416667 * t - 0.00000016389 * t * t + 0.00000050361 * t * t * t
        return epsilon
    }
}
