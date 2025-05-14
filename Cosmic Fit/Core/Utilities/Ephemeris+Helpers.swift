//
//  Ephemeris+Helpers.swift.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 07/05/2025.
//

import Foundation
import CSwissEphemeris

// MARK: – Calendar ↔ JD helpers
extension Date {
    /// Astronomical Julian Day (UT) – the “JD” Swiss Ephemeris expects.
    var julianDayUT: Double {
        // 1) Calendar + guaranteed‑non‑nil UTC zone  -------------------------
        let cal = Calendar(identifier: .gregorian)
        let utc = TimeZone(secondsFromGMT: 0)!          // ← unwrap once, safe
        
        // 2) Break the long expression into smaller pieces  ------------------
        let c = cal.dateComponents(in: utc, from: self)
        
        // Fractional hours  (Swift gets slow if you chain them on one line)
        let hourFrac =
        Double(c.hour   ?? 0)
        + Double(c.minute ?? 0) / 60
        + Double(c.second ?? 0) / 3600
        
        // 3) Call the C function – all optionals unwrapped, compiler is fast --
        return swe_julday(
            Int32(c.year!),  Int32(c.month!), Int32(c.day!),
            hourFrac,
            Int32(SE_GREG_CAL)
        )
    }
}

/// A geocentric ecliptic position with distance in AU.
struct BodyPosition {
    let body: String             // “Ceres”, …
    let jdUT: Double
    let lonDeg: Double           // λ, true ecliptic & equinox of date
    let latDeg: Double           // β
    let distAU: Double
}

// MARK: – High‑level query
enum Ephemeris {
    /// Supported asteroid IDs in the C API
    private static let ids: [(String, Int32)] = [
        ("Ceres",  SE_CERES),
        ("Pallas", SE_PALLAS),
        ("Juno",   SE_JUNO),
        ("Vesta",  SE_VESTA)
    ]
    
    /// Return the four big‑asteroid positions for an arbitrary date.
    static func bigFour(on date: Date, flags: Int32 = SEFLG_SWIEPH) -> [BodyPosition] {
        let jd = date.julianDayUT
        var out = [BodyPosition]()
        var xx = [Double](repeating: 0, count: 6)
        var serr = [CChar](repeating: 0, count: 256)
        
        for (label, ip) in ids {
            swe_calc_ut(jd, ip, flags, &xx, &serr)
            out.append(BodyPosition(body: label,
                                    jdUT: jd,
                                    lonDeg: xx[0],
                                    latDeg: xx[1],
                                    distAU: xx[2]))
        }
        return out
    }
}
