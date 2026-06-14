//
//  DailyFitPipeline.swift
//  Cosmic Fit
//
//  Sole assembly point for DailyFitPayload. All consumers (app, inspector, diagnostics, tests) go through this.
//

import Foundation

enum DailyFitPipeline {

    /// Generate a complete payload. Stage1 routes through DailyNarrativePlan (Plan 2).
    static func generate(
        blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        dailyFitEngineId engineId: String? = nil
    ) -> DailyFitPayload {
        let mode = DailyFitEngineRegistry.resolvedMode(engineId: engineId)

        if mode == .stage1Experimental {
            let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
            let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                from: blueprint, snapshot: snapshot, calibration: calibration, mode: mode
            )
            let (plan, _) = DailyNarrativeSelector.select(
                snapshot: snapshot,
                blueprint: blueprint,
                calibration: calibration,
                precomputedEssence: rawEssence,
                precomputedSilhouette: rawSilhouette,
                dailyFitEngineId: engineId
            )
            return BlueprintLensEngine.generatePayloadFromPlan(
                plan: plan,
                blueprint: blueprint,
                snapshot: snapshot,
                calibration: calibration,
                mode: mode,
                dailyFitEngineId: engineId
            )
        } else {
            // Production path — completely unchanged
            let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
            let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                from: blueprint, snapshot: snapshot, calibration: calibration, mode: mode
            )
            return BlueprintLensEngine.generatePayload(
                blueprint: blueprint,
                snapshot: snapshot,
                calibration: calibration,
                mode: mode,
                dailyFitEngineId: engineId,
                precomputedEssence: rawEssence,
                precomputedSilhouette: silhouette,
                narrativeIntent: nil
            )
        }
    }

    /// Generate payload + Stage 2 trace, with narrative trace for diagnostics.
    /// Stage1 routes through DailyNarrativePlan; legacy traces still generated for comparison.
    static func generateWithTrace(
        blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        dailyFitEngineId engineId: String? = nil
    ) -> (
        payload: DailyFitPayload,
        trace: BlueprintLensEngine.PayloadTrace,
        narrativeTrace: NarrativeTrace?,
        narrativeIntentTrace: NarrativeIntentTrace?,
        narrativeCoherenceTrace: NarrativeCoherenceTrace?,
        essenceConflictTrace: EssenceConflictTrace?
    ) {
        let mode = DailyFitEngineRegistry.resolvedMode(engineId: engineId)
        let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: mode
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default

        if mode == .stage1Experimental {
            let (plan, _) = DailyNarrativeSelector.select(
                snapshot: snapshot,
                blueprint: blueprint,
                calibration: calibration,
                precomputedEssence: rawEssence,
                precomputedSilhouette: silhouette,
                dailyFitEngineId: engineId
            )

            // Use plan-driven intent for trace compatibility
            let planIntent = NarrativeIntent(
                relationship: plan.relationship,
                anchorTop3: plan.anchorEssences,
                weatherTop3: [plan.accentEssence] + plan.supportingEssences,
                tarot: plan.tarotDirective,
                palette: plan.paletteDirective,
                scales: plan.scaleDirective ?? ScaleDirective(
                    vibrancyCap: nil, contrastCap: nil,
                    pullTowardBaseline: false, baselineBlend: 0.0
                ),
                essencePresentation: EssencePresentationDirective(showAnchorGhost: true),
                themeLexiconKey: nil,
                coherenceGap: nil
            )

            // Generate payload through the same plan-driven path as generate().
            // Reuse its tarot result for trace generation so Inspector diagnostics
            // do not perform a second stateful tarot selection for the same day.
            let planPayload = BlueprintLensEngine.generatePayloadFromPlanWithTarotResult(
                plan: plan,
                blueprint: blueprint,
                snapshot: snapshot,
                calibration: calibration,
                mode: mode,
                dailyFitEngineId: engineId
            )
            let payload = planPayload.payload

            // Generate legacy trace for diagnostics (slider values may differ but trace structure is preserved)
            let (_, s2Trace) = BlueprintLensEngine.generatePayloadWithTrace(
                blueprint: blueprint,
                snapshot: snapshot,
                calibration: calibration,
                mode: mode,
                dailyFitEngineId: engineId,
                precomputedEssence: rawEssence,
                precomputedSilhouette: silhouette,
                narrativeIntent: planIntent,
                preselectedTarotResult: planPayload.tarotResult,
                recordTarotSelection: false
            )

            // Build legacy-compatible trace from the plan
            let narrativeTrace = NarrativeTrace(
                anchorTop3: plan.anchorEssences.map(\.rawValue),
                weatherTop3: ([plan.accentEssence] + plan.supportingEssences).map(\.rawValue),
                overlapCount: Set(plan.anchorEssences).intersection(Set([plan.accentEssence] + plan.supportingEssences)).count,
                silhouetteDeltaMF: silhouette.chartAnchorMF.map { silhouette.masculineFeminine - $0 },
                silhouetteDeltaAR: silhouette.chartAnchorAR.map { silhouette.angularRounded - $0 },
                silhouetteDeltaSD: silhouette.chartAnchorSD.map { silhouette.structuredDraped - $0 },
                chosenRelationship: plan.relationship,
                templateKey: "\(plan.relationship.rawValue).\(plan.accentEssence.rawValue)"
            )

            let intentTrace = NarrativeIntentTrace(
                relationship: plan.relationship.rawValue,
                anchorTop3: plan.anchorEssences.map(\.rawValue),
                weatherTop3: ([plan.accentEssence] + plan.supportingEssences).map(\.rawValue),
                accentCategory: plan.accentEssence.rawValue,
                foundationCategory: plan.paletteDirective.foundationCategory.rawValue,
                overlapCount: Set(plan.anchorEssences).intersection(Set([plan.accentEssence] + plan.supportingEssences)).count,
                themeLexiconKey: nil,
                coherenceGap: nil
            )

            let coherence = NarrativeSelectionDirectives.computeCoherenceTrace(
                payload: payload,
                intent: planIntent,
                tuning: tuning,
                tarotVariantWasScored: s2Trace.tarotVariantWasScored,
                tarotCategoryBoostApplied: s2Trace.tarotCategoryBoostApplied,
                statementSlotCount: s2Trace.paletteStatementSlotCount,
                bridgeTrace: s2Trace.narrativeBridgeTrace
            )

            return (payload, s2Trace, narrativeTrace, intentTrace, coherence, nil)
        }

        // Production path — completely unchanged
        let (payload, s2Trace) = BlueprintLensEngine.generatePayloadWithTrace(
            blueprint: blueprint,
            snapshot: snapshot,
            calibration: calibration,
            mode: mode,
            dailyFitEngineId: engineId,
            precomputedEssence: rawEssence,
            precomputedSilhouette: silhouette,
            narrativeIntent: nil
        )

        return (payload, s2Trace, nil, nil, nil, nil)
    }
}
