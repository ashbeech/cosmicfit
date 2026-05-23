//
//  NarrativePaletteUnification_Tests.swift
//  Cosmic FitTests
//
//  Stage-1 palette slot + role rules via DailyFitPipeline.generateWithTrace (§7.1, §15.3).
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("NarrativePaletteUnification")
struct NarrativePaletteUnification_Tests {

    @Test("Briar reinforce 2026-05-26: ≤2 statement slots, accent role present")
    func briarReinforcePaletteSlots() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, trace, narrativeTrace, _, coherence) = generateBriarTrace(for: date)

        #expect(narrativeTrace?.chosenRelationship == .reinforce)
        #expect(trace.paletteStatementSlotCount <= 2)
        #expect(coherence?.paletteAccentRoleMatch == true)
        #expect(trace.paletteSelectionPath == "narrativeSlots")
    }

    @Test("Briar 2026-05-23 reinforce: ≤2 statement slots")
    func briarMay23PaletteSlots() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        let (_, trace, narrativeTrace, _, _) = generateBriarTrace(for: date)

        #expect(narrativeTrace?.chosenRelationship == .reinforce)
        #expect(trace.paletteStatementSlotCount <= 2)
        #expect(trace.narrativeBiasApplied == true)
    }

    @Test("Production Ash: no narrative palette bias")
    func productionNoNarrativePaletteBias() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 10)
        let payload = SkyForwardV2Support.generateProductionPayload(
            natalSigns: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5],
            progressedSigns: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5],
            hash: "cal_ash",
            targetDate: date,
            dayOffset: 0
        )
        let roles = Set(payload.dailyPalette.colours.map(\.role))
        #expect(!roles.isEmpty)
        // Production path uses dramaSlots / coreAnchored — never narrativeSlots.
        #expect(payload.dailyFitEngineId == DailyFitEngineRegistry.productionId
            || payload.resolvedDailyFitEngineId == DailyFitEngineRegistry.productionId)
    }

    private func generateBriarTrace(for date: Date) -> (
        DailyFitPayload,
        BlueprintLensEngine.PayloadTrace,
        NarrativeTrace?,
        NarrativeIntentTrace?,
        NarrativeCoherenceTrace?
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
        let (payload, s2Trace, narrativeTrace, intentTrace, coherence) = DailyFitPipeline.generateWithTrace(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot,
            calibration: SkyForwardV2Support.stage1Calibration,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        return (payload, s2Trace, narrativeTrace, intentTrace, coherence)
    }
}
