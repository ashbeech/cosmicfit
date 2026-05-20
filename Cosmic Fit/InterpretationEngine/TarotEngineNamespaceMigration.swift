//
//  TarotEngineNamespaceMigration.swift
//  Cosmic Fit
//
//  One-time migration from pre–engine-versioning UserDefaults keys to
//  production-namespaced keys. Safe to ship in a follow-up PR after
//  `engine-versioning` merges (see file header in integration note below).
//

import Foundation

/// Copies legacy tarot recency / variant-rotation state into `production`-namespaced keys.
enum TarotEngineNamespaceMigration {

    private static let recencyPrefix = "tarot.recency"
    private static let variantPrefix = "variantRotation_"
    private static let recencyMigrationFlagPrefix = "tarot.namespaceMigration.production.recency"
    private static let variantMigrationFlagPrefix = "tarot.namespaceMigration.production.variant"

    private static let knownEngineIds: Set<String> = Set(
        DailyFitEngineRegistry.allDescriptors.map(\.id)
    )

    // MARK: - Recency

    /// Call before reading production recency for a profile (lazy, once per profile).
    static func migrateProductionRecencyIfNeeded(
        profileHash: String,
        userDefaults: UserDefaults,
        dateFormatter: DateFormatter
    ) {
        guard !isRecencyMigrated(profileHash: profileHash, userDefaults: userDefaults) else { return }

        let legacyDateListKey = "\(recencyPrefix).dates.\(profileHash)"
        let newDateListKey = "\(recencyPrefix).dates.\(DailyFitEngineRegistry.productionId).\(profileHash)"

        var dateStrings = userDefaults.stringArray(forKey: legacyDateListKey) ?? []

        if dateStrings.isEmpty {
            dateStrings = legacyRecencyDateStrings(
                profileHash: profileHash,
                userDefaults: userDefaults
            )
        }

        var migratedCount = 0
        for dateString in dateStrings {
            let legacyCardKey = "\(recencyPrefix).\(profileHash).\(dateString)"
            let newCardKey = "\(recencyPrefix).\(DailyFitEngineRegistry.productionId).\(profileHash).\(dateString)"

            guard let cardName = userDefaults.string(forKey: legacyCardKey),
                  userDefaults.string(forKey: newCardKey) == nil else {
                continue
            }

            userDefaults.set(cardName, forKey: newCardKey)
            migratedCount += 1
        }

        if !dateStrings.isEmpty,
           userDefaults.stringArray(forKey: newDateListKey) == nil {
            userDefaults.set(dateStrings, forKey: newDateListKey)
        }

        markRecencyMigrated(profileHash: profileHash, userDefaults: userDefaults)

        #if DEBUG
        if migratedCount > 0 {
            print("[TarotEngineNamespaceMigration] Migrated \(migratedCount) recency card(s) for profile \(profileHash)")
        }
        #endif
    }

    // MARK: - Variant rotation

    /// Call before reading production variant index for a card (lazy, once per profile).
    static func migrateProductionVariantRotationIfNeeded(
        profileHash: String,
        userDefaults: UserDefaults
    ) {
        guard !isVariantMigrated(profileHash: profileHash, userDefaults: userDefaults) else { return }

        let legacyPrefix = "\(variantPrefix)\(profileHash)_"
        let newPrefix = "\(variantPrefix)\(DailyFitEngineRegistry.productionId)_\(profileHash)_"

        var migratedCount = 0
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(legacyPrefix) {
            let suffix = String(key.dropFirst(legacyPrefix.count))
            guard !suffix.isEmpty else { continue }

            let newKey = newPrefix + suffix
            guard userDefaults.object(forKey: newKey) == nil,
                  let value = userDefaults.object(forKey: key) else {
                continue
            }

            userDefaults.set(value, forKey: newKey)
            migratedCount += 1
        }

        markVariantMigrated(profileHash: profileHash, userDefaults: userDefaults)

        #if DEBUG
        if migratedCount > 0 {
            print("[TarotEngineNamespaceMigration] Migrated \(migratedCount) variant rotation key(s) for profile \(profileHash)")
        }
        #endif
    }

    // MARK: - Private

    private static func recencyMigrationFlagKey(profileHash: String) -> String {
        "\(recencyMigrationFlagPrefix).\(profileHash)"
    }

    private static func variantMigrationFlagKey(profileHash: String) -> String {
        "\(variantMigrationFlagPrefix).\(profileHash)"
    }

    private static func isRecencyMigrated(profileHash: String, userDefaults: UserDefaults) -> Bool {
        userDefaults.bool(forKey: recencyMigrationFlagKey(profileHash: profileHash))
    }

    private static func isVariantMigrated(profileHash: String, userDefaults: UserDefaults) -> Bool {
        userDefaults.bool(forKey: variantMigrationFlagKey(profileHash: profileHash))
    }

    private static func markRecencyMigrated(profileHash: String, userDefaults: UserDefaults) {
        userDefaults.set(true, forKey: recencyMigrationFlagKey(profileHash: profileHash))
    }

    private static func markVariantMigrated(profileHash: String, userDefaults: UserDefaults) {
        userDefaults.set(true, forKey: variantMigrationFlagKey(profileHash: profileHash))
    }

    /// Discovers legacy per-day keys when the date list key was never written.
    private static func legacyRecencyDateStrings(
        profileHash: String,
        userDefaults: UserDefaults
    ) -> [String] {
        let cardPrefix = "\(recencyPrefix).\(profileHash)."
        var dates: [String] = []

        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(cardPrefix) {
            let dateString = String(key.dropFirst(cardPrefix.count))
            guard dateString.range(
                of: #"^\d{4}-\d{2}-\d{2}$"#,
                options: .regularExpression
            ) != nil else {
                continue
            }
            dates.append(dateString)
        }

        return dates
    }

    /// True for pre–engine-versioning card keys (`tarot.recency.{profile}.{date}`).
    static func isLegacyRecencyCardKey(_ key: String, profileHash: String) -> Bool {
        let prefix = "\(recencyPrefix).\(profileHash)."
        guard key.hasPrefix(prefix) else { return false }
        let tail = String(key.dropFirst(prefix.count))
        guard tail.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else {
            return false
        }
        return true
    }

    /// True when the segment after `tarot.recency.` is a known engine id (namespaced key).
    static func isNamespacedRecencyKey(_ key: String) -> Bool {
        guard key.hasPrefix("\(recencyPrefix).") else { return false }
        let remainder = String(key.dropFirst(recencyPrefix.count + 1))
        guard let firstSegment = remainder.split(separator: ".").first else { return false }
        return knownEngineIds.contains(String(firstSegment))
    }
}
