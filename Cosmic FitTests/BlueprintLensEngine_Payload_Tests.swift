//
//  BlueprintLensEngine_Payload_Tests.swift
//  Cosmic FitTests
//
//  Phase 4 acceptance tests for BlueprintLensEngine.generatePayload()
//  and all Blueprint-as-Lens derivations.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixtures

private enum Fixtures {

    static let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)
    static let profileHash = "test_profile_phase4"

    // MARK: Colour Helpers

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

    // MARK: Warm Palette Colours

    static let warmNeutrals = [
        colour("Ivory", "#FFFFF0", .neutral),
        colour("Sand", "#C2B280", .neutral),
        colour("Taupe", "#483C32", .neutral),
        colour("Warm Grey", "#9F9186", .neutral),
    ]
    static let warmCore = [
        colour("Burnt Sienna", "#A0522D", .core),
        colour("Terracotta", "#E2725B", .core),
        colour("Amber", "#FFBF00", .core),
        colour("Olive", "#808000", .core),
    ]
    static let warmAccent = [
        colour("Coral", "#FF7F50", .accent),
        colour("Tangerine", "#FF9966", .accent),
        colour("Saffron", "#F4C430", .accent),
        colour("Burgundy", "#800020", .accent),
    ]
    static let warmSupport = [
        colour("Blush", "#DE5D83", .support),
        colour("Champagne", "#F7E7CE", .support),
        colour("Cinnamon", "#D2691E", .support),
        colour("Copper Rose", "#996666", .support),
    ]

    // MARK: Cool Palette Colours

    static let coolNeutrals = [
        colour("Ice White", "#F0F0FF", .neutral),
        colour("Slate", "#708090", .neutral),
        colour("Cool Grey", "#9090A0", .neutral),
        colour("Charcoal", "#36454F", .neutral),
    ]
    static let coolCore = [
        colour("Navy", "#000080", .core),
        colour("Steel Blue", "#4682B4", .core),
        colour("Lavender", "#B0A0D0", .core),
        colour("Sage", "#87AE73", .core),
    ]
    static let coolAccent = [
        colour("Fuchsia", "#FF00FF", .accent),
        colour("Electric Blue", "#007FFF", .accent),
        colour("Violet", "#8B00FF", .accent),
        colour("Mint", "#3EB489", .accent),
    ]
    static let coolSupport = [
        colour("Mauve", "#E0B0FF", .support),
        colour("Periwinkle", "#CCCCFF", .support),
        colour("Dusty Rose", "#DCAE96", .support),
        colour("Silver Sage", "#C0C0B0", .support),
    ]

    // MARK: Blueprint Factory

    static func makeBlueprint(
        neutrals: [BlueprintColour],
        core: [BlueprintColour],
        accent: [BlueprintColour],
        support: [BlueprintColour],
        variables: DerivedVariables,
        family: PaletteFamily,
        cluster: PaletteCluster,
        metals: [String],
        code: CodeSection,
        luminarySignature: BlueprintColour? = nil,
        rulerSignature: BlueprintColour? = nil
    ) -> CosmicBlueprint {
        let palette = PaletteSection(
            neutrals: neutrals,
            coreColours: core,
            accentColours: accent,
            supportColours: support,
            luminarySignature: luminarySignature,
            rulerSignature: rulerSignature,
            family: family,
            cluster: cluster,
            variables: variables,
            secondaryPull: nil,
            overrideFlags: OverrideFlags(),
            narrativeText: "Test palette narrative."
        )
        return CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 0),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            styleCore: StyleCoreSection(narrativeText: "Test style core."),
            textures: TexturesSection(
                goodText: "Good textures.",
                badText: "Bad textures.",
                sweetSpotText: "Sweet spot.",
                recommendedTextures: ["cashmere", "denim", "silk", "leather"],
                avoidTextures: ["polyester", "nylon", "acrylic"],
                sweetSpotKeywords: ["luxe", "natural"]
            ),
            palette: palette,
            occasions: OccasionsSection(
                workText: "Work.", intimateText: "Intimate.",
                dailyText: "Daily."
            ),
            hardware: HardwareSection(
                metalsText: "Metals.", stonesText: "Stones.",
                tipText: "Tip.",
                recommendedMetals: metals,
                recommendedStones: ["ruby", "garnet"]
            ),
            code: code,
            accessory: AccessorySection(
                paragraphs: ["Acc 1.", "Acc 2.", "Acc 3."]
            ),
            pattern: PatternSection(
                narrativeText: "Pattern.", tipText: "Tip.",
                recommendedPatterns: [
                    "stripes", "herringbone", "abstract geometric"
                ],
                avoidPatterns: ["neon prints"]
            ),
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            engineVersion: "4.7"
        )
    }

    // MARK: Blueprint Instances

    /// Warm user: rich saturation, high contrast, warm temperature,
    /// gold metals, structured/sharp/angular code directives.
    static let warmBlueprint = makeBlueprint(
        neutrals: warmNeutrals, core: warmCore,
        accent: warmAccent, support: warmSupport,
        variables: DerivedVariables(
            depth: .deep, temperature: .warm,
            saturation: .rich, contrast: .high,
            surface: .structured
        ),
        family: .deepAutumn, cluster: .deepWarmStructured,
        metals: ["gold", "brass", "copper"],
        code: CodeSection(
            leanInto: [
                "structured shoulders", "sharp tailoring", "angular lines"
            ],
            avoid: [], consider: []
        )
    )

    /// Luminary and ruler signatures share one hex (mirrors real Deep Autumn clamps).
    static let duplicateSignatureHexBlueprint = makeBlueprint(
        neutrals: warmNeutrals, core: warmCore,
        accent: warmAccent, support: warmSupport,
        variables: DerivedVariables(
            depth: .deep, temperature: .warm,
            saturation: .rich, contrast: .high,
            surface: .structured
        ),
        family: .deepAutumn, cluster: .deepWarmStructured,
        metals: ["gold", "brass", "copper"],
        code: CodeSection(
            leanInto: ["structured shoulders", "sharp tailoring", "angular lines"],
            avoid: [], consider: []
        ),
        luminarySignature: colour("black cherry", "#751A2F", .signature),
        rulerSignature: colour("black cherry", "#751A2F", .signature)
    )

    /// Cool user: soft saturation, low contrast, cool temperature,
    /// silver metals, soft/relaxed/fluid code directives.
    static let coolBlueprint = makeBlueprint(
        neutrals: coolNeutrals, core: coolCore,
        accent: coolAccent, support: coolSupport,
        variables: DerivedVariables(
            depth: .light, temperature: .cool,
            saturation: .soft, contrast: .low,
            surface: .soft
        ),
        family: .lightSummer, cluster: .lightAiryCool,
        metals: ["silver", "platinum", "white gold"],
        code: CodeSection(
            leanInto: [
                "soft draping", "relaxed fits", "fluid layering"
            ],
            avoid: [], consider: []
        )
    )

    // MARK: Lunar Fixtures

    static let defaultLunar = LunarContext(
        phaseName: "Waxing Crescent", isWaxing: true,
        element: "Air", phaseDegrees: 45.0
    )

    // MARK: Vibe Profiles

    static let balancedVibe = VibeBreakdown(
        classic: 4, playful: 3, romantic: 4,
        utility: 3, drama: 4, edge: 3
    )
    static let dramaHeavyVibe = VibeBreakdown(
        classic: 1, playful: 1, romantic: 1,
        utility: 1, drama: 10, edge: 7
    )
    static let classicHeavyVibe = VibeBreakdown(
        classic: 10, playful: 2, romantic: 3,
        utility: 2, drama: 2, edge: 2
    )
    static let utilityHeavyVibe = VibeBreakdown(
        classic: 7, playful: 1, romantic: 1,
        utility: 10, drama: 1, edge: 1
    )

    /// Low-drama vibe for palette grounding tests (drama=2).
    static let lowDramaVibe = VibeBreakdown(
        classic: 5, playful: 3, romantic: 5,
        utility: 4, drama: 2, edge: 2
    )

    /// Boundary drama=3 — still quiet regime under new thresholds.
    static let drama3Vibe = VibeBreakdown(
        classic: 4, playful: 3, romantic: 4,
        utility: 4, drama: 3, edge: 3
    )

    /// Moderate-drama vibe (drama=4).
    static let moderateDramaVibe = VibeBreakdown(
        classic: 3, playful: 3, romantic: 3,
        utility: 3, drama: 4, edge: 5
    )

    // MARK: Snapshot Builders

    static let neutralAxes = DerivedAxes(
        action: 5.0, tempo: 5.0, strategy: 5.0, visibility: 5.0
    )

    static func snapshot(
        vibe: VibeBreakdown,
        axes: DerivedAxes = neutralAxes,
        transits: [DailyTransitSummary] = [],
        lunar: LunarContext = defaultLunar,
        seed: Int = 42
    ) -> DailyEnergySnapshot {
        DailyEnergySnapshot(
            vibeProfile: vibe,
            axes: axes,
            dominantTransits: transits,
            lunarContext: lunar,
            dailySeed: seed,
            profileHash: profileHash,
            generatedAt: fixedDate
        )
    }

    // MARK: Named Snapshots

    static let balancedSnap = snapshot(vibe: balancedVibe)
    static let dramaSnap = snapshot(vibe: dramaHeavyVibe)
    static let classicSnap = snapshot(vibe: classicHeavyVibe)
    static let utilitySnap = snapshot(vibe: utilityHeavyVibe)
    static let lowDramaSnap = snapshot(vibe: lowDramaVibe)
    static let drama3Snap = snapshot(vibe: drama3Vibe)
    static let moderateDramaSnap = snapshot(vibe: moderateDramaVibe)

    static let highVisDramaSnap = snapshot(
        vibe: dramaHeavyVibe,
        axes: DerivedAxes(
            action: 5.0, tempo: 5.0, strategy: 5.0, visibility: 8.0
        )
    )
    static let lowVisClassicSnap = snapshot(
        vibe: classicHeavyVibe,
        axes: DerivedAxes(
            action: 5.0, tempo: 5.0, strategy: 5.0, visibility: 3.0
        )
    )
    static let highStrategySnap = snapshot(
        vibe: balancedVibe,
        axes: DerivedAxes(
            action: 5.0, tempo: 5.0, strategy: 9.0, visibility: 5.0
        )
    )
    static let lowAxesSnap = snapshot(
        vibe: balancedVibe,
        axes: DerivedAxes(
            action: 3.0, tempo: 3.0, strategy: 3.0, visibility: 3.0
        )
    )
    static let highAxesSnap = snapshot(
        vibe: balancedVibe,
        axes: DerivedAxes(
            action: 8.0, tempo: 8.0, strategy: 8.0, visibility: 8.0
        )
    )

    // MARK: Calibration Fixtures

    /// Production-equivalent calibration with coreAnchoredRanking for testing.
    static let coreAnchoredCalibration: DailyFitCalibration = {
        var s2 = DailyFitCalibration.Stage2Sensitivity(
            paletteJitter: 0.08, vibrancyCoeff: 0.35,
            contrastCoeff: 0.40, silhouetteAxisScale: 2.0,
            metalNudgePerHit: 0.10,
            paletteSelectionStrategy: .coreAnchoredRanking
        )
        return DailyFitCalibration(
            sourceWeights: DailyFitCalibration.default.sourceWeights,
            signEnergyMap: DailyFitCalibration.default.signEnergyMap,
            signMultiplierPolicy: DailyFitCalibration.default.signMultiplierPolicy,
            planetAxisMap: DailyFitCalibration.default.planetAxisMap,
            selectionWeights: DailyFitCalibration.default.selectionWeights,
            axisTuning: DailyFitCalibration.default.axisTuning,
            stage2Sensitivity: s2
        )
    }()

    // MARK: Helpers

    static func allBlueprintHexValues(
        _ bp: CosmicBlueprint
    ) -> Set<String> {
        var hexes = Set<String>()
        if let n = bp.palette.neutrals { hexes.formUnion(n.map(\.hexValue)) }
        hexes.formUnion(bp.palette.coreColours.map(\.hexValue))
        hexes.formUnion(bp.palette.accentColours.map(\.hexValue))
        if let s = bp.palette.supportColours {
            hexes.formUnion(s.map(\.hexValue))
        }
        if let la = bp.palette.lightAnchor { hexes.insert(la.hexValue) }
        if let da = bp.palette.deepAnchor { hexes.insert(da.hexValue) }
        if let l = bp.palette.luminarySignature { hexes.insert(l.hexValue) }
        if let r = bp.palette.rulerSignature { hexes.insert(r.hexValue) }
        return hexes
    }
}

// MARK: - Test Suite (serialized to avoid shared tracker contention)

@Suite(.serialized)
struct BlueprintLensEngine_Payload_Tests {

    private func resetTrackers() {
        let suiteName = "com.cosmicfit.tests.\(UUID().uuidString)"
        let isolated = UserDefaults(suiteName: suiteName)!
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: isolated)
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: isolated)
        BlueprintLensEngine._resetCardCache()
    }

    // MARK: - T4.1: Payload Fully Populated

    @Test("T4.1 — generatePayload returns a fully populated DailyFitPayload")
    func testPayloadFullyPopulated() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    #expect(!p.tarotCard.name.isEmpty)
    #expect(!p.styleEditVariant.variant.isEmpty)
    #expect(p.dailyPalette.colours.count == 3)
    #expect(p.dailyTextures.count >= 2 && p.dailyTextures.count <= 3)
    #expect(p.vibrancy >= 0.0 && p.vibrancy <= 1.0)
    #expect(p.contrast >= 0.0 && p.contrast <= 1.0)
    #expect(p.metalTone >= 0.0 && p.metalTone <= 1.0)
}

// MARK: - T4.2: Palette Colours From Blueprint

@Test("T4.2 — every palette colour hexValue exists in the Blueprint")
func testPaletteColoursFromBlueprint() {
    resetTrackers()
    let bp = Fixtures.warmBlueprint
    let p = BlueprintLensEngine.generatePayload(
        blueprint: bp, snapshot: Fixtures.dramaSnap
    )
    let allHex = Fixtures.allBlueprintHexValues(bp)
    for pick in p.dailyPalette.colours {
        #expect(allHex.contains(pick.hexValue),
                "\(pick.name) hex \(pick.hexValue) not in Blueprint palette")
    }
}

// MARK: - T4.3: Palette Has 3 Colours

@Test("T4.3 — dailyPalette always contains exactly 3 colours")
func testPaletteHas3Colours() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    #expect(p.dailyPalette.colours.count == 3)
}

// MARK: - T4.4: Palette Diversity

@Test("T4.4 — low drama (≤3) palette contains zero accent/signature/statement colours")
func testPaletteLowDramaAllGrounding() {
    resetTrackers()
    let statementRoles: Set<String> = ["accent", "signature", "statement"]
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.lowDramaSnap
    )
    let statementCount = p.dailyPalette.colours.filter {
        statementRoles.contains($0.role)
    }.count
    #expect(statementCount == 0,
            "Low-drama day should have 0 statement colours, got \(statementCount): \(p.dailyPalette.colours.map { "\($0.name) (\($0.role))" })")
}

@Test("T4.4 boundary — drama=3 is still quiet (0 statement colours)")
func testPaletteDrama3StillQuiet() {
    resetTrackers()
    let statementRoles: Set<String> = ["accent", "signature", "statement"]
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.drama3Snap
    )
    let statementCount = p.dailyPalette.colours.filter {
        statementRoles.contains($0.role)
    }.count
    #expect(statementCount == 0,
            "Drama=3 should still be quiet (0 statement), got \(statementCount): \(p.dailyPalette.colours.map { "\($0.name) (\($0.role))" })")
}

@Test("T4.4a — moderate drama (3–4) palette has exactly 1 statement colour")
func testPaletteModerateDramaOneStatement() {
    resetTrackers()
    let statementRoles: Set<String> = ["accent", "signature", "statement"]
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.moderateDramaSnap
    )
    let statementCount = p.dailyPalette.colours.filter {
        statementRoles.contains($0.role)
    }.count
    #expect(statementCount == 1,
            "Moderate-drama day should have 1 statement colour, got \(statementCount): \(p.dailyPalette.colours.map { "\($0.name) (\($0.role))" })")
}

@Test("T4.4b — high drama (5+) palette has at least 1 grounding colour")
func testPaletteHighDramaStillGrounded() {
    resetTrackers()
    let statementRoles: Set<String> = ["accent", "signature", "statement"]
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.dramaSnap
    )
    let groundingCount = p.dailyPalette.colours.filter {
        !statementRoles.contains($0.role)
    }.count
    #expect(groundingCount >= 1,
            "High-drama day must still have ≥1 grounding colour, got \(groundingCount): \(p.dailyPalette.colours.map { "\($0.name) (\($0.role))" })")
}

@Test("T4.4c — daily palette never repeats the same hex (even when signatures collide)")
func testPaletteNoDuplicateHexes() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.duplicateSignatureHexBlueprint,
        snapshot: Fixtures.dramaSnap
    )
    let hexes = p.dailyPalette.colours.map {
        $0.hexValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    #expect(Set(hexes).count == 3, "Duplicate hex in daily picks: \(hexes)")
}

// MARK: - T4.5: All Palette Hexes Complete

@Test("T4.5 — allPaletteHexes contains every Blueprint colour hex")
func testAllPaletteHexesComplete() {
    resetTrackers()
    let bp = Fixtures.warmBlueprint
    let p = BlueprintLensEngine.generatePayload(
        blueprint: bp, snapshot: Fixtures.balancedSnap
    )
    let outputSet = Set(p.dailyPalette.allPaletteHexes)
    let coreHexes = bp.palette.coreColours.map(\.hexValue)
    let accentHexes = bp.palette.accentColours.map(\.hexValue)
    let neutralHexes = bp.palette.neutrals?.map(\.hexValue) ?? []
    let supportHexes = bp.palette.supportColours?.map(\.hexValue) ?? []
    let anchorHexes = [bp.palette.lightAnchor?.hexValue, bp.palette.deepAnchor?.hexValue].compactMap { $0 }

    for hex in coreHexes + accentHexes + neutralHexes + supportHexes + anchorHexes {
        #expect(outputSet.contains(hex),
                "Missing hex \(hex) from allPaletteHexes")
    }
}

// MARK: - T4.6: Textures From Blueprint

@Test("T4.6 — every texture in dailyTextures is from recommendedTextures")
func testTexturesFromBlueprint() {
    resetTrackers()
    let bp = Fixtures.warmBlueprint
    let p = BlueprintLensEngine.generatePayload(
        blueprint: bp, snapshot: Fixtures.balancedSnap
    )
    let allowed = Set(bp.textures.recommendedTextures)
    for tex in p.dailyTextures {
        #expect(allowed.contains(tex),
                "Texture '\(tex)' not in recommendedTextures")
    }
}

// MARK: - T4.7: Texture Count

@Test("T4.7 — dailyTextures count is 2 or 3")
func testTextureCount() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    #expect(p.dailyTextures.count >= 2 && p.dailyTextures.count <= 3,
            "Expected 2-3 textures, got \(p.dailyTextures.count)")
}

// MARK: - T4.8: Pattern Nil When Low Visibility

@Test("T4.8 — pattern is nil with low visibility and classic dominant")
func testPatternNilWhenLowVisibility() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.lowVisClassicSnap
    )
    #expect(p.dailyPattern == nil,
            "Expected nil pattern with visibility=3, classic dominant")
}

// MARK: - T4.9: Pattern Present When High Visibility

@Test("T4.9 — pattern is non-nil with high visibility and drama dominant")
func testPatternPresentWhenHighVisibility() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.highVisDramaSnap
    )
    #expect(p.dailyPattern != nil,
            "Expected pattern with visibility=8, drama dominant")
}

// MARK: - T4.10: Pattern From Blueprint

@Test("T4.10 — if pattern is non-nil it exists in recommendedPatterns")
func testPatternFromBlueprint() {
    resetTrackers()
    let bp = Fixtures.warmBlueprint
    let p = BlueprintLensEngine.generatePayload(
        blueprint: bp, snapshot: Fixtures.highVisDramaSnap
    )
    if let pat = p.dailyPattern {
        #expect(bp.pattern.recommendedPatterns.contains(pat),
                "Pattern '\(pat)' not in recommendedPatterns")
    }
}

// MARK: - T4.11: Payload Deterministic

@Test("T4.11 — same inputs produce identical payload")
func testPayloadDeterministic() {
    resetTrackers()
    let p1 = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    resetTrackers()
    let p2 = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )

    #expect(p1.tarotCard.name == p2.tarotCard.name)
    #expect(p1.styleEditVariant.variant == p2.styleEditVariant.variant)
    #expect(p1.styleEditVariant.title == p2.styleEditVariant.title)
    #expect(p1.dailyPalette.colours.count == p2.dailyPalette.colours.count)
    for i in 0..<p1.dailyPalette.colours.count {
        #expect(p1.dailyPalette.colours[i].hexValue
                == p2.dailyPalette.colours[i].hexValue)
    }
    #expect(p1.vibrancy == p2.vibrancy)
    #expect(p1.contrast == p2.contrast)
    #expect(p1.metalTone == p2.metalTone)
    #expect(p1.essenceProfile == p2.essenceProfile)
    #expect(p1.silhouetteProfile == p2.silhouetteProfile)
    #expect(p1.dailyTextures == p2.dailyTextures)
    #expect(p1.dailyPattern == p2.dailyPattern)
}

// MARK: - T4.12: Different Snapshots → Different Palettes

@Test("T4.12 — drama vs classic snapshots produce different palettes")
func testDifferentSnapshotsProduceDifferentPalettes() {
    resetTrackers()
    let p1 = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.dramaSnap
    )
    resetTrackers()
    let p2 = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.classicSnap
    )
    let hexes1 = Set(p1.dailyPalette.colours.map(\.hexValue))
    let hexes2 = Set(p2.dailyPalette.colours.map(\.hexValue))
    #expect(hexes1 != hexes2,
            "Expected at least 1 colour difference between drama and classic palettes")
}

// MARK: - T4.13: Payload Codable Round Trip

@Test("T4.13 — DailyFitPayload encodes and decodes with field equality")
func testPayloadCodableRoundTrip() throws {
    resetTrackers()
    let original = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(DailyFitPayload.self, from: data)

    #expect(decoded.tarotCard.name == original.tarotCard.name)
    #expect(decoded.styleEditVariant.variant == original.styleEditVariant.variant)
    #expect(decoded.styleEditVariant.description
            == original.styleEditVariant.description)
    #expect(decoded.dailyPalette == original.dailyPalette)
    #expect(decoded.vibrancy == original.vibrancy)
    #expect(decoded.contrast == original.contrast)
    #expect(decoded.metalTone == original.metalTone)
    #expect(decoded.essenceProfile == original.essenceProfile)
    #expect(decoded.silhouetteProfile == original.silhouetteProfile)
    #expect(decoded.dailyTextures == original.dailyTextures)
    #expect(decoded.dailyPattern == original.dailyPattern)
    #expect(decoded.dominantTransits == original.dominantTransits)
    #expect(decoded.lunarContext == original.lunarContext)
    #expect(abs(decoded.generatedAt.timeIntervalSince1970
                - original.generatedAt.timeIntervalSince1970) < 0.01)
}

// MARK: - T4.14: Vibe Breakdown Passed Through

@Test("T4.14 — payload.vibeBreakdown matches snapshot.vibeProfile")
func testPayloadVibeBreakdownPassedThrough() {
    resetTrackers()
    let snap = Fixtures.dramaSnap
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: snap
    )
    #expect(p.vibeBreakdown.classic == snap.vibeProfile.classic)
    #expect(p.vibeBreakdown.playful == snap.vibeProfile.playful)
    #expect(p.vibeBreakdown.romantic == snap.vibeProfile.romantic)
    #expect(p.vibeBreakdown.utility == snap.vibeProfile.utility)
    #expect(p.vibeBreakdown.drama == snap.vibeProfile.drama)
    #expect(p.vibeBreakdown.edge == snap.vibeProfile.edge)
}

// MARK: - T4.15: Axes Passed Through

@Test("T4.15 — payload.axes matches snapshot.axes")
func testPayloadAxesPassedThrough() {
    resetTrackers()
    let snap = Fixtures.balancedSnap
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: snap
    )
    #expect(p.axes.action == snap.axes.action)
    #expect(p.axes.tempo == snap.axes.tempo)
    #expect(p.axes.strategy == snap.axes.strategy)
    #expect(p.axes.visibility == snap.axes.visibility)
}

// MARK: - T4.16: Vibrancy Anchors To Blueprint

@Test("T4.16 — vibrancy anchors to Blueprint palette saturation baseline")
func testVibrancyAnchorsToBlueprint() {
    resetTrackers()
    let softDrama = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.coolBlueprint, snapshot: Fixtures.dramaSnap
    )
    resetTrackers()
    let richDrama = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.dramaSnap
    )
    #expect(richDrama.vibrancy > softDrama.vibrancy,
            "Rich baseline should exceed soft for same energy; rich=\(richDrama.vibrancy) soft=\(softDrama.vibrancy)")

    resetTrackers()
    let softUtil = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.coolBlueprint, snapshot: Fixtures.utilitySnap
    )
    resetTrackers()
    let richUtil = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.utilitySnap
    )
    #expect(richUtil.vibrancy > softUtil.vibrancy,
            "Rich baseline should exceed soft for same energy; rich=\(richUtil.vibrancy) soft=\(softUtil.vibrancy)")
}

// MARK: - T4.17: Vibrancy Varies With Energy

@Test("T4.17 — same Blueprint, drama vs utility snapshots differ by ≥ 0.05")
func testVibrancyVariesWithEnergy() {
    resetTrackers()
    let dramaPay = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.dramaSnap
    )
    resetTrackers()
    let utilPay = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.utilitySnap
    )
    let diff = abs(dramaPay.vibrancy - utilPay.vibrancy)
    #expect(diff >= 0.05,
            "Expected vibrancy diff >= 0.05, got \(diff)")
}

// MARK: - T4.18: Contrast Anchors To Blueprint

@Test("T4.18 — low contrast Blueprint never > 0.50; high contrast never < 0.50")
func testContrastAnchorsToBlueprint() {
    resetTrackers()
    let lowCon = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.coolBlueprint,
        snapshot: Fixtures.highAxesSnap
    )
    #expect(lowCon.contrast <= 0.50,
            "Low contrast BP + high vis should be ≤ 0.50, got \(lowCon.contrast)")

    resetTrackers()
    let highCon = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.lowAxesSnap
    )
    #expect(highCon.contrast >= 0.50,
            "High contrast BP + low vis should be ≥ 0.50, got \(highCon.contrast)")
}

// MARK: - T4.19: Metal Tone Reflects Temperature

@Test("T4.19 — warm BP+gold → metalTone > 0.6; cool BP+silver → metalTone < 0.4")
func testMetalToneReflectsTemperature() {
    resetTrackers()
    let warmPay = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    #expect(warmPay.metalTone > 0.6,
            "Warm temp + gold metals should give > 0.6, got \(warmPay.metalTone)")

    resetTrackers()
    let coolPay = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.coolBlueprint, snapshot: Fixtures.balancedSnap
    )
    #expect(coolPay.metalTone < 0.4,
            "Cool temp + silver metals should give < 0.4, got \(coolPay.metalTone)")
}

// MARK: - T4.20: Style Essence Has 14 Categories With Top 3

@Test("T4.20 — essenceProfile has 14 scores and 3 visible categories")
func testStyleEssenceProfileStructure() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    #expect(p.essenceProfile.allScores.count == 14,
            "Expected 14 categories, got \(p.essenceProfile.allScores.count)")
    #expect(p.essenceProfile.visibleCategories.count == 3,
            "Expected top 3, got \(p.essenceProfile.visibleCategories.count)")
    for score in p.essenceProfile.allScores {
        #expect(score.score >= 0.0 && score.score <= 1.0,
                "\(score.category) out of range: \(score.score)")
    }
}

// MARK: - T4.21: Drama-Heavy → Drama or Edgy in Top 3

@Test("T4.21 — drama=10, edge=7 → drama or edgy in visible top 3")
func testStyleEssenceDramaHeavy() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.dramaSnap
    )
    let topCategories = Set(p.essenceProfile.visibleCategories.map(\.category))
    let hasDramaOrEdgy = topCategories.contains(.drama) || topCategories.contains(.edgy)
    #expect(hasDramaOrEdgy,
            "Expected drama or edgy in top 3 for drama-heavy snap, got \(topCategories)")
}

// MARK: - T4.22: Visible Categories Are Sorted Descending

@Test("T4.22 — visible categories are sorted by score descending")
func testStyleEssenceVisibleSortOrder() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    let vis = p.essenceProfile.visibleCategories
    for i in 0..<(vis.count - 1) {
        #expect(vis[i].score >= vis[i + 1].score,
                "Top-3 not sorted: \(vis[i].category)=\(vis[i].score) < \(vis[i+1].category)=\(vis[i+1].score)")
    }
}

// MARK: - T4.23: Silhouette Baseline Dominates

@Test("T4.23 — same BP, different axes → silhouette values change ≤ 0.25")
func testSilhouetteBaselineDominates() {
    resetTrackers()
    let lowPay = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.lowAxesSnap
    )
    resetTrackers()
    let highPay = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.highAxesSnap
    )
    let mfDiff = abs(lowPay.silhouetteProfile.masculineFeminine
                     - highPay.silhouetteProfile.masculineFeminine)
    let arDiff = abs(lowPay.silhouetteProfile.angularRounded
                     - highPay.silhouetteProfile.angularRounded)
    let sdDiff = abs(lowPay.silhouetteProfile.structuredDraped
                     - highPay.silhouetteProfile.structuredDraped)

    #expect(mfDiff <= 0.25,
            "masculineFeminine change = \(mfDiff), expected ≤ 0.25")
    #expect(arDiff <= 0.25,
            "angularRounded change = \(arDiff), expected ≤ 0.25")
    #expect(sdDiff <= 0.25,
            "structuredDraped change = \(sdDiff), expected ≤ 0.25")
}

// MARK: - T4.24: Silhouette High Strategy → Structured

@Test("T4.24 — strategy=9 → structuredDraped < 0.50")
func testSilhouetteHighStrategyShiftsStructured() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.highStrategySnap
    )
    #expect(p.silhouetteProfile.structuredDraped < 0.50,
            "Expected < 0.50 with strategy=9, got \(p.silhouetteProfile.structuredDraped)")
}

// MARK: - T4.25: Silhouette Values In Range

@Test("T4.25 — all 3 silhouette values between 0.0 and 1.0")
func testSilhouetteValuesInRange() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.balancedSnap
    )
    let s = p.silhouetteProfile
    #expect(s.masculineFeminine >= 0.0 && s.masculineFeminine <= 1.0)
    #expect(s.angularRounded >= 0.0 && s.angularRounded <= 1.0)
    #expect(s.structuredDraped >= 0.0 && s.structuredDraped <= 1.0)
}

// MARK: - T4.26: Vibrancy / Contrast / Metal Tone In Range

@Test("T4.26 — vibrancy, contrast, metalTone all in [0.0, 1.0]")
func testVibrancyContrastMetalToneInRange() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint, snapshot: Fixtures.dramaSnap
    )
    #expect(p.vibrancy >= 0.0 && p.vibrancy <= 1.0)
    #expect(p.contrast >= 0.0 && p.contrast <= 1.0)
    #expect(p.metalTone >= 0.0 && p.metalTone <= 1.0)
}
// MARK: - T4.27: coreAnchoredRanking — at least 1 core colour in every pick set

@Test("T4.27 — coreAnchoredRanking always includes at least 1 core colour")
func testCoreAnchoredRankingAlwaysHasCore() {
    resetTrackers()
    let snapshots = [
        Fixtures.dramaSnap, Fixtures.classicSnap,
        Fixtures.balancedSnap, Fixtures.lowDramaSnap,
        Fixtures.moderateDramaSnap, Fixtures.utilitySnap,
    ]
    for snap in snapshots {
        resetTrackers()
        let p = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: snap,
            calibration: Fixtures.coreAnchoredCalibration
        )
        let coreCount = p.dailyPalette.colours.filter { $0.role == "core" }.count
        #expect(coreCount >= 1,
                "coreAnchoredRanking must pick ≥1 core, got \(coreCount): \(p.dailyPalette.colours.map { "\($0.name) (\($0.role))" })")
    }
}

// MARK: - T4.28: coreAnchoredRanking — never all statement/accent/signature

@Test("T4.28 — coreAnchoredRanking never picks 3 accent/signature/statement colours")
func testCoreAnchoredRankingNeverAllStatement() {
    resetTrackers()
    let statementRoles: Set<String> = ["accent", "signature", "statement"]
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.dramaSnap,
        calibration: Fixtures.coreAnchoredCalibration
    )
    let statementCount = p.dailyPalette.colours.filter {
        statementRoles.contains($0.role)
    }.count
    #expect(statementCount < 3,
            "coreAnchoredRanking should never have 3 statement colours, got \(statementCount)")
}

// MARK: - T4.29: coreAnchoredRanking — 3 unique hexes

@Test("T4.29 — coreAnchoredRanking produces 3 unique hexes")
func testCoreAnchoredRankingNoDuplicateHexes() {
    resetTrackers()
    let p = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.duplicateSignatureHexBlueprint,
        snapshot: Fixtures.dramaSnap,
        calibration: Fixtures.coreAnchoredCalibration
    )
    let hexes = p.dailyPalette.colours.map {
        $0.hexValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    #expect(Set(hexes).count == 3, "Duplicate hex in coreAnchoredRanking picks: \(hexes)")
}

// MARK: - T4.30: coreAnchoredRanking — drama vs classic produce different palettes

@Test("T4.30 — coreAnchoredRanking: drama vs classic snapshots produce different palettes")
func testCoreAnchoredRankingDifferentSnapshotsDiffer() {
    resetTrackers()
    let p1 = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.dramaSnap,
        calibration: Fixtures.coreAnchoredCalibration
    )
    resetTrackers()
    let p2 = BlueprintLensEngine.generatePayload(
        blueprint: Fixtures.warmBlueprint,
        snapshot: Fixtures.classicSnap,
        calibration: Fixtures.coreAnchoredCalibration
    )
    let hexes1 = Set(p1.dailyPalette.colours.map(\.hexValue))
    let hexes2 = Set(p2.dailyPalette.colours.map(\.hexValue))
    #expect(hexes1 != hexes2,
            "Expected different palettes for drama vs classic under coreAnchoredRanking")
}

// MARK: - T4.31: production preset still uses dramaSlots

@Test("T4.31 — production calibration defaults to dramaSlots strategy")
func testProductionDefaultIsDramaSlots() {
    let prodCal = DailyFitCalibration.default
    #expect(prodCal.stage2Sensitivity.paletteSelectionStrategy == .dramaSlots)

    let prodDescriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)
    #expect(prodDescriptor?.calibration.stage2Sensitivity.paletteSelectionStrategy == .dramaSlots)
}

// MARK: - T4.32: stage1_experimental preset uses pureSkyScoring

@Test("T4.32 — stage1_experimental calibration uses pureSkyScoring strategy")
func testStage1ExperimentalIsPureSkyScoring() {
    let descriptor = DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.stage1ExperimentalId)
    #expect(descriptor?.calibration.stage2Sensitivity.paletteSelectionStrategy == .pureSkyScoring)
    #expect(descriptor?.calibration.axisTuning.sigmoidSpread == 0.8)
}

// MARK: - T4.33: coreAnchoredRanking — picks from blueprint pool

@Test("T4.33 — coreAnchoredRanking: every colour hex exists in the Blueprint")
func testCoreAnchoredRankingColoursFromBlueprint() {
    resetTrackers()
    let bp = Fixtures.warmBlueprint
    let p = BlueprintLensEngine.generatePayload(
        blueprint: bp,
        snapshot: Fixtures.dramaSnap,
        calibration: Fixtures.coreAnchoredCalibration
    )
    let allHex = Fixtures.allBlueprintHexValues(bp)
    for pick in p.dailyPalette.colours {
        #expect(allHex.contains(pick.hexValue),
                "\(pick.name) hex \(pick.hexValue) not in Blueprint palette")
    }
}

} // BlueprintLensEngine_Payload_Tests
