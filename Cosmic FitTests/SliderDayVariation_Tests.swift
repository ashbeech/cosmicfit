//
//  SliderDayVariation_Tests.swift
//  Cosmic FitTests
//
//  CI gate: 12 named cohort profiles × 30 days — contrast and metalTone must
//  show meaningful day-over-day UI variation (continuous metal displayPosition).
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("Slider Day Variation — CI Gate")
struct SliderDayVariation_Tests {

    private static let profileIds = [
        "synth_124_libra_newyork",
        "synth_168_capricorn_london",
        "synth_009_aries_london",
        "synth_104_virgo_sydney",
        "synth_070_cancer_newyork",
        "synth_036_gemini_london",
        "synth_090_virgo_london",
        "synth_128_scorpio_sydney",
        "synth_018_taurus_london",
        "synth_072_leo_london",
        "synth_108_libra_london",
        "synth_051_gemini_london",
    ]

    private static let windowDays = 30
    private static let startDate = SkyForwardV2Support.date(year: 2026, month: 4, day: 23)

    @Test("12 profiles × 30 days: contrast and metalTone vary in UI")
    func cohortProfilesShowDayVariation() throws {
        let cal = SkyForwardV2Support.stage1Calibration
        let engineId = DailyFitEngineRegistry.stage1ExperimentalId

        let cohortPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("inspector/Resources/synthetic_cohort.json")
        let cohortRaw = try JSONSerialization.jsonObject(with: Data(contentsOf: cohortPath)) as! [[String: Any]]
        let cohortById = Dictionary(uniqueKeysWithValues: cohortRaw.map { ($0["id"] as! String, $0) })

        for profileId in Self.profileIds {
            guard let userDict = cohortById[profileId] else {
                Issue.record("Missing cohort profile: \(profileId)")
                continue
            }
            guard let userIdx = cohortRaw.firstIndex(where: { ($0["id"] as? String) == profileId }) else {
                Issue.record("Could not resolve index for \(profileId)")
                continue
            }

            let sunSign = userDict["sunSign"] as! String
            let signs = CohortChartSupportVariation.signsForUser(sunSign: sunSign, userIndex: userIdx)
            let chart = SkyForwardV2Support.chart(signs: signs)
            let bp = CohortChartSupportVariation.blueprint(forUserIndex: userIdx)

            var contrastUI: [Double] = []
            var metalUI: [Double] = []

            for dayOffset in 0..<Self.windowDays {
                let date = Self.startDate.addingTimeInterval(Double(dayOffset) * 86400)
                let transits = CohortChartSupportVariation.transits(
                    for: date, dayOffset: dayOffset, userSeed: userIdx
                )
                let moonPhase = SkyForwardV2Support.moonPhase(for: date, base: Self.startDate)

                let snapshot = DailyEnergyEngine.generateSnapshot(
                    natalChart: chart,
                    progressedChart: chart,
                    transits: transits,
                    moonPhaseDegrees: moonPhase,
                    profileHash: profileId,
                    date: date,
                    calibration: cal,
                    mode: .stage1Experimental,
                    dailyFitEngineId: engineId
                )

                let rawEssence = BlueprintLensEngine.resolveEssenceProfile(
                    from: snapshot, mode: .stage1Experimental
                )
                let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                    from: bp, snapshot: snapshot, calibration: cal, mode: .stage1Experimental
                )
                let (plan, _) = DailyNarrativeSelector.select(
                    snapshot: snapshot, blueprint: bp, calibration: cal,
                    precomputedEssence: rawEssence, precomputedSilhouette: rawSilhouette
                )
                let payload = BlueprintLensEngine.generatePayloadFromPlan(
                    plan: plan, blueprint: bp, snapshot: snapshot,
                    calibration: cal, mode: .stage1Experimental, dailyFitEngineId: engineId
                )

                guard let sp = payload.scalePresentation else {
                    Issue.record("\(profileId): scalePresentation nil on day \(dayOffset)")
                    continue
                }

                contrastUI.append(sp.contrast.displayPosition)
                metalUI.append(sp.metalTone.displayPosition)
            }

            let contrastDistinct = Set(contrastUI.map { String(format: "%.3f", $0) }).count
            let metalDistinct = Set(metalUI.map { String(format: "%.3f", $0) }).count
            let contrastMaxStreak = Self.maxUnchangedStreak(contrastUI)
            let metalMaxStreak = Self.maxUnchangedStreak(metalUI)

            #expect(contrastDistinct >= 3,
                    "\(profileId): contrast needs ≥3 distinct UI positions; got \(contrastDistinct)")
            #expect(metalDistinct >= 3,
                    "\(profileId): metalTone needs ≥3 distinct UI positions; got \(metalDistinct)")
            #expect(contrastMaxStreak < 10,
                    "\(profileId): contrast max unchanged streak \(contrastMaxStreak) must be < 10")
            #expect(metalMaxStreak < 10,
                    "\(profileId): metalTone max unchanged streak \(metalMaxStreak) must be < 10")
        }
    }

    private static func maxUnchangedStreak(_ values: [Double], eps: Double = 1e-9) -> Int {
        guard values.count >= 2 else { return values.count }
        var best = 1
        var current = 1
        for i in 1..<values.count {
            if abs(values[i] - values[i - 1]) <= eps {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }
}

// MARK: - Cohort support (mirrors SliderRangeAudit_Tests)

private enum CohortChartSupportVariation {

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

    static let signNames = [
        "aries", "taurus", "gemini", "cancer", "leo", "virgo",
        "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
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
            ["silver", "platinum"],
            ["gold", "silver"],
            ["gold", "brass"],
            ["silver", "steel"],
            ["gold", "copper"],
            ["platinum", "silver"],
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
