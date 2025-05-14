//
//  ParagraphAssemblerDebug.swift
//  Cosmic Fit
//
//  Created to extend ParagraphAssembler with enhanced debugging
//

import Foundation

/// Extension to ParagraphAssembler that adds detailed debugging capabilities
extension ParagraphAssembler {
    
    // MARK: - Blueprint Debug Helpers
    
    /// Debug wrapper for generating blueprint interpretation
    static func generateBlueprintInterpretationWithDebug(tokens: [StyleToken], birthInfo: String? = nil) -> String {
        DebugLogger.info("Starting Blueprint interpretation generation")
        DebugLogger.tokenSet("BLUEPRINT TOKENS", tokens)
        
        // Build the complete blueprint with all sections
        var blueprint = ""
        
        // Log overall token analysis
        logTokenAnalysisForBlueprint(tokens)
        
        // Upper sections - all using Whole Sign system
        blueprint += debugGenerateSection("Style Essence", {
            let content = generateEssenceSection(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Style Essence",
                paragraphText: content,
                tokens: filterTokensForEssenceSection(tokens)
            )
            return "## Style Essence\n\n" + content + "\n\n"
        })
        
        blueprint += debugGenerateSection("Celestial Style ID", {
            let content = generateCoreSection(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Celestial Style ID",
                paragraphText: content,
                tokens: filterTokensForCoreSection(tokens)
            )
            return "## Celestial Style ID\n\n" + content + "\n\n"
        })
        
        blueprint += debugGenerateSection("Expression", {
            let content = generateExpressionSection(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Expression",
                paragraphText: content,
                tokens: filterTokensForExpressionSection(tokens)
            )
            return "## Expression\n\n" + content + "\n\n"
        })
        
        blueprint += debugGenerateSection("Magnetism", {
            let content = generateMagnetismSection(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Magnetism",
                paragraphText: content,
                tokens: filterTokensForMagnetismSection(tokens)
            )
            return "## Magnetism\n\n" + content + "\n\n"
        })
        
        blueprint += debugGenerateSection("Emotional Dressing", {
            let content = generateEmotionalDressingSection(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Emotional Dressing",
                paragraphText: content,
                tokens: filterTokensForEmotionalDressingSection(tokens)
            )
            return "## Emotional Dressing\n\n" + content + "\n\n"
        })
        
        blueprint += debugGenerateSection("Planetary Frequency", {
            let content = generatePlanetaryFrequencySection(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Planetary Frequency",
                paragraphText: content,
                tokens: filterTokensForPlanetaryFrequencySection(tokens)
            )
            return "## Planetary Frequency\n\n" + content + "\n\n"
        })
        
        blueprint += "---\n\n"
        
        // Fabric guide - using Whole Sign system
        blueprint += debugGenerateSection("Energetic Fabric Guide", {
            let content = generateFabricRecommendations(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Energetic Fabric Guide",
                paragraphText: content,
                tokens: filterTokensForFabricSection(tokens)
            )
            return "# Energetic Fabric Guide\n\n" + content + "\n\n"
        })
        
        // Style pulse - 90% natal, 10% progressed flavor (handled by token weighting)
        blueprint += debugGenerateSection("Style Pulse", {
            let content = generateStylePulse(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Style Pulse",
                paragraphText: content,
                tokens: filterTokensForStylePulseSection(tokens)
            )
            return "# Style Pulse\n\n" + content + "\n\n"
        })
        
        blueprint += "---\n\n"
        
        // Fashion guidance - using Whole Sign system
        blueprint += debugGenerateSection("Fashion Dos & Don'ts", {
            let content = generateFashionGuidance(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Fashion Dos & Don'ts",
                paragraphText: content,
                tokens: filterTokensForFashionGuidanceSection(tokens)
            )
            return "# Fashion Dos & Don'ts\n\n" + content + "\n\n"
        })
        
        // Color guidance - 70% natal, 30% progressed (handled by token weighting)
        blueprint += debugGenerateSection("Elemental Colours", {
            let content = generateColorRecommendations(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Elemental Colours",
                paragraphText: content,
                tokens: filterTokensForColorSection(tokens)
            )
            return "# Elemental Colours\n\n" + content + "\n\n"
        })
        
        // Wardrobe storyline - 60% progressed with Placidus, 40% natal (handled by token weighting)
        blueprint += debugGenerateSection("Wardrobe Storyline", {
            let content = generateWardrobeStoryline(from: tokens)
            DebugLogger.paragraphAssembly(
                sectionName: "Wardrobe Storyline",
                paragraphText: content,
                tokens: filterTokensForWardrobeStorylineSection(tokens)
            )
            return "# Wardrobe Storyline\n\n" + content
        })
        
        DebugLogger.info("Blueprint interpretation generation complete - \(blueprint.count) characters")
        return blueprint
    }
    
    // MARK: - Debug Wrapper Methods
    
    /// Debug wrapper for generating a section
    private static func debugGenerateSection(_ name: String, _ generator: () -> String) -> String {
        DebugLogger.info("Generating section: \(name)")
        let result = generator()
        DebugLogger.info("Completed section: \(name)")
        return result
    }
    
    /// Log analysis of tokens for the blueprint
    private static func logTokenAnalysisForBlueprint(_ tokens: [StyleToken]) {
        DebugLogger.info("Analyzing token set for Blueprint generation")
        
        // Count tokens by source
        var planetaryCounts: [String: Int] = [:]
        for token in tokens {
            if let planet = token.planetarySource {
                planetaryCounts[planet, default: 0] += 1
            }
        }
        
        // Log planetary distributions
        DebugLogger.debug("Planetary token distribution:")
        for (planet, count) in planetaryCounts.sorted(by: { $0.value > $1.value }) {
            DebugLogger.debug("  • \(planet): \(count) tokens")
        }
        
        // Log top tokens by weight
        let topTokensByWeight = tokens.sorted { $0.weight > $1.weight }.prefix(10)
        DebugLogger.debug("Top 10 tokens by weight:")
        for (index, token) in topTokensByWeight.enumerated() {
            DebugLogger.debug("  \(index+1). \(token.name) (\(token.type)): \(String(format: "%.2f", token.weight))")
        }
        
        // Log element analysis
        let fireCount = tokens.filter { $0.name == "fiery" || $0.name == "fire" || $0.name == "passionate" }.count
        let earthCount = tokens.filter { $0.name == "earthy" || $0.name == "earth" || $0.name == "grounded" }.count
        let airCount = tokens.filter { $0.name == "airy" || $0.name == "air" || $0.name == "intellectual" }.count
        let waterCount = tokens.filter { $0.name == "watery" || $0.name == "water" || $0.name == "emotional" }.count
        
        DebugLogger.debug("Elemental distribution:")
        DebugLogger.debug("  • Fire: \(fireCount) tokens")
        DebugLogger.debug("  • Earth: \(earthCount) tokens")
        DebugLogger.debug("  • Air: \(airCount) tokens")
        DebugLogger.debug("  • Water: \(waterCount) tokens")
    }
    
    // MARK: - Token Filtering for Sections
    
    // These methods filter tokens to show only those relevant to each section for better debugging
    
    static func filterTokensForEssenceSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Essence section, focus on Sun, Venus, and Ascendant signs
        return tokens.filter {
            ($0.planetarySource == "Sun" || $0.planetarySource == "Venus" || $0.planetarySource == "Ascendant") ||
            ($0.type == "mood" || $0.type == "texture" || $0.type == "structure")
        }
    }
    
    static func filterTokensForCoreSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Core section, focus on Sun, Venus, and Moon signs
        return tokens.filter {
            ($0.planetarySource == "Sun" || $0.planetarySource == "Venus" || $0.planetarySource == "Moon")
        }
    }
    
    static func filterTokensForExpressionSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Expression section, focus on Ascendant, Mercury, and Mars
        return tokens.filter {
            ($0.planetarySource == "Ascendant" || $0.planetarySource == "Mercury" || $0.planetarySource == "Mars") ||
            ($0.houseSource == 1 || $0.houseSource == 3 || $0.houseSource == 5) ||
            ($0.type == "expression" || $0.type == "structure")
        }
    }
    
    static func filterTokensForMagnetismSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Magnetism section, focus on Venus placement and aspects
        return tokens.filter {
            ($0.planetarySource == "Venus" || $0.planetarySource == "Moon") ||
            ($0.houseSource == 1 || $0.houseSource == 7) ||
            ($0.name.contains("magnetic") || $0.name.contains("attractive") ||
             $0.name.contains("harmonious") || $0.name.contains("balanced"))
        }
    }
    
    static func filterTokensForEmotionalDressingSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Emotional Dressing section, focus on Moon placement
        return tokens.filter {
            ($0.planetarySource == "Moon" || $0.planetarySource == "Neptune") ||
            ($0.signSource == "Pisces") ||
            ($0.houseSource == 12) ||
            ($0.name.contains("emotional") || $0.name.contains("intuitive") ||
             $0.name.contains("sensitive") || $0.name.contains("nurturing"))
        }
    }
    
    static func filterTokensForPlanetaryFrequencySection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Planetary Frequency section, focus on elemental dominance
        return tokens.filter {
            ($0.name == "earthy" || $0.name == "watery" ||
             $0.name == "fiery" || $0.name == "airy") ||
            ($0.type == "element") ||
            ($0.name.contains("reflective") || $0.name.contains("introspective"))
        }
    }
    
    static func filterTokensForFabricSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Fabric section, focus on texture and element tokens
        return tokens.filter {
            ($0.type == "texture" || $0.type == "fabric" || $0.type == "element") ||
            ($0.name == "sensual" || $0.name == "comfortable" ||
             $0.name == "structured" || $0.name == "fluid" ||
             $0.name == "layered" || $0.name == "textured")
        }
    }
    
    static func filterTokensForStylePulseSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Style Pulse section, select top weighted tokens
        return Array(tokens.sorted { $0.weight > $1.weight }.prefix(15))
    }
    
    static func filterTokensForFashionGuidanceSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Fashion Guidance section, focus on structure and expression tokens
        return tokens.filter {
            ($0.type == "structure" || $0.type == "expression" ||
             $0.type == "mood" || $0.type == "approach") ||
            ($0.name.contains("layered") || $0.name.contains("structured") ||
             $0.name.contains("minimal") || $0.name.contains("bold") ||
             $0.name.contains("subtle") || $0.name.contains("practical"))
        }
    }
    
    static func filterTokensForColorSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Color section, focus on color and element tokens
        return tokens.filter {
            ($0.type == "color" || $0.type == "element") ||
            ($0.name.contains("muted") || $0.name.contains("bright") ||
             $0.name.contains("dark") || $0.name.contains("light"))
        }
    }
    
    static func filterTokensForWardrobeStorylineSection(_ tokens: [StyleToken]) -> [StyleToken] {
        // For Wardrobe Storyline section, focus on progressed tokens
        return tokens.filter {
            ($0.planetarySource?.contains("Progressed") == true) ||
            ($0.name.contains("transformative") || $0.name.contains("evolutionary") ||
             $0.name.contains("balanced") || $0.name.contains("integrated"))
        }
    }
    
    // MARK: - Sentence-Level Debug Methods
    
    /// Debug helper to log each sentence addition to a paragraph with context
    static func debugLogSentence(_ sentence: String, tokens: [StyleToken], section: String, context: String? = nil) {
        // Find relevant tokens for this sentence
        let relevantTokens = findRelevantTokensForSentence(sentence, from: tokens)
        
        // Log the sentence with its influential tokens
        DebugLogger.sentence(text: sentence, influencedBy: relevantTokens, inSection: section)
        
        // Log additional context if provided
        if let context = context {
            DebugLogger.verbose("Context: \(context)")
        }
    }
    
    /// Find tokens likely to have influenced a particular sentence
    private static func findRelevantTokensForSentence(_ sentence: String, from allTokens: [StyleToken]) -> [StyleToken] {
        // This is a simple heuristic that looks for token names in the sentence
        var relevantTokens: [StyleToken] = []
        
        // First pass: look for direct token name mentions in the sentence
        for token in allTokens {
            if sentence.lowercased().contains(token.name.lowercased()) {
                relevantTokens.append(token)
            }
        }
        
        // If no direct matches, use key tokens by weight
        if relevantTokens.isEmpty {
            relevantTokens = Array(allTokens.sorted { $0.weight > $1.weight }.prefix(5))
        }
        
        return relevantTokens
    }
    
    // MARK: - Enhanced Section Generators with Sentence Debugging
    
    /// Generate Essence section with debug logging for each sentence
    static func generateEssenceSectionWithDebug(from tokens: [StyleToken]) -> String {
        DebugLogger.info("Generating Style Essence section with debug")
        
        // ✴️ SOURCE: Sun sign + Venus sign + Ascendant sign
        // ⚖️ WEIGHTING: Sun x1.1, Venus x1.5, Ascendant x1.3
        
        // Get top 3 tokens by weight
        let topTokens = tokens
            .filter { $0.type == "mood" || $0.type == "texture" || $0.type == "structure" }
            .sorted { $0.weight > $1.weight }
            .prefix(3)
        
        // Check for dominant elements
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 2.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 2.0 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 2.0 }
        let hasIntuitive = tokens.contains { $0.name == "intuitive" && $0.weight > 2.0 }
        
        // Extract key themes from top tokens
        var themes: [String] = []
        for token in topTokens {
            themes.append(token.name)
        }
        
        // Process 12th house influence (dreamlike) - using Whole Sign house
        let has12thHouse = tokens.contains { $0.houseSource == 12 && $0.weight > 2.0 }
        
        // Build the essence paragraph with debugging
        var essence = ""
        var sentence = ""
        
        // First sentence based on dominant elements
        if hasEarthy && hasIntuitive {
            sentence = "You walk the line between earth and ether—rooted, but always sensing something deeper. "
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "hasEarthy && hasIntuitive")
        } else if hasEarthy {
            sentence = "You embody a grounded presence, drawing strength from what feels stable and real. "
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "hasEarthy")
        } else if hasFluid {
            sentence = "There's a flowing energy to your presence—adaptable, intuitive, and subtly responsive. "
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "hasFluid")
        } else if hasBold {
            sentence = "You project a confident energy that leaves an impression—unmistakable, defined, and purposeful. "
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "hasBold")
        } else {
            sentence = "Your style essence balances personal expression with authentic presence. "
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "default")
        }
        essence += sentence
        
        // Second sentence about presence
        sentence = "There's a "
        if hasBold {
            sentence += "compelling force in your presence, a clear kind of intention. "
        } else {
            sentence += "quiet force in your presence, a soft kind of defiance. "
        }
        debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                         context: "Force in presence: hasBold = \(hasBold)")
        essence += sentence
        
        // Third sentence about energy
        sentence = "Your energy isn't "
        if hasBold {
            sentence += "subtle, but it resonates. "
        } else {
            sentence += "loud, but it lingers. "
        }
        debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                         context: "Energy description: hasBold = \(hasBold)")
        essence += sentence
        
        // Final sentence about dressing
        sentence = ""
        if has12thHouse {
            sentence += "You dress like someone who remembers dreams—and honors them through "
        } else {
            sentence += "You dress like someone who remembers every version of yourself—and honors them through "
        }
        sentence += "texture, color, and the way fabric falls. This blueprint reflects a wardrobe built on "
        debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                         context: "Dressing style: has12thHouse = \(has12thHouse)")
        essence += sentence
        
        // Add the three themes as closing qualities
        if !themes.isEmpty {
            sentence = themes.joined(separator: ", ") + "."
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "Closing themes")
        } else {
            sentence = "intuition, integrity, and evolution."
            debugLogSentence(sentence, tokens: tokens, section: "Style Essence",
                             context: "Default closing themes")
        }
        essence += sentence
        
        DebugLogger.info("Completed Style Essence section")
        return essence
    }
    
    // Similar debug-enhanced implementations could be created for other section generators
    // as needed, following the same pattern shown above
}
