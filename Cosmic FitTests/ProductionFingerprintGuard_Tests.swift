//
//  ProductionFingerprintGuard_Tests.swift
//  Cosmic FitTests
//
//  Ensures production pipeline output remains bit-identical when narrativeIntent == nil.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("ProductionFingerprintGuard")
struct ProductionFingerprintGuard_Tests {

    /// Captured at baseline 47b73b5508d7ea056502a27036acbd560f96a60f (2026-05-23) before Phase B.
    static let expectedProductionFingerprint = "classic=3;playful=5;romantic=3;utility=2;drama=5;edge=3|9.331550665012362,7.28915832623337,4.37105210124435,8.945773984030346|maximalist,magnetic,eclectic|#FF7F50,#8E4585,#DE5D83|0.8|0.9078309593612138|0.6799999999999999|1.0"

    @Test("Ash profile day 0 production fingerprint matches baseline")
    func ashProfileDay0Fingerprint() {
        let fingerprint = captureAshProductionFingerprint()
        #expect(fingerprint == Self.expectedProductionFingerprint,
                "Production fingerprint drifted. Expected: \(Self.expectedProductionFingerprint), got: \(fingerprint)")
    }

    @Test("Production pipeline is deterministic")
    func productionDeterministic() {
        let a = captureAshProductionFingerprint()
        let b = captureAshProductionFingerprint()
        #expect(a == b)
    }

    private func captureAshProductionFingerprint() -> String {
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
