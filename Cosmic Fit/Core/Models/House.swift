//
//  House.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

struct House {
    let number: Int
    let cusp: Double
    
    // Return the zodiac sign at this house cusp
    func getSign() -> ZodiacSign {
        let signIndex = Int(cusp / 30.0)
        return ZodiacSign.allCases[signIndex]
    }
    
    // Return the degrees within the sign
    func getDegreesInSign() -> Double {
        return cusp.truncatingRemainder(dividingBy: 30.0)
    }
    
    // Get traditional house meaning
    var meaning: String {
        switch number {
        case 1: return "Self, personality, appearance"
        case 2: return "Possessions, values, resources"
        case 3: return "Communication, siblings, short trips"
        case 4: return "Home, family, roots"
        case 5: return "Creativity, pleasure, children"
        case 6: return "Health, service, daily routine"
        case 7: return "Partnerships, marriage, open enemies"
        case 8: return "Shared resources, transformation, sexuality"
        case 9: return "Higher learning, philosophy, long journeys"
        case 10: return "Career, public standing, authority"
        case 11: return "Friends, groups, hopes and wishes"
        case 12: return "Unconscious, spirituality, secrets"
        default: return "Unknown house meaning"
        }
    }
}
