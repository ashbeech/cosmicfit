//
//  NarrativeIntentEngine.swift
//  Cosmic Fit
//
//  DEPRECATED (Plan 2): Superseded by DailyNarrativeSelector + DailyNarrativeCoherence.
//  Retained for production compatibility and diagnostic comparison.
//  Planned removal after Plan 3 cleanup validation.
//
//  Original purpose: Chart anchor vs sky weather classification and selection directives.
//

import Foundation

enum NarrativeIntentEngine {

    struct Resolution {
        let intent: NarrativeIntent
        let trace: NarrativeTrace
    }

    // MARK: - Public API

    static func resolve(
        essence: StyleEssenceProfile,
        snapshot: DailyEnergySnapshot,
        mode: DailyFitEngineMode,
        silhouetteProfile: SilhouetteProfile? = nil,
        tuning: DailyFitCalibration.NarrativeSelectionTuning = .stage1Default
    ) -> Resolution? {
        guard mode.usesSkyForwardPipeline else { return nil }
        guard let chartAnchorScores = essence.chartAnchorScores else { return nil }

        let anchorTop3 = chartAnchorScores
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map(\.category)
        let weatherTop3 = essence.visibleCategories
            .prefix(3)
            .map(\.category)

        guard anchorTop3.count >= 3, weatherTop3.count >= 3 else { return nil }

        let anchorSet = Set(anchorTop3)
        let weatherSet = Set(weatherTop3)
        let overlapCount = anchorSet.intersection(weatherSet).count

        let silhouetteDeltaMF = silhouetteDelta(
            today: silhouetteProfile?.masculineFeminine,
            anchor: silhouetteProfile?.chartAnchorMF
        )
        let silhouetteDeltaAR = silhouetteDelta(
            today: silhouetteProfile?.angularRounded,
            anchor: silhouetteProfile?.chartAnchorAR
        )
        let silhouetteDeltaSD = silhouetteDelta(
            today: silhouetteProfile?.structuredDraped,
            anchor: silhouetteProfile?.chartAnchorSD
        )

        var relationship = classifyRelationship(
            anchorTop3: Array(anchorTop3),
            weatherTop3: Array(weatherTop3),
            overlapCount: overlapCount,
            silhouetteDeltaMF: silhouetteDeltaMF,
            silhouetteDeltaAR: silhouetteDeltaAR,
            silhouetteDeltaSD: silhouetteDeltaSD,
            snapshot: snapshot
        )

        var coherenceGap: String?
        let anchorTop2Set = Set(anchorTop3.prefix(2))
        let weatherTop2Set = Set(weatherTop3.prefix(2))
        if overlapCount == 0,
           anchorTop2Set.isSubset(of: NarrativeSelectionDirectives.intenseBoldCategories),
           weatherTop2Set.isSubset(of: NarrativeSelectionDirectives.restrainedCategories) {
            relationship = .stretch
            coherenceGap = "intenseAnchorRestrainedWeather"
        }

        let templateKey = "\(relationship.rawValue).\(anchorTop3[0].rawValue).\(weatherTop3[0].rawValue)"
        let themeLexiconKey = resolveThemeLexiconKey(
            anchor: anchorTop3[0],
            weatherTop3: Array(weatherTop3)
        )

        let intent = buildIntent(
            relationship: relationship,
            anchorTop3: Array(anchorTop3),
            weatherTop3: Array(weatherTop3),
            themeLexiconKey: themeLexiconKey,
            coherenceGap: coherenceGap,
            tuning: tuning,
            snapshot: snapshot,
            silhouetteProfile: silhouetteProfile
        )

        let trace = NarrativeTrace(
            anchorTop3: anchorTop3.map(\.rawValue),
            weatherTop3: weatherTop3.map(\.rawValue),
            overlapCount: overlapCount,
            silhouetteDeltaMF: silhouetteDeltaMF,
            silhouetteDeltaAR: silhouetteDeltaAR,
            silhouetteDeltaSD: silhouetteDeltaSD,
            chosenRelationship: relationship,
            templateKey: templateKey
        )

        return Resolution(intent: intent, trace: trace)
    }

    // MARK: - Relationship Classification

    private static let oppositions = essenceOppositions

    private static func classifyRelationship(
        anchorTop3: [StyleEssenceCategory],
        weatherTop3: [StyleEssenceCategory],
        overlapCount: Int,
        silhouetteDeltaMF: Double?,
        silhouetteDeltaAR: Double?,
        silhouetteDeltaSD: Double?,
        snapshot: DailyEnergySnapshot
    ) -> NarrativeRelationship {
        if anchorTop3[0] == weatherTop3[0] || overlapCount >= 2 {
            return .reinforce
        }

        if overlapCount >= 1 {
            let anchorVec = BlueprintLensEngine.essenceCategoryWeights(for: anchorTop3[0])
            let weatherVec = BlueprintLensEngine.essenceCategoryWeights(for: weatherTop3[0])
            if NarrativeSelectionDirectives.cosineSimilarity(anchorVec, weatherVec) > 0.7 {
                return .reinforce
            }
        }

        if hasLeadingOpposition(anchorTop3: anchorTop3, weatherTop3: weatherTop3) {
            return .contrast
        }

        let weatherTop2Set = Set(weatherTop3.prefix(2))
        let anchorTop2Set = Set(anchorTop3.prefix(2))
        if overlapCount >= 1,
           weatherTop2Set.isSubset(of: NarrativeSelectionDirectives.intenseBoldCategories),
           anchorTop2Set.isSubset(of: NarrativeSelectionDirectives.restrainedCategories) {
            if shouldPreferStretchOverSoften(
                snapshot: snapshot,
                silhouetteDeltaMF: silhouetteDeltaMF,
                silhouetteDeltaAR: silhouetteDeltaAR,
                silhouetteDeltaSD: silhouetteDeltaSD
            ) {
                return .stretch
            }
            return .soften
        }

        return .stretch
    }

    private static func hasLeadingOpposition(
        anchorTop3: [StyleEssenceCategory],
        weatherTop3: [StyleEssenceCategory]
    ) -> Bool {
        let anchorLeading = Set(anchorTop3.prefix(2))
        let weatherLeading = Set(weatherTop3.prefix(2))
        for (a, b) in oppositions {
            if (anchorLeading.contains(a) && weatherLeading.contains(b)) ||
               (anchorLeading.contains(b) && weatherLeading.contains(a)) {
                return true
            }
        }
        return false
    }

    private static func shouldPreferStretchOverSoften(
        snapshot: DailyEnergySnapshot,
        silhouetteDeltaMF: Double?,
        silhouetteDeltaAR: Double?,
        silhouetteDeltaSD: Double?
    ) -> Bool {
        let meanDelta = meanAbsSilhouetteDelta(mf: silhouetteDeltaMF, ar: silhouetteDeltaAR, sd: silhouetteDeltaSD)
        if meanDelta > 0.12 { return true }

        if let chartVisibility = snapshot.chartAxes?.visibility {
            let visibilityDelta = snapshot.axes.visibility - chartVisibility
            if visibilityDelta > 1.0 { return true }
        }
        return false
    }

    // MARK: - Intent Building

    private static let themeLexiconKeys: [String: String] = [
        "polished.drama": "Polished Drama",
        "romantic.edgy": "Romantic Edge",
        "classic.maximalist": "Classic Maximalism",
        "minimal.drama": "Quiet Impact",
        "grounded.magnetic": "Grounded Magnetism",
        "polished.edgy": "Refined Edge",
        "sensual.drama": "Soft Power",
    ]

    private static func resolveThemeLexiconKey(
        anchor: StyleEssenceCategory,
        weatherTop3: [StyleEssenceCategory]
    ) -> String? {
        for weather in weatherTop3 where weather != anchor {
            let key = "\(anchor.rawValue).\(weather.rawValue)"
            if themeLexiconKeys[key] != nil {
                return key
            }
        }
        return nil
    }

    private static func buildIntent(
        relationship: NarrativeRelationship,
        anchorTop3: [StyleEssenceCategory],
        weatherTop3: [StyleEssenceCategory],
        themeLexiconKey: String?,
        coherenceGap: String?,
        tuning: DailyFitCalibration.NarrativeSelectionTuning,
        snapshot: DailyEnergySnapshot,
        silhouetteProfile: SilhouetteProfile?
    ) -> NarrativeIntent {
        let weatherAccent = weatherTop3[0]
        let foundation = restrainedFoundationCategory(from: anchorTop3)

        let tarotVector: [Energy: Double]
        switch relationship {
        case .reinforce:
            tarotVector = NarrativeSelectionDirectives.blendedReinforceVector(
                anchorTop3: anchorTop3,
                weatherTop3: weatherTop3
            )
        case .soften:
            tarotVector = NarrativeSelectionDirectives.scaledVector(
                NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: weatherTop3),
                factor: 0.7
            )
        case .stretch, .contrast:
            let weatherVec = NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: weatherTop3)
            let anchorVec = NarrativeSelectionDirectives.blendCategoryWeightRowsPublic(
                categories: anchorTop3,
                weights: [0.5, 0.35, 0.15]
            )
            tarotVector = NarrativeSelectionDirectives.zipEnergyPublic(weatherVec, anchorVec, anchorWeight: 0.25)
        }

        let maxStatementSlots: Int
        switch relationship {
        case .reinforce: maxStatementSlots = 2
        case .stretch, .soften, .contrast: maxStatementSlots = 1
        }

        let scales: ScaleDirective
        switch relationship {
        case .reinforce:
            scales = ScaleDirective(
                vibrancyCap: nil, contrastCap: nil,
                pullTowardBaseline: false, baselineBlend: 0.0
            )
        case .stretch:
            if coherenceGap == "intenseAnchorRestrainedWeather" {
                scales = ScaleDirective(
                    vibrancyCap: nil, contrastCap: nil,
                    pullTowardBaseline: true,
                    baselineBlend: tuning.intenseAnchorRestrainedWeatherBlend
                )
            } else {
                scales = ScaleDirective(
                    vibrancyCap: nil, contrastCap: nil,
                    pullTowardBaseline: false, baselineBlend: 0.0
                )
            }
        case .soften:
            scales = ScaleDirective(
                vibrancyCap: tuning.softenVibrancyCap,
                contrastCap: tuning.softenContrastCap,
                pullTowardBaseline: true,
                baselineBlend: tuning.softenBaselineBlend
            )
        case .contrast:
            scales = ScaleDirective(
                vibrancyCap: nil, contrastCap: nil,
                pullTowardBaseline: false, baselineBlend: 0.0
            )
        }

        let preferFoundation = coherenceGap == "intenseAnchorRestrainedWeather"

        return NarrativeIntent(
            relationship: relationship,
            anchorTop3: anchorTop3,
            weatherTop3: weatherTop3,
            tarot: TarotDirective(
                targetEnergyVector: tarotVector,
                targetAxesVector: {
                    if let sil = silhouetteProfile {
                        return NarrativeSelectionDirectives.targetAxesVector(
                            snapshot: snapshot, silhouette: sil, tuning: tuning
                        )
                    }
                    return NarrativeSelectionDirectives.targetAxesVectorSkyOnly(snapshot: snapshot)
                }(),
                structuredDraped: silhouetteProfile?.structuredDraped ?? 0.5
            ),
            palette: PaletteDirective(
                maxStatementSlots: maxStatementSlots,
                accentCategory: weatherAccent,
                foundationCategory: foundation,
                categoryEnergyBoost: NarrativeSelectionDirectives.categoryEnergyBoost(weatherTop3: weatherTop3),
                preferFoundationOverStatement: preferFoundation
            ),
            scales: scales,
            essencePresentation: EssencePresentationDirective(showAnchorGhost: true),
            themeLexiconKey: themeLexiconKey,
            coherenceGap: coherenceGap
        )
    }

    private static func restrainedFoundationCategory(from anchorTop3: [StyleEssenceCategory]) -> StyleEssenceCategory {
        for category in anchorTop3 {
            if NarrativeSelectionDirectives.restrainedCategories.contains(category) {
                return category
            }
        }
        return anchorTop3[0]
    }

    // MARK: - Helpers

    private static func silhouetteDelta(today: Double?, anchor: Double?) -> Double? {
        guard let today, let anchor else { return nil }
        return today - anchor
    }

    private static func meanAbsSilhouetteDelta(mf: Double?, ar: Double?, sd: Double?) -> Double {
        let deltas = [mf, ar, sd].compactMap { $0 }
        guard !deltas.isEmpty else { return 0 }
        return deltas.map { abs($0) }.reduce(0, +) / Double(deltas.count)
    }
}
