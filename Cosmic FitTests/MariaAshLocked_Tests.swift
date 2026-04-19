import XCTest
@testable import Cosmic_Fit

/// Non-negotiable behavioural anchors for Maria and Ash.
/// These must pass before V4 can be wired into production.
final class MariaAshLocked_Tests: XCTestCase {

    // MARK: - Maria

    /// Maria's chart placements (to be frozen from NatalChartCalculator output).
    /// Placeholder values — will be replaced with frozen fixture placements.
    private var mariaInput: BirthChartColourInput {
        get throws {
            try loadPlacement(id: "maria")
        }
    }

    func testMariaFamilyIsDeepAutumn() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(result.family, .deepAutumn, "Maria must be Deep Autumn")
    }

    func testMariaDepthIsDeep() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(result.variables.depth, .deep, "Maria must have Deep depth")
    }

    func testMariaTemperatureIsWarm() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(result.variables.temperature, .warm, "Maria must have Warm temperature")
    }

    func testMariaSaturationIsRich() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(result.variables.saturation, .rich, "Maria must have Rich saturation")
    }

    func testMariaSurfaceIsNotSoftAutumnCollapse() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertTrue(
            result.variables.surface == .balanced || result.variables.surface == .structured,
            "Maria surface must be Balanced or Structured (not Soft — that would be Soft Autumn collapse). Got: \(result.variables.surface)"
        )
    }

    func testMariaPaletteIsDeepAutumnWithTAVariation() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        let base = PaletteLibrary.palette(for: .deepAutumn)

        XCTAssertEqual(result.palette.accentColours[3], "warm auburn",
            "Maria accent[3] should be 'warm auburn' from True Autumn pull")

        XCTAssertEqual(result.palette.neutrals, base.neutrals)
        XCTAssertEqual(result.palette.coreColours, base.coreColours)
        XCTAssertEqual(result.palette.accentColours[0], base.accentColours[0])
        XCTAssertEqual(result.palette.accentColours[1], base.accentColours[1])
        XCTAssertEqual(result.palette.accentColours[2], base.accentColours[2])
    }

    // MARK: - Ash

    /// Ash's chart placements (to be frozen from NatalChartCalculator output).
    private var ashInput: BirthChartColourInput {
        get throws {
            try loadPlacement(id: "ash")
        }
    }

    func testAshFamilyIsDeepAutumn() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        XCTAssertEqual(result.family, .deepAutumn, "Ash must be Deep Autumn")
    }

    func testAshWinterCompressionApplied() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        XCTAssertTrue(
            result.trace.overrideFlags.winterCompressionApplied,
            "Ash must have winterCompressionApplied = true"
        )
    }

    func testAshPaletteIsDeepAutumnWithDWVariation() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        let base = PaletteLibrary.palette(for: .deepAutumn)

        XCTAssertEqual(result.palette.accentColours[2], "cool ruby",
            "Ash accent[2] should be 'cool ruby' from Deep Winter pull")
        XCTAssertEqual(result.palette.coreColours[3], "petrol",
            "Ash core[3] should be 'petrol' from Deep Winter pull")
        XCTAssertEqual(result.palette.neutrals[1], "cool charcoal",
            "Ash neutral[1] should be 'cool charcoal' from Deep Winter pull (strength 3)")

        XCTAssertEqual(result.palette.accentColours[0], base.accentColours[0])
        XCTAssertEqual(result.palette.accentColours[1], base.accentColours[1])
        XCTAssertEqual(result.palette.accentColours[3], base.accentColours[3])
        XCTAssertEqual(result.palette.coreColours[0], base.coreColours[0])
        XCTAssertEqual(result.palette.coreColours[1], base.coreColours[1])
        XCTAssertEqual(result.palette.coreColours[2], base.coreColours[2])
        XCTAssertEqual(result.palette.neutrals[0], base.neutrals[0])
        XCTAssertEqual(result.palette.neutrals[2], base.neutrals[2])
        XCTAssertEqual(result.palette.neutrals[3], base.neutrals[3])
    }

    func testAshSecondaryPullMayBeDeepWinter() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        if let pull = result.secondaryPull {
            XCTAssertTrue(
                pull == .deepWinter || pull == .trueAutumn,
                "Ash secondary pull should be Deep Winter or True Autumn if present. Got: \(pull)"
            )
        }
    }

    // MARK: - Variation Difference

    func testAshAndMariaHaveDifferentPalettes() throws {
        let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
        let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertNotEqual(ashResult.palette, mariaResult.palette,
            "Ash and Maria should have different palettes despite both being Deep Autumn")
    }

    func testAshVariationTrace() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        let v = result.trace.variation
        XCTAssertEqual(v.pullFamily, "Deep Winter")
        XCTAssertEqual(v.pullStrength, 3,
            "Ash has 3 DW-aligned flags: winterCompression, coolLeanDeepAutumn, capricornVirgoCooling")
        XCTAssertEqual(v.substitutions.count, 3)
    }

    func testMariaVariationTrace() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        let v = result.trace.variation
        XCTAssertEqual(v.pullFamily, "True Autumn")
        XCTAssertEqual(v.pullStrength, 1)
        XCTAssertEqual(v.substitutions.count, 1)
    }

    // MARK: - Fixture Loading

    private func loadPlacement(id: String) throws -> BirthChartColourInput {
        let filename = "v4_locked_placements_\(id)"
        guard let url = Bundle(for: type(of: self)).url(forResource: filename, withExtension: "json")
                ?? locateFixture(named: "\(filename).json") else {
            throw XCTSkip("Fixture \(filename).json not yet generated — run placement freezing first")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(BirthChartColourInput.self, from: data)
    }

    private func locateFixture(named name: String) -> URL? {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")
        let url = fixturesDir.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
