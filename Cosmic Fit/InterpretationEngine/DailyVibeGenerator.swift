//
//  DailyVibeGenerator.swift
//  Cosmic Fit
//
//  Created for Daily Vibe implementation
//

import Foundation

class DailyVibeGenerator {
    
    // MARK: - Public Methods
    
    /// Generate a complete daily vibe interpretation
    /// - Parameters:
    ///   - natalChart: The natal chart (for base style resonance using Whole Sign)
    ///   - progressedChart: The progressed chart (for emotional vibe using Placidus)
    ///   - transits: Array of transit aspects to natal chart
    ///   - weather: Optional current weather conditions
    ///   - moonPhase: Current lunar phase (0-360)
    /// - Returns: A formatted daily vibe interpretation
    static func generateDailyVibe(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        moonPhase: Double) -> DailyVibeContent {
        
        print("\n☀️ GENERATING DAILY COSMIC VIBE ☀️")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🧩 USING HYBRID HOUSE SYSTEM APPROACH:")
        print("  • Base Style Resonance: Whole Sign (100% natal)")
        print("  • Emotional Vibe: Placidus (60% progressed Moon, 40% natal Moon)")
        print("  • Transit Impact: Placidus")
        print("  • Fashion Output: 50% natal + 50% transit-based")
        
        // 1. Generate tokens for base style resonance (100% natal, Whole Sign)
        let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
        logTokenSet("BASE STYLE TOKENS (WHOLE SIGN)", baseStyleTokens)
        
        // 2. Generate tokens for emotional vibe of day (60% progressed Moon, 40% natal Moon, Placidus)
        let emotionalVibeTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
            natal: natalChart,
            progressed: progressedChart
        )
        logTokenSet("EMOTIONAL VIBE TOKENS (PLACIDUS - 60% PROGRESSED, 40% NATAL)", emotionalVibeTokens)
        
        // 3. Generate tokens from planetary transits (Placidus houses)
        let transitTokens = SemanticTokenGenerator.generateTransitTokens(
            transits: transits,
            natal: natalChart
        )
        logTokenSet("TRANSIT TOKENS (PLACIDUS)", transitTokens)
        
        // 4. Generate tokens from moon phase
        let moonPhaseTokens = SemanticTokenGenerator.generateMoonPhaseTokens(moonPhase: moonPhase)
        logTokenSet("MOON PHASE TOKENS", moonPhaseTokens)
        
        // 5. Generate tokens from weather if available
        var weatherTokens: [StyleToken] = []
        if let weather = weather {
            weatherTokens = SemanticTokenGenerator.generateWeatherTokens(weather: weather)
            logTokenSet("WEATHER TOKENS", weatherTokens)
        } else {
            print("❗️ No weather data available")
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
        logTokenSet("COMBINED WEIGHTED TOKENS", allTokens)
        
        // 7. Generate the daily vibe content
        let dailyVibeContent = generateDailyVibeContent(tokens: allTokens, weather: weather, moonPhase: moonPhase)
        
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
    
    // MARK: - New Daily Vibe Content Generation
    
    /// Generate structured daily vibe content according to the specified format
    static func generateDailyVibeContent(tokens: [StyleToken], weather: TodayWeather?, moonPhase: Double) -> DailyVibeContent {
        // Create content object
        var content = DailyVibeContent()
        
        // Generate title
        content.title = generateVibeTitle(tokens: tokens)
        
        // Generate main paragraph
        content.mainParagraph = generateMainParagraph(tokens: tokens, moonPhase: moonPhase)
        
        // Generate textiles section
        content.textiles = generateTextiles(tokens: tokens)
        
        // Generate colors section
        content.colors = generateColors(tokens: tokens)
        
        // Calculate brightness and vibrancy values
        content.brightness = calculateBrightness(tokens: tokens, moonPhase: moonPhase)
        content.vibrancy = calculateVibrancy(tokens: tokens)
        
        // Generate patterns section
        content.patterns = generatePatterns(tokens: tokens)
        
        // Generate shape section
        content.shape = generateShape(tokens: tokens)
        
        // Generate accessories section
        content.accessories = generateAccessories(tokens: tokens)
        
        // Generate takeaway line
        content.takeaway = generateTakeaway(tokens: tokens, moonPhase: moonPhase)
        
        return content
    }
    
    /// Generate a poetic title for the daily vibe
    private static func generateVibeTitle(tokens: [StyleToken]) -> String {
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
        
        // Second/third word options for the title
        let connectionWords = ["Beneath", "Within", "Beyond", "Between", "Through", "Against", "Beside", "Behind", "Under", "Above"]
        let finalWords = ["the Surface", "the Veil", "the Noise", "the Current", "the Light", "the Shadow", "the Day", "the Self", "the Moment", "the Form"]
        
        // Select words randomly with weighting based on token strength
        let firstWord = firstWordOptions.randomElement() ?? "Resonance"
        let connectionWord = connectionWords.randomElement() ?? "Beneath"
        let finalWord = finalWords.randomElement() ?? "the Surface"
        
        // Additional title options with different patterns
        let styleTitles = [
            "\(firstWord) \(connectionWord) \(finalWord)",
            "The \(firstWord) of \(finalWord)",
            "\(firstWord) and \(finalWord)",
            "\(connectionWord) \(finalWord)",
            "\(firstWord) in \(finalWord)"
        ]
        
        // Select a title format randomly
        return styleTitles.randomElement() ?? "Cinders Beneath the Surface"
    }
    
    /// Generate the main paragraph describing the overall vibe
    private static func generateMainParagraph(tokens: [StyleToken], moonPhase: Double) -> String {
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
        
        // Create paragraph based on dominant characteristics
        var paragraph = ""
        
        // Opening sentence based on dominant characteristics
        if hasSubtle {
            paragraph += "A quiet smoulder glows today, asking for warmth without noise, texture without spectacle. "
        } else if hasBold {
            paragraph += "An electric current runs through today, asking for clarity and presence in your expression. "
        } else if hasFluid {
            paragraph += "A flowing current moves through today, asking you to adapt and shift with intuitive ease. "
        } else if hasStructured {
            paragraph += "A grounded foundation supports today, asking for intention and purpose in your choices. "
        } else if hasDreamy {
            paragraph += "A misty veil surrounds today, blurring boundaries and inviting you to trust the unseen. "
        } else {
            paragraph += "A balanced energy permeates today, inviting you to find harmony between expression and restraint. "
        }
        
        // Middle section based on secondary characteristics
        if hasEarthy && hasIntuitive {
            paragraph += "You're not meant to burn bright—just burn real. There's an undercurrent pulling you inward to dress for your inner world, not the outer gaze. "
        } else if hasLayered && hasMinimal {
            paragraph += "You're meant to reveal through concealing, to speak volumes through careful restraint. Your layers should tell a story only you fully understand. "
        } else if hasBold && hasLayered {
            paragraph += "You're meant to command attention through depth rather than flash. Build a presence that reveals itself layer by layer, each with intention. "
        } else if hasFluid && hasIntuitive {
            paragraph += "You're meant to flow with your instincts today, allowing your outer expression to mirror your inner currents. Trust the subtle shifts you feel. "
        } else {
            paragraph += "You're meant to find balance between what you show and what you keep hidden. Your style today should feel like an authentic extension of your interior landscape. "
        }
        
        // Closing guidance based on moon phase
        if moonPhase < 90.0 {
            // New Moon to First Quarter - beginnings, intentions
            paragraph += "It's a day to layer comfort with mystery, to carry softness like armour, and to resist the urge to explain yourself. "
        } else if moonPhase < 180.0 {
            // First Quarter to Full Moon - growth, expression
            paragraph += "It's a day to build presence through intention, to communicate through texture and form, and to trust your evolving intuition. "
        } else if moonPhase < 270.0 {
            // Full Moon to Last Quarter - culmination, visibility
            paragraph += "It's a day to embody your full expression, to balance what you reveal and what you protect, and to honor your authentic presence. "
        } else {
            // Last Quarter to New Moon - release, introspection
            paragraph += "It's a day to release what no longer serves, to simplify your expression to its essence, and to prepare for new cycles of creativity. "
        }
        
        // Final unifying statement
        paragraph += "What matters is how it feels, not how it looks from the outside. Trust the flicker in your gut."
        
        return paragraph
    }
    
    /// Generate textiles recommendations
    static func generateTextiles(tokens: [StyleToken]) -> String {
        // Extract relevant characteristics for fabric recommendations
        let hasSoft = tokens.contains { $0.name == "soft" && $0.weight > 1.0 }
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.0 }
        let hasTextured = tokens.contains { $0.name == "textured" && $0.weight > 1.0 }
        let hasLayered = tokens.contains { $0.name == "layered" && $0.weight > 1.0 }
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.0 }
        let hasLuxurious = tokens.contains { $0.name == "luxurious" && $0.weight > 1.0 }
        
        // Fabric options based on characteristics
        var fabricOptions: [String] = []
        
        if hasSoft {
            fabricOptions.append(contentsOf: ["brushed cotton", "cashmere", "velvet", "mohair", "silk", "flannel"])
        }
        
        if hasStructured {
            fabricOptions.append(contentsOf: ["denim", "wool gabardine", "canvas", "heavyweight cotton", "leather", "suede"])
        }
        
        if hasFluid {
            fabricOptions.append(contentsOf: ["silk", "lyocell", "matte satin", "modal", "fluid jersey", "lightweight wool"])
        }
        
        if hasTextured {
            fabricOptions.append(contentsOf: ["tweed", "bouclé", "corduroy", "raw silk", "nubby linen", "textured knits"])
        }
        
        if hasLayered {
            fabricOptions.append(contentsOf: ["layered jersey", "tissue-weight cotton", "fine wool", "lightweight layers"])
        }
        
        if hasEarthy {
            fabricOptions.append(contentsOf: ["washed leather", "stonewashed cotton", "linen", "hemp", "raw denim"])
        }
        
        if hasLuxurious {
            fabricOptions.append(contentsOf: ["fine wool", "silk velvet", "cashmere", "merino", "high-quality leather"])
        }
        
        // If not enough specific fabrics, add some general options
        if fabricOptions.count < 3 {
            fabricOptions.append(contentsOf: ["cotton blends", "jersey", "wool", "linen", "denim"])
        }
        
        // Randomly select 4-6 fabric options
        let shuffledFabrics = fabricOptions.shuffled()
        let selectedCount = min(shuffledFabrics.count, Int.random(in: 4...6))
        let selectedFabrics = shuffledFabrics.prefix(selectedCount)
        
        // Create the fabric description
        var description = selectedFabrics.joined(separator: ", ")
        
        // Add a descriptive second sentence
        if hasSoft && hasTextured {
            description += "—anything that feels like second skin with a touch of shadow. Choose tactile layers that soften the wind but hold your power close."
        } else if hasStructured && hasEarthy {
            description += "—anything with substance and character. Choose materials with presence that ground you while letting you move with intention."
        } else if hasFluid && hasLayered {
            description += "—anything that flows and adapts to your movement. Choose fabrics that create dimension through layering rather than weight."
        } else if hasLuxurious {
            description += "—anything that elevates through quality rather than flash. Choose materials that feel transformative against your skin."
        } else {
            description += "—anything that resonates with your body's needs today. Choose fabrics that support rather than distract from your presence."
        }
        
        return description
    }
    
    /// Generate color recommendations
    static func generateColors(tokens: [StyleToken]) -> String {
        // Extract relevant characteristics for color recommendations
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.0 }
        let hasWatery = tokens.contains { $0.name == "watery" || $0.name == "fluid" && $0.weight > 1.0 }
        let hasAiry = tokens.contains { $0.name == "airy" && $0.weight > 1.0 }
        let hasFiery = tokens.contains { $0.name == "fiery" || $0.name == "passionate" && $0.weight > 1.0 }
        let hasDark = tokens.contains { $0.name == "deep" || $0.name == "intense" && $0.weight > 1.0 }
        let hasLight = tokens.contains { $0.name == "light" || $0.name == "bright" && $0.weight > 1.0 }
        let hasMuted = tokens.contains { $0.name == "muted" || $0.name == "subtle" && $0.weight > 1.0 }
        let hasVibrant = tokens.contains { $0.name == "vibrant" || $0.name == "bold" && $0.weight > 1.0 }
        
        // Color options based on characteristics
        var colorOptions: [String] = []
        
        if hasEarthy {
            colorOptions.append(contentsOf: ["olive", "terracotta", "moss", "ochre", "walnut", "sand", "umber"])
        }
        
        if hasWatery {
            colorOptions.append(contentsOf: ["navy ink", "teal", "indigo", "slate blue", "stormy gray", "deep aqua"])
        }
        
        if hasAiry {
            colorOptions.append(contentsOf: ["pale blue", "silver gray", "cloud white", "light lavender", "sky"])
        }
        
        if hasFiery {
            colorOptions.append(contentsOf: ["oxblood", "rust", "amber", "burnt orange", "burgundy", "ruby"])
        }
        
        if hasDark {
            colorOptions.append(contentsOf: ["coal", "espresso", "midnight blue", "deep forest", "smoky plum", "charcoal"])
        }
        
        if hasLight {
            colorOptions.append(contentsOf: ["ivory", "bone", "pearl", "light gray", "soft white", "pale gold"])
        }
        
        if hasMuted {
            colorOptions.append(contentsOf: ["faded indigo", "dove gray", "dusty rose", "sage", "muted mauve", "ash grey"])
        }
        
        if hasVibrant {
            colorOptions.append(contentsOf: ["electric blue", "emerald", "crimson", "royal purple", "bright mustard"])
        }
        
        // If not enough specific colors, add some neutral options
        if colorOptions.count < 3 {
            colorOptions.append(contentsOf: ["navy", "charcoal", "ivory", "taupe", "black", "gray"])
        }
        
        // Randomly select 5-7 color options
        let shuffledColors = colorOptions.shuffled()
        let selectedCount = min(shuffledColors.count, Int.random(in: 5...7))
        let selectedColors = shuffledColors.prefix(selectedCount)
        
        // Create the color description
        var description = selectedColors.joined(separator: ", ")
        
        // Add a descriptive closing phrase
        if hasDark || hasMuted {
            description += ". Let them absorb the light, not reflect it"
        } else if hasLight || hasAiry {
            description += ". Let them diffuse the light with subtle presence"
        } else if hasVibrant || hasFiery {
            description += ". Let them express your energy with intention"
        } else {
            description += ". Let them ground and center your presence today"
        }
        
        return description
    }
    
    /// Calculate brightness percentage based on tokens
    private static func calculateBrightness(tokens: [StyleToken], moonPhase: Double) -> Int {
        // Start with a base value
        var brightnessValue = 50
        
        // Adjust based on tokens
        if tokens.contains(where: { $0.name == "dark" && $0.weight > 1.5 }) { brightnessValue -= 20 }
        if tokens.contains(where: { $0.name == "deep" && $0.weight > 1.5 }) { brightnessValue -= 15 }
        if tokens.contains(where: { $0.name == "muted" && $0.weight > 1.5 }) { brightnessValue -= 10 }
        if tokens.contains(where: { $0.name == "intense" && $0.weight > 1.5 }) { brightnessValue -= 10 }
        
        if tokens.contains(where: { $0.name == "light" && $0.weight > 1.5 }) { brightnessValue += 20 }
        if tokens.contains(where: { $0.name == "bright" && $0.weight > 1.5 }) { brightnessValue += 15 }
        if tokens.contains(where: { $0.name == "clear" && $0.weight > 1.5 }) { brightnessValue += 10 }
        if tokens.contains(where: { $0.name == "illuminated" && $0.weight > 1.5 }) { brightnessValue += 10 }
        
        // Adjust based on moon phase (new moon = darker, full moon = brighter)
        if moonPhase < 90.0 {
            brightnessValue -= 10 // New Moon to First Quarter
        } else if moonPhase < 180.0 {
            brightnessValue += 5 // First Quarter to Full Moon
        } else if moonPhase < 270.0 {
            brightnessValue += 10 // Full Moon to Last Quarter
        } else {
            brightnessValue -= 5 // Last Quarter to New Moon
        }
        
        // Ensure value is within 0-100 range
        brightnessValue = max(0, min(100, brightnessValue))
        
        return brightnessValue
    }
    
    /// Calculate vibrancy percentage based on tokens
    static func calculateVibrancy(tokens: [StyleToken]) -> Int {
        // Start with a base value
        var vibrancyValue = 50
        
        // Adjust based on tokens
        if tokens.contains(where: { $0.name == "vibrant" && $0.weight > 1.5 }) { vibrancyValue += 25 }
        if tokens.contains(where: { $0.name == "bold" && $0.weight > 1.5 }) { vibrancyValue += 20 }
        if tokens.contains(where: { $0.name == "expressive" && $0.weight > 1.5 }) { vibrancyValue += 15 }
        if tokens.contains(where: { $0.name == "dynamic" && $0.weight > 1.5 }) { vibrancyValue += 10 }
        
        if tokens.contains(where: { $0.name == "muted" && $0.weight > 1.5 }) { vibrancyValue -= 20 }
        if tokens.contains(where: { $0.name == "subtle" && $0.weight > 1.5 }) { vibrancyValue -= 15 }
        if tokens.contains(where: { $0.name == "minimal" && $0.weight > 1.5 }) { vibrancyValue -= 10 }
        if tokens.contains(where: { $0.name == "quiet" && $0.weight > 1.5 }) { vibrancyValue -= 10 }
        
        // Adjust based on elemental prevalence
        if tokens.contains(where: { $0.name == "fiery" && $0.weight > 1.5 }) { vibrancyValue += 15 }
        if tokens.contains(where: { $0.name == "watery" && $0.weight > 1.5 }) { vibrancyValue += 5 }
        if tokens.contains(where: { $0.name == "earthy" && $0.weight > 1.5 }) { vibrancyValue -= 10 }
        if tokens.contains(where: { $0.name == "airy" && $0.weight > 1.5 }) { vibrancyValue -= 5 }
        
        // Ensure value is within 0-100 range
        vibrancyValue = max(0, min(100, vibrancyValue))
        
        return vibrancyValue
    }
    
    /// Generate pattern recommendations
    static func generatePatterns(tokens: [StyleToken]) -> String {
        // Extract relevant characteristics for pattern recommendations
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.0 }
        let hasTextured = tokens.contains { $0.name == "textured" && $0.weight > 1.0 }
        let hasExpressive = tokens.contains { $0.name == "expressive" || $0.name == "bold" && $0.weight > 1.0 }
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.0 }
        let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 1.0 }
        let hasEclectic = tokens.contains { $0.name == "eclectic" || $0.name == "unique" && $0.weight > 1.0 }
        
        // Pattern suggestions based on characteristics
        var patterns = ""
        
        if hasMinimal && hasTextured {
            patterns = "Uneven dye effects (stonewash, acid, mineral). Minimal prints that feel faded or lived-in—nothing polished or loud."
        } else if hasExpressive && hasEclectic {
            patterns = "Bold geometrics, unexpected color combinations, statement prints. Patterns that tell a story or reference art—each with a clear point of view."
        } else if hasStructured && hasMinimal {
            patterns = "Architectural lines, subtle grids, precision pinstripes. Patterns with mathematical order rather than organic flow."
        } else if hasFluid && hasExpressive {
            patterns = "Watercolor effects, organic forms, nature-inspired motifs. Patterns that move and flow with a sense of natural rhythm."
        } else if hasSubtle {
            patterns = "Barely-there textures, monochromatic tone-on-tone, shadow effects. Patterns that reveal themselves only upon closer inspection."
        } else if hasEclectic {
            patterns = "Unexpected combinations, vintage-inspired motifs, cultural references. Mix patterns of different scales for a curated eclectic approach."
        } else {
            patterns = "Balanced, intentional patterns that enhance rather than overwhelm. Choose prints that feel authentic to your energy today."
        }
        
        return patterns
    }
    
    /// Generate shape recommendations
    static func generateShape(tokens: [StyleToken]) -> String {
        // Extract relevant characteristics for shape recommendations
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.0 }
        let hasLayered = tokens.contains { $0.name == "layered" && $0.weight > 1.0 }
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.0 }
        let hasExpressive = tokens.contains { $0.name == "expressive" || $0.name == "bold" && $0.weight > 1.0 }
        let hasBalanced = tokens.contains { $0.name == "balanced" && $0.weight > 1.0 }
        let hasProtective = tokens.contains { $0.name == "protective" && $0.weight > 1.0 }
        
        // Shape description based on characteristics
        var shape = ""
        
        if hasStructured && hasProtective {
            shape = "Cocooned, but defined. A wrap coat with structure. A tapered sleeve that holds the wrist. Layer your look like secrets stacked: fitted base, fluid overlay, something sculptural to finish."
        } else if hasFluid && hasLayered {
            shape = "Flowing layers with intentional drape. Pieces that move with your body rather than constrain. Create dimension through differential lengths and weights that interact as you move."
        } else if hasMinimal && hasBalanced {
            shape = "Clean lines with precise proportion. Focus on the relationship between pieces rather than individual statements. Create intentional negative space within your silhouette."
        } else if hasExpressive && hasLayered {
            shape = "Bold volume balanced with definition. Create dimension through contrast—fitted against full, structured against fluid. Allow one element to command focus within a cohesive whole."
        } else if hasProtective {
            shape = "Protective without restriction. Forms that create personal space while allowing movement. Consider overlapping layers that shield without weighing you down."
        } else {
            shape = "Balanced proportions that honor your body's needs today. Create a silhouette that supports your energy rather than forcing it into a predetermined shape."
        }
        
        return shape
    }
    
    /// Generate accessories recommendations
    static func generateAccessories(tokens: [StyleToken]) -> String {
        // Extract relevant characteristics for accessories recommendations
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.0 }
        let hasExpressive = tokens.contains { $0.name == "expressive" || $0.name == "bold" && $0.weight > 1.0 }
        let hasProtective = tokens.contains { $0.name == "protective" && $0.weight > 1.0 }
        let hasEclectic = tokens.contains { $0.name == "eclectic" || $0.name == "unique" && $0.weight > 1.0 }
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.0 }
        let hasWatery = tokens.contains { $0.name == "watery" || $0.name == "fluid" && $0.weight > 1.0 }
        
        // Accessories description based on characteristics
        var accessories = ""
        
        if hasMinimal && hasProtective {
            accessories = "One object only, and it must mean something—your protective piece. A locket, a band, a scent worn like armor. No flash. Just focus. Fragrance: vetiver, resin, or something bitter-green."
        } else if hasExpressive && hasEclectic {
            accessories = "Statement pieces with personal significance. Items that invite questions and create connection. Focus on one primary focal point balanced by subtle supporting elements. Fragrance: spiced citrus, rich amber, or something unexpectedly botanical."
        } else if hasStructured && hasEarthy {
            accessories = "Natural materials with clear purpose. Items that ground and center through weight and texture. Choose pieces with history or handmade quality. Fragrance: cedarwood, tobacco, or something mineral-based."
        } else if hasWatery && hasProtective {
            accessories = "Fluid forms that move with you. Items that adapt to different contexts through the day. Consider pieces with emotional resonance that anchor your shifting states. Fragrance: salt air, clean musk, or something aquatic but warm."
        } else {
            accessories = "Intentional selections that enhance rather than distract. Choose pieces that feel like natural extensions of your energy rather than additions. Fragrance: something that resonates with your skin chemistry and emotional state today."
        }
        
        return accessories
    }
    
    /// Generate final takeaway message
    static func generateTakeaway(tokens: [StyleToken], moonPhase: Double) -> String {
        // Create takeaway options based on token combinations
        var takeawayOptions: [String] = []
        
        // Based on dominant token combinations
        if tokens.contains(where: { $0.name == "authentic" && $0.weight > 1.5 }) {
            takeawayOptions.append("No one else has to get it. But you do. That's the point.")
            takeawayOptions.append("Trust what feels true, not what looks obvious.")
        }
        
        if tokens.contains(where: { $0.name == "intuitive" && $0.weight > 1.5 }) {
            takeawayOptions.append("Your instinct knows before your mind does. Listen.")
            takeawayOptions.append("The inner voice speaks in textures and weights, not just words.")
        }
        
        if tokens.contains(where: { $0.name == "balanced" && $0.weight > 1.5 }) {
            takeawayOptions.append("Balance isn't static. It's a continuous recalibration.")
            takeawayOptions.append("The middle path isn't always halfway between extremes.")
        }
        
        if tokens.contains(where: { $0.name == "expressive" && $0.weight > 1.5 }) {
            takeawayOptions.append("Expression is most powerful when it's intentional, not just loud.")
            takeawayOptions.append("Speak through what you choose, not just what you say.")
        }
        
        // Based on moon phase
        if moonPhase < 90.0 {
            takeawayOptions.append("Begin with intention. The rest will follow.")
            takeawayOptions.append("New cycles start with quiet commitment, not grand gestures.")
        } else if moonPhase < 180.0 {
            takeawayOptions.append("Growth happens in the tension between comfort and challenge.")
            takeawayOptions.append("The path forward reveals itself one step at a time.")
        } else if moonPhase < 270.0 {
            takeawayOptions.append("Full expression requires both vulnerability and strength.")
            takeawayOptions.append("What you reveal is as important as what you conceal.")
        } else {
            takeawayOptions.append("Release what no longer serves before seeking what's next.")
            takeawayOptions.append("Completion is just another form of beginning.")
        }
        
        // Add general takeaways
        takeawayOptions.append("Dress for the energy you need, not just the one you have.")
        takeawayOptions.append("Your body knows. Your clothes should listen.")
        takeawayOptions.append("What you wear changes how you move. Choose accordingly.")
        
        // Randomly select a takeaway
        return takeawayOptions.randomElement() ?? "No one else has to get it. But you do. That's the point."
    }
    
    // MARK: - Private Helper Methods
    
    /// Log a set of tokens with descriptive title for debugging
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
}

/// Structure to hold all daily vibe content
struct DailyVibeContent {
    // Main content
    var title: String = ""
    var mainParagraph: String = ""
    
    // Style guidance sections
    var textiles: String = ""
    var colors: String = ""
    var brightness: Int = 50 // Percentage (0-100)
    var vibrancy: Int = 50   // Percentage (0-100)
    var patterns: String = ""
    var shape: String = ""
    var accessories: String = ""
    
    // Final line
    var takeaway: String = ""
    
    // Weather information
    var temperature: Double? = nil
    var weatherCondition: String? = nil
}
