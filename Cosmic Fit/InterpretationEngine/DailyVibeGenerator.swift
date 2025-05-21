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
            print("  • Fashion Output: 40% natal + 60% daily-influenced factors")
            
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
            let rawTransitTokens = SemanticTokenGenerator.generateTransitTokens(
                transits: transits,
                natal: natalChart
            )
            
            // 3a. NEW: Separate fast and slow transit tokens and apply freshness boost
            var fastTransitTokens: [StyleToken] = []
            var slowTransitTokens: [StyleToken] = []

            for token in rawTransitTokens {
                if let planetarySource = token.planetarySource, let aspectSource = token.aspectSource {
                    // Extract just the aspect type from the aspect source
                    let aspectComponents = aspectSource.split(separator: " ")
                    let aspectType = aspectComponents.count > 1 ? String(aspectComponents[1]) : aspectSource
                    
                    let freshnessBoost = applyFreshnessBoost(transitPlanet: planetarySource, aspectType: aspectSource)
                    
                    // Create adjusted token with freshness boost
                    let adjustedToken = StyleToken(
                        name: token.name,
                        type: token.type,
                        weight: token.weight * freshnessBoost,
                        planetarySource: token.planetarySource,
                        signSource: token.signSource,
                        houseSource: token.houseSource,
                        aspectSource: (token.aspectSource ?? "") + " (freshness adjusted: \(String(format: "%.1f", freshnessBoost)))",
                        originType: token.originType
                    )
                    
                    // Separate into fast and slow transit groups
                    if ["Moon", "Mercury", "Venus", "Sun", "Mars"].contains(planetarySource) {
                        fastTransitTokens.append(adjustedToken)
                    } else {
                        slowTransitTokens.append(adjustedToken)
                    }
                }
            }
            
            logTokenSet("FAST TRANSIT TOKENS (WITH FRESHNESS BOOST)", fastTransitTokens)
            logTokenSet("SLOW TRANSIT TOKENS (WITH FRESHNESS REDUCTION)", slowTransitTokens)
            
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
            
            // 5a. NEW: Generate daily signature tokens
            let dailySignatureTokens = generateDailySignature()
            logTokenSet("DAILY SIGNATURE TOKENS", dailySignatureTokens)
            
            // 5b. NEW: Generate temporal context markers
            let temporalMarkers = addTemporalMarkers()
            logTokenSet("TEMPORAL CONTEXT MARKERS", temporalMarkers)
            
            // 6. Combine all tokens with modified weighting for freshness
            var allTokens: [StyleToken] = []
            
            // REBALANCED WEIGHTS:
            let baseStyleWeight = 0.4      // Reduced from 0.5
            let emotionalVibeWeight = 0.15  // Reduced from 0.2
            let fastTransitWeight = 0.15    // Emphasize fast-moving planets
            let slowTransitWeight = 0.05    // De-emphasize slow-moving planets
            let moonPhaseWeight = 0.1      // Increased from 0.05
            let weatherWeight = 0.1        // Increased from 0.05
            let dailySignatureWeight = 0.1  // NEW
            let temporalMarkerWeight = 0.05 // NEW
            
            // Add base style tokens (reduced to 40% weight in final output)
            for token in baseStyleTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * baseStyleWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add emotional vibe tokens (reduced to 15% transit weight)
            for token in emotionalVibeTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * emotionalVibeWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add fast transit tokens (15% weight - fast moving planets emphasized)
            for token in fastTransitTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * fastTransitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add slow transit tokens (5% weight - reduced influence)
            for token in slowTransitTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * slowTransitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add moon phase tokens (increased to 10%)
            for token in moonPhaseTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * moonPhaseWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add weather tokens (increased to 10%)
            for token in weatherTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * weatherWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add daily signature tokens (10% weight - new)
            for token in dailySignatureTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * dailySignatureWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // Add temporal marker tokens (5% weight - new)
            for token in temporalMarkers {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * temporalMarkerWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource
                )
                allTokens.append(adjustedToken)
            }
            
            // NEW: Apply controlled variation to tokens
            allTokens = introduceControlledVariation(baseTokens: allTokens)
            
            // Log combined weighted tokens
            logTokenSet("COMBINED WEIGHTED TOKENS", allTokens)
            
            // 7. Generate the daily vibe content with patternSeed for variation
            let patternSeed = getDailyPatternSeed()
            let dailyVibeContent = generateDailyVibeContent(
                tokens: allTokens,
                weather: weather,
                moonPhase: moonPhase,
                patternSeed: patternSeed
            )
            
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
    static func generateDailyVibeContent(
        tokens: [StyleToken],
        weather: TodayWeather?,
        moonPhase: Double,
        patternSeed: Int = 0) -> DailyVibeContent {
        // Create content object
        var content = DailyVibeContent()
        
        // Generate title with pattern variation using seed
        content.title = generateVibeTitle(tokens: tokens, patternSeed: patternSeed)
        
        // Generate main paragraph with variation
        content.mainParagraph = generateMainParagraph(tokens: tokens, moonPhase: moonPhase, patternSeed: patternSeed)
        
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
        
        // Generate takeaway line with pattern variation
        content.takeaway = generateTakeaway(tokens: tokens, moonPhase: moonPhase, patternSeed: patternSeed)
        
        // Add weather information if available
        if let weather = weather {
            content.temperature = weather.temp
            content.weatherCondition = weather.conditions
        }
        
        return content
    }
    
    /// Generate a poetic title for the daily vibe with pattern variation
    private static func generateVibeTitle(tokens: [StyleToken], patternSeed: Int) -> String {
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
        
        // NEW: Get title pattern using seed for daily variation
        let patterns = [
            "%s %s %s",            // e.g. "Resonance Beneath Surface"
            "The %s of %s",        // e.g. "The Flow of Light"
            "%s and %s",           // e.g. "Structure and Shadow"
            "%s in %s",            // e.g. "Depth in Motion"
            "%s meets %s",         // e.g. "Form meets Function"
            "%s through %s"        // e.g. "Light through Shadow"
        ]
        
        let pattern = patterns[patternSeed % patterns.count]
        
        // Select words using the seed for consistent daily variation
        let firstWordIndex = (patternSeed * 17) % max(1, firstWordOptions.count)
        let connectionWordIndex = (patternSeed * 23) % connectionWords.count
        let finalWordIndex = (patternSeed * 13) % finalWords.count
        
        let firstWord = firstWordOptions[firstWordIndex % firstWordOptions.count]
        let connectionWord = connectionWords[connectionWordIndex]
        let finalWord = finalWords[finalWordIndex]
        
        // Format according to pattern
        switch pattern {
        case "%s %s %s":
            return "\(firstWord) \(connectionWord) \(finalWord)"
        case "The %s of %s":
            return "The \(firstWord) of \(finalWord)"
        case "%s and %s":
            return "\(firstWord) and \(finalWord)"
        case "%s in %s":
            return "\(firstWord) in \(finalWord)"
        case "%s meets %s":
            return "\(firstWord) meets \(finalWord.replacingOccurrences(of: "the ", with: ""))"
        case "%s through %s":
            return "\(firstWord) through \(finalWord)"
        default:
            return "\(firstWord) \(connectionWord) \(finalWord)"
        }
    }
    
    /// Generate the main paragraph describing the overall vibe with pattern variation
    private static func generateMainParagraph(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
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
        
        // NEW: Opening sentence variations based on pattern seed
        let openingPatterns = [
            "A %s glows today, asking for %s without %s. ",
            "Today carries a %s current, inviting %s with %s. ",
            "There's a %s quality to today's energy, suggesting %s and %s. ",
            "%s weaves through today, encouraging a balance of %s and %s. ",
            "The day unfolds with a %s rhythm, connecting %s to %s. "
        ]
        
        // Get opening pattern based on seed
        let openingPattern = openingPatterns[patternSeed % openingPatterns.count]
        
        // Create paragraph based on dominant characteristics
        var paragraph = ""
        
        // Fill in the opening pattern based on dominant characteristics
        if hasSubtle {
            paragraph += String(format: openingPattern, "quiet smoulder", "warmth", "noise")
        } else if hasBold {
            paragraph += String(format: openingPattern, "electric", "clarity", "presence")
        } else if hasFluid {
            paragraph += String(format: openingPattern, "flowing", "adaptability", "intuitive ease")
        } else if hasStructured {
            paragraph += String(format: openingPattern, "grounded", "intention", "purpose")
        } else if hasDreamy {
            paragraph += String(format: openingPattern, "misty", "trust", "the unseen")
        } else {
            paragraph += String(format: openingPattern, "balanced", "harmony", "expression")
        }
        
        // NEW: Middle section variations based on pattern seed
        let middlePatterns = [
            "You're %s. There's an %s pulling you %s to dress for your %s, not the %s. ",
            "You're meant to %s through %s. Your %s should tell a story only you fully %s. ",
            "Today asks you to embrace %s and release %s. Your style can reflect this through %s and %s. ",
            "Find the courage to %s rather than %s. Your appearance today is more about %s than %s. "
        ]
        
        // Get middle pattern based on seed
        let middlePattern = middlePatterns[(patternSeed * 3) % middlePatterns.count]
        
        // Middle section based on secondary characteristics
        if hasEarthy && hasIntuitive {
            paragraph += String(format: middlePattern,
                               "not meant to burn bright—just burn real",
                               "undercurrent",
                               "inward",
                               "inner world",
                               "outer gaze")
        } else if hasLayered && hasMinimal {
            paragraph += String(format: middlePattern,
                               "meant to reveal through concealing",
                               "careful restraint",
                               "layers",
                               "understand")
        } else if hasBold && hasLayered {
            paragraph += String(format: middlePattern,
                               "depth",
                               "flash",
                               "presence",
                               "layer by layer")
        } else if hasFluid && hasIntuitive {
            paragraph += String(format: middlePattern,
                               "flow with your instincts",
                               "allowing",
                               "outer expression",
                               "inner currents")
        } else {
            paragraph += String(format: middlePattern,
                               "find balance between what you show and what you keep hidden",
                               "authentic extension",
                               "style",
                               "interior landscape")
        }
        
        // NEW: Closing guidance variations based on pattern seed and moon phase
        let closingPatterns = [
            "It's a day to %s with %s, to carry %s like %s, and to resist the urge to %s. ",
            "Today invites you to %s through %s, to embody %s with %s, and to trust your %s. ",
            "Consider how to %s your %s today, allowing %s to guide your %s rather than %s. ",
            "The day's energy supports %s that %s, creating a sense of %s without sacrificing %s. "
        ]
        
        // Get closing pattern based on seed
        let closingPattern = closingPatterns[(patternSeed * 7) % closingPatterns.count]
        
        // Closing guidance based on moon phase
        if moonPhase < 90.0 {
            // New Moon to First Quarter - beginnings, intentions
            paragraph += String(format: closingPattern,
                               "layer comfort",
                               "mystery",
                               "softness",
                               "armour",
                               "explain yourself")
        } else if moonPhase < 180.0 {
            // First Quarter to Full Moon - growth, expression
            paragraph += String(format: closingPattern,
                               "build presence",
                               "intention",
                               "texture and form",
                               "clarity",
                               "evolving intuition")
        } else if moonPhase < 270.0 {
            // Full Moon to Last Quarter - culmination, visibility
            paragraph += String(format: closingPattern,
                               "embody",
                               "full expression",
                               "what you reveal",
                               "what you protect",
                               "authentic presence")
        } else {
            // Last Quarter to New Moon - release, introspection
            paragraph += String(format: closingPattern,
                               "release",
                               "what no longer serves",
                               "simplify",
                               "its essence",
                               "new cycles of creativity")
        }
        
        // NEW: Final statements with variations
        let finalStatements = [
            "What matters is how it feels, not how it looks from the outside. Trust the flicker in your gut.",
            "The strongest style statements come from within. Let your inner knowing guide your choices today.",
            "Your body already knows what it needs. Listen to that wisdom rather than external expectations.",
            "The most powerful appearance is one that aligns with your authentic energy. Trust that alignment.",
            "Style is a conversation between your inner and outer worlds. Make sure both voices are heard."
        ]
        
        // Get final statement based on seed
        let finalStatement = finalStatements[(patternSeed * 11) % finalStatements.count]
        paragraph += finalStatement
        
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
        
        // NEW: Add daily variation to fabric options
        let patternSeed = getDailyPatternSeed()
        let dailyFabric = getDailyFabricEmphasis(seed: patternSeed)
        
        // Fabric options based on characteristics
        var fabricOptions: [String] = []
        
        // Always include the daily fabric emphasis first
        fabricOptions.append(dailyFabric)
        
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
        
        // Use seed to ensure consistent "randomness" for the day
        let shuffledFabrics = shuffleArrayWithSeed(fabricOptions, seed: patternSeed)
        let selectedCount = min(shuffledFabrics.count, 4 + (patternSeed % 3)) // 4-6 fabrics
        let selectedFabrics = shuffledFabrics.prefix(selectedCount)
        
        // Create the fabric description
        var description = selectedFabrics.joined(separator: ", ")
        
        // NEW: Add varied descriptive second sentences
        let descriptivePatterns = [
            "—anything that feels like %s with a touch of %s. Choose %s that %s.",
            "—anything with %s and %s. Choose materials that %s while letting you %s.",
            "—anything that %s and %s to your movement. Choose fabrics that %s through %s.",
            "—anything that %s through %s rather than %s. Choose materials that %s against your skin."
        ]
        
        let descriptivePattern = descriptivePatterns[(patternSeed * 13) % descriptivePatterns.count]
        
        // Add a descriptive second sentence
        if hasSoft && hasTextured {
            description += String(format: descriptivePattern,
                                 "second skin",
                                 "shadow",
                                 "tactile layers",
                                 "soften the wind but hold your power close")
        } else if hasStructured && hasEarthy {
            description += String(format: descriptivePattern,
                                 "substance",
                                 "character",
                                 "ground you",
                                 "move with intention")
        } else if hasFluid && hasLayered {
            description += String(format: descriptivePattern,
                                 "flows",
                                 "adapts",
                                 "create dimension",
                                 "layering rather than weight")
        } else if hasLuxurious {
            description += String(format: descriptivePattern,
                                 "elevates",
                                 "quality rather than flash",
                                 "feel transformative",
                                 "transformative")
        } else {
            description += String(format: descriptivePattern,
                                 "resonates",
                                 "your body's needs today",
                                 "support",
                                 "rather than distract from your presence")
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
        
        // NEW: Get daily color emphasis for variety
        let patternSeed = getDailyPatternSeed()
        let dailyColor = getDailyColorEmphasis(seed: patternSeed)
        
        // Color options based on characteristics
        var colorOptions: [String] = []
        
        // Always include the daily color emphasis
        colorOptions.append(dailyColor)
        
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
        
        // Use seed for consistent daily variation
        let shuffledColors = shuffleArrayWithSeed(colorOptions, seed: patternSeed)
        let selectedCount = min(shuffledColors.count, 5 + (patternSeed % 3)) // 5-7 colors
        let selectedColors = shuffledColors.prefix(selectedCount)
        
        // Create the color description
        var description = selectedColors.joined(separator: ", ")
        
        // NEW: Add varied closing phrases
        let closingPhrases = [
            ". Let them %s the light, not %s it",
            ". Let them %s with %s presence",
            ". Let them %s your energy with %s",
            ". Let them %s and %s your presence today",
            ". Let them %s your %s with subtle %s"
        ]
        
        let closingPhrase = closingPhrases[(patternSeed * 19) % closingPhrases.count]
        
        // Add a descriptive closing phrase
        if hasDark || hasMuted {
            description += String(format: closingPhrase, "absorb", "reflect")
        } else if hasLight || hasAiry {
            description += String(format: closingPhrase, "diffuse", "subtle")
        } else if hasVibrant || hasFiery {
            description += String(format: closingPhrase, "express", "intention")
        } else {
            description += String(format: closingPhrase, "ground", "center")
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
        
        // NEW: Add small daily variation for freshness
        let dailyVariation = getDailyPatternSeed() % 11 - 5 // -5 to +5 variation
        brightnessValue += dailyVariation
        
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
        
        // NEW: Add small daily variation for freshness
        let dailyVariation = getDailyPatternSeed() % 13 - 6 // -6 to +6 variation
        vibrancyValue += dailyVariation
        
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
        
        // NEW: Get daily pattern emphasis
        let patternSeed = getDailyPatternSeed()
        let dailyPatternEmphasis = getDailyPatternEmphasis(seed: patternSeed)
        
        // Pattern suggestions based on characteristics and daily emphasis
        var patterns = ""
        
        // NEW: Add varied pattern descriptions based on daily seed
        let patternDescriptions = [
            "%s. %s—%s.",
            "%s. Let these patterns %s with %s.",
            "Today favors %s. %s that %s.",
            "Consider %s. These create %s without %s."
        ]
        
        let patternDescription = patternDescriptions[(patternSeed * 17) % patternDescriptions.count]
        
        // Include daily pattern emphasis in description
        if hasMinimal && hasTextured {
            patterns = String(format: patternDescription,
                             "Uneven dye effects (stonewash, acid, mineral)" + dailyPatternEmphasis,
                             "Minimal prints that feel faded or lived-in",
                             "nothing polished or loud")
        } else if hasExpressive && hasEclectic {
            patterns = String(format: patternDescription,
                             "Bold geometrics, unexpected color combinations" + dailyPatternEmphasis,
                             "Statement prints that tell a story or reference art",
                             "each with a clear point of view")
        } else if hasStructured && hasMinimal {
            patterns = String(format: patternDescription,
                             "Architectural lines, subtle grids" + dailyPatternEmphasis,
                             "Patterns with mathematical order",
                             "rather than organic flow")
        } else if hasFluid && hasExpressive {
            patterns = String(format: patternDescription,
                             "Watercolor effects, organic forms" + dailyPatternEmphasis,
                             "Patterns that move and flow",
                             "with a sense of natural rhythm")
        } else if hasSubtle {
            patterns = String(format: patternDescription,
                             "Barely-there textures, monochromatic tone-on-tone" + dailyPatternEmphasis,
                             "Patterns that reveal themselves",
                             "only upon closer inspection")
        } else if hasEclectic {
            patterns = String(format: patternDescription,
                             "Unexpected combinations, vintage-inspired motifs" + dailyPatternEmphasis,
                             "Mix patterns of different scales",
                             "for a curated eclectic approach")
        } else {
            patterns = String(format: patternDescription,
                             "Balanced, intentional patterns" + dailyPatternEmphasis,
                             "Choose prints that feel authentic",
                             "to your energy today")
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
        
        // NEW: Get daily shape emphasis
        let patternSeed = getDailyPatternSeed()
        let dailyShapeEmphasis = getDailyShapeEmphasis(seed: patternSeed)
        
        // Shape description based on characteristics and daily emphasis
        var shape = ""
        
        // NEW: Add varied shape descriptions based on seed
        let shapeDescriptions = [
            "%s. %s. %s.",
            "%s. Consider %s that %s as you move.",
            "Today's energy favors %s. %s that %s rather than %s.",
            "Focus on %s. Create %s through %s."
        ]
        
        let shapeDescription = shapeDescriptions[(patternSeed * 23) % shapeDescriptions.count]
        
        // Create shape description with daily emphasis included
        if hasStructured && hasProtective {
            shape = String(format: shapeDescription,
                          "Cocooned, but defined" + dailyShapeEmphasis,
                          "A wrap coat with structure",
                          "Layer your look like secrets stacked: fitted base, fluid overlay, something sculptural to finish")
        } else if hasFluid && hasLayered {
            shape = String(format: shapeDescription,
                          "Flowing layers with intentional drape" + dailyShapeEmphasis,
                          "pieces",
                          "move with your body rather than constrain")
        } else if hasMinimal && hasBalanced {
            shape = String(format: shapeDescription,
                          "Clean lines with precise proportion" + dailyShapeEmphasis,
                          "the relationship between pieces",
                          "rather than individual statements")
        } else if hasExpressive && hasLayered {
            shape = String(format: shapeDescription,
                          "Bold volume balanced with definition" + dailyShapeEmphasis,
                          "dimension through contrast",
                          "fitted against full, structured against fluid")
        } else if hasProtective {
            shape = String(format: shapeDescription,
                          "Protective without restriction" + dailyShapeEmphasis,
                          "Forms that create personal space",
                          "while allowing movement")
        } else {
            shape = String(format: shapeDescription,
                          "Balanced proportions that honor your body's needs today" + dailyShapeEmphasis,
                          "a silhouette that supports your energy",
                          "rather than forcing it into a predetermined shape")
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
        
        // NEW: Get daily accessory emphasis
        let patternSeed = getDailyPatternSeed()
        let dailyAccessoryEmphasis = getDailyAccessoryEmphasis(seed: patternSeed)
        
        // Accessories description based on characteristics
        var accessories = ""
        
        // NEW: Add varied accessory descriptions based on seed
        let accessoryDescriptions = [
            "%s, and it must %s—%s. %s. %s: %s.",
            "%s with %s. Items that %s and %s. %s. %s: %s.",
            "Choose %s that %s. %s through %s and %s. %s: %s.",
            "Accessories that %s to %s through the day. %s that %s. %s: %s."
        ]
        
        let accessoryDescription = accessoryDescriptions[(patternSeed * 11) % accessoryDescriptions.count]
        
        // Create accessories description with daily emphasis
        if hasMinimal && hasProtective {
            accessories = String(format: accessoryDescription,
                                "One object only" + dailyAccessoryEmphasis,
                                "mean something",
                                "your protective piece",
                                "A locket, a band, a scent worn like armor. No flash. Just focus",
                                "Fragrance",
                                "vetiver, resin, or something bitter-green")
        } else if hasExpressive && hasEclectic {
            accessories = String(format: accessoryDescription,
                                "Statement pieces" + dailyAccessoryEmphasis,
                                "personal significance",
                                "invite questions",
                                "create connection",
                                "Focus on one primary focal point balanced by subtle supporting elements",
                                "Fragrance",
                                "spiced citrus, rich amber, or something unexpectedly botanical")
        } else if hasStructured && hasEarthy {
            accessories = String(format: accessoryDescription,
                                "Natural materials" + dailyAccessoryEmphasis,
                                "with clear purpose",
                                "ground and center",
                                "weight",
                                "texture",
                                "Fragrance",
                                "cedarwood, tobacco, or something mineral-based")
        } else if hasWatery && hasProtective {
            accessories = String(format: accessoryDescription,
                                "Fluid forms" + dailyAccessoryEmphasis,
                                "move with you",
                                "adapt",
                                "different contexts",
                                "Consider pieces with emotional resonance that anchor your shifting states",
                                "Fragrance",
                                "salt air, clean musk, or something aquatic but warm")
        } else {
            accessories = String(format: accessoryDescription,
                                "Intentional selections" + dailyAccessoryEmphasis,
                                "enhance rather than distract",
                                "feel like natural extensions of your energy",
                                "rather than additions",
                                "Choose pieces that resonate with your current state",
                                "Fragrance",
                                "something that resonates with your skin chemistry and emotional state today")
        }
        
        return accessories
    }
    
    /// Generate final takeaway message
    static func generateTakeaway(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
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
        
        // NEW: Add daily variations
        takeawayOptions.append("Today's energy speaks through form. Let your clothes translate.")
        takeawayOptions.append("The most authentic style comes from within, not from outside.")
        takeawayOptions.append("Trust the conversation between your body and your clothes today.")
        takeawayOptions.append("Your physical presence carries a message. Make it intentional.")
        takeawayOptions.append("Style isn't about being seen, but about seeing yourself clearly.")
        
        // Use seed to select takeaway consistently for the day
        let index = patternSeed % takeawayOptions.count
        return takeawayOptions[index]
    }
    
    // MARK: - NEW: Daily Freshness Methods
    
    /// Generate a unique but stable seed for each day
    static func getDailyPatternSeed() -> Int {
    // Generate a unique but stable seed for each day
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: Date())
    return (components.day ?? 1) + ((components.month ?? 1) * 31) +
           ((components.year ?? 2025) * 366)
    }

    
    /// Applies freshness boost based on transit planet and aspect type
    static func applyFreshnessBoost(transitPlanet: String, aspectType: String) -> Double {
        var freshnessBoost = 1.0
        
        // Boost fast-moving planets significantly for daily freshness
        switch transitPlanet {
        case "Moon":
            freshnessBoost = 3.0  // Very significant - moves ~13° daily
        case "Mercury":
            freshnessBoost = 2.2  // Significant - moves ~1-2° daily
        case "Venus":
            freshnessBoost = 2.0  // Significant - moves ~1° daily
        case "Sun":
            freshnessBoost = 1.5  // Moderate - moves ~1° daily
        case "Mars":
            freshnessBoost = 1.2  // Slight boost - moves ~0.5° daily
        case "Jupiter":
            freshnessBoost = 0.7  // Reduce - moves slowly
        case "Saturn", "Uranus", "Neptune", "Pluto":
            freshnessBoost = 0.5  // Significantly reduce - very slow moving
        default:
            freshnessBoost = 0.8  // Slightly reduce other points
        }
        
        // Additional boost for aspects that create more interesting daily variations
        if ["Square", "Opposition"].contains(aspectType) {
            freshnessBoost *= 1.2  // Emphasize dynamic aspects
        }
        
        // Give a boost to minor aspects for daily variety
        if ["Semisextile", "Semisquare", "Quintile", "Sesquisquare", "Quincunx"].contains(aspectType) {
            freshnessBoost *= 1.4  // Boost minor aspects for daily variety
        }
        
        return freshnessBoost
    }
    
    /// Generate daily signature tokens based on day of week and other daily factors
    static func generateDailySignature() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Day of week influence
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let seed = getDailyPatternSeed()
        
        switch weekday {
        case 1: // Sunday (Sun)
            tokens.append(StyleToken(
                name: "illuminated",
                type: "texture",
                weight: 2.2,
                planetarySource: "Daily Signature",
                aspectSource: "Sun Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "radiant",
                type: "color_quality",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Sun Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "amber gold",
                type: "color",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Sun Day",
                originType: .transit
            ))
            
        case 2: // Monday (Moon)
            tokens.append(StyleToken(
                name: "reflective",
                type: "mood",
                weight: 2.2,
                planetarySource: "Daily Signature",
                aspectSource: "Moon Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "intuitive",
                type: "structure",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Moon Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "pearl silver",
                type: "color",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Moon Day",
                originType: .transit
            ))
            
        case 3: // Tuesday (Mars)
            tokens.append(StyleToken(
                name: "energetic",
                type: "mood",
                weight: 2.2,
                planetarySource: "Daily Signature",
                aspectSource: "Mars Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "dynamic",
                type: "structure",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Mars Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "ruby red",
                type: "color",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Mars Day",
                originType: .transit
            ))
            
        case 4: // Wednesday (Mercury)
            tokens.append(StyleToken(
                name: "communicative",
                type: "mood",
                weight: 2.2,
                planetarySource: "Daily Signature",
                aspectSource: "Mercury Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "versatile",
                type: "structure",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Mercury Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "quicksilver",
                type: "color",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Mercury Day",
                originType: .transit
            ))
            
        case 5: // Thursday (Jupiter)
            tokens.append(StyleToken(
                name: "expansive",
                type: "mood",
                weight: 2.2,
                planetarySource: "Daily Signature",
                aspectSource: "Jupiter Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "abundant",
                type: "structure",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Jupiter Day",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "royal blue",
                type: "color",
                weight: 2.0,
                planetarySource: "Daily Signature",
                aspectSource: "Jupiter Day",
                originType: .transit
            ))
            
        case 6: // Friday (Venus)
            tokens.append(StyleToken(
                name: "harmonious",
                        type: "mood",
                        weight: 2.2,
                        planetarySource: "Daily Signature",
                        aspectSource: "Venus Day",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "balanced",
                        type: "structure",
                        weight: 2.0,
                        planetarySource: "Daily Signature",
                        aspectSource: "Venus Day",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "emerald",
                        type: "color",
                        weight: 2.0,
                        planetarySource: "Daily Signature",
                        aspectSource: "Venus Day",
                        originType: .transit
                    ))
                    
                case 7: // Saturday (Saturn)
                    tokens.append(StyleToken(
                        name: "structured",
                        type: "mood",
                        weight: 2.2,
                        planetarySource: "Daily Signature",
                        aspectSource: "Saturn Day",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "enduring",
                        type: "structure",
                        weight: 2.0,
                        planetarySource: "Daily Signature",
                        aspectSource: "Saturn Day",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "obsidian",
                        type: "color",
                        weight: 2.0,
                        planetarySource: "Daily Signature",
                        aspectSource: "Saturn Day",
                        originType: .transit
                    ))
                    
                default:
                    tokens.append(StyleToken(
                        name: "balanced",
                        type: "mood",
                        weight: 2.0,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Energy",
                        originType: .transit
                    ))
                }

                // Add temporal markers (season, time of day)
                let month = calendar.component(.month, from: Date())
                let hour = calendar.component(.hour, from: Date())

                // Seasonal influence
                switch month {
                case 3...5: // Spring
                    tokens.append(StyleToken(
                        name: "emerging",
                        type: "structure",
                        weight: 1.8,
                        planetarySource: "Daily Signature",
                        aspectSource: "Spring Energy",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "fresh",
                        type: "texture",
                        weight: 1.7,
                        planetarySource: "Daily Signature",
                        aspectSource: "Spring Energy",
                        originType: .transit
                    ))
                    
                case 6...8: // Summer
                    tokens.append(StyleToken(
                        name: "expansive",
                        type: "structure",
                        weight: 1.8,
                        planetarySource: "Daily Signature",
                        aspectSource: "Summer Energy",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "vibrant",
                        type: "color_quality",
                        weight: 1.7,
                        planetarySource: "Daily Signature",
                        aspectSource: "Summer Energy",
                        originType: .transit
                    ))
                    
                case 9...11: // Fall
                    tokens.append(StyleToken(
                        name: "layered",
                        type: "structure",
                        weight: 1.8,
                        planetarySource: "Daily Signature",
                        aspectSource: "Autumn Energy",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "transitional",
                        type: "texture",
                        weight: 1.7,
                        planetarySource: "Daily Signature",
                        aspectSource: "Autumn Energy",
                        originType: .transit
                    ))
                    
                default: // Winter (12, 1, 2)
                    tokens.append(StyleToken(
                        name: "protective",
                        type: "structure",
                        weight: 1.8,
                        planetarySource: "Daily Signature",
                        aspectSource: "Winter Energy",
                        originType: .transit
                    ))
                    tokens.append(StyleToken(
                        name: "insulating",
                        type: "texture",
                        weight: 1.7,
                        planetarySource: "Daily Signature",
                        aspectSource: "Winter Energy",
                        originType: .transit
                    ))
                }

                // Time of day influence
                if hour >= 5 && hour < 12 {
                    // Morning
                    tokens.append(StyleToken(
                        name: "fresh",
                        type: "mood",
                        weight: 1.6,
                        planetarySource: "Daily Signature",
                        aspectSource: "Morning Energy",
                        originType: .transit
                    ))
                } else if hour >= 12 && hour < 17 {
                    // Afternoon
                    tokens.append(StyleToken(
                        name: "active",
                        type: "mood",
                        weight: 1.6,
                        planetarySource: "Daily Signature",
                        aspectSource: "Afternoon Energy",
                        originType: .transit
                    ))
                } else if hour >= 17 && hour < 22 {
                    // Evening
                    tokens.append(StyleToken(
                        name: "mellow",
                        type: "mood",
                        weight: 1.6,
                        planetarySource: "Daily Signature",
                        aspectSource: "Evening Energy",
                        originType: .transit
                    ))
                } else {
                    // Night
                    tokens.append(StyleToken(
                        name: "introspective",
                        type: "mood",
                        weight: 1.6,
                        planetarySource: "Daily Signature",
                        aspectSource: "Night Energy",
                        originType: .transit
                    ))
                }

                // Add lunar day influence (1-29.5)
                let lunarDate = calendar.dateComponents([.day], from: Date()).day ?? 1
                let lunarDay = (lunarDate % 30) + 1

                if lunarDay <= 7 {
                    // Waxing crescent - beginning energy
                    tokens.append(StyleToken(
                        name: "initiating",
                        type: "mood",
                        weight: 1.5,
                        planetarySource: "Daily Signature",
                        aspectSource: "Lunar Day \(lunarDay)",
                        originType: .transit
                    ))
                } else if lunarDay <= 14 {
                    // Waxing gibbous - building energy
                    tokens.append(StyleToken(
                        name: "developing",
                        type: "mood",
                        weight: 1.5,
                        planetarySource: "Daily Signature",
                        aspectSource: "Lunar Day \(lunarDay)",
                        originType: .transit
                    ))
                } else if lunarDay <= 21 {
                    // Waning gibbous - expressing energy
                    tokens.append(StyleToken(
                        name: "expressing",
                        type: "mood",
                        weight: 1.5,
                        planetarySource: "Daily Signature",
                        aspectSource: "Lunar Day \(lunarDay)",
                        originType: .transit
                    ))
                } else {
                    // Waning crescent - releasing energy
                    tokens.append(StyleToken(
                        name: "releasing",
                        type: "mood",
                        weight: 1.5,
                        planetarySource: "Daily Signature",
                        aspectSource: "Lunar Day \(lunarDay)",
                        originType: .transit
                    ))
                }

                // Daily numerical influence (based on day number)
                let dayNumber = calendar.dateComponents([.day], from: Date()).day ?? 1
                let dayDigitSum = sumDigits(dayNumber)

                // Numerological influence
                switch dayDigitSum {
                case 1:
                    tokens.append(StyleToken(
                        name: "pioneering",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 1",
                        originType: .transit
                    ))
                case 2:
                    tokens.append(StyleToken(
                        name: "receptive",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 2",
                        originType: .transit
                    ))
                case 3:
                    tokens.append(StyleToken(
                        name: "expressive",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 3",
                        originType: .transit
                    ))
                case 4:
                    tokens.append(StyleToken(
                        name: "structured",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 4",
                        originType: .transit
                    ))
                case 5:
                    tokens.append(StyleToken(
                        name: "dynamic",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 5",
                        originType: .transit
                    ))
                case 6:
                    tokens.append(StyleToken(
                        name: "harmonious",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 6",
                        originType: .transit
                    ))
                case 7:
                    tokens.append(StyleToken(
                        name: "reflective",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 7",
                        originType: .transit
                    ))
                case 8:
                    tokens.append(StyleToken(
                        name: "powerful",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 8",
                        originType: .transit
                    ))
                case 9:
                    tokens.append(StyleToken(
                        name: "completing",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Number 9",
                        originType: .transit
                    ))
                default:
                    tokens.append(StyleToken(
                        name: "flexible",
                        type: "mood",
                        weight: 1.4,
                        planetarySource: "Daily Signature",
                        aspectSource: "Day Energy",
                        originType: .transit
                    ))
                }

                return tokens
                }

 


    
    /// Add temporal context markers for freshness
    static func addTemporalMarkers() -> [StyleToken] {
    var tokens: [StyleToken] = []

    // Seasonal influence
    let month = Calendar.current.component(.month, from: Date())

    switch month {
    case 3...5: // Spring
        tokens.append(StyleToken(
            name: "emerging",
            type: "structure",
            weight: 1.8,
            planetarySource: "Temporal Context",
            aspectSource: "Spring Energy",
            originType: .transit
        ))
        tokens.append(StyleToken(
            name: "fresh",
            type: "texture",
            weight: 1.7,
            planetarySource: "Temporal Context",
            aspectSource: "Spring Energy",
            originType: .transit
        ))
        
    case 6...8: // Summer
        tokens.append(StyleToken(
            name: "expansive",
            type: "structure",
            weight: 1.8,
            planetarySource: "Temporal Context",
            aspectSource: "Summer Energy",
            originType: .transit
        ))
        tokens.append(StyleToken(
            name: "vibrant",
            type: "color_quality",
            weight: 1.7,
            planetarySource: "Temporal Context",
            aspectSource: "Summer Energy",
            originType: .transit
        ))
        
    case 9...11: // Fall
        tokens.append(StyleToken(
            name: "layered",
            type: "structure",
            weight: 1.8,
            planetarySource: "Temporal Context",
            aspectSource: "Autumn Energy",
            originType: .transit
        ))
        tokens.append(StyleToken(
            name: "transitional",
            type: "texture",
            weight: 1.7,
            planetarySource: "Temporal Context",
            aspectSource: "Autumn Energy",
            originType: .transit
        ))
        
    default: // Winter (12, 1, 2)
        tokens.append(StyleToken(
            name: "protective",
            type: "structure",
            weight: 1.8,
            planetarySource: "Temporal Context",
            aspectSource: "Winter Energy",
            originType: .transit
        ))
        tokens.append(StyleToken(
            name: "insulating",
            type: "texture",
            weight: 1.7,
            planetarySource: "Temporal Context",
            aspectSource: "Winter Energy",
            originType: .transit
        ))
    }

    // Time of day influence
    let hour = Calendar.current.component(.hour, from: Date())

    if hour >= 5 && hour < 12 {
        // Morning
        tokens.append(StyleToken(
            name: "awakening",
            type: "mood",
            weight: 1.6,
            planetarySource: "Temporal Context",
            aspectSource: "Morning Energy",
            originType: .transit
        ))
    } else if hour >= 12 && hour < 17 {
        // Afternoon
        tokens.append(StyleToken(
            name: "productive",
            type: "mood",
            weight: 1.6,
            planetarySource: "Temporal Context",
            aspectSource: "Afternoon Energy",
            originType: .transit
        ))
    } else if hour >= 17 && hour < 22 {
        // Evening
        tokens.append(StyleToken(
            name: "reflective",
            type: "mood",
            weight: 1.6,
            planetarySource: "Temporal Context",
            aspectSource: "Evening Energy",
            originType: .transit
        ))
    } else {
        // Night
        tokens.append(StyleToken(
            name: "deepening",
            type: "mood",
            weight: 1.6,
            planetarySource: "Temporal Context",
            aspectSource: "Night Energy",
            originType: .transit
        ))
    }

    return tokens
    }
    
    /// Apply controlled variation to tokens for daily freshness
    static func introduceControlledVariation(baseTokens: [StyleToken]) -> [StyleToken] {
    var tokens = baseTokens
    let seed = getDailyPatternSeed()

    // Daily emphasis on a random token type
    let tokenTypes = ["mood", "texture", "structure", "color_quality"]
    let targetType = tokenTypes[seed % tokenTypes.count]
    let emphasisFactor = 1.0 + Double(seed % 3) * 0.1 + 0.1 // 1.1 to 1.3

    // Apply the emphasis
    for i in 0..<tokens.count {
        if tokens[i].type == targetType {
            tokens[i] = StyleToken(
                name: tokens[i].name,
                type: tokens[i].type,
                weight: tokens[i].weight * emphasisFactor,
                planetarySource: tokens[i].planetarySource,
                signSource: tokens[i].signSource,
                houseSource: tokens[i].houseSource,
                aspectSource: (tokens[i].aspectSource ?? "") + " (Daily Emphasis)",
                originType: tokens[i].originType
            )
        }
    }

    // Add 1-2 daily wildcard tokens
    let wildcardOptions = [
        "unexpected", "juxtaposed", "nuanced", "transitional",
        "distinctive", "paradoxical", "intuitive", "emergent",
        "responsive", "calibrated", "resonant", "harmonized",
        "textured", "articulated", "considered", "attentive"
    ]

    let wildcard1 = wildcardOptions[seed % wildcardOptions.count]
    let wildcard2 = wildcardOptions[(seed * 7) % wildcardOptions.count]

    tokens.append(StyleToken(
        name: wildcard1,
        type: "mood",
        weight: 1.5,
        planetarySource: "Daily Variation",
        aspectSource: "Daily Wildcard",
        originType: .transit
    ))

    // Add a second wildcard half the time for more variation
    if seed % 2 == 0 {
        tokens.append(StyleToken(
            name: wildcard2,
            type: "texture",
            weight: 1.4,
            planetarySource: "Daily Variation",
            aspectSource: "Daily Wildcard 2",
            originType: .transit
        ))
    }

    return tokens
    }
    
    /// Get daily fabric emphasis
    static func getDailyFabricEmphasis(seed: Int) -> String {
        let fabricOptions = [
            "washed linen", "raw silk", "brushed wool", "supple leather",
            "lightly waxed cotton", "textured knit", "airy gauze",
            "structured denim", "fluid rayon", "crisp poplin",
            "heavyweight jersey", "distressed suede", "lightweight tweed",
            "crisp oxford", "vintage velvet", "laundered chambray",
            "bouclé wool", "burnished leather", "crinkled cotton",
            "technical mesh", "textured lace", "organic hemp",
            "woven jacquard", "structured canvas", "draped georgette"
        ]
        
        return fabricOptions[seed % fabricOptions.count]
    }
    
    /// Get daily color emphasis
    static func getDailyColorEmphasis(seed: Int) -> String {
        let colorOptions = [
            "washed indigo", "burnt sienna", "faded moss", "rich mahogany",
            "pale chamomile", "misty lavender", "storm grey", "warm terracotta",
            "dusty sage", "deep bordeaux", "weathered denim", "soft ochre",
            "antique ivory", "vintage cognac", "muted juniper", "hazy charcoal",
            "blushed clay", "stained walnut", "aged brass", "smoky quartz",
            "faded damson", "burnished copper", "sea glass", "deep olive",
            "washed saffron", "shadow mauve", "midnight navy", "sunlit amber",
            "cool teal", "sandstone", "dusty plum", "smoked pearl"
        ]
        
        return colorOptions[seed % colorOptions.count]
    }
    
    /// Get daily pattern emphasis
    static func getDailyPatternEmphasis(seed: Int) -> String {
        let patternOptions = [
            ", today especially fine pinstripes",
            ", with today's emphasis on tonal texture",
            ", focusing today on shadowed stripes",
            ", with attention to today's speckled details",
            ", incorporating today's subtle check pattern",
            ", with today's focus on irregular dots",
            ", emphasizing today organic textures",
            ", highlighting today's geometric simplicity",
            ", with today's emphasis on fluid stripes",
            ", focusing today on balanced asymmetry",
            ", leaning today toward textural contrast",
            ", with today's gentle gradients"
        ]
        
        return patternOptions[seed % patternOptions.count]
    }
    
    /// Get daily shape emphasis
    static func getDailyShapeEmphasis(seed: Int) -> String {
        let shapeOptions = [
            ", today emphasizing shoulder definition",
            ", with today's focus on sleeve volume",
            ", highlighting today's waist proportion",
            ", with attention to today's collar structure",
            ", with today's emphasis on sleeve length",
            ", focusing today on horizontal lines",
            ", with today's definition at the hip",
            ", emphasizing today vertical proportions",
            ", with today's attention to neckline shape",
            ", highlighting today's layering proportions",
            ", with today's focus on hem detail",
            ", emphasizing today's balance of fitted and fluid elements"
        ]
        
        return shapeOptions[seed % shapeOptions.count]
    }
    
    /// Get daily accessory emphasis
    static func getDailyAccessoryEmphasis(seed: Int) -> String {
        let accessoryOptions = [
            " with today's emphasis on wrist elements",
            " focusing today on neck adornment",
            " with special attention today to metals",
            " highlighting today the power of a single element",
            " with today's emphasis on natural materials",
            " focusing today on textural contrast",
            " with today's attention to meaningful objects",
            " considering today the symbolic weight",
            " with today's focus on handcrafted details",
            " emphasizing today personal significance",
            " with today's attention to organic forms",
            " highlighting today the interplay of scale"
        ]
        
        return accessoryOptions[seed % accessoryOptions.count]
    }
    
    // MARK: - Helper methods
    
    /// Helper function to sum digits in a number (for numerology)
    private static func sumDigits(_ number: Int) -> Int {
    var sum = 0
    var num = number

    while num > 0 {
        sum += num % 10
        num /= 10
    }

    // If sum is greater than 9, reduce to a single digit
    if sum > 9 {
        sum = sumDigits(sum)
    }

    return sum
    }
    
    /// Helper function to shuffle array with seed for consistent daily randomness
    private static func shuffleArrayWithSeed<T>(_ array: [T], seed: Int) -> [T] {
    var shuffled = array

    for i in 0..<shuffled.count {
        // Use consistent seed-based "random" swapping
        let j = (i * seed + 17) % shuffled.count
        if i != j {
            shuffled.swapAt(i, j)
        }
    }

    return shuffled
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
struct DailyVibeContent: Codable {
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
    
    // Weather information (optional)
    var temperature: Double? = nil
    var weatherCondition: String? = nil
}
