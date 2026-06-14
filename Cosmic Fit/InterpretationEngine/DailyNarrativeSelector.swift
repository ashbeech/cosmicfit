//
//  DailyNarrativeSelector.swift
//  Cosmic Fit
//
//  Plan 2: Single narrative decision for the day.
//  Uses Plan 1 skySalience as primary sky input.
//  Builds candidate plans and rejects any that violate the coherence contract.
//

import Foundation

enum DailyNarrativeSelector {

    struct RejectedCandidate: Codable, Equatable {
        let accentEssence: String
        let supporting: [String]
        let reasons: [String]
    }

    struct SelectionTrace: Codable, Equatable {
        let candidatesGenerated: Int
        let candidatesRejected: Int
        let rejectedCandidates: [RejectedCandidate]
        let selectedAccent: String
        let selectedSupporting: [String]
        let relationship: String
        let intensityLevel: String
        let tempoEmphasis: String
        let visibleEssenceCooldownBlocked: [String]
    }

    // MARK: - Public API

    static func select(
        snapshot: DailyEnergySnapshot,
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        precomputedEssence: StyleEssenceProfile,
        precomputedSilhouette: SilhouetteProfile,
        dailyFitEngineId: String? = nil
    ) -> (plan: DailyNarrativePlan, trace: SelectionTrace) {
        let resolvedEngineId = dailyFitEngineId
            ?? DailyFitEngineRegistry.engineId(for: calibration, mode: .stage1Experimental)
        let salience = snapshot.skySalience
        let tuning = calibration.narrativeSelection ?? .stage1Default

        // 1. Classify relationship (preserve backward compat with NarrativeIntentEngine)
        let anchorTop3 = (precomputedEssence.chartAnchorScores ?? precomputedEssence.allScores)
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map(\.category)
        let weatherTop3 = precomputedEssence.visibleCategories
            .prefix(3)
            .map(\.category)
        let relationship = classifyRelationship(
            anchorTop3: Array(anchorTop3),
            weatherTop3: Array(weatherTop3),
            snapshot: snapshot,
            silhouette: precomputedSilhouette
        )

        // 2. Derive intensity from salience concentration
        let intensityLevel = deriveIntensity(salience: salience)

        // 3. Derive tempo from Moon's position
        let tempoEmphasis = deriveTempo(salience: salience, snapshot: snapshot)

        // 4. Visible essence cooldown — hard block categories from recent top-3
        let cooldown = VisibleEssenceRecencyTracker.shared.getCooldownCategories(
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt,
            dailyFitEngineId: resolvedEngineId,
            cooldownDayCount: tuning.visibleEssenceCooldownDays
        )
        let recentVisible = VisibleEssenceRecencyTracker.shared.getRecentVisibleEssences(
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt,
            dailyFitEngineId: resolvedEngineId,
            windowDays: tuning.visibleEssenceCooldownDays
        )
        var cooldownBlockedOut: [String] = []

        // 5. Identify sky top driver category (exempt from accent cooldown)
        let skyTopCategory: StyleEssenceCategory? = salience?.topDrivers.first?.essenceCategory

        // 6. Build candidate accent essences ranked by salience + scoring + recency
        let rankedAccents = rankAccentCandidates(
            salience: salience,
            essenceScores: precomputedEssence.allScores,
            dailySeed: snapshot.dailySeed,
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt,
            cooldown: cooldown,
            skyTopCategory: skyTopCategory,
            cooldownBlockedOut: &cooldownBlockedOut
        )

        // 7. For each accent candidate, try to build a valid plan
        var rejectedCandidates: [RejectedCandidate] = []
        var candidateCount = 0

        for accentCandidate in rankedAccents {
            let supporting = pickSupportingEssences(
                accent: accentCandidate,
                essenceScores: precomputedEssence.allScores,
                relationship: relationship,
                anchorTop3: Array(anchorTop3),
                dailySeed: snapshot.dailySeed,
                cooldown: cooldown,
                recentVisible: recentVisible,
                cooldownDayCount: tuning.visibleEssenceCooldownDays,
                cooldownBlockedOut: &cooldownBlockedOut
            )

            candidateCount += 1

            let candidatePlan = buildPlan(
                relationship: relationship,
                accent: accentCandidate,
                supporting: supporting,
                anchorEssences: Array(anchorTop3),
                intensityLevel: intensityLevel,
                tempoEmphasis: tempoEmphasis,
                snapshot: snapshot,
                blueprint: blueprint,
                calibration: calibration,
                salience: salience,
                precomputedSilhouette: precomputedSilhouette,
                tuning: tuning,
                weatherTop3: Array(weatherTop3)
            )

            let validation = DailyNarrativeCoherence.validate(plan: candidatePlan)

            if validation.passed {
                let planWithTrace = DailyNarrativePlan(
                    relationship: candidatePlan.relationship,
                    accentEssence: candidatePlan.accentEssence,
                    supportingEssences: candidatePlan.supportingEssences,
                    anchorEssences: candidatePlan.anchorEssences,
                    intensityLevel: candidatePlan.intensityLevel,
                    tempoEmphasis: candidatePlan.tempoEmphasis,
                    targetVibrancy: candidatePlan.targetVibrancy,
                    targetContrast: candidatePlan.targetContrast,
                    targetMetalTone: candidatePlan.targetMetalTone,
                    targetSilhouette: candidatePlan.targetSilhouette,
                    paletteDirective: candidatePlan.paletteDirective,
                    tarotDirective: candidatePlan.tarotDirective,
                    scaleDirective: candidatePlan.scaleDirective,
                    textureDirective: candidatePlan.textureDirective,
                    patternDirective: candidatePlan.patternDirective,
                    salienceDrivers: candidatePlan.salienceDrivers,
                    skyJustification: candidatePlan.skyJustification,
                    coherenceTrace: validation
                )

                AccentRecencyTracker.shared.storeAccent(
                    accentCandidate,
                    profileHash: snapshot.profileHash,
                    date: snapshot.generatedAt
                )
                VisibleEssenceRecencyTracker.shared.storeVisibleTop3(
                    [accentCandidate] + supporting,
                    profileHash: snapshot.profileHash,
                    date: snapshot.generatedAt,
                    dailyFitEngineId: resolvedEngineId
                )

                let trace = SelectionTrace(
                    candidatesGenerated: candidateCount,
                    candidatesRejected: rejectedCandidates.count,
                    rejectedCandidates: rejectedCandidates,
                    selectedAccent: accentCandidate.rawValue,
                    selectedSupporting: supporting.map(\.rawValue),
                    relationship: relationship.rawValue,
                    intensityLevel: intensityLevel.rawValue,
                    tempoEmphasis: tempoEmphasis.rawValue,
                    visibleEssenceCooldownBlocked: cooldownBlockedOut
                )

                return (planWithTrace, trace)
            } else {
                let allReasons = validation.essenceOppositionViolations + validation.crossSurfaceViolations
                rejectedCandidates.append(RejectedCandidate(
                    accentEssence: accentCandidate.rawValue,
                    supporting: supporting.map(\.rawValue),
                    reasons: allReasons
                ))
            }
        }

        // Fallback: all candidates rejected — try each accent with forced-safe supporting,
        // pick the first that passes coherence; fall through to first if none pass.
        let fallbackAccent = rankedAccents.first ?? .magnetic
        var chosenFallbackAccent = fallbackAccent
        for candidate in rankedAccents {
            let safeSupporting = forceSafeSupporting(
                accent: candidate,
                essenceScores: precomputedEssence.allScores
            )
            let testPlan = buildPlan(
                relationship: relationship,
                accent: candidate,
                supporting: safeSupporting,
                anchorEssences: Array(anchorTop3),
                intensityLevel: intensityLevel,
                tempoEmphasis: tempoEmphasis,
                snapshot: snapshot,
                blueprint: blueprint,
                calibration: calibration,
                salience: salience,
                precomputedSilhouette: precomputedSilhouette,
                tuning: tuning,
                weatherTop3: Array(weatherTop3)
            )
            let testValidation = DailyNarrativeCoherence.validate(plan: testPlan)
            if testValidation.passed {
                chosenFallbackAccent = candidate
                break
            }
        }
        AccentRecencyTracker.shared.storeAccent(
            chosenFallbackAccent, profileHash: snapshot.profileHash, date: snapshot.generatedAt
        )
        let fallbackSupporting = forceSafeSupporting(
            accent: chosenFallbackAccent,
            essenceScores: precomputedEssence.allScores
        )
        VisibleEssenceRecencyTracker.shared.storeVisibleTop3(
            [chosenFallbackAccent] + fallbackSupporting,
            profileHash: snapshot.profileHash,
            date: snapshot.generatedAt,
            dailyFitEngineId: resolvedEngineId
        )
        let fallbackPlan = buildPlan(
            relationship: relationship,
            accent: chosenFallbackAccent,
            supporting: fallbackSupporting,
            anchorEssences: Array(anchorTop3),
            intensityLevel: intensityLevel,
            tempoEmphasis: tempoEmphasis,
            snapshot: snapshot,
            blueprint: blueprint,
            calibration: calibration,
            salience: salience,
            precomputedSilhouette: precomputedSilhouette,
            tuning: tuning,
            weatherTop3: Array(weatherTop3)
        )
        let fallbackValidation = DailyNarrativeCoherence.validate(plan: fallbackPlan)
        let plan = DailyNarrativePlan(
            relationship: fallbackPlan.relationship,
            accentEssence: fallbackPlan.accentEssence,
            supportingEssences: fallbackPlan.supportingEssences,
            anchorEssences: fallbackPlan.anchorEssences,
            intensityLevel: fallbackPlan.intensityLevel,
            tempoEmphasis: fallbackPlan.tempoEmphasis,
            targetVibrancy: fallbackPlan.targetVibrancy,
            targetContrast: fallbackPlan.targetContrast,
            targetMetalTone: fallbackPlan.targetMetalTone,
            targetSilhouette: fallbackPlan.targetSilhouette,
            paletteDirective: fallbackPlan.paletteDirective,
            tarotDirective: fallbackPlan.tarotDirective,
            scaleDirective: fallbackPlan.scaleDirective,
            textureDirective: fallbackPlan.textureDirective,
            patternDirective: fallbackPlan.patternDirective,
            salienceDrivers: fallbackPlan.salienceDrivers,
            skyJustification: fallbackPlan.skyJustification,
            coherenceTrace: fallbackValidation
        )
        let trace = SelectionTrace(
            candidatesGenerated: candidateCount + 1,
            candidatesRejected: rejectedCandidates.count,
            rejectedCandidates: rejectedCandidates,
            selectedAccent: chosenFallbackAccent.rawValue,
            selectedSupporting: fallbackSupporting.map(\.rawValue),
            relationship: relationship.rawValue,
            intensityLevel: intensityLevel.rawValue,
            tempoEmphasis: tempoEmphasis.rawValue,
            visibleEssenceCooldownBlocked: cooldownBlockedOut
        )
        return (plan, trace)
    }

    // MARK: - Relationship Classification

    private static func classifyRelationship(
        anchorTop3: [StyleEssenceCategory],
        weatherTop3: [StyleEssenceCategory],
        snapshot: DailyEnergySnapshot,
        silhouette: SilhouetteProfile
    ) -> NarrativeRelationship {
        let anchorSet = Set(anchorTop3)
        let weatherSet = Set(weatherTop3)
        let overlapCount = anchorSet.intersection(weatherSet).count

        if anchorTop3.first == weatherTop3.first || overlapCount >= 2 {
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

        if overlapCount == 0,
           anchorTop2Set.isSubset(of: NarrativeSelectionDirectives.intenseBoldCategories),
           weatherTop2Set.isSubset(of: NarrativeSelectionDirectives.restrainedCategories) {
            return .stretch
        }

        if overlapCount >= 1,
           weatherTop2Set.isSubset(of: NarrativeSelectionDirectives.intenseBoldCategories),
           anchorTop2Set.isSubset(of: NarrativeSelectionDirectives.restrainedCategories) {
            let meanDelta = meanSilhouetteDelta(silhouette)
            if meanDelta > 0.12 { return .stretch }
            if let chartVis = snapshot.chartAxes?.visibility {
                let visDelta = snapshot.axes.visibility - chartVis
                if visDelta > 1.0 { return .stretch }
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
        for (a, b) in essenceOppositions {
            if (anchorLeading.contains(a) && weatherLeading.contains(b)) ||
               (anchorLeading.contains(b) && weatherLeading.contains(a)) {
                return true
            }
        }
        return false
    }

    private static func meanSilhouetteDelta(_ sil: SilhouetteProfile) -> Double {
        let deltas = [
            sil.chartAnchorMF.map { abs(sil.masculineFeminine - $0) },
            sil.chartAnchorAR.map { abs(sil.angularRounded - $0) },
            sil.chartAnchorSD.map { abs(sil.structuredDraped - $0) }
        ].compactMap { $0 }
        guard !deltas.isEmpty else { return 0 }
        return deltas.reduce(0, +) / Double(deltas.count)
    }

    // MARK: - Intensity & Tempo

    private static func deriveIntensity(salience: SkySalienceProfile?) -> IntensityLevel {
        guard let top = salience?.topDrivers.first else { return .moderate }
        if top.salience > 0.8 {
            let orb = abs(1.0 - top.rawStrength)
            return orb < 0.5 ? .peak : .high
        }
        if top.salience > 0.6 { return .high }
        if top.salience > 0.3 { return .moderate }
        return .low
    }

    private static func deriveTempo(salience: SkySalienceProfile?, snapshot: DailyEnergySnapshot) -> TempoEmphasis {
        guard let entries = salience?.entries else { return .steady }
        let moonRank = entries.firstIndex(where: { $0.planet == "Moon" })
        if let rank = moonRank {
            if rank < 3 { return .dynamic }
            if rank < 5 { return .steady }
        }
        let phase = snapshot.lunarContext.phaseName.lowercased()
        if phase.contains("balsamic") || phase.contains("waning") {
            return .slow
        }
        return .steady
    }

    // MARK: - Accent Ranking

    /// Minimum recency multiplier for the sky's top salience driver.
    /// Full penalty (as low as 0.30) would let diversity machinery override
    /// the dominant transit signal; 0.80 keeps the top driver competitive
    /// while still allowing mild demotion.
    private static let skyTopRecencyFloor = 0.80

    private static func rankAccentCandidates(
        salience: SkySalienceProfile?,
        essenceScores: [StyleEssenceScore],
        dailySeed: Int,
        profileHash: String,
        referenceDate: Date,
        cooldown: Set<StyleEssenceCategory>,
        skyTopCategory: StyleEssenceCategory?,
        cooldownBlockedOut: inout [String]
    ) -> [StyleEssenceCategory] {
        var candidates: [(StyleEssenceCategory, Double)] = []
        let scoreMap = Dictionary(uniqueKeysWithValues: essenceScores.map { ($0.category, $0.score) })

        if let drivers = salience?.topDrivers {
            for driver in drivers {
                if let cat = driver.essenceCategory {
                    let essenceScore = scoreMap[cat] ?? 0.0
                    let combined = driver.salience * 0.6 + essenceScore * 0.4
                    candidates.append((cat, combined))
                }
            }
        }

        let salienceCategories = Set(candidates.map(\.0))
        for score in essenceScores.sorted(by: { $0.score > $1.score }).prefix(5) {
            if !salienceCategories.contains(score.category) {
                candidates.append((score.category, score.score * 0.3))
            }
        }

        if candidates.isEmpty {
            candidates = essenceScores
                .sorted { $0.score > $1.score }
                .prefix(5)
                .map { ($0.category, $0.score) }
        }

        // Hard block: remove categories in visible-essence cooldown,
        // but exempt the sky's top salience driver — the accent slot
        // should reflect "what the sky is shouting today."
        let unfilteredCount = candidates.count
        candidates = candidates.filter { (cat, _) in
            if cat == skyTopCategory { return true }
            if cooldown.contains(cat) {
                cooldownBlockedOut.append("accent:\(cat.rawValue)")
                return false
            }
            return true
        }

        // Fallback: if cooldown removed all candidates, use unfiltered top-5
        if candidates.isEmpty {
            candidates = essenceScores
                .sorted { $0.score > $1.score }
                .prefix(5)
                .map { ($0.category, $0.score) }
            if unfilteredCount > 0 {
                cooldownBlockedOut.append("accent:fallback_pool_exhausted")
            }
        }

        // Accent recency penalty — demote recently-used #1 categories,
        // but floor the penalty for the sky top driver so transit signal
        // isn't drowned by diversity rotation.
        candidates = candidates.map { (cat, score) in
            var penalty = AccentRecencyTracker.shared.recencyPenalty(
                for: cat, profileHash: profileHash, referenceDate: referenceDate
            )
            if cat == skyTopCategory {
                penalty = max(penalty, skyTopRecencyFloor)
            }
            return (cat, score * penalty)
        }

        // Seeded tie-break for candidates within epsilon
        var rng = SeededRandomGenerator(seed: dailySeed &+ 31)
        candidates = candidates.map { ($0.0, $0.1 + Double.random(in: 0...0.001, using: &rng)) }
        candidates.sort { $0.1 > $1.1 }

        return candidates.map(\.0)
    }

    // MARK: - Supporting Essences

    private static func pickSupportingEssences(
        accent: StyleEssenceCategory,
        essenceScores: [StyleEssenceScore],
        relationship: NarrativeRelationship,
        anchorTop3: [StyleEssenceCategory],
        dailySeed: Int,
        cooldown: Set<StyleEssenceCategory>,
        recentVisible: [(category: StyleEssenceCategory, daysAgo: Int)],
        cooldownDayCount: Int,
        cooldownBlockedOut: inout [String]
    ) -> [StyleEssenceCategory] {
        let opposedToAccent = Set(essenceOppositions.flatMap { pair -> [StyleEssenceCategory] in
            if pair.0 == accent { return [pair.1] }
            if pair.1 == accent { return [pair.0] }
            return []
        })

        let ranked = essenceScores
            .sorted { $0.score > $1.score }
            .map(\.category)
            .filter { $0 != accent && !opposedToAccent.contains($0) }

        var selected: [StyleEssenceCategory] = []

        // Contrast anchor injection — EXEMPT from cooldown
        if relationship == .contrast, let anchorCat = anchorTop3.first,
           !opposedToAccent.contains(anchorCat), anchorCat != accent {
            selected.append(anchorCat)
        }

        // Attempt with full cooldown gate
        let result = fillSupporting(
            ranked: ranked,
            selected: &selected,
            accent: accent,
            cooldownFilter: cooldown,
            cooldownBlockedOut: &cooldownBlockedOut
        )

        if result { return Array(selected.prefix(2)) }

        // Progressive relaxation: re-admit oldest blocked day first
        if cooldownDayCount > 1 {
            let oldestBlocked = Set(
                recentVisible.filter { $0.daysAgo == cooldownDayCount }.map(\.category)
            )
            let relaxedCooldown = cooldown.subtracting(oldestBlocked)
            let relaxedResult = fillSupporting(
                ranked: ranked,
                selected: &selected,
                accent: accent,
                cooldownFilter: relaxedCooldown,
                cooldownBlockedOut: &cooldownBlockedOut
            )
            if relaxedResult { return Array(selected.prefix(2)) }
        }

        // Further relaxation: re-admit all except daysAgo == 1
        let yesterdayOnly = Set(
            recentVisible.filter { $0.daysAgo == 1 }.map(\.category)
        )
        if yesterdayOnly != cooldown {
            let _ = fillSupporting(
                ranked: ranked,
                selected: &selected,
                accent: accent,
                cooldownFilter: yesterdayOnly,
                cooldownBlockedOut: &cooldownBlockedOut
            )
            if selected.count >= 2 { return Array(selected.prefix(2)) }
        }

        // Final fallback: no gate at all
        if selected.count < 2 {
            for cat in StyleEssenceCategory.allCases where cat != accent && !selected.contains(cat) {
                if selected.count >= 2 { break }
                selected.append(cat)
            }
        }

        return Array(selected.prefix(2))
    }

    /// Fill supporting slots from ranked candidates, filtering by cooldown. Returns true when 2 slots filled.
    private static func fillSupporting(
        ranked: [StyleEssenceCategory],
        selected: inout [StyleEssenceCategory],
        accent: StyleEssenceCategory,
        cooldownFilter: Set<StyleEssenceCategory>,
        cooldownBlockedOut: inout [String]
    ) -> Bool {
        for cat in ranked {
            if selected.count >= 2 { break }
            if selected.contains(cat) { continue }
            if cooldownFilter.contains(cat) {
                cooldownBlockedOut.append("supporting:\(cat.rawValue)")
                continue
            }
            let conflictsWithSelected = selected.contains { existing in
                essenceOppositions.contains { ($0.0 == cat && $0.1 == existing) || ($0.1 == cat && $0.0 == existing) }
            }
            if conflictsWithSelected { continue }
            selected.append(cat)
        }
        return selected.count >= 2
    }

    private static func forceSafeSupporting(
        accent: StyleEssenceCategory,
        essenceScores: [StyleEssenceScore]
    ) -> [StyleEssenceCategory] {
        let allOpposed = Set(essenceOppositions.flatMap { [$0.0, $0.1] })
        let safe = essenceScores
            .sorted { $0.score > $1.score }
            .map(\.category)
            .filter { $0 != accent && !allOpposed.contains($0) }
        return Array(safe.prefix(2))
    }

    // MARK: - Plan Construction

    private static func buildPlan(
        relationship: NarrativeRelationship,
        accent: StyleEssenceCategory,
        supporting: [StyleEssenceCategory],
        anchorEssences: [StyleEssenceCategory],
        intensityLevel: IntensityLevel,
        tempoEmphasis: TempoEmphasis,
        snapshot: DailyEnergySnapshot,
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration,
        salience: SkySalienceProfile?,
        precomputedSilhouette: SilhouetteProfile,
        tuning: DailyFitCalibration.NarrativeSelectionTuning,
        weatherTop3: [StyleEssenceCategory]
    ) -> DailyNarrativePlan {

        // Vibrancy: existing stage1 formula (sky-driven) + plan intensity modifier
        let vibrancyBaseline = vibrancyBaselineValue(blueprint: blueprint)
        let skyVibe = snapshot.skyVibeProfile ?? snapshot.vibeProfile
        let push = Double(skyVibe.value(for: .drama) + skyVibe.value(for: .edge)) / 21.0
        let pull = Double(skyVibe.value(for: .utility) + skyVibe.value(for: .classic) + skyVibe.value(for: .romantic)) / 21.0
        let vibeModulation = (push - pull) * Stage1ScaleSensitivity.vibeScale
        let tempoMod = (snapshot.axes.tempo / 10.0 - 0.5) * Stage1ScaleSensitivity.tempoScale
        let intensityMod: Double = {
            switch intensityLevel {
            case .low:      return -0.05
            case .moderate: return  0.0
            case .high:     return  0.05
            case .peak:     return  0.10
            }
        }()
        let targetVibrancy = clamp01(vibrancyBaseline + vibeModulation + tempoMod + intensityMod)

        // Contrast: existing stage1 formula (axis-driven) + plan relationship modifier
        let contrastBaseline = contrastBaselineValue(blueprint: blueprint)
        let coeff = calibration.stage2Sensitivity.contrastCoeff
        let visNorm = snapshot.axes.visibility / 10.0
        let strNorm = snapshot.axes.strategy / 10.0
        let contrastModulation = ((visNorm - 0.5) * Stage1ScaleSensitivity.contrastVisWeight
            + (strNorm - 0.5) * Stage1ScaleSensitivity.contrastStrWeight) * coeff
        let relationshipContrastMod: Double = {
            switch relationship {
            case .reinforce: return  0.02
            case .stretch:   return  0.05
            case .soften:    return -0.05
            case .contrast:  return  0.08
            }
        }()
        let targetContrast = clamp01(contrastBaseline + contrastModulation + relationshipContrastMod)

        // Metal tone: existing derivation
        let targetMetalTone = BlueprintLensEngine.deriveMetalTonePublic(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: .stage1Experimental
        )

        // Silhouette: use precomputed (from sky axes, per existing stage1 tanh formula)
        let targetSilhouette = precomputedSilhouette

        // Palette directive
        let foundation = restrainedFoundation(from: anchorEssences)
        let maxStatementSlots: Int = {
            switch relationship {
            case .reinforce: return 2
            case .stretch, .soften, .contrast: return 1
            }
        }()
        let preferFoundation = relationship == .stretch
            && Set(anchorEssences.prefix(2)).isSubset(of: NarrativeSelectionDirectives.intenseBoldCategories)

        let weatherForVector = [accent] + supporting
        let categoryEnergy = NarrativeSelectionDirectives.categoryEnergyBoost(weatherTop3: weatherForVector)

        let paletteDirective = PaletteDirective(
            maxStatementSlots: maxStatementSlots,
            accentCategory: accent,
            foundationCategory: foundation,
            categoryEnergyBoost: categoryEnergy,
            preferFoundationOverStatement: preferFoundation
        )

        // Tarot directive
        let tarotVector: [Energy: Double]
        switch relationship {
        case .reinforce:
            tarotVector = NarrativeSelectionDirectives.blendedReinforceVector(
                anchorTop3: anchorEssences,
                weatherTop3: weatherForVector
            )
        case .soften:
            tarotVector = NarrativeSelectionDirectives.scaledVector(
                NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: weatherForVector),
                factor: 0.7
            )
        case .stretch, .contrast:
            let weatherVec = NarrativeSelectionDirectives.targetEnergyVector(weatherTop3: weatherForVector)
            let anchorVec = NarrativeSelectionDirectives.blendCategoryWeightRowsPublic(
                categories: anchorEssences,
                weights: [0.5, 0.35, 0.15]
            )
            tarotVector = NarrativeSelectionDirectives.zipEnergyPublic(weatherVec, anchorVec, anchorWeight: 0.25)
        }
        let tarotDirective = TarotDirective(
            targetEnergyVector: tarotVector,
            targetAxesVector: NarrativeSelectionDirectives.targetAxesVector(
                snapshot: snapshot,
                silhouette: precomputedSilhouette,
                tuning: tuning
            ),
            structuredDraped: precomputedSilhouette.structuredDraped
        )

        // Apply scale directive to vibrancy/contrast targets
        var finalVibrancy = targetVibrancy
        var finalContrast = targetContrast

        // Scale directive
        let scales: ScaleDirective? = {
            switch relationship {
            case .reinforce:
                return ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0)
            case .stretch:
                if preferFoundation {
                    return ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: true,
                                          baselineBlend: tuning.intenseAnchorRestrainedWeatherBlend)
                }
                return ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0)
            case .soften:
                return ScaleDirective(vibrancyCap: tuning.softenVibrancyCap, contrastCap: tuning.softenContrastCap,
                                      pullTowardBaseline: true, baselineBlend: tuning.softenBaselineBlend)
            case .contrast:
                return ScaleDirective(vibrancyCap: nil, contrastCap: nil, pullTowardBaseline: false, baselineBlend: 0.0)
            }
        }()

        // Apply scale directive caps/blending
        if let scaleDir = scales {
            if let cap = scaleDir.vibrancyCap { finalVibrancy = min(finalVibrancy, cap) }
            if let cap = scaleDir.contrastCap { finalContrast = min(finalContrast, cap) }
            if scaleDir.pullTowardBaseline {
                finalVibrancy = vibrancyBaseline * scaleDir.baselineBlend + finalVibrancy * (1.0 - scaleDir.baselineBlend)
                finalContrast = contrastBaseline * scaleDir.baselineBlend + finalContrast * (1.0 - scaleDir.baselineBlend)
            }
        }

        // Texture directive
        let textureAffinities: [String] = {
            switch accent {
            case .romantic, .sensual: return ["silk", "velvet", "cashmere", "satin", "chiffon"]
            case .edgy, .drama:      return ["leather", "denim", "bonded"]
            case .classic, .polished: return ["wool", "tweed", "cashmere", "knit"]
            case .utility, .grounded: return ["cotton", "linen", "denim", "flannel"]
            case .playful, .eclectic: return ["jersey", "cotton", "stretch", "chiffon"]
            case .minimal:           return ["cotton", "linen", "jersey", "matte"]
            case .maximalist:        return ["velvet", "silk", "satin", "leather"]
            case .magnetic:          return ["silk", "velvet", "leather", "satin"]
            case .effortless:        return ["jersey", "cotton", "linen", "knit"]
            }
        }()
        let textureIntensityBias: Double = {
            switch intensityLevel {
            case .low: return -0.1
            case .moderate: return 0.0
            case .high: return 0.1
            case .peak: return 0.2
            }
        }()
        let textureDirective = TextureDirective(
            preferredAffinities: textureAffinities,
            intensityBias: textureIntensityBias
        )

        // Pattern directive
        let patternGate: Bool = {
            switch intensityLevel {
            case .high, .peak: return true
            case .moderate:    return tempoEmphasis == .dynamic
            case .low:         return false
            }
        }()
        let patternEnergy: String? = {
            let polarity = DailyNarrativeCoherence.blendedPolarity(accent: accent, supporting: supporting)
            if polarity.restraintExpression > 0.3 { return Energy.drama.rawValue }
            if polarity.groundednessMotion > 0.3 { return Energy.playful.rawValue }
            return nil
        }()
        let patternDirective = PatternDirective(gateEnabled: patternGate, preferredEnergy: patternEnergy)

        // Salience drivers
        let salienceDrivers = (salience?.topDrivers ?? []).prefix(3).map {
            "\($0.planet) \($0.aspect) \($0.natalTarget) (salience: \(String(format: "%.2f", $0.salience)))"
        }
        let justification: String = {
            guard let top = salience?.topDrivers.first else { return "No salience data" }
            let catLabel = top.essenceCategory?.rawValue ?? "unknown"
            return "\(top.planet) \(top.aspect) \(top.natalTarget) drives \(catLabel) (salience \(String(format: "%.2f", top.salience)))"
        }()

        return DailyNarrativePlan(
            relationship: relationship,
            accentEssence: accent,
            supportingEssences: supporting,
            anchorEssences: anchorEssences,
            intensityLevel: intensityLevel,
            tempoEmphasis: tempoEmphasis,
            targetVibrancy: finalVibrancy,
            targetContrast: finalContrast,
            targetMetalTone: targetMetalTone,
            targetSilhouette: targetSilhouette,
            paletteDirective: paletteDirective,
            tarotDirective: tarotDirective,
            scaleDirective: scales,
            textureDirective: textureDirective,
            patternDirective: patternDirective,
            salienceDrivers: salienceDrivers,
            skyJustification: justification,
            coherenceTrace: nil
        )
    }

    // MARK: - Helpers

    private static func vibrancyBaselineValue(blueprint: CosmicBlueprint) -> Double {
        switch blueprint.palette.variables?.saturation {
        case .soft:  return 0.25
        case .muted: return 0.50
        case .rich:  return 0.75
        case nil:    return 0.50
        }
    }

    private static func contrastBaselineValue(blueprint: CosmicBlueprint) -> Double {
        switch blueprint.palette.variables?.contrast {
        case .low:    return 0.25
        case .medium: return 0.50
        case .high:   return 0.75
        case nil:     return 0.50
        }
    }

    private static func restrainedFoundation(from anchorTop3: [StyleEssenceCategory]) -> StyleEssenceCategory {
        for cat in anchorTop3 {
            if NarrativeSelectionDirectives.restrainedCategories.contains(cat) {
                return cat
            }
        }
        return anchorTop3.first ?? .classic
    }

    private static func clamp01(_ v: Double) -> Double {
        max(0.0, min(1.0, v))
    }
}
