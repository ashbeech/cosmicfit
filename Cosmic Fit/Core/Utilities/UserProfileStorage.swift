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
    let firstName: String
    let birthDate: Date
    let birthLocation: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let createdAt: Date
    let lastModified: Date
    
    // Primary initializer for new profiles
    init(firstName: String, birthDate: Date, birthLocation: String, latitude: Double, longitude: Double, timeZone: TimeZone) {
        self.id = UUID().uuidString
        self.firstName = firstName
        self.birthDate = birthDate
        self.birthLocation = birthLocation
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZone.identifier
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // Internal initializer for updates (preserves ID and creation date)
    init(id: String, firstName: String, birthDate: Date, birthLocation: String, latitude: Double, longitude: Double, timeZoneIdentifier: String, createdAt: Date, lastModified: Date) {
        self.id = id
        self.firstName = firstName
        self.birthDate = birthDate
        self.birthLocation = birthLocation
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    // Validation helper
    var isComplete: Bool {
        return !firstName.isEmpty &&
               !birthLocation.isEmpty &&
               latitude != 0.0 &&
               longitude != 0.0
    }
}

// MARK: - User Profile Storage Manager
class UserProfileStorage {
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let userProfileKey = "CosmicFitUserProfile"
    private let hasSeenWelcomeKey = "CosmicFitHasSeenWelcome"
    private let migrationDoneKey = "CosmicFitProfileMigratedToFile"
    
    private var profileFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("cosmic_fit_profile.json")
    }
    
    // MARK: - Singleton
    static let shared = UserProfileStorage()
    private init() {}
    
    // MARK: - Migration
    
    func migrateFromUserDefaultsIfNeeded() {
        guard !userDefaults.bool(forKey: migrationDoneKey) else { return }
        
        if let data = userDefaults.data(forKey: userProfileKey) {
            do {
                try data.write(to: profileFileURL, options: .atomic)
                userDefaults.removeObject(forKey: userProfileKey)
                print("✅ Profile migrated from UserDefaults to Documents")
            } catch {
                print("⚠️ Profile migration failed: \(error.localizedDescription)")
                return
            }
        }
        userDefaults.set(true, forKey: migrationDoneKey)
    }
    
    // MARK: - Public Methods
    
    @discardableResult
    func saveUserProfile(_ profile: UserProfile) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            try data.write(to: profileFileURL, options: .atomic)
            print("✅ User profile saved with ID: \(profile.id)")
            return true
        } catch {
            print("❌ Error saving user profile: \(error)")
            return false
        }
    }
    
    func loadUserProfile() -> UserProfile? {
        // File-based path (primary)
        if FileManager.default.fileExists(atPath: profileFileURL.path) {
            do {
                let data = try Data(contentsOf: profileFileURL)
                let decoder = JSONDecoder()
                let profile = try decoder.decode(UserProfile.self, from: data)
                return profile
            } catch {
                print("❌ Error loading profile from file: \(error)")
            }
        }
        
        // UserDefaults fallback (pre-migration)
        if let data = userDefaults.data(forKey: userProfileKey) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(UserProfile.self, from: data)
            } catch {
                print("❌ Error loading profile from UserDefaults: \(error)")
            }
        }
        
        return nil
    }
    
    func hasCompleteUserProfile() -> Bool {
        guard let profile = loadUserProfile() else {
            return false
        }
        return profile.isComplete
    }
    
    func hasUserProfile() -> Bool {
        return FileManager.default.fileExists(atPath: profileFileURL.path)
            || userDefaults.data(forKey: userProfileKey) != nil
    }
    
    func deleteUserProfile() {
        let existingProfile = loadUserProfile()
        
        try? FileManager.default.removeItem(at: profileFileURL)
        userDefaults.removeObject(forKey: userProfileKey)
        
        if let profile = existingProfile {
            cleanupUserDailyVibes(userId: profile.id)
        }
        
        print("🗑️ User profile deleted")
    }
    
    func hasSeenWelcome() -> Bool {
        return userDefaults.bool(forKey: hasSeenWelcomeKey)
    }
    
    func markWelcomeSeen() {
        userDefaults.set(true, forKey: hasSeenWelcomeKey)
    }
    
    func resetWelcomeFlag() {
        userDefaults.removeObject(forKey: hasSeenWelcomeKey)
    }
    
    // MARK: - Private Methods
    
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
    
    /// Posted when the daily vibe needs to be refreshed due to date change
    static let dailyVibeNeedsRefresh = Notification.Name("dailyVibeNeedsRefresh")
    
    /// Posted when profile view controller requests dismissal
    static let dismissProfileRequested = Notification.Name("dismissProfileRequested")
}
