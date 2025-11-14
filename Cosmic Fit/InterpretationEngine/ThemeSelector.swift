//
//  ThemeSelector.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 12/05/2025.
//

import Foundation

struct ThemeSelector {
    
    // Predefined composite themes with required and optional tokens
    static let themes: [CompositeTheme] = [
        CompositeTheme(
            name: "Comfort at the Core",
            required: ["emotional", "soft"],
            optional: ["playful", "cool", "nurturing", "warm", "cozy"],
            minimumScore: 5.0
        ),
        CompositeTheme(
            name: "Structured Spontaneity",
            required: ["earthy", "restless"],
            optional: ["playful", "airy", "structured", "versatile"],
            minimumScore: 5.0
        ),
        CompositeTheme(
            name: "Quiet Boldness",
            required: ["bold", "muted"],
            optional: ["stable", "grounded", "minimal", "dark"],
            minimumScore: 5.0
        ),
        CompositeTheme(
            name: "Dream Layering",
            required: ["dreamy", "fluid"],
            optional: ["soft", "introspective", "flowing", "watery"],
            minimumScore: 5.0
        ),
        CompositeTheme(
            name: "Grounded Glamour",
            required: ["luxurious", "earthy"],
            optional: ["stable", "warm", "sensual", "rich"],
            minimumScore: 5.0
        ),
        CompositeTheme(
            name: "Expressive Restraint",
            required: ["minimalist", "colourful"],
            optional: ["structured", "bold", "balanced"],
            minimumScore: 4.5
        ),
        CompositeTheme(
            name: "Crisp Precision",
            required: ["structured", "cool"],
            optional: ["clean", "focused", "minimal", "sharp"],
            minimumScore: 4.5
        ),
        CompositeTheme(
            name: "Layered Protection",
            required: ["protective", "warm"],
            optional: ["cozy", "structured", "insulated", "soft"],
            minimumScore: 4.5
        ),
        CompositeTheme(
            name: "Effortless Flow",
            required: ["fluid", "adaptable"],
            optional: ["light", "breathable", "soft", "airy"],
            minimumScore: 4.5
        ),
        CompositeTheme(
            name: "Textured Dimensions",
            required: ["tactile", "structured"],
            optional: ["layered", "rich", "warm", "earthy"],
            minimumScore: 4.5
        ),
        CompositeTheme(
            name: "Default Flow",
            required: [],
            optional: ["adaptable", "balanced", "intuitive"],
            minimumScore: 0.0
        )
    ]
    
    // Core function that scores themes against tokens and selects the best match
    static func scoreThemes(tokens: [StyleToken], themes: [CompositeTheme] = themes) -> String {
        var bestTheme: String = "Default Flow"
        var bestScore: Double = 0.0
        
        for theme in themes {
            var score: Double = 0.0
            var matchedRequired = Set<String>()
            
            for token in tokens {
                if theme.required.contains(token.name) {
                    score += token.weight
                    matchedRequired.insert(token.name)
                } else if theme.optional.contains(token.name) {
                    score += token.weight * 0.5 // optional tokens contribute half weight
                }
            }
            
            // Theme qualifies if all required tokens are matched and minimum score is reached
            if matchedRequired.count == theme.required.count && score >= theme.minimumScore {
                if score > bestScore {
                    bestTheme = theme.name
                    bestScore = score
                }
            }
        }
        
        return bestTheme
    }
    
    // Advanced method that returns the top N themes with their scores
    static func rankThemes(tokens: [StyleToken], topCount: Int = 3) -> [(name: String, score: Double)] {
        var themeScores: [(name: String, score: Double)] = []
        
        for theme in themes {
            var score: Double = 0.0
            var matchedRequired = Set<String>()
            
            for token in tokens {
                if theme.required.contains(token.name) {
                    score += token.weight
                    matchedRequired.insert(token.name)
                } else if theme.optional.contains(token.name) {
                    score += token.weight * 0.5
                }
            }
            
            if matchedRequired.count == theme.required.count && score >= theme.minimumScore {
                themeScores.append((name: theme.name, score: score))
            }
        }
        
        // Sort by score (descending) and take top N
        themeScores.sort { $0.score > $1.score }
        return Array(themeScores.prefix(topCount))
    }
}
