//
//  ChartAnalyser.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Takes a NatalChartCalculator.NatalChart and produces a ChartAnalysis struct
//  containing element/modality balance, dignity evaluation, chart ruler,
//  natal-natal aspects, dominant planets, and house context mapping.
//
//  This module consumes ONLY the NatalChart contract from the Foundation Layer.
//  It does NOT call NatalChartCalculator.calculateTransits().
//

import Foundation

// MARK: - Output Types

struct ElementBalance: Codable, Equatable {
    let fire: Int
    let earth: Int
    let air: Int
    let water: Int

    var firePercent: Double  { Double(fire) / Double(total) }
    var earthPercent: Double { Double(earth) / Double(total) }
    var airPercent: Double   { Double(air) / Double(total) }
    var waterPercent: Double { Double(water) / Double(total) }

    var dominant: String {
        let pairs: [(String, Int)] = [("fire", fire), ("earth", earth), ("air", air), ("water", water)]
        return pairs.max(by: { $0.1 < $1.1 })!.0
    }

    private var total: Int { max(fire + earth + air + water, 1) }
}

struct ModalityBalance: Codable, Equatable {
    let cardinal: Int
    let fixed: Int
    let mutable: Int

    var dominant: String {
        let pairs: [(String, Int)] = [("cardinal", cardinal), ("fixed", fixed), ("mutable", mutable)]
        return pairs.max(by: { $0.1 < $1.1 })!.0
    }
}

struct ChartAspect: Codable, Equatable {
    let planet1: String
    let planet2: String
    let aspectType: String
    let exactness: Double
}

enum ChartSect: String, Codable, Equatable {
    case day
    case night
}

enum PlanetSectStatus: String, Codable, Equatable {
    case sectLight
    case beneficOfSect
    case maleficOfSect
    case contraryBenefic
    case contraryMalefic
    case contraryLuminary
    case neutral
}

struct HouseEmphasis: Equatable {
    let houseScores: [Int: Double]
    let dominantHouses: [Int]
    let venusHouseDomain: String
    let moonHouseDomain: String
}

struct ChartAnalysis: Equatable {
    let elementBalance: ElementBalance
    let modalityBalance: ModalityBalance
    let chartRuler: String
    let sunSign: String
    let moonSign: String
    let ascendantSign: String
    let venusSign: String
    let marsSign: String
    let planetSigns: [String: String]
    let planetDignities: [String: DignityStatus]
    let planetHouses: [String: Int]
    let significantAspects: [ChartAspect]
    let dominantPlanets: [String]
    let chartSect: ChartSect
    let planetSectStatus: [String: PlanetSectStatus]
    let houseEmphasis: HouseEmphasis
}

// MARK: - ChartAnalyser

struct ChartAnalyser {

    // MARK: - Public API

    static func analyse(chart: NatalChartCalculator.NatalChart) -> ChartAnalysis {
        let signLookup = buildSignLookup(chart: chart)
        let houseLookup = buildHouseLookup(chart: chart)

        let elementBalance = computeElementBalance(signLookup: signLookup, chart: chart)
        let modalityBalance = computeModalityBalance(signLookup: signLookup, chart: chart)

        let ascSign = signName(for: chart.ascendant)
        let chartRuler = resolveChartRuler(ascendantSign: ascSign)

        let dignities = computeDignities(signLookup: signLookup)
        let aspects = computeNatalAspects(chart: chart)

        let sunLongitude = chart.planets.first(where: { $0.name == "Sun" })?.longitude ?? 0.0
        let sect = computeSect(sunLongitude: sunLongitude, ascendantLongitude: chart.ascendant)
        let sectStatus = computePlanetSectStatus(chartSect: sect)

        let dominantPlanets = computeDominantPlanets(
            chart: chart, signLookup: signLookup, houseLookup: houseLookup,
            chartRuler: chartRuler, sectStatus: sectStatus
        )

        let houseEmphasis = computeHouseEmphasis(houseLookup: houseLookup, chartRuler: chartRuler)

        return ChartAnalysis(
            elementBalance: elementBalance,
            modalityBalance: modalityBalance,
            chartRuler: chartRuler,
            sunSign: signLookup["Sun"] ?? "Unknown",
            moonSign: signLookup["Moon"] ?? "Unknown",
            ascendantSign: ascSign,
            venusSign: signLookup["Venus"] ?? "Unknown",
            marsSign: signLookup["Mars"] ?? "Unknown",
            planetSigns: signLookup,
            planetDignities: dignities,
            planetHouses: houseLookup,
            significantAspects: aspects,
            dominantPlanets: dominantPlanets,
            chartSect: sect,
            planetSectStatus: sectStatus,
            houseEmphasis: houseEmphasis
        )
    }

    // MARK: - Sign Lookup

    /// Maps planet name → zodiac sign name by converting longitude to sign index.
    private static func buildSignLookup(chart: NatalChartCalculator.NatalChart) -> [String: String] {
        var lookup: [String: String] = [:]
        for planet in chart.planets {
            lookup[planet.name] = signName(for: planet.longitude)
        }
        return lookup
    }

    /// Converts an ecliptic longitude (degrees) to a zodiac sign name.
    static func signName(for longitude: Double) -> String {
        let signIndex = CoordinateTransformations.decimalDegreesToZodiac(longitude).sign
        return CoordinateTransformations.getZodiacSignName(sign: signIndex)
    }

    /// Returns sign index (1-12) for a longitude.
    static func signIndex(for longitude: Double) -> Int {
        CoordinateTransformations.decimalDegreesToZodiac(longitude).sign
    }

    // MARK: - House Lookup

    /// Determines which Whole-Sign house each planet occupies.
    /// Whole Sign houses: Ascendant sign = house 1, next sign = house 2, etc.
    private static func buildHouseLookup(chart: NatalChartCalculator.NatalChart) -> [String: Int] {
        var lookup: [String: Int] = [:]
        let ascSignIndex = signIndex(for: chart.ascendant)

        for planet in chart.planets {
            let planetSignIndex = signIndex(for: planet.longitude)
            var house = planetSignIndex - ascSignIndex + 1
            if house <= 0 { house += 12 }
            lookup[planet.name] = house
        }
        return lookup
    }

    // MARK: - Element & Modality Balance

    private static let signElements: [String: String] = [
        "Aries": "fire", "Taurus": "earth", "Gemini": "air", "Cancer": "water",
        "Leo": "fire", "Virgo": "earth", "Libra": "air", "Scorpio": "water",
        "Sagittarius": "fire", "Capricorn": "earth", "Aquarius": "air", "Pisces": "water"
    ]

    private static let signModalities: [String: String] = [
        "Aries": "cardinal", "Taurus": "fixed", "Gemini": "mutable",
        "Cancer": "cardinal", "Leo": "fixed", "Virgo": "mutable",
        "Libra": "cardinal", "Scorpio": "fixed", "Sagittarius": "mutable",
        "Capricorn": "cardinal", "Aquarius": "fixed", "Pisces": "mutable"
    ]

    /// The planets that count towards element/modality tallies.
    private static let balancePlanets: Set<String> = [
        "Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn"
    ]

    private static func computeElementBalance(
        signLookup: [String: String],
        chart: NatalChartCalculator.NatalChart
    ) -> ElementBalance {
        var fire = 0, earth = 0, air = 0, water = 0

        for (planet, sign) in signLookup where balancePlanets.contains(planet) {
            switch signElements[sign] {
            case "fire":  fire += 1
            case "earth": earth += 1
            case "air":   air += 1
            case "water": water += 1
            default: break
            }
        }

        let ascElement = signElements[signName(for: chart.ascendant)] ?? ""
        switch ascElement {
        case "fire":  fire += 1
        case "earth": earth += 1
        case "air":   air += 1
        case "water": water += 1
        default: break
        }

        return ElementBalance(fire: fire, earth: earth, air: air, water: water)
    }

    private static func computeModalityBalance(
        signLookup: [String: String],
        chart: NatalChartCalculator.NatalChart
    ) -> ModalityBalance {
        var cardinal = 0, fixed = 0, mutable = 0

        for (planet, sign) in signLookup where balancePlanets.contains(planet) {
            switch signModalities[sign] {
            case "cardinal": cardinal += 1
            case "fixed":    fixed += 1
            case "mutable":  mutable += 1
            default: break
            }
        }

        let ascModality = signModalities[signName(for: chart.ascendant)] ?? ""
        switch ascModality {
        case "cardinal": cardinal += 1
        case "fixed":    fixed += 1
        case "mutable":  mutable += 1
        default: break
        }

        return ModalityBalance(cardinal: cardinal, fixed: fixed, mutable: mutable)
    }

    // MARK: - Chart Ruler

    /// Traditional rulership: maps a sign name to the ruling planet.
    static func resolveChartRuler(ascendantSign: String) -> String {
        switch ascendantSign {
        case "Aries":       return "Mars"
        case "Taurus":      return "Venus"
        case "Gemini":      return "Mercury"
        case "Cancer":      return "Moon"
        case "Leo":         return "Sun"
        case "Virgo":       return "Mercury"
        case "Libra":       return "Venus"
        case "Scorpio":     return "Mars"
        case "Sagittarius": return "Jupiter"
        case "Capricorn":   return "Saturn"
        case "Aquarius":    return "Saturn"
        case "Pisces":      return "Jupiter"
        default:            return "Sun"
        }
    }

    // MARK: - Dignity Evaluation

    private static func computeDignities(signLookup: [String: String]) -> [String: DignityStatus] {
        var dignities: [String: DignityStatus] = [:]
        for (planet, sign) in signLookup {
            dignities[planet] = PlanetPowerEvaluator.getDignityStatus(planet: planet, sign: sign)
        }
        return dignities
    }

    // MARK: - Natal-Natal Aspect Detection

    private static let aspectRelevantBodies: Set<String> = [
        "Sun", "Moon", "Mercury", "Venus", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"
    ]

    private static let majorAspects: Set<String> = [
        "Conjunction", "Opposition", "Trine", "Square", "Sextile"
    ]

    /// Computes natal-natal aspects (planet-to-planet within the birth chart).
    /// Filters to major aspects involving at least one of Venus, Moon, Sun, Mars, or Ascendant.
    private static func computeNatalAspects(
        chart: NatalChartCalculator.NatalChart
    ) -> [ChartAspect] {
        let relevantPlanets = chart.planets.filter { aspectRelevantBodies.contains($0.name) }
        let styleDrivers: Set<String> = ["Venus", "Moon", "Sun", "Mars"]
        var aspects: [ChartAspect] = []

        for i in 0..<relevantPlanets.count {
            for j in (i + 1)..<relevantPlanets.count {
                let p1 = relevantPlanets[i]
                let p2 = relevantPlanets[j]

                guard styleDrivers.contains(p1.name) || styleDrivers.contains(p2.name) else {
                    continue
                }

                if let result = AstronomicalCalculator.calculateAspect(
                    point1: p1.longitude, point2: p2.longitude
                ), majorAspects.contains(result.aspectType) {
                    aspects.append(ChartAspect(
                        planet1: p1.name,
                        planet2: p2.name,
                        aspectType: result.aspectType,
                        exactness: result.exactness
                    ))
                }
            }
        }

        // Also check Ascendant against all planets (Asc is a separate Double, not in planets array)
        for planet in relevantPlanets {
            if let result = AstronomicalCalculator.calculateAspect(
                point1: chart.ascendant, point2: planet.longitude
            ), majorAspects.contains(result.aspectType) {
                aspects.append(ChartAspect(
                    planet1: "Ascendant",
                    planet2: planet.name,
                    aspectType: result.aspectType,
                    exactness: result.exactness
                ))
            }
        }

        return aspects.sorted { $0.exactness < $1.exactness }
    }

    // MARK: - Sect Computation

    /// Determines chart sect using actual horizon geometry (not Whole Sign house number).
    /// Sun above horizon = day chart; Sun below horizon = night chart.
    static func computeSect(sunLongitude: Double, ascendantLongitude: Double) -> ChartSect {
        let desc = CoordinateTransformations.normalizeAngle(ascendantLongitude + 180.0)
        let sunNorm = CoordinateTransformations.normalizeAngle(sunLongitude - desc)
        return sunNorm < 180.0 ? .day : .night
    }

    static func computePlanetSectStatus(chartSect: ChartSect) -> [String: PlanetSectStatus] {
        switch chartSect {
        case .day:
            return [
                "Sun": .sectLight,
                "Moon": .contraryLuminary,
                "Jupiter": .beneficOfSect,
                "Venus": .contraryBenefic,
                "Saturn": .maleficOfSect,
                "Mars": .contraryMalefic,
                "Mercury": .neutral,
                "Uranus": .neutral,
                "Neptune": .neutral,
                "Pluto": .neutral
            ]
        case .night:
            return [
                "Sun": .contraryLuminary,
                "Moon": .sectLight,
                "Jupiter": .contraryBenefic,
                "Venus": .beneficOfSect,
                "Saturn": .contraryMalefic,
                "Mars": .maleficOfSect,
                "Mercury": .neutral,
                "Uranus": .neutral,
                "Neptune": .neutral,
                "Pluto": .neutral
            ]
        }
    }

    // MARK: - House Emphasis

    static let houseDomainLabels: [Int: String] = [
        1: "identity", 2: "resources", 3: "expression", 4: "foundations",
        5: "creativity", 6: "routine", 7: "partnership", 8: "intensity",
        9: "philosophy", 10: "public", 11: "community", 12: "retreat"
    ]

    static func houseDomainLabel(for house: Int) -> String? {
        houseDomainLabels[house]
    }

    private static let houseEmphasisPlanetWeights: [String: Double] = [
        "Venus": 1.0, "Moon": 0.9, "Sun": 0.8, "Mars": 0.7,
        "Mercury": 0.4, "Jupiter": 0.4, "Saturn": 0.5,
        "Uranus": 0.3, "Neptune": 0.3, "Pluto": 0.3
    ]

    private static func computeHouseEmphasis(
        houseLookup: [String: Int],
        chartRuler: String
    ) -> HouseEmphasis {
        var scores: [Int: Double] = [:]
        for h in 1...12 { scores[h] = 0.0 }

        for (planet, house) in houseLookup {
            let weight = houseEmphasisPlanetWeights[planet] ?? 0.2
            scores[house, default: 0.0] += weight
            if planet == chartRuler {
                scores[house, default: 0.0] += 0.4
            }
        }

        let dominant = scores
            .sorted { a, b in
                if a.value != b.value { return a.value > b.value }
                return a.key < b.key
            }
            .prefix(3)
            .map(\.key)

        let venusHouse = houseLookup["Venus"] ?? 1
        let moonHouse = houseLookup["Moon"] ?? 1

        return HouseEmphasis(
            houseScores: scores,
            dominantHouses: Array(dominant),
            venusHouseDomain: houseDomainLabels[venusHouse] ?? "identity",
            moonHouseDomain: houseDomainLabels[moonHouse] ?? "identity"
        )
    }

    // MARK: - Dominant Planets

    /// Returns top 3 planets by power score (using PlanetPowerEvaluator).
    private static func computeDominantPlanets(
        chart: NatalChartCalculator.NatalChart,
        signLookup: [String: String],
        houseLookup: [String: Int],
        chartRuler: String,
        sectStatus: [String: PlanetSectStatus]
    ) -> [String] {
        let candidates = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                          "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

        let scored: [(String, Double)] = candidates.compactMap { name in
            guard let sign = signLookup[name] else { return nil }
            let house = houseLookup[name]
            let isAngular: Bool = {
                guard let h = house else { return false }
                return [1, 4, 7, 10].contains(h)
            }()

            let power = PlanetPowerEvaluator.evaluatePower(
                for: name,
                sign: sign,
                house: house,
                isAngular: isAngular,
                isChartRuler: name == chartRuler,
                isSectLight: sectStatus[name] == .sectLight
            )
            return (name, power)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map(\.0)
    }
}
