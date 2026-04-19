import Foundation

enum SecondaryPullDerivation {

    static func derive(
        family: PaletteFamily,
        input: BirthChartColourInput,
        rawScores: RawVariableScores
    ) -> PaletteFamily? {
        let adjacentFamilies = adjacentPulls(for: family)
        guard !adjacentFamilies.isEmpty else { return nil }

        if adjacentFamilies.count == 1 {
            return adjacentFamilies[0]
        }

        return selectPull(
            from: adjacentFamilies,
            input: input,
            rawScores: rawScores,
            primaryFamily: family
        )
    }

    // Intentionally internal (not private) so VariationSlots_Tests can validate
    // map completeness against the real adjacency source.
    static func adjacentPulls(for family: PaletteFamily) -> [PaletteFamily] {
        switch family {
        case .lightSpring:  return [.brightSpring, .lightSummer]
        case .trueSpring:   return [.brightSpring]
        case .brightSpring: return [.brightWinter, .trueAutumn]
        case .lightSummer:  return [.trueSummer, .lightSpring]
        case .trueSummer:   return [.softSummer, .softAutumn, .trueWinter]
        case .softSummer:   return [.trueSummer, .softAutumn]
        case .softAutumn:   return [.trueAutumn, .deepAutumn, .brightWinter]
        case .trueAutumn:   return [.deepAutumn, .trueSpring]
        case .deepAutumn:   return [.trueAutumn, .deepWinter]
        case .deepWinter:   return [.deepAutumn, .brightWinter]
        case .trueWinter:   return [.brightWinter, .trueSummer]
        case .brightWinter: return [.brightSpring, .trueWinter]
        }
    }

    private static func selectPull(
        from candidates: [PaletteFamily],
        input: BirthChartColourInput,
        rawScores: RawVariableScores,
        primaryFamily: PaletteFamily
    ) -> PaletteFamily {
        let fireAir = FamilyMapping.countFireAir(input: input)
        let earthWater = FamilyMapping.countEarthWater(input: input)
        let isWarmLeaning = rawScores.warmth > 0
        let isCoolLeaning = rawScores.warmth < 0
        let isHighChroma = rawScores.saturation > 10

        for candidate in candidates {
            let fits: Bool
            switch candidate {
            case .brightSpring, .brightWinter:
                fits = fireAir >= 3 || isHighChroma
            case .lightSummer, .trueSummer, .softSummer:
                fits = isCoolLeaning
            case .lightSpring, .trueSpring:
                fits = isWarmLeaning && fireAir > earthWater
            case .trueAutumn, .deepAutumn:
                fits = isWarmLeaning && earthWater > fireAir
            case .softAutumn:
                fits = isWarmLeaning && !isHighChroma
            case .deepWinter, .trueWinter:
                fits = isCoolLeaning && rawScores.depth > 20
            }
            if fits { return candidate }
        }

        return candidates[0]
    }
}
