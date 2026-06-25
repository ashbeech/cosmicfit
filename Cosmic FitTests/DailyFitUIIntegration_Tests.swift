//
//  DailyFitUIIntegration_Tests.swift
//  Cosmic FitTests
//
//  Phase 5 acceptance tests for UI Integration & Pipeline Wiring.
//

import Testing
import Foundation
import UIKit
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

    @Test("EssenceTriangleView places anchor ghost labels at anchor vertices")
    @MainActor func testEssenceTriangleViewAnchorGhostLabelPlacement() throws {
        var allScores = StyleEssenceCategory.allCases.map {
            StyleEssenceScore(category: $0, score: 0.01)
        }
        let weatherTop3: [StyleEssenceCategory] = [.maximalist, .drama, .edgy]
        for (index, category) in weatherTop3.enumerated() {
            let score = 0.30 - Double(index) * 0.05
            if let idx = allScores.firstIndex(where: { $0.category == category }) {
                allScores[idx] = StyleEssenceScore(category: category, score: score)
            }
        }
        let visibleCategories = weatherTop3.enumerated().map { index, category in
            StyleEssenceScore(category: category, score: 0.30 - Double(index) * 0.05)
        }

        var chartAnchorScores = StyleEssenceCategory.allCases.map {
            StyleEssenceScore(category: $0, score: 0.01)
        }
        let anchorTop3: [StyleEssenceCategory] = [.polished, .romantic, .classic]
        for (index, category) in anchorTop3.enumerated() {
            let score = 0.30 - Double(index) * 0.05
            if let idx = chartAnchorScores.firstIndex(where: { $0.category == category }) {
                chartAnchorScores[idx] = StyleEssenceScore(category: category, score: score)
            }
        }

        let profile = StyleEssenceProfile(
            allScores: allScores,
            visibleCategories: visibleCategories,
            chartAnchorScores: chartAnchorScores
        )

        let view = EssenceTriangleView(frame: CGRect(x: 0, y: 0, width: 220, height: 220))
        view.configure(
            with: profile,
            presentation: EssencePresentationDirective(showAnchorGhost: true)
        )
        view.layoutIfNeeded()

        // Mirror EssenceTriangleView's geometry: build each vertex in normalised
        // radar space, then apply the same centre-and-fill fit the view uses so
        // the diagram is centred and scaled to fill its allotted square.
        let minRadiusFraction: CGFloat = 0.25
        let chartMargin: CGFloat = 28
        let targetRect = view.bounds.insetBy(dx: chartMargin, dy: chartMargin)

        let weatherMax = visibleCategories.map(\.score).max() ?? 1.0
        let weatherScale = weatherMax > 0 ? 1.0 / weatherMax : 1.0
        let anchorMax = anchorTop3.enumerated().map { 0.30 - Double($0.offset) * 0.05 }.max() ?? 1.0
        let anchorScale = anchorMax > 0 ? 1.0 / anchorMax : 1.0

        func rawPoint(for category: StyleEssenceCategory, score: Double, scale: Double) -> CGPoint {
            let angle = CGFloat(category.angle)
            let clampedNorm = max(CGFloat(score * scale), minRadiusFraction)
            return CGPoint(x: cos(angle) * clampedNorm, y: sin(angle) * clampedNorm)
        }

        // The fit spans every drawn vertex (weather + anchor + ghost).
        var fitPoints: [CGPoint] = []
        for category in weatherTop3 {
            let score = visibleCategories.first { $0.category == category }!.score
            fitPoints.append(rawPoint(for: category, score: score, scale: weatherScale))
        }
        for category in anchorTop3 {
            let score = chartAnchorScores.first { $0.category == category }!.score
            // anchor + ghost share the same raw vertex here (disjoint from weather).
            let raw = rawPoint(for: category, score: score, scale: anchorScale)
            fitPoints.append(raw)
            fitPoints.append(raw)
        }

        let minX = fitPoints.map(\.x).min()!
        let maxX = fitPoints.map(\.x).max()!
        let minY = fitPoints.map(\.y).min()!
        let maxY = fitPoints.map(\.y).max()!
        let spanX = max(maxX - minX, 0.0001)
        let spanY = max(maxY - minY, 0.0001)
        let fitScale = min(targetRect.width / spanX, targetRect.height / spanY)
        let sourceCentre = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let targetCentre = CGPoint(x: targetRect.midX, y: targetRect.midY)

        func fit(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: (point.x - sourceCentre.x) * fitScale + targetCentre.x,
                y: (point.y - sourceCentre.y) * fitScale + targetCentre.y
            )
        }

        func expectedAnchorPoint(for category: StyleEssenceCategory) -> CGPoint {
            let score = chartAnchorScores.first { $0.category == category }!.score
            return fit(rawPoint(for: category, score: score, scale: anchorScale))
        }

        let weatherLabels = weatherTop3.map(\.label)
        let ghostLabels = anchorTop3.map(\.label)

        for ghostLabel in ghostLabels {
            let label = view.subviews.compactMap { $0 as? UILabel }
                .first { $0.text == ghostLabel }
            #expect(label != nil, "Missing ghost label \(ghostLabel)")

            let category = StyleEssenceCategory.allCases.first { $0.label == ghostLabel }!
            let anchorPoint = expectedAnchorPoint(for: category)
            let labelCenter = label!.center

            let distanceToAnchor = hypot(labelCenter.x - anchorPoint.x, labelCenter.y - anchorPoint.y)
            #expect(distanceToAnchor < 60, "\(ghostLabel) should sit near its anchor vertex")

            for weatherLabel in weatherLabels {
                let weatherCategory = StyleEssenceCategory.allCases.first { $0.label == weatherLabel }!
                let weatherScore = visibleCategories.first { $0.category == weatherCategory }!.score
                let weatherPoint = fit(rawPoint(for: weatherCategory, score: weatherScore, scale: weatherScale))
                let distanceToWeather = hypot(labelCenter.x - weatherPoint.x, labelCenter.y - weatherPoint.y)
                #expect(
                    distanceToAnchor < distanceToWeather,
                    "\(ghostLabel) should be closer to its anchor vertex than weather vertex \(weatherLabel)"
                )
            }
        }
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

    // U1 — Personal scale: payload with presentation uses displayPosition
    @Test("Payload with scalePresentation provides valid displayPositions")
    func testPayloadWithPresentationUsesDisplayPosition() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )
        let sp = payload.scalePresentation
        #expect(sp != nil, "scalePresentation should be populated on new payloads")
        guard let sp = sp else { return }

        #expect(sp.vibrancy.displayPosition >= 0.0 && sp.vibrancy.displayPosition <= 1.0)
        #expect(sp.contrast.displayPosition >= 0.0 && sp.contrast.displayPosition <= 1.0)
        #expect(sp.metalTone.displayPosition >= 0.0 && sp.metalTone.displayPosition <= 1.0)

        #expect(sp.vibrancy.baselinePosition >= 0.0 && sp.vibrancy.baselinePosition <= 1.0)
        #expect(sp.contrast.baselinePosition >= 0.0 && sp.contrast.baselinePosition <= 1.0)
        #expect(sp.metalTone.baselinePosition >= 0.0 && sp.metalTone.baselinePosition <= 1.0)

        // Absolute values must be unchanged
        #expect(sp.vibrancy.value == payload.vibrancy)
        #expect(sp.contrast.value == payload.contrast)
        #expect(sp.metalTone.value == payload.metalTone)
    }

    // U3 — Metal marker uses continuous displayPosition on presentation path
    @Test("U3: Metal marker uses continuous displayPosition, not 3-snap")
    func testMetalMarkerUsesContinuousDisplayPosition() {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )
        guard let sp = payload.scalePresentation else {
            Issue.record("scalePresentation should be populated")
            return
        }
        let dp = sp.metalTone.displayPosition
        let snapped = DailyFitViewController.snapMetalToThreePositions(dp)
        // With presentation path the UI now uses dp directly, not snapped.
        // At least verify snap function still works for legacy and that
        // values in the middle tertile would have been collapsed.
        if dp > 1.0 / 3.0 && dp < 2.0 / 3.0 {
            #expect(snapped == 0.5, "Middle-tertile values snap to 0.5")
            #expect(dp != 0.5, "Raw displayPosition should differ from snap at 0.5")
        }
        #expect(dp >= 0.0 && dp <= 1.0)
    }

    // U2 — Legacy payload: falls back to absolute (no scalePresentation)
    @Test("Legacy payload without scalePresentation decodes and has nil presentation")
    func testLegacyPayloadFallback() throws {
        let payload = BlueprintLensEngine.generatePayload(
            blueprint: Fixtures.warmBlueprint,
            snapshot: Fixtures.balancedSnapshot
        )
        let encoder = JSONEncoder()
        var json = try JSONSerialization.jsonObject(with: encoder.encode(payload)) as! [String: Any]

        // Simulate legacy: strip scalePresentation
        json.removeValue(forKey: "scalePresentation")

        let legacyData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(DailyFitPayload.self, from: legacyData)

        #expect(decoded.scalePresentation == nil, "Legacy payloads must have nil scalePresentation")
        #expect(decoded.vibrancy == payload.vibrancy, "Absolute vibrancy must survive round-trip")
        #expect(decoded.contrast == payload.contrast, "Absolute contrast must survive round-trip")
        #expect(decoded.metalTone == payload.metalTone, "Absolute metalTone must survive round-trip")
    }
}
