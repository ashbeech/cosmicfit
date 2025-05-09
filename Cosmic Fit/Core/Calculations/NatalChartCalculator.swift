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
        let houseCusps: [Double]         // NEW  – indices 1‑12
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
        let utcDate   = JulianDateCalculator.localToUTC(date: birthDate,
                                                        timezone: timeZone)
        let jd        = JulianDateCalculator.calculateJulianDate(from: utcDate)

        // 2) Angles ---------------------------------------------------------
        let ascendant  = AstronomicalCalculator.calculateAscendant(julianDay: jd,
                                                                   latitude: latitude,
                                                                   longitude: longitude)
        let midheaven  = AstronomicalCalculator.calculateMidheaven(julianDay: jd,
                                                                    longitude: longitude)
        let descendant = CoordinateTransformations.normalizeAngle(ascendant + 180)
        let imumCoeli  = CoordinateTransformations.normalizeAngle(midheaven + 180)

        // 3) House cusps ----------------------------------------------------
        let cusps = AstronomicalCalculator.calculateHouseCusps(julianDay: jd,
                                                               latitude: latitude,
                                                               longitude: longitude)

        // 4) Nodes ----------------------------------------------------------
        let (northNode, southNode) = AstronomicalCalculator.calculateLunarNodes(julianDay: jd)

        // 5) Planets --------------------------------------------------------
        var planets: [PlanetPosition] = []

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

        // --- Sun & Moon ---------------
        do {
            let (lon, lat) = AstronomicalCalculator.calculateSunPosition(julianDay: jd)
            appendPlanet("Sun", "☉", lon, lat, false)
        }
        do {
            let (lon, lat) = AstronomicalCalculator.calculateMoonPosition(julianDay: jd)
            appendPlanet("Moon", "☽", lon, lat, false)
        }

        // --- VSOP87 planets -----------
        func addVSOP(_ p: VSOP87Parser.Planet, _ name: String, _ symbol: String) {
            let geo = VSOP87Parser.calculateGeocentricCoordinates(planet: p, julianDay: jd)
            let lon = CoordinateTransformations.radiansToDegrees(geo.longitude)
            let lat = CoordinateTransformations.radiansToDegrees(geo.latitude)
            appendPlanet(name, symbol, lon, lat, isRetrograde(planet: p, julianDay: jd))
        }
        addVSOP(.mercury, "Mercury", "☿")
        addVSOP(.venus,   "Venus",   "♀")
        addVSOP(.mars,    "Mars",    "♂")
        addVSOP(.jupiter, "Jupiter", "♃")
        addVSOP(.saturn,  "Saturn",  "♄")
        addVSOP(.uranus,  "Uranus",  "♅")
        addVSOP(.neptune, "Neptune", "♆")

        // --- Pluto (simplified) -------
        let plutoLon = calculateSimplifiedPlanetPosition(julianDay: jd, planet: "Pluto")
        appendPlanet("Pluto", "♇", plutoLon, 0, false)

        // --- Asteroids ----------------
        let asteroidPositions = AsteroidCalculator.positions(at: jd)
        for (ast, pos) in asteroidPositions {
            appendPlanet(ast.displayName, ast.symbol,
                         pos.longitude, pos.latitude,
                         AsteroidCalculator.isRetrograde(ast, at: jd))
        }
        let chironLongitude = asteroidPositions[.chiron]?.longitude ?? 0

        // 6) Other points ---------------------------------------------------
        let lilithLongitude  = calculateLilithPosition(julianDay: jd)
        let partOfFortune    = calculatePartOfFortune(ascendant: ascendant,
                                                      sunLongitude: planets.first { $0.name == "Sun" }!.longitude,
                                                      moonLongitude: planets.first { $0.name == "Moon" }!.longitude)

        // 7) Lunar phase ----------------------------------------------------
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: jd)

        // 8) Return chart ---------------------------------------------------
        return NatalChart(planets: planets,
                          ascendant: ascendant,
                          midheaven: midheaven,
                          descendant: descendant,
                          imumCoeli: imumCoeli,
                          houseCusps: cusps,
                          northNode: northNode,
                          southNode: southNode,
                          vertex: AstronomicalCalculator.calculateVertex(julianDay: jd,
                                                                         latitude: latitude,
                                                                         longitude: longitude),
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
    /// Convert `NatalChart` to a dictionary for display in the UI.
    static func formatNatalChart(_ chart: NatalChart) -> [String: Any] {

        var formatted: [String: Any] = [:]

        // Planets ----------------------------------------------------------
        var planetArr: [[String: Any]] = []
        for p in chart.planets {
            planetArr.append([
                "name":              p.name,
                "symbol":            p.symbol,
                "longitude":         p.longitude,
                "formattedPosition": "\(p.zodiacPosition) \(CoordinateTransformations.getZodiacSignName(sign: p.zodiacSign))",
                "zodiacSign":        CoordinateTransformations.getZodiacSignName(sign: p.zodiacSign),
                "zodiacSymbol":      CoordinateTransformations.getZodiacSignSymbol(sign: p.zodiacSign),
                "isRetrograde":      p.isRetrograde
            ])
        }
        formatted["planets"] = planetArr

        // Angles -----------------------------------------------------------
        func angleDict(_ lon: Double) -> [String: Any] {
            let (s, pos) = CoordinateTransformations.decimalDegreesToZodiac(lon)
            return [
                "longitude":         lon,
                "formattedPosition": "\(pos) \(CoordinateTransformations.getZodiacSignName(sign: s))",
                "zodiacSign":        CoordinateTransformations.getZodiacSignName(sign: s),
                "zodiacSymbol":      CoordinateTransformations.getZodiacSignSymbol(sign: s)
            ]
        }
        formatted["angles"] = [
            "Ascendant":  angleDict(chart.ascendant),
            "Midheaven":  angleDict(chart.midheaven),
            "Descendant": angleDict(chart.descendant),
            "ImumCoeli":  angleDict(chart.imumCoeli)
        ]

        // Houses -----------------------------------------------------------
        var houses: [[String: Any]] = []
        for i in 1...12 {
            let lon = chart.houseCusps[i]
            let (s, pos) = CoordinateTransformations.decimalDegreesToZodiac(lon)
            houses.append([
                "number":            i,
                "longitude":         lon,
                "formattedPosition": "\(pos) \(CoordinateTransformations.getZodiacSignName(sign: s))",
                "zodiacSign":        CoordinateTransformations.getZodiacSignName(sign: s),
                "zodiacSymbol":      CoordinateTransformations.getZodiacSignSymbol(sign: s)
            ])
        }
        formatted["houses"] = houses
        
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
        
        // Add all formatted data to the chart dictionary.
        // We already saved planets & angles above; just add the points block.
        formatted["points"] = points
        
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
        
        formatted["lunarPhase"] = [
            "angle": chart.lunarPhase,
            "description": phaseDescription
        ]
        
        return formatted
    }
}
