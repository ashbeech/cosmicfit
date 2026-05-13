// Check that each required VSOP87D.xxx file is present and readable.
// If any are missing, downstream production-ephemeris tests should be skipped.

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("VSOP87 Bundle Integrity")
struct VSOP87BundleIntegrity_Tests {

    private static let requiredFiles = [
        "VSOP87D.mer", "VSOP87D.ven", "VSOP87D.ear", "VSOP87D.mar",
        "VSOP87D.jup", "VSOP87D.sat", "VSOP87D.ura", "VSOP87D.nep"
    ]

    @Test("All VSOP87D data files present in bundle")
    func testAllVSOP87FilesPresent() throws {
        let bundle = Bundle.main
        for filename in Self.requiredFiles {
            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            let path = bundle.path(forResource: name, ofType: ext, inDirectory: "VSOP87Data")
                ?? bundle.path(forResource: name, ofType: ext)
            #expect(path != nil, "Missing VSOP87 data file: \(filename)")
            if let p = path {
                let data = FileManager.default.contents(atPath: p)
                #expect(data != nil && !(data?.isEmpty ?? true), "VSOP87 data file is empty: \(filename)")
            }
        }
    }

    @Test("VSOP87Parser can compute Earth position for J2000")
    func testParserBasicComputation() throws {
        let coords = VSOP87Parser.calculateHeliocentricCoordinates(planet: .earth, julianDay: 2451545.0)
        let lonDeg = coords.longitude * 180.0 / .pi
        // Earth longitude at J2000 should be ~100° (~1.75 rad). Parser returns radians.
        // Fallback Keplerian gives the same approximate value.
        #expect(lonDeg > 50 && lonDeg < 200,
                "Earth longitude at J2000 (\(String(format: "%.1f", lonDeg))°) seems unreasonable")
        #expect(coords.radius > 0.5 && coords.radius < 1.5,
                "Earth radius at J2000 (\(coords.radius) AU) seems unreasonable")
    }
}

private class BundleToken {}
