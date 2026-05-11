//
//  DailyFitCalibration_Tests.swift
//  Cosmic FitTests
//
//  Phase 6: Calibration & diagnostic test harness.
//  5 test profiles × 7-day sweep, 12 numbered tests (T6.1–T6.12),
//  plus a diagnostic report generator that writes to disk.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Profile Definitions

private enum CalibrationProfiles {

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

    static func chart(
        signs: [Int]
    ) -> NatalChartCalculator.NatalChart {
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

    // Sign indices: Aries=1..Pisces=12

    /// Leo Sun, Sagittarius Moon — fire-heavy. Expected: Drama + Playful dominant.
    static let ashProfile = ProfileDef(
        name: "ashProfile (Leo fire-heavy)",
        hash: "cal_ash",
        // Sun=Leo(5), Moon=Sag(9), Merc=Leo(5), Venus=Cancer(4), Mars=Aries(1),
        // Jup=Sag(9), Sat=Leo(5), Uranus=Aries(1), Nep=Sag(9), Pluto=Leo(5)
        natalSigns: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5],
        progressedSigns: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5],
        expectedDominant: [.drama, .playful]
    )

    /// Cancer Sun, Scorpio Moon, Pisces spread — water-heavy.
    static let waterDominant = ProfileDef(
        name: "waterDominant (Cancer/Scorpio/Pisces)",
        hash: "cal_water",
        natalSigns: [4, 8, 12, 4, 8, 12, 4, 8, 12, 4],
        progressedSigns: [4, 8, 12, 4, 8, 12, 4, 8, 12, 4],
        expectedDominant: [.romantic, .drama]
    )

    /// Virgo Sun, Taurus Moon, Capricorn spread — earth-heavy.
    static let earthGrounded = ProfileDef(
        name: "earthGrounded (Virgo/Taurus/Capricorn)",
        hash: "cal_earth",
        natalSigns: [6, 2, 10, 6, 2, 10, 6, 2, 10, 6],
        progressedSigns: [6, 2, 10, 6, 2, 10, 6, 2, 10, 6],
        expectedDominant: [.classic, .utility]
    )

    /// Gemini Sun, Aquarius Moon, Libra spread — air-heavy.
    static let airIntellectual = ProfileDef(
        name: "airIntellectual (Gemini/Aquarius/Libra)",
        hash: "cal_air",
        natalSigns: [3, 11, 7, 3, 11, 7, 3, 11, 7, 3],
        progressedSigns: [3, 11, 7, 3, 11, 7, 3, 11, 7, 3],
        expectedDominant: [.playful, .edge]
    )

    /// Aries Sun, Leo Moon, Sagittarius spread — fire-explosive.
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
            CalibrationProfiles.chart(signs: natalSigns)
        }
        var progressedChart: NatalChartCalculator.NatalChart {
            CalibrationProfiles.chart(signs: progressedSigns)
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

    static let emptyTransits: [NatalChartCalculator.TransitAspect] = []

    // MARK: Moon Phase Per Day

    static func moonPhaseForDay(_ dayOffset: Int) -> Double {
        let base = 45.0
        return (base + Double(dayOffset) * 12.86).truncatingRemainder(dividingBy: 360.0)
    }

    // MARK: Blueprint Fixtures

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
        calibration: DailyFitCalibration = .default,
        transits: [NatalChartCalculator.TransitAspect]? = nil
    ) -> DayRun {
        let date = fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
        let t = transits ?? transitsForDay(dayOffset)
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
        days: Int = 7,
        calibration: DailyFitCalibration = .default
    ) -> [DayRun] {
        (0..<days).map { runProfile(profile, dayOffset: $0, calibration: calibration) }
    }
}

// MARK: - Test Suite (serialized to avoid shared UserDefaults contention)

@Suite(.serialized)
struct DailyFitCalibration_Tests {

    private func resetTrackers() {
        let suiteName = "com.cosmicfit.tests.\(UUID().uuidString)"
        let isolated = UserDefaults(suiteName: suiteName)!
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: isolated)
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: isolated)
        BlueprintLensEngine._resetCardCache()
    }

    // MARK: - T6.1: All Profiles Produce Valid Output

    @Test("T6.1 — all 5 profiles produce valid DailyFitPayload")
    func testAllProfilesProduceValidOutput() {
        resetTrackers()
        for profile in CalibrationProfiles.allProfiles {
            let run = CalibrationProfiles.runProfile(profile, dayOffset: 0)
            let p = run.payload

            #expect(p.vibeBreakdown.totalPoints == 21,
                    "\(profile.name): vibe total = \(p.vibeBreakdown.totalPoints)")
            #expect(p.vibeBreakdown.isValid, "\(profile.name): vibe invalid")
            #expect(p.axes.action >= 1.0 && p.axes.action <= 10.0,
                    "\(profile.name): action out of range")
            #expect(p.axes.tempo >= 1.0 && p.axes.tempo <= 10.0)
            #expect(p.axes.strategy >= 1.0 && p.axes.strategy <= 10.0)
            #expect(p.axes.visibility >= 1.0 && p.axes.visibility <= 10.0)
            #expect(!p.tarotCard.name.isEmpty, "\(profile.name): no tarot card")
            #expect(p.dailyPalette.colours.count == 3,
                    "\(profile.name): palette count = \(p.dailyPalette.colours.count)")
        }
    }

    // MARK: - T6.2: Daily Variation Across 7 Days

    @Test("T6.2 — 7-day run produces ≥3 different tarot cards per profile; ≥3 dominant energies across all profiles")
    func testDailyVariationAcross7Days() {
        resetTrackers()
        var allDominants = Set<Energy>()
        for profile in CalibrationProfiles.allProfiles {
            let runs = CalibrationProfiles.runAllDays(profile)
            let cards = Set(runs.map(\.payload.tarotCard.name))
            let dominants = Set(runs.map(\.payload.vibeBreakdown.dominantEnergy))
            allDominants.formUnion(dominants)

            #expect(cards.count >= 3,
                    "\(profile.name): only \(cards.count) unique cards over 7 days — \(cards)")
        }
        // Cross-profile: the 5 distinct astrological profiles must produce varied dominant energies
        #expect(allDominants.count >= 3,
                "Across all 5 profiles × 7 days expected ≥3 distinct dominant energies, got \(allDominants.count)")
    }

    // MARK: - T6.3: Personality Consistency

    @Test("T6.3 — each profile's dominant energy aligns with expectation ≥5/7 days")
    func testPersonalityConsistency() {
        resetTrackers()
        for profile in CalibrationProfiles.allProfiles {
            let runs = CalibrationProfiles.runAllDays(profile)
            let matchCount = runs.filter { run in
                profile.expectedDominant.contains(run.payload.vibeBreakdown.dominantEnergy)
            }.count

            let expected = profile.expectedDominant.map(\.rawValue).joined(separator: ",")
            let got = runs.map(\.payload.vibeBreakdown.dominantEnergy.rawValue).joined(separator: ",")
            #expect(matchCount >= 5,
                    "\(profile.name): dominant matched \(matchCount)/7 (≥5). Expected: \(expected), Got: \(got)")
        }
    }

    // MARK: - T6.4: Transit Impact Visible

    @Test("T6.4 — same profile/date with vs without transits produces different output")
    func testTransitImpactVisible() {
        resetTrackers()
        let profile = CalibrationProfiles.ashProfile
        let withTransits = CalibrationProfiles.runProfile(profile, dayOffset: 0)
        resetTrackers()
        let withoutTransits = CalibrationProfiles.runProfile(
            profile, dayOffset: 0, transits: CalibrationProfiles.emptyTransits
        )

        let v1 = withTransits.payload.vibeBreakdown
        let v2 = withoutTransits.payload.vibeBreakdown
        let vibeChanged = v1.classic != v2.classic || v1.playful != v2.playful
            || v1.romantic != v2.romantic || v1.utility != v2.utility
            || v1.drama != v2.drama || v1.edge != v2.edge

        let a1 = withTransits.payload.axes
        let a2 = withoutTransits.payload.axes
        let axesChanged = abs(a1.action - a2.action) > 0.01
            || abs(a1.tempo - a2.tempo) > 0.01
            || abs(a1.strategy - a2.strategy) > 0.01
            || abs(a1.visibility - a2.visibility) > 0.01

        #expect(vibeChanged || axesChanged,
                "Expected transit impact to change either vibe or axes")
    }

    // MARK: - T6.5: Moon Cycle Variation

    @Test("T6.5 — new/first-quarter/full/last-quarter moon produce noticeably different output")
    func testMoonCycleVariation() {
        resetTrackers()
        let profile = CalibrationProfiles.ashProfile
        let phases: [(String, Double)] = [
            ("New Moon", 0.0), ("First Quarter", 90.0),
            ("Full Moon", 180.0), ("Last Quarter", 270.0),
        ]
        var axesResults: [(String, DerivedAxes)] = []
        for (name, degrees) in phases {
            resetTrackers()
            let date = CalibrationProfiles.fixedBaseDate
            let transits = CalibrationProfiles.transitsForDay(0)
            let (payload, _) = DailyFitDiagnostics.generateReport(
                natalChart: profile.natalChart,
                progressedChart: profile.progressedChart,
                transits: transits,
                moonPhaseDegrees: degrees,
                profileHash: profile.hash,
                blueprint: CalibrationProfiles.calibrationBlueprint,
                date: date
            )
            axesResults.append((name, payload.axes))
        }

        var pairsDiffer = 0
        for i in 0..<axesResults.count {
            for j in (i+1)..<axesResults.count {
                let a = axesResults[i].1
                let b = axesResults[j].1
                let diff = abs(a.action - b.action) + abs(a.tempo - b.tempo)
                    + abs(a.strategy - b.strategy) + abs(a.visibility - b.visibility)
                if diff > 0.1 { pairsDiffer += 1 }
            }
        }
        #expect(pairsDiffer >= 3,
                "Expected ≥3 axis pairs to differ noticeably across 4 moon phases, got \(pairsDiffer)")
    }

    // MARK: - T6.6: Calibration Weight Sensitivity

    @Test("T6.6 — changing transit weight from 0.25 to 0.50 changes output")
    func testCalibrationWeightSensitivity() {
        resetTrackers()
        let profile = CalibrationProfiles.ashProfile
        let defaultRun = CalibrationProfiles.runProfile(profile, dayOffset: 0)

        let heavyTransitWeights = DailyFitCalibration.SourceWeights(
            natal: 0.20, transits: 0.50, lunarPhase: 0.10,
            progressed: 0.15, currentSun: 0.05
        )
        let heavyTransitCal = DailyFitCalibration(
            sourceWeights: heavyTransitWeights,
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: DailyFitCalibration.default.selectionWeights
        )
        resetTrackers()
        let modifiedRun = CalibrationProfiles.runProfile(
            profile, dayOffset: 0, calibration: heavyTransitCal
        )

        let v1 = defaultRun.payload.vibeBreakdown
        let v2 = modifiedRun.payload.vibeBreakdown
        let changed = v1.classic != v2.classic || v1.playful != v2.playful
            || v1.romantic != v2.romantic || v1.utility != v2.utility
            || v1.drama != v2.drama || v1.edge != v2.edge
        #expect(changed, "Changing transit weight should alter the vibe breakdown")
    }

    // MARK: - T6.7: No Profile Produces Mono Energy

    @Test("T6.7 — no profile on any date has a single energy ≥12/21 points")
    func testNoProfileProducesMonoEnergy() {
        resetTrackers()
        for profile in CalibrationProfiles.allProfiles {
            let runs = CalibrationProfiles.runAllDays(profile)
            for run in runs {
                let v = run.payload.vibeBreakdown
                for energy in Energy.allCases {
                    let val = v.value(for: energy)
                    #expect(val < 12,
                            "\(profile.name) day \(run.dayOffset): \(energy.rawValue) = \(val), expected < 12")
                }
            }
        }
    }

    // MARK: - T6.8: Axes Spread Across Profiles

    @Test("T6.8 — across all profiles × 7 days, each axis has min ≤ 3.0 and max ≥ 7.0")
    func testAxesSpreadAcrossProfiles() {
        resetTrackers()
        var actionVals: [Double] = []
        var tempoVals: [Double] = []
        var strategyVals: [Double] = []
        var visibilityVals: [Double] = []

        for profile in CalibrationProfiles.allProfiles {
            let runs = CalibrationProfiles.runAllDays(profile)
            for run in runs {
                actionVals.append(run.payload.axes.action)
                tempoVals.append(run.payload.axes.tempo)
                strategyVals.append(run.payload.axes.strategy)
                visibilityVals.append(run.payload.axes.visibility)
            }
        }

        #expect(actionVals.min()! <= 3.0,
                "Action min = \(actionVals.min()!), expected ≤ 3.0")
        #expect(actionVals.max()! >= 7.0,
                "Action max = \(actionVals.max()!), expected ≥ 7.0")
        #expect(tempoVals.min()! <= 3.0,
                "Tempo min = \(tempoVals.min()!), expected ≤ 3.0")
        #expect(tempoVals.max()! >= 7.0,
                "Tempo max = \(tempoVals.max()!), expected ≥ 7.0")
        #expect(strategyVals.min()! <= 3.0,
                "Strategy min = \(strategyVals.min()!), expected ≤ 3.0")
        #expect(strategyVals.max()! >= 7.0,
                "Strategy max = \(strategyVals.max()!), expected ≥ 7.0")
        #expect(visibilityVals.min()! <= 3.0,
                "Visibility min = \(visibilityVals.min()!), expected ≤ 3.0")
        #expect(visibilityVals.max()! >= 7.0,
                "Visibility max = \(visibilityVals.max()!), expected ≥ 7.0")
    }

    // MARK: - T6.9: Palette From Blueprint Only

    @Test("T6.9 — every generated colour hex exists in the Blueprint's palette")
    func testPaletteFromBlueprintOnly() {
        resetTrackers()
        let bp = CalibrationProfiles.calibrationBlueprint
        var allBPHexes = Set<String>()
        if let n = bp.palette.neutrals { allBPHexes.formUnion(n.map(\.hexValue)) }
        allBPHexes.formUnion(bp.palette.coreColours.map(\.hexValue))
        allBPHexes.formUnion(bp.palette.accentColours.map(\.hexValue))
        if let s = bp.palette.supportColours { allBPHexes.formUnion(s.map(\.hexValue)) }
        if let l = bp.palette.luminarySignature { allBPHexes.insert(l.hexValue) }
        if let r = bp.palette.rulerSignature { allBPHexes.insert(r.hexValue) }

        for profile in CalibrationProfiles.allProfiles {
            let runs = CalibrationProfiles.runAllDays(profile)
            for run in runs {
                for pick in run.payload.dailyPalette.colours {
                    #expect(allBPHexes.contains(pick.hexValue),
                            "\(profile.name) day \(run.dayOffset): colour \(pick.name) (\(pick.hexValue)) not in Blueprint")
                }
            }
        }
    }

    // MARK: - T6.10: Diagnostic Report Complete

    @Test("T6.10 — diagnostic report has all fields populated")
    func testDiagnosticReportComplete() {
        resetTrackers()
        let run = CalibrationProfiles.runProfile(
            CalibrationProfiles.ashProfile, dayOffset: 0
        )
        let r = run.report

        #expect(!r.profileIdentifier.isEmpty)
        #expect(!r.rawEnergyScores.isEmpty)
        #expect(!r.postMultiplierScores.isEmpty)
        #expect(r.finalVibeBreakdown.isValid)
        #expect(!r.rawAxisScores.isEmpty)
        #expect(r.finalAxes.action >= 1.0 && r.finalAxes.action <= 10.0)
        #expect(r.dailySeed != 0)
        #expect(!r.tarotCardScores.isEmpty)
        #expect(!r.selectedTarotCard.isEmpty)
        #expect(r.variantRotationIndex >= 0 && r.variantRotationIndex <= 2)
        #expect(!r.selectedStyleEdit.isEmpty)
        #expect(r.paletteSelectionTrace.candidateCount > 0)
        #expect(!r.paletteSelectionTrace.selectedColours.isEmpty)
        #expect(!r.textureSelectionTrace.availableTextures.isEmpty)
        #expect(!r.textureSelectionTrace.scores.isEmpty)
        #expect(!r.textureSelectionTrace.selected.isEmpty)
        #expect(r.vibrancyTrace.finalValue >= 0.0 && r.vibrancyTrace.finalValue <= 1.0)
        #expect(r.contrastTrace.finalValue >= 0.0 && r.contrastTrace.finalValue <= 1.0)
        #expect(r.metalToneTrace.finalValue >= 0.0 && r.metalToneTrace.finalValue <= 1.0)
        #expect(r.essenceProfile.allScores.count == 14, "Expected 14 essence categories")
        #expect(r.essenceProfile.visibleCategories.count == 3, "Expected top-3 visible")
        #expect(!r.calibrationSnapshot.sourceWeights.isEmpty)
        #expect(!r.calibrationSnapshot.selectionWeights.isEmpty)
    }

    // MARK: - T6.11: Source Contributions Sum ≈ 1.0

    @Test("T6.11 — sourceContributions shares sum to ≈1.0 (±0.05)")
    func testDiagnosticReportSourceContributionsSum() {
        resetTrackers()
        let run = CalibrationProfiles.runProfile(
            CalibrationProfiles.ashProfile, dayOffset: 0
        )
        let c = run.report.sourceContributions
        let sum = c.natalShare + c.transitShare + c.lunarShare
            + c.progressedShare + c.currentSunShare
        #expect(abs(sum - 1.0) < 0.05,
                "Source contributions sum = \(sum), expected ≈1.0")
    }

    // MARK: - T6.12: Tarot Scores Ordered Descending

    @Test("T6.12 — tarotCardScores are sorted by totalScore descending")
    func testDiagnosticReportTarotScoresOrdered() {
        resetTrackers()
        let run = CalibrationProfiles.runProfile(
            CalibrationProfiles.ashProfile, dayOffset: 0
        )
        let scores = run.report.tarotCardScores
        #expect(!scores.isEmpty)
        for i in 1..<scores.count {
            #expect(scores[i - 1].totalScore >= scores[i].totalScore,
                    "Tarot scores not descending at index \(i): \(scores[i-1].totalScore) vs \(scores[i].totalScore)")
        }
    }

    // MARK: - Calibration Report Generator

    @Test("Generate calibration report to disk")
    func testGenerateCalibrationReport() {
        resetTrackers()
    var lines: [String] = []
    lines.append("=== Daily Fit Calibration Report ===")
    lines.append("Generated: \(Date())")
    lines.append("Calibration: DailyFitCalibration.default")
    lines.append("Profiles: \(CalibrationProfiles.allProfiles.count)")
    lines.append("Days per profile: 7")
    lines.append("")

    let cal = DailyFitCalibration.default
    lines.append("--- Source Weights ---")
    lines.append("  natal=\(cal.sourceWeights.natal), transits=\(cal.sourceWeights.transits), " +
                 "lunar=\(cal.sourceWeights.lunarPhase), progressed=\(cal.sourceWeights.progressed), " +
                 "currentSun=\(cal.sourceWeights.currentSun)")
    lines.append("--- Selection Weights ---")
    lines.append("  vibeWeight=\(cal.selectionWeights.vibeWeight), " +
                 "axisWeight=\(cal.selectionWeights.axisWeight), " +
                 "transitBoost=\(cal.selectionWeights.transitBoost)")
    lines.append("")

    for profile in CalibrationProfiles.allProfiles {
        resetTrackers()
        lines.append("========================================")
        lines.append("PROFILE: \(profile.name)")
        lines.append("Expected dominant: \(profile.expectedDominant.map(\.rawValue).joined(separator: ", "))")
        lines.append("========================================")

        let runs = CalibrationProfiles.runAllDays(profile)
        var dominantHits = 0

        for run in runs {
            let p = run.payload
            let r = run.report
            let dominant = p.vibeBreakdown.dominantEnergy
            let matchesExpected = profile.expectedDominant.contains(dominant)
            if matchesExpected { dominantHits += 1 }

            lines.append("")
            lines.append("  Day \(run.dayOffset) (\(formatDate(run.date)))")
            lines.append("    Moon: \(p.lunarContext.phaseName) (\(String(format: "%.0f", p.lunarContext.phaseDegrees))°)")
            lines.append("    Vibe: C=\(p.vibeBreakdown.classic) P=\(p.vibeBreakdown.playful) " +
                         "R=\(p.vibeBreakdown.romantic) U=\(p.vibeBreakdown.utility) " +
                         "D=\(p.vibeBreakdown.drama) E=\(p.vibeBreakdown.edge)  " +
                         "dominant=\(dominant.rawValue)\(matchesExpected ? " ✓" : " ✗")")
            lines.append("    Axes: action=\(f1(p.axes.action)) tempo=\(f1(p.axes.tempo)) " +
                         "strategy=\(f1(p.axes.strategy)) visibility=\(f1(p.axes.visibility))")
            lines.append("    Tarot: \(p.tarotCard.name) (variant \(p.styleEditVariant.variant))")
            lines.append("    Palette: \(p.dailyPalette.colours.map { "\($0.name) [\($0.role)]" }.joined(separator: ", "))")
            lines.append("    Vibrancy: \(f2(p.vibrancy)) (base=\(f2(r.vibrancyTrace.blueprintBaseline)), mod=\(f2(r.vibrancyTrace.modulation)))")
            lines.append("    Contrast: \(f2(p.contrast)) (base=\(f2(r.contrastTrace.blueprintBaseline)), mod=\(f2(r.contrastTrace.modulation)))")
            lines.append("    Metal Tone: \(f2(p.metalTone)) (base=\(f2(r.metalToneTrace.blueprintBaseline)), mod=\(f2(r.metalToneTrace.modulation)))")
            lines.append("    Essence: \(p.essenceProfile.visibleCategories.map { "\($0.category.label)=\(f2($0.score))" }.joined(separator: " "))")
            lines.append("    Silhouette: MF=\(f2(p.silhouetteProfile.masculineFeminine)) " +
                         "AR=\(f2(p.silhouetteProfile.angularRounded)) SD=\(f2(p.silhouetteProfile.structuredDraped))")
            lines.append("    Source shares: natal=\(f2(r.sourceContributions.natalShare)) " +
                         "transit=\(f2(r.sourceContributions.transitShare)) " +
                         "lunar=\(f2(r.sourceContributions.lunarShare)) " +
                         "progressed=\(f2(r.sourceContributions.progressedShare)) " +
                         "sun=\(f2(r.sourceContributions.currentSunShare))")
        }

        lines.append("")
        lines.append("  Summary: dominant matched \(dominantHits)/7 days")
        let uniqueCards = Set(runs.map(\.payload.tarotCard.name))
        lines.append("  Unique tarot cards: \(uniqueCards.count) — \(uniqueCards.sorted().joined(separator: ", "))")
        lines.append("")
    }

    // ── DRAMA HISTOGRAM (30-day sweep, all profiles) ──
    lines.append("")
    lines.append("╔══════════════════════════════════════════════════════════════")
    lines.append("║  DRAMA DISTRIBUTION — 30-Day Sweep × \(CalibrationProfiles.allProfiles.count) Profiles")
    lines.append("╚══════════════════════════════════════════════════════════════")
    lines.append("")

    var dramaCounts = [Int](repeating: 0, count: 11) // 0–10
    var regimeCounts: [String: Int] = ["quiet (0 stmt)": 0, "moderate (1 stmt)": 0, "bold (2 stmt)": 0]
    var perProfileDrama: [String: [Int]] = [:]

    for profile in CalibrationProfiles.allProfiles {
        resetTrackers()
        var profileValues: [Int] = []
        let runs30 = CalibrationProfiles.runAllDays(profile, days: 30)
        for run in runs30 {
            let drama = run.payload.vibeBreakdown.drama
            profileValues.append(drama)
            dramaCounts[drama] += 1
            if drama <= 2 {
                regimeCounts["quiet (0 stmt)", default: 0] += 1
            } else if drama <= 4 {
                regimeCounts["moderate (1 stmt)", default: 0] += 1
            } else {
                regimeCounts["bold (2 stmt)", default: 0] += 1
            }
        }
        perProfileDrama[profile.name] = profileValues
    }

    let totalSamples = CalibrationProfiles.allProfiles.count * 30
    lines.append("--- Aggregate Drama Histogram (n=\(totalSamples)) ---")
    lines.append("")
    let maxBar = dramaCounts.max() ?? 1
    for value in 0...10 {
        let count = dramaCounts[value]
        let pct = Double(count) / Double(totalSamples) * 100.0
        let barLen = maxBar > 0 ? Int(Double(count) / Double(maxBar) * 40.0) : 0
        let bar = String(repeating: "█", count: barLen) + String(repeating: "░", count: 40 - barLen)
        lines.append("  drama=\(String(format: "%2d", value))  \(bar)  \(String(format: "%3d", count)) (\(String(format: "%5.1f", pct))%)")
    }
    lines.append("")

    lines.append("--- Palette Slot Regime Distribution ---")
    lines.append("")
    for regime in ["quiet (0 stmt)", "moderate (1 stmt)", "bold (2 stmt)"] {
        let count = regimeCounts[regime, default: 0]
        let pct = Double(count) / Double(totalSamples) * 100.0
        lines.append("  \(regime.padding(toLength: 20, withPad: " ", startingAt: 0))  \(String(format: "%3d", count))/\(totalSamples) (\(String(format: "%5.1f", pct))%)")
    }
    lines.append("")

    lines.append("--- Per-Profile Drama Summary ---")
    lines.append("")
    for profile in CalibrationProfiles.allProfiles {
        let vals = perProfileDrama[profile.name] ?? []
        let avg = vals.isEmpty ? 0.0 : Double(vals.reduce(0, +)) / Double(vals.count)
        let minV = vals.min() ?? 0
        let maxV = vals.max() ?? 0
        let quiet = vals.filter { $0 <= 2 }.count
        let moderate = vals.filter { $0 >= 3 && $0 <= 4 }.count
        let bold = vals.filter { $0 >= 5 }.count
        lines.append("  \(profile.name)")
        lines.append("    avg=\(String(format: "%.1f", avg))  min=\(minV)  max=\(maxV)  quiet=\(quiet)  moderate=\(moderate)  bold=\(bold)")
        lines.append("    values: \(vals.map(String.init).joined(separator: " "))")
        lines.append("")
    }

    let output = lines.joined(separator: "\n")

    let docsDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("docs")
        .appendingPathComponent("fixtures")
    try? FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)
    let outputURL = docsDir.appendingPathComponent("daily_fit_calibration_report.txt")
    try? output.write(to: outputURL, atomically: true, encoding: .utf8)

    if let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
        let hostDir = URL(fileURLWithPath: hostHome)
            .appendingPathComponent("dev/mobile_apps/cosmicfit/docs/fixtures")
        try? FileManager.default.createDirectory(at: hostDir, withIntermediateDirectories: true)
        let hostURL = hostDir.appendingPathComponent("daily_fit_calibration_report.txt")
        try? output.write(to: hostURL, atomically: true, encoding: .utf8)
    }
}

    // MARK: - Formatting Helpers

    private func f1(_ v: Double) -> String { String(format: "%.1f", v) }
    private func f2(_ v: Double) -> String { String(format: "%.3f", v) }
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }
}
