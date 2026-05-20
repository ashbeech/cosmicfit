//
//  DailyFitDiagnostics.swift
//  Cosmic Fit
//
//  Phase 6: Structured diagnostic logger for the Daily Fit pipeline.
//  Captures a complete trace of one pipeline run as a Codable data object.
//  Used for calibration and debugging — NOT in the production path.
//

import Foundation

// MARK: - Diagnostic Report

/// Complete trace of a single Daily Fit pipeline run.
/// Codable for serialisation and comparison across runs.
struct DailyFitDiagnosticReport: Codable {
    let timestamp: Date
    let profileIdentifier: String

    // Stage 1 trace
    let sourceContributions: SourceContributionBreakdown
    let rawEnergyScores: [String: Double]
    let postMultiplierScores: [String: Double]
    let finalVibeBreakdown: VibeBreakdown
    let rawAxisScores: [String: Double]
    let finalAxes: DerivedAxes
    let transitSummaries: [DailyTransitSummary]
    let lunarContext: LunarContext
    let dailySeed: Int

    // Stage 2 trace
    let tarotCardScores: [TarotScoreEntry]
    let selectedTarotCard: String
    let variantRotationIndex: Int
    let selectedStyleEdit: String
    let paletteSelectionTrace: PaletteTrace
    let textureSelectionTrace: TextureTrace
    let patternDecision: PatternDecision

    // Style Guide–anchored scale traces (baselines from CosmicBlueprint.palette)
    let vibrancyTrace: ScaleDerivationTrace
    let contrastTrace: ScaleDerivationTrace
    let metalToneTrace: ScaleDerivationTrace
    let essenceProfile: StyleEssenceProfile
    let silhouetteTrace: SilhouetteDerivationTrace

    // Calibration used
    let calibrationSnapshot: CalibrationSummary
}

// MARK: - Nested Diagnostic Types

struct SourceContributionBreakdown: Codable {
    let natalShare: Double
    let transitShare: Double
    let lunarShare: Double
    let progressedShare: Double
    let currentSunShare: Double
}

struct TarotScoreEntry: Codable {
    let cardName: String
    let vibeScore: Double
    let axisScore: Double
    let transitBoost: Double
    let recencyPenalty: Double
    let totalScore: Double
}

struct ScaleDerivationTrace: Codable {
    let blueprintBaseline: Double
    let modulation: Double
    let finalValue: Double
}

struct SilhouetteDerivationTrace: Codable {
    let baselineMF: Double
    let baselineAR: Double
    let baselineSD: Double
    let finalMF: Double
    let finalAR: Double
    let finalSD: Double
}

struct ScoredColourEntry: Codable {
    let name: String
    let role: String
    let score: Double
}

struct ScoredTextureEntry: Codable {
    let name: String
    let score: Double
}

struct PaletteTrace: Codable {
    let candidateCount: Int
    let topScoredColours: [ScoredColourEntry]
    let selectedColours: [DailyColourPick]
    let diversitySwapApplied: Bool
}

struct TextureTrace: Codable {
    let availableTextures: [String]
    let scores: [ScoredTextureEntry]
    let selected: [String]
}

struct PatternDecision: Codable {
    let gateCheckPassed: Bool
    let visibilityValue: Double
    let dominantEnergy: String
    let selectedPattern: String?
}

struct CalibrationSummary: Codable {
    let sourceWeights: [String: Double]
    let selectionWeights: [String: Double]
    let axisTuning: [String: Double]
    let stage2Sensitivity: [String: Double]
    let dailyFitEngineId: String
    let fingerprint: String
}

// MARK: - Report Generator

/// Diagnostic entry point. Runs the full pipeline once and captures
/// intermediate values at each step via engine hooks.
enum DailyFitDiagnostics {

    static func generateReport(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        profileHash: String,
        blueprint: CosmicBlueprint,
        date: Date = Date(),
        calibration: DailyFitCalibration = .default,
        dailyFitEngineId: String? = nil
    ) -> (payload: DailyFitPayload, report: DailyFitDiagnosticReport) {

        // Stage 1: energy snapshot with trace
        let (snapshot, s1Trace) = DailyEnergyEngine.generateSnapshotWithTrace(
            natalChart: natalChart, progressedChart: progressedChart,
            transits: transits, moonPhaseDegrees: moonPhaseDegrees,
            profileHash: profileHash, date: date, calibration: calibration,
            dailyFitEngineId: dailyFitEngineId
        )

        // Stage 2: payload with trace
        let (payload, s2Trace) = BlueprintLensEngine.generatePayloadWithTrace(
            blueprint: blueprint, snapshot: snapshot, calibration: calibration,
            dailyFitEngineId: dailyFitEngineId
        )

        let contributions = SourceContributionBreakdown(
            natalShare: s1Trace.sourceContributions["natal"] ?? 0,
            transitShare: s1Trace.sourceContributions["transits"] ?? 0,
            lunarShare: s1Trace.sourceContributions["lunar"] ?? 0,
            progressedShare: s1Trace.sourceContributions["progressed"] ?? 0,
            currentSunShare: s1Trace.sourceContributions["currentSun"] ?? 0
        )

        let tarotEntries = s2Trace.tarotScores.map {
            TarotScoreEntry(
                cardName: $0.cardName, vibeScore: $0.vibeScore,
                axisScore: $0.axisScore, transitBoost: $0.transitBoost,
                recencyPenalty: $0.recencyPenalty, totalScore: $0.totalScore
            )
        }

        let paletteColours = s2Trace.paletteTrace.scoredColours
            .sorted(by: { $0.score > $1.score })
            .prefix(10)
            .map { ScoredColourEntry(name: $0.name, role: $0.role, score: $0.score) }
        let palTrace = PaletteTrace(
            candidateCount: s2Trace.paletteTrace.candidateCount,
            topScoredColours: Array(paletteColours),
            selectedColours: payload.dailyPalette.colours,
            diversitySwapApplied: s2Trace.paletteTrace.diversitySwapApplied
        )

        let texScores = s2Trace.textureTrace.scores
            .sorted(by: { $0.1 > $1.1 })
            .map { ScoredTextureEntry(name: $0.0, score: $0.1) }
        let texTrace = TextureTrace(
            availableTextures: s2Trace.textureTrace.available,
            scores: texScores,
            selected: payload.dailyTextures
        )

        let patDecision = PatternDecision(
            gateCheckPassed: s2Trace.patternTrace.gatePassed,
            visibilityValue: s2Trace.patternTrace.visibilityValue,
            dominantEnergy: s2Trace.patternTrace.dominantEnergy,
            selectedPattern: payload.dailyPattern
        )

        let calSnap = calibrationSummary(for: calibration, dailyFitEngineId: dailyFitEngineId)

        let report = DailyFitDiagnosticReport(
            timestamp: date,
            profileIdentifier: profileHash,
            sourceContributions: contributions,
            rawEnergyScores: s1Trace.rawScores,
            postMultiplierScores: s1Trace.postMultiplierScores,
            finalVibeBreakdown: snapshot.vibeProfile,
            rawAxisScores: s1Trace.rawAxisScores,
            finalAxes: snapshot.axes,
            transitSummaries: snapshot.dominantTransits,
            lunarContext: snapshot.lunarContext,
            dailySeed: snapshot.dailySeed,
            tarotCardScores: tarotEntries,
            selectedTarotCard: payload.tarotCard.name,
            variantRotationIndex: s2Trace.variantRotationIndex,
            selectedStyleEdit: payload.styleEditVariant.title,
            paletteSelectionTrace: palTrace,
            textureSelectionTrace: texTrace,
            patternDecision: patDecision,
            vibrancyTrace: ScaleDerivationTrace(
                blueprintBaseline: s2Trace.vibrancyBaseline,
                modulation: s2Trace.vibrancyModulation,
                finalValue: payload.vibrancy
            ),
            contrastTrace: ScaleDerivationTrace(
                blueprintBaseline: s2Trace.contrastBaseline,
                modulation: s2Trace.contrastModulation,
                finalValue: payload.contrast
            ),
            metalToneTrace: ScaleDerivationTrace(
                blueprintBaseline: s2Trace.metalToneBaseline,
                modulation: s2Trace.metalToneModulation,
                finalValue: payload.metalTone
            ),
            essenceProfile: payload.essenceProfile,
            silhouetteTrace: SilhouetteDerivationTrace(
                baselineMF: s2Trace.silhouetteBaselines.mf,
                baselineAR: s2Trace.silhouetteBaselines.ar,
                baselineSD: s2Trace.silhouetteBaselines.sd,
                finalMF: payload.silhouetteProfile.masculineFeminine,
                finalAR: payload.silhouetteProfile.angularRounded,
                finalSD: payload.silhouetteProfile.structuredDraped
            ),
            calibrationSnapshot: calSnap
        )

        return (payload, report)
    }

    static func calibrationSummary(
        for calibration: DailyFitCalibration,
        dailyFitEngineId explicitEngineId: String? = nil
    ) -> CalibrationSummary {
        let sw = calibration.sourceWeights
        let sel = calibration.selectionWeights
        let at = calibration.axisTuning
        let s2 = calibration.stage2Sensitivity
        let engineId: String
        if let explicitEngineId {
            engineId = explicitEngineId
        } else {
            var inferred = DailyFitEngineRegistry.productionId
            for descriptor in DailyFitEngineRegistry.allDescriptors {
                if descriptor.calibration == calibration {
                    inferred = descriptor.id
                    break
                }
            }
            engineId = inferred
        }
        let fingerprint = DailyFitEngineRegistry.descriptor(for: engineId)?.fingerprint
            ?? DailyFitEngineRegistry.fingerprint(for: calibration)
        return CalibrationSummary(
            sourceWeights: [
                "natal": sw.natal, "transits": sw.transits,
                "lunarPhase": sw.lunarPhase, "progressed": sw.progressed,
                "currentSun": sw.currentSun,
            ],
            selectionWeights: [
                "vibeWeight": sel.vibeWeight,
                "axisWeight": sel.axisWeight,
                "transitBoost": sel.transitBoost,
            ],
            axisTuning: [
                "sigmoidSpread": at.sigmoidSpread,
                "jitterRange": at.jitterRange,
            ],
            stage2Sensitivity: [
                "paletteJitter": s2.paletteJitter,
                "vibrancyCoeff": s2.vibrancyCoeff,
                "contrastCoeff": s2.contrastCoeff,
                "silhouetteAxisScale": s2.silhouetteAxisScale,
                "metalNudgePerHit": s2.metalNudgePerHit,
            ],
            dailyFitEngineId: engineId,
            fingerprint: fingerprint
        )
    }
}
