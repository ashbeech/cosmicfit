//
//  DailyFitGoldens_Tests.swift
//  Cosmic FitTests
//
//  Phase 0G: Expert-reviewed golden cases.
//  These are HARD FAILURES — not diagnostic reports.
//  Each case encodes astrological ground truth for a known chart + date.
//
//  Cases are loaded from `docs/fixtures/golden_cases.json` (engine-version provenance).
//  Maintenance: when engine weights or dataset entries change, re-review
//  affected goldens and update the fixture's `engineVersion` + `lastValidated`.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Codable Golden Case Models

private struct GoldenFixture: Codable {
    let goldens: [GoldenCaseData]
    let baseDate: String
}

private struct GoldenCaseData: Codable {
    let id: String
    let description: String
    let engineVersion: String
    let natalSigns: [Int]
    let progressedSigns: [Int]
    let profileHash: String
    let moonPhaseDegrees: Double
    let transits: [TransitSpecData]
    let expected: ExpectedOutcome

    struct TransitSpecData: Codable {
        let planet: String
        let natal: String
        let aspect: String
        let orb: Double
    }

    struct ExpectedOutcome: Codable {
        let dominantEnergies: [String]
        let essenceTopBand: [String]
        let paletteTemperature: String
        let silhouetteLean: String
    }
}

// MARK: - Fixture Loader

private func loadGoldenFixture() -> (cases: [GoldenCaseData], baseDate: Date)? {
    let bundle = Bundle(for: _GoldenBundleToken.self)
    let bundleURL = bundle.url(forResource: "golden_cases", withExtension: "json")
    let repoURL = FixtureLocator.fixtureURL(named: "golden_cases.json")

    let url: URL
    if let repoURL {
        url = repoURL
    } else if let b = bundleURL {
        url = b
    } else {
        return nil
    }

    guard let data = try? Data(contentsOf: url),
          let fixture = try? JSONDecoder().decode(GoldenFixture.self, from: data) else {
        return nil
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    let base = formatter.date(from: fixture.baseDate) ?? Date()

    return (cases: fixture.goldens, baseDate: base)
}

private class _GoldenBundleToken {}

// MARK: - Chart + Transit Factory

private func makeChart(signs: [Int]) -> NatalChartCalculator.NatalChart {
    let planetDefs: [(String, String)] = [
        ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
        ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
        ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
    ]
    let planets = planetDefs.enumerated().map { (i, pair) in
        NatalChartCalculator.PlanetPosition(
            name: pair.0, symbol: pair.1,
            longitude: Double((signs[i] - 1) * 30 + 15), latitude: 0.0,
            zodiacSign: signs[i], zodiacPosition: "15°00'",
            isRetrograde: false
        )
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

private func makeTransits(from specs: [GoldenCaseData.TransitSpecData], baseDate: Date) -> [NatalChartCalculator.TransitAspect] {
    specs.map { spec in
        NatalChartCalculator.TransitAspect(
            transitPlanet: spec.planet, transitPlanetSymbol: "•",
            natalPlanet: spec.natal, natalPlanetSymbol: "•",
            aspectType: spec.aspect, aspectSymbol: "•",
            orb: spec.orb, applying: true,
            effectiveFrom: baseDate,
            effectiveTo: baseDate.addingTimeInterval(86400 * 3),
            description: "\(spec.planet) \(spec.aspect) \(spec.natal)",
            category: .shortTerm
        )
    }
}

private let goldenBlueprint: CosmicBlueprint = {
    let colour = { (n: String, h: String, r: ColourRole) in
        BlueprintColour(name: n, hexValue: h, role: r,
                       provenance: .v4Template(family: "Gold", band: r.rawValue, index: 0))
    }
    let palette = PaletteSection(
        neutrals: [colour("Ivory", "#FFFFF0", .neutral), colour("Sand", "#C2B280", .neutral)],
        coreColours: [colour("Burnt Sienna", "#A0522D", .core), colour("Terracotta", "#E2725B", .core),
                     colour("Amber", "#FFBF00", .core), colour("Olive", "#808000", .core)],
        accentColours: [colour("Coral", "#FF7F50", .accent), colour("Tangerine", "#FF9966", .accent),
                       colour("Saffron", "#F4C430", .accent), colour("Burgundy", "#800020", .accent)],
        supportColours: [colour("Blush", "#DE5D83", .support), colour("Champagne", "#F7E7CE", .support)],
        family: .deepAutumn, cluster: .deepWarmStructured,
        variables: DerivedVariables(depth: .deep, temperature: .warm,
                                   saturation: .rich, contrast: .high, surface: .structured),
        secondaryPull: nil, overrideFlags: OverrideFlags(), narrativeText: "Golden palette."
    )
    return CosmicBlueprint(
        userInfo: BlueprintUserInfo(birthDate: Date(timeIntervalSince1970: 0),
                                   birthLocation: "London, UK", generationDate: Date()),
        styleCore: StyleCoreSection(narrativeText: "Golden style core."),
        textures: TexturesSection(goodText: "G.", badText: "B.", sweetSpotText: "S.",
                                 recommendedTextures: ["cashmere", "denim", "silk", "leather"],
                                 avoidTextures: ["polyester"], sweetSpotKeywords: ["luxe"]),
        palette: palette,
        occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
        hardware: HardwareSection(metalsText: "M.", stonesText: "S.", tipText: "T.",
                                 recommendedMetals: ["gold", "brass", "copper"],
                                 recommendedStones: ["ruby"]),
        code: CodeSection(leanInto: ["structured shoulders", "sharp tailoring"],
                         avoid: ["soft draping"], consider: ["angular lines"]),
        accessory: AccessorySection(paragraphs: ["A1.", "A2.", "A3."]),
        pattern: PatternSection(narrativeText: "P.", tipText: "T.",
                               recommendedPatterns: ["stripes", "herringbone"],
                               avoidPatterns: ["neon"]),
        generatedAt: Date(), engineVersion: "4.7"
    )
}()

// MARK: - Energy Enum Resolution

private func resolveEnergy(_ name: String) -> Energy? {
    Energy(rawValue: name)
}

private func resolveEssenceCategory(_ name: String) -> StyleEssenceCategory? {
    StyleEssenceCategory(rawValue: name)
}

// MARK: - Helper: Direction Classification

private func classifyPaletteTemperature(_ colours: [DailyColourPick]) -> String {
    let warmNames = Set(["Coral", "Tangerine", "Saffron", "Amber", "Burnt Sienna", "Terracotta", "Burgundy"])
    let coolNames = Set(["Ivory", "Sand", "Champagne", "Olive", "Blush"])
    var warmCount = 0
    var coolCount = 0
    for c in colours {
        if warmNames.contains(c.name) { warmCount += 1 }
        if coolNames.contains(c.name) { coolCount += 1 }
    }
    if warmCount > coolCount { return "warm" }
    if coolCount > warmCount { return "cool" }
    return "neutral"
}

private func classifySilhouette(_ profile: SilhouetteProfile) -> String {
    let avg = (profile.angularRounded + profile.structuredDraped) / 2.0
    if avg < 0.4 { return "structured" }
    if avg > 0.6 { return "fluid" }
    return "neutral"
}

// MARK: - Test Suite

@Suite(.serialized)
struct DailyFitGoldens_Tests {

    private func resetTrackers() {
        let suiteName = "com.cosmicfit.goldens.\(UUID().uuidString)"
        let isolated = UserDefaults(suiteName: suiteName)!
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: isolated)
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: isolated)
        BlueprintLensEngine._resetCardCache()
    }

    private func loadFixture() throws -> (cases: [GoldenCaseData], baseDate: Date) {
        guard let fixture = loadGoldenFixture() else {
            Issue.record("Failed to load golden_cases.json from docs/fixtures/ or test bundle")
            throw GoldenLoadError.fixtureNotFound
        }
        return fixture
    }

    private enum GoldenLoadError: Error { case fixtureNotFound }

    @Test("Golden cases — dominant energy matches expected band")
    func testDominantEnergyMatchesExpectation() throws {
        let (goldens, baseDate) = try loadFixture()
        for golden in goldens {
            resetTrackers()
            let chart = makeChart(signs: golden.natalSigns)
            let progressed = makeChart(signs: golden.progressedSigns)
            let transits = makeTransits(from: golden.transits, baseDate: baseDate)

            let (payload, _) = DailyFitDiagnostics.generateReport(
                natalChart: chart, progressedChart: progressed,
                transits: transits, moonPhaseDegrees: golden.moonPhaseDegrees,
                profileHash: golden.profileHash, blueprint: goldenBlueprint,
                date: baseDate
            )

            let dominant = payload.vibeBreakdown.dominantEnergy
            let expectedEnergies = golden.expected.dominantEnergies.compactMap(resolveEnergy)
            #expect(expectedEnergies.contains(dominant),
                    "[\(golden.id)] Expected dominant in \(golden.expected.dominantEnergies), got \(dominant.rawValue)")
        }
    }

    @Test("Golden cases — essence top-3 intersects expected band")
    func testEssenceTopBandIntersectsExpectation() throws {
        let (goldens, baseDate) = try loadFixture()
        for golden in goldens {
            resetTrackers()
            let chart = makeChart(signs: golden.natalSigns)
            let progressed = makeChart(signs: golden.progressedSigns)
            let transits = makeTransits(from: golden.transits, baseDate: baseDate)

            let (payload, _) = DailyFitDiagnostics.generateReport(
                natalChart: chart, progressedChart: progressed,
                transits: transits, moonPhaseDegrees: golden.moonPhaseDegrees,
                profileHash: golden.profileHash, blueprint: goldenBlueprint,
                date: baseDate
            )

            let top3 = payload.essenceProfile.visibleCategories.map(\.category)
            let expectedCategories = Set(golden.expected.essenceTopBand.compactMap(resolveEssenceCategory))
            let intersection = Set(top3).intersection(expectedCategories)
            #expect(!intersection.isEmpty,
                    "[\(golden.id)] Essence top-3 \(top3.map(\.rawValue)) has no overlap with expected \(golden.expected.essenceTopBand)")
        }
    }

    @Test("Golden cases — payload structurally valid")
    func testPayloadStructurallyValid() throws {
        let (goldens, baseDate) = try loadFixture()
        for golden in goldens {
            resetTrackers()
            let chart = makeChart(signs: golden.natalSigns)
            let progressed = makeChart(signs: golden.progressedSigns)
            let transits = makeTransits(from: golden.transits, baseDate: baseDate)

            let (payload, _) = DailyFitDiagnostics.generateReport(
                natalChart: chart, progressedChart: progressed,
                transits: transits, moonPhaseDegrees: golden.moonPhaseDegrees,
                profileHash: golden.profileHash, blueprint: goldenBlueprint,
                date: baseDate
            )

            #expect(payload.vibeBreakdown.totalPoints == 21, "[\(golden.id)] Vibe total != 21")
            #expect(payload.vibeBreakdown.isValid, "[\(golden.id)] Vibe invalid")
            #expect(!payload.tarotCard.name.isEmpty, "[\(golden.id)] No tarot card")
            #expect(payload.dailyPalette.colours.count == 3, "[\(golden.id)] Palette != 3 colours")
            #expect(payload.essenceProfile.allScores.count == 14, "[\(golden.id)] Essence != 14 categories")
            #expect(payload.axes.action >= 1.0 && payload.axes.action <= 10.0, "[\(golden.id)] Action out of range")
        }
    }

    @Test("Golden cases — generate diagnostic report to disk")
    func testGenerateGoldenReport() throws {
        let (goldens, baseDate) = try loadFixture()
        var lines: [String] = []
        lines.append("=== Daily Fit Goldens Report ===")
        lines.append("Generated: \(Date())")
        lines.append("Engine version: 4.7")
        lines.append("Fixture: golden_cases.json")
        lines.append("Cases: \(goldens.count)")
        lines.append("")

        for golden in goldens {
            resetTrackers()
            let chart = makeChart(signs: golden.natalSigns)
            let progressed = makeChart(signs: golden.progressedSigns)
            let transits = makeTransits(from: golden.transits, baseDate: baseDate)

            let (payload, _) = DailyFitDiagnostics.generateReport(
                natalChart: chart, progressedChart: progressed,
                transits: transits, moonPhaseDegrees: golden.moonPhaseDegrees,
                profileHash: golden.profileHash, blueprint: goldenBlueprint,
                date: baseDate
            )

            lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            lines.append("CASE: \(golden.id)")
            lines.append("  \(golden.description)")
            lines.append("  Moon: \(golden.moonPhaseDegrees)°")
            lines.append("")

            let v = payload.vibeBreakdown
            let dominant = v.dominantEnergy
            let expectedEnergies = golden.expected.dominantEnergies
            let matchDominant = expectedEnergies.contains(dominant.rawValue) ? "✓" : "✗"
            lines.append("  Vibe: C=\(v.classic) P=\(v.playful) R=\(v.romantic) U=\(v.utility) D=\(v.drama) E=\(v.edge)")
            lines.append("  Dominant: \(dominant.rawValue) \(matchDominant) (expected: \(expectedEnergies))")

            let top3 = payload.essenceProfile.visibleCategories.map { "\($0.category.rawValue)=\(String(format: "%.2f", $0.score))" }
            let expectedCategories = Set(golden.expected.essenceTopBand.compactMap(resolveEssenceCategory))
            let essenceIntersection = Set(payload.essenceProfile.visibleCategories.map(\.category)).intersection(expectedCategories)
            let matchEssence = essenceIntersection.isEmpty ? "✗" : "✓"
            lines.append("  Essence top-3: \(top3.joined(separator: " ")) \(matchEssence)")

            let palTemp = classifyPaletteTemperature(payload.dailyPalette.colours)
            let matchPalette = palTemp == golden.expected.paletteTemperature ? "✓" : "~"
            lines.append("  Palette temp: \(palTemp) \(matchPalette) (expected: \(golden.expected.paletteTemperature))")

            let silLean = classifySilhouette(payload.silhouetteProfile)
            let matchSil = silLean == golden.expected.silhouetteLean ? "✓" : "~"
            lines.append("  Silhouette: \(silLean) \(matchSil) (expected: \(golden.expected.silhouetteLean))")

            lines.append("  Tarot: \(payload.tarotCard.name)")
            lines.append("  Palette: \(payload.dailyPalette.colours.map(\.name).joined(separator: ", "))")
            lines.append("")
        }

        CalibrationReportHelper.writeReport(prefix: "daily_fit_goldens", content: lines.joined(separator: "\n"))
    }
}
