//
//  TarotCardScoring.swift
//  Cosmic Fit
//
//  Single source of truth for tarot card scoring primitives.
//  Used by BlueprintLensEngine (production + trace paths) and
//  NarrativeTarotBridgeSelector (Stage-1 bridge funnel).
//

import Foundation

enum TarotCardScoring {

    // MARK: - Planet-Energy Affinity Table

    /// Mirrored from DailyEnergyEngine.planetEnergyBase.
    /// One copy — no duplicates in the codebase.
    static let planetEnergyAffinities: [String: [String: Double]] = [
        "Sun":     ["drama": 0.3, "classic": 0.3, "playful": 0.2, "edge": 0.1, "romantic": 0.1],
        "Moon":    ["romantic": 0.4, "classic": 0.2, "playful": 0.2, "drama": 0.1, "utility": 0.1],
        "Mercury": ["playful": 0.3, "utility": 0.3, "classic": 0.2, "edge": 0.2],
        "Venus":   ["romantic": 0.4, "classic": 0.3, "playful": 0.2, "drama": 0.1],
        "Mars":    ["drama": 0.3, "edge": 0.3, "utility": 0.2, "playful": 0.2],
        "Jupiter": ["drama": 0.3, "playful": 0.3, "romantic": 0.2, "classic": 0.2],
        "Saturn":  ["classic": 0.4, "utility": 0.4, "drama": 0.1, "edge": 0.1],
        "Uranus":  ["edge": 0.5, "playful": 0.2, "drama": 0.2, "utility": 0.1],
        "Neptune": ["romantic": 0.4, "edge": 0.3, "drama": 0.2, "playful": 0.1],
        "Pluto":   ["drama": 0.4, "edge": 0.3, "romantic": 0.1, "utility": 0.1, "classic": 0.1],
    ]

    // MARK: - Transit Boost

    /// Sum of alignment between each dominant transit's planet energies
    /// and the card's energy affinities, weighted by transit strength. Capped at 1.0.
    static func transitBoost(
        for card: TarotCard,
        dominantTransits: [DailyTransitSummary]
    ) -> Double {
        guard !dominantTransits.isEmpty else { return 0.0 }
        var total = 0.0
        for transit in dominantTransits {
            guard let planetEnergies = planetEnergyAffinities[transit.transitPlanet] else {
                continue
            }
            var alignment = 0.0
            for (energy, planetAff) in planetEnergies {
                let cardAff = card.energyAffinity[energy] ?? 0.0
                alignment += planetAff * cardAff
            }
            total += alignment * transit.strength
        }
        return min(total, 1.0)
    }

    // MARK: - Recency Penalty

    /// Tiered near-term suppression (≤2 days: 0.45, ≤6: 0.25, ≤10: 0.12)
    /// plus frequency escalation (+0.08 per extra appearance). Capped at 0.7.
    static func recencyPenalty(
        for cardName: String,
        recentSelections: [(cardName: String, daysAgo: Int)]
    ) -> Double {
        let matches = recentSelections.filter { $0.cardName == cardName }
        guard let match = matches.first else {
            return 0.0
        }
        var penalty = 0.0
        if match.daysAgo <= 2 {
            penalty += 0.45
        } else if match.daysAgo <= 6 {
            penalty += 0.25
        } else if match.daysAgo <= 10 {
            penalty += 0.12
        }
        penalty += max(0.0, Double(matches.count - 1) * 0.08)
        return min(penalty, 0.7)
    }

    // MARK: - Narrative Category Boost

    /// Card-level narrative affinity boost. Returns 0 when intent/tuning are nil.
    static func narrativeCategoryBoost(
        card: TarotCard,
        intent: NarrativeIntent,
        tuning: DailyFitCalibration.NarrativeSelectionTuning
    ) -> Double {
        let cardVector = NarrativeSelectionDirectives.energyDictionary(from: card.energyAffinity)
        var boost = NarrativeSelectionDirectives.cosineSimilarity(
            cardVector, intent.tarot.targetEnergyVector
        )
        if intent.relationship == .contrast {
            boost *= 1.2
        }
        return boost * tuning.categoryBoostWeight
    }

    // MARK: - Full Card Scoring

    /// Decomposed score for trace/inspector display.
    struct ScoreBreakdown {
        let vibeScore: Double
        let axisScore: Double
        let transitBoost: Double
        let recencyPenalty: Double
        let narrativeBoost: Double
        let total: Double
    }

    /// Complete base card score: vibe + axis + transit − recency + optional narrative boost.
    /// All callers (production, bridge, trace, diagnostics) use this single implementation.
    static func scoreCard(
        card: TarotCard,
        normAxes: [String: Double],
        vibeVector: [String: Double],
        axesVector: [String: Double],
        weights: DailyFitCalibration.SelectionWeights,
        recentSelections: [(cardName: String, daysAgo: Int)],
        dominantTransits: [DailyTransitSummary],
        intent: NarrativeIntent? = nil,
        tuning: DailyFitCalibration.NarrativeSelectionTuning? = nil
    ) -> ScoreBreakdown {
        let vibe = BlueprintLensEngine.cosineSimilarity(card.energyAffinity, vibeVector)
        let axis = normAxes.isEmpty ? 0.5 : BlueprintLensEngine.cosineSimilarity(normAxes, axesVector)
        let transit = transitBoost(for: card, dominantTransits: dominantTransits)
        let recency = recencyPenalty(for: card.name, recentSelections: recentSelections)

        var narrative = 0.0
        if let intent, let tuning {
            narrative = narrativeCategoryBoost(card: card, intent: intent, tuning: tuning)
        }

        let total = (vibe * weights.vibeWeight)
            + (axis * weights.axisWeight)
            + (transit * weights.transitBoost)
            - recency
            + narrative

        return ScoreBreakdown(
            vibeScore: vibe,
            axisScore: axis,
            transitBoost: transit,
            recencyPenalty: recency,
            narrativeBoost: narrative,
            total: total
        )
    }
}
