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
                        "Entry for \(family) → \(pull) should have exactly 3 substitutions (accent, core, support)")
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
        let base = fullPalette(for: .deepAutumn)
        let flags = OverrideFlags()
        let (palette, trace) = VariationSlots.apply(
            base: base, family: .deepAutumn, secondaryPull: nil, overrideFlags: flags
        )
        XCTAssertEqual(palette, base, "Palette should be unchanged when secondaryPull is nil")
        XCTAssertEqual(trace, VariationTrace.none, "Trace should be .none when secondaryPull is nil")
    }

    // MARK: - Pull Strength Levels

    func testStrength1_NoAlignedFlags() {
        let base = fullPalette(for: .deepAutumn)
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
        let base = fullPalette(for: .deepAutumn)
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
        let base = fullPalette(for: .deepAutumn)
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
        XCTAssertEqual(palette.supportColours?[3], "cocoa",
            "Strength 3 substitutes support[3] with pull family's support[3]")
        XCTAssertEqual(palette.neutrals, base.neutrals,
            "Neutrals should be unchanged — V4.2 targets support band at strength 3")
    }

    // MARK: - Determinism

    func testDeterminism() {
        let base = fullPalette(for: .deepAutumn)
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
        let base = fullPalette(for: .deepAutumn)
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
        let base = fullPalette(for: .deepAutumn)
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

    // MARK: - V4.3 Anchor Invariance

    /// Universal anchors must never change under variation. They are the
    /// family-determined foundation; per-user edge lives in the 12+4 mid-palette.
    func testAnchorsUnchangedAcrossAllPullsAndStrengths() {
        for (family, pullMap) in VariationSlots.substitutionMap {
            let base = fullPalette(for: family)
            for pull in pullMap.keys {
                // Test all strength levels by firing 0, 1, 2, 3 aligned flags.
                let flagSets: [OverrideFlags] = [
                    OverrideFlags(),
                    allAlignedFlags(for: pull, count: 1),
                    allAlignedFlags(for: pull, count: 2),
                    allAlignedFlags(for: pull, count: 3),
                ]
                for flags in flagSets {
                    let (palette, _) = VariationSlots.apply(
                        base: base, family: family, secondaryPull: pull, overrideFlags: flags
                    )
                    XCTAssertEqual(palette.lightAnchor, base.lightAnchor,
                        "\(family) → \(pull): lightAnchor must not change under variation")
                    XCTAssertEqual(palette.deepAnchor, base.deepAnchor,
                        "\(family) → \(pull): deepAnchor must not change under variation")
                }
            }
        }
    }

    /// Every family has a valid anchor pair with resolvable hex codes.
    func testEveryFamilyHasValidAnchorPair() {
        for family in PaletteFamily.allCases {
            let triad = PaletteLibrary.palette(for: family)
            XCTAssertFalse(triad.lightAnchor.isEmpty,
                "\(family) must have a non-empty lightAnchor")
            XCTAssertFalse(triad.deepAnchor.isEmpty,
                "\(family) must have a non-empty deepAnchor")
            let lightHex = PaletteLibrary.colourNameToHex[triad.lightAnchor]
            let deepHex = PaletteLibrary.colourNameToHex[triad.deepAnchor]
            XCTAssertNotNil(lightHex, "\(family).lightAnchor '\(triad.lightAnchor)' has no hex entry")
            XCTAssertNotNil(deepHex, "\(family).deepAnchor '\(triad.deepAnchor)' has no hex entry")
            XCTAssertNotEqual(lightHex, "#808080",
                "\(family).lightAnchor resolved to placeholder grey")
            XCTAssertNotEqual(deepHex, "#808080",
                "\(family).deepAnchor resolved to placeholder grey")
        }
    }

    /// Contrast envelope sanity: across the 12 families, the light-anchor
    /// lightness must always exceed the deep-anchor lightness. Without this,
    /// the "light" and "deep" labels would be meaningless.
    func testAnchorPairHasProperValueOrder() {
        for family in PaletteFamily.allCases {
            let triad = PaletteLibrary.palette(for: family)
            guard
                let lightHex = PaletteLibrary.colourNameToHex[triad.lightAnchor],
                let deepHex = PaletteLibrary.colourNameToHex[triad.deepAnchor],
                let lightL = ColourMath.hexToHSL(lightHex)?.l,
                let deepL = ColourMath.hexToHSL(deepHex)?.l
            else {
                XCTFail("\(family) anchor hex parse failed")
                continue
            }
            XCTAssertGreaterThan(lightL, deepL,
                "\(family): lightAnchor L(\(lightL)) must exceed deepAnchor L(\(deepL))")
        }
    }

    // MARK: - Non-standard Index Pairs

    func testTrueSummerToTrueWinterUsesNonStandardIndices() {
        let base = fullPalette(for: .trueSummer)
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

    /// Build an `OverrideFlags` value with up to `count` flags aligned to the
    /// given pull family set to `true`. Used by anchor-invariance to exercise
    /// every pull strength level.
    private func allAlignedFlags(for pull: PaletteFamily, count: Int) -> OverrideFlags {
        // Write-paths for each flag, matching the alignment table inside
        // `VariationSlots`. This is a reverse-map: for a given pull family,
        // produce the full set of flags that would be "aligned."
        let alignedWrites: [PaletteFamily: [(inout OverrideFlags) -> Void]] = [
            .deepWinter: [
                { $0.winterCompressionApplied = true },
                { $0.coolLeanDeepAutumn = true },
                { $0.scorpioDensityApplied = true },
                { $0.capricornVirgoCoolingApplied = true },
            ],
            .trueWinter: [
                { $0.winterCompressionApplied = true },
                { $0.capricornVirgoCoolingApplied = true },
            ],
            .brightWinter: [
                { $0.winterCompressionApplied = true },
                { $0.fireAirChromaApplied = true },
            ],
            .brightSpring: [{ $0.fireAirChromaApplied = true }],
            .softSummer:   [{ $0.waterSofteningApplied = true }],
            .trueSummer:   [{ $0.waterSofteningApplied = true }],
            .lightSummer:  [{ $0.waterSofteningApplied = true }],
            .deepAutumn: [
                { $0.earthDepthOverrideApplied = true },
                { $0.scorpioDensityApplied = true },
            ],
            .trueAutumn:  [{ $0.earthDepthOverrideApplied = true }],
            .softAutumn:  [{ $0.surfacePreservationApplied = true }],
        ]

        var flags = OverrideFlags()
        let writes = alignedWrites[pull] ?? []
        for write in writes.prefix(count) {
            write(&flags)
        }
        return flags
    }

    private func fullPalette(for family: PaletteFamily) -> PaletteTriadV4 {
        let base = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        return PaletteTriadV4(
            neutrals: base.neutrals,
            coreColours: base.coreColours,
            accentColours: base.accentColours,
            supportColours: support,
            lightAnchor: base.lightAnchor,
            deepAnchor: base.deepAnchor
        )
    }
}
