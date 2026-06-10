//
//  DailyNarrativeCoherence.swift
//  Cosmic Fit
//
//  Plan 2: Hard coherence contract for DailyNarrativePlan.
//  Zero-tolerance gates for visible contradictions.
//

import Foundation

// MARK: - Coherence Validation Result

struct CoherenceValidationResult: Codable, Equatable {
    let passed: Bool
    let essenceOppositionViolations: [String]
    let crossSurfaceViolations: [String]
    let coherenceScore: Double
    let dimensionScores: CoherenceDimensionScores

    var hasHardGateViolation: Bool {
        !essenceOppositionViolations.isEmpty || !crossSurfaceViolations.isEmpty
    }
}

struct CoherenceDimensionScores: Codable, Equatable {
    let essenceMatch: Double
    let paletteMatch: Double
    let tarotMatch: Double
    let sliderMatch: Double
    let silhouetteMatch: Double
}

// MARK: - Narrative Polarity

/// Cross-surface polarity dimensions per §3.2.
/// Each surface allocation maps to a position on these four bipolar axes.
enum NarrativePolarity: String, Codable, CaseIterable {
    case restraint
    case expression
    case softness
    case sharpness
    case classicism
    case experimentation
    case groundedness
    case motion
}

struct PolarityProfile: Codable, Equatable {
    let restraintExpression: Double      // -1 (restraint) to +1 (expression)
    let softnessSharpness: Double        // -1 (softness) to +1 (sharpness)
    let classicismExperimentation: Double // -1 (classicism) to +1 (experimentation)
    let groundednessMotion: Double       // -1 (groundedness) to +1 (motion)
}

// MARK: - Coherence Engine

enum DailyNarrativeCoherence {

    // MARK: - Essence Opposition Contract (§3.1)

    static func validateEssenceOppositions(
        accent: StyleEssenceCategory,
        supporting: [StyleEssenceCategory]
    ) -> [String] {
        let visible = [accent] + supporting
        var violations: [String] = []
        for (a, b) in essenceOppositions {
            let hasA = visible.contains(a)
            let hasB = visible.contains(b)
            if hasA && hasB {
                violations.append("\(a.rawValue) ↔ \(b.rawValue)")
            }
        }
        return violations
    }

    // MARK: - Cross-Surface Compatibility Contract (§3.2)

    static func polarityProfile(for category: StyleEssenceCategory) -> PolarityProfile {
        switch category {
        case .minimal:     return PolarityProfile(restraintExpression: -0.9, softnessSharpness: -0.2, classicismExperimentation: -0.6, groundednessMotion: -0.5)
        case .maximalist:  return PolarityProfile(restraintExpression:  0.9, softnessSharpness:  0.3, classicismExperimentation:  0.6, groundednessMotion:  0.5)
        case .polished:    return PolarityProfile(restraintExpression: -0.5, softnessSharpness:  0.2, classicismExperimentation: -0.4, groundednessMotion: -0.3)
        case .edgy:        return PolarityProfile(restraintExpression:  0.6, softnessSharpness:  0.8, classicismExperimentation:  0.7, groundednessMotion:  0.4)
        case .classic:     return PolarityProfile(restraintExpression: -0.6, softnessSharpness: -0.1, classicismExperimentation: -0.8, groundednessMotion: -0.4)
        case .eclectic:    return PolarityProfile(restraintExpression:  0.5, softnessSharpness:  0.1, classicismExperimentation:  0.8, groundednessMotion:  0.5)
        case .grounded:    return PolarityProfile(restraintExpression: -0.4, softnessSharpness: -0.3, classicismExperimentation: -0.5, groundednessMotion: -0.8)
        case .playful:     return PolarityProfile(restraintExpression:  0.4, softnessSharpness: -0.2, classicismExperimentation:  0.4, groundednessMotion:  0.8)
        case .romantic:    return PolarityProfile(restraintExpression:  0.1, softnessSharpness: -0.6, classicismExperimentation: -0.2, groundednessMotion: -0.1)
        case .drama:       return PolarityProfile(restraintExpression:  0.7, softnessSharpness:  0.4, classicismExperimentation:  0.3, groundednessMotion:  0.6)
        case .sensual:     return PolarityProfile(restraintExpression:  0.2, softnessSharpness: -0.5, classicismExperimentation:  0.1, groundednessMotion:  0.0)
        case .magnetic:    return PolarityProfile(restraintExpression:  0.5, softnessSharpness:  0.3, classicismExperimentation:  0.2, groundednessMotion:  0.3)
        case .utility:     return PolarityProfile(restraintExpression: -0.7, softnessSharpness: -0.1, classicismExperimentation: -0.3, groundednessMotion: -0.6)
        case .effortless:  return PolarityProfile(restraintExpression: -0.2, softnessSharpness: -0.4, classicismExperimentation:  0.2, groundednessMotion:  0.1)
        }
    }

    /// Blend the polarity profiles of the visible top-3 to get the day's narrative polarity.
    static func blendedPolarity(
        accent: StyleEssenceCategory,
        supporting: [StyleEssenceCategory]
    ) -> PolarityProfile {
        let accentP = polarityProfile(for: accent)
        let supportWeights = [0.25, 0.15]
        var re = accentP.restraintExpression * 0.6
        var ss = accentP.softnessSharpness * 0.6
        var ce = accentP.classicismExperimentation * 0.6
        var gm = accentP.groundednessMotion * 0.6
        for (i, cat) in supporting.prefix(2).enumerated() {
            let p = polarityProfile(for: cat)
            let w = supportWeights[i]
            re += p.restraintExpression * w
            ss += p.softnessSharpness * w
            ce += p.classicismExperimentation * w
            gm += p.groundednessMotion * w
        }
        return PolarityProfile(
            restraintExpression: re,
            softnessSharpness: ss,
            classicismExperimentation: ce,
            groundednessMotion: gm
        )
    }

    /// Cross-surface violation: slider targets must not contradict the essence polarity.
    /// Vibrancy maps to restraint/expression, contrast to softness/sharpness.
    static func validateCrossSurface(
        plan: DailyNarrativePlan
    ) -> [String] {
        var violations: [String] = []
        let polarity = blendedPolarity(accent: plan.accentEssence, supporting: plan.supportingEssences)

        // Vibrancy vs restraint/expression: high vibrancy contradicts deep restraint
        if plan.targetVibrancy > 0.75 && polarity.restraintExpression < -0.5 {
            violations.append("vibrancy \(f2(plan.targetVibrancy)) contradicts restraint polarity \(f2(polarity.restraintExpression))")
        }
        if plan.targetVibrancy < 0.25 && polarity.restraintExpression > 0.5 {
            violations.append("vibrancy \(f2(plan.targetVibrancy)) contradicts expression polarity \(f2(polarity.restraintExpression))")
        }

        // Contrast vs softness/sharpness: high contrast contradicts deep softness
        if plan.targetContrast > 0.75 && polarity.softnessSharpness < -0.5 {
            violations.append("contrast \(f2(plan.targetContrast)) contradicts softness polarity \(f2(polarity.softnessSharpness))")
        }
        if plan.targetContrast < 0.25 && polarity.softnessSharpness > 0.5 {
            violations.append("contrast \(f2(plan.targetContrast)) contradicts sharpness polarity \(f2(polarity.softnessSharpness))")
        }

        return violations
    }

    // MARK: - Full Validation (§4.3)

    static func validate(plan: DailyNarrativePlan) -> CoherenceValidationResult {
        let essenceViolations = validateEssenceOppositions(
            accent: plan.accentEssence,
            supporting: plan.supportingEssences
        )
        let crossSurfaceViolations = validateCrossSurface(plan: plan)

        let dimensionScores = CoherenceDimensionScores(
            essenceMatch: essenceViolations.isEmpty ? 1.0 : 0.0,
            paletteMatch: 1.0,
            tarotMatch: 1.0,
            sliderMatch: crossSurfaceViolations.isEmpty ? 1.0 : 0.0,
            silhouetteMatch: 1.0
        )

        let coherenceScore = (dimensionScores.essenceMatch
            + dimensionScores.paletteMatch
            + dimensionScores.tarotMatch
            + dimensionScores.sliderMatch
            + dimensionScores.silhouetteMatch) / 5.0

        let passed = essenceViolations.isEmpty
            && crossSurfaceViolations.isEmpty
            && coherenceScore >= 0.85

        return CoherenceValidationResult(
            passed: passed,
            essenceOppositionViolations: essenceViolations,
            crossSurfaceViolations: crossSurfaceViolations,
            coherenceScore: coherenceScore,
            dimensionScores: dimensionScores
        )
    }

    // MARK: - Post-Routing Coherence Scoring (§5.8)

    static func scorePayloadCoherence(
        plan: DailyNarrativePlan,
        payload: DailyFitPayload
    ) -> CoherenceDimensionScores {
        let planVisible = [plan.accentEssence] + plan.supportingEssences
        let payloadVisible = payload.essenceProfile.visibleCategories.prefix(3).map(\.category)
        let essenceMatch: Double = Set(planVisible) == Set(payloadVisible) ? 1.0 : 0.0

        let paletteMatch: Double = 1.0

        let tarotMatch: Double = {
            let planVector = plan.tarotDirective.targetEnergyVector
            let variantVector = NarrativeSelectionDirectives.energyDictionary(
                from: payload.styleEditVariant.energyEmphasis
            )
            return NarrativeSelectionDirectives.cosineSimilarity(planVector, variantVector) > 0.5 ? 1.0 : 0.0
        }()

        let sliderMatch: Double = abs(payload.vibrancy - plan.targetVibrancy) < 0.05 ? 1.0 : 0.0

        let silhouetteMatch: Double = {
            let mfOk = abs(payload.silhouetteProfile.masculineFeminine - plan.targetSilhouette.masculineFeminine) < 0.1
            let arOk = abs(payload.silhouetteProfile.angularRounded - plan.targetSilhouette.angularRounded) < 0.1
            let sdOk = abs(payload.silhouetteProfile.structuredDraped - plan.targetSilhouette.structuredDraped) < 0.1
            return (mfOk && arOk && sdOk) ? 1.0 : 0.0
        }()

        return CoherenceDimensionScores(
            essenceMatch: essenceMatch,
            paletteMatch: paletteMatch,
            tarotMatch: tarotMatch,
            sliderMatch: sliderMatch,
            silhouetteMatch: silhouetteMatch
        )
    }

    static func meanCoherenceScore(_ scores: CoherenceDimensionScores) -> Double {
        (scores.essenceMatch + scores.paletteMatch + scores.tarotMatch
            + scores.sliderMatch + scores.silhouetteMatch) / 5.0
    }

    // MARK: - Helpers

    private static func f2(_ v: Double) -> String {
        String(format: "%.2f", v)
    }
}
