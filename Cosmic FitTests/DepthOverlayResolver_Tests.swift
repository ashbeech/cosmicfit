import XCTest
@testable import Cosmic_Fit

final class DepthOverlayResolver_Tests: XCTestCase {

    // MARK: - Helpers

    private func makeInput(
        asc: V4ZodiacSign = .aquarius,
        venus: V4ZodiacSign = .cancer,
        sun: V4ZodiacSign = .virgo,
        moon: V4ZodiacSign = .taurus,
        mercury: V4ZodiacSign = .libra,
        mars: V4ZodiacSign = .cancer,
        saturn: V4ZodiacSign = .aries,
        jupiter: V4ZodiacSign = .capricorn,
        pluto: V4ZodiacSign? = .scorpio,
        midheaven: V4ZodiacSign? = .scorpio
    ) -> BirthChartColourInput {
        BirthChartColourInput(
            ascendant: PlacementInput(sign: asc),
            venus: PlacementInput(sign: venus),
            sun: PlacementInput(sign: sun),
            moon: PlacementInput(sign: moon),
            mercury: PlacementInput(sign: mercury),
            mars: PlacementInput(sign: mars),
            saturn: PlacementInput(sign: saturn),
            jupiter: PlacementInput(sign: jupiter),
            pluto: pluto.map { PlacementInput(sign: $0) },
            midheaven: midheaven.map { PlacementInput(sign: $0) }
        )
    }

    // MARK: - Zendaya-like: Soft Summer + Scorpio MC + Taurus Moon

    func testSoftSummer_ScorpioMC_TaurusMoon_GainsDepth() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )
        let family: PaletteFamily = .softSummer
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (resultPalette, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertTrue(overlay.applied, "Overlay should apply for Scorpio MC + Taurus Moon in Soft Summer")
        XCTAssertNotNil(overlay.supportSubstitution, "Should substitute a support slot")

        if let sub = overlay.supportSubstitution {
            XCTAssertNotEqual(sub.originalColour, sub.replacementColour)
            let deepNames: Set<String> = ["oxblood", "bark brown", "black cherry", "dark terracotta",
                                          "cocoa", "bitter chocolate", "warm olive",
                                          "espresso", "deep olive", "ink brown"]
            XCTAssertTrue(deepNames.contains(sub.replacementColour),
                          "Replacement '\(sub.replacementColour)' should be a deep colour")
            XCTAssertEqual(sub.replacementColour, "oxblood",
                           "Scorpio MC should visibly add oxblood depth, not default to terracotta")
        }

        // Core and neutrals unchanged
        XCTAssertEqual(resultPalette.neutrals, fullPalette.neutrals)
        XCTAssertEqual(resultPalette.coreColours, fullPalette.coreColours)
    }

    func testSoftSummer_ScorpioMC_GainsDeepAnchor() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )
        let family: PaletteFamily = .softSummer
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (resultPalette, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertNotNil(overlay.deepAnchorSubstitution,
                        "Should substitute deep anchor for shallow family with Scorpio MC")

        if let sub = overlay.deepAnchorSubstitution {
            XCTAssertNotEqual(sub.originalColour, sub.replacementColour)
            XCTAssertEqual(sub.replacementColour, "bitter chocolate",
                           "With Scorpio MC in support, Taurus Moon should ground the anchor")
            XCTAssertEqual(resultPalette.deepAnchor, sub.replacementColour)
        }
    }

    // MARK: - Deep Autumn (no-op)

    func testDeepAutumn_NoOverlay() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .scorpio,
            moon: .taurus, midheaven: .scorpio
        )
        let family: PaletteFamily = .deepAutumn
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (resultPalette, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertFalse(overlay.applied, "Deep Autumn should not get depth overlay")
        XCTAssertNil(overlay.supportSubstitution)
        XCTAssertNil(overlay.deepAnchorSubstitution)
        XCTAssertEqual(resultPalette, fullPalette)
    }

    func testDeepWinter_NoOverlay() {
        let input = makeInput(
            asc: .capricorn, venus: .scorpio, sun: .capricorn,
            moon: .scorpio, midheaven: .scorpio
        )
        let family: PaletteFamily = .deepWinter
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (_, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertFalse(overlay.applied)
    }

    // MARK: - Light/Airy MC/Moon (no-op)

    func testLightSpring_AriesMC_GeminiMoon_NoOverlay() {
        let input = makeInput(
            asc: .aries, venus: .leo, sun: .aries,
            moon: .gemini, mercury: .aries, mars: .leo,
            midheaven: .aries
        )
        let family: PaletteFamily = .lightSpring
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (resultPalette, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertFalse(overlay.applied,
                       "Aries MC + Gemini Moon are not depth signs; should not apply")
        XCTAssertEqual(resultPalette, fullPalette)
    }

    // MARK: - No MC provided (Moon-only activation)

    func testSoftSummer_NoMC_TaurusMoon_StillApplies() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: nil
        )
        let family: PaletteFamily = .softSummer
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (_, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertTrue(overlay.applied,
                      "Taurus Moon alone should trigger overlay in Soft Summer")
    }

    // MARK: - Determinism

    func testDeterministic() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )
        let family: PaletteFamily = .softSummer
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let results = (0..<10).map { _ in
            DepthOverlayResolver.resolve(
                family: family, input: input, palette: fullPalette
            )
        }

        for i in 1..<results.count {
            XCTAssertEqual(results[i].palette, results[0].palette,
                           "Run \(i) produced different palette")
            XCTAssertEqual(results[i].overlay, results[0].overlay,
                           "Run \(i) produced different overlay")
        }
    }

    // MARK: - Soft Autumn with Scorpio MC (non-deep family, should apply)

    func testSoftAutumn_ScorpioMC_AppliesSupport() {
        let input = makeInput(
            asc: .taurus, venus: .taurus, sun: .taurus,
            moon: .capricorn, midheaven: .scorpio
        )
        let family: PaletteFamily = .softAutumn
        let palette = PaletteLibrary.palette(for: family)
        let support = PaletteLibrary.supportPalette(for: family)
        let fullPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: support,
            lightAnchor: palette.lightAnchor,
            deepAnchor: palette.deepAnchor
        )

        let (_, overlay) = DepthOverlayResolver.resolve(
            family: family, input: input, palette: fullPalette
        )

        XCTAssertTrue(overlay.applied)
        XCTAssertNotNil(overlay.supportSubstitution)
    }

    // MARK: - Full engine integration

    func testFullEngine_SoftSummer_ScorpioMC_HasDepthOverlay() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )

        let result = ColourEngine.evaluateProduction(input: input)

        if result.family == .softSummer || result.family == .trueSummer {
            XCTAssertTrue(result.depthOverlay.applied,
                          "Depth overlay should fire for Scorpio MC + Taurus Moon in Summer families")
        }
    }

    // MARK: - Accent Depth Injection

    func testAccentInjection_ScorpioMC_SoftSummer_InjectsDarkAccent() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )

        let result = ColourEngine.evaluateProduction(input: input)

        if result.family == .softSummer || result.family == .trueSummer {
            XCTAssertNotNil(result.depthOverlay.accentDepthInjection,
                            "Scorpio MC in Soft Summer should inject a dark accent")

            if let injection = result.depthOverlay.accentDepthInjection {
                let lab = ColourMath.hexToLab(injection.replacementHex)
                XCTAssertNotNil(lab)
                if let lab = lab {
                    XCTAssertLessThan(lab.L, 40.0,
                                      "Injected accent should be dark (L < 40), got L=\(lab.L)")
                }
                XCTAssertEqual(injection.sourceSign, .scorpio)
            }
        }
    }

    func testAccentInjection_NoMC_NoInjection() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: nil
        )
        let family: PaletteFamily = .softSummer

        let lightAccents = ["#678C70", "#BA4983"]
        let overlay = DepthOverlayResolver.OverlayResult(
            supportSubstitution: nil,
            deepAnchorSubstitution: nil,
            accentDepthInjection: nil,
            applied: true
        )

        let (resultAccents, resultOverlay) = DepthOverlayResolver.injectAccentDepth(
            input: input,
            family: family,
            accentHexes: lightAccents,
            existingPaletteHexes: [],
            previousOverlay: overlay
        )

        XCTAssertNil(resultOverlay.accentDepthInjection,
                     "No MC means no accent injection")
        XCTAssertEqual(resultAccents, lightAccents)
    }

    func testAccentInjection_AriesMC_NoInjection() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .aries
        )
        let family: PaletteFamily = .softSummer

        let lightAccents = ["#678C70", "#BA4983"]
        let overlay = DepthOverlayResolver.OverlayResult(
            supportSubstitution: nil,
            deepAnchorSubstitution: nil,
            accentDepthInjection: nil,
            applied: true
        )

        let (resultAccents, resultOverlay) = DepthOverlayResolver.injectAccentDepth(
            input: input,
            family: family,
            accentHexes: lightAccents,
            existingPaletteHexes: [],
            previousOverlay: overlay
        )

        XCTAssertNil(resultOverlay.accentDepthInjection,
                     "Aries MC is not a depth sign for accent injection")
        XCTAssertEqual(resultAccents, lightAccents)
    }

    func testAccentInjection_AlreadyHasDarkAccent_NoInjection() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )
        let family: PaletteFamily = .softSummer

        // One accent is already dark (L ~25)
        let accentsWithDark = ["#678C70", "#3A1520"]
        let overlay = DepthOverlayResolver.OverlayResult(
            supportSubstitution: nil,
            deepAnchorSubstitution: nil,
            accentDepthInjection: nil,
            applied: true
        )

        let (resultAccents, resultOverlay) = DepthOverlayResolver.injectAccentDepth(
            input: input,
            family: family,
            accentHexes: accentsWithDark,
            existingPaletteHexes: [],
            previousOverlay: overlay
        )

        XCTAssertNil(resultOverlay.accentDepthInjection,
                     "Already has a dark accent — no injection needed")
        XCTAssertEqual(resultAccents, accentsWithDark)
    }

    func testAccentInjection_Deterministic() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, midheaven: .scorpio
        )

        let results = (0..<10).map { _ in
            ColourEngine.evaluateProduction(input: input)
        }

        for i in 1..<results.count {
            XCTAssertEqual(results[i].depthOverlay.accentDepthInjection,
                           results[0].depthOverlay.accentDepthInjection,
                           "Accent injection must be deterministic")
        }
    }
}
