//
//  DailyFitFrozenPayloadStorage.swift
//  Cosmic Fit
//
//  Persists the exact DailyFitPayload for a calendar day once the user has revealed
//  the card, so cold launches never regenerate a different tarot or copy.
//

import Foundation

enum DailyFitRevealPersistence {
    static func revealedFlagKey(forCalendarDay date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_GB_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        return "CardRevealed_\(fmt.string(from: date))"
    }

    /// Clears persisted "card revealed" flags for each calendar day from `start` through `end`
    /// (inclusive), using `Calendar.current` start-of-day boundaries. Used when birth chart
    /// inputs change so Daily Fit is not constrained by stale reveal state.
    static func clearRevealFlags(from start: Date, through end: Date, calendar: Calendar = .current) {
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            UserDefaults.standard.removeObject(forKey: revealedFlagKey(forCalendarDay: day))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
    }
}

final class DailyFitFrozenPayloadStorage {

    static let shared = DailyFitFrozenPayloadStorage()

    private init() {}

    private var directoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("DailyFitFrozen", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func sanitizedProfileKey(_ profileKey: String) -> String {
        profileKey.replacingOccurrences(of: "/", with: "_")
    }

    private func fileURL(date: Date, profileKey: String) -> URL {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_GB_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        let day = fmt.string(from: date)
        return directoryURL.appendingPathComponent("\(sanitizedProfileKey(profileKey))_\(day).json")
    }

    @discardableResult
    func save(payload: DailyFitPayload, date: Date, profileKey: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = []
            let data = try encoder.encode(payload)
            try data.write(to: fileURL(date: date, profileKey: profileKey), options: .atomic)
            return true
        } catch {
            print("⚠️ Daily Fit frozen save failed: \(error.localizedDescription)")
            return false
        }
    }

    func load(date: Date, profileKey: String) -> DailyFitPayload? {
        let url = fileURL(date: date, profileKey: profileKey)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DailyFitPayload.self, from: data)
        } catch {
            print("⚠️ Daily Fit frozen load failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Removes every frozen payload (e.g. dev refresh or Style Guide data wipe).
    func removeAll() {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL, includingPropertiesForKeys: nil
        ) else { return }
        for url in urls where url.pathExtension == "json" {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
