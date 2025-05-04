//
//  AspectType.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

enum AspectType: String, CaseIterable {
    case conjunction = "Conjunction"
    case opposition = "Opposition"
    case trine = "Trine"
    case square = "Square"
    case sextile = "Sextile"
    case quincunx = "Quincunx"
    case semisextile = "Semi-sextile"
    
    // Get the angle value for this aspect
    var angle: Double {
        switch self {
        case .conjunction: return 0.0
        case .opposition: return 180.0
        case .trine: return 120.0
        case .square: return 90.0
        case .sextile: return 60.0
        case .quincunx: return 150.0
        case .semisextile: return 30.0
        }
    }
    
    // Get the standard orb (allowable deviation) for this aspect type
    var standardOrb: Double {
        switch self {
        case .conjunction: return 10.0
        case .opposition: return 10.0
        case .trine: return 8.0
        case .square: return 8.0
        case .sextile: return 6.0
        case .quincunx: return 3.0
        case .semisextile: return 3.0
        }
    }
    
    // Is this a harmonious or challenging aspect?
    var nature: String {
        switch self {
        case .conjunction:
            return "Neutral"
        case .opposition, .square, .quincunx:
            return "Challenging"
        case .trine, .sextile, .semisextile:
            return "Harmonious"
        }
    }
    
    // Symbol for the aspect type
    var symbol: String {
        switch self {
        case .conjunction: return "☌"
        case .opposition: return "☍"
        case .trine: return "△"
        case .square: return "□"
        case .sextile: return "⚹"
        case .quincunx: return "⚻"
        case .semisextile: return "⚺"
        }
    }
}
