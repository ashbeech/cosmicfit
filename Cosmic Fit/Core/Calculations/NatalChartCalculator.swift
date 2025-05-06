//
//  NatalChartCalculator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

struct NatalChartCalculator {
    struct PlanetPosition {
        let name: String
        let symbol: String
        let longitude: Double
        let latitude: Double
        let zodiacSign: Int
        let zodiacPosition: String
        let inHouse: Int
        let isRetrograde: Bool
    }
    
    struct NatalChart {
        let planets: [PlanetPosition]
        let houses: [Double]
        let ascendant: Double
        let midheaven: Double
        let descendant: Double
        let imumCoeli: Double
        let northNode: Double
        let southNode: Double
        let vertex: Double
        let partOfFortune: Double
        let lilith: Double
        let chiron: Double
        
        // Additional chart points
        let lunarPhase: Double
        let aspects: [(planet1: String, planet2: String, aspectType: String, exactness: Double)]
    }
    
    // Calculate entire natal chart based on birth information
    static func calculateNatalChart(birthDate: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> NatalChart {
        // Convert birth date to UTC
        let utcDate = JulianDateCalculator.localToUTC(date: birthDate, timezone: timeZone)
        
        // Calculate Julian Date
        let julianDay = JulianDateCalculator.calculateJulianDate(from: utcDate)
        
        // House system calculations
        let houses = AstronomicalCalculator.calculateHouseCusps(julianDay: julianDay, latitude: latitude, longitude: longitude)
        
        // Calculate chart angles
        let ascendant = AstronomicalCalculator.calculateAscendant(julianDay: julianDay, latitude: latitude, longitude: longitude)
        let midheaven = AstronomicalCalculator.calculateMidheaven(julianDay: julianDay, longitude: longitude)
        let descendant = CoordinateTransformations.normalizeAngle(ascendant + 180.0)
        let imumCoeli = CoordinateTransformations.normalizeAngle(midheaven + 180.0)
        
        // Calculate vertex
        let vertex = AstronomicalCalculator.calculateVertex(julianDay: julianDay, latitude: latitude, longitude: longitude)
        
        // Calculate North and South Nodes
        let (northNode, southNode) = AstronomicalCalculator.calculateLunarNodes(julianDay: julianDay)
        
        // Calculate planets
        var planets: [PlanetPosition] = []
        
        // Sun
        let (sunLongitude, sunLatitude) = AstronomicalCalculator.calculateSunPosition(julianDay: julianDay)
        let (sunSign, sunPosition) = CoordinateTransformations.decimalDegreesToZodiac(sunLongitude)
        let sunHouse = findHouse(longitude: sunLongitude, houses: houses)
        planets.append(PlanetPosition(
            name: "Sun",
            symbol: "☉",
            longitude: sunLongitude,
            latitude: sunLatitude,
            zodiacSign: sunSign,
            zodiacPosition: sunPosition,
            inHouse: sunHouse,
            isRetrograde: false
        ))
        
        // Moon
        let (moonLongitude, moonLatitude) = AstronomicalCalculator.calculateMoonPosition(julianDay: julianDay)
        let (moonSign, moonPosition) = CoordinateTransformations.decimalDegreesToZodiac(moonLongitude)
        let moonHouse = findHouse(longitude: moonLongitude, houses: houses)
        planets.append(PlanetPosition(
            name: "Moon",
            symbol: "☽",
            longitude: moonLongitude,
            latitude: moonLatitude,
            zodiacSign: moonSign,
            zodiacPosition: moonPosition,
            inHouse: moonHouse,
            isRetrograde: false
        ))
        
        // Mercury
        let mercuryPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .mercury, julianDay: julianDay)
        let mercuryLongitude = CoordinateTransformations.radiansToDegrees(mercuryPosition.longitude)
        let mercuryLatitude = CoordinateTransformations.radiansToDegrees(mercuryPosition.latitude)
        let (mercurySign, mercuryPos) = CoordinateTransformations.decimalDegreesToZodiac(mercuryLongitude)
        let mercuryHouse = findHouse(longitude: mercuryLongitude, houses: houses)
        let mercuryRetrograde = isRetrograde(planet: .mercury, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Mercury",
            symbol: "☿",
            longitude: mercuryLongitude,
            latitude: mercuryLatitude,
            zodiacSign: mercurySign,
            zodiacPosition: mercuryPos,
            inHouse: mercuryHouse,
            isRetrograde: mercuryRetrograde
        ))
        
        // Venus
        let venusPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .venus, julianDay: julianDay)
        let venusLongitude = CoordinateTransformations.radiansToDegrees(venusPosition.longitude)
        let venusLatitude = CoordinateTransformations.radiansToDegrees(venusPosition.latitude)
        let (venusSign, venusPos) = CoordinateTransformations.decimalDegreesToZodiac(venusLongitude)
        let venusHouse = findHouse(longitude: venusLongitude, houses: houses)
        let venusRetrograde = isRetrograde(planet: .venus, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Venus",
            symbol: "♀",
            longitude: venusLongitude,
            latitude: venusLatitude,
            zodiacSign: venusSign,
            zodiacPosition: venusPos,
            inHouse: venusHouse,
            isRetrograde: venusRetrograde
        ))
        
        // Mars
        let marsPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .mars, julianDay: julianDay)
        let marsLongitude = CoordinateTransformations.radiansToDegrees(marsPosition.longitude)
        let marsLatitude = CoordinateTransformations.radiansToDegrees(marsPosition.latitude)
        let (marsSign, marsPos) = CoordinateTransformations.decimalDegreesToZodiac(marsLongitude)
        let marsHouse = findHouse(longitude: marsLongitude, houses: houses)
        let marsRetrograde = isRetrograde(planet: .mars, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Mars",
            symbol: "♂",
            longitude: marsLongitude,
            latitude: marsLatitude,
            zodiacSign: marsSign,
            zodiacPosition: marsPos,
            inHouse: marsHouse,
            isRetrograde: marsRetrograde
        ))
        
        // Jupiter
        let jupiterPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .jupiter, julianDay: julianDay)
        let jupiterLongitude = CoordinateTransformations.radiansToDegrees(jupiterPosition.longitude)
        let jupiterLatitude = CoordinateTransformations.radiansToDegrees(jupiterPosition.latitude)
        let (jupiterSign, jupiterPos) = CoordinateTransformations.decimalDegreesToZodiac(jupiterLongitude)
        let jupiterHouse = findHouse(longitude: jupiterLongitude, houses: houses)
        let jupiterRetrograde = isRetrograde(planet: .jupiter, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Jupiter",
            symbol: "♃",
            longitude: jupiterLongitude,
            latitude: jupiterLatitude,
            zodiacSign: jupiterSign,
            zodiacPosition: jupiterPos,
            inHouse: jupiterHouse,
            isRetrograde: jupiterRetrograde
        ))
        
        // Saturn
        let saturnPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .saturn, julianDay: julianDay)
        let saturnLongitude = CoordinateTransformations.radiansToDegrees(saturnPosition.longitude)
        let saturnLatitude = CoordinateTransformations.radiansToDegrees(saturnPosition.latitude)
        let (saturnSign, saturnPos) = CoordinateTransformations.decimalDegreesToZodiac(saturnLongitude)
        let saturnHouse = findHouse(longitude: saturnLongitude, houses: houses)
        let saturnRetrograde = isRetrograde(planet: .saturn, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Saturn",
            symbol: "♄",
            longitude: saturnLongitude,
            latitude: saturnLatitude,
            zodiacSign: saturnSign,
            zodiacPosition: saturnPos,
            inHouse: saturnHouse,
            isRetrograde: saturnRetrograde
        ))
        
        // Uranus
        let uranusPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .uranus, julianDay: julianDay)
        let uranusLongitude = CoordinateTransformations.radiansToDegrees(uranusPosition.longitude)
        let uranusLatitude = CoordinateTransformations.radiansToDegrees(uranusPosition.latitude)
        let (uranusSign, uranusPos) = CoordinateTransformations.decimalDegreesToZodiac(uranusLongitude)
        let uranusHouse = findHouse(longitude: uranusLongitude, houses: houses)
        let uranusRetrograde = isRetrograde(planet: .uranus, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Uranus",
            symbol: "♅",
            longitude: uranusLongitude,
            latitude: uranusLatitude,
            zodiacSign: uranusSign,
            zodiacPosition: uranusPos,
            inHouse: uranusHouse,
            isRetrograde: uranusRetrograde
        ))
        
        // Neptune
        let neptunePosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .neptune, julianDay: julianDay)
        let neptuneLongitude = CoordinateTransformations.radiansToDegrees(neptunePosition.longitude)
        let neptuneLatitude = CoordinateTransformations.radiansToDegrees(neptunePosition.latitude)
        let (neptuneSign, neptunePos) = CoordinateTransformations.decimalDegreesToZodiac(neptuneLongitude)
        let neptuneHouse = findHouse(longitude: neptuneLongitude, houses: houses)
        let neptuneRetrograde = isRetrograde(planet: .neptune, julianDay: julianDay)
        planets.append(PlanetPosition(
            name: "Neptune",
            symbol: "♆",
            longitude: neptuneLongitude,
            latitude: neptuneLatitude,
            zodiacSign: neptuneSign,
            zodiacPosition: neptunePos,
            inHouse: neptuneHouse,
            isRetrograde: neptuneRetrograde
        ))
        
        // Pluto (not technically a planet, but commonly used in astrology)
        // For Pluto, we use a simplified calculation
        let plutoLongitude = calculateSimplifiedPlanetPosition(julianDay: julianDay, planet: "Pluto")
        let (plutoSign, plutoPos) = CoordinateTransformations.decimalDegreesToZodiac(plutoLongitude)
        let plutoHouse = findHouse(longitude: plutoLongitude, houses: houses)
        planets.append(PlanetPosition(
            name: "Pluto",
            symbol: "♇",
            longitude: plutoLongitude,
            latitude: 0.0,
            zodiacSign: plutoSign,
            zodiacPosition: plutoPos,
            inHouse: plutoHouse,
            isRetrograde: false
        ))
        
        // Calculate Chiron position
        let chironLongitude = AstronomicalCalculator.calculateChironPosition(julianDay: julianDay)
        let (chironSign, chironPos) = CoordinateTransformations.decimalDegreesToZodiac(chironLongitude)
        let chironHouse = findHouse(longitude: chironLongitude, houses: houses)
        
        // Calculate Lilith (Mean Black Moon Lilith) position
        let lilithLongitude = calculateLilithPosition(julianDay: julianDay)
        let (lilithSign, lilithPos) = CoordinateTransformations.decimalDegreesToZodiac(lilithLongitude)
        let lilithHouse = findHouse(longitude: lilithLongitude, houses: houses)
        
        // Add asteroid Ceres
        let ceresLongitude = calculateSimplifiedPlanetPosition(julianDay: julianDay, planet: "Ceres")
        let (ceresSign, ceresPos) = CoordinateTransformations.decimalDegreesToZodiac(ceresLongitude)
        let ceresHouse = findHouse(longitude: ceresLongitude, houses: houses)
        planets.append(PlanetPosition(
            name: "Ceres",
            symbol: "⚳",
            longitude: ceresLongitude,
            latitude: 0.0,
            zodiacSign: ceresSign,
            zodiacPosition: ceresPos,
            inHouse: ceresHouse,
            isRetrograde: false
        ))
        
        // Add asteroid Pallas
        let pallasLongitude = calculateSimplifiedPlanetPosition(julianDay: julianDay, planet: "Pallas")
        let (pallasSign, pallasPos) = CoordinateTransformations.decimalDegreesToZodiac(pallasLongitude)
        let pallasHouse = findHouse(longitude: pallasLongitude, houses: houses)
        planets.append(PlanetPosition(
            name: "Pallas",
            symbol: "⚴",
            longitude: pallasLongitude,
            latitude: 0.0,
            zodiacSign: pallasSign,
            zodiacPosition: pallasPos,
            inHouse: pallasHouse,
            isRetrograde: false
        ))
        
        // Add asteroid Juno
        let junoLongitude = calculateSimplifiedPlanetPosition(julianDay: julianDay, planet: "Juno")
        let (junoSign, junoPos) = CoordinateTransformations.decimalDegreesToZodiac(junoLongitude)
        let junoHouse = findHouse(longitude: junoLongitude, houses: houses)
        planets.append(PlanetPosition(
            name: "Juno",
            symbol: "⚵",
            longitude: junoLongitude,
            latitude: 0.0,
            zodiacSign: junoSign,
            zodiacPosition: junoPos,
            inHouse: junoHouse,
            isRetrograde: false
        ))
        
        // Calculate Part of Fortune
        let partOfFortune = calculatePartOfFortune(ascendant: ascendant, sunLongitude: sunLongitude, moonLongitude: moonLongitude)
        
        // Calculate lunar phase
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)
        
        // Calculate aspects between planets
        var aspects: [(planet1: String, planet2: String, aspectType: String, exactness: Double)] = []
        
        for i in 0..<planets.count {
            // Calculate aspects between planets
            for j in (i + 1)..<planets.count {
                if let aspect = AstronomicalCalculator.calculateAspect(point1: planets[i].longitude, point2: planets[j].longitude) {
                    aspects.append((
                        planet1: planets[i].name,
                        planet2: planets[j].name,
                        aspectType: aspect.aspectType,
                        exactness: aspect.exactness
                    ))
                }
            }
            
            // Calculate aspects with chart angles
            if let aspectWithAsc = AstronomicalCalculator.calculateAspect(point1: planets[i].longitude, point2: ascendant) {
                aspects.append((
                    planet1: planets[i].name,
                    planet2: "Ascendant",
                    aspectType: aspectWithAsc.aspectType,
                    exactness: aspectWithAsc.exactness
                ))
            }
            
            if let aspectWithMC = AstronomicalCalculator.calculateAspect(point1: planets[i].longitude, point2: midheaven) {
                aspects.append((
                    planet1: planets[i].name,
                    planet2: "Midheaven",
                    aspectType: aspectWithMC.aspectType,
                    exactness: aspectWithMC.exactness
                ))
            }
        }
        
        return NatalChart(
            planets: planets,
            houses: houses,
            ascendant: ascendant,
            midheaven: midheaven,
            descendant: descendant,
            imumCoeli: imumCoeli,
            northNode: northNode,
            southNode: southNode,
            vertex: vertex,
            partOfFortune: partOfFortune,
            lilith: lilithLongitude,
            chiron: chironLongitude,
            lunarPhase: lunarPhase,
            aspects: aspects
        )
    }
    
    // Find which house a planet is in
    private static func findHouse(longitude: Double, houses: [Double]) -> Int {
        for i in 1...12 {
            let nextHouse = i < 12 ? i + 1 : 1
            
            var start = houses[i]
            var end = houses[nextHouse]
            
            // Handle house cusp wrap-around at 0°/360°
            if end < start {
                end += 360.0
            }
            
            var normalizedLongitude = longitude
            if normalizedLongitude < start {
                normalizedLongitude += 360.0
            }
            
            if normalizedLongitude >= start && normalizedLongitude < end {
                return i
            }
        }
        
        // Default to first house if not found
        return 1
    }
    
    // Calculate if a planet is retrograde
    private static func isRetrograde(planet: VSOP87Parser.Planet, julianDay: Double) -> Bool {
        // We need to calculate positions at two close points in time
        // and see if the longitude is decreasing (retrograde) or increasing
        
        let position1 = VSOP87Parser.calculateGeocentricCoordinates(planet: planet, julianDay: julianDay)
        let position2 = VSOP87Parser.calculateGeocentricCoordinates(planet: planet, julianDay: julianDay + 1.0)
        
        let longitude1 = CoordinateTransformations.radiansToDegrees(position1.longitude)
        let longitude2 = CoordinateTransformations.radiansToDegrees(position2.longitude)
        
        // Adjust for 0°/360° boundary
        var diff = longitude2 - longitude1
        if diff > 180.0 {
            diff -= 360.0
        } else if diff < -180.0 {
            diff += 360.0
        }
        
        // If longitude is decreasing, the planet is retrograde
        return diff < 0
    }
    
    // Calculate Part of Fortune
    private static func calculatePartOfFortune(ascendant: Double, sunLongitude: Double, moonLongitude: Double) -> Double {
        // Part of Fortune = Ascendant + Moon - Sun
        let pof = ascendant + moonLongitude - sunLongitude
        return CoordinateTransformations.normalizeAngle(pof)
    }
    
    // Calculate Lilith (Mean Black Moon) position
    private static func calculateLilithPosition(julianDay: Double) -> Double {
        // T is the number of centuries since J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Mean Lunar apogee (Lilith)
        var lilith = 280.0 + 36000.0 * T + 13.0 * T * T
        
        // Mean motion of Lilith (approximation)
        lilith += 18.0 * 360.0 / 365.25 * (julianDay - 2451545.0) / 360.0
        lilith = CoordinateTransformations.normalizeAngle(lilith)
        
        // Apply nutation
        let (nutationLongitude, _) = AstronomicalCalculator.calculateNutation(julianDay: julianDay)
        lilith += nutationLongitude
        
        return CoordinateTransformations.normalizeAngle(lilith)
    }
    
    // Simplified planetary positions for additional bodies
    private static func calculateSimplifiedPlanetPosition(julianDay: Double, planet: String) -> Double {
        // This is a very simplified calculation
        // For a real implementation, proper ephemeris data should be used
        
        // For demonstration purposes, we'll use approximate positions based on the Julian day
        let T = (julianDay - 2451545.0) / 36525.0
        
        switch planet {
        case "Pluto":
            // Very simplified Pluto longitude calculation
            return CoordinateTransformations.normalizeAngle(238.96 + 144.96 * T)
            
        case "Ceres":
            // Simplified Ceres longitude calculation
            return CoordinateTransformations.normalizeAngle(107.68 + 59.5 * T)
            
        case "Pallas":
            // Simplified Pallas longitude calculation
            return CoordinateTransformations.normalizeAngle(310.17 + 42.3 * T)
            
        case "Juno":
            // Simplified Juno longitude calculation
            return CoordinateTransformations.normalizeAngle(27.68 + 31.4 * T)
            
        default:
            return 0.0
        }
    }
    
    // Format natal chart data for display
    static func formatNatalChart(_ chart: NatalChart) -> [String: Any] {
        // Create a dictionary to hold the formatted chart data
        var formattedChart: [String: Any] = [:]
        
        // Format planets
        var formattedPlanets: [[String: Any]] = []
        for planet in chart.planets {
            let zodiacSignName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            let zodiacSignSymbol = CoordinateTransformations.getZodiacSignSymbol(sign: planet.zodiacSign)
            
            formattedPlanets.append([
                "name": planet.name,
                "symbol": planet.symbol,
                "longitude": planet.longitude,
                "formattedPosition": "\(planet.zodiacPosition) \(zodiacSignName)",
                "zodiacSign": zodiacSignName,
                "zodiacSymbol": zodiacSignSymbol,
                "house": planet.inHouse,
                "isRetrograde": planet.isRetrograde
            ])
        }
        
        // Format houses
        var formattedHouses: [[String: Any]] = []
        for i in 1...12 {
            let (sign, position) = CoordinateTransformations.decimalDegreesToZodiac(chart.houses[i])
            let signName = CoordinateTransformations.getZodiacSignName(sign: sign)
            let signSymbol = CoordinateTransformations.getZodiacSignSymbol(sign: sign)
            
            formattedHouses.append([
                "house": i,
                "longitude": chart.houses[i],
                "formattedPosition": "\(position) \(signName)",
                "zodiacSign": signName,
                "zodiacSymbol": signSymbol
            ])
        }
        
        // Format angles and points
        let (ascSign, ascPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant)
        let (mcSign, mcPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.midheaven)
        let (descSign, descPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.descendant)
        let (icSign, icPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.imumCoeli)
        
        let angles: [String: Any] = [
            "Ascendant": [
                "longitude": chart.ascendant,
                "formattedPosition": "\(ascPos) \(CoordinateTransformations.getZodiacSignName(sign: ascSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: ascSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: ascSign)
            ],
            "Midheaven": [
                "longitude": chart.midheaven,
                "formattedPosition": "\(mcPos) \(CoordinateTransformations.getZodiacSignName(sign: mcSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: mcSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: mcSign)
            ],
            "Descendant": [
                "longitude": chart.descendant,
                "formattedPosition": "\(descPos) \(CoordinateTransformations.getZodiacSignName(sign: descSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: descSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: descSign)
            ],
            "ImumCoeli": [
                "longitude": chart.imumCoeli,
                "formattedPosition": "\(icPos) \(CoordinateTransformations.getZodiacSignName(sign: icSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: icSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: icSign)
            ]
        ]
        
        // Format nodes, Lilith, Chiron and other points
        let (nnSign, nnPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.northNode)
        let (ssSign, ssPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.southNode)
        let (lilithSign, lilithPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.lilith)
        let (chironSign, chironPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.chiron)
        let (pofSign, pofPos) = CoordinateTransformations.decimalDegreesToZodiac(chart.partOfFortune)
        
        let points: [String: Any] = [
            "NorthNode": [
                "longitude": chart.northNode,
                "formattedPosition": "\(nnPos) \(CoordinateTransformations.getZodiacSignName(sign: nnSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: nnSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: nnSign),
                "house": findHouse(longitude: chart.northNode, houses: chart.houses)
            ],
            "SouthNode": [
                "longitude": chart.southNode,
                "formattedPosition": "\(ssPos) \(CoordinateTransformations.getZodiacSignName(sign: ssSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: ssSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: ssSign),
                "house": findHouse(longitude: chart.southNode, houses: chart.houses)
            ],
            "Lilith": [
                "longitude": chart.lilith,
                "formattedPosition": "\(lilithPos) \(CoordinateTransformations.getZodiacSignName(sign: lilithSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: lilithSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: lilithSign),
                "house": findHouse(longitude: chart.lilith, houses: chart.houses)
            ],
            "Chiron": [
                "longitude": chart.chiron,
                "formattedPosition": "\(chironPos) \(CoordinateTransformations.getZodiacSignName(sign: chironSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: chironSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: chironSign),
                "house": findHouse(longitude: chart.chiron, houses: chart.houses)
            ],
            "PartOfFortune": [
                "longitude": chart.partOfFortune,
                "formattedPosition": "\(pofPos) \(CoordinateTransformations.getZodiacSignName(sign: pofSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: pofSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: pofSign),
                "house": findHouse(longitude: chart.partOfFortune, houses: chart.houses)
            ]
        ]
        
        // Format aspects
        var formattedAspects: [[String: Any]] = []
        for aspect in chart.aspects {
            formattedAspects.append([
                "planet1": aspect.planet1,
                "planet2": aspect.planet2,
                "aspectType": aspect.aspectType,
                "exactness": aspect.exactness
            ])
        }
        
        // Add all formatted data to the chart dictionary
        formattedChart["planets"] = formattedPlanets
        formattedChart["houses"] = formattedHouses
        formattedChart["angles"] = angles
        formattedChart["points"] = points
        formattedChart["aspects"] = formattedAspects
        
        // Add lunar phase
        var phaseDescription = ""
        let phase = chart.lunarPhase
        
        if phase < 45.0 {
            phaseDescription = "New Moon"
        } else if phase < 90.0 {
            phaseDescription = "Waxing Crescent"
        } else if phase < 135.0 {
            phaseDescription = "First Quarter"
        } else if phase < 180.0 {
            phaseDescription = "Waxing Gibbous"
        } else if phase < 225.0 {
            phaseDescription = "Full Moon"
        } else if phase < 270.0 {
            phaseDescription = "Waning Gibbous"
        } else if phase < 315.0 {
            phaseDescription = "Last Quarter"
        } else {
            phaseDescription = "Waning Crescent"
        }
        
        formattedChart["lunarPhase"] = [
            "angle": chart.lunarPhase,
            "description": phaseDescription
        ]
        
        return formattedChart
    }
}
