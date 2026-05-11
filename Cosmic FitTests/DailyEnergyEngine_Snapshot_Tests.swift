//
//  DailyEnergyEngine_Snapshot_Tests.swift
//  Cosmic FitTests
//
//  Phase 2 acceptance tests for DailyEnergyEngine.generateSnapshot().
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Fixtures

private enum SnapshotFixtures {

    static let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
    static let profileHash = "test_profile_abc123"

    // MARK: Chart Building

    static let standardPlanets: [(String, String)] = [
        ("Sun", "☉"), ("Moon", "☽"), ("Mercury", "☿"), ("Venus", "♀"),
        ("Mars", "♂"), ("Jupiter", "♃"), ("Saturn", "♄"),
        ("Uranus", "♅"), ("Neptune", "♆"), ("Pluto", "♇")
    ]

    static func chart(
        sunSign: Int, moonSign: Int? = nil, spreadElement: String? = nil
    ) -> NatalChartCalculator.NatalChart {
        var planets: [NatalChartCalculator.PlanetPosition] = []
        let signs = distributedSigns(
            sunSign: sunSign, moonSign: moonSign, element: spreadElement
        )
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
            ascendant: 0.0, midheaven: 90.0,
            descendant: 180.0, imumCoeli: 270.0,
            houseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            wholeSignHouseCusps: Array(stride(from: 0.0, to: 360.0, by: 30.0)),
            northNode: 0.0, southNode: 180.0, vertex: 90.0,
            partOfFortune: 45.0, lilith: 120.0, chiron: 200.0,
            lunarPhase: 90.0
        )
    }

    private static func distributedSigns(
        sunSign: Int, moonSign: Int?, element: String?
    ) -> [Int] {
        var signs = [Int](repeating: 1, count: 10)
        signs[0] = sunSign
        signs[1] = moonSign ?? ((sunSign % 12) + 3)
        if let element = element {
            let eSigns = signsForElement(element)
            for i in 2..<10 { signs[i] = eSigns[i % eSigns.count] }
        } else {
            for i in 2..<10 { signs[i] = ((sunSign + i * 2) % 12) + 1 }
        }
        return signs
    }

    private static func signsForElement(_ element: String) -> [Int] {
        switch element {
        case "Fire":  return [1, 5, 9]
        case "Earth": return [2, 6, 10]
        case "Air":   return [3, 7, 11]
        case "Water": return [4, 8, 12]
        default:      return [1, 2, 3]
        }
    }

    static func leoChart() -> NatalChartCalculator.NatalChart { chart(sunSign: 5) }
    static func virgoChart() -> NatalChartCalculator.NatalChart { chart(sunSign: 6) }
    static func piscesChart() -> NatalChartCalculator.NatalChart { chart(sunSign: 12) }
    static func aquariusChart() -> NatalChartCalculator.NatalChart { chart(sunSign: 11) }

    static func heavyFireChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 1, moonSign: 5, spreadElement: "Fire")
    }
    static func heavyEarthChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 2, moonSign: 6, spreadElement: "Earth")
    }
    static func heavyWaterChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 4, moonSign: 8, spreadElement: "Water")
    }
    static func heavyAirChart() -> NatalChartCalculator.NatalChart {
        chart(sunSign: 3, moonSign: 7, spreadElement: "Air")
    }

    // MARK: Transit Fixtures

    static func makeTransit(
        planet: String, natal: String = "Sun",
        aspect: String = "conjunction", orb: Double = 1.0
    ) -> NatalChartCalculator.TransitAspect {
        NatalChartCalculator.TransitAspect(
            transitPlanet: planet, transitPlanetSymbol: "•",
            natalPlanet: natal, natalPlanetSymbol: "•",
            aspectType: aspect, aspectSymbol: "•",
            orb: orb, applying: true,
            effectiveFrom: fixedDate,
            effectiveTo: fixedDate.addingTimeInterval(86400 * 3),
            description: "\(planet) \(aspect) \(natal)",
            category: .shortTerm
        )
    }

    static func heavyMarsTransits() -> [NatalChartCalculator.TransitAspect] {
        [
            makeTransit(planet: "Mars", natal: "Sun", aspect: "conjunction", orb: 0.5),
            makeTransit(planet: "Mars", natal: "Moon", aspect: "square", orb: 1.0),
            makeTransit(planet: "Pluto", natal: "Mars", aspect: "conjunction", orb: 0.3),
            makeTransit(planet: "Jupiter", natal: "Venus", aspect: "opposition", orb: 1.5),
            makeTransit(planet: "Uranus", natal: "Mercury", aspect: "square", orb: 2.0),
        ]
    }

    static func softVenusTransits() -> [NatalChartCalculator.TransitAspect] {
        [
            makeTransit(planet: "Venus", natal: "Moon", aspect: "trine", orb: 0.5),
            makeTransit(planet: "Neptune", natal: "Venus", aspect: "sextile", orb: 1.0),
            makeTransit(planet: "Moon", natal: "Neptune", aspect: "trine", orb: 2.0),
        ]
    }

    static func mixedTransits() -> [NatalChartCalculator.TransitAspect] {
        [
            makeTransit(planet: "Mars", natal: "Venus", aspect: "conjunction", orb: 2.0),
            makeTransit(planet: "Jupiter", natal: "Sun", aspect: "trine", orb: 3.5),
        ]
    }

    static func largeTransitArray() -> [NatalChartCalculator.TransitAspect] {
        let planets = [
            "Mars", "Venus", "Jupiter", "Saturn", "Pluto",
            "Uranus", "Neptune", "Mercury", "Sun", "Moon",
            "Mars", "Venus", "Jupiter", "Saturn", "Pluto",
            "Uranus", "Neptune", "Mercury", "Sun", "Moon",
        ]
        let aspects = ["conjunction", "square", "opposition", "trine", "sextile"]
        return planets.enumerated().map { i, planet in
            makeTransit(
                planet: planet, natal: "Sun",
                aspect: aspects[i % aspects.count],
                orb: Double(i % 5) + 0.5
            )
        }
    }

    // MARK: Snapshot Helper

    static func defaultSnapshot(
        chart: NatalChartCalculator.NatalChart? = nil,
        transits: [NatalChartCalculator.TransitAspect]? = nil,
        moonPhaseDegrees: Double = 90.0
    ) -> DailyEnergySnapshot {
        DailyEnergyEngine.generateSnapshot(
            natalChart: chart ?? leoChart(),
            progressedChart: chart ?? leoChart(),
            transits: transits ?? mixedTransits(),
            moonPhaseDegrees: moonPhaseDegrees,
            profileHash: profileHash,
            date: fixedDate
        )
    }
}

// MARK: - Tests

@Suite("DailyEnergyEngine – Snapshot Assembly")
struct DailyEnergyEngine_Snapshot_Tests {

    // MARK: T2.1

    @Test("Snapshot contains valid vibe profile")
    func testSnapshotContainsValidVibeProfile() {
        let snapshot = SnapshotFixtures.defaultSnapshot()
        #expect(snapshot.vibeProfile.totalPoints == 21)
        #expect(snapshot.vibeProfile.isValid)
    }

    // MARK: T2.2

    @Test("Snapshot axes all in 1.0–10.0 range")
    func testSnapshotAxesInRange() {
        let snapshot = SnapshotFixtures.defaultSnapshot()
        #expect(snapshot.axes.action >= 1.0 && snapshot.axes.action <= 10.0)
        #expect(snapshot.axes.tempo >= 1.0 && snapshot.axes.tempo <= 10.0)
        #expect(snapshot.axes.strategy >= 1.0 && snapshot.axes.strategy <= 10.0)
        #expect(snapshot.axes.visibility >= 1.0 && snapshot.axes.visibility <= 10.0)
    }

    // MARK: T2.3

    @Test("Axes use full 1–10 range across varied inputs")
    func testSnapshotAxesUseFullRange() {
        let inputs: [(
            NatalChartCalculator.NatalChart,
            [NatalChartCalculator.TransitAspect],
            Double
        )] = [
            (SnapshotFixtures.heavyFireChart(), SnapshotFixtures.heavyMarsTransits(), 180.0),
            (SnapshotFixtures.heavyWaterChart(), SnapshotFixtures.softVenusTransits(), 0.0),
            (SnapshotFixtures.heavyEarthChart(), [], 0.0),
            (SnapshotFixtures.heavyAirChart(), SnapshotFixtures.mixedTransits(), 90.0),
            (SnapshotFixtures.leoChart(), SnapshotFixtures.heavyMarsTransits(), 270.0),
            (SnapshotFixtures.virgoChart(), [], 180.0),
            (SnapshotFixtures.piscesChart(), SnapshotFixtures.softVenusTransits(), 45.0),
            (SnapshotFixtures.aquariusChart(), SnapshotFixtures.mixedTransits(), 315.0),
            (SnapshotFixtures.heavyFireChart(), [], 0.0),
            (SnapshotFixtures.heavyWaterChart(), SnapshotFixtures.heavyMarsTransits(), 180.0),
        ]

        var allValues: [Double] = []
        for (chart, transits, moonPhase) in inputs {
            let snapshot = DailyEnergyEngine.generateSnapshot(
                natalChart: chart, progressedChart: chart,
                transits: transits, moonPhaseDegrees: moonPhase,
                profileHash: SnapshotFixtures.profileHash,
                date: SnapshotFixtures.fixedDate
            )
            allValues.append(contentsOf: [
                snapshot.axes.action, snapshot.axes.tempo,
                snapshot.axes.strategy, snapshot.axes.visibility,
            ])
        }

        let minVal = allValues.min()!
        let maxVal = allValues.max()!
        #expect(minVal <= 3.0, "Min axis value \(minVal) should be ≤ 3.0")
        #expect(maxVal >= 8.0, "Max axis value \(maxVal) should be ≥ 8.0")
    }

    // MARK: T2.4

    @Test("Snapshot is deterministic for same inputs")
    func testSnapshotDeterministic() {
        let chart = SnapshotFixtures.leoChart()
        let transits = SnapshotFixtures.mixedTransits()

        let s1 = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart, transits: transits,
            moonPhaseDegrees: 90.0, profileHash: SnapshotFixtures.profileHash,
            date: SnapshotFixtures.fixedDate
        )
        let s2 = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart, transits: transits,
            moonPhaseDegrees: 90.0, profileHash: SnapshotFixtures.profileHash,
            date: SnapshotFixtures.fixedDate
        )

        #expect(s1.vibeProfile.classic == s2.vibeProfile.classic)
        #expect(s1.vibeProfile.playful == s2.vibeProfile.playful)
        #expect(s1.vibeProfile.romantic == s2.vibeProfile.romantic)
        #expect(s1.vibeProfile.utility == s2.vibeProfile.utility)
        #expect(s1.vibeProfile.drama == s2.vibeProfile.drama)
        #expect(s1.vibeProfile.edge == s2.vibeProfile.edge)

        #expect(s1.axes.action == s2.axes.action)
        #expect(s1.axes.tempo == s2.axes.tempo)
        #expect(s1.axes.strategy == s2.axes.strategy)
        #expect(s1.axes.visibility == s2.axes.visibility)

        #expect(s1.dominantTransits.count == s2.dominantTransits.count)
        for i in 0..<s1.dominantTransits.count {
            #expect(s1.dominantTransits[i] == s2.dominantTransits[i])
        }

        #expect(s1.lunarContext == s2.lunarContext)
        #expect(s1.dailySeed == s2.dailySeed)
        #expect(s1.profileHash == s2.profileHash)
        #expect(s1.generatedAt == s2.generatedAt)
    }

    // MARK: T2.5

    @Test("Dominant transits limited to 5")
    func testDominantTransitsLimitedTo5() {
        let transits = SnapshotFixtures.largeTransitArray()
        #expect(transits.count == 20)
        let snapshot = SnapshotFixtures.defaultSnapshot(transits: transits)
        #expect(snapshot.dominantTransits.count <= 5)
    }

    // MARK: T2.6

    @Test("Dominant transits ordered by strength descending")
    func testDominantTransitsOrderedByStrength() {
        let snapshot = SnapshotFixtures.defaultSnapshot(
            transits: SnapshotFixtures.largeTransitArray()
        )
        for i in 1..<snapshot.dominantTransits.count {
            let prev = snapshot.dominantTransits[i - 1].strength
            let curr = snapshot.dominantTransits[i].strength
            #expect(prev >= curr,
                    "Transit \(i-1) strength \(prev) should be >= \(curr)")
        }
    }

    // MARK: T2.7

    @Test("Dominant transit strengths normalised to 0.0–1.0")
    func testDominantTransitsStrengthNormalised() {
        let snapshot = SnapshotFixtures.defaultSnapshot(
            transits: SnapshotFixtures.largeTransitArray()
        )
        #expect(!snapshot.dominantTransits.isEmpty)
        #expect(snapshot.dominantTransits[0].strength >= 0.99,
                "Top transit should have strength ≈ 1.0")
        for transit in snapshot.dominantTransits {
            #expect(transit.strength >= 0.0 && transit.strength <= 1.0)
        }
    }

    // MARK: T2.8

    @Test("Lunar context at new moon (0°)")
    func testLunarContextNewMoon() {
        let snapshot = SnapshotFixtures.defaultSnapshot(moonPhaseDegrees: 0.0)
        #expect(snapshot.lunarContext.phaseName == "New Moon")
        #expect(snapshot.lunarContext.isWaxing == true)
    }

    // MARK: T2.9

    @Test("Lunar context at full moon (180°)")
    func testLunarContextFullMoon() {
        let snapshot = SnapshotFixtures.defaultSnapshot(moonPhaseDegrees: 180.0)
        #expect(snapshot.lunarContext.phaseName == "Full Moon")
        #expect(snapshot.lunarContext.isWaxing == false)
    }

    // MARK: T2.10

    @Test("Waxing/waning boundary at 180°")
    func testLunarContextWaxingWaning() {
        for degrees in stride(from: 0.0, through: 179.0, by: 45.0) {
            let snapshot = SnapshotFixtures.defaultSnapshot(
                moonPhaseDegrees: degrees
            )
            #expect(snapshot.lunarContext.isWaxing == true,
                    "Degrees \(degrees) should be waxing")
        }
        for degrees in stride(from: 180.0, through: 359.0, by: 45.0) {
            let snapshot = SnapshotFixtures.defaultSnapshot(
                moonPhaseDegrees: degrees
            )
            #expect(snapshot.lunarContext.isWaxing == false,
                    "Degrees \(degrees) should be waning")
        }
    }

    // MARK: T2.11

    @Test("Full moon boosts action and visibility vs new moon")
    func testFullMoonBoostsActionAndVisibility() {
        let chart = SnapshotFixtures.leoChart()
        let transits = SnapshotFixtures.mixedTransits()

        let fullMoon = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart, transits: transits,
            moonPhaseDegrees: 180.0, profileHash: SnapshotFixtures.profileHash,
            date: SnapshotFixtures.fixedDate
        )
        let newMoon = DailyEnergyEngine.generateSnapshot(
            natalChart: chart, progressedChart: chart, transits: transits,
            moonPhaseDegrees: 0.0, profileHash: SnapshotFixtures.profileHash,
            date: SnapshotFixtures.fixedDate
        )

        #expect(fullMoon.axes.action > newMoon.axes.action,
                "Full moon action \(fullMoon.axes.action) should exceed new moon \(newMoon.axes.action)")
        #expect(fullMoon.axes.visibility > newMoon.axes.visibility,
                "Full moon visibility \(fullMoon.axes.visibility) should exceed new moon \(newMoon.axes.visibility)")
    }

    // MARK: T2.12

    @Test("Daily seed matches DailySeedGenerator and profileHash passes through")
    func testDailySeedMatchesDailySeedGenerator() {
        let snapshot = SnapshotFixtures.defaultSnapshot()
        let expectedSeed = DailySeedGenerator.generateDailySeed(
            profileHash: SnapshotFixtures.profileHash,
            for: SnapshotFixtures.fixedDate
        )
        #expect(snapshot.dailySeed == expectedSeed)
        #expect(snapshot.profileHash == SnapshotFixtures.profileHash)
    }

    // MARK: T2.13

    @Test("Empty transits produce valid snapshot")
    func testEmptyTransitsProducesValidSnapshot() {
        let snapshot = SnapshotFixtures.defaultSnapshot(transits: [])
        #expect(snapshot.vibeProfile.isValid)
        #expect(snapshot.dominantTransits.isEmpty)
        #expect(snapshot.axes.action >= 1.0 && snapshot.axes.action <= 10.0)
        #expect(snapshot.axes.tempo >= 1.0 && snapshot.axes.tempo <= 10.0)
        #expect(snapshot.axes.strategy >= 1.0 && snapshot.axes.strategy <= 10.0)
        #expect(snapshot.axes.visibility >= 1.0 && snapshot.axes.visibility <= 10.0)
        #expect(!snapshot.lunarContext.phaseName.isEmpty)
        #expect(snapshot.dailySeed != 0)
        #expect(snapshot.profileHash == SnapshotFixtures.profileHash)
    }

    // MARK: T2.14

    @Test("Snapshot Codable round-trip preserves all fields")
    func testSnapshotCodableRoundTrip() throws {
        let original = SnapshotFixtures.defaultSnapshot()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyEnergySnapshot.self, from: data)

        #expect(original.vibeProfile.classic == decoded.vibeProfile.classic)
        #expect(original.vibeProfile.playful == decoded.vibeProfile.playful)
        #expect(original.vibeProfile.romantic == decoded.vibeProfile.romantic)
        #expect(original.vibeProfile.utility == decoded.vibeProfile.utility)
        #expect(original.vibeProfile.drama == decoded.vibeProfile.drama)
        #expect(original.vibeProfile.edge == decoded.vibeProfile.edge)

        #expect(original.axes.action == decoded.axes.action)
        #expect(original.axes.tempo == decoded.axes.tempo)
        #expect(original.axes.strategy == decoded.axes.strategy)
        #expect(original.axes.visibility == decoded.axes.visibility)

        #expect(original.dominantTransits == decoded.dominantTransits)
        #expect(original.lunarContext == decoded.lunarContext)

        #expect(original.dailySeed == decoded.dailySeed)
        #expect(original.profileHash == decoded.profileHash)
        #expect(original.generatedAt == decoded.generatedAt)
    }
}
