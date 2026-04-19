//
//  PaletteRework_Tests.swift
//  Cosmic FitTests
//
//  Phase A — Palette Engine Rework (spec v1.1).
//
//  This file covers the new test surface added by §12.2, §12.4, and §12.5:
//
//   • Exact accent count == 4 on both fixture users.
//   • Provenance shape (round-trip) and content (chart-derived, no fallback,
//     ranks within top contributors).
//   • Hue-gap invariant on both bands of both fixtures.
//   • Determinism — resolver produces a byte-identical PaletteSection across
//     10 back-to-back runs for both fixture charts.
//   • Narrative-exposure rule (§12.4) — only top-2 accents reach the
//     template context.
//   • Rank ordering (§12.5) — coreColours and accentColours sorted by
//     provenance.contributorRank ascending; library-fallback sorts last.
//
//  Existing `accentColours.count >= 2` shape assertions in
//  Cosmic_FitTests.swift have been bumped to `>= 4` to satisfy §12.1.
//

import Testing
import Foundation
@testable import Cosmic_Fit

struct PaletteReworkTests {

    // MARK: - Fixture Loading

    private static func fixturesURL() -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        return testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs")
            .appendingPathComponent("fixtures")
    }

    private static func loadBlueprint(_ filename: String) throws -> CosmicBlueprint {
        let url = fixturesURL().appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CosmicBlueprint.self, from: data)
    }

    private static func loadDataset() -> AstrologicalStyleDataset? {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        return BlueprintTokenGenerator.loadDataset(
            from: repoRoot.appendingPathComponent("astrological_style_dataset.json")
        )
    }

    private static let fixtureSpecs: [(filename: String, label: String, birthDate: String, birthLocation: String, latitude: Double, longitude: Double)] = [
        ("blueprint_input_user_1.json", "Ash", "1984-12-11T00:00:00Z", "London, UK", 51.5074, -0.1278),
        ("blueprint_input_user_2.json", "Maria", "1989-04-28T00:00:00Z", "Unknown", 51.5074, -0.1278),
    ]

    private static func isoDate(_ s: String) -> Date {
        ISO8601DateFormatter().date(from: s)!
    }

    /// Returns false when no legacy fixtures are present in the current set.
    /// This keeps legacy assertions dormant under all-V4 fixtures while
    /// automatically re-activating if a legacy fixture is reintroduced.
    private static func hasLegacyFixtures(_ fixtures: [CosmicBlueprint]) -> Bool {
        fixtures.contains { !$0.palette.isV4 }
    }

    // MARK: - §12.2: Exact accent count

    @Test("Both fixtures have exactly 4 accent colours")
    func exactAccentCount() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            #expect(bp.palette.accentColours.count == 4,
                    "\(spec.label) (\(spec.filename)) must have exactly 4 accentColours, got \(bp.palette.accentColours.count)")
        }
    }

    // MARK: - §12.2: Provenance shape (lossless round-trip)

    @Test("BlueprintColour.provenance round-trips losslessly across all anchors")
    func provenanceRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            for colour in bp.palette.coreColours + bp.palette.accentColours {
                let encoded = try encoder.encode(colour.provenance)
                let decoded = try decoder.decode(ColourProvenance.self, from: encoded)
                #expect(decoded == colour.provenance,
                        "\(spec.label): provenance for \(colour.name) failed round-trip")
            }
        }
    }

    // MARK: - §12.2 (v1.1 revision 2): Provenance content

    /// Hard gate (matches §8.3): zero `.libraryFallback` entries in either
    /// band for fixture users. `.chartDerived` is preferred but
    /// `.crossPoolEscalation` is permitted — see v1.1 revision 2 note.
    @Test("Both fixtures: no anchor has .libraryFallback provenance")
    func provenanceNoLibraryFallback() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            for colour in bp.palette.coreColours + bp.palette.accentColours {
                if case .libraryFallback = colour.provenance {
                    Issue.record("\(spec.label): \(colour.role) anchor \(colour.name) has .libraryFallback provenance — hard gate violation")
                }
            }
        }
    }

    /// Soft floor per v1.1 rev 2: core is the strongest-signal band, so
    /// escalation here should be rare. ≥ 3 of 4 core anchors must be chart-derived.
    @Test("Both fixtures: at least 3 of 4 core anchors are chart-derived")
    func coreChartDerivedFloor() throws {
        let fixtures = try Self.fixtureSpecs.map { spec in
            (spec: spec, bp: try Self.loadBlueprint(spec.filename))
        }
        guard Self.hasLegacyFixtures(fixtures.map { $0.bp }) else { return }

        for entry in fixtures {
            let spec = entry.spec
            let bp = entry.bp
            guard !bp.palette.isV4 else { continue }
            let chartDerivedCore = bp.palette.coreColours.reduce(into: 0) { acc, colour in
                if case .chartDerived = colour.provenance { acc += 1 }
            }
            #expect(chartDerivedCore >= 3,
                    "\(spec.label): only \(chartDerivedCore)/\(bp.palette.coreColours.count) core anchors are chart-derived (floor 3)")
        }
    }

    /// Soft floor per v1.1 rev 2: accent pool is thinner per dataset, so
    /// ≥ 2 of 4 accents must be chart-derived; up to 2 may be cross-pool.
    @Test("Both fixtures: at least 2 of 4 accent anchors are chart-derived")
    func accentChartDerivedFloor() throws {
        let fixtures = try Self.fixtureSpecs.map { spec in
            (spec: spec, bp: try Self.loadBlueprint(spec.filename))
        }
        guard Self.hasLegacyFixtures(fixtures.map { $0.bp }) else { return }

        for entry in fixtures {
            let spec = entry.spec
            let bp = entry.bp
            guard !bp.palette.isV4 else { continue }
            let chartDerivedAccent = bp.palette.accentColours.reduce(into: 0) { acc, colour in
                if case .chartDerived = colour.provenance { acc += 1 }
            }
            #expect(chartDerivedAccent >= 2,
                    "\(spec.label): only \(chartDerivedAccent)/\(bp.palette.accentColours.count) accent anchors are chart-derived (floor 2)")
        }
    }

    /// Rank applies across `.chartDerived` and `.crossPoolEscalation` — both
    /// record a real contributor rank. `.libraryFallback` would not qualify,
    /// and the hard gate above guarantees none appear on fixtures.
    ///
    /// Threshold is 2 (matching `accentChartDerivedFloor`), aligned with
    /// v1.1 rev 2: once cross-pool is accepted as a legitimate accent
    /// fallback, only the own-pool top-2 has a meaningful rank ceiling
    /// — the other two slots may land anywhere in the opposite pool's
    /// combo ordering. Maria's accentColours[2..3] are a live example
    /// (`mars_gemini` rank 5, `neptune_capricorn` rank 8).
    @Test("Both fixtures: at least 2 of 4 accents come from the top-5 contributors")
    func accentsTopContributors() throws {
        let fixtures = try Self.fixtureSpecs.map { spec in
            (spec: spec, bp: try Self.loadBlueprint(spec.filename))
        }
        guard Self.hasLegacyFixtures(fixtures.map { $0.bp }) else { return }

        for entry in fixtures {
            let spec = entry.spec
            let bp = entry.bp
            guard !bp.palette.isV4 else { continue }
            let topRankAccentCount = bp.palette.accentColours.reduce(into: 0) { acc, colour in
                let rank: Int
                switch colour.provenance {
                case let .chartDerived(_, r, _, _):           rank = r
                case let .crossPoolEscalation(_, r, _, _, _): rank = r
                case .libraryFallback:                        return
                case .v4Template:                             return
                }
                if rank < 5 { acc += 1 }
            }
            #expect(topRankAccentCount >= 2,
                    "\(spec.label): only \(topRankAccentCount) of 4 accents in top-5 contributors")
        }
    }

    // MARK: - V4 Invariants

    @Test("V4 fixtures use template provenance for all 12 anchors")
    func v4TemplateProvenanceIntegrity() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            guard bp.palette.isV4 else { continue }
            let allAnchors = (bp.palette.neutrals ?? []) + bp.palette.coreColours + bp.palette.accentColours
            #expect(allAnchors.count == 12, "\(spec.label): expected 12 anchors for V4 template integrity")
            for anchor in allAnchors {
                if case .v4Template = anchor.provenance {
                    continue
                }
                Issue.record("\(spec.label): non-template provenance found in V4 fixture for \(anchor.name)")
            }
        }
    }

    @Test("V4 fixtures keep 4/4/4 band counts")
    func v4BandCounts() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            guard bp.palette.isV4 else { continue }
            #expect((bp.palette.neutrals ?? []).count == 4, "\(spec.label): V4 neutrals count must be 4")
            #expect(bp.palette.coreColours.count == 4, "\(spec.label): V4 core count must be 4")
            #expect(bp.palette.accentColours.count == 4, "\(spec.label): V4 accent count must be 4")
        }
    }

    @Test("V4 fixtures include family, cluster, and variables")
    func v4ClassificationFieldsPresent() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            guard bp.palette.isV4 else { continue }
            #expect(bp.palette.family != nil, "\(spec.label): V4 family should be present")
            #expect(bp.palette.cluster != nil, "\(spec.label): V4 cluster should be present")
            #expect(bp.palette.variables != nil, "\(spec.label): V4 variables should be present")
        }
    }

    // MARK: - §12.2: Hue-gap invariant

    @Test("Both fixtures: pairwise hue distance ≥ tightest applied gap (core band)")
    func hueGapInvariantCore() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            assertHueGap(in: bp.palette.coreColours, label: "\(spec.label)/core")
        }
    }

    @Test("Both fixtures: pairwise hue distance ≥ tightest applied gap (accent band)")
    func hueGapInvariantAccent() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            assertHueGap(in: bp.palette.accentColours, label: "\(spec.label)/accent")
        }
    }

    private func assertHueGap(in band: [BlueprintColour], label: String) {
        guard band.count >= 2 else { return }
        for i in 0..<(band.count - 1) {
            for j in (i + 1)..<band.count {
                let a = band[i]
                let b = band[j]
                let gapA = appliedGap(a.provenance)
                let gapB = appliedGap(b.provenance)
                let tightest = min(gapA, gapB)
                let distance = hueDistance(hueFromHex(a.hexValue), hueFromHex(b.hexValue))
                // Allow 0.001° float slack — gaps are integral degrees by spec.
                #expect(distance + 0.001 >= tightest,
                        "\(label): \(a.name) ↔ \(b.name) distance \(distance)° < tightest applied gap \(tightest)°")
            }
        }
    }

    private func appliedGap(_ p: ColourProvenance) -> Double {
        switch p {
        case let .chartDerived(_, _, _, gap):                return gap
        case let .crossPoolEscalation(_, _, _, gap, _):      return gap
        case .libraryFallback:                               return 15.0
        case .v4Template:                                    return 0.0
        }
    }

    // MARK: - §12.2: Determinism (10× resolve, byte-identical PaletteSection)

    @Test("Both fixture charts: 10 consecutive resolves produce byte-identical PaletteSection")
    func resolverDeterminism() throws {
        guard let dataset = Self.loadDataset() else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        for spec in Self.fixtureSpecs {
            let chart = NatalChartCalculator.calculateNatalChart(
                birthDate: Self.isoDate(spec.birthDate),
                latitude: spec.latitude, longitude: spec.longitude,
                timeZone: TimeZone(secondsFromGMT: 0)!
            )
            let analysis = ChartAnalyser.analyse(chart: chart)

            var canonicalEncoding: Data?
            for run in 0..<10 {
                let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
                let resolved = DeterministicResolver.resolve(
                    tokens: tokenResult.tokens, analysis: analysis,
                    dataset: dataset, contributingCombos: tokenResult.contributingCombos
                )
                let palette = PaletteSection(
                    coreColours: resolved.coreColours,
                    accentColours: resolved.accentColours,
                    swatchFamilies: resolved.swatchFamilies,
                    narrativeText: ""
                )
                let encoded = try encoder.encode(palette)
                if let canonical = canonicalEncoding {
                    #expect(encoded == canonical,
                            "\(spec.label): PaletteSection diverged on run \(run)")
                } else {
                    canonicalEncoding = encoded
                }
            }
        }
    }

    // MARK: - §12.4: Narrative-exposure rule

    @Test("buildContext exposes only accent_colour_1 and _2 (top-2 by rank)")
    func narrativeExposureTopTwoAccentsOnly() {
        let resolved = DeterministicResolverResult(
            coreColours: [
                BlueprintColour(name: "midnight", hexValue: "#191970", role: .core,
                                provenance: .chartDerived(comboKey: "venus_scorpio", contributorRank: 0,
                                                          sourceRole: .primary, hueGapApplied: 15.0)),
            ],
            accentColours: [
                BlueprintColour(name: "A", hexValue: "#FF0000", role: .accent,
                                provenance: .chartDerived(comboKey: "venus_scorpio", contributorRank: 0,
                                                          sourceRole: .accent, hueGapApplied: 15.0)),
                BlueprintColour(name: "B", hexValue: "#00FF00", role: .accent,
                                provenance: .chartDerived(comboKey: "moon_capricorn", contributorRank: 1,
                                                          sourceRole: .accent, hueGapApplied: 15.0)),
                BlueprintColour(name: "C", hexValue: "#0000FF", role: .accent,
                                provenance: .chartDerived(comboKey: "sun_sagittarius", contributorRank: 2,
                                                          sourceRole: .accent, hueGapApplied: 15.0)),
                BlueprintColour(name: "D", hexValue: "#FFFF00", role: .accent,
                                provenance: .chartDerived(comboKey: "mars_aries", contributorRank: 3,
                                                          sourceRole: .accent, hueGapApplied: 15.0)),
            ],
            swatchFamilies: [],
            recommendedMetals: [], recommendedStones: [],
            leanInto: [], avoid: [], consider: [],
            recommendedPatterns: [], avoidPatterns: [],
            recommendedTextures: [], avoidTextures: [],
            sweetSpotKeywords: []
        )

        let ctx = NarrativeTemplateRenderer.buildContext(resolved: resolved)

        #expect(ctx["accent_colour_1"] == "A")
        #expect(ctx["accent_colour_2"] == "B")
        #expect(ctx["accent_colour_3"] == nil,
                "accent_colour_3 must NOT be written to context (v1.1 §9.1)")
        #expect(ctx["accent_colour_4"] == nil,
                "accent_colour_4 must NOT be written to context (v1.1 §9.1)")
    }

    // MARK: - §12.5: Rank ordering

    @Test("Both fixtures: coreColours sorted by contributorRank ascending; fallback sorts last")
    func rankOrderingCore() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            assertRankAscending(bp.palette.coreColours, label: "\(spec.label)/core")
        }
    }

    @Test("Both fixtures: accentColours sorted by contributorRank ascending; fallback sorts last")
    func rankOrderingAccent() throws {
        for spec in Self.fixtureSpecs {
            let bp = try Self.loadBlueprint(spec.filename)
            assertRankAscending(bp.palette.accentColours, label: "\(spec.label)/accent")
        }
    }

    private func assertRankAscending(_ band: [BlueprintColour], label: String) {
        let ranks = band.map { rankFor($0.provenance) }
        for i in 1..<ranks.count {
            #expect(ranks[i - 1] <= ranks[i],
                    "\(label): rank order violated at index \(i): \(ranks[i - 1]) > \(ranks[i]) (full ranks: \(ranks))")
        }
    }

    /// Mirrors `DeterministicResolver.provenanceRank`: chartDerived and
    /// crossPoolEscalation surface their real rank; libraryFallback maps
    /// to `Int.max` so it always sorts to the end.
    private func rankFor(_ provenance: ColourProvenance) -> Int {
        switch provenance {
        case let .chartDerived(_, rank, _, _):           return rank
        case let .crossPoolEscalation(_, rank, _, _, _): return rank
        case .libraryFallback:                           return .max
        case .v4Template:                                return 0
        }
    }

    // MARK: - §6.5 (v1.1 rev 3): Dataset ships fallback_palette_pool

    /// Guards the Option A migration — the library fallback pool must live
    /// in `astrological_style_dataset.json` under `fallback_palette_pool`,
    /// not in Swift. If a future refactor accidentally drops the key (or
    /// ships it empty), the resolver degrades to a no-op pad and bands may
    /// underflow. This test catches that regression at the Swift layer;
    /// `validate_dataset.py` mirrors the assertion at the schema layer.
    @Test("Dataset ships a non-empty fallback_palette_pool with ≥1 core and ≥1 accent")
    func datasetShipsFallbackPool() {
        guard let dataset = Self.loadDataset() else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }
        let pool = dataset.fallbackPalettePool ?? []
        #expect(pool.count >= 4,
                "fallback_palette_pool too small: \(pool.count) entries (minimum 4)")
        #expect(pool.contains(where: { $0.role == .core }),
                "fallback_palette_pool missing at least one core entry")
        #expect(pool.contains(where: { $0.role == .accent }),
                "fallback_palette_pool missing at least one accent entry")
    }

    // MARK: - Hue Math (duplicated to keep the resolver utilities private)

    private func hueFromHex(_ hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else { return 0 }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        let maxC = max(r, g, b), minC = min(r, g, b)
        let delta = maxC - minC
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

    private func hueDistance(_ h1: Double, _ h2: Double) -> Double {
        let diff = abs(h1 - h2)
        return min(diff, 360.0 - diff)
    }
}
