//
//  MoonPhaseInterpreter.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 15/05/2025.
//  Integrates moon phase significance into interpretation

import Foundation

struct MoonPhaseInterpreter {
    
    enum Phase {
        case newMoon           // 0°
        case waxingCrescent    // 0-90°
        case firstQuarter      // 90°
        case waxingGibbous     // 90-180°
        case fullMoon          // 180°
        case waningGibbous     // 180-270°
        case lastQuarter       // 270°
        case waningCrescent    // 270-360°
        
        static func fromDegrees(_ degrees: Double) -> Phase {
            let normalized = degrees.truncatingRemainder(dividingBy: 360.0)
                        
            switch normalized {
            case 0..<2, 358..<360:
                return .newMoon
            case 2..<87:
                return .waxingCrescent
            case 87..<93:
                return .firstQuarter
            case 93..<177:
                return .waxingGibbous
            case 177..<183:
                return .fullMoon
            case 183..<267:
                return .waningGibbous
            case 267..<273:
                return .lastQuarter
            case 273..<358:
                return .waningCrescent
            default:
                return .newMoon
            }
        }
        
        var description: String {
            switch self {
            case .newMoon: return "New Moon"
            case .waxingCrescent: return "Waxing Crescent"
            case .firstQuarter: return "First Quarter"
            case .waxingGibbous: return "Waxing Gibbous"
            case .fullMoon: return "Full Moon"
            case .waningGibbous: return "Waning Gibbous"
            case .lastQuarter: return "Last Quarter"
            case .waningCrescent: return "Waning Crescent"
            }
        }
    }
    
    /// Format moon phase for console output with percentage and name
     /// - Parameter degrees: Moon phase angle in degrees (0-360)
     /// - Returns: Formatted console string
     static func formatForConsole(_ degrees: Double) -> String {
         let phase = Phase.fromDegrees(degrees)
         let illumination = calculateIlluminationPercentage(from: degrees)
         
         return "\(phase.description) (\(illumination)% illuminated)"
     }
     
     /// Calculate illumination percentage from degrees
     /// - Parameter degrees: Moon phase angle in degrees
     /// - Returns: Illumination percentage (0-100)
     static func calculateIlluminationPercentage(from degrees: Double) -> Int {
         let normalizedDegrees = degrees.truncatingRemainder(dividingBy: 360.0)
         
         // Use cosine formula for accurate illumination calculation
         let illumination: Double
         
         if normalizedDegrees <= 180.0 {
             // Waxing phase: 0% to 100%
             illumination = (1.0 - cos(normalizedDegrees * .pi / 180.0)) / 2.0
         } else {
             // Waning phase: 100% to 0%
             let waningAngle = normalizedDegrees - 180.0
             illumination = (1.0 + cos(waningAngle * .pi / 180.0)) / 2.0
         }
         
         return Int(round(illumination * 100.0))
     }
    
    // Generate tokens for Blueprint relevance
    static func tokensForBlueprintRelevance(phase: Phase) -> [StyleToken] {
        var tokens: [StyleToken] = []
        let baseWeight = 1.2
        
        switch phase {
        case .newMoon:
            tokens.append(StyleToken(
                name: "seeded",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "potential",
                type: "structure",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "minimal",
                type: "colour",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            
        case .fullMoon:
            tokens.append(StyleToken(
                name: "illuminated",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "expressive",
                type: "structure",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "vibrant",
                type: "colour",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            
        case .firstQuarter, .lastQuarter:
            tokens.append(StyleToken(
                name: "balanced",
                type: "structure",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: phase.description
            ))
            
        case .waxingCrescent, .waxingGibbous:
            tokens.append(StyleToken(
                name: "growing",
                type: "mood",
                weight: baseWeight - 0.4,
                planetarySource: "Moon Phase",
                aspectSource: phase.description
            ))
            
        case .waningGibbous, .waningCrescent:
            tokens.append(StyleToken(
                name: "distilling",
                type: "mood",
                weight: baseWeight - 0.4,
                planetarySource: "Moon Phase",
                aspectSource: phase.description
            ))
        }
        
        return tokens
    }
    
    // Generate tokens for Daily Vibe based on current moon phase
    static func tokensForDailyVibe(phase: Phase) -> [StyleToken] {
        var tokens: [StyleToken] = []
        let baseWeight = 2.0  // Higher weight for daily vibe since moon phase is more significant
        
        switch phase {
        case .newMoon:
            tokens.append(StyleToken(
                name: "inward",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "seeded",
                type: "structure",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "minimal",
                type: "colour",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            tokens.append(StyleToken(
                name: "quiet",
                type: "texture",
                weight: baseWeight - 0.4,
                planetarySource: "Moon Phase",
                aspectSource: "New Moon"
            ))
            
        case .waxingCrescent:
            tokens.append(StyleToken(
                name: "emerging",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Crescent"
            ))
            tokens.append(StyleToken(
                name: "intentional",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Crescent"
            ))
            tokens.append(StyleToken(
                name: "textured",
                type: "texture",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Crescent"
            ))
            
        case .firstQuarter:
            tokens.append(StyleToken(
                name: "decisive",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "First Quarter"
            ))
            tokens.append(StyleToken(
                name: "structured",
                type: "structure",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "First Quarter"
            ))
            tokens.append(StyleToken(
                name: "dynamic",
                type: "colour",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "First Quarter"
            ))
            
        case .waxingGibbous:
            tokens.append(StyleToken(
                name: "developing",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Gibbous"
            ))
            tokens.append(StyleToken(
                name: "refining",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Gibbous"
            ))
            tokens.append(StyleToken(
                name: "layered",
                type: "texture",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Waxing Gibbous"
            ))
            
        case .fullMoon:
            tokens.append(StyleToken(
                name: "illuminated",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "expressive",
                type: "structure",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "vibrant",
                type: "colour",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            tokens.append(StyleToken(
                name: "visible",
                type: "texture",
                weight: baseWeight - 0.4,
                planetarySource: "Moon Phase",
                aspectSource: "Full Moon"
            ))
            
        case .waningGibbous:
            tokens.append(StyleToken(
                name: "substantial",
                type: "structure",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Gibbous"
            ))
            tokens.append(StyleToken(
                name: "sharing",
                type: "mood",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Gibbous"
            ))
            tokens.append(StyleToken(
                name: "rich",
                type: "colour",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Gibbous"
            ))
            
        case .lastQuarter:
            tokens.append(StyleToken(
                name: "releasing",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Last Quarter"
            ))
            tokens.append(StyleToken(
                name: "resolving",
                type: "structure",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Last Quarter"
            ))
            tokens.append(StyleToken(
                name: "transitional",
                type: "texture",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Last Quarter"
            ))
            
        case .waningCrescent:
            tokens.append(StyleToken(
                name: "reflective",
                type: "mood",
                weight: baseWeight,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Crescent"
            ))
            tokens.append(StyleToken(
                name: "subtle",
                type: "colour",
                weight: baseWeight - 0.2,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Crescent"
            ))
            tokens.append(StyleToken(
                name: "dissolving",
                type: "structure",
                weight: baseWeight - 0.3,
                planetarySource: "Moon Phase",
                aspectSource: "Waning Crescent"
            ))
        }
        
        return tokens
    }
    
    // Get colour palette suggestions based on moon phase
    static func colourPaletteForPhase(phase: Phase) -> [String] {
        switch phase {
        case .newMoon:
            return ["black", "charcoal", "deep navy", "indigo", "dark plum"]
        case .waxingCrescent:
            return ["silver", "pearl", "pale blue", "light gray", "ivory"]
        case .firstQuarter:
            return ["white", "cream", "pale yellow", "light blue", "silver"]
        case .waxingGibbous:
            return ["gold", "cream", "amber", "honey", "warm yellow"]
        case .fullMoon:
            return ["white", "silver", "platinum", "pearl", "luminous blue"]
        case .waningGibbous:
            return ["bronze", "copper", "warm gold", "amber", "rust"]
        case .lastQuarter:
            return ["pewter", "stone gray", "taupe", "mauve", "dusty rose"]
        case .waningCrescent:
            return ["charcoal", "midnight blue", "deep purple", "slate", "obsidian"]
        }
    }
}
