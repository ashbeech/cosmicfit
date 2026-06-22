//
//  BlueprintComposer.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Final assembly step. Combines ChartAnalysis, deterministic resolved data,
//  archetype keys, and narrative cache lookups into a complete CosmicBlueprint.
//

import Foundation

struct BlueprintComposer {

    static let engineVersion = "2.1.0"

    // MARK: - Full Pipeline

    /// Runs the complete Blueprint generation pipeline.
    /// This is the single entry point that takes a NatalChart and produces a CosmicBlueprint.
    static func compose(
        chart: NatalChartCalculator.NatalChart,
        birthDate: Date,
        birthLocation: String,
        dataset: AstrologicalStyleDataset,
        narrativeCache: NarrativeCacheLoader
    ) -> CosmicBlueprint {
        composeFull(
            chart: chart,
            birthDate: birthDate,
            birthLocation: birthLocation,
            dataset: dataset,
            narrativeCache: narrativeCache
        ).blueprint
    }

    /// Same pipeline as `compose`, but also returns structured palette-engine diagnostics
    /// for inspector drill-down (FamilyDecisionTrace, chart input, accent slots).
    static func composeFull(
        chart: NatalChartCalculator.NatalChart,
        birthDate: Date,
        birthLocation: String,
        dataset: AstrologicalStyleDataset,
        narrativeCache: NarrativeCacheLoader
    ) -> BlueprintComposeResult {
        let analysis = ChartAnalyser.analyse(chart: chart)

        // V4 colour engine — the only palette path
        let adapted = ChartInputAdapter.adapt(analysis: analysis, natalChart: chart)
        let colourResult = ColourEngine.evaluateProduction(input: adapted.colourInput)

        let tokenResult = BlueprintTokenGenerator.generate(
            analysis: analysis,
            dataset: dataset
        )

        // NOTE: V4 is the only production palette path. We still run the
        // deterministic resolver for non-palette fields (metals, stones,
        // code, patterns, textures) used by Group B narrative placeholders.
        // Palette anchors from this resolver are intentionally discarded.
        let resolved = DeterministicResolver.resolveNonPalette(
            tokens: tokenResult.tokens,
            analysis: analysis,
            dataset: tokenResult.dataset,
            contributingCombos: tokenResult.contributingCombos
        )

        let keyResult = ArchetypeKeyGenerator.generateKey(analysis: analysis)

        let (narratives, resolvedKey, usedFallback) = narrativeCache.lookup(
            keyResult: keyResult
        )

        if usedFallback {
            print("[BlueprintComposer] Narrative fallback: \(keyResult.archetypeCluster) → \(resolvedKey)")
        }

        let overlays = HouseSectOverlayGenerator.generate(
            analysis: analysis, dataset: dataset
        )

        var narrativesMut = narratives
        if let append = overlays.styleCoreAppend {
            narrativesMut["style_core"] = (narrativesMut["style_core"] ?? "") + "\n\n" + append
        }
        if let append = overlays.texturesSweetSpotAppend {
            narrativesMut["textures_sweet_spot"] = (narrativesMut["textures_sweet_spot"] ?? "") + "\n\n" + append
        }
        if let append = overlays.occasionsWorkAppend {
            narrativesMut["occasions_work"] = (narrativesMut["occasions_work"] ?? "") + "\n\n" + append
        }
        if let append = overlays.occasionsIntimateAppend {
            narrativesMut["occasions_intimate"] = (narrativesMut["occasions_intimate"] ?? "") + "\n\n" + append
        }
        if let append = overlays.occasionsDailyAppend {
            narrativesMut["occasions_daily"] = (narrativesMut["occasions_daily"] ?? "") + "\n\n" + append
        }

        let nonAccentTemplateNames = Self.collectNonAccentTemplateNames(colourResult: colourResult)
        let renamedAccentLabels = Self.resolveAccentLabels(
            colourResult: colourResult,
            nonAccentTemplateNames: nonAccentTemplateNames
        )

        var templateContext = NarrativeTemplateRenderer.buildContext(resolved: resolved)
        let v4Context = NarrativeTemplateRenderer.buildV4PaletteContext(
            colourResult: colourResult,
            accentLabelOverrides: renamedAccentLabels
        )
        templateContext.merge(v4Context) { _, v4 in v4 }

        for sectionKey in NarrativeTemplateRenderer.groupBSections {
            guard let raw = narrativesMut[sectionKey], !raw.isEmpty else { continue }
            narrativesMut[sectionKey] = NarrativeTemplateRenderer.render(
                template: raw, context: templateContext
            )
        }

        let paletteSection = buildV4PaletteSection(
            colourResult: colourResult,
            narrativeText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.paletteNarrative.rawValue] ?? "",
            accentLabelOverrides: renamedAccentLabels
        )

        logV4PaletteReadout(paletteSection)

        #if DEBUG
        logBlueprintDiagnostics(
            analysis: analysis,
            tokenResult: tokenResult,
            resolved: resolved,
            keyResult: keyResult,
            resolvedKey: resolvedKey,
            usedFallback: usedFallback,
            overlays: overlays,
            templateContext: templateContext,
            narrativesMut: narrativesMut,
            dataset: dataset
        )
        #endif

        let now = Date()

        let blueprint = CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: birthDate,
                birthLocation: birthLocation,
                generationDate: now
            ),
            styleCore: StyleCoreSection(
                narrativeText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.styleCore.rawValue] ?? ""
            ),
            textures: TexturesSection(
                goodText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.texturesGood.rawValue] ?? "",
                badText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.texturesBad.rawValue] ?? "",
                sweetSpotText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.texturesSweetSpot.rawValue] ?? "",
                recommendedTextures: resolved.recommendedTextures,
                avoidTextures: resolved.avoidTextures,
                sweetSpotKeywords: resolved.sweetSpotKeywords
            ),
            palette: paletteSection,
            occasions: OccasionsSection(
                workText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.occasionsWork.rawValue] ?? "",
                intimateText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.occasionsIntimate.rawValue] ?? "",
                dailyText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.occasionsDaily.rawValue] ?? ""
            ),
            hardware: HardwareSection(
                metalsText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.hardwareMetals.rawValue] ?? "",
                stonesText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.hardwareStones.rawValue] ?? "",
                tipText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.hardwareTip.rawValue] ?? "",
                recommendedMetals: resolved.recommendedMetals,
                recommendedStones: resolved.recommendedStones
            ),
            code: CodeSection(
                leanInto: resolved.leanInto,
                avoid: resolved.avoid,
                consider: resolved.consider
            ),
            accessory: AccessorySection(
                paragraphs: [
                    narrativesMut[BlueprintArchetypeKey.BlueprintSection.accessoryParagraph1.rawValue] ?? "",
                    narrativesMut[BlueprintArchetypeKey.BlueprintSection.accessoryParagraph2.rawValue] ?? "",
                    narrativesMut[BlueprintArchetypeKey.BlueprintSection.accessoryParagraph3.rawValue] ?? ""
                ]
            ),
            pattern: PatternSection(
                narrativeText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.patternNarrative.rawValue] ?? "",
                tipText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.patternTip.rawValue] ?? "",
                recommendedPatterns: resolved.recommendedPatterns,
                avoidPatterns: resolved.avoidPatterns
            ),
            generatedAt: now,
            engineVersion: engineVersion
        )

        let diagnostics = BlueprintDiagnostics.report(
            from: colourResult,
            adaptedInput: adapted,
            midheavenSign: analysis.midheavenSign,
            midheavenOverlayApplied: true
        )

        return BlueprintComposeResult(blueprint: blueprint, diagnostics: diagnostics)
    }

    // MARK: - Palette console readout

    /// Prints every V4 palette colour by section when the blueprint is composed
    /// (visible in Xcode console and device logs).
    private static func logV4PaletteReadout(_ palette: PaletteSection) {
        guard palette.isV4 else {
            print("[BlueprintComposer] Palette readout: legacy palette (no V4 bands)")
            return
        }

        print("[BlueprintComposer] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[BlueprintComposer] V4 palette colour readout (name — hex)")
        if let family = palette.family {
            print("[BlueprintComposer] Family: \(family.rawValue)")
        }
        if let cluster = palette.cluster {
            print("[BlueprintComposer] Cluster: \(cluster.rawValue)")
        }
        print("[BlueprintComposer] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        if let neutrals = palette.neutrals, !neutrals.isEmpty {
            print("[BlueprintComposer] Neutrals (\(neutrals.count)):")
            for (i, c) in neutrals.enumerated() {
                print("[BlueprintComposer]   \(i + 1). \(c.name) — \(c.hexValue)")
            }
        }

        print("[BlueprintComposer] Core (\(palette.coreColours.count)):")
        for (i, c) in palette.coreColours.enumerated() {
            print("[BlueprintComposer]   \(i + 1). \(c.name) — \(c.hexValue)")
        }

        print("[BlueprintComposer] Accents (\(palette.accentColours.count)):")
        for (i, c) in palette.accentColours.enumerated() {
            let extra = accentProvenanceLogSuffix(c.provenance)
            print("[BlueprintComposer]   \(i + 1). \(c.name) — \(c.hexValue)\(extra)")
        }

        if let support = palette.supportColours, !support.isEmpty {
            print("[BlueprintComposer] Support (\(support.count)):")
            for (i, c) in support.enumerated() {
                print("[BlueprintComposer]   \(i + 1). \(c.name) — \(c.hexValue)")
            }
        }

        if let la = palette.lightAnchor {
            print("[BlueprintComposer] Light anchor: \(la.name) — \(la.hexValue)")
        }
        if let da = palette.deepAnchor {
            print("[BlueprintComposer] Deep anchor: \(da.name) — \(da.hexValue)")
        }
        if let lum = palette.luminarySignature {
            print("[BlueprintComposer] Luminary signature: \(lum.name) — \(lum.hexValue)")
        }
        if let rul = palette.rulerSignature {
            print("[BlueprintComposer] Ruler signature: \(rul.name) — \(rul.hexValue)")
        }

        print("[BlueprintComposer] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private static func accentProvenanceLogSuffix(_ p: ColourProvenance) -> String {
        switch p {
        case let .chartDerivedAccent(role, planet, sign, saturationOverride):
            let vivid = saturationOverride ? " · vivid element" : ""
            return "  [\(role) · \(planet) in \(sign)\(vivid)]"
        default:
            return ""
        }
    }

    // MARK: - Accent Label Deduplication

    /// Template names from all non-accent bands (neutrals, core, support,
    /// anchors). These are fixed by the family template and never renamed.
    private static func collectNonAccentTemplateNames(
        colourResult: ColourEngineResult
    ) -> Set<String> {
        var names = Set<String>()
        for n in colourResult.palette.neutrals { names.insert(n.lowercased()) }
        for n in colourResult.palette.coreColours { names.insert(n.lowercased()) }
        if let support = colourResult.palette.supportColours {
            for n in support { names.insert(n.lowercased()) }
        }
        names.insert(colourResult.palette.lightAnchor.lowercased())
        names.insert(colourResult.palette.deepAnchor.lowercased())
        return names
    }

    /// Renamed accent labels that avoid collisions with template names
    /// and with each other.
    private static func resolveAccentLabels(
        colourResult: ColourEngineResult,
        nonAccentTemplateNames: Set<String>
    ) -> [String] {
        if !colourResult.accentSlots.isEmpty {
            return PaletteLibrary.deduplicatedAccentLabels(
                slots: colourResult.accentSlots,
                templateNames: Array(nonAccentTemplateNames),
                claimedTemplateNames: nonAccentTemplateNames
            )
        } else {
            return PaletteLibrary.deduplicatedAccentLabelsFromTemplate(
                names: colourResult.palette.accentColours,
                claimedTemplateNames: nonAccentTemplateNames
            )
        }
    }

    // MARK: - V4 Palette Builder

    private static func buildV4PaletteSection(
        colourResult: ColourEngineResult,
        narrativeText: String,
        accentLabelOverrides: [String]
    ) -> PaletteSection {
        let family = colourResult.family

        func makeBand(
            names: [String], band: String, role: ColourRole
        ) -> [BlueprintColour] {
            names.enumerated().map { index, name in
                BlueprintColour(
                    name: name,
                    hexValue: PaletteLibrary.hex(for: name),
                    role: role,
                    provenance: .v4Template(
                        family: family.rawValue, band: band, index: index
                    )
                )
            }
        }

        let supportBand: [BlueprintColour]? = colourResult.palette.supportColours.map {
            makeBand(names: $0, band: "support", role: .support)
        }

        func makeAnchor(name: String, band: String) -> BlueprintColour {
            BlueprintColour(
                name: name,
                hexValue: PaletteLibrary.hex(for: name),
                role: .anchor,
                provenance: .v4Template(family: family.rawValue, band: band, index: 0)
            )
        }

        let accentBand: [BlueprintColour]
        if !colourResult.accentSlots.isEmpty {
            accentBand = colourResult.accentSlots.enumerated().map { index, slot in
                let label = index < accentLabelOverrides.count
                    ? accentLabelOverrides[index] : slot.displayName
                return BlueprintColour(
                    name: label,
                    hexValue: slot.hex,
                    role: .accent,
                    provenance: .chartDerivedAccent(
                        role: slot.role.rawValue,
                        sourcePlanet: slot.sourcePlanet.rawValue,
                        sourceSign: slot.sourceSign.rawValue,
                        saturationOverride: slot.saturationOverrideApplied
                    )
                )
            }
        } else {
            accentBand = accentLabelOverrides.enumerated().map { index, label in
                let originalName = colourResult.palette.accentColours[index]
                return BlueprintColour(
                    name: label,
                    hexValue: PaletteLibrary.hex(for: originalName),
                    role: .accent,
                    provenance: .v4Template(
                        family: family.rawValue, band: "accent", index: index
                    )
                )
            }
        }

        let neutralsBand = makeBand(names: colourResult.palette.neutrals, band: "neutrals", role: .neutral)
        let coreBand = makeBand(names: colourResult.palette.coreColours, band: "core", role: .core)
        let lightAnchorColour = makeAnchor(name: colourResult.palette.lightAnchor, band: "lightAnchor")
        let deepAnchorColour = makeAnchor(name: colourResult.palette.deepAnchor, band: "deepAnchor")

        var claimedTemplateNames = Set<String>()
        func claimNames(_ colours: [BlueprintColour]) {
            for c in colours { claimedTemplateNames.insert(c.name.lowercased()) }
        }
        claimNames(neutralsBand)
        claimNames(coreBand)
        claimNames(accentBand)
        if let support = supportBand { claimNames(support) }
        claimNames([lightAnchorColour, deepAnchorColour])

        let signatureLabels = PaletteLibrary.signaturePairLabels(
            luminaryHex: colourResult.luminarySignature,
            rulerHex: colourResult.rulerSignature,
            claimedTemplateNames: claimedTemplateNames
        )

        return PaletteSection(
            neutrals: neutralsBand,
            coreColours: coreBand,
            accentColours: accentBand,
            supportColours: supportBand,
            lightAnchor: lightAnchorColour,
            deepAnchor: deepAnchorColour,
            luminarySignature: BlueprintColour(
                name: signatureLabels.luminary,
                hexValue: colourResult.luminarySignature,
                role: .signature,
                provenance: .v4Template(family: family.rawValue, band: "luminarySignature", index: 0),
                semanticLabel: "luminary signature"
            ),
            rulerSignature: BlueprintColour(
                name: signatureLabels.ruler,
                hexValue: colourResult.rulerSignature,
                role: .signature,
                provenance: .v4Template(family: family.rawValue, band: "rulerSignature", index: 0),
                semanticLabel: "ruler signature"
            ),
            family: colourResult.family,
            cluster: colourResult.cluster,
            variables: colourResult.variables,
            secondaryPull: colourResult.secondaryPull,
            overrideFlags: colourResult.trace.overrideFlags,
            narrativeText: narrativeText
        )
    }

    // MARK: - Blueprint Decision Tree Diagnostics

    #if DEBUG
    private static func logBlueprintDiagnostics(
        analysis: ChartAnalysis,
        tokenResult: BlueprintTokenGenerator.TokenGenerationResult,
        resolved: DeterministicResolverResult,
        keyResult: ArchetypeKeyGenerator.KeyGenerationResult,
        resolvedKey: String,
        usedFallback: Bool,
        overlays: HouseSectOverlayGenerator.Overlays,
        templateContext: [String: String],
        narrativesMut: NarrativeClusterEntry,
        dataset: AstrologicalStyleDataset
    ) {
        let p = "[BlueprintDiag]"

        print("\(p) ╔══════════════════════════════════════════════════════════════")
        print("\(p) ║  BLUEPRINT DECISION TREE — FULL DIAGNOSTIC")
        print("\(p) ╚══════════════════════════════════════════════════════════════")

        // ── 1. CHART INPUT ──
        print("\(p)")
        print("\(p) ── 1. CHART INPUT ──────────────────────────────────────────")
        print("\(p) Sun: \(analysis.sunSign)   Moon: \(analysis.moonSign)   Ascendant: \(analysis.ascendantSign)")
        print("\(p) Venus: \(analysis.venusSign)   Mars: \(analysis.marsSign)")
        print("\(p) Chart Ruler: \(analysis.chartRuler)")
        print("\(p) Sect: \(analysis.chartSect) chart")
        print("\(p) Elements: fire=\(analysis.elementBalance.fire) earth=\(analysis.elementBalance.earth) air=\(analysis.elementBalance.air) water=\(analysis.elementBalance.water) → dominant: \(analysis.elementBalance.dominant)")
        print("\(p) Dominant planets: \(analysis.dominantPlanets.joined(separator: ", "))")

        print("\(p) Planet signs & houses:")
        for planet in ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"] {
            let sign = analysis.planetSigns[planet] ?? "—"
            let house = analysis.planetHouses[planet].map { "H\($0)" } ?? "—"
            let dignity = analysis.planetDignities[planet].map { "\($0)" } ?? "peregrine"
            let sect = analysis.planetSectStatus[planet].map { "\($0)" } ?? "—"
            print("\(p)   \(planet.padding(toLength: 9, withPad: " ", startingAt: 0)) \(sign.padding(toLength: 12, withPad: " ", startingAt: 0)) \(house.padding(toLength: 5, withPad: " ", startingAt: 0)) dignity=\(dignity.padding(toLength: 10, withPad: " ", startingAt: 0)) sect=\(sect)")
        }
        print("\(p)   Ascendant  \(analysis.ascendantSign)")

        // ── 2. CONTRIBUTING COMBOS ──
        print("\(p)")
        print("\(p) ── 2. CONTRIBUTING COMBOS (ranked by weight) ────────────────")
        for (i, combo) in tokenResult.contributingCombos.enumerated() {
            let marker = i < 5 ? "★" : " "
            print("\(p)   \(marker) #\(i + 1) \(combo.key.padding(toLength: 22, withPad: " ", startingAt: 0)) weight=\(String(format: "%.3f", combo.aggregateWeight))")
        }

        // Sign concentration
        var signGroups: [String: Int] = [:]
        for combo in tokenResult.contributingCombos {
            let parts = combo.key.split(separator: "_")
            if let sign = parts.last { signGroups[String(sign), default: 0] += 1 }
        }
        let stelliums = signGroups.filter { $0.value >= 3 }.sorted { $0.value > $1.value }
        if !stelliums.isEmpty {
            print("\(p)   Stelliums detected:")
            for (sign, count) in stelliums {
                print("\(p)     \(sign): \(count) combos (concentration bonus = +\(count - 2))")
            }
        } else {
            print("\(p)   No stelliums (3+ combos in one sign)")
        }

        // ── 3. NARRATIVE SELECTION ──
        print("\(p)")
        print("\(p) ── 3. NARRATIVE SELECTION ──────────────────────────────────")
        print("\(p) Archetype key: \(keyResult.archetypeCluster)")
        print("\(p) Venus=\(keyResult.venusComponent) Moon=\(keyResult.moonComponent) element=\(keyResult.elementComponent)")
        if usedFallback {
            print("\(p) ⚠️  FALLBACK: exact key not found → resolved to: \(resolvedKey)")
        } else {
            print("\(p) ✅ Exact match found")
        }

        // ── 4. HARDWARE (Metals & Stones) ──
        print("\(p)")
        print("\(p) ── 4. HARDWARE ─────────────────────────────────────────────")
        print("\(p) Sect bias: \(analysis.chartSect) → \(analysis.chartSect == .night ? "cool metals boosted +1" : "warm metals boosted +1")")

        print("\(p) Top 5 combo metals contribution:")
        for combo in tokenResult.contributingCombos.prefix(5) {
            if let entry = dataset.planetSign[combo.key] {
                print("\(p)   \(combo.key): metals=\(entry.metals) stones=\(entry.stones)")
            }
        }

        print("\(p) Final recommended metals: \(resolved.recommendedMetals.joined(separator: ", "))")
        print("\(p) Final recommended stones: \(resolved.recommendedStones.joined(separator: ", "))")

        // ── 5. TEXTURES ──
        print("\(p)")
        print("\(p) ── 5. TEXTURES ─────────────────────────────────────────────")
        print("\(p) Recommended: \(resolved.recommendedTextures.joined(separator: ", "))")
        print("\(p) Avoid: \(resolved.avoidTextures.joined(separator: ", "))")
        print("\(p) Sweet spot keywords: \(resolved.sweetSpotKeywords.joined(separator: ", "))")

        // ── 6. PATTERNS ──
        print("\(p)")
        print("\(p) ── 6. PATTERNS ─────────────────────────────────────────────")
        print("\(p) Recommended: \(resolved.recommendedPatterns.joined(separator: ", "))")
        print("\(p) Avoid: \(resolved.avoidPatterns.joined(separator: ", "))")

        // ── 7. CODE DIRECTIVES ──
        print("\(p)")
        print("\(p) ── 7. CODE DIRECTIVES ──────────────────────────────────────")
        print("\(p) Lean into: \(resolved.leanInto.joined(separator: " · "))")
        print("\(p) Avoid: \(resolved.avoid.joined(separator: " · "))")
        print("\(p) Consider: \(resolved.consider.joined(separator: " · "))")

        // ── 8. HOUSE/SECT OVERLAYS ──
        print("\(p)")
        print("\(p) ── 8. HOUSE/SECT OVERLAYS ──────────────────────────────────")
        let venusH = analysis.planetHouses["Venus"].map { "H\($0)" } ?? "—"
        let moonH = analysis.planetHouses["Moon"].map { "H\($0)" } ?? "—"
        print("\(p) Venus house: \(venusH)   Moon house: \(moonH)")
        print("\(p) Midheaven sign: \(analysis.midheavenSign)")
        print("\(p) style_core append: \(overlays.styleCoreAppend != nil ? "YES (\(overlays.styleCoreAppend!.prefix(60))…)" : "none")")
        print("\(p) textures_sweet_spot append: \(overlays.texturesSweetSpotAppend != nil ? "YES (\(overlays.texturesSweetSpotAppend!.prefix(60))…)" : "none")")
        print("\(p) occasions_work append: \(overlays.occasionsWorkAppend != nil ? "YES (\(overlays.occasionsWorkAppend!.prefix(60))…)" : "none")")
        print("\(p) occasions_intimate append: \(overlays.occasionsIntimateAppend != nil ? "YES (\(overlays.occasionsIntimateAppend!.prefix(60))…)" : "none")")
        print("\(p) occasions_daily append: \(overlays.occasionsDailyAppend != nil ? "YES (\(overlays.occasionsDailyAppend!.prefix(60))…)" : "none")")

        // ── 9. TEMPLATE RENDERING (Group B placeholders) ──
        print("\(p)")
        print("\(p) ── 9. TEMPLATE PLACEHOLDERS (Group B substitutions) ────────")
        let metalKeys = templateContext.filter { $0.key.hasPrefix("metal_") }.sorted { $0.key < $1.key }
        let stoneKeys = templateContext.filter { $0.key.hasPrefix("stone_") }.sorted { $0.key < $1.key }
        let textureKeys = templateContext.filter { $0.key.hasPrefix("texture_") }.sorted { $0.key < $1.key }
        let patternKeys = templateContext.filter { $0.key.hasPrefix("recommended_pattern_") || $0.key.hasPrefix("avoid_pattern_") }.sorted { $0.key < $1.key }
        let colourKeys = templateContext.filter { $0.key.hasPrefix("core_colour_") || $0.key.hasPrefix("accent_colour_") || $0.key.hasPrefix("neutral_colour_") }.sorted { $0.key < $1.key }
        let paletteVarKeys = templateContext.filter { ["family", "cluster", "depth", "temperature", "saturation", "contrast", "surface"].contains($0.key) }.sorted { $0.key < $1.key }

        for kv in metalKeys { print("\(p)   {\(kv.key)} → \(kv.value)") }
        for kv in stoneKeys { print("\(p)   {\(kv.key)} → \(kv.value)") }
        for kv in textureKeys { print("\(p)   {\(kv.key)} → \(kv.value)") }
        for kv in patternKeys { print("\(p)   {\(kv.key)} → \(kv.value)") }
        for kv in colourKeys { print("\(p)   {\(kv.key)} → \(kv.value)") }
        for kv in paletteVarKeys { print("\(p)   {\(kv.key)} → \(kv.value)") }

        // ── 10. FINAL NARRATIVE SECTIONS ──
        print("\(p)")
        print("\(p) ── 10. FINAL NARRATIVE SECTIONS (first 80 chars each) ──────")
        let sectionOrder: [(String, String)] = [
            ("style_core", "Style Core"),
            ("textures_good", "Textures: Good"),
            ("textures_bad", "Textures: Avoid"),
            ("textures_sweet_spot", "Textures: Sweet Spot"),
            ("palette_narrative", "Palette"),
            ("occasions_work", "Occasions: Work"),
            ("occasions_intimate", "Occasions: Intimate"),
            ("occasions_daily", "Occasions: Daily"),
            ("hardware_metals", "Hardware: Metals"),
            ("hardware_stones", "Hardware: Stones"),
            ("hardware_tip", "Hardware: Tip"),
            ("accessory_1", "Accessory §1"),
            ("accessory_2", "Accessory §2"),
            ("accessory_3", "Accessory §3"),
            ("pattern_narrative", "Pattern"),
            ("pattern_tip", "Pattern: Tip")
        ]
        for (key, label) in sectionOrder {
            let text = narrativesMut[key] ?? "(empty)"
            let preview = String(text.prefix(80)).replacingOccurrences(of: "\n", with: " ")
            let suffix = text.count > 80 ? "…" : ""
            print("\(p)   \(label.padding(toLength: 22, withPad: " ", startingAt: 0)) \(preview)\(suffix)")
        }

        print("\(p) ╔══════════════════════════════════════════════════════════════")
        print("\(p) ║  END BLUEPRINT DIAGNOSTIC")
        print("\(p) ╚══════════════════════════════════════════════════════════════")
    }
    #endif

    // MARK: - Pre-assembled (for testing or when steps are run separately)

    /// Assembles a CosmicBlueprint from pre-computed components.
    static func assemble(
        birthDate: Date,
        birthLocation: String,
        resolved: DeterministicResolverResult,
        narratives: NarrativeClusterEntry
    ) -> CosmicBlueprint {
        var narrativesMut = narratives
        let templateContext = NarrativeTemplateRenderer.buildContext(resolved: resolved)
        for sectionKey in NarrativeTemplateRenderer.groupBSections {
            guard let raw = narrativesMut[sectionKey], !raw.isEmpty else { continue }
            narrativesMut[sectionKey] = NarrativeTemplateRenderer.render(
                template: raw, context: templateContext
            )
        }

        let now = Date()

        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: birthDate,
                birthLocation: birthLocation,
                generationDate: now
            ),
            styleCore: StyleCoreSection(
                narrativeText: narrativesMut["style_core"] ?? ""
            ),
            textures: TexturesSection(
                goodText: narrativesMut["textures_good"] ?? "",
                badText: narrativesMut["textures_bad"] ?? "",
                sweetSpotText: narrativesMut["textures_sweet_spot"] ?? "",
                recommendedTextures: resolved.recommendedTextures,
                avoidTextures: resolved.avoidTextures,
                sweetSpotKeywords: resolved.sweetSpotKeywords
            ),
            palette: PaletteSection(
                coreColours: resolved.coreColours,
                accentColours: resolved.accentColours,
                swatchFamilies: resolved.swatchFamilies,
                narrativeText: narrativesMut["palette_narrative"] ?? ""
            ),
            occasions: OccasionsSection(
                workText: narrativesMut["occasions_work"] ?? "",
                intimateText: narrativesMut["occasions_intimate"] ?? "",
                dailyText: narrativesMut["occasions_daily"] ?? ""
            ),
            hardware: HardwareSection(
                metalsText: narrativesMut["hardware_metals"] ?? "",
                stonesText: narrativesMut["hardware_stones"] ?? "",
                tipText: narrativesMut["hardware_tip"] ?? "",
                recommendedMetals: resolved.recommendedMetals,
                recommendedStones: resolved.recommendedStones
            ),
            code: CodeSection(
                leanInto: resolved.leanInto,
                avoid: resolved.avoid,
                consider: resolved.consider
            ),
            accessory: AccessorySection(
                paragraphs: [
                    narrativesMut["accessory_1"] ?? "",
                    narrativesMut["accessory_2"] ?? "",
                    narrativesMut["accessory_3"] ?? ""
                ]
            ),
            pattern: PatternSection(
                narrativeText: narrativesMut["pattern_narrative"] ?? "",
                tipText: narrativesMut["pattern_tip"] ?? "",
                recommendedPatterns: resolved.recommendedPatterns,
                avoidPatterns: resolved.avoidPatterns
            ),
            generatedAt: now,
            engineVersion: engineVersion
        )
    }
}
