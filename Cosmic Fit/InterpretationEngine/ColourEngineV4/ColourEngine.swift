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

        // 9. Look up base palette template + support colours
        let baseTriad = PaletteLibrary.palette(for: family)
        let supportColours = PaletteLibrary.supportPalette(for: family)
        let basePalette = PaletteTriadV4(
            neutrals: baseTriad.neutrals,
            coreColours: baseTriad.coreColours,
            accentColours: baseTriad.accentColours,
            supportColours: supportColours,
            lightAnchor: baseTriad.lightAnchor,
            deepAnchor: baseTriad.deepAnchor
        )

        // 10. Derive secondary pull
        let secondaryPull = SecondaryPullDerivation.derive(
            family: family,
            input: input,
            rawScores: rawScoresModified
        )

        // 11. VariationSlots — retained but not invoked.
        // Chart signatures (V4.4) + AccentResolver (V4.5) provide per-user
        // individuation. Re-enable only if future design requires
        // core/neutral/support per-user substitution.
        let variationTrace: VariationTrace = .none

        // 11b. Deep Autumn winter-compression anchor override
        var palette = basePalette
        if family == .deepAutumn && flags.winterCompressionApplied {
            palette = PaletteTriadV4(
                neutrals: basePalette.neutrals,
                coreColours: basePalette.coreColours,
                accentColours: basePalette.accentColours,
                supportColours: basePalette.supportColours,
                lightAnchor: basePalette.lightAnchor,
                deepAnchor: "black"
            )
            flags.deepAnchorOverriddenToBlack = true
        }

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

        // 13. Resolve V4.4 chart-signature swatches. These live alongside
        // the template palette and anchors — computed from the user's
        // actual chart (Sun sign + Ascendant's traditional ruler), then
        // projected into the family envelope so they never break
        // coherence. Invariant to secondary pulls by construction.
        let luminarySignature = ChartSignatureResolver.luminarySignature(
            family: family, input: input
        )
        let rulerSignature = ChartSignatureResolver.rulerSignature(
            family: family, input: input
        )

        // 14. V4.6 — Resolve chart-derived accent slots. Each of 4 roles
        // sources a planet's sign, then picks the best candidate from
        // SignAccentExpressions (temperature-keyed) via spike scoring
        // against the core palette. No envelope projection for accents.
        var personalPaletteHexes = (palette.neutrals + palette.coreColours).map {
            PaletteLibrary.hex(for: $0)
        }
        if let support = palette.supportColours {
            personalPaletteHexes.append(contentsOf: support.map { PaletteLibrary.hex(for: $0) })
        }
        personalPaletteHexes.append(PaletteLibrary.hex(for: palette.lightAnchor))
        personalPaletteHexes.append(PaletteLibrary.hex(for: palette.deepAnchor))
        personalPaletteHexes.append(luminarySignature)
        personalPaletteHexes.append(rulerSignature)

        let accentSlots = AccentResolver.resolve(
            family: family, input: input,
            personalPaletteHexes: personalPaletteHexes
        )

        // Replace template accent band with chart-derived hex values
        let accentHexes = accentSlots.map(\.hex)
        palette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: accentHexes,
            supportColours: palette.supportColours,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        // 15. V4.5 — Post-assembly palette diagnostics (passive logging)
        var allHexes = personalPaletteHexes
        allHexes.append(contentsOf: accentHexes)
        let _ = PaletteValidator.validate(accentHexes: accentHexes, allHexes: allHexes)

        return ColourEngineResult(
            variables: canonicalVariables,
            family: family,
            cluster: cluster,
            palette: palette,
            secondaryPull: secondaryPull,
            trace: trace,
            luminarySignature: luminarySignature,
            rulerSignature: rulerSignature,
            accentSlots: accentSlots
        )
    }
}
