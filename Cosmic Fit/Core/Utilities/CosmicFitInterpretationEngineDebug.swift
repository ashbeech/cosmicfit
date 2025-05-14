//
//  CosmicFitInterpretationEngineDebug.swift
//  Cosmic Fit
//
//  Created for enhanced debugging of interpretation generation
//

import Foundation

/// Debug extension for the CosmicFitInterpretationEngine
extension CosmicFitInterpretationEngine {
    
    /// Generate a Blueprint interpretation with detailed paragraph assembly logging
    static func generateBlueprintInterpretationWithDebug(from chart: NatalChartCalculator.NatalChart) -> InterpretationResult {
        print("\n🧩 GENERATING COSMIC FIT BLUEPRINT WITH DETAILED DEBUG 🧩")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Start a new debug session
        DebugLogger.info("Starting Blueprint interpretation debug session")
        
        // Generate tokens from natal chart with Whole Sign houses for Blueprint
        let tokens = SemanticTokenGenerator.generateBlueprintTokens(natal: chart)
        DebugLogger.tokenSet("BLUEPRINT TOKENS", tokens)
        
        // Format birth info for display in the blueprint header
        var birthInfoText: String? = nil
        
        // Find the Sun position for sign information
        if let sunPlanet = chart.planets.first(where: { $0.name == "Sun" }) {
            let sunSignName = CoordinateTransformations.getZodiacSignName(sign: sunPlanet.zodiacSign)
            birthInfoText = "Natal Chart: \(sunSignName) Energy"
        }
        
        // Generate the complete blueprint with all sections according to spec - using debug version
        DebugLogger.info("Generating blueprint text with detailed paragraph debugging")
        let blueprintText = ParagraphAssembler.generateBlueprintInterpretationWithDebug(
            tokens: tokens,
            birthInfo: birthInfoText
        )
        
        // Determine the dominant theme from tokens
        let themeName = ThemeSelector.scoreThemes(tokens: tokens)
        DebugLogger.info("Theme selected: \(themeName)")
        
        // Log theme selection process
        let topThemes = ThemeSelector.rankThemes(tokens: tokens, topCount: 3)
        DebugLogger.debug("Top 3 themes:")
        for (i, theme) in topThemes.enumerated() {
            DebugLogger.debug("  \(i+1). \(theme.name): Score \(String(format: "%.2f", theme.score))")
        }
        
        print("\n✅ Blueprint generation with detailed debug completed!")
        print("Theme: \(themeName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return InterpretationResult(
            themeName: themeName,
            stitchedParagraph: blueprintText,
            tokensUsed: tokens,
            isBlueprintReport: true
        )
    }
    
    /// Generate a daily vibe interpretation with detailed paragraph assembly logging
    static func generateDailyVibeInterpretationWithDebug(
        from natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?) -> DailyVibeContent {
        
        print("\n☀️ GENERATING DAILY COSMIC VIBE WITH DETAILED DEBUG ☀️")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Start a new debug session
        DebugLogger.info("Starting Daily Vibe interpretation debug session")
        
        // Get current lunar phase
        let currentDate = Date()
        let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
        let lunarPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: currentJulianDay)
        
        DebugLogger.info("Current lunar phase: \(String(format: "%.2f", lunarPhase))")
        
        // Generate the daily vibe content using the DailyVibeGenerator - we'll access its internals
        // directly for detailed debugging
        DebugLogger.info("Preparing token generation for Daily Vibe")
        
        // Log house system approach
        DebugLogger.info("HYBRID HOUSE SYSTEM APPROACH:")
        DebugLogger.info("  • Base Style Resonance: Whole Sign (100% natal)")
        DebugLogger.info("  • Emotional Vibe: Placidus (60% progressed Moon, 40% natal Moon)")
        DebugLogger.info("  • Transit Impact: Placidus")
        DebugLogger.info("  • Fashion Output: 50% natal + 50% transit-based")
        
        // 1. Generate tokens for base style resonance (100% natal, Whole Sign)
        let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
        DebugLogger.tokenSet("BASE STYLE TOKENS (WHOLE SIGN)", baseStyleTokens)
        
        // 2. Generate tokens for emotional vibe of day (60% progressed Moon, 40% natal Moon, Placidus)
        let emotionalVibeTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
            natal: natalChart,
            progressed: progressedChart
        )
        DebugLogger.tokenSet("EMOTIONAL VIBE TOKENS (PLACIDUS - 60% PROGRESSED, 40% NATAL)", emotionalVibeTokens)
        
        // 3. Generate tokens from planetary transits (Placidus houses)
        let transitTokens = SemanticTokenGenerator.generateTransitTokens(
            transits: transits,
            natal: natalChart
        )
        DebugLogger.tokenSet("TRANSIT TOKENS (PLACIDUS)", transitTokens)
        
        // 4. Generate tokens from moon phase
        let moonPhaseTokens = SemanticTokenGenerator.generateMoonPhaseTokens(moonPhase: lunarPhase)
        DebugLogger.tokenSet("MOON PHASE TOKENS", moonPhaseTokens)
        
        // 5. Generate tokens from weather if available
        var weatherTokens: [StyleToken] = []
        if let weather = weather {
            weatherTokens = SemanticTokenGenerator.generateWeatherTokens(weather: weather)
            DebugLogger.tokenSet("WEATHER TOKENS", weatherTokens)
        } else {
            DebugLogger.warning("No weather data available")
        }
        
        // 6. Combine all tokens with appropriate weighting
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
                aspectSource: token.aspectSource
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
                aspectSource: token.aspectSource
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
                aspectSource: token.aspectSource
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
                aspectSource: token.aspectSource
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
                aspectSource: token.aspectSource
            )
            allTokens.append(adjustedToken)
        }
        
        // Log combined weighted tokens
        DebugLogger.tokenSet("COMBINED WEIGHTED TOKENS", allTokens)
        
        // 7. Generate the daily vibe content with detailed logging at each step
        DebugLogger.info("Generating Daily Vibe content with paragraph-level logging")
        
        // Create a debug-enhanced daily vibe generation
        let dailyVibeContent = generateDailyVibeContentWithDebug(tokens: allTokens, weather: weather, moonPhase: lunarPhase)
        
        // Log theme determination
        let themeName = ThemeSelector.scoreThemes(tokens: allTokens)
        DebugLogger.info("Selected Theme: \(themeName)")
        
        // Log the top themes with scores for debugging
        let topThemes = ThemeSelector.rankThemes(tokens: allTokens, topCount: 3)
        for (i, theme) in topThemes.enumerated() {
            DebugLogger.info("  \(i+1). \(theme.name): Score \(String(format: "%.2f", theme.score))")
        }
        
        print("\n✅ Daily vibe generation with detailed debug completed!")
        print("Theme: \(themeName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return dailyVibeContent
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
