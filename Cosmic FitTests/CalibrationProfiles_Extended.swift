//
//  CalibrationProfiles_Extended.swift
//  Cosmic FitTests
//
//  Part 3A: Extended chart population for Style Guide / Blueprint distribution testing.
//
//  Two chart sources are available:
//    1. **Synthetic** — 48 sign-array charts (fast, deterministic, no ephemeris dependency).
//    2. **Real ephemeris** — 60 birth specs from `blueprint_birth_specs.json`, computed
//       via `NatalChartCalculator.calculateNatalChart` at test time.
//
//  `allCharts` exposes the active population. When production ephemeris is available,
//  real charts are preferred; otherwise synthetic charts are used as fallback.
//

import Foundation
@testable import Cosmic_Fit

enum ExtendedCalibrationProfiles {

    // MARK: - Chart Specification (synthetic sign-array format)

    struct ChartSpec {
        let id: String
        let label: String
        let sunSign: Int
        let moonSign: Int
        let risingSign: Int
        let signs: [Int]            // [Sun, Moon, Merc, Venus, Mars, Jup, Sat, Ura, Nep, Plu]
        let elementDominance: String // "fire", "earth", "air", "water", "balanced"
        let sect: String            // "day" or "night"
        let hasStellium: Bool
        let venusCondition: String  // "dignified", "debilitated", "neutral"
        let source: ChartSource

        enum ChartSource: String {
            case synthetic = "synthetic"
            case ephemeris = "ephemeris"
        }

        init(id: String, label: String, sunSign: Int, moonSign: Int, risingSign: Int,
             signs: [Int], elementDominance: String, sect: String,
             hasStellium: Bool, venusCondition: String, source: ChartSource = .synthetic) {
            self.id = id; self.label = label; self.sunSign = sunSign
            self.moonSign = moonSign; self.risingSign = risingSign; self.signs = signs
            self.elementDominance = elementDominance; self.sect = sect
            self.hasStellium = hasStellium; self.venusCondition = venusCondition
            self.source = source
        }

        var natalChart: NatalChartCalculator.NatalChart {
            let standardPlanets: [(String, String)] = [
                ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
                ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
                ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
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
            let asc = Double((risingSign - 1) * 30)
            return NatalChartCalculator.NatalChart(
                planets: planets,
                ascendant: asc, midheaven: 90.0,
                descendant: fmod(asc + 180.0, 360.0), imumCoeli: 270.0,
                houseCusps: Array(stride(from: asc, to: asc + 360.0, by: 30.0).map { fmod($0, 360.0) }),
                wholeSignHouseCusps: Array(stride(from: asc, to: asc + 360.0, by: 30.0).map { fmod($0, 360.0) }),
                northNode: 0.0, southNode: 180.0, vertex: 90.0,
                partOfFortune: 45.0, lilith: 120.0, chiron: 200.0,
                lunarPhase: 90.0
            )
        }
    }

    // MARK: - Birth Spec (real ephemeris format)

    struct BirthSpec: Codable {
        let id: String
        let label: String
        let birthDateUTC: String
        let latitude: Double
        let longitude: Double
        let timeZoneId: String
    }

    // MARK: - Birth Spec Loader

    private static func loadBirthSpecs() -> [BirthSpec]? {
        let bundle = Bundle(for: _CalibrationBundleToken.self)
        if let url = bundle.url(forResource: "blueprint_birth_specs", withExtension: "json") {
            return decodeBirthSpecs(from: url)
        }
        let repoURL = repoRoot()?.appendingPathComponent("docs/fixtures/blueprint_birth_specs.json")
        if let url = repoURL, FileManager.default.fileExists(atPath: url.path) {
            return decodeBirthSpecs(from: url)
        }
        return nil
    }

    private static func decodeBirthSpecs(from url: URL) -> [BirthSpec]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        struct Wrapper: Codable {
            let profiles: [BirthSpec]
        }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.profiles
    }

    /// Attempt to compute a real NatalChart from a birth spec using production ephemeris.
    /// Returns nil if the calculator throws or VSOP87 data is unavailable.
    static func computeChart(from spec: BirthSpec) -> NatalChartCalculator.NatalChart? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: spec.birthDateUTC)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: spec.birthDateUTC)
        }
        guard let birthDate = date else { return nil }

        let tz = TimeZone(identifier: spec.timeZoneId) ?? TimeZone(secondsFromGMT: 0)!

        let chart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: spec.latitude,
            longitude: spec.longitude,
            timeZone: tz
        )
        let hasReasonablePlanets = chart.planets.count >= 10
            && chart.planets.contains(where: { $0.name == "Sun" })
        return hasReasonablePlanets ? chart : nil
    }

    /// Build a ChartSpec from a computed NatalChart + ChartAnalysis.
    static func chartSpec(from spec: BirthSpec, chart: NatalChartCalculator.NatalChart) -> ChartSpec {
        let analysis = ChartAnalyser.analyse(chart: chart)

        let signs: [Int] = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                            "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"].map { name in
            chart.planets.first(where: { $0.name == name })?.zodiacSign ?? 0
        }
        let sunSign = chart.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0
        let moonSign = chart.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0
        let risingSign = { () -> Int in
            let (s, _) = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant)
            return s
        }()

        let elementDom = dominantElement(from: analysis.elementBalance)
        let sect = analysis.chartSect == .day ? "day" : "night"
        let stellium = detectStellium(signs: signs)
        let venusCondition = dignityLabel(for: "Venus", in: analysis)

        return ChartSpec(
            id: spec.id, label: spec.label,
            sunSign: sunSign, moonSign: moonSign, risingSign: risingSign,
            signs: signs, elementDominance: elementDom, sect: sect,
            hasStellium: stellium, venusCondition: venusCondition,
            source: .ephemeris
        )
    }

    // MARK: - Active Chart Population

    /// Load real-ephemeris charts from birth specs if available; fall back to synthetic.
    /// Call this to get the population used by Part 3 tests.
    static var allChartsWithEphemeris: [ChartSpec] {
        guard let specs = loadBirthSpecs() else {
            print("⚠️ blueprint_birth_specs.json not found — using synthetic charts")
            return syntheticCharts
        }
        var computed: [ChartSpec] = []
        for spec in specs {
            if let chart = computeChart(from: spec) {
                computed.append(chartSpec(from: spec, chart: chart))
            }
        }
        if computed.isEmpty {
            print("⚠️ Production ephemeris unavailable — using synthetic charts")
            return syntheticCharts
        }
        print("✅ Loaded \(computed.count) real-ephemeris charts from birth specs")
        return computed
    }

    // MARK: - Helpers

    private static func dominantElement(from balance: ElementBalance) -> String {
        let counts: [(String, Int)] = [
            ("fire", balance.fire), ("earth", balance.earth),
            ("air", balance.air), ("water", balance.water)
        ]
        let sorted = counts.sorted { $0.1 > $1.1 }
        let top = sorted[0]
        let second = sorted[1]
        return (top.1 - second.1) >= 2 ? top.0 : "balanced"
    }

    private static func detectStellium(signs: [Int]) -> Bool {
        let freq = Dictionary(grouping: signs, by: { $0 }).mapValues(\.count)
        return freq.values.contains(where: { $0 >= 3 })
    }

    private static func dignityLabel(for planet: String, in analysis: ChartAnalysis) -> String {
        guard let dignity = analysis.planetDignities[planet] else { return "neutral" }
        switch dignity {
        case .domicile, .exaltation: return "dignified"
        case .detriment, .fall: return "debilitated"
        case .peregrine: return "neutral"
        }
    }

    private static func repoRoot() -> URL? {
        var url = URL(fileURLWithPath: #filePath)
        url.deleteLastPathComponent() // Cosmic FitTests
        url.deleteLastPathComponent() // repo root
        return url
    }

    // MARK: - Default accessor (backward-compatible)

    /// Synthetic charts — always available, no ephemeris dependency.
    /// Used as the default for CI and as fallback when birth specs or VSOP87 are unavailable.
    static var allCharts: [ChartSpec] { syntheticCharts }

    // MARK: - All 48 Synthetic Charts

    static let syntheticCharts: [ChartSpec] = [

        // ───────────────────────────────────────────────
        // ARIES SUN (sign 1) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_aries_sun_01", label: "Aries Sun / Cancer Rising",
            sunSign: 1, moonSign: 5, risingSign: 4,
            signs: [1, 5, 1, 2, 9, 3, 10, 1, 12, 8],
            elementDominance: "fire", sect: "night",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_aries_sun_02", label: "Aries Sun / Libra Rising",
            sunSign: 1, moonSign: 4, risingSign: 7,
            signs: [1, 4, 12, 1, 5, 7, 2, 11, 12, 8],
            elementDominance: "water", sect: "day",
            hasStellium: false, venusCondition: "debilitated"
        ),
        ChartSpec(
            id: "ext_aries_sun_03", label: "Aries Sun / Capricorn Rising / stellium",
            sunSign: 1, moonSign: 9, risingSign: 10,
            signs: [1, 9, 1, 1, 5, 6, 10, 9, 12, 8],
            elementDominance: "fire", sect: "day",
            hasStellium: true, venusCondition: "debilitated"
        ),
        ChartSpec(
            id: "ext_aries_sun_04", label: "Aries Sun / Aquarius Rising",
            sunSign: 1, moonSign: 11, risingSign: 11,
            signs: [1, 11, 2, 2, 3, 5, 10, 11, 12, 8],
            elementDominance: "air", sect: "day",
            hasStellium: false, venusCondition: "dignified"
        ),

        // ───────────────────────────────────────────────
        // TAURUS SUN (sign 2) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_taurus_sun_01", label: "Taurus Sun / Scorpio Rising",
            sunSign: 2, moonSign: 8, risingSign: 8,
            signs: [2, 8, 3, 2, 6, 4, 10, 11, 12, 8],
            elementDominance: "water", sect: "day",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_taurus_sun_02", label: "Taurus Sun / Leo Rising",
            sunSign: 2, moonSign: 12, risingSign: 5,
            signs: [2, 12, 1, 3, 9, 7, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_taurus_sun_03", label: "Taurus Sun / Taurus Rising / earth stellium",
            sunSign: 2, moonSign: 6, risingSign: 2,
            signs: [2, 6, 2, 2, 10, 8, 6, 11, 12, 8],
            elementDominance: "earth", sect: "night",
            hasStellium: true, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_taurus_sun_04", label: "Taurus Sun / Pisces Rising",
            sunSign: 2, moonSign: 1, risingSign: 12,
            signs: [2, 1, 3, 4, 5, 9, 10, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // GEMINI SUN (sign 3) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_gemini_sun_01", label: "Gemini Sun / Virgo Rising",
            sunSign: 3, moonSign: 7, risingSign: 6,
            signs: [3, 7, 4, 3, 1, 5, 10, 11, 12, 8],
            elementDominance: "air", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_gemini_sun_02", label: "Gemini Sun / Sagittarius Rising",
            sunSign: 3, moonSign: 4, risingSign: 9,
            signs: [3, 4, 3, 2, 5, 9, 6, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_gemini_sun_03", label: "Gemini Sun / Gemini Rising / air stellium",
            sunSign: 3, moonSign: 11, risingSign: 3,
            signs: [3, 11, 3, 3, 7, 1, 10, 11, 12, 8],
            elementDominance: "air", sect: "night",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_gemini_sun_04", label: "Gemini Sun / Pisces Rising",
            sunSign: 3, moonSign: 8, risingSign: 12,
            signs: [3, 8, 2, 4, 9, 6, 2, 11, 12, 8],
            elementDominance: "water", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // CANCER SUN (sign 4) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_cancer_sun_01", label: "Cancer Sun / Aries Rising",
            sunSign: 4, moonSign: 12, risingSign: 1,
            signs: [4, 12, 3, 4, 8, 5, 10, 11, 12, 8],
            elementDominance: "water", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_cancer_sun_02", label: "Cancer Sun / Libra Rising",
            sunSign: 4, moonSign: 2, risingSign: 7,
            signs: [4, 2, 5, 4, 6, 9, 10, 11, 12, 8],
            elementDominance: "earth", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_cancer_sun_03", label: "Cancer Sun / Cancer Rising / water stellium",
            sunSign: 4, moonSign: 8, risingSign: 4,
            signs: [4, 8, 4, 4, 12, 1, 10, 11, 12, 8],
            elementDominance: "water", sect: "night",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_cancer_sun_04", label: "Cancer Sun / Sagittarius Rising",
            sunSign: 4, moonSign: 5, risingSign: 9,
            signs: [4, 5, 3, 6, 1, 7, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // LEO SUN (sign 5) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_leo_sun_01", label: "Leo Sun / Taurus Rising",
            sunSign: 5, moonSign: 9, risingSign: 2,
            signs: [5, 9, 5, 4, 1, 3, 10, 11, 12, 8],
            elementDominance: "fire", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_leo_sun_02", label: "Leo Sun / Aquarius Rising",
            sunSign: 5, moonSign: 4, risingSign: 11,
            signs: [5, 4, 6, 7, 9, 1, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_leo_sun_03", label: "Leo Sun / Leo Rising / fire stellium",
            sunSign: 5, moonSign: 1, risingSign: 5,
            signs: [5, 1, 5, 5, 9, 1, 10, 11, 12, 8],
            elementDominance: "fire", sect: "night",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_leo_sun_04", label: "Leo Sun / Capricorn Rising",
            sunSign: 5, moonSign: 10, risingSign: 10,
            signs: [5, 10, 4, 6, 2, 7, 10, 11, 12, 8],
            elementDominance: "earth", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // VIRGO SUN (sign 6) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_virgo_sun_01", label: "Virgo Sun / Gemini Rising",
            sunSign: 6, moonSign: 3, risingSign: 3,
            signs: [6, 3, 7, 5, 10, 9, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_virgo_sun_02", label: "Virgo Sun / Pisces Rising",
            sunSign: 6, moonSign: 8, risingSign: 12,
            signs: [6, 8, 5, 7, 4, 6, 10, 11, 12, 8],
            elementDominance: "water", sect: "day",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_virgo_sun_03", label: "Virgo Sun / Virgo Rising / earth stellium",
            sunSign: 6, moonSign: 2, risingSign: 6,
            signs: [6, 2, 6, 6, 10, 4, 2, 11, 12, 8],
            elementDominance: "earth", sect: "night",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_virgo_sun_04", label: "Virgo Sun / Sagittarius Rising",
            sunSign: 6, moonSign: 11, risingSign: 9,
            signs: [6, 11, 7, 8, 1, 5, 10, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "debilitated"
        ),

        // ───────────────────────────────────────────────
        // LIBRA SUN (sign 7) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_libra_sun_01", label: "Libra Sun / Aries Rising",
            sunSign: 7, moonSign: 4, risingSign: 1,
            signs: [7, 4, 8, 7, 3, 5, 10, 11, 12, 8],
            elementDominance: "air", sect: "night",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_libra_sun_02", label: "Libra Sun / Cancer Rising",
            sunSign: 7, moonSign: 1, risingSign: 4,
            signs: [7, 1, 6, 8, 9, 3, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "debilitated"
        ),
        ChartSpec(
            id: "ext_libra_sun_03", label: "Libra Sun / Libra Rising / air stellium",
            sunSign: 7, moonSign: 3, risingSign: 7,
            signs: [7, 3, 7, 7, 11, 9, 10, 11, 12, 8],
            elementDominance: "air", sect: "day",
            hasStellium: true, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_libra_sun_04", label: "Libra Sun / Capricorn Rising",
            sunSign: 7, moonSign: 12, risingSign: 10,
            signs: [7, 12, 8, 9, 2, 6, 10, 11, 12, 8],
            elementDominance: "earth", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // SCORPIO SUN (sign 8) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_scorpio_sun_01", label: "Scorpio Sun / Taurus Rising",
            sunSign: 8, moonSign: 5, risingSign: 2,
            signs: [8, 5, 7, 6, 1, 9, 10, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_scorpio_sun_02", label: "Scorpio Sun / Leo Rising",
            sunSign: 8, moonSign: 4, risingSign: 5,
            signs: [8, 4, 9, 7, 12, 3, 2, 11, 12, 8],
            elementDominance: "water", sect: "night",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_scorpio_sun_03", label: "Scorpio Sun / Scorpio Rising / water stellium",
            sunSign: 8, moonSign: 12, risingSign: 8,
            signs: [8, 12, 8, 8, 4, 5, 10, 11, 12, 8],
            elementDominance: "water", sect: "day",
            hasStellium: true, venusCondition: "debilitated"
        ),
        ChartSpec(
            id: "ext_scorpio_sun_04", label: "Scorpio Sun / Aquarius Rising",
            sunSign: 8, moonSign: 6, risingSign: 11,
            signs: [8, 6, 9, 10, 5, 7, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // SAGITTARIUS SUN (sign 9) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_sag_sun_01", label: "Sagittarius Sun / Virgo Rising",
            sunSign: 9, moonSign: 7, risingSign: 6,
            signs: [9, 7, 10, 8, 5, 1, 10, 11, 12, 8],
            elementDominance: "fire", sect: "night",
            hasStellium: false, venusCondition: "debilitated"
        ),
        ChartSpec(
            id: "ext_sag_sun_02", label: "Sagittarius Sun / Pisces Rising",
            sunSign: 9, moonSign: 2, risingSign: 12,
            signs: [9, 2, 8, 10, 1, 3, 6, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_sag_sun_03", label: "Sagittarius Sun / Sag Rising / fire stellium",
            sunSign: 9, moonSign: 5, risingSign: 9,
            signs: [9, 5, 9, 9, 1, 5, 10, 11, 12, 8],
            elementDominance: "fire", sect: "day",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_sag_sun_04", label: "Sagittarius Sun / Taurus Rising",
            sunSign: 9, moonSign: 11, risingSign: 2,
            signs: [9, 11, 10, 7, 5, 3, 2, 11, 12, 8],
            elementDominance: "air", sect: "night",
            hasStellium: false, venusCondition: "dignified"
        ),

        // ───────────────────────────────────────────────
        // CAPRICORN SUN (sign 10) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_cap_sun_01", label: "Capricorn Sun / Aries Rising",
            sunSign: 10, moonSign: 4, risingSign: 1,
            signs: [10, 4, 11, 8, 9, 6, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "debilitated"
        ),
        ChartSpec(
            id: "ext_cap_sun_02", label: "Capricorn Sun / Cancer Rising",
            sunSign: 10, moonSign: 9, risingSign: 4,
            signs: [10, 9, 11, 12, 5, 3, 6, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_cap_sun_03", label: "Capricorn Sun / Cap Rising / earth stellium",
            sunSign: 10, moonSign: 6, risingSign: 10,
            signs: [10, 6, 10, 10, 2, 4, 6, 11, 12, 8],
            elementDominance: "earth", sect: "day",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_cap_sun_04", label: "Capricorn Sun / Leo Rising",
            sunSign: 10, moonSign: 3, risingSign: 5,
            signs: [10, 3, 9, 12, 1, 7, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),

        // ───────────────────────────────────────────────
        // AQUARIUS SUN (sign 11) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_aquarius_sun_01", label: "Aquarius Sun / Taurus Rising",
            sunSign: 11, moonSign: 8, risingSign: 2,
            signs: [11, 8, 10, 9, 3, 5, 10, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_aquarius_sun_02", label: "Aquarius Sun / Leo Rising",
            sunSign: 11, moonSign: 1, risingSign: 5,
            signs: [11, 1, 12, 12, 5, 7, 2, 11, 12, 8],
            elementDominance: "water", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_aquarius_sun_03", label: "Aquarius Sun / Aquarius Rising / air stellium",
            sunSign: 11, moonSign: 7, risingSign: 11,
            signs: [11, 7, 11, 11, 3, 1, 10, 11, 12, 8],
            elementDominance: "air", sect: "day",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_aquarius_sun_04", label: "Aquarius Sun / Scorpio Rising",
            sunSign: 11, moonSign: 6, risingSign: 8,
            signs: [11, 6, 12, 1, 9, 4, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "debilitated"
        ),

        // ───────────────────────────────────────────────
        // PISCES SUN (sign 12) — 4 charts
        // ───────────────────────────────────────────────

        ChartSpec(
            id: "ext_pisces_sun_01", label: "Pisces Sun / Gemini Rising",
            sunSign: 12, moonSign: 4, risingSign: 3,
            signs: [12, 4, 11, 2, 1, 6, 10, 11, 12, 8],
            elementDominance: "water", sect: "night",
            hasStellium: false, venusCondition: "dignified"
        ),
        ChartSpec(
            id: "ext_pisces_sun_02", label: "Pisces Sun / Virgo Rising",
            sunSign: 12, moonSign: 5, risingSign: 6,
            signs: [12, 5, 1, 10, 9, 3, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "night",
            hasStellium: false, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_pisces_sun_03", label: "Pisces Sun / Pisces Rising / water stellium",
            sunSign: 12, moonSign: 8, risingSign: 12,
            signs: [12, 8, 12, 12, 4, 5, 10, 11, 12, 8],
            elementDominance: "water", sect: "day",
            hasStellium: true, venusCondition: "neutral"
        ),
        ChartSpec(
            id: "ext_pisces_sun_04", label: "Pisces Sun / Sagittarius Rising",
            sunSign: 12, moonSign: 10, risingSign: 9,
            signs: [12, 10, 1, 1, 5, 7, 2, 11, 12, 8],
            elementDominance: "balanced", sect: "day",
            hasStellium: false, venusCondition: "debilitated"
        ),
    ]
}

private class _CalibrationBundleToken {}
