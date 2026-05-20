import XCTest
@testable import CosmicFitInspectorLib

final class TarotEngineNamespaceTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.tarot.namespace.\(UUID().uuidString)")!
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: defaults)
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: defaults)
    }

    override func tearDown() {
        TarotRecencyTracker.shared.resetAllForTesting()
        TarotVariantRotationTracker.shared.resetAll()
        super.tearDown()
    }

    func testRecencyHistoryIsolatedPerEngine() {
        let profile = "namespaceTestProfile"
        let date = Date()
        let tracker = TarotRecencyTracker.shared

        tracker.storeCardSelection(
            "The Fool",
            profileHash: profile,
            date: date,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        tracker.storeCardSelection(
            "The Magician",
            profileHash: profile,
            date: date,
            dailyFitEngineId: DailyFitEngineRegistry.legacyBaselineId
        )

        let productionHistory = tracker.getRecentSelections(
            profileHash: profile,
            referenceDate: date,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        let legacyHistory = tracker.getRecentSelections(
            profileHash: profile,
            referenceDate: date,
            dailyFitEngineId: DailyFitEngineRegistry.legacyBaselineId
        )

        XCTAssertEqual(productionHistory.first?.cardName, "The Fool")
        XCTAssertEqual(legacyHistory.first?.cardName, "The Magician")
    }

    func testVariantRotationIsolatedPerEngine() {
        let profile = "namespaceTestProfile"
        let card = "The Star"
        let rotation = TarotVariantRotationTracker.shared

        let productionFirst = rotation.nextVariantIndex(
            forCard: card,
            profileHash: profile,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        let legacyFirst = rotation.nextVariantIndex(
            forCard: card,
            profileHash: profile,
            dailyFitEngineId: DailyFitEngineRegistry.legacyBaselineId
        )

        XCTAssertEqual(productionFirst, 0)
        XCTAssertEqual(legacyFirst, 0)

        let productionSecond = rotation.nextVariantIndex(
            forCard: card,
            profileHash: profile,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        let legacySecond = rotation.nextVariantIndex(
            forCard: card,
            profileHash: profile,
            dailyFitEngineId: DailyFitEngineRegistry.legacyBaselineId
        )

        XCTAssertEqual(productionSecond, 1)
        XCTAssertEqual(legacySecond, 1)
    }
}
