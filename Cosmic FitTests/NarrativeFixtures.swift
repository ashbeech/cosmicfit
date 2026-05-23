//
//  NarrativeFixtures.swift
//  Cosmic FitTests
//
//  Linden / Wren profiles — natal signs pending inspector verification (§15.1).
//

import Testing
import Foundation
@testable import Cosmic_Fit

enum NarrativeFixtures {

    static let wrenHash = "609730200.0_37.9855765_23.7283762"
    static let lindenHash = "1759731240.0_53.7439438_-0.3402508"

    /// Placeholder until verified via Inspector /api/inspect.
    static let wrenNatalSigns = [10, 2, 10, 10, 4, 10, 10, 4, 10, 10]
    static let wrenProgressedSigns = wrenNatalSigns

    static let lindenNatalSigns = [7, 1, 7, 10, 3, 7, 7, 3, 7, 7]
    static let lindenProgressedSigns = lindenNatalSigns

    static func date(year: Int, month: Int, day: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func generatePayload(
        natalSigns: [Int],
        progressedSigns: [Int],
        hash: String,
        date: Date,
        blueprint: CosmicBlueprint = SkyForwardV2Support.briarBlueprint
    ) -> DailyFitPayload {
        let natal = SkyForwardV2Support.chart(signs: natalSigns)
        let progressed = SkyForwardV2Support.chart(signs: progressedSigns)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: natal,
            progressedChart: progressed,
            transits: SkyForwardV2Support.briarTransits(for: date),
            moonPhaseDegrees: 120.0,
            profileHash: hash,
            date: date,
            calibration: SkyForwardV2Support.stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        return DailyFitPipeline.generate(
            blueprint: blueprint,
            snapshot: snapshot,
            calibration: SkyForwardV2Support.stage1Calibration,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
    }
}

@Suite("NarrativeFixtures — Linden/Wren")
struct NarrativeFixtures_Golden_Tests {

    @Test("Wren contrast window", .disabled("Awaiting inspector-derived natal signs"))
    func wrenContrast() {}

    @Test("Linden 14-day stretch window", .disabled("Awaiting inspector-derived natal signs"))
    func lindenStretchWindow() {}
}
