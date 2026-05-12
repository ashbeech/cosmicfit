//
//  DailyFitCoherence_Tests.swift
//  Cosmic FitTests
//
//  Part 1: Coherence audit — direction-vector classification per section,
//  contradiction detection across 5 profiles × 30 days.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Profile Definitions (mirrored from DailyFitCalibration_Tests)

private enum CoherenceProfiles {

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
            CoherenceProfiles.chart(signs: natalSigns)
        }
        var progressedChart: NatalChartCalculator.NatalChart {
            CoherenceProfiles.chart(signs: progressedSigns)
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
        blueprint: CosmicBlueprint = calibrationBlueprint,
        calibration: DailyFitCalibration = .default
    ) -> DayRun {
        let date = fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
        let t = transitsForDay(dayOffset)
        let moon = moonPhaseForDay(dayOffset)
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

// MARK: - Direction Classification Helpers

private func classifyPaletteTemperature(palette: DailyPaletteSelection) -> String {
    let warmKeywords = ["coral", "tangerine", "amber", "saffron", "terracotta",
                        "burnt sienna", "burgundy", "blush", "champagne", "sand",
                        "gold", "copper", "rust", "peach", "sienna", "warm"]
    let coolKeywords = ["ice", "slate", "silver", "steel", "navy", "cobalt",
                        "sapphire", "teal", "mint", "lavender", "frost", "cool",
                        "arctic", "ash", "pewter"]

    var warmCount = 0
    var coolCount = 0
    for pick in palette.colours {
        let lower = pick.name.lowercased()
        if warmKeywords.contains(where: { lower.contains($0) }) { warmCount += 1 }
        if coolKeywords.contains(where: { lower.contains($0) }) { coolCount += 1 }
    }
    if warmCount > coolCount { return "warm" }
    if coolCount > warmCount { return "cool" }
    return "neutral"
}

private let boldCategories: Set<StyleEssenceCategory> = [
    .drama, .edgy, .maximalist, .magnetic, .sensual
]
private let restrainedCategories: Set<StyleEssenceCategory> = [
    .classic, .minimal, .grounded, .utility, .polished
]

private func classifyEssenceDirection(essence: StyleEssenceProfile) -> String {
    let top3 = essence.visibleCategories.prefix(3)
    let boldCount = top3.filter { boldCategories.contains($0.category) }.count
    let restrainedCount = top3.filter { restrainedCategories.contains($0.category) }.count
    if boldCount >= 2 { return "bold" }
    if restrainedCount >= 2 { return "restrained" }
    return "neutral"
}

private func classifySliderIntensity(value: Double) -> String {
    if value > 0.65 { return "high" }
    if value < 0.35 { return "low" }
    return "neutral"
}

private func classifySilhouetteDirection(silhouette: SilhouetteProfile) -> String {
    let structured = silhouette.structuredDraped < 0.4 && silhouette.angularRounded < 0.4
    let fluid = silhouette.structuredDraped > 0.6 && silhouette.angularRounded > 0.6
    if structured { return "structured" }
    if fluid { return "fluid" }
    return "neutral"
}

// MARK: - Contradiction Detection

private let fluidEssenceCategories: Set<StyleEssenceCategory> = [
    .romantic, .effortless, .sensual
]

private struct CoherenceResult {
    let profileName: String
    let dayOffset: Int
    let contradictions: [String]
    let paletteTemp: String
    let essenceDir: String
    let vibrancyDir: String
    let silhouetteDir: String
}

private func detectContradictions(payload: DailyFitPayload) -> [String] {
    var hits: [String] = []

    let essenceDir = classifyEssenceDirection(essence: payload.essenceProfile)
    let vibrancyDir = classifySliderIntensity(value: payload.vibrancy)

    if essenceDir == "bold" && vibrancyDir == "low" {
        hits.append("Essence=bold but vibrancy=\(String(format: "%.3f", payload.vibrancy)) (<0.35)")
    }

    let paletteTemp = classifyPaletteTemperature(palette: payload.dailyPalette)
    if paletteTemp == "warm" && payload.metalTone < 0.3 {
        hits.append("Palette=warm but metalTone=\(String(format: "%.3f", payload.metalTone)) (<0.3, strongly cool)")
    }

    let silhouetteDir = classifySilhouetteDirection(silhouette: payload.silhouetteProfile)
    if silhouetteDir == "structured" {
        let top3 = payload.essenceProfile.visibleCategories.prefix(3)
        let allFluid = top3.allSatisfy { fluidEssenceCategories.contains($0.category) }
        if allFluid {
            hits.append("Silhouette=structured but top-3 essence all romantic/fluid")
        }
    }

    return hits
}

// MARK: - Test Suite

@Suite(.serialized)
struct DailyFitCoherence_Tests {

    // MARK: - Test 1: Diagnostic Coherence Report

    @Test("Generate coherence report — diagnostic")
    func testCoherenceReportDiagnostic() {
        TarotCalibrationTestSupport.installIsolatedTrackers()

        var lines: [String] = []
        lines.append("=== Daily Fit Coherence Audit ===")
        lines.append("Generated: \(Date())")
        lines.append("Profiles: \(CoherenceProfiles.allProfiles.count)")
        lines.append("Days per profile: 30")
        lines.append("")

        var allResults: [CoherenceResult] = []

        for profile in CoherenceProfiles.allProfiles {
            TarotCalibrationTestSupport.resetTrackersForProfile()
            lines.append("========================================")
            lines.append("PROFILE: \(profile.name)")
            lines.append("========================================")

            let runs = CoherenceProfiles.runAllDays(profile)
            var profileContradictionDays = 0

            for run in runs {
                let p = run.payload
                let contradictions = detectContradictions(payload: p)
                let paletteTemp = classifyPaletteTemperature(palette: p.dailyPalette)
                let essenceDir = classifyEssenceDirection(essence: p.essenceProfile)
                let vibrancyDir = classifySliderIntensity(value: p.vibrancy)
                let silhouetteDir = classifySilhouetteDirection(silhouette: p.silhouetteProfile)

                let result = CoherenceResult(
                    profileName: profile.name, dayOffset: run.dayOffset,
                    contradictions: contradictions,
                    paletteTemp: paletteTemp, essenceDir: essenceDir,
                    vibrancyDir: vibrancyDir, silhouetteDir: silhouetteDir
                )
                allResults.append(result)

                if !contradictions.isEmpty { profileContradictionDays += 1 }

                let marker = contradictions.isEmpty ? "✓" : "✗ (\(contradictions.count))"
                lines.append("  Day \(String(format: "%2d", run.dayOffset)): " +
                             "palette=\(paletteTemp.padding(toLength: 7, withPad: " ", startingAt: 0)) " +
                             "essence=\(essenceDir.padding(toLength: 10, withPad: " ", startingAt: 0)) " +
                             "vibrancy=\(vibrancyDir.padding(toLength: 7, withPad: " ", startingAt: 0)) " +
                             "silhouette=\(silhouetteDir.padding(toLength: 10, withPad: " ", startingAt: 0)) " +
                             "\(marker)")
                for c in contradictions {
                    lines.append("         → \(c)")
                }
            }

            let pct = Double(profileContradictionDays) / 30.0 * 100.0
            lines.append("")
            lines.append("  Summary: \(profileContradictionDays)/30 days with contradictions (\(String(format: "%.1f", pct))%)")
            lines.append("")
        }

        // Aggregate alignment histogram
        let directionCounts: [(String, String)] = allResults.flatMap { r in
            [("palette", r.paletteTemp), ("essence", r.essenceDir),
             ("vibrancy", r.vibrancyDir), ("silhouette", r.silhouetteDir)]
        }
        var sectionBuckets: [String: [String: Int]] = [:]
        for (section, dir) in directionCounts {
            sectionBuckets[section, default: [:]][dir, default: 0] += 1
        }
        lines.append("--- Direction Distribution ---")
        for section in ["palette", "essence", "vibrancy", "silhouette"] {
            let buckets = sectionBuckets[section] ?? [:]
            let desc = buckets.sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }.joined(separator: "  ")
            lines.append("  \(section.padding(toLength: 12, withPad: " ", startingAt: 0)) \(desc)")
        }
        lines.append("")

        let totalContradictions = allResults.filter { !$0.contradictions.isEmpty }.count
        lines.append("Total days with contradictions: \(totalContradictions)/\(allResults.count)")

        let content = lines.joined(separator: "\n")
        if let url = CalibrationReportHelper.writeReport(prefix: "daily_fit_coherence", content: content) {
            lines.append("Report written to: \(url.path)")
        }
    }

    // MARK: - Test 2: CI-Gated Contradiction Threshold

    @Test("No profile has >20% hard contradiction days")
    func testNoProfileExceeds20PercentContradictions() {
        guard CalibrationTier.current.isCIGated else { return }

        TarotCalibrationTestSupport.installIsolatedTrackers()

        for profile in CoherenceProfiles.allProfiles {
            TarotCalibrationTestSupport.resetTrackersForProfile()

            let runs = CoherenceProfiles.runAllDays(profile)
            var contradictionDays = 0

            for run in runs {
                let contradictions = detectContradictions(payload: run.payload)
                if !contradictions.isEmpty { contradictionDays += 1 }
            }

            let pct = Double(contradictionDays) / 30.0 * 100.0
            #expect(pct <= 20.0,
                    "\(profile.name): \(contradictionDays)/30 contradiction days (\(String(format: "%.1f", pct))%) exceeds 20% threshold")
        }
    }

    // MARK: - Test 3: Shared Input Verification

    @Test("Shared input verification — all sections derive from same snapshot")
    func testSharedInputVerification() {
        TarotCalibrationTestSupport.installIsolatedTrackers()

        let run = CoherenceProfiles.runProfile(CoherenceProfiles.ashProfile, dayOffset: 0)
        let p = run.payload

        // Vibe total must be 21
        #expect(p.vibeBreakdown.totalPoints == 21,
                "Vibe total = \(p.vibeBreakdown.totalPoints), expected 21")
        #expect(p.vibeBreakdown.isValid, "Vibe breakdown invalid")

        // Axes in 1–10 range
        #expect(p.axes.action >= 1.0 && p.axes.action <= 10.0,
                "Action axis out of range: \(p.axes.action)")
        #expect(p.axes.tempo >= 1.0 && p.axes.tempo <= 10.0,
                "Tempo axis out of range: \(p.axes.tempo)")
        #expect(p.axes.strategy >= 1.0 && p.axes.strategy <= 10.0,
                "Strategy axis out of range: \(p.axes.strategy)")
        #expect(p.axes.visibility >= 1.0 && p.axes.visibility <= 10.0,
                "Visibility axis out of range: \(p.axes.visibility)")

        // Sliders in 0–1
        #expect(p.vibrancy >= 0.0 && p.vibrancy <= 1.0,
                "Vibrancy out of range: \(p.vibrancy)")
        #expect(p.contrast >= 0.0 && p.contrast <= 1.0,
                "Contrast out of range: \(p.contrast)")
        #expect(p.metalTone >= 0.0 && p.metalTone <= 1.0,
                "MetalTone out of range: \(p.metalTone)")

        // Essence has 14 categories
        #expect(p.essenceProfile.allScores.count == 14,
                "Essence count = \(p.essenceProfile.allScores.count), expected 14")
        #expect(p.essenceProfile.visibleCategories.count == 3,
                "Visible essence count = \(p.essenceProfile.visibleCategories.count), expected 3")

        // Silhouette sliders in 0–1
        #expect(p.silhouetteProfile.masculineFeminine >= 0.0 && p.silhouetteProfile.masculineFeminine <= 1.0)
        #expect(p.silhouetteProfile.angularRounded >= 0.0 && p.silhouetteProfile.angularRounded <= 1.0)
        #expect(p.silhouetteProfile.structuredDraped >= 0.0 && p.silhouetteProfile.structuredDraped <= 1.0)

        // Palette has 3 colours
        #expect(p.dailyPalette.colours.count == 3,
                "Palette count = \(p.dailyPalette.colours.count), expected 3")

        // Tarot card exists
        #expect(!p.tarotCard.name.isEmpty, "Tarot card name is empty")

        // Lunar context populated
        #expect(!p.lunarContext.phaseName.isEmpty, "Lunar phase name is empty")
    }
}
