//
//  SliderRangeAudit_Tests.swift
//  Cosmic FitTests
//
//  Comprehensive slider range audit: for each slider outputs raw value range,
//  baseline-relative delta range, envelope span, display-position range,
//  clamp rate, and actual UI marker range (post-snap for metal).
//  Generates docs/fixtures/slider_range_audit.json.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("Slider Range Audit — Full Diagnostic")
struct SliderRangeAudit_Tests {

    private struct SliderDayRecord {
        let rawValue: Double
        let baseline: Double
        let floor: Double
        let ceiling: Double
        let displayPosition: Double
        let uiMarkerPosition: Double
    }

    private struct SliderUserSummary {
        let rawMin: Double
        let rawMax: Double
        let rawRange: Double
        let baseline: Double
        let baselineDeltaMin: Double
        let baselineDeltaMax: Double
        let baselineDeltaRange: Double
        let envelopeSpan: Double
        let dpMin: Double
        let dpMax: Double
        let dpRange: Double
        let clampFloorCount: Int
        let clampCeilingCount: Int
        let clampRate: Double
        let uiMarkerMin: Double
        let uiMarkerMax: Double
        let uiMarkerRange: Double
        let uiMarkerDistinct: Int
        let totalDays: Int
    }

    private static let sliderNames = [
        "vibrancy", "contrast", "metalTone",
        "masculineFeminine", "angularRounded", "structuredDraped"
    ]

    @Test("Generate slider_range_audit fixture (216 users × 60 days)")
    func generateSliderRangeAudit() throws {
        let days = 60
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        let cal = SkyForwardV2Support.stage1Calibration
        let engineId = DailyFitEngineRegistry.stage1ExperimentalId

        let cohortPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("inspector/Resources/synthetic_cohort.json")
        let cohortData = try Data(contentsOf: cohortPath)
        let cohortRaw = try JSONSerialization.jsonObject(with: cohortData) as! [[String: Any]]

        var allUserSummaries: [String: [String: SliderUserSummary]] = [:]

        for (userIdx, userDict) in cohortRaw.enumerated() {
            let userId = userDict["id"] as! String
            let sunSign = userDict["sunSign"] as! String
            let signs = CohortChartSupportAudit.signsForUser(sunSign: sunSign, userIndex: userIdx)
            let chart = SkyForwardV2Support.chart(signs: signs)
            let bp = CohortChartSupportAudit.blueprint(forUserIndex: userIdx)

            var sliderRecords: [String: [SliderDayRecord]] = [:]
            for name in Self.sliderNames { sliderRecords[name] = [] }

            for dayOffset in 0..<days {
                let date = start.addingTimeInterval(Double(dayOffset) * 86400)
                let transits = CohortChartSupportAudit.transits(for: date, dayOffset: dayOffset, userSeed: userIdx)
                let moonPhase = SkyForwardV2Support.moonPhase(for: date, base: start)

                let snapshot = DailyEnergyEngine.generateSnapshot(
                    natalChart: chart,
                    progressedChart: chart,
                    transits: transits,
                    moonPhaseDegrees: moonPhase,
                    profileHash: userId,
                    date: date,
                    calibration: cal,
                    mode: .stage1Experimental,
                    dailyFitEngineId: engineId
                )

                let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
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

                guard let sp = payload.scalePresentation else { continue }

                let metalDp = sp.metalTone.displayPosition

                sliderRecords["vibrancy"]!.append(SliderDayRecord(
                    rawValue: payload.vibrancy,
                    baseline: sp.vibrancy.baseline,
                    floor: sp.vibrancy.floor,
                    ceiling: sp.vibrancy.ceiling,
                    displayPosition: sp.vibrancy.displayPosition,
                    uiMarkerPosition: sp.vibrancy.displayPosition
                ))
                sliderRecords["contrast"]!.append(SliderDayRecord(
                    rawValue: payload.contrast,
                    baseline: sp.contrast.baseline,
                    floor: sp.contrast.floor,
                    ceiling: sp.contrast.ceiling,
                    displayPosition: sp.contrast.displayPosition,
                    uiMarkerPosition: sp.contrast.displayPosition
                ))
                sliderRecords["metalTone"]!.append(SliderDayRecord(
                    rawValue: payload.metalTone,
                    baseline: sp.metalTone.baseline,
                    floor: sp.metalTone.floor,
                    ceiling: sp.metalTone.ceiling,
                    displayPosition: metalDp,
                    uiMarkerPosition: DailyFitViewController.snapMetalToThreePositions(metalDp)
                ))
                if let mf = sp.masculineFeminine {
                    sliderRecords["masculineFeminine"]!.append(SliderDayRecord(
                        rawValue: payload.silhouetteProfile.masculineFeminine,
                        baseline: mf.baseline,
                        floor: mf.floor,
                        ceiling: mf.ceiling,
                        displayPosition: mf.displayPosition,
                        uiMarkerPosition: mf.displayPosition
                    ))
                }
                if let ar = sp.angularRounded {
                    sliderRecords["angularRounded"]!.append(SliderDayRecord(
                        rawValue: payload.silhouetteProfile.angularRounded,
                        baseline: ar.baseline,
                        floor: ar.floor,
                        ceiling: ar.ceiling,
                        displayPosition: ar.displayPosition,
                        uiMarkerPosition: ar.displayPosition
                    ))
                }
                if let sd = sp.structuredDraped {
                    sliderRecords["structuredDraped"]!.append(SliderDayRecord(
                        rawValue: payload.silhouetteProfile.structuredDraped,
                        baseline: sd.baseline,
                        floor: sd.floor,
                        ceiling: sd.ceiling,
                        displayPosition: sd.displayPosition,
                        uiMarkerPosition: sd.displayPosition
                    ))
                }
            }

            var userSliders: [String: SliderUserSummary] = [:]
            for name in Self.sliderNames {
                guard let records = sliderRecords[name], !records.isEmpty else { continue }
                let rawValues = records.map(\.rawValue)
                let baselines = records.map(\.baseline)
                let floors = records.map(\.floor)
                let ceilings = records.map(\.ceiling)
                let dps = records.map(\.displayPosition)
                let uis = records.map(\.uiMarkerPosition)

                let baseline = baselines[0]
                let deltas = rawValues.map { $0 - baseline }

                let clampFloor = dps.filter { $0 < 0.001 }.count
                let clampCeiling = dps.filter { $0 > 0.999 }.count
                let clampRate = Double(clampFloor + clampCeiling) / Double(records.count)

                let uiDistinct = Set(uis.map { String(format: "%.3f", $0) }).count

                userSliders[name] = SliderUserSummary(
                    rawMin: rawValues.min()!,
                    rawMax: rawValues.max()!,
                    rawRange: rawValues.max()! - rawValues.min()!,
                    baseline: baseline,
                    baselineDeltaMin: deltas.min()!,
                    baselineDeltaMax: deltas.max()!,
                    baselineDeltaRange: deltas.max()! - deltas.min()!,
                    envelopeSpan: ceilings[0] - floors[0],
                    dpMin: dps.min()!,
                    dpMax: dps.max()!,
                    dpRange: dps.max()! - dps.min()!,
                    clampFloorCount: clampFloor,
                    clampCeilingCount: clampCeiling,
                    clampRate: clampRate,
                    uiMarkerMin: uis.min()!,
                    uiMarkerMax: uis.max()!,
                    uiMarkerRange: uis.max()! - uis.min()!,
                    uiMarkerDistinct: uiDistinct,
                    totalDays: records.count
                )
            }
            allUserSummaries[userId] = userSliders
        }

        // Compute aggregate per slider
        var aggregate: [String: [String: Any]] = [:]
        for name in Self.sliderNames {
            let userSums = allUserSummaries.values.compactMap { $0[name] }
            guard !userSums.isEmpty else { continue }
            let n = Double(userSums.count)

            let meanRawRange = userSums.map(\.rawRange).reduce(0, +) / n
            let meanBaselineDeltaRange = userSums.map(\.baselineDeltaRange).reduce(0, +) / n
            let meanEnvelopeSpan = userSums.map(\.envelopeSpan).reduce(0, +) / n
            let meanDpRange = userSums.map(\.dpRange).reduce(0, +) / n
            let meanClampRate = userSums.map(\.clampRate).reduce(0, +) / n
            let meanUiMarkerRange = userSums.map(\.uiMarkerRange).reduce(0, +) / n
            let meanUiDistinct = Double(userSums.map(\.uiMarkerDistinct).reduce(0, +)) / n

            let pctStuckDp = Double(userSums.filter { $0.dpRange < 0.33 }.count) / n * 100
            let pctStuckUi = Double(userSums.filter { $0.uiMarkerRange < 0.33 }.count) / n * 100
            let pctClampAny = Double(userSums.filter { $0.clampRate > 0 }.count) / n * 100
            let pctClampHigh = Double(userSums.filter { $0.clampRate > 0.1 }.count) / n * 100

            let sortedDpRanges = userSums.map(\.dpRange).sorted()
            let p10DpRange = sortedDpRanges[Int(n * 0.1)]
            let p50DpRange = sortedDpRanges[Int(n * 0.5)]
            let p90DpRange = sortedDpRanges[Int(n * 0.9)]

            let sortedRawRanges = userSums.map(\.rawRange).sorted()
            let p50RawRange = sortedRawRanges[Int(n * 0.5)]

            let utilization = meanRawRange / meanEnvelopeSpan

            aggregate[name] = [
                "nUsers": userSums.count,
                "meanRawRange": round6(meanRawRange),
                "p50RawRange": round6(p50RawRange),
                "meanBaselineDeltaRange": round6(meanBaselineDeltaRange),
                "meanEnvelopeSpan": round6(meanEnvelopeSpan),
                "envelopeUtilization": round6(utilization),
                "meanDisplayPositionRange": round6(meanDpRange),
                "p10DpRange": round6(p10DpRange),
                "p50DpRange": round6(p50DpRange),
                "p90DpRange": round6(p90DpRange),
                "meanClampRate": round6(meanClampRate),
                "pctUsersClampAny": round1(pctClampAny),
                "pctUsersClampHigh": round1(pctClampHigh),
                "meanUiMarkerRange": round6(meanUiMarkerRange),
                "meanUiDistinctPositions": round1(meanUiDistinct),
                "pctStuckOneTertile_dp": round1(pctStuckDp),
                "pctStuckOneTertile_ui": round1(pctStuckUi),
            ] as [String: Any]
        }

        // Write JSON fixture
        let report: [String: Any] = [
            "generated": SkyForwardV2Support.isoString(for: Date()),
            "engine": "stage1_experimental",
            "cohort": "synthetic_cohort",
            "nUsers": allUserSummaries.count,
            "window": ["start": "2026-05-01", "days": 60] as [String: Any],
            "aggregate": aggregate,
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])

        // Write using absolute path (same location as narrative_cohesion_report.json)
        let fixturesDir = URL(fileURLWithPath: "/Users/ash/dev/mobile_apps/cosmicfit/docs/fixtures")
        try FileManager.default.createDirectory(at: fixturesDir, withIntermediateDirectories: true)
        let jsonPath = fixturesDir.appendingPathComponent("slider_range_audit.json")
        try jsonData.write(to: jsonPath)

        // Write TXT summary
        var txt = "Slider Range Audit — Full Diagnostic\n"
        txt += "Engine: stage1_experimental | 216 users × 60 days | 2026-05-01\n"
        txt += String(repeating: "═", count: 90) + "\n\n"

        for name in Self.sliderNames {
            guard let agg = aggregate[name] as? [String: Any] else { continue }
            txt += "┌─ \(name.uppercased()) \(String(repeating: "─", count: max(0, 70 - name.count)))\n"
            txt += "│ Raw value range (mean):          \(fmt(agg["meanRawRange"]))\n"
            txt += "│ Raw value range (p50):           \(fmt(agg["p50RawRange"]))\n"
            txt += "│ Baseline-relative delta (mean):  \(fmt(agg["meanBaselineDeltaRange"]))\n"
            txt += "│ Envelope span (mean):            \(fmt(agg["meanEnvelopeSpan"]))\n"
            txt += "│ Envelope utilization:            \(fmt(agg["envelopeUtilization"]))\n"
            txt += "│ Display position range (mean):   \(fmt(agg["meanDisplayPositionRange"]))\n"
            txt += "│ Display position range (p10/p50/p90): \(fmt(agg["p10DpRange"]))/\(fmt(agg["p50DpRange"]))/\(fmt(agg["p90DpRange"]))\n"
            txt += "│ Clamp rate (mean):               \(fmt(agg["meanClampRate"]))\n"
            txt += "│ Users with any clamping:         \(fmt(agg["pctUsersClampAny"]))%\n"
            txt += "│ Users with >10% clamping:        \(fmt(agg["pctUsersClampHigh"]))%\n"
            txt += "│ UI marker range (mean):          \(fmt(agg["meanUiMarkerRange"]))\n"
            txt += "│ UI distinct positions (mean):    \(fmt(agg["meanUiDistinctPositions"]))\n"
            txt += "│ Stuck one tertile (dp):          \(fmt(agg["pctStuckOneTertile_dp"]))%\n"
            txt += "│ Stuck one tertile (UI):          \(fmt(agg["pctStuckOneTertile_ui"]))%\n"
            txt += "└\(String(repeating: "─", count: 88))\n\n"
        }

        txt += String(repeating: "═", count: 90) + "\n"
        txt += "DIAGNOSIS SUMMARY\n\n"
        txt += "Bottleneck key: [E]=Envelope [S]=Signal [U]=UI [C]=Coherence cap\n\n"

        for name in Self.sliderNames {
            guard let agg = aggregate[name] as? [String: Any] else { continue }
            let dpRange = (agg["meanDisplayPositionRange"] as? Double) ?? 0
            let uiRange = (agg["meanUiMarkerRange"] as? Double) ?? 0
            let util = (agg["envelopeUtilization"] as? Double) ?? 0
            let clamp = (agg["meanClampRate"] as? Double) ?? 0

            var bottlenecks: [String] = []
            if util < 0.5 { bottlenecks.append("[E] envelope too wide for actual signal") }
            if dpRange < 0.4 { bottlenecks.append("[S] weak daily signal variation") }
            if uiRange < dpRange * 0.8 { bottlenecks.append("[U] UI snap compresses range") }
            if clamp > 0.05 { bottlenecks.append("[E] envelope too narrow (clamping)") }

            let status = dpRange >= 0.5 ? "OK" : (dpRange >= 0.35 ? "WEAK" : "POOR")
            txt += "  \(name.padding(toLength: 20, withPad: " ", startingAt: 0)) [\(status)] "
            txt += bottlenecks.isEmpty ? "— no major bottleneck" : bottlenecks.joined(separator: " + ")
            txt += "\n"
        }

        let txtPath = fixturesDir.appendingPathComponent("slider_range_audit.txt")
        try txt.write(to: txtPath, atomically: true, encoding: .utf8)

        // Basic assertions
        let vibrancyDp = (aggregate["vibrancy"]?["meanDisplayPositionRange"] as? Double) ?? 0
        #expect(vibrancyDp > 0.5, "Vibrancy should maintain good travel after Plan 3 calibration")
    }

    private func round6(_ value: Double) -> Double {
        (value * 1_000_000).rounded() / 1_000_000
    }

    private func round1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private func fmt(_ value: Any?) -> String {
        guard let v = value as? Double else { return "?" }
        return String(format: "%.4f", v)
    }
}

// MARK: - Cohort support (shared with NarrativeCohesionReport_Tests)

private enum CohortChartSupportAudit {

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
        "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"
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
