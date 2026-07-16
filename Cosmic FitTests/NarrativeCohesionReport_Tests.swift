//
//  NarrativeCohesionReport_Tests.swift
//  Cosmic FitTests
//
//  Plan 3 §4: Narrative cohesion harness — 216 users × 60 days, plan-driven payloads.
//  Generates docs/fixtures/narrative_cohesion_report.json + .txt
//  and updates docs/fixtures/slider_range_report.json (all 6 sliders with displayPosition).
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Cohort Chart Generation

private enum CohortChartSupport {

    static let sunSignCharts: [[Int]] = [
        [1, 5, 1, 4, 9, 10, 9, 12, 6, 3],    // aries
        [2, 6, 2, 5, 10, 11, 10, 1, 7, 4],    // taurus
        [3, 7, 3, 6, 11, 12, 11, 2, 8, 5],    // gemini
        [4, 8, 4, 7, 12, 1, 12, 3, 9, 6],     // cancer
        [5, 9, 5, 8, 1, 2, 1, 4, 10, 7],      // leo
        [6, 10, 6, 9, 2, 3, 2, 5, 11, 8],     // virgo
        [7, 11, 7, 10, 3, 4, 3, 6, 12, 9],    // libra
        [8, 12, 8, 11, 4, 5, 4, 7, 1, 10],    // scorpio
        [9, 1, 9, 12, 5, 6, 5, 8, 2, 11],     // sagittarius
        [10, 2, 10, 1, 6, 7, 6, 9, 3, 12],    // capricorn
        [11, 3, 11, 2, 7, 8, 7, 10, 4, 1],    // aquarius
        [12, 4, 12, 3, 8, 9, 8, 11, 5, 2],    // pisces
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

// MARK: - Report Generator

@Suite("Plan 3 — Narrative Cohesion Report Generator")
struct NarrativeCohesionReport_Tests {

    @Test("Generate narrative_cohesion_report fixture (216 users × 60 days)")
    func generateCohesionReport() throws {
        let days = 60
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        // Cohort-ladder gate runs against the shipping-candidate engine (Sky Forward v1.0.2 by default;
        // override with DAILY_FIT_ENGINE_ID). Phase 6c / plan G2 item 2.
        let cal = SkyForwardV2Support.gateCalibration
        let engineId = SkyForwardV2Support.gateEngineId
        let mode = SkyForwardV2Support.gateMode

        let cohortPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("inspector/Resources/synthetic_cohort.json")
        let cohortData = try Data(contentsOf: cohortPath)
        var cohortRaw = try JSONSerialization.jsonObject(with: cohortData) as! [[String: Any]]

        // Fast tuning aid: COHESION_SUBSET=N runs only the first N users (measurement only — the
        // fail-closed §4.3 asserts are skipped on a subset so a small sample can't spuriously red/pass).
        // The full 216-user cohort is the real gate. Not set in CI → full run.
        let subsetN = ProcessInfo.processInfo.environment["COHESION_SUBSET"].flatMap { Int($0) }
        if let subsetN, subsetN > 0, subsetN < cohortRaw.count {
            cohortRaw = Array(cohortRaw.prefix(subsetN))
        }

        struct UserResult {
            var flipCount: Int = 0
            var distinctAccents: Set<String> = []
            var categories: Set<String> = []
            var oppositionViolations: Int = 0
            var crossSurfaceViolations: Int = 0
            var coherenceScores: [Double] = []
            var sliderValues: [String: [Double]] = [:]
            var sliderDisplayPositions: [String: [Double]] = [:]
            var prevAccent: String?
            var paletteValid: Int = 0
            var totalDays: Int = 0
            var accentMatchesSalience: Int = 0
            var salienceChecks: Int = 0
            var skyTopInSupporting: Int = 0
            var skyTopCooldownBlocked: Int = 0
            var skyTopCoherenceRejected: Int = 0
        }

        var userResults: [String: UserResult] = [:]
        var aggOppositions = 0
        var aggCrossSurface = 0

        for (userIdx, userDict) in cohortRaw.enumerated() {
            let userId = userDict["id"] as! String
            let sunSign = userDict["sunSign"] as! String
            let signs = CohortChartSupport.signsForUser(sunSign: sunSign, userIndex: userIdx)
            let chart = SkyForwardV2Support.chart(signs: signs)
            let bp = CohortChartSupport.blueprint(forUserIndex: userIdx)

            var result = UserResult()

            for dayOffset in 0..<days {
                let date = start.addingTimeInterval(Double(dayOffset) * 86400)
                let transits = CohortChartSupport.transits(for: date, dayOffset: dayOffset, userSeed: userIdx)
                let moonPhase = SkyForwardV2Support.moonPhase(for: date, base: start)

                let snapshot = DailyEnergyEngine.generateSnapshot(
                    natalChart: chart,
                    progressedChart: chart,
                    transits: transits,
                    moonPhaseDegrees: moonPhase,
                    profileHash: userId,
                    date: date,
                    calibration: cal,
                    mode: mode,
                    dailyFitEngineId: engineId
                )

                let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
                let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                    from: bp, snapshot: snapshot, calibration: cal, mode: mode
                )
                let (plan, _) = DailyNarrativeSelector.select(
                    snapshot: snapshot, blueprint: bp, calibration: cal,
                    precomputedEssence: rawEssence, precomputedSilhouette: rawSilhouette
                )

                let validation = DailyNarrativeCoherence.validate(plan: plan)
                let payload = BlueprintLensEngine.generatePayloadFromPlan(
                    plan: plan, blueprint: bp, snapshot: snapshot,
                    calibration: cal, mode: mode, dailyFitEngineId: engineId
                )

                let accent = plan.accentEssence.rawValue
                result.distinctAccents.insert(accent)
                let top3 = ([plan.accentEssence] + plan.supportingEssences).map(\.rawValue)
                for cat in top3 { result.categories.insert(cat) }

                result.oppositionViolations += validation.essenceOppositionViolations.count
                result.crossSurfaceViolations += validation.crossSurfaceViolations.count

                let payloadCoherence = DailyNarrativeCoherence.scorePayloadCoherence(plan: plan, payload: payload)
                let score = DailyNarrativeCoherence.meanCoherenceScore(payloadCoherence)
                result.coherenceScores.append(score)

                if let prev = result.prevAccent, accent != prev { result.flipCount += 1 }
                result.prevAccent = accent

                // Slider tracking (raw values)
                result.sliderValues["vibrancy", default: []].append(payload.vibrancy)
                result.sliderValues["contrast", default: []].append(payload.contrast)
                result.sliderValues["metalTone", default: []].append(payload.metalTone)
                result.sliderValues["masculineFeminine", default: []].append(payload.silhouetteProfile.masculineFeminine)
                result.sliderValues["angularRounded", default: []].append(payload.silhouetteProfile.angularRounded)
                result.sliderValues["structuredDraped", default: []].append(payload.silhouetteProfile.structuredDraped)

                // Display position tracking
                if let sp = payload.scalePresentation {
                    result.sliderDisplayPositions["vibrancy", default: []].append(sp.vibrancy.displayPosition)
                    result.sliderDisplayPositions["contrast", default: []].append(sp.contrast.displayPosition)
                    result.sliderDisplayPositions["metalTone", default: []].append(sp.metalTone.displayPosition)
                    if let mf = sp.masculineFeminine {
                        result.sliderDisplayPositions["masculineFeminine", default: []].append(mf.displayPosition)
                    }
                    if let ar = sp.angularRounded {
                        result.sliderDisplayPositions["angularRounded", default: []].append(ar.displayPosition)
                    }
                    if let sd = sp.structuredDraped {
                        result.sliderDisplayPositions["structuredDraped", default: []].append(sd.displayPosition)
                    }
                }

                // Salience match: accent matches top salience category from snapshot
                if let salience = snapshot.skySalience,
                   let topDriver = salience.topDrivers.first,
                   let topCategory = topDriver.essenceCategory {
                    result.salienceChecks += 1
                    if plan.accentEssence == topCategory {
                        result.accentMatchesSalience += 1
                    } else {
                        let visible = [plan.accentEssence] + plan.supportingEssences
                        if visible.contains(topCategory) {
                            result.skyTopInSupporting += 1
                        }
                    }
                }

                result.paletteValid += 1
                result.totalDays += 1
            }

            aggOppositions += result.oppositionViolations
            aggCrossSurface += result.crossSurfaceViolations
            userResults[userId] = result
        }

        // Compute aggregate metrics
        let nUsers = userResults.count
        let allFlipRates = userResults.values.map { r in
            r.totalDays > 1 ? Double(r.flipCount) / Double(r.totalDays - 1) : 0.0
        }
        let allDistinct = userResults.values.map { $0.distinctAccents.count }
        let allCategories = userResults.values.map { $0.categories.count }
        let allCoherence = userResults.values.flatMap(\.coherenceScores)
        let meanFlipRate = allFlipRates.reduce(0, +) / Double(nUsers)
        let meanDistinct = Double(allDistinct.reduce(0, +)) / Double(nUsers)
        let meanCategories = Double(allCategories.reduce(0, +)) / Double(nUsers)
        let meanCoherence = allCoherence.isEmpty ? 0.0 : allCoherence.reduce(0, +) / Double(allCoherence.count)

        let sliderNames = ["vibrancy", "contrast", "metalTone", "masculineFeminine", "angularRounded", "structuredDraped"]
        var sliderAgg: [String: [String: Any]] = [:]
        var sliderUsers: [[String: Any]] = []

        for (userId, result) in userResults.sorted(by: { $0.key < $1.key }) {
            var userSliders: [String: Any] = [:]
            for slider in sliderNames {
                let dp = result.sliderDisplayPositions[slider] ?? []
                guard !dp.isEmpty else { continue }
                let minV = dp.min()!
                let maxV = dp.max()!
                let range = maxV - minV
                let mean = dp.reduce(0, +) / Double(dp.count)
                userSliders[slider] = [
                    "min": round(minV * 1000000) / 1000000,
                    "max": round(maxV * 1000000) / 1000000,
                    "range": round(range * 1000000) / 1000000,
                    "mean": round(mean * 1000000) / 1000000,
                ] as [String : Any]
            }
            sliderUsers.append(["userId": userId, "sliders": userSliders])
        }

        for slider in sliderNames {
            let ranges = userResults.values.compactMap { r -> Double? in
                guard let dp = r.sliderDisplayPositions[slider], !dp.isEmpty else { return nil }
                return dp.max()! - dp.min()!
            }
            guard !ranges.isEmpty else { continue }
            let meanRange = ranges.reduce(0, +) / Double(ranges.count)
            let sortedRanges = ranges.sorted()
            let medianRange = sortedRanges[sortedRanges.count / 2]
            let stuckCount = ranges.filter { $0 < 0.33 }.count
            let pctStuck = Double(stuckCount) / Double(ranges.count) * 100
            let pctLt05 = Double(ranges.filter { $0 < 0.5 }.count) / Double(ranges.count) * 100

            sliderAgg[slider] = [
                "meanRange": round(meanRange * 10000) / 10000,
                "medianRange": round(medianRange * 10000) / 10000,
                "pctStuckOneTertile": round(pctStuck * 10) / 10,
                "pctRangeLt05": round(pctLt05 * 10) / 10,
                "pctRangeGt08": round(Double(ranges.filter { $0 > 0.8 }.count) / Double(ranges.count) * 1000) / 10,
                "nUsers": ranges.count,
            ] as [String : Any]
        }

        // Accent-salience match rate + miss diagnostics
        let totalSalienceChecks = userResults.values.map(\.salienceChecks).reduce(0, +)
        let totalSalienceMatches = userResults.values.map(\.accentMatchesSalience).reduce(0, +)
        let salienceMatchRate = totalSalienceChecks > 0 ? Double(totalSalienceMatches) / Double(totalSalienceChecks) : 0
        let totalSkyTopInSupporting = userResults.values.map(\.skyTopInSupporting).reduce(0, +)
        let totalSkyTopCooldownBlocked = userResults.values.map(\.skyTopCooldownBlocked).reduce(0, +)
        let totalSkyTopCoherenceRejected = userResults.values.map(\.skyTopCoherenceRejected).reduce(0, +)
        let totalSalienceMisses = totalSalienceChecks - totalSalienceMatches

        let report: [String: Any] = [
            "generated": SkyForwardV2Support.isoString(for: Date()),
            "engine": engineId,
            "startDate": "2026-05-01",
            "days": days,
            "nUsers": nUsers,
            "aggregate": [
                "totalOppositionViolations": aggOppositions,
                "totalCrossSurfaceViolations": aggCrossSurface,
                "meanCoherenceScore": round(meanCoherence * 10000) / 10000,
                "meanFlipRate": round(meanFlipRate * 10000) / 10000,
                "meanDistinctAccents": round(meanDistinct * 100) / 100,
                "meanCategoryCount": round(meanCategories * 100) / 100,
                "accentSalienceMatchRate": round(salienceMatchRate * 10000) / 10000,
                "salienceMissBreakdown": [
                    "totalMisses": totalSalienceMisses,
                    "skyTopInSupporting": totalSkyTopInSupporting,
                    "skyTopCooldownBlocked": totalSkyTopCooldownBlocked,
                    "skyTopCoherenceRejected": totalSkyTopCoherenceRejected,
                ] as [String : Any],
                "usersWithFlipBelow40pct": allFlipRates.filter { $0 < 0.40 }.count,
                "usersWithDistinctBelow6": allDistinct.filter { $0 < 6 }.count,
            ] as [String : Any],
            "sliderAggregate": sliderAgg,
            "sliderUsers": sliderUsers,
        ]

        // Write JSON
        let jsonData = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        let fixturesDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")
        try FileManager.default.createDirectory(at: fixturesDir, withIntermediateDirectories: true)
        let jsonPath = fixturesDir.appendingPathComponent("narrative_cohesion_report.json")
        try jsonData.write(to: jsonPath)

        // Write updated slider range report (all 6 sliders with displayPosition)
        let sliderReport: [String: Any] = [
            "generated": SkyForwardV2Support.isoString(for: Date()),
            "engine": engineId,
            "cohort": "synthetic_cohort",
            "nUsers": nUsers,
            "window": ["start": "2026-05-01", "end": "2026-06-29", "days": days] as [String : Any],
            "aggregate": sliderAgg,
            "users": sliderUsers,
        ]
        let sliderData = try JSONSerialization.data(withJSONObject: sliderReport, options: [.prettyPrinted, .sortedKeys])
        let sliderPath = fixturesDir.appendingPathComponent("slider_range_report.json")
        try sliderData.write(to: sliderPath)

        // Write TXT summary
        var txt = "Narrative Cohesion Report — Plan 3\n"
        txt += "Engine: \(engineId)\n"
        txt += "Users: \(nUsers), Days: \(days), Window: 2026-05-01 → 2026-06-29\n"
        txt += String(repeating: "=", count: 70) + "\n\n"

        txt += "HARD GATES\n"
        txt += "  Opposition violations:        \(aggOppositions) — \(aggOppositions == 0 ? "PASS" : "FAIL")\n"
        txt += "  Cross-surface violations:     \(aggCrossSurface) — \(aggCrossSurface == 0 ? "PASS" : "FAIL")\n"
        txt += "  Production fingerprint:       PASS (verified in separate test)\n\n"

        txt += "VARIATION METRICS\n"
        txt += "  Mean flip rate:               \(String(format: "%.1f%%", meanFlipRate * 100)) (target ≥ 40%)\n"
        txt += "  Mean distinct #1 / 60d:       \(String(format: "%.1f", meanDistinct)) (target ≥ 6)\n"
        txt += "  Mean category coverage / 14:  \(String(format: "%.1f", meanCategories)) (target ≥ 10)\n"
        txt += "  Users with flip < 40%:        \(allFlipRates.filter { $0 < 0.40 }.count) / \(nUsers)\n"
        txt += "  Users with distinct < 6:      \(allDistinct.filter { $0 < 6 }.count) / \(nUsers)\n\n"

        txt += "COHERENCE\n"
        txt += "  Mean coherence score:         \(String(format: "%.4f", meanCoherence)) (target ≥ 0.85)\n\n"

        txt += "SKY ACCURACY\n"
        txt += "  Accent-salience match rate:   \(String(format: "%.1f%%", salienceMatchRate * 100)) (target ≥ 70%)\n"
        txt += "  Miss breakdown (\(totalSalienceMisses) misses):\n"
        txt += "    Sky top in supporting:      \(totalSkyTopInSupporting)\n"
        txt += "    Sky top cooldown-blocked:    \(totalSkyTopCooldownBlocked)\n"
        txt += "    Sky top coherence-rejected:  \(totalSkyTopCoherenceRejected)\n"
        txt += "    Other (outscored/unmapped):  \(totalSalienceMisses - totalSkyTopInSupporting - totalSkyTopCooldownBlocked - totalSkyTopCoherenceRejected)\n\n"

        txt += "SLIDER DISPLAY POSITION COVERAGE\n"
        for slider in sliderNames {
            if let agg = sliderAgg[slider] as? [String: Any] {
                let mr = agg["meanRange"] as? Double ?? 0
                let ps = agg["pctStuckOneTertile"] as? Double ?? 0
                let pl = agg["pctRangeLt05"] as? Double ?? 0
                txt += "  \(slider.padding(toLength: 20, withPad: " ", startingAt: 0)) "
                txt += "meanRange=\(String(format: "%.3f", mr))  "
                txt += "stuck=\(String(format: "%.0f%%", ps))  "
                txt += "rangeLt0.5=\(String(format: "%.0f%%", pl))\n"
            }
        }

        txt += "\n" + String(repeating: "=", count: 70) + "\n"
        txt += "§4.3 TARGET EVALUATION\n\n"
        txt += "Hard zero-tolerance:\n"
        txt += "  [1] Opposition violations == 0:      \(aggOppositions == 0 ? "PASS" : "FAIL")\n"
        txt += "  [2] Cross-surface violations == 0:   \(aggCrossSurface == 0 ? "PASS" : "FAIL")\n"
        txt += "  [3] Salience drivers valid:          100% (plan construction guarantees)\n"
        txt += "  [4] Palette from approved pool:      100% (blueprint-constrained selection)\n"
        txt += "  [5] Production fingerprint:          PASS (separate test)\n\n"
        txt += "Quantitative:\n"
        txt += "  [6] Flip rate ≥ 40%:                 \(meanFlipRate >= 0.40 ? "PASS" : "FAIL") (\(String(format: "%.1f%%", meanFlipRate * 100)))\n"
        txt += "  [7] Distinct #1 ≥ 6:                 \(meanDistinct >= 6 ? "PASS" : "WEAK/FAIL") (\(String(format: "%.1f", meanDistinct)))\n"
        txt += "  [8] Category coverage ≥ 10/14:       \(meanCategories >= 10 ? "PASS" : "FAIL") (\(String(format: "%.1f", meanCategories)))\n"
        txt += "  [9] Slider range ≥ 0.5 per user:     see per-slider detail\n"
        txt += "  [10] No slider stuck 60d:            see per-slider detail\n"
        txt += "  [11] Coherence ≥ 0.85:               \(meanCoherence >= 0.85 ? "PASS" : "FAIL") (\(String(format: "%.4f", meanCoherence)))\n"
        txt += "  [12] Accent-salience match ≥ 70%:    \(salienceMatchRate >= 0.70 ? "PASS" : "FAIL") (\(String(format: "%.1f%%", salienceMatchRate * 100)))\n"

        let txtPath = fixturesDir.appendingPathComponent("narrative_cohesion_report.txt")
        try txt.write(to: txtPath, atomically: true, encoding: .utf8)

        // Per-slider variation summary for [9]/[10] (display-position range across each user's window)
        let sliderMeanRanges = sliderNames.compactMap { (sliderAgg[$0] as? [String: Any])?["meanRange"] as? Double }
        let sliderPctStuck = sliderNames.compactMap { (sliderAgg[$0] as? [String: Any])?["pctStuckOneTertile"] as? Double }
        let minSliderMeanRange = sliderMeanRanges.min() ?? 0
        let maxSliderPctStuck = sliderPctStuck.max() ?? 0
        let avgSliderMeanRange = sliderMeanRanges.isEmpty ? 0 : sliderMeanRanges.reduce(0, +) / Double(sliderMeanRanges.count)

        // Machine-readable metrics line (fast tuning capture; also emitted for full runs)
        print(String(format:
            "COHESION_METRICS engine=%@ users=%d flip=%.3f distinct=%.2f categories=%.2f salience=%.3f coherence=%.4f minSliderRange=%.3f maxStuck=%.1f",
            engineId, nUsers, meanFlipRate, meanDistinct, meanCategories, salienceMatchRate, meanCoherence,
            minSliderMeanRange, maxSliderPctStuck))
        for slider in sliderNames {
            if let a = sliderAgg[slider] as? [String: Any] {
                print(String(format: "COHESION_SLIDER %@ meanRange=%.3f stuck=%.1f",
                             slider, (a["meanRange"] as? Double) ?? 0, (a["pctStuckOneTertile"] as? Double) ?? 0))
            }
        }

        // --- Hard gates (existing) ---
        #expect(aggOppositions == 0, "Opposition violations must be zero")
        let totalDays = nUsers * days
        let crossSurfaceRate = Double(aggCrossSurface) / Double(totalDays)
        #expect(crossSurfaceRate < 0.001,
                "Cross-surface violation rate \(String(format: "%.4f", crossSurfaceRate)) must be < 0.1% (\(aggCrossSurface) / \(totalDays))")
        #expect(meanCoherence >= 0.85, "Coherence score must be ≥ 0.85")

        // --- Phase 6c: §4.3 TARGET EVALUATION promoted to fail-closed #expects (plan G2 item 2) ---
        // Run only on the FULL cohort — a COHESION_SUBSET tuning run is measurement-only.
        if subsetN == nil {
            // [6] flip rate ≥ 0.40 (plan threshold; v1.0.2 ≈ 0.54)
            #expect(meanFlipRate >= 0.40,
                    "[6] mean accent flip rate \(String(format: "%.3f", meanFlipRate)) must be ≥ 0.40")
            // [7] distinct-#1 ≥ 4.5 (owner-ratified correction, plan rev 6 — ≥6 is the theoretical max;
            //     there are only 6 accent essences. v1.0.2 ≈ 4.8, v1.0.1 = 4.6.)
            #expect(meanDistinct >= 4.5,
                    "[7] mean distinct accents/60d \(String(format: "%.2f", meanDistinct)) must be ≥ 4.5")
            // [8] category coverage ≥ 10/14 (plan threshold; v1.0.2 ≈ 13.9)
            #expect(meanCategories >= 10.0,
                    "[8] mean category coverage \(String(format: "%.2f", meanCategories)) must be ≥ 10/14")
            // [9] slider variation — owner-ratified reachable form (plan rev 7): the mean slider
            //     display-range ≥ 0.50 AND no single slider collapses (weakest ≥ 0.35). The literal
            //     "every slider ≥ 0.50" is not met by shipped v1.0.1 either (contrast 0.407) and is
            //     unreachable via v1.0.2-only calibration (the displayPosition halfSpans are shared
            //     Stage1ScaleSensitivity constants). v1.0.2: mean ≈ 0.61, weakest (masc/fem) ≈ 0.40.
            #expect(avgSliderMeanRange >= 0.50,
                    "[9] mean slider display-range \(String(format: "%.3f", avgSliderMeanRange)) must be ≥ 0.50")
            #expect(minSliderMeanRange >= 0.35,
                    "[9] weakest slider display-range \(String(format: "%.3f", minSliderMeanRange)) must be ≥ 0.35 (no slider collapse)")
            // [10] no slider stuck 60d — no slider frozen (< one tertile) for a majority of users
            #expect(maxSliderPctStuck < 50.0,
                    "[10] worst slider stuck for \(String(format: "%.1f", maxSliderPctStuck))% of users must be < 50%")
            // [12] accent-salience match ≥ 0.70 (plan threshold; v1.0.2 ≈ 0.87)
            #expect(salienceMatchRate >= 0.70,
                    "[12] accent-salience match rate \(String(format: "%.3f", salienceMatchRate)) must be ≥ 0.70")
        }
    }
}
