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
    func nextVariantIndex(forCard cardName: String, profileHash: String) -> Int {
        let key = storageKey(cardName: cardName, profileHash: profileHash)
        let current = defaults.object(forKey: key) as? Int ?? -1
        let next = (current + 1) % 3
        defaults.set(next, forKey: key)
        return next
    }

    /// Peek at the next index without advancing. Useful for tests.
    func peekNextVariantIndex(forCard cardName: String, profileHash: String) -> Int {
        let key = storageKey(cardName: cardName, profileHash: profileHash)
        let current = defaults.object(forKey: key) as? Int ?? -1
        return (current + 1) % 3
    }

    /// Reset all rotation state.
    func resetAll() {
        let prefix = "variantRotation_"
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func storageKey(cardName: String, profileHash: String) -> String {
        "variantRotation_\(profileHash)_\(cardName)"
    }
}
