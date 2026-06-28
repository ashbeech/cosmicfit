//
//  DailyFitFrozenPayloadStorage.swift
//  Cosmic Fit
//
//  Persists the exact DailyFitPayload for a calendar day once the user has revealed
//  the card, so cold launches never regenerate a different tarot or copy.
//

import Foundation

enum DailyFitRevealPersistence {

    // MARK: - Shared date helper

    private static let dayFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_GB_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }()

    static func calendarDayString(from date: Date) -> String {
        dayFormatter.timeZone = .current
        return dayFormatter.string(from: date)
    }

    // MARK: - Per-day reveal / slider keys

    static func revealedFlagKey(
        forCalendarDay date: Date,
        engineId: String = DailyFitEngineRegistry.productionId
    ) -> String {
        let day = calendarDayString(from: date)
        if engineId == DailyFitEngineRegistry.productionId {
            return "CardRevealed_\(day)"
        }
        return "CardRevealed_\(engineId)_\(day)"
    }

    static func sliderEntranceAnimationFlagKey(
        forCalendarDay date: Date,
        engineId: String = DailyFitEngineRegistry.productionId
    ) -> String {
        let day = calendarDayString(from: date)
        if engineId == DailyFitEngineRegistry.productionId {
            return "SliderEntrancePlayed_\(day)"
        }
        return "SliderEntrancePlayed_\(engineId)_\(day)"
    }

    /// Clears persisted "card revealed" flags for each calendar day from `start` through `end`
    /// (inclusive), using `Calendar.current` start-of-day boundaries. Used when birth chart
    /// inputs change so Daily Fit is not constrained by stale reveal state.
    static func clearRevealFlags(from start: Date, through end: Date, calendar: Calendar = .current) {
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            UserDefaults.standard.removeObject(forKey: revealedFlagKey(forCalendarDay: day))
            UserDefaults.standard.removeObject(forKey: sliderEntranceAnimationFlagKey(forCalendarDay: day))
            for descriptor in DailyFitEngineRegistry.allDescriptors where descriptor.id != DailyFitEngineRegistry.productionId {
                UserDefaults.standard.removeObject(
                    forKey: revealedFlagKey(forCalendarDay: day, engineId: descriptor.id)
                )
                UserDefaults.standard.removeObject(
                    forKey: sliderEntranceAnimationFlagKey(forCalendarDay: day, engineId: descriptor.id)
                )
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
    }

    // MARK: - First free daily fit

    private static let firstFreeRevealDateKey = "CosmicFit_FirstFreeDailyFitDate"
    private static let migrationPerformedKey = "CosmicFit_FirstFreeMigrationDone"

    /// In-memory cache: `nil` means not yet loaded; `.some(nil)` means loaded but no value stored.
    private static var _cachedFirstFree: String?? = nil

    /// The calendar day (`yyyy-MM-dd`) of the user's first-ever revealed daily fit,
    /// which is always shown in full regardless of subscription status.
    static var firstFreeRevealDate: String? {
        if let cached = _cachedFirstFree { return cached }
        migrateFirstFreeRevealDateIfNeeded()
        let value = UserDefaults.standard.string(forKey: firstFreeRevealDateKey)
        _cachedFirstFree = .some(value)
        return value
    }

    /// Records the first-ever revealed daily fit date. No-op if already set.
    static func markFirstDailyFitRevealed(for date: Date) {
        guard UserDefaults.standard.string(forKey: firstFreeRevealDateKey) == nil else { return }
        let day = calendarDayString(from: date)
        UserDefaults.standard.set(day, forKey: firstFreeRevealDateKey)
        _cachedFirstFree = .some(day)
    }

    static func clearFirstFreeRevealDate() {
        UserDefaults.standard.removeObject(forKey: firstFreeRevealDateKey)
        UserDefaults.standard.removeObject(forKey: migrationPerformedKey)
        _cachedFirstFree = nil
    }

    /// Determines whether the torn-paper paywall should be applied after a card reveal.
    /// Extracted from `DailyFitViewController` so the logic is unit-testable without a VC.
    static func shouldObscureContentForRestrictedUser(
        isCardRevealed: Bool,
        displayDate: Date,
        hasFullAccess: Bool
    ) -> Bool {
        guard isCardRevealed else { return false }
        guard !hasFullAccess else { return false }
        let dayKey = calendarDayString(from: displayDate)
        if firstFreeRevealDate == dayKey { return false }
        return true
    }

    // MARK: - Migration (existing users)

    /// On first read after the update ships, backfills `firstFreeRevealDate` from the
    /// earliest existing `CardRevealed_*` UserDefaults key so the user's true first
    /// daily fit retroactively becomes the free day.
    private static func migrateFirstFreeRevealDateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationPerformedKey) else { return }
        UserDefaults.standard.set(true, forKey: migrationPerformedKey)

        guard UserDefaults.standard.string(forKey: firstFreeRevealDateKey) == nil else { return }

        let datePattern = #"^\d{4}-\d{2}-\d{2}$"#
        var earliestDate: String?
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            guard key.hasPrefix("CardRevealed_"),
                  UserDefaults.standard.bool(forKey: key) else { continue }

            let suffix = String(key.dropFirst("CardRevealed_".count))
            let candidate: String
            if suffix.range(of: datePattern, options: .regularExpression) != nil {
                candidate = suffix
            } else if let lastUnderscore = suffix.lastIndex(of: "_") {
                let datePart = String(suffix[suffix.index(after: lastUnderscore)...])
                guard datePart.range(of: datePattern, options: .regularExpression) != nil else { continue }
                candidate = datePart
            } else {
                continue
            }

            if let current = earliestDate {
                if candidate < current { earliestDate = candidate }
            } else {
                earliestDate = candidate
            }
        }

        if let date = earliestDate {
            UserDefaults.standard.set(date, forKey: firstFreeRevealDateKey)
        }
    }
}

final class DailyFitFrozenPayloadStorage {

    static let shared = DailyFitFrozenPayloadStorage()

    private let rootDirectoryURL: URL?
    private var lastPurgedEngineId: String?

    init(rootDirectoryURL: URL? = nil) {
        self.rootDirectoryURL = rootDirectoryURL
    }

    private var directoryURL: URL {
        if let rootDirectoryURL {
            try? FileManager.default.createDirectory(at: rootDirectoryURL, withIntermediateDirectories: true)
            return rootDirectoryURL
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("DailyFitFrozen", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func sanitizedProfileKey(_ profileKey: String) -> String {
        profileKey.replacingOccurrences(of: "/", with: "_")
    }

    private func calendarDayString(from date: Date) -> String {
        DailyFitRevealPersistence.calendarDayString(from: date)
    }

    private func legacyFileURL(date: Date, profileKey: String) -> URL {
        let day = calendarDayString(from: date)
        return directoryURL.appendingPathComponent("\(sanitizedProfileKey(profileKey))_\(day).json")
    }

    private func namespacedFileURL(date: Date, profileKey: String, engineId: String) -> URL {
        let day = calendarDayString(from: date)
        return directoryURL.appendingPathComponent(
            "\(sanitizedProfileKey(profileKey))_\(engineId)_\(day).json"
        )
    }

    @discardableResult
    func save(payload: DailyFitPayload, date: Date, profileKey: String) -> Bool {
        let engineId = DailyFitEngineConfig.effectiveEngineId
        let stamped = payload.withDailyFitEngineId(engineId)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = []
            let data = try encoder.encode(stamped)
            try data.write(
                to: namespacedFileURL(date: date, profileKey: profileKey, engineId: engineId),
                options: .atomic
            )
            return true
        } catch {
            print("⚠️ Daily Fit frozen save failed: \(error.localizedDescription)")
            return false
        }
    }

    func load(date: Date, profileKey: String) -> DailyFitPayload? {
        let effectiveId = DailyFitEngineConfig.effectiveEngineId
        if lastPurgedEngineId != effectiveId {
            purgeStaleArtifacts(date: date, profileKey: profileKey, effectiveEngineId: effectiveId)
            lastPurgedEngineId = effectiveId
        }

        let namespacedURL = namespacedFileURL(date: date, profileKey: profileKey, engineId: effectiveId)
        if FileManager.default.fileExists(atPath: namespacedURL.path),
           let payload = decodePayload(from: namespacedURL),
           payload.resolvedDailyFitEngineId == effectiveId {
            return payload
        }

        let legacyURL = legacyFileURL(date: date, profileKey: profileKey)
        if FileManager.default.fileExists(atPath: legacyURL.path),
           let payload = decodePayload(from: legacyURL),
           payload.resolvedDailyFitEngineId == effectiveId {
            return payload
        }

        return nil
    }

    /// Removes every frozen payload (e.g. dev refresh or Style Guide data wipe).
    func removeAll() {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL, includingPropertiesForKeys: nil
        ) else { return }
        for url in urls where url.pathExtension == "json" {
            try? FileManager.default.removeItem(at: url)
        }
        lastPurgedEngineId = nil
        clearRevealAndSliderFlags()
        DailyFitRevealPersistence.clearFirstFreeRevealDate()
    }

    /// Clears persisted Daily Fit reveal and slider-animation flags from UserDefaults.
    func clearRevealAndSliderFlags() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix("CardRevealed_") || key.hasPrefix("SliderEntrancePlayed_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Forces the next `load` to re-run purge logic (e.g. after engine override change).
    func invalidatePurgeCache() {
        lastPurgedEngineId = nil
    }

    // MARK: - Engine mismatch invalidation (P2)

    /// Clears reveal flags and deletes frozen files when stored engine ≠ effective engine.
    /// Invoked from `load` so launch-time tab bar paths invalidate without extra tab bar logic.
    private func purgeStaleArtifacts(date: Date, profileKey: String, effectiveEngineId: String) {
        let day = calendarDayString(from: date)
        let profilePrefix = sanitizedProfileKey(profileKey)
        var didPurge = false

        let legacyURL = legacyFileURL(date: date, profileKey: profileKey)
        if FileManager.default.fileExists(atPath: legacyURL.path) {
            let storedId = decodePayload(from: legacyURL)?.resolvedDailyFitEngineId
                ?? DailyFitEngineRegistry.productionId
            if storedId != effectiveEngineId {
                try? FileManager.default.removeItem(at: legacyURL)
                didPurge = true
            }
        }

        if let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL, includingPropertiesForKeys: nil
        ) {
            for url in urls where url.pathExtension == "json" {
                let name = url.lastPathComponent
                guard name.hasPrefix("\(profilePrefix)_"), name.contains("_\(day).json") else { continue }
                if let fileEngineId = engineIdFromNamespacedFilename(name),
                   fileEngineId != effectiveEngineId {
                    try? FileManager.default.removeItem(at: url)
                    didPurge = true
                }
            }
        }

        let noValidFrozen = !hasValidFrozenPayload(date: date, profileKey: profileKey, effectiveEngineId: effectiveEngineId)
        var revealKeysToCheck = Set<String>()
        revealKeysToCheck.insert(DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date, engineId: effectiveEngineId))
        revealKeysToCheck.insert(DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date, engineId: DailyFitEngineRegistry.productionId))
        var sliderEntranceKeysToCheck = Set<String>()
        sliderEntranceKeysToCheck.insert(DailyFitRevealPersistence.sliderEntranceAnimationFlagKey(forCalendarDay: date, engineId: effectiveEngineId))
        sliderEntranceKeysToCheck.insert(DailyFitRevealPersistence.sliderEntranceAnimationFlagKey(forCalendarDay: date, engineId: DailyFitEngineRegistry.productionId))
        for key in revealKeysToCheck {
            if UserDefaults.standard.bool(forKey: key), noValidFrozen {
                UserDefaults.standard.removeObject(forKey: key)
                didPurge = true
            }
        }
        for key in sliderEntranceKeysToCheck {
            if UserDefaults.standard.bool(forKey: key), noValidFrozen {
                UserDefaults.standard.removeObject(forKey: key)
                didPurge = true
            }
        }

        if didPurge {
            #if DEBUG
            print("[DailyFitFrozenPayloadStorage] Purged stale freeze for \(profilePrefix) on \(day) (effective: \(effectiveEngineId))")
            #endif
        }
    }

    private func hasValidFrozenPayload(date: Date, profileKey: String, effectiveEngineId: String) -> Bool {
        let namespacedURL = namespacedFileURL(date: date, profileKey: profileKey, engineId: effectiveEngineId)
        if FileManager.default.fileExists(atPath: namespacedURL.path),
           let payload = decodePayload(from: namespacedURL),
           payload.resolvedDailyFitEngineId == effectiveEngineId {
            return true
        }

        let legacyURL = legacyFileURL(date: date, profileKey: profileKey)
        if FileManager.default.fileExists(atPath: legacyURL.path),
           let payload = decodePayload(from: legacyURL),
           payload.resolvedDailyFitEngineId == effectiveEngineId {
            return true
        }

        return false
    }

    private func engineIdFromNamespacedFilename(_ filename: String) -> String? {
        guard filename.hasSuffix(".json") else { return nil }
        let stem = String(filename.dropLast(5))
        guard stem.count > 11 else { return nil }
        let dateSuffix = String(stem.suffix(10))
        guard dateSuffix.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            return nil
        }
        let withoutDate = String(stem.dropLast(11))
        for descriptor in DailyFitEngineRegistry.allDescriptors {
            let suffix = "_\(descriptor.id)"
            if withoutDate.hasSuffix(suffix) {
                return descriptor.id
            }
        }
        return nil
    }

    private func decodePayload(from url: URL) -> DailyFitPayload? {
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
}
