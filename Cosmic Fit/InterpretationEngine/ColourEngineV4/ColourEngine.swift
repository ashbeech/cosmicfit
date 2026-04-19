import Foundation

/// V4 Colour Palette Engine — deterministic mapping from chart placements to
/// family → canonical variables → cluster → fixed palette template.
///
/// Pipeline order (locked):
///   raw scores → modifiers → classify family → canonical variables → cluster → palette
///
/// Two entry points enforce strict/tolerant separation:
/// - `evaluateStrict(input:)` — calibration regression only, frozen fixtures only
/// - `evaluateProduction(input:)` — real user charts only
///
/// `secondaryPull` drives per-user palette variation via curated slot substitution.
enum ColourEngine {

    // MARK: - Strict Evaluation (calibration regression only)

    static func evaluateStrict(input: BirthChartColourInput) -> ColourEngineResult {
        evaluate(input: input)
    }

    // MARK: - Production Evaluation (real user charts only)

    static func evaluateProduction(input: BirthChartColourInput) -> ColourEngineResult {
        evaluate(input: input)
    }

    // MARK: - Core Pipeline

    private static func evaluate(input: BirthChartColourInput) -> ColourEngineResult {
        // 1. Normalize the eight weighted drivers
        let normalizedDrivers = Normalizer.normalizeDrivers(input: input)

        // 2. Accumulate base raw scores
        let rawScoresBase = Scoring.accumulateRawScores(normalized: normalizedDrivers)

        // 3. Apply deterministic modifiers (locked order)
        var rawScoresModified = rawScoresBase
        var flags = OverrideFlags()
        Modifiers.applyAll(input: input, scores: &rawScoresModified, flags: &flags)

        // 4. Derive preliminary variable buckets (for trace only)
        let variablesBeforeOverrides = Thresholds.deriveAll(from: rawScoresModified)

        // 5. Classify family from raw scores + chart analysis
        let family = FamilyMapping.mapToFamily(
            input: input,
            rawScores: rawScoresModified,
            overrideFlags: &flags
        )

        // 6. Output canonical variables for the family
        let canonicalVariables = FamilyProfiles.variables(for: family)

        // 7. Cool-leaning DA flag (trace only)
        if family == .deepAutumn {
            if Overrides.isCoolLeaningDeepAutumn(
                input: input,
                variables: canonicalVariables,
                rawScores: rawScoresModified
            ) {
                flags.coolLeanDeepAutumn = true
            }
        }

        // 8. Map to cluster
        let cluster = ClusterMapping.mapToCluster(
            variables: canonicalVariables,
            family: family
        )

        // 9. Look up base palette template
        let basePalette = PaletteLibrary.palette(for: family)

        // 10. Derive secondary pull
        let secondaryPull = SecondaryPullDerivation.derive(
            family: family,
            input: input,
            rawScores: rawScoresModified
        )

        // 11. Apply per-user variation
        let (palette, variationTrace) = VariationSlots.apply(
            base: basePalette,
            family: family,
            secondaryPull: secondaryPull,
            overrideFlags: flags
        )

        // 12. Assemble trace
        let trace = FamilyDecisionTrace(
            rawScoresBeforeModifiers: rawScoresBase,
            rawScoresAfterModifiers: rawScoresModified,
            normalizedDrivers: normalizedDrivers,
            variablesBeforeOverrides: variablesBeforeOverrides,
            variablesAfterOverrides: canonicalVariables,
            overrideFlags: flags,
            family: family,
            cluster: cluster,
            secondaryPull: secondaryPull,
            variation: variationTrace
        )

        return ColourEngineResult(
            variables: canonicalVariables,
            family: family,
            cluster: cluster,
            palette: palette,
            secondaryPull: secondaryPull,
            trace: trace
        )
    }
}
