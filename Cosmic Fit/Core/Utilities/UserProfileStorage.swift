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
    let birthTimeIsUnknown: Bool
    let createdAt: Date
    let lastModified: Date
    
    // Primary initializer for new profiles
    init(firstName: String, birthDate: Date, birthLocation: String, latitude: Double, longitude: Double, timeZone: TimeZone, birthTimeIsUnknown: Bool = false) {
        self.id = UUID().uuidString
        self.firstName = firstName
        self.birthDate = birthDate
        self.birthLocation = birthLocation
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZone.identifier
        self.birthTimeIsUnknown = birthTimeIsUnknown
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // Internal initializer for updates (preserves ID and creation date)
    init(id: String, firstName: String, birthDate: Date, birthLocation: String, latitude: Double, longitude: Double, timeZoneIdentifier: String, birthTimeIsUnknown: Bool = false, createdAt: Date, lastModified: Date) {
        self.id = id
        self.firstName = firstName
        self.birthDate = birthDate
        self.birthLocation = birthLocation
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.birthTimeIsUnknown = birthTimeIsUnknown
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    // Backward-compatible decoding: old JSON files lack birthTimeIsUnknown
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        birthLocation = try container.decode(String.self, forKey: .birthLocation)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        birthTimeIsUnknown = try container.decodeIfPresent(Bool.self, forKey: .birthTimeIsUnknown) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
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
    private let onboardingPendingAuthKey = "CosmicFitOnboardingPendingAuth"
    private let showMasculineFeminineSliderKey = "CosmicFitShowMasculineFeminineSlider"
    
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
        clearLocalUserGeneratedContent()
        print("🗑️ User profile deleted")
    }

    /// Removes on-device profile, Style Guide, Daily Fit cache, location cache, recency
    /// tracker state, and related preferences. Comp access is cleared separately by
    /// `CosmicFitAuthService` on user switch / sign-out. Keychain install identifiers
    /// (`ClientInstallIdentity`) remain device-stable by design.
    func clearLocalUserGeneratedContent() {
        let existingProfile = loadUserProfile()

        try? FileManager.default.removeItem(at: profileFileURL)
        userDefaults.removeObject(forKey: userProfileKey)

        if let profile = existingProfile {
            cleanupUserDailyVibes(userId: profile.id)
            cleanupRecencyTrackers(profileHash: profile.id)
        }

        BlueprintStorage.shared.delete()
        DailyFitFrozenPayloadStorage.shared.removeAll()
        LocationManager.shared.clearCachedLocation()
        userDefaults.removeObject(forKey: showMasculineFeminineSliderKey)

        Task { @MainActor in
            BlueprintStorage.bumpRemoteBlueprintPullEpoch()
        }
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
    
    // MARK: - Onboarding Pending Auth
    
    func isOnboardingPendingAuth() -> Bool {
        return userDefaults.bool(forKey: onboardingPendingAuthKey)
    }
    
    func setOnboardingPendingAuth(_ pending: Bool) {
        userDefaults.set(pending, forKey: onboardingPendingAuthKey)
    }
    
    func clearOnboardingPendingAuth() {
        userDefaults.removeObject(forKey: onboardingPendingAuthKey)
    }

    // MARK: - Daily Fit Display Preferences

    /// When `true` (default), the masculine/feminine silhouette slider is shown on Daily Fit.
    func showMasculineFeminineSliderInDailyFit() -> Bool {
        if userDefaults.object(forKey: showMasculineFeminineSliderKey) == nil {
            return true
        }
        return userDefaults.bool(forKey: showMasculineFeminineSliderKey)
    }

    func setShowMasculineFeminineSliderInDailyFit(_ show: Bool) {
        userDefaults.set(show, forKey: showMasculineFeminineSliderKey)
        NotificationCenter.default.post(name: .dailyFitDisplayPreferencesChanged, object: nil)
    }

    // MARK: - Private Methods
    
    private func cleanupRecencyTrackers(profileHash: String) {
        let engineId = DailyFitEngineConfig.effectiveEngineId
        TarotRecencyTracker.shared.clearProfile(profileHash: profileHash, dailyFitEngineId: engineId)
        TarotVariantRotationTracker.shared.clearProfile(profileHash: profileHash, dailyFitEngineId: engineId)
        VisibleEssenceRecencyTracker.shared.clearProfile(profileHash: profileHash, dailyFitEngineId: engineId)
        ColourRecencyTracker.shared.clearProfile(profileHash: profileHash, dailyFitEngineId: engineId)
        AccentRecencyTracker.shared.clearProfile(profileHash: profileHash)
    }

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

    /// DEBUG: Posted to force-regenerate blueprint, clear daily vibes, and refresh all UI.
    static let devForceRefreshRequested = Notification.Name("devForceRefreshRequested")

    /// DEBUG: Posted when dev force refresh starts/finishes; `userInfo["isRefreshing"]` is `Bool`.
    static let devForceRefreshStateChanged = Notification.Name("devForceRefreshStateChanged")

    /// Posted when Daily Fit display preferences change (e.g. silhouette slider visibility).
    static let dailyFitDisplayPreferencesChanged = Notification.Name("dailyFitDisplayPreferencesChanged")
}
