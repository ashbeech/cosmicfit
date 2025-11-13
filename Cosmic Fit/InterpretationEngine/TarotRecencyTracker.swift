//
//  TarotRecencyTracker.swift
//  Cosmic Fit
//
//  FINAL HYBRID VERSION - Hard-block recency with en_US_POSIX locale
//

import Foundation

/// Tracks recent Tarot card selections per user with date-based storage
class TarotRecencyTracker {
    
    // MARK: - Constants
    
    /// Number of days to track recent selections (increased for longer variety memory)
    private static let RECENCY_WINDOW_DAYS = EngineConfig.tarotRecencyWindowDays
    
    /// Base penalty multiplier for yesterday's card (increased for stronger variety enforcement)
    private static let YESTERDAY_PENALTY_BASE = EngineConfig.tarotRecencyStrongPenalty
    
    private static let COOLDOWN_DAYS = 3  // Hard-block period
    
    /// Minimum penalty floor (cards can't be reduced below this multiplier)
    private static let PENALTY_FLOOR = 0.55
    
    /// Storage key prefix for UserDefaults
    private static let STORAGE_KEY_PREFIX = "tarot.recency"
    
    // MARK: - Singleton
    
    static let shared = TarotRecencyTracker()
    private init() {}
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")  // CRITICAL: Consistent date formatting
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Store a card selection for a specific profile and date
    /// - Parameters:
    ///   - cardName: Name of the selected Tarot card
    ///   - profileHash: User profile identifier
    ///   - date: Date of selection (defaults to today)
    func storeCardSelection(_ cardName: String, profileHash: String, date: Date = Date()) {
        let key = storageKey(profileHash: profileHash, date: date)
        userDefaults.set(cardName, forKey: key)
        
        // Update the list of dates for this profile
        updateProfileDateList(profileHash: profileHash, date: date)
        
        // CRITICAL: Force synchronization to ensure persistence
        userDefaults.synchronize()
        
        // ENHANCED: Log exact stored key/value for verification
        let storedValue = userDefaults.string(forKey: key) ?? "nil"
        print("💾 STORED: key='\(key)' value='\(storedValue)'")
    }
    
    /// Get cards within the cooldown period (3 days) - for hard-blocking
    /// - Parameters:
    ///   - profileHash: User profile identifier
    ///   - referenceDate: Date to calculate from (defaults to today)
    /// - Returns: Set of card names within cooldown period
    func getCooldownCards(profileHash: String, referenceDate: Date = Date()) -> Set<String> {
        let recentSelections = getRecentSelections(profileHash: profileHash, referenceDate: referenceDate)
        
        let cooldownCards = Set(recentSelections
            .filter { $0.daysAgo <= Self.COOLDOWN_DAYS }
            .map { $0.cardName })
        
        print("🚫 COOLDOWN CARDS (3-day block): \(cooldownCards.count) cards")
        for cardName in cooldownCards {
            print("   • \(cardName)")
        }
        
        return cooldownCards
    }
    
    /// Get recent card selections for a profile
    /// - Parameters:
    ///   - profileHash: User profile identifier
    ///   - referenceDate: Date to calculate recency from (defaults to today)
    /// - Returns: Array of (cardName, daysAgo) tuples for the last 7 days
    func getRecentSelections(profileHash: String, referenceDate: Date = Date()) -> [(cardName: String, daysAgo: Int)] {
        var recentSelections: [(String, Int)] = []
        let calendar = Calendar.current
        
        // Get dates for this profile
        let profileDates = getProfileDates(profileHash: profileHash)
        
        print("🔍 RECENCY CHECK: Found \(profileDates.count) stored dates for profile \(profileHash)")
        
        for date in profileDates {
            // Calculate days difference
            guard let daysDifference = calendar.dateComponents([.day], from: date, to: referenceDate).day else {
                continue
            }
            
            // Only include selections within the recency window
            guard daysDifference >= 0 && daysDifference < Self.RECENCY_WINDOW_DAYS else {
                continue
            }
            
            // Get card name for this date
            let key = storageKey(profileHash: profileHash, date: date)
            if let cardName = userDefaults.string(forKey: key) {
                recentSelections.append((cardName, daysDifference))
                print("🔍   • Found: '\(cardName)' from \(daysDifference) days ago (key: '\(key)')")
            }
        }
        
        // Sort by most recent first
        return recentSelections.sorted { $0.1 < $1.1 }
    }
    
    /// Get the card selected yesterday for a profile
    /// - Parameter profileHash: User profile identifier
    /// - Returns: Card name if one was selected yesterday, nil otherwise
    func getYesterdayCard(profileHash: String) -> String? {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }
        
        let key = storageKey(profileHash: profileHash, date: yesterday)
        let card = userDefaults.string(forKey: key)
        
        if let card = card {
            print("📅 Yesterday's card: '\(card)'")
        }
        
        return card
    }
    
    /// Clean up old entries beyond the recency window
    /// - Parameter profileHash: User profile identifier
    func cleanupOldEntries(profileHash: String) {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -Self.RECENCY_WINDOW_DAYS, to: Date()) else {
            return
        }
        
        let profileDates = getProfileDates(profileHash: profileHash)
        var remainingDates: [Date] = []
        var removedCount = 0
        
        for date in profileDates {
            if date < cutoffDate {
                // Remove old entry
                let key = storageKey(profileHash: profileHash, date: date)
                userDefaults.removeObject(forKey: key)
                removedCount += 1
            } else {
                remainingDates.append(date)
            }
        }
        
        // Update profile date list
        if removedCount > 0 {
            saveProfileDates(profileHash: profileHash, dates: remainingDates)
            userDefaults.synchronize()
            print("🧹 Cleaned up \(removedCount) old Tarot entries for profile \(profileHash)")
        }
    }
    
    /// Clear all recency data for a profile
    /// - Parameter profileHash: User profile identifier
    func clearProfile(profileHash: String) {
        let profileDates = getProfileDates(profileHash: profileHash)
        
        for date in profileDates {
            let key = storageKey(profileHash: profileHash, date: date)
            userDefaults.removeObject(forKey: key)
        }
        
        // Clear date list
        let dateListKey = profileDateListKey(profileHash: profileHash)
        userDefaults.removeObject(forKey: dateListKey)
        
        userDefaults.synchronize()
        print("🗑️ Cleared all Tarot recency data for profile \(profileHash)")
    }
    
    /// Debug method to show recent history for a profile
    /// - Parameter profileHash: User profile identifier
    func debugShowHistory(profileHash: String) {
        print("\n📜 TAROT RECENCY HISTORY FOR PROFILE: \(profileHash)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let recentSelections = getRecentSelections(profileHash: profileHash)
        
        if recentSelections.isEmpty {
            print("  No recent selections found")
            
            // Debug: Check if any keys exist at all
            let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
            let relevantKeys = allKeys.filter { $0.contains(profileHash) && $0.contains("tarot.recency") }
            
            if !relevantKeys.isEmpty {
                print("  ⚠️ Found \(relevantKeys.count) storage keys for this profile:")
                for key in relevantKeys.prefix(3) {
                    if let value = userDefaults.string(forKey: key) {
                        print("     - \(key): \(value)")
                    }
                }
            } else {
                print("  ℹ️ No storage keys found matching this profile")
            }
        } else {
            for (cardName, daysAgo) in recentSelections {
                let cooldownStatus = daysAgo <= Self.COOLDOWN_DAYS ? " [BLOCKED]" : ""
                
                if daysAgo == 0 {
                    print("  • TODAY: \(cardName)\(cooldownStatus)")
                } else if daysAgo == 1 {
                    print("  • Yesterday: \(cardName)\(cooldownStatus)")
                } else {
                    print("  • \(daysAgo) days ago: \(cardName)\(cooldownStatus)")
                }
            }
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    // MARK: - Private Methods
    
    /// Generate storage key for a specific profile and date
    /// Format: "tarot.recency.{profileHash}.{yyyy-MM-dd}"
    private func storageKey(profileHash: String, date: Date) -> String {
        let dateString = dateFormatter.string(from: date)
        return "\(Self.STORAGE_KEY_PREFIX).\(profileHash).\(dateString)"
    }
    
    /// Generate key for profile date list
    private func profileDateListKey(profileHash: String) -> String {
        return "\(Self.STORAGE_KEY_PREFIX).dates.\(profileHash)"
    }
    
    /// Get list of dates for a profile
    private func getProfileDates(profileHash: String) -> [Date] {
        let key = profileDateListKey(profileHash: profileHash)
        guard let dateStrings = userDefaults.stringArray(forKey: key) else {
            return []
        }
        
        return dateStrings.compactMap { dateFormatter.date(from: $0) }
    }
    
    /// Save list of dates for a profile
    private func saveProfileDates(profileHash: String, dates: [Date]) {
        let key = profileDateListKey(profileHash: profileHash)
        let dateStrings = dates.map { dateFormatter.string(from: $0) }
        userDefaults.set(dateStrings, forKey: key)
        userDefaults.synchronize()
    }
    
    /// Update the date list for a profile to include a new date
    private func updateProfileDateList(profileHash: String, date: Date) {
        var dates = getProfileDates(profileHash: profileHash)
        
        // Check if date already exists
        let calendar = Calendar.current
        let dateExists = dates.contains { calendar.isDate($0, inSameDayAs: date) }
        
        if !dateExists {
            dates.append(date)
            saveProfileDates(profileHash: profileHash, dates: dates)
        }
    }
}

// MARK: - Migration Helper (for backwards compatibility)

extension TarotRecencyTracker {
    
    /// Migrate from old global storage key to new namespaced storage
    /// - Parameter profileHash: User profile identifier
    func migrateOldStorage(profileHash: String) {
        // Check if old key exists
        if let oldCard = userDefaults.string(forKey: "LastSelectedTarotCard") {
            // Store it as yesterday's selection for this profile
            let calendar = Calendar.current
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                storeCardSelection(oldCard, profileHash: profileHash, date: yesterday)
                print("🔄 Migrated old Tarot selection '\(oldCard)' to new storage for profile \(profileHash)")
            }
            
            // Remove old key
            userDefaults.removeObject(forKey: "LastSelectedTarotCard")
            userDefaults.synchronize()
        }
        
        // Also migrate any old "LastTarot::" prefixed keys
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let oldFormatKeys = allKeys.filter { $0.hasPrefix("LastTarot::") && $0.contains(profileHash) }
        
        for oldKey in oldFormatKeys {
            if let cardName = userDefaults.string(forKey: oldKey) {
                // Extract date from old key format if possible
                let components = oldKey.components(separatedBy: "::")
                if components.count >= 3, let date = dateFormatter.date(from: components[2]) {
                    storeCardSelection(cardName, profileHash: profileHash, date: date)
                    print("🔄 Migrated old format key '\(oldKey)' to new format")
                }
            }
            
            // Remove old key
            userDefaults.removeObject(forKey: oldKey)
        }
        
        if !oldFormatKeys.isEmpty {
            userDefaults.synchronize()
        }
    }
}
