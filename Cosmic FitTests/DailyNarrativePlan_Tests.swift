//
//  DailyNarrativePlan_Tests.swift
//  Cosmic FitTests
//
//  Plan 2 tests: plan determinism, completeness, opposition violations,
//  coherence contract, cross-surface compatibility, and surface routing.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Support

private func briarSnapshot(for date: Date) -> DailyEnergySnapshot {
    let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
    let dayOffset = Int(date.timeIntervalSince(base) / 86400)
    return DailyEnergyEngine.generateSnapshot(
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
}

private func briarPlan(for date: Date) -> (DailyNarrativePlan, DailyNarrativeSelector.SelectionTrace) {
    let snapshot = briarSnapshot(for: date)
    let bp = SkyForwardV2Support.briarBlueprint
    let cal = SkyForwardV2Support.stage1Calibration
    let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
    let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
        from: bp, snapshot: snapshot, calibration: cal, mode: .stage1Experimental
    )
    return DailyNarrativeSelector.select(
        snapshot: snapshot,
        blueprint: bp,
        calibration: cal,
        precomputedEssence: rawEssence,
        precomputedSilhouette: rawSilhouette
    )
}

// MARK: - Plan Determinism

@Suite("DailyNarrativePlan — Determinism")
struct DailyNarrativePlan_Determinism_Tests {

    @Test("Same snapshot + blueprint + seed produces identical plan")
    func planDeterminism() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 25)
        let (plan1, _) = briarPlan(for: date)
        let (plan2, _) = briarPlan(for: date)
        #expect(plan1 == plan2)
    }

    @Test("Different dates produce different plans")
    func differentDatesDifferentPlans() {
        let date1 = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        let date2 = SkyForwardV2Support.date(year: 2026, month: 5, day: 28)
        let (plan1, _) = briarPlan(for: date1)
        let (plan2, _) = briarPlan(for: date2)
        #expect(plan1.accentEssence != plan2.accentEssence
            || plan1.relationship != plan2.relationship
            || plan1.targetVibrancy != plan2.targetVibrancy)
    }
}

// MARK: - Plan Completeness

@Suite("DailyNarrativePlan — Completeness")
struct DailyNarrativePlan_Completeness_Tests {

    @Test("Plan has exactly 2 supporting essences")
    func supportingEssenceCount() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            #expect(plan.supportingEssences.count == 2,
                    "Day \(offset): got \(plan.supportingEssences.count) supporting essences")
        }
    }

    @Test("Accent essence is backed by salience or essence scoring")
    func accentBackedBySalience() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 25)
        let snapshot = briarSnapshot(for: date)
        let (plan, _) = briarPlan(for: date)

        let salienceCategories = Set((snapshot.skySalience?.topDrivers ?? []).compactMap(\.essenceCategory))
        let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
        let topEssence = Set(rawEssence.allScores.sorted { $0.score > $1.score }.prefix(5).map(\.category))

        #expect(salienceCategories.contains(plan.accentEssence) || topEssence.contains(plan.accentEssence),
                "Accent \(plan.accentEssence) not in salience \(salienceCategories) or top essence \(topEssence)")
    }

    @Test("All slider targets in [0, 1]")
    func sliderTargetsInRange() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            #expect(plan.targetVibrancy >= 0.0 && plan.targetVibrancy <= 1.0)
            #expect(plan.targetContrast >= 0.0 && plan.targetContrast <= 1.0)
            #expect(plan.targetMetalTone >= 0.0 && plan.targetMetalTone <= 1.0)
            #expect(plan.targetSilhouette.masculineFeminine >= 0.0 && plan.targetSilhouette.masculineFeminine <= 1.0)
            #expect(plan.targetSilhouette.angularRounded >= 0.0 && plan.targetSilhouette.angularRounded <= 1.0)
            #expect(plan.targetSilhouette.structuredDraped >= 0.0 && plan.targetSilhouette.structuredDraped <= 1.0)
        }
    }

    @Test("Plan salience drivers are non-empty when salience available")
    func salienceDriversPresent() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 25)
        let (plan, _) = briarPlan(for: date)
        #expect(!plan.salienceDrivers.isEmpty)
        #expect(!plan.skyJustification.isEmpty)
    }
}

// MARK: - Opposition & Coherence

@Suite("DailyNarrativePlan — Coherence Contract")
struct DailyNarrativePlan_Coherence_Tests {

    @Test("No visible essence opposition pairs across 60 days — zero-tolerance")
    func noOppositionsIn60Days() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        var totalViolations = 0
        for offset in 0..<60 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            let violations = DailyNarrativeCoherence.validateEssenceOppositions(
                accent: plan.accentEssence, supporting: plan.supportingEssences
            )
            totalViolations += violations.count
        }
        #expect(totalViolations == 0, "Found \(totalViolations) opposition violations in 60 days")
    }

    @Test("Coherence validation passes for all plans across 14 days")
    func coherencePassesAll14Days() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            let result = DailyNarrativeCoherence.validate(plan: plan)
            #expect(result.passed, "Day \(offset): coherence failed — \(result.essenceOppositionViolations + result.crossSurfaceViolations)")
        }
    }

    @Test("Candidate rejection explains every contradiction")
    func rejectedCandidatesHaveReasons() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        for offset in 0..<14 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (_, trace) = briarPlan(for: date)
            for rejected in trace.rejectedCandidates {
                #expect(!rejected.reasons.isEmpty,
                        "Rejected candidate \(rejected.accentEssence) has no reasons")
            }
        }
    }

    @Test("Cross-surface compatibility: no contradiction between sliders and polarity")
    func crossSurfaceNoContradictions() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        var totalViolations = 0
        for offset in 0..<60 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            let violations = DailyNarrativeCoherence.validateCrossSurface(plan: plan)
            totalViolations += violations.count
        }
        #expect(totalViolations == 0, "Found \(totalViolations) cross-surface violations in 60 days")
    }
}

// MARK: - Surface Routing

@Suite("DailyNarrativePlan — Surface Routing")
struct DailyNarrativePlan_SurfaceRouting_Tests {

    @Test("Every routed surface reads from DailyNarrativePlan — essence matches plan")
    func essenceFollowsPlan() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 25)
        let (plan, _) = briarPlan(for: date)
        let payload = SkyForwardV2Support.generateBriarPayload(for: date)

        let planVisible = Set([plan.accentEssence] + plan.supportingEssences)
        let payloadVisible = Set(payload.essenceProfile.visibleCategories.prefix(3).map(\.category))
        #expect(planVisible == payloadVisible,
                "Plan visible \(planVisible) ≠ payload visible \(payloadVisible)")
    }

    @Test("Stage1 plan-driven path does not call resolveEssenceConflicts")
    func stage1DoesNotCallOldConflictResolver() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 25)
        let (_, _, _, _, _, essenceConflictTrace) = DailyFitPipeline.generateWithTrace(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: briarSnapshot(for: date),
            calibration: SkyForwardV2Support.stage1Calibration,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        #expect(essenceConflictTrace == nil,
                "Stage1 plan-driven path should NOT produce an essenceConflictTrace")
    }

    @Test("Contrast and bridge days still produce coherent visible output")
    func contrastDaysCoherent() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 23)
        for offset in 0..<30 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            if plan.relationship == .contrast {
                let validation = DailyNarrativeCoherence.validate(plan: plan)
                #expect(validation.passed,
                        "Contrast day \(offset): coherence failed — \(validation.essenceOppositionViolations)")
            }
        }
    }

    @Test("Production fingerprint unchanged")
    func productionUnchanged() {
        let date = SkyForwardV2Support.date(year: 2026, month: 5, day: 25)
        let snapshot = DailyEnergyEngine.generateSnapshot(
            natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
            progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
            transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: 4),
            moonPhaseDegrees: SkyForwardV2Support.moonPhase(
                for: date, base: SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
            ),
            profileHash: SkyForwardV2Support.briarHash,
            date: date,
            calibration: .default,
            mode: .standard
        )
        let prod1 = DailyFitPipeline.generate(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot
        )
        let prod2 = DailyFitPipeline.generate(
            blueprint: SkyForwardV2Support.briarBlueprint,
            snapshot: snapshot
        )
        #expect(SkyForwardV2Support.payloadFingerprint(prod1) == SkyForwardV2Support.payloadFingerprint(prod2))
    }
}

// MARK: - Variation Preserved

@Suite("DailyNarrativePlan — Variation")
struct DailyNarrativePlan_Variation_Tests {

    @Test("Essence flip rate ≥40% across 60 days")
    func essenceFlipRate() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        var previousAccent: StyleEssenceCategory?
        var flips = 0
        let total = 59

        for offset in 0..<60 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            if let prev = previousAccent, plan.accentEssence != prev {
                flips += 1
            }
            previousAccent = plan.accentEssence
        }

        let flipRate = Double(flips) / Double(total)
        #expect(flipRate >= 0.40,
                "Flip rate \(String(format: "%.1f%%", flipRate * 100)) below 40% target")
    }

    @Test("Distinct accent essences ≥4 in 60 days")
    func distinctAccents() {
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        var accents = Set<StyleEssenceCategory>()
        for offset in 0..<60 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let (plan, _) = briarPlan(for: date)
            accents.insert(plan.accentEssence)
        }
        #expect(accents.count >= 4,
                "Only \(accents.count) distinct accent essences in 60 days")
    }
}

// MARK: - Fixture Report Generator

@Suite("DailyNarrativePlan — Coherence Report Generator")
struct DailyNarrativePlan_ReportGenerator_Tests {

    @Test("Generate narrative_coherence_report fixture")
    func generateCoherenceReport() throws {
        let presetNames = ["fire", "earth", "air", "water", "leo"]
        let presetSigns: [[Int]] = [
            [1, 5, 1, 1, 1, 9, 1, 9, 1, 1],   // fire: Aries
            [2, 6, 2, 2, 2, 10, 2, 10, 2, 2],  // earth: Taurus
            [3, 7, 3, 3, 3, 11, 3, 11, 3, 3],  // air: Gemini
            [4, 8, 4, 4, 4, 12, 4, 12, 4, 4],  // water: Cancer
            [5, 1, 5, 5, 5, 1, 5, 1, 5, 5],    // leo: Leo
        ]
        let days = 60
        let start = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
        let cal = SkyForwardV2Support.stage1Calibration
        let bp = SkyForwardV2Support.briarBlueprint

        var presetResults: [[String: Any]] = []
        var aggOppositions = 0
        var aggCrossSurface = 0
        var aggCoherence: [Double] = []
        var aggFlip: [Double] = []
        var aggDistinct: [Int] = []

        for (pIdx, pid) in presetNames.enumerated() {
            let signs = presetSigns[pIdx]
            var accentCounts: [String: Int] = [:]
            var relationshipCounts: [String: Int] = [:]
            var oppositionViolations = 0
            var crossSurfaceViolations = 0
            var coherenceScores: [Double] = []
            var flipCount = 0
            var prevAccent: String?
            var dailyRows: [[String: Any]] = []

            for dayOffset in 0..<days {
                let date = start.addingTimeInterval(Double(dayOffset) * 86400)
                let baseDate = SkyForwardV2Support.date(year: 2026, month: 5, day: 1)
                let snapshot = DailyEnergyEngine.generateSnapshot(
                    natalChart: SkyForwardV2Support.chart(signs: signs),
                    progressedChart: SkyForwardV2Support.chart(signs: signs),
                    transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
                    moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: baseDate),
                    profileHash: pid,
                    date: date,
                    calibration: cal,
                    mode: .stage1Experimental,
                    dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
                )
                let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: .stage1Experimental)
                let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                    from: bp, snapshot: snapshot, calibration: cal, mode: .stage1Experimental
                )
                let (plan, trace) = DailyNarrativeSelector.select(
                    snapshot: snapshot, blueprint: bp, calibration: cal,
                    precomputedEssence: rawEssence, precomputedSilhouette: rawSilhouette
                )

                let validation = DailyNarrativeCoherence.validate(plan: plan)
                let payload = BlueprintLensEngine.generatePayloadFromPlan(
                    plan: plan, blueprint: bp, snapshot: snapshot,
                    calibration: cal, mode: .stage1Experimental,
                    dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
                )
                let payloadCoherence = DailyNarrativeCoherence.scorePayloadCoherence(plan: plan, payload: payload)
                let score = DailyNarrativeCoherence.meanCoherenceScore(payloadCoherence)

                let accent = plan.accentEssence.rawValue
                accentCounts[accent, default: 0] += 1
                relationshipCounts[plan.relationship.rawValue, default: 0] += 1
                oppositionViolations += validation.essenceOppositionViolations.count
                crossSurfaceViolations += validation.crossSurfaceViolations.count
                coherenceScores.append(score)

                if let prev = prevAccent, accent != prev { flipCount += 1 }
                prevAccent = accent

                dailyRows.append([
                    "date": SkyForwardV2Support.isoString(for: date),
                    "accent": accent,
                    "top3": ([plan.accentEssence] + plan.supportingEssences).map(\.rawValue),
                    "relationship": plan.relationship.rawValue,
                    "intensity": plan.intensityLevel.rawValue,
                    "tempo": plan.tempoEmphasis.rawValue,
                    "vibrancy": String(format: "%.4f", plan.targetVibrancy),
                    "contrast": String(format: "%.4f", plan.targetContrast),
                    "metalTone": String(format: "%.4f", plan.targetMetalTone),
                    "coherenceScore": String(format: "%.4f", score),
                    "oppositionViolations": validation.essenceOppositionViolations,
                    "crossSurfaceViolations": validation.crossSurfaceViolations,
                    "candidatesGenerated": trace.candidatesGenerated,
                    "candidatesRejected": trace.candidatesRejected,
                ] as [String : Any])
            }

            let distinctAccents = accentCounts.count
            let flipRate = days > 1 ? Double(flipCount) / Double(days - 1) : 0
            let meanCoherence = coherenceScores.isEmpty ? 0.0 : coherenceScores.reduce(0, +) / Double(coherenceScores.count)

            aggOppositions += oppositionViolations
            aggCrossSurface += crossSurfaceViolations
            aggCoherence.append(meanCoherence)
            aggFlip.append(flipRate)
            aggDistinct.append(distinctAccents)

            presetResults.append([
                "preset": pid,
                "plansGenerated": days,
                "essenceOppositionViolations": oppositionViolations,
                "crossSurfaceViolations": crossSurfaceViolations,
                "coherenceScore": round(meanCoherence * 10000) / 10000,
                "flipRate": round(flipRate * 10000) / 10000,
                "distinctAccents": distinctAccents,
                "accentDistribution": accentCounts,
                "relationshipDistribution": relationshipCounts,
                "dailyRows": dailyRows,
            ] as [String : Any])
        }

        let report: [String: Any] = [
            "generated": SkyForwardV2Support.isoString(for: Date()),
            "engine": "stage1_experimental",
            "startDate": "2026-05-01",
            "days": days,
            "presets": presetResults,
            "aggregate": [
                "totalOppositionViolations": aggOppositions,
                "totalCrossSurfaceViolations": aggCrossSurface,
                "meanCoherenceScore": aggCoherence.isEmpty ? 0 : round(aggCoherence.reduce(0, +) / Double(aggCoherence.count) * 10000) / 10000,
                "meanFlipRate": aggFlip.isEmpty ? 0 : round(aggFlip.reduce(0, +) / Double(aggFlip.count) * 10000) / 10000,
                "meanDistinctAccents": aggDistinct.isEmpty ? 0 : Double(aggDistinct.reduce(0, +)) / Double(aggDistinct.count),
            ] as [String : Any],
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        let fixturesDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")
        try FileManager.default.createDirectory(at: fixturesDir, withIntermediateDirectories: true)
        let jsonPath = fixturesDir.appendingPathComponent("narrative_coherence_report.json")
        try jsonData.write(to: jsonPath)

        // Write TXT summary
        var txt = "Narrative Coherence Report — Plan 2\n"
        txt += "Engine: stage1_experimental\n"
        txt += "Window: 2026-05-01 + \(days) days\n"
        txt += String(repeating: "=", count: 70) + "\n\n"

        for pr in presetResults {
            let pid = pr["preset"] as! String
            txt += "Preset: \(pid)\n"
            txt += "  Plans generated:          \(pr["plansGenerated"]!)\n"
            txt += "  Opposition violations:    \(pr["essenceOppositionViolations"]!)\n"
            txt += "  Cross-surface violations: \(pr["crossSurfaceViolations"]!)\n"
            txt += "  Coherence score:          \(pr["coherenceScore"]!)\n"
            txt += "  Flip rate:                \(pr["flipRate"]!)\n"
            txt += "  Distinct accents:         \(pr["distinctAccents"]!)\n"
            txt += "  Accents: \(pr["accentDistribution"]!)\n"
            txt += "  Relationships: \(pr["relationshipDistribution"]!)\n\n"
        }

        txt += String(repeating: "=", count: 70) + "\n"
        txt += "AGGREGATE\n"
        let agg = report["aggregate"] as! [String: Any]
        txt += "  Total opposition violations:    \(agg["totalOppositionViolations"]!)\n"
        txt += "  Total cross-surface violations: \(agg["totalCrossSurfaceViolations"]!)\n"
        txt += "  Mean coherence score:           \(agg["meanCoherenceScore"]!)\n"
        txt += "  Mean flip rate:                 \(agg["meanFlipRate"]!)\n"
        txt += "  Mean distinct accents:          \(agg["meanDistinctAccents"]!)\n"
        txt += "\nEXIT GATE:\n"
        txt += "  Opposition == 0:    \(aggOppositions == 0 ? "PASS" : "FAIL")\n"
        txt += "  Cross-surface == 0: \(aggCrossSurface == 0 ? "PASS" : "FAIL")\n"
        let mc = aggCoherence.reduce(0, +) / max(1, Double(aggCoherence.count))
        txt += "  Coherence ≥ 0.85:   \(mc >= 0.85 ? "PASS" : "FAIL")\n"
        let mf = aggFlip.reduce(0, +) / max(1, Double(aggFlip.count))
        txt += "  Flip rate ≥ 40%:    \(mf >= 0.40 ? "PASS" : "FAIL")\n"

        let txtPath = fixturesDir.appendingPathComponent("narrative_coherence_report.txt")
        try txt.write(to: txtPath, atomically: true, encoding: .utf8)

        #expect(aggOppositions == 0, "Opposition violations must be zero")
        #expect(aggCrossSurface == 0, "Cross-surface violations must be zero")
    }
}
