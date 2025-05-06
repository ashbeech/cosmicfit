import Foundation

struct JulianDateCalculator {
    // Calculate Julian Date from a given date and time (UTC)
    static func calculateJulianDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Double {
        var y = Double(year)
        var m = Double(month)
        
        // Adjust month and year for January and February
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let d = Double(day) + (Double(hour) / 24.0) + (Double(minute) / 1440.0) + (Double(second) / 86400.0)
        
        // Check if date is in Gregorian calendar (after October 15, 1582)
        let gregorian = (year > 1582) ||
                       (year == 1582 && month > 10) ||
                       (year == 1582 && month == 10 && day >= 15)
        
        // Calculate A and B terms for Julian/Gregorian calendar
        let a = Int(y / 100.0)
        let b = gregorian ? (2 - a + Int(a / 4)) : 0
        
        // Calculate Julian Day Number - broken down into steps
        let term1 = Int(365.25 * (y + 4716))
        let term2 = Int(30.6001 * (m + 1))
        let jdn = Double(term1 + term2) + d + Double(b) - 1524.5
        
        return jdn
    }
    
    // Calculate Julian Date from Date object
    static func calculateJulianDate(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return 0
        }
        
        return calculateJulianDate(year: year, month: month, day: day,
                                  hour: hour, minute: minute, second: second)
    }
    
    // Convert local time to UTC
    static func localToUTC(date: Date, timezone: TimeZone) -> Date {
        let secondsFromGMT = timezone.secondsFromGMT(for: date)
        return date.addingTimeInterval(Double(-secondsFromGMT))
    }
    
    // Calculate sidereal time at Greenwich
    static func calculateGreenwichSiderealTime(julianDay: Double) -> Double {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Calculate GMST in degrees - break down the calculation
        let term1 = 280.46061837
        let term2 = 360.98564736629 * (julianDay - 2451545.0)
        let term3 = 0.000387933 * T * T
        let term4 = T * T * T / 38710000.0
        var theta = term1 + term2 + term3 - term4
        
        // Normalize to range [0, 360)
        theta = theta.truncatingRemainder(dividingBy: 360.0)
        if theta < 0 {
            theta += 360.0
        }
        
        return theta
    }
    
    // Calculate local sidereal time
    static func calculateLocalSiderealTime(julianDay: Double, longitude: Double) -> Double {
        // Get Greenwich sidereal time
        var siderealTime = calculateGreenwichSiderealTime(julianDay: julianDay)
        
        // Add longitude (east positive)
        siderealTime += longitude
        
        // Normalize to range [0, 360)
        siderealTime = siderealTime.truncatingRemainder(dividingBy: 360.0)
        if siderealTime < 0 {
            siderealTime += 360.0
        }
        
        return siderealTime
    }
}
