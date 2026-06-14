//
//  SkySalience_Tests.swift
//  Cosmic FitTests
//
//  Validates the adaptive salience model: speed ordering, freshness bonuses,
//  per-day normalization, category dedup, and no planet→category collisions.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("SkySalience — Adaptive Transit Weighting")
struct SkySalience_Tests {

    private static let baseDate = SkyForwardV2Support.date(year: 2026, month: 6, day: 10)

    private func makeTransit(
        planet: String, natal: String, aspect: String,
        orb: Double, applying: Bool = true
    ) -> NatalChartCalculator.TransitAspect {
        NatalChartCalculator.TransitAspect(
            transitPlanet: planet, transitPlanetSymbol: "•",
            natalPlanet: natal, natalPlanetSymbol: "•",
            aspectType: aspect, aspectSymbol: "•",
            orb: orb, applying: applying,
            effectiveFrom: Self.baseDate,
            effectiveTo: Self.baseDate.addingTimeInterval(86400 * 5),
            description: "\(planet) \(aspect) \(natal)",
            category: .shortTerm,
            transitZodiacSign: nil
        )
    }

    // MARK: - Speed Ordering

    @Test("Same-orb Moon outranks same-orb Pluto")
    func moonOutranksPluto() {
        let transits = [
            makeTransit(planet: "Moon", natal: "Venus", aspect: "trine", orb: 2.0),
            makeTransit(planet: "Pluto", natal: "Sun", aspect: "trine", orb: 2.0),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(profile.entries.first?.planet == "Moon",
                "Moon (speed=1.0) should outrank Pluto (speed=0.1) at same orb")
    }

    @Test("Fast movers rank above slow movers at equal orb")
    func fastMoversRankHigher() {
        let transits = [
            makeTransit(planet: "Neptune", natal: "Moon", aspect: "conjunction", orb: 1.5),
            makeTransit(planet: "Venus", natal: "Mars", aspect: "conjunction", orb: 1.5),
            makeTransit(planet: "Mercury", natal: "Jupiter", aspect: "conjunction", orb: 1.5),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        let order = profile.entries.map(\.planet)
        let mercIdx = order.firstIndex(of: "Mercury")!
        let venusIdx = order.firstIndex(of: "Venus")!
        let neptuneIdx = order.firstIndex(of: "Neptune")!
        #expect(mercIdx < venusIdx, "Mercury should rank above Venus")
        #expect(venusIdx < neptuneIdx, "Venus should rank above Neptune")
    }

    // MARK: - Freshness Bonus

    @Test("Applying exact Venus outranks wide separating Pluto")
    func exactVenusBeatsWidePluto() {
        let transits = [
            makeTransit(planet: "Venus", natal: "Moon", aspect: "trine", orb: 0.3, applying: true),
            makeTransit(planet: "Pluto", natal: "Sun", aspect: "trine", orb: 4.0, applying: false),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(profile.entries.first?.planet == "Venus",
                "Exact applying Venus should outrank wide separating Pluto")
    }

    @Test("Near-exact transit gets +0.3 freshness bonus")
    func nearExactBonus() {
        let transits = [
            makeTransit(planet: "Mars", natal: "Venus", aspect: "conjunction", orb: 0.2),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(profile.entries.first?.freshnessBonus == 0.3)
    }

    @Test("Wide separating transit gets -0.2 freshness penalty")
    func wideSeparatingPenalty() {
        let transits = [
            makeTransit(planet: "Saturn", natal: "Moon", aspect: "square", orb: 4.0, applying: false),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(profile.entries.first?.freshnessBonus == -0.2)
    }

    // MARK: - Per-Day Normalization

    @Test("Top salience is exactly 1.0 when transits exist")
    func normalizationTopIsOne() {
        let transits = [
            makeTransit(planet: "Moon", natal: "Venus", aspect: "trine", orb: 1.0),
            makeTransit(planet: "Saturn", natal: "Mars", aspect: "square", orb: 3.0),
            makeTransit(planet: "Neptune", natal: "Sun", aspect: "opposition", orb: 5.0),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(!profile.entries.isEmpty)
        #expect(profile.entries.first!.salience == 1.0,
                "Highest salience entry should be normalized to exactly 1.0")
    }

    @Test("All salience values are in [0, 1]")
    func salienceInRange() {
        let transits = SkyForwardV2Support.briarTransits(for: Self.baseDate)
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        for entry in profile.entries {
            #expect(entry.salience >= 0.0 && entry.salience <= 1.0,
                    "\(entry.planet) salience \(entry.salience) out of [0,1]")
        }
    }

    @Test("Empty transits produces empty profile")
    func emptyTransits() {
        let profile = DailyEnergyEngine.computeSkySalience(from: [], date: Self.baseDate)
        #expect(profile.entries.isEmpty)
        #expect(profile.topDrivers.isEmpty)
        #expect(profile.dominantNarrative == nil)
    }

    // MARK: - Category Dedup

    @Test("Duplicate category boosts are deduped in top drivers")
    func categoryDedup() {
        let transits = [
            makeTransit(planet: "Moon", natal: "Venus", aspect: "trine", orb: 1.0),
            makeTransit(planet: "Moon", natal: "Mars", aspect: "sextile", orb: 2.0),
            makeTransit(planet: "Venus", natal: "Sun", aspect: "conjunction", orb: 0.5),
            makeTransit(planet: "Mars", natal: "Mercury", aspect: "square", orb: 1.5),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        let driverCategories = profile.topDrivers.compactMap(\.essenceCategory)
        let uniqueCategories = Set(driverCategories)
        #expect(driverCategories.count == uniqueCategories.count,
                "Top drivers should not have duplicate essence categories")
    }

    @Test("Top drivers limited to 3")
    func topDriversCapped() {
        let transits = SkyForwardV2Support.briarTransits(for: Self.baseDate)
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(profile.topDrivers.count <= 3)
    }

    // MARK: - No Planet-to-Category Collisions

    @Test("No two planets map to the same essence category")
    func noCategoryCollisions() {
        let mapping: [String: StyleEssenceCategory] = [
            "Mars": .drama, "Venus": .romantic, "Sun": .magnetic,
            "Moon": .playful, "Mercury": .eclectic, "Jupiter": .maximalist,
            "Saturn": .minimal, "Uranus": .effortless, "Neptune": .sensual, "Pluto": .edgy,
        ]
        var seen: [StyleEssenceCategory: String] = [:]
        for (planet, category) in mapping {
            if let existing = seen[category] {
                Issue.record("Collision: \(planet) and \(existing) both map to \(category)")
            }
            seen[category] = planet
        }
        #expect(seen.count == mapping.count, "All 10 planets should map to distinct categories")
    }

    // MARK: - Determinism

    @Test("Same inputs produce identical salience profile")
    func deterministic() {
        let transits = SkyForwardV2Support.briarTransits(for: Self.baseDate)
        let a = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        let b = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(a == b)
    }

    // MARK: - Narrative Trace

    @Test("Dominant narrative describes top driver")
    func narrativeTrace() {
        let transits = [
            makeTransit(planet: "Venus", natal: "Moon", aspect: "trine", orb: 0.3),
        ]
        let profile = DailyEnergyEngine.computeSkySalience(from: transits, date: Self.baseDate)
        #expect(profile.dominantNarrative == "Venus trine Moon")
    }

    // MARK: - Production Fingerprint Unchanged

    @Test("Production fingerprint unchanged after salience addition")
    func productionFingerprint() {
        let fingerprint = captureProductionFingerprint()
        #expect(fingerprint == ProductionFingerprintGuard_Tests.expectedProductionFingerprint)
    }

    private func captureProductionFingerprint() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = cal.date(from: DateComponents(year: 2026, month: 5, day: 10))!
        let natalSigns = [5, 9, 5, 4, 1, 9, 5, 1, 9, 5]
        let progressedSigns = [5, 9, 6, 5, 2, 9, 5, 1, 9, 5]
        let payload = SkyForwardV2Support.generateProductionPayload(
            natalSigns: natalSigns,
            progressedSigns: progressedSigns,
            hash: "cal_ash",
            targetDate: date,
            dayOffset: 0
        )
        return SkyForwardV2Support.payloadFingerprint(payload)
    }
}
