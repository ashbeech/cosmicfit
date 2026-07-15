//
//  LunarEventDetector_Tests.swift
//  InspectorEngineTests
//
//  Sky Forward v1.0.2 (Phase 5) — cross-checks the analytic-ephemeris LunarEventDetector
//  against the pinned 2026 almanac (docs/fixtures/lunar_events_2026.json). The detector is
//  judged against the almanac, never against itself. Bounds the analytic (non-Swiss) approximation.
//

import XCTest
@testable import CosmicFitInspectorLib

final class LunarEventDetector_Tests: XCTestCase {

    typealias S = CalibrationAuditSupport

    // MARK: - Fixture

    struct FullMoon: Decodable {
        let date: String
        let name: String
        let supermoon: Bool?
        let lunarEclipse: Bool?
        let micromoon: Bool?
    }
    struct Eclipse: Decodable { let date: String; let type: String; let kind: String }
    struct Almanac: Decodable {
        let fullMoons: [FullMoon]
        let eclipses: [Eclipse]
        let supermoons: [String]
        let micromoons: [String]
    }

    static func fixtureURL() -> URL {
        // <repo>/inspector/Tests/InspectorEngineTests/<thisFile> → up 4 → <repo>
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<4 { root.deleteLastPathComponent() }
        return root.appendingPathComponent("docs/fixtures/lunar_events_2026.json")
    }

    func loadAlmanac() throws -> Almanac {
        let data = try Data(contentsOf: Self.fixtureURL())
        return try JSONDecoder().decode(Almanac.self, from: data)
    }

    /// Noon-UTC instant for a "yyyy-MM-dd" date — the once-daily production sampling cadence.
    func noonUTC(_ ymd: String) -> Date {
        let parts = ymd.split(separator: "-").compactMap { Int($0) }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(
            year: parts[0], month: parts[1], day: parts[2], hour: 12))!
    }

    override func setUp() {
        super.setUp()
        S.bootstrapEphemeris()
    }

    // MARK: - Gate (b) basis: full-moon labelling ≥ 12/13

    func testFullMoonsAreLabelled() throws {
        let almanac = try loadAlmanac()
        var labelled = 0
        var misses: [String] = []
        for fm in almanac.fullMoons {
            if let ev = LunarEventDetector.detect(date: noonUTC(fm.date)), ev.isFullMoonFamily {
                labelled += 1
            } else {
                misses.append(fm.date)
            }
        }
        XCTAssertGreaterThanOrEqual(
            labelled, 12,
            "Only \(labelled)/\(almanac.fullMoons.count) 2026 full moons labelled; misses: \(misses)"
        )
    }

    // MARK: - Eclipses matched on date + type

    func testEclipsesMatchAlmanac() throws {
        let almanac = try loadAlmanac()
        for e in almanac.eclipses {
            let ev = LunarEventDetector.detect(date: noonUTC(e.date))
            switch (e.type, ev) {
            case ("solar", .some(.solarEclipse)):
                break
            case ("lunar", .some(.lunarEclipse)):
                break
            default:
                XCTFail("2026 \(e.kind) \(e.type) eclipse on \(e.date) not detected — got \(String(describing: ev))")
            }
        }
    }

    // MARK: - Supermoons detected (amended 363,300 km threshold — see fixture note)

    func testSupermoonsMatchAlmanac() throws {
        let almanac = try loadAlmanac()
        for date in almanac.supermoons {
            let ev = LunarEventDetector.detect(date: noonUTC(date))
            XCTAssertEqual(ev, .supermoon(strength: ev?.strength ?? -1),
                           "Expected supermoon on \(date), got \(String(describing: ev))")
        }
    }

    // MARK: - Micromoons detected (far full moons)

    func testMicromoonsDetected() throws {
        let almanac = try loadAlmanac()
        var hits = 0
        for date in almanac.micromoons {
            if case .micromoon = LunarEventDetector.detect(date: noonUTC(date)) { hits += 1 }
        }
        XCTAssertGreaterThanOrEqual(hits, almanac.micromoons.count - 1,
                                    "Micromoon detection below almanac (analytic-ephemeris tolerance)")
    }

    // MARK: - ≥5-term distance series actually reaches supermoon depths (B2)

    func testDistanceSeriesReachesSupermoonRange() {
        // The leading term alone floors at ~364,096 km. The full series must dip below the
        // 363,300 km supermoon threshold across a year — else the detector fires zero supermoons.
        var minDist = Double.greatestFiniteMagnitude
        var maxDist = 0.0
        let jd0 = JulianDateCalculator.calculateJulianDate(from: noonUTC("2026-01-01"))
        for day in 0..<365 {
            let d = AstronomicalCalculator.calculateMoonDistance(julianDay: jd0 + Double(day))
            minDist = min(minDist, d)
            maxDist = max(maxDist, d)
        }
        XCTAssertLessThan(minDist, LunarEventDetector.supermoonKm,
                          "Distance series never reaches supermoon depth — supermoons unsatisfiable")
        XCTAssertGreaterThan(maxDist, LunarEventDetector.micromoonKm,
                             "Distance series never reaches micromoon range")
    }
}
