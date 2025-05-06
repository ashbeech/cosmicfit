//
//  Planet.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

struct Planet {
    let type: PlanetType
    let longitude: Double
    let latitude: Double
    let inHouse: Int
    
    // Return the zodiac sign the planet is in
    func getSign() -> ZodiacSign {
        let signIndex = Int(longitude / 30.0)
        return ZodiacSign.allCases[signIndex]
    }
    
    // Return the degrees within the sign
    func getDegreesInSign() -> Double {
        return longitude.truncatingRemainder(dividingBy: 30.0)
    }
    
    // Return formatted position string
    func formattedPosition() -> String {
        let sign = getSign()
        let degrees = getDegreesInSign()
        let minutes = (degrees - floor(degrees)) * 60
        
        return "\(sign.rawValue) \(Int(degrees))° \(Int(minutes))'"
    }
    
    // Is this planet in its rulership?
    func isInRulership() -> Bool {
        return type.rulerOf.contains(getSign())
    }
    
    // Is this planet in its detriment?
    func isInDetriment() -> Bool {
        for ruledSign in type.rulerOf {
            let oppositeSignIndex = (ZodiacSign.allCases.firstIndex(of: ruledSign)! + 6) % 12
            let oppositeSign = ZodiacSign.allCases[oppositeSignIndex]
            if getSign() == oppositeSign {
                return true
            }
        }
        return false
    }
}
