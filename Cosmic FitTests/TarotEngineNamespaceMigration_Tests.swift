//
//  TarotEngineNamespaceMigration_Tests.swift
//  Cosmic FitTests
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite(.serialized)
struct TarotEngineNamespaceMigration_Tests {

    private static let profileHash = "migrate_test_profile"
    private static let cardName = "The Fool"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    @Test("Legacy recency keys copy into production namespace")
    func migratesLegacyRecencyToProduction() {
        let defaults = UserDefaults(suiteName: "TarotEngineNamespaceMigration_Tests.recency")!
        defaults.removePersistentDomain(forName: "TarotEngineNamespaceMigration_Tests.recency")

        let day = "2026-05-18"
        defaults.set("The Moon", forKey: "tarot.recency.\(Self.profileHash).\(day)")
        defaults.set([day], forKey: "tarot.recency.dates.\(Self.profileHash)")

        TarotEngineNamespaceMigration.migrateProductionRecencyIfNeeded(
            profileHash: Self.profileHash,
            userDefaults: defaults,
            dateFormatter: Self.dateFormatter
        )

        let productionKey = "tarot.recency.production.\(Self.profileHash).\(day)"
        #expect(defaults.string(forKey: productionKey) == "The Moon")
        #expect(
            defaults.stringArray(forKey: "tarot.recency.dates.production.\(Self.profileHash)") == [day]
        )

        let tracker = TarotRecencyTracker(userDefaults: defaults)
        let recent = tracker.getRecentSelections(
            profileHash: Self.profileHash,
            referenceDate: Self.dateFormatter.date(from: "2026-05-20")!,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        #expect(recent.contains { $0.cardName == "The Moon" })
    }

    @Test("Legacy variant rotation copies into production namespace")
    func migratesLegacyVariantRotationToProduction() {
        let defaults = UserDefaults(suiteName: "TarotEngineNamespaceMigration_Tests.variant")!
        defaults.removePersistentDomain(forName: "TarotEngineNamespaceMigration_Tests.variant")

        let legacyKey = "variantRotation_\(Self.profileHash)_\(Self.cardName)"
        defaults.set(1, forKey: legacyKey)

        TarotEngineNamespaceMigration.migrateProductionVariantRotationIfNeeded(
            profileHash: Self.profileHash,
            userDefaults: defaults
        )

        let productionKey = "variantRotation_production_\(Self.profileHash)_\(Self.cardName)"
        #expect(defaults.integer(forKey: productionKey) == 1)

        let tracker = TarotVariantRotationTracker(defaults: defaults)
        #expect(tracker.peekNextVariantIndex(
            forCard: Self.cardName,
            profileHash: Self.profileHash,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        ) == 2)
    }

    @Test("Migration runs once per profile")
    func migrationIsIdempotent() {
        let defaults = UserDefaults(suiteName: "TarotEngineNamespaceMigration_Tests.idempotent")!
        defaults.removePersistentDomain(forName: "TarotEngineNamespaceMigration_Tests.idempotent")

        let day = "2026-05-17"
        defaults.set("The Star", forKey: "tarot.recency.\(Self.profileHash).\(day)")

        TarotEngineNamespaceMigration.migrateProductionRecencyIfNeeded(
            profileHash: Self.profileHash,
            userDefaults: defaults,
            dateFormatter: Self.dateFormatter
        )

        defaults.set("Overwritten", forKey: "tarot.recency.\(Self.profileHash).\(day)")

        TarotEngineNamespaceMigration.migrateProductionRecencyIfNeeded(
            profileHash: Self.profileHash,
            userDefaults: defaults,
            dateFormatter: Self.dateFormatter
        )

        let productionKey = "tarot.recency.production.\(Self.profileHash).\(day)"
        #expect(defaults.string(forKey: productionKey) == "The Star")
    }

    @Test("Non-production engine id does not trigger migration hook")
    func skipsMigrationForExperimentalEngine() {
        let defaults = UserDefaults(suiteName: "TarotEngineNamespaceMigration_Tests.skip")!
        defaults.removePersistentDomain(forName: "TarotEngineNamespaceMigration_Tests.skip")

        let day = "2026-05-16"
        defaults.set("The Sun", forKey: "tarot.recency.\(Self.profileHash).\(day)")

        let tracker = TarotRecencyTracker(userDefaults: defaults)
        let recent = tracker.getRecentSelections(
            profileHash: Self.profileHash,
            referenceDate: Self.dateFormatter.date(from: "2026-05-20")!,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )

        #expect(recent.isEmpty)
        #expect(defaults.string(forKey: "tarot.recency.production.\(Self.profileHash).\(day)") == nil)
    }
}
