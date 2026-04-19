import XCTest
@testable import Cosmic_Fit

final class VariationSlots_Tests: XCTestCase {

    // MARK: - Map Completeness

    func testEveryFamilyPullPairHasEntry() {
        for family in PaletteFamily.allCases {
            let pulls = adjacentPulls(for: family)
            XCTAssertFalse(pulls.isEmpty, "\(family) should have adjacent pulls")
            for pull in pulls {
                let entries = VariationSlots.substitutionMap[family]?[pull]
                XCTAssertNotNil(entries, "Missing substitution map entry for \(family) → \(pull)")
                if let entries = entries {
                    XCTAssertEqual(entries.count, 3,
                        "Entry for \(family) → \(pull) should have exactly 3 substitutions (accent, core, neutral)")
                }
            }
        }
    }

    // MARK: - Hex Validity

    func testAllSourceColoursResolveToValidHex() {
        for (family, pullMap) in VariationSlots.substitutionMap {
            for (pull, entries) in pullMap {
                for entry in entries {
                    let hex = PaletteLibrary.colourNameToHex[entry.sourceColourName]
                    XCTAssertNotNil(hex,
                        "Colour '\(entry.sourceColourName)' in \(family) → \(pull) has no hex in PaletteLibrary")
                    if let hex = hex {
                        XCTAssertNotEqual(hex, "#808080",
                            "Colour '\(entry.sourceColourName)' in \(family) → \(pull) resolves to placeholder grey")
                    }
                }
            }
        }
    }

    // MARK: - No-Pull Passthrough

    func testNoPullReturnsBaseUnchanged() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        let flags = OverrideFlags()
        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: nil, overrideFlags: flags
        )
        XCTAssertEqual(palette, base, "Palette should be unchanged when secondaryPull is nil")
        XCTAssertEqual(trace, VariationTrace.none, "Trace should be .none when secondaryPull is nil")
    }

    // MARK: - Pull Strength Levels

    func testStrength1_NoAlignedFlags() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        var flags = OverrideFlags()
        flags.scorpioDensityApplied = true // aligns with DA depth, NOT True Autumn

        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .trueAutumn, overrideFlags: flags
        )

        XCTAssertEqual(trace.pullStrength, 1)
        XCTAssertEqual(trace.substitutions.count, 1)
        XCTAssertEqual(trace.substitutions[0].band, "accent")
        XCTAssertEqual(palette.accentColours[3], "warm auburn")
        XCTAssertEqual(palette.coreColours, base.coreColours, "Core should be unchanged at strength 1")
        XCTAssertEqual(palette.neutrals, base.neutrals, "Neutrals should be unchanged at strength 1")
    }

    func testStrength2_OneAlignedFlag() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        var flags = OverrideFlags()
        flags.winterCompressionApplied = true // aligns with Deep Winter

        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .deepWinter, overrideFlags: flags
        )

        XCTAssertEqual(trace.pullStrength, 2)
        XCTAssertEqual(trace.substitutions.count, 2)
        XCTAssertEqual(palette.accentColours[2], "cool ruby")
        XCTAssertEqual(palette.coreColours[3], "petrol")
        XCTAssertEqual(palette.neutrals, base.neutrals, "Neutrals should be unchanged at strength 2")
    }

    func testStrength3_TwoAlignedFlags() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        var flags = OverrideFlags()
        flags.winterCompressionApplied = true
        flags.coolLeanDeepAutumn = true // both align with Deep Winter

        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .deepWinter, overrideFlags: flags
        )

        XCTAssertEqual(trace.pullStrength, 3)
        XCTAssertEqual(trace.substitutions.count, 3)
        XCTAssertEqual(palette.accentColours[2], "cool ruby")
        XCTAssertEqual(palette.coreColours[3], "petrol")
        XCTAssertEqual(palette.neutrals[1], "cool charcoal")
    }

    // MARK: - Determinism

    func testDeterminism() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        var flags = OverrideFlags()
        flags.winterCompressionApplied = true

        let (palette1, trace1) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .deepWinter, overrideFlags: flags
        )
        let (palette2, trace2) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .deepWinter, overrideFlags: flags
        )

        XCTAssertEqual(palette1, palette2)
        XCTAssertEqual(trace1, trace2)
    }

    // MARK: - Ash: Deep Autumn → Deep Winter (strength 2)

    func testAshDeepAutumnToDeepWinter() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        var flags = OverrideFlags()
        flags.winterCompressionApplied = true

        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .deepWinter, overrideFlags: flags
        )

        XCTAssertEqual(trace.pullFamily, "Deep Winter")
        XCTAssertEqual(trace.pullStrength, 2)
        XCTAssertEqual(trace.substitutions.count, 2)

        XCTAssertEqual(palette.accentColours[2], "cool ruby")
        XCTAssertEqual(palette.coreColours[3], "petrol")

        XCTAssertEqual(trace.substitutions[0].band, "accent")
        XCTAssertEqual(trace.substitutions[0].slotIndex, 2)
        XCTAssertEqual(trace.substitutions[0].originalColour, "copper")
        XCTAssertEqual(trace.substitutions[0].replacedWith, "cool ruby")

        XCTAssertEqual(trace.substitutions[1].band, "core")
        XCTAssertEqual(trace.substitutions[1].slotIndex, 3)
        XCTAssertEqual(trace.substitutions[1].originalColour, "dark terracotta")
        XCTAssertEqual(trace.substitutions[1].replacedWith, "petrol")
    }

    // MARK: - Maria: Deep Autumn → True Autumn (strength 1)

    func testMariaDeepAutumnToTrueAutumn() {
        let base = PaletteLibrary.palette(for: .deepAutumn)
        var flags = OverrideFlags()
        flags.scorpioDensityApplied = true // aligns with DA, not TA → +0

        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: .trueAutumn, overrideFlags: flags
        )

        XCTAssertEqual(trace.pullFamily, "True Autumn")
        XCTAssertEqual(trace.pullStrength, 1)
        XCTAssertEqual(trace.substitutions.count, 1)

        XCTAssertEqual(palette.accentColours[3], "warm auburn")

        XCTAssertEqual(trace.substitutions[0].band, "accent")
        XCTAssertEqual(trace.substitutions[0].slotIndex, 3)
        XCTAssertEqual(trace.substitutions[0].originalColour, "deep amber")
        XCTAssertEqual(trace.substitutions[0].replacedWith, "warm auburn")
    }

    // MARK: - Non-standard Index Pairs

    func testTrueSummerToTrueWinterUsesNonStandardIndices() {
        let base = PaletteLibrary.palette(for: .trueSummer)
        let flags = OverrideFlags()

        let (palette, trace) = VariationSlots.apply(
            base: base, family: .trueSummer, secondaryPull: .trueWinter, overrideFlags: flags
        )

        XCTAssertEqual(trace.pullStrength, 1)
        XCTAssertEqual(palette.accentColours[2], "icy blue",
            "True Summer → True Winter accent substitution should be at index 2, not 3")
    }

    // MARK: - Helpers

    private func adjacentPulls(for family: PaletteFamily) -> [PaletteFamily] {
        SecondaryPullDerivation.adjacentPulls(for: family)
    }
}
