
//
//  VSOP87Parser.swift
//  Cosmic Fit
//
//  Updated to support VSOP87D single files containing L, B, R variables
//

import Foundation

struct VSOP87Parser {
    enum Planet: String, CaseIterable {
        case mercury = "MERCURY"
        case venus = "VENUS"
        case earth = "EARTH"
        case mars = "MARS"
        case jupiter = "JUPITER"
        case saturn = "SATURN"
        case uranus = "URANUS"
        case neptune = "NEPTUNE"

        var filename: String {
            switch self {
            case .mercury: return "VSOP87D.mer"
            case .venus: return "VSOP87D.ven"
            case .earth: return "VSOP87D.ear"
            case .mars: return "VSOP87D.mar"
            case .jupiter: return "VSOP87D.jup"
            case .saturn: return "VSOP87D.sat"
            case .uranus: return "VSOP87D.ura"
            case .neptune: return "VSOP87D.nep"
            }
        }
    }

    struct Term {
        let a: Double
        let b: Double
        let c: Double
    }

    struct Variable {
        var terms: [Term]
        let power: Int
    }

    struct Component {
        var variables: [Variable]
        let label: String // "L", "B", or "R"
    }

    private static var planetData: [Planet: [String: Component]] = [:]

    static func loadData() {
        for planet in Planet.allCases {
            if planetData[planet] == nil {
                planetData[planet] = loadComponents(for: planet)
            }
        }
    }

    private static func loadComponents(for planet: Planet) -> [String: Component] {
        var components: [String: Component] = [:]

        guard let url = Bundle.main.url(forResource: planet.filename, withExtension: nil) else {
            print("Could not find file: \(planet.filename)")
            return components
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            components = parseVSOP87DFile(content)
        } catch {
            print("Failed to read \(planet.filename): \(error)")
        }

        return components
    }

    private static func parseVSOP87DFile(_ data: String) -> [String: Component] {
        var components: [String: Component] = [:]

        let lines = data.components(separatedBy: .newlines)

        var currentLabel = ""
        var currentVariables: [Variable] = []
        var currentVariable: Variable?
        var currentTerms: [Term] = []

        for line in lines {
            if line.contains("VARIABLE =") {
                if let label = currentLabel.isEmpty ? nil : currentLabel {
                    if let variable = currentVariable {
                        currentVariables.append(variable)
                    }
                    components[label] = Component(variables: currentVariables, label: label)
                }

                currentLabel = line.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces) ?? ""
                currentVariables = []
                currentVariable = nil
                currentTerms = []
            } else if line.contains("T**") {
                if let variable = currentVariable {
                    currentVariables.append(variable)
                }

                let powerString = line.components(separatedBy: "T**").last?.trimmingCharacters(in: .whitespaces) ?? "0"
                let power = Int(powerString) ?? 0
                currentVariable = Variable(terms: [], power: power)
                currentTerms = []
            } else {
                let parts = line.split(separator: " ").map(String.init).filter { !$0.isEmpty }
                if parts.count >= 3,
                   let a = Double(parts[0]),
                   let b = Double(parts[1]),
                   let c = Double(parts[2]) {
                    let term = Term(a: a, b: b, c: c)
                    currentTerms.append(term)

                    if var variable = currentVariable {
                        variable.terms = currentTerms
                        currentVariable = variable
                    }
                }
            }
        }

        if let variable = currentVariable {
            currentVariables.append(variable)
        }
        if !currentLabel.isEmpty {
            components[currentLabel] = Component(variables: currentVariables, label: currentLabel)
        }

        return components
    }

    static func calculateHeliocentricCoordinates(planet: Planet, julianDay: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        loadData()

        guard let components = planetData[planet],
              let lonComp = components["L"],
              let latComp = components["B"],
              let radComp = components["R"] else {
            return (0, 0, 0)
        }

        let T = (julianDay - 2451545.0) / 36525.0

        func calculateValue(from component: Component) -> Double {
            var value: Double = 0.0
            for variable in component.variables {
                let sum = variable.terms.reduce(0.0) { $0 + $1.a * cos($1.b + $1.c * T) }
                value += sum * pow(T, Double(variable.power))
            }
            return value
        }

        var lon = calculateValue(from: lonComp)
        if lon < 0 { lon += 2 * .pi }
        else if lon >= 2 * .pi { lon = fmod(lon, 2 * .pi) }

        let lat = calculateValue(from: latComp)
        let rad = calculateValue(from: radComp)

        return (lon, lat, rad)
    }

    static func calculateGeocentricCoordinates(planet: Planet, julianDay: Double) -> (longitude: Double, latitude: Double) {
        let earthCoords = calculateHeliocentricCoordinates(planet: .earth, julianDay: julianDay)
        let planetCoords = calculateHeliocentricCoordinates(planet: planet, julianDay: julianDay)

        func toRectangular(lon: Double, lat: Double, rad: Double) -> (x: Double, y: Double, z: Double) {
            let x = rad * cos(lat) * cos(lon)
            let y = rad * cos(lat) * sin(lon)
            let z = rad * sin(lat)
            return (x, y, z)
        }

        let planetVec = toRectangular(lon: planetCoords.longitude, lat: planetCoords.latitude, rad: planetCoords.radius)
        let earthVec = toRectangular(lon: earthCoords.longitude, lat: earthCoords.latitude, rad: earthCoords.radius)

        let x = planetVec.x - earthVec.x
        let y = planetVec.y - earthVec.y
        let z = planetVec.z - earthVec.z

        let r = sqrt(x * x + y * y + z * z)
        let lon = atan2(y, x)
        let lat = asin(z / r)

        var normalizedLon = lon
        if normalizedLon < 0 { normalizedLon += 2 * .pi }

        return (normalizedLon, lat)
    }
}
