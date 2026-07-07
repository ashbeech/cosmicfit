import Foundation

enum Overrides {

    // MARK: - 10.1 Earth-Depth Override

    struct EarthDepthCheck {
        let earthCoreCount: Int
        let depthReinforcementCount: Int
        var qualifyingForMediumDeep: Bool { earthCoreCount >= 2 && depthReinforcementCount >= 1 }
        var qualifyingForDeep: Bool { earthCoreCount >= 2 && depthReinforcementCount >= 2 }
    }

    static func evaluateEarthDepthOverride(input: BirthChartColourInput) -> EarthDepthCheck {
        let earthSigns: Set<V4ZodiacSign> = [.taurus, .virgo, .capricorn]
        let earthCoreCount = input.coreDriverSigns.filter { earthSigns.contains($0) }.count

        let depthSigns: Set<V4ZodiacSign> = [.scorpio, .taurus, .capricorn]
        let outerDriverKeys: [DriverKey] = [.mercury, .mars, .saturn, .jupiter]
        var reinforcement = outerDriverKeys
            .compactMap { input.sign(for: $0) }
            .filter { depthSigns.contains($0) }
            .count

        if let plutoSign = input.pluto?.sign {
            if depthSigns.contains(plutoSign) {
                reinforcement += 1
            }
            if plutoSign == .scorpio {
                reinforcement += 1
            }
        }

        if let saturnSign = input.sign(for: .saturn),
           saturnSign == .capricorn || saturnSign == .taurus {
            reinforcement += 1
        }

        return EarthDepthCheck(
            earthCoreCount: earthCoreCount,
            depthReinforcementCount: reinforcement
        )
    }

    static func applyEarthDepthOverride(
        input: BirthChartColourInput,
        variables: inout DerivedVariables,
        rawScores: RawVariableScores,
        flags: inout OverrideFlags
    ) {
        let check = evaluateEarthDepthOverride(input: input)

        if check.qualifyingForDeep {
            variables.depth = .deep
            flags.earthDepthOverrideApplied = true
        } else if check.qualifyingForMediumDeep {
            if rawScores.structure >= 40 || rawScores.contrast >= 20 {
                variables.depth = .deep
                flags.earthDepthOverrideApplied = true
            }
        }
    }

    // MARK: - 10.2 Winter Compression

    static func shouldApplyWinterCompression(
        input: BirthChartColourInput,
        variables: DerivedVariables,
        rawScores: RawVariableScores
    ) -> Bool {
        guard variables.depth == .deep else { return false }
        guard variables.temperature != .cool else { return false }
        guard rawScores.contrast >= 12 else { return false }

        let winterSigns: Set<V4ZodiacSign> = [.scorpio, .capricorn]

        let coreHasWinterSign = input.coreDriverSigns
            .contains(where: { winterSigns.contains($0) })

        let saturnInRelevant: Bool = {
            guard let sign = input.sign(for: .saturn) else { return false }
            return sign == .scorpio || sign == .capricorn || sign == .taurus
        }()

        let outerHasWinterInfluence: Bool = {
            let jupiterWinter = input.sign(for: .jupiter)
                .map { winterSigns.contains($0) } ?? false
            let plutoWinter = input.pluto
                .map { winterSigns.contains($0.sign) } ?? false
            return jupiterWinter || plutoWinter
        }()

        return coreHasWinterSign || saturnInRelevant || outerHasWinterInfluence
    }

    // MARK: - 10.3 Surface Preservation

    static func applySurfacePreservation(
        input: BirthChartColourInput,
        variables: inout DerivedVariables,
        rawScores: RawVariableScores,
        flags: inout OverrideFlags
    ) {
        guard variables.depth == .deep else { return }
        guard rawScores.structure < Thresholds.structureBalancedMax + 1 else { return }

        let waterSoft: Set<V4ZodiacSign> = [.cancer, .pisces]
        let hasWaterInCore = input.coreDriverSigns.contains(where: { waterSoft.contains($0) })

        if hasWaterInCore {
            variables.surface = .balanced
            flags.surfacePreservationApplied = true
        }
    }

    // MARK: - 10.5 Venus-Element Temperature Floor (SG-2 Phase 2e, Layer A)

    /// The temperature FLOOR the Venus sign's element sets. Depth/muting
    /// overrides may deepen or mute a palette, but must not FLIP a warm Venus
    /// to a cool family. Mirrors `ChartAestheticProfile.temperature(forVenusSign:)`
    /// (earth/fire warm; Scorpio warm-deep despite water; Virgo neutral;
    /// air/water cool) so the profile and the V4 engine agree (the Phase 4a
    /// three-way check).
    enum VenusFloor { case warm, cool, neutral }

    static func venusTemperatureFloor(input: BirthChartColourInput) -> VenusFloor {
        switch input.venus.sign {
        case .scorpio:                                  return .warm   // warm-deep nuance
        case .virgo:                                    return .neutral
        case .aries, .leo, .sagittarius, .taurus, .capricorn:
            return .warm
        case .gemini, .libra, .aquarius, .cancer, .pisces:
            return .cool
        }
    }

    /// Cool DEEP families a warm-Venus chart can wrongly flip into via the
    /// cool-leaning / earth-depth path (Slate: deepWinter). The warm
    /// equivalent at the SAME depth is Deep Autumn (deep, rich, structured) —
    /// depth is preserved, only the temperature flip is undone.
    private static let coolDeepFamilies: Set<PaletteFamily> = [
        .deepWinter, .trueWinter, .brightWinter
    ]

    /// Applies the Venus warm floor: if the Venus floor is warm but the
    /// classified family is a cool DEEP family, remap to Deep Autumn. Returns
    /// the family unchanged otherwise. Sets `flags.venusWarmFloorApplied` when
    /// it fires. Non-deep cool families are left untouched (the traced flip is
    /// deep-only; Cove/Mist/Frost cool-Venus charts are correct as-is).
    static func applyVenusWarmFloor(
        family: PaletteFamily,
        input: BirthChartColourInput,
        flags: inout OverrideFlags
    ) -> PaletteFamily {
        guard venusTemperatureFloor(input: input) == .warm,
              coolDeepFamilies.contains(family) else { return family }
        flags.venusWarmFloorApplied = true
        return .deepAutumn
    }

    // MARK: - 10.4 Cool-Leaning Deep Autumn

    static func isCoolLeaningDeepAutumn(
        input: BirthChartColourInput,
        variables: DerivedVariables,
        rawScores: RawVariableScores
    ) -> Bool {
        guard rawScores.warmth < Thresholds.warmthWarmMin else { return false }

        let coolEarthSigns: Set<V4ZodiacSign> = [.virgo, .capricorn]
        let relevantKeys: [DriverKey] = [.ascendant, .venus, .sun, .moon, .saturn]
        let count = relevantKeys
            .compactMap { input.sign(for: $0) }
            .filter { coolEarthSigns.contains($0) }
            .count

        return count >= 2
    }
}
