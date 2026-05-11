//
//  DailyEnergyEngine_VibeProfile_Tests.swift
//  Cosmic FitTests
//
//  Phase 1 acceptance tests for DailyEnergyEngine.generateVibeProfile().
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Fixtures

private enum ChartFixtures {

    static let standardPlanets: [(String, String)] = [
        ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
        ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
        ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
    ]

    /// Build a NatalChart with the Sun in a given sign and remaining planets spread across signs.
    static func chart(sunSign: Int, moonSign: Int? = nil, spreadElement: String? = nil) -> NatalChartCalculator.NatalChart {
        var planets: [NatalChartCalculator.PlanetPosition] = []
        let signs = distributedSigns(sunSign: sunSign, moonSign: moonSign, element: spreadElement)

        for (index, (name, symbol)) in standardPlanets.enumerated() {
            let sign = signs[index]
            planets.append(NatalChartCalculator.PlanetPosition(
                name: name,
                symbol: symbol,
                longitude: Double((sign - 1) * 30 + 15),
                latitude: 0.0,
                zodiacSign: sign,
                zodiacPosition: "15°00'",
                isRetrograde: false
            ))
        }

        return NatalChartCalculator.NatalChart(
            planets: planets,
            ascendant: 0.0,
            midheaven: 90.0,
            descendant: 180.0,
            imumCoeli: 270.0,
            houseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            wholeSignHouseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            northNode: 0.0,
            southNode: 180.0,
            vertex: 90.0,
            partOfFortune: 45.0,
            lilith: 120.0,
            chiron: 200.0,
            lunarPhase: 90.0
        )
    }

    /// Distribute planet signs with Sun and Moon controlled, rest spread.
    private static func distributedSigns(sunSign: Int, moonSign: Int?, element: String?) -> [Int] {
        var signs = [Int](repeating: 1, count: 10)
        signs[0] = sunSign  // Sun
        signs[1] = moonSign ?? ((sunSign % 12) + 3)  // Moon defaults to 2 signs ahead

        if let element = element {
            let elementSigns = signsForElement(element)
            for i in 2..<10 {
                signs[i] = elementSigns[i % elementSigns.count]
            }
        } else {
            for i in 2..<10 {
                signs[i] = ((sunSign + i * 2) % 12) + 1
            }
        }
        return signs
    }

    private static func signsForElement(_ element: String) -> [Int] {
        switch element {
        case "Fire":  return [1, 5, 9]    // Aries, Leo, Sagittarius
        case "Earth": return [2, 6, 10]   // Taurus, Virgo, Capricorn
        case "Air":   return [3, 7, 11]   // Gemini, Libra, Aquarius
        case "Water": return [4, 8, 12]   // Cancer, Scorpio, Pisces
        default:      return [1, 2, 3]
        }
    }

    static func leoChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 5)  // Leo = Fire
    }

    static func virgoChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 6)  // Virgo = Earth
    }

    static func piscesChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 12)  // Pisces = Water
    }

    static func aquariusChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 11)  // Aquarius = Air
    }

    static func heavyWaterChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 4, moonSign: 8, spreadElement: "Water")  // Cancer Sun, Scorpio Moon
    }

    static let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    static func sampleTransits(aspect: String = "conjunction", orb: Double = 2.0) -> [NatalChartCalculator.TransitAspect] {
        let now = fixedDate
        return [
            NatalChartCalculator.TransitAspect(
                transitPlanet: "Mars",
                transitPlanetSymbol: "♂",
                natalPlanet: "Venus",
                natalPlanetSymbol: "♀",
                aspectType: aspect,
                aspectSymbol: "☌",
                orb: orb,
                applying: true,
                effectiveFrom: now,
                effectiveTo: now.addingTimeInterval(86400 * 3),
                description: "Mars \(aspect) Venus",
                category: .shortTerm
            ),
            NatalChartCalculator.TransitAspect(
                transitPlanet: "Jupiter",
                transitPlanetSymbol: "♃",
                natalPlanet: "Sun",
                natalPlanetSymbol: "☉",
                aspectType: "trine",
                aspectSymbol: "△",
                orb: 3.5,
                applying: false,
                effectiveFrom: now,
                effectiveTo: now.addingTimeInterval(86400 * 7),
                description: "Jupiter trine Sun",
                category: .regular
            )
        ]
    }

    /// Many tight hard transits from drama/edge-heavy planets.
    static func heavyHardTransits() -> [NatalChartCalculator.TransitAspect] {
        let now = fixedDate
        let planets = ["Mars", "Pluto", "Uranus", "Mars", "Pluto"]
        let symbols = ["♂", "♇", "♅", "♂", "♇"]
        return zip(planets, symbols).enumerated().map { (i, pair) in
            NatalChartCalculator.TransitAspect(
                transitPlanet: pair.0,
                transitPlanetSymbol: pair.1,
                natalPlanet: "Sun",
                natalPlanetSymbol: "☉",
                aspectType: "square",
                aspectSymbol: "□",
                orb: 0.5,
                applying: true,
                effectiveFrom: now,
                effectiveTo: now.addingTimeInterval(86400 * 3),
                description: "\(pair.0) square Sun",
                category: .shortTerm
            )
        }
    }

    /// Many tight soft transits from romantic/classic-heavy planets.
    static func heavySoftTransits() -> [NatalChartCalculator.TransitAspect] {
        let now = fixedDate
        let planets = ["Venus", "Neptune", "Moon", "Venus", "Jupiter"]
        let symbols = ["♀", "♆", "☽", "♀", "♃"]
        return zip(planets, symbols).enumerated().map { (i, pair) in
            NatalChartCalculator.TransitAspect(
                transitPlanet: pair.0,
                transitPlanetSymbol: pair.1,
                natalPlanet: "Mars",
                natalPlanetSymbol: "♂",
                aspectType: "trine",
                aspectSymbol: "△",
                orb: 0.5,
                applying: true,
                effectiveFrom: now,
                effectiveTo: now.addingTimeInterval(86400 * 5),
                description: "\(pair.0) trine Mars",
                category: .regular
            )
        }
    }
}

// MARK: - Tests

@Suite("DailyEnergyEngine – Vibe Profile Generation")
struct DailyEnergyEngine_VibeProfile_Tests {

    let fixedDate = ChartFixtures.fixedDate
    let defaultTransits = ChartFixtures.sampleTransits()

    // T1.1: All outputs total 21 points
    @Test("Vibe profile totals 21 points for varied charts")
    func testVibeProfileTotals21Points() {
        let charts = [
            ChartFixtures.leoChart(),
            ChartFixtures.virgoChart(),
            ChartFixtures.piscesChart(),
            ChartFixtures.aquariusChart(),
            ChartFixtures.heavyWaterChart()
        ]

        for chart in charts {
            let vibe = DailyEnergyEngine.generateVibeProfile(
                natalChart: chart,
                progressedChart: chart,
                transits: defaultTransits,
                moonPhaseDegrees: 90.0,
                date: fixedDate
            )
            #expect(vibe.totalPoints == 21)
        }
    }

    // T1.2: All energies in 0-10 range
    @Test("All energy values are 0–10")
    func testVibeProfileAllEnergiesInRange() {
        let charts = [
            ChartFixtures.leoChart(),
            ChartFixtures.virgoChart(),
            ChartFixtures.piscesChart(),
            ChartFixtures.aquariusChart(),
            ChartFixtures.heavyWaterChart()
        ]

        for chart in charts {
            let vibe = DailyEnergyEngine.generateVibeProfile(
                natalChart: chart,
                progressedChart: chart,
                transits: defaultTransits,
                moonPhaseDegrees: 45.0,
                date: fixedDate
            )
            for energy in Energy.allCases {
                let val = vibe.value(for: energy)
                #expect(val >= 0 && val <= 10, "Energy \(energy) was \(val)")
            }
        }
    }

    // T1.3: Deterministic - same inputs → same output
    @Test("Deterministic output for identical inputs")
    func testVibeProfileDeterministic() {
        let chart = ChartFixtures.leoChart()

        let first = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )
        let second = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )
        let third = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )

        #expect(first.classic == second.classic && second.classic == third.classic)
        #expect(first.playful == second.playful && second.playful == third.playful)
        #expect(first.romantic == second.romantic && second.romantic == third.romantic)
        #expect(first.utility == second.utility && second.utility == third.utility)
        #expect(first.drama == second.drama && second.drama == third.drama)
        #expect(first.edge == second.edge && second.edge == third.edge)
    }

    // T1.4: Leo has drama above average
    @Test("Leo chart produces drama >= 4")
    func testLeoHasDramaAboveAverage() {
        let chart = ChartFixtures.leoChart()
        let vibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )
        #expect(vibe.drama >= 4, "Leo drama was \(vibe.drama)")
    }

    // T1.5: Virgo has classic above average
    @Test("Virgo chart produces classic >= 4")
    func testVirgoHasClassicAboveAverage() {
        let chart = ChartFixtures.virgoChart()
        let vibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )
        #expect(vibe.classic >= 4, "Virgo classic was \(vibe.classic)")
    }

    // T1.6: Pisces has romantic above average
    @Test("Pisces chart produces romantic >= 4")
    func testPiscesHasRomanticAboveAverage() {
        let chart = ChartFixtures.piscesChart()
        let vibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )
        #expect(vibe.romantic >= 4, "Pisces romantic was \(vibe.romantic)")
    }

    // T1.7: Aquarius has edge above average
    @Test("Aquarius chart produces edge >= 4")
    func testAquariusHasEdgeAboveAverage() {
        let chart = ChartFixtures.aquariusChart()
        let vibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: defaultTransits, moonPhaseDegrees: 90.0, date: fixedDate
        )
        #expect(vibe.edge >= 4, "Aquarius edge was \(vibe.edge)")
    }

    // T1.8: Transits affect output
    @Test("Different transits produce different vibe profiles")
    func testTransitsAffectOutput() {
        let chart = ChartFixtures.leoChart()

        let hardVibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: ChartFixtures.heavyHardTransits(),
            moonPhaseDegrees: 90.0, date: fixedDate
        )
        let softVibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: ChartFixtures.heavySoftTransits(),
            moonPhaseDegrees: 90.0, date: fixedDate
        )

        let different = hardVibe.classic != softVibe.classic ||
            hardVibe.playful != softVibe.playful ||
            hardVibe.romantic != softVibe.romantic ||
            hardVibe.utility != softVibe.utility ||
            hardVibe.drama != softVibe.drama ||
            hardVibe.edge != softVibe.edge
        #expect(different, "Hard and soft transits should produce different vibes")
    }

    // T1.9: Moon phase affects output
    @Test("New moon vs full moon produces different vibe profiles")
    func testMoonPhaseAffectsOutput() {
        let chart = ChartFixtures.leoChart()
        // Amplify lunar weight to ensure the phase difference survives discretization
        let lunarSensitive = DailyFitCalibration(
            sourceWeights: .init(natal: 0.15, transits: 0.0, lunarPhase: 0.70, progressed: 0.10, currentSun: 0.05),
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: DailyFitCalibration.default.selectionWeights
        )

        let newMoonVibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 0.0, date: fixedDate,
            calibration: lunarSensitive
        )
        let fullMoonVibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: [], moonPhaseDegrees: 180.0, date: fixedDate,
            calibration: lunarSensitive
        )

        let different = newMoonVibe.classic != fullMoonVibe.classic ||
            newMoonVibe.playful != fullMoonVibe.playful ||
            newMoonVibe.romantic != fullMoonVibe.romantic ||
            newMoonVibe.utility != fullMoonVibe.utility ||
            newMoonVibe.drama != fullMoonVibe.drama ||
            newMoonVibe.edge != fullMoonVibe.edge
        #expect(different, "New moon and full moon should produce different vibes")
    }

    // T1.10: Source weights respected
    @Test("Source weights control contribution dominance")
    func testSourceWeightsRespected() {
        let chart = ChartFixtures.leoChart()
        let emptyTransits: [NatalChartCalculator.TransitAspect] = []

        let natalOnly = DailyFitCalibration(
            sourceWeights: .init(natal: 1.0, transits: 0.0, lunarPhase: 0.0, progressed: 0.0, currentSun: 0.0),
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: DailyFitCalibration.default.selectionWeights
        )
        let transitsOnly = DailyFitCalibration(
            sourceWeights: .init(natal: 0.0, transits: 1.0, lunarPhase: 0.0, progressed: 0.0, currentSun: 0.0),
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: DailyFitCalibration.default.selectionWeights
        )

        let natalVibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: ChartFixtures.sampleTransits(aspect: "square", orb: 0.5),
            moonPhaseDegrees: 90.0, date: fixedDate, calibration: natalOnly
        )
        let transitVibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: ChartFixtures.sampleTransits(aspect: "square", orb: 0.5),
            moonPhaseDegrees: 90.0, date: fixedDate, calibration: transitsOnly
        )

        let different = natalVibe.classic != transitVibe.classic ||
            natalVibe.playful != transitVibe.playful ||
            natalVibe.romantic != transitVibe.romantic ||
            natalVibe.utility != transitVibe.utility ||
            natalVibe.drama != transitVibe.drama ||
            natalVibe.edge != transitVibe.edge
        #expect(different, "Natal-only and transit-only should produce different distributions")
    }

    // T1.11: No single energy dominates over 60%
    @Test("No energy exceeds 13 points (60% of 21)")
    func testNoEnergyDominatesOver60Percent() {
        let charts = [
            ChartFixtures.leoChart(),
            ChartFixtures.virgoChart(),
            ChartFixtures.piscesChart(),
            ChartFixtures.aquariusChart(),
            ChartFixtures.heavyWaterChart()
        ]
        let moonPhases: [Double] = [0.0, 90.0, 180.0, 270.0]

        for chart in charts {
            for phase in moonPhases {
                let vibe = DailyEnergyEngine.generateVibeProfile(
                    natalChart: chart, progressedChart: chart,
                    transits: defaultTransits, moonPhaseDegrees: phase, date: fixedDate
                )
                for energy in Energy.allCases {
                    #expect(vibe.value(for: energy) <= 13,
                            "Energy \(energy) exceeded 13 points")
                }
            }
        }
    }

    // T1.12: Empty transits still produce valid output
    @Test("Empty transits still produce valid 21-point breakdown")
    func testEmptyTransitsStillProducesValidOutput() {
        let chart = ChartFixtures.leoChart()
        let vibe = DailyEnergyEngine.generateVibeProfile(
            natalChart: chart, progressedChart: chart,
            transits: [],
            moonPhaseDegrees: 90.0,
            date: fixedDate
        )
        #expect(vibe.totalPoints == 21)
        for energy in Energy.allCases {
            let val = vibe.value(for: energy)
            #expect(val >= 0 && val <= 10)
        }
    }
}
