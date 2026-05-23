//
//  DailyFitPipeline.swift
//  Cosmic Fit
//
//  Sole assembly point for DailyFitPayload. All consumers (app, inspector, diagnostics, tests) go through this.
//

import Foundation

enum DailyFitPipeline {

    /// Generate a complete payload. Narrative intent biases Stage-1 selection only; no user-facing copy.
    static func generate(
        blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        dailyFitEngineId engineId: String? = nil
    ) -> DailyFitPayload {
        let mode = DailyFitEngineRegistry.resolvedMode(engineId: engineId)
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: mode
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let narrativeResolution = mode == .stage1Experimental
            ? NarrativeIntentEngine.resolve(
                essence: essence,
                snapshot: snapshot,
                mode: mode,
                silhouetteProfile: silhouette,
                tuning: tuning
            )
            : nil
        return BlueprintLensEngine.generatePayload(
            blueprint: blueprint,
            snapshot: snapshot,
            calibration: calibration,
            mode: mode,
            dailyFitEngineId: engineId,
            precomputedEssence: essence,
            precomputedSilhouette: silhouette,
            narrativeIntent: narrativeResolution?.intent
        )
    }

    /// Generate payload + Stage 2 trace, with narrative trace for diagnostics.
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
        narrativeCoherenceTrace: NarrativeCoherenceTrace?
    ) {
        let mode = DailyFitEngineRegistry.resolvedMode(engineId: engineId)
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: mode)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: mode
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let narrativeResolution = mode == .stage1Experimental
            ? NarrativeIntentEngine.resolve(
                essence: essence,
                snapshot: snapshot,
                mode: mode,
                silhouetteProfile: silhouette,
                tuning: tuning
            )
            : nil

        let (payload, s2Trace) = BlueprintLensEngine.generatePayloadWithTrace(
            blueprint: blueprint,
            snapshot: snapshot,
            calibration: calibration,
            mode: mode,
            dailyFitEngineId: engineId,
            precomputedEssence: essence,
            precomputedSilhouette: silhouette,
            narrativeIntent: narrativeResolution?.intent
        )

        guard let resolution = narrativeResolution else {
            return (payload, s2Trace, nil, nil, nil)
        }

        let coherence = NarrativeSelectionDirectives.computeCoherenceTrace(
            payload: payload,
            intent: resolution.intent,
            tuning: tuning,
            tarotVariantWasScored: s2Trace.tarotVariantWasScored,
            tarotCategoryBoostApplied: s2Trace.tarotCategoryBoostApplied,
            statementSlotCount: s2Trace.paletteStatementSlotCount
        )

        return (
            payload,
            s2Trace,
            resolution.trace,
            NarrativeSelectionDirectives.narrativeIntentTrace(from: resolution.intent, trace: resolution.trace),
            coherence
        )
    }
}
