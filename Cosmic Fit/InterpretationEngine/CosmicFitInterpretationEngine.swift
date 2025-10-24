//
//  CosmicFitInterpretationEngine.swift
//  Cosmic Fit
//
//

import Foundation

/// Main entry point for the Cosmic Fit Interpretation Engine
class CosmicFitInterpretationEngine {
    
    // MARK: - Public Methods
    
    /// Generate a complete natal chart interpretation (Cosmic Blueprint)
    /// - Parameter chart: The natal chart to interpret
    /// - Parameter currentAge: User's current age for age-dependent weighting
    /// - Returns: An interpretation result with the cosmic blueprint
    static func generateBlueprintInterpretation(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        
        // Unified debug/production logging
        DebugConfiguration.debugLog {
            DebugLogger.info("Starting Blueprint interpretation generation with debug")
            print("\n🧩 GENERATING COSMIC FIT BLUEPRINT 🧩")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📊 Chart Data Analysis:")
            print("Sun Sign: \(CoordinateTransformations.getZodiacSignName(sign: chart.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0))")
            print("Ascendant Sign: \(CoordinateTransformations.getZodiacSignName(sign: CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign))")
            print("Current Age Parameter: \(currentAge)")
        }
        
        // Production logging
        if !DebugConfiguration.isDebugEnabled {
            print("\n🧩 GENERATING COSMIC FIT BLUEPRINT 🧩")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }

        // Generate base tokens from natal chart with Whole Sign houses for Blueprint
        DebugConfiguration.debugLog {
            print("\n🪙 GENERATING BASE TOKENS 🪙")
        }
        
        let baseTokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart, currentAge: currentAge)
        
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
        
        // Generate color frequency tokens for nuanced colors
        DebugConfiguration.debugLog {
            print("\n🎨 GENERATING COLOR FREQUENCY TOKENS 🎨")
        }
        
        let colorFrequencyTokens = SemanticTokenGenerator.generateColorFrequencyTokens(
            natal: chart,
            progressed: chart, // Use natal as progressed for blueprint (100% natal for blueprint colors)
            currentAge: currentAge
        )
        
        DebugConfiguration.debugLog {
            print("Generated \(colorFrequencyTokens.count) color frequency tokens")
        }

        // Combine base tokens with color frequency tokens
        DebugConfiguration.debugLog {
            print("\n🔄 COMBINING ALL TOKENS 🔄")
        }
        
        var allTokens = baseTokens
        allTokens.append(contentsOf: colorFrequencyTokens)
        
        DebugConfiguration.debugLog {
            print("Total combined tokens: \(allTokens.count)")
            
            // Log top weighted tokens
            let topTokens = allTokens.sorted { $0.weight > $1.weight }.prefix(10)
            print("\n⭐ TOP 10 WEIGHTED TOKENS ⭐")
            for (index, token) in topTokens.enumerated() {
                print("\(index + 1). \(token.name): \(String(format: "%.2f", token.weight))")
            }
        }

        // Generate birth info text
        var birthInfoText: String? = nil
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
            birthInfoText = "Natal Chart: \(sunSignName) Energy"
        }
        
        DebugConfiguration.debugLog {
            print("\n📝 GENERATING BLUEPRINT TEXT 📝")
        }

        // Generate the blueprint text using unified assembler
        let blueprintText = ParagraphAssembler.generateBlueprintInterpretation(
            tokens: allTokens,
            birthInfo: birthInfoText
        )

        // Select theme
        let themeName = ThemeSelector.scoreThemes(tokens: allTokens)
        
        DebugConfiguration.debugLog {
            print("\n✅ Blueprint generation completed successfully!")
            print("Theme: \(themeName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }

        // Production logging
        if !DebugConfiguration.isDebugEnabled {
            print("✅ Blueprint generated successfully!")
            print("Theme: \(themeName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }

        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: blueprintText,
            tokensUsed: allTokens,
            isBlueprintReport: true,
            reportDate: Date()
        )
    }
    
    /// Generate a daily vibe interpretation with daily seeding for variety
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    ///   - profileHash: Stable user/profile identifier for daily seed generation
    ///   - date: Target date (defaults to today)
    /// - Returns: A daily vibe content object with formatted sections
    static func generateDailyVibeInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        profileHash: String,
        date: Date = Date()
    ) -> DailyVibeContent {
        
        // Unified debug/production logging
        DebugConfiguration.debugLog {
            DebugLogger.dailyVibeGenerationStart(natal: natalChart, progressed: progressedChart, transits: transits)
            
            // Log transit information
            let planetCounts = transits.reduce(into: [String: Int]()) { counts, transit in
                if let planet = transit["transitPlanet"] as? String {
                    counts[planet, default: 0] += 1
                }
            }
            
            print("Transit distribution:")
            for (planet, count) in planetCounts.sorted(by: { $0.key < $1.key }) {
                print("  - \(planet): \(count) aspects")
            }
        }
        
        // Production logging
        if !DebugConfiguration.isDebugEnabled {
            print("\n🎯 DAILY VIBE GENERATOR")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
        
        // Calculate moon phase using existing helper
        let moonPhase = calculateCurrentMoonPhase()
        
        // Generate daily vibe with seeding
        let dailyVibe = DailyVibeGenerator.generateDailyVibe(
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            moonPhase: moonPhase,
            profileHash: profileHash,
            date: date
        )
        
        DebugConfiguration.debugLog {
            print("✅ Daily vibe generated successfully with seed")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
        
        if !DebugConfiguration.isDebugEnabled {
            print("✅ Daily vibe generated successfully")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
        
        return dailyVibe
    }
    
    /// Generate a combined interpretation including both blueprint and daily vibe
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    ///   - profileHash: Stable user/profile identifier for daily seed generation
    ///   - date: Target date (defaults to today)
    /// - Returns: A combined interpretation string with blueprint and daily vibe
    static func generateFullInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        profileHash: String,
        date: Date = Date()
    ) -> String {

        print("\n📋 GENERATING FULL INTERPRETATION (Blueprint + Daily Vibe)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Generate blueprint (natal chart based, no seeding needed)
        let blueprint = generateBlueprintInterpretation(from: natalChart)

        // Generate daily vibe WITH profileHash for proper seeding
        let dailyVibe = generateDailyVibeInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            profileHash: profileHash,
            date: date
        )

        // Format the date for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "en_GB")
        let dateString = dateFormatter.string(from: date)

        // Combine both interpretations into formatted output
        let fullInterpretation = """
        YOUR COSMIC BLUEPRINT
        ====================
        
        \(blueprint.stitchedParagraph)
        
        
        TODAY'S COSMIC VIBE (\(dateString))
        ====================
        
        \(dailyVibe.styleBrief)
        
        TEXTILES: \(dailyVibe.textiles)
        
        COLORS: \(dailyVibe.colors)
        
        PATTERNS: \(dailyVibe.patterns)
        
        SHAPE: \(dailyVibe.shape)
        
        ACCESSORIES: \(dailyVibe.accessories)
        
        \(dailyVibe.styleBrief)
        """
        
        print("✅ Full interpretation generated successfully")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return fullInterpretation
    }
    
    // MARK: - Specialized Section Generation Methods
    
    /// Generate color frequency interpretation (70% natal, 30% progressed)
    static func generateColorFrequencyInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateColorFrequencyTokens(
            natal: natalChart,
            progressed: progressedChart,
            currentAge: currentAge)

        return ParagraphAssembler.generateColorRecommendations(from: tokens)
    }
    
    /// Generate wardrobe storyline interpretation (60% progressed with Placidus, 40% natal)
    static func generateWardrobeStorylineInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateWardrobeStorylineTokens(
            natal: natalChart,
            progressed: progressedChart,
            currentAge: currentAge)

        return ParagraphAssembler.generateWardrobeStoryline(from: tokens)
    }
    
    /// Generate style pulse interpretation (90% natal, 10% progressed flavor)
    static func generateStylePulseInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateStylePulseTokens(
            natal: natalChart,
            progressed: progressedChart,
            currentAge: currentAge)

        return ParagraphAssembler.generateStylePulse(from: tokens)
    }
    
    /// Generate fashion guidance interpretation (100% natal)
    static func generateFashionGuidanceInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: natalChart, currentAge: currentAge)

        return ParagraphAssembler.generateFashionGuidance(from: tokens)
    }
    
    /// Generate fabric recommendations interpretation (100% natal)
    static func generateFabricRecommendationsInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30,
        weather: TodayWeather? = nil) -> String {
        
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: natalChart, currentAge: currentAge)
        
        // FOR BLUEPRINT: Don't pass weather - this is pure chart analysis
        return ParagraphAssembler.generateFabricRecommendations(from: tokens, weather: nil)
    }
    
    /// Generate style tensions interpretation (natal aspects)
    static func generateStyleTensionsInterpretation(
        from natalChart: NatalChartCalculator.NatalChart,
        currentAge: Int = 30) -> String {

        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: natalChart, currentAge: currentAge)

        return ParagraphAssembler.generateStyleTensionsSection(from: tokens)
    }
    
    /// Run system validation tests - call this method from your test device
    /// Returns true if all critical tests pass
    static func runSystemValidation() -> Bool {
        print("\n🔧 COSMIC FIT SYSTEM VALIDATION")
        print(String(repeating: "=", count: 50))
        
        // Run all validation tests
        let validationResult = SystemValidationTests.runAllValidationTests()
        
        print("\n✨ System validation \(validationResult ? "PASSED" : "FAILED")")
        print(String(repeating: "=", count: 50))
        
        return validationResult
    }

    /// Verify system integration is working correctly
    /// Call this method during development to ensure all changes are functioning
    static func verifySystemIntegration() {
        print("\n🔍 SYSTEM INTEGRATION VERIFICATION")
        print(String(repeating: "=", count: 50))
        
        // Check that enhanced methods work
        let mockChart = SystemValidationTests.createMockNatalChart()
        
        // Test enhanced Venus/Mars/Moon weights
        let blueprintTokens = SemanticTokenGenerator.generateBlueprintTokens(natal: mockChart, currentAge: 30)
        let venusTokens = blueprintTokens.filter { $0.planetarySource == "Venus" }
        let marsTokens = blueprintTokens.filter { $0.planetarySource == "Mars" }
        let moonTokens = blueprintTokens.filter { $0.planetarySource == "Moon" }
        
        print("✅ Enhanced weights active:")
        print("  • Venus tokens: \(venusTokens.count)")
        print("  • Mars tokens: \(marsTokens.count)")
        print("  • Moon tokens: \(moonTokens.count)")
        
        // Check WeatherFabricFilter is available and functional
        let mockWeather = TodayWeather(condition: "Clear", temperature: 30.0, humidity: 50, windKph: 10)
        let testFiltering = WeatherFabricFilter.requiresWeatherOverride(weather: mockWeather)
        print("✅ Hard weather filtering: \(testFiltering ? "Active" : "Inactive") for test conditions")
        
        // Test method signature compatibility
        let testTokens: [StyleToken] = []
        let _ = ParagraphAssembler.generateFabricRecommendations(from: testTokens, weather: mockWeather)
        print("✅ ParagraphAssembler weather parameter integration: Working")
        
        // Run validation tests
        let validationPassed = SystemValidationTests.runAllValidationTests()
        print("✅ System validation: \(validationPassed ? "PASSED" : "FAILED")")
        
        print("\n🎯 Integration status: \(validationPassed ? "READY FOR TESTING" : "NEEDS ATTENTION")")
        print(String(repeating: "=", count: 50))
    }
}

// MARK: - Convenience Methods for View Controllers

extension CosmicFitInterpretationEngine {
    
    /// Convenience method for view controllers to generate blueprint with current debug settings
    static func generateBlueprintForViewController(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        return generateBlueprintInterpretation(from: chart, currentAge: currentAge)
    }
    
    /// Convenience method for view controllers to generate daily vibe with current debug settings
    static func generateDailyVibeForViewController(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        profileHash: String
    ) -> DailyVibeContent {
        
        return generateDailyVibeInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            profileHash: profileHash
        )
    }
    
    /// Convenience method for view controllers to generate full interpretation with current debug settings
    static func generateFullInterpretationForViewController(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        profileHash: String
    ) -> String {
        
        return generateFullInterpretation(
            from: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            weather: weather,
            profileHash: profileHash
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
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: natalChart, currentAge: currentAge)
        
        // Score tokens against themes to find the best-fit theme
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        
        // Generate custom guidance based on the query and theme
        var guidance = "Custom Style Guidance: \(query)\n\n"
        
        // Add theme-specific recommendations
        guidance += "Based on your Cosmic Blueprint theme of \"\(themeName)\", here are styling recommendations for \(query):\n\n"
        
        // Add situation-specific guidance
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
                return "Channel your bold energy through confident color choices and strong silhouettes, while keeping details professional. A well-cut blazer in a rich color can satisfy both your expressive nature and workplace expectations."
            } else {
                return "Choose pieces that feel authentically you while respecting professional norms. Quality basics in colors that energize you will serve as a strong foundation."
            }
        } else if query.contains("date") || query.contains("romantic") || query.contains("dinner") {
            if hasExpressive {
                return "This is your moment to let your expressive nature shine. Choose pieces with interesting textures, colors, or details that invite conversation and reflect your personality."
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
                return "This is your time to shine! Choose pieces that make a statement—rich colors, interesting textures, or striking silhouettes that reflect your dynamic energy."
            } else if hasSubtle {
                return "Your understated elegance is perfect for special events. Choose pieces with luxurious fabrics or refined details that create impact through quality rather than flash."
            } else if hasExpressive {
                return "Let your creative side lead. Choose pieces with artistic details, interesting proportions, or unique elements that spark conversation and showcase your individuality."
            } else {
                return "Select pieces that make you feel celebratory while staying true to your style. The key is feeling confident and appropriately festive for the occasion."
            }
        } else {
            // Default guidance for unspecified situations
            return "Based on your cosmic blueprint, focus on pieces that align with your natural energy patterns. Choose clothes that support rather than fight your authentic self-expression."
        }
    }
}

// MARK: - Debug Method Compatibility (for transition period)

extension CosmicFitInterpretationEngine {
    
    /// Debug wrapper for blueprint generation (maintains compatibility during transition)
    static func generateBlueprintInterpretationWithDebug(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        // This now just calls the unified method - no separate implementation needed
        return generateBlueprintInterpretation(from: chart, currentAge: currentAge)
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
