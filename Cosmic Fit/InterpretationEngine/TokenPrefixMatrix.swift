//
//  TokenPrefixMatrix.swift
//  Cosmic Fit
//
//  Created for Token Prefix Matrix implementation
//  Maps tokens to their appropriate prefixes based on weekday, context, and version
//

import Foundation

class TokenPrefixMatrix {
    
    // MARK: - Core Token Mappings
    
    /// Core tokens with weekday and version variations
    private static let coreTokens: [String: [String: [Int: String]]] = [
        "structured": [
            "Monday": [1: "Monday needs boundaries", 2: "Structure sets you free today"],
            "Thursday": [1: "Thursday calls for solid choices", 2: "Your power comes from good structure today"]
        ],
        "fluid": [
            "Wednesday": [1: "Midweek flow state", 2: "Fluid energy cuts through Wednesday stiffness"],
            "Saturday": [1: "Saturday softness", 2: "Slip into weekend mode"]
        ],
        "bold": [
            "Monday": [1: "It's Monday baby"],
            "Tuesday": [1: "Tuesday confidence", 2: "Bold moves pay off today"],
            "Friday": [1: "Friday drama earned", 2: "It's a bold kind of Friday"]
        ],
        "minimal": [
            "Sunday": [1: "Sunday simplicity", 2: "Less noise, more power"],
            "Wednesday": [1: "Wednesday clarity", 2: "Strip away the extra"]
        ],
        "layered": [
            "Monday": [1: "Monday depth", 2: "Add complexity where it counts"],
            "Thursday": [1: "Thursday nuance", 2: "Create richness through layers"]
        ],
        "playful": [
            "Wednesday": [1: "Wednesday joy check", 2: "Play with your style today"],
            "Saturday": [1: "Saturday play rules", 2: "Weekend fun mode"]
        ],
        "reflective": [
            "Sunday": [1: "Sunday reflection", 2: "Quiet power leads today"],
            "Thursday": [1: "Thursday contemplation", 2: "Midweek mirror time"]
        ],
        "radiant": [
            "Tuesday": [1: "Tuesday glow up", 2: "Radiant energy flowing"],
            "Friday": [1: "Friday luminosity", 2: "Shine from the inside out"]
        ],
        "dynamic": [
            "Monday": [1: "Monday momentum", 2: "Dynamic Tuesday"],
            "Wednesday": [1: "Wednesday flow state", 2: "Change-ready style"]
        ],
        "inward": [
            "Sunday": [1: "Sunday sanctuary", 2: "Quiet strength leads today"],
            "Tuesday": [1: "Tuesday introspection", 2: "Inward focus"]
        ]
    ]
    
    // MARK: - Mood Tokens
    
    private static let moodTokens: [String: String] = [
        "intense": "Intensity calls",
        "expansive": "Go bigger today",
        "dreamy": "Soft focus mode",
        "energetic": "High energy vibes",
        "communicative": "Your voice matters",
        "nurturing": "Gentle power moves",
        "optimistic": "Bright outlook energy",
        "refined": "Elevated choices",
        "distinctive": "Stand out naturally",
        "adventurous": "Take the leap",
        "emotional": "Feel it all",
        "independent": "Your own path",
        "social": "Connection energy",
        "warm": "Heart-forward vibes",
        "mysterious": "Keep them guessing"
    ]
    
    // MARK: - Structure Tokens
    
    private static let structureTokens: [String: String] = [
        "versatile": "Adapt as needed",
        "protective": "Armor up smartly",
        "balanced": "Find your center",
        "innovative": "Break new ground",
        "practical": "Function meets style",
        "expressive": "Let it show",
        "adaptable": "Roll with it",
        "elegant": "Grace under pressure",
        "assertive": "Take up space",
        "unconventional": "Rewrite the rules",
        "responsive": "Match the moment",
        "defining": "Make your mark",
        "transformative": "Change the game",
        "harmonious": "Everything aligns"
    ]
    
    // MARK: - Texture Tokens
    
    private static let textureTokens: [String: String] = [
        "sensual": "Feel good energy",
        "comfortable": "Ease into confidence",
        "transformative": "Change-ready texture",
        "enduring": "Built to last",
        "luxurious": "Treat yourself right",
        "substantial": "Weight and presence",
        "nurturing": "Soft strength vibes",
        "protective": "Safe but stylish",
        "soft": "Gentle approach",
        "detailed": "Precision matters"
    ]
    
    // MARK: - Color Quality Tokens
    
    private static let colorQualityTokens: [String: String] = [
        "vibrant": "Color that pops",
        "grounded": "Earth-connected tones",
        "bright": "Light it up",
        "gentle": "Soft color story",
        "warm": "Heat in your palette",
        "precise": "Exact color choices",
        "elegant": "Sophisticated spectrum",
        "intense": "Deep color power",
        "unique": "Your color signature",
        "flowing": "Colors that move",
        "rich": "Luxury in hue",
        "luminous": "Light from within",
        "mysterious": "Colors with secrets",
        "clear": "Pure color energy",
        "abundant": "More is more"
    ]
    
    // MARK: - Specific Color Tokens
    
    private static let specificColorTokens: [String: String] = [
        "bright red": "Fire energy",
        "forest green": "Earth magic",
        "electric blue": "Lightning mood",
        "seafoam": "Ocean calm",
        "gold": "Treasure vibes",
        "emerald": "Precious power",
        "crimson": "Bold blood",
        "wine red": "Deep luxury",
        "teal": "Water wisdom",
        "coral": "Sunset energy",
        "amber": "Ancient light",
        "pearl": "Hidden glow",
        "turquoise": "Sky meets sea",
        "lavender": "Calm royalty",
        "sage": "Herb wisdom"
    ]
    
    // MARK: - Expression Tokens
    
    private static let expressionTokens: [String: String] = [
        "authentic": "True to you",
        "confident": "Own your power",
        "creative": "Make something new",
        "magnetic": "Draw them in",
        "powerful": "Feel your strength",
        "graceful": "Move with ease",
        "bold expression": "Say it loud",
        "subtle expression": "Whisper strength",
        "natural expression": "Effortless you",
        "dramatic expression": "Full theater mode"
    ]
    
    // MARK: - Planetary Day Tokens
    
    private static let planetaryDayTokens: [String: String] = [
        "sun energy": "Solar power day",
        "moon energy": "Lunar intuition",
        "mars energy": "Warrior vibes",
        "mercury energy": "Quick silver",
        "jupiter energy": "Expansion mode",
        "venus energy": "Love and beauty",
        "saturn energy": "Structure day"
    ]
    
    // MARK: - Seasonal Tokens
    
    private static let seasonalTokens: [String: String] = [
        "spring energy": "Fresh start vibes",
        "summer energy": "Peak power season",
        "autumn energy": "Harvest wisdom",
        "winter energy": "Inner strength time",
        "emerging": "New growth",
        "blooming": "Full flower power",
        "ripening": "Peak moment",
        "harvesting": "Gathering energy",
        "storing": "Inner resources"
    ]
    
    // MARK: - Moon Phase Tokens
    
    private static let moonPhaseTokens: [String: String] = [
        "new moon": "Fresh slate energy",
        "waxing moon": "Building momentum",
        "full moon": "Peak power time",
        "waning moon": "Release and reset",
        "dark moon": "Deep inner work"
    ]
    
    // MARK: - Aspect Tokens
    
    private static let aspectTokens: [String: String] = [
        "conjunction": "Powers combine",
        "trine": "Easy flow energy",
        "square": "Tension creates growth",
        "opposition": "Balance opposing forces",
        "sextile": "Opportunity knocks"
    ]
    
    // MARK: - Elemental Tokens
    
    private static let elementalTokens: [String: String] = [
        "fire element": "Spark and flame",
        "earth element": "Ground and grow",
        "air element": "Think and breathe",
        "water element": "Feel and flow",
        "fire dominant": "All flame",
        "earth dominant": "Full ground",
        "air dominant": "Pure thought",
        "water dominant": "Deep feel"
    ]
    
    // MARK: - Public Methods
    
    /// Get the appropriate prefix for a token based on current context
    /// - Parameters:
    ///   - token: The StyleToken to get prefix for
    ///   - context: TokenContext with weekday, moon phase, season, etc.
    /// - Returns: The appropriate prefix string, or empty string if no prefix found
    static func getPrefix(for token: StyleToken, context: TokenContext) -> String {
        
        // Check core tokens first (weekday-specific with versions)
        if let weekdayMap = coreTokens[token.name] {
            if let versionMap = weekdayMap[context.weekdayName] {
                // Try to get version 2 first, then fall back to version 1
                if let prefix = versionMap[2] {
                    return prefix
                } else if let prefix = versionMap[1] {
                    return prefix
                }
            }
        }
        
        // Check mood tokens
        if let prefix = moodTokens[token.name] {
            return prefix
        }
        
        // Check structure tokens
        if let prefix = structureTokens[token.name] {
            return prefix
        }
        
        // Check texture tokens
        if let prefix = textureTokens[token.name] {
            return prefix
        }
        
        // Check color quality tokens
        if let prefix = colorQualityTokens[token.name] {
            return prefix
        }
        
        // Check specific color tokens
        if let prefix = specificColorTokens[token.name] {
            return prefix
        }
        
        // Check expression tokens
        if let prefix = expressionTokens[token.name] {
            return prefix
        }
        
        // Check planetary day tokens
        if let prefix = planetaryDayTokens[token.name] {
            return prefix
        }
        
        // Check seasonal tokens
        if let prefix = seasonalTokens[token.name] {
            return prefix
        }
        
        // Check moon phase tokens
        if let prefix = moonPhaseTokens[token.name] {
            return prefix
        }
        
        // Check aspect tokens
        if let prefix = aspectTokens[token.name] {
            return prefix
        }
        
        // Check elemental tokens
        if let prefix = elementalTokens[token.name] {
            return prefix
        }
        
        // No prefix found
        return ""
    }
    
    /// Get all available prefixes for a token across all contexts
    /// - Parameter tokenName: The name of the token
    /// - Returns: Array of all possible prefixes for this token
    static func getAllPrefixes(for tokenName: String) -> [String] {
        var prefixes: [String] = []
        let lowercaseTokenName = tokenName.lowercased()
        
        // Check core tokens
        if let weekdayMap = coreTokens[lowercaseTokenName] {
            for (_, versionMap) in weekdayMap {
                for (_, prefix) in versionMap {
                    prefixes.append(prefix)
                }
            }
        }
        
        // Check all other token types
        let allTokenMaps = [
            moodTokens, structureTokens, textureTokens, colorQualityTokens,
            specificColorTokens, expressionTokens, planetaryDayTokens,
            seasonalTokens, moonPhaseTokens, aspectTokens, elementalTokens
        ]
        
        for tokenMap in allTokenMaps {
            if let prefix = tokenMap[lowercaseTokenName] {
                prefixes.append(prefix)
            }
        }
        
        return prefixes
    }
    
    /// Check if a token has any prefixes available
    /// - Parameter tokenName: The name of the token
    /// - Returns: True if the token has prefixes available
    static func hasPrefix(for tokenName: String) -> Bool {
        return !getAllPrefixes(for: tokenName).isEmpty
    }
}

// MARK: - Token Context Structure

/// Context information needed to determine appropriate token prefixes
struct TokenContext {
    let weekdayName: String      // "Monday", "Tuesday", etc.
    let weekdayNumber: Int       // 1-7 (Sunday = 1)
    let moonPhase: Double        // 0-360
    let season: String           // "spring", "summer", "autumn", "winter"
    let planetaryDay: String     // "Venus", "Jupiter", etc. (based on weekday)
    let month: Int               // 1-12
    let dayOfMonth: Int          // 1-31
    
    /// Initialize context with current date and moon phase
    /// - Parameter moonPhase: Current moon phase (0-360)
    init(moonPhase: Double = 0) {
        let now = Date()
        let calendar = Calendar.current
        
        // Weekday information
        self.weekdayNumber = calendar.component(.weekday, from: now)
        self.weekdayName = TokenContext.getWeekdayName(for: weekdayNumber)
        self.planetaryDay = TokenContext.getPlanetaryDay(for: weekdayNumber)
        
        // Date information
        self.month = calendar.component(.month, from: now)
        self.dayOfMonth = calendar.component(.day, from: now)
        
        // Moon phase
        self.moonPhase = moonPhase
        
        // Season (Northern Hemisphere)
        self.season = TokenContext.getSeason(for: month)
    }
    
    // MARK: - Helper Methods
    
    private static func getWeekdayName(for weekdayNumber: Int) -> String {
        switch weekdayNumber {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Monday"
        }
    }
    
    private static func getPlanetaryDay(for weekdayNumber: Int) -> String {
        switch weekdayNumber {
        case 1: return "Sun"      // Sunday
        case 2: return "Moon"     // Monday
        case 3: return "Mars"     // Tuesday
        case 4: return "Mercury"  // Wednesday
        case 5: return "Jupiter"  // Thursday
        case 6: return "Venus"    // Friday
        case 7: return "Saturn"   // Saturday
        default: return "Mercury"
        }
    }
    
    private static func getSeason(for month: Int) -> String {
        switch month {
        case 3, 4, 5: return "spring"
        case 6, 7, 8: return "summer"
        case 9, 10, 11: return "autumn"
        case 12, 1, 2: return "winter"
        default: return "spring"
        }
    }

}
