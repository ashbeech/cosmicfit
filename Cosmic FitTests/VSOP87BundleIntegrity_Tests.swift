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
        let bundle = Bundle(for: BundleToken.self)
        for filename in Self.requiredFiles {
            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            let path = bundle.path(forResource: name, ofType: ext, inDirectory: "VSOP87Data")
            #expect(path != nil, "Missing VSOP87 data file: \(filename)")
            if let p = path {
                let data = FileManager.default.contents(atPath: p)
                #expect(data != nil && !(data?.isEmpty ?? true), "VSOP87 data file is empty: \(filename)")
            }
        }
    }

    @Test("VSOP87Parser can compute Earth position for J2000")
    func testParserBasicComputation() throws {
        // J2000.0 = Julian day 2451545.0
        let coords = VSOP87Parser.calculateHeliocentricCoordinates(planet: .earth, julianDay: 2451545.0)
        // Earth longitude at J2000 should be ~100° (L0 term gives roughly that)
        #expect(coords.longitude > 50 && coords.longitude < 200,
                "Earth longitude at J2000 (\(coords.longitude)°) seems unreasonable")
    }
}

private class BundleToken {}
