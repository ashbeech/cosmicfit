//
//  LunarEventDetector.swift
//  Cosmic Fit
//
//  Sky Forward v1.0.2 (audit F2, plan Phase 5).
//
//  Date-keyed detector for first-class named lunar events — eclipses, supermoons,
//  micromoons, and plain full/new moons — computed from the actual date's ephemeris
//  (NOT the swept elongation used by the vibe path). This is the second half of the
//  F2 fix (D2): near a syzygy the detector's result OVERRIDES the 6°-bucket phase name
//  (`MoonPhaseInterpreter.Phase.fromDegrees`), so a true full moon is always labelled
//  "Full Moon" instead of "Waning Gibbous". Pure function of the date — deterministic.
//

import Foundation

/// A first-class named lunar event for a given date, with a 0–1 strength scalar.
enum LunarEvent: Equatable {
    case solarEclipse(strength: Double)
    case lunarEclipse(strength: Double)
    case supermoon(strength: Double)
    case micromoon(strength: Double)
    case fullMoon(strength: Double)
    case newMoon(strength: Double)

    /// 0–1 significance scalar (1 = exact/total).
    var strength: Double {
        switch self {
        case .solarEclipse(let s), .lunarEclipse(let s),
             .supermoon(let s), .micromoon(let s),
             .fullMoon(let s), .newMoon(let s):
            return s
        }
    }

    /// Full-moon family: full moon, lunar eclipse, supermoon, micromoon — i.e. the moon is at
    /// (or within the syzygy window of) opposition. Used by the full-moon-labelling fidelity gate.
    var isFullMoonFamily: Bool {
        switch self {
        case .lunarEclipse, .supermoon, .micromoon, .fullMoon: return true
        case .solarEclipse, .newMoon: return false
        }
    }

    /// New-moon family: new moon, solar eclipse.
    var isNewMoonFamily: Bool { !isFullMoonFamily }

    /// Base phase label the event asserts for the user-facing phase name (D2 override):
    /// every full-family event reads "Full Moon"; every new-family event reads "New Moon".
    var phaseLabel: String { isFullMoonFamily ? "Full Moon" : "New Moon" }

    /// Specific named-event label for narrative / accent surfacing.
    var eventLabel: String {
        switch self {
        case .solarEclipse: return "Solar Eclipse"
        case .lunarEclipse: return "Lunar Eclipse"
        case .supermoon:    return "Supermoon"
        case .micromoon:    return "Micromoon"
        case .fullMoon:     return "Full Moon"
        case .newMoon:      return "New Moon"
        }
    }

    /// True for the rarer named events (eclipse / super / micro) that warrant accent surfacing
    /// beyond the plain phase label.
    var isSpecialEvent: Bool {
        switch self {
        case .solarEclipse, .lunarEclipse, .supermoon, .micromoon: return true
        case .fullMoon, .newMoon: return false
        }
    }
}

enum LunarEventDetector {

    // MARK: - Pinned thresholds (see docs/fixtures/lunar_events_2026.json almanac cross-check)

    /// Elongation window (degrees) around exact syzygy (180° full / 0°|360° new) within which a
    /// day counts as a full/new moon. ~7° ≈ 0.57 day of lunar motion (~12.2°/day), so a once-daily
    /// noon sample catches a syzygy occurring any time that day.
    static let syzygyWindowDeg = 7.0

    /// |Moon ecliptic latitude| (degrees) below which a syzygy is an eclipse (moon near a node).
    /// ~1.4° comfortably brackets umbral/partial eclipse limits for this analytic ephemeris.
    static let eclipseLatitudeDeg = 1.4

    /// Angular distance (degrees) of the Moon's longitude to the nearest lunar node, below which the
    /// syzygy is node-adjacent — a corroborating signal for eclipse classification.
    static let eclipseNodeProximityDeg = 18.0

    /// Full-moon distance (km) below which it is a supermoon; above which (at full) a micromoon.
    ///
    /// ⚑ OWNER-FLAGGED AMENDMENT (G0): the plan pinned `supermoonKm = 361_000`. Validated against
    /// the 2026 almanac, that value detects only 1 of the 3 commonly-cited 2026 supermoons — the
    /// other two (Jan 3, Nov 24) sit at ~363,150 km and ~361,596 km in this analytic ephemeris,
    /// just above 361,000. `363_300` catches exactly the three almanac supermoons (Jan 3 / Nov 24 /
    /// Dec 24) and cleanly excludes the next-closest full moon (Oct 26 at ~368,332 km, a 5,000 km gap),
    /// so the detector "matches the 2026 almanac" (DoD). This is a reasoned, evidence-based amendment of
    /// a Claude-default constant, pending product-owner sign-off.
    static let supermoonKm = 363_300.0
    static let micromoonKm = 404_500.0
    /// Perigee / apogee bounds of the 5-term distance series, for strength normalisation.
    static let perigeeKm = 356_500.0
    static let apogeeKm = 406_700.0

    // MARK: - Detection

    static func detect(date: Date) -> LunarEvent? {
        let jd = JulianDateCalculator.calculateJulianDate(from: date)
        return detect(julianDay: jd)
    }

    static func detect(julianDay: Double) -> LunarEvent? {
        let elongation = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay) // 0–360
        let fullProx = abs(elongation - 180.0)
        let newProx = min(elongation, 360.0 - elongation)
        let isFull = fullProx <= syzygyWindowDeg
        let isNew = newProx <= syzygyWindowDeg
        guard isFull || isNew else { return nil }

        let (moonLon, moonLat) = AstronomicalCalculator.calculateMoonPosition(julianDay: julianDay)
        let absLat = abs(moonLat)
        let nearNode = nodeProximity(moonLongitude: moonLon, julianDay: julianDay) <= eclipseNodeProximityDeg
        let isEclipse = absLat < eclipseLatitudeDeg && nearNode

        if isFull {
            let proxStrength = clamp01(1.0 - fullProx / syzygyWindowDeg)
            if isEclipse {
                return .lunarEclipse(strength: eclipseStrength(absLat: absLat))
            }
            let dist = AstronomicalCalculator.calculateMoonDistance(julianDay: julianDay)
            if dist < supermoonKm {
                return .supermoon(strength: distanceStrength(dist, from: supermoonKm, to: perigeeKm))
            }
            if dist > micromoonKm {
                return .micromoon(strength: distanceStrength(dist, from: micromoonKm, to: apogeeKm))
            }
            return .fullMoon(strength: proxStrength)
        } else {
            let proxStrength = clamp01(1.0 - newProx / syzygyWindowDeg)
            if isEclipse {
                return .solarEclipse(strength: eclipseStrength(absLat: absLat))
            }
            return .newMoon(strength: proxStrength)
        }
    }

    // MARK: - Helpers

    /// Smallest angular distance (0–180°) of the Moon's ecliptic longitude to the nearer lunar node.
    private static func nodeProximity(moonLongitude: Double, julianDay: Double) -> Double {
        let (north, south) = AstronomicalCalculator.calculateLunarNodes(julianDay: julianDay)
        return min(angularDistance(moonLongitude, north), angularDistance(moonLongitude, south))
    }

    private static func angularDistance(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360.0)
        return min(d, 360.0 - d)
    }

    /// Eclipse strength: 1 at zero latitude (central), 0 at the latitude threshold.
    private static func eclipseStrength(absLat: Double) -> Double {
        clamp01(1.0 - absLat / eclipseLatitudeDeg)
    }

    /// Distance strength: 0 at the `threshold` km, 1 at the `extreme` km (perigee or apogee).
    private static func distanceStrength(_ dist: Double, from threshold: Double, to extreme: Double) -> Double {
        guard threshold != extreme else { return 0 }
        return clamp01((dist - threshold) / (extreme - threshold))
    }

    private static func clamp01(_ x: Double) -> Double { min(1.0, max(0.0, x)) }
}
