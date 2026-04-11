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

    static let engineVersion = "1.0.0"

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

        let tokenResult = BlueprintTokenGenerator.generate(
            analysis: analysis,
            dataset: dataset
        )

        let resolved = DeterministicResolver.resolve(
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
                sweetSpotText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.texturesSweetSpot.rawValue] ?? ""
            ),
            palette: PaletteSection(
                coreColours: resolved.coreColours,
                accentColours: resolved.accentColours,
                narrativeText: narrativesMut[BlueprintArchetypeKey.BlueprintSection.paletteNarrative.rawValue] ?? ""
            ),
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

    // MARK: - Pre-assembled (for testing or when steps are run separately)

    /// Assembles a CosmicBlueprint from pre-computed components.
    static func assemble(
        birthDate: Date,
        birthLocation: String,
        resolved: DeterministicResolverResult,
        narratives: NarrativeClusterEntry
    ) -> CosmicBlueprint {
        let now = Date()

        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: birthDate,
                birthLocation: birthLocation,
                generationDate: now
            ),
            styleCore: StyleCoreSection(
                narrativeText: narratives["style_core"] ?? ""
            ),
            textures: TexturesSection(
                goodText: narratives["textures_good"] ?? "",
                badText: narratives["textures_bad"] ?? "",
                sweetSpotText: narratives["textures_sweet_spot"] ?? ""
            ),
            palette: PaletteSection(
                coreColours: resolved.coreColours,
                accentColours: resolved.accentColours,
                narrativeText: narratives["palette_narrative"] ?? ""
            ),
            occasions: OccasionsSection(
                workText: narratives["occasions_work"] ?? "",
                intimateText: narratives["occasions_intimate"] ?? "",
                dailyText: narratives["occasions_daily"] ?? ""
            ),
            hardware: HardwareSection(
                metalsText: narratives["hardware_metals"] ?? "",
                stonesText: narratives["hardware_stones"] ?? "",
                tipText: narratives["hardware_tip"] ?? "",
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
                    narratives["accessory_1"] ?? "",
                    narratives["accessory_2"] ?? "",
                    narratives["accessory_3"] ?? ""
                ]
            ),
            pattern: PatternSection(
                narrativeText: narratives["pattern_narrative"] ?? "",
                tipText: narratives["pattern_tip"] ?? "",
                recommendedPatterns: resolved.recommendedPatterns,
                avoidPatterns: resolved.avoidPatterns
            ),
            generatedAt: now,
            engineVersion: engineVersion
        )
    }
}
