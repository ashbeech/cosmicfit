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
}
