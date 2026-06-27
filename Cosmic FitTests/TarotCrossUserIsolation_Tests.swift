import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Tarot Tracker Cross-User Isolation Tests

struct TarotCrossUserIsolation_Tests {

    private static func isolatedDefaults() -> UserDefaults {
        let suite = "com.cosmicfit.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    // MARK: - TarotRecencyTracker isolation

    @Test("Tarot recency: different profileHash produces independent cooldown lists")
    func tarotRecencyProfileIsolation() {
        let defaults = Self.isolatedDefaults()
        let tracker = TarotRecencyTracker(userDefaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let engineId = "test-engine"
        let today = Date()

        tracker.storeSelection(
            cardName: "The Tower",
            profileHash: profileA,
            date: today,
            dailyFitEngineId: engineId
        )

        let cooldownA = tracker.getCooldownCards(
            profileHash: profileA, referenceDate: today, dailyFitEngineId: engineId
        )
        let cooldownB = tracker.getCooldownCards(
            profileHash: profileB, referenceDate: today, dailyFitEngineId: engineId
        )

        #expect(cooldownA.contains("The Tower"),
                "Profile A should have 'The Tower' in cooldown")
        #expect(!cooldownB.contains("The Tower"),
                "Profile B must NOT see Profile A's cooldown cards")
    }

    // MARK: - TarotVariantRotationTracker isolation

    @Test("Variant rotation: different profileHash produces independent rotation indexes")
    func variantRotationProfileIsolation() {
        let defaults = Self.isolatedDefaults()
        let tracker = TarotVariantRotationTracker(defaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let engineId = "test-engine"

        let idxA1 = tracker.nextVariantIndex(forCard: "The Star", profileHash: profileA, dailyFitEngineId: engineId)
        let idxA2 = tracker.nextVariantIndex(forCard: "The Star", profileHash: profileA, dailyFitEngineId: engineId)

        let idxB1 = tracker.nextVariantIndex(forCard: "The Star", profileHash: profileB, dailyFitEngineId: engineId)

        #expect(idxA1 == 0, "First call for Profile A should be variant 0")
        #expect(idxA2 == 1, "Second call for Profile A should advance to variant 1")
        #expect(idxB1 == 0, "First call for Profile B should start fresh at variant 0")
    }

    // MARK: - VisibleEssenceRecencyTracker isolation

    @Test("Visible essence recency: different profileHash is independent")
    func visibleEssenceProfileIsolation() {
        let defaults = Self.isolatedDefaults()
        let tracker = VisibleEssenceRecencyTracker(defaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let engineId = "test-engine"
        let today = Date()

        tracker.storeVisibleTop3(
            [.dramatic, .romantic, .natural],
            profileHash: profileA,
            date: today,
            dailyFitEngineId: engineId
        )

        let recentA = tracker.getRecentVisibleEssences(
            profileHash: profileA, referenceDate: today, dailyFitEngineId: engineId
        )
        let recentB = tracker.getRecentVisibleEssences(
            profileHash: profileB, referenceDate: today, dailyFitEngineId: engineId
        )

        #expect(!recentA.isEmpty, "Profile A should have visible essence history")
        #expect(recentB.isEmpty, "Profile B must not see Profile A's visible essences")
    }

    // MARK: - AccentRecencyTracker isolation

    @Test("Accent recency: different profileHash is independent")
    func accentRecencyProfileIsolation() {
        let defaults = Self.isolatedDefaults()
        let tracker = AccentRecencyTracker(defaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let today = Date()

        tracker.storeAccent(.dramatic, profileHash: profileA, date: today)

        let recentA = tracker.getRecentAccents(profileHash: profileA, referenceDate: today)
        let recentB = tracker.getRecentAccents(profileHash: profileB, referenceDate: today)

        #expect(!recentA.isEmpty, "Profile A should have accent history")
        #expect(recentB.isEmpty, "Profile B must not see Profile A's accent history")
    }

    // MARK: - ColourRecencyTracker isolation

    @Test("Colour recency: different profileHash is independent")
    func colourRecencyProfileIsolation() {
        let defaults = Self.isolatedDefaults()
        let tracker = ColourRecencyTracker(defaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let engineId = "test-engine"
        let today = Date()

        tracker.storeDailyColours(
            shownHexes: ["#FF0000", "#00FF00"],
            heroHex: "#FF0000",
            profileHash: profileA,
            date: today,
            dailyFitEngineId: engineId
        )

        let historyA = tracker.getDailyColourHistory(
            profileHash: profileA, referenceDate: today, dailyFitEngineId: engineId
        )
        let historyB = tracker.getDailyColourHistory(
            profileHash: profileB, referenceDate: today, dailyFitEngineId: engineId
        )

        #expect(!historyA.isEmpty, "Profile A should have colour history")
        #expect(historyB.isEmpty, "Profile B must not see Profile A's colour history")
    }

    // MARK: - clearProfile removes only the targeted profile

    @Test("TarotVariantRotationTracker.clearProfile removes only the targeted profile")
    func variantRotationClearProfile() {
        let defaults = Self.isolatedDefaults()
        let tracker = TarotVariantRotationTracker(defaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let engineId = "test-engine"

        _ = tracker.nextVariantIndex(forCard: "The Star", profileHash: profileA, dailyFitEngineId: engineId)
        _ = tracker.nextVariantIndex(forCard: "The Star", profileHash: profileA, dailyFitEngineId: engineId)
        _ = tracker.nextVariantIndex(forCard: "The Star", profileHash: profileB, dailyFitEngineId: engineId)

        tracker.clearProfile(profileHash: profileA, dailyFitEngineId: engineId)

        let nextA = tracker.peekNextVariantIndex(forCard: "The Star", profileHash: profileA, dailyFitEngineId: engineId)
        let nextB = tracker.peekNextVariantIndex(forCard: "The Star", profileHash: profileB, dailyFitEngineId: engineId)

        #expect(nextA == 0, "Profile A should reset to variant 0 after clearProfile")
        #expect(nextB == 1, "Profile B should be unaffected by clearing Profile A")
    }

    @Test("AccentRecencyTracker.clearProfile removes only the targeted profile")
    func accentRecencyClearProfile() {
        let defaults = Self.isolatedDefaults()
        let tracker = AccentRecencyTracker(defaults: defaults)

        let profileA = UUID().uuidString
        let profileB = UUID().uuidString
        let today = Date()

        tracker.storeAccent(.dramatic, profileHash: profileA, date: today)
        tracker.storeAccent(.classic, profileHash: profileB, date: today)

        tracker.clearProfile(profileHash: profileA)

        let recentA = tracker.getRecentAccents(profileHash: profileA, referenceDate: today)
        let recentB = tracker.getRecentAccents(profileHash: profileB, referenceDate: today)

        #expect(recentA.isEmpty, "Profile A history should be gone after clearProfile")
        #expect(!recentB.isEmpty, "Profile B history should be unaffected")
    }

    // MARK: - Fallback collision prevention (item K)

    @Test("Fallback profileHash uses ClientInstallIdentity.id, not birth-derived chartId")
    func fallbackUsesDeviceUUID() {
        let installId = ClientInstallIdentity.id
        #expect(!installId.isEmpty)

        let uuidPattern = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/
        #expect(installId.wholeMatch(of: uuidPattern) != nil,
                "ClientInstallIdentity.id should be a valid UUID, got: \(installId)")
    }
}
