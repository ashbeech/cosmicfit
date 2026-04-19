import XCTest
@testable import Cosmic_Fit

final class ColourEngineV4_UnitTests: XCTestCase {

    // MARK: - Helpers

    private func makeInput(
        asc: V4ZodiacSign = .aries,
        venus: V4ZodiacSign = .taurus,
        sun: V4ZodiacSign = .gemini,
        moon: V4ZodiacSign = .cancer,
        mercury: V4ZodiacSign = .leo,
        mars: V4ZodiacSign = .virgo,
        saturn: V4ZodiacSign = .libra,
        jupiter: V4ZodiacSign = .sagittarius,
        pluto: V4ZodiacSign? = nil
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
            pluto: pluto.map { PlacementInput(sign: $0) }
        )
    }

    // MARK: - Driver Weights

    func testDriverWeightsTotal100() {
        let total = DriverWeights.weights.values.reduce(0, +)
        XCTAssertEqual(total, 100, "Driver weights must sum to exactly 100")
    }

    func testDriverWeightOrder() {
        let ordered: [DriverKey] = [.ascendant, .venus, .sun, .moon, .mercury, .mars, .saturn, .jupiter]
        for i in 0..<ordered.count - 1 {
            let w1 = DriverWeights.weight(for: ordered[i])
            let w2 = DriverWeights.weight(for: ordered[i + 1])
            XCTAssertGreaterThan(w1, w2, "\(ordered[i]) weight should exceed \(ordered[i + 1])")
        }
    }

    // MARK: - Sign Contributions

    func testAllSignsHaveContributions() {
        for sign in V4ZodiacSign.allCases {
            XCTAssertNotNil(SignContributions.table[sign], "Missing contribution for \(sign)")
        }
    }

    func testScorpioHighDepthAndContrast() {
        let c = SignContributions.contribution(for: .scorpio)
        XCTAssertEqual(c.depthDelta, 2)
        XCTAssertEqual(c.contrastDelta, 2)
        XCTAssertEqual(c.warmthDelta, -1)
    }

    // MARK: - Normalization

    func testNormalizationEmits8Drivers() {
        let input = makeInput()
        let normalized = Normalizer.normalizeDrivers(input: input)
        XCTAssertEqual(normalized.drivers.count, 8)
        XCTAssertFalse(normalized.hasPluto)
    }

    func testNormalizationWithPluto() {
        let input = makeInput(pluto: .scorpio)
        let normalized = Normalizer.normalizeDrivers(input: input)
        XCTAssertTrue(normalized.hasPluto)
        XCTAssertEqual(normalized.plutoSign, .scorpio)
    }

    func testNormalizationDriverOrder() {
        let input = makeInput()
        let normalized = Normalizer.normalizeDrivers(input: input)
        let keys = normalized.drivers.map { $0.key }
        XCTAssertEqual(keys, [.ascendant, .venus, .sun, .moon, .mercury, .mars, .saturn, .jupiter])
    }

    // MARK: - Raw Scoring

    func testAllSameSignScoring() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .scorpio, moon: .scorpio,
            mercury: .scorpio, mars: .scorpio, saturn: .scorpio, jupiter: .scorpio
        )
        let normalized = Normalizer.normalizeDrivers(input: input)
        let scores = Scoring.accumulateRawScores(normalized: normalized)

        let c = SignContributions.contribution(for: .scorpio)
        XCTAssertEqual(scores.depth, c.depthDelta * 100)
        XCTAssertEqual(scores.warmth, c.warmthDelta * 100)
        XCTAssertEqual(scores.saturation, c.saturationDelta * 100)
        XCTAssertEqual(scores.contrast, c.contrastDelta * 100)
        XCTAssertEqual(scores.structure, c.structureDelta * 100)
    }

    // MARK: - Scorpio Density Modifier

    func testScorpioDensityCore() {
        let input = makeInput(asc: .scorpio, venus: .scorpio, sun: .aries, moon: .aries)
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyScorpioDensity(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.depth, 20)
        XCTAssertEqual(scores.contrast, 16)
        XCTAssertEqual(scores.warmth, -6)
        XCTAssertTrue(flags.scorpioDensityApplied)
    }

    func testScorpioDensityOuter() {
        let input = makeInput(
            asc: .aries, venus: .aries, sun: .aries, moon: .aries,
            mercury: .scorpio, mars: .scorpio
        )
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyScorpioDensity(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.depth, 8)
        XCTAssertEqual(scores.contrast, 6)
        XCTAssertEqual(scores.warmth, -2)
        XCTAssertTrue(flags.scorpioDensityApplied)
    }

    func testScorpioDensityNotAppliedWhenAbsent() {
        let input = makeInput(asc: .aries, venus: .taurus, sun: .gemini, moon: .cancer)
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyScorpioDensity(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores, RawVariableScores.zero)
        XCTAssertFalse(flags.scorpioDensityApplied)
    }

    // MARK: - Capricorn/Virgo Cooling Modifier

    func testCapricornCooling() {
        let input = makeInput(asc: .capricorn, venus: .aries, sun: .aries, moon: .aries)
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyCapricornVirgoCooling(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.depth, 8)
        XCTAssertEqual(scores.warmth, -5)
        XCTAssertEqual(scores.structure, 8)
        XCTAssertTrue(flags.capricornVirgoCoolingApplied)
    }

    func testVirgoCooling() {
        let input = makeInput(asc: .virgo, venus: .aries, sun: .aries, moon: .aries)
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyCapricornVirgoCooling(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.warmth, -3)
        XCTAssertEqual(scores.saturation, -3)
        XCTAssertEqual(scores.structure, 4)
        XCTAssertTrue(flags.capricornVirgoCoolingApplied)
    }

    // MARK: - Fire-Air Chroma Modifier

    func testFireAirChromaAppliedAt4() {
        let input = makeInput(
            asc: .aries, venus: .leo, sun: .sagittarius, moon: .gemini,
            mercury: .taurus, mars: .taurus
        )
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyFireAirChroma(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.saturation, 12)
        XCTAssertEqual(scores.contrast, 8)
        XCTAssertTrue(flags.fireAirChromaApplied)
    }

    func testFireAirChromaNotAppliedBelow4() {
        let input = makeInput(
            asc: .aries, venus: .leo, sun: .sagittarius, moon: .taurus,
            mercury: .taurus, mars: .taurus
        )
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyFireAirChroma(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.saturation, 0)
        XCTAssertFalse(flags.fireAirChromaApplied)
    }

    // MARK: - Water Softening Modifier

    func testWaterSofteningAppliedAt2() {
        let input = makeInput(asc: .cancer, venus: .pisces, sun: .aries, moon: .aries)
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyWaterSoftening(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores.saturation, -8)
        XCTAssertEqual(scores.contrast, -8)
        XCTAssertEqual(scores.structure, -8)
        XCTAssertTrue(flags.waterSofteningApplied)
    }

    func testWaterSofteningNotAppliedBelow2() {
        let input = makeInput(asc: .cancer, venus: .aries, sun: .aries, moon: .aries)
        var scores = RawVariableScores.zero
        var flags = OverrideFlags()
        Modifiers.applyWaterSoftening(input: input, scores: &scores, flags: &flags)

        XCTAssertEqual(scores, RawVariableScores.zero)
        XCTAssertFalse(flags.waterSofteningApplied)
    }

    // MARK: - Threshold Edge Cases

    func testDepthBoundaries() {
        XCTAssertEqual(Thresholds.deriveDepth(-26), .light)
        XCTAssertEqual(Thresholds.deriveDepth(-25), .light)
        XCTAssertEqual(Thresholds.deriveDepth(-24), .medium)
        XCTAssertEqual(Thresholds.deriveDepth(34), .medium)
        XCTAssertEqual(Thresholds.deriveDepth(35), .deep)
    }

    func testTemperatureBoundaries() {
        XCTAssertEqual(Thresholds.deriveTemperature(-19), .cool)
        XCTAssertEqual(Thresholds.deriveTemperature(-18), .cool)
        XCTAssertEqual(Thresholds.deriveTemperature(-17), .neutral)
        XCTAssertEqual(Thresholds.deriveTemperature(17), .neutral)
        XCTAssertEqual(Thresholds.deriveTemperature(18), .warm)
    }

    func testSaturationBoundaries() {
        XCTAssertEqual(Thresholds.deriveSaturation(-19), .soft)
        XCTAssertEqual(Thresholds.deriveSaturation(-18), .soft)
        XCTAssertEqual(Thresholds.deriveSaturation(-17), .muted)
        XCTAssertEqual(Thresholds.deriveSaturation(5), .muted)
        XCTAssertEqual(Thresholds.deriveSaturation(6), .rich)
    }

    func testContrastBoundaries() {
        XCTAssertEqual(Thresholds.deriveContrast(-11), .low)
        XCTAssertEqual(Thresholds.deriveContrast(-10), .low)
        XCTAssertEqual(Thresholds.deriveContrast(-9), .medium)
        XCTAssertEqual(Thresholds.deriveContrast(19), .medium)
        XCTAssertEqual(Thresholds.deriveContrast(20), .high)
    }

    func testSurfaceBoundaries() {
        XCTAssertEqual(Thresholds.deriveSurface(-9), .soft)
        XCTAssertEqual(Thresholds.deriveSurface(-8), .soft)
        XCTAssertEqual(Thresholds.deriveSurface(-7), .balanced)
        XCTAssertEqual(Thresholds.deriveSurface(15), .balanced)
        XCTAssertEqual(Thresholds.deriveSurface(16), .structured)
    }

    // MARK: - Earth-Depth Override

    func testEarthDepthDeepFloor() {
        let input = makeInput(
            asc: .taurus, venus: .capricorn, sun: .aries, moon: .aries,
            mercury: .scorpio, mars: .taurus,
            saturn: .capricorn
        )
        let check = Overrides.evaluateEarthDepthOverride(input: input)
        XCTAssertGreaterThanOrEqual(check.earthCoreCount, 2)
        XCTAssertGreaterThanOrEqual(check.depthReinforcementCount, 2)
        XCTAssertTrue(check.qualifyingForDeep)
    }

    func testEarthDepthMediumDeepFloor() {
        let input = makeInput(
            asc: .taurus, venus: .virgo, sun: .aries, moon: .aries,
            mercury: .taurus
        )
        let check = Overrides.evaluateEarthDepthOverride(input: input)
        XCTAssertGreaterThanOrEqual(check.earthCoreCount, 2)
        XCTAssertGreaterThanOrEqual(check.depthReinforcementCount, 1)
        XCTAssertTrue(check.qualifyingForMediumDeep)
        XCTAssertFalse(check.qualifyingForDeep)
    }

    // MARK: - Winter Compression

    func testWinterCompressionRequiresDeep() {
        let input = makeInput(asc: .scorpio, venus: .taurus, sun: .taurus, moon: .taurus)
        let vars = DerivedVariables(depth: .medium, temperature: .warm, saturation: .rich, contrast: .medium, surface: .structured)
        let scores = RawVariableScores(depth: 40, warmth: 20, saturation: 10, contrast: 15, structure: 20)
        XCTAssertFalse(Overrides.shouldApplyWinterCompression(input: input, variables: vars, rawScores: scores))
    }

    func testWinterCompressionApplied() {
        let input = makeInput(asc: .scorpio, venus: .taurus, sun: .taurus, moon: .taurus)
        let vars = DerivedVariables(depth: .deep, temperature: .warm, saturation: .rich, contrast: .medium, surface: .structured)
        let scores = RawVariableScores(depth: 40, warmth: 20, saturation: 10, contrast: 15, structure: 20)
        XCTAssertTrue(Overrides.shouldApplyWinterCompression(input: input, variables: vars, rawScores: scores))
    }

    // MARK: - Surface Preservation

    func testSurfacePreservationWithWater() {
        let input = makeInput(asc: .cancer, venus: .taurus, sun: .taurus, moon: .taurus)
        var vars = DerivedVariables(depth: .deep, temperature: .warm, saturation: .rich, contrast: .medium, surface: .structured)
        let scores = RawVariableScores(depth: 40, warmth: 20, saturation: 10, contrast: 10, structure: 10)
        var flags = OverrideFlags()

        Overrides.applySurfacePreservation(input: input, variables: &vars, rawScores: scores, flags: &flags)
        XCTAssertEqual(vars.surface, .balanced)
        XCTAssertTrue(flags.surfacePreservationApplied)
    }

    // MARK: - Family Mapping Tie-Breaks

    func testFamilyOutputMatchesCanonicalVariables() {
        let input = makeInput(
            asc: .aries, venus: .leo, sun: .sagittarius, moon: .gemini,
            mercury: .aries, mars: .leo
        )
        let result = ColourEngine.evaluateStrict(input: input)
        let expected = FamilyProfiles.variables(for: result.family)
        XCTAssertEqual(result.variables, expected,
                       "Output variables must be the canonical profile for \(result.family)")
    }

    func testPaletteMatchesFamily() {
        let input = makeInput(
            asc: .taurus, venus: .cancer, sun: .virgo, moon: .scorpio,
            mercury: .capricorn, mars: .pisces
        )
        let result = ColourEngine.evaluateStrict(input: input)
        let base = PaletteLibrary.palette(for: result.family)

        XCTAssertEqual(result.palette.neutrals.count, 4)
        XCTAssertEqual(result.palette.coreColours.count, 4)
        XCTAssertEqual(result.palette.accentColours.count, 4)

        let allResult = result.palette.neutrals + result.palette.coreColours + result.palette.accentColours
        let allBase = base.neutrals + base.coreColours + base.accentColours
        let matchCount = zip(allResult, allBase).filter { $0 == $1 }.count
        XCTAssertGreaterThanOrEqual(matchCount, 9,
            "At least 9 of 12 slots (≥75%) should match the base template for \(result.family); matched \(matchCount)")

        for name in allResult {
            XCTAssertNotEqual(PaletteLibrary.hex(for: name), "#808080",
                "Colour '\(name)' must have a valid hex value")
        }
    }

    func testCanonicalVariablesMatchFamily() {
        for family in PaletteFamily.allCases {
            let canonical = FamilyProfiles.variables(for: family)
            XCTAssertNotNil(canonical, "Should have canonical variables for \(family)")
        }
    }

    // MARK: - Cluster Mapping

    func testClusterMappingExhaustive() {
        let testCases: [(DerivedVariables, PaletteFamily, PaletteCluster)] = [
            (DerivedVariables(depth: .light, temperature: .warm, saturation: .rich, contrast: .medium, surface: .soft),
             .lightSpring, .lightAiryWarm),
            (DerivedVariables(depth: .light, temperature: .cool, saturation: .soft, contrast: .low, surface: .soft),
             .lightSummer, .lightAiryCool),
            (DerivedVariables(depth: .medium, temperature: .warm, saturation: .rich, contrast: .medium, surface: .balanced),
             .trueSpring, .mediumWarmGrounded),
            (DerivedVariables(depth: .medium, temperature: .warm, saturation: .rich, contrast: .medium, surface: .balanced),
             .trueAutumn, .mediumWarmGrounded),
            (DerivedVariables(depth: .medium, temperature: .warm, saturation: .muted, contrast: .low, surface: .balanced),
             .softAutumn, .mediumWarmMuted),
            (DerivedVariables(depth: .medium, temperature: .neutral, saturation: .rich, contrast: .high, surface: .structured),
             .brightSpring, .mediumNeutralElectric),
            (DerivedVariables(depth: .medium, temperature: .cool, saturation: .soft, contrast: .low, surface: .soft),
             .trueSummer, .mediumCoolSoft),
            (DerivedVariables(depth: .medium, temperature: .cool, saturation: .muted, contrast: .low, surface: .soft),
             .softSummer, .mediumCoolMuted),
            (DerivedVariables(depth: .deep, temperature: .warm, saturation: .rich, contrast: .medium, surface: .structured),
             .deepAutumn, .deepWarmStructured),
            (DerivedVariables(depth: .deep, temperature: .cool, saturation: .rich, contrast: .medium, surface: .structured),
             .deepWinter, .deepCoolControlled),
            (DerivedVariables(depth: .deep, temperature: .cool, saturation: .rich, contrast: .high, surface: .structured),
             .trueWinter, .deepCoolHighContrast),
            (DerivedVariables(depth: .deep, temperature: .cool, saturation: .rich, contrast: .high, surface: .structured),
             .brightWinter, .deepCoolHighContrast),
        ]

        for (vars, family, expectedCluster) in testCases {
            let cluster = ClusterMapping.mapToCluster(variables: vars, family: family)
            XCTAssertEqual(cluster, expectedCluster,
                           "Expected \(expectedCluster) for \(family) with \(vars), got \(cluster)")
        }
    }

    // MARK: - Palette Library

    func testAllFamiliesHavePalettes() {
        for family in PaletteFamily.allCases {
            let palette = PaletteLibrary.palette(for: family)
            XCTAssertEqual(palette.neutrals.count, 4, "\(family) neutrals count")
            XCTAssertEqual(palette.coreColours.count, 4, "\(family) core count")
            XCTAssertEqual(palette.accentColours.count, 4, "\(family) accent count")
        }
    }

    func testAllPaletteNamesHaveHexValues() {
        for family in PaletteFamily.allCases {
            let palette = PaletteLibrary.palette(for: family)
            for name in palette.neutrals + palette.coreColours + palette.accentColours {
                let hex = PaletteLibrary.hex(for: name)
                XCTAssertNotEqual(hex, "#808080",
                                  "Missing hex for '\(name)' in \(family)")
            }
        }
    }

    // MARK: - Secondary Pull (metadata only)

    func testSecondaryPullNeverMatchesPrimary() {
        let families = PaletteFamily.allCases
        let input = makeInput()
        let scores = RawVariableScores(depth: 10, warmth: 10, saturation: 10, contrast: 10, structure: 10)

        for family in families {
            let pull = SecondaryPullDerivation.derive(family: family, input: input, rawScores: scores)
            if let pull = pull {
                XCTAssertNotEqual(pull, family,
                                  "Secondary pull for \(family) should not equal primary")
            }
        }
    }

    // MARK: - End-to-End Pipeline Order

    func testEndToEndDeterminism() {
        let input = makeInput(
            asc: .taurus, venus: .scorpio, sun: .capricorn, moon: .virgo,
            mercury: .scorpio, mars: .taurus, saturn: .capricorn, jupiter: .pisces
        )

        let result1 = ColourEngine.evaluateStrict(input: input)
        let result2 = ColourEngine.evaluateStrict(input: input)

        XCTAssertEqual(result1.family, result2.family)
        XCTAssertEqual(result1.cluster, result2.cluster)
        XCTAssertEqual(result1.variables, result2.variables)
        XCTAssertEqual(result1.palette, result2.palette)
    }

    func testPipelineOrderModifiersBeforeBuckets() {
        let input = makeInput(
            asc: .scorpio, venus: .scorpio, sun: .taurus, moon: .capricorn
        )
        let result = ColourEngine.evaluateStrict(input: input)

        XCTAssertNotEqual(
            result.trace.rawScoresBeforeModifiers,
            result.trace.rawScoresAfterModifiers,
            "Modifiers should have changed the raw scores"
        )
    }
}
