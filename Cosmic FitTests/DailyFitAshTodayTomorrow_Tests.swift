//
//  DailyFitAshTodayTomorrow_Tests.swift
//  Cosmic FitTests
//
//  Reproduces the in-app "today vs tomorrow" Daily Fit scenario for Ash:
//  fresh generation (no frozen payload), production calibration, side-by-side report.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Harness Ash (mirrors CalibrationProfiles.ashProfile — Leo fire synthetic chart)

private enum HarnessAshProfile {
    static let fixedBaseDate: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: 2026, month: 5, day: 10))!
    }()

    static let hash = "cal_ash"

    static let natalChart: NatalChartCalculator.NatalChart = {
        chart(signs: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5])
    }()

    static let progressedChart: NatalChartCalculator.NatalChart = {
        chart(signs: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5])
    }()

    static func transitsForDay(_ dayOffset: Int) -> [NatalChartCalculator.TransitAspect] {
        let base = fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
        let configs: [(String, String, String, Double)] = [
            ("Mars", "Sun", "conjunction", 1.0 + Double(dayOffset % 3)),
            ("Venus", "Moon", "trine", 0.5 + Double(dayOffset % 4)),
            ("Jupiter", "Venus", "sextile", 2.0 + Double(dayOffset % 2)),
            ("Saturn", "Mercury", "square", 1.5),
            ("Pluto", "Mars", "opposition", 3.0 - Double(dayOffset % 3)),
        ]
        return configs.map { cfg in
            NatalChartCalculator.TransitAspect(
                transitPlanet: cfg.0, transitPlanetSymbol: "•",
                natalPlanet: cfg.1, natalPlanetSymbol: "•",
                aspectType: cfg.2, aspectSymbol: "•",
                orb: cfg.3, applying: true,
                effectiveFrom: base,
                effectiveTo: base.addingTimeInterval(86400 * 3),
                description: "\(cfg.0) \(cfg.2) \(cfg.1)",
                category: .shortTerm
            )
        }
    }

    static let calibrationBlueprint: CosmicBlueprint = {
        func colour(_ name: String, _ hex: String, _ role: ColourRole) -> BlueprintColour {
            BlueprintColour(
                name: name, hexValue: hex, role: role,
                provenance: .v4Template(family: "Cal", band: role.rawValue, index: 0)
            )
        }
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
            occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
            hardware: HardwareSection(
                metalsText: "Metals.", stonesText: "Stones.", tipText: "Tip.",
                recommendedMetals: ["gold", "brass", "copper"],
                recommendedStones: ["ruby"]
            ),
            code: CodeSection(leanInto: ["structured shoulders"], avoid: ["soft draping"], consider: ["angular lines"]),
            accessory: AccessorySection(paragraphs: ["A1.", "A2.", "A3."]),
            pattern: PatternSection(
                narrativeText: "Pattern.", tipText: "Tip.",
                recommendedPatterns: ["stripes", "herringbone"],
                avoidPatterns: ["neon"]
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }()

    private static func chart(signs: [Int]) -> NatalChartCalculator.NatalChart {
        let standardPlanets: [(String, String)] = [
            ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
            ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
            ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇"),
        ]
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
}

// MARK: - Shared helpers

private enum AshTodayTomorrowSupport {

    struct DayOutput {
        let label: String
        let date: Date
        let payload: DailyFitPayload
        let snapshot: DailyEnergySnapshot
    }

    struct ComparisonRow {
        let field: String
        let today: String
        let tomorrow: String
        let differs: Bool
    }

    static func resetTrackers() {
        let suiteName = "com.cosmicfit.tests.\(UUID().uuidString)"
        let isolated = UserDefaults(suiteName: suiteName)!
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: isolated)
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: isolated)
        BlueprintLensEngine._resetCardCache()
    }

    static func paletteNames(_ payload: DailyFitPayload) -> [String] {
        payload.dailyPalette.colours.map(\.name)
    }

    static func essenceLabels(_ payload: DailyFitPayload) -> [String] {
        payload.essenceProfile.visibleCategories.map(\.category.label)
    }

    static func vibeString(_ vibe: VibeBreakdown) -> String {
        "C\(vibe.classic) P\(vibe.playful) R\(vibe.romantic) U\(vibe.utility) D\(vibe.drama) E\(vibe.edge)"
    }

    static func compare(today: DayOutput, tomorrow: DayOutput) -> [ComparisonRow] {
        let tPal = paletteNames(today.payload)
        let mPal = paletteNames(tomorrow.payload)
        let tEss = essenceLabels(today.payload)
        let mEss = essenceLabels(tomorrow.payload)

        return [
            ComparisonRow(
                field: "Dominant energy",
                today: today.payload.vibeBreakdown.dominantEnergy.rawValue,
                tomorrow: tomorrow.payload.vibeBreakdown.dominantEnergy.rawValue,
                differs: today.payload.vibeBreakdown.dominantEnergy != tomorrow.payload.vibeBreakdown.dominantEnergy
            ),
            ComparisonRow(
                field: "Vibe (21 pts)",
                today: vibeString(today.payload.vibeBreakdown),
                tomorrow: vibeString(tomorrow.payload.vibeBreakdown),
                differs: vibeString(today.payload.vibeBreakdown) != vibeString(tomorrow.payload.vibeBreakdown)
            ),
            ComparisonRow(
                field: "Palette (all 3)",
                today: tPal.joined(separator: ", "),
                tomorrow: mPal.joined(separator: ", "),
                differs: tPal != mPal
            ),
            ComparisonRow(
                field: "Palette colour 1",
                today: tPal.indices.contains(0) ? tPal[0] : "—",
                tomorrow: mPal.indices.contains(0) ? mPal[0] : "—",
                differs: tPal.first != mPal.first
            ),
            ComparisonRow(
                field: "Palette colour 2",
                today: tPal.indices.contains(1) ? tPal[1] : "—",
                tomorrow: mPal.indices.contains(1) ? mPal[1] : "—",
                differs: tPal.count > 1 && mPal.count > 1 && tPal[1] != mPal[1]
            ),
            ComparisonRow(
                field: "Palette colour 3",
                today: tPal.indices.contains(2) ? tPal[2] : "—",
                tomorrow: mPal.indices.contains(2) ? mPal[2] : "—",
                differs: tPal.count > 2 && mPal.count > 2 && tPal[2] != mPal[2]
            ),
            ComparisonRow(
                field: "Vibrancy",
                today: String(format: "%.4f", today.payload.vibrancy),
                tomorrow: String(format: "%.4f", tomorrow.payload.vibrancy),
                differs: abs(today.payload.vibrancy - tomorrow.payload.vibrancy) > 0.0005
            ),
            ComparisonRow(
                field: "Contrast",
                today: String(format: "%.4f", today.payload.contrast),
                tomorrow: String(format: "%.4f", tomorrow.payload.contrast),
                differs: abs(today.payload.contrast - tomorrow.payload.contrast) > 0.0005
            ),
            ComparisonRow(
                field: "Metal tone",
                today: String(format: "%.4f", today.payload.metalTone),
                tomorrow: String(format: "%.4f", tomorrow.payload.metalTone),
                differs: abs(today.payload.metalTone - tomorrow.payload.metalTone) > 0.0005
            ),
            ComparisonRow(
                field: "Essence top 3",
                today: tEss.joined(separator: ", "),
                tomorrow: mEss.joined(separator: ", "),
                differs: tEss != mEss
            ),
            ComparisonRow(
                field: "Tarot card",
                today: today.payload.tarotCard.name,
                tomorrow: tomorrow.payload.tarotCard.name,
                differs: today.payload.tarotCard.name != tomorrow.payload.tarotCard.name
            ),
            ComparisonRow(
                field: "Daily seed",
                today: "\(today.snapshot.dailySeed)",
                tomorrow: "\(tomorrow.snapshot.dailySeed)",
                differs: today.snapshot.dailySeed != tomorrow.snapshot.dailySeed
            ),
        ]
    }

    static func buildReport(
        scenario: String,
        today: DayOutput,
        tomorrow: DayOutput,
        notes: [String] = []
    ) -> String {
        let fmt = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append("╔══════════════════════════════════════════════════════════════════")
        lines.append("║  ASH — TODAY vs TOMORROW (consecutive calendar days)")
        lines.append("║  Scenario: \(scenario)")
        lines.append("║  Calibration: production (.default)")
        lines.append("║  Generated: \(fmt.string(from: Date()))")
        lines.append("╚══════════════════════════════════════════════════════════════════")
        lines.append("")
        lines.append("Today:    \(fmt.string(from: today.date))  (seed \(today.snapshot.dailySeed))")
        lines.append("Tomorrow: \(fmt.string(from: tomorrow.date))  (seed \(tomorrow.snapshot.dailySeed))")
        lines.append("")
        if !notes.isEmpty {
            lines.append("Notes:")
            for note in notes { lines.append("  • \(note)") }
            lines.append("")
        }
        lines.append(String(format: "%-22s | %-28s | %-28s | diff", "Field", "Today", "Tomorrow"))
        lines.append(String(repeating: "─", count: 95))
        for row in compare(today: today, tomorrow: tomorrow) {
            let flag = row.differs ? "YES" : "no"
            lines.append(String(format: "%-22s | %-28s | %-28s | %@", row.field, row.today, row.tomorrow, flag))
        }
        lines.append("")
        let rows = compare(today: today, tomorrow: tomorrow)
        let changed = rows.filter(\.differs).map(\.field)
        lines.append("Changed: \(changed.isEmpty ? "(none)" : changed.joined(separator: ", "))")
        return lines.joined(separator: "\n")
    }

    /// Writes a timestamped copy plus a stable `docs/fixtures/ash_today_tomorrow_combined.txt` for easy inspection.
    @discardableResult
    static func writeReport(scenario: String, content: String) -> URL? {
        let dir = CalibrationReportHelper.reportDirectory()
        let stableURL = dir.appendingPathComponent("ash_today_tomorrow_combined.txt")
        try? content.write(to: stableURL, atomically: true, encoding: .utf8)
        _ = CalibrationReportHelper.writeReport(prefix: "ash_today_tomorrow_\(scenario)", content: content)
        return stableURL
    }

    /// Mirrors app behaviour: same progressed chart for both days; transits + moon vary by date.
    static func runConsecutiveDays(
        scenario: String,
        natal: NatalChartCalculator.NatalChart,
        progressed: NatalChartCalculator.NatalChart,
        blueprint: CosmicBlueprint,
        profileHash: String,
        baseDate: Date,
        transitsForDate: (Date) -> [NatalChartCalculator.TransitAspect]
    ) -> (today: DayOutput, tomorrow: DayOutput, report: String) {
        resetTrackers()
        let todayDate = baseDate
        let tomorrowDate = baseDate.addingTimeInterval(86400)

        func runDay(_ label: String, _ date: Date) -> DayOutput {
            let transits = transitsForDate(date)
            let jd = JulianDateCalculator.calculateJulianDate(from: date)
            let moon = AstronomicalCalculator.calculateLunarPhase(julianDay: jd)
            let snapshot = DailyEnergyEngine.generateSnapshot(
                natalChart: natal,
                progressedChart: progressed,
                transits: transits,
                moonPhaseDegrees: moon,
                profileHash: profileHash,
                date: date
            )
            let payload = BlueprintLensEngine.generatePayload(
                blueprint: blueprint,
                snapshot: snapshot
            )
            return DayOutput(label: label, date: date, payload: payload, snapshot: snapshot)
        }

        let today = runDay("today", todayDate)
        resetTrackers()
        let tomorrow = runDay("tomorrow", tomorrowDate)
        let report = buildReport(scenario: scenario, today: today, tomorrow: tomorrow)
        writeReport(scenario: scenario, content: report)
        return (today, tomorrow, report)
    }

    static func loadAshBlueprintFixture() throws -> CosmicBlueprint {
        let url = FixtureLocator.repoRoot()
            .appendingPathComponent("docs/house_sect_regression/input_after/ash.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "AshTodayTomorrow", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing ash.json at \(url.path)"])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CosmicBlueprint.self, from: data)
    }

    static let ashBirthDate: Date = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: "1984-12-11T00:00:00Z")!
    }()

    static let ashLatitude = 51.5074
    static let ashLongitude = -0.1278
    static let ashTimeZone = TimeZone(identifier: "Europe/London")!
}

// MARK: - Tests

@Suite(.serialized)
struct DailyFitAshTodayTomorrow_Tests {

    @Test("sanity — suite loads")
    func testSuiteLoads() {
        #expect(true)
    }

    /// Side-by-side today vs tomorrow for Ash harness profile (CI-safe, no large report I/O).
    @Test("Ash — today vs tomorrow harness varies between consecutive days")
    func testAshTodayVsTomorrowComparisonReport() {
        AshTodayTomorrowSupport.resetTrackers()
        let harnessBase = HarnessAshProfile.fixedBaseDate
        let todayDate = harnessBase
        let tomorrowDate = harnessBase.addingTimeInterval(86400)

        func runDay(_ date: Date) -> DailyFitPayload {
            let offset = Int(date.timeIntervalSince(harnessBase) / 86400)
            let transits = HarnessAshProfile.transitsForDay(offset)
            let jd = JulianDateCalculator.calculateJulianDate(from: date)
            let moon = AstronomicalCalculator.calculateLunarPhase(julianDay: jd)
            let snapshot = DailyEnergyEngine.generateSnapshot(
                natalChart: HarnessAshProfile.natalChart,
                progressedChart: HarnessAshProfile.progressedChart,
                transits: transits,
                moonPhaseDegrees: moon,
                profileHash: HarnessAshProfile.hash,
                date: date
            )
            return BlueprintLensEngine.generatePayload(
                blueprint: HarnessAshProfile.calibrationBlueprint,
                snapshot: snapshot
            )
        }

        let today = runDay(todayDate)
        AshTodayTomorrowSupport.resetTrackers()
        let tomorrow = runDay(tomorrowDate)

        let paletteDiffers = today.dailyPalette.colours.map(\.name) != tomorrow.dailyPalette.colours.map(\.name)
        let vibeDiffers = AshTodayTomorrowSupport.vibeString(today.vibeBreakdown)
            != AshTodayTomorrowSupport.vibeString(tomorrow.vibeBreakdown)

        // Phase 6c (plan G0 owner-priority (iii)): the former OR included
        // `seedDiffers = today.generatedAt != tomorrow.generatedAt`, which is ALWAYS true by
        // construction (distinct generation timestamps / render dates) — so the assert could never
        // fail even on a fully frozen palette+vibe. Drop it: consecutive days must differ in the
        // actual shown content (palette or vibe), not merely in the date seed.
        #expect(paletteDiffers || vibeDiffers,
                "Harness Ash: consecutive days should differ in palette or vibe (not just the date seed).")
    }

    /// Full side-by-side report (harness + optional real birth) — diagnostic only.
    @Test("Ash — today vs tomorrow comparison report (full)", .disabled("Diagnostic-only — writes fixture report; run locally"))
    func testAshTodayVsTomorrowComparisonReportFull() {
        var combined: [String] = []
        combined.append("ASH TODAY vs TOMORROW — IN-APP SCENARIO")
        combined.append("Compares consecutive calendar days with production calibration (.default).")
        combined.append("No frozen-payload cache (fresh generation each day).")
        combined.append("")

        let harnessBase = HarnessAshProfile.fixedBaseDate
        let harness = AshTodayTomorrowSupport.runConsecutiveDays(
            scenario: "harness",
            natal: HarnessAshProfile.natalChart,
            progressed: HarnessAshProfile.progressedChart,
            blueprint: HarnessAshProfile.calibrationBlueprint,
            profileHash: HarnessAshProfile.hash,
            baseDate: harnessBase,
            transitsForDate: { day in
                let offset = Int(day.timeIntervalSince(harnessBase) / 86400)
                return HarnessAshProfile.transitsForDay(offset)
            }
        )
        combined.append(harness.report)

        let hRows = AshTodayTomorrowSupport.compare(today: harness.today, tomorrow: harness.tomorrow)
        let url = AshTodayTomorrowSupport.writeReport(scenario: "combined", content: combined.joined(separator: "\n"))
        print(combined.joined(separator: "\n"))
        if let url {
            print("📄 Report written to: \(url.path)")
        }

        let hPalette = hRows.first { $0.field == "Palette (all 3)" }!
        let hPal1 = hRows.first { $0.field == "Palette colour 1" }!
        let hPal2 = hRows.first { $0.field == "Palette colour 2" }!
        print("Harness: palette=\(hPalette.differs) pal1=\(hPal1.differs) pal2=\(hPal2.differs)")

        #expect(hPalette.differs || hPal1.differs || hPal2.differs,
                "Harness Ash: consecutive days should vary palette — see report.")
    }

    /// Real Ash birth + saved Style Guide blueprint — diagnostic only (ephemeris path can crash in full suite).
    @Test("Ash — today vs tomorrow real birth diagnostic", .disabled("Diagnostic-only — run locally; ephemeris path unstable in full serial suite"))
    func testAshTodayVsTomorrowRealBirthDiagnostic() {
        var combined: [String] = []
        combined.append("REAL ASH (1984-12-11 London + docs/house_sect_regression/input_after/ash.json)")
        combined.append("")

        let blueprint: CosmicBlueprint
        do {
            blueprint = try AshTodayTomorrowSupport.loadAshBlueprintFixture()
        } catch {
            combined.append("⚠️ Could not load ash.json blueprint: \(error.localizedDescription)")
            _ = AshTodayTomorrowSupport.writeReport(scenario: "real_birth", content: combined.joined(separator: "\n"))
            return
        }

        let birth = AshTodayTomorrowSupport.ashBirthDate
        let tz = AshTodayTomorrowSupport.ashTimeZone

        guard let natal = ExtendedCalibrationProfiles.computeChart(
            from: ExtendedCalibrationProfiles.BirthSpec(
                id: "ash_fixture",
                label: "Ash (house sect fixture)",
                birthDateUTC: "1984-12-11T00:00:00Z",
                latitude: AshTodayTomorrowSupport.ashLatitude,
                longitude: AshTodayTomorrowSupport.ashLongitude,
                timeZoneId: tz.identifier
            )
        ) else {
            combined.append("⚠️ Skipped real-birth scenario: production ephemeris unavailable.")
            _ = AshTodayTomorrowSupport.writeReport(scenario: "real_birth", content: combined.joined(separator: "\n"))
            return
        }

        let age = NatalChartCalculator.calculateCurrentAge(from: birth)
        let progressed = NatalChartCalculator.calculateProgressedChart(
            birthDate: birth,
            targetAge: age,
            latitude: AshTodayTomorrowSupport.ashLatitude,
            longitude: AshTodayTomorrowSupport.ashLongitude,
            timeZone: tz
        )

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let realBase = cal.date(from: DateComponents(year: 2026, month: 5, day: 18))!

        let real = AshTodayTomorrowSupport.runConsecutiveDays(
            scenario: "real_birth",
            natal: natal,
            progressed: progressed,
            blueprint: blueprint,
            profileHash: "ash_user",
            baseDate: realBase,
            transitsForDate: { date in
                NatalChartCalculator.calculateTransits(natalChart: natal, date: date)
            }
        )
        combined.append(real.report)
        _ = AshTodayTomorrowSupport.writeReport(scenario: "real_birth", content: combined.joined(separator: "\n"))
    }

    /// 7-day comparison: dramaSlots vs coreAnchoredRanking for Ash harness profile.
    @Test("Ash — 7-day palette strategy comparison (dramaSlots vs coreAnchoredRanking)", .disabled("Diagnostic-only — writes comparison report; run locally"))
    func testAshSevenDayStrategyComparison() {
        let coreAnchoredCal: DailyFitCalibration = {
            let s2 = DailyFitCalibration.Stage2Sensitivity(
                paletteJitter: 0.08, vibrancyCoeff: 0.35,
                contrastCoeff: 0.40, silhouetteAxisScale: 2.0,
                metalNudgePerHit: 0.10,
                paletteSelectionStrategy: .coreAnchoredRanking
            )
            return DailyFitCalibration(
                sourceWeights: DailyFitCalibration.default.sourceWeights,
                signEnergyMap: DailyFitCalibration.default.signEnergyMap,
                signMultiplierPolicy: DailyFitCalibration.default.signMultiplierPolicy,
                planetAxisMap: DailyFitCalibration.default.planetAxisMap,
                selectionWeights: DailyFitCalibration.default.selectionWeights,
                axisTuning: DailyFitCalibration.default.axisTuning,
                stage2Sensitivity: s2
            )
        }()

        let days = 7
        var dramaSlotsResults: [[String]] = []
        var coreAnchoredResults: [[String]] = []

        for dayOffset in 0..<days {
            let date = HarnessAshProfile.fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
            let transits = HarnessAshProfile.transitsForDay(dayOffset)
            let jd = JulianDateCalculator.calculateJulianDate(from: date)
            let moon = AstronomicalCalculator.calculateLunarPhase(julianDay: jd)

            AshTodayTomorrowSupport.resetTrackers()
            let snapshot = DailyEnergyEngine.generateSnapshot(
                natalChart: HarnessAshProfile.natalChart,
                progressedChart: HarnessAshProfile.progressedChart,
                transits: transits,
                moonPhaseDegrees: moon,
                profileHash: HarnessAshProfile.hash,
                date: date
            )

            AshTodayTomorrowSupport.resetTrackers()
            let dramaPayload = BlueprintLensEngine.generatePayload(
                blueprint: HarnessAshProfile.calibrationBlueprint,
                snapshot: snapshot
            )

            AshTodayTomorrowSupport.resetTrackers()
            let corePayload = BlueprintLensEngine.generatePayload(
                blueprint: HarnessAshProfile.calibrationBlueprint,
                snapshot: snapshot,
                calibration: coreAnchoredCal
            )

            dramaSlotsResults.append(dramaPayload.dailyPalette.colours.map(\.name))
            coreAnchoredResults.append(corePayload.dailyPalette.colours.map(\.name))
        }

        print("\n══ 7-DAY STRATEGY COMPARISON (Ash harness) ══\n")
        print(String(format: "%-4s | %-50s | %-50s", "Day", "dramaSlots", "coreAnchoredRanking"))
        print(String(repeating: "─", count: 110))
        for i in 0..<days {
            let ds = dramaSlotsResults[i].joined(separator: ", ")
            let ca = coreAnchoredResults[i].joined(separator: ", ")
            print(String(format: "%-4d | %-50s | %-50s", i, ds, ca))
        }

        let dsUniqueSets = Set(dramaSlotsResults.map { $0.sorted().joined(separator: "|") })
        let caUniqueSets = Set(coreAnchoredResults.map { $0.sorted().joined(separator: "|") })

        let dsSlot3Values = Set(dramaSlotsResults.compactMap(\.last))
        let caSlot3Values = Set(coreAnchoredResults.compactMap(\.last))

        let dsAllColours = Set(dramaSlotsResults.flatMap { $0 })
        let caAllColours = Set(coreAnchoredResults.flatMap { $0 })

        let dsCoreCount = dramaSlotsResults.flatMap { $0 }.filter {
            HarnessAshProfile.calibrationBlueprint.palette.coreColours.map(\.name).contains($0)
        }.count
        let caCoreCount = coreAnchoredResults.flatMap { $0 }.filter {
            HarnessAshProfile.calibrationBlueprint.palette.coreColours.map(\.name).contains($0)
        }.count

        print("\n── Summary ──")
        print("                         dramaSlots    coreAnchored")
        print("Unique palette sets:     \(String(format: "%-14d", dsUniqueSets.count))\(caUniqueSets.count)")
        print("Distinct slot-3 values:  \(String(format: "%-14d", dsSlot3Values.count))\(caSlot3Values.count)")
        print("Distinct colours used:   \(String(format: "%-14d", dsAllColours.count))\(caAllColours.count)")
        print("Core appearances (of \(days*3)): \(String(format: "%-14d", dsCoreCount))\(caCoreCount)")
        print("")

        for i in 0..<days {
            let names = coreAnchoredResults[i]
            let coreNames = HarnessAshProfile.calibrationBlueprint.palette.coreColours.map(\.name)
            let hasCoreToday = names.contains(where: { coreNames.contains($0) })
            #expect(hasCoreToday,
                    "coreAnchoredRanking day \(i) missing core colour: \(names)")
        }
    }
}
