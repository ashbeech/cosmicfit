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
        #expect(calibration == DailyFitCalibration.default)
    }

    @Test("Production preset uses .default by identity")
    func productionUsesDefaultIdentity() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)
        #expect(production?.calibration == DailyFitCalibration.default)
    }

    @Test("Fingerprints are stable and differ between production and legacy_baseline")
    func fingerprintsDiffer() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let legacy = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.legacyBaselineId)!

        #expect(production.fingerprint == DailyFitEngineRegistry.fingerprint(for: production.calibration))
        #expect(legacy.fingerprint == DailyFitEngineRegistry.fingerprint(for: legacy.calibration))
        #expect(production.fingerprint != legacy.fingerprint)
    }

    @Test("stage1_experimental fingerprint differs from production")
    func stage1FingerprintDiffersFromProduction() {
        let production = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
        let stage1 = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)!
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

    @Test("stage1_experimental produces different output than production on fixed fixture")
    func stage1ExperimentalDiffersFromProduction() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let profile = DailyFitEngineRegistryTestSupport.ashProfile
        let date = DailyFitEngineRegistryTestSupport.fixedBaseDate
        let stage1Calibration = DailyFitEngineRegistry.calibration(
            for: DailyFitEngineRegistry.stage1ExperimentalId
        )

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let productionPayload = DailyFitEngineRegistryTestSupport.generatePayload(
            profile: profile,
            date: date,
            calibration: DailyFitCalibration.default,
            engineId: DailyFitEngineRegistry.productionId
        )

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let stage1Payload = DailyFitEngineRegistryTestSupport.generatePayload(
            profile: profile,
            date: date,
            calibration: stage1Calibration,
            engineId: DailyFitEngineRegistry.stage1ExperimentalId
        )

        #expect(stage1Payload.dailyFitEngineId == DailyFitEngineRegistry.stage1ExperimentalId)
        let productionVibe = productionPayload.vibeBreakdown
        let stage1Vibe = stage1Payload.vibeBreakdown
        let vibeDiffers = Energy.allCases.contains {
            productionVibe.value(for: $0) != stage1Vibe.value(for: $0)
        }
        let essenceDiffers = productionPayload.essenceProfile.visibleCategories.map(\.category)
            != stage1Payload.essenceProfile.visibleCategories.map(\.category)
        let tarotDiffers = productionPayload.tarotCard.name != stage1Payload.tarotCard.name
        let paletteDiffers = productionPayload.dailyPalette.colours.map(\.name)
            != stage1Payload.dailyPalette.colours.map(\.name)
        let scalesDiffer = productionPayload.vibrancy != stage1Payload.vibrancy
            || productionPayload.contrast != stage1Payload.contrast
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

    @Test("production daily path applies non-neutral sign multipliers in trace")
    func productionDailySignMultipliersInTrace() {
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
            dailyFitEngineId: DailyFitEngineRegistry.productionId
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
