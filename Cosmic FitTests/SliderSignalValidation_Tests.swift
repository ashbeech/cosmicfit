//
//  SliderSignalValidation_Tests.swift
//  Cosmic FitTests
//
//  Quick validation: exercises contrast + M/F slider computations on a 12-user
//  mini-cohort (one per zodiac sign) × 60 days. Validates that axis speed damping,
//  contrast signal amplification, and M/F tempo driver produce improved range/stuck %.
//  Runs in seconds (no tarot/narrative pipeline overhead).
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Inline cohort support (self-contained, mirrors CohortChartSupport)

private enum QuickCohort {

    static let signNames = [
        "aries", "taurus", "gemini", "cancer", "leo", "virgo",
        "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"
    ]

    static let sunSignCharts: [[Int]] = [
        [1, 5, 1, 4, 9, 10, 9, 12, 6, 3],
        [2, 6, 2, 5, 10, 11, 10, 1, 7, 4],
        [3, 7, 3, 6, 11, 12, 11, 2, 8, 5],
        [4, 8, 4, 7, 12, 1, 12, 3, 9, 6],
        [5, 9, 5, 8, 1, 2, 1, 4, 10, 7],
        [6, 10, 6, 9, 2, 3, 2, 5, 11, 8],
        [7, 11, 7, 10, 3, 4, 3, 6, 12, 9],
        [8, 12, 8, 11, 4, 5, 4, 7, 1, 10],
        [9, 1, 9, 12, 5, 6, 5, 8, 2, 11],
        [10, 2, 10, 1, 6, 7, 6, 9, 3, 12],
        [11, 3, 11, 2, 7, 8, 7, 10, 4, 1],
        [12, 4, 12, 3, 8, 9, 8, 11, 5, 2],
    ]

    static func signsForUser(sunSign: String, userIndex: Int) -> [Int] {
        guard let signIdx = signNames.firstIndex(of: sunSign.lowercased()) else {
            return sunSignCharts[0]
        }
        var signs = sunSignCharts[signIdx]
        let offset = userIndex % 3
        if offset > 0 {
            for i in 1..<signs.count {
                signs[i] = ((signs[i] - 1 + offset) % 12) + 1
            }
        }
        return signs
    }

    static func transits(for date: Date, dayOffset: Int, userSeed: Int) -> [NatalChartCalculator.TransitAspect] {
        let seedShift = Double(userSeed % 7) * 0.1
        let orbShift = Double(dayOffset % 5) * 0.12 + seedShift
        let dayPhase = dayOffset % 12
        let userPhase = userSeed % 5

        let allConfigs: [(String, String, String, Double, Int?)] = [
            ("Neptune", "Moon", "square", max(0.8, 1.2 - orbShift), 8 + (dayOffset % 4)),
            ("Moon", "Sun", "trine", 1.2 + Double(dayOffset % 3) * 0.4, 4 + (dayOffset % 8)),
            ("Mars", "Venus", "conjunction", 0.9 + orbShift, 1 + ((userSeed + dayOffset) % 11)),
            ("Venus", "Mercury", "sextile", 1.5 + Double(dayOffset % 4) * 0.3, (userSeed + dayOffset * 2) % 12 + 1),
            ("Jupiter", "Saturn", "opposition", 2.0 - orbShift * 0.5, 12 - (dayOffset % 6)),
            ("Saturn", "Mercury", "square", 1.4 + Double(dayOffset % 7) * 0.15, (dayOffset + userSeed) % 12 + 1),
            ("Uranus", "Sun", "trine", 1.0 + Double(dayPhase) * 0.12, (dayOffset * 3 + userPhase) % 12 + 1),
            ("Pluto", "Moon", "square", 1.3 + Double(userPhase) * 0.2, (dayOffset + 3) % 12 + 1),
            ("Mars", "Saturn", "opposition", 1.5 + orbShift * 0.3, (dayOffset * 2 + userSeed) % 12 + 1),
            ("Venus", "Sun", "conjunction", 0.8 + Double(dayOffset % 6) * 0.15, (dayOffset + userPhase * 2) % 12 + 1),
        ]

        let startIdx = (dayPhase + userPhase) % 4
        let count = 5 + (dayOffset % 3)
        let selected = (0..<count).map { i in allConfigs[(startIdx + i) % allConfigs.count] }

        return selected.map { cfg in
            NatalChartCalculator.TransitAspect(
                transitPlanet: cfg.0, transitPlanetSymbol: "•",
                natalPlanet: cfg.1, natalPlanetSymbol: "•",
                aspectType: cfg.2, aspectSymbol: "•",
                orb: cfg.3, applying: (dayOffset + userSeed) % 4 != 0,
                effectiveFrom: date,
                effectiveTo: date.addingTimeInterval(86400 * 5),
                description: "\(cfg.0) \(cfg.2) \(cfg.1)",
                category: .shortTerm,
                transitZodiacSign: cfg.4
            )
        }
    }

    private static func colour(_ name: String, _ hex: String, _ role: ColourRole) -> BlueprintColour {
        BlueprintColour(
            name: name, hexValue: hex, role: role,
            provenance: .v4Template(family: "Synth", band: role.rawValue, index: 0)
        )
    }

    static func blueprint(forUserIndex idx: Int) -> CosmicBlueprint {
        let variant = idx % 6
        let saturation: Saturation = [.soft, .muted, .rich, .soft, .muted, .rich][variant]
        let contrast: ContrastLevel = [.low, .medium, .high, .medium, .high, .low][variant]
        let temperature: Temperature = [.cool, .neutral, .warm, .warm, .cool, .neutral][variant]
        let surface: SurfaceQuality = [.soft, .structured, .soft, .structured, .soft, .structured][variant]
        let metals: [String] = [
            ["silver", "platinum"], ["gold", "silver"], ["gold", "brass"],
            ["silver", "steel"], ["gold", "copper"], ["platinum", "silver"],
        ][variant]

        let palette = PaletteSection(
            neutrals: [colour("Neutral", "#808080", .neutral)],
            coreColours: [colour("Core", "#446688", .core)],
            accentColours: [colour("Accent", "#FF6644", .accent)],
            supportColours: nil,
            family: .trueWinter, cluster: .deepCoolControlled,
            variables: DerivedVariables(
                depth: .medium, temperature: temperature,
                saturation: saturation, contrast: contrast,
                surface: surface
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Cohort test."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "Test", generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Test."),
            textures: TexturesSection(
                goodText: "G.", badText: "B.", sweetSpotText: "S.",
                recommendedTextures: ["silk", "cotton"], avoidTextures: [], sweetSpotKeywords: []
            ),
            palette: palette,
            occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
            hardware: HardwareSection(
                metalsText: "M.", stonesText: "S.", tipText: "T.",
                recommendedMetals: metals, recommendedStones: []
            ),
            code: CodeSection(leanInto: ["structured", "classic"], avoid: ["edgy"], consider: ["minimal"]),
            accessory: AccessorySection(paragraphs: []),
            pattern: PatternSection(
                narrativeText: "P.", tipText: "T.",
                recommendedPatterns: ["stripes", "checks"], avoidPatterns: []
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }
}

// MARK: - Test

@Suite("Slider Signal Validation — Quick Cohort")
struct SliderSignalValidation_Tests {

    @Test("12-user × 60-day slider metrics (contrast + M/F improvement)")
    func validateSliderSignalImprovements() throws {
        let days = 60
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        let cal = SkyForwardV2Support.stage1Calibration

        var sliderDisplayPositions: [String: [[Double]]] = [
            "contrast": [], "masculineFeminine": [],
            "angularRounded": [], "structuredDraped": [],
            "metalTone": []
        ]

        for userIdx in 0..<12 {
            let sunSign = QuickCohort.signNames[userIdx]
            let signs = QuickCohort.signsForUser(sunSign: sunSign, userIndex: userIdx)
            let chart = SkyForwardV2Support.chart(signs: signs)
            let bp = QuickCohort.blueprint(forUserIndex: userIdx)

            var userContrast: [Double] = []
            var userMF: [Double] = []
            var userAR: [Double] = []
            var userSD: [Double] = []
            var userMetal: [Double] = []

            for dayOffset in 0..<days {
                let date = start.addingTimeInterval(Double(dayOffset) * 86400)
                let transits = QuickCohort.transits(for: date, dayOffset: dayOffset, userSeed: userIdx)
                let moonPhase = SkyForwardV2Support.moonPhase(for: date, base: start)

                let snapshot = DailyEnergyEngine.generateSnapshot(
                    natalChart: chart,
                    progressedChart: chart,
                    transits: transits,
                    moonPhaseDegrees: moonPhase,
                    profileHash: "quick_\(userIdx)",
                    date: date,
                    calibration: cal,
                    mode: .stage1Experimental,
                    dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
                )

                let contrast = BlueprintLensEngine.computeStage1ContrastRaw(
                    palette: bp.palette, snapshot: snapshot, calibration: cal
                )
                let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                    from: bp, snapshot: snapshot, calibration: cal, mode: .stage1Experimental
                )
                let metalTone = BlueprintLensEngine.deriveMetalTonePublic(
                    from: bp, snapshot: snapshot, calibration: cal, mode: .stage1Experimental
                )

                let presentation = PersonalScaleEnvelopeCalculator.makePresentation(
                    blueprint: bp, calibration: cal, mode: .stage1Experimental,
                    vibrancy: 0.5, contrast: contrast, metalTone: metalTone,
                    silhouette: silhouette
                )

                userContrast.append(presentation.contrast.displayPosition)
                userMF.append(presentation.masculineFeminine!.displayPosition)
                userAR.append(presentation.angularRounded!.displayPosition)
                userSD.append(presentation.structuredDraped!.displayPosition)
                userMetal.append(presentation.metalTone.displayPosition)
            }

            sliderDisplayPositions["contrast"]!.append(userContrast)
            sliderDisplayPositions["masculineFeminine"]!.append(userMF)
            sliderDisplayPositions["angularRounded"]!.append(userAR)
            sliderDisplayPositions["structuredDraped"]!.append(userSD)
            sliderDisplayPositions["metalTone"]!.append(userMetal)
        }

        print("\n══════════ SLIDER SIGNAL VALIDATION (12 users × 60 days) ══════════")
        let sliderNames = ["contrast", "metalTone", "masculineFeminine", "angularRounded", "structuredDraped"]

        for slider in sliderNames {
            let allUsers = sliderDisplayPositions[slider]!
            let ranges = allUsers.map { vals in (vals.max()! - vals.min()!) }
            let meanRange = ranges.reduce(0, +) / Double(ranges.count)
            let stuckCount = ranges.filter { $0 < 0.33 }.count
            let pctStuck = Double(stuckCount) / Double(ranges.count) * 100
            let pctLt05 = Double(ranges.filter { $0 < 0.5 }.count) / Double(ranges.count) * 100

            print("  \(slider.padding(toLength: 20, withPad: " ", startingAt: 0)) meanRange=\(String(format: "%.3f", meanRange))  stuck=\(String(format: "%.0f", pctStuck))%  rangeLt0.5=\(String(format: "%.0f", pctLt05))%")
        }
        print("═══════════════════════════════════════════════════════════════════\n")

        let contrastRanges = sliderDisplayPositions["contrast"]!.map { $0.max()! - $0.min()! }
        let mfRanges = sliderDisplayPositions["masculineFeminine"]!.map { $0.max()! - $0.min()! }
        let arRanges = sliderDisplayPositions["angularRounded"]!.map { $0.max()! - $0.min()! }
        let sdRanges = sliderDisplayPositions["structuredDraped"]!.map { $0.max()! - $0.min()! }

        let contrastMean = contrastRanges.reduce(0, +) / Double(contrastRanges.count)
        let mfMean = mfRanges.reduce(0, +) / Double(mfRanges.count)
        let arMean = arRanges.reduce(0, +) / Double(arRanges.count)
        let sdMean = sdRanges.reduce(0, +) / Double(sdRanges.count)

        let contrastStuck = Double(contrastRanges.filter { $0 < 0.33 }.count) / Double(contrastRanges.count) * 100
        let mfStuck = Double(mfRanges.filter { $0 < 0.33 }.count) / Double(mfRanges.count) * 100

        #expect(contrastMean > 0.40,
                "Contrast meanRange \(String(format: "%.3f", contrastMean)) should exceed 0.40 (was 0.361)")
        #expect(contrastStuck < 20,
                "Contrast stuck \(String(format: "%.0f", contrastStuck))% should be < 20% (was 30%)")

        #expect(mfMean > 0.40,
                "M/F meanRange \(String(format: "%.3f", mfMean)) should exceed 0.40 (was 0.334)")
        #expect(mfStuck < 25,
                "M/F stuck \(String(format: "%.0f", mfStuck))% should be < 25% (was 44%)")

        #expect(arMean > 0.45,
                "AR meanRange \(String(format: "%.3f", arMean)) should remain > 0.45")
        #expect(sdMean > 0.45,
                "SD meanRange \(String(format: "%.3f", sdMean)) should remain > 0.45")
    }
}
