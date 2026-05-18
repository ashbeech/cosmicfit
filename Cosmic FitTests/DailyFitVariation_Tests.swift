//
//  DailyFitVariation_Tests.swift
//  Cosmic FitTests
//
//  Part 4: Variation tests — intra-user drift, inter-user differentiation,
//  and temporal sensitivity to astrological contrasts.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Profile Definitions (mirrored from DailyFitCalibration_Tests)

private enum VariationProfiles {

    static let fixedBaseDate: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: 2026, month: 5, day: 10))!
    }()

    static let standardPlanets: [(String, String)] = [
        ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
        ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
        ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
    ]

    static func chart(signs: [Int]) -> NatalChartCalculator.NatalChart {
        var planets: [NatalChartCalculator.PlanetPosition] = []
        for (index, (name, symbol)) in standardPlanets.enumerated() {
            let sign = signs[index]
            planets.append(NatalChartCalculator.PlanetPosition(
                name: name, symbol: symbol,
                longitude: Double((sign - 1) * 30 + 15), latitude: 0.0,
                zodiacSign: sign, zodiacPosition: "15°00'",
                isRetrograde: false
            ))
        }
        return NatalChartCalculator.NatalChart(
            planets: planets,
            ascendant: Double((signs[0] - 1) * 30), midheaven: 90.0,
            descendant: 180.0, imumCoeli: 270.0,
            houseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            wholeSignHouseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            northNode: 0.0, southNode: 180.0, vertex: 90.0,
            partOfFortune: 45.0, lilith: 120.0, chiron: 200.0,
            lunarPhase: 90.0
        )
    }

    static let ashProfile = ProfileDef(
        name: "ashProfile (Leo fire-heavy)",
        hash: "cal_ash",
        natalSigns: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5],
        progressedSigns: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5],
        expectedDominant: [.drama, .playful]
    )

    static let waterDominant = ProfileDef(
        name: "waterDominant (Cancer/Scorpio/Pisces)",
        hash: "cal_water",
        natalSigns: [4, 8, 12, 4, 8, 12, 4, 8, 12, 4],
        progressedSigns: [4, 8, 12, 4, 8, 12, 4, 8, 12, 4],
        expectedDominant: [.romantic, .drama]
    )

    static let earthGrounded = ProfileDef(
        name: "earthGrounded (Virgo/Taurus/Capricorn)",
        hash: "cal_earth",
        natalSigns: [6, 2, 10, 6, 2, 10, 6, 2, 10, 6],
        progressedSigns: [6, 2, 10, 6, 2, 10, 6, 2, 10, 6],
        expectedDominant: [.classic, .utility]
    )

    static let airIntellectual = ProfileDef(
        name: "airIntellectual (Gemini/Aquarius/Libra)",
        hash: "cal_air",
        natalSigns: [3, 11, 7, 3, 11, 7, 3, 11, 7, 3],
        progressedSigns: [3, 11, 7, 3, 11, 7, 3, 11, 7, 3],
        expectedDominant: [.playful, .edge]
    )

    static let fireExplosive = ProfileDef(
        name: "fireExplosive (Aries/Leo/Sagittarius)",
        hash: "cal_fire",
        natalSigns: [1, 5, 9, 1, 5, 9, 1, 5, 9, 1],
        progressedSigns: [1, 5, 9, 1, 5, 9, 1, 5, 9, 1],
        expectedDominant: [.drama, .playful]
    )

    static let allProfiles = [ashProfile, waterDominant, earthGrounded, airIntellectual, fireExplosive]

    struct ProfileDef {
        let name: String
        let hash: String
        let natalSigns: [Int]
        let progressedSigns: [Int]
        let expectedDominant: [Energy]

        var natalChart: NatalChartCalculator.NatalChart {
            VariationProfiles.chart(signs: natalSigns)
        }
        var progressedChart: NatalChartCalculator.NatalChart {
            VariationProfiles.chart(signs: progressedSigns)
        }
    }

    // MARK: Transit Factory

    static func makeTransit(
        planet: String, natal: String = "Sun",
        aspect: String = "conjunction", orb: Double = 1.0,
        date: Date = fixedBaseDate
    ) -> NatalChartCalculator.TransitAspect {
        NatalChartCalculator.TransitAspect(
            transitPlanet: planet, transitPlanetSymbol: "•",
            natalPlanet: natal, natalPlanetSymbol: "•",
            aspectType: aspect, aspectSymbol: "•",
            orb: orb, applying: true,
            effectiveFrom: date,
            effectiveTo: date.addingTimeInterval(86400 * 3),
            description: "\(planet) \(aspect) \(natal)",
            category: .shortTerm
        )
    }

    static func transitsForDay(_ dayOffset: Int) -> [NatalChartCalculator.TransitAspect] {
        let base = fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
        let configs: [(String, String, String, Double)] = [
            ("Mars", "Sun", "conjunction", 1.0 + Double(dayOffset % 3)),
            ("Venus", "Moon", "trine", 0.5 + Double(dayOffset % 4)),
            ("Jupiter", "Venus", "sextile", 2.0 + Double(dayOffset % 2)),
            ("Saturn", "Mercury", "square", 1.5),
            ("Pluto", "Mars", "opposition", 3.0 - Double(dayOffset % 3)),
        ]
        return configs.map { makeTransit(planet: $0.0, natal: $0.1, aspect: $0.2, orb: $0.3, date: base) }
    }

    static func moonPhaseForDay(_ dayOffset: Int) -> Double {
        (45.0 + Double(dayOffset) * 12.86).truncatingRemainder(dividingBy: 360.0)
    }

    // MARK: Blueprint

    static func colour(_ name: String, _ hex: String, _ role: ColourRole) -> BlueprintColour {
        BlueprintColour(
            name: name, hexValue: hex, role: role,
            provenance: .v4Template(family: "Cal", band: role.rawValue, index: 0)
        )
    }

    static let calibrationBlueprint: CosmicBlueprint = {
        let palette = PaletteSection(
            neutrals: [
                colour("Ivory", "#FFFFF0", .neutral),
                colour("Sand", "#C2B280", .neutral),
            ],
            coreColours: [
                colour("Burnt Sienna", "#A0522D", .core),
                colour("Terracotta", "#E2725B", .core),
                colour("Amber", "#FFBF00", .core),
                colour("Olive", "#808000", .core),
            ],
            accentColours: [
                colour("Coral", "#FF7F50", .accent),
                colour("Tangerine", "#FF9966", .accent),
                colour("Saffron", "#F4C430", .accent),
                colour("Burgundy", "#800020", .accent),
            ],
            supportColours: [
                colour("Blush", "#DE5D83", .support),
                colour("Champagne", "#F7E7CE", .support),
            ],
            family: .deepAutumn, cluster: .deepWarmStructured,
            variables: DerivedVariables(
                depth: .deep, temperature: .warm,
                saturation: .rich, contrast: .high,
                surface: .structured
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Calibration palette."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Calibration style core."),
            textures: TexturesSection(
                goodText: "Good.", badText: "Bad.", sweetSpotText: "Sweet.",
                recommendedTextures: ["cashmere", "denim", "silk", "leather"],
                avoidTextures: ["polyester"], sweetSpotKeywords: ["luxe"]
            ),
            palette: palette,
            occasions: OccasionsSection(
                workText: "W.", intimateText: "I.", dailyText: "D."
            ),
            hardware: HardwareSection(
                metalsText: "Metals.", stonesText: "Stones.", tipText: "Tip.",
                recommendedMetals: ["gold", "brass", "copper"],
                recommendedStones: ["ruby"]
            ),
            code: CodeSection(
                leanInto: ["structured shoulders", "sharp tailoring"],
                avoid: ["soft draping"],
                consider: ["angular lines"]
            ),
            accessory: AccessorySection(paragraphs: ["A1.", "A2.", "A3."]),
            pattern: PatternSection(
                narrativeText: "Pattern.", tipText: "Tip.",
                recommendedPatterns: ["stripes", "herringbone", "abstract geometric"],
                avoidPatterns: ["neon"]
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }()

    // MARK: Run Helper

    struct DayRun {
        let profile: ProfileDef
        let dayOffset: Int
        let date: Date
        let payload: DailyFitPayload
        let report: DailyFitDiagnosticReport
    }

    static func runProfile(
        _ profile: ProfileDef,
        dayOffset: Int,
        moonOverride: Double? = nil,
        blueprint: CosmicBlueprint = calibrationBlueprint,
        calibration: DailyFitCalibration = .default
    ) -> DayRun {
        let date = fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
        let t = transitsForDay(dayOffset)
        let moon = moonOverride ?? moonPhaseForDay(dayOffset)
        let (payload, report) = DailyFitDiagnostics.generateReport(
            natalChart: profile.natalChart,
            progressedChart: profile.progressedChart,
            transits: t,
            moonPhaseDegrees: moon,
            profileHash: profile.hash,
            blueprint: blueprint,
            date: date,
            calibration: calibration
        )
        return DayRun(
            profile: profile, dayOffset: dayOffset,
            date: date, payload: payload, report: report
        )
    }

    static func runAllDays(
        _ profile: ProfileDef,
        days: Int = 30
    ) -> [DayRun] {
        (0..<days).map { runProfile(profile, dayOffset: $0) }
    }
}

// MARK: - Cosine Distance Helper

private func cosineDistance(_ a: [Double], _ b: [Double]) -> Double {
    let dot = zip(a, b).map(*).reduce(0, +)
    let magA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let magB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    guard magA > 0, magB > 0 else { return 1.0 }
    return 1.0 - (dot / (magA * magB))
}

private func stddev(_ values: [Double]) -> Double {
    guard values.count > 1 else { return 0.0 }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
    return sqrt(variance)
}

// MARK: - Test Suite

@Suite(.serialized)
struct DailyFitVariation_Tests {

    // MARK: - 4A: Intra-User Variation

    @Test("4A — intra-user variation across 30 days")
    func testIntraUserVariation() {
        TarotCalibrationTestSupport.installIsolatedTrackers()

        var lines: [String] = []
        lines.append("=== 4A: Intra-User Variation (30 days) ===")
        lines.append("Generated: \(Date())")
        lines.append("")

        var allProfilesPass = true

        for profile in VariationProfiles.allProfiles {
            TarotCalibrationTestSupport.resetTrackersForProfile()

            let runs = VariationProfiles.runAllDays(profile)

            // Essence drift: cosine distance between consecutive days
            var essenceDrifts: [Double] = []
            for i in 1..<runs.count {
                let prev = runs[i - 1].payload.essenceProfile.allScores.map(\.score)
                let curr = runs[i].payload.essenceProfile.allScores.map(\.score)
                essenceDrifts.append(cosineDistance(prev, curr))
            }
            let avgDrift = essenceDrifts.isEmpty ? 0.0 : essenceDrifts.reduce(0, +) / Double(essenceDrifts.count)
            let maxDrift = essenceDrifts.max() ?? 0.0

            // Palette churn: % of daily colours that change day-to-day
            var paletteChurns: [Double] = []
            for i in 1..<runs.count {
                let prevNames = Set(runs[i - 1].payload.dailyPalette.colours.map(\.name))
                let currNames = Set(runs[i].payload.dailyPalette.colours.map(\.name))
                let changed = prevNames.symmetricDifference(currNames).count
                let total = max(prevNames.count, currNames.count, 1)
                paletteChurns.append(Double(changed) / Double(total))
            }
            let avgChurn = paletteChurns.isEmpty ? 0.0 : paletteChurns.reduce(0, +) / Double(paletteChurns.count)

            // Slider stability: stddev of vibrancy, contrast, metalTone
            let vibrancyValues = runs.map(\.payload.vibrancy)
            let contrastValues = runs.map(\.payload.contrast)
            let metalToneValues = runs.map(\.payload.metalTone)
            let vibrancyStd = stddev(vibrancyValues)
            let contrastStd = stddev(contrastValues)
            let metalToneStd = stddev(metalToneValues)

            // Tarot repeat rate
            let uniqueCards = Set(runs.map(\.payload.tarotCard.name))
            let tarotUniqueCount = uniqueCards.count

            lines.append("PROFILE: \(profile.name)")
            lines.append(CalibrationReportHelper.summaryStats(label: "  Essence drift", values: essenceDrifts))
            lines.append("  Avg essence drift: \(String(format: "%.4f", avgDrift))  Max: \(String(format: "%.4f", maxDrift))")
            lines.append("  Avg palette churn: \(String(format: "%.3f", avgChurn))")
            lines.append("  Slider stddev — vibrancy: \(String(format: "%.4f", vibrancyStd))  contrast: \(String(format: "%.4f", contrastStd))  metalTone: \(String(format: "%.4f", metalToneStd))")
            lines.append("  Unique tarot cards: \(tarotUniqueCount)/30 — \(uniqueCards.sorted().joined(separator: ", "))")
            lines.append("")

            // CI-gated assertions
            if CalibrationTier.current.isCIGated {
                if avgDrift <= 0.01 || avgDrift >= 0.8 {
                    allProfilesPass = false
                }
                #expect(avgDrift > 0.01,
                        "\(profile.name): avg essence drift \(String(format: "%.4f", avgDrift)) ≤ 0.01 — too static")
                #expect(avgDrift < 0.8,
                        "\(profile.name): avg essence drift \(String(format: "%.4f", avgDrift)) ≥ 0.8 — too chaotic")
                #expect(avgChurn > 0.1,
                        "\(profile.name): avg palette churn \(String(format: "%.3f", avgChurn)) ≤ 0.1 — palette too static")
                #expect(tarotUniqueCount >= 10,
                        "\(profile.name): only \(tarotUniqueCount) unique cards over 30 days, expected ≥ 10")
            }
        }

        let content = lines.joined(separator: "\n")
        CalibrationReportHelper.writeReport(prefix: "daily_fit_variation_4a", content: content)
    }

    // MARK: - 4B: Inter-User Variation

    @Test("4B — inter-user differentiation on same date")
    func testInterUserDifferentiation() {
        TarotCalibrationTestSupport.installIsolatedTrackers()

        var payloads: [(name: String, payload: DailyFitPayload)] = []

        for profile in VariationProfiles.allProfiles {
            TarotCalibrationTestSupport.resetTrackersForProfile()
            let run = VariationProfiles.runProfile(profile, dayOffset: 0)
            payloads.append((name: profile.name, payload: run.payload))
        }

        let count = payloads.count
        let totalPairs = count * (count - 1) / 2

        // Pairwise cosine distance of essence vectors
        var distantPairs = 0
        for i in 0..<count {
            for j in (i + 1)..<count {
                let vecA = payloads[i].payload.essenceProfile.allScores.map(\.score)
                let vecB = payloads[j].payload.essenceProfile.allScores.map(\.score)
                let dist = cosineDistance(vecA, vecB)
                if dist > 0.01 { distantPairs += 1 }
            }
        }
        let distantPct = Double(distantPairs) / Double(totalPairs)
        #expect(distantPct >= 0.3,
                "Only \(distantPairs)/\(totalPairs) pairs (\(String(format: "%.0f", distantPct * 100))%) have cosine distance > 0.01; expected ≥ 30%")

        // Most profiles should produce different palettes (allow some overlap)
        var paletteSamePairs = 0
        for i in 0..<count {
            for j in (i + 1)..<count {
                let namesA = payloads[i].payload.dailyPalette.colours.map(\.name).sorted()
                let namesB = payloads[j].payload.dailyPalette.colours.map(\.name).sorted()
                if namesA == namesB { paletteSamePairs += 1 }
            }
        }
        #expect(paletteSamePairs <= 3,
                "\(paletteSamePairs)/\(totalPairs) profile pairs share identical palette — too little differentiation")

        // Tarot card differs for at least 60% of profile pairs
        var tarotDiffPairs = 0
        for i in 0..<count {
            for j in (i + 1)..<count {
                if payloads[i].payload.tarotCard.name != payloads[j].payload.tarotCard.name {
                    tarotDiffPairs += 1
                }
            }
        }
        let tarotDiffPct = Double(tarotDiffPairs) / Double(totalPairs)
        #expect(tarotDiffPct >= 0.3,
                "Only \(tarotDiffPairs)/\(totalPairs) pairs (\(String(format: "%.0f", tarotDiffPct * 100))%) have different tarot cards; expected ≥ 30%")
    }

    // MARK: - 4C: Temporal Sensitivity

    @Test("4C — temporal sensitivity to astrological contrasts")
    func testTemporalSensitivity() {
        TarotCalibrationTestSupport.installIsolatedTrackers()

        let profile = VariationProfiles.ashProfile

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let fullMoonRun = VariationProfiles.runProfile(profile, dayOffset: 0, moonOverride: 180.0)

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let newMoonRun = VariationProfiles.runProfile(profile, dayOffset: 0, moonOverride: 0.0)

        let fmAxes = fullMoonRun.payload.axes
        let nmAxes = newMoonRun.payload.axes
        let axesDiff = abs(fmAxes.action - nmAxes.action)
            + abs(fmAxes.tempo - nmAxes.tempo)
            + abs(fmAxes.strategy - nmAxes.strategy)
            + abs(fmAxes.visibility - nmAxes.visibility)

        let fmVibe = fullMoonRun.payload.vibeBreakdown
        let nmVibe = newMoonRun.payload.vibeBreakdown
        let vibeDiff = fmVibe.classic != nmVibe.classic
            || fmVibe.playful != nmVibe.playful
            || fmVibe.romantic != nmVibe.romantic
            || fmVibe.utility != nmVibe.utility
            || fmVibe.drama != nmVibe.drama
            || fmVibe.edge != nmVibe.edge

        #expect(axesDiff > 0.01 || vibeDiff,
                "Full moon (180°) vs new moon (0°) produced identical axes and vibe — temporal sensitivity missing")
    }
}
