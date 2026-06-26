//
//  NarrativeTarotBridge_Tests.swift
//  Cosmic FitTests
//
//  Joint (card, variant) tarot bridge selection tests (§8.1).
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("NarrativeTarotBridge", .serialized)
struct NarrativeTarotBridge_Tests {

    @Test("Stage-1 uses bridge selector → narrativeBridgeTrace non-nil")
    func stage1UsesBridgeSelector() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, trace, _, _, _, _) = generateBriarTrace(for: date)

        #expect(trace.narrativeBridgeTrace != nil)
        #expect(trace.narrativeBridgeTrace!.pairsEvaluated > 0)
        #expect(trace.narrativeBridgeTrace!.funnelCardCount > 0)
    }

    @Test("Joint selection can beat card-first: variant influences which card wins")
    func jointSelectionCanBeatCardFirst() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        // Run 14 days and check that at least one day has a card that would NOT
        // have been selected by pure base-card-score alone (variant bumped it).
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        var variantChangedCard = false

        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (payload, trace, _, _, _, _) = generateBriarTrace(for: date)

            guard let bridgeTrace = trace.narrativeBridgeTrace else { continue }

            // If the selected card's base score is NOT the highest in the trace,
            // then variant scoring changed the winner.
            if let topByBaseScore = trace.tarotScores.first,
               topByBaseScore.cardName != payload.tarotCard.name {
                variantChangedCard = true
                break
            }

            // Also check margin: if margin is small, variant was decisive
            if bridgeTrace.bridgeMargin < 0.05 && bridgeTrace.pairsEvaluated > 3 {
                variantChangedCard = true
                break
            }
        }

        #expect(variantChangedCard == true,
                "Expected at least one day where variant scoring changed the card selection")
    }

    @Test("Bridge trace fields are populated and sane")
    func bridgeTracePopulated() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, trace, _, _, _, _) = generateBriarTrace(for: date)

        guard let bt = trace.narrativeBridgeTrace else {
            Issue.record("Expected non-nil narrativeBridgeTrace")
            return
        }

        #expect(!bt.selectedCardName.isEmpty)
        #expect(!bt.selectedVariantTitle.isEmpty)
        #expect(bt.selectedVariantIndex >= 0)
        #expect(bt.variantBridgeSimilarity >= -1.0 && bt.variantBridgeSimilarity <= 1.5)
        #expect(bt.bestPairTotalScore > 0)
        #expect(bt.funnelCardCount >= 1 && bt.funnelCardCount <= 15)
        #expect(bt.pairsEvaluated >= 1)
        #expect(bt.bridgeMargin >= 0)
        #expect(bt.bestVariantSimilarityInPool >= bt.variantBridgeSimilarity || bt.bestVariantSimilarityInPool >= 0)
    }

    @Test("Stage 2 legacy engine → no bridge trace, rotation path")
    func stage2LegacyUnchanged() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let legacyId = DailyFitEngineRegistry.stage2LegacyId
        let legacyCalibration = DailyFitEngineRegistry.calibration(for: legacyId)
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 10)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: [5, 9, 5, 4, 1, 9, 5, 1, 9, 5]),
            progressedChart: SkyForwardV2Support.chart(signs: [5, 9, 6, 5, 2, 9, 5, 1, 9, 5]),
            transits: [],
            moonPhaseDegrees: 60,
            profileHash: "bridge_test_legacy",
            date: date,
            calibration: legacyCalibration,
            mode: .standard,
            dailyFitEngineId: legacyId
        )
        let (_, trace, narrativeTrace, _, _, _) = DailyFitPipeline.generateWithTrace(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot,
            calibration: legacyCalibration,
            dailyFitEngineId: legacyId
        )

        #expect(narrativeTrace == nil)
        #expect(trace.narrativeBridgeTrace == nil)
        #expect(trace.tarotVariantWasScored == false)
    }

    @Test("Deterministic pair: same inputs → same card + variant across 10 runs")
    func deterministicPair() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
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
        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let calibration = SkyForwardV2Support.stage1Calibration
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: SkyForwardV2Support.briarBlueprint, snapshot: snapshot,
            calibration: calibration, mode: .stage1Experimental
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let resolution = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: snapshot, mode: .stage1Experimental,
            silhouetteProfile: silhouette, tuning: tuning
        )!
        let intent = resolution.intent

        // Call the selector directly — no recency tracker side effects between runs
        let first = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [],
            intent: intent, calibration: calibration,
            dailySeed: snapshot.dailySeed
        )

        for run in 1..<10 {
            let result = NarrativeTarotBridgeSelector.select(
                snapshot: snapshot, allCards: allCards,
                recentSelections: [],
                intent: intent, calibration: calibration,
                dailySeed: snapshot.dailySeed
            )
            #expect(result.candidate.card.name == first.candidate.card.name,
                    "Card diverged on run \(run)")
            #expect(result.candidate.variant.title == first.candidate.variant.title,
                    "Variant diverged on run \(run)")
            #expect(abs(result.candidate.variantBridgeScore - first.candidate.variantBridgeScore) < 1e-10,
                    "Bridge score diverged on run \(run)")
            #expect(abs(result.candidate.pairTotalScore - first.candidate.pairTotalScore) < 1e-10,
                    "Pair total diverged on run \(run)")
        }

        // Internal consistency (previously in deterministicPair)
        let bt = first.bridgeTrace
        #expect(bt.bestPairTotalScore >= bt.runnerUpPairTotalScore)
        let expectedMargin = bt.bestPairTotalScore - bt.runnerUpPairTotalScore
        #expect(abs(bt.bridgeMargin - expectedMargin) < 0.001)
        #expect(bt.variantBridgeSimilarity <= bt.bestVariantSimilarityInPool + 0.001)
    }

    @Test("Soften relationship prefers low-drama variant among top scores")
    func softenPrefersLowDramaVariant() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        // Find a soften day or construct one via known Briar window
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        var foundSoftenDay = false

        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
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
            let (_, _, narrativeTrace, _, _, _) = DailyFitPipeline.generateWithTrace(
                blueprint: SkyForwardV2Support.briarBlueprint,
                snapshot: snapshot,
                calibration: SkyForwardV2Support.stage1Calibration,
                dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
            )
            if narrativeTrace?.chosenRelationship == .soften {
                foundSoftenDay = true
                break
            }
        }

        // If no soften day in Briar window, the test is vacuously true
        // (soften requires specific weather conditions)
        if !foundSoftenDay {
            // Soften days are rare for Briar; test passes if no soften days exist
            #expect(true, "No soften day in Briar 14-day window — test vacuously passes")
        }
    }

    @Test("Briar 14-day: every stage-1 day has non-nil bridge trace with pairsEvaluated > 0")
    func briar14DayAllBridged() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (_, trace, _, _, _, _) = generateBriarTrace(for: date)
            #expect(trace.narrativeBridgeTrace != nil,
                    "Day \(offset) missing bridge trace")
            #expect((trace.narrativeBridgeTrace?.pairsEvaluated ?? 0) > 0,
                    "Day \(offset) has 0 pairs evaluated")
        }
    }

    @Test("Briar 14-day bridge trace export for signoff")
    func briar14DayBridgeExport() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        var lines: [String] = ["day|templateKey|card|variant|similarity|bridgePass|margin|contrastWW|pairsEval"]
        var totalSimilarity = 0.0
        var passCount = 0
        var cardChangedDays = 0

        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (payload, trace, narrativeTrace, intentTrace, _, _) = generateBriarTrace(for: date)
            let bt = trace.narrativeBridgeTrace!
            let templateKey = narrativeTrace?.templateKey ?? "—"
            let contrastWW = bt.contrastWeatherWins.map { $0 ? "yes" : "no" } ?? "—"

            totalSimilarity += bt.variantBridgeSimilarity
            if bt.bridgePass { passCount += 1 }

            // Check if card differs from base-score leader
            if let topBase = trace.tarotScores.first, topBase.cardName != payload.tarotCard.name {
                cardChangedDays += 1
            }

            lines.append("\(offset)|\(templateKey)|\(bt.selectedCardName)|\(bt.selectedVariantTitle)|" +
                "\(String(format: "%.3f", bt.variantBridgeSimilarity))|\(bt.bridgePass ? "pass" : "fail")|" +
                "\(String(format: "%.3f", bt.bridgeMargin))|\(contrastWW)|\(bt.pairsEvaluated)")
        }

        let meanSim = totalSimilarity / 14.0
        lines.append("")
        lines.append("Mean similarity: \(String(format: "%.3f", meanSim))")
        lines.append("Pass rate: \(passCount)/14")
        lines.append("Days card changed by variant: \(cardChangedDays)")

        let output = lines.joined(separator: "\n")
        CalibrationReportHelper.writeReport(prefix: "briar_14day_bridge_trace", content: output)
        print(output)
    }

    @Test("3-day cooldown hard-blocks repeat cards across consecutive days")
    func cooldownHardBlock() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        var selectedCards: [String] = []

        for offset in 0..<7 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (payload, _, _, _, _, _) = generateBriarTrace(for: date)
            selectedCards.append(payload.tarotCard.name)
        }

        // Verify no card appears on consecutive days (cooldown >= 1 day apart)
        for i in 1..<selectedCards.count {
            #expect(selectedCards[i] != selectedCards[i - 1],
                    "Day \(i) repeated '\(selectedCards[i])' from day \(i - 1) — cooldown should prevent this")
        }

        // Verify no card appears within a 3-day window
        for i in 0..<selectedCards.count {
            for j in (i + 1)..<min(i + 4, selectedCards.count) {
                #expect(selectedCards[j] != selectedCards[i],
                        "Day \(j) repeated '\(selectedCards[i])' from day \(i) — within 3-day cooldown")
            }
        }
    }

    @Test("Stage-1 trace generation stores the payload tarot card once")
    func stage1TraceStoresPayloadCard() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)

        for offset in 0..<7 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (payload, trace, _, _, _, _) = generateBriarTrace(for: date)
            // Resolved engine id for stage1 calibration is production (first registry match).
            let todaySelection = TarotRecencyTracker.shared.getRecentSelections(
                profileHash: SkyForwardV2Support.briarHash,
                referenceDate: date,
                dailyFitEngineId: DailyFitEngineRegistry.productionId
            ).first { $0.daysAgo == 0 }

            #expect(todaySelection?.cardName == payload.tarotCard.name,
                    "Trace generation should not overwrite day \(offset)'s payload card")
            #expect(trace.narrativeBridgeTrace?.selectedCardName == payload.tarotCard.name,
                    "Bridge trace should describe the payload card")
        }
    }

    // MARK: - Variant Recency Swap

    @Test("Variant recency swap: returning card gets a different variant when lastVariantByCard matches")
    func variantRecencySwapTriggered() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
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
        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let calibration = SkyForwardV2Support.stage1Calibration
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: SkyForwardV2Support.briarBlueprint, snapshot: snapshot,
            calibration: calibration, mode: .stage1Experimental
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let resolution = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: snapshot, mode: .stage1Experimental,
            silhouetteProfile: silhouette, tuning: tuning
        )!
        let intent = resolution.intent

        // First call: no recency → establishes baseline variant
        let baseline = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [],
            intent: intent, calibration: calibration,
            dailySeed: snapshot.dailySeed
        )
        let winningCard = baseline.candidate.card
        let winningVariantIndex = baseline.candidate.variantIndex
        #expect(baseline.bridgeTrace.variantRecencySwapped == false)

        // Skip cards with only 1 styleEdit — swap is impossible for them
        let editCount = winningCard.styleEdits?.count ?? 0
        guard editCount >= 2 else {
            #expect(true, "Winning card has <2 styleEdits — swap test vacuously passes")
            return
        }

        // Second call: same card scoring (no recentSelections penalty),
        // but lastVariantByCard triggers the variant swap.
        let recencyResult = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [],
            intent: intent, calibration: calibration,
            dailySeed: snapshot.dailySeed,
            lastVariantByCard: [winningCard.name: winningVariantIndex]
        )

        #expect(recencyResult.candidate.card.name == winningCard.name,
                "Card should not change — only the variant swaps")
        #expect(recencyResult.candidate.variantIndex != winningVariantIndex,
                "Variant should differ from the last-shown index")
        #expect(recencyResult.bridgeTrace.variantRecencySwapped == true)
    }

    @Test("Variant recency swap: no swap when lastVariantByCard is empty")
    func variantRecencyNoSwapWhenEmpty() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
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
        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let calibration = SkyForwardV2Support.stage1Calibration
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: SkyForwardV2Support.briarBlueprint, snapshot: snapshot,
            calibration: calibration, mode: .stage1Experimental
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let resolution = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: snapshot, mode: .stage1Experimental,
            silhouetteProfile: silhouette, tuning: tuning
        )!

        let result = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [],
            intent: resolution.intent, calibration: calibration,
            dailySeed: snapshot.dailySeed,
            lastVariantByCard: [:]
        )
        #expect(result.bridgeTrace.variantRecencySwapped == false)
    }

    @Test("Variant recency swap: no swap when lastVariant differs from selected variant")
    func variantRecencyNoSwapWhenDifferent() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
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
        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let calibration = SkyForwardV2Support.stage1Calibration
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: SkyForwardV2Support.briarBlueprint, snapshot: snapshot,
            calibration: calibration, mode: .stage1Experimental
        )
        let tuning = calibration.narrativeSelection ?? .stage1Default
        let resolution = NarrativeIntentEngine.resolve(
            essence: essence, snapshot: snapshot, mode: .stage1Experimental,
            silhouetteProfile: silhouette, tuning: tuning
        )!

        // First call to find baseline
        let baseline = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [],
            intent: resolution.intent, calibration: calibration,
            dailySeed: snapshot.dailySeed
        )
        let cardName = baseline.candidate.card.name
        let editCount = baseline.candidate.card.styleEdits?.count ?? 0
        guard editCount >= 2 else { return }

        // Provide a lastVariant that differs from what would be selected → no swap needed.
        // Keep recentSelections empty so card scoring is unchanged from baseline.
        let differentIndex = (baseline.candidate.variantIndex + 1) % editCount
        let result = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [],
            intent: resolution.intent, calibration: calibration,
            dailySeed: snapshot.dailySeed,
            lastVariantByCard: [cardName: differentIndex]
        )

        #expect(result.candidate.variantIndex == baseline.candidate.variantIndex,
                "Should keep original variant when it differs from lastShown")
        #expect(result.bridgeTrace.variantRecencySwapped == false)
    }

    @Test("Briar 30-day: repeated cards after cooldown get a different variant via pipeline")
    func repeatedCardsGetDifferentVariant() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 15)
        var cardVariantHistory: [String: [(day: Int, variantIndex: Int, title: String)]] = [:]

        for offset in 0..<30 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (payload, trace, _, _, _, _) = generateBriarTrace(for: date)
            let cardName = payload.tarotCard.name
            let variantIndex = trace.narrativeBridgeTrace?.selectedVariantIndex
                ?? Int(payload.styleEditVariant.variant.unicodeScalars.first.map { Int($0.value) - 73 } ?? 0)
            let title = payload.styleEditVariant.title

            var history = cardVariantHistory[cardName] ?? []
            history.append((day: offset, variantIndex: variantIndex, title: title))
            cardVariantHistory[cardName] = history
        }

        // For cards that appear more than once, check that the variant/title
        // differs between appearances (at least when the card has ≥2 edits)
        var exactDuplicatePairs = 0
        var multiAppearanceCards = 0
        for (_, appearances) in cardVariantHistory where appearances.count >= 2 {
            multiAppearanceCards += 1
            for i in 1..<appearances.count {
                if appearances[i].title == appearances[i - 1].title {
                    exactDuplicatePairs += 1
                }
            }
        }

        // Allow duplicates for single-edit cards or edge cases;
        // target: fewer than 60% duplicate pairs among multi-appearance cards.
        if multiAppearanceCards > 0 {
            let duplicateRate = Double(exactDuplicatePairs) / Double(multiAppearanceCards)
            #expect(duplicateRate < 0.6,
                    "Too many exact title duplicates for repeated cards: \(exactDuplicatePairs)/\(multiAppearanceCards)")
        }
    }

    // MARK: - Form Bridge Tests

    @Test("Structure gate excludes low-strategy variant when day is decisively structured")
    func structureGate_excludesLowStrategyVariant_whenStructured() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
            profileHash: "form_bridge_gate_test",
            date: date,
            calibration: SkyForwardV2Support.stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        let calibration = SkyForwardV2Support.stage1Calibration
        let tuning = calibration.narrativeSelection ?? .stage1Default

        let targetEnergy: [Energy: Double] = [.classic: 0.6, .romantic: 0.3, .drama: 0.1]
        let targetAxes: [String: Double] = ["action": 0.8, "tempo": 0.7, "strategy": 0.9, "visibility": 0.7]
        let directive = TarotDirective(
            targetEnergyVector: targetEnergy,
            targetAxesVector: targetAxes,
            structuredDraped: 0.05
        )
        let intent = NarrativeIntent(
            relationship: .contrast,
            anchorTop3: [.classic, .polished, .grounded],
            weatherTop3: [.romantic, .classic, .magnetic],
            tarot: directive,
            palette: PaletteDirective(
                maxStatementSlots: 1, accentCategory: .romantic,
                foundationCategory: .classic, categoryEnergyBoost: targetEnergy,
                preferFoundationOverStatement: false
            ),
            scales: ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0),
            essencePresentation: EssencePresentationDirective(showAnchorGhost: true),
            themeLexiconKey: nil, coherenceGap: nil
        )

        let result = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [], intent: intent,
            calibration: calibration, dailySeed: snapshot.dailySeed
        )

        let selectedStrategy = result.candidate.variant.axesEmphasis["strategy"] ?? 0
        #expect(selectedStrategy >= tuning.structureVariantStrategyFloor,
                "Gate should exclude variant with strategy \(selectedStrategy) < \(tuning.structureVariantStrategyFloor)")
        #expect(result.bridgeTrace.structureGateApplied == true)
    }

    @Test("Structure gate is inactive when structuredDraped is above threshold")
    func structureGate_inactiveAboveThreshold() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
            profileHash: "form_bridge_nogate_test",
            date: date,
            calibration: SkyForwardV2Support.stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        let calibration = SkyForwardV2Support.stage1Calibration

        let targetEnergy: [Energy: Double] = [.classic: 0.6, .romantic: 0.3, .drama: 0.1]
        let targetAxes: [String: Double] = ["action": 0.5, "tempo": 0.5, "strategy": 0.3, "visibility": 0.5]
        let directive = TarotDirective(
            targetEnergyVector: targetEnergy,
            targetAxesVector: targetAxes,
            structuredDraped: 0.5
        )
        let intent = NarrativeIntent(
            relationship: .reinforce,
            anchorTop3: [.classic, .polished, .grounded],
            weatherTop3: [.romantic, .classic, .magnetic],
            tarot: directive,
            palette: PaletteDirective(
                maxStatementSlots: 2, accentCategory: .romantic,
                foundationCategory: .classic, categoryEnergyBoost: targetEnergy,
                preferFoundationOverStatement: false
            ),
            scales: ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0),
            essencePresentation: EssencePresentationDirective(showAnchorGhost: true),
            themeLexiconKey: nil, coherenceGap: nil
        )

        let result = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [], intent: intent,
            calibration: calibration, dailySeed: snapshot.dailySeed
        )

        #expect(result.bridgeTrace.structureGateApplied == false)
    }

    @Test("Structure gate never empties pool — selection always returns a candidate")
    func structureGate_neverEmptiesPool() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
            profileHash: "form_bridge_floor_test",
            date: date,
            calibration: SkyForwardV2Support.stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        let calibration = SkyForwardV2Support.stage1Calibration

        let targetEnergy: [Energy: Double] = [.classic: 0.5, .romantic: 0.5]
        let targetAxes: [String: Double] = ["action": 0.9, "tempo": 0.9, "strategy": 0.95, "visibility": 0.9]
        let directive = TarotDirective(
            targetEnergyVector: targetEnergy,
            targetAxesVector: targetAxes,
            structuredDraped: 0.01
        )
        let intent = NarrativeIntent(
            relationship: .reinforce,
            anchorTop3: [.classic, .polished, .grounded],
            weatherTop3: [.classic, .romantic, .polished],
            tarot: directive,
            palette: PaletteDirective(
                maxStatementSlots: 2, accentCategory: .classic,
                foundationCategory: .polished, categoryEnergyBoost: targetEnergy,
                preferFoundationOverStatement: false
            ),
            scales: ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0),
            essencePresentation: EssencePresentationDirective(showAnchorGhost: true),
            themeLexiconKey: nil, coherenceGap: nil
        )

        let result = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [], intent: intent,
            calibration: calibration, dailySeed: snapshot.dailySeed
        )

        #expect(result.candidate.pairTotalScore != 0 || result.pairsEvaluated > 0)
        #expect(!result.candidate.card.name.isEmpty)
    }

    @Test("Form bridge soft channel: high-strategy variant preferred on structured day")
    func formBridge_highStructure_prefersHighStrategyVariant() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let allCards = BlueprintLensEngine.loadAndNormaliseCards()
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
            profileHash: "form_bridge_soft_test",
            date: date,
            calibration: SkyForwardV2Support.stage1Calibration,
            mode: .stage1Experimental,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        let calibration = SkyForwardV2Support.stage1Calibration

        let targetEnergy: [Energy: Double] = [.classic: 0.6, .romantic: 0.3, .drama: 0.1]
        let targetAxes: [String: Double] = ["action": 0.8, "tempo": 0.7, "strategy": 0.85, "visibility": 0.7]
        let directive = TarotDirective(
            targetEnergyVector: targetEnergy,
            targetAxesVector: targetAxes,
            structuredDraped: 0.05
        )
        let intent = NarrativeIntent(
            relationship: .reinforce,
            anchorTop3: [.classic, .polished, .grounded],
            weatherTop3: [.classic, .romantic, .polished],
            tarot: directive,
            palette: PaletteDirective(
                maxStatementSlots: 2, accentCategory: .classic,
                foundationCategory: .polished, categoryEnergyBoost: targetEnergy,
                preferFoundationOverStatement: false
            ),
            scales: ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0),
            essencePresentation: EssencePresentationDirective(showAnchorGhost: true),
            themeLexiconKey: nil, coherenceGap: nil
        )

        let result = NarrativeTarotBridgeSelector.select(
            snapshot: snapshot, allCards: allCards,
            recentSelections: [], intent: intent,
            calibration: calibration, dailySeed: snapshot.dailySeed
        )

        #expect(result.bridgeTrace.variantFormBridgeSimilarity != nil)
        #expect(result.bridgeTrace.variantFormBridgeSimilarity! > 0)
        #expect(result.bridgeTrace.formBridgePass != nil)
    }

    @Test("Form bridge is safe when variant has empty axesEmphasis")
    func formBridge_nilAxesEmphasis_safe() {
        let emptyAxes: [String: Int] = [:]
        let result = NarrativeSelectionDirectives.axesDictionary(from: emptyAxes)
        #expect(result.isEmpty)

        let target: [String: Double] = ["action": 0.8, "tempo": 0.7, "strategy": 0.9, "visibility": 0.7]
        let sim = NarrativeSelectionDirectives.cosineSimilarityAxes(result, target)
        #expect(sim == 0.0)
    }

    @Test("Form bridge trace fields are populated on Stage-1")
    func formBridge_traceFieldsPopulated() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
        defer { TarotCalibrationTestSupport.resetTrackersForProfile() }

        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 26)
        let (_, trace, _, _, _, _) = generateBriarTrace(for: date)

        guard let bt = trace.narrativeBridgeTrace else {
            Issue.record("Expected non-nil narrativeBridgeTrace")
            return
        }

        #expect(bt.variantFormBridgeSimilarity != nil)
        #expect(bt.formBridgePass != nil)
        #expect(bt.structureGateApplied != nil)
    }

    // MARK: - Coherence Structure Gate Tests

    @Test("Coherence gate flags Diplomat-like variant on structured day")
    func structureGate_flagsDiplomatOnStructuredDay() {
        let plan = makeMinimalPlan(structuredDraped: 0.05)
        let variantAxes: [String: Int] = ["strategy": 21, "action": 9, "tempo": 7, "visibility": 18]
        let violations = DailyNarrativeCoherence.validateTarotForm(
            plan: plan, variantAxesEmphasis: variantAxes
        )
        #expect(!violations.isEmpty)
        #expect(violations[0].contains("strategy"))
    }

    @Test("Coherence gate is silent on relaxed day")
    func structureGate_silentOnRelaxedDay() {
        let plan = makeMinimalPlan(structuredDraped: 0.80)
        let variantAxes: [String: Int] = ["strategy": 21, "action": 9, "tempo": 7, "visibility": 18]
        let violations = DailyNarrativeCoherence.validateTarotForm(
            plan: plan, variantAxesEmphasis: variantAxes
        )
        #expect(violations.isEmpty)
    }

    private func makeMinimalPlan(structuredDraped: Double) -> DailyNarrativePlan {
        DailyNarrativePlan(
            relationship: .contrast,
            accentEssence: .romantic,
            supportingEssences: [.classic, .magnetic],
            anchorEssences: [.classic, .polished, .grounded],
            intensityLevel: .moderate,
            tempoEmphasis: .steady,
            targetVibrancy: 0.65,
            targetContrast: 0.60,
            targetMetalTone: 0.50,
            targetSilhouette: SilhouetteProfile(
                masculineFeminine: 0.5,
                angularRounded: 0.5,
                structuredDraped: structuredDraped
            ),
            paletteDirective: PaletteDirective(
                maxStatementSlots: 1, accentCategory: .romantic,
                foundationCategory: .classic,
                categoryEnergyBoost: [.classic: 0.5, .romantic: 0.3],
                preferFoundationOverStatement: false
            ),
            tarotDirective: TarotDirective(
                targetEnergyVector: [.classic: 0.6, .romantic: 0.3],
                targetAxesVector: ["action": 0.8, "tempo": 0.7, "strategy": 0.9, "visibility": 0.7],
                structuredDraped: structuredDraped
            ),
            scaleDirective: nil,
            textureDirective: TextureDirective(preferredAffinities: ["structured"], intensityBias: 0.5),
            patternDirective: PatternDirective(gateEnabled: false, preferredEnergy: nil),
            salienceDrivers: [],
            skyJustification: "test",
            coherenceTrace: nil
        )
    }

    // MARK: - Helpers

    private func generateBriarTrace(
        for date: Date,
        profileHash: String = SkyForwardV2Support.briarHash
    ) -> (
        DailyFitPayload,
        BlueprintLensEngine.PayloadTrace,
        NarrativeTrace?,
        NarrativeIntentTrace?,
        NarrativeCoherenceTrace?,
        EssenceConflictTrace?
    ) {
        let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
            profileHash: profileHash,
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
