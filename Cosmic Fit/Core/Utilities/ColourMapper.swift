//
//  ColourMapper.swift
//  Cosmic Fit
//
//  Maps astrological colour names to UIColor objects
//

import UIKit

/// Maps semantic colour names from astrology tokens to UIColor representations
class ColourMapper {
    
    // MARK: - Public Methods
    
    /// Convert a colour name string to UIColor
    /// - Parameter colourName: Semantic colour name (e.g., "burgundy", "teal", "rust")
    /// - Returns: UIColor representation, or nil if colour not found
    static func colour(for colourName: String) -> UIColor? {
        let normalizedName = colourName.lowercased().trimmingCharacters(in: .whitespaces)
        return colourPalette[normalizedName]
    }
    
    /// Get top N colours from StyleTokens, sorted by weight
    /// - Parameters:
    ///   - tokens: Array of StyleTokens from IE
    ///   - count: Number of top colours to return (default: 3)
    /// - Returns: Array of (colourName, UIColor, weight) tuples
    static func getTopColours(from tokens: [StyleToken], count: Int = 3) -> [(String, UIColor, Double)] {
        // Filter to only colour tokens
        let colourTokens = tokens.filter { $0.type == "colour" }
        
        // Sort by weight descending
        let sorted = colourTokens.sorted { $0.weight > $1.weight }
        
        // Take top N and convert to UIColors
        var results: [(String, UIColor, Double)] = []
        
        for token in sorted.prefix(count) {
            if let uiColour = colour(for: token.name) {
                results.append((token.name, uiColour, token.weight))
            }
        }
        
        return results
    }
    
    /// Get all colours from StyleTokens, sorted by weight
    /// - Parameter tokens: Array of StyleTokens from IE
    /// - Returns: Array of UIColors sorted by prominence
    static func getAllColours(from tokens: [StyleToken]) -> [UIColor] {
        let colourTokens = tokens.filter { $0.type == "colour" }
        let sorted = colourTokens.sorted { $0.weight > $1.weight }
        
        return sorted.compactMap { colour(for: $0.name) }
    }
    
    // MARK: - Colour Palette Dictionary
    
    /// Comprehensive mapping of astrological color names to UIColors
    private static let colourPalette: [String: UIColor] = [
        // Reds & Burgundy
        "red": UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0),
        "burgundy": UIColor(red: 0.5, green: 0.13, blue: 0.13, alpha: 1.0),
        "rust": UIColor(red: 0.72, green: 0.26, blue: 0.05, alpha: 1.0),
        "crimson": UIColor(red: 0.86, green: 0.08, blue: 0.24, alpha: 1.0),
        "wine red": UIColor(red: 0.45, green: 0.18, blue: 0.22, alpha: 1.0),
        "oxblood": UIColor(red: 0.4, green: 0.0, blue: 0.0, alpha: 1.0),
        "ruby": UIColor(red: 0.61, green: 0.07, blue: 0.12, alpha: 1.0),
        "bright red": UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
        
        // Oranges & Warm Tones
        "orange": UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0),
        "burnt orange": UIColor(red: 0.8, green: 0.33, blue: 0.0, alpha: 1.0),
        "deep orange": UIColor(red: 0.9, green: 0.4, blue: 0.0, alpha: 1.0),
        "coral": UIColor(red: 1.0, green: 0.5, blue: 0.31, alpha: 1.0),
        "peach": UIColor(red: 1.0, green: 0.9, blue: 0.71, alpha: 1.0),
        "amber": UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1.0),
        "terracotta": UIColor(red: 0.89, green: 0.45, blue: 0.36, alpha: 1.0),
        
        // Yellows & Golds
        "yellow": UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
        "golden_yellow": UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
        "gold": UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
        "golden_brown": UIColor(red: 0.6, green: 0.4, blue: 0.08, alpha: 1.0),
        "ochre": UIColor(red: 0.8, green: 0.47, blue: 0.13, alpha: 1.0),
        
        // Greens
        "green": UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
        "forest green": UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0),
        "olive": UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0),
        "moss": UIColor(red: 0.54, green: 0.6, blue: 0.36, alpha: 1.0),
        "sage": UIColor(red: 0.6, green: 0.73, blue: 0.62, alpha: 1.0),
        "mint": UIColor(red: 0.74, green: 0.99, blue: 0.79, alpha: 1.0),
        "emerald": UIColor(red: 0.31, green: 0.78, blue: 0.47, alpha: 1.0),
        "warm_green": UIColor(red: 0.56, green: 0.74, blue: 0.56, alpha: 1.0),
        
        // Blues
        "blue": UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0),
        "navy": UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0),
        "navy ink": UIColor(red: 0.08, green: 0.15, blue: 0.28, alpha: 1.0),
        "teal": UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0),
        "turquoise": UIColor(red: 0.25, green: 0.88, blue: 0.82, alpha: 1.0),
        "electric blue": UIColor(red: 0.49, green: 0.98, blue: 1.0, alpha: 1.0),
        "royal_blue": UIColor(red: 0.25, green: 0.41, blue: 0.88, alpha: 1.0),
        "indigo": UIColor(red: 0.29, green: 0.0, blue: 0.51, alpha: 1.0),
        "slate blue": UIColor(red: 0.42, green: 0.35, blue: 0.8, alpha: 1.0),
        "deep aqua": UIColor(red: 0.0, green: 0.67, blue: 0.62, alpha: 1.0),
        "pale blue": UIColor(red: 0.69, green: 0.88, blue: 0.9, alpha: 1.0),
        "soft_blue": UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0),
        "sky": UIColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1.0),
        "seafoam": UIColor(red: 0.69, green: 0.98, blue: 0.95, alpha: 1.0),
        
        // Purples & Lavenders
        "purple": UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0),
        "lavender": UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1.0),
        "light lavender": UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0),
        "magenta": UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0),
        
        // Browns & Neutrals
        "brown": UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0),
        "camel": UIColor(red: 0.76, green: 0.6, blue: 0.42, alpha: 1.0),
        "walnut": UIColor(red: 0.47, green: 0.33, blue: 0.28, alpha: 1.0),
        "sand": UIColor(red: 0.96, green: 0.96, blue: 0.86, alpha: 1.0),
        "umber": UIColor(red: 0.39, green: 0.32, blue: 0.28, alpha: 1.0),
        
        // Grays
        "gray": UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
        "silver gray": UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0),
        "stormy gray": UIColor(red: 0.44, green: 0.5, blue: 0.56, alpha: 1.0),
        "pearl_gray": UIColor(red: 0.73, green: 0.75, blue: 0.76, alpha: 1.0),
        "cloud white": UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0),
        
        // Black & White
        "black": UIColor.black,
        "white": UIColor.white,
        
        // Roses & Pinks
        "rose": UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0),
        "pearl": UIColor(red: 0.92, green: 0.88, blue: 0.88, alpha: 1.0),
        
        // Additional common colour names from tokens
        "dark": UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
    ]
}

