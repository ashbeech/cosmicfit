import Testing
import Foundation
@testable import Cosmic_Fit

/// Verifies that pattern/hardware narrative sections use V4 palette placeholders
/// instead of hardcoded colour literals, and that the full compose pipeline
/// resolves them to actual palette colour names.
@Suite("NarrativePaletteCoherence")
struct NarrativePaletteCoherence_Tests {

    private static let paletteLiterals = [
        "burnt sienna", "burnt siennas", "cobalt blue", "deep cobalt", "warm ochre",
        "ochre", "ochres", "sienna", "siennas", "cobalt",
        "fire red", "electric blue", "silver grey", "jet black",
        "bright coral", "deep coral", "coral",
    ]

    // MARK: - Romford Regression

    @Test("Romford (1964-12-21 unknown time): pattern tip + narrative contain no palette literals")
    func romfordNoLiterals() {
        let bp = composeRomford()

        for literal in Self.paletteLiterals {
            #expect(!bp.pattern.tipText.localizedCaseInsensitiveContains(literal),
                    "pattern.tipText contains hardcoded palette literal \"\(literal)\": \(bp.pattern.tipText.prefix(120))")
            #expect(!bp.pattern.narrativeText.localizedCaseInsensitiveContains(literal),
                    "pattern.narrativeText contains hardcoded palette literal \"\(literal)\": \(bp.pattern.narrativeText.prefix(120))")
            #expect(!bp.hardware.metalsText.localizedCaseInsensitiveContains(literal),
                    "hardware.metalsText contains hardcoded palette literal \"\(literal)\"")
            #expect(!bp.hardware.stonesText.localizedCaseInsensitiveContains(literal),
                    "hardware.stonesText contains hardcoded palette literal \"\(literal)\"")
            #expect(!bp.hardware.tipText.localizedCaseInsensitiveContains(literal),
                    "hardware.tipText contains hardcoded palette literal \"\(literal)\"")
        }
    }

    @Test("Romford: rendered colour names in tip/narrative appear in palette lists")
    func romfordPaletteNamesInNarrative() {
        let bp = composeRomford()

        let paletteNames = Set(
            bp.palette.coreColours.map { $0.name.lowercased() }
            + bp.palette.accentColours.map { $0.name.lowercased() }
        )

        let narrativeTexts = [
            bp.pattern.tipText,
            bp.pattern.narrativeText,
            bp.hardware.metalsText,
            bp.hardware.stonesText,
            bp.hardware.tipText,
        ]

        var foundInPalette = false
        for text in narrativeTexts {
            for name in paletteNames where text.localizedCaseInsensitiveContains(name) {
                foundInPalette = true
                break
            }
        }

        #expect(foundInPalette,
                "Expected at least one palette colour name to appear in pattern/hardware narratives. Palette: \(paletteNames)")
    }

    // MARK: - Placeholder Rendering Fidelity

    @Test("V4 placeholder rendering: {core_colour_1} resolves to palette name, not fallback")
    func placeholderRendersV4Name() {
        let bp = composeRomford()

        let tipText = bp.pattern.tipText
        #expect(!tipText.contains("{core_colour_"), "Unresolved placeholder in tipText")
        #expect(!tipText.contains("{accent_colour_"), "Unresolved placeholder in tipText")
        #expect(!tipText.contains("a complementary choice"),
                "Fallback text appeared — placeholder was not populated by V4 context")
    }

    @Test("Template with V4 context resolves placeholders to V4 names")
    func templateSubstitutionDirectly() {
        let template = "Balance with {core_colour_1} or {accent_colour_1}."
        let context: [String: String] = [
            "core_colour_1": "powder blue",
            "accent_colour_1": "dusty rose",
        ]
        let result = NarrativeTemplateRenderer.render(template: template, context: context)

        #expect(result == "Balance with powder blue or dusty rose.")
        #expect(!result.contains("{"))
    }

    // MARK: - Engine Version

    @Test("Engine version is 2.1.0 after palette placeholder pass")
    func engineVersionBumped() {
        #expect(BlueprintComposer.engineVersion == "2.1.0")
    }

    // MARK: - Helpers

    private func composeRomford() -> CosmicBlueprint {
        guard let dataset = BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath)
        ) else {
            Issue.record("Failed to load dataset")
            fatalError("Cannot proceed without dataset")
        }

        let cacheURL = StyleGuideDataURL.blueprintNarrativeCache(testFilePath: #filePath)
        let narrativeCache = NarrativeCacheLoader()
        guard narrativeCache.loadFromURL(cacheURL), narrativeCache.clusterCount > 0 else {
            Issue.record("Failed to load narrative cache")
            fatalError("Cannot proceed without narrative cache")
        }

        let birthDate = ISO8601DateFormatter().date(from: "1964-12-21T12:00:00Z")!
        let chart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: 51.5785,
            longitude: 0.1833,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        return BlueprintComposer.compose(
            chart: chart,
            birthDate: birthDate,
            birthLocation: "Romford, UK",
            dataset: dataset,
            narrativeCache: narrativeCache
        )
    }
}
