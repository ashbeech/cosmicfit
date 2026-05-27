//
//  NarrativeTarotUnification_Tests.swift
//  Cosmic FitTests
//
//  Stage-1 tarot category boost + variant scoring via pipeline (§7.1, §15.7).
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("NarrativeTarotUnification")
struct NarrativeTarotUnification_Tests {

    @Test("Stage-1 Briar: tarot variant scored (not rotation fallback)")
    func stage1VariantScored() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, trace, _, _, coherence, _) = generateBriarTrace(for: date)

        #expect(trace.tarotVariantWasScored == true)
        #expect(coherence?.tarotVariantScored == true)
    }

    @Test("Stage-1 Briar: narrative tarot category boost applied")
    func stage1CategoryBoostApplied() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, _, _, _, coherence, _) = generateBriarTrace(for: date)

        #expect(coherence?.tarotCategoryBoostApplied == true)
    }

    @Test("Production: variant rotation path (no narrative scoring)")
    func productionUsesRotation() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 10)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5]),
            progressedChart: SkyForwardV2Support.chart(signs: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5]),
            transits: [],
            moonPhaseDegrees: 60,
            profileHash: "cal_tarot_prod",
            date: date,
            calibration: DailyFitCalibration.default,
            mode: .standard,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        let (_, trace, narrativeTrace, _, coherence, _) = DailyFitPipeline.generateWithTrace(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot,
            calibration: DailyFitCalibration.default,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )

        #expect(narrativeTrace == nil)
        #expect(coherence == nil)
        #expect(trace.tarotVariantWasScored == false)
    }

    private func generateBriarTrace(for date: Date) -> (
        DailyFitPayload,
        BlueprintLensEngine.PayloadTrace,
        NarrativeTrace?,
        NarrativeIntentTrace?,
        NarrativeCoherenceTrace?,
        EssenceConflictTrace?
    ) {
        let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
            profileHash: SkyForwardV2Support.briarHash,
            date: date,
            calibration: SkyForwardV2Support.stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        return DailyFitPipeline.generateWithTrace(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot,
            calibration: SkyForwardV2Support.stage1Calibration,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
    }
}
