//
//  ZodiacSign.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

enum ZodiacSign: String, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    // Get the symbol for a zodiac sign
    var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
    
    // Get the element of a sign
    var element: String {
        switch self {
        case .aries, .leo, .sagittarius:
            return "Fire"
        case .taurus, .virgo, .capricorn:
            return "Earth"
        case .gemini, .libra, .aquarius:
            return "Air"
        case .cancer, .scorpio, .pisces:
            return "Water"
        }
    }
    
    // Get the modality of a sign
    var modality: String {
        switch self {
        case .aries, .cancer, .libra, .capricorn:
            return "Cardinal"
        case .taurus, .leo, .scorpio, .aquarius:
            return "Fixed"
        case .gemini, .virgo, .sagittarius, .pisces:
            return "Mutable"
        }
    }
}
