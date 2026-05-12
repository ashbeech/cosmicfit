//
//  TarotCalibrationTestSupport.swift
//  Cosmic FitTests
//
//  Phase 0E: Shared helpers for tarot tracker isolation in calibration sweeps.
//  - Isolated UserDefaults per test run
//  - Tracker reset helpers
//  - Profile hash uniqueness assertion
//  - Fixed UTC timezone for date-keyed recency
//

import Foundation
import Testing
@testable import Cosmic_Fit

enum TarotCalibrationTestSupport {

    // MARK: - Isolated Tracker Setup

    /// Create a fresh pair of tarot trackers backed by an isolated UserDefaults suite.
    /// Assigns them to the `.shared` singletons so production code picks them up.
    /// Returns the suite name for diagnostics.
    @discardableResult
    static func installIsolatedTrackers() -> String {
        let suiteName = "com.cosmicfit.calibration.\(UUID().uuidString)"
        let isolated = UserDefaults(suiteName: suiteName)!
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: isolated)
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: isolated)
        return suiteName
    }

    /// Reset both trackers and BlueprintLensEngine card cache.
    /// Call at the start of each profile's multi-day sweep.
    static func resetTrackersForProfile() {
        TarotRecencyTracker.shared.resetAllForTesting()
        TarotVariantRotationTracker.shared.resetAll()
        BlueprintLensEngine._resetCardCache()
    }

    // MARK: - Profile Hash Uniqueness

    /// Assert that all profile hashes in the given array are distinct.
    static func assertUniqueHashes(_ profiles: [(name: String, hash: String)]) {
        var seen = [String: String]()
        for p in profiles {
            if let existing = seen[p.hash] {
                Issue.record("Duplicate profileHash '\(p.hash)' shared by '\(existing)' and '\(p.name)'")
            }
            seen[p.hash] = p.name
        }
    }

    // MARK: - Fixed-Timezone Date Helper

    /// Build a date string in yyyy-MM-dd format using UTC, matching the format
    /// expected by TarotRecencyTracker when timezone is pinned.
    static func utcDateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }
}
