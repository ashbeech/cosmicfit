//
//  PlanetType.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

enum PlanetType: String, CaseIterable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
    case northNode = "North Node"
    case southNode = "South Node"
    case chiron = "Chiron"
    case lilith = "Lilith"
    case ceres = "Ceres"
    case pallas = "Pallas"
    case juno = "Juno"
    case vesta = "Vesta"
    
    // Get the symbol for a planet
    var symbol: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        case .northNode: return "☊"
        case .southNode: return "☋"
        case .chiron: return "⚷"
        case .lilith: return "⚸"
        case .ceres: return "⚳"
        case .pallas: return "⚴"
        case .juno: return "⚵"
        case .vesta: return "⚶"
        }
    }
    
    // Ruling properties
    var rulerOf: [ZodiacSign] {
        switch self {
        case .sun: return [.leo]
        case .moon: return [.cancer]
        case .mercury: return [.gemini, .virgo]
        case .venus: return [.taurus, .libra]
        case .mars: return [.aries, .scorpio]
        case .jupiter: return [.sagittarius, .pisces]
        case .saturn: return [.capricorn, .aquarius]
        case .uranus: return [.aquarius]
        case .neptune: return [.pisces]
        case .pluto: return [.scorpio]
        default: return []
        }
    }
    
    // Get the nature of the planet (e.g., personal, social, transpersonal)
    var nature: String {
        switch self {
        case .sun, .moon, .mercury, .venus, .mars:
            return "Personal"
        case .jupiter, .saturn:
            return "Social"
        case .uranus, .neptune, .pluto:
            return "Transpersonal"
        case .northNode, .southNode:
            return "Karmic"
        case .chiron, .lilith, .ceres, .pallas, .juno, .vesta:
            return "Asteroid"
        }
    }
    
    // Planets that are in detriment in the given sign
    func isInDetrimentIn(sign: ZodiacSign) -> Bool {
        switch self {
        case .sun:
            return sign == .aquarius
        case .moon:
            return sign == .capricorn
        case .mercury:
            return sign == .sagittarius || sign == .pisces
        case .venus:
            return sign == .aries || sign == .scorpio
        case .mars:
            return sign == .libra || sign == .taurus
        case .jupiter:
            return sign == .gemini || sign == .virgo
        case .saturn:
            return sign == .cancer || sign == .leo
        case .uranus:
            return sign == .leo
        case .neptune:
            return sign == .virgo
        case .pluto:
            return sign == .taurus
        default:
            return false
        }
    }
}
