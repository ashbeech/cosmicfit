//
//  UserProfileStorage.swift
//  Cosmic Fit
//
//  Created for user profile persistence functionality
//

import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable {
    let id: String
    let birthDate: Date
    let birthLocation: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let createdAt: Date
    let lastModified: Date
    
    // Primary initializer for new profiles
    init(birthDate: Date, birthLocation: String, latitude: Double, longitude: Double, timeZone: TimeZone) {
        self.id = UUID().uuidString
        self.birthDate = birthDate
        self.birthLocation = birthLocation
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZone.identifier
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // Internal initializer for updates (preserves ID and creation date)
    init(id: String, birthDate: Date, birthLocation: String, latitude: Double, longitude: Double, timeZoneIdentifier: String, createdAt: Date, lastModified: Date) {
        self.id = id
        self.birthDate = birthDate
        self.birthLocation = birthLocation
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}

// MARK: - User Profile Storage Manager
class UserProfileStorage {
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let userProfileKey = "CosmicFitUserProfile"
    private let userFirstLaunchKey = "CosmicFitFirstLaunch"
    
    // MARK: - Singleton
    static let shared = UserProfileStorage()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save user profile to local storage
    /// - Parameter profile: The user profile to save
    /// - Returns: Boolean indicating success
    func saveUserProfile(_ profile: UserProfile) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: userProfileKey)
            userDefaults.set(false, forKey: userFirstLaunchKey) // Mark as not first launch
            print("✅ User profile saved with ID: \(profile.id)")
            return true
        } catch {
            print("❌ Error saving user profile: \(error)")
            return false
        }
    }
    
    /// Load user profile from local storage
    /// - Returns: User profile if available
    func loadUserProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: userProfileKey) else {
            print("📱 No user profile found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(UserProfile.self, from: data)
            print("✅ User profile loaded with ID: \(profile.id)")
            return profile
        } catch {
            print("❌ Error loading user profile: \(error)")
            return nil
        }
    }
    
    /// Check if user profile exists
    /// - Returns: Boolean indicating if profile exists
    func hasUserProfile() -> Bool {
        return userDefaults.data(forKey: userProfileKey) != nil
    }
    
    /// Delete user profile from local storage
    func deleteUserProfile() {
        userDefaults.removeObject(forKey: userProfileKey)
        userDefaults.set(true, forKey: userFirstLaunchKey) // Mark as first launch again
        
        // Also clean up all daily vibes for this user
        if let profile = loadUserProfile() {
            cleanupUserDailyVibes(userId: profile.id)
        }
        
        print("🗑️ User profile deleted")
    }
    
    /// Check if this is the first app launch
    /// - Returns: Boolean indicating if this is first launch
    func isFirstLaunch() -> Bool {
        return userDefaults.bool(forKey: userFirstLaunchKey)
    }
    
    // MARK: - Private Methods
    
    /// Clean up all daily vibes for a specific user
    private func cleanupUserDailyVibes(userId: String) {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let userKeys = allKeys.filter { $0.contains("DailyVibe") && $0.contains(userId) }
        
        for key in userKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("🧹 Cleaned up \(userKeys.count) daily vibes for user: \(userId)")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Posted when user profile is updated
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    
    /// Posted when user profile is deleted
    static let userProfileDeleted = Notification.Name("userProfileDeleted")
}
