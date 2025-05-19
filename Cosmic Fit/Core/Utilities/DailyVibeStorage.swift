//
//  DailyVibeStorage.swift
//  Cosmic Fit
//
//  Created for Daily Vibe persistence functionality
//

import Foundation

/// Storage manager for daily vibe content with date-based persistence
class DailyVibeStorage {
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let dailyVibeKeysKey = "DailyVibeKeys"
    private let keyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Singleton
    static let shared = DailyVibeStorage()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save daily vibe content for a specific date
    /// - Parameters:
    ///   - content: The daily vibe content to save
    ///   - date: The date for which to save the content (defaults to today)
    ///   - chartIdentifier: Optional identifier for the chart (e.g., birth date + location hash)
    /// - Returns: Boolean indicating success
    @discardableResult
    func saveDailyVibe(_ content: DailyVibeContent,
                      for date: Date = Date(),
                      chartIdentifier: String? = nil) -> Bool {
        do {
            let encoder = JSONEncoder()
            
            // Create a wrapper that includes metadata
            let wrapper = DailyVibeWrapper(
                content: content,
                generatedDate: date,
                chartIdentifier: chartIdentifier
            )
            
            let data = try encoder.encode(wrapper)
            let key = dailyVibeKey(for: date, chartIdentifier: chartIdentifier)
            
            userDefaults.set(data, forKey: key)
            
            // Update list of saved daily vibe keys
            updateSavedKeys(with: key)
            
            print("✅ Daily vibe saved for date: \(keyDateFormatter.string(from: date))")
            return true
        } catch {
            print("❌ Error saving daily vibe: \(error)")
            return false
        }
    }
    
    /// Load daily vibe content for a specific date
    /// - Parameters:
    ///   - date: The date for which to load content (defaults to today)
    ///   - chartIdentifier: Optional identifier for the chart
    /// - Returns: Daily vibe content if available
    func loadDailyVibe(for date: Date = Date(),
                      chartIdentifier: String? = nil) -> DailyVibeContent? {
        let key = dailyVibeKey(for: date, chartIdentifier: chartIdentifier)
        
        guard let data = userDefaults.data(forKey: key) else {
            print("📱 No daily vibe found for date: \(keyDateFormatter.string(from: date))")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let wrapper = try decoder.decode(DailyVibeWrapper.self, from: data)
            
            print("✅ Daily vibe loaded for date: \(keyDateFormatter.string(from: date))")
            return wrapper.content
        } catch {
            print("❌ Error loading daily vibe: \(error)")
            return nil
        }
    }
    
    /// Check if daily vibe content exists for a specific date
    /// - Parameters:
    ///   - date: The date to check (defaults to today)
    ///   - chartIdentifier: Optional identifier for the chart
    /// - Returns: Boolean indicating if content exists
    func hasDailyVibe(for date: Date = Date(),
                     chartIdentifier: String? = nil) -> Bool {
        let key = dailyVibeKey(for: date, chartIdentifier: chartIdentifier)
        return userDefaults.data(forKey: key) != nil
    }
    
    /// Delete daily vibe content for a specific date
    /// - Parameters:
    ///   - date: The date for which to delete content
    ///   - chartIdentifier: Optional identifier for the chart
    /// - Returns: Boolean indicating success
    @discardableResult
    func deleteDailyVibe(for date: Date,
                        chartIdentifier: String? = nil) -> Bool {
        let key = dailyVibeKey(for: date, chartIdentifier: chartIdentifier)
        userDefaults.removeObject(forKey: key)
        
        // Remove from saved keys list
        removeSavedKey(key)
        
        print("🗑️ Daily vibe deleted for date: \(keyDateFormatter.string(from: date))")
        return true
    }
    
    /// Clean up old daily vibe entries (older than specified days)
    /// - Parameter daysToKeep: Number of days to keep (default: 30)
    func cleanupOldEntries(daysToKeep: Int = 30) {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -daysToKeep, to: Date()) else {
            return
        }
        
        let savedKeys = getSavedKeys()
        var keysToRemove: [String] = []
        
        for key in savedKeys {
            // Extract date from key
            if let dateString = extractDateFromKey(key),
               let date = keyDateFormatter.date(from: dateString),
               date < cutoffDate {
                userDefaults.removeObject(forKey: key)
                keysToRemove.append(key)
            }
        }
        
        // Update saved keys list
        for key in keysToRemove {
            removeSavedKey(key)
        }
        
        if !keysToRemove.isEmpty {
            print("🧹 Cleaned up \(keysToRemove.count) old daily vibe entries")
        }
    }
    
    /// Get all saved daily vibe dates for a chart
    /// - Parameter chartIdentifier: Optional identifier for the chart
    /// - Returns: Array of dates for which daily vibes are saved
    func getSavedDates(for chartIdentifier: String? = nil) -> [Date] {
        let savedKeys = getSavedKeys()
        var dates: [Date] = []
        
        for key in savedKeys {
            // Check if key matches chart identifier
            if let chartId = chartIdentifier {
                guard key.contains(chartId) else { continue }
            }
            
            // Extract date from key
            if let dateString = extractDateFromKey(key),
               let date = keyDateFormatter.date(from: dateString) {
                dates.append(date)
            }
        }
        
        return dates.sorted(by: >) // Most recent first
    }
    
    // MARK: - Private Methods
    
    /// Generate storage key for daily vibe
    private func dailyVibeKey(for date: Date, chartIdentifier: String? = nil) -> String {
        let dateString = keyDateFormatter.string(from: date)
        
        if let chartId = chartIdentifier {
            return "DailyVibe_\(dateString)_\(chartId)"
        } else {
            return "DailyVibe_\(dateString)"
        }
    }
    
    /// Update the list of saved daily vibe keys
    private func updateSavedKeys(with newKey: String) {
        var savedKeys = getSavedKeys()
        if !savedKeys.contains(newKey) {
            savedKeys.append(newKey)
            userDefaults.set(savedKeys, forKey: dailyVibeKeysKey)
        }
    }
    
    /// Remove a key from the saved keys list
    private func removeSavedKey(_ keyToRemove: String) {
        var savedKeys = getSavedKeys()
        savedKeys.removeAll { $0 == keyToRemove }
        userDefaults.set(savedKeys, forKey: dailyVibeKeysKey)
    }
    
    /// Get all saved daily vibe keys
    private func getSavedKeys() -> [String] {
        return userDefaults.stringArray(forKey: dailyVibeKeysKey) ?? []
    }
    
    /// Extract date string from storage key
    private func extractDateFromKey(_ key: String) -> String? {
        let components = key.components(separatedBy: "_")
        if components.count >= 2 {
            return components[1] // Expected format: "DailyVibe_yyyy-MM-dd_chartId" or "DailyVibe_yyyy-MM-dd"
        }
        return nil
    }
    
    /// Generate a chart identifier from birth details
    static func generateChartIdentifier(birthDate: Date, latitude: Double, longitude: Double) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH:mm"
        let dateString = formatter.string(from: birthDate)
        let locationString = String(format: "%.4f_%.4f", latitude, longitude)
        
        // Create a simple hash to keep the identifier manageable
        let combined = "\(dateString)_\(locationString)"
        return String(combined.hash).replacingOccurrences(of: "-", with: "N")
    }
}

// MARK: - Storage Models

/// Wrapper for daily vibe content with metadata
private struct DailyVibeWrapper: Codable {
    let content: DailyVibeContent
    let generatedDate: Date
    let chartIdentifier: String?
    var version: Int = 1 // For future migration needs
}
