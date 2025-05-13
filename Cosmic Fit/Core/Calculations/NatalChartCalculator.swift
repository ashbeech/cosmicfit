//
//  NatalChartCalculator.swift
//  Cosmic Fit
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
        let houseCusps: [Double]         // Placidus house cusps
        let wholeSignHouseCusps: [Double] // Whole Sign house cusps
        let northNode: Double
        let southNode: Double
        let vertex: Double
        let partOfFortune: Double
        let lilith: Double
        let chiron: Double
        let lunarPhase: Double
    }
    
    // MARK: - Progression Types --------------------------------------------
    
    enum ProgressionMethod {
        case naiveDate    // Recalculate angles for progressed date
        case solarArc     // Add solar arc distance to natal angles
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
        // Calculate Placidus house cusps
        let placidusHouseCusps = AstronomicalCalculator.calculateHouseCusps(
            julianDay: jd,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .placidus)
            
        // Calculate Whole Sign house cusps
        let wholeSignHouseCusps = AstronomicalCalculator.calculateHouseCusps(
            julianDay: jd,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .wholeSign)

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
                          houseCusps: placidusHouseCusps,
                          wholeSignHouseCusps: wholeSignHouseCusps,
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
    
    // MARK: - Progressed Chart Calculation --------------------------------
    
    static func calculateProgressedChart(birthDate: Date,
                                       targetAge: Int,
                                       latitude: Double,
                                       longitude: Double,
                                       timeZone: TimeZone,
                                       progressAnglesMethod: ProgressionMethod = .solarArc) -> NatalChart {
        
        // Calculate natal chart first (we need it for comparison and solar arc)
        let natalChart = calculateNatalChart(birthDate: birthDate,
                                           latitude: latitude,
                                           longitude: longitude,
                                           timeZone: timeZone)
        
        // 1) Add targetAge days to birth date to get progressed date
        let calendar = Calendar.current
        let progressedDate = calendar.date(byAdding: .day, value: targetAge, to: birthDate)!
        
        // 2) Calculate Julian Day for progressed date (keeping same birth time)
        let utcProgressedDate = JulianDateCalculator.localToUTC(date: progressedDate, timezone: timeZone)
        let progressedJD = JulianDateCalculator.calculateJulianDate(from: utcProgressedDate)
        
        // 3) Calculate progressed planetary positions
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
            let (lon, lat) = AstronomicalCalculator.calculateSunPosition(julianDay: progressedJD)
            appendPlanet("Sun", "☉", lon, lat, false)
        }
        
        do {
            let (lon, lat) = AstronomicalCalculator.calculateMoonPosition(julianDay: progressedJD)
            appendPlanet("Moon", "☽", lon, lat, false)
        }
        
        // --- VSOP87 planets -----------
        func addVSOP(_ p: VSOP87Parser.Planet, _ name: String, _ symbol: String) {
            let geo = VSOP87Parser.calculateGeocentricCoordinates(planet: p, julianDay: progressedJD)
            let lon = CoordinateTransformations.radiansToDegrees(geo.longitude)
            let lat = CoordinateTransformations.radiansToDegrees(geo.latitude)
            appendPlanet(name, symbol, lon, lat, isRetrograde(planet: p, julianDay: progressedJD))
        }
        
        addVSOP(.mercury, "Mercury", "☿")
        addVSOP(.venus,   "Venus",   "♀")
        addVSOP(.mars,    "Mars",    "♂")
        addVSOP(.jupiter, "Jupiter", "♃")
        addVSOP(.saturn,  "Saturn",  "♄")
        addVSOP(.uranus,  "Uranus",  "♅")
        addVSOP(.neptune, "Neptune", "♆")
        
        // --- Pluto (simplified) -------
        let plutoLon = calculateSimplifiedPlanetPosition(julianDay: progressedJD, planet: "Pluto")
        appendPlanet("Pluto", "♇", plutoLon, 0, false)
        
        // --- Asteroids ----------------
        let asteroidPositions = AsteroidCalculator.positions(at: progressedJD)
        for (ast, pos) in asteroidPositions {
            appendPlanet(ast.displayName, ast.symbol,
                         pos.longitude, pos.latitude,
                         AsteroidCalculator.isRetrograde(ast, at: progressedJD))
        }
        let chironLongitude = asteroidPositions[.chiron]?.longitude ?? 0
        
        // 4) Progress the angles based on the chosen method
        var progressedAscendant: Double
        var progressedMidheaven: Double
        
        if progressAnglesMethod == .naiveDate {
            // Naive method: recalculate angles for the progressed date and birth place
            progressedAscendant = AstronomicalCalculator.calculateAscendant(julianDay: progressedJD,
                                                                           latitude: latitude,
                                                                           longitude: longitude)
            progressedMidheaven = AstronomicalCalculator.calculateMidheaven(julianDay: progressedJD,
                                                                           longitude: longitude)
        } else {
            // Solar arc method: add solar arc to natal angles
            let natalSun = natalChart.planets.first { $0.name == "Sun" }!.longitude
            let progressedSun = planets.first { $0.name == "Sun" }!.longitude
            
            // Calculate solar arc (the shortest distance between the two points)
            var solarArc = progressedSun - natalSun
            if solarArc > 180 { solarArc -= 360 } else if solarArc < -180 { solarArc += 360 }
            
            progressedAscendant = CoordinateTransformations.normalizeAngle(natalChart.ascendant + solarArc)
            progressedMidheaven = CoordinateTransformations.normalizeAngle(natalChart.midheaven + solarArc)
        }
        
        let progressedDescendant = CoordinateTransformations.normalizeAngle(progressedAscendant + 180)
        let progressedImumCoeli = CoordinateTransformations.normalizeAngle(progressedMidheaven + 180)
        
        // 5) Calculate progressed house cusps using Placidus
        let progressedPlacidusHouseCusps = AstronomicalCalculator.calculateHouseCusps(
            julianDay: progressedJD,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .placidus)
            
        // Calculate Whole Sign house cusps for progressed chart
        let progressedWholeSignHouseCusps = AstronomicalCalculator.calculateHouseCusps(
            julianDay: progressedJD,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .wholeSign)
        
        // 6) Other points
        let (northNode, southNode) = AstronomicalCalculator.calculateLunarNodes(julianDay: progressedJD)
        let lilithLongitude = calculateLilithPosition(julianDay: progressedJD)
        let partOfFortune = calculatePartOfFortune(ascendant: progressedAscendant,
                                                 sunLongitude: planets.first { $0.name == "Sun" }!.longitude,
                                                 moonLongitude: planets.first { $0.name == "Moon" }!.longitude)
        
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: progressedJD)
        
        // 7) Return the progressed chart
        return NatalChart(planets: planets,
                          ascendant: progressedAscendant,
                          midheaven: progressedMidheaven,
                          descendant: progressedDescendant,
                          imumCoeli: progressedImumCoeli,
                          houseCusps: progressedPlacidusHouseCusps,
                          wholeSignHouseCusps: progressedWholeSignHouseCusps,
                          northNode: northNode,
                          southNode: southNode,
                          vertex: AstronomicalCalculator.calculateVertex(julianDay: progressedJD,
                                                                       latitude: latitude,
                                                                       longitude: longitude),
                          partOfFortune: partOfFortune,
                          lilith: lilithLongitude,
                          chiron: chironLongitude,
                          lunarPhase: lunarPhase)
    }
    
    // Calculate current age in years from birth date
    static func calculateCurrentAge(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // MARK: - House System Methods ------------------------------------------
    
    // Determine house using Placidus house system (original method)
    static func determineHouse(longitude: Double, houseCusps: [Double]) -> Int {
        for i in 1...12 {
            let currentCusp = houseCusps[i]
            let nextIndex = i % 12 + 1
            let nextCusp = houseCusps[nextIndex]
            
            // Handle the case where the house crosses the 0° point (e.g., house 12 to house 1)
            if nextCusp < currentCusp {
                if longitude >= currentCusp || longitude < nextCusp {
                    return i
                }
            } else {
                if longitude >= currentCusp && longitude < nextCusp {
                    return i
                }
            }
        }
        
        // Fallback (should not happen with valid data)
        return 1
    }
    
    // Determine house using Whole Sign system
    static func determineWholeSignHouse(longitude: Double, ascendant: Double) -> Int {
        // Get the sign of the longitude and the ascendant (1-12)
        let longitudeSign = Int(longitude / 30.0) % 12 + 1
        let ascendantSign = Int(ascendant / 30.0) % 12 + 1
        
        // In Whole Sign, houses map directly to signs, with the ascendant sign being the 1st house
        var house = (longitudeSign - ascendantSign + 1)
        if house <= 0 {
            house += 12
        }
        
        return house
    }
    
    // MARK: - Transit Calculations -------------------------------------------

    struct TransitAspect {
        let transitPlanet: String
        let transitPlanetSymbol: String
        let natalPlanet: String
        let natalPlanetSymbol: String
        let aspectType: String
        let aspectSymbol: String
        let orb: Double
        let applying: Bool
        let effectiveFrom: Date
        let effectiveTo: Date
        let description: String
        let category: TransitCategory
    }

    enum TransitCategory: String {
        case shortTerm = "Short-term Influences"
        case regular = "Regular Influences"
        case longTerm = "Long-term Influences"
    }

    // Calculate transits to natal chart
    static func calculateTransits(natalChart: NatalChart) -> [TransitAspect] {
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        var transitAspects: [TransitAspect] = []
        
        // Get current planetary positions
        let transitPositions = calculateCurrentPlanetaryPositions(julianDay: currentJulianDay)
        
        // For each transit position, check aspects to natal planets
        for transit in transitPositions {
            for natal in natalChart.planets {
                if let aspect = calculateTransitAspect(
                    transitPlanet: transit.name,
                    transitSymbol: transit.symbol,
                    transitLongitude: transit.longitude,
                    transitIsRetrograde: transit.isRetrograde,
                    natalPlanet: natal.name,
                    natalSymbol: natal.symbol,
                    natalLongitude: natal.longitude) {
                        transitAspects.append(aspect)
                }
            }
            
            // Check aspects to natal angles (Ascendant, Midheaven)
            if let aspect = calculateTransitAspect(
                transitPlanet: transit.name,
                transitSymbol: transit.symbol,
                transitLongitude: transit.longitude,
                transitIsRetrograde: transit.isRetrograde,
                natalPlanet: "Ascendant",
                natalSymbol: "Asc",
                natalLongitude: natalChart.ascendant) {
                    transitAspects.append(aspect)
            }
            
            if let aspect = calculateTransitAspect(
                transitPlanet: transit.name,
                transitSymbol: transit.symbol,
                transitLongitude: transit.longitude,
                transitIsRetrograde: transit.isRetrograde,
                natalPlanet: "Midheaven",
                natalSymbol: "MC",
                natalLongitude: natalChart.midheaven) {
                    transitAspects.append(aspect)
            }
        }
        
        // Sort transit aspects
        return sortTransitAspects(transitAspects)
    }

    private static func calculateCurrentPlanetaryPositions(julianDay: Double) -> [PlanetPosition] {
        var positions: [PlanetPosition] = []
        
        // Calculate Sun
        let (sunLon, sunLat) = AstronomicalCalculator.calculateSunPosition(julianDay: julianDay)
        let (sunSign, sunPos) = CoordinateTransformations.decimalDegreesToZodiac(sunLon)
        positions.append(PlanetPosition(
            name: "Sun",
            symbol: "☉",
            longitude: sunLon,
            latitude: sunLat,
            zodiacSign: sunSign,
            zodiacPosition: sunPos,
            isRetrograde: false
        ))
        
        // Calculate Moon
        let (moonLon, moonLat) = AstronomicalCalculator.calculateMoonPosition(julianDay: julianDay)
        let (moonSign, moonPos) = CoordinateTransformations.decimalDegreesToZodiac(moonLon)
        positions.append(PlanetPosition(
            name: "Moon",
            symbol: "☽",
            longitude: moonLon,
            latitude: moonLat,
            zodiacSign: moonSign,
            zodiacPosition: moonPos,
            isRetrograde: false
        ))
        
        // Calculate planets using VSOP87
        func addVSOP(_ p: VSOP87Parser.Planet, _ name: String, _ symbol: String) {
            let geo = VSOP87Parser.calculateGeocentricCoordinates(planet: p, julianDay: julianDay)
            let lon = CoordinateTransformations.radiansToDegrees(geo.longitude)
            let lat = CoordinateTransformations.radiansToDegrees(geo.latitude)
            let (sign, pos) = CoordinateTransformations.decimalDegreesToZodiac(lon)
            let isRetro = isRetrograde(planet: p, julianDay: julianDay)
            positions.append(PlanetPosition(
                name: name,
                symbol: symbol,
                longitude: lon,
                latitude: lat,
                zodiacSign: sign,
                zodiacPosition: pos,
                isRetrograde: isRetro
            ))
        }
        
        addVSOP(.mercury, "Mercury", "☿")
        addVSOP(.venus,   "Venus",   "♀")
        addVSOP(.mars,    "Mars",    "♂")
        addVSOP(.jupiter, "Jupiter", "♃")
        addVSOP(.saturn,  "Saturn",  "♄")
        addVSOP(.uranus,  "Uranus",  "♅")
        addVSOP(.neptune, "Neptune", "♆")
        
        // Add Pluto (simplified)
        let plutoLon = calculateSimplifiedPlanetPosition(julianDay: julianDay, planet: "Pluto")
        let (plutoSign, plutoPos) = CoordinateTransformations.decimalDegreesToZodiac(plutoLon)
        positions.append(PlanetPosition(
            name: "Pluto",
            symbol: "♇",
            longitude: plutoLon,
            latitude: 0.0,
            zodiacSign: plutoSign,
            zodiacPosition: plutoPos,
            isRetrograde: false
        ))
        
        // Add Chiron
                let chironLon = AstronomicalCalculator.calculateChironPosition(julianDay: julianDay)
                let (chironSign, chironPos) = CoordinateTransformations.decimalDegreesToZodiac(chironLon)
                positions.append(PlanetPosition(
                    name: "Chiron",
                    symbol: "⚷",
                    longitude: chironLon,
                    latitude: 0.0,
                    zodiacSign: chironSign,
                    zodiacPosition: chironPos,
                    isRetrograde: false
                ))
                
                return positions
            }

            private static func calculateTransitAspect(
                transitPlanet: String,
                transitSymbol: String,
                transitLongitude: Double,
                transitIsRetrograde: Bool,
                natalPlanet: String,
                natalSymbol: String,
                natalLongitude: Double) -> TransitAspect? {
                
                // Skip same planet to same planet aspects (except Sun to Sun which is the solar return)
                if transitPlanet == natalPlanet && transitPlanet != "Sun" {
                    return nil
                }
                
                // Define orbs based on the planet (tighter orbs for transits than natal)
                let maxOrb: Double
                switch transitPlanet {
                case "Sun", "Moon":
                    maxOrb = 3.0 // Slightly larger to catch more aspects
                case "Mercury", "Venus", "Mars":
                    maxOrb = 2.0
                case "Jupiter", "Saturn":
                    maxOrb = 2.5
                case "Uranus", "Neptune", "Pluto", "Chiron":
                    maxOrb = 2.5
                default:
                    maxOrb = 2.0
                }
                
                // Calculate the aspect
                if let (aspectType, exactness) = AstronomicalCalculator.calculateAspect(
                    point1: transitLongitude,
                    point2: natalLongitude,
                    orb: maxOrb) {
                    
                    // Determine the category based on planet speed
                    let category: TransitCategory
                    if transitPlanet == "Moon" {
                        category = .shortTerm
                    } else if ["Uranus", "Neptune", "Pluto", "Chiron"].contains(transitPlanet) {
                        category = .longTerm
                    } else {
                        category = .regular
                    }
                    
                    // Determine if the aspect is applying or separating
                    // This is simplified; in reality we'd need to calculate future positions
                    let applying = !transitIsRetrograde
                    
                    // Calculate effective dates (simplified estimate)
                    let effectiveDays: Double
                    switch transitPlanet {
                    case "Moon":
                        effectiveDays = 0.5 // Half-day for Moon
                    case "Sun", "Mercury", "Venus":
                        effectiveDays = 7.0 // One week for personal planets
                    case "Mars":
                        effectiveDays = 10.0 // Ten days for Mars
                    case "Jupiter", "Saturn":
                        effectiveDays = 21.0 // Three weeks for social planets
                    case "Uranus", "Neptune", "Pluto", "Chiron":
                        effectiveDays = 90.0 // Three months for outer planets
                    default:
                        effectiveDays = 7.0
                    }
                    
                    // Create date range
                    let now = Date()
                    let effectiveFrom = Calendar.current.date(byAdding: .day, value: -Int(effectiveDays/2), to: now)!
                    let effectiveTo = Calendar.current.date(byAdding: .day, value: Int(effectiveDays/2), to: now)!
                    
                    // Format dates for display
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    let fromStr = dateFormatter.string(from: effectiveFrom)
                    let toStr = dateFormatter.string(from: effectiveTo)
                    
                    // Get signs for display
                    let (transitSign, _) = CoordinateTransformations.decimalDegreesToZodiac(transitLongitude)
                    let transitSignSymbol = CoordinateTransformations.getZodiacSignSymbol(sign: transitSign)
                    
                    let (natalSign, _) = CoordinateTransformations.decimalDegreesToZodiac(natalLongitude)
                    let natalSignSymbol = CoordinateTransformations.getZodiacSignSymbol(sign: natalSign)
                    
                    // Create description based on format in the example
                    let retroMark = transitIsRetrograde ? " Rx" : ""
                    let description = "\(transitPlanet) \(aspectType) \(natalPlanet)\n(effective from \(fromStr) to \(toStr))"
                    let detailedInfo = "orb \(String(format: "%.2f", exactness))° \(applying ? "applying" : "separating")   (\(transitPlanet) \(transitSignSymbol) \(String(format: "%.2f", transitLongitude))°\(retroMark), \(natalPlanet) \(natalSignSymbol) \(String(format: "%.2f", natalLongitude))°)"
                    
                    // Get aspect symbol
                    let aspectSymbol = getAspectSymbol(aspectType)
                    
                    return TransitAspect(
                        transitPlanet: transitPlanet,
                        transitPlanetSymbol: transitSymbol,
                        natalPlanet: natalPlanet,
                        natalPlanetSymbol: natalSymbol,
                        aspectType: aspectType,
                        aspectSymbol: aspectSymbol,
                        orb: exactness,
                        applying: applying,
                        effectiveFrom: effectiveFrom,
                        effectiveTo: effectiveTo,
                        description: description + "\n" + detailedInfo,
                        category: category
                    )
                }
                
                return nil
            }

            private static func getAspectSymbol(_ aspectType: String) -> String {
                switch aspectType {
                case "Conjunction": return "☌"
                case "Opposition": return "☍"
                case "Trine": return "△"
                case "Square": return "□"
                case "Sextile": return "⚹"
                case "Quincunx": return "⚻"
                case "Semi-sextile": return "⚺"
                case "Semi-square": return "∠"
                case "Sesquiquadrate": return "⚼"
                case "Quintile": return "Q"
                case "Bi-quintile": return "bQ"
                default: return "?"
                }
            }

            private static func sortTransitAspects(_ aspects: [TransitAspect]) -> [TransitAspect] {
                // Define planet order for sorting (faster moving first within each category)
                let planetOrder = [
                    "Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn",
                    "Chiron", "Uranus", "Neptune", "Pluto"
                ]
                
                // Define aspect order for secondary sorting (major aspects first)
                let aspectOrder = [
                    "Conjunction", "Opposition", "Square", "Trine", "Sextile",
                    "Quincunx", "Semi-sextile", "Semi-square", "Sesquiquadrate", "Quintile", "Bi-quintile"
                ]
                
                return aspects.sorted { a, b in
                    // First sort by category (short-term, regular, long-term)
                    if a.category.rawValue != b.category.rawValue {
                        if a.category == .shortTerm { return true }
                        if b.category == .shortTerm { return false }
                        if a.category == .regular { return true }
                        if b.category == .regular { return false }
                        return false
                    }
                    
                    // Then sort by transit planet within each category
                    let planetIndexA = planetOrder.firstIndex(of: a.transitPlanet) ?? 100
                    let planetIndexB = planetOrder.firstIndex(of: b.transitPlanet) ?? 100
                    
                    if planetIndexA != planetIndexB {
                        // For short-term, faster moving first
                        if a.category == .shortTerm {
                            return planetIndexA < planetIndexB
                        }
                        // For regular and long-term, slower moving first
                        return planetIndexA > planetIndexB
                    }
                    
                    // Then sort by aspect type
                    let aspectIndexA = aspectOrder.firstIndex(of: a.aspectType) ?? 100
                    let aspectIndexB = aspectOrder.firstIndex(of: b.aspectType) ?? 100
                    
                    if aspectIndexA != aspectIndexB {
                        return aspectIndexA < aspectIndexB
                    }
                    
                    // Finally sort by orb (exact aspects first)
                    return a.orb < b.orb
                }
            }

            // Format transit aspects for display
            static func formatTransitAspects(_ aspects: [TransitAspect]) -> [[String: Any]] {
                var formatted: [[String: Any]] = []
                
                for aspect in aspects {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    
                    formatted.append([
                        "transitPlanet": aspect.transitPlanet,
                        "transitSymbol": aspect.transitPlanetSymbol,
                        "natalPlanet": aspect.natalPlanet,
                        "natalSymbol": aspect.natalPlanetSymbol,
                        "aspectType": aspect.aspectType,
                        "aspectSymbol": aspect.aspectSymbol,
                        "orb": aspect.orb,
                        "applying": aspect.applying,
                        "effectiveFrom": dateFormatter.string(from: aspect.effectiveFrom),
                        "effectiveTo": dateFormatter.string(from: aspect.effectiveTo),
                        "description": aspect.description,
                        "category": aspect.category.rawValue
                    ])
                }
                
                return formatted
            }

            // Group transit aspects by category
            static func groupTransitAspectsByCategory(_ aspects: [[String: Any]]) -> [String: [[String: Any]]] {
                var grouped: [String: [[String: Any]]] = [
                    TransitCategory.shortTerm.rawValue: [],
                    TransitCategory.regular.rawValue: [],
                    TransitCategory.longTerm.rawValue: []
                ]
                
                for aspect in aspects {
                    if let category = aspect["category"] as? String {
                        grouped[category, default: []].append(aspect)
                    }
                }
                
                return grouped
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
                    // Determine which house the planet is in - using Placidus system (default)
                    let placidusHouse = determineHouse(longitude: p.longitude, houseCusps: chart.houseCusps)
                    
                    // Determine which house the planet is in - using Whole Sign system
                    let wholeSignHouse = determineWholeSignHouse(longitude: p.longitude, ascendant: chart.ascendant)
                    
                    planetArr.append([
                        "name":              p.name,
                        "symbol":            p.symbol,
                        "longitude":         p.longitude,
                        "formattedPosition": "\(p.zodiacPosition) \(CoordinateTransformations.getZodiacSignName(sign: p.zodiacSign))",
                        "zodiacSign":        CoordinateTransformations.getZodiacSignName(sign: p.zodiacSign),
                        "zodiacSymbol":      CoordinateTransformations.getZodiacSignSymbol(sign: p.zodiacSign),
                        "isRetrograde":      p.isRetrograde,
                        "placidusHouse":     placidusHouse,  // Placidus house number
                        "wholeSignHouse":    wholeSignHouse  // Whole Sign house number
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

                // Houses - Placidus System -----------------------------------------
                var placidusHouses: [[String: Any]] = []
                for i in 1...12 {
                    let lon = chart.houseCusps[i]
                    let (s, pos) = CoordinateTransformations.decimalDegreesToZodiac(lon)
                    placidusHouses.append([
                        "number":            i,
                        "longitude":         lon,
                        "formattedPosition": "\(pos) \(CoordinateTransformations.getZodiacSignName(sign: s))",
                        "zodiacSign":        CoordinateTransformations.getZodiacSignName(sign: s),
                        "zodiacSymbol":      CoordinateTransformations.getZodiacSignSymbol(sign: s)
                    ])
                }
                formatted["placidusHouses"] = placidusHouses
                
                // Houses - Whole Sign System ---------------------------------------
                var wholeSignHouses: [[String: Any]] = []
                for i in 1...12 {
                    let lon = chart.wholeSignHouseCusps[i]
                    let (s, pos) = CoordinateTransformations.decimalDegreesToZodiac(lon)
                    wholeSignHouses.append([
                        "number":            i,
                        "longitude":         lon,
                        "formattedPosition": "\(pos) \(CoordinateTransformations.getZodiacSignName(sign: s))",
                        "zodiacSign":        CoordinateTransformations.getZodiacSignName(sign: s),
                        "zodiacSymbol":      CoordinateTransformations.getZodiacSignSymbol(sign: s)
                    ])
                }
                formatted["wholeSignHouses"] = wholeSignHouses
                
                // Default houses (for backward compatibility) - use Placidus
                formatted["houses"] = placidusHouses
                
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
