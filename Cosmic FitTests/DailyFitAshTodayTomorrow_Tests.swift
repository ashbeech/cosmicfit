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

    /// Side-by-side today vs tomorrow for Ash — the exact in-app comparison.
    /// Writes `docs/fixtures/ash_today_tomorrow_*.txt` with both harness and real-birth scenarios.
    @Test("Ash — today vs tomorrow comparison report (harness + real birth)")
    func testAshTodayVsTomorrowComparisonReport() {
        var combined: [String] = []
        combined.append("ASH TODAY vs TOMORROW — IN-APP SCENARIO")
        combined.append("Compares consecutive calendar days with production calibration (.default).")
        combined.append("No frozen-payload cache (fresh generation each day).")
        combined.append("")

        // --- Scenario A: calibration harness (14-week exploration Ash profile) ---
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
        combined.append("\n")

        // --- Scenario B: real Ash birth + saved Style Guide blueprint fixture ---
        combined.append("══════════════════════════════════════════════════════════════════")
        combined.append("REAL ASH (1984-12-11 London + docs/house_sect_regression/input_after/ash.json)")
        combined.append("══════════════════════════════════════════════════════════════════")
        combined.append("")

        let blueprint: CosmicBlueprint
        do {
            blueprint = try AshTodayTomorrowSupport.loadAshBlueprintFixture()
        } catch {
            combined.append("⚠️ Could not load ash.json blueprint: \(error.localizedDescription)")
            let url = AshTodayTomorrowSupport.writeReport(scenario: "combined", content: combined.joined(separator: "\n"))
            print("📄 Report (partial): \(url?.path ?? "FAILED")")
            print("⚠️ ash.json decode failed: \(error)")
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
            let url = AshTodayTomorrowSupport.writeReport(scenario: "combined", content: combined.joined(separator: "\n"))
            print("Report: \(url?.path ?? "write failed")")
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

        let rRows = AshTodayTomorrowSupport.compare(today: real.today, tomorrow: real.tomorrow)
        let rPal1 = rRows.first { $0.field == "Palette colour 1" }!
        let rPal2 = rRows.first { $0.field == "Palette colour 2" }!
        let rPal3 = rRows.first { $0.field == "Palette colour 3" }!
        let rVibrancy = rRows.first { $0.field == "Vibrancy" }!
        let rContrast = rRows.first { $0.field == "Contrast" }!
        let rEssence = rRows.first { $0.field == "Essence top 3" }!

        combined.append("")
        combined.append("REAL ASH — matches user-reported stuck UI when:")
        combined.append("  • Palette 1 & 2 unchanged, only colour 3 changes: \( !rPal1.differs && !rPal2.differs && rPal3.differs )")
        combined.append("  • Vibrancy unchanged: \( !rVibrancy.differs )")
        combined.append("  • Contrast unchanged: \( !rContrast.differs )")
        combined.append("  • Essence top-3 unchanged: \( !rEssence.differs ) → \(AshTodayTomorrowSupport.essenceLabels(real.today.payload).joined(separator: ", "))")

        let hRows = AshTodayTomorrowSupport.compare(today: harness.today, tomorrow: harness.tomorrow)

        let url = AshTodayTomorrowSupport.writeReport(scenario: "combined", content: combined.joined(separator: "\n"))
        print(combined.joined(separator: "\n"))
        if let url {
            print("📄 Report written to: \(url.path)")
        } else {
            print("⚠️ Could not write report file — full output printed above.")
        }

        // Summary for CI log (report file has full tables).
        let hPalette = hRows.first { $0.field == "Palette (all 3)" }!
        let hPal1 = hRows.first { $0.field == "Palette colour 1" }!
        let hPal2 = hRows.first { $0.field == "Palette colour 2" }!
        let hVibrancy = hRows.first { $0.field == "Vibrancy" }!
        let hContrast = hRows.first { $0.field == "Contrast" }!

        print("Harness: palette=\(hPalette.differs) pal1=\(hPal1.differs) pal2=\(hPal2.differs) vibrancy=\(hVibrancy.differs) contrast=\(hContrast.differs)")
        print("Real Ash: pal1=\(rPal1.differs) pal2=\(rPal2.differs) pal3=\(rPal3.differs) vibrancy=\(rVibrancy.differs) contrast=\(rContrast.differs) essence=\(rEssence.differs)")

        if !hPalette.differs || (!hPal1.differs && !hPal2.differs) {
            print("⚠️ Harness Ash: consecutive days did not vary enough — see report.")
        }

        // Real Ash: flag if we reproduce the on-device pattern (diagnostic only).
        if !rPal1.differs && !rPal2.differs {
            print("⚠️ REAL ASH reproduces user pattern: first two palette colours match between today and tomorrow.")
        }
    }
}
