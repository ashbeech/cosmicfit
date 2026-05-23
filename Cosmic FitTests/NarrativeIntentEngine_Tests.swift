//
//  NarrativeIntentEngine_Tests.swift
//  Cosmic FitTests
//
//  Classification parity tests — no user-facing copy assertions.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixtures

private enum NarrativeTestFixtures {

    static func essenceProfile(
        top3: [StyleEssenceCategory],
        chartAnchorTop3: [StyleEssenceCategory]
    ) -> StyleEssenceProfile {
        var allScores = StyleEssenceCategory.allCases.map {
            StyleEssenceScore(category: $0, score: 0.01)
        }
        for (i, cat) in top3.enumerated() {
            let score = 0.30 - Double(i) * 0.05
            if let idx = allScores.firstIndex(where: { $0.category == cat }) {
                allScores[idx] = StyleEssenceScore(category: cat, score: score)
            }
        }
        let visibleCategories = top3.enumerated().map { i, cat in
            StyleEssenceScore(category: cat, score: 0.30 - Double(i) * 0.05)
        }

        var chartAnchorScores = StyleEssenceCategory.allCases.map {
            StyleEssenceScore(category: $0, score: 0.01)
        }
        for (i, cat) in chartAnchorTop3.enumerated() {
            let score = 0.30 - Double(i) * 0.05
            if let idx = chartAnchorScores.firstIndex(where: { $0.category == cat }) {
                chartAnchorScores[idx] = StyleEssenceScore(category: cat, score: score)
            }
        }

        return StyleEssenceProfile(
            allScores: allScores,
            visibleCategories: visibleCategories,
            chartAnchorScores: chartAnchorScores
        )
    }

    static let snapshot = DailyEnergySnapshot.fixture()
}

@Suite("NarrativeIntentEngine")
struct NarrativeIntentEngine_Tests {

    @Test("stretch_conflict_golden — polished anchor vs maximalist weather")
    func stretchConflictGolden() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.maximalist, .drama, .edgy],
            chartAnchorTop3: [.polished, .romantic, .classic]
        )

        let result = NarrativeIntentEngine.resolve(
            essence: essence,
            snapshot: NarrativeTestFixtures.snapshot,
            mode: .stage1Experimental
        )

        #expect(result != nil)
        #expect(result!.trace.chosenRelationship == .stretch)
        #expect(result!.intent.relationship == .stretch)
        #expect(result!.trace.overlapCount == 0)
        #expect(result!.intent.palette.maxStatementSlots == 1)
    }

    @Test("reinforce_top1_match")
    func reinforceTop1Match() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.romantic, .playful, .sensual],
            chartAnchorTop3: [.romantic, .classic, .polished]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .reinforce)
        #expect(result?.intent.palette.maxStatementSlots == 2)
    }

    @Test("reinforce_shared_2")
    func reinforceShared2() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.classic, .romantic, .drama],
            chartAnchorTop3: [.romantic, .classic, .polished]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .reinforce)
    }

    @Test("contrast_minimal_maximalist")
    func contrastMinimalMaximalist() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.maximalist, .playful, .magnetic],
            chartAnchorTop3: [.minimal, .grounded, .effortless]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .contrast)
        #expect(result?.intent.palette.maxStatementSlots == 1)
    }

    @Test("contrast_polished_edgy_leading")
    func contrastPolishedEdgyLeading() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.edgy, .drama, .maximalist],
            chartAnchorTop3: [.polished, .classic, .romantic]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .contrast)
        #expect(result?.intent.themeLexiconKey == "polished.edgy")
    }

    @Test("stretch_polished_edgy_rank3")
    func stretchPolishedEdgyRank3() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.maximalist, .drama, .edgy],
            chartAnchorTop3: [.polished, .romantic, .classic]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .stretch)
    }

    @Test("soften_intense_weather_restrained_anchor")
    func softenIntenseWeather() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.drama, .magnetic, .polished],
            chartAnchorTop3: [.polished, .classic, .romantic]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .soften)
        #expect(result?.intent.scales.vibrancyCap != nil)
    }

    @Test("nil_production_mode")
    func nilProductionMode() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.maximalist, .drama, .edgy],
            chartAnchorTop3: [.romantic, .classic, .polished]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .standard
        )
        #expect(result == nil)
    }

    @Test("nil_missing_chart_anchor")
    func nilMissingChartAnchor() {
        let essence = StyleEssenceProfile(
            allScores: StyleEssenceCategory.allCases.map {
                StyleEssenceScore(category: $0, score: 0.07)
            },
            visibleCategories: [
                StyleEssenceScore(category: .romantic, score: 0.3),
                StyleEssenceScore(category: .classic, score: 0.25),
                StyleEssenceScore(category: .polished, score: 0.2)
            ],
            chartAnchorScores: nil
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result == nil)
    }

    @Test("theme_lexicon_key_trace_only")
    func themeLexiconKeyTraceOnly() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.drama, .edgy, .magnetic],
            chartAnchorTop3: [.polished, .classic, .romantic]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: NarrativeTestFixtures.snapshot, mode: .stage1Experimental
        )
        #expect(result?.intent.themeLexiconKey == "polished.drama")
    }

    @Test("intense_anchor_restrained_weather gap flags stretch + foundation preference")
    func intenseAnchorRestrainedWeatherGap() {
        let essence = NarrativeTestFixtures.essenceProfile(
            top3: [.romantic, .classic, .effortless],
            chartAnchorTop3: [.drama, .magnetic, .edgy]
        )
        let result = NarrativeIntentEngine.resolve(
            essence: essence,
            snapshot: NarrativeTestFixtures.snapshot,
            mode: .stage1Experimental
        )
        #expect(result?.intent.relationship == .stretch)
        #expect(result?.intent.coherenceGap == "intenseAnchorRestrainedWeather")
        #expect(result?.intent.palette.preferFoundationOverStatement == true)
    }
}
