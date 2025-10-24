//
//  TarotRecencyTracker.swift
//  Cosmic Fit
//
//  Created for tracking recent Tarot card selections with decay penalties
//

import Foundation

/// Tracks recent Tarot card selections per user with date-based storage
class TarotRecencyTracker {
    
    // MARK: - Constants
    
    private static let RECENCY_WINDOW_DAYS = 7
    private static let YESTERDAY_PENALTY_BASE = 0.12
    private static let PENALTY_FLOOR = 0.55
    private static let STORAGE_KEY_PREFIX = "LastTarot"
    
    // MARK: - Singleton
    
    static let shared = TarotRecencyTracker()
    private init() {}
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_GB")
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
        
        print("💾 Stored Tarot selection: \(cardName) for profile \(profileHash) on \(dateFormatter.string(from: date))")
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
            }
        }
        
        // Sort by most recent first
        return recentSelections.sorted { $0.1 < $1.1 }
    }
    
    /// Calculate decay penalty multiplier for a card based on recency
    /// - Parameters:
    ///   - cardName: Name of the card to check
    ///   - profileHash: User profile identifier
    ///   - referenceDate: Date to calculate recency from (defaults to today)
    /// - Returns: Penalty multiplier (0.0-1.0) to apply to card's score
    func calculateDecayPenalty(
        for cardName: String,
        profileHash: String,
        referenceDate: Date = Date()
    ) -> Double {
        
        let recentSelections = getRecentSelections(profileHash: profileHash, referenceDate: referenceDate)
        
        // Find if this card was selected recently
        guard let match = recentSelections.first(where: { $0.cardName.lowercased() == cardName.lowercased() }) else {
            // Card not in recent history, no penalty
            return 1.0
        }
        
        let daysSince = match.daysAgo
        
        // Apply decay formula: score *= max(0.55, 1.0 - 0.12 * (8 - daysSince))
        // Yesterday (1 day): 1.0 - 0.12 * 7 = 0.16 (84% penalty)
        // 2 days ago: 1.0 - 0.12 * 6 = 0.28 (72% penalty)
        // 3 days ago: 1.0 - 0.12 * 5 = 0.40 (60% penalty)
        // 7 days ago: 1.0 - 0.12 * 1 = 0.88 (12% penalty)
        
        let rawMultiplier = 1.0 - (Self.YESTERDAY_PENALTY_BASE * Double(8 - daysSince))
        let multiplier = max(Self.PENALTY_FLOOR, rawMultiplier)
        
        print("🔄 Decay penalty for '\(cardName)': \(daysSince) days ago → \(String(format: "%.2f", multiplier))x multiplier (\(String(format: "%.0f", (1.0 - multiplier) * 100))% penalty)")
        
        return multiplier
    }
    
    /// Get the card selected yesterday for a profile (for backwards compatibility)
    /// - Parameter profileHash: User profile identifier
    /// - Returns: Card name if one was selected yesterday, nil otherwise
    func getYesterdaySelection(profileHash: String) -> String? {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }
        
        let key = storageKey(profileHash: profileHash, date: yesterday)
        return userDefaults.string(forKey: key)
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
        } else {
            for (cardName, daysAgo) in recentSelections {
                let penalty = calculateDecayPenalty(for: cardName, profileHash: profileHash)
                let penaltyPercent = (1.0 - penalty) * 100
                
                if daysAgo == 0 {
                    print("  • TODAY: \(cardName)")
                } else if daysAgo == 1 {
                    print("  • Yesterday: \(cardName) (penalty: \(String(format: "%.0f", penaltyPercent))%)")
                } else {
                    print("  • \(daysAgo) days ago: \(cardName) (penalty: \(String(format: "%.0f", penaltyPercent))%)")
                }
            }
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    // MARK: - Private Methods
    
    /// Generate storage key for a specific profile and date
    private func storageKey(profileHash: String, date: Date) -> String {
        let dateString = dateFormatter.string(from: date)
        return "\(Self.STORAGE_KEY_PREFIX)::\(profileHash)::\(dateString)"
    }
    
    /// Generate key for profile date list
    private func profileDateListKey(profileHash: String) -> String {
        return "\(Self.STORAGE_KEY_PREFIX)::Dates::\(profileHash)"
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
        }
    }
}
