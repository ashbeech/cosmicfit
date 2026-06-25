//
//  NarrativeTarotBridgeSelector.swift
//  Cosmic Fit
//
//  DEPRECATED (Plan 2): Stage-1 tarot selection now reads from DailyNarrativePlan.tarotDirective
//  via BlueprintLensEngine.generatePayloadFromPlan. This selector is still called indirectly
//  through the plan-to-intent bridge for backward compatibility.
//  Retained for production compatibility. Planned removal after Plan 3 cleanup.
//
//  Original purpose: Joint (card, variant) selection for Stage-1 narrative bridge.
//

import Foundation

enum NarrativeTarotBridgeSelector {

    struct Candidate: Equatable {
        let card: TarotCard
        let variant: StyleEditVariant
        let variantIndex: Int
        let baseCardScore: Double
        let variantBridgeScore: Double
        let variantFormBridgeScore: Double
        let pairTotalScore: Double
    }

    struct SelectionResult: Equatable {
        let candidate: Candidate
        let bridgeTrace: NarrativeBridgeTrace
        let funnelCardCount: Int
        let pairsEvaluated: Int
    }

    // MARK: - Public API

    static func select(
        snapshot: DailyEnergySnapshot,
        allCards: [(card: TarotCard, normAxes: [String: Double])],
        recentSelections: [(cardName: String, daysAgo: Int)],
        intent: NarrativeIntent,
        calibration: DailyFitCalibration,
        dailySeed: Int,
        lastVariantByCard: [String: Int] = [:]
    ) -> SelectionResult {
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let weights = calibration.selectionWeights
        let target = intent.tarot.targetEnergyVector

        // Stage A: score all cards with existing astro formula + card-level narrative boost
        let vibeVector = BlueprintLensEngine.buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = BlueprintLensEngine.buildAxesVector(from: snapshot.axes)

        var scoredCards: [(card: TarotCard, normAxes: [String: Double], baseScore: Double)] = []
        let recentSuitCounts = BlueprintLensEngine.computeRecentSuitCounts(
            recentSelections: recentSelections, allCards: allCards
        )
        for (card, normAxes) in allCards {
            let base = scoreBaseCard(
                card: card,
                normAxes: normAxes,
                vibeVector: vibeVector,
                axesVector: axesVector,
                weights: weights,
                recentSelections: recentSelections,
                dominantTransits: snapshot.dominantTransits,
                intent: intent,
                tuning: tuning,
                recentSuitCounts: recentSuitCounts
            )
            scoredCards.append((card, normAxes, base))
        }
        scoredCards.sort { $0.baseScore > $1.baseScore }

        let poolSize = min(tuning.bridgeCandidatePoolSize, scoredCards.count)
        let pool = Array(scoredCards.prefix(poolSize))

        // Stage B + C: for each card in funnel, score all variants jointly
        let targetAxes = intent.tarot.targetAxesVector
        let structureGateActive = intent.tarot.structuredDraped < tuning.structureSliderThreshold
        var pairs: [Candidate] = []
        for entry in pool {
            guard let edits = entry.card.styleEdits, !edits.isEmpty else { continue }
            for (i, edit) in edits.enumerated() {
                let variantVector = NarrativeSelectionDirectives.energyDictionary(from: edit.energyEmphasis)
                var bridgeScore = NarrativeSelectionDirectives.cosineSimilarity(variantVector, target)

                if intent.relationship == .contrast {
                    bridgeScore *= 1.2
                }

                let axesDict = NarrativeSelectionDirectives.axesDictionary(from: edit.axesEmphasis)
                let formScore = NarrativeSelectionDirectives.cosineSimilarityAxes(axesDict, targetAxes)

                var total = entry.baseScore
                    + tuning.variantBridgeWeight * bridgeScore
                    + tuning.variantFormBridgeWeight * formScore

                if structureGateActive {
                    let variantStrategy = edit.axesEmphasis["strategy"] ?? 50
                    if variantStrategy < tuning.structureVariantStrategyFloor {
                        total -= 10.0
                    }
                }

                pairs.append(Candidate(
                    card: entry.card,
                    variant: edit,
                    variantIndex: i,
                    baseCardScore: entry.baseScore,
                    variantBridgeScore: bridgeScore,
                    variantFormBridgeScore: formScore,
                    pairTotalScore: total
                ))
            }
        }

        // Soften: among top-3 variant scores per card, prefer minimum drama emphasis
        if intent.relationship == .soften {
            pairs = applySoftenMinDramaRule(pairs)
        }

        pairs.sort { $0.pairTotalScore > $1.pairTotalScore }

        guard let best = pairs.first else {
            // Fallback: no pairs (all cards had empty styleEdits)
            let fallbackCard = pool.first?.card ?? allCards.first?.card ?? TarotCard.fallbackFool
            let fallbackVariant = StyleEditVariant(
                variant: "I", title: fallbackCard.name,
                description: "Style guidance inspired by \(fallbackCard.name).",
                energyEmphasis: [:], axesEmphasis: [:],
                dailyRitual: nil, wardrobeReflection: nil
            )
            let fallbackCandidate = Candidate(
                card: fallbackCard, variant: fallbackVariant, variantIndex: 0,
                baseCardScore: pool.first?.baseScore ?? 0, variantBridgeScore: 0,
                variantFormBridgeScore: 0, pairTotalScore: 0
            )
            let trace = NarrativeBridgeTrace(
                selectedCardName: fallbackCard.name,
                selectedVariantTitle: fallbackVariant.title,
                selectedVariantIndex: 0,
                variantBridgeSimilarity: 0,
                bestPairTotalScore: 0,
                runnerUpPairTotalScore: 0,
                bridgeMargin: 0,
                bestVariantSimilarityInPool: 0,
                funnelCardCount: poolSize,
                pairsEvaluated: 0,
                contrastWeatherWins: nil,
                bridgePass: false
            )
            return SelectionResult(
                candidate: fallbackCandidate,
                bridgeTrace: trace,
                funnelCardCount: poolSize,
                pairsEvaluated: 0
            )
        }

        // Tie-break: if top two within epsilon, use dailySeed
        var selected = best
        if pairs.count >= 2, abs(pairs[0].pairTotalScore - pairs[1].pairTotalScore) < tuning.pairScoreTieEpsilon {
            let pick = dailySeed % 2
            selected = pairs[pick]
        }

        // Variant-recency swap: if the winning card is a returning card and
        // would repeat the same variant, swap to the best alternate variant
        // of the same card. Card choice stays untouched.
        let recencySwapped = applyVariantRecencySwap(
            &selected, pairs: pairs, lastVariantByCard: lastVariantByCard
        )

        let runnerUp = pairs.count > 1 ? pairs[1].pairTotalScore : selected.pairTotalScore
        let maxSim = pairs.map(\.variantBridgeScore).max() ?? 0
        let margin = selected.pairTotalScore - runnerUp

        let contrastWeatherWins: Bool? = intent.relationship == .contrast
            ? computeContrastWeatherWins(variant: selected.variant, intent: intent)
            : nil

        let bridgePass = selected.variantBridgeScore >= tuning.minVariantBridgeSimilarity
            && margin >= tuning.minBridgeMargin

        let formBridgePass = selected.variantFormBridgeScore >= tuning.minFormBridgeSimilarity

        let trace = NarrativeBridgeTrace(
            selectedCardName: selected.card.name,
            selectedVariantTitle: selected.variant.title,
            selectedVariantIndex: selected.variantIndex,
            variantBridgeSimilarity: selected.variantBridgeScore,
            bestPairTotalScore: selected.pairTotalScore,
            runnerUpPairTotalScore: runnerUp,
            bridgeMargin: margin,
            bestVariantSimilarityInPool: maxSim,
            funnelCardCount: poolSize,
            pairsEvaluated: pairs.count,
            contrastWeatherWins: contrastWeatherWins,
            bridgePass: bridgePass,
            variantRecencySwapped: recencySwapped,
            variantFormBridgeSimilarity: selected.variantFormBridgeScore,
            formBridgePass: formBridgePass,
            structureGateApplied: structureGateActive
        )

        return SelectionResult(
            candidate: selected,
            bridgeTrace: trace,
            funnelCardCount: poolSize,
            pairsEvaluated: pairs.count
        )
    }

    // MARK: - Base Card Scoring (delegates to TarotCardScoring)

    /// Computes base card score using the shared astro formula + optional narrative boost.
    static func scoreBaseCard(
        card: TarotCard,
        normAxes: [String: Double],
        vibeVector: [String: Double],
        axesVector: [String: Double],
        weights: DailyFitCalibration.SelectionWeights,
        recentSelections: [(cardName: String, daysAgo: Int)],
        dominantTransits: [DailyTransitSummary],
        intent: NarrativeIntent?,
        tuning: DailyFitCalibration.NarrativeSelectionTuning?,
        recentSuitCounts: [String: Int]? = nil
    ) -> Double {
        TarotCardScoring.scoreCard(
            card: card, normAxes: normAxes,
            vibeVector: vibeVector, axesVector: axesVector,
            weights: weights,
            recentSelections: recentSelections,
            dominantTransits: dominantTransits,
            intent: intent, tuning: tuning,
            recentSuitCounts: recentSuitCounts
        ).total
    }

    // MARK: - Private Helpers

    /// If the selected card was recently shown and would repeat the same variant index,
    /// swap to the best-scoring alternate variant of the same card.
    /// Returns true if a swap occurred.
    private static func applyVariantRecencySwap(
        _ selected: inout Candidate,
        pairs: [Candidate],
        lastVariantByCard: [String: Int]
    ) -> Bool {
        guard let lastIndex = lastVariantByCard[selected.card.name],
              lastIndex == selected.variantIndex else {
            return false
        }
        let alternates = pairs
            .filter { $0.card.name == selected.card.name && $0.variantIndex != lastIndex }
            .sorted { $0.variantBridgeScore > $1.variantBridgeScore }
        guard let best = alternates.first else { return false }
        selected = best
        return true
    }

    /// Soften rule: among top-3 variant bridge scores per card, prefer minimum drama emphasis.
    /// Iterates grouped cards in sorted key order for deterministic results.
    private static func applySoftenMinDramaRule(_ pairs: [Candidate]) -> [Candidate] {
        let grouped = Dictionary(grouping: pairs, by: { $0.card.name })

        var result: [Candidate] = []
        for cardName in grouped.keys.sorted() {
            guard let cardPairs = grouped[cardName] else { continue }
            // Stable ordering within card: highest bridge score first, variant index breaks ties
            let sorted = cardPairs.sorted {
                $0.variantBridgeScore != $1.variantBridgeScore
                    ? $0.variantBridgeScore > $1.variantBridgeScore
                    : $0.variantIndex < $1.variantIndex
            }
            let top3 = Array(sorted.prefix(3))
            guard top3.count >= 2 else {
                result.append(contentsOf: cardPairs)
                continue
            }

            // Among top-3, prefer minimum drama; variant index breaks ties
            let minDramaCandidate = top3.min(by: {
                let d0 = $0.variant.energyEmphasis["drama"] ?? 0.5
                let d1 = $1.variant.energyEmphasis["drama"] ?? 0.5
                return d0 != d1 ? d0 < d1 : $0.variantIndex < $1.variantIndex
            })

            for pair in cardPairs {
                if let winner = minDramaCandidate, top3.contains(where: { $0 == pair }) {
                    if pair == winner {
                        let bestScore = top3.map(\.pairTotalScore).max() ?? pair.pairTotalScore
                        result.append(Candidate(
                            card: pair.card, variant: pair.variant, variantIndex: pair.variantIndex,
                            baseCardScore: pair.baseCardScore, variantBridgeScore: pair.variantBridgeScore,
                            variantFormBridgeScore: pair.variantFormBridgeScore,
                            pairTotalScore: bestScore
                        ))
                    } else {
                        result.append(pair)
                    }
                } else {
                    result.append(pair)
                }
            }
        }
        return result
    }

    private static func computeContrastWeatherWins(variant: StyleEditVariant, intent: NarrativeIntent) -> Bool {
        let variantVector = NarrativeSelectionDirectives.energyDictionary(from: variant.energyEmphasis)
        let weatherVec = NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: intent.weatherTop3)
        let anchorVec = NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: intent.anchorTop3)
        let weatherAlignment = NarrativeSelectionDirectives.cosineSimilarity(variantVector, weatherVec)
        let anchorAlignment = NarrativeSelectionDirectives.cosineSimilarity(variantVector, anchorVec)
        return weatherAlignment >= anchorAlignment
    }
}
