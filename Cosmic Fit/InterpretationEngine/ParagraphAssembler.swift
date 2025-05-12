//
//  ParagraphAssembler.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 11/05/2025.
//

import Foundation

struct ParagraphAssembler {
    
    // Transition phrases library organized by paragraph tone
    static let transitionPhrases: [ParagraphTone: [String]] = [
        .warm: [
            "To carry that feeling forward,",
            "Flowing from that warmth,",
            "Keeping that comfort close,"
        ],
        .grounded: [
            "To stay rooted,",
            "To continue in balance,",
            "Echoing that stability,"
        ],
        .playful: [
            "And for a final twist,",
            "Add a little spark with,",
            "To keep the joy moving,"
        ],
        .poetic: [
            "Like a melody unfolding,",
            "In a gentle continuation,",
            "Following that rhythm,"
        ],
        .bold: [
            "Building on this energy,",
            "To amplify your presence,",
            "With confident expansion,"
        ],
        .minimal: [
            "With clean intention,",
            "In focused simplicity,",
            "Maintaining essential lines,"
        ]
    ]
    
    // Core paragraph stitching function with transition phrases and newlines
    static func stitchParagraphsStyled(from blocks: [ParagraphBlock]) -> String {
        guard !blocks.isEmpty else { return "" }

        var stitched = blocks[0].text.trimmingCharacters(in: .whitespacesAndNewlines)

        for i in 1..<blocks.count {
            let previousTone = blocks[i-1].tone
            let currentBlock = blocks[i]
            
            // Pick a transition phrase that matches the previous tone
            let transitionOptions = transitionPhrases[previousTone] ?? [""]
            let transition = transitionOptions.randomElement() ?? ""
            
            // Add transition + next paragraph block with double newline for SwiftUI/UIKit spacing
            stitched += "\n\n\(transition) \(currentBlock.text.trimmingCharacters(in: .whitespacesAndNewlines))"
        }

        return stitched
    }
    
    // Get paragraph blocks for a specific theme
    static func getBlocksForTheme(_ theme: String) -> [ParagraphBlock] {
        switch theme {
        case "Comfort at the Core":
            return [
                ParagraphBlock(
                    text: "Let texture lead you today. Soft fabrics can help you feel held without hesitation.",
                    tone: .warm,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Try leaning into earthy tones—clay, moss, or soft charcoal—to anchor your expression.",
                    tone: .grounded,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Finish with an accessory that makes you smile. A scarf, a ring, a shimmer of joy.",
                    tone: .playful,
                    positionHint: .closer
                )
            ]
            
        case "Structured Spontaneity":
            return [
                ParagraphBlock(
                    text: "Find balance in structure with room to breathe. A well-cut jacket paired with something that moves freely.",
                    tone: .grounded,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Colors can be reliable with one unexpected note—think navy with a flash of something bright.",
                    tone: .playful,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Keep accessories minimal but meaningful. One statement piece speaks volumes in this dialogue between order and freedom.",
                    tone: .minimal,
                    positionHint: .closer
                )
            ]
            
        case "Quiet Boldness":
            return [
                ParagraphBlock(
                    text: "Embrace the power of understatement today. A muted palette with strong silhouettes creates presence without noise.",
                    tone: .minimal,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Focus on proportion and cut rather than ornament. Let the quality of fabric and construction do the talking.",
                    tone: .bold,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Ground this quiet statement with solid footwear—something with weight and permanence to anchor your silent confidence.",
                    tone: .grounded,
                    positionHint: .closer
                )
            ]
            
        case "Dream Layering":
            return [
                ParagraphBlock(
                    text: "Allow yourself to drift between layers today. Sheer over opaque, light catching the edges, nothing too defined.",
                    tone: .poetic,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Colors that blur and blend—blues that become violet, whites with hidden depths—reflect your intuitive nature.",
                    tone: .warm,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Keep silhouettes loose and flowing, with gentle gathering rather than sharp structure. Let your boundaries breathe.",
                    tone: .playful,
                    positionHint: .closer
                )
            ]
            
        case "Grounded Glamour":
            return [
                ParagraphBlock(
                    text: "Today calls for luxury with substance. Think rich textures that feel good against the skin but can handle real life.",
                    tone: .grounded,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Incorporate elements that catch the light—a touch of shimmer in fabric, a metal accent, or jewelry with presence.",
                    tone: .bold,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Keep your color palette earth-connected—deep forest greens, burnt terracotta, or the perfect shade of chocolate brown.",
                    tone: .warm,
                    positionHint: .closer
                )
            ]
            
        case "Expressive Restraint":
            return [
                ParagraphBlock(
                    text: "Simplicity creates the perfect canvas for one striking moment of color. Clean lines speak volumes when punctuated with intention.",
                    tone: .minimal,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Choose a single vibrant element that pulls focus—a vivid bag against neutrals, a brilliant shoe with monochrome layers.",
                    tone: .bold,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Let this contrast between restraint and expression mirror your inner balance of discipline and creative spirit.",
                    tone: .poetic,
                    positionHint: .closer
                )
            ]
            
        case "Crisp Precision":
            return [
                ParagraphBlock(
                    text: "Sharp edges and clear intentions suit your energy today. Seek out clothing with defined structure and minimal distraction.",
                    tone: .minimal,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "A palette of cool neutrals—steely blues, graphite grays, pristine whites—enhances your focused mindset.",
                    tone: .grounded,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Keep accessories deliberately sparse and geometric. A single watch, architectural earrings, or a precisely placed pin completes this exacting approach.",
                    tone: .bold,
                    positionHint: .closer
                )
            ]
            
        case "Layered Protection":
            return [
                ParagraphBlock(
                    text: "Create a personal sanctuary of warmth through thoughtful layering. Pieces that overlap and reinforce each other mirror your multi-faceted nature.",
                    tone: .warm,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Choose fabrics that provide both physical comfort and emotional reinforcement—wool that breathes, cotton that feels like home.",
                    tone: .grounded,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Keep your outer layer structured but not rigid, a boundary that defines without confining. Your strength comes from flexibility.",
                    tone: .bold,
                    positionHint: .closer
                )
            ]
            
        case "Effortless Flow":
            return [
                ParagraphBlock(
                    text: "Move with ease today in fabrics that follow your body's natural rhythm. Nothing tight, nothing binding—just gentle accompaniment.",
                    tone: .playful,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Let your palette reflect water and air—blues that shift from sky to sea, whites with a hint of cloud-like softness.",
                    tone: .poetic,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Wear just enough structure to hold space, like a riverbank guides water. Your power is in adaptation, not resistance.",
                    tone: .grounded,
                    positionHint: .closer
                )
            ]
            
        case "Textured Dimensions":
            return [
                ParagraphBlock(
                    text: "Invite touch into your outfit today through contrasting textures. Smooth against rough, soft against structured—create conversation through contradiction.",
                    tone: .bold,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Keep your color story simple to let the materials speak. Tonal variations in a tight palette highlight surface qualities.",
                    tone: .minimal,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Find one special piece with tactile richness—heavily woven fabric, natural materials with visible grain, or something with gentle relief.",
                    tone: .warm,
                    positionHint: .closer
                )
            ]
            
        default: // Default Flow
            return [
                ParagraphBlock(
                    text: "Today brings a fluid energy that's best expressed through adaptable layers and intuitive choices.",
                    tone: .poetic,
                    positionHint: .opener
                ),
                ParagraphBlock(
                    text: "Trust your instincts with color and texture—what feels right against your skin is right for today's journey.",
                    tone: .warm,
                    positionHint: .middle
                ),
                ParagraphBlock(
                    text: "Consider one unexpected element that brings joy or surprise. Sometimes a small shift can transform your entire outlook.",
                    tone: .playful,
                    positionHint: .closer
                )
            ]
        }
    }
    
    // Generate complete interpretation for Cosmic Blueprint (foundational style profile)
    static func generateBlueprintInterpretation(themeName: String, tokens: [StyleToken]) -> String {
        // First get the paragraphs for the main theme
        let primaryBlocks = getBlocksForTheme(themeName)
        let primaryParagraph = stitchParagraphsStyled(from: primaryBlocks)
        
        // Create an opening statement
        let openingStatement = """
        Your Cosmic Blueprint reveals your style essence—a wardrobe philosophy derived from your astrological birth chart. This isn't about trends, but rather your innate fashion energy.
        """
        
        // Generate fabric and color recommendations based on tokens
        let fabricRecommendations = generateFabricRecommendations(from: tokens)
        let colorRecommendations = generateColorRecommendations(from: tokens)
        
        // Build the complete blueprint
        return """
        \(openingStatement)
        
        \(primaryParagraph)
        
        \(fabricRecommendations)
        
        \(colorRecommendations)
        
        This blueprint doesn't change with daily transits but evolves slowly with your life path. Consider it your style foundation—principles to guide choices rather than strict rules to follow.
        """
    }
    
    // Helper functions for blueprint specific sections
    private static func generateFabricRecommendations(from tokens: [StyleToken]) -> String {
        var nourishingFabrics: [String] = []
        var depletingFabrics: [String] = []
        
        // Analyze tokens to determine fabric preferences
        if tokens.contains(where: { $0.name == "earthy" && $0.weight > 2.0 }) {
            nourishingFabrics.append("raw denim")
            nourishingFabrics.append("washed cotton")
            nourishingFabrics.append("linen")
        }
        
        if tokens.contains(where: { $0.name == "soft" && $0.weight > 2.0 }) {
            nourishingFabrics.append("cashmere")
            nourishingFabrics.append("modal")
            nourishingFabrics.append("brushed cotton")
        }
        
        if tokens.contains(where: { $0.name == "structured" && $0.weight > 2.0 }) {
            nourishingFabrics.append("wool")
            nourishingFabrics.append("heavy cotton")
            depletingFabrics.append("unstructured synthetics")
        }
        
        if tokens.contains(where: { $0.name == "fluid" && $0.weight > 2.0 }) {
            nourishingFabrics.append("silk")
            nourishingFabrics.append("rayon")
            depletingFabrics.append("stiff brocades")
        }
        
        // Default options if no strong preferences
        if nourishingFabrics.isEmpty {
            nourishingFabrics = ["natural fibers", "breathable cotton", "textured weaves"]
        }
        
        if depletingFabrics.isEmpty {
            depletingFabrics = ["high-shine synthetics", "overly processed materials", "fabrics that restrict movement"]
        }
        
        return """
        Energetic Fabric Guide:
        
        Nourishing Fabrics: \(nourishingFabrics.joined(separator: ", "))
        
        Depleting Fabrics: \(depletingFabrics.joined(separator: ", "))
        """
    }
    
    private static func generateColorRecommendations(from tokens: [StyleToken]) -> String {
        var elementalColors: [String] = []
        var powerColors: [String] = []
        
        // Analyze tokens to determine color preferences
        if tokens.contains(where: { $0.name == "earthy" }) {
            elementalColors.append("rust")
            elementalColors.append("olive")
            elementalColors.append("camel")
        }
        
        if tokens.contains(where: { $0.name == "watery" }) {
            elementalColors.append("navy")
            elementalColors.append("teal")
            elementalColors.append("deep blue")
        }
        
        if tokens.contains(where: { $0.name == "airy" }) {
            elementalColors.append("sky blue")
            elementalColors.append("light grey")
            elementalColors.append("white")
        }
        
        if tokens.contains(where: { $0.name == "fiery" }) {
            elementalColors.append("red")
            elementalColors.append("orange")
            elementalColors.append("bright yellow")
        }
        
        // Generate power colors
        if tokens.contains(where: { $0.name == "bold" && $0.weight > 2.0 }) {
            powerColors.append("deep oxblood")
            powerColors.append("electric blue")
        }
        
        if tokens.contains(where: { $0.name == "grounded" && $0.weight > 2.0 }) {
            powerColors.append("forest green")
            powerColors.append("charcoal")
        }
        
        // Default options if no strong preferences
        if elementalColors.isEmpty {
            elementalColors = ["stone", "navy", "charcoal", "cream"]
        }
        
        if powerColors.isEmpty {
            powerColors = ["deep indigo", "matte silver", "burgundy"]
        }
        
        return """
        Elemental Colors:
        
        Base Palette: \(elementalColors.joined(separator: ", "))
        
        Power Colors: \(powerColors.joined(separator: ", "))
        """
    }
    
    // Generate daily cosmic vibe report (current transit & weather influences)
    static func generateDailyVibeInterpretation(themeName: String,
                                               tokens: [StyleToken],
                                               weather: TodayWeather?) -> String {
        // Get the paragraphs for the main theme
        let primaryBlocks = getBlocksForTheme(themeName)
        let primaryParagraph = stitchParagraphsStyled(from: primaryBlocks)
        
        // Create a weather-specific opening if available
        var openingLine = "Today's cosmic currents suggest:"
        
        if let weather = weather {
            let tempFeeling = weather.temp < 15 ? "cool" : (weather.temp > 25 ? "warm" : "mild")
            let conditions = weather.conditions.lowercased()
            
            if conditions.contains("rain") || conditions.contains("shower") {
                openingLine = "With today's wet weather and \(tempFeeling) temperatures, your cosmic vibe calls for:"
            } else if conditions.contains("cloud") {
                openingLine = "Under today's cloudy skies and \(tempFeeling) air, your cosmic style suggests:"
            } else if conditions.contains("sun") || conditions.contains("clear") {
                openingLine = "With today's sunny conditions and \(tempFeeling) temperatures, your cosmic fit is:"
            } else if conditions.contains("snow") {
                openingLine = "In today's snowy conditions, your cosmic protection layer is:"
            } else if conditions.contains("wind") {
                openingLine = "Against today's winds and \(tempFeeling) temperatures, your cosmic armor is:"
            }
        }
        
        // Build the complete daily vibe report
        return """
        \(openingLine)
        
        \(primaryParagraph)
        """
    }
}
