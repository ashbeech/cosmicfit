//
//  TokenSupplyDiagnostic.swift
//  Cosmic FitTests
//
//  Palette Engine Rework (Phase A) §8 — token-supply pre-req gate.
//
//  Runs against two fixture charts (Ash, Maria) plus ≥10 synthetic charts
//  covering element / modality spread. For each, generates tokens via the
//  post-§5 BlueprintTokenGenerator, partitions .colour tokens by
//  `sourceColourRole`, and runs the 15° hue-gap filter separately on each
//  pool.
//
//  Pass criteria (§8.3):
//   • Both fixture users: zero library-fallback escalation on both bands.
//   • ≥ 80% of synthetic charts: zero library-fallback escalation.
//
//  Output is printed to stdout for the PR appendix. The single @Test below
//  never fails — the gate is a human-read diagnostic, not an automated
//  pass/fail check. Dev confirms §8.3 by reading the printed summary.
//

import Testing
import Foundation
@testable import Cosmic_Fit

struct TokenSupplyDiagnostic {

    // MARK: - Entry Point

    @Test("Token-supply diagnostic: fixtures + synthetic spread")
    func runDiagnostic() throws {
        guard let dataset = Self.loadDataset() else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }

        var lines: [String] = []
        lines.append("=====================================================")
        lines.append(" Palette Engine Rework — Token Supply Diagnostic")
        lines.append(" Spec: docs/palette_engine_rework_spec_v1.md §8")
        lines.append("=====================================================")
        lines.append("")

        var reports: [ChartReport] = []

        // Fixture 1 — Ash, London, 1984-12-11 00:00 UTC.
        let ashChart = NatalChartCalculator.calculateNatalChart(
            birthDate: Self.isoDate("1984-12-11T00:00:00Z"),
            latitude: 51.5074, longitude: -0.1278,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        reports.append(Self.run(label: "FIXTURE · Ash",
                                kind: .fixture,
                                analysis: ChartAnalyser.analyse(chart: ashChart),
                                dataset: dataset))

        // Fixture 2 — Maria, same coords/time (fixture uses London default).
        let mariaChart = NatalChartCalculator.calculateNatalChart(
            birthDate: Self.isoDate("1989-04-28T00:00:00Z"),
            latitude: 51.5074, longitude: -0.1278,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        reports.append(Self.run(label: "FIXTURE · Maria",
                                kind: .fixture,
                                analysis: ChartAnalyser.analyse(chart: mariaChart),
                                dataset: dataset))

        // Synthetic spread (≥ 10) — §8.2.
        for synth in Self.syntheticSpread() {
            reports.append(Self.run(label: "SYNTH · \(synth.label)",
                                    kind: .synthetic,
                                    analysis: synth.analysis,
                                    dataset: dataset))
        }

        // Per-chart block.
        for r in reports {
            lines.append(r.render())
            lines.append("")
        }

        // Aggregate summary.
        lines.append("-----------------------------------------------------")
        lines.append(" Aggregate — Pass criteria (§8.3)")
        lines.append("-----------------------------------------------------")
        let fixtures = reports.filter { $0.kind == .fixture }
        let synths = reports.filter { $0.kind == .synthetic }
        let fixturesPassing = fixtures.filter { !$0.requiresLibraryFallback }.count
        let synthsPassing = synths.filter { !$0.requiresLibraryFallback }.count
        let synthPct = synths.isEmpty ? 0.0 : (Double(synthsPassing) / Double(synths.count)) * 100.0
        lines.append(String(format: " Fixture users clean: %d / %d", fixturesPassing, fixtures.count))
        lines.append(String(format: " Synthetic charts clean: %d / %d (%.0f%%, floor 80%%)",
                            synthsPassing, synths.count, synthPct))
        let fixtureGate = fixturesPassing == fixtures.count
        let synthGate = synthPct >= 80.0
        lines.append(" Fixture gate: \(fixtureGate ? "PASS" : "FAIL — escalate per §8.4")")
        lines.append(" Synthetic gate: \(synthGate ? "PASS" : "FAIL — escalate per §8.4")")
        lines.append("=====================================================")

        // Print as a single newline-joined block so it's trivially copy-pastable.
        print("\n" + lines.joined(separator: "\n") + "\n")

        // Also drop the report to a file alongside the repo for the PR appendix.
        Self.writeAppendix(body: lines.joined(separator: "\n"))
    }

    // MARK: - Per-Chart Run

    private struct ChartReport {
        enum Kind { case fixture, synthetic }
        let label: String
        let kind: Kind
        let primaryDistinctAt15: Int
        let accentDistinctAt15: Int
        let primaryPoolSize: Int
        let accentPoolSize: Int
        let escalationStep: EscalationStep
        let topContributingCombos: [(key: String, aggregateWeight: Double)]

        var requiresLibraryFallback: Bool { escalationStep == .libraryFallback }

        func render() -> String {
            var s: [String] = []
            s.append("[\(label)]")
            s.append(String(format: "  primary pool: %d tokens, %d distinct @ 15°",
                            primaryPoolSize, primaryDistinctAt15))
            s.append(String(format: "  accent  pool: %d tokens, %d distinct @ 15°",
                            accentPoolSize, accentDistinctAt15))
            s.append("  escalation step expected: \(escalationStep.label)")
            let top = topContributingCombos.prefix(5)
                .map { String(format: "%@(%.2f)", $0.key, $0.aggregateWeight) }
                .joined(separator: ", ")
            s.append("  top combos: \(top)")
            return s.joined(separator: "\n")
        }
    }

    private enum EscalationStep: Equatable {
        /// Passes 1–2 satisfied both bands at 15°.
        case none
        /// Required hue-gap loosening (12° or 10°) to satisfy at least one band.
        case hueGapLoosen(Double)
        /// Needed cross-pool escalation to meet band minima.
        case crossPool
        /// Still underflows after cross-pool — must pad from curated library.
        case libraryFallback

        var label: String {
            switch self {
            case .none: return "0 · no escalation (clean at 15°)"
            case .hueGapLoosen(let gap): return String(format: "1 · hue-gap loosen to %.0f°", gap)
            case .crossPool: return "2 · cross-pool escalation"
            case .libraryFallback: return "3 · library fallback (blocks §8.3)"
            }
        }
    }

    private static func run(
        label: String,
        kind: ChartReport.Kind,
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset
    ) -> ChartReport {
        let result = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)

        // Recreate the resolver's own sort so distinct-hue counting matches
        // what the resolver will actually see post-§6 rewrite.
        let colourTokens = result.tokens
            .filter { $0.category == .colour }
            .sorted(by: tieBreakSort)

        let primaryPool = colourTokens.filter { $0.sourceColourRole == .primary }
        let accentPool = colourTokens.filter { $0.sourceColourRole == .accent }

        let primaryDistinct = distinctHueCount(in: primaryPool,
                                               library: dataset.colourLibrary,
                                               hueGap: 15.0)
        let accentDistinct = distinctHueCount(in: accentPool,
                                              library: dataset.colourLibrary,
                                              hueGap: 15.0)

        // Escalation model mirrors the planned resolver: both bands want 4.
        // If either band can't hit 4 distinct hues at 15° from its own pool,
        // the resolver will climb the ladder — this diagnostic reports the
        // highest step the planned resolver would reach, not simulating the
        // full pipeline.
        let step = estimateEscalationStep(
            primaryPool: primaryPool,
            accentPool: accentPool,
            library: dataset.colourLibrary
        )

        return ChartReport(
            label: label,
            kind: kind,
            primaryDistinctAt15: primaryDistinct,
            accentDistinctAt15: accentDistinct,
            primaryPoolSize: primaryPool.count,
            accentPoolSize: accentPool.count,
            escalationStep: step,
            topContributingCombos: Array(result.contributingCombos.prefix(5))
        )
    }

    // MARK: - Hue-Gap Logic (mirrors DeterministicResolver — kept local)

    private static func distinctHueCount(
        in pool: [BlueprintToken],
        library: [String: ColourLibraryEntry],
        hueGap: Double
    ) -> Int {
        var hues: [Double] = []
        var seenNames: Set<String> = []
        for token in pool {
            guard !seenNames.contains(token.name) else { continue }
            let hex = resolveHex(name: token.name, library: library)
            let hue = hueFromHex(hex)
            let tooClose = hues.contains { hueDistance($0, hue) < hueGap }
            if tooClose { continue }
            hues.append(hue)
            seenNames.insert(token.name)
        }
        return hues.count
    }

    private static func estimateEscalationStep(
        primaryPool: [BlueprintToken],
        accentPool: [BlueprintToken],
        library: [String: ColourLibraryEntry]
    ) -> EscalationStep {
        let target = 4
        let ladder: [Double] = [15.0, 12.0, 10.0]

        for gap in ladder {
            let primary = distinctHueCount(in: primaryPool, library: library, hueGap: gap)
            let accent = distinctHueCount(in: accentPool, library: library, hueGap: gap)
            if primary >= target && accent >= target {
                return gap == 15.0 ? .none : .hueGapLoosen(gap)
            }
        }

        // Ladder exhausted on own pools — try cross-pool substitution at 15°.
        let combined = primaryPool + accentPool
        let combinedDistinct = distinctHueCount(in: combined, library: library, hueGap: 15.0)
        if combinedDistinct >= target * 2 {
            return .crossPool
        }
        return .libraryFallback
    }

    private static func resolveHex(
        name: String,
        library: [String: ColourLibraryEntry]
    ) -> String {
        if let entry = library[name] { return entry.hex }
        let lower = name.lowercased()
        for (key, entry) in library {
            if key.lowercased().contains(lower) || lower.contains(key.lowercased()) {
                return entry.hex
            }
        }
        return library.values.first?.hex ?? "#808080"
    }

    private static func hueFromHex(_ hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else { return 0 }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        let maxC = max(r, g, b); let minC = min(r, g, b); let delta = maxC - minC
        guard delta > 0 else { return 0 }
        var hue: Double
        if maxC == r {
            hue = 60.0 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
        } else if maxC == g {
            hue = 60.0 * (((b - r) / delta) + 2)
        } else {
            hue = 60.0 * (((r - g) / delta) + 4)
        }
        if hue < 0 { hue += 360 }
        return hue
    }

    private static func hueDistance(_ h1: Double, _ h2: Double) -> Double {
        let diff = abs(h1 - h2)
        return min(diff, 360.0 - diff)
    }

    private static func tieBreakSort(_ a: BlueprintToken, _ b: BlueprintToken) -> Bool {
        if a.weight != b.weight { return a.weight > b.weight }
        return planetRank(a.planetarySource) > planetRank(b.planetarySource)
    }

    private static func planetRank(_ name: String?) -> Int {
        switch name {
        case "Venus": return 10
        case "Moon": return 9
        case "Ascendant": return 8
        case "Sun": return 7
        case "Mars": return 6
        case "Saturn": return 5
        case "Jupiter": return 4
        case "Mercury": return 3
        default: return 1
        }
    }

    // MARK: - Synthetic Spread (§8.2)

    private struct SyntheticChart {
        let label: String
        let analysis: ChartAnalysis
    }

    private static func syntheticSpread() -> [SyntheticChart] {
        return [
            makeSynth(label: "fire-dominant cardinal",
                      signs: ["Sun": "Aries", "Moon": "Leo", "Venus": "Aries",
                              "Mars": "Sagittarius", "Mercury": "Aries",
                              "Jupiter": "Leo", "Saturn": "Sagittarius"],
                      ascendant: "Aries", chartRuler: "Mars",
                      element: (fire: 6, earth: 1, air: 1, water: 1),
                      modality: (cardinal: 4, fixed: 3, mutable: 1)),
            makeSynth(label: "fire-dominant mutable",
                      signs: ["Sun": "Sagittarius", "Moon": "Sagittarius", "Venus": "Leo",
                              "Mars": "Aries", "Mercury": "Sagittarius",
                              "Jupiter": "Leo", "Saturn": "Aries"],
                      ascendant: "Sagittarius", chartRuler: "Jupiter",
                      element: (fire: 6, earth: 1, air: 1, water: 1),
                      modality: (cardinal: 1, fixed: 2, mutable: 5)),
            makeSynth(label: "earth-dominant fixed",
                      signs: ["Sun": "Taurus", "Moon": "Virgo", "Venus": "Taurus",
                              "Mars": "Capricorn", "Mercury": "Virgo",
                              "Jupiter": "Taurus", "Saturn": "Capricorn"],
                      ascendant: "Taurus", chartRuler: "Venus",
                      element: (fire: 0, earth: 6, air: 1, water: 2),
                      modality: (cardinal: 2, fixed: 4, mutable: 2)),
            makeSynth(label: "earth-dominant cardinal",
                      signs: ["Sun": "Capricorn", "Moon": "Capricorn", "Venus": "Virgo",
                              "Mars": "Taurus", "Mercury": "Capricorn",
                              "Jupiter": "Virgo", "Saturn": "Capricorn"],
                      ascendant: "Capricorn", chartRuler: "Saturn",
                      element: (fire: 0, earth: 6, air: 1, water: 2),
                      modality: (cardinal: 5, fixed: 2, mutable: 1)),
            makeSynth(label: "air-dominant fixed",
                      signs: ["Sun": "Aquarius", "Moon": "Gemini", "Venus": "Libra",
                              "Mars": "Aquarius", "Mercury": "Gemini",
                              "Jupiter": "Libra", "Saturn": "Aquarius"],
                      ascendant: "Aquarius", chartRuler: "Saturn",
                      element: (fire: 1, earth: 0, air: 6, water: 2),
                      modality: (cardinal: 2, fixed: 4, mutable: 2)),
            makeSynth(label: "air-dominant cardinal",
                      signs: ["Sun": "Libra", "Moon": "Aquarius", "Venus": "Libra",
                              "Mars": "Gemini", "Mercury": "Libra",
                              "Jupiter": "Gemini", "Saturn": "Aquarius"],
                      ascendant: "Libra", chartRuler: "Venus",
                      element: (fire: 1, earth: 0, air: 6, water: 2),
                      modality: (cardinal: 4, fixed: 3, mutable: 2)),
            makeSynth(label: "water-dominant mutable",
                      signs: ["Sun": "Pisces", "Moon": "Cancer", "Venus": "Scorpio",
                              "Mars": "Pisces", "Mercury": "Pisces",
                              "Jupiter": "Cancer", "Saturn": "Scorpio"],
                      ascendant: "Pisces", chartRuler: "Jupiter",
                      element: (fire: 1, earth: 1, air: 0, water: 6),
                      modality: (cardinal: 1, fixed: 3, mutable: 4)),
            makeSynth(label: "water-dominant fixed",
                      signs: ["Sun": "Scorpio", "Moon": "Scorpio", "Venus": "Scorpio",
                              "Mars": "Cancer", "Mercury": "Scorpio",
                              "Jupiter": "Pisces", "Saturn": "Cancer"],
                      ascendant: "Scorpio", chartRuler: "Mars",
                      element: (fire: 1, earth: 1, air: 0, water: 6),
                      modality: (cardinal: 2, fixed: 5, mutable: 1)),
            makeSynth(label: "mixed modality · cardinal blend",
                      signs: ["Sun": "Aries", "Moon": "Cancer", "Venus": "Libra",
                              "Mars": "Capricorn", "Mercury": "Aries",
                              "Jupiter": "Libra", "Saturn": "Cancer"],
                      ascendant: "Libra", chartRuler: "Venus",
                      element: (fire: 2, earth: 2, air: 2, water: 2),
                      modality: (cardinal: 7, fixed: 1, mutable: 0)),
            makeSynth(label: "mixed modality · mutable blend",
                      signs: ["Sun": "Gemini", "Moon": "Virgo", "Venus": "Pisces",
                              "Mars": "Sagittarius", "Mercury": "Gemini",
                              "Jupiter": "Virgo", "Saturn": "Sagittarius"],
                      ascendant: "Virgo", chartRuler: "Mercury",
                      element: (fire: 2, earth: 2, air: 2, water: 2),
                      modality: (cardinal: 0, fixed: 1, mutable: 7)),
            makeSynth(label: "balanced · no dominant element",
                      signs: ["Sun": "Leo", "Moon": "Taurus", "Venus": "Cancer",
                              "Mars": "Libra", "Mercury": "Virgo",
                              "Jupiter": "Sagittarius", "Saturn": "Pisces"],
                      ascendant: "Scorpio", chartRuler: "Mars",
                      element: (fire: 2, earth: 2, air: 2, water: 2),
                      modality: (cardinal: 3, fixed: 3, mutable: 2)),
        ]
    }

    private static func makeSynth(
        label: String,
        signs: [String: String],
        ascendant: String,
        chartRuler: String,
        element: (fire: Int, earth: Int, air: Int, water: Int),
        modality: (cardinal: Int, fixed: Int, mutable: Int)
    ) -> SyntheticChart {
        // Neutral houses (all planets in house 1) — the diagnostic cares about
        // sign-driven colour supply, not house weighting. House modifier only
        // affects combo *weight*, not which colour tokens are emitted.
        let planetHouses: [String: Int] = Dictionary(uniqueKeysWithValues:
            signs.keys.map { ($0, 1) }
        )
        let sect: ChartSect = .day
        let sectStatus = ChartAnalyser.computePlanetSectStatus(chartSect: sect)
        var houseScores: [Int: Double] = [:]
        for h in 1...12 { houseScores[h] = 0.0 }
        houseScores[1] = Double(signs.count) * 0.5

        let analysis = ChartAnalysis(
            elementBalance: ElementBalance(
                fire: element.fire, earth: element.earth,
                air: element.air, water: element.water
            ),
            modalityBalance: ModalityBalance(
                cardinal: modality.cardinal, fixed: modality.fixed, mutable: modality.mutable
            ),
            chartRuler: chartRuler,
            sunSign: signs["Sun"] ?? "Aries",
            moonSign: signs["Moon"] ?? "Aries",
            ascendantSign: ascendant,
            venusSign: signs["Venus"] ?? "Aries",
            marsSign: signs["Mars"] ?? "Aries",
            planetSigns: signs,
            planetDignities: [:],
            planetHouses: planetHouses,
            significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Sun"],
            chartSect: sect,
            planetSectStatus: sectStatus,
            houseEmphasis: HouseEmphasis(
                houseScores: houseScores,
                dominantHouses: [1],
                venusHouseDomain: "identity",
                moonHouseDomain: "identity"
            )
        )
        return SyntheticChart(label: label, analysis: analysis)
    }

    // MARK: - Support

    private static func loadDataset() -> AstrologicalStyleDataset? {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        return BlueprintTokenGenerator.loadDataset(
            from: repoRoot.appendingPathComponent("astrological_style_dataset.json")
        )
    }

    private static func isoDate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value)!
    }

    private static func writeAppendix(body: String) {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        let appendixURL = repoRoot
            .appendingPathComponent("docs")
            .appendingPathComponent("fixtures")
            .appendingPathComponent("token_supply_diagnostic.txt")
        try? FileManager.default.createDirectory(
            at: appendixURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? body.data(using: .utf8)?.write(to: appendixURL, options: .atomic)
    }
}
