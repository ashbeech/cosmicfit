//
//  VisibleEssenceRecencyTracker.swift
//  Cosmic Fit
//
//  Hard-block recency gate for the full visible essence top-3 (accent + supporting).
//  Prevents high-scoring floaters from occupying supporting slots day after day.
//  Engine-namespaced to match TarotRecencyTracker conventions.
//

import Foundation

final class VisibleEssenceRecencyTracker {
    static var shared = VisibleEssenceRecencyTracker()

    private static let RETENTION_WINDOW_DAYS = 10
    private static let STORAGE_KEY_PREFIX = "essence.visible.recency"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func storeVisibleTop3(
        _ categories: [StyleEssenceCategory],
        profileHash: String,
        date: Date,
        dailyFitEngineId: String
    ) {
        let key = storageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
        defaults.set(categories.map(\.rawValue), forKey: key)
        updateDateList(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
    }

    /// Categories within the cooldown window (daysAgo 1...cooldownDayCount). Today (daysAgo 0) excluded.
    func getCooldownCategories(
        profileHash: String,
        referenceDate: Date,
        dailyFitEngineId: String,
        cooldownDayCount: Int
    ) -> Set<StyleEssenceCategory> {
        let recent = getRecentVisibleEssences(
            profileHash: profileHash,
            referenceDate: referenceDate,
            dailyFitEngineId: dailyFitEngineId,
            windowDays: cooldownDayCount
        )
        return Set(recent.filter { $0.daysAgo >= 1 && $0.daysAgo <= cooldownDayCount }.map(\.category))
    }

    /// Full history with age, for progressive relaxation fallback.
    func getRecentVisibleEssences(
        profileHash: String,
        referenceDate: Date,
        dailyFitEngineId: String,
        windowDays: Int = 10
    ) -> [(category: StyleEssenceCategory, daysAgo: Int)] {
        let calendar = Calendar.current
        let dates = getDateList(profileHash: profileHash, engineId: dailyFitEngineId)
        var result: [(StyleEssenceCategory, Int)] = []

        for date in dates {
            guard let daysDiff = calendar.dateComponents([.day], from: date, to: referenceDate).day,
                  daysDiff >= 0, daysDiff <= windowDays else { continue }
            let key = storageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
            if let rawValues = defaults.stringArray(forKey: key) {
                for raw in rawValues {
                    if let cat = StyleEssenceCategory(rawValue: raw) {
                        result.append((cat, daysDiff))
                    }
                }
            }
        }
        return result.sorted { $0.1 < $1.1 }
    }

    func clearProfile(profileHash: String, dailyFitEngineId: String) {
        let dates = getDateList(profileHash: profileHash, engineId: dailyFitEngineId)
        for date in dates {
            let key = storageKey(profileHash: profileHash, date: date, engineId: dailyFitEngineId)
            defaults.removeObject(forKey: key)
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

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    private func storageKey(profileHash: String, date: Date, engineId: String) -> String {
        "\(Self.STORAGE_KEY_PREFIX).\(engineId).\(profileHash).\(dateFormatter.string(from: date))"
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
