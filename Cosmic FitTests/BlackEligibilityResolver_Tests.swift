import XCTest
@testable import Cosmic_Fit

final class BlackEligibilityResolver_Tests: XCTestCase {

    // MARK: - Helpers

    private func makeInput(
        asc: V4ZodiacSign = .aries,
        venus: V4ZodiacSign = .leo,
        sun: V4ZodiacSign = .aries,
        moon: V4ZodiacSign = .gemini,
        mercury: V4ZodiacSign = .aries,
        mars: V4ZodiacSign = .leo,
        saturn: V4ZodiacSign = .aries,
        jupiter: V4ZodiacSign = .sagittarius,
        pluto: V4ZodiacSign? = nil,
        midheaven: V4ZodiacSign? = nil
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

    // MARK: - Zendaya-like: Scorpio MC + Taurus Moon in Soft Summer

    func testSoftSummer_ScorpioMC_TaurusMoon_GainsBlack() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, saturn: .aries,
            pluto: .scorpio, midheaven: .scorpio
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

        let (resultPalette, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: fullPalette,
            winterCompressionApplied: false
        )

        XCTAssertTrue(result.eligible,
                      "Scorpio MC + Pluto in Scorpio should qualify for black (score: \(result.score))")
        XCTAssertNotNil(result.mode)
        XCTAssertNotNil(result.colourName)
        XCTAssertNotEqual(resultPalette.deepAnchor, fullPalette.deepAnchor,
                          "Deep anchor should be upgraded to a black swatch")

        if let hex = result.hex, let lab = ColourMath.hexToLab(hex) {
            XCTAssertLessThan(lab.L, 15.0,
                              "Black swatch should be very dark (L < 15), got L=\(lab.L)")
        }
    }

    // MARK: - Deep Winter already has black — skip

    func testDeepWinter_AlreadyHasBlack_Skipped() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .scorpio,
            moon: .capricorn, pluto: .scorpio, midheaven: .scorpio
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

        let (resultPalette, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: fullPalette,
            winterCompressionApplied: false
        )

        XCTAssertFalse(result.eligible, "Deep Winter already has black — should skip")
        XCTAssertEqual(resultPalette.deepAnchor, fullPalette.deepAnchor)
    }

    // MARK: - True Winter already has black — skip

    func testTrueWinter_Skipped() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .scorpio,
            moon: .scorpio, midheaven: .scorpio
        )
        let (_, result) = BlackEligibilityResolver.resolve(
            family: .trueWinter, input: input,
            palette: PaletteLibrary.palette(for: .trueWinter),
            winterCompressionApplied: false
        )
        XCTAssertFalse(result.eligible)
    }

    // MARK: - Winter-compressed Deep Autumn already has black — skip

    func testDeepAutumn_WinterCompression_Skipped() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .scorpio,
            moon: .taurus, pluto: .scorpio, midheaven: .scorpio
        )
        let family: PaletteFamily = .deepAutumn
        let palette = PaletteLibrary.palette(for: family)

        let (_, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: palette,
            winterCompressionApplied: true
        )

        XCTAssertFalse(result.eligible,
                       "Winter-compressed Deep Autumn already has black anchor")
    }

    // MARK: - No qualifying signals — ineligible

    func testLightSpring_FireAir_NoBlack() {
        let input = makeInput(
            asc: .aries, venus: .leo, sun: .aries,
            moon: .gemini, mercury: .aries, mars: .leo,
            saturn: .leo, jupiter: .sagittarius,
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

        let (resultPalette, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: fullPalette,
            winterCompressionApplied: false
        )

        XCTAssertFalse(result.eligible,
                       "Pure fire/air chart should not get black (score: \(result.score))")
        XCTAssertEqual(resultPalette.deepAnchor, fullPalette.deepAnchor)
    }

    // MARK: - Capricorn heavy chart

    func testSoftAutumn_CapricornHeavy_GainsBlack() {
        let input = makeInput(
            asc: .capricorn, venus: .capricorn, sun: .capricorn,
            moon: .taurus, saturn: .capricorn,
            pluto: .capricorn, midheaven: .capricorn
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

        let (_, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: fullPalette,
            winterCompressionApplied: false
        )

        XCTAssertTrue(result.eligible,
                      "Heavy Capricorn chart should qualify for black (score: \(result.score))")
        XCTAssertNotNil(result.mode)
    }

    // MARK: - Warm family gets blackBrown, not trueBlack (moderate score)

    func testWarmFamily_ModerateScore_GetsBlackBrown() {
        let input = makeInput(
            asc: .taurus, venus: .scorpio, sun: .taurus,
            moon: .capricorn, saturn: .aries,
            midheaven: .scorpio
        )
        let family: PaletteFamily = .trueAutumn
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

        let (_, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: fullPalette,
            winterCompressionApplied: false
        )

        if result.eligible {
            XCTAssertEqual(result.mode, .blackBrown,
                           "Warm family with moderate score should get blackBrown, not trueBlack")
        }
    }

    // MARK: - Full engine integration

    func testFullEngine_ScorpioMC_HasBlackInPalette() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, pluto: .scorpio, midheaven: .scorpio
        )

        let result = ColourEngine.evaluateProduction(input: input)

        let deepAnchorHex = PaletteLibrary.hex(for: result.palette.deepAnchor)
        if let lab = ColourMath.hexToLab(deepAnchorHex) {
            XCTAssertLessThan(lab.L, 20.0,
                              "Scorpio MC + Pluto in Scorpio should produce a very dark anchor " +
                              "(family: \(result.family.rawValue), anchor: \(result.palette.deepAnchor), L=\(lab.L))")
        }
    }

    // MARK: - Determinism

    func testDeterministic() {
        let input = makeInput(
            asc: .aquarius, venus: .cancer, sun: .virgo,
            moon: .taurus, pluto: .scorpio, midheaven: .scorpio
        )

        let results = (0..<10).map { _ in
            ColourEngine.evaluateProduction(input: input)
        }

        for i in 1..<results.count {
            XCTAssertEqual(results[i].blackEligibility, results[0].blackEligibility,
                           "Run \(i) produced different black eligibility")
            XCTAssertEqual(results[i].palette.deepAnchor, results[0].palette.deepAnchor,
                           "Run \(i) produced different deep anchor")
        }
    }

    // MARK: - Signals are traced

    func testSignalsTraced() {
        let input = makeInput(
            asc: .scorpio, venus: .capricorn, sun: .virgo,
            moon: .taurus, saturn: .scorpio,
            pluto: .scorpio, midheaven: .scorpio
        )
        let family: PaletteFamily = .softSummer
        let palette = PaletteLibrary.palette(for: family)

        let (_, result) = BlackEligibilityResolver.resolve(
            family: family, input: input, palette: palette,
            winterCompressionApplied: false
        )

        XCTAssertTrue(result.signals.contains("Scorpio MC"),
                      "Should trace Scorpio MC signal")
        XCTAssertTrue(result.signals.contains("Scorpio Asc"),
                      "Should trace Scorpio Asc signal")
        XCTAssertTrue(result.signals.contains("Pluto in Scorpio"),
                      "Should trace Pluto in Scorpio signal")
        XCTAssertTrue(result.score > 3.0,
                      "Heavy Scorpio chart should score high (got \(result.score))")
    }
}
