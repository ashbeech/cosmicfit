import XCTest
@testable import CosmicFitInspectorLib

final class DailyFitEngineRegistryInspectorTests: XCTestCase {

    func testRegistryListsProductionAndLegacyBaseline() {
        let ids = Set(DailyFitEngineRegistry.allDescriptors.map(\.id))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.productionId))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.legacyBaselineId))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.stage1ExperimentalId))
        XCTAssertEqual(DailyFitEngineRegistry.allDescriptors.count, 3)
    }

    func testUnknownEngineIdFallsBackToProductionCalibration() {
        let calibration = DailyFitEngineRegistry.calibration(for: "not_a_real_engine")
        XCTAssertEqual(calibration, DailyFitCalibration.default)
    }

    func testStage1ExperimentalDescriptorUsesExperimentalMode() {
        let descriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
        XCTAssertEqual(descriptor.mode, .stage1Experimental)
        XCTAssertEqual(descriptor.dailySeedPolicy, .includesEngineId)
        let stage1Calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )
        XCTAssertNotEqual(stage1Calibration, DailyFitCalibration.default)
        XCTAssertGreaterThan(
            stage1Calibration.sourceWeights.transits,
            DailyFitCalibration.default.sourceWeights.transits
        )
    }

    func testStage1ExperimentalFingerprintDiffersFromProduction() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let stage1 = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
        XCTAssertNotEqual(stage1.fingerprint, production.fingerprint)
    }

    func testProductionAndLegacyFingerprintsDiffer() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.legacyBaselineId)!
        XCTAssertNotEqual(production.fingerprint, legacy.fingerprint)
    }

    func testInspectResponseMetaIncludesDailyFitEngineFields() async throws {
        let engine = InspectorEngine()
        try await engine.bootstrap()

        let presets = PresetCatalog.loadPresets()
        try XCTSkipIf(presets.isEmpty, "presets.json required for inspect integration test")

        let preset = presets[0]
        let request = InspectorRequest(
            preset: preset.id,
            birth: preset.birthInput,
            targetDate: "2026-05-10",
            options: InspectOptions(
                composeBlueprint: true,
                includeProgressed: true,
                profileId: nil,
                resetTarotHistory: true,
                dailyFitEngineId: DailyFitEngineRegistry.legacyBaselineId
            )
        )

        let response = try await engine.resolve(request: request)
        let descriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.legacyBaselineId)!

        XCTAssertEqual(response.meta.dailyFitEngineId, DailyFitEngineRegistry.legacyBaselineId)
        XCTAssertEqual(response.meta.dailyFitEngineDisplayName, descriptor.displayName)
        XCTAssertEqual(response.meta.dailyFitEngineFingerprint, descriptor.fingerprint)
    }

    func testInspectOmitsEngineIdUsesProduction() async throws {
        let engine = InspectorEngine()
        try await engine.bootstrap()

        let presets = PresetCatalog.loadPresets()
        try XCTSkipIf(presets.isEmpty, "presets.json required for inspect integration test")

        let preset = presets[0]
        let request = InspectorRequest(
            preset: preset.id,
            birth: preset.birthInput,
            targetDate: "2026-05-10",
            options: InspectOptions(
                composeBlueprint: true,
                includeProgressed: true,
                profileId: nil,
                resetTarotHistory: true,
                dailyFitEngineId: nil
            )
        )

        let response = try await engine.resolve(request: request)
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!

        XCTAssertEqual(response.meta.dailyFitEngineId, DailyFitEngineRegistry.productionId)
        XCTAssertEqual(response.meta.dailyFitEngineDisplayName, production.displayName)
        XCTAssertEqual(response.meta.dailyFitEngineFingerprint, production.fingerprint)
    }
}

final class CompareCacheKeyTests: XCTestCase {

    /// Documents the compare cache key contract exercised by inspector Web/app.js (§11).
    func testCompareCacheKeyFormat() {
        let key = "legacy_baseline:2026-05-10"
        XCTAssertTrue(key.contains(":"))
        XCTAssertTrue(key.hasPrefix("legacy_baseline:"))
        XCTAssertFalse("2026-05-10".contains(":"))
    }
}
