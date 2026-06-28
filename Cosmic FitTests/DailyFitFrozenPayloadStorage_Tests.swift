//
//  DailyFitFrozenPayloadStorage_Tests.swift
//  Cosmic FitTests
//
//  P2 — frozen payload namespacing, legacy load, engine mismatch invalidation.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite(.serialized)
struct DailyFitFrozenPayloadStorage_Tests {

    private func calendarDayString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_GB_POSIX")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func makeTempStorage() throws -> (DailyFitFrozenPayloadStorage, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DailyFitFrozenTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return (DailyFitFrozenPayloadStorage(rootDirectoryURL: dir), dir)
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    @Test("Legacy frozen file without engine id loads when effective engine is production")
    func legacyFileLoadsForProduction() throws {
        let (storage, dir) = try makeTempStorage()
        defer { cleanup(dir) }

        #if DEBUG
        let overrideKey = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        UserDefaults.standard.set(DailyFitEngineRegistry.productionId, forKey: overrideKey)
        defer { UserDefaults.standard.removeObject(forKey: overrideKey) }
        #endif

        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let day = calendarDayString(from: date)
        let profileKey = "test-profile"
        let payload = DailyFitPayload.fixture(generatedAt: date)

        let legacyURL = dir.appendingPathComponent("test-profile_\(day).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(payload).write(to: legacyURL)

        let loaded = storage.load(date: date, profileKey: profileKey)
        #expect(loaded != nil)
        #expect(loaded?.tarotCard.name == payload.tarotCard.name)
        #expect(loaded?.resolvedDailyFitEngineId == DailyFitEngineRegistry.productionId)
    }

    #if DEBUG
    @Test("Legacy frozen file returns nil when effective engine is legacy_baseline")
    func legacyFileRejectedForLegacyBaseline() throws {
        let (storage, dir) = try makeTempStorage()
        defer { cleanup(dir) }

        let overrideKey = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        UserDefaults.standard.set(DailyFitEngineRegistry.legacyBaselineId, forKey: overrideKey)
        defer { UserDefaults.standard.removeObject(forKey: overrideKey) }

        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let day = calendarDayString(from: date)
        let profileKey = "test-profile"
        let payload = DailyFitPayload.fixture(generatedAt: date)

        let legacyURL = dir.appendingPathComponent("test-profile_\(day).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(payload).write(to: legacyURL)

        let revealKey = DailyFitRevealPersistence.revealedFlagKey(forCalendarDay: date)
        UserDefaults.standard.set(true, forKey: revealKey)
        defer { UserDefaults.standard.removeObject(forKey: revealKey) }

        let loaded = storage.load(date: date, profileKey: profileKey)
        #expect(loaded == nil)
        #expect(UserDefaults.standard.bool(forKey: revealKey) == false)
        #expect(FileManager.default.fileExists(atPath: legacyURL.path) == false)
    }

    @Test("Save writes namespaced filename and stamps dailyFitEngineId in JSON")
    func saveUsesNamespacedPathAndStampsEngineId() throws {
        let (storage, dir) = try makeTempStorage()
        defer { cleanup(dir) }

        let overrideKey = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        UserDefaults.standard.set(DailyFitEngineRegistry.legacyBaselineId, forKey: overrideKey)
        defer { UserDefaults.standard.removeObject(forKey: overrideKey) }

        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let day = calendarDayString(from: date)
        let profileKey = "user/abc"
        let payload = DailyFitPayload.fixture(generatedAt: date)

        #expect(storage.save(payload: payload, date: date, profileKey: profileKey))

        let expectedName = "user_abc_\(DailyFitEngineRegistry.legacyBaselineId)_\(day).json"
        let fileURL = dir.appendingPathComponent(expectedName)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyFitPayload.self, from: Data(contentsOf: fileURL))
        #expect(decoded.dailyFitEngineId == DailyFitEngineRegistry.legacyBaselineId)

        let loaded = storage.load(date: date, profileKey: profileKey)
        #expect(loaded?.resolvedDailyFitEngineId == DailyFitEngineRegistry.legacyBaselineId)
    }
    #endif

    @Test("Payload missing dailyFitEngineId on decode resolves to production")
    func missingEngineIdResolvesToProduction() throws {
        let payload = DailyFitPayload.fixture()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyFitPayload.self, from: data)
        #expect(decoded.dailyFitEngineId == nil)
        #expect(decoded.resolvedDailyFitEngineId == DailyFitEngineRegistry.productionId)
    }

    @Test("Frozen payload preserves narrativeBrief through save/load cycle")
    func frozenPayloadPreservesNarrativeBrief() throws {
        let (storage, dir) = try makeTempStorage()
        defer { cleanup(dir) }

        let brief = DailyNarrativeBrief(
            anchorCategories: [.romantic, .classic, .polished],
            weatherCategories: [.maximalist, .drama, .edgy],
            relationship: .stretch,
            resolvedTheme: "Polished Drama",
            instruction: "Keep the base refined, add one bold detail.",
            avoid: "Do not let the outfit become chaotic.",
            foundationControls: ["silhouette", "polish", "wearability", "comfort"],
            accentControls: ["colour pop", "texture", "accessory", "contrast", "styling twist"],
            essenceCaption: "Adapt signal: dramatic.",
            paletteCaption: "Let drama show in colour.",
            scalesCaption: "Sky intensity on top of polish."
        )
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let payload = DailyFitPayload.fixture(generatedAt: date).withNarrativeBrief(brief)

        #expect(storage.save(payload: payload, date: date, profileKey: "brief-test"))

        let loaded = storage.load(date: date, profileKey: "brief-test")
        #expect(loaded?.narrativeBrief == brief)
    }

    @Test("Legacy frozen payload without narrativeBrief decodes as nil brief")
    func legacyFrozenDecodesNilBrief() throws {
        let payload = DailyFitPayload.fixture()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyFitPayload.self, from: data)
        #expect(decoded.narrativeBrief == nil)
    }

    // MARK: - First Free Daily Fit

    private static let firstFreeKey = "CosmicFit_FirstFreeDailyFitDate"
    private static let migrationDoneKey = "CosmicFit_FirstFreeMigrationDone"

    private func cleanupFirstFreeKeys() {
        UserDefaults.standard.removeObject(forKey: Self.firstFreeKey)
        UserDefaults.standard.removeObject(forKey: Self.migrationDoneKey)
    }

    @Test("markFirstDailyFitRevealed persists date and is idempotent")
    func markFirstFreeIsIdempotent() {
        cleanupFirstFreeKeys()
        defer { cleanupFirstFreeKeys() }

        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let day2 = Date(timeIntervalSince1970: 1_800_000_000 + 86400)

        DailyFitRevealPersistence.markFirstDailyFitRevealed(for: day1)
        let stored = DailyFitRevealPersistence.firstFreeRevealDate
        #expect(stored == DailyFitRevealPersistence.calendarDayString(from: day1))

        DailyFitRevealPersistence.markFirstDailyFitRevealed(for: day2)
        let stillOriginal = DailyFitRevealPersistence.firstFreeRevealDate
        #expect(stillOriginal == DailyFitRevealPersistence.calendarDayString(from: day1))
    }

    @Test("shouldObscureContentForRestrictedUser returns false on first-free day")
    func firstFreeDayIsNotObscured() {
        cleanupFirstFreeKeys()
        defer { cleanupFirstFreeKeys() }

        let day = Date(timeIntervalSince1970: 1_800_000_000)
        DailyFitRevealPersistence.markFirstDailyFitRevealed(for: day)

        let result = DailyFitRevealPersistence.shouldObscureContentForRestrictedUser(
            isCardRevealed: true, displayDate: day, hasFullAccess: false
        )
        #expect(result == false)
    }

    @Test("shouldObscureContentForRestrictedUser returns true on a different day")
    func secondDayIsObscured() {
        cleanupFirstFreeKeys()
        defer { cleanupFirstFreeKeys() }

        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let day2 = Date(timeIntervalSince1970: 1_800_000_000 + 86400)
        DailyFitRevealPersistence.markFirstDailyFitRevealed(for: day1)

        let result = DailyFitRevealPersistence.shouldObscureContentForRestrictedUser(
            isCardRevealed: true, displayDate: day2, hasFullAccess: false
        )
        #expect(result == true)
    }

    @Test("shouldObscureContentForRestrictedUser returns false when unrevealed")
    func unrevealedIsNeverObscured() {
        cleanupFirstFreeKeys()
        defer { cleanupFirstFreeKeys() }

        let result = DailyFitRevealPersistence.shouldObscureContentForRestrictedUser(
            isCardRevealed: false, displayDate: Date(), hasFullAccess: false
        )
        #expect(result == false)
    }

    @Test("shouldObscureContentForRestrictedUser returns false with full access")
    func fullAccessIsNeverObscured() {
        cleanupFirstFreeKeys()
        defer { cleanupFirstFreeKeys() }

        let day = Date(timeIntervalSince1970: 1_800_000_000 + 86400)
        DailyFitRevealPersistence.markFirstDailyFitRevealed(
            for: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let result = DailyFitRevealPersistence.shouldObscureContentForRestrictedUser(
            isCardRevealed: true, displayDate: day, hasFullAccess: true
        )
        #expect(result == false)
    }

    @Test("Migration backfills earliest CardRevealed key")
    func migrationBackfillsEarliestDate() {
        cleanupFirstFreeKeys()
        defer {
            cleanupFirstFreeKeys()
            UserDefaults.standard.removeObject(forKey: "CardRevealed_2026-06-20")
            UserDefaults.standard.removeObject(forKey: "CardRevealed_2026-06-22")
        }

        UserDefaults.standard.set(true, forKey: "CardRevealed_2026-06-22")
        UserDefaults.standard.set(true, forKey: "CardRevealed_2026-06-20")

        let date = DailyFitRevealPersistence.firstFreeRevealDate
        #expect(date == "2026-06-20")
    }

    @Test("removeAll clears firstFreeRevealDate")
    func removeAllClearsFirstFree() throws {
        cleanupFirstFreeKeys()
        defer { cleanupFirstFreeKeys() }

        let (storage, dir) = try makeTempStorage()
        defer { cleanup(dir) }

        DailyFitRevealPersistence.markFirstDailyFitRevealed(
            for: Date(timeIntervalSince1970: 1_800_000_000)
        )
        #expect(DailyFitRevealPersistence.firstFreeRevealDate != nil)

        storage.removeAll()
        #expect(UserDefaults.standard.string(forKey: Self.firstFreeKey) == nil)
    }
}
