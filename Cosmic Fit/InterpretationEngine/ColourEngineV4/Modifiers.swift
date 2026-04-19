import Foundation

enum Modifiers {

    // MARK: - 8.1 Scorpio Density

    static func applyScorpioDensity(
        input: BirthChartColourInput,
        scores: inout RawVariableScores,
        flags: inout OverrideFlags
    ) {
        var applied = false

        for (_, placement) in input.allCorePlacements where placement.sign == .scorpio {
            scores.depth    += 10
            scores.contrast += 8
            scores.warmth   -= 3
            applied = true
        }

        for (_, placement) in input.allOuterPlacements where placement.sign == .scorpio {
            scores.depth    += 4
            scores.contrast += 3
            scores.warmth   -= 1
            applied = true
        }

        flags.scorpioDensityApplied = applied
    }

    // MARK: - 8.2 Capricorn/Virgo Cooling + Structure

    static func applyCapricornVirgoCooling(
        input: BirthChartColourInput,
        scores: inout RawVariableScores,
        flags: inout OverrideFlags
    ) {
        var applied = false

        for (_, placement) in input.allCorePlacements {
            if placement.sign == .capricorn {
                scores.depth     += 8
                scores.warmth    -= 5
                scores.structure += 8
                applied = true
            }
            if placement.sign == .virgo {
                scores.warmth     -= 3
                scores.saturation -= 3
                scores.structure  += 4
                applied = true
            }
        }

        flags.capricornVirgoCoolingApplied = applied
    }

    // MARK: - 8.3 Fire-Air Chroma

    static let fireAirSigns: Set<V4ZodiacSign> = [
        .aries, .leo, .sagittarius, .gemini, .libra, .aquarius
    ]

    static func applyFireAirChroma(
        input: BirthChartColourInput,
        scores: inout RawVariableScores,
        flags: inout OverrideFlags
    ) {
        let relevantDrivers: [DriverKey] = [.ascendant, .venus, .sun, .moon, .mercury, .mars]
        let count = relevantDrivers.compactMap { input.sign(for: $0) }
            .filter { fireAirSigns.contains($0) }
            .count

        if count >= 4 {
            scores.saturation += 12
            scores.contrast   += 8
            flags.fireAirChromaApplied = true
        }
    }

    // MARK: - 8.4 Water Softening

    static func applyWaterSoftening(
        input: BirthChartColourInput,
        scores: inout RawVariableScores,
        flags: inout OverrideFlags
    ) {
        let waterSoftSigns: Set<V4ZodiacSign> = [.cancer, .pisces]
        let count = input.coreDriverSigns.filter { waterSoftSigns.contains($0) }.count

        if count >= 2 {
            scores.saturation -= 8
            scores.contrast   -= 8
            scores.structure  -= 8
            flags.waterSofteningApplied = true
        }
    }

    // MARK: - Apply All (locked order)

    static func applyAll(
        input: BirthChartColourInput,
        scores: inout RawVariableScores,
        flags: inout OverrideFlags
    ) {
        applyScorpioDensity(input: input, scores: &scores, flags: &flags)
        applyCapricornVirgoCooling(input: input, scores: &scores, flags: &flags)
        applyFireAirChroma(input: input, scores: &scores, flags: &flags)
        applyWaterSoftening(input: input, scores: &scores, flags: &flags)
    }
}
