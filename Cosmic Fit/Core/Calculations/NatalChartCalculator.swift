//
//  NatalChartCalculator.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

struct NatalChartCalculator {
    // MARK: – Data Types --------------------------------------------------

    struct PlanetPosition {
        let name: String
        let symbol: String
        let longitude: Double
        let latitude: Double
        let zodiacSign: Int
        let zodiacPosition: String
        let isRetrograde: Bool
    }

    struct NatalChart {
        let planets: [PlanetPosition]
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
        let lunarPhase: Double
    }

    // MARK: – Public API --------------------------------------------------

    static func calculateNatalChart(birthDate: Date,
                                    latitude: Double,
                                    longitude: Double,
                                    timeZone: TimeZone) -> NatalChart {

        // Ensure Swiss Ephemeris path is set
        AsteroidCalculator.bootstrap()

        // 1) Convert to UTC & Julian Day -----------------------------------
        let utcDate   = JulianDateCalculator.localToUTC(date: birthDate, timezone: timeZone)
        let jd        = JulianDateCalculator.calculateJulianDate(from: utcDate)

        // 2) Angles ----------------------------------------------
        let ascendant  = AstronomicalCalculator.calculateAscendant(julianDay: jd,
                                                                   latitude: latitude,
                                                                   longitude: longitude)
        let midheaven  = AstronomicalCalculator.calculateMidheaven(julianDay: jd,
                                                                    longitude: longitude)
        let descendant = CoordinateTransformations.normalizeAngle(ascendant + 180)
        let imumCoeli  = CoordinateTransformations.normalizeAngle(midheaven + 180)
        let vertex     = AstronomicalCalculator.calculateVertex(julianDay: jd,
                                                                 latitude: latitude,
                                                                 longitude: longitude)

        // 3) Nodes ---------------------------------------------------------
        let (northNode, southNode) = AstronomicalCalculator.calculateLunarNodes(julianDay: jd)

        // 4) Planet array ---------------------------------------------------
        var planets: [PlanetPosition] = []

        // local helper
        func appendPlanet(_ name: String, _ symbol: String,
                          _ lon: Double, _ lat: Double, _ retro: Bool) {
            let (sign, posStr) = CoordinateTransformations.decimalDegreesToZodiac(lon)
            planets.append(PlanetPosition(name: name,
                                           symbol: symbol,
                                           longitude: lon,
                                           latitude: lat,
                                           zodiacSign: sign,
                                           zodiacPosition: posStr,
                                           isRetrograde: retro))
        }

        // --- Sun & Moon ----------------------------------------------------
        do {
            let (lon, lat) = AstronomicalCalculator.calculateSunPosition(julianDay: jd)
            appendPlanet("Sun", "☉", lon, lat, false)
        }
        do {
            let (lon, lat) = AstronomicalCalculator.calculateMoonPosition(julianDay: jd)
            appendPlanet("Moon", "☽", lon, lat, false)
        }

        // --- VSOP87 planets -----------------------------------------------
        func addVSOP(_ p: VSOP87Parser.Planet, _ name: String, _ symbol: String) {
            let geo = VSOP87Parser.calculateGeocentricCoordinates(planet: p, julianDay: jd)
            let lon = CoordinateTransformations.radiansToDegrees(geo.longitude)
            let lat = CoordinateTransformations.radiansToDegrees(geo.latitude)
            let retro = isRetrograde(planet: p, julianDay: jd)
            appendPlanet(name, symbol, lon, lat, retro)
        }
        addVSOP(.mercury, "Mercury", "☿")
        addVSOP(.venus,   "Venus",   "♀")
        addVSOP(.mars,    "Mars",    "♂")
        addVSOP(.jupiter, "Jupiter", "♃")
        addVSOP(.saturn,  "Saturn",  "♄")
        addVSOP(.uranus,  "Uranus",  "♅")
        addVSOP(.neptune, "Neptune", "♆")

        // --- Pluto (simplified) -------------------------------------------
        let plutoLon = calculateSimplifiedPlanetPosition(julianDay: jd, planet: "Pluto")
        appendPlanet("Pluto", "♇", plutoLon, 0, false)

        // --- Swiss‑Ephemeris asteroids ------------------------------------
        let asteroidPositions = AsteroidCalculator.positions(at: jd)
        for (ast, pos) in asteroidPositions {
            let retro = AsteroidCalculator.isRetrograde(ast, at: jd)
            appendPlanet(ast.displayName, ast.symbol, pos.longitude, pos.latitude, retro)
        }
        let chironLongitude = asteroidPositions[.chiron]?.longitude ?? 0

        // 5) Other points ---------------------------------------------------
        let lilithLongitude = calculateLilithPosition(julianDay: jd)
        let partOfFortune   = calculatePartOfFortune(ascendant: ascendant,
                                                     sunLongitude: planets.first { $0.name == "Sun" }!.longitude,
                                                     moonLongitude: planets.first { $0.name == "Moon" }!.longitude)

        // 6) Lunar phase ----------------------------------------------------
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: jd)

        // 7) Return chart ---------------------------------------------
        return NatalChart(planets: planets,
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
                          lunarPhase: lunarPhase)
    }
    
    // Calculate if a planet is retrograde
    private static func isRetrograde(planet: VSOP87Parser.Planet, julianDay: Double) -> Bool {
        let pos1 = VSOP87Parser.calculateGeocentricCoordinates(planet: planet, julianDay: julianDay)
        let pos2 = VSOP87Parser.calculateGeocentricCoordinates(planet: planet, julianDay: julianDay + 1)
        let lon1 = CoordinateTransformations.radiansToDegrees(pos1.longitude)
        let lon2 = CoordinateTransformations.radiansToDegrees(pos2.longitude)
        var diff = lon2 - lon1
        if diff > 180 { diff -= 360 } else if diff < -180 { diff += 360 }
        return diff < 0
    }
    
    // Calculate Part of Fortune
    private static func calculatePartOfFortune(ascendant: Double, sunLongitude: Double, moonLongitude: Double) -> Double {
        return CoordinateTransformations.normalizeAngle(ascendant + moonLongitude - sunLongitude)
    }
    
    // Calculate Lilith (Mean Black Moon) position
    private static func calculateLilithPosition(julianDay: Double) -> Double {
        let T = (julianDay - 2451545) / 36525
        var lilith = 280 + 36000 * T + 13 * T * T
        lilith += 18 * 360 / 365.25 * (julianDay - 2451545) / 360
        lilith = CoordinateTransformations.normalizeAngle(lilith)
        let (nutLon, _) = AstronomicalCalculator.calculateNutation(julianDay: julianDay)
        lilith += nutLon
        return CoordinateTransformations.normalizeAngle(lilith)
    }
    
    // Simplified planetary positions for additional bodies
    private static func calculateSimplifiedPlanetPosition(julianDay: Double, planet: String) -> Double {
        let T = (julianDay - 2451545) / 36525
        switch planet {
        case "Pluto": return CoordinateTransformations.normalizeAngle(238.96 + 144.96 * T)
        default:      return 0
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
                "isRetrograde": planet.isRetrograde
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
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: nnSign)
            ],
            "SouthNode": [
                "longitude": chart.southNode,
                "formattedPosition": "\(ssPos) \(CoordinateTransformations.getZodiacSignName(sign: ssSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: ssSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: ssSign)
            ],
            "Lilith": [
                "longitude": chart.lilith,
                "formattedPosition": "\(lilithPos) \(CoordinateTransformations.getZodiacSignName(sign: lilithSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: lilithSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: lilithSign)
            ],
            "Chiron": [
                "longitude": chart.chiron,
                "formattedPosition": "\(chironPos) \(CoordinateTransformations.getZodiacSignName(sign: chironSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: chironSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: chironSign)
            ],
            "PartOfFortune": [
                "longitude": chart.partOfFortune,
                "formattedPosition": "\(pofPos) \(CoordinateTransformations.getZodiacSignName(sign: pofSign))",
                "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: pofSign),
                "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: pofSign)
            ]
        ]
        
        // Add all formatted data to the chart dictionary
        formattedChart["planets"] = formattedPlanets
        formattedChart["angles"] = angles
        formattedChart["points"] = points
        
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
