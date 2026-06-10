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

        // 11c. V4.7 — MC/Moon depth overlay. Evaluates whether
        // Midheaven and Moon signs indicate depth the family template
        // underrepresents. May substitute one support slot and/or
        // the deep anchor. Neutrals and core are never touched.
        let depthOverlayResult = DepthOverlayResolver.resolve(
            family: family, input: input, palette: palette
        )
        palette = depthOverlayResult.palette
        let depthOverlay = depthOverlayResult.overlay

        // 11d. V4.8 — Black eligibility. Evaluates whether chart
        // placements justify upgrading the deep anchor to a black or
        // near-black swatch. Scorpio/Capricorn prominence, Pluto,
        // and high-contrast families are the primary signals.
        let blackResult = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: palette,
            winterCompressionApplied: flags.winterCompressionApplied
        )
        palette = blackResult.palette

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
        var accentHexes = accentSlots.map(\.hex)

        // 14b. V4.7 — Accent depth injection. If MC is a strong depth
        // sign and the accent band has no dark note, inject one moody
        // accent from the MC sign's expression table.
        let accentInjectionResult = DepthOverlayResolver.injectAccentDepth(
            input: input,
            family: family,
            accentHexes: accentHexes,
            existingPaletteHexes: personalPaletteHexes,
            previousOverlay: depthOverlay
        )
        accentHexes = accentInjectionResult.accentHexes
        let depthOverlayFinal = accentInjectionResult.overlay

        // 14c. Sync accentSlots when accent injection replaced a slot,
        // so BlueprintComposer (which reads accentSlots[].hex) displays
        // the injected dark accent instead of the pre-injection value.
        var finalAccentSlots = accentSlots
        if let injection = depthOverlayFinal.accentDepthInjection,
           injection.slotIndex < finalAccentSlots.count {
            let original = finalAccentSlots[injection.slotIndex]
            finalAccentSlots[injection.slotIndex] = AccentSlot(
                hex: injection.replacementHex,
                displayName: injection.replacementName,
                role: original.role,
                sourcePlanet: original.sourcePlanet,
                sourceSign: original.sourceSign,
                saturationOverrideApplied: original.saturationOverrideApplied
            )
        }

        // 14d. V4.9 — MC visibility accent. When the MC is a fire/air sign
        // and the existing accent band lacks coverage in the MC ruler's
        // colour direction, appends one vivid accent for public-facing
        // memorability. Complements DepthOverlayResolver (which handles
        // depth-sign MCs) by covering brightness-sign MCs.
        let visibilityResult = VisibilityAccentResolver.resolve(
            family: family,
            input: input,
            accentHexes: accentHexes,
            accentSlots: finalAccentSlots,
            existingPaletteHexes: personalPaletteHexes
        )
        if let visSlot = visibilityResult.slot {
            accentHexes.append(visSlot.hex)
            finalAccentSlots.append(visSlot)
        }

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
            accentSlots: finalAccentSlots,
            depthOverlay: depthOverlayFinal,
            blackEligibility: blackResult.result,
            visibilityAccent: visibilityResult
        )
    }
}
