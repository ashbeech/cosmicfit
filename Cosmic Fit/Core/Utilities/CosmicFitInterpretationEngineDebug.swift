//
//  CosmicFitInterpretationEngineDebug.swift
//  Cosmic Fit
//
//  Created for enhanced debugging of interpretation generation
//

import Foundation

/// Debug extension for the CosmicFitInterpretationEngine
extension CosmicFitInterpretationEngine {
    
    /// Generate a complete natal chart interpretation (Cosmic Blueprint) with detailed debugging
    /// - Parameter chart: The natal chart to interpret
    /// - Parameter currentAge: User's current age for age-dependent weighting
    /// - Returns: An interpretation result with the cosmic blueprint
    static func generateBlueprintInterpretationWithDebug(from chart: NatalChartCalculator.NatalChart, currentAge: Int = 30) -> InterpretationResult {
        print("\n🧩 GENERATING COSMIC FIT BLUEPRINT WITH DEBUG 🧩")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Chart Data Analysis:")
        print("Sun Sign: \(CoordinateTransformations.getZodiacSignName(sign: chart.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0))")
        print("Ascendant Sign: \(CoordinateTransformations.getZodiacSignName(sign: CoordinateTransformations.decimalDegreesToZodiac(chart.ascendant).sign))")
        print("Current Age Parameter: \(currentAge)")
        
        // Generate base tokens from natal chart with Whole Sign houses for Blueprint
        print("\n🪙 GENERATING BASE TOKENS 🪙")
        let baseTokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart, currentAge: currentAge)
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
        
        // Generate color frequency tokens for nuanced colors
        print("\n🎨 GENERATING COLOR FREQUENCY TOKENS 🎨")
        let colorFrequencyTokens = SemanticTokenGenerator.generateColorFrequencyTokens(
            natal: chart,
            progressed: chart, // Use natal as progressed for blueprint (100% natal for blueprint colors)
            currentAge: currentAge
        )
        print("Generated \(colorFrequencyTokens.count) color frequency tokens")
        
        // Combine base tokens with color frequency tokens
        print("\n🔄 COMBINING ALL TOKENS 🔄")
        var allTokens = baseTokens
        allTokens.append(contentsOf: colorFrequencyTokens)
        print("Total combined tokens: \(allTokens.count)")
        
        // Log top weighted tokens
        let topTokens = allTokens.sorted { $0.weight > $1.weight }.prefix(10)
        print("\n⭐ TOP 10 WEIGHTED TOKENS ⭐")
        for (index, token) in topTokens.enumerated() {
            print("\(index + 1). \(token.name) (\(token.type), weight: \(String(format: "%.2f", token.weight)))")
            if let source = token.planetarySource {
                print("   Source: \(source)")
            }
        }
        
        // Format birth info for display in the blueprint header
        var birthInfoText: String? = nil
        
        // Find the Sun position for sign information
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
            birthInfoText = "Natal Chart: \(sunSignName) Energy"
        }
        
        // Generate the complete blueprint with all sections according to spec
        print("\n📝 GENERATING BLUEPRINT SECTIONS 📝")
        let blueprintText = ParagraphAssembler.generateBlueprintInterpretation(
            tokens: allTokens,
            birthInfo: birthInfoText
        )
        
        print("Blueprint text length: \(blueprintText.count) characters")
        
        // Determine the dominant theme from tokens
        print("\n🎭 DETERMINING DOMINANT THEME 🎭")
        let themeName = ThemeSelector.scoreThemes(tokens: allTokens)
        print("Selected Theme: \(themeName)")
        
        // Log the top themes with scores for debugging
        let topThemes = ThemeSelector.rankThemes(tokens: allTokens, topCount: 5)
        print("\n📊 TOP THEMES BY SCORE:")
        for (i, theme) in topThemes.enumerated() {
            print("  \(i+1). \(theme.name): Score \(String(format: "%.2f", theme.score))")
        }
        
        // Log any style tensions detected
        print("\n⚖️ STYLE TENSIONS DETECTED:")
        let styleTensions = ParagraphAssembler.detectStylePushPullConflicts(from: allTokens)
        if styleTensions.isEmpty {
            print("  None detected - harmonious integration of elements")
        } else {
            for (i, tension) in styleTensions.enumerated() {
                print("  \(i+1). \(tension)")
            }
        }
        
        print("\n✅ Blueprint generation completed successfully!")
        print("Theme: \(themeName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: blueprintText,
            tokensUsed: allTokens,
            isBlueprintReport: true,
            reportDate: Date()
        )
    }
    
    /// Generate a daily vibe interpretation with detailed debugging output
    /// - Parameters:
    ///   - natalChart: The base natal chart
    ///   - progressedChart: The current progressed chart
    ///   - transits: Array of transit aspects
    ///   - weather: Optional current weather conditions
    /// - Returns: A daily vibe content object with formatted sections
    static func generateDailyVibeInterpretationWithDebug(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> DailyVibeContent {
            
            print("\n🔍 STARTING DETAILED DEBUG DAILY VIBE GENERATION 🔍")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // Log chart information
            print("📊 CHART DATA ANALYSIS:")
            print("Natal Sun Sign: \(CoordinateTransformations.getZodiacSignName(sign: natalChart.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0))")
            print("Natal Moon Sign: \(CoordinateTransformations.getZodiacSignName(sign: natalChart.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0))")
            print("Progressed Moon Sign: \(CoordinateTransformations.getZodiacSignName(sign: progressedChart.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0))")
            print("Natal Ascendant Sign: \(CoordinateTransformations.getZodiacSignName(sign: CoordinateTransformations.decimalDegreesToZodiac(natalChart.ascendant).sign))")
            
            // Log transit information
            print("\n🔄 TRANSIT INFORMATION:")
            print("Total transit aspects: \(transits.count)")
            
            let planetCounts = transits.reduce(into: [String: Int]()) { counts, transit in
                if let planet = transit["transitPlanet"] as? String {
                    counts[planet, default: 0] += 1
                }
            }
            
            print("Transit planets:")
            for (planet, count) in planetCounts.sorted(by: { $0.key < $1.key }) {
                print("  - \(planet): \(count) aspects")
            }
            
            // Log weather information if available
            if let weather = weather {
                print("\n☀️ WEATHER INFORMATION:")
                print("Temperature: \(weather.temp)°C")
                print("Conditions: \(weather.conditions)")
                print("Humidity: \(weather.humidity)%")
                print("Wind: \(weather.windKph) km/h")
            } else {
                print("\n⚠️ No weather information available")
            }
            
            // Get current lunar phase
            let currentDate = Date()
            let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
            let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
            let moonPhase = MoonPhaseInterpreter.Phase.fromDegrees(lunarPhase)
            
            print("\n🌙 MOON PHASE INFORMATION:")
            print("Current lunar phase: \(moonPhase.description) (\(String(format: "%.1f", lunarPhase))°)")
            
            // Log token generation process
            print("\n🪙 TOKEN GENERATION PROCESS:")
            
            // 1. Generate tokens for base style resonance (100% natal, Whole Sign)
            print("\n1️⃣ GENERATING BASE STYLE TOKENS (100% NATAL, WHOLE SIGN)")
            let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
            logTokenSet("BASE STYLE TOKENS", baseStyleTokens)
            
            // 2. Generate tokens for emotional vibe of day (60% progressed Moon, 40% natal Moon, Placidus)
            print("\n2️⃣ GENERATING EMOTIONAL VIBE TOKENS (60% PROGRESSED, 40% NATAL, PLACIDUS)")
            let emotionalVibeTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
                natal: natalChart,
                progressed: progressedChart
            )
            logTokenSet("EMOTIONAL VIBE TOKENS", emotionalVibeTokens)
            
            // 3. Generate tokens from planetary transits (Placidus houses)
            print("\n3️⃣ GENERATING TRANSIT TOKENS (PLACIDUS)")
            let transitTokens = SemanticTokenGenerator.generateTransitTokens(
                transits: transits,
                natal: natalChart
            )
            logTokenSet("TRANSIT TOKENS", transitTokens)
            
            // 4. Generate tokens from moon phase
            print("\n4️⃣ GENERATING MOON PHASE TOKENS")
            let moonPhaseTokens = SemanticTokenGenerator.generateMoonPhaseTokens(moonPhase: lunarPhase)
            logTokenSet("MOON PHASE TOKENS", moonPhaseTokens)
            
            // 5. Generate tokens from weather if available
            print("\n5️⃣ GENERATING WEATHER TOKENS")
            var weatherTokens: [StyleToken] = []
            if let weather = weather {
                weatherTokens = SemanticTokenGenerator.generateWeatherTokens(weather: weather)
                logTokenSet("WEATHER TOKENS", weatherTokens)
            } else {
                print("❗️ No weather data available - skipping weather tokens")
            }
            
            // 6. Combine all tokens with appropriate weighting
            print("\n6️⃣ COMBINING TOKENS WITH APPROPRIATE WEIGHTING")
            var allTokens: [StyleToken] = []
            
            // Add base style tokens (50% weight in final output)
            for token in baseStyleTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.5,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Add emotional vibe tokens (integrated into 50% transit weight)
            for token in emotionalVibeTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.2,  // 20% of total (part of the 50% transit-based)
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Add transit tokens (part of the 50% transit-based weight)
            for token in transitTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.2,  // 20% of total (part of the 50% transit-based)
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Add moon phase tokens (integrated into transit portion)
            for token in moonPhaseTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.05,  // 5% of total
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Add weather tokens (final styling filter)
            for token in weatherTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * 0.05,  // 5% of total
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Log combined weighted tokens
            logTokenSet("COMBINED WEIGHTED TOKENS", allTokens)
            
            // Log top weighted tokens
            let topTokens = allTokens.sorted { $0.weight > $1.weight }.prefix(10)
            print("\n⭐ TOP 10 WEIGHTED TOKENS ⭐")
            for (index, token) in topTokens.enumerated() {
                print("\(index + 1). \(token.name) (\(token.type), weight: \(String(format: "%.2f", token.weight)))")
                if let source = token.planetarySource {
                    print("   Source: \(source)")
                }
            }
            
            // 7. Generate the daily vibe content
            print("\n7️⃣ GENERATING DAILY VIBE CONTENT")
            let dailyVibeContent = DailyVibeGenerator.generateDailyVibeContent(tokens: allTokens, weather: weather, moonPhase: lunarPhase)
            
            // Log the generated content
            print("\n📋 GENERATED DAILY VIBE CONTENT:")
            print("Title: \(dailyVibeContent.title)")
            print("Main Paragraph: \(dailyVibeContent.mainParagraph.prefix(50))...")
            print("Brightness: \(dailyVibeContent.brightness)%")
            print("Vibrancy: \(dailyVibeContent.vibrancy)%")
            
            // Log theme determination
            let themeName = ThemeSelector.scoreThemes(tokens: allTokens)
            print("\n🎨 THEME DETERMINATION:")
            print("  • Selected Theme: \(themeName)")
            
            // Log the top themes with scores for debugging
            let topThemes = ThemeSelector.rankThemes(tokens: allTokens, topCount: 3)
            for (i, theme) in topThemes.enumerated() {
                print("  \(i+1). \(theme.name): Score \(String(format: "%.2f", theme.score))")
            }
            
            print("\n✅ Daily vibe generation completed successfully")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return dailyVibeContent
    }

    // Helper function for logging token sets in a consistent format
    private static func logTokenSet(_ title: String, _ tokens: [StyleToken]) {
        print("\n🪙 \(title) 🪙")
        print("  ▶ Count: \(tokens.count)")
        
        // Group by type
        var tokensByType: [String: [StyleToken]] = [:]
        for token in tokens {
            if tokensByType[token.type] == nil {
                tokensByType[token.type] = []
            }
            tokensByType[token.type]?.append(token)
        }
        
        // Print by type with weights
        for (type, typeTokens) in tokensByType.sorted(by: { $0.key < $1.key }) {
            print("  📊 \(type.uppercased())")
            
            // Sort by weight (highest first)
            let sorted = typeTokens.sorted { $0.weight > $1.weight }
            for token in sorted {
                var sourceInfo = ""
                if let planet = token.planetarySource {
                    sourceInfo += "[\(planet)]"
                }
                if let sign = token.signSource {
                    sourceInfo += "[\(sign)]"
                }
                if let house = token.houseSource {
                    sourceInfo += "[House \(house)]"
                }
                if let aspect = token.aspectSource {
                    sourceInfo += "[\(aspect)]"
                }
                
                print("    • \(token.name): \(String(format: "%.2f", token.weight)) \(sourceInfo)")
            }
        }
        
        // Count tokens by source
        var sourceCounts: [String: Int] = [:]
        for token in tokens {
            var source = "Unknown"
            if let planet = token.planetarySource {
                source = planet
            } else if let aspect = token.aspectSource {
                source = aspect
            }
            sourceCounts[source, default: 0] += 1
        }
        
        print("  🔍 SOURCE DISTRIBUTION:")
        for (source, count) in sourceCounts.sorted(by: { $0.key < $1.key }) {
            print("    • \(source): \(count) tokens")
        }
    }
    
    // MARK: - Daily Vibe Debug Helpers
    
    /// Generate daily vibe content with detailed debugging
    private static func generateDailyVibeContentWithDebug(tokens: [StyleToken], weather: TodayWeather?, moonPhase: Double) -> DailyVibeContent {
        // Create content object
        var content = DailyVibeContent()
        
        // Generate title
        content.title = generateVibeTitleWithDebug(tokens: tokens)
        
        // Generate main paragraph
        content.mainParagraph = generateMainParagraphWithDebug(tokens: tokens, moonPhase: moonPhase)
        
        // Generate textiles section
        content.textiles = generateTextilesWithDebug(tokens: tokens)
        
        // Generate colors section
        content.colors = generateColorsWithDebug(tokens: tokens)
        
        // Calculate brightness and vibrancy values
        content.brightness = calculateBrightnessWithDebug(tokens: tokens, moonPhase: moonPhase)
        content.vibrancy = calculateVibrancyWithDebug(tokens: tokens)
        
        // Generate patterns section
        content.patterns = generatePatternsWithDebug(tokens: tokens)
        
        // Generate shape section
        content.shape = generateShapeWithDebug(tokens: tokens)
        
        // Generate accessories section
        content.accessories = generateAccessoriesWithDebug(tokens: tokens)
        
        // Generate takeaway line
        content.takeaway = generateTakeawayWithDebug(tokens: tokens, moonPhase: moonPhase)
        
        return content
    }
    
    /// Generate vibe title with debugging
    private static func generateVibeTitleWithDebug(tokens: [StyleToken]) -> String {
        DebugLogger.info("Generating Daily Vibe title")
        
        // Extract dominant characteristics from tokens
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.5 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.5 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 1.5 }
        let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 1.5 }
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.5 }
        let hasEthereal = tokens.contains { $0.name == "ethereal" || $0.name == "dreamy" && $0.weight > 1.5 }
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.5 }
        let hasLayered = tokens.contains { $0.name == "layered" && $0.weight > 1.5 }
        let hasInstinctive = tokens.contains { $0.name == "instinctive" || $0.name == "intuitive" && $0.weight > 1.5 }
        
        DebugLogger.debug("Title token analysis:")
        DebugLogger.debug("  • structured: \(hasStructured)")
        DebugLogger.debug("  • fluid: \(hasFluid)")
        DebugLogger.debug("  • bold: \(hasBold)")
        DebugLogger.debug("  • subtle: \(hasSubtle)")
        DebugLogger.debug("  • earthy: \(hasEarthy)")
        DebugLogger.debug("  • ethereal: \(hasEthereal)")
        DebugLogger.debug("  • minimal: \(hasMinimal)")
        DebugLogger.debug("  • layered: \(hasLayered)")
        DebugLogger.debug("  • instinctive: \(hasInstinctive)")
        
        // First word options based on dominant tokens
        var firstWordOptions: [String] = []
        if hasEarthy { firstWordOptions.append(contentsOf: ["Cinders", "Earth", "Roots", "Soil", "Ember"]) }
        if hasEthereal { firstWordOptions.append(contentsOf: ["Mist", "Whispers", "Echoes", "Shadow", "Ghost"]) }
        if hasFluid { firstWordOptions.append(contentsOf: ["Flow", "Current", "Rivers", "Waves", "Drift"]) }
        if hasStructured { firstWordOptions.append(contentsOf: ["Structure", "Framework", "Scaffold", "Bones", "Pillars"]) }
        if hasSubtle { firstWordOptions.append(contentsOf: ["Subtle", "Quiet", "Gentle", "Soft", "Tender"]) }
        if hasBold { firstWordOptions.append(contentsOf: ["Bold", "Statement", "Command", "Presence", "Power"]) }
        if hasMinimal { firstWordOptions.append(contentsOf: ["Minimal", "Essential", "Core", "Basic", "Pure"]) }
        if hasLayered { firstWordOptions.append(contentsOf: ["Layers", "Depths", "Textured", "Woven", "Veiled"]) }
        if hasInstinctive { firstWordOptions.append(contentsOf: ["Instinct", "Intuition", "Primal", "Wild", "Raw"]) }
        
        // If no specific dominant characteristic, use general options
        if firstWordOptions.isEmpty {
            firstWordOptions = ["Resonance", "Threshold", "Echo", "Whisper", "Rhythm", "Pulse", "Thread", "Cinders", "Veil", "Shift"]
        }
        
        DebugLogger.debug("First word options: \(firstWordOptions)")
        
        // Second/third word options for the title
        let connectionWords = ["Beneath", "Within", "Beyond", "Between", "Through", "Against", "Beside", "Behind", "Under", "Above"]
        let finalWords = ["the Surface", "the Veil", "the Noise", "the Current", "the Light", "the Shadow", "the Day", "the Self", "the Moment", "the Form"]
        
        // Select words randomly with weighting based on token strength
        let firstWord = firstWordOptions.randomElement() ?? "Resonance"
        let connectionWord = connectionWords.randomElement() ?? "Beneath"
        let finalWord = finalWords.randomElement() ?? "the Surface"
        
        DebugLogger.debug("Selected title components:")
        DebugLogger.debug("  • First word: \(firstWord)")
        DebugLogger.debug("  • Connection word: \(connectionWord)")
        DebugLogger.debug("  • Final word: \(finalWord)")
        
        // Additional title options with different patterns
        let styleTitles = [
            "\(firstWord) \(connectionWord) \(finalWord)",
            "The \(firstWord) of \(finalWord)",
            "\(firstWord) and \(finalWord)",
            "\(connectionWord) \(finalWord)",
            "\(firstWord) in \(finalWord)"
        ]
        
        // Select a title format randomly
        let title = styleTitles.randomElement() ?? "Cinders Beneath the Surface"
        DebugLogger.info("Generated title: \(title)")
        
        return title
    }
    
    /// Generate main paragraph with debugging
    private static func generateMainParagraphWithDebug(tokens: [StyleToken], moonPhase: Double) -> String {
        DebugLogger.info("Generating main paragraph")
        
        // Extract dominant characteristics
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.5 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.5 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 1.5 }
        let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 1.5 }
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.5 }
        let hasDreamy = tokens.contains { $0.name == "dreamy" || $0.name == "ethereal" && $0.weight > 1.5 }
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.5 }
        let hasLayered = tokens.contains { $0.name == "layered" && $0.weight > 1.5 }
        let hasIntuitive = tokens.contains { $0.name == "intuitive" || $0.name == "instinctive" && $0.weight > 1.5 }
        
        DebugLogger.debug("Main paragraph token analysis:")
        DebugLogger.debug("  • structured: \(hasStructured)")
        DebugLogger.debug("  • fluid: \(hasFluid)")
        DebugLogger.debug("  • bold: \(hasBold)")
        DebugLogger.debug("  • subtle: \(hasSubtle)")
        DebugLogger.debug("  • earthy: \(hasEarthy)")
        DebugLogger.debug("  • dreamy: \(hasDreamy)")
        DebugLogger.debug("  • minimal: \(hasMinimal)")
        DebugLogger.debug("  • layered: \(hasLayered)")
        DebugLogger.debug("  • intuitive: \(hasIntuitive)")
        DebugLogger.debug("  • moon phase: \(moonPhase)")
        
        // Create paragraph based on dominant characteristics
        var paragraph = ""
        var sentence = ""
        
        // Opening sentence based on dominant characteristics
        if hasSubtle {
            sentence = "A quiet smoulder glows today, asking for warmth without noise, texture without spectacle. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "subtle" }, inSection: "Main Paragraph")
        } else if hasBold {
            sentence = "An electric current runs through today, asking for clarity and presence in your expression. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "bold" }, inSection: "Main Paragraph")
        } else if hasFluid {
            sentence = "A flowing current moves through today, asking you to adapt and shift with intuitive ease. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "fluid" }, inSection: "Main Paragraph")
        } else if hasStructured {
            sentence = "A grounded foundation supports today, asking for intention and purpose in your choices. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "structured" }, inSection: "Main Paragraph")
        } else if hasDreamy {
            sentence = "A misty veil surrounds today, blurring boundaries and inviting you to trust the unseen. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "dreamy" || $0.name == "ethereal" }, inSection: "Main Paragraph")
        } else {
            sentence = "A balanced energy permeates today, inviting you to find harmony between expression and restraint. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "balanced" }, inSection: "Main Paragraph")
        }
        paragraph += sentence
        
        // Middle section based on secondary characteristics
        if hasEarthy && hasIntuitive {
            sentence = "You're not meant to burn bright—just burn real. There's an undercurrent pulling you inward to dress for your inner world, not the outer gaze. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "earthy" || $0.name == "intuitive" }, inSection: "Main Paragraph")
        } else if hasLayered && hasMinimal {
            sentence = "You're meant to reveal through concealing, to speak volumes through careful restraint. Your layers should tell a story only you fully understand. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "layered" || $0.name == "minimal" }, inSection: "Main Paragraph")
        } else if hasBold && hasLayered {
            sentence = "You're meant to command attention through depth rather than flash. Build a presence that reveals itself layer by layer, each with intention. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "bold" || $0.name == "layered" }, inSection: "Main Paragraph")
        } else if hasFluid && hasIntuitive {
            sentence = "You're meant to flow with your instincts today, allowing your outer expression to mirror your inner currents. Trust the subtle shifts you feel. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "fluid" || $0.name == "intuitive" }, inSection: "Main Paragraph")
        } else {
            sentence = "You're meant to find balance between what you show and what you keep hidden. Your style today should feel like an authentic extension of your interior landscape. "
            DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "balanced" || $0.name == "authentic" }, inSection: "Main Paragraph")
        }
        paragraph += sentence
        
        // Closing guidance based on moon phase
        if moonPhase < 90.0 {
            // New Moon to First Quarter - beginnings, intentions
            sentence = "It's a day to layer comfort with mystery, to carry softness like armour, and to resist the urge to explain yourself. "
            DebugLogger.sentence(text: sentence, influencedBy: moonPhaseTokens(moonPhase), inSection: "Main Paragraph")
        } else if moonPhase < 180.0 {
            // First Quarter to Full Moon - growth, expression
            sentence = "It's a day to build presence through intention, to communicate through texture and form, and to trust your evolving intuition. "
            DebugLogger.sentence(text: sentence, influencedBy: moonPhaseTokens(moonPhase), inSection: "Main Paragraph")
        } else if moonPhase < 270.0 {
            // Full Moon to Last Quarter - culmination, visibility
            sentence = "It's a day to embody your full expression, to balance what you reveal and what you protect, and to honor your authentic presence. "
            DebugLogger.sentence(text: sentence, influencedBy: moonPhaseTokens(moonPhase), inSection: "Main Paragraph")
        } else {
            // Last Quarter to New Moon - release, introspection
            sentence = "It's a day to release what no longer serves, to simplify your expression to its essence, and to prepare for new cycles of creativity. "
            DebugLogger.sentence(text: sentence, influencedBy: moonPhaseTokens(moonPhase), inSection: "Main Paragraph")
        }
        paragraph += sentence
        
        // Final unifying statement
        sentence = "What matters is how it feels, not how it looks from the outside. Trust the flicker in your gut."
        DebugLogger.sentence(text: sentence, influencedBy: tokens.filter { $0.name == "intuitive" || $0.name == "authentic" }, inSection: "Main Paragraph")
        paragraph += sentence
        
        DebugLogger.info("Generated main paragraph with \(paragraph.count) characters")
        return paragraph
    }
    
    /// Create moon phase tokens for debugging
    private static func moonPhaseTokens(_ phase: Double) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        if phase < 45.0 {
            tokens.append(StyleToken(name: "new", type: "moon phase", weight: 2.0, aspectSource: "New Moon"))
            tokens.append(StyleToken(name: "beginning", type: "moon phase", weight: 1.8, aspectSource: "New Moon"))
        } else if phase < 90.0 {
            tokens.append(StyleToken(name: "waxing crescent", type: "moon phase", weight: 2.0, aspectSource: "Waxing Crescent"))
            tokens.append(StyleToken(name: "growing", type: "moon phase", weight: 1.8, aspectSource: "Waxing Crescent"))
        } else if phase < 135.0 {
            tokens.append(StyleToken(name: "first quarter", type: "moon phase", weight: 2.0, aspectSource: "First Quarter"))
            tokens.append(StyleToken(name: "building", type: "moon phase", weight: 1.8, aspectSource: "First Quarter"))
        } else if phase < 180.0 {
            tokens.append(StyleToken(name: "waxing gibbous", type: "moon phase", weight: 2.0, aspectSource: "Waxing Gibbous"))
            tokens.append(StyleToken(name: "culminating", type: "moon phase", weight: 1.8, aspectSource: "Waxing Gibbous"))
        } else if phase < 225.0 {
            tokens.append(StyleToken(name: "full", type: "moon phase", weight: 2.0, aspectSource: "Full Moon"))
            tokens.append(StyleToken(name: "illuminated", type: "moon phase", weight: 1.8, aspectSource: "Full Moon"))
        } else if phase < 270.0 {
            tokens.append(StyleToken(name: "waning gibbous", type: "moon phase", weight: 2.0, aspectSource: "Waning Gibbous"))
            tokens.append(StyleToken(name: "releasing", type: "moon phase", weight: 1.8, aspectSource: "Waning Gibbous"))
        } else if phase < 315.0 {
            tokens.append(StyleToken(name: "last quarter", type: "moon phase", weight: 2.0, aspectSource: "Last Quarter"))
            tokens.append(StyleToken(name: "resolving", type: "moon phase", weight: 1.8, aspectSource: "Last Quarter"))
        } else {
            tokens.append(StyleToken(name: "waning crescent", type: "moon phase", weight: 2.0, aspectSource: "Waning Crescent"))
            tokens.append(StyleToken(name: "surrendering", type: "moon phase", weight: 1.8, aspectSource: "Waning Crescent"))
        }
        
        return tokens
    }
    
    // Implement debug versions of other section generators following the same pattern
    // Each should include detailed logging about the tokens that influence the text generated
    
    /// Generate textiles section with debugging
    private static func generateTextilesWithDebug(tokens: [StyleToken]) -> String {
        DebugLogger.info("Generating textiles section")
        
        // Implementation would follow similar pattern to the above methods
        // For brevity, I'm not including the full implementation of every section
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.generateTextiles(tokens: tokens)
        DebugLogger.paragraphAssembly(sectionName: "Textiles", paragraphText: result, tokens: filterTokensForTextiles(tokens))
        return result
    }
    
    /// Generate colors section with debugging
    private static func generateColorsWithDebug(tokens: [StyleToken]) -> String {
        DebugLogger.info("Generating colors section")
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.generateColors(tokens: tokens)
        DebugLogger.paragraphAssembly(sectionName: "Colors", paragraphText: result, tokens: filterTokensForColors(tokens))
        return result
    }
    
    /// Calculate brightness with debugging
    private static func calculateBrightnessWithDebug(tokens: [StyleToken], moonPhase: Double) -> Int {
        DebugLogger.info("Calculating brightness value")
        
        // Start with a base value
        var brightnessValue = 50
        DebugLogger.debug("Starting brightness value: 50")
        
        // Adjust based on tokens
        if tokens.contains(where: { $0.name == "dark" && $0.weight > 1.5 }) {
            brightnessValue -= 20
            DebugLogger.debug("Adjusting for 'dark' token: -20")
        }
        if tokens.contains(where: { $0.name == "deep" && $0.weight > 1.5 }) {
            brightnessValue -= 15
            DebugLogger.debug("Adjusting for 'deep' token: -15")
        }
        if tokens.contains(where: { $0.name == "muted" && $0.weight > 1.5 }) {
            brightnessValue -= 10
            DebugLogger.debug("Adjusting for 'muted' token: -10")
        }
        if tokens.contains(where: { $0.name == "intense" && $0.weight > 1.5 }) {
            brightnessValue -= 10
            DebugLogger.debug("Adjusting for 'intense' token: -10")
        }
        
        if tokens.contains(where: { $0.name == "light" && $0.weight > 1.5 }) {
            brightnessValue += 20
            DebugLogger.debug("Adjusting for 'light' token: +20")
        }
        if tokens.contains(where: { $0.name == "bright" && $0.weight > 1.5 }) {
            brightnessValue += 15
            DebugLogger.debug("Adjusting for 'bright' token: +15")
        }
        if tokens.contains(where: { $0.name == "clear" && $0.weight > 1.5 }) {
            brightnessValue += 10
            DebugLogger.debug("Adjusting for 'clear' token: +10")
        }
        if tokens.contains(where: { $0.name == "illuminated" && $0.weight > 1.5 }) {
            brightnessValue += 10
            DebugLogger.debug("Adjusting for 'illuminated' token: +10")
        }
        
        // Adjust based on moon phase (new moon = darker, full moon = brighter)
        DebugLogger.debug("Moon phase: \(String(format: "%.2f", moonPhase))")
        if moonPhase < 90.0 {
            brightnessValue -= 10 // New Moon to First Quarter
            DebugLogger.debug("Adjusting for New Moon to First Quarter: -10")
        } else if moonPhase < 180.0 {
            brightnessValue += 5 // First Quarter to Full Moon
            DebugLogger.debug("Adjusting for First Quarter to Full Moon: +5")
        } else if moonPhase < 270.0 {
            brightnessValue += 10 // Full Moon to Last Quarter
            DebugLogger.debug("Adjusting for Full Moon to Last Quarter: +10")
        } else {
            brightnessValue -= 5 // Last Quarter to New Moon
            DebugLogger.debug("Adjusting for Last Quarter to New Moon: -5")
        }
        
        // Ensure value is within 0-100 range
        brightnessValue = max(0, min(100, brightnessValue))
        
        DebugLogger.info("Final brightness value: \(brightnessValue)")
        return brightnessValue
    }
    
    /// Calculate vibrancy with debugging
    private static func calculateVibrancyWithDebug(tokens: [StyleToken]) -> Int {
        // Implementation would follow similar pattern to calculateBrightnessWithDebug
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.calculateVibrancy(tokens: tokens)
        DebugLogger.debug("Calculated vibrancy value: \(result)")
        return result
    }
    
    /// Generate patterns section with debugging
    private static func generatePatternsWithDebug(tokens: [StyleToken]) -> String {
        // Implementation would follow similar pattern
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.generatePatterns(tokens: tokens)
        DebugLogger.paragraphAssembly(sectionName: "Patterns", paragraphText: result, tokens: filterTokensForPatterns(tokens))
        return result
    }
    
    /// Generate shape section with debugging
    private static func generateShapeWithDebug(tokens: [StyleToken]) -> String {
        // Implementation would follow similar pattern
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.generateShape(tokens: tokens)
        DebugLogger.paragraphAssembly(sectionName: "Shape", paragraphText: result, tokens: filterTokensForShape(tokens))
        return result
    }
    
    /// Generate accessories section with debugging
    private static func generateAccessoriesWithDebug(tokens: [StyleToken]) -> String {
        // Implementation would follow similar pattern
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.generateAccessories(tokens: tokens)
        DebugLogger.paragraphAssembly(sectionName: "Accessories", paragraphText: result, tokens: filterTokensForAccessories(tokens))
        return result
    }
    
    /// Generate takeaway with debugging
    private static func generateTakeawayWithDebug(tokens: [StyleToken], moonPhase: Double) -> String {
        DebugLogger.info("Generating takeaway")
        
        // Using the regular DailyVibeGenerator implementation
        let result = DailyVibeGenerator.generateTakeaway(tokens: tokens, moonPhase: moonPhase)
        DebugLogger.paragraphAssembly(sectionName: "Takeaway", paragraphText: result, tokens: filterTokensForTakeaway(tokens))
        return result
    }
    
    // MARK: - Token Filtering for Sections
    
    // Helper methods to filter tokens relevant to specific sections for better debugging
    
    private static func filterTokensForTextiles(_ tokens: [StyleToken]) -> [StyleToken] {
        return tokens.filter {
            $0.type == "texture" || $0.type == "fabric" ||
            $0.name.contains("soft") || $0.name.contains("structured") ||
            $0.name.contains("fluid") || $0.name.contains("layered") ||
            $0.name.contains("earthy") || $0.name.contains("luxurious")
        }
    }
    
    private static func filterTokensForColors(_ tokens: [StyleToken]) -> [StyleToken] {
        return tokens.filter {
            $0.type == "color" || $0.type == "element" ||
            $0.name.contains("earthy") || $0.name.contains("watery") ||
            $0.name.contains("airy") || $0.name.contains("fiery") ||
            $0.name.contains("dark") || $0.name.contains("light") ||
            $0.name.contains("muted") || $0.name.contains("vibrant")
        }
    }
    
    private static func filterTokensForPatterns(_ tokens: [StyleToken]) -> [StyleToken] {
        return tokens.filter {
            $0.type == "texture" || $0.type == "structure" ||
            $0.name.contains("minimal") || $0.name.contains("textured") ||
            $0.name.contains("expressive") || $0.name.contains("structured") ||
            $0.name.contains("fluid") || $0.name.contains("subtle") ||
            $0.name.contains("eclectic")
        }
    }
    
    private static func filterTokensForShape(_ tokens: [StyleToken]) -> [StyleToken] {
        return tokens.filter {
            $0.type == "structure" ||
            $0.name.contains("structured") || $0.name.contains("fluid") ||
            $0.name.contains("layered") || $0.name.contains("minimal") ||
            $0.name.contains("expressive") || $0.name.contains("balanced") ||
            $0.name.contains("protective")
        }
    }
    
    private static func filterTokensForAccessories(_ tokens: [StyleToken]) -> [StyleToken] {
        return tokens.filter {
            $0.type == "structure" || $0.type == "expression" ||
            $0.name.contains("minimal") || $0.name.contains("expressive") ||
            $0.name.contains("protective") || $0.name.contains("eclectic") ||
            $0.name.contains("structured") || $0.name.contains("earthy") ||
            $0.name.contains("watery")
        }
    }
    
    private static func filterTokensForTakeaway(_ tokens: [StyleToken]) -> [StyleToken] {
        // For takeaway, focus on higher-level tokens and moon phase
        return tokens.filter {
            $0.weight > 1.8 || $0.type == "moon phase" ||
            $0.name.contains("authentic") || $0.name.contains("intuitive") ||
            $0.name.contains("balanced") || $0.name.contains("expressive")
        }
    }
}
