//
//  NarrativeSelectionDirectives.swift
//  Cosmic Fit
//
//  Narrative intent types, role-preference maps, and palette slot allocation (§15.2–§15.3).
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

struct TarotDirective: Equatable {
    let targetEnergyVector: [Energy: Double]
}

struct PaletteDirective: Equatable {
    let maxStatementSlots: Int
    let accentCategory: StyleEssenceCategory
    let foundationCategory: StyleEssenceCategory
    let categoryEnergyBoost: [Energy: Double]
    let preferFoundationOverStatement: Bool
}

struct ScaleDirective: Equatable {
    let vibrancyCap: Double?
    let contrastCap: Double?
    let pullTowardBaseline: Bool
    let baselineBlend: Double
}

struct EssencePresentationDirective: Equatable {
    let showAnchorGhost: Bool
}

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
        seededJitter: (BlueprintColour) -> Double
    ) -> [(colour: BlueprintColour, score: Double)] {
        let directive = intent.palette
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
            let score = item.score
                + tuning.categoryEnergyWeight * energyTerm
                + roleTerm
                + tuning.narrativePaletteJitter * jitter
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
        normalizeHex: (String) -> String
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

        let statementCount = selected.filter { accentRoles.contains($0.colour.role) }.count
        return (selected, statementCount)
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
