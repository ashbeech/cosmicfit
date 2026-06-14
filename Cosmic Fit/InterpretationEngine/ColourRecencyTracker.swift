//
//  ColourRecencyTracker.swift
//  Cosmic Fit
//
//  Cross-day memory for daily palette colour selection (stage1_experimental).
//  Tracks which palette hexes were shown and which was the hero (slot 0),
//  enabling coverage-debt scoring and hero rotation over a 14-day window.
//  Engine-namespaced to match TarotRecencyTracker / VisibleEssenceRecencyTracker conventions.
//

import Foundation

final class ColourRecencyTracker {
    static var shared = ColourRecencyTracker()

    private static let RETENTION_WINDOW_DAYS = 14
    private static let STORAGE_KEY_PREFIX = "colour.recency"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Storage

    func storeDailyColours(
        shownHexes: [String],
        heroHex: String,
        profileHash: String,
        date: Date,
        dailyFitEngineId: String
    ) {
        let normalized = shownHexes.map { Self.normalizeHex($0) }
        let heroNorm = Self.normalizeHex(heroHex)
        let shownKey = shownStorageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
        let heroKey = heroStorageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
        defaults.set(normalized, forKey: shownKey)
        defaults.set(heroNorm, forKey: heroKey)
        updateDateList(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
    }

    // MARK: - Query

    /// Days since the hex was shown in any slot (nil = never within the retention window).
    func daysSinceShown(
        hex: String,
        profileHash: String,
        referenceDate: Date,
        dailyFitEngineId: String
    ) -> Int? {
        let target = Self.normalizeHex(hex)
        let calendar = Calendar.current
        let dates = getDateList(profileHash: profileHash, engineId: dailyFitEngineId)

        for date in dates.sorted(by: { $0 > $1 }) {
            guard let daysDiff = calendar.dateComponents([.day], from: date, to: referenceDate).day,
                  daysDiff >= 0 else { continue }
            let key = shownStorageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
            if let stored = defaults.stringArray(forKey: key), stored.contains(target) {
                return daysDiff
            }
        }
        return nil
    }

    /// Days since the hex was the hero/first-slot colour (nil = never within the retention window).
    func daysSinceHero(
        hex: String,
        profileHash: String,
        referenceDate: Date,
        dailyFitEngineId: String
    ) -> Int? {
        let target = Self.normalizeHex(hex)
        let calendar = Calendar.current
        let dates = getDateList(profileHash: profileHash, engineId: dailyFitEngineId)

        for date in dates.sorted(by: { $0 > $1 }) {
            guard let daysDiff = calendar.dateComponents([.day], from: date, to: referenceDate).day,
                  daysDiff >= 0 else { continue }
            let key = heroStorageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
            if let stored = defaults.string(forKey: key), stored == target {
                return daysDiff
            }
        }
        return nil
    }

    /// Normalized coverage debt in 0...1. Never-shown within the window = 1.0,
    /// shown today = 0.0. Linear decay: debt = min(daysSince, window) / window.
    func coverageDebt(
        hex: String,
        profileHash: String,
        referenceDate: Date,
        dailyFitEngineId: String
    ) -> Double {
        guard let days = daysSinceShown(
            hex: hex,
            profileHash: profileHash,
            referenceDate: referenceDate,
            dailyFitEngineId: dailyFitEngineId
        ) else {
            return 1.0
        }
        if days == 0 { return 0.0 }
        return min(Double(days), Double(Self.RETENTION_WINDOW_DAYS)) / Double(Self.RETENTION_WINDOW_DAYS)
    }

    /// Normalized hero debt in 0...1. Never hero within window = 1.0,
    /// hero today = 0.0. Linear decay.
    func heroDebt(
        hex: String,
        profileHash: String,
        referenceDate: Date,
        dailyFitEngineId: String
    ) -> Double {
        guard let days = daysSinceHero(
            hex: hex,
            profileHash: profileHash,
            referenceDate: referenceDate,
            dailyFitEngineId: dailyFitEngineId
        ) else {
            return 1.0
        }
        if days == 0 { return 0.0 }
        return min(Double(days), Double(Self.RETENTION_WINDOW_DAYS)) / Double(Self.RETENTION_WINDOW_DAYS)
    }

    // MARK: - Maintenance

    func clearProfile(profileHash: String, dailyFitEngineId: String) {
        let dates = getDateList(profileHash: profileHash, engineId: dailyFitEngineId)
        for date in dates {
            let shownKey = shownStorageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
            let heroKey = heroStorageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
            defaults.removeObject(forKey: shownKey)
            defaults.removeObject(forKey: heroKey)
        }
        let listKey = dateListKey(profileHash: profileHash, engineId: dailyFitEngineId)
        defaults.removeObject(forKey: listKey)
    }

    func resetAll() {
        let prefix = Self.STORAGE_KEY_PREFIX
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Private

    static func normalizeHex(_ hex: String) -> String {
        let t = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if t.hasPrefix("#") { return t }
        return "#" + t
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    private func shownStorageKey(profileHash: String, date: Date, engineId: String) -> String {
        "\(Self.STORAGE_KEY_PREFIX).shown.\(engineId).\(profileHash).\(dateFormatter.string(from: date))"
    }

    private func heroStorageKey(profileHash: String, date: Date, engineId: String) -> String {
        "\(Self.STORAGE_KEY_PREFIX).hero.\(engineId).\(profileHash).\(dateFormatter.string(from: date))"
    }

    private func dateListKey(profileHash: String, engineId: String) -> String {
        "\(Self.STORAGE_KEY_PREFIX).dates.\(engineId).\(profileHash)"
    }

    private func getDateList(profileHash: String, engineId: String) -> [Date] {
        let key = dateListKey(profileHash: profileHash, engineId: engineId)
        guard let strings = defaults.stringArray(forKey: key) else { return [] }
        return strings.compactMap { dateFormatter.date(from: $0) }
    }

    private func updateDateList(profileHash: String, date: Date, engineId: String) {
        var dates = getDateList(profileHash: profileHash, engineId: engineId)
        let calendar = Calendar.current
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
            dates.append(date)
            let cutoff = calendar.date(byAdding: .day, value: -Self.RETENTION_WINDOW_DAYS, to: date) ?? date
            dates = dates.filter { $0 >= cutoff }
            let key = dateListKey(profileHash: profileHash, engineId: engineId)
            defaults.set(dates.map { dateFormatter.string(from: $0) }, forKey: key)
        }
    }
}
