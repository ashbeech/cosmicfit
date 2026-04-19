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

    static let engineVersion = "2.0.0"

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

        var templateContext = NarrativeTemplateRenderer.buildContext(resolved: resolved)
        let v4Context = NarrativeTemplateRenderer.buildV4PaletteContext(colourResult: colourResult)
        templateContext.merge(v4Context) { _, v4 in v4 }

        for sectionKey in NarrativeTemplateRenderer.groupBSections {
            guard let raw = narrativesMut[sectionKey], !raw.isEmpty else { continue }
            narrativesMut[sectionKey] = NarrativeTemplateRenderer.render(
                template: raw, context: templateContext
            )
        }

        let paletteSection = buildV4PaletteSection(
            colourResult: colourResult,
            narrativeText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.paletteNarrative.rawValue] ?? ""
        )

        let now = Date()

        return CosmicBlueprint(
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
    }

    // MARK: - V4 Palette Builder

    private static func buildV4PaletteSection(
        colourResult: ColourEngineResult,
        narrativeText: String
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

        return PaletteSection(
            neutrals: makeBand(names: colourResult.palette.neutrals, band: "neutrals", role: .neutral),
            coreColours: makeBand(names: colourResult.palette.coreColours, band: "core", role: .core),
            accentColours: makeBand(names: colourResult.palette.accentColours, band: "accent", role: .accent),
            family: colourResult.family,
            cluster: colourResult.cluster,
            variables: colourResult.variables,
            secondaryPull: colourResult.secondaryPull,
            overrideFlags: colourResult.trace.overrideFlags,
            narrativeText: narrativeText
        )
    }

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
