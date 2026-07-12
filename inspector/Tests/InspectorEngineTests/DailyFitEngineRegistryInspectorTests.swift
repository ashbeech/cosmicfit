import XCTest
@testable import CosmicFitInspectorLib

final class DailyFitEngineRegistryInspectorTests: XCTestCase {

    func testRegistryListsProductionAndLegacyBaseline() {
        let ids = Set(DailyFitEngineRegistry.allDescriptors.map(\.id))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.productionId))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.legacyBaselineId))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.stage1ExperimentalId))
        XCTAssertTrue(ids.contains(DailyFitEngineRegistry.stage2LegacyId))
        XCTAssertEqual(DailyFitEngineRegistry.allDescriptors.count, 4)
    }

    func testUnknownEngineIdFallsBackToProductionCalibration() {
        let calibration = DailyFitEngineRegistry.calibration(for: "not_a_real_engine")
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        XCTAssertEqual(calibration, production.calibration)
    }

    func testStage1ExperimentalDescriptorUsesExperimentalMode() {
        let descriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
        XCTAssertEqual(descriptor.mode, .stage1Experimental)
        XCTAssertEqual(descriptor.dailySeedPolicy, .includesEngineId)
        let stage1Calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )
        XCTAssertNotEqual(stage1Calibration, DailyFitCalibration.default)
        XCTAssertEqual(stage1Calibration.axisTuning.sigmoidSpread, 0.8)
        XCTAssertEqual(
            stage1Calibration.stage2Sensitivity.paletteSelectionStrategy,
            .pureSkyScoring
        )
    }

    func testStage2LegacyFingerprintDiffersFromSkyForwardProduction() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let stage2Legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage2LegacyId)!
        XCTAssertNotEqual(stage2Legacy.fingerprint, production.fingerprint)
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
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.legacyBaselineId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )

        let response = try await engine.resolve(request: request)
        let descriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.legacyBaselineId)!

        XCTAssertEqual(response.meta.dailyFitEngineId, DailyFitEngineRegistry.legacyBaselineId)
        XCTAssertEqual(response.meta.dailyFitEngineDisplayName, descriptor.displayName)
        XCTAssertEqual(response.meta.dailyFitEngineFingerprint, descriptor.fingerprint)
    }

    func testInspectResponseIncludesBlueprintDiagnostics() async throws {
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
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.productionId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )

        let response = try await engine.resolve(request: request)

        XCTAssertNotNil(response.blueprintDiagnostics)
        XCTAssertNotNil(response.blueprintDiagnostics?.familyDecisionTrace.family)
        XCTAssertNotNil(response.blueprintDiagnostics?.familyDecisionTrace.cluster)
        XCTAssertFalse(
            response.blueprintDiagnostics?.familyDecisionTrace.normalizedDrivers.drivers.isEmpty ?? true
        )
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
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: nil,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )

        let response = try await engine.resolve(request: request)
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!

        XCTAssertEqual(response.meta.dailyFitEngineId, DailyFitEngineRegistry.productionId)
        XCTAssertEqual(response.meta.dailyFitEngineDisplayName, production.displayName)
        XCTAssertEqual(response.meta.dailyFitEngineFingerprint, production.fingerprint)
    }

    func testInspectResponseIncludesStage1Attribution() async throws {
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
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.productionId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )

        let response = try await engine.resolve(request: request)
        let attribution = response.dailyFit.diagnostics.stage1Attribution
        XCTAssertNotNil(attribution, "stage1Attribution must be populated")
        XCTAssertEqual(attribution?.byEnergy.count, 6, "Should have one breakdown per energy")
        XCTAssertEqual(attribution?.engineMode, "standard")
        XCTAssertEqual(attribution?.signMultipliersAppliedToDailyVibe, true)
        let hasNonNeutralMultiplier = attribution?.signMultiplierApplied.values.contains { $0 != 1.0 } ?? false
        XCTAssertTrue(hasNonNeutralMultiplier, "Production daily path should apply non-neutral sign multipliers")

        for breakdown in attribution?.byEnergy ?? [] {
            XCTAssertFalse(breakdown.entries.isEmpty, "Energy \(breakdown.energy) should have attribution entries")
            XCTAssertGreaterThan(breakdown.totalRaw, 0, "Energy \(breakdown.energy) should have positive total")
        }
    }

    func testSkyForwardAttributionDiffersFromStage2Legacy() async throws {
        let engine = InspectorEngine()
        try await engine.bootstrap()

        let presets = PresetCatalog.loadPresets()
        try XCTSkipIf(presets.isEmpty, "presets.json required for inspect integration test")

        let preset = presets[0]

        let prodRequest = InspectorRequest(
            preset: preset.id,
            birth: preset.birthInput,
            targetDate: "2026-05-10",
            options: InspectOptions(
                composeBlueprint: true,
                includeProgressed: true,
                profileId: nil,
                resetTarotHistory: true,
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.productionId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )
        let prodResponse = try await engine.resolve(request: prodRequest)

        let stage2Request = InspectorRequest(
            preset: preset.id,
            birth: preset.birthInput,
            targetDate: "2026-05-10",
            options: InspectOptions(
                composeBlueprint: true,
                includeProgressed: true,
                profileId: nil,
                resetTarotHistory: true,
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.stage2LegacyId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )
        let stage2Response = try await engine.resolve(request: stage2Request)

        let prodAttr = prodResponse.dailyFit.diagnostics.stage1Attribution
        let stage2Attr = stage2Response.dailyFit.diagnostics.stage1Attribution
        XCTAssertNotNil(prodAttr)
        XCTAssertNotNil(stage2Attr)
        XCTAssertEqual(prodAttr?.engineMode, "stage1Experimental")
        XCTAssertEqual(stage2Attr?.engineMode, "standard")
        XCTAssertNotEqual(prodAttr, stage2Attr, "Sky Forward and Stage 2 legacy should produce different attribution")
    }

    func testStage1AttributionSkipsDailySignMultipliers() async throws {
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
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )

        let response = try await engine.resolve(request: request)
        let attribution = response.dailyFit.diagnostics.stage1Attribution
        let diagnostics = response.dailyFit.diagnostics

        XCTAssertNotNil(attribution)
        XCTAssertEqual(attribution?.engineMode, "stage1Experimental")
        XCTAssertEqual(attribution?.signMultipliersAppliedToDailyVibe, false)
        XCTAssertEqual(diagnostics.postMultiplierScores, diagnostics.rawEnergyScores)
        for value in attribution?.signMultiplierApplied.values ?? Dictionary<String, Double>().values {
            XCTAssertEqual(value, 1.0, accuracy: 0.0001)
        }
        XCTAssertEqual(
            diagnostics.calibrationSnapshot.signMultiplierPolicy["applyToDailyVibe"],
            false
        )
        XCTAssertEqual(
            diagnostics.calibrationSnapshot.signMultiplierPolicy["applyToChartAnchor"],
            true
        )
        let chartMults = attribution?.chartAnchorSignMultiplierApplied ?? [:]
        XCTAssertEqual(chartMults["drama"] ?? 0, 1.35, accuracy: 0.0001)
    }

    func testInspectResponseIncludesStage1AxisAttribution() async throws {
        let engine = InspectorEngine()
        try await engine.bootstrap()

        let presets = PresetCatalog.loadPresets()
        try XCTSkipIf(presets.isEmpty, "presets.json required for inspect integration test")

        let preset = presets[0]
        let request = InspectorRequest(
            preset: preset.id,
            birth: preset.birthInput,
            targetDate: "2026-05-22",
            options: InspectOptions(
                composeBlueprint: true,
                includeProgressed: true,
                profileId: nil,
                resetTarotHistory: true,
                resetEssenceRecencyHistory: nil,
                dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId,
                deviceLatitude: nil,
                deviceLongitude: nil
            )
        )

        let response = try await engine.resolve(request: request)
        let axisAttr = response.dailyFit.diagnostics.stage1AxisAttribution
        XCTAssertNotNil(axisAttr, "stage1AxisAttribution must be populated")
        XCTAssertEqual(axisAttr?.engineMode, "stage1Experimental")
        XCTAssertEqual(axisAttr?.byAxis.count, 4, "Should have one breakdown per axis")

        let visibility = axisAttr?.byAxis.first { $0.axis == "visibility" }
        XCTAssertNotNil(visibility)
        XCTAssertFalse(visibility?.entries.isEmpty ?? true, "Visibility axis should have transit contributors")
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
