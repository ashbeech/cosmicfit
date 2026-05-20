//
//  DailyFitCalibrationExploration_Tests.swift
//  Cosmic FitTests
//
//  Calibration exploration: runs 5 profiles × 98 days (14 weeks)
//  across multiple DailyFitCalibration presets and writes
//  per-user per-day tables to disk for comparison.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Shared Test Infrastructure

private enum ExplorationProfiles {

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

    struct ProfileDef {
        let name: String
        let hash: String
        let natalSigns: [Int]
        let progressedSigns: [Int]

        var natalChart: NatalChartCalculator.NatalChart {
            ExplorationProfiles.chart(signs: natalSigns)
        }
        var progressedChart: NatalChartCalculator.NatalChart {
            ExplorationProfiles.chart(signs: progressedSigns)
        }
    }

    static let ashProfile = ProfileDef(
        name: "ash (Leo fire)",
        hash: "cal_ash",
        natalSigns: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5],
        progressedSigns: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5]
    )

    static let waterDominant = ProfileDef(
        name: "water (Cancer/Scorpio/Pisces)",
        hash: "cal_water",
        natalSigns: [4, 8, 12, 4, 8, 12, 4, 8, 12, 4],
        progressedSigns: [4, 8, 12, 4, 8, 12, 4, 8, 12, 4]
    )

    static let earthGrounded = ProfileDef(
        name: "earth (Virgo/Taurus/Cap)",
        hash: "cal_earth",
        natalSigns: [6, 2, 10, 6, 2, 10, 6, 2, 10, 6],
        progressedSigns: [6, 2, 10, 6, 2, 10, 6, 2, 10, 6]
    )

    static let airIntellectual = ProfileDef(
        name: "air (Gemini/Aqua/Libra)",
        hash: "cal_air",
        natalSigns: [3, 11, 7, 3, 11, 7, 3, 11, 7, 3],
        progressedSigns: [3, 11, 7, 3, 11, 7, 3, 11, 7, 3]
    )

    static let fireExplosive = ProfileDef(
        name: "fire (Aries/Leo/Sag)",
        hash: "cal_fire",
        natalSigns: [1, 5, 9, 1, 5, 9, 1, 5, 9, 1],
        progressedSigns: [1, 5, 9, 1, 5, 9, 1, 5, 9, 1]
    )

    static let allProfiles = [ashProfile, waterDominant, earthGrounded, airIntellectual, fireExplosive]

    // MARK: Transit & Moon Factories

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

    struct DayResult {
        let dayOffset: Int
        let date: Date
        let moonPhase: String
        let dominantEnergy: String
        let secondaryEnergy: String
        let vibeString: String
        let tarotCard: String
        let variantIndex: String
        let palette: String
        let vibrancy: Double
        let contrast: Double
        let metalTone: Double
        let essenceTop3: String
        let silhouetteMF: Double
        let silhouetteAR: Double
        let silhouetteSD: Double
        let axisAction: Double
        let axisTempo: Double
        let axisStrategy: Double
        let axisVisibility: Double
        let pattern: String
    }

    static func runDay(
        profile: ProfileDef,
        dayOffset: Int,
        calibration: DailyFitCalibration,
        dailyFitEngineId: String? = nil
    ) -> DayResult {
        let date = fixedBaseDate.addingTimeInterval(Double(dayOffset) * 86400)
        let t = transitsForDay(dayOffset)
        let moon = moonPhaseForDay(dayOffset)
        let (payload, _) = DailyFitDiagnostics.generateReport(
            natalChart: profile.natalChart,
            progressedChart: profile.progressedChart,
            transits: t,
            moonPhaseDegrees: moon,
            profileHash: profile.hash,
            blueprint: calibrationBlueprint,
            date: date,
            calibration: calibration,
            dailyFitEngineId: dailyFitEngineId
        )

        let vibe = payload.vibeBreakdown
        let vibeStr = "C\(vibe.classic) P\(vibe.playful) R\(vibe.romantic) U\(vibe.utility) D\(vibe.drama) E\(vibe.edge)"
        let paletteStr = payload.dailyPalette.colours.map(\.name).joined(separator: ", ")
        let top3 = payload.essenceProfile.visibleCategories.map {
            "\($0.category.label)(\(String(format: "%.2f", $0.score)))"
        }.joined(separator: " ")
        let moonName = payload.lunarContext.phaseName

        return DayResult(
            dayOffset: dayOffset,
            date: date,
            moonPhase: moonName,
            dominantEnergy: vibe.dominantEnergy.rawValue,
            secondaryEnergy: vibe.secondaryEnergy.rawValue,
            vibeString: vibeStr,
            tarotCard: payload.tarotCard.name,
            variantIndex: payload.styleEditVariant.variant,
            palette: paletteStr,
            vibrancy: payload.vibrancy,
            contrast: payload.contrast,
            metalTone: payload.metalTone,
            essenceTop3: top3,
            silhouetteMF: payload.silhouetteProfile.masculineFeminine,
            silhouetteAR: payload.silhouetteProfile.angularRounded,
            silhouetteSD: payload.silhouetteProfile.structuredDraped,
            axisAction: payload.axes.action,
            axisTempo: payload.axes.tempo,
            axisStrategy: payload.axes.strategy,
            axisVisibility: payload.axes.visibility,
            pattern: payload.dailyPattern ?? "—"
        )
    }
}

// MARK: - Summary Metrics

private struct PresetSummary {
    let presetName: String
    let profileName: String
    let days: Int
    let uniqueTarotCards: Int
    let dominantEnergyChanges: Int
    let vibeIntegerChangeRate: Double
    let avgPaletteChurn: Double
    let vibrancyStddev: Double
    let contrastStddev: Double
    let metalToneStddev: Double
    let silhouetteMFStddev: Double
    let silhouetteARStddev: Double
    let silhouetteSDStddev: Double
    let axisActionStddev: Double
    let axisTempoStddev: Double
    let axisStrategyStddev: Double
    let axisVisibilityStddev: Double
    let uniqueVariants: Int
}

private func stddev(_ values: [Double]) -> Double {
    guard values.count > 1 else { return 0.0 }
    let mean = values.reduce(0, +) / Double(values.count)
    let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
    return sqrt(variance)
}

// MARK: - Date Formatter

private let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = TimeZone(secondsFromGMT: 0)
    return f
}()

// MARK: - Test Suite

@Suite(.serialized)
struct DailyFitCalibrationExploration_Tests {

    private static let totalDays = 98 // 14 weeks

    // MARK: - Full Exploration Run

    @Test("Calibration Exploration — 5 profiles × 98 days × all presets → per-day tables")
    func runFullExploration() {
        TarotCalibrationTestSupport.installIsolatedTrackers()

        var allOutput: [String] = []
        var summaries: [PresetSummary] = []

        allOutput.append("╔══════════════════════════════════════════════════════════════════════════════════")
        allOutput.append("║  DAILY FIT CALIBRATION EXPLORATION — 14-WEEK COMPARISON")
        allOutput.append("║  Generated: \(Date())")
        allOutput.append("║  Days: \(Self.totalDays) (14 weeks from \(dayFormatter.string(from: ExplorationProfiles.fixedBaseDate)))")
        allOutput.append("║  Profiles: \(ExplorationProfiles.allProfiles.count)")
        allOutput.append("║  Presets: \(DailyFitEngineRegistry.allDescriptors.count)")
        allOutput.append("╚══════════════════════════════════════════════════════════════════════════════════")
        allOutput.append("")

        // Print preset configurations for reference
        allOutput.append("━━━ PRESET CONFIGURATIONS ━━━")
        for descriptor in DailyFitEngineRegistry.allDescriptors {
            let presetName = descriptor.id.uppercased()
            let cal = descriptor.calibration
            allOutput.append("  \(presetName):")
            let sw = cal.sourceWeights
            let sel = cal.selectionWeights
            allOutput.append("    Source: natal=\(sw.natal) transit=\(sw.transits) lunar=\(sw.lunarPhase) progressed=\(sw.progressed) sun=\(sw.currentSun)")
            allOutput.append("    Selection: vibe=\(sel.vibeWeight) axis=\(sel.axisWeight) transitBoost=\(sel.transitBoost)")
            let at = cal.axisTuning
            allOutput.append("    Axis: sigmoid=\(at.sigmoidSpread) jitter=±\(at.jitterRange)")
            let s2 = cal.stage2Sensitivity
            allOutput.append("    Stage2: paletteJitter=\(s2.paletteJitter) vibrancyCoeff=\(s2.vibrancyCoeff) contrastCoeff=\(s2.contrastCoeff) silhouetteScale=\(s2.silhouetteAxisScale) metalNudge=\(s2.metalNudgePerHit)")
        }
        allOutput.append("")

        for descriptor in DailyFitEngineRegistry.allDescriptors {
            let presetName = descriptor.id.uppercased()
            let calibration = descriptor.calibration
            allOutput.append("╔══════════════════════════════════════════════════════════════════════════════════")
            allOutput.append("║  PRESET: \(presetName)")
            allOutput.append("╚══════════════════════════════════════════════════════════════════════════════════")
            allOutput.append("")

            for profile in ExplorationProfiles.allProfiles {
                TarotCalibrationTestSupport.resetTrackersForProfile()

                var results: [ExplorationProfiles.DayResult] = []
                for day in 0..<Self.totalDays {
                    let r = ExplorationProfiles.runDay(
                        profile: profile,
                        dayOffset: day,
                        calibration: calibration,
                        dailyFitEngineId: descriptor.id
                    )
                    results.append(r)
                }

                // Build per-day table
                allOutput.append("┌─── PROFILE: \(profile.name) ───┐")
                allOutput.append("")
                allOutput.append(buildDayTable(results))
                allOutput.append("")

                // Compute summary metrics
                let summary = computeSummary(
                    presetName: presetName,
                    profileName: profile.name,
                    results: results
                )
                summaries.append(summary)

                allOutput.append(buildSummaryBlock(summary))
                allOutput.append("")
            }
        }

        // Final comparison table across all presets
        allOutput.append("╔══════════════════════════════════════════════════════════════════════════════════")
        allOutput.append("║  COMPARISON SUMMARY — ALL PRESETS × ALL PROFILES")
        allOutput.append("╚══════════════════════════════════════════════════════════════════════════════════")
        allOutput.append("")
        allOutput.append(buildComparisonTable(summaries))

        let content = allOutput.joined(separator: "\n")
        CalibrationReportHelper.writeReport(
            prefix: "calibration_exploration_98day",
            content: content
        )
    }

    // MARK: - Table Builders

    private func buildDayTable(_ results: [ExplorationProfiles.DayResult]) -> String {
        var lines: [String] = []

        let header = "Day | Date       | Moon            | Dominant | Vibe               | Tarot                  | Var | Palette                              | Vibr  | Cont  | Metal | M/F   | A/R   | S/D   | Action| Tempo | Strat | Vis   | Pattern"
        let sep = String(repeating: "─", count: header.count)
        lines.append(header)
        lines.append(sep)

        for r in results {
            let dateStr = dayFormatter.string(from: r.date)
            let moonPad = r.moonPhase.padding(toLength: 15, withPad: " ", startingAt: 0)
            let domPad = r.dominantEnergy.padding(toLength: 8, withPad: " ", startingAt: 0)
            let vibePad = r.vibeString.padding(toLength: 18, withPad: " ", startingAt: 0)
            let tarotPad = r.tarotCard.padding(toLength: 22, withPad: " ", startingAt: 0)
            let palettePad = r.palette.padding(toLength: 36, withPad: " ", startingAt: 0)
            let patPad = r.pattern.padding(toLength: 7, withPad: " ", startingAt: 0)

            let line = String(format: "%3d | %@ | %@ | %@ | %@ | %@ | %@  | %@ | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %.1f  | %.1f  | %.1f  | %.1f  | %@",
                r.dayOffset,
                dateStr,
                moonPad,
                domPad,
                vibePad,
                tarotPad,
                r.variantIndex,
                palettePad,
                r.vibrancy,
                r.contrast,
                r.metalTone,
                r.silhouetteMF,
                r.silhouetteAR,
                r.silhouetteSD,
                r.axisAction,
                r.axisTempo,
                r.axisStrategy,
                r.axisVisibility,
                patPad
            )
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    private func computeSummary(
        presetName: String,
        profileName: String,
        results: [ExplorationProfiles.DayResult]
    ) -> PresetSummary {
        let days = results.count

        let uniqueTarot = Set(results.map(\.tarotCard)).count

        var domChanges = 0
        for i in 1..<results.count {
            if results[i].dominantEnergy != results[i - 1].dominantEnergy {
                domChanges += 1
            }
        }

        var vibeChangeDays = 0
        for i in 1..<results.count {
            if results[i].vibeString != results[i - 1].vibeString {
                vibeChangeDays += 1
            }
        }
        let vibeChangeRate = Double(vibeChangeDays) / Double(max(days - 1, 1))

        var paletteChurns: [Double] = []
        for i in 1..<results.count {
            let prev = Set(results[i - 1].palette.components(separatedBy: ", "))
            let curr = Set(results[i].palette.components(separatedBy: ", "))
            let changed = prev.symmetricDifference(curr).count
            let total = max(prev.count, curr.count, 1)
            paletteChurns.append(Double(changed) / Double(total))
        }
        let avgChurn = paletteChurns.isEmpty ? 0.0 : paletteChurns.reduce(0, +) / Double(paletteChurns.count)

        let vibrancyStd = stddev(results.map(\.vibrancy))
        let contrastStd = stddev(results.map(\.contrast))
        let metalToneStd = stddev(results.map(\.metalTone))
        let silMFStd = stddev(results.map(\.silhouetteMF))
        let silARStd = stddev(results.map(\.silhouetteAR))
        let silSDStd = stddev(results.map(\.silhouetteSD))
        let actionStd = stddev(results.map(\.axisAction))
        let tempoStd = stddev(results.map(\.axisTempo))
        let strategyStd = stddev(results.map(\.axisStrategy))
        let visibilityStd = stddev(results.map(\.axisVisibility))

        let uniqueVars = Set(results.map(\.variantIndex)).count

        return PresetSummary(
            presetName: presetName,
            profileName: profileName,
            days: days,
            uniqueTarotCards: uniqueTarot,
            dominantEnergyChanges: domChanges,
            vibeIntegerChangeRate: vibeChangeRate,
            avgPaletteChurn: avgChurn,
            vibrancyStddev: vibrancyStd,
            contrastStddev: contrastStd,
            metalToneStddev: metalToneStd,
            silhouetteMFStddev: silMFStd,
            silhouetteARStddev: silARStd,
            silhouetteSDStddev: silSDStd,
            axisActionStddev: actionStd,
            axisTempoStddev: tempoStd,
            axisStrategyStddev: strategyStd,
            axisVisibilityStddev: visibilityStd,
            uniqueVariants: uniqueVars
        )
    }

    private func buildSummaryBlock(_ s: PresetSummary) -> String {
        var lines: [String] = []
        lines.append("  ┌─ Summary: \(s.profileName) × \(s.presetName) ─┐")
        lines.append("  │ Unique tarot cards:       \(s.uniqueTarotCards)/\(s.days)")
        lines.append("  │ Dominant energy changes:  \(s.dominantEnergyChanges)/\(s.days - 1) days")
        lines.append("  │ Vibe integer change rate: \(String(format: "%.1f%%", s.vibeIntegerChangeRate * 100))")
        lines.append("  │ Avg palette churn:        \(String(format: "%.3f", s.avgPaletteChurn))")
        lines.append("  │ Vibrancy stddev:          \(String(format: "%.5f", s.vibrancyStddev))")
        lines.append("  │ Contrast stddev:          \(String(format: "%.5f", s.contrastStddev))")
        lines.append("  │ Metal tone stddev:        \(String(format: "%.5f", s.metalToneStddev))")
        lines.append("  │ Silhouette stddev (M/A/S): \(String(format: "%.5f / %.5f / %.5f", s.silhouetteMFStddev, s.silhouetteARStddev, s.silhouetteSDStddev))")
        lines.append("  │ Axis stddev (A/T/S/V):    \(String(format: "%.3f / %.3f / %.3f / %.3f", s.axisActionStddev, s.axisTempoStddev, s.axisStrategyStddev, s.axisVisibilityStddev))")
        lines.append("  │ Unique variants (I/II/III): \(s.uniqueVariants)")
        lines.append("  └───────────────────────────────────┘")
        return lines.joined(separator: "\n")
    }

    private func buildComparisonTable(_ summaries: [PresetSummary]) -> String {
        var lines: [String] = []

        let header = "Preset                  | Profile                    | Tarot | Dom.Chg | Vibe%  | PalChurn | Vib.σ   | Con.σ   | Met.σ   | Sil.MF.σ| Sil.AR.σ| Sil.SD.σ| AxA.σ  | AxT.σ  | AxS.σ  | AxV.σ  | Vars"
        let sep = String(repeating: "─", count: header.count)
        lines.append(header)
        lines.append(sep)

        for s in summaries {
            let preset = s.presetName.padding(toLength: 23, withPad: " ", startingAt: 0)
            let profile = s.profileName.padding(toLength: 26, withPad: " ", startingAt: 0)
            let line = String(format: "%@ | %@ | %5d | %7d | %5.1f%% | %8.3f | %7.5f | %7.5f | %7.5f | %7.5f | %7.5f | %7.5f | %6.3f | %6.3f | %6.3f | %6.3f | %4d",
                preset,
                profile,
                s.uniqueTarotCards,
                s.dominantEnergyChanges,
                s.vibeIntegerChangeRate * 100,
                s.avgPaletteChurn,
                s.vibrancyStddev,
                s.contrastStddev,
                s.metalToneStddev,
                s.silhouetteMFStddev,
                s.silhouetteARStddev,
                s.silhouetteSDStddev,
                s.axisActionStddev,
                s.axisTempoStddev,
                s.axisStrategyStddev,
                s.axisVisibilityStddev,
                s.uniqueVariants
            )
            lines.append(line)
        }

        // Per-preset averages
        lines.append(sep)
        lines.append("")
        lines.append("AVERAGES PER PRESET:")
        lines.append("")
        let presetNames = DailyFitEngineRegistry.allDescriptors.map { $0.id.uppercased() }
        let avgHeader = "Preset                  | Tarot | Dom.Chg | Vibe%  | PalChurn | Vib.σ   | Con.σ   | Met.σ   | Sil.MF.σ| Sil.AR.σ| Sil.SD.σ| Vars"
        lines.append(avgHeader)
        lines.append(String(repeating: "─", count: avgHeader.count))
        for name in presetNames {
            let group = summaries.filter { $0.presetName == name }
            guard !group.isEmpty else { continue }
            let n = Double(group.count)
            let avgTarot = Double(group.map(\.uniqueTarotCards).reduce(0, +)) / n
            let avgDom = Double(group.map(\.dominantEnergyChanges).reduce(0, +)) / n
            let avgVibe = group.map(\.vibeIntegerChangeRate).reduce(0, +) / n
            let avgPal = group.map(\.avgPaletteChurn).reduce(0, +) / n
            let avgVibStd = group.map(\.vibrancyStddev).reduce(0, +) / n
            let avgConStd = group.map(\.contrastStddev).reduce(0, +) / n
            let avgMetStd = group.map(\.metalToneStddev).reduce(0, +) / n
            let avgSilMF = group.map(\.silhouetteMFStddev).reduce(0, +) / n
            let avgSilAR = group.map(\.silhouetteARStddev).reduce(0, +) / n
            let avgSilSD = group.map(\.silhouetteSDStddev).reduce(0, +) / n
            let avgVars = Double(group.map(\.uniqueVariants).reduce(0, +)) / n

            let preset = name.padding(toLength: 23, withPad: " ", startingAt: 0)
            let line = String(format: "%@ | %5.1f | %7.1f | %5.1f%% | %8.3f | %7.5f | %7.5f | %7.5f | %7.5f | %7.5f | %7.5f | %4.1f",
                preset, avgTarot, avgDom, avgVibe * 100, avgPal, avgVibStd, avgConStd, avgMetStd, avgSilMF, avgSilAR, avgSilSD, avgVars)
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Ash today vs tomorrow (in-app scenario)

    @Test("Ash — today vs tomorrow under production calibration → docs/fixtures/ash_today_tomorrow_combined.txt")
    func ashTodayVsTomorrowStableReport() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        let profile = ExplorationProfiles.ashProfile
        let production = DailyFitCalibration.default

        TarotCalibrationTestSupport.resetTrackersForProfile()
        let today = ExplorationProfiles.runDay(
            profile: profile, dayOffset: 0, calibration: production
        )
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let tomorrow = ExplorationProfiles.runDay(
            profile: profile, dayOffset: 1, calibration: production
        )

        var lines: [String] = []
        lines.append("╔══════════════════════════════════════════════════════════════════")
        lines.append("║  ASH — TODAY vs TOMORROW (consecutive days)")
        lines.append("║  Profile: \(profile.name)")
        lines.append("║  Calibration: PRODUCTION (.default)")
        lines.append("║  Base date: \(dayFormatter.string(from: ExplorationProfiles.fixedBaseDate))")
        lines.append("╚══════════════════════════════════════════════════════════════════")
        lines.append("")
        lines.append(buildDayTable([today, tomorrow]))
        lines.append("")

        let tPal = today.palette.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let mPal = tomorrow.palette.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        lines.append("COMPARISON (what you see in the app)")
        lines.append("  Palette 1:  today=\(tPal.indices.contains(0) ? tPal[0] : "—")  tomorrow=\(mPal.indices.contains(0) ? mPal[0] : "—")  differs=\(tPal.first != mPal.first)")
        lines.append("  Palette 2:  today=\(tPal.indices.contains(1) ? tPal[1] : "—")  tomorrow=\(mPal.indices.contains(1) ? mPal[1] : "—")  differs=\(tPal.count > 1 && mPal.count > 1 && tPal[1] != mPal[1])")
        lines.append("  Palette 3:  today=\(tPal.indices.contains(2) ? tPal[2] : "—")  tomorrow=\(mPal.indices.contains(2) ? mPal[2] : "—")  differs=\(tPal.count > 2 && mPal.count > 2 && tPal[2] != mPal[2])")
        lines.append(String(format: "  Vibrancy:   today=%.4f  tomorrow=%.4f  differs=%@", today.vibrancy, tomorrow.vibrancy, abs(today.vibrancy - tomorrow.vibrancy) > 0.0005 ? "YES" : "no"))
        lines.append(String(format: "  Contrast:   today=%.4f  tomorrow=%.4f  differs=%@", today.contrast, tomorrow.contrast, abs(today.contrast - tomorrow.contrast) > 0.0005 ? "YES" : "no"))
        lines.append("  Essence:    today=\(today.essenceTop3)")
        lines.append("              tomorrow=\(tomorrow.essenceTop3)  differs=\(today.essenceTop3 != tomorrow.essenceTop3)")
        lines.append("  Tarot:      today=\(today.tarotCard)  tomorrow=\(tomorrow.tarotCard)  differs=\(today.tarotCard != tomorrow.tarotCard)")
        lines.append("  Dominant:   today=\(today.dominantEnergy)  tomorrow=\(tomorrow.dominantEnergy)")

        let content = lines.joined(separator: "\n")
        let stableURL = CalibrationReportHelper.reportDirectory()
            .appendingPathComponent("ash_today_tomorrow_combined.txt")
        try? content.write(to: stableURL, atomically: true, encoding: .utf8)
        print("📄 Ash today/tomorrow report: \(stableURL.path)")
        print(content)

        #expect(FileManager.default.fileExists(atPath: stableURL.path),
                "Expected report at \(stableURL.path)")
        #expect(today.palette != tomorrow.palette,
                "Production Ash should differ palette between consecutive days")
    }
}
