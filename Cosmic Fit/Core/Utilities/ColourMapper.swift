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
        
        // Try exact match first
        if let colour = colourPalette[normalizedName] {
            return colour
        }
        
        // FALLBACK: If color has descriptive adjectives (e.g. "opalescent blue", "structured charcoal"),
        // try to extract the base color name by taking the last word
        let components = normalizedName.split(separator: " ")
        if components.count > 1 {
            // Try the last word (e.g. "blue" from "opalescent blue")
            let baseColour = String(components.last!)
            if let colour = colourPalette[baseColour] {
                return colour
            }
            
            // Try the last two words (e.g. "slate gray" from "stormy slate gray")
            if components.count > 2 {
                let lastTwoWords = components.suffix(2).joined(separator: " ")
                if let colour = colourPalette[lastTwoWords] {
                    return colour
                }
            }
        }
        
        return nil
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
        
        // Oranges & Warm Tones
        "orange": UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0),
        "burnt orange": UIColor(red: 0.8, green: 0.33, blue: 0.0, alpha: 1.0),
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
        "soft blue": UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1.0),
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
        "pearl gray": UIColor(red: 0.73, green: 0.75, blue: 0.76, alpha: 1.0),
        "cloud white": UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0),
        
        // Black & White
        "black": UIColor.black,
        "white": UIColor.white,
        
        // Roses & Pinks
        "rose": UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0),
        "pearl": UIColor(red: 0.92, green: 0.88, blue: 0.88, alpha: 1.0),
        
        // Additional common colour names from tokens
        "dark": UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        
        // Missing Colors from IE - Basic Colors
        "charcoal": UIColor(red: 0.21, green: 0.27, blue: 0.31, alpha: 1.0),
        "cream": UIColor(red: 1.0, green: 0.99, blue: 0.82, alpha: 1.0),
        "silver": UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0),
        "wheat": UIColor(red: 0.96, green: 0.87, blue: 0.70, alpha: 1.0),
        "pastels": UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0),
        "ivory": UIColor(red: 1.0, green: 1.0, blue: 0.94, alpha: 1.0),
        "bone": UIColor(red: 0.89, green: 0.85, blue: 0.79, alpha: 1.0),
        "taupe": UIColor(red: 0.72, green: 0.57, blue: 0.45, alpha: 1.0),
        "copper": UIColor(red: 0.72, green: 0.45, blue: 0.20, alpha: 1.0),
        
        // Descriptive/Adjective Colors from IE (fallback will strip adjectives if these aren't found)
        "structured charcoal": UIColor(red: 0.21, green: 0.27, blue: 0.31, alpha: 1.0),
        "opalescent blue": UIColor(red: 0.69, green: 0.88, blue: 0.9, alpha: 1.0),
        "abyssal black": UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0),
        "oceanic teal": UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0),
        "leaden grey": UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
        "abundant indigo": UIColor(red: 0.29, green: 0.0, blue: 0.51, alpha: 1.0),
        
        // Reds & Oranges - Extended
        "bright red": UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
        "coral red": UIColor(red: 1.0, green: 0.38, blue: 0.28, alpha: 1.0),
        "brick red": UIColor(red: 0.8, green: 0.25, blue: 0.20, alpha: 1.0),
        "clear red": UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0),
        "bright orange": UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0),
        "deep orange": UIColor(red: 0.9, green: 0.4, blue: 0.0, alpha: 1.0),
        
        // Yellows - Extended
        "bright yellow": UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
        "pale yellow": UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0),
        "golden yellow": UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
        "warm gold": UIColor(red: 1.0, green: 0.77, blue: 0.05, alpha: 1.0),
        "pale gold": UIColor(red: 0.93, green: 0.91, blue: 0.67, alpha: 1.0),
        "bright mustard": UIColor(red: 1.0, green: 0.86, blue: 0.35, alpha: 1.0),
        
        // Greens - Extended
        "sage green": UIColor(red: 0.6, green: 0.73, blue: 0.62, alpha: 1.0),
        "warm green": UIColor(red: 0.56, green: 0.74, blue: 0.56, alpha: 1.0),
        
        // Blues - Extended
        "midnight blue": UIColor(red: 0.1, green: 0.1, blue: 0.44, alpha: 1.0),
        "deep forest": UIColor(red: 0.05, green: 0.25, blue: 0.05, alpha: 1.0),
        "royal blue": UIColor(red: 0.25, green: 0.41, blue: 0.88, alpha: 1.0),
        "sea blue": UIColor(red: 0.0, green: 0.4, blue: 0.58, alpha: 1.0),
        "light gray": UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1.0),
        "midnight navy": UIColor(red: 0.0, green: 0.0, blue: 0.35, alpha: 1.0),
        "cool teal": UIColor(red: 0.0, green: 0.6, blue: 0.6, alpha: 1.0),
        
        // Purples - Extended
        "royal purple": UIColor(red: 0.47, green: 0.32, blue: 0.66, alpha: 1.0),
        "smoky plum": UIColor(red: 0.56, green: 0.27, blue: 0.52, alpha: 1.0),
        "dusty plum": UIColor(red: 0.6, green: 0.4, blue: 0.52, alpha: 1.0),
        "faded damson": UIColor(red: 0.4, green: 0.2, blue: 0.35, alpha: 1.0),
        "lilac": UIColor(red: 0.78, green: 0.64, blue: 0.78, alpha: 1.0),
        "periwinkle": UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 1.0),
        
        // Pinks - Extended
        "rose pink": UIColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0),
        "pastel pink": UIColor(red: 1.0, green: 0.82, blue: 0.86, alpha: 1.0),
        "rose quartz": UIColor(red: 0.97, green: 0.76, blue: 0.76, alpha: 1.0),
        "dusty rose": UIColor(red: 0.8, green: 0.56, blue: 0.56, alpha: 1.0),
        
        // Browns - Extended
        "warm brown": UIColor(red: 0.65, green: 0.45, blue: 0.30, alpha: 1.0),
        "dark brown": UIColor(red: 0.4, green: 0.26, blue: 0.13, alpha: 1.0),
        "golden brown": UIColor(red: 0.6, green: 0.4, blue: 0.08, alpha: 1.0),
        "deep burgundy": UIColor(red: 0.4, green: 0.0, blue: 0.13, alpha: 1.0),
        "merlot": UIColor(red: 0.45, green: 0.16, blue: 0.16, alpha: 1.0),
        "rich mahogany": UIColor(red: 0.75, green: 0.25, blue: 0.0, alpha: 1.0),
        "vintage cognac": UIColor(red: 0.69, green: 0.38, blue: 0.20, alpha: 1.0),
        "stained walnut": UIColor(red: 0.47, green: 0.33, blue: 0.28, alpha: 1.0),
        
        // Grays - Extended
        "dove gray": UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
        "ash grey": UIColor(red: 0.7, green: 0.75, blue: 0.71, alpha: 1.0),
        "storm grey": UIColor(red: 0.54, green: 0.57, blue: 0.62, alpha: 1.0),
        "hazy charcoal": UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1.0),
        "soft white": UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),
        
        // Complex/Descriptive Colors
        "washed indigo": UIColor(red: 0.45, green: 0.55, blue: 0.75, alpha: 1.0),
        "faded indigo": UIColor(red: 0.52, green: 0.6, blue: 0.75, alpha: 1.0),
        "burnt sienna": UIColor(red: 0.91, green: 0.45, blue: 0.32, alpha: 1.0),
        "faded moss": UIColor(red: 0.65, green: 0.70, blue: 0.50, alpha: 1.0),
        "pale chamomile": UIColor(red: 1.0, green: 0.98, blue: 0.80, alpha: 1.0),
        "misty lavender": UIColor(red: 0.88, green: 0.88, blue: 0.95, alpha: 1.0),
        "warm terracotta": UIColor(red: 0.89, green: 0.45, blue: 0.36, alpha: 1.0),
        "dusty sage": UIColor(red: 0.7, green: 0.78, blue: 0.72, alpha: 1.0),
        "deep bordeaux": UIColor(red: 0.38, green: 0.03, blue: 0.10, alpha: 1.0),
        "weathered denim": UIColor(red: 0.46, green: 0.58, blue: 0.74, alpha: 1.0),
        "soft ochre": UIColor(red: 0.85, green: 0.6, blue: 0.3, alpha: 1.0),
        "antique ivory": UIColor(red: 0.98, green: 0.96, blue: 0.88, alpha: 1.0),
        "muted juniper": UIColor(red: 0.47, green: 0.58, blue: 0.50, alpha: 1.0),
        "blushed clay": UIColor(red: 0.85, green: 0.60, blue: 0.53, alpha: 1.0),
        "aged brass": UIColor(red: 0.71, green: 0.65, blue: 0.26, alpha: 1.0),
        "smoky quartz": UIColor(red: 0.58, green: 0.51, blue: 0.48, alpha: 1.0),
        "burnished copper": UIColor(red: 0.62, green: 0.38, blue: 0.24, alpha: 1.0),
        "sea glass": UIColor(red: 0.62, green: 0.82, blue: 0.80, alpha: 1.0),
        "deep olive": UIColor(red: 0.33, green: 0.42, blue: 0.18, alpha: 1.0),
        "washed saffron": UIColor(red: 0.96, green: 0.77, blue: 0.19, alpha: 1.0),
        "shadow mauve": UIColor(red: 0.58, green: 0.51, blue: 0.58, alpha: 1.0),
        "sunlit amber": UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1.0),
        "sandstone": UIColor(red: 0.87, green: 0.79, blue: 0.69, alpha: 1.0),
        "smoked pearl": UIColor(red: 0.78, green: 0.76, blue: 0.76, alpha: 1.0),
        
        // Additional IE Colors
        "coal": UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0),
        "espresso": UIColor(red: 0.23, green: 0.17, blue: 0.12, alpha: 1.0),
        "muted mauve": UIColor(red: 0.7, green: 0.6, blue: 0.7, alpha: 1.0),
    ]
}

