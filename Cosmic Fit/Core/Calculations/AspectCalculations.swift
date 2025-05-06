//
//  AspectCalculations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

class AspectCalculations {
    // Calculate aspects between planets
    static func calculateAspects(planets: [Planet]) -> [Aspect] {
        var aspects: [Aspect] = []
        
        for i in 0..<planets.count {
            for j in (i+1)..<planets.count {
                if let aspect = calculateAspect(planet1: planets[i], planet2: planets[j]) {
                    aspects.append(aspect)
                }
            }
        }
        
        return aspects
    }
    
    // Calculate aspect between two planets
    static func calculateAspect(planet1: Planet, planet2: Planet) -> Aspect? {
        // Calculate the angle between two planets
        var angle = abs(planet1.longitude - planet2.longitude)
        if angle > 180.0 {
            angle = 360.0 - angle
        }
        
        // Define aspect types and their orbs (allowed deviation)
        let aspectTypes = AspectType.allCases
        
        // Check each aspect type
        for aspectType in aspectTypes {
            // Get standard orb
            let standardOrb = aspectType.standardOrb
            
            // Adjust orb based on planet importance
            let adjustedOrb = adjustOrbForPlanetImportance(
                standardOrb: standardOrb,
                planet1: planet1.type,
                planet2: planet2.type
            )
            
            // Check if the angle matches an aspect within the allowed orb
            let deviation = abs(angle - aspectType.angle)
            if deviation <= adjustedOrb {
                // Determine if aspect is applying or separating
                // This would require speed data, which we've simplified
                // A rough approximation based on typical planetary speeds
                let isApplying = isAspectApplying(planet1: planet1, planet2: planet2, aspectAngle: aspectType.angle)
                
                return Aspect(
                    planet1: planet1.type,
                    planet2: planet2.type,
                    type: aspectType,
                    angle: angle,
                    orb: deviation,
                    applying: isApplying
                )
            }
        }
        
        return nil // No aspect found within allowed orbs
    }
    
    // Adjust orb based on planet importance
    private static func adjustOrbForPlanetImportance(standardOrb: Double, planet1: PlanetType, planet2: PlanetType) -> Double {
        // Luminaries (Sun and Moon) get larger orbs
        let luminaryFactor = isLuminary(planet1) || isLuminary(planet2) ? 1.5 : 1.0
        
        // Personal planets get slightly larger orbs than outer planets
        let personalFactor = isPersonalPlanet(planet1) && isPersonalPlanet(planet2) ? 1.2 : 1.0
        
        return standardOrb * luminaryFactor * personalFactor
    }
    
    // Check if a planet is a luminary (Sun or Moon)
    private static func isLuminary(_ planet: PlanetType) -> Bool {
        return planet == .sun || planet == .moon
    }
    
    // Check if a planet is a personal planet (Mercury, Venus, Mars)
    private static func isPersonalPlanet(_ planet: PlanetType) -> Bool {
        return planet == .mercury || planet == .venus || planet == .mars
    }
    
    // Rough approximation to determine if an aspect is applying or separating
    // A more accurate version would use actual planetary speeds from ephemeris
    private static func isAspectApplying(planet1: Planet, planet2: Planet, aspectAngle: Double) -> Bool {
        // Get typical speeds for each planet (degrees per day)
        let speed1 = getTypicalSpeed(planet1.type)
        let speed2 = getTypicalSpeed(planet2.type)
        
        // Calculate the angle between planets (direct angle, not shortest)
        var directAngle = planet2.longitude - planet1.longitude
        if directAngle < 0 {
            directAngle += 360.0
        }
        
        // Check if angle is approaching the aspect angle
        // For conjunction (0°), opposition (180°), and other aspects
        if (aspectAngle == 0.0 && directAngle > 180.0) || (aspectAngle == 180.0 && directAngle < 180.0) {
            // For conjunction, if directAngle > 180°, the planets are getting closer
            // For opposition, if directAngle < 180°, the planets are getting closer to opposition
            return (speed1 > speed2)
        } else {
            // For other aspects
            let distanceToAspect = abs(directAngle - aspectAngle)
            let distanceToOppositeAspect = abs(directAngle - (360.0 - aspectAngle))
            
            if distanceToAspect < distanceToOppositeAspect {
                return (speed1 > speed2)
            } else {
                return (speed1 < speed2)
            }
        }
        }

        // Get typical orbital speed for a planet (in degrees per day)
        private static func getTypicalSpeed(_ planetType: PlanetType) -> Double {
            switch planetType {
            case .sun:
                return 1.0  // The Sun's apparent motion is about 1° per day
            case .moon:
                return 13.2  // The Moon moves about 13.2° per day
            case .mercury:
                return 1.5  // Mercury's average speed is about 1-2° per day
            case .venus:
                return 1.2  // Venus moves about 1-1.2° per day
            case .mars:
                return 0.5  // Mars moves about 0.5° per day
            case .jupiter:
                return 0.083  // Jupiter moves about 0.083° per day
            case .saturn:
                return 0.034  // Saturn moves about 0.034° per day
            case .uranus:
                return 0.012  // Uranus moves about 0.012° per day
            case .neptune:
                return 0.006  // Neptune moves about 0.006° per day
            case .pluto:
                return 0.004  // Pluto moves about 0.004° per day
            case .northNode, .southNode:
                return 0.053  // The Moon's nodes move about -0.053° per day (retrograde)
            default:
                return 0.1  // Default value for other points
            }
        }

        // Filter aspects by strength
        static func filterAspectsByStrength(aspects: [Aspect], minimumStrength: Double = 0.5) -> [Aspect] {
            return aspects.filter { aspect in
                let strength = 1.0 - (aspect.orb / aspect.type.standardOrb)
                return strength >= minimumStrength
            }
        }

        // Get major aspects only (conjunction, opposition, trine, square, sextile)
        static func getMajorAspects(aspects: [Aspect]) -> [Aspect] {
            return aspects.filter { aspect in
                [.conjunction, .opposition, .trine, .square, .sextile].contains(aspect.type)
            }
        }

        // Calculate aspect pattern: Grand Trine
        static func findGrandTrines(aspects: [Aspect], planets: [Planet]) -> [(planet1: Planet, planet2: Planet, planet3: Planet)] {
            var grandTrines: [(planet1: Planet, planet2: Planet, planet3: Planet)] = []
            let trineAspects = aspects.filter { $0.type == .trine }
            
            // Create a dictionary of planets
            var planetDict: [PlanetType: Planet] = [:]
            for planet in planets {
                planetDict[planet.type] = planet
            }
            
            // Find planets that are in trine with each other
            for i in 0..<trineAspects.count {
                for j in (i+1)..<trineAspects.count {
                    let aspect1 = trineAspects[i]
                    let aspect2 = trineAspects[j]
                    
                    // Check if the two aspects share a planet
                    var commonPlanet: PlanetType?
                    var otherPlanets: [PlanetType] = []
                    
                    if aspect1.planet1 == aspect2.planet1 {
                        commonPlanet = aspect1.planet1
                        otherPlanets = [aspect1.planet2, aspect2.planet2]
                    } else if aspect1.planet1 == aspect2.planet2 {
                        commonPlanet = aspect1.planet1
                        otherPlanets = [aspect1.planet2, aspect2.planet1]
                    } else if aspect1.planet2 == aspect2.planet1 {
                        commonPlanet = aspect1.planet2
                        otherPlanets = [aspect1.planet1, aspect2.planet2]
                    } else if aspect1.planet2 == aspect2.planet2 {
                        commonPlanet = aspect1.planet2
                        otherPlanets = [aspect1.planet1, aspect2.planet1]
                    }
                    
                    // If the aspects share a planet and the other two planets are also in trine
                    if let commonPlanet = commonPlanet,
                       let planet1 = planetDict[commonPlanet],
                       let planet2 = planetDict[otherPlanets[0]],
                       let planet3 = planetDict[otherPlanets[1]] {
                        
                        // Check if the other two planets are in trine
                        let angle = abs(planet2.longitude - planet3.longitude)
                        let normalizedAngle = angle > 180.0 ? 360.0 - angle : angle
                        
                        if abs(normalizedAngle - 120.0) <= 8.0 {  // 8.0 is the standard orb for trines
                            grandTrines.append((planet1, planet2, planet3))
                        }
                    }
                }
            }
            
            return grandTrines
        }

        // Calculate aspect pattern: T-Square
        static func findTSquares(aspects: [Aspect], planets: [Planet]) -> [(planet1: Planet, planet2: Planet, planet3: Planet)] {
            var tSquares: [(planet1: Planet, planet2: Planet, planet3: Planet)] = []
            let oppositionAspects = aspects.filter { $0.type == .opposition }
            let squareAspects = aspects.filter { $0.type == .square }
            
            // Create a dictionary of planets
            var planetDict: [PlanetType: Planet] = [:]
            for planet in planets {
                planetDict[planet.type] = planet
            }
            
            // For each opposition, find a planet that squares both planets in opposition
            for opposition in oppositionAspects {
                let opposingPlanet1 = opposition.planet1
                let opposingPlanet2 = opposition.planet2
                
                for square in squareAspects {
                    var squaringPlanet: PlanetType?
                    var squaredPlanets: [PlanetType] = []
                    
                    // Check if the square involves one of the opposing planets
                    if square.planet1 == opposingPlanet1 {
                        squaringPlanet = square.planet2
                        squaredPlanets = [opposingPlanet1]
                    } else if square.planet1 == opposingPlanet2 {
                        squaringPlanet = square.planet2
                        squaredPlanets = [opposingPlanet2]
                    } else if square.planet2 == opposingPlanet1 {
                        squaringPlanet = square.planet1
                        squaredPlanets = [opposingPlanet1]
                    } else if square.planet2 == opposingPlanet2 {
                        squaringPlanet = square.planet1
                        squaredPlanets = [opposingPlanet2]
                    }
                    
                    // If the square involves one of the opposing planets, check if it also squares the other
                    if let squaringPlanet = squaringPlanet {
                        let otherOpposingPlanet = squaredPlanets[0] == opposingPlanet1 ? opposingPlanet2 : opposingPlanet1
                        
                        // Check if there's another square aspect between the squaring planet and the other opposing planet
                        let hasOtherSquare = squareAspects.contains {
                            ($0.planet1 == squaringPlanet && $0.planet2 == otherOpposingPlanet) ||
                            ($0.planet1 == otherOpposingPlanet && $0.planet2 == squaringPlanet)
                        }
                        
                        if hasOtherSquare {
                            if let planet1 = planetDict[opposingPlanet1],
                               let planet2 = planetDict[opposingPlanet2],
                               let planet3 = planetDict[squaringPlanet] {
                                tSquares.append((planet1, planet2, planet3))
                            }
                        }
                    }
                }
            }
            
            return tSquares
        }

        // Calculate aspect pattern: Grand Cross
        static func findGrandCrosses(aspects: [Aspect], planets: [Planet]) -> [(planet1: Planet, planet2: Planet, planet3: Planet, planet4: Planet)] {
            var grandCrosses: [(planet1: Planet, planet2: Planet, planet3: Planet, planet4: Planet)] = []
            let oppositionAspects = aspects.filter { $0.type == .opposition }
            
            // Create a dictionary of planets
            var planetDict: [PlanetType: Planet] = [:]
            for planet in planets {
                planetDict[planet.type] = planet
            }
            
            // Need at least 2 oppositions
            if oppositionAspects.count < 2 {
                return []
            }
            
            // For each pair of oppositions
            for i in 0..<oppositionAspects.count {
                for j in (i+1)..<oppositionAspects.count {
                    let opposition1 = oppositionAspects[i]
                    let opposition2 = oppositionAspects[j]
                    
                    // Ensure the oppositions involve different planets
                    if Set([opposition1.planet1, opposition1.planet2, opposition2.planet1, opposition2.planet2]).count != 4 {
                        continue
                    }
                    
                    // Check if the four planets form a grand cross (each planet is square to two others)
                    if let planet1 = planetDict[opposition1.planet1],
                       let planet2 = planetDict[opposition1.planet2],
                       let planet3 = planetDict[opposition2.planet1],
                       let planet4 = planetDict[opposition2.planet2] {
                        
                        let angle12_3 = abs(angleBetween(planet1: planet1, planet2: planet3))
                        let angle12_4 = abs(angleBetween(planet1: planet1, planet2: planet4))
                        let angle22_3 = abs(angleBetween(planet1: planet2, planet2: planet3))
                        let angle22_4 = abs(angleBetween(planet1: planet2, planet2: planet4))
                        
                        // Check if the angles are approximately 90 degrees (square)
                        if (abs(angle12_3 - 90.0) <= 8.0 && abs(angle22_4 - 90.0) <= 8.0) ||
                           (abs(angle12_4 - 90.0) <= 8.0 && abs(angle22_3 - 90.0) <= 8.0) {
                            grandCrosses.append((planet1, planet2, planet3, planet4))
                        }
                    }
                }
            }
            
            return grandCrosses
        }

        // Calculate the angle between two planets
        private static func angleBetween(planet1: Planet, planet2: Planet) -> Double {
            let angle = abs(planet1.longitude - planet2.longitude)
            return angle > 180.0 ? 360.0 - angle : angle
        }
        }
