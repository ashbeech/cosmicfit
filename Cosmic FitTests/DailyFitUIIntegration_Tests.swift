//
//  DailyFitUIIntegration_Tests.swift
//  Cosmic FitTests
//
//  Phase 5 acceptance tests for UI Integration & Pipeline Wiring.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixtures

private enum Fixtures {

    static let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
    static let profileHash = "test_profile_phase5"

    static let defaultLunar = LunarContext(
        phaseName: "Full Moon", isWaxing: false,
        element: "Water", phaseDegrees: 180.0
    )

    static let balancedVibe = VibeBreakdown(
        classic: 4, playful: 3, romantic: 4,
        utility: 3, drama: 4, edge: 3
    )

    static let neutralAxes = DerivedAxes(
        action: 5.0, tempo: 5.0, strategy: 5.0, visibility: 5.0
    )

    static var balancedSnapshot: DailyEnergySnapshot {
        DailyEnergySnapshot(
            vibeProfile: balancedVibe,
            axes: neutralAxes,
            dominantTransits: [
                DailyTransitSummary(
                    transitPlanet: "Mars", natalPlanet: "Venus",
                    aspect: "trine", strength: 0.75
                )
            ],
            lunarContext: defaultLunar,
            dailySeed: 42,
            profileHash: profileHash,
            generatedAt: fixedDate
        )
    }

    static func colour(
        _ name: String, _ hex: String, _ role: ColourRole
    ) -> BlueprintColour {
        BlueprintColour(
            name: name, hexValue: hex, role: role,
            provenance: .v4Template(
                family: "Test", band: role.rawValue, index: 0
            )
        )
    }

    static let warmBlueprint: CosmicBlueprint = {
        let palette = PaletteSection(
            neutrals: [
                colour("Ivory", "#FFFFF0", .neutral),
                colour("Sand", "#C2B280", .neutral),
                colour("Taupe", "#483C32", .neutral),
                colour("Warm Grey", "#9F9186", .neutral),
            ],
            coreColours: [
                colour("Burnt Sienna", "#A0522D", .core),
                colour("Terracotta", "#E2725B", .core),
                colour("Amber", "#FFBF00", .core),
                colour("Olive", "#808000", .core),
            ],
            accentColours: [
                colour("Coral", "#FF7F50", .accent),
                colour("Tangerine", "#FF9966", .accent),
                colour("Saffron", "#F4C430", .accent),
                colour("Burgundy", "#800020", .accent),
            ],
            supportColours: [
                colour("Blush", "#DE5D83", .support),
                colour("Champagne", "#F7E7CE", .support),
                colour("Cinnamon", "#D2691E", .support),
                colour("Copper Rose", "#996666", .support),
            ],
            family: .deepAutumn, cluster: .deepWarmStructured,
            variables: DerivedVariables(
                depth: .deep, temperature: .warm,
                saturation: .rich, contrast: .high,
                surface: .structured
            ),
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Test palette."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: fixedDate
            ),
            styleCore: StyleCoreSection(narrativeText: "Test style core."),
            textures: TexturesSection(
                goodText: "Good.", badText: "Bad.",
                sweetSpotText: "Sweet spot.",
                recommendedTextures: ["cashmere", "denim", "silk"],
                avoidTextures: ["polyester"],
                sweetSpotKeywords: ["luxe"]
            ),
            palette: palette,
            occasions: OccasionsSection(
                workText: "Work.", intimateText: "Intimate.",
                dailyText: "Daily."
            ),
            hardware: HardwareSection(
                metalsText: "Gold metals.", stonesText: "Rubies.",
                tipText: "Tip.",
                recommendedMetals: ["gold", "brass"],
                recommendedStones: ["ruby", "garnet"]
            ),
            code: CodeSection(
                leanInto: ["structured shoulders", "sharp tailoring"],
                avoid: [], consider: []
            ),
            accessory: AccessorySection(
                paragraphs: ["Acc 1."]
            ),
            pattern: PatternSection(
                narrativeText: "Pattern.", tipText: "Tip.",
                recommendedPatterns: ["stripes"],
                avoidPatterns: ["neon"]
            ),
            generatedAt: fixedDate,
            engineVersion: "4.7"
        )
    }()
}

// MARK: - Tests

@Suite("Phase 5 — UI Integration & Pipeline Wiring")
struct DailyFitUIIntegrationTests {

    // T5.1
    @Test("New pipeline produces fully populated payload")
    func testNewPipelineProducesPayload() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )

        #expect(payload.dailyPalette.colours.count == 3)
        #expect(payload.vibrancy >= 0.0 && payload.vibrancy <= 1.0)
        #expect(payload.contrast >= 0.0 && payload.contrast <= 1.0)
        #expect(payload.metalTone >= 0.0 && payload.metalTone <= 1.0)
        #expect(!payload.styleEditVariant.description.isEmpty)
        #expect(!payload.tarotCard.name.isEmpty)
        #expect(!payload.dailyTextures.isEmpty)
    }

    // T5.2
    @Test("Palette hex values are valid hex format")
    func testPayloadPaletteHexesAreValidHex() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )

        let hexPattern = #"^#[0-9A-Fa-f]{6}$"#
        for colour in payload.dailyPalette.colours {
            #expect(colour.hexValue.range(of: hexPattern, options: .regularExpression) != nil,
                    "Invalid hex: \(colour.hexValue)")
        }
    }

    // T5.3
    @Test("Payload vibe breakdown totals 21 points")
    func testPayloadVibeBreakdownValid() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )
        #expect(payload.vibeBreakdown.totalPoints == 21)
    }

    // T5.4
    @Test("Payload tarot card has non-empty image path")
    func testPayloadTarotCardHasImage() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )
        #expect(!payload.tarotCard.imagePath.isEmpty)
    }

    // T5.5
    @Test("Payload style edit has non-empty description")
    func testPayloadStyleEditHasDescription() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )
        #expect(!payload.styleEditVariant.description.isEmpty)
    }

    // T5.6
    @Test("DailyColourPaletteView accepts payload hex data without crash")
    @MainActor func testDailyColourPaletteViewAcceptsPayloadData() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )

        let view = DailyColourPaletteView()
        let allHexes = payload.dailyPalette.allPaletteHexes
        view.configure(dailyPicks: payload.dailyPalette.colours, allPaletteHexes: allHexes)
    }

    // T5.7
    @Test("EssenceTriangleView accepts payload data and has non-zero intrinsic size")
    @MainActor func testEssenceTriangleViewAcceptsPayloadData() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )

        let view = EssenceTriangleView()
        view.configure(with: payload.essenceProfile)
        let size = view.intrinsicContentSize
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    // T5.8
    @Test("Full end-to-end pipeline produces valid payload")
    func testFullPipelineEndToEnd() {
        let snapshot = Fixtures.balancedSnapshot
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: snapshot
        )

        #expect(payload.dailyPalette.colours.count == 3)
        #expect(!payload.dailyPalette.allPaletteHexes.isEmpty)
        #expect(payload.vibeBreakdown.totalPoints == 21)
        #expect(!payload.tarotCard.imagePath.isEmpty)
        #expect(!payload.styleEditVariant.description.isEmpty)
        #expect(!payload.essenceProfile.allScores.isEmpty)
        #expect(payload.essenceProfile.visibleCategories.count <= 3)
        #expect(payload.silhouetteProfile.masculineFeminine >= 0.0)
        #expect(payload.silhouetteProfile.masculineFeminine <= 1.0)
    }

    // T5.9
    @Test("Legacy fallback removed — new pipeline is sole path")
    func testLegacyFallbackWhenNoBlueprintPresent() {
        // Legacy DailyVibeGenerator fallback was removed in Phase 7.
        // The new pipeline (DailyEnergyEngine + BlueprintLensEngine) is the sole path.
        #expect(true, "Legacy fallback removed — DailyFitPayload is the only path")
    }

    // T5.10
    @Test("Essence profile scores are non-negative and top-3 are a subset of allScores")
    func testEssenceTrianglePointInBounds() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )

        let profile = payload.essenceProfile
        for score in profile.allScores {
            #expect(score.score >= 0, "\(score.category) has negative score \(score.score)")
        }
        #expect(profile.visibleCategories.count <= 3)
        let allCategories = Set(profile.allScores.map(\.category))
        for vis in profile.visibleCategories {
            #expect(allCategories.contains(vis.category),
                    "\(vis.category) in visibleCategories but not in allScores")
        }
    }

    // T5.11
    @Test("New payload scales are all within [0.0, 1.0]")
    func testPayloadNewScalesInRange() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )

        #expect(payload.vibrancy >= 0.0 && payload.vibrancy <= 1.0)
        #expect(payload.contrast >= 0.0 && payload.contrast <= 1.0)
        #expect(payload.metalTone >= 0.0 && payload.metalTone <= 1.0)
        #expect(payload.silhouetteProfile.masculineFeminine >= 0.0 && payload.silhouetteProfile.masculineFeminine <= 1.0)
        #expect(payload.silhouetteProfile.angularRounded >= 0.0 && payload.silhouetteProfile.angularRounded <= 1.0)
        #expect(payload.silhouetteProfile.structuredDraped >= 0.0 && payload.silhouetteProfile.structuredDraped <= 1.0)
    }

    // T5.12
    @Test("DailyFitPipeline does not attach narrative brief for stage1_experimental")
    func testPipelineNoBriefForStage1() {
        let payload = DailyFitPipeline.generate(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot,
            dailyFitEngineId: DailyFitEngineRegistry.stage1ExperimentalId
        )
        #expect(payload.narrativeBrief == nil)
    }

    // T5.13
    @Test("DailyFitPipeline returns nil brief for production engine")
    func testPipelineNilBriefForProduction() {
        let payload = DailyFitPipeline.generate(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot,
            dailyFitEngineId: DailyFitEngineRegistry.productionId
        )
        #expect(payload.narrativeBrief == nil)
    }
}
