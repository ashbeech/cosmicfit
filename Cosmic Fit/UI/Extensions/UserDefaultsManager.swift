//
//  UserDefaultsManager.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation
import CoreLocation

/// Manager class for storing and retrieving user preferences using UserDefaults
class UserDefaultsManager {
    
    // MARK: - Keys
    
    /// UserDefaults keys
    private enum Keys {
        // Birth date keys
        static let day = "birthDay"
        static let month = "birthMonth"
        static let year = "birthYear"
        
        // Birth time keys
        static let hour = "birthHour"
        static let minute = "birthMinute"
        static let amPm = "birthAmPm"
        
        // Birth location keys
        static let locationName = "birthLocationName"
        static let latitude = "birthLatitude"
        static let longitude = "birthLongitude"
        
        // App settings keys
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredChartDisplay = "preferredChartDisplay" // 0: Text, 1: Wheel
    }
    
    // MARK: - Save Methods
    
    /// Save birth date information
    /// - Parameters:
    ///   - day: Birth day (1-31)
    ///   - month: Birth month (0-11, 0-based index)
    ///   - year: Birth year
    static func saveBirthDate(day: Int, month: Int, year: Int) {
        UserDefaults.standard.set(day, forKey: Keys.day)
        UserDefaults.standard.set(month, forKey: Keys.month)
        UserDefaults.standard.set(year, forKey: Keys.year)
    }
    
    /// Save birth time information
    /// - Parameters:
    ///   - hour: Birth hour (1-12)
    ///   - minute: Birth minute (0-59)
    ///   - amPm: AM/PM indicator (0: AM, 1: PM)
    static func saveBirthTime(hour: Int, minute: Int, amPm: Int) {
        UserDefaults.standard.set(hour, forKey: Keys.hour)
        UserDefaults.standard.set(minute, forKey: Keys.minute)
        UserDefaults.standard.set(amPm, forKey: Keys.amPm)
    }
    
    /// Save birth location information
    /// - Parameters:
    ///   - name: Location name
    ///   - location: CLLocation object with coordinates
    static func saveLocation(name: String, location: CLLocation) {
        UserDefaults.standard.set(name, forKey: Keys.locationName)
        UserDefaults.standard.set(location.coordinate.latitude, forKey: Keys.latitude)
        UserDefaults.standard.set(location.coordinate.longitude, forKey: Keys.longitude)
    }
    
    /// Save preference for chart display
    /// - Parameter displayMode: Display mode (0: Text, 1: Wheel)
    static func saveChartDisplayPreference(displayMode: Int) {
        UserDefaults.standard.set(displayMode, forKey: Keys.preferredChartDisplay)
    }
    
    /// Save onboarding completion status
    /// - Parameter completed: Whether onboarding has been completed
    static func saveOnboardingStatus(completed: Bool) {
        UserDefaults.standard.set(completed, forKey: Keys.hasCompletedOnboarding)
    }
    
    // MARK: - Load Methods
    
    /// Load birth date information
    /// - Returns: Tuple with day, month, and year, or nil if not set
    static func loadBirthDate() -> (day: Int, month: Int, year: Int)? {
        if UserDefaults.standard.object(forKey: Keys.day) != nil &&
           UserDefaults.standard.object(forKey: Keys.month) != nil &&
           UserDefaults.standard.object(forKey: Keys.year) != nil {
            
            let day = UserDefaults.standard.integer(forKey: Keys.day)
            let month = UserDefaults.standard.integer(forKey: Keys.month)
            let year = UserDefaults.standard.integer(forKey: Keys.year)
            
            return (day, month, year)
        }
        
        return nil
    }
    
    /// Load birth time information
    /// - Returns: Tuple with hour, minute, and AM/PM indicator, or nil if not set
    static func loadBirthTime() -> (hour: Int, minute: Int, amPm: Int)? {
        if UserDefaults.standard.object(forKey: Keys.hour) != nil &&
           UserDefaults.standard.object(forKey: Keys.minute) != nil &&
           UserDefaults.standard.object(forKey: Keys.amPm) != nil {
            
            let hour = UserDefaults.standard.integer(forKey: Keys.hour)
            let minute = UserDefaults.standard.integer(forKey: Keys.minute)
            let amPm = UserDefaults.standard.integer(forKey: Keys.amPm)
            
            return (hour, minute, amPm)
        }
        
        return nil
    }
    
    /// Load birth location information
    /// - Returns: Tuple with location name and CLLocation object, or nil if not set
    static func loadLocation() -> (name: String, location: CLLocation)? {
        if let name = UserDefaults.standard.string(forKey: Keys.locationName),
           UserDefaults.standard.object(forKey: Keys.latitude) != nil,
           UserDefaults.standard.object(forKey: Keys.longitude) != nil {
            
            let latitude = UserDefaults.standard.double(forKey: Keys.latitude)
            let longitude = UserDefaults.standard.double(forKey: Keys.longitude)
            let location = CLLocation(latitude: latitude, longitude: longitude)
            
            return (name, location)
        }
        
        return nil
    }
    
    /// Load preferred chart display mode
    /// - Returns: Display mode (0: Text, 1: Wheel), defaults to 0 if not set
    static func loadChartDisplayPreference() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.preferredChartDisplay)
    }
    
    /// Load onboarding completion status
    /// - Returns: Whether onboarding has been completed, defaults to false if not set
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
    }
    
    // MARK: - Convenience Methods
    
    /// Save complete birth data
    /// - Parameters:
    ///   - day: Birth day
    ///   - month: Birth month
    ///   - year: Birth year
    ///   - hour: Birth hour
    ///   - minute: Birth minute
    ///   - amPm: AM/PM indicator
    ///   - locationName: Location name
    ///   - location: Location coordinates
    static func saveBirthData(day: Int, month: Int, year: Int,
                              hour: Int, minute: Int, amPm: Int,
                              locationName: String, location: CLLocation) {
        saveBirthDate(day: day, month: month, year: year)
        saveBirthTime(hour: hour, minute: minute, amPm: amPm)
        saveLocation(name: locationName, location: location)
    }
    
    /// Clear all saved data
    static func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
