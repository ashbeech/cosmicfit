//
//  DailyFitEngineRegistry_Tests.swift
//  Cosmic FitTests
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite
struct DailyFitEngineRegistry_Tests {

    @Test("All registry ids resolve to descriptors")
    func allIdsResolve() {
        for descriptor in DailyFitEngineRegistry.allDescriptors {
            let resolved = DailyFitEngineRegistry.descriptor(for: descriptor.id)
            #expect(resolved == descriptor)
            #expect(DailyFitEngineRegistry.calibration(for: descriptor.id) == descriptor.calibration)
        }
    }

    @Test("Unknown id falls back to production calibration")
    func unknownIdFallsBackToProduction() {
        let calibration = DailyFitEngineRegistry.calibration(for: "not_a_real_engine")
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        #expect(calibration == production.calibration)
    }

    @Test("Production preset is the Sky Forward v1.0.2 sky-fidelity engine")
    func productionUsesSkyFidelityCalibration() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)
        let skyFidelityCalibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.skyForwardV102Id
        )
        #expect(production?.displayName == "Sky Forward")
        // Real literal (was tautological `== productionMarketingVersion`, C3 in the plan).
        #expect(production?.marketingVersion == "1.0.2")
        #expect(production?.calibration == skyFidelityCalibration)
        #expect(production?.mode == .stage2SkyFidelity)
        #expect(production?.fingerprint == PinnedFingerprints.skyForwardV102)
    }

    @Test("Fingerprints are stable and differ between production and legacy_baseline")
    func fingerprintsDiffer() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.legacyBaselineId)!

        #expect(production.fingerprint == DailyFitEngineRegistry.fingerprint(for: production.calibration))
        #expect(legacy.fingerprint == DailyFitEngineRegistry.fingerprint(for: legacy.calibration))
        #expect(production.fingerprint != legacy.fingerprint)
    }

    @Test("stage2_legacy fingerprint differs from Sky Forward production")
    func stage2LegacyFingerprintDiffersFromProduction() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let stage2Legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage2LegacyId)!
        #expect(stage2Legacy.fingerprint != production.fingerprint)
    }

    @Test("stage1_experimental retains the v1.0.1 fingerprint, now distinct from v1.0.2 production")
    func stage1RetainsV101Fingerprint() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let stage1 = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
        // Pre-cutover these matched (production WAS stage1); post-cutover production is v1.0.2, so the
        // stage1_experimental preset preserves the byte-identical v1.0.1 fingerprint but no longer aliases production.
        #expect(stage1.fingerprint == PinnedFingerprints.skyForwardV101)
        #expect(stage1.fingerprint != production.fingerprint)
    }

    @Test("stage1_experimental uses sky-forward calibration, stage1Experimental mode, and S2 seed policy")
    func stage1ExperimentalDescriptor() {
        let descriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
        #expect(descriptor.mode == .stage1Experimental)
        #expect(descriptor.dailySeedPolicy == .includesEngineId)
        #expect(descriptor.calibration != DailyFitCalibration.default)
        #expect(descriptor.calibration.axisTuning.sigmoidSpread == 0.8)
        #expect(descriptor.calibration.stage2Sensitivity.paletteSelectionStrategy == .pureSkyScoring)
        #expect(descriptor.calibration.stage2Sensitivity.paletteJitter
            > DailyFitCalibration.default.stage2Sensitivity.paletteJitter)
        #expect(DailyFitEngineRegistry.mode(for: DailyFitEngineRegistry.stage1ExperimentalId)
            == .stage1Experimental)
    }

    // MARK: - Sky Forward v1.0.2 (Phase 1 + Phase 2)

    /// Pinned pre-change fingerprints. Verified byte-identical against the
    /// `sky-forward-v1.0.1` git tag on 2026-07-15. Promoting the sky mix into the
    /// fingerprinted calibration (Phase 2) MUST NOT change any pre-v1.0.2 preset's
    /// fingerprint — the new fields serialise into `canonicalCalibrationString` ONLY
    /// when non-nil, and every legacy preset leaves them nil. A change here means a
    /// legacy fingerprint drifted → frozen-payload compatibility broke.
    enum PinnedFingerprints {
        static let skyForwardV101 = "9a6aeebeb1f965f32b4e9ff6226adf56d753a465e447f15d760d3979ee0f2a7f"
        static let legacyBaseline = "6c8afc1f3d8a7f4b3ce921a5283b5ec87f907b61c1d4b80a68355b7c48e013a7"
        static let stage2Legacy   = "9110e802e4fdfe84c975ae565c0468070193199b9e406662e73bcd92093ebe47"
        static let skyForwardV102 = "e0e7c597802dfd47be993bf6e3f6d90b0d73f23771d67995326329e89efde1f6"
    }

    @Test("Pre-v1.0.2 preset fingerprints are byte-identical to the v1.0.1 tag")
    func preExistingFingerprintsAreByteIdentical() {
        // Post-cutover, production is v1.0.2 (see productionUsesSkyFidelityCalibration). The v1.0.1
        // calibration is preserved byte-for-byte in the stage1_experimental (+ sky_forward_v1_0_1) preset.
        let stage1 = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
        let legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.legacyBaselineId)!
        let stage2Legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage2LegacyId)!

        #expect(stage1.fingerprint == PinnedFingerprints.skyForwardV101)
        #expect(legacy.fingerprint == PinnedFingerprints.legacyBaseline)
        #expect(stage2Legacy.fingerprint == PinnedFingerprints.stage2Legacy)
    }

    @Test("sky_forward_v1_0_1 rollback preset retains v1.0.1 identity + byte-identical fingerprint")
    func skyForwardV101RollbackPreset() {
        let v101 = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.skyForwardV101Id)!
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!

        let stage1Calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )
        #expect(v101.mode == .stage1Experimental)
        #expect(v101.marketingVersion == "1.0.1")
        // Post-cutover the rollback is DISTINCT from production (now v1.0.2) but retains the shipped
        // v1.0.1 calibration + fingerprint → running it recovers v1.0.1 behaviour.
        #expect(v101.calibration == stage1Calibration)
        #expect(v101.calibration != production.calibration)
        #expect(v101.fingerprint == PinnedFingerprints.skyForwardV101)
        #expect(v101.fingerprint != production.fingerprint)
        // No v1.0.2 fields leaked onto the rollback calibration.
        #expect(v101.calibration.skyVibeWeights == nil)
        #expect(v101.calibration.lunarSignificanceCoeff == nil)
        // Post-cutover, production no longer shares this calibration+mode, so the v1.0.1 preset resolves
        // to itself (its own seed namespace) rather than collapsing to `production` (the handoff's
        // "resolvedEngineId shifts at cutover" note) — so rolling back busts the v1.0.2 production cache.
        #expect(DailyFitEngineRegistry.engineId(for: v101.calibration, mode: .stage1Experimental)
            == DailyFitEngineRegistry.skyForwardV101Id)
    }

    @Test("sky_forward_v1_0_2 preset is the sky-fidelity engine, now sharing production's fingerprint")
    func skyForwardV102ExperimentalPreset() {
        let v102 = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.skyForwardV102Id)!
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!

        #expect(v102.mode == .stage2SkyFidelity)
        #expect(v102.isExperimental)
        #expect(v102.dailySeedPolicy == .includesEngineId)
        #expect(v102.fingerprint == PinnedFingerprints.skyForwardV102)
        // Post-cutover production IS the v1.0.2 sky-fidelity engine, so v102 (the DEBUG alias) shares
        // production's calibration + fingerprint (was `!=` pre-cutover).
        #expect(v102.fingerprint == production.fingerprint)
        // Fingerprinted lunar-led sky mix (ratified 0.25 / 0.60 / 0.15).
        #expect(v102.calibration.skyVibeWeights?.lunar == 0.60)
        #expect(v102.calibration.skyVibeWeights?.transits == 0.25)
        #expect(v102.calibration.skyVibeWeights?.currentSun == 0.15)
        #expect(v102.calibration.lunarSignificanceCoeff == 0.8)
        // F5: jitter cut 0.40 → 0.18.
        #expect(v102.calibration.axisTuning.jitterRange == 0.18)
    }

    @Test("usesSkyForwardPipeline covers both v1.0.1 and v1.0.2 modes; standard excluded")
    func skyForwardPipelineHelper() {
        #expect(DailyFitEngineMode.stage1Experimental.usesSkyForwardPipeline)
        #expect(DailyFitEngineMode.stage2SkyFidelity.usesSkyForwardPipeline)
        #expect(!DailyFitEngineMode.standard.usesSkyForwardPipeline)
        #expect(DailyFitEngineMode.stage2SkyFidelity.usesSkyFidelityVibe)
        #expect(!DailyFitEngineMode.stage1Experimental.usesSkyFidelityVibe)
    }

    @Test("Sky Forward production differs from stage2 legacy on fixed fixture")
    func skyForwardDiffersFromStage2Legacy() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let skyForwardCalibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.productionId
        )

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let stage2Payload = DailyFitEngineRegistryTestSupport.generatePayload(
            profile: profile,
            date: date,
            calibration: DailyFitCalibration.default,
            engineId: DailyFitEngineRegistry.stage2LegacyId
        )

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let skyForwardPayload = DailyFitEngineRegistryTestSupport.generatePayload(
            profile: profile,
            date: date,
            calibration: skyForwardCalibration,
            mode: .stage1Experimental,
            engineId: DailyFitEngineRegistry.productionId
        )

        #expect(skyForwardPayload.dailyFitEngineId == DailyFitEngineRegistry.productionId)
        let stage2Vibe = stage2Payload.vibeBreakdown
        let skyForwardVibe = skyForwardPayload.vibeBreakdown
        let vibeDiffers = Energy.allCases.contains {
            stage2Vibe.value(for: $0) != skyForwardVibe.value(for: $0)
        }
        let essenceDiffers = stage2Payload.essenceProfile.visibleCategories.map(\.category)
            != skyForwardPayload.essenceProfile.visibleCategories.map(\.category)
        let tarotDiffers = stage2Payload.tarotCard.name != skyForwardPayload.tarotCard.name
        let paletteDiffers = stage2Payload.dailyPalette.colours.map(\.name)
            != skyForwardPayload.dailyPalette.colours.map(\.name)
        let scalesDiffer = stage2Payload.vibrancy != skyForwardPayload.vibrancy
            || stage2Payload.contrast != skyForwardPayload.contrast
        #expect(vibeDiffers || essenceDiffers || tarotDiffers || paletteDiffers || scalesDiffer)
    }

    @Test("Standard mode with production calibration is bit-identical to default-mode snapshot")
    func standardModeMatchesImplicitDefault() {
        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let natal = DailyFitEngineRegistryTestSupport.chart(signs: profile.natalSigns)
        let progressed = DailyFitEngineRegistryTestSupport.chart(signs: profile.progressedSigns)
        let transits = [
            NatalChartCalculator.TransitAspect(
                transitPlanet: "Mars", transitPlanetSymbol: "•",
                natalPlanet: "Sun", natalPlanetSymbol: "•",
                aspectType: "conjunction", aspectSymbol: "•",
                orb: 1.0, applying: true,
                effectiveFrom: date,
                effectiveTo: date.addingTimeInterval(86400 * 3),
                description: "Mars conjunction Sun",
                category: .shortTerm
            )
        ]

        let implicit = DailyEnergyEngine.generateSnapshot(
            natalChart: natal, progressedChart: progressed,
            transits: transits, moonPhaseDegrees: 45.0,
            profileHash: profile.hash, date: date
        )
        let explicit = DailyEnergyEngine.generateSnapshot(
            natalChart: natal, progressedChart: progressed,
            transits: transits, moonPhaseDegrees: 45.0,
            profileHash: profile.hash, date: date,
            mode: .standard
        )

        for energy in Energy.allCases {
            #expect(implicit.vibeProfile.value(for: energy) == explicit.vibeProfile.value(for: energy))
        }
        #expect(implicit.axes.action == explicit.axes.action)
        #expect(implicit.axes.tempo == explicit.axes.tempo)
        #expect(implicit.axes.strategy == explicit.axes.strategy)
        #expect(implicit.axes.visibility == explicit.axes.visibility)
        #expect(implicit.dailySeed == explicit.dailySeed)
    }

    @Test("stage1_experimental uses Option A sign multiplier policy")
    func stage1SignMultiplierPolicy() {
        let stage1 = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )
        #expect(stage1.signMultiplierPolicy == .stage1OptionA)
        #expect(stage1.signMultiplierPolicy.applyToDailyVibe == false)
        #expect(stage1.signMultiplierPolicy.applyToChartAnchor == true)
    }

    @Test("production and legacy use productionDefault sign multiplier policy")
    func productionSignMultiplierPolicy() {
        #expect(DailyFitCalibration.default.signMultiplierPolicy == .productionDefault)
        let legacy = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.legacyBaselineId)
        #expect(legacy.signMultiplierPolicy == .productionDefault)
    }

    @Test("stage1 sky payload skips sign multipliers; chart anchor keeps them")
    func stage1SkyPathSkipsSignMultipliers() {
        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let natal = DailyFitEngineRegistryTestSupport.chart(signs: profile.natalSigns)
        let progressed = DailyFitEngineRegistryTestSupport.chart(signs: profile.progressedSigns)
        let transits = [
            NatalChartCalculator.TransitAspect(
                transitPlanet: "Mars", transitPlanetSymbol: "•",
                natalPlanet: "Sun", natalPlanetSymbol: "•",
                aspectType: "conjunction", aspectSymbol: "•",
                orb: 1.0, applying: true,
                effectiveFrom: date,
                effectiveTo: date.addingTimeInterval(86400 * 3),
                description: "Mars conjunction Sun",
                category: .shortTerm
            )
        ]
        let calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )

        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            date: date,
            calibration: calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )

        #expect(snapshot.vibeProfile == snapshot.skyVibeProfile)
        #expect(snapshot.chartVibeProfile != nil)

        let (_, trace) = DailyEnergyEngine.generateSnapshotWithTrace(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            date: date,
            calibration: calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )

        #expect(trace.postMultiplierScores == trace.rawScores)
        for energy in Energy.allCases {
            #expect(trace.signMultipliers[energy.rawValue] == 1.0)
        }

        let chartAnchorOffCal = DailyFitCalibration(
            sourceWeights: calibration.sourceWeights,
            signEnergyMap: calibration.signEnergyMap,
            signMultiplierPolicy: .off,
            planetAxisMap: calibration.planetAxisMap,
            selectionWeights: calibration.selectionWeights,
            axisTuning: calibration.axisTuning,
            stage2Sensitivity: calibration.stage2Sensitivity
        )
        let snapshotNoChartMult = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            date: date,
            calibration: chartAnchorOffCal,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        let chartDiffers = Energy.allCases.contains {
            snapshot.chartVibeProfile!.value(for: $0)
                != snapshotNoChartMult.chartVibeProfile!.value(for: $0)
        }
        #expect(chartDiffers, "Chart anchor should still apply sign multipliers when policy enables it")
    }

    @Test("stage1 diagnostics report honest daily sign-multiplier policy")
    func stage1DiagnosticsHonesty() {
        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let natal = DailyFitEngineRegistryTestSupport.chart(signs: profile.natalSigns)
        let progressed = DailyFitEngineRegistryTestSupport.chart(signs: profile.progressedSigns)
        let calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )

        let (_, report) = DailyFitDiagnostics.generateReport(
            natalChart: natal,
            progressedChart: progressed,
            transits: [],
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            blueprint: DailyFitEngineRegistryTestSupport.minimalBlueprint,
            date: date,
            calibration: calibration,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )

        #expect(report.postMultiplierScores == report.rawEnergyScores)
        #expect(report.stage1Attribution?.signMultipliersAppliedToDailyVibe == false)
        #expect(report.calibrationSnapshot.signMultiplierPolicy["applyToDailyVibe"] == false)
        #expect(report.calibrationSnapshot.signMultiplierPolicy["applyToChartAnchor"] == true)
        #expect(report.stage1Attribution?.chartAnchorSignMultiplierApplied?["drama"] == 1.35)
        #expect(report.stage1AxisAttribution?.byAxis.count == 4)
    }

    @Test("Sky Forward production daily path skips sign multipliers on sky read")
    func skyForwardDailySignMultipliersInTrace() {
        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let natal = DailyFitEngineRegistryTestSupport.chart(signs: profile.natalSigns)
        let progressed = DailyFitEngineRegistryTestSupport.chart(signs: profile.progressedSigns)
        let skyForwardCalibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.productionId
        )

        let (_, report) = DailyFitDiagnostics.generateReport(
            natalChart: natal,
            progressedChart: progressed,
            transits: [],
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            blueprint: DailyFitEngineRegistryTestSupport.minimalBlueprint,
            date: date,
            calibration: skyForwardCalibration,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )

        #expect(report.stage1Attribution?.signMultipliersAppliedToDailyVibe == false)
        #expect(report.postMultiplierScores == report.rawEnergyScores)
    }

    @Test("stage2 legacy daily path applies non-neutral sign multipliers in trace")
    func stage2LegacyDailySignMultipliersInTrace() {
        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let natal = DailyFitEngineRegistryTestSupport.chart(signs: profile.natalSigns)
        let progressed = DailyFitEngineRegistryTestSupport.chart(signs: profile.progressedSigns)

        let (_, report) = DailyFitDiagnostics.generateReport(
            natalChart: natal,
            progressedChart: progressed,
            transits: [],
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            blueprint: DailyFitEngineRegistryTestSupport.minimalBlueprint,
            date: date,
            calibration: .default,
            dailyFitEngineId: DailyFitEngineRegistry.stage2LegacyId
        )

        #expect(report.stage1Attribution?.signMultipliersAppliedToDailyVibe == true)
        #expect(report.postMultiplierScores != report.rawEnergyScores)
        let dramaMult = report.stage1Attribution?.signMultiplierApplied["drama"] ?? 0
        #expect(dramaMult == 1.35)
    }

    @Test("stage1 sky payload ignores signEnergyMap on daily path")
    func stage1SkyPayloadIgnoresSignMapOnDailyPath() {
        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let natal = DailyFitEngineRegistryTestSupport.chart(signs: profile.natalSigns)
        let progressed = DailyFitEngineRegistryTestSupport.chart(signs: profile.progressedSigns)
        let transits = [
            NatalChartCalculator.TransitAspect(
                transitPlanet: "Mars", transitPlanetSymbol: "•",
                natalPlanet: "Sun", natalPlanetSymbol: "•",
                aspectType: "conjunction", aspectSymbol: "•",
                orb: 1.0, applying: true,
                effectiveFrom: date,
                effectiveTo: date.addingTimeInterval(86400 * 3),
                description: "Mars conjunction Sun",
                category: .shortTerm
            )
        ]
        let stage1Calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )
        var extremeMap = stage1Calibration.signEnergyMap.multipliers
        extremeMap["Leo"] = Dictionary(uniqueKeysWithValues: Energy.allCases.map { ($0, 2.0) })
        let extremeCalibration = DailyFitCalibration(
            sourceWeights: stage1Calibration.sourceWeights,
            signEnergyMap: DailyFitCalibration.SignEnergyMap(multipliers: extremeMap),
            signMultiplierPolicy: .stage1OptionA,
            planetAxisMap: stage1Calibration.planetAxisMap,
            selectionWeights: stage1Calibration.selectionWeights,
            axisTuning: stage1Calibration.axisTuning,
            stage2Sensitivity: stage1Calibration.stage2Sensitivity
        )

        let baseline = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            date: date,
            calibration: stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        let extreme = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            date: date,
            calibration: extremeCalibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )

        #expect(baseline.vibeProfile == extreme.vibeProfile)
        #expect(baseline.skyVibeProfile == extreme.skyVibeProfile)
        #expect(baseline.vibeProfile.totalPoints == 21)
        #expect(baseline.chartVibeProfile != extreme.chartVibeProfile)
    }

    @Test("legacy_baseline produces different Daily Fit output than production on fixed fixture")
    func legacyBaselineDiffersFromProduction() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let productionPayload = DailyFitEngineRegistryTestSupport.generatePayload(
            profile: profile,
            date: date,
            calibration: DailyFitCalibration.default
        )

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let legacyPayload = DailyFitEngineRegistryTestSupport.generatePayload(
            profile: profile,
            date: date,
            calibration: DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.legacyBaselineId)
        )

        #expect(productionPayload.vibeBreakdown.dominantEnergy != legacyPayload.vibeBreakdown.dominantEnergy
            || productionPayload.vibrancy != legacyPayload.vibrancy
            || productionPayload.tarotCard.name != legacyPayload.tarotCard.name)
    }
}

private enum DailyFitEngineRegistryTestSupport {

    static let fixedBaseDate: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: 2026, month: 5, day: 10))!
    }()

    static let ashProfile = (
        hash: "cal_ash",
        natalSigns: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5],
        progressedSigns: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5]
    )

    static func generatePayload(
        profile: (hash: String, natalSigns: [Int], progressedSigns: [Int]),
        date: Date,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode = .standard,
        engineId: String? = nil
    ) -> DailyFitPayload {
        let natal = chart(signs: profile.natalSigns)
        let progressed = chart(signs: profile.progressedSigns)
        let transits = [
            NatalChartCalculator.TransitAspect(
                transitPlanet: "Mars", transitPlanetSymbol: "•",
                natalPlanet: "Sun", natalPlanetSymbol: "•",
                aspectType: "conjunction", aspectSymbol: "•",
                orb: 1.0, applying: true,
                effectiveFrom: date,
                effectiveTo: date.addingTimeInterval(86400 * 3),
                description: "Mars conjunction Sun",
                category: .shortTerm
            )
        ]
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: transits,
            moonPhaseDegrees: 45.0,
            profileHash: profile.hash,
            date: date,
            calibration: calibration,
            mode: mode,
            dailyFitEngineId: engineId
        )
        return BlueprintLensEngine.generatePayload(
            blueprint: minimalBlueprint,
            snapshot: snapshot,
            calibration: calibration,
            mode: mode,
            dailyFitEngineId: engineId
        )
    }

    static func chart(signs: [Int]) -> NatalChartCalculator.NatalChart {
        let planets: [(String, String)] = [
            ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
            ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
            ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
        ]
        var positions: [NatalChartCalculator.PlanetPosition] = []
        for (index, (name, symbol)) in planets.enumerated() {
            let sign = signs[index]
            positions.append(NatalChartCalculator.PlanetPosition(
                name: name, symbol: symbol,
                longitude: Double((sign - 1) * 30 + 15), latitude: 0.0,
                zodiacSign: sign, zodiacPosition: "15°00'",
                isRetrograde: false
            ))
        }
        return NatalChartCalculator.NatalChart(
            planets: positions,
            ascendant: Double((signs[0] - 1) * 30), midheaven: 90.0,
            descendant: 180.0, imumCoeli: 270.0,
            houseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            wholeSignHouseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            northNode: 0.0, southNode: 180.0, vertex: 90.0,
            partOfFortune: 45.0, lilith: 120.0, chiron: 200.0,
            lunarPhase: 90.0
        )
    }

    static let minimalBlueprint: CosmicBlueprint = {
        func colour(_ name: String, _ hex: String, _ role: ColourRole) -> BlueprintColour {
            BlueprintColour(
                name: name, hexValue: hex, role: role,
                provenance: .v4Template(family: "Reg", band: role.rawValue, index: 0)
            )
        }
        let palette = PaletteSection(
            neutrals: [colour("Ivory", "#FFFFF0", .neutral)],
            coreColours: [
                colour("Burnt Sienna", "#A0522D", .core),
                colour("Terracotta", "#E2725B", .core),
                colour("Amber", "#FFBF00", .core),
                colour("Olive", "#808000", .core),
            ],
            accentColours: [colour("Coral", "#FF7F50", .accent)],
            supportColours: [colour("Blush", "#DE5D83", .support)],
            family: .deepAutumn, cluster: .deepWarmStructured,
            variables: DerivedVariables(
                depth: .deep, temperature: .warm,
                saturation: .rich, contrast: .high,
                surface: .structured
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Registry test palette."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Registry test."),
            textures: TexturesSection(
                goodText: "Good.", badText: "Bad.", sweetSpotText: "Sweet.",
                recommendedTextures: ["cashmere", "denim"],
                avoidTextures: ["polyester"], sweetSpotKeywords: ["luxe"]
            ),
            palette: palette,
            occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
            hardware: HardwareSection(
                metalsText: "Metals.", stonesText: "Stones.", tipText: "Tip.",
                recommendedMetals: ["gold"], recommendedStones: ["ruby"]
            ),
            code: CodeSection(leanInto: ["structured shoulders"], avoid: ["soft draping"], consider: []),
            accessory: AccessorySection(paragraphs: ["A1."]),
            pattern: PatternSection(
                narrativeText: "Pattern.", tipText: "Tip.",
                recommendedPatterns: ["stripes"], avoidPatterns: ["neon"]
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }()

}
