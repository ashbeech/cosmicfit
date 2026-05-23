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

    // Stage 1 per-input energy attribution (Phase 3)
    let stage1Attribution: Stage1AttributionTrace?

    // Stage 1 per-input axis attribution (visibility/action/tempo/strategy drivers)
    let stage1AxisAttribution: Stage1AxisAttributionTrace?

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

    // Narrative selection (Stage 1 only — trace export, no user copy)
    let narrativeTrace: NarrativeTrace?
    let narrativeIntentTrace: NarrativeIntentTrace?
    let narrativeCoherenceTrace: NarrativeCoherenceTrace?
}

// MARK: - Phase 3: Per-Input Energy Attribution

/// A specific input's contribution to one energy.
struct EnergyAttributionEntry: Codable, Equatable {
    /// "natal" | "progressed" | "transit" | "lunar" | "currentSun"
    let source: String
    /// Human-readable label, e.g. "Mars square Moon", "Venus in Scorpio", "Waxing Gibbous"
    let label: String
    /// Energy.rawValue
    let energy: String
    /// Before source weight application
    let rawContribution: Double
    /// After source weight (+ aspect modifiers for transits)
    let weightedContribution: Double
}

/// Per-energy rollup with top contributors.
struct EnergyAttributionBreakdown: Codable, Equatable {
    let energy: String
    let totalRaw: Double
    let totalPostMultiplier: Double
    /// Sorted by abs(weightedContribution) descending.
    let entries: [EnergyAttributionEntry]
}

/// Full Stage 1 attribution trace across all 6 energies.
struct Stage1AttributionTrace: Codable, Equatable {
    /// One breakdown per energy (6 entries).
    let byEnergy: [EnergyAttributionBreakdown]
    /// Sun-sign multiplier applied to each energy after accumulation (daily payload path).
    let signMultiplierApplied: [String: Double]
    /// Whether sign multipliers were applied to the daily vibe payload path.
    let signMultipliersAppliedToDailyVibe: Bool
    /// Natal Sun signEnergyMap for chart-anchor slice when policy enables it (stage1 only).
    let chartAnchorSignMultiplierApplied: [String: Double]?
    /// Which weight profile was used: "standard" or "stage1Experimental"
    let engineMode: String
}

// MARK: - Phase 5: Per-Input Axis Attribution

/// One line item: a specific input's contribution to one axis raw score (pre-sigmoid).
struct AxisAttributionEntry: Codable, Equatable {
    /// "transit" | "natal" | "progressed" | "lunar" | "jitter" | "baseline"
    let source: String
    /// Human-readable label, e.g. "Mars square Venus (Aries, Fire)"
    let label: String
    /// action | tempo | strategy | visibility
    let axis: String
    /// Signed contribution to raw axis score before sigmoid scaling.
    let contribution: Double
}

/// Per-axis rollup with top contributors.
struct AxisAttributionBreakdown: Codable, Equatable {
    let axis: String
    let rawScore: Double
    let finalAxisValue: Double
    /// Sorted by abs(contribution) descending.
    let entries: [AxisAttributionEntry]
}

/// Full Stage 1 axis attribution trace (feeds silhouette, contrast, tarot axis match).
struct Stage1AxisAttributionTrace: Codable, Equatable {
    let byAxis: [AxisAttributionBreakdown]
    let engineMode: String
    let sigmoidSpread: Double
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
    let selectionStrategy: String?
    let coreAnchorSwapApplied: Bool?
    let narrativeBiasApplied: Bool?
    let statementSlotsUsed: Int?
    let selectionPath: String?
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
    let signMultiplierPolicy: [String: Bool]
    let dailyFitEngineId: String
    let fingerprint: String
}

// MARK: - Attribution Builder

extension Stage1AttributionTrace {

    /// Builds a structured trace from flat attribution entries collected during
    /// `generateSnapshotWithTrace`. Groups by energy, sorts by magnitude, caps per energy.
    static func build(
        entries: [EnergyAttributionEntry],
        signMultipliers: [String: Double],
        postMultiplierScores: [String: Double],
        engineMode: String,
        signMultipliersAppliedToDailyVibe: Bool,
        chartAnchorSignMultipliers: [String: Double]? = nil,
        maxEntriesPerEnergy: Int = 20
    ) -> Stage1AttributionTrace {
        var grouped: [String: [EnergyAttributionEntry]] = [:]
        for entry in entries {
            grouped[entry.energy, default: []].append(entry)
        }

        var breakdowns: [EnergyAttributionBreakdown] = []
        for energy in Energy.allCases {
            let key = energy.rawValue
            var energyEntries = grouped[key] ?? []
            energyEntries.sort { abs($0.weightedContribution) > abs($1.weightedContribution) }
            if energyEntries.count > maxEntriesPerEnergy {
                energyEntries = Array(energyEntries.prefix(maxEntriesPerEnergy))
            }
            let totalRaw = energyEntries.reduce(0.0) { $0 + $1.rawContribution }
            let totalPost = postMultiplierScores[key] ?? 0.0
            breakdowns.append(EnergyAttributionBreakdown(
                energy: key,
                totalRaw: totalRaw,
                totalPostMultiplier: totalPost,
                entries: energyEntries
            ))
        }

        return Stage1AttributionTrace(
            byEnergy: breakdowns,
            signMultiplierApplied: signMultipliers,
            signMultipliersAppliedToDailyVibe: signMultipliersAppliedToDailyVibe,
            chartAnchorSignMultiplierApplied: chartAnchorSignMultipliers,
            engineMode: engineMode
        )
    }
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

        // Stage 2: payload with trace (via pipeline)
        let (payload, s2Trace, narrativeTrace, narrativeIntentTrace, narrativeCoherenceTrace) = DailyFitPipeline.generateWithTrace(
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
            diversitySwapApplied: s2Trace.paletteTrace.diversitySwapApplied,
            selectionStrategy: s2Trace.paletteTrace.selectionStrategy,
            coreAnchorSwapApplied: s2Trace.paletteTrace.coreAnchorSwapApplied,
            narrativeBiasApplied: s2Trace.narrativeBiasApplied,
            statementSlotsUsed: s2Trace.paletteStatementSlotCount,
            selectionPath: s2Trace.paletteSelectionPath
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

        let stage1Attribution = Stage1AttributionTrace.build(
            entries: s1Trace.attributionEntries,
            signMultipliers: s1Trace.signMultipliers,
            postMultiplierScores: s1Trace.postMultiplierScores,
            engineMode: s1Trace.engineMode,
            signMultipliersAppliedToDailyVibe: calibration.signMultiplierPolicy.applyToDailyVibe,
            chartAnchorSignMultipliers: s1Trace.chartAnchorSignMultipliers
        )

        let stage1AxisAttribution = Stage1AxisAttributionTrace(
            byAxis: s1Trace.axisAttribution,
            engineMode: s1Trace.engineMode,
            sigmoidSpread: calibration.axisTuning.sigmoidSpread
        )

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
            stage1Attribution: stage1Attribution,
            stage1AxisAttribution: stage1AxisAttribution,
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
            calibrationSnapshot: calSnap,
            narrativeTrace: narrativeTrace,
            narrativeIntentTrace: narrativeIntentTrace,
            narrativeCoherenceTrace: narrativeCoherenceTrace
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
        let policy = calibration.signMultiplierPolicy
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
            signMultiplierPolicy: [
                "applyToDailyVibe": policy.applyToDailyVibe,
                "applyToChartAnchor": policy.applyToChartAnchor,
            ],
            dailyFitEngineId: engineId,
            fingerprint: fingerprint
        )
    }
}
