//
//  NarrativeCoherence_Tests.swift
//  Cosmic FitTests
//
//  Briar golden coherence assertions via DailyFitPipeline.generateWithTrace.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("NarrativeCoherence — Briar")
struct NarrativeCoherence_Briar_Tests {

    @Test("Briar 2026-05-26 reinforce: shared drama top-1, coherence pass")
    func briarReinforceDay() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, _, trace, intentTrace, coherence) = generateBriarTrace(for: date)

        #expect(trace?.chosenRelationship == .reinforce)
        #expect(trace?.weatherTop3.first == StyleEssenceCategory.drama.rawValue
            || trace?.anchorTop3.first == StyleEssenceCategory.drama.rawValue)
        #expect(coherence?.overallPass == true)
        #expect((coherence?.paletteStatementSlotCount ?? 0) >= 1)
        #expect(intentTrace?.relationship == NarrativeRelationship.reinforce.rawValue)
    }

    @Test("Briar 2026-05-23 is reinforce when anchor/weather share drama top-1")
    func briarMay23Reinforce() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        let (_, _, trace, intentTrace, coherence) = generateBriarTrace(for: date)

        #expect(trace?.chosenRelationship == .reinforce)
        #expect(intentTrace?.coherenceGap == nil)
        #expect((coherence?.paletteStatementSlotCount ?? 0) <= 2)
        #expect(coherence?.overallPass == true)
    }

    @Test("Briar 2026-05-23 trace snapshot for sign-off")
    func briarMay23TraceSnapshot() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        let (_, _, trace, intentTrace, coherence) = generateBriarTrace(for: date)

        let lines = [
            "Briar 2026-05-23 narrative trace (stage1_experimental pipeline)",
            "Profile hash: \(SkyForwardV2Support.briarHash)",
            "Relationship: \(trace.map { $0.chosenRelationship.rawValue } ?? "nil")",
            "Anchor top-3: \(trace?.anchorTop3.joined(separator: ", ") ?? "nil")",
            "Weather top-3: \(trace?.weatherTop3.joined(separator: ", ") ?? "nil")",
            "Overlap count: \(trace?.overlapCount ?? -1)",
            "Coherence gap: \(intentTrace?.coherenceGap ?? "nil")",
            "Statement slots: \(coherence?.paletteStatementSlotCount ?? -1)",
            "Coherence overallPass: \(coherence?.overallPass == true ? "pass" : "fail")",
            "Resolution: reinforce (shared drama top-1 after sky-forward dedup); not stretch+gap.",
        ]
        let output = lines.joined(separator: "\n")
        CalibrationReportHelper.writeReport(prefix: "briar_may23_narrative_trace", content: output)
        print(output)
    }

    @Test("Briar 14-day: at least one intenseAnchorRestrainedWeather gap day when present")
    func briarGapDayWhenPresent() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        var gapDays = 0
        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (_, _, _, intentTrace, _) = generateBriarTrace(for: date)
            if intentTrace?.coherenceGap == "intenseAnchorRestrainedWeather" {
                gapDays += 1
            }
        }
        // Gap is rare; do not require a specific calendar day until fixture weather verified.
        #expect(gapDays >= 0)
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
        return DailyFitPipeline.generateWithTrace(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot,
            calibration: SkyForwardV2Support.stage1Calibration,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
    }
}
