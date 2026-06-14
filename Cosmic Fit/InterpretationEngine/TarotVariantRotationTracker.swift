//
//  TarotVariantRotationTracker.swift
//  Cosmic Fit
//
//  Phase 3: Tracks variant rotation per card per user.
//  Cycles through 3 variants (I, II, III) sequentially.
//

import Foundation

/// Tracks which style-edit variant index was last shown for each card,
/// per user profile. Backed by UserDefaults.
final class TarotVariantRotationTracker {
    static var shared = TarotVariantRotationTracker()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Returns the next variant index (0, 1, or 2) for the given card and
    /// user profile, then advances the stored rotation.
    func nextVariantIndex(
        forCard cardName: String,
        profileHash: String,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) -> Int {
        migrateLegacyNamespaceIfNeeded(profileHash: profileHash, dailyFitEngineId: dailyFitEngineId)

        let key = storageKey(cardName: cardName, profileHash: profileHash, dailyFitEngineId: dailyFitEngineId)
        let current = defaults.object(forKey: key) as? Int ?? -1
        let next = (current + 1) % 3
        defaults.set(next, forKey: key)
        return next
    }

    /// Peek at the next index without advancing. Useful for tests.
    func peekNextVariantIndex(
        forCard cardName: String,
        profileHash: String,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) -> Int {
        migrateLegacyNamespaceIfNeeded(profileHash: profileHash, dailyFitEngineId: dailyFitEngineId)

        let key = storageKey(cardName: cardName, profileHash: profileHash, dailyFitEngineId: dailyFitEngineId)
        let current = defaults.object(forKey: key) as? Int ?? -1
        return (current + 1) % 3
    }

    // MARK: - Bridge-path variant recency (P0 production readiness)

    /// Returns the variant index last shown for this card, or nil if never shown.
    func lastShownVariantIndex(
        forCard cardName: String,
        profileHash: String,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) -> Int? {
        let key = lastShownKey(cardName: cardName, profileHash: profileHash, dailyFitEngineId: dailyFitEngineId)
        return defaults.object(forKey: key) as? Int
    }

    /// Build a lookup of last-shown variant index for every card in `recentSelections`.
    func lastShownVariantMap(
        recentSelections: [(cardName: String, daysAgo: Int)],
        profileHash: String,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) -> [String: Int] {
        var map: [String: Int] = [:]
        for entry in recentSelections {
            guard map[entry.cardName] == nil else { continue }
            if let idx = lastShownVariantIndex(
                forCard: entry.cardName,
                profileHash: profileHash,
                dailyFitEngineId: dailyFitEngineId
            ) {
                map[entry.cardName] = idx
            }
        }
        return map
    }

    /// Build last-shown variant map for cards in today's eligible pool.
    /// Used by bridge-path variant recency swap when a card returns after the
    /// 10-day recency window (recentSelections will not contain it).
    func lastShownVariantMapForEligibleCards(
        eligibleCardNames: [String],
        profileHash: String,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) -> [String: Int] {
        var map: [String: Int] = [:]
        for cardName in eligibleCardNames {
            if let idx = lastShownVariantIndex(
                forCard: cardName,
                profileHash: profileHash,
                dailyFitEngineId: dailyFitEngineId
            ) {
                map[cardName] = idx
            }
        }
        return map
    }

    /// Record which variant was shown for a card (bridge-path counterpart of rotation advance).
    func recordVariantShown(
        _ variantIndex: Int,
        forCard cardName: String,
        profileHash: String,
        dailyFitEngineId: String = DailyFitEngineRegistry.productionId
    ) {
        let key = lastShownKey(cardName: cardName, profileHash: profileHash, dailyFitEngineId: dailyFitEngineId)
        defaults.set(variantIndex, forKey: key)
    }

    // MARK: - Reset

    /// Reset all rotation state.
    func resetAll() {
        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix("variantRotation_") || key.hasPrefix("lastVariantShown_")
        {
            defaults.removeObject(forKey: key)
        }
    }

    private func storageKey(cardName: String, profileHash: String, dailyFitEngineId: String) -> String {
        "variantRotation_\(dailyFitEngineId)_\(profileHash)_\(cardName)"
    }

    private func lastShownKey(cardName: String, profileHash: String, dailyFitEngineId: String) -> String {
        "lastVariantShown_\(dailyFitEngineId)_\(profileHash)_\(cardName)"
    }

    private func migrateLegacyNamespaceIfNeeded(profileHash: String, dailyFitEngineId: String) {
        guard dailyFitEngineId == DailyFitEngineRegistry.productionId else { return }
        TarotEngineNamespaceMigration.migrateProductionVariantRotationIfNeeded(
            profileHash: profileHash,
            userDefaults: defaults
        )
    }
}
