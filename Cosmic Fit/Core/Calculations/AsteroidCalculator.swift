//  AsteroidCalculator.swift
//  Cosmic Fit
//
//  A thin Swift wrapper around Swiss Ephemeris that delivers geocentric
//  ecliptic positions (λ, β, r) for the six main asteroids used in modern
//  astrology: Ceres, Pallas, Juno, Vesta, Chiron and Pholus.
//  ----------------------------------------------------------------------
//  Requires:
//    • SwissEphemerisBootstrap.initialise() to have run once at app launch
//      ***OR*** call AsteroidCalculator.bootstrap() before the first query.
//    • seas_18.se1 (and optionally seas_24.se1, …) inside the main bundle.
//  ----------------------------------------------------------------------
//  Created by ChatGPT‑o3 on 07 May 2025.

import Foundation
import CSwissEphemeris   // raw C symbols (swe_calc_ut, SE_* ids, flags)

/// Swiss‑Ephem powered asteroid utility.
/// Every function is *thread‑safe* thanks to the internal serial queue ‑‑
/// Swiss Ephemeris’ C core is not re‑entrant.
enum AsteroidCalculator {

    // MARK: – Public types ------------------------------------------------

    struct Position {
        /// Ecliptic longitude (true, equinox‑of‑date) in **degrees 0‑360**.
        let longitude: Double
        /// Ecliptic latitude in **degrees**.
        let latitude: Double
        /// Earth‑asteroid distance in **astronomical units**.
        let distanceAU: Double
    }

    enum Asteroid: CaseIterable {
        case ceres, pallas, juno, vesta, chiron, pholus

        // Swiss Ephemeris integer IDs ------------------------------------
        var seId: Int32 {
            switch self {
            case .ceres:  return SE_CERES
            case .pallas: return SE_PALLAS
            case .juno:   return SE_JUNO
            case .vesta:  return SE_VESTA
            case .chiron: return SE_CHIRON   // minor planet 2060
            case .pholus: return SE_PHOLUS   // minor planet 5145
            }
        }

        /// Unicode symbols recommended by contemporary astrology fonts.
        var symbol: String {
            switch self {
            case .ceres:  return "⚳"
            case .pallas: return "⚴"
            case .juno:   return "⚵"
            case .vesta:  return "⚶"
            case .chiron: return "⚷"
            case .pholus: return "⚸"
            }
        }

        var displayName: String {
            switch self {
            case .ceres:  return "Ceres"
            case .pallas: return "Pallas"
            case .juno:   return "Juno"
            case .vesta:  return "Vesta"
            case .chiron: return "Chiron"
            case .pholus: return "Pholus"
            }
        }
    }

    // MARK: – Public API --------------------------------------------------

    /// Make sure Swiss Ephemeris has its ephemeris path set.
    /// You can call this manually if your app does not already invoke
    /// `SwissEphemerisBootstrap.initialise()` at launch.
    static func bootstrap() {
        SwissEphemerisBootstrap.initialise()
    }

    /// Geocentric position of one asteroid at the given Julian Day (UT).
    static func position(of asteroid: Asteroid, at julianDayUT: Double) -> Position {
        queryQueue.sync {
            var xx   = [Double](repeating: 0, count: 6) // output array
            var serr = [CChar](repeating: 0, count: 256)

            let iflag: Int32 = SEFLG_SWIEPH            // Swiss ephemeris, true ecliptic
            swe_calc_ut(julianDayUT, asteroid.seId, iflag, &xx, &serr)

            return Position(longitude: xx[0], latitude: xx[1], distanceAU: xx[2])
        }
    }

    /// Convenience: true if the asteroid is **retrograde** on the given day.
    ///
    /// Algorithm: compare longitudes one day apart; account for 360° wrap.
    static func isRetrograde(_ asteroid: Asteroid, at julianDayUT: Double) -> Bool {
        let lon1 = position(of: asteroid, at: julianDayUT).longitude
        let lon2 = position(of: asteroid, at: julianDayUT + 1.0).longitude
        var delta = lon2 - lon1
        if delta > 180 { delta -= 360 } else if delta < -180 { delta += 360 }
        return delta < 0
    }

    /// Batch query – returns a dictionary keyed by Asteroid.
    static func positions(of asteroids: [Asteroid] = Asteroid.allCases,
                          at julianDayUT: Double) -> [Asteroid: Position] {
        var dict: [Asteroid: Position] = [:]
        for a in asteroids { dict[a] = position(of: a, at: julianDayUT) }
        return dict
    }

    // MARK: – Implementation details -------------------------------------

    /// Serial queue guarding calls into the non‑re‑entrant C core.
    private static let queryQueue = DispatchQueue(label: "AsteroidCalculator.SEQueue")
}
