//
//  NarrativeSelectionDirectives.swift
//  Cosmic Fit
//
//  DEPRECATED (Plan 2): resolveEssenceConflicts superseded by DailyNarrativeCoherence.validate.
//  applyNarrativePaletteScoring and selectViaNarrativeSlots still used by generatePayloadFromPlan
//  via plan-to-intent bridge. Palette slot allocation reads from DailyNarrativePlan.paletteDirective.
//  Retained for production compatibility and plan-to-intent bridge. Planned removal after Plan 3.
//
//  Original purpose: Narrative intent types, role-preference maps, and palette slot allocation.
//

import Foundation

// MARK: - Intent Directives

/// Stage-1 selection bias derived from chart anchor vs sky weather relationship.
struct NarrativeIntent: Equatable {
    let relationship: NarrativeRelationship
    let anchorTop3: [StyleEssenceCategory]
    let weatherTop3: [StyleEssenceCategory]
    let tarot: TarotDirective
    let palette: PaletteDirective
    let scales: ScaleDirective
    let essencePresentation: EssencePresentationDirective
    let themeLexiconKey: String?
    let coherenceGap: String?
}

struct TarotDirective: Equatable, Codable {
    let targetEnergyVector: [Energy: Double]
    /// Normalized 0–1 targets for action/tempo/strategy/visibility.
    /// `strategy` incorporates plan.targetSilhouette.structuredDraped.
    let targetAxesVector: [String: Double]
    /// Carried from plan so the bridge can fire the hard structure gate.
    let structuredDraped: Double
}

struct PaletteDirective: Equatable, Codable {
    let maxStatementSlots: Int
    let accentCategory: StyleEssenceCategory
    let foundationCategory: StyleEssenceCategory
    let categoryEnergyBoost: [Energy: Double]
    let preferFoundationOverStatement: Bool
}

struct ScaleDirective: Equatable, Codable {
    let vibrancyCap: Double?
    let contrastCap: Double?
    let pullTowardBaseline: Bool
    let baselineBlend: Double
}

struct EssencePresentationDirective: Equatable {
    let showAnchorGhost: Bool
}

// MARK: - Opposition Pairs

/// Archetypal opposition pairs: categories that contradict each other when
/// shown together in the user-facing essence top 3.
let essenceOppositions: [(StyleEssenceCategory, StyleEssenceCategory)] = [
    (.minimal, .maximalist), (.polished, .edgy), (.classic, .eclectic), (.grounded, .playful)
]

// MARK: - Role Preference Maps (§15.2)

enum NarrativeSelectionDirectives {

    static let intenseBoldCategories: Set<StyleEssenceCategory> = [
        .drama, .edgy, .maximalist, .magnetic
    ]

    static let restrainedCategories: Set<StyleEssenceCategory> = [
        .polished, .classic, .minimal, .romantic, .grounded, .effortless
    ]

    static let accentRoles: Set<ColourRole> = [.accent, .statement, .signature]

    static let foundationRoles: Set<ColourRole> = [.core, .neutral, .anchor, .support]

    static let accentRolePreference: [StyleEssenceCategory: [ColourRole]] = [
        .edgy: [.statement, .accent, .signature],
        .romantic: [.core, .accent, .support],
        .classic: [.core, .neutral, .anchor],
        .utility: [.neutral, .anchor, .core],
        .drama: [.statement, .accent, .signature],
        .playful: [.accent, .support, .signature],
        .polished: [.core, .neutral, .anchor],
        .effortless: [.neutral, .core, .support],
        .sensual: [.accent, .core, .support],
        .magnetic: [.statement, .signature, .accent],
        .grounded: [.neutral, .anchor, .core],
        .eclectic: [.accent, .statement, .support],
        .minimal: [.neutral, .anchor, .core],
        .maximalist: [.statement, .signature, .accent],
    ]

    static let foundationRolePreference: [StyleEssenceCategory: [ColourRole]] = [
        .edgy: [.core, .neutral],
        .romantic: [.neutral, .anchor],
        .classic: [.accent],
        .utility: [.support],
        .drama: [.core, .neutral],
        .playful: [.core, .neutral],
        .polished: [.accent],
        .effortless: [.anchor],
        .sensual: [.neutral],
        .magnetic: [.core, .neutral],
        .grounded: [.support],
        .eclectic: [.core],
        .minimal: [.accent],
        .maximalist: [.core, .neutral],
    ]

    // MARK: - Energy Vector Helpers (§15.4)

    static func targetEnergyVector(
        weatherTop3: [StyleEssenceCategory],
        weights: [Double] = [0.55, 0.30, 0.15]
    ) -> [Energy: Double] {
        blendCategoryWeightRows(categories: weatherTop3, weights: weights)
    }

    static func blendedReinforceVector(
        anchorTop3: [StyleEssenceCategory],
        weatherTop3: [StyleEssenceCategory]
    ) -> [Energy: Double] {
        let anchorVec = blendCategoryWeightRows(
            categories: anchorTop3,
            weights: [0.5, 0.35, 0.15]
        )
        let weatherVec = blendCategoryWeightRows(
            categories: weatherTop3,
            weights: [0.55, 0.30, 0.15]
        )
        return zipEnergy(anchorVec, weatherVec, anchorWeight: 0.5)
    }

    static func scaledVector(_ vector: [Energy: Double], factor: Double) -> [Energy: Double] {
        vector.mapValues { $0 * factor }
    }

    static func energyDictionary(from stringKeyed: [String: Double]) -> [Energy: Double] {
        var result: [Energy: Double] = [:]
        for (key, value) in stringKeyed {
            if let energy = Energy(rawValue: key) {
                result[energy] = value
            }
        }
        return result
    }

    static func cosineSimilarity(_ a: [Energy: Double], _ b: [Energy: Double]) -> Double {
        let allKeys = Set(a.keys).union(b.keys)
        var dot = 0.0, magA = 0.0, magB = 0.0
        for key in allKeys {
            let va = a[key] ?? 0.0
            let vb = b[key] ?? 0.0
            dot += va * vb
            magA += va * va
            magB += vb * vb
        }
        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0.0 }
        return dot / denom
    }

    static func categoryEnergyBoost(
        weatherTop3: [StyleEssenceCategory],
        weights: [Double] = [0.55, 0.30, 0.15]
    ) -> [Energy: Double] {
        targetEnergyVector(weatherTop3: weatherTop3, weights: weights)
    }

    // MARK: - Form / Axes Helpers (Tarot Form Bridge)

    /// Build a normalized 0–1 target axes vector from sky axes + silhouette structure blend.
    static func targetAxesVector(
        snapshot: DailyEnergySnapshot,
        silhouette: SilhouetteProfile,
        tuning: DailyFitCalibration.NarrativeSelectionTuning
    ) -> [String: Double] {
        let skyStrategy = snapshot.axes.strategy / 10.0
        let silhouetteStructure = 1.0 - silhouette.structuredDraped
        let targetStrategy = min(max(
            tuning.structureSkyWeight * skyStrategy
            + tuning.structureSilhouetteWeight * silhouetteStructure,
            0.0), 1.0)

        return [
            "action": snapshot.axes.action / 10.0,
            "tempo": snapshot.axes.tempo / 10.0,
            "strategy": targetStrategy,
            "visibility": snapshot.axes.visibility / 10.0
        ]
    }

    /// Sky-only fallback when no silhouette is available (e.g. NarrativeIntentEngine legacy path).
    static func targetAxesVectorSkyOnly(snapshot: DailyEnergySnapshot) -> [String: Double] {
        [
            "action": snapshot.axes.action / 10.0,
            "tempo": snapshot.axes.tempo / 10.0,
            "strategy": snapshot.axes.strategy / 10.0,
            "visibility": snapshot.axes.visibility / 10.0
        ]
    }

    /// Normalize Int 0–100 variant axesEmphasis to Double 0–1.
    static func axesDictionary(from emphasis: [String: Int]) -> [String: Double] {
        var result: [String: Double] = [:]
        for (key, value) in emphasis {
            result[key] = Double(value) / 100.0
        }
        return result
    }

    /// Cosine similarity for string-keyed axes vectors (action/tempo/strategy/visibility).
    static func cosineSimilarityAxes(_ a: [String: Double], _ b: [String: Double]) -> Double {
        let allKeys = Set(a.keys).union(b.keys)
        var dot = 0.0, magA = 0.0, magB = 0.0
        for key in allKeys {
            let va = a[key] ?? 0.0
            let vb = b[key] ?? 0.0
            dot += va * vb
            magA += va * va
            magB += vb * vb
        }
        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0.0 }
        return dot / denom
    }

    // MARK: - Palette Scoring (§15.3)

    static func tierMultiplier(role: ColourRole, preferences: [ColourRole]) -> Double {
        guard let index = preferences.firstIndex(of: role) else { return 0.0 }
        switch index {
        case 0: return 1.0
        case 1: return 0.6
        case 2: return 0.3
        default: return 0.0
        }
    }

    static func rolePreferenceTerm(
        role: ColourRole,
        accentCategory: StyleEssenceCategory,
        foundationCategory: StyleEssenceCategory,
        tuning: DailyFitCalibration.NarrativeSelectionTuning
    ) -> Double {
        let accentPrefs = accentRolePreference[accentCategory] ?? []
        let foundationPrefs = foundationRolePreference[foundationCategory] ?? []
        let accentTerm = tuning.rolePreferenceBonus * tierMultiplier(role: role, preferences: accentPrefs)
        let foundationTerm = tuning.rolePreferenceBonus * 0.5 * tierMultiplier(role: role, preferences: foundationPrefs)
        return accentTerm + foundationTerm
    }

    static func energyAlignmentTerm(
        role: ColourRole,
        categoryEnergyBoost: [Energy: Double],
        roleEnergyAlignment: [ColourRole: [Energy]]
    ) -> Double {
        let aligned = roleEnergyAlignment[role] ?? [.classic, .romantic]
        guard !aligned.isEmpty else { return 0.0 }
        let sum = aligned.reduce(0.0) { partial, energy in
            partial + (categoryEnergyBoost[energy] ?? 0.0)
        }
        return sum / Double(aligned.count)
    }

    /// Narrative-biased palette scoring layered on top of base sky scoring.
    static func applyNarrativePaletteScoring(
        baseScored: [(colour: BlueprintColour, score: Double)],
        intent: NarrativeIntent,
        tuning: DailyFitCalibration.NarrativeSelectionTuning,
        roleEnergyAlignment: [ColourRole: [Energy]],
        seededJitter: (BlueprintColour) -> Double,
        coverageDebtForHex: ((String) -> Double)? = nil
    ) -> [(colour: BlueprintColour, score: Double)] {
        let directive = intent.palette
        let coverageWeight = tuning.colourCoverageWeight
        var scored = baseScored.map { item -> (colour: BlueprintColour, score: Double) in
            let role = item.colour.role
            let energyTerm = energyAlignmentTerm(
                role: role,
                categoryEnergyBoost: directive.categoryEnergyBoost,
                roleEnergyAlignment: roleEnergyAlignment
            )
            let roleTerm = rolePreferenceTerm(
                role: role,
                accentCategory: directive.accentCategory,
                foundationCategory: directive.foundationCategory,
                tuning: tuning
            )
            let jitter = seededJitter(item.colour)
            let debtTerm: Double = coverageDebtForHex?(item.colour.hexValue) ?? 0.0
            let score = item.score
                + tuning.categoryEnergyWeight * energyTerm
                + roleTerm
                + tuning.narrativePaletteJitter * jitter
                + coverageWeight * debtTerm
            return (item.colour, score)
        }
        if directive.preferFoundationOverStatement {
            scored = scored.map { item in
                guard foundationRoles.contains(item.colour.role) else { return item }
                return (item.colour, item.score + tuning.rolePreferenceBonus * 0.5)
            }
        }
        scored.sort { $0.score > $1.score }
        return scored
    }

    // MARK: - Slot Allocator (§15.3)

    static func selectViaNarrativeSlots(
        scored: [(colour: BlueprintColour, score: Double)],
        intent: NarrativeIntent,
        normalizeHex: (String) -> String,
        tuning: DailyFitCalibration.NarrativeSelectionTuning? = nil,
        coverageDebtForHex: ((String) -> Double)? = nil
    ) -> (selected: [(colour: BlueprintColour, score: Double)], statementSlotCount: Int) {
        let statementPool = scored.filter { accentRoles.contains($0.colour.role) }
        let foundationPool = scored.filter { foundationRoles.contains($0.colour.role) }

        var nStatement = min(intent.palette.maxStatementSlots, statementPool.count)
        if intent.palette.preferFoundationOverStatement {
            nStatement = min(nStatement, 1)
        }

        var selected: [(colour: BlueprintColour, score: Double)] = []
        var usedHexes = Set<String>()

        for item in statementPool.prefix(nStatement) {
            let key = normalizeHex(item.colour.hexValue)
            guard !usedHexes.contains(key) else { continue }
            usedHexes.insert(key)
            selected.append(item)
        }

        for item in foundationPool {
            if selected.count >= 3 { break }
            let key = normalizeHex(item.colour.hexValue)
            guard !usedHexes.contains(key) else { continue }
            usedHexes.insert(key)
            selected.append(item)
        }

        if selected.count < 3 {
            for item in scored {
                if selected.count >= 3 { break }
                let key = normalizeHex(item.colour.hexValue)
                guard !usedHexes.contains(key) else { continue }
                usedHexes.insert(key)
                selected.append(item)
            }
        }

        // Coverage floor: on grounded-eligible days, if a max-debt foundation/anchor
        // candidate exists outside the current selection, swap it into the lowest-scoring
        // foundation slot.
        if let tuning, tuning.colourCoverageFloorEnabled,
           let debtFn = coverageDebtForHex,
           isGroundedEligible(intent: intent) {
            let selectedHexes = Set(selected.map { normalizeHex($0.colour.hexValue) })
            let unselectedFoundation = foundationPool.filter {
                !selectedHexes.contains(normalizeHex($0.colour.hexValue))
            }
            if let maxDebtCandidate = unselectedFoundation
                .map({ ($0, debtFn($0.colour.hexValue)) })
                .filter({ $0.1 >= 0.85 })
                .max(by: { $0.1 < $1.1 })?.0 {
                // Find lowest-scoring foundation slot in selected to swap out
                if let swapIdx = selected.enumerated()
                    .filter({ foundationRoles.contains($0.element.colour.role) })
                    .min(by: { $0.element.score < $1.element.score })?.offset {
                    let swapHex = normalizeHex(selected[swapIdx].colour.hexValue)
                    let candidateHex = normalizeHex(maxDebtCandidate.colour.hexValue)
                    if swapHex != candidateHex {
                        selected[swapIdx] = maxDebtCandidate
                        usedHexes.remove(swapHex)
                        usedHexes.insert(candidateHex)
                    }
                }
            }
        }

        let statementCount = selected.filter { accentRoles.contains($0.colour.role) }.count
        return (selected, statementCount)
    }

    /// A day is grounded-eligible when statement slots are limited (soften/contrast/stretch
    /// or preferFoundationOverStatement). Coverage floor only activates on these days.
    private static func isGroundedEligible(intent: NarrativeIntent) -> Bool {
        if intent.palette.preferFoundationOverStatement { return true }
        if intent.palette.maxStatementSlots <= 1 { return true }
        return false
    }

    // MARK: - Hero Rotation (§15.4)

    /// Reorder selected colours so the hero (index 0) rotates over time while
    /// respecting narrative coherence: statement-leaning days (reinforce / maxStatementSlots >= 2)
    /// always keep a statement-role hero; grounded days allow any pick to be hero.
    /// Among eligible candidates, the one with greatest heroDebt wins, tie-broken by score.
    static func applyHeroRotation(
        selected: [(colour: BlueprintColour, score: Double)],
        intent: NarrativeIntent,
        tuning: DailyFitCalibration.NarrativeSelectionTuning,
        heroDebtForHex: ((String) -> Double)? = nil
    ) -> [(colour: BlueprintColour, score: Double)] {
        guard tuning.colourHeroRotationEnabled,
              let debtFn = heroDebtForHex,
              selected.count >= 2 else {
            return selected
        }

        let statementLeaning = intent.palette.maxStatementSlots >= 2
            && !intent.palette.preferFoundationOverStatement

        let eligibleIndices: [Int]
        if statementLeaning {
            let indices = selected.indices.filter { accentRoles.contains(selected[$0].colour.role) }
            eligibleIndices = indices.isEmpty ? [0] : indices
        } else {
            eligibleIndices = Array(selected.indices)
        }

        guard eligibleIndices.count > 1 else { return selected }

        let bestIdx = eligibleIndices.max(by: { a, b in
            let debtA = debtFn(selected[a].colour.hexValue)
            let debtB = debtFn(selected[b].colour.hexValue)
            if abs(debtA - debtB) > 0.01 { return debtA < debtB }
            return selected[a].score < selected[b].score
        }) ?? eligibleIndices[0]

        if bestIdx == 0 { return selected }

        var reordered = selected
        let hero = reordered.remove(at: bestIdx)
        reordered.insert(hero, at: 0)
        return reordered
    }

    // MARK: - Coherence Heuristic (§15.5)

    static func computeCoherenceTrace(
        payload: DailyFitPayload,
        intent: NarrativeIntent,
        tuning: DailyFitCalibration.NarrativeSelectionTuning,
        tarotVariantWasScored: Bool,
        tarotCategoryBoostApplied: Bool,
        statementSlotCount: Int,
        bridgeTrace: NarrativeBridgeTrace? = nil
    ) -> NarrativeCoherenceTrace {
        let selectedRoles = payload.dailyPalette.colours.compactMap { ColourRole(rawValue: $0.role) }
        let paletteAccentRoleMatch = selectedRoles.contains { accentRoles.contains($0) }

        var pass = paletteAccentRoleMatch

        switch intent.relationship {
        case .contrast, .stretch:
            pass = pass && statementSlotCount <= 1
        case .soften:
            pass = pass && statementSlotCount <= 1
            pass = pass && payload.vibrancy <= tuning.softenVibrancyCap + 0.02
        case .reinforce:
            pass = pass && statementSlotCount <= 2
        }

        pass = pass && tarotVariantWasScored

        // Phase 1: bridgePass is traced but does NOT fail overallPass yet.
        // Phase 2 (enable enforcement) requires Ash sign-off after contrast-day review.
        let variantBridgeSimilarity = bridgeTrace?.variantBridgeSimilarity
        let bridgePass = bridgeTrace?.bridgePass

        return NarrativeCoherenceTrace(
            paletteAccentRoleMatch: paletteAccentRoleMatch,
            paletteStatementSlotCount: statementSlotCount,
            tarotCategoryBoostApplied: tarotCategoryBoostApplied,
            tarotVariantScored: tarotVariantWasScored,
            variantBridgeSimilarity: variantBridgeSimilarity,
            bridgePass: bridgePass,
            overallPass: pass
        )
    }

    static func narrativeIntentTrace(from intent: NarrativeIntent, trace: NarrativeTrace) -> NarrativeIntentTrace {
        NarrativeIntentTrace(
            relationship: intent.relationship.rawValue,
            anchorTop3: intent.anchorTop3.map(\.rawValue),
            weatherTop3: intent.weatherTop3.map(\.rawValue),
            accentCategory: intent.palette.accentCategory.rawValue,
            foundationCategory: intent.palette.foundationCategory.rawValue,
            overlapCount: trace.overlapCount,
            themeLexiconKey: intent.themeLexiconKey,
            coherenceGap: intent.coherenceGap
        )
    }

    // MARK: - Essence Conflict Resolution (Stage 1 only)

    /// When an opposition pair (e.g. minimal + maximalist) appears in the
    /// visible top 3, the user sees contradictory styling instructions.
    /// This resolver keeps the side that matches the day's narrative intent
    /// and promotes the next-highest non-conflicting category.
    static func resolveEssenceConflicts(
        profile: StyleEssenceProfile,
        intent: NarrativeIntent
    ) -> (resolved: StyleEssenceProfile, trace: EssenceConflictTrace?) {
        var visible = profile.visibleCategories
        let visibleCategories = Set(visible.map(\.category))
        let weatherSet = Set(intent.weatherTop3)

        var suppressions: [EssenceConflictSuppression] = []

        for (a, b) in essenceOppositions {
            guard visibleCategories.contains(a), visibleCategories.contains(b) else { continue }

            let keep: StyleEssenceCategory
            let suppress: StyleEssenceCategory

            let aInWeather = weatherSet.contains(a)
            let bInWeather = weatherSet.contains(b)

            if aInWeather && !bInWeather {
                keep = a; suppress = b
            } else if bInWeather && !aInWeather {
                keep = b; suppress = a
            } else {
                let aScore = visible.first(where: { $0.category == a })?.score ?? 0
                let bScore = visible.first(where: { $0.category == b })?.score ?? 0
                if aScore >= bScore { keep = a; suppress = b } else { keep = b; suppress = a }
            }

            guard let suppressIdx = visible.firstIndex(where: { $0.category == suppress }) else { continue }
            let suppressedScore = visible[suppressIdx].score

            let conflicting = Set([a, b])
            let alreadyVisible = Set(visible.map(\.category))
            let replacement = profile.allScores
                .sorted { $0.score > $1.score }
                .first { !alreadyVisible.contains($0.category) && !conflicting.contains($0.category) }

            if let replacement {
                visible[suppressIdx] = replacement
            } else {
                visible.remove(at: suppressIdx)
            }

            suppressions.append(EssenceConflictSuppression(
                suppressedCategory: suppress.rawValue,
                suppressedScore: suppressedScore,
                keptCategory: keep.rawValue,
                replacementCategory: replacement?.category.rawValue,
                replacementScore: replacement?.score,
                reason: "opposition pair (\(a.rawValue) ↔ \(b.rawValue))"
            ))
        }

        guard !suppressions.isEmpty else { return (profile, nil) }

        let resolved = StyleEssenceProfile(
            allScores: profile.allScores,
            visibleCategories: visible,
            chartAnchorScores: profile.chartAnchorScores
        )
        let trace = EssenceConflictTrace(suppressions: suppressions)
        return (resolved, trace)
    }

    // MARK: - Public Accessors (for NarrativeIntentEngine anchor-blend)

    static func blendCategoryWeightRowsPublic(
        categories: [StyleEssenceCategory],
        weights: [Double]
    ) -> [Energy: Double] {
        blendCategoryWeightRows(categories: categories, weights: weights)
    }

    static func zipEnergyPublic(
        _ a: [Energy: Double],
        _ b: [Energy: Double],
        anchorWeight: Double
    ) -> [Energy: Double] {
        zipEnergy(a, b, anchorWeight: anchorWeight)
    }

    // MARK: - Private Helpers

    private static func blendCategoryWeightRows(
        categories: [StyleEssenceCategory],
        weights: [Double]
    ) -> [Energy: Double] {
        var blended: [Energy: Double] = [:]
        var totalWeight = 0.0
        for (index, category) in categories.prefix(weights.count).enumerated() {
            let row = BlueprintLensEngine.essenceCategoryWeights(for: category)
            let w = weights[index]
            totalWeight += w
            for (energy, value) in row {
                blended[energy, default: 0.0] += value * w
            }
        }
        guard totalWeight > 0 else { return blended }
        return blended.mapValues { $0 / totalWeight }
    }

    private static func zipEnergy(
        _ anchor: [Energy: Double],
        _ weather: [Energy: Double],
        anchorWeight: Double
    ) -> [Energy: Double] {
        let weatherWeight = 1.0 - anchorWeight
        let keys = Set(anchor.keys).union(weather.keys)
        var result: [Energy: Double] = [:]
        for key in keys {
            result[key] = (anchor[key] ?? 0.0) * anchorWeight + (weather[key] ?? 0.0) * weatherWeight
        }
        return result
    }
}
