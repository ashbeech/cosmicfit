//
//  AccentRecencyTracker.swift
//  Cosmic Fit
//
//  Tracks recent #1 accent essence selections per user to promote
//  diversity in the DailyNarrativeSelector accent slot.
//

import Foundation

final class AccentRecencyTracker {
    static var shared = AccentRecencyTracker()

    private static let RECENCY_WINDOW_DAYS = 10
    private static let STORAGE_KEY_PREFIX = "accent.recency"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func storeAccent(
        _ category: StyleEssenceCategory,
        profileHash: String,
        date: Date = Date()
    ) {
        let key = storageKey(profileHash: profileHash, date: date)
        defaults.set(category.rawValue, forKey: key)
        updateDateList(profileHash: profileHash, date: date)
    }

    func getRecentAccents(
        profileHash: String,
        referenceDate: Date = Date()
    ) -> [(category: StyleEssenceCategory, daysAgo: Int)] {
        let calendar = Calendar.current
        let dates = getDateList(profileHash: profileHash)
        var result: [(StyleEssenceCategory, Int)] = []

        for date in dates {
            guard let daysDiff = calendar.dateComponents([.day], from: date, to: referenceDate).day,
                  daysDiff >= 0, daysDiff < Self.RECENCY_WINDOW_DAYS else { continue }
            let key = storageKey(profileHash: profileHash, date: date)
            if let raw = defaults.string(forKey: key),
               let cat = StyleEssenceCategory(rawValue: raw) {
                result.append((cat, daysDiff))
            }
        }
        return result.sorted { $0.1 < $1.1 }
    }

    /// Penalty multiplier — demote recent #1 accents; repeat appearances stack further.
    func recencyPenalty(
        for category: StyleEssenceCategory,
        profileHash: String,
        referenceDate: Date = Date()
    ) -> Double {
        let recent = getRecentAccents(profileHash: profileHash, referenceDate: referenceDate)
        let matches = recent.filter { $0.category == category }
        guard !matches.isEmpty else { return 1.0 }

        let mostRecentDaysAgo = matches.map(\.daysAgo).min() ?? Self.RECENCY_WINDOW_DAYS
        let base: Double
        switch mostRecentDaysAgo {
        case 0: return 1.0
        case 1: base = 0.30
        case 2: base = 0.45
        case 3: base = 0.55
        case 4...6: base = 0.68
        default: base = 0.78
        }
        let frequencyFactor = pow(0.88, Double(max(0, matches.count - 1)))
        return base * frequencyFactor
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

    private func storageKey(profileHash: String, date: Date) -> String {
        "\(Self.STORAGE_KEY_PREFIX).\(profileHash).\(dateFormatter.string(from: date))"
    }

    private func dateListKey(profileHash: String) -> String {
        "\(Self.STORAGE_KEY_PREFIX).dates.\(profileHash)"
    }

    private func getDateList(profileHash: String) -> [Date] {
        let key = dateListKey(profileHash: profileHash)
        guard let strings = defaults.stringArray(forKey: key) else { return [] }
        return strings.compactMap { dateFormatter.date(from: $0) }
    }

    private func updateDateList(profileHash: String, date: Date) {
        var dates = getDateList(profileHash: profileHash)
        let calendar = Calendar.current
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
            dates.append(date)
            let cutoff = calendar.date(byAdding: .day, value: -Self.RECENCY_WINDOW_DAYS, to: date) ?? date
            dates = dates.filter { $0 >= cutoff }
            let key = dateListKey(profileHash: profileHash)
            defaults.set(dates.map { dateFormatter.string(from: $0) }, forKey: key)
        }
    }
}
