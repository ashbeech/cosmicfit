//
//  NatalChart.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation
import CoreLocation

class NatalChart {
    // Birth information
    let birthDate: Date
    let birthLocation: CLLocation
    
    // Calculated chart components
    private(set) var ascendant: Double = 0.0
    private(set) var midheaven: Double = 0.0
    private(set) var houses: [House] = []
    private(set) var planets: [Planet] = []
    private(set) var aspects: [Aspect] = []
    
    init(birthDate: Date, latitude: Double, longitude: Double) {
        self.birthDate = birthDate
        self.birthLocation = CLLocation(latitude: latitude, longitude: longitude)
        calculateChart()
    }
    
    // Main calculation method
    private func calculateChart() {
        calculateAscendantAndMidheaven()
        calculateHouses()
        calculatePlanetaryPositions()
        calculateAspects()
    }
    
    // MARK: - Calculation Methods
    
    private func calculateAscendantAndMidheaven() {
        // Calculate local sidereal time (LST)
        let jd = AstronomicalUtils.julianDay(from: birthDate)
        let lst = AstronomicalCalculations.calculateLocalSiderealTime(jd: jd, longitude: birthLocation.coordinate.longitude)
        
        // Calculate ascendant (rising sign)
        ascendant = AstronomicalCalculations.calculateAscendant(lst: lst, latitude: birthLocation.coordinate.latitude)
        
        // Calculate Midheaven (MC)
        midheaven = AstronomicalCalculations.calculateMidheaven(lst: lst)
    }
    
    private func calculateHouses() {
        // Calculate houses using Placidus system
        houses = HouseCalculations.calculatePlacidusHouses(ascendant: ascendant, midheaven: midheaven)
    }
    
    private func calculatePlanetaryPositions() {
        // Get Julian day for the birth time
        let jd = AstronomicalUtils.julianDay(from: birthDate)
        
        // Calculate Sun position using VSOP87
        let sunPosition = VSOP87Calculator.calculateSunPosition(jd: jd)
        planets.append(Planet(
            type: .sun,
            longitude: sunPosition,
            latitude: 0,
            inHouse: HouseCalculations.findHouse(position: sunPosition, houses: houses)
        ))
        
        // Calculate Moon position
        let moonPosition = VSOP87Calculator.calculateMoonPosition(jd: jd)
        planets.append(Planet(
            type: .moon,
            longitude: moonPosition.longitude,
            latitude: moonPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: moonPosition.longitude, houses: houses)
        ))
        
        // Calculate Mercury position
        let mercuryPosition = VSOP87Calculator.calculatePlanetPosition(planet: .mercury, jd: jd)
        planets.append(Planet(
            type: .mercury,
            longitude: mercuryPosition.longitude,
            latitude: mercuryPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: mercuryPosition.longitude, houses: houses)
        ))
        
        // Calculate Venus position
        let venusPosition = VSOP87Calculator.calculatePlanetPosition(planet: .venus, jd: jd)
        planets.append(Planet(
            type: .venus,
            longitude: venusPosition.longitude,
            latitude: venusPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: venusPosition.longitude, houses: houses)
        ))
        
        // Calculate Mars position
        let marsPosition = VSOP87Calculator.calculatePlanetPosition(planet: .mars, jd: jd)
        planets.append(Planet(
            type: .mars,
            longitude: marsPosition.longitude,
            latitude: marsPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: marsPosition.longitude, houses: houses)
        ))
        
        // Calculate Jupiter position
        let jupiterPosition = VSOP87Calculator.calculatePlanetPosition(planet: .jupiter, jd: jd)
        planets.append(Planet(
            type: .jupiter,
            longitude: jupiterPosition.longitude,
            latitude: jupiterPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: jupiterPosition.longitude, houses: houses)
        ))
        
        // Calculate Saturn position
        let saturnPosition = VSOP87Calculator.calculatePlanetPosition(planet: .saturn, jd: jd)
        planets.append(Planet(
            type: .saturn,
            longitude: saturnPosition.longitude,
            latitude: saturnPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: saturnPosition.longitude, houses: houses)
        ))
        
        // Calculate Uranus position
        let uranusPosition = VSOP87Calculator.calculatePlanetPosition(planet: .uranus, jd: jd)
        planets.append(Planet(
            type: .uranus,
            longitude: uranusPosition.longitude,
            latitude: uranusPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: uranusPosition.longitude, houses: houses)
        ))
        
        // Calculate Neptune position
        let neptunePosition = VSOP87Calculator.calculatePlanetPosition(planet: .neptune, jd: jd)
        planets.append(Planet(
            type: .neptune,
            longitude: neptunePosition.longitude,
            latitude: neptunePosition.latitude,
            inHouse: HouseCalculations.findHouse(position: neptunePosition.longitude, houses: houses)
        ))
        
        // Calculate Pluto position
        let plutoPosition = VSOP87Calculator.calculatePlanetPosition(planet: .pluto, jd: jd)
        planets.append(Planet(
            type: .pluto,
            longitude: plutoPosition.longitude,
            latitude: plutoPosition.latitude,
            inHouse: HouseCalculations.findHouse(position: plutoPosition.longitude, houses: houses)
        ))
        
        // Calculate North Node (Lunar Node)
        let northNodePosition = VSOP87Calculator.calculateNorthNodePosition(jd: jd)
        planets.append(Planet(
            type: .northNode,
            longitude: northNodePosition,
            latitude: 0,
            inHouse: HouseCalculations.findHouse(position: northNodePosition, houses: houses)
        ))
    }
    
    private func calculateAspects() {
        aspects = AspectCalculations.calculateAspects(planets: planets)
    }
    
    // MARK: - Output Methods
    
    // Convert zodiac position in degrees to sign and degrees within sign
    func getZodiacPosition(_ longitude: Double) -> (sign: ZodiacSign, degrees: Double) {
        let signIndex = Int(longitude / 30.0) % 12
        let degreesInSign = longitude - Double(signIndex) * 30.0
        
        return (ZodiacSign.allCases[signIndex], degreesInSign)
    }
    
    // Get readable format of a zodiac position
    func formatZodiacPosition(_ longitude: Double) -> String {
        let position = getZodiacPosition(longitude)
        let minutes = (position.degrees - floor(position.degrees)) * 60
        
        return "\(position.sign.rawValue) \(Int(position.degrees))° \(Int(minutes))'"
    }
    
    // Generate full chart text report
    func generateReport() -> String {
        var report = "NATAL CHART REPORT\n"
        report += "=================\n\n"
        
        // Birth information
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        report += "Birth Date and Time: \(dateFormatter.string(from: birthDate))\n"
        report += "Birth Location: Latitude \(birthLocation.coordinate.latitude), Longitude \(birthLocation.coordinate.longitude)\n\n"
        
        // Ascendant and Midheaven
        report += "ANGLES\n"
        report += "------\n"
        report += "Ascendant: \(formatZodiacPosition(ascendant))\n"
        report += "Midheaven: \(formatZodiacPosition(midheaven))\n\n"
        
        // Houses
        report += "HOUSES\n"
        report += "------\n"
        for house in houses.sorted(by: { $0.number < $1.number }) {
            report += "House \(house.number): \(formatZodiacPosition(house.cusp))\n"
        }
        report += "\n"
        
        // Planets
        report += "PLANETS\n"
        report += "-------\n"
        for planet in planets {
            report += "\(planet.type.rawValue): \(formatZodiacPosition(planet.longitude)) in House \(planet.inHouse)\n"
        }
        report += "\n"
        
        // Aspects
        report += "ASPECTS\n"
        report += "-------\n"
        for aspect in aspects {
            report += "\(aspect.planet1.rawValue) \(aspect.type.symbol) \(aspect.planet2.rawValue) (orb: \(String(format: "%.2f°", aspect.orb)))\n"
        }
        
        return report
    }
    
    // Generate a dictionary representation for JSON output
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Basic information
        dict["birthDate"] = birthDate.timeIntervalSince1970
        dict["birthLocation"] = [
            "latitude": birthLocation.coordinate.latitude,
            "longitude": birthLocation.coordinate.longitude
        ]
        
        // Angles
        dict["ascendant"] = [
            "degrees": ascendant,
            "position": formatZodiacPosition(ascendant)
        ]
        dict["midheaven"] = [
            "degrees": midheaven,
            "position": formatZodiacPosition(midheaven)
        ]
        
        // Houses
        var housesArray: [[String: Any]] = []
        for house in houses.sorted(by: { $0.number < $1.number }) {
            let position = getZodiacPosition(house.cusp)
            housesArray.append([
                "number": house.number,
                "cusp": house.cusp,
                "sign": position.sign.rawValue,
                "degreesInSign": position.degrees
            ])
        }
        dict["houses"] = housesArray
        
        // Planets
        var planetsArray: [[String: Any]] = []
        for planet in planets {
            let position = getZodiacPosition(planet.longitude)
            planetsArray.append([
                "name": planet.type.rawValue,
                "longitude": planet.longitude,
                "latitude": planet.latitude,
                "sign": position.sign.rawValue,
                "degreesInSign": position.degrees,
                "house": planet.inHouse
            ])
        }
        dict["planets"] = planetsArray
        
        // Aspects
        var aspectsArray: [[String: Any]] = []
        for aspect in aspects {
            aspectsArray.append([
                "planet1": aspect.planet1.rawValue,
                "planet2": aspect.planet2.rawValue,
                "type": aspect.type.rawValue,
                "angle": aspect.angle,
                "orb": aspect.orb
            ])
        }
        dict["aspects"] = aspectsArray
        
        return dict
    }
}
