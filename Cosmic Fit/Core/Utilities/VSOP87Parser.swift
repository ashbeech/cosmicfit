//
//  VSOP87Parser.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
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
            case .mercury: return "VSOP87C.mer"
            case .venus: return "VSOP87C.ven"
            case .earth: return "VSOP87C.ear"
            case .mars: return "VSOP87C.mar"
            case .jupiter: return "VSOP87C.jup"
            case .saturn: return "VSOP87C.sat"
            case .uranus: return "VSOP87C.ura"
            case .neptune: return "VSOP87C.nep"
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
        let coordinate: String // "X", "Y", or "Z"
    }
    
    private static var planetData: [Planet: [Component]] = [:]
    
    static func loadData() {
        for planet in Planet.allCases {
            if planetData[planet] == nil {
                planetData[planet] = parseDataFile(for: planet)
            }
        }
    }
    
    private static func parseDataFile(for planet: Planet) -> [Component] {
        
        //print("Looking for file: \(planet.filename)")
        //print("Full bundle path: \(Bundle.main.bundlePath)")
        
        /*
        if let bundlePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            let contents = try? fm.contentsOfDirectory(atPath: bundlePath)
            print("Contents: \(contents ?? [])")
        }*/
        
        guard let url = Bundle.main.url(forResource: planet.filename, withExtension: nil) else {
            print("Could not find VSOP87 data file for \(planet.filename)")
            return []
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return parseVSOP87Data(content)
        } catch {
            print("Error loading VSOP87 data for \(planet): \(error)")
            return []
        }
    }
    
    private static func parseVSOP87Data(_ data: String) -> [Component] {
        var components: [Component] = []
        var currentComponent: Component?
        var currentVariable: Variable?
        var currentTerms: [Term] = []
        
        let lines = data.components(separatedBy: .newlines)
        
        for line in lines {
            if line.isEmpty { continue }
            
            // Check if line starts a new component
            if line.contains("VSOP87") {
                // Save previous component if it exists
                if let comp = currentComponent {
                    components.append(comp)
                }
                
                // Create new component
                let coordinate = line.contains(" X ") ? "X" : (line.contains(" Y ") ? "Y" : "Z")
                currentComponent = Component(variables: [], coordinate: coordinate)
                currentVariable = nil
                currentTerms = []
                
            // Check if line starts a new variable (power of T)
            } else if line.contains("T**") {
                // Save previous variable if it exists
                if let variable = currentVariable {
                    if var comp = currentComponent {
                        var updatedVariables = comp.variables
                        updatedVariables.append(variable)
                        comp.variables = updatedVariables
                        currentComponent = comp
                    }
                }
                
                // Get power of T from line
                let powerString = line.components(separatedBy: "T**").last?.trimmingCharacters(in: .whitespaces) ?? "0"
                let power = Int(powerString) ?? 0
                
                currentVariable = Variable(terms: [], power: power)
                currentTerms = []
                
            // Parse term line
            } else if line.contains(" ") {
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if components.count >= 3 {
                    let a = Double(components[0]) ?? 0.0
                    let b = Double(components[1]) ?? 0.0
                    let c = Double(components[2]) ?? 0.0
                    
                    let term = Term(a: a, b: b, c: c)
                    currentTerms.append(term)
                    
                    if var variable = currentVariable {
                        variable.terms = currentTerms
                        currentVariable = variable
                    }
                }
            }
        }
        
        // Add the last variable if it exists
        if let variable = currentVariable {
            if var comp = currentComponent {
                var updatedVariables = comp.variables
                updatedVariables.append(variable)
                comp.variables = updatedVariables
                currentComponent = comp
            }
        }
        
        // Add the last component if it exists
        if let comp = currentComponent {
            components.append(comp)
        }
        
        return components
    }
    
    static func calculatePosition(planet: Planet, julianDay: Double) -> (x: Double, y: Double, z: Double) {
        loadData()
        
        guard let components = planetData[planet] else {
            return (0, 0, 0)
        }
        
        // Calculate T (time in Julian centuries since J2000.0)
        let T = (julianDay - 2451545.0) / 36525.0
        
        var x: Double = 0.0
        var y: Double = 0.0
        var z: Double = 0.0
        
        for component in components {
            var value: Double = 0.0
            
            for variable in component.variables {
                var sum: Double = 0.0
                
                for term in variable.terms {
                    sum += term.a * cos(term.b + term.c * T)
                }
                
                // Multiply by T^power
                let tPower = pow(T, Double(variable.power))
                value += sum * tPower
            }
            
            switch component.coordinate {
            case "X": x = value
            case "Y": y = value
            case "Z": z = value
            default: break
            }
        }
        
        return (x, y, z)
    }
    
    // Calculate heliocentric ecliptic coordinates (longitude, latitude)
    static func calculateHeliocentricCoordinates(planet: Planet, julianDay: Double) -> (longitude: Double, latitude: Double, radius: Double) {
        let position = calculatePosition(planet: planet, julianDay: julianDay)
        
        let x = position.x
        let y = position.y
        let z = position.z
        
        let radius = sqrt(x*x + y*y + z*z)
        let longitude = atan2(y, x)
        let latitude = asin(z / radius)
        
        // Convert longitude to standard range [0, 2π]
        let lon = (longitude < 0 ? longitude + 2 * Double.pi : longitude)
        
        return (lon, latitude, radius)
    }
    
    // Calculate geocentric ecliptic coordinates
    static func calculateGeocentricCoordinates(planet: Planet, julianDay: Double) -> (longitude: Double, latitude: Double) {
        // Get Earth's position
        let earthPosition = calculatePosition(planet: .earth, julianDay: julianDay)
        
        // Get planet's position
        let planetPosition = calculatePosition(planet: planet, julianDay: julianDay)
        
        // Calculate planet position relative to Earth
        let x = planetPosition.x - earthPosition.x
        let y = planetPosition.y - earthPosition.y
        let z = planetPosition.z - earthPosition.z
        
        let radius = sqrt(x*x + y*y + z*z)
        let longitude = atan2(y, x)
        let latitude = asin(z / radius)
        
        // Convert longitude to standard range [0, 2π]
        let lon = (longitude < 0 ? longitude + 2 * Double.pi : longitude)
        
        return (lon, latitude)
    }
}
