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

    @Test("P1: Contrast medium baseline + Stage 1 — floor/ceiling match §6.2 ±0.001")
    func contrastMediumStage1() {
        let cal = EnvelopeFixtures.stage1Calibration
        let coeff = cal.stage2Sensitivity.contrastCoeff // 0.55
        let presentation = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint,
            calibration: cal,
            mode: .stage1Experimental,
            vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        let env = presentation.contrast
        #expect(env.baseline == 0.50)
        let expectedFloor = max(0.0, 0.50 + (-Stage1ScaleSensitivity.contrastMaxBlendNorm * coeff))
        let expectedCeiling = min(1.0, 0.50 + (Stage1ScaleSensitivity.contrastMaxBlendNorm * coeff))
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

        // Stage 1: wide modulation (±0.92) clamps both floors to 0;
        // difference shows in baseline and baselinePosition
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

    @Test("P10: Envelope ceiling is analytical max — soften caps apply only at runtime via ScaleDirective")
    func envelopeCeilingIsAnalyticalMax() {
        let cal = EnvelopeFixtures.stage1Calibration
        let coeff = cal.stage2Sensitivity.contrastCoeff

        // Briar (high contrast, baseline 0.75): ceiling = 0.75 + 0.50*coeff = 1.025 → clamped to 1.0
        let briarEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.briarBlueprint, calibration: cal,
            mode: .stage1Experimental, vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        let expectedBriarCeiling = min(1.0, 0.75 + Stage1ScaleSensitivity.contrastMaxBlendNorm * coeff)
        #expect(abs(briarEnv.contrast.ceiling - expectedBriarCeiling) < 0.001,
                "Briar contrast ceiling \(briarEnv.contrast.ceiling) should be analytical max \(expectedBriarCeiling)")
        #expect(briarEnv.contrast.ceiling > 0.70,
                "Contrast ceiling must exceed softenContrastCap (0.70) — cap is runtime-only")

        // Vibrancy (rich, baseline 0.75): analytical max clamps to 1.0
        #expect(briarEnv.vibrancy.ceiling == 1.0,
                "Vibrancy ceiling \(briarEnv.vibrancy.ceiling) should be 1.0 (analytical max clamped)")
        // Vibrancy floor for rich baseline: 0.75 + minMod ≈ 0.75 - 0.92 → clamped to 0.0
        #expect(briarEnv.vibrancy.floor == 0.0)

        // Medium blueprint vibrancy: floor=0, ceiling=1.0 (no soften cap)
        let medEnv = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: EnvelopeFixtures.mediumBlueprint, calibration: cal,
            mode: .stage1Experimental, vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
        )
        #expect(medEnv.vibrancy.ceiling == 1.0,
                "Muted vibrancy ceiling \(medEnv.vibrancy.ceiling) should be 1.0 (full analytical range)")
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
