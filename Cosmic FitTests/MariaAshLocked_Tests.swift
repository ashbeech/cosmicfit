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

    func testMariaPaletteNeutralsAndCoreUnchanged() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        let base = PaletteLibrary.palette(for: .deepAutumn)

        XCTAssertEqual(result.palette.neutrals, base.neutrals)
        XCTAssertEqual(result.palette.coreColours, base.coreColours)
    }

    func testMariaAccentsAreChartDerived() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(result.accentSlots.count, 2,
            "Maria must have exactly 2 chart-derived accent slots")
        for slot in result.accentSlots {
            XCTAssertTrue(slot.hex.hasPrefix("#") && slot.hex.count == 7,
                "Accent hex '\(slot.hex)' must be valid 7-char format")
            XCTAssertFalse(slot.displayName.isEmpty,
                "Accent displayName must not be empty")
            XCTAssertFalse(slot.displayName.contains("#"),
                "Accent displayName must not contain '#'")
        }
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

    func testAshPaletteNeutralsCoreSupportUnchanged() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        let base = PaletteLibrary.palette(for: .deepAutumn)
        let support = PaletteLibrary.supportPalette(for: .deepAutumn)

        XCTAssertEqual(result.palette.neutrals, base.neutrals)
        XCTAssertEqual(result.palette.coreColours, base.coreColours,
            "Ash gets the unmodified Deep Autumn core band")
        XCTAssertEqual(result.palette.supportColours, support,
            "Ash gets the unmodified Deep Autumn support band")
        XCTAssertEqual(result.palette.lightAnchor, base.lightAnchor)
    }

    func testAshAccentsAreChartDerived() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        XCTAssertEqual(result.accentSlots.count, 2,
            "Ash must have exactly 2 chart-derived accent slots")
        for slot in result.accentSlots {
            XCTAssertTrue(slot.hex.hasPrefix("#") && slot.hex.count == 7,
                "Accent hex '\(slot.hex)' must be valid 7-char format")
            XCTAssertFalse(slot.displayName.isEmpty,
                "Accent displayName must not be empty")
            XCTAssertFalse(slot.displayName.contains("#"),
                "Accent displayName must not contain '#'")
        }
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

    func testAshAndMariaShareNeutralsAndCoreButDifferInAccents() throws {
        let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
        let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(ashResult.palette.neutrals, mariaResult.palette.neutrals,
            "Same-family users share the neutral band")
        XCTAssertEqual(ashResult.palette.coreColours, mariaResult.palette.coreColours,
            "Same-family users share the core band")
        XCTAssertNotEqual(ashResult.palette.accentColours, mariaResult.palette.accentColours,
            "Chart-derived accents differ between users with different placements")
        XCTAssertNotEqual(ashResult.luminarySignature, mariaResult.luminarySignature,
            "Chart signatures still provide per-user individuation")
    }

    func testAshVariationTraceIsNone() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        let v = result.trace.variation
        XCTAssertTrue(v.substitutions.isEmpty,
            "Variation is bypassed — no substitutions should be applied")
    }

    func testMariaVariationTraceIsNone() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        let v = result.trace.variation
        XCTAssertTrue(v.substitutions.isEmpty,
            "Variation is bypassed — no substitutions should be applied")
    }

    // MARK: - V4.3 Universal Anchors

    /// Every Deep Autumn user, regardless of pull, should receive the same
    /// anchor pair: warm cream + ink brown. Anchors are purely
    /// family-determined foundation; variation lives in the 12+4 mid-palette.
    func testMariaHasDeepAutumnAnchors() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(result.palette.lightAnchor, "warm cream",
            "Maria lightAnchor should be 'warm cream' for Deep Autumn")
        XCTAssertEqual(result.palette.deepAnchor, "black",
            "Maria deepAnchor should be 'black' — winter-compressed DA override")
    }

    func testAshHasDeepAutumnAnchors() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        XCTAssertEqual(result.palette.lightAnchor, "warm cream",
            "Ash lightAnchor should be 'warm cream' for Deep Autumn")
        XCTAssertEqual(result.palette.deepAnchor, "black",
            "Ash deepAnchor should be 'black' — winter-compressed DA override")
    }

    /// Both Ash and Maria are winter-compressed Deep Autumn, so they share
    /// both anchors: "warm cream" (light) and "black" (deep override).
    func testAshAndMariaShareAnchors() throws {
        let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
        let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertEqual(ashResult.palette.lightAnchor, mariaResult.palette.lightAnchor,
            "Same-family users must share the lightAnchor (foundation invariance)")
        XCTAssertEqual(ashResult.palette.deepAnchor, mariaResult.palette.deepAnchor,
            "Both winter-compressed DA users get 'black' as deepAnchor")
    }

    // MARK: - V4.5 Winter-Compression Anchor Override

    func testWinterCompressedDAGetsBlackDeepAnchor() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        XCTAssertTrue(result.trace.overrideFlags.winterCompressionApplied)
        XCTAssertEqual(result.palette.deepAnchor, "black",
            "Deep Autumn + winterCompressionApplied → deepAnchor must be 'black'")
    }

    func testMariaIsAlsoWinterCompressedDA() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertTrue(result.trace.overrideFlags.winterCompressionApplied,
            "Maria is also winter-compressed DA")
        XCTAssertEqual(result.palette.deepAnchor, "black",
            "Winter-compressed DA gets 'black' as deepAnchor")
    }

    // MARK: - V4.4 Chart Signatures

    /// Both signatures are parseable hexes inside the Deep Autumn envelope.
    /// This is the structural contract that prevents a malformed LCH
    /// projection from leaking into the grid.
    func testSignaturesAreValidHexAndInsideEnvelope() throws {
        let envelope = ChartSignatureResolver.envelope(for: .deepAutumn)
        let LTol = 6.0
        let CTol = 12.0

        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            for (sigLabel, hex) in [
                ("luminary", result.luminarySignature),
                ("ruler", result.rulerSignature),
            ] {
                guard let lab = ColourMath.hexToLab(hex) else {
                    XCTFail("\(label) \(sigLabel) hex '\(hex)' is unparseable")
                    continue
                }
                XCTAssertGreaterThanOrEqual(lab.L, envelope.lightness.min - LTol,
                    "\(label) \(sigLabel) L*=\(lab.L) below Deep Autumn envelope min")
                XCTAssertLessThanOrEqual(lab.L, envelope.lightness.max + LTol,
                    "\(label) \(sigLabel) L*=\(lab.L) above Deep Autumn envelope max")
                let chroma = (lab.a * lab.a + lab.b * lab.b).squareRoot()
                XCTAssertLessThanOrEqual(chroma, envelope.chroma.max + CTol,
                    "\(label) \(sigLabel) C*=\(chroma) exceeds Deep Autumn chroma ceiling")
            }
        }
    }

    /// Ash (Scorpio Sun) and Maria (Taurus Sun) must get distinct luminary
    /// signatures — this is the *point* of chart signatures: user-level
    /// individuation inside a shared family template.
    func testAshAndMariaHaveDistinctLuminarySignatures() throws {
        let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
        let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertNotEqual(ashResult.luminarySignature, mariaResult.luminarySignature,
            "Different Sun signs must yield different luminary signatures within Deep Autumn")
    }

    /// Likewise for ruler signatures — Ash and Maria's Ascendant-ruler
    /// signs differ, so their ruler cells must differ.
    func testAshAndMariaHaveDistinctRulerSignatures() throws {
        let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
        let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
        XCTAssertNotEqual(ashResult.rulerSignature, mariaResult.rulerSignature,
            "Different Ascendant-ruler signs must yield different ruler signatures within Deep Autumn")
    }

    /// Signatures are chart-derived but pull-invariant — they don't live
    /// in `VariationSlots.apply`. Assert this explicitly so a future
    /// refactor that routes signatures through pulls immediately fails.
    func testAshSignaturesAreInvariantAcrossRepeatedEvaluations() throws {
        let input = try ashInput
        let firstResult = ColourEngine.evaluateStrict(input: input)
        let secondResult = ColourEngine.evaluateStrict(input: input)
        XCTAssertEqual(firstResult.luminarySignature, secondResult.luminarySignature)
        XCTAssertEqual(firstResult.rulerSignature, secondResult.rulerSignature)
    }

    // MARK: - V4.6 Accent Slot Candidate Selection & Diversity

    func testAccentSlotsAreValidHexes() throws {
        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            for (i, slot) in result.accentSlots.enumerated() {
                guard let lab = ColourMath.hexToLab(slot.hex) else {
                    XCTFail("\(label) accent[\(i)] hex '\(slot.hex)' is unparseable")
                    continue
                }
                XCTAssertGreaterThanOrEqual(lab.L, 10,
                    "\(label) accent[\(i)] L*=\(lab.L) unexpectedly dark")
                XCTAssertLessThanOrEqual(lab.L, 95,
                    "\(label) accent[\(i)] L*=\(lab.L) unexpectedly light")
            }
        }
    }

    func testAccentSlotsPairwiseDiversity() throws {
        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            let hexes = result.accentSlots.map(\.hex)
            for i in 0..<hexes.count {
                for j in (i+1)..<hexes.count {
                    let dist = ColourMath.labDistanceSquared(hexes[i], hexes[j])
                    XCTAssertGreaterThanOrEqual(dist, 64.0,
                        "\(label) accent[\(i)] vs [\(j)] Delta E² = \(dist) < 64 (threshold)")
                }
            }
        }
    }

    func testAccentSlotsMinimumDistanceFromCorePalette() throws {
        let corePaletteThreshold: Double = 64.0 // ΔE ≥ 8

        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            let corePaletteHexes = (result.palette.neutrals + result.palette.coreColours).map {
                PaletteLibrary.hex(for: $0)
            }
            for (i, slot) in result.accentSlots.enumerated() {
                let minDist = corePaletteHexes.map { coreHex in
                    ColourMath.labDistanceSquared(slot.hex, coreHex)
                }.min() ?? .infinity
                XCTAssertGreaterThanOrEqual(minDist, corePaletteThreshold,
                    "\(label) accent[\(i)] '\(slot.displayName)' too close to core palette: ΔE=\(String(format: "%.1f", minDist.squareRoot()))")
            }
        }
    }

    func testAccentToAccentHueSeparation() throws {
        let minAccentHueAngle: Double = 10.0

        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            let accentHues: [Double] = result.accentSlots.compactMap { slot in
                guard let lab = ColourMath.hexToLab(slot.hex) else { return nil }
                let h = atan2(lab.b, lab.a) * 180.0 / .pi
                return h < 0 ? h + 360.0 : h
            }
            for i in 0..<accentHues.count {
                for j in (i+1)..<accentHues.count {
                    let raw = abs(accentHues[i] - accentHues[j]).truncatingRemainder(dividingBy: 360)
                    let dist = min(raw, 360 - raw)
                    XCTAssertGreaterThanOrEqual(dist, minAccentHueAngle,
                        "\(label) accent[\(i)] vs [\(j)]: hue separation only \(String(format: "%.1f", dist))° (need ≥\(minAccentHueAngle)°)")
                }
            }
        }
    }

    func testAccentHueSeparationFromCorePalette() throws {
        let chromaFloor: Double = 10.0

        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            var personalHexes = (result.palette.neutrals + result.palette.coreColours).map {
                PaletteLibrary.hex(for: $0)
            }
            if let support = result.palette.supportColours {
                personalHexes.append(contentsOf: support.map { PaletteLibrary.hex(for: $0) })
            }
            personalHexes.append(PaletteLibrary.hex(for: result.palette.lightAnchor))
            personalHexes.append(PaletteLibrary.hex(for: result.palette.deepAnchor))
            let coreHues: [Double] = personalHexes.compactMap { hex in
                guard let lab = ColourMath.hexToLab(hex) else { return nil }
                let C = sqrt(lab.a * lab.a + lab.b * lab.b)
                guard C >= chromaFloor else { return nil }
                let h = atan2(lab.b, lab.a) * 180.0 / .pi
                return h < 0 ? h + 360.0 : h
            }
            var totalMinDist: Double = 0
            for (i, slot) in result.accentSlots.enumerated() {
                guard let lab = ColourMath.hexToLab(slot.hex) else { continue }
                let rawH = atan2(lab.b, lab.a) * 180.0 / .pi
                let accentHue = rawH < 0 ? rawH + 360.0 : rawH
                var minDist: Double = 180.0
                for coreHue in coreHues {
                    let raw = abs(accentHue - coreHue).truncatingRemainder(dividingBy: 360)
                    minDist = min(minDist, min(raw, 360 - raw))
                }
                totalMinDist += minDist
                XCTAssertGreaterThanOrEqual(minDist, 5.0,
                    "\(label) accent[\(i)] '\(slot.displayName)' hue \(String(format: "%.0f", accentHue))° is only \(String(format: "%.1f", minDist))° from nearest core hue (absolute minimum 5°)")
                if i == 0 {
                    XCTAssertGreaterThanOrEqual(minDist, 18.0,
                        "\(label) accent[\(i)] '\(slot.displayName)' primary accent hue \(String(format: "%.0f", accentHue))° is only \(String(format: "%.1f", minDist))° from nearest core hue (need ≥18° for strict path)")
                }
            }
            let avgMinDist = totalMinDist / Double(result.accentSlots.count)
            XCTAssertGreaterThanOrEqual(avgMinDist, 12.0,
                "\(label) average accent-to-core hue separation is only \(String(format: "%.1f", avgMinDist))° — expected ≥12° across accents")
        }
    }

    func testMariaAccentsUseDifferentSigns() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        let signs = result.accentSlots.map(\.sourceSign)
        XCTAssertEqual(signs.count, 2, "Maria should have exactly 2 accent slots")
        XCTAssertNotEqual(signs[0], signs[1],
            "Maria accent slots should source from different signs, got \(signs[0]) twice")
    }

    func testMariaAccentSourcesAreChartDerived() throws {
        let result = ColourEngine.evaluateStrict(input: try mariaInput)
        let chartSigns: Set<V4ZodiacSign> = [
            .scorpio, .gemini, .cancer, .leo, .aquarius
        ]
        for slot in result.accentSlots {
            XCTAssertTrue(chartSigns.contains(slot.sourceSign),
                "Maria accent '\(slot.displayName)' sourced from \(slot.sourceSign) which is not in her chart")
        }
    }

    func testAshAndMariaGetDifferentAccentHexes() throws {
        let ashResult = ColourEngine.evaluateStrict(input: try ashInput)
        let mariaResult = ColourEngine.evaluateStrict(input: try mariaInput)
        let ashHexes = Set(ashResult.accentSlots.map(\.hex))
        let mariaHexes = Set(mariaResult.accentSlots.map(\.hex))
        XCTAssertNotEqual(ashHexes, mariaHexes,
            "Ash and Maria have different Venus/Mars/Jupiter signs — accents must differ")
    }

    func testAccentSlotsAreDeterministic() throws {
        let input = try ashInput
        let first = ColourEngine.evaluateStrict(input: input)
        let second = ColourEngine.evaluateStrict(input: input)
        XCTAssertEqual(first.accentSlots, second.accentSlots,
            "AccentResolver must be deterministic")
    }

    func testAccentDisplayNamesFromCandidateTable() throws {
        for (label, input) in [("Ash", try ashInput), ("Maria", try mariaInput)] {
            let result = ColourEngine.evaluateStrict(input: input)
            for slot in result.accentSlots {
                XCTAssertFalse(slot.displayName.isEmpty,
                    "\(label) accent displayName must not be empty")
                XCTAssertFalse(slot.displayName.contains("#"),
                    "\(label) accent displayName '\(slot.displayName)' must not contain hex")
                let candidates = SignAccentExpressions.candidates(
                    for: slot.sourceSign,
                    temperature: FamilyProfiles.variables(for: result.family).temperature
                )
                let candidateNames = candidates.map(\.name)
                XCTAssertTrue(candidateNames.contains(slot.displayName),
                    "\(label) accent displayName '\(slot.displayName)' not in expression table for \(slot.sourceSign)")
            }
        }
    }

    // MARK: - V4.6 Temperature-Conditioned Accent Qualitative

    func testDeepAutumnWarmGetsWarmAccents() throws {
        let result = ColourEngine.evaluateStrict(input: try ashInput)
        XCTAssertEqual(result.family, .deepAutumn)
        let temperature = FamilyProfiles.variables(for: result.family).temperature
        XCTAssertEqual(temperature, .warm,
            "Deep Autumn canonical temperature must be warm")
        for slot in result.accentSlots {
            let candidates = SignAccentExpressions.candidates(
                for: slot.sourceSign,
                temperature: .warm
            )
            XCTAssertFalse(candidates.isEmpty,
                "Warm candidates must exist for \(slot.sourceSign)")
        }
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
        FixtureLocator.fixtureURL(named: name)
    }
}
