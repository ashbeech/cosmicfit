import Foundation

enum Normalizer {

    static func normalizeDrivers(input: BirthChartColourInput) -> NormalizedDriverSet {
        let orderedKeys: [DriverKey] = [
            .ascendant, .venus, .sun, .moon, .mercury, .mars, .saturn, .jupiter
        ]

        let drivers = orderedKeys.compactMap { key -> WeightedDriver? in
            guard let sign = input.sign(for: key),
                  let weight = DriverWeights.weights[key] else { return nil }
            return WeightedDriver(key: key, sign: sign, weight: weight)
        }

        return NormalizedDriverSet(
            drivers: drivers,
            hasPluto: input.pluto != nil,
            plutoSign: input.pluto?.sign
        )
    }
}
