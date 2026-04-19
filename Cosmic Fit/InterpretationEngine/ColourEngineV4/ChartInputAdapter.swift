import Foundation

/// Converts the app's existing `NatalChart` + `ChartAnalysis` into the V4 engine's
/// `BirthChartColourInput`. This is the only entry point for V4 engine inputs —
/// no legacy season labels, colour scoring, or palette-derived signals are used.
enum ChartInputAdapter {

    struct BoundaryFlag: Codable, Equatable {
        let driverKey: DriverKey
        let sign: V4ZodiacSign
        let degreeFromCusp: Double
    }

    struct AdaptedInput: Codable, Equatable {
        let colourInput: BirthChartColourInput
        let boundaryFlags: [BoundaryFlag]
    }

    /// Convert a `ChartAnalysis` (plus the raw `NatalChart` for degree info) into V4 input.
    /// `ChartAnalysis.planetSigns` is keyed by planet name (e.g. "Venus", "Sun").
    static func adapt(
        analysis: ChartAnalysis,
        natalChart: NatalChartCalculator.NatalChart
    ) -> AdaptedInput {
        let signMap = analysis.planetSigns
        var boundaryFlags: [BoundaryFlag] = []

        func placement(
            for planet: String,
            driverKey: DriverKey,
            longitude: Double?
        ) -> PlacementInput {
            let signName = planet == "Ascendant" ? analysis.ascendantSign : (signMap[planet] ?? "Aries")
            let sign = V4ZodiacSign(rawValue: signName) ?? .aries
            let degree = longitude.map { $0.truncatingRemainder(dividingBy: 30.0) }

            if let deg = degree {
                let fromCusp = min(deg, 30.0 - deg)
                if fromCusp < 1.0 {
                    boundaryFlags.append(BoundaryFlag(
                        driverKey: driverKey,
                        sign: sign,
                        degreeFromCusp: fromCusp
                    ))
                }
            }

            return PlacementInput(sign: sign, degree: degree)
        }

        func longitude(for planetName: String) -> Double? {
            natalChart.planets.first(where: { $0.name == planetName })?.longitude
        }

        let ascendantDeg = natalChart.ascendant.truncatingRemainder(dividingBy: 30.0)
        let ascendantSign = V4ZodiacSign(rawValue: analysis.ascendantSign) ?? .aries
        if min(ascendantDeg, 30.0 - ascendantDeg) < 1.0 {
            boundaryFlags.append(BoundaryFlag(
                driverKey: .ascendant,
                sign: ascendantSign,
                degreeFromCusp: min(ascendantDeg, 30.0 - ascendantDeg)
            ))
        }

        let colourInput = BirthChartColourInput(
            ascendant: PlacementInput(sign: ascendantSign, degree: ascendantDeg),
            venus: placement(for: "Venus", driverKey: .venus, longitude: longitude(for: "Venus")),
            sun: placement(for: "Sun", driverKey: .sun, longitude: longitude(for: "Sun")),
            moon: placement(for: "Moon", driverKey: .moon, longitude: longitude(for: "Moon")),
            mercury: placement(for: "Mercury", driverKey: .mercury, longitude: longitude(for: "Mercury")),
            mars: placement(for: "Mars", driverKey: .mars, longitude: longitude(for: "Mars")),
            saturn: placement(for: "Saturn", driverKey: .saturn, longitude: longitude(for: "Saturn")),
            jupiter: placement(for: "Jupiter", driverKey: .jupiter, longitude: longitude(for: "Jupiter")),
            pluto: placement(for: "Pluto", driverKey: .pluto, longitude: longitude(for: "Pluto"))
        )

        return AdaptedInput(
            colourInput: colourInput,
            boundaryFlags: boundaryFlags
        )
    }
}
