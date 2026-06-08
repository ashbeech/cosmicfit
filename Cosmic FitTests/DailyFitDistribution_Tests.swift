//
//  DailyFitDistribution_Tests.swift
//  Cosmic FitTests
//
//  Part 2 of calibration plan: distribution histograms for ALL Daily Fit sections.
//  5 test profiles × 30 days, per-section analysis with CalibrationReportHelper.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Shared Calibration Profiles (mirrors DailyFitCalibration_Tests definitions)

private enum DistributionProfiles {

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

    // MARK: Chart Factory

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

    // MARK: Profile Definitions

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
            DistributionProfiles.chart(signs: natalSigns)
        }
        var progressedChart: NatalChartCalculator.NatalChart {
            DistributionProfiles.chart(signs: progressedSigns)
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

    // MARK: Moon Phase

    static func moonPhaseForDay(_ dayOffset: Int) -> Double {
        (45.0 + Double(dayOffset) * 12.86).truncatingRemainder(dividingBy: 360.0)
    }

    // MARK: Blueprint Fixture

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
        let transits = transitsForDay(dayOffset)
        let moon = moonPhaseForDay(dayOffset)
        let (payload, report) = DailyFitDiagnostics.generateReport(
            natalChart: profile.natalChart,
            progressedChart: profile.progressedChart,
            transits: transits,
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
        _ profile: ProfileDef, days: Int = 30
    ) -> [DayRun] {
        (0..<days).map { runProfile(profile, dayOffset: $0) }
    }
}

// MARK: - Collected Distribution Data

private struct DistributionData {
    var essenceTop3Counts: [StyleEssenceCategory: Int] = [:]
    var perProfileEssenceTop3: [String: [StyleEssenceCategory: Int]] = [:]

    var colourNameCounts: [String: Int] = [:]
    var colourRoleCounts: [String: Int] = [:]
    var statementSlotCount = 0
    var groundingSlotCount = 0

    var vibrancyValues: [Double] = []
    var contrastValues: [Double] = []
    var metalToneValues: [Double] = []
    var perProfileVibrancy: [String: [Double]] = [:]
    var perProfileContrast: [String: [Double]] = [:]
    var perProfileMetalTone: [String: [Double]] = [:]

    var mfValues: [Double] = []
    var arValues: [Double] = []
    var sdValues: [Double] = []

    var tarotCardCounts: [String: Int] = [:]
    var perProfileTarot: [String: [String: Int]] = [:]

    var vibeValues: [Energy: [Int]] = {
        var d = [Energy: [Int]]()
        for e in Energy.allCases { d[e] = [] }
        return d
    }()
    var perProfileVibe: [String: [Energy: [Int]]] = [:]
}

// MARK: - Test Suite

@Suite(.serialized)
struct DailyFitDistribution_Tests {

    private let dayCount = 30

    // MARK: - Sweep Runner

    private func collectAllData() -> (DistributionData, [DistributionProfiles.DayRun]) {
        var data = DistributionData()
        var allRuns: [DistributionProfiles.DayRun] = []

        for profile in DistributionProfiles.allProfiles {
            TarotCalibrationTestSupport.resetTrackersForProfile()

            var profileTarot: [String: Int] = [:]
            var profileVibrancy: [Double] = []
            var profileContrast: [Double] = []
            var profileMetal: [Double] = []
            var profileEssence: [StyleEssenceCategory: Int] = [:]
            var profileVibe: [Energy: [Int]] = {
                var d = [Energy: [Int]]()
                for e in Energy.allCases { d[e] = [] }
                return d
            }()

            let runs = DistributionProfiles.runAllDays(profile, days: dayCount)
            allRuns.append(contentsOf: runs)

            for run in runs {
                let p = run.payload

                // 2A: Essence top-3
                for score in p.essenceProfile.visibleCategories {
                    data.essenceTop3Counts[score.category, default: 0] += 1
                    profileEssence[score.category, default: 0] += 1
                }

                // 2B: Palette
                for pick in p.dailyPalette.colours {
                    data.colourNameCounts[pick.name, default: 0] += 1
                    data.colourRoleCounts[pick.role, default: 0] += 1
                    if pick.role == "accent" || pick.role == "core" {
                        data.statementSlotCount += 1
                    } else {
                        data.groundingSlotCount += 1
                    }
                }

                // 2C: Vibrancy / Contrast / Metal Tone
                data.vibrancyValues.append(p.vibrancy)
                data.contrastValues.append(p.contrast)
                data.metalToneValues.append(p.metalTone)
                profileVibrancy.append(p.vibrancy)
                profileContrast.append(p.contrast)
                profileMetal.append(p.metalTone)

                // 2D: Silhouette
                data.mfValues.append(p.silhouetteProfile.masculineFeminine)
                data.arValues.append(p.silhouetteProfile.angularRounded)
                data.sdValues.append(p.silhouetteProfile.structuredDraped)

                // 2E: Tarot
                let cardName = p.tarotCard.name
                data.tarotCardCounts[cardName, default: 0] += 1
                profileTarot[cardName, default: 0] += 1

                // 2F: Vibe Breakdown
                for energy in Energy.allCases {
                    let val = p.vibeBreakdown.value(for: energy)
                    data.vibeValues[energy, default: []].append(val)
                    profileVibe[energy, default: []].append(val)
                }
            }

            data.perProfileEssenceTop3[profile.name] = profileEssence
            data.perProfileTarot[profile.name] = profileTarot
            data.perProfileVibrancy[profile.name] = profileVibrancy
            data.perProfileContrast[profile.name] = profileContrast
            data.perProfileMetalTone[profile.name] = profileMetal
            data.perProfileVibe[profile.name] = profileVibe
        }

        return (data, allRuns)
    }

    // MARK: - 2A: Style Essence Distribution

    @Test("2A — Style Essence top-3 distribution across 5 profiles × 30 days")
    func testStyleEssenceDistribution() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        let sorted = StyleEssenceCategory.allCases.map { cat in
            (label: cat.rawValue, count: data.essenceTop3Counts[cat] ?? 0)
        }

        let histogram = CalibrationReportHelper.renderHistogram(
            title: "Style Essence Top-3 Appearances (n=\(DistributionProfiles.allProfiles.count * dayCount * 3))",
            data: sorted
        )

        var report = histogram + "\n"
        report += "--- Per-Profile Breakdown ---\n\n"
        for profile in DistributionProfiles.allProfiles {
            let profileCounts = data.perProfileEssenceTop3[profile.name] ?? [:]
            let top = profileCounts.sorted { $0.value > $1.value }.prefix(5)
            report += "  \(profile.name): \(top.map { "\($0.key.rawValue)=\($0.value)" }.joined(separator: ", "))\n"
        }

        CalibrationReportHelper.writeReport(prefix: "dist_2a_essence", content: report)

        if CalibrationTier.current.isCIGated {
            for category in StyleEssenceCategory.allCases {
                let count = data.essenceTop3Counts[category] ?? 0
                #expect(count >= 1,
                        "CI gate: \(category.rawValue) never appeared in top-3 across \(DistributionProfiles.allProfiles.count * dayCount) profile-days")
            }
        }
    }

    // MARK: - 2B: Palette Distribution

    @Test("2B — Palette colour name/role distribution across 5 profiles × 30 days")
    func testPaletteDistribution() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        let nameSorted = data.colourNameCounts.sorted { $0.value > $1.value }
            .map { (label: $0.key, count: $0.value) }
        let roleSorted = data.colourRoleCounts.sorted { $0.value > $1.value }
            .map { (label: $0.key, count: $0.value) }

        var report = CalibrationReportHelper.renderHistogram(
            title: "Palette — Colour Name Frequency",
            data: nameSorted
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "Palette — Colour Role Frequency",
            data: roleSorted
        )
        report += "\n--- Slot Regime ---\n"
        let totalSlots = data.statementSlotCount + data.groundingSlotCount
        report += "  Statement (core+accent): \(data.statementSlotCount)/\(totalSlots)"
        if totalSlots > 0 {
            report += " (\(String(format: "%.1f", Double(data.statementSlotCount) / Double(totalSlots) * 100))%)"
        }
        report += "\n"
        report += "  Grounding (neutral+support): \(data.groundingSlotCount)/\(totalSlots)"
        if totalSlots > 0 {
            report += " (\(String(format: "%.1f", Double(data.groundingSlotCount) / Double(totalSlots) * 100))%)"
        }
        report += "\n"

        CalibrationReportHelper.writeReport(prefix: "dist_2b_palette", content: report)
    }

    // MARK: - 2C: Vibrancy / Contrast / Metal Tone Distribution

    @Test("2C — Vibrancy, Contrast, Metal Tone histograms (10 bins)")
    func testVibrancyContrastMetalDistribution() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        var report = CalibrationReportHelper.renderNumericHistogram(
            title: "Vibrancy Distribution (0.0–1.0)",
            values: data.vibrancyValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "Vibrancy (all)", values: data.vibrancyValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Contrast Distribution (0.0–1.0)",
            values: data.contrastValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "Contrast (all)", values: data.contrastValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Metal Tone Distribution (0.0–1.0)",
            values: data.metalToneValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "MetalTone (all)", values: data.metalToneValues) + "\n\n"

        report += "--- Per-Profile Stats ---\n\n"
        for profile in DistributionProfiles.allProfiles {
            report += "  \(profile.name):\n"
            report += "  " + CalibrationReportHelper.summaryStats(label: "vibrancy", values: data.perProfileVibrancy[profile.name] ?? []) + "\n"
            report += "  " + CalibrationReportHelper.summaryStats(label: "contrast", values: data.perProfileContrast[profile.name] ?? []) + "\n"
            report += "  " + CalibrationReportHelper.summaryStats(label: "metalTone", values: data.perProfileMetalTone[profile.name] ?? []) + "\n\n"
        }

        CalibrationReportHelper.writeReport(prefix: "dist_2c_sliders", content: report)
    }

    // MARK: - 2D: Silhouette Profile Distribution

    @Test("2D — Silhouette scale histograms (masculineFeminine, angularRounded, structuredDraped)")
    func testSilhouetteDistribution() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        var report = CalibrationReportHelper.renderNumericHistogram(
            title: "Silhouette — Masculine↔Feminine (0.0–1.0)",
            values: data.mfValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "M↔F", values: data.mfValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Silhouette — Angular↔Rounded (0.0–1.0)",
            values: data.arValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "A↔R", values: data.arValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Silhouette — Structured↔Relaxed (0.0–1.0)",
            values: data.sdValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "S↔D", values: data.sdValues) + "\n\n"

        CalibrationReportHelper.writeReport(prefix: "dist_2d_silhouette", content: report)
    }

    // MARK: - 2E: Tarot Card Distribution

    @Test("2E — Tarot card frequency per profile across 30 days")
    func testTarotCardDistribution() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        let sorted = data.tarotCardCounts.sorted { $0.value > $1.value }
            .map { (label: $0.key, count: $0.value) }

        var report = CalibrationReportHelper.renderHistogram(
            title: "Tarot Card Distribution — All Profiles × \(dayCount) Days",
            data: sorted
        )

        report += "--- Per-Profile Tarot ---\n\n"
        for profile in DistributionProfiles.allProfiles {
            let profileCards = data.perProfileTarot[profile.name] ?? [:]
            let cardsSorted = profileCards.sorted { $0.value > $1.value }
            report += "  \(profile.name):\n"
            report += "    unique=\(profileCards.count)  "
            report += cardsSorted.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            report += "\n\n"
        }

        CalibrationReportHelper.writeReport(prefix: "dist_2e_tarot", content: report)

        for profile in DistributionProfiles.allProfiles {
            let profileCards = data.perProfileTarot[profile.name] ?? [:]
            for (card, count) in profileCards {
                #expect(count <= 3,
                        "\(profile.name): card '\(card)' appeared \(count)× in \(dayCount) days (max 3)")
            }
        }
    }

    // MARK: - 2F: Vibe Breakdown Distribution (all 6 energies)

    @Test("2F — Vibe Breakdown histograms for all 6 energies")
    func testVibeBreakdownDistribution() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        var report = ""
        for energy in Energy.allCases {
            let vals = data.vibeValues[energy] ?? []
            let counts = [Int](repeating: 0, count: 11)
            var buckets = counts
            for v in vals {
                let clamped = min(max(v, 0), 10)
                buckets[clamped] += 1
            }
            let histData = (0...10).map { (label: "\(energy.rawValue)=\($0)", count: buckets[$0]) }
            report += CalibrationReportHelper.renderHistogram(
                title: "\(energy.rawValue.uppercased()) Distribution (0–10, n=\(vals.count))",
                data: histData
            )
            let doubleVals = vals.map(Double.init)
            report += CalibrationReportHelper.summaryStats(label: energy.rawValue, values: doubleVals) + "\n\n"
        }

        report += "--- Per-Profile Vibe Summary ---\n\n"
        for profile in DistributionProfiles.allProfiles {
            report += "  \(profile.name):\n"
            let profileVibe = data.perProfileVibe[profile.name] ?? [:]
            for energy in Energy.allCases {
                let vals = profileVibe[energy] ?? []
                let avg = vals.isEmpty ? 0.0 : Double(vals.reduce(0, +)) / Double(vals.count)
                let minV = vals.min() ?? 0
                let maxV = vals.max() ?? 0
                report += "    \(energy.rawValue.padding(toLength: 10, withPad: " ", startingAt: 0)) avg=\(String(format: "%.1f", avg))  min=\(minV)  max=\(maxV)\n"
            }
            report += "\n"
        }

        CalibrationReportHelper.writeReport(prefix: "dist_2f_vibe", content: report)
    }

    // MARK: - Full Combined Distribution Report

    @Test("Generate full distribution report")
    func testGenerateFullDistributionReport() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let (data, _) = collectAllData()

        var report = "=== Daily Fit Distribution Report (Part 2) ===\n"
        report += "Generated: \(Date())\n"
        report += "Profiles: \(DistributionProfiles.allProfiles.count)\n"
        report += "Days per profile: \(dayCount)\n"
        report += "Total profile-days: \(DistributionProfiles.allProfiles.count * dayCount)\n\n"

        // ── 2A: Style Essence ──
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "  SECTION 2A: STYLE ESSENCE DISTRIBUTION\n"
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        let essenceSorted = StyleEssenceCategory.allCases.map { cat in
            (label: cat.rawValue, count: data.essenceTop3Counts[cat] ?? 0)
        }
        report += CalibrationReportHelper.renderHistogram(
            title: "Essence Top-3 Appearances",
            data: essenceSorted
        )
        for profile in DistributionProfiles.allProfiles {
            let pc = data.perProfileEssenceTop3[profile.name] ?? [:]
            let top = pc.sorted { $0.value > $1.value }.prefix(5)
            report += "  \(profile.name): \(top.map { "\($0.key.rawValue)=\($0.value)" }.joined(separator: ", "))\n"
        }
        report += "\n"

        // ── 2B: Palette ──
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "  SECTION 2B: PALETTE DISTRIBUTION\n"
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        let nameSorted = data.colourNameCounts.sorted { $0.value > $1.value }
            .map { (label: $0.key, count: $0.value) }
        report += CalibrationReportHelper.renderHistogram(
            title: "Colour Name Frequency", data: nameSorted
        )

        let roleSorted = data.colourRoleCounts.sorted { $0.value > $1.value }
            .map { (label: $0.key, count: $0.value) }
        report += CalibrationReportHelper.renderHistogram(
            title: "Colour Role Frequency", data: roleSorted
        )

        let totalSlots = data.statementSlotCount + data.groundingSlotCount
        report += "  Statement slots (core+accent): \(data.statementSlotCount)/\(totalSlots)\n"
        report += "  Grounding slots (neutral+support): \(data.groundingSlotCount)/\(totalSlots)\n\n"

        // ── 2C: Vibrancy / Contrast / Metal Tone ──
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "  SECTION 2C: VIBRANCY / CONTRAST / METAL TONE\n"
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Vibrancy (0.0–1.0)", values: data.vibrancyValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "Vibrancy", values: data.vibrancyValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Contrast (0.0–1.0)", values: data.contrastValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "Contrast", values: data.contrastValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Metal Tone (0.0–1.0)", values: data.metalToneValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "MetalTone", values: data.metalToneValues) + "\n\n"

        for profile in DistributionProfiles.allProfiles {
            report += "  \(profile.name):\n"
            report += "  " + CalibrationReportHelper.summaryStats(label: "vibrancy", values: data.perProfileVibrancy[profile.name] ?? []) + "\n"
            report += "  " + CalibrationReportHelper.summaryStats(label: "contrast", values: data.perProfileContrast[profile.name] ?? []) + "\n"
            report += "  " + CalibrationReportHelper.summaryStats(label: "metalTone", values: data.perProfileMetalTone[profile.name] ?? []) + "\n\n"
        }

        // ── 2D: Silhouette ──
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "  SECTION 2D: SILHOUETTE PROFILE\n"
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Masculine↔Feminine (0.0–1.0)", values: data.mfValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "M↔F", values: data.mfValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Angular↔Rounded (0.0–1.0)", values: data.arValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "A↔R", values: data.arValues) + "\n\n"

        report += CalibrationReportHelper.renderNumericHistogram(
            title: "Structured↔Relaxed (0.0–1.0)", values: data.sdValues,
            bucketCount: 10, rangeMin: 0.0, rangeMax: 1.0
        )
        report += CalibrationReportHelper.summaryStats(label: "S↔D", values: data.sdValues) + "\n\n"

        // ── 2E: Tarot ──
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "  SECTION 2E: TAROT CARD DISTRIBUTION\n"
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        let tarotSorted = data.tarotCardCounts.sorted { $0.value > $1.value }
            .map { (label: $0.key, count: $0.value) }
        report += CalibrationReportHelper.renderHistogram(
            title: "Tarot Card Frequency (all profiles)", data: tarotSorted
        )

        for profile in DistributionProfiles.allProfiles {
            let profileCards = data.perProfileTarot[profile.name] ?? [:]
            let cardsSorted = profileCards.sorted { $0.value > $1.value }
            report += "  \(profile.name) (unique=\(profileCards.count)):\n"
            report += "    \(cardsSorted.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))\n\n"
        }

        // ── 2F: Vibe Breakdown ──
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "  SECTION 2F: VIBE BREAKDOWN (ALL 6 ENERGIES)\n"
        report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

        for energy in Energy.allCases {
            let vals = data.vibeValues[energy] ?? []
            var buckets = [Int](repeating: 0, count: 11)
            for v in vals {
                buckets[min(max(v, 0), 10)] += 1
            }
            let histData = (0...10).map { (label: "\(energy.rawValue)=\($0)", count: buckets[$0]) }
            report += CalibrationReportHelper.renderHistogram(
                title: "\(energy.rawValue.uppercased()) (0–10, n=\(vals.count))",
                data: histData
            )
            report += CalibrationReportHelper.summaryStats(label: energy.rawValue, values: vals.map(Double.init)) + "\n\n"
        }

        for profile in DistributionProfiles.allProfiles {
            report += "  \(profile.name):\n"
            let profileVibe = data.perProfileVibe[profile.name] ?? [:]
            for energy in Energy.allCases {
                let vals = profileVibe[energy] ?? []
                let avg = vals.isEmpty ? 0.0 : Double(vals.reduce(0, +)) / Double(vals.count)
                let minV = vals.min() ?? 0
                let maxV = vals.max() ?? 0
                report += "    \(energy.rawValue.padding(toLength: 10, withPad: " ", startingAt: 0)) avg=\(String(format: "%.1f", avg))  min=\(minV)  max=\(maxV)\n"
            }
            report += "\n"
        }

        // ── Write combined report ──
        let url = CalibrationReportHelper.writeReport(prefix: "daily_fit_distribution", content: report)
        if let url {
            print("Distribution report written to: \(url.path)")
        }

        // CI-gated assertions
        if CalibrationTier.current.isCIGated {
            for category in StyleEssenceCategory.allCases {
                let count = data.essenceTop3Counts[category] ?? 0
                #expect(count >= 1,
                        "CI gate: essence category \(category.rawValue) never appeared in top-3")
            }

            for profile in DistributionProfiles.allProfiles {
                let profileCards = data.perProfileTarot[profile.name] ?? [:]
                for (card, count) in profileCards {
                    #expect(count <= 3,
                            "CI gate: \(profile.name) card '\(card)' appeared \(count)× (max 3)")
                }
            }
        }
    }
}
