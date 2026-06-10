import XCTest
@testable import Cosmic_Fit

final class VisibilityAccentResolver_Tests: XCTestCase {

    // MARK: - Helpers

    private func makeInput(
        asc: V4ZodiacSign = .pisces,
        venus: V4ZodiacSign = .taurus,
        sun: V4ZodiacSign = .taurus,
        moon: V4ZodiacSign = .capricorn,
        mercury: V4ZodiacSign = .taurus,
        mars: V4ZodiacSign = .gemini,
        saturn: V4ZodiacSign = .capricorn,
        jupiter: V4ZodiacSign = .gemini,
        pluto: V4ZodiacSign? = .scorpio,
        midheaven: V4ZodiacSign? = .sagittarius
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

    private func makeAccentSlot(
        hex: String = "#808080",
        name: String = "Test",
        role: AccentRole = .signature,
        planet: DriverKey = .mars,
        sign: V4ZodiacSign = .aries
    ) -> AccentSlot {
        AccentSlot(
            hex: hex,
            displayName: name,
            role: role,
            sourcePlanet: planet,
            sourceSign: sign,
            saturationOverrideApplied: false
        )
    }

    // MARK: - Gate 1: No MC

    func testSkipsWhenNoMC() {
        let input = makeInput(midheaven: nil)
        let result = VisibilityAccentResolver.resolve(
            family: .deepWinter, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied)
        XCTAssertNil(result.slot)
        XCTAssertNil(result.mcSign)
        XCTAssertEqual(result.skipReason, "no MC")
    }

    // MARK: - Gate 1: MC is depth sign (not fire/air)

    func testSkipsWhenMCIsDepthSign() {
        let input = makeInput(midheaven: .scorpio)
        let result = VisibilityAccentResolver.resolve(
            family: .softSummer, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied)
        XCTAssertNil(result.slot)
        XCTAssertEqual(result.mcSign, .scorpio)
        XCTAssertEqual(result.skipReason, "MC not a visibility sign")
    }

    // MARK: - Gate 2: Bright families skip

    func testSkipsForBrightSpring() {
        let input = makeInput(midheaven: .sagittarius)
        let result = VisibilityAccentResolver.resolve(
            family: .brightSpring, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied)
        XCTAssertNil(result.slot)
        XCTAssertEqual(result.mcSign, .sagittarius)
        XCTAssertEqual(result.skipReason, "family already bright")
    }

    func testSkipsForBrightWinter() {
        let input = makeInput(midheaven: .aries)
        let result = VisibilityAccentResolver.resolve(
            family: .brightWinter, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied)
        XCTAssertNil(result.slot)
        XCTAssertEqual(result.skipReason, "family already bright")
    }

    // MARK: - Gate 3: Hue already covered

    func testSkipsWhenHueAlreadyCovered() {
        // Sagittarius MC → Jupiter ruler → Jupiter in Gemini
        // Gemini/cool first candidate hue ≈ 200 (Mercurial Teal)
        // Provide an existing accent hex in the teal zone (h ≈ 200)
        let input = makeInput(
            mars: .leo, jupiter: .gemini,
            midheaven: .sagittarius
        )
        let tealHex = ColourMath.lchToHex(L: 60, C: 40, h: 200)
        let accentSlot = makeAccentSlot(
            hex: tealHex, name: "Teal Test",
            planet: .saturn, sign: .aquarius
        )

        let result = VisibilityAccentResolver.resolve(
            family: .deepWinter, input: input,
            accentHexes: [tealHex],
            accentSlots: [accentSlot],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied)
        XCTAssertNil(result.slot)
        XCTAssertEqual(result.mcSign, .sagittarius)
        XCTAssertEqual(result.rulerPlanet, .jupiter)
        XCTAssertEqual(result.rulerSign, .gemini)
        XCTAssertEqual(result.skipReason, "hue already covered")
    }

    // MARK: - Gate 4: Ruler sign already in accent band

    func testSkipsWhenRulerSignAlreadyInAccentBand() {
        // Sagittarius MC → Jupiter → Gemini. Accent band already has a
        // Gemini-sourced slot (different hue to avoid gate 3 triggering first).
        let input = makeInput(
            mars: .leo, jupiter: .gemini,
            midheaven: .sagittarius
        )
        let redHex = ColourMath.lchToHex(L: 50, C: 55, h: 30)
        let geminiSlot = makeAccentSlot(
            hex: redHex, name: "Gemini Red",
            planet: .mars, sign: .gemini
        )

        let result = VisibilityAccentResolver.resolve(
            family: .deepWinter, input: input,
            accentHexes: [redHex],
            accentSlots: [geminiSlot],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied)
        XCTAssertNil(result.slot)
        XCTAssertEqual(result.skipReason, "ruler sign already in accent band")
    }

    // MARK: - Fires: MC ruler in new direction

    func testFiresMCRulerInNewDirection() {
        // Sagittarius MC → Jupiter → Leo (warm gold direction ≈ h:78)
        // Deep Autumn family (warm temperature)
        // Existing accents in teal (h≈200) + wine (h≈15) zones — far from gold
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .capricorn,
            moon: .taurus, mercury: .sagittarius, mars: .aries,
            saturn: .capricorn, jupiter: .leo, pluto: .scorpio,
            midheaven: .sagittarius
        )
        let tealHex = ColourMath.lchToHex(L: 55, C: 40, h: 200)
        let wineHex = ColourMath.lchToHex(L: 30, C: 40, h: 15)
        let slot0 = makeAccentSlot(hex: tealHex, name: "Teal", planet: .mars, sign: .aries)
        let slot1 = makeAccentSlot(hex: wineHex, name: "Wine", role: .contrast, planet: .pluto, sign: .scorpio)

        let result = VisibilityAccentResolver.resolve(
            family: .deepAutumn, input: input,
            accentHexes: [tealHex, wineHex],
            accentSlots: [slot0, slot1],
            existingPaletteHexes: [tealHex, wineHex]
        )

        XCTAssertTrue(result.applied)
        XCTAssertNotNil(result.slot)
        XCTAssertEqual(result.mcSign, .sagittarius)
        XCTAssertEqual(result.rulerPlanet, .jupiter)
        XCTAssertEqual(result.rulerSign, .leo)
        XCTAssertNil(result.skipReason)

        if let slot = result.slot {
            XCTAssertEqual(slot.role, .visibility)
            XCTAssertEqual(slot.sourcePlanet, .jupiter)
            XCTAssertEqual(slot.sourceSign, .leo)
            XCTAssertFalse(slot.hex.isEmpty)
        }
    }

    // MARK: - Fires: Aries MC, Mars in Scorpio (cool)

    func testFiresAriesMCMarsCool() {
        // Aries MC → Mars ruler → Mars in Scorpio
        // Soft Summer (cool temperature)
        let input = makeInput(
            asc: .cancer, venus: .virgo, sun: .virgo,
            moon: .pisces, mercury: .virgo, mars: .scorpio,
            saturn: .aquarius, jupiter: .pisces, pluto: .scorpio,
            midheaven: .aries
        )
        let greenHex = ColourMath.lchToHex(L: 50, C: 30, h: 150)
        let blueHex = ColourMath.lchToHex(L: 55, C: 35, h: 250)
        let slot0 = makeAccentSlot(hex: greenHex, name: "Green", planet: .venus, sign: .virgo)
        let slot1 = makeAccentSlot(hex: blueHex, name: "Blue", role: .contrast, planet: .jupiter, sign: .pisces)

        let result = VisibilityAccentResolver.resolve(
            family: .softSummer, input: input,
            accentHexes: [greenHex, blueHex],
            accentSlots: [slot0, slot1],
            existingPaletteHexes: [greenHex, blueHex]
        )

        XCTAssertTrue(result.applied)
        XCTAssertNotNil(result.slot)
        XCTAssertEqual(result.mcSign, .aries)
        XCTAssertEqual(result.rulerPlanet, .mars)
        XCTAssertEqual(result.rulerSign, .scorpio)
        XCTAssertEqual(result.slot?.sourceSign, .scorpio)
    }

    // MARK: - Fires: Aquarius MC, Saturn in Taurus (warm)

    func testFiresAquariusMCSaturnEarth() {
        // Aquarius MC → Saturn ruler → Saturn in Taurus
        // Soft Autumn (warm temperature)
        let input = makeInput(
            asc: .leo, venus: .libra, sun: .libra,
            moon: .aries, mercury: .libra, mars: .sagittarius,
            saturn: .taurus, jupiter: .leo, pluto: .virgo,
            midheaven: .aquarius
        )
        let pinkHex = ColourMath.lchToHex(L: 60, C: 35, h: 340)
        let tealHex = ColourMath.lchToHex(L: 50, C: 30, h: 200)
        let slot0 = makeAccentSlot(hex: pinkHex, name: "Pink", planet: .venus, sign: .libra)
        let slot1 = makeAccentSlot(hex: tealHex, name: "Teal", role: .contrast, planet: .mars, sign: .sagittarius)

        let result = VisibilityAccentResolver.resolve(
            family: .softAutumn, input: input,
            accentHexes: [pinkHex, tealHex],
            accentSlots: [slot0, slot1],
            existingPaletteHexes: [pinkHex, tealHex]
        )

        XCTAssertTrue(result.applied)
        XCTAssertNotNil(result.slot)
        XCTAssertEqual(result.mcSign, .aquarius)
        XCTAssertEqual(result.rulerPlanet, .saturn)
        XCTAssertEqual(result.rulerSign, .taurus)
        XCTAssertEqual(result.slot?.sourceSign, .taurus)
    }

    // MARK: - Slot properties

    func testVisibilitySlotHasCorrectRole() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .capricorn,
            moon: .taurus, jupiter: .leo,
            midheaven: .sagittarius
        )

        let result = VisibilityAccentResolver.resolve(
            family: .deepAutumn, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertTrue(result.applied)
        XCTAssertEqual(result.slot?.role, .visibility)
    }

    func testVisibilitySlotSourcesFromRulerNotMC() {
        // Sagittarius MC → Jupiter → Jupiter in Cancer
        // Slot source should be Cancer, not Sagittarius
        let input = makeInput(
            asc: .aries, venus: .leo, sun: .leo,
            moon: .aries, mercury: .leo, mars: .sagittarius,
            saturn: .aquarius, jupiter: .cancer, pluto: .scorpio,
            midheaven: .sagittarius
        )

        let result = VisibilityAccentResolver.resolve(
            family: .trueAutumn, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertTrue(result.applied)
        XCTAssertEqual(result.rulerSign, .cancer)
        XCTAssertEqual(result.slot?.sourceSign, .cancer,
                       "Slot must source from ruler's sign (Cancer), not MC sign (Sagittarius)")
        XCTAssertNotEqual(result.slot?.sourceSign, .sagittarius)
    }

    // MARK: - Vibrancy fallback

    func testVibrancyFilterExcludesLowChroma() {
        // Aquarius MC → Saturn → Capricorn
        // Capricorn/cool candidates: Saturn Slate (C:15), Cool Graphite (C:18), Steel Blue (C:22)
        // All below vibrancyChromaMin of 30, so fallback to chroma-descending sort
        let input = makeInput(
            asc: .cancer, venus: .virgo, sun: .virgo,
            moon: .pisces, mercury: .virgo, mars: .aries,
            saturn: .capricorn, jupiter: .pisces, pluto: .scorpio,
            midheaven: .aquarius
        )

        let result = VisibilityAccentResolver.resolve(
            family: .softSummer, input: input,
            accentHexes: [], accentSlots: [],
            existingPaletteHexes: []
        )

        XCTAssertTrue(result.applied,
                       "Should still fire using fallback candidates when vibrancy filter excludes all")
        XCTAssertNotNil(result.slot)
        XCTAssertEqual(result.slot?.sourceSign, .capricorn)
    }

    // MARK: - Determinism

    func testDeterminism() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .capricorn,
            moon: .taurus, jupiter: .leo,
            midheaven: .sagittarius
        )

        let results = (0..<10).map { _ in
            VisibilityAccentResolver.resolve(
                family: .deepAutumn, input: input,
                accentHexes: [], accentSlots: [],
                existingPaletteHexes: []
            )
        }

        for i in 1..<results.count {
            XCTAssertEqual(results[i], results[0],
                           "Run \(i) produced different result")
        }
    }

    // MARK: - Maria's chart: Sag MC, Jupiter in Gemini, existing Gemini accent

    func testMariaSagMCSkipsBecauseGeminiCovered() {
        // Maria: Pisces Asc, Taurus Sun/Venus/Mercury, Capricorn Moon/Saturn,
        // Gemini Mars/Jupiter, Scorpio Pluto, Sagittarius MC
        // Existing accent: Mars/Gemini Iced Aqua at teal zone
        let input = makeInput(
            asc: .pisces, venus: .taurus, sun: .taurus,
            moon: .capricorn, mercury: .taurus, mars: .gemini,
            saturn: .capricorn, jupiter: .gemini, pluto: .scorpio,
            midheaven: .sagittarius
        )

        let icedAquaHex = "#00AFBF"
        let aubergineHex = "#562865"
        let geminiSlot = makeAccentSlot(
            hex: icedAquaHex, name: "Iced Aqua",
            planet: .mars, sign: .gemini
        )
        let scorpioSlot = makeAccentSlot(
            hex: aubergineHex, name: "Aubergine",
            role: .contrast, planet: .pluto, sign: .scorpio
        )

        let result = VisibilityAccentResolver.resolve(
            family: .deepWinter, input: input,
            accentHexes: [icedAquaHex, aubergineHex],
            accentSlots: [geminiSlot, scorpioSlot],
            existingPaletteHexes: []
        )

        XCTAssertFalse(result.applied,
                       "Maria's palette already covers the Gemini direction — should skip")
        XCTAssertNil(result.slot)
        XCTAssertEqual(result.mcSign, .sagittarius)
        XCTAssertEqual(result.rulerPlanet, .jupiter)
        XCTAssertEqual(result.rulerSign, .gemini)
        XCTAssertTrue(
            result.skipReason == "ruler sign already in accent band" ||
            result.skipReason == "hue already covered",
            "Expected skip due to Gemini coverage, got: \(result.skipReason ?? "nil")"
        )
    }

    // MARK: - Full engine integration: non-visibility charts unchanged

    func testFullEngine_NoMC_NoVisibility() {
        let input = makeInput(midheaven: nil)
        let result = ColourEngine.evaluateProduction(input: input)

        XCTAssertFalse(result.visibilityAccent.applied)
        XCTAssertNil(result.visibilityAccent.slot)
        XCTAssertEqual(result.visibilityAccent.skipReason, "no MC")
    }

    func testFullEngine_DepthSignMC_NoVisibility() {
        let input = makeInput(midheaven: .scorpio)
        let result = ColourEngine.evaluateProduction(input: input)

        XCTAssertFalse(result.visibilityAccent.applied)
        XCTAssertEqual(result.visibilityAccent.skipReason, "MC not a visibility sign")
    }

    // MARK: - All six visibility signs accepted

    func testAllVisibilitySignsAccepted() {
        let visibilitySigns: [V4ZodiacSign] = [.aries, .gemini, .leo, .libra, .sagittarius, .aquarius]
        for sign in visibilitySigns {
            let input = makeInput(midheaven: sign)
            let result = VisibilityAccentResolver.resolve(
                family: .softSummer, input: input,
                accentHexes: [], accentSlots: [],
                existingPaletteHexes: []
            )
            XCTAssertNotEqual(result.skipReason, "MC not a visibility sign",
                              "\(sign) should be accepted as a visibility sign")
        }
    }

    // MARK: - All depth signs rejected

    func testDepthSignsRejected() {
        let depthSigns: [V4ZodiacSign] = [.taurus, .cancer, .virgo, .scorpio, .capricorn, .pisces]
        for sign in depthSigns {
            let input = makeInput(midheaven: sign)
            let result = VisibilityAccentResolver.resolve(
                family: .softSummer, input: input,
                accentHexes: [], accentSlots: [],
                existingPaletteHexes: []
            )
            XCTAssertEqual(result.skipReason, "MC not a visibility sign",
                           "\(sign) should be rejected as not a visibility sign")
        }
    }

    // MARK: - Visibility accent appears in ColourEngineResult trace

    func testVisibilityTraceInResult() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .capricorn,
            moon: .taurus, mercury: .sagittarius, mars: .aries,
            saturn: .capricorn, jupiter: .leo, pluto: .scorpio,
            midheaven: .sagittarius
        )
        let result = ColourEngine.evaluateProduction(input: input)

        XCTAssertEqual(result.visibilityAccent.mcSign, .sagittarius)
        XCTAssertEqual(result.visibilityAccent.rulerPlanet, .jupiter)
        XCTAssertEqual(result.visibilityAccent.rulerSign, .leo)
    }
}
