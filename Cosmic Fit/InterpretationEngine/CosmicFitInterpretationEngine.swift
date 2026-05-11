//
//  CosmicFitInterpretationEngine.swift
//  Cosmic Fit
//
//

import Foundation

/// Main entry point for the Cosmic Fit Interpretation Engine
class CosmicFitInterpretationEngine {
    
    // MARK: - Public Methods
    
    /// Generate a complete natal chart interpretation (Cosmic Style Guide)
    /// - Parameter chart: The natal chart to interpret
    /// - Parameter currentAge: User's current age for age-dependent weighting
    /// - Returns: An interpretation result with the cosmic style guide
    static func generateStyleGuideInterpretation(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        
        // Unified debug/production logging
        DebugConfiguration.debugLog {
            DebugLogger.info("Starting Style Guide interpretation generation with debug")
            print("\n🧩 GENERATING COSMIC FIT STYLE GUIDE 🧩")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📊 Chart Data Analysis:")
            print("Sun Sign: \(CoordinateTransformations.getZodiacSignName(sign: chart.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0))")
            print("Ascendant Sign: \(CoordinateTransformations.getZodiacSignName(sign: CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign))")
            print("Current Age Parameter: \(currentAge)")
        }
        
        // Production logging
        if !DebugConfiguration.isDebugEnabled {
            print("\n🧩 GENERATING COSMIC FIT STYLE GUIDE 🧩")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }

        // Generate base tokens from natal chart with Whole Sign houses for Style Guide
        DebugConfiguration.debugLog {
            print("\n🪙 GENERATING BASE TOKENS 🪙")
        }
        
        let baseTokens = SemanticTokenGenerator.generateStyleGuideTokens(natal: chart, currentAge: currentAge)
        
        DebugConfiguration.debugLog {
            print("Generated \(baseTokens.count) base tokens")
            
            // Log token categories
            var tokenCategories: [String: Int] = [:]
            for token in baseTokens {
                tokenCategories[token.type, default: 0] += 1
            }
            print("Token categories:")
            for (category, count) in tokenCategories.sorted(by: { $0.key < $1.key }) {
                print("  - \(category): \(count) tokens")
            }
        }
        
        // Generate colour frequency tokens for nuanced colours
        DebugConfiguration.debugLog {
            print("\n🎨 GENERATING COLOUR FREQUENCY TOKENS 🎨")
        }
        
        let colourFrequencyTokens = SemanticTokenGenerator.generateColourFrequencyTokens(
            natal: chart,
            progressed: chart, // Use natal as progressed for style guide (100% natal for style guide colours)
            currentAge: currentAge
        )
        
        DebugConfiguration.debugLog {
            print("Generated \(colourFrequencyTokens.count) colour frequency tokens")
        }

        // Combine base tokens with colour frequency tokens
        DebugConfiguration.debugLog {
            print("\n🔄 COMBINING ALL TOKENS 🔄")
        }
        
        var allTokens = baseTokens
        allTokens.append(contentsOf: colourFrequencyTokens)
        
        DebugConfiguration.debugLog {
            print("Total combined tokens: \(allTokens.count)")
            
            // Log top weighted tokens
            let topTokens = allTokens.sorted { $0.weight > $1.weight }.prefix(10)
            print("\n⭐ TOP 10 WEIGHTED TOKENS ⭐")
            for (index, token) in topTokens.enumerated() {
                print("\(index + 1). \(token.name): \(String(format: "%.2f", token.weight))")
            }
        }
        
        DebugConfiguration.debugLog {
            print("\n📝 STYLE GUIDE TEXT (PLACEHOLDER) 📝")
            print("⚠️  Legacy ParagraphAssembler not used - template system to be implemented")
        }

        // ARCHITECTURAL NOTE: Style Guide now uses pre-written template selection
        // TODO: Implement template selection based on token patterns
        let styleGuideText = """
        STYLE GUIDE PLACEHOLDER
        
        This will be replaced with pre-written template selection based on token patterns.
        
        Token Analysis Available:
        - \(allTokens.count) total tokens generated
        - Top tokens: \(allTokens.sorted { $0.weight > $1.weight }.prefix(5).map { $0.name }.joined(separator: ", "))
        
        Next Steps:
        1. Analyze token patterns
        2. Match to pre-written templates
        3. Assemble selected templates into Style Guide sections
        """

        // Theme name placeholder (template system will handle categorization)
        let themeName = "Template-Based Style Guide"
        
        DebugConfiguration.debugLog {
            print("\n✅ Style Guide generation completed successfully!")
            print("Theme: \(themeName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }

        // Production logging
        if !DebugConfiguration.isDebugEnabled {
            print("✅ Style Guide generated successfully!")
            print("Theme: \(themeName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }

        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: styleGuideText,
            tokensUsed: allTokens,
            isStyleGuideReport: true,
            reportDate: Date()
        )
    }
}

// MARK: - Custom Style Guidance Methods

extension CosmicFitInterpretationEngine {
    
    /// Generate custom style guidance for a specific situation
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - query: The styling situation/query (e.g., "job interview", "date night")
    ///   - currentAge: User's current age for age-dependent weighting
    /// - Returns: A string containing customized style guidance
    static func generateCustomStyleGuidance(
        for natalChart: NatalChartCalculator.NatalChart,
        query: String,
        currentAge: Int = 30) -> String {
            
        // Generate tokens from natal chart
        let tokens = SemanticTokenGenerator.generateStyleGuideTokens(natal: natalChart, currentAge: currentAge)
        
        // NOTE: Theme system being replaced with template selection
        let themeName = "Your Cosmic Style"
        
        // Generate custom guidance based on the query and token patterns
        var guidance = "Custom Style Guidance: \(query)\n\n"
        
        // Add situation-specific guidance based on token analysis
        let situationGuidance = generateSituationGuidance(query: query, tokens: tokens, themeName: themeName)
        guidance += situationGuidance
        
        return guidance
    }
    
    /// Generate situation-specific style guidance
    private static func generateSituationGuidance(query: String, tokens: [StyleToken], themeName: String) -> String {
        // Look for dominant style characteristics
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 2.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 2.0 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 2.0 }
        let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 2.0 }
        let hasComfortable = tokens.contains { $0.name == "comfortable" && $0.weight > 2.0 }
        let hasExpressive = tokens.contains { $0.name == "expressive" && $0.weight > 2.0 }
        
        let query = query.lowercased()
        
        if query.contains("interview") || query.contains("professional") || query.contains("work") {
            if hasStructured {
                return "For this professional setting, lean into your natural affinity for structure with a well-tailored silhouette. Choose pieces with clean lines and subtle details that communicate competence and attention to detail."
            } else if hasFluid {
                return "While maintaining professional standards, incorporate your natural fluidity through softer tailoring and layers that move with intention. Avoid overly rigid pieces that feel inauthentic to your energy."
            } else if hasBold {
                return "Channel your bold energy through confident colour choices and strong silhouettes, while keeping details professional. A well-cut blazer in a rich colour can satisfy both your expressive nature and workplace expectations."
            } else {
                return "Choose pieces that feel authentically you while respecting professional norms. Quality basics in colours that energize you will serve as a strong foundation."
            }
        } else if query.contains("date") || query.contains("romantic") || query.contains("dinner") {
            if hasExpressive {
                return "This is your moment to let your expressive nature shine. Choose pieces with interesting textures, colours, or details that invite conversation and reflect your personality."
            } else if hasSubtle {
                return "Your subtle magnetism is your strength. Choose pieces with refined details—perhaps an interesting neckline or luxurious fabric—that draw people in without being obvious."
            } else if hasComfortable {
                return "Comfort and confidence go hand in hand for you. Choose pieces that feel amazing against your skin and allow you to move naturally. When you feel comfortable, your authentic charm emerges."
            } else {
                return "Select pieces that make you feel most like yourself. Authenticity is more attractive than trying to be someone you're not. Trust your instincts about what makes you feel confident."
            }
        } else if query.contains("casual") || query.contains("weekend") || query.contains("relaxed") {
            if hasFluid {
                return "This is where your fluid nature can truly shine. Embrace pieces that move with you—flowing fabrics, comfortable layers, and silhouettes that adapt to your activities."
            } else if hasComfortable {
                return "Prioritize how things feel against your skin. Soft fabrics, well-fitting basics, and pieces you can move freely in will serve you best during relaxed moments."
            } else if hasStructured {
                return "Even in casual settings, you appreciate structure. Look for well-cut casual pieces—perhaps a perfectly fitted tee or structured jacket that maintains your aesthetic while feeling relaxed."
            } else {
                return "Choose pieces that honor both comfort and your personal style. The goal is to feel relaxed while still feeling like yourself."
            }
        } else if query.contains("party") || query.contains("celebration") || query.contains("event") {
            if hasBold {
                return "This is your time to shine! Choose pieces that make a statement—rich colours, interesting textures, or striking silhouettes that reflect your dynamic energy."
            } else if hasSubtle {
                return "Your understated elegance is perfect for special events. Choose pieces with luxurious fabrics or refined details that create impact through quality rather than flash."
            } else if hasExpressive {
                return "Let your creative side lead. Choose pieces with artistic details, interesting proportions, or unique elements that spark conversation and showcase your individuality."
            } else {
                return "Select pieces that make you feel celebratory while staying true to your style. The key is feeling confident and appropriately festive for the occasion."
            }
        } else {
            // Default guidance for unspecified situations
            return "Based on your cosmic style guide, focus on pieces that align with your natural energy patterns. Choose clothes that support rather than fight your authentic self-expression."
        }
    }
}

// MARK: - Debug Method Compatibility (for transition period)

extension CosmicFitInterpretationEngine {
    
    /// Debug wrapper for style guide generation (maintains compatibility during transition)
    static func generateStyleGuideInterpretationWithDebug(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        // This now just calls the unified method - no separate implementation needed
        return generateStyleGuideInterpretation(from: chart, currentAge: currentAge)
    }
}

// MARK: - Private Helper Methods

extension CosmicFitInterpretationEngine {
    
    /// Calculate current moon phase (0-360 degrees)
    private static func calculateCurrentMoonPhase() -> Double {
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        return AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
    }
    
    /// Get current Julian day for calculations
    private static func getCurrentJulianDay() -> Double {
        let currentDate = Date()
        return JulianDateCalculator.calculateJulianDate(from: currentDate)
    }
}
