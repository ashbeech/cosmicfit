//
//  PersonalScaleEnvelope_Tests.swift
//  Cosmic FitTests
//
//  Unit tests for PersonalScaleEnvelope calculator — P1–P10 per spec §10.1.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixtures

private enum EnvelopeFixtures {

    static let stage1Calibration = DailyFitEngineRegistry.calibration(
        for: DailyFitEngineRegistry.stage1ExperimentalId
    )
    static let productionCalibration = DailyFitCalibration.default

    static func colour(_ name: String, _ hex: String, _ role: ColourRole) -> BlueprintColour {
        BlueprintColour(
            name: name, hexValue: hex, role: role,
            provenance: .v4Template(family: "Test", band: role.rawValue, index: 0)
        )
    }

    /// Medium contrast, rich vibrancy, warm temperature, gold + silver metals.
    static let briarBlueprint: CosmicBlueprint = {
        let palette = PaletteSection(
            neutrals: [colour("Ivory", "#FFFFF0", .neutral)],
            coreColours: [colour("Burnt Sienna", "#A0522D", .core)],
            accentColours: [colour("Coral", "#FF7F50", .accent)],
            supportColours: nil,
            family: .deepAutumn, cluster: .deepWarmStructured,
            variables: DerivedVariables(
                depth: .deep, temperature: .warm,
                saturation: .rich, contrast: .high,
                surface: .structured
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Test."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Test."),
            textures: TexturesSection(
                goodText: "G.", badText: "B.", sweetSpotText: "S.",
                recommendedTextures: ["silk"], avoidTextures: [], sweetSpotKeywords: []
            ),
            palette: palette,
            occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
            hardware: HardwareSection(
                metalsText: "M.", stonesText: "S.", tipText: "T.",
                recommendedMetals: ["gold", "silver"], recommendedStones: []
            ),
            code: CodeSection(leanInto: [], avoid: [], consider: []),
            accessory: AccessorySection(paragraphs: []),
            pattern: PatternSection(
                narrativeText: "P.", tipText: "T.",
                recommendedPatterns: [], avoidPatterns: []
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }()

    /// Soft saturation, low contrast — for testing floor near 0.
    static func softBlueprint(temperature: Temperature = .cool) -> CosmicBlueprint {
        let palette = PaletteSection(
            neutrals: [colour("Dove", "#B0B0B0", .neutral)],
            coreColours: [colour("Powder Blue", "#B0E0E6", .core)],
            accentColours: [colour("Lavender", "#E6E6FA", .accent)],
            supportColours: nil,
            family: .lightSummer, cluster: .lightAiryCool,
            variables: DerivedVariables(
                depth: .light, temperature: temperature,
                saturation: .soft, contrast: .low,
                surface: .soft
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Soft."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Soft."),
            textures: TexturesSection(
                goodText: "G.", badText: "B.", sweetSpotText: "S.",
                recommendedTextures: [], avoidTextures: [], sweetSpotKeywords: []
            ),
            palette: palette,
            occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
            hardware: HardwareSection(
                metalsText: "M.", stonesText: "S.", tipText: "T.",
                recommendedMetals: ["silver", "platinum"], recommendedStones: []
            ),
            code: CodeSection(leanInto: [], avoid: [], consider: []),
            accessory: AccessorySection(paragraphs: []),
            pattern: PatternSection(
                narrativeText: "P.", tipText: "T.",
                recommendedPatterns: [], avoidPatterns: []
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }

    /// Medium contrast, muted vibrancy — neutral defaults.
    static let mediumBlueprint: CosmicBlueprint = {
        let palette = PaletteSection(
            neutrals: [colour("Grey", "#808080", .neutral)],
            coreColours: [colour("Navy", "#000080", .core)],
            accentColours: [colour("Teal", "#008080", .accent)],
            supportColours: nil,
            family: .trueWinter, cluster: .deepCoolControlled,
            variables: DerivedVariables(
                depth: .medium, temperature: .neutral,
                saturation: .muted, contrast: .medium,
                surface: .structured
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Medium."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Medium."),
            textures: TexturesSection(
                goodText: "G.", badText: "B.", sweetSpotText: "S.",
                recommendedTextures: [], avoidTextures: [], sweetSpotKeywords: []
            ),
            palette: palette,
            occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
            hardware: HardwareSection(
                metalsText: "M.", stonesText: "S.", tipText: "T.",
                recommendedMetals: ["silver"], recommendedStones: []
            ),
            code: CodeSection(leanInto: [], avoid: [], consider: []),
            accessory: AccessorySection(paragraphs: []),
            pattern: PatternSection(
                narrativeText: "P.", tipText: "T.",
                recommendedPatterns: [], avoidPatterns: []
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }()
}

// MARK: - P1–P10 Unit Tests

@Suite
struct PersonalScaleEnvelopeTests {

    // MARK: P1 — Contrast medium + Stage 1 coeffs

    @Test("P1: Contrast medium baseline + Stage 1 — floor/ceiling match practical half-span")
    func contrastMediumStage1() {
        let cal = EnvelopeFixtures.stage1Calibration
        let presentation = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: cal,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        let env = presentation.contrast
        #expect(env.baseline == 0.50)
        let halfSpan = Stage1ScaleSensitivity.contrastPracticalHalfSpan
        let expectedFloor = max(0.0, 0.50 - halfSpan)
        let expectedCeiling = min(1.0, 0.50 + halfSpan)
        #expect(abs(env.floor - expectedFloor) < 0.001,
                "Floor: \(env.floor) vs expected \(expectedFloor)")
        #expect(abs(env.ceiling - expectedCeiling) < 0.001,
                "Ceiling: \(env.ceiling) vs expected \(expectedCeiling)")
    }

    // MARK: P2 — Vibrancy soft vs rich same engine

    @Test("P2: Vibrancy soft vs rich — baselines differ; standard floors differ")
    func vibrancySoftVsRich() {
        let prodCal = EnvelopeFixtures.productionCalibration
        let softBP = EnvelopeFixtures.softBlueprint()
        let richBP = EnvelopeFixtures.briarBlueprint

        // Standard mode: vibrancyCoeff (0.40) keeps modulation narrow enough for floor separation
        let softEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: softBP, calibration: prodCal, mode: .standard,
            vibrancy: 0.3, contrast: 0.5, metalTone: 0.5
        ).vibrancy
        let richEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: richBP, calibration: prodCal, mode: .standard,
            vibrancy: 0.8, contrast: 0.5, metalTone: 0.5
        ).vibrancy

        #expect(softEnv.floor < richEnv.floor,
                "Soft floor \(softEnv.floor) should be < rich floor \(richEnv.floor)")
        #expect(softEnv.baseline != richEnv.baseline)

        // Stage 1: calibrated practical bounds (Plan 3); floors differ because baselines differ
        let s1Cal = EnvelopeFixtures.stage1Calibration
        let softS1 = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: softBP, calibration: s1Cal, mode: .stage1Experimental,
            vibrancy: 0.3, contrast: 0.5, metalTone: 0.5
        ).vibrancy
        let richS1 = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: richBP, calibration: s1Cal, mode: .stage1Experimental,
            vibrancy: 0.8, contrast: 0.5, metalTone: 0.5
        ).vibrancy
        #expect(softS1.baseline < richS1.baseline)
    }

    // MARK: P3 — Metal tone baseline from temp + metals

    @Test("P3: Metal tone baseline matches manual calculation")
    func metalToneBaselineComputation() {
        let presentation = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.briarBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.6
        )
        let env = presentation.metalTone
        // Briar: warm temp → 0.8, metals = [gold, silver] → warm=1, cool=1 → lean=0.5
        // baseline = 0.8 * 0.6 + 0.5 * 0.4 = 0.48 + 0.20 = 0.68
        #expect(abs(env.baseline - 0.68) < 0.001,
                "Metal baseline: \(env.baseline) vs expected 0.68")
    }

    // MARK: P4 — displayPosition at floor

    @Test("P4: displayPosition ≈ 0.0 when value equals floor")
    func displayPositionAtFloor() {
        let cal = EnvelopeFixtures.stage1Calibration
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: cal, mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        ).contrast

        let atFloor = PersonalScaleEnvelopeCalculator.computeDisplayPosition(
            value: env.floor, floor: env.floor, ceiling: env.ceiling
        )
        #expect(abs(atFloor - 0.0) < 0.001)
    }

    // MARK: P5 — displayPosition at ceiling

    @Test("P5: displayPosition ≈ 1.0 when value equals ceiling")
    func displayPositionAtCeiling() {
        let cal = EnvelopeFixtures.stage1Calibration
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: cal, mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        ).contrast

        let atCeiling = PersonalScaleEnvelopeCalculator.computeDisplayPosition(
            value: env.ceiling, floor: env.floor, ceiling: env.ceiling
        )
        #expect(abs(atCeiling - 1.0) < 0.001)
    }

    // MARK: P6 — displayPosition at baseline

    @Test("P6: displayPosition at baseline ≈ (baseline-floor)/(ceiling-floor)")
    func displayPositionAtBaseline() {
        let cal = EnvelopeFixtures.stage1Calibration
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: cal, mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        ).contrast

        let expected = (env.baseline - env.floor) / (env.ceiling - env.floor)
        #expect(abs(env.baselinePosition - expected) < 0.001,
                "Baseline position: \(env.baselinePosition) vs expected \(expected)")
    }

    // MARK: P7 — Degenerate envelope

    @Test("P7: Degenerate envelope (floor ≈ ceiling) returns displayPosition 0.5")
    func degenerateEnvelopeReturnsCentre() {
        let dp = PersonalScaleEnvelopeCalculator.computeDisplayPosition(
            value: 0.5, floor: 0.5, ceiling: 0.5
        )
        #expect(dp == 0.5)

        let nearDegen = PersonalScaleEnvelopeCalculator.computeDisplayPosition(
            value: 0.5, floor: 0.5, ceiling: 0.5005
        )
        #expect(nearDegen == 0.5)
    }

    // MARK: P8 — Value above ceiling clamps to 1.0

    @Test("P8: Value above ceiling (injected) clamps displayPosition to 1.0")
    func valueAboveCeilingClampsToOne() {
        let dp = PersonalScaleEnvelopeCalculator.computeDisplayPosition(
            value: 0.95, floor: 0.3, ceiling: 0.7
        )
        #expect(dp == 1.0)
    }

    // MARK: P9 — Production vs Stage 1 same blueprint

    @Test("P9: Production vs Stage 1 same blueprint — envelopes differ")
    func productionVsStage1EnvelopesDiffer() {
        let bp = EnvelopeFixtures.mediumBlueprint
        let prodEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: bp,
            calibration: EnvelopeFixtures.productionCalibration,
            mode: .standard,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        let stage1Env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: bp,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )

        let contrastDiffers = prodEnv.contrast.floor != stage1Env.contrast.floor
            || prodEnv.contrast.ceiling != stage1Env.contrast.ceiling
        #expect(contrastDiffers,
                "Contrast envelopes must differ between production and stage1")

        let metalDiffers = prodEnv.metalTone.floor != stage1Env.metalTone.floor
            || prodEnv.metalTone.ceiling != stage1Env.metalTone.ceiling
        #expect(metalDiffers,
                "Metal tone envelopes must differ between production and stage1")
    }

    // MARK: P10 — Envelope uses full analytical ceiling (soften caps are runtime-only)

    @Test("P10: Contrast uses calibrated practical bounds (Plan 4); Vibrancy uses calibrated practical bounds (Plan 3)")
    func envelopeCeilingBehavior() {
        let cal = EnvelopeFixtures.stage1Calibration

        // Briar (high contrast, baseline 0.75): ceiling = 0.75 + halfSpan
        let briarEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.briarBlueprint, calibration: cal,
            mode: .stage1Experimental, vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        let contrastHalfSpan = Stage1ScaleSensitivity.contrastPracticalHalfSpan
        let expectedBriarCeiling = min(1.0, 0.75 + contrastHalfSpan)
        #expect(abs(briarEnv.contrast.ceiling - expectedBriarCeiling) < 0.001,
                "Briar contrast ceiling \(briarEnv.contrast.ceiling) should be baseline+halfSpan \(expectedBriarCeiling)")
        #expect(briarEnv.contrast.ceiling > 0.70,
                "Contrast ceiling must exceed softenContrastCap (0.70) — cap is runtime-only")

        // Vibrancy (rich, baseline 0.75): Plan 3 calibrated practical envelope
        let halfSpan = Stage1ScaleSensitivity.vibrancyPracticalHalfSpan
        let expectedVibrancyCeiling = min(1.0, 0.75 + halfSpan)
        let expectedVibrancyFloor = max(0.0, 0.75 - halfSpan)
        #expect(abs(briarEnv.vibrancy.ceiling - expectedVibrancyCeiling) < 0.001,
                "Vibrancy ceiling \(briarEnv.vibrancy.ceiling) should be baseline+halfSpan \(expectedVibrancyCeiling)")
        #expect(abs(briarEnv.vibrancy.floor - expectedVibrancyFloor) < 0.001,
                "Vibrancy floor \(briarEnv.vibrancy.floor) should be baseline-halfSpan \(expectedVibrancyFloor)")

        // Medium blueprint vibrancy: calibrated around 0.50
        let medEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint, calibration: cal,
            mode: .stage1Experimental, vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        #expect(abs(medEnv.vibrancy.ceiling - (0.50 + halfSpan)) < 0.001,
                "Muted vibrancy ceiling \(medEnv.vibrancy.ceiling) should be 0.50+halfSpan")
        #expect(abs(medEnv.vibrancy.floor - (0.50 - halfSpan)) < 0.001,
                "Muted vibrancy floor \(medEnv.vibrancy.floor) should be 0.50-halfSpan")
    }

    // MARK: - Additional edge cases

    @Test("E11: Blueprint variable nil uses default baselines (0.50)")
    func nilVariablesDefaultBaseline() {
        let palette = PaletteSection(
            coreColours: [], accentColours: [],
            narrativeText: ""
        )
        let bp = CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "Test", generationDate: Date()
            ),
            styleCore: StyleCoreSection(narrativeText: ""),
            textures: TexturesSection(
                goodText: "", badText: "", sweetSpotText: "",
                recommendedTextures: [], avoidTextures: [], sweetSpotKeywords: []
            ),
            palette: palette,
            occasions: OccasionsSection(workText: "", intimateText: "", dailyText: ""),
            hardware: HardwareSection(
                metalsText: "", stonesText: "", tipText: "",
                recommendedMetals: [], recommendedStones: []
            ),
            code: CodeSection(leanInto: [], avoid: [], consider: []),
            accessory: AccessorySection(paragraphs: []),
            pattern: PatternSection(
                narrativeText: "", tipText: "",
                recommendedPatterns: [], avoidPatterns: []
            ),
            generatedAt: Date(), engineVersion: "4.7"
        )
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: bp,
            calibration: EnvelopeFixtures.productionCalibration,
            mode: .standard,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        #expect(env.vibrancy.baseline == 0.50)
        #expect(env.contrast.baseline == 0.50)
        // Metal tone = tempVal*0.6 + metalLean*0.4 = 0.5*0.6 + 0*0.4 = 0.30
        #expect(abs(env.metalTone.baseline - 0.30) < 0.001)
    }

    @Test("Value below floor clamps displayPosition to 0.0")
    func valueBelowFloorClampsToZero() {
        let dp = PersonalScaleEnvelopeCalculator.computeDisplayPosition(
            value: 0.1, floor: 0.3, ceiling: 0.7
        )
        #expect(dp == 0.0)
    }

    @Test("Display position is within [0, 1] for all envelope outputs")
    func displayPositionAlwaysInRange() {
        let cals: [(DailyFitCalibration, DailyFitEngineMode)] = [
            (EnvelopeFixtures.productionCalibration, .standard),
            (EnvelopeFixtures.stage1Calibration, .stage1Experimental),
        ]
        let blueprints = [
            EnvelopeFixtures.briarBlueprint,
            EnvelopeFixtures.softBlueprint(),
            EnvelopeFixtures.mediumBlueprint,
        ]
        for bp in blueprints {
            for (cal, mode) in cals {
                for v in stride(from: 0.0, through: 1.0, by: 0.1) {
                    let env = PersonalScaleEnvelopeCalculator.makePresentation(
                        blueprint: bp, calibration: cal, mode: mode,
                        vibrancy: v, contrast: v, metalTone: v
                    )
                    #expect(env.vibrancy.displayPosition >= 0.0 && env.vibrancy.displayPosition <= 1.0)
                    #expect(env.contrast.displayPosition >= 0.0 && env.contrast.displayPosition <= 1.0)
                    #expect(env.metalTone.displayPosition >= 0.0 && env.metalTone.displayPosition <= 1.0)
                }
            }
        }
    }
}

// MARK: - Plan 3 Silhouette Envelope Tests

@Suite
struct SilhouetteEnvelopeTests {

    @Test("S1: Silhouette envelope floor/ceiling centered on chart anchor with practical half-span")
    func silhouetteEnvelopeUsesCommittedConstants() {
        let sil = SilhouetteProfile(
            masculineFeminine: 0.6, angularRounded: 0.4, structuredDraped: 0.5,
            chartAnchorMF: 0.55, chartAnchorAR: 0.45, chartAnchorSD: 0.50
        )
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.briarBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
            silhouette: sil
        )
        let mf = env.masculineFeminine!
        let ar = env.angularRounded!
        let sd = env.structuredDraped!

        let mfHalf = Stage1ScaleSensitivity.silhouetteMFARPracticalHalfSpan
        let sdHalf = Stage1ScaleSensitivity.silhouetteSDPracticalHalfSpan

        #expect(abs(mf.floor - max(0.0, 0.55 - mfHalf)) < 0.001)
        #expect(abs(mf.ceiling - min(1.0, 0.55 + mfHalf)) < 0.001)
        #expect(abs(ar.floor - max(0.0, 0.45 - mfHalf)) < 0.001)
        #expect(abs(ar.ceiling - min(1.0, 0.45 + mfHalf)) < 0.001)
        #expect(abs(sd.floor - max(0.0, 0.50 - sdHalf)) < 0.001)
        #expect(abs(sd.ceiling - min(1.0, 0.50 + sdHalf)) < 0.001)
    }

    @Test("S2: Silhouette envelope baseline matches chart anchor")
    func silhouetteBaselineIsChartAnchor() {
        let sil = SilhouetteProfile(
            masculineFeminine: 0.6, angularRounded: 0.4, structuredDraped: 0.7,
            chartAnchorMF: 0.35, chartAnchorAR: 0.60, chartAnchorSD: 0.45
        )
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
            silhouette: sil
        )
        #expect(env.masculineFeminine!.baseline == 0.35)
        #expect(env.angularRounded!.baseline == 0.60)
        #expect(env.structuredDraped!.baseline == 0.45)
    }

    @Test("S3: Silhouette displayPosition at floor ≈ 0.0")
    func silhouetteDisplayPositionAtFloor() {
        let sil = SilhouetteProfile(
            masculineFeminine: Stage1ScaleSensitivity.silhouetteFloor,
            angularRounded: 0.5, structuredDraped: 0.5,
            chartAnchorMF: 0.5, chartAnchorAR: 0.5, chartAnchorSD: 0.5
        )
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
            silhouette: sil
        )
        #expect(abs(env.masculineFeminine!.displayPosition - 0.0) < 0.001)
    }

    @Test("S4: Silhouette displayPosition at ceiling ≈ 1.0")
    func silhouetteDisplayPositionAtCeiling() {
        let sil = SilhouetteProfile(
            masculineFeminine: Stage1ScaleSensitivity.silhouetteCeiling,
            angularRounded: 0.5, structuredDraped: 0.5,
            chartAnchorMF: 0.5, chartAnchorAR: 0.5, chartAnchorSD: 0.5
        )
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
            silhouette: sil
        )
        #expect(abs(env.masculineFeminine!.displayPosition - 1.0) < 0.001)
    }

    @Test("S5: Silhouette degenerate (value outside bounds) clamps to 0 or 1")
    func silhouetteClampsBeyondBounds() {
        let sil = SilhouetteProfile(
            masculineFeminine: 0.01, angularRounded: 0.99, structuredDraped: 0.5,
            chartAnchorMF: 0.5, chartAnchorAR: 0.5, chartAnchorSD: 0.5
        )
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
            silhouette: sil
        )
        #expect(env.masculineFeminine!.displayPosition == 0.0)
        #expect(env.angularRounded!.displayPosition == 1.0)
    }

    @Test("S6: No silhouette input → nil envelopes (legacy compat)")
    func noSilhouetteInputProducesNilEnvelopes() {
        let env = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: EnvelopeFixtures.stage1Calibration,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        #expect(env.masculineFeminine == nil)
        #expect(env.angularRounded == nil)
        #expect(env.structuredDraped == nil)
    }

    @Test("S7: Stage1 payloads include six scale envelopes")
    func stage1PayloadIncludesSixEnvelopes() {
        let bp = EnvelopeFixtures.briarBlueprint
        let snapshot = DailyEnergySnapshot.fixture()
        let cal = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.stage1ExperimentalId)
        let engineId = DailyFitEngineRegistry.stage1ExperimentalId
        let payload = DailyFitPipeline.generate(
            blueprint: bp, snapshot: snapshot, calibration: cal, dailyFitEngineId: engineId
        )
        let sp = payload.scalePresentation!
        #expect(sp.masculineFeminine != nil)
        #expect(sp.angularRounded != nil)
        #expect(sp.structuredDraped != nil)
        #expect(sp.masculineFeminine!.kind == .masculineFeminine)
        #expect(sp.angularRounded!.kind == .angularRounded)
        #expect(sp.structuredDraped!.kind == .structuredDraped)
    }

    @Test("S8: Legacy payloads without silhouette envelopes decode safely")
    func legacyPayloadDecodesSafely() throws {
        let presentation = PersonalScalePresentation(
            vibrancy: PersonalScaleEnvelope(
                kind: .vibrancy, floor: 0.0, ceiling: 0.72,
                baseline: 0.25, value: 0.4,
                displayPosition: 0.556, baselinePosition: 0.347
            ),
            contrast: PersonalScaleEnvelope(
                kind: .contrast, floor: 0.3, ceiling: 0.7,
                baseline: 0.5, value: 0.55,
                displayPosition: 0.625, baselinePosition: 0.5
            ),
            metalTone: PersonalScaleEnvelope(
                kind: .metalTone, floor: 0.2, ceiling: 0.9,
                baseline: 0.5, value: 0.6,
                displayPosition: 0.571, baselinePosition: 0.429
            ),
            masculineFeminine: nil,
            angularRounded: nil,
            structuredDraped: nil
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(presentation)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersonalScalePresentation.self, from: data)
        #expect(decoded.masculineFeminine == nil)
        #expect(decoded.angularRounded == nil)
        #expect(decoded.structuredDraped == nil)
        #expect(decoded.vibrancy == presentation.vibrancy)
    }

    @Test("S9: Vibrancy calibrated envelope span ≈ 0.44 for all baselines")
    func vibrancyCalibratedEnvelopeSpan() {
        let cal = EnvelopeFixtures.stage1Calibration
        let halfSpan = Stage1ScaleSensitivity.vibrancyPracticalHalfSpan

        for bp in [EnvelopeFixtures.briarBlueprint, EnvelopeFixtures.mediumBlueprint, EnvelopeFixtures.softBlueprint()] {
            let env = PersonalScaleEnvelopeCalculator.makePresentation(
                blueprint: bp, calibration: cal, mode: .stage1Experimental,
                vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
            )
            let span = env.vibrancy.ceiling - env.vibrancy.floor
            #expect(abs(span - halfSpan * 2) < 0.01 || span < halfSpan * 2,
                    "Vibrancy span \(span) should be ≈ \(halfSpan * 2) or less (clamped to [0,1])")
        }
    }
}
