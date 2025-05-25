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
                if let planetarySource = token.planetarySource {
                    let freshnessBoost = applyFreshnessBoost(transitPlanet: planetarySource, aspectType: token.aspectSource ?? "")
                    
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
        let hasEthereal = tokens.contains { ($0.name == "ethereal" || $0.name == "dreamy") && $0.weight > 1.5 }
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.5 }
        let hasLayered = tokens.contains { $0.name == "layered" && $0.weight > 1.5 }
        let hasInstinctive = tokens.contains { ($0.name == "instinctive" || $0.name == "intuitive") && $0.weight > 1.5 }
        
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
        let finalWords = ["Surface", "Veil", "Noise", "Current", "Light", "Shadow", "Day", "Self", "Moment", "Form"]
        
        // Get title pattern using seed for daily variation
        let patterns = [
            "firstWord connectionWord finalWord",         // e.g. "Resonance Beneath Surface"
            "The firstWord of finalWord",                 // e.g. "The Flow of Light"
            "firstWord and finalWord",                    // e.g. "Structure and Shadow"
            "firstWord in finalWord",                     // e.g. "Depth in Motion"
            "firstWord meets finalWord",                  // e.g. "Form meets Function"
            "firstWord through finalWord"                 // e.g. "Light through Shadow"
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
        case "firstWord connectionWord finalWord":
            return "\(firstWord) \(connectionWord) \(finalWord)"
        case "The firstWord of finalWord":
            return "The \(firstWord) of \(finalWord)"
        case "firstWord and finalWord":
            return "\(firstWord) and \(finalWord)"
        case "firstWord in finalWord":
            return "\(firstWord) in \(finalWord)"
        case "firstWord meets finalWord":
            return "\(firstWord) meets \(finalWord)"
        case "firstWord through finalWord":
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
        let hasDreamy = tokens.contains { ($0.name == "dreamy" || $0.name == "ethereal") && $0.weight > 1.5 }
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.5 }
        let hasLayered = tokens.contains { $0.name == "layered" && $0.weight > 1.5 }
        let hasIntuitive = tokens.contains { ($0.name == "intuitive" || $0.name == "instinctive") && $0.weight > 1.5 }
        
        // Opening sentence variations based on pattern seed
        let openingPatterns = [
            "A QUALITY glows today, asking for ACTION without CONTRAST.",
            "Today carries a QUALITY current, inviting ACTION with COMPLEMENT.",
            "There's a QUALITY quality to today's energy, suggesting ACTION and COMPLEMENT.",
            "QUALITY weaves through today, encouraging a balance of ACTION and COMPLEMENT.",
            "The day unfolds with a QUALITY rhythm, connecting ACTION to COMPLEMENT."
        ]
        
        // Get opening pattern based on seed
        let openingPatternIndex = patternSeed % openingPatterns.count
        let openingPattern = openingPatterns[openingPatternIndex]
        
        // Create paragraph based on dominant characteristics
        var paragraph = ""
        
        // Fill in the opening pattern based on dominant characteristics
        var openingSentence = openingPattern
        
        if hasSubtle {
            openingSentence = openingSentence
                .replacingOccurrences(of: "QUALITY", with: "quiet smoulder")
                .replacingOccurrences(of: "ACTION", with: "warmth")
                .replacingOccurrences(of: "CONTRAST", with: "noise")
                .replacingOccurrences(of: "COMPLEMENT", with: "gentleness")
        } else if hasBold {
            openingSentence = openingSentence
                .replacingOccurrences(of: "QUALITY", with: "electric")
                .replacingOccurrences(of: "ACTION", with: "clarity")
                .replacingOccurrences(of: "CONTRAST", with: "hesitation")
                .replacingOccurrences(of: "COMPLEMENT", with: "presence")
        } else if hasFluid {
            openingSentence = openingSentence
                .replacingOccurrences(of: "QUALITY", with: "flowing")
                .replacingOccurrences(of: "ACTION", with: "adaptability")
                .replacingOccurrences(of: "CONTRAST", with: "rigidity")
                .replacingOccurrences(of: "COMPLEMENT", with: "intuitive ease")
        } else if hasStructured {
            openingSentence = openingSentence
                .replacingOccurrences(of: "QUALITY", with: "grounded")
                .replacingOccurrences(of: "ACTION", with: "intention")
                .replacingOccurrences(of: "CONTRAST", with: "chaos")
                .replacingOccurrences(of: "COMPLEMENT", with: "purpose")
        } else if hasDreamy {
            openingSentence = openingSentence
                .replacingOccurrences(of: "QUALITY", with: "misty")
                .replacingOccurrences(of: "ACTION", with: "trust")
                .replacingOccurrences(of: "CONTRAST", with: "the concrete")
                .replacingOccurrences(of: "COMPLEMENT", with: "the unseen")
        } else {
            openingSentence = openingSentence
                .replacingOccurrences(of: "QUALITY", with: "balanced")
                .replacingOccurrences(of: "ACTION", with: "harmony")
                .replacingOccurrences(of: "CONTRAST", with: "extremes")
                .replacingOccurrences(of: "COMPLEMENT", with: "expression")
        }
        
        paragraph += openingSentence + " "
        
        // Middle section variations based on pattern seed
        let middlePatterns = [
            "You're STATE. There's an FORCE pulling you DIRECTION to dress for your INTERNAL, not the EXTERNAL.",
            "You're meant to ACTION through MEDIUM. Your EXPRESSION should tell a story only you fully UNDERSTAND.",
            "Today asks you to embrace POSITIVE and release NEGATIVE. Your style can reflect this through ELEMENT1 and ELEMENT2.",
            "Find the courage to ACTION1 rather than ACTION2. Your appearance today is more about QUALITY1 than QUALITY2."
        ]
        
        // Get middle pattern based on seed
        let middlePatternIndex = (patternSeed * 3) % middlePatterns.count
        let middlePattern = middlePatterns[middlePatternIndex]
        
        // Fill in middle section based on secondary characteristics
        var middleSentence = middlePattern
        
        if hasEarthy && hasIntuitive {
            middleSentence = middleSentence
                .replacingOccurrences(of: "STATE", with: "not meant to burn bright—just burn real")
                .replacingOccurrences(of: "FORCE", with: "undercurrent")
                .replacingOccurrences(of: "DIRECTION", with: "inward")
                .replacingOccurrences(of: "INTERNAL", with: "inner world")
                .replacingOccurrences(of: "EXTERNAL", with: "outer gaze")
                .replacingOccurrences(of: "ACTION", with: "ground yourself")
                .replacingOccurrences(of: "MEDIUM", with: "earthen wisdom")
                .replacingOccurrences(of: "EXPRESSION", with: "choices")
                .replacingOccurrences(of: "UNDERSTAND", with: "understand")
        } else if hasLayered && hasMinimal {
            middleSentence = middleSentence
                .replacingOccurrences(of: "STATE", with: "meant to reveal through concealing")
                .replacingOccurrences(of: "FORCE", with: "tension")
                .replacingOccurrences(of: "DIRECTION", with: "toward simplicity")
                .replacingOccurrences(of: "INTERNAL", with: "essence")
                .replacingOccurrences(of: "EXTERNAL", with: "excess")
                .replacingOccurrences(of: "ACTION", with: "simplify")
                .replacingOccurrences(of: "MEDIUM", with: "careful restraint")
                .replacingOccurrences(of: "EXPRESSION", with: "layers")
                .replacingOccurrences(of: "UNDERSTAND", with: "perceive")
                .replacingOccurrences(of: "POSITIVE", with: "depth")
                .replacingOccurrences(of: "NEGATIVE", with: "flash")
                .replacingOccurrences(of: "ELEMENT1", with: "presence")
                .replacingOccurrences(of: "ELEMENT2", with: "layer by layer")
        } else if hasBold && hasLayered {
            middleSentence = middleSentence
                .replacingOccurrences(of: "STATE", with: "creating impact through depth")
                .replacingOccurrences(of: "FORCE", with: "energy")
                .replacingOccurrences(of: "DIRECTION", with: "outward")
                .replacingOccurrences(of: "INTERNAL", with: "fullness")
                .replacingOccurrences(of: "EXTERNAL", with: "surface")
                .replacingOccurrences(of: "POSITIVE", with: "depth")
                .replacingOccurrences(of: "NEGATIVE", with: "flash")
                .replacingOccurrences(of: "ELEMENT1", with: "presence")
                .replacingOccurrences(of: "ELEMENT2", with: "dimension")
                .replacingOccurrences(of: "ACTION1", with: "build")
                .replacingOccurrences(of: "ACTION2", with: "diminish")
                .replacingOccurrences(of: "QUALITY1", with: "presence")
                .replacingOccurrences(of: "QUALITY2", with: "projection")
        } else if hasFluid && hasIntuitive {
            middleSentence = middleSentence
                .replacingOccurrences(of: "STATE", with: "flowing with your instincts")
                .replacingOccurrences(of: "FORCE", with: "current")
                .replacingOccurrences(of: "DIRECTION", with: "naturally")
                .replacingOccurrences(of: "INTERNAL", with: "inner currents")
                .replacingOccurrences(of: "EXTERNAL", with: "expectations")
                .replacingOccurrences(of: "ACTION", with: "flow")
                .replacingOccurrences(of: "MEDIUM", with: "allowing")
                .replacingOccurrences(of: "EXPRESSION", with: "outer expression")
                .replacingOccurrences(of: "UNDERSTAND", with: "feel")
                .replacingOccurrences(of: "POSITIVE", with: "fluidity")
                .replacingOccurrences(of: "NEGATIVE", with: "rigidity")
                .replacingOccurrences(of: "ELEMENT1", with: "movement")
                .replacingOccurrences(of: "ELEMENT2", with: "ease")
                .replacingOccurrences(of: "ACTION1", with: "flow")
                .replacingOccurrences(of: "ACTION2", with: "force")
                .replacingOccurrences(of: "QUALITY1", with: "feeling")
                .replacingOccurrences(of: "QUALITY2", with: "thinking")
                } else {
                middleSentence = middleSentence
                .replacingOccurrences(of: "STATE", with: "finding balance between what you show and what you keep hidden")
                .replacingOccurrences(of: "FORCE", with: "energy")
                .replacingOccurrences(of: "DIRECTION", with: "authentically")
                .replacingOccurrences(of: "INTERNAL", with: "interior landscape")
                .replacingOccurrences(of: "EXTERNAL", with: "outside world")
                .replacingOccurrences(of: "ACTION", with: "express yourself")
                .replacingOccurrences(of: "MEDIUM", with: "authentic choices")
                .replacingOccurrences(of: "EXPRESSION", with: "style")
                .replacingOccurrences(of: "UNDERSTAND", with: "recognize")
                .replacingOccurrences(of: "POSITIVE", with: "authenticity")
                .replacingOccurrences(of: "NEGATIVE", with: "pretense")
                .replacingOccurrences(of: "ELEMENT1", with: "truth")
                .replacingOccurrences(of: "ELEMENT2", with: "presence")
                .replacingOccurrences(of: "ACTION1", with: "be")
                .replacingOccurrences(of: "ACTION2", with: "seem")
                .replacingOccurrences(of: "QUALITY1", with: "being")
                .replacingOccurrences(of: "QUALITY2", with: "appearing")
                }
                    paragraph += middleSentence + " "
                    
                    // Closing guidance variations based on pattern seed and moon phase
                    let closingPatterns = [
                        "It's a day to ACTION1 with QUALITY1, to carry ELEMENT1 like METAPHOR, and to resist the urge to ACTION2.",
                        "Today invites you to ACTION1 through MEDIUM, to embody QUALITY1 with QUALITY2, and to trust your GUIDE.",
                        "Consider how to ACTION your ELEMENT today, allowing FORCE to guide your EXPRESSION rather than CONTRAST.",
                        "The day's energy supports ELEMENT that ACTION, creating a sense of QUALITY1 without sacrificing QUALITY2."
                    ]
                    
                    // Get closing pattern based on seed
                    let closingPatternIndex = (patternSeed * 7) % closingPatterns.count
                    let closingPattern = closingPatterns[closingPatternIndex]
                    
                    // Fill in closing based on moon phase
                    var closingSentence = closingPattern
                    
                    if moonPhase < 90.0 {
                        // New Moon to First Quarter - beginnings, intentions
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "layer comfort")
                            .replacingOccurrences(of: "QUALITY1", with: "mystery")
                            .replacingOccurrences(of: "ELEMENT1", with: "softness")
                            .replacingOccurrences(of: "METAPHOR", with: "armor")
                            .replacingOccurrences(of: "ACTION2", with: "explain yourself")
                            .replacingOccurrences(of: "ACTION", with: "nurture")
                            .replacingOccurrences(of: "ELEMENT", with: "beginnings")
                            .replacingOccurrences(of: "MEDIUM", with: "gentle steps")
                            .replacingOccurrences(of: "QUALITY2", with: "intention")
                            .replacingOccurrences(of: "GUIDE", with: "inner compass")
                            .replacingOccurrences(of: "FORCE", with: "intuition")
                            .replacingOccurrences(of: "EXPRESSION", with: "emergence")
                            .replacingOccurrences(of: "CONTRAST", with: "haste")
                    } else if moonPhase < 180.0 {
                        // First Quarter to Full Moon - growth, expression
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "build presence")
                            .replacingOccurrences(of: "QUALITY1", with: "intention")
                            .replacingOccurrences(of: "ELEMENT1", with: "texture and form")
                            .replacingOccurrences(of: "METAPHOR", with: "clarity")
                            .replacingOccurrences(of: "ACTION2", with: "hold back")
                            .replacingOccurrences(of: "ACTION", with: "express")
                            .replacingOccurrences(of: "ELEMENT", with: "choices")
                            .replacingOccurrences(of: "MEDIUM", with: "confident steps")
                            .replacingOccurrences(of: "QUALITY2", with: "grace")
                            .replacingOccurrences(of: "GUIDE", with: "evolving intuition")
                            .replacingOccurrences(of: "FORCE", with: "momentum")
                            .replacingOccurrences(of: "EXPRESSION", with: "growth")
                            .replacingOccurrences(of: "CONTRAST", with: "doubt")
                    } else if moonPhase < 270.0 {
                        // Full Moon to Last Quarter - culmination, visibility
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "embody")
                            .replacingOccurrences(of: "QUALITY1", with: "fullness")
                            .replacingOccurrences(of: "ELEMENT1", with: "what you reveal")
                            .replacingOccurrences(of: "METAPHOR", with: "truth")
                            .replacingOccurrences(of: "ACTION2", with: "hide")
                            .replacingOccurrences(of: "ACTION", with: "illuminate")
                            .replacingOccurrences(of: "ELEMENT", with: "presence")
                            .replacingOccurrences(of: "MEDIUM", with: "full expression")
                            .replacingOccurrences(of: "QUALITY2", with: "authenticity")
                            .replacingOccurrences(of: "GUIDE", with: "authentic presence")
                            .replacingOccurrences(of: "FORCE", with: "clarity")
                            .replacingOccurrences(of: "EXPRESSION", with: "visibility")
                            .replacingOccurrences(of: "CONTRAST", with: "pretense")
                    } else {
                        // Last Quarter to New Moon - release, introspection
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "release")
                            .replacingOccurrences(of: "QUALITY1", with: "grace")
                            .replacingOccurrences(of: "ELEMENT1", with: "what no longer serves")
                            .replacingOccurrences(of: "METAPHOR", with: "water finding its level")
                            .replacingOccurrences(of: "ACTION2", with: "cling")
                            .replacingOccurrences(of: "ACTION", with: "simplify")
                            .replacingOccurrences(of: "ELEMENT", with: "release")
                            .replacingOccurrences(of: "MEDIUM", with: "letting go")
                            .replacingOccurrences(of: "QUALITY2", with: "wisdom")
                            .replacingOccurrences(of: "GUIDE", with: "inner knowing")
                            .replacingOccurrences(of: "FORCE", with: "release")
                            .replacingOccurrences(of: "EXPRESSION", with: "essence")
                            .replacingOccurrences(of: "CONTRAST", with: "attachment")
                    }
                    
                    paragraph += closingSentence + " "
                    
                    // Final statements with variations
                    let finalStatements = [
                        "What matters is how it feels, not how it looks from the outside. Trust the flicker in your gut.",
                        "The strongest style statements come from within. Let your inner knowing guide your choices today.",
                        "Your body already knows what it needs. Listen to that wisdom rather than external expectations.",
                        "The most powerful appearance is one that aligns with your authentic energy. Trust that alignment.",
                        "Style is a conversation between your inner and outer worlds. Make sure both voices are heard."
                    ]
                    
                    // Get final statement based on seed
                    let finalStatementIndex = (patternSeed * 11) % finalStatements.count
                    paragraph += finalStatements[finalStatementIndex]
                    
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
                    
                    // Get daily variation to fabric options
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
                    let selectedFabrics = Array(shuffledFabrics.prefix(selectedCount))
                    
                    // Create the fabric description
                    var description = selectedFabrics.joined(separator: ", ")
                    
                    // Add varied descriptive second sentences
                    let descriptivePatterns = [
                        "—anything that feels like QUALITY1 with a touch of QUALITY2. Choose ELEMENT that ACTION.",
                        "—anything with QUALITY1 and QUALITY2. Choose materials that ACTION1 while letting you ACTION2.",
                        "—anything that ACTION1 and ACTION2 to your movement. Choose fabrics that CREATE through METHOD.",
                        "—anything that ACTION through QUALITY1 rather than QUALITY2. Choose materials that FEEL against your skin."
                    ]
                    
                    let descriptivePatternIndex = (patternSeed * 13) % descriptivePatterns.count
                    let descriptivePattern = descriptivePatterns[descriptivePatternIndex]
                    
                    // Fill in descriptive pattern
                    var descriptiveSentence = descriptivePattern
                    
                    if hasSoft && hasTextured {
                        descriptiveSentence = descriptiveSentence
                            .replacingOccurrences(of: "QUALITY1", with: "second skin")
                            .replacingOccurrences(of: "QUALITY2", with: "shadow")
                            .replacingOccurrences(of: "ELEMENT", with: "tactile layers")
                            .replacingOccurrences(of: "ACTION", with: "soften the wind but hold your power close")
                            .replacingOccurrences(of: "ACTION1", with: "comfort")
                            .replacingOccurrences(of: "ACTION2", with: "protect")
                            .replacingOccurrences(of: "CREATE", with: "create comfort")
                            .replacingOccurrences(of: "METHOD", with: "gentle touch")
                            .replacingOccurrences(of: "FEEL", with: "whisper")
                    } else if hasStructured && hasEarthy {
                        descriptiveSentence = descriptiveSentence
                            .replacingOccurrences(of: "QUALITY1", with: "substance")
                            .replacingOccurrences(of: "QUALITY2", with: "character")
                            .replacingOccurrences(of: "ELEMENT", with: "materials")
                            .replacingOccurrences(of: "ACTION", with: "ground you while letting you move with intention")
                            .replacingOccurrences(of: "ACTION1", with: "ground you")
                            .replacingOccurrences(of: "ACTION2", with: "move with purpose")
                            .replacingOccurrences(of: "CREATE", with: "create stability")
                            .replacingOccurrences(of: "METHOD", with: "structured form")
                            .replacingOccurrences(of: "FEEL", with: "anchor")
                    } else if hasFluid && hasLayered {
                        descriptiveSentence = descriptiveSentence
                            .replacingOccurrences(of: "QUALITY1", with: "movement")
                            .replacingOccurrences(of: "QUALITY2", with: "adaptability")
                            .replacingOccurrences(of: "ACTION1", with: "flows")
                            .replacingOccurrences(of: "ACTION2", with: "adapts")
                            .replacingOccurrences(of: "CREATE", with: "create dimension")
                            .replacingOccurrences(of: "METHOD", with: "layering rather than weight")
                            .replacingOccurrences(of: "ACTION", with: "moves")
                            .replacingOccurrences(of: "FEEL", with: "flow")
                    } else if hasLuxurious {
                        descriptiveSentence = descriptiveSentence
                            .replacingOccurrences(of: "ACTION", with: "elevates")
                            .replacingOccurrences(of: "QUALITY1", with: "quality")
                            .replacingOccurrences(of: "QUALITY2", with: "refinement")
                            .replacingOccurrences(of: "ELEMENT", with: "pieces")
                            .replacingOccurrences(of: "ACTION1", with: "elevate")
                            .replacingOccurrences(of: "ACTION2", with: "express refinement")
                            .replacingOccurrences(of: "CREATE", with: "feel transformative")
                            .replacingOccurrences(of: "METHOD", with: "quality rather than flash")
                            .replacingOccurrences(of: "FEEL", with: "luxuriate")
                    } else {
                        descriptiveSentence = descriptiveSentence
                            .replacingOccurrences(of: "ACTION", with: "resonates with")
                            .replacingOccurrences(of: "QUALITY1", with: "comfort")
                            .replacingOccurrences(of: "QUALITY2", with: "expression")
                            .replacingOccurrences(of: "ELEMENT", with: "fabrics")
                            .replacingOccurrences(of: "ACTION1", with: "support")
                            .replacingOccurrences(of: "ACTION2", with: "express yourself")
                            .replacingOccurrences(of: "CREATE", with: "support")
                            .replacingOccurrences(of: "METHOD", with: "thoughtful selection")
                            .replacingOccurrences(of: "FEEL", with: "resonate")
                    }
                    
                    description += descriptiveSentence
                    
                    return description
                }

                /// Generate color recommendations
                static func generateColors(tokens: [StyleToken]) -> String {
                    // Extract relevant characteristics for color recommendations
                    let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.0 }
                    let hasWatery = tokens.contains { ($0.name == "watery" || $0.name == "fluid") && $0.weight > 1.0 }
                    let hasAiry = tokens.contains { $0.name == "airy" && $0.weight > 1.0 }
                    let hasFiery = tokens.contains { ($0.name == "fiery" || $0.name == "passionate") && $0.weight > 1.0 }
                    let hasDark = tokens.contains { ($0.name == "deep" || $0.name == "intense") && $0.weight > 1.0 }
                    let hasLight = tokens.contains { ($0.name == "light" || $0.name == "bright") && $0.weight > 1.0 }
                    let hasMuted = tokens.contains { ($0.name == "muted" || $0.name == "subtle") && $0.weight > 1.0 }
                    let hasVibrant = tokens.contains { ($0.name == "vibrant" || $0.name == "bold") && $0.weight > 1.0 }
                    
                    // Get daily color emphasis for variety
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
                        colorOptions.append(contentsOf: ["faded indigo", "dove gray", "dusty rose", "sage", "muted mauve", "ash gray"])
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
                    let selectedColors = Array(shuffledColors.prefix(selectedCount))
                    
                    // Create the color description
                    var description = selectedColors.joined(separator: ", ")
                    
                    // Add varied closing phrases
                    let closingPhrases = [
                        ". Let them ACTION1 the light, not ACTION2 it",
                        ". Let them ACTION with QUALITY presence",
                        ". Let them ACTION1 your energy with ACTION2",
                        ". Let them ACTION1 and ACTION2 your presence today",
                        ". Let them ACTION your QUALITY with subtle ELEMENT"
                    ]
                    
                    let closingPhraseIndex = (patternSeed * 19) % closingPhrases.count
                    let closingPhrase = closingPhrases[closingPhraseIndex]
                    
                    // Fill in closing phrase
                    var closingSentence = closingPhrase
                    
                    if hasDark || hasMuted {
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "absorb")
                            .replacingOccurrences(of: "ACTION2", with: "reflect")
                            .replacingOccurrences(of: "ACTION", with: "ground")
                            .replacingOccurrences(of: "QUALITY", with: "depth")
                            .replacingOccurrences(of: "ELEMENT", with: "power")
                    } else if hasLight || hasAiry {
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "diffuse")
                            .replacingOccurrences(of: "ACTION2", with: "scatter")
                            .replacingOccurrences(of: "ACTION", with: "lift")
                            .replacingOccurrences(of: "QUALITY", with: "subtle")
                            .replacingOccurrences(of: "ELEMENT", with: "radiance")
                    } else if hasVibrant || hasFiery {
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "express")
                            .replacingOccurrences(of: "ACTION2", with: "intention")
                            .replacingOccurrences(of: "ACTION", with: "radiate")
                            .replacingOccurrences(of: "QUALITY", with: "bold")
                            .replacingOccurrences(of: "ELEMENT", with: "energy")
                    } else {
                        closingSentence = closingSentence
                            .replacingOccurrences(of: "ACTION1", with: "ground")
                            .replacingOccurrences(of: "ACTION2", with: "center")
                            .replacingOccurrences(of: "ACTION", with: "balance")
                            .replacingOccurrences(of: "QUALITY", with: "presence")
                            .replacingOccurrences(of: "ELEMENT", with: "harmony")
                    }
                    
                    description += closingSentence
                    
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
                    
                    // Add small daily variation for freshness
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
                    
                    // Add small daily variation for freshness
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
                    let hasExpressive = tokens.contains { ($0.name == "expressive" || $0.name == "bold") && $0.weight > 1.0 }
                    let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
                    let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.0 }
                    let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 1.0 }
                    let hasEclectic = tokens.contains { ($0.name == "eclectic" || $0.name == "unique") && $0.weight > 1.0 }
                    
                    // Get daily pattern emphasis
                    let patternSeed = getDailyPatternSeed()
                    let dailyPatternEmphasis = getDailyPatternEmphasis(seed: patternSeed)
                    
                    // Pattern suggestions based on characteristics and daily emphasis
                    var patterns = ""
                    let seedMod = patternSeed % 4
                    
                    if hasMinimal && hasTextured {
                        if seedMod == 0 {
                            patterns = "Uneven dye effects (stonewash, acid, mineral)\(dailyPatternEmphasis). Minimal prints that feel faded or lived-in—nothing polished or loud."
                        } else if seedMod == 1 {
                            patterns = "Today favors uneven dye effects (stonewash, acid, mineral)\(dailyPatternEmphasis). Minimal prints that feel faded or lived-in."
                        } else if seedMod == 2 {
                            patterns = "Consider uneven dye effects (stonewash, acid, mineral)\(dailyPatternEmphasis). These create texture without overwhelming."
                        } else {
                            patterns = "Uneven dye effects (stonewash, acid, mineral)\(dailyPatternEmphasis). Let these patterns connect with subtlety."
                        }
                    } else if hasExpressive && hasEclectic {
                        if seedMod == 0 {
                            patterns = "Bold geometrics, unexpected color combinations\(dailyPatternEmphasis). Statement prints that tell a story or reference art—each with a clear point of view."
                        } else if seedMod == 1 {
                            patterns = "Today favors bold geometrics, unexpected color combinations\(dailyPatternEmphasis). Statement prints that tell a story or reference art."
                        } else if seedMod == 2 {
                            patterns = "Consider bold geometrics, unexpected color combinations\(dailyPatternEmphasis). These create impact without overwhelming."
                        } else {
                            patterns = "Bold geometrics, unexpected color combinations\(dailyPatternEmphasis). Let these patterns speak with intention."
                        }
                    } else if hasStructured && hasMinimal {
                        if seedMod == 0 {
                            patterns = "Architectural lines, subtle grids\(dailyPatternEmphasis). Patterns with mathematical order rather than organic flow."
                        } else if seedMod == 1 {
                            patterns = "Today favors architectural lines, subtle grids\(dailyPatternEmphasis). Patterns with mathematical order."
                        } else if seedMod == 2 {
                            patterns = "Consider architectural lines, subtle grids\(dailyPatternEmphasis). These create structure without complexity."
                        } else {
                            patterns = "Architectural lines, subtle grids\(dailyPatternEmphasis). Let these patterns bring order with elegance."
                        }
                    } else if hasFluid && hasExpressive {
                        if seedMod == 0 {
                            patterns = "Watercolor effects, organic forms\(dailyPatternEmphasis). Patterns that move and flow with a sense of natural rhythm."
                        } else if seedMod == 1 {
                            patterns = "Today favors watercolor effects, organic forms\(dailyPatternEmphasis). Patterns that move and flow."
                        } else if seedMod == 2 {
                            patterns = "Consider watercolor effects, organic forms\(dailyPatternEmphasis). These create movement without constraint."
                        } else {
                            patterns = "Watercolor effects, organic forms\(dailyPatternEmphasis). Let these patterns flow with your movements."
                        }
                    } else if hasSubtle {
                        if seedMod == 0 {
                            patterns = "Barely-there textures, monochromatic tone-on-tone\(dailyPatternEmphasis). Patterns that reveal themselves only upon closer inspection."
                        } else if seedMod == 1 {
                            patterns = "Today favors barely-there textures, monochromatic tone-on-tone\(dailyPatternEmphasis). Patterns that reveal themselves."
                        } else if seedMod == 2 {
                            patterns = "Consider barely-there textures, monochromatic tone-on-tone\(dailyPatternEmphasis). These create depth without distraction."
                        } else {
                            patterns = "Barely-there textures, monochromatic tone-on-tone\(dailyPatternEmphasis). Let these patterns whisper rather than shout."
                        }
                    } else if hasEclectic {
                        if seedMod == 0 {
                            patterns = "Unexpected combinations, vintage-inspired motifs\(dailyPatternEmphasis). Mix patterns of different scales for a curated eclectic approach."
                        } else if seedMod == 1 {
                            patterns = "Today favors unexpected combinations, vintage-inspired motifs\(dailyPatternEmphasis). Mix patterns of different scales."
                        } else if seedMod == 2 {
                            patterns = "Consider unexpected combinations, vintage-inspired motifs\(dailyPatternEmphasis). These create interest without chaos."
                        } else {
                            patterns = "Unexpected combinations, vintage-inspired motifs\(dailyPatternEmphasis). Let these patterns tell your unique story."
                        }
                    } else {
                        if seedMod == 0 {
                            patterns = "Balanced, intentional patterns\(dailyPatternEmphasis). Choose prints that feel authentic to your energy today."
                        } else if seedMod == 1 {
                            patterns = "Today favors balanced, intentional patterns\(dailyPatternEmphasis). Choose prints that feel authentic."
                        } else if seedMod == 2 {
                            patterns = "Consider balanced, intentional patterns\(dailyPatternEmphasis). These create harmony without overwhelming."
                        } else {
                            patterns = "Balanced, intentional patterns\(dailyPatternEmphasis). Let these patterns enhance your natural presence."
                        }
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
                    let hasExpressive = tokens.contains { ($0.name == "expressive" || $0.name == "bold") && $0.weight > 1.0 }
                    let hasBalanced = tokens.contains { $0.name == "balanced" && $0.weight > 1.0 }
                    let hasProtective = tokens.contains { $0.name == "protective" && $0.weight > 1.0 }
                    
                    // Get daily shape emphasis
                    let patternSeed = getDailyPatternSeed()
                    let dailyShapeEmphasis = getDailyShapeEmphasis(seed: patternSeed)
                    
                    // Shape description based on characteristics and daily emphasis
                    var shape = ""
                    let seedMod = patternSeed % 4
                    
                    if hasStructured && hasProtective {
                        if seedMod == 0 {
                            shape = "Cocooned, but defined\(dailyShapeEmphasis). A wrap coat with structure. Layer your look like secrets stacked: fitted base, fluid overlay, something sculptural to finish."
                        } else if seedMod == 1 {
                            shape = "Cocooned, but defined\(dailyShapeEmphasis). Consider a wrap coat with structure that moves with your body as you move."
                        } else if seedMod == 2 {
                            shape = "Today's energy favors cocooned, but defined forms\(dailyShapeEmphasis). A wrap coat with structure that protects rather than restricts."
                        } else {
                            shape = "Focus on cocooned, but defined shapes\(dailyShapeEmphasis). Create structure through layered elements."
                        }
                    } else if hasFluid && hasLayered {
                        if seedMod == 0 {
                            shape = "Flowing layers with intentional drape\(dailyShapeEmphasis). Pieces that breathe. Movement is key, restriction is counterproductive."
                        } else if seedMod == 1 {
                            shape = "Flowing layers with intentional drape\(dailyShapeEmphasis). Consider pieces that move with your body as you move."
                        } else if seedMod == 2 {
                            shape = "Today's energy favors flowing layers with intentional drape\(dailyShapeEmphasis). Pieces that move with your body rather than constrain."
                        } else {
                            shape = "Focus on flowing layers with intentional drape\(dailyShapeEmphasis). Create movement through thoughtful layering."
                        }
                    } else if hasMinimal && hasBalanced {
                        if seedMod == 0 {
                            shape = "Clean lines with precise proportion\(dailyShapeEmphasis). The relationship between pieces matters. Quality over quantity, space over clutter."
                        } else if seedMod == 1 {
                            shape = "Clean lines with precise proportion\(dailyShapeEmphasis). Consider the relationship between pieces that balance as you move."
                        } else if seedMod == 2 {
                            shape = "Today's energy favors clean lines with precise proportion\(dailyShapeEmphasis). The relationship between pieces rather than individual statements."
                        } else {
                            shape = "Focus on clean lines with precise proportion\(dailyShapeEmphasis). Create harmony through balanced elements."
                        }
                    } else if hasExpressive && hasLayered {
                        if seedMod == 0 {
                            shape = "Bold volume balanced with definition\(dailyShapeEmphasis). Dimension through contrast. Fitted against full, structured against fluid."
                        } else if seedMod == 1 {
                            shape = "Bold volume balanced with definition\(dailyShapeEmphasis). Consider dimension through contrast that evolves as you move."
                        } else if seedMod == 2 {
                            shape = "Today's energy favors bold volume balanced with definition\(dailyShapeEmphasis). Dimension through contrast rather than uniformity."
                        } else {
                            shape = "Focus on bold volume balanced with definition\(dailyShapeEmphasis). Create dimension through contrasting elements."
                        }
                    } else if hasProtective {
                        if seedMod == 0 {
                            shape = "Protective without restriction\(dailyShapeEmphasis). Forms that create personal space. Soft armor that moves with you, not against you."
                        } else if seedMod == 1 {
                            shape = "Protective without restriction\(dailyShapeEmphasis). Consider forms that create personal space that adapts as you move."
                        } else if seedMod == 2 {
                            shape = "Today's energy favors protective without restriction\(dailyShapeEmphasis). Forms that create personal space while allowing movement."
                        } else {
                            shape = "Focus on protective without restriction\(dailyShapeEmphasis). Create personal space through thoughtful construction."
                        }
                    } else {
                        if seedMod == 0 {
                            shape = "Balanced proportions that honor your body's needs today\(dailyShapeEmphasis). A silhouette that supports your energy. Neither constricting nor obscuring."
                        } else if seedMod == 1 {
                            shape = "Balanced proportions that honor your body's needs today\(dailyShapeEmphasis). Consider a silhouette that supports your energy as you move."
                        } else if seedMod == 2 {
                            shape = "Today's energy favors balanced proportions that honor your body's needs\(dailyShapeEmphasis). A silhouette that supports your energy rather than forcing it into a predetermined shape."
                        } else {
                            shape = "Focus on balanced proportions that honor your body's needs today\(dailyShapeEmphasis). Create support through thoughtful silhouettes."
                        }
                    }
                    
                    return shape
                }

                /// Generate accessories recommendations
                static func generateAccessories(tokens: [StyleToken]) -> String {
                    // Extract relevant characteristics for accessories recommendations
                    let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 1.0 }
                    let hasExpressive = tokens.contains { ($0.name == "expressive" || $0.name == "bold") && $0.weight > 1.0 }
                    let hasProtective = tokens.contains { $0.name == "protective" && $0.weight > 1.0 }
                    let hasEclectic = tokens.contains { ($0.name == "eclectic" || $0.name == "unique") && $0.weight > 1.0 }
                    let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
                    let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.0 }
                    let hasWatery = tokens.contains { ($0.name == "watery" || $0.name == "fluid") && $0.weight > 1.0 }
                    
                    // Get daily accessory emphasis
                    let patternSeed = getDailyPatternSeed()
                    let dailyAccessoryEmphasis = getDailyAccessoryEmphasis(seed: patternSeed)
                    
                    // Accessories description based on characteristics
                    var accessories = ""
                    
                    // Add varied accessory descriptions based on seed
                    let accessoryDescriptions = [
                        "ITEM, and it must ACTION—MEANING. DETAIL. FRAGRANCE: SCENT.",
                        "ITEM with QUALITY. Items that ACTION1 and ACTION2. DETAIL. FRAGRANCE: SCENT.",
                        "Choose ITEM that ACTION. CREATE through QUALITY1 and QUALITY2. FRAGRANCE: SCENT.",
                        "Accessories that ACTION1 to ACTION2 through the day. ITEM that QUALITY. FRAGRANCE: SCENT."
                    ]
                    
                    let accessoryDescriptionIndex = (patternSeed * 11) % accessoryDescriptions.count
                    let accessoryDescription = accessoryDescriptions[accessoryDescriptionIndex]
                    
                    // Fill in accessory description
                    var accessorySentence = accessoryDescription
                    
                    if hasMinimal && hasProtective {
                        accessorySentence = accessorySentence
                            .replacingOccurrences(of: "ITEM", with: "One object only" + dailyAccessoryEmphasis)
                            .replacingOccurrences(of: "ACTION", with: "mean something")
                            .replacingOccurrences(of: "MEANING", with: "your protective piece")
                            .replacingOccurrences(of: "DETAIL", with: "A locket, a band, a scent worn like armor. No flash. Just focus")
                            .replacingOccurrences(of: "FRAGRANCE", with: "Fragrance")
                            .replacingOccurrences(of: "SCENT", with: "vetiver, resin, or something bitter-green")
                            .replacingOccurrences(of: "QUALITY", with: "personal significance")
                            .replacingOccurrences(of: "ACTION1", with: "protect")
                            .replacingOccurrences(of: "ACTION2", with: "define")
                            .replacingOccurrences(of: "CREATE", with: "Create protection")
                            .replacingOccurrences(of: "QUALITY1", with: "intention")
                            .replacingOccurrences(of: "QUALITY2", with: "restraint")
                    } else if hasExpressive && hasEclectic {
                        accessorySentence = accessorySentence
                            .replacingOccurrences(of: "ITEM", with: "Statement pieces" + dailyAccessoryEmphasis)
                            .replacingOccurrences(of: "ACTION", with: "tell stories")
                            .replacingOccurrences(of: "MEANING", with: "conversation starters")
                            .replacingOccurrences(of: "DETAIL", with: "Focus on one primary focal point balanced by subtle supporting elements")
                            .replacingOccurrences(of: "FRAGRANCE", with: "Fragrance")
                            .replacingOccurrences(of: "SCENT", with: "spiced citrus, rich amber, or something unexpectedly botanical")
                            .replacingOccurrences(of: "QUALITY", with: "personal significance")
                            .replacingOccurrences(of: "ACTION1", with: "invite questions")
                            .replacingOccurrences(of: "ACTION2", with: "create connection")
                            .replacingOccurrences(of: "CREATE", with: "Express yourself")
                            .replacingOccurrences(of: "QUALITY1", with: "boldness")
                            .replacingOccurrences(of: "QUALITY2", with: "intention")
                    } else if hasStructured && hasEarthy {
                        accessorySentence = accessorySentence
                            .replacingOccurrences(of: "ITEM", with: "Natural materials" + dailyAccessoryEmphasis)
                            .replacingOccurrences(of: "ACTION", with: "ground you")
                            .replacingOccurrences(of: "QUALITY", with: "clear purpose")
                            .replacingOccurrences(of: "ACTION1", with: "ground")
                            .replacingOccurrences(of: "ACTION2", with: "center")
                            .replacingOccurrences(of: "DETAIL", with: "Consider pieces with weight and texture")
                            .replacingOccurrences(of: "FRAGRANCE", with: "Fragrance")
                            .replacingOccurrences(of: "SCENT", with: "cedarwood, tobacco, or something mineral-based")
                            .replacingOccurrences(of: "CREATE", with: "Ground yourself")
                            .replacingOccurrences(of: "QUALITY1", with: "substance")
                            .replacingOccurrences(of: "QUALITY2", with: "authenticity")
                    } else if hasWatery && hasProtective {
                        accessorySentence = accessorySentence
                            .replacingOccurrences(of: "ITEM", with: "Fluid forms" + dailyAccessoryEmphasis)
                            .replacingOccurrences(of: "ACTION", with: "flow with you")
                            .replacingOccurrences(of: "ACTION1", with: "move with you")
                            .replacingOccurrences(of: "ACTION2", with: "adapt")
                            .replacingOccurrences(of: "QUALITY", with: "adapt to different contexts")
                            .replacingOccurrences(of: "DETAIL", with: "Consider pieces with emotional resonance that anchor your shifting states")
                            .replacingOccurrences(of: "FRAGRANCE", with: "Fragrance")
                            .replacingOccurrences(of: "SCENT", with: "salt air, clean musk, or something aquatic but warm")
                            .replacingOccurrences(of: "CREATE", with: "Create flow")
                            .replacingOccurrences(of: "QUALITY1", with: "fluidity")
                            .replacingOccurrences(of: "QUALITY2", with: "protection")
                    } else {
                        accessorySentence = accessorySentence
                            .replacingOccurrences(of: "ITEM", with: "Intentional selections" + dailyAccessoryEmphasis)
                            .replacingOccurrences(of: "ACTION", with: "enhance rather than distract")
                            .replacingOccurrences(of: "ACTION1", with: "feel like natural extensions of your energy")
                            .replacingOccurrences(of: "ACTION2", with: "support your presence")
                            .replacingOccurrences(of: "QUALITY", with: "resonate with your current state")
                            .replacingOccurrences(of: "DETAIL", with: "Choose pieces that resonate with your current state")
                            .replacingOccurrences(of: "FRAGRANCE", with: "Fragrance")
                            .replacingOccurrences(of: "SCENT", with: "something that resonates with your skin chemistry and emotional state today")
                            .replacingOccurrences(of: "CREATE", with: "Express yourself")
                            .replacingOccurrences(of: "QUALITY1", with: "authenticity")
                            .replacingOccurrences(of: "QUALITY2", with: "intention")
                    }
                    
                    accessories = accessorySentence
                    
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
                    
                    // Add daily variations
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
                    
                    // Use seed for daily weight variations (subtle but consistent)
                    let weightVariation = 1.0 + (Double(seed % 21) - 10.0) / 100.0 // ±10% variation
                    
                    switch weekday {
                    case 1: // Sunday (Sun)
                        tokens.append(StyleToken(
                            name: "illuminated",
                            type: "texture",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Sun Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "radiant",
                            type: "color_quality",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Sun Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "amber gold",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Sun Day",
                            originType: .transit
                        ))
                        
                    case 2: // Monday (Moon)
                        tokens.append(StyleToken(
                            name: "reflective",
                            type: "mood",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Moon Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "intuitive",
                            type: "structure",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Moon Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "pearl silver",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Moon Day",
                            originType: .transit
                        ))
                        
                    case 3: // Tuesday (Mars)
                        tokens.append(StyleToken(
                            name: "energetic",
                            type: "mood",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Mars Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "structure",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Mars Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "ruby red",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Mars Day",
                            originType: .transit
                        ))
                        
                    case 4: // Wednesday (Mercury)
                        tokens.append(StyleToken(
                            name: "communicative",
                            type: "mood",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Mercury Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "versatile",
                            type: "structure",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Mercury Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "quicksilver",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Mercury Day",
                            originType: .transit
                        ))
                        
                    case 5: // Thursday (Jupiter)
                        tokens.append(StyleToken(
                            name: "expansive",
                            type: "mood",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Jupiter Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "abundant",
                            type: "structure",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Jupiter Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "royal blue",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Jupiter Day",
                            originType: .transit
                        ))
                        
                    case 6: // Friday (Venus)
                        tokens.append(StyleToken(
                            name: "harmonious",
                            type: "mood",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Venus Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "structure",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Venus Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "emerald",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Venus Day",
                            originType: .transit
                        ))
                        
                    case 7: // Saturday (Saturn)
                        tokens.append(StyleToken(
                            name: "structured",
                            type: "mood",
                            weight: 2.2 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Saturn Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "enduring",
                            type: "structure",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Saturn Day",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "obsidian",
                            type: "color",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Saturn Day",
                            originType: .transit
                        ))
                        
                    default:
                        tokens.append(StyleToken(
                            name: "balanced",
                            type: "mood",
                            weight: 2.0 * weightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Energy",
                            originType: .transit
                        ))
                    }

                    // Add temporal markers (season, time of day)
                    let month = calendar.component(.month, from: Date())
                    let hour = calendar.component(.hour, from: Date())

                    // Seasonal influence with seed-based weight variation
                    let seasonalWeightVariation = 1.0 + (Double((seed * 7) % 21) - 10.0) / 100.0
                    
                    switch month {
                    case 3...5: // Spring
                        tokens.append(StyleToken(
                            name: "emerging",
                            type: "structure",
                            weight: 1.8 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Spring Energy",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "fresh",
                            type: "texture",
                            weight: 1.7 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Spring Energy",
                            originType: .transit
                        ))
                        
                    case 6...8: // Summer
                        tokens.append(StyleToken(
                            name: "expansive",
                            type: "structure",
                            weight: 1.8 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Summer Energy",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "vibrant",
                            type: "color_quality",
                            weight: 1.7 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Summer Energy",
                            originType: .transit
                        ))
                        
                    case 9...11: // Fall
                        tokens.append(StyleToken(
                            name: "layered",
                            type: "structure",
                            weight: 1.8 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Autumn Energy",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "transitional",
                            type: "texture",
                            weight: 1.7 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Autumn Energy",
                            originType: .transit
                        ))
                        
                    default: // Winter (12, 1, 2)
                        tokens.append(StyleToken(
                            name: "protective",
                            type: "structure",
                            weight: 1.8 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Winter Energy",
                            originType: .transit
                        ))
                        tokens.append(StyleToken(
                            name: "insulating",
                            type: "texture",
                            weight: 1.7 * seasonalWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Winter Energy",
                            originType: .transit
                        ))
                    }

                    // Time of day influence with seed-based weight variation
                    let timeWeightVariation = 1.0 + (Double((seed * 11) % 21) - 10.0) / 100.0
                    
                    if hour >= 5 && hour < 12 {
                        // Morning
                        tokens.append(StyleToken(
                            name: "fresh",
                            type: "mood",
                            weight: 1.6 * timeWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Morning Energy",
                            originType: .transit
                        ))
                    } else if hour >= 12 && hour < 17 {
                        // Afternoon
                        tokens.append(StyleToken(
                            name: "active",
                            type: "mood",
                            weight: 1.6 * timeWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Afternoon Energy",
                            originType: .transit
                        ))
                    } else if hour >= 17 && hour < 22 {
                        // Evening
                        tokens.append(StyleToken(
                            name: "mellow",
                            type: "mood",
                            weight: 1.6 * timeWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Evening Energy",
                            originType: .transit
                        ))
                    } else {
                        // Night
                        tokens.append(StyleToken(
                            name: "introspective",
                            type: "mood",
                            weight: 1.6 * timeWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Night Energy",
                            originType: .transit
                        ))
                    }

                    // Add lunar day influence (1-29.5)
                    let lunarDate = calendar.dateComponents([.day], from: Date()).day ?? 1
                    let lunarDay = (lunarDate % 30) + 1

                    // Lunar weight variation using seed
                    let lunarWeightVariation = 1.0 + (Double((seed * 13) % 21) - 10.0) / 100.0
                    
                    if lunarDay <= 7 {
                        // Waxing crescent - beginning energy
                        tokens.append(StyleToken(
                            name: "initiating",
                            type: "mood",
                            weight: 1.5 * lunarWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Lunar Day \(lunarDay)",
                            originType: .transit
                        ))
                    } else if lunarDay <= 14 {
                        // Waxing gibbous - building energy
                        tokens.append(StyleToken(
                            name: "developing",
                            type: "mood",
                            weight: 1.5 * lunarWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Lunar Day \(lunarDay)",
                            originType: .transit
                        ))
                    } else if lunarDay <= 21 {
                        // Waning gibbous - expressing energy
                        tokens.append(StyleToken(
                            name: "expressing",
                            type: "mood",
                            weight: 1.5 * lunarWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Lunar Day \(lunarDay)",
                            originType: .transit
                        ))
                    } else {
                        // Waning crescent - releasing energy
                        tokens.append(StyleToken(
                            name: "releasing",
                            type: "mood",
                            weight: 1.5 * lunarWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Lunar Day \(lunarDay)",
                            originType: .transit
                        ))
                    }

                    // Daily numerical influence (based on day number) with seed variation
                    let dayNumber = calendar.dateComponents([.day], from: Date()).day ?? 1
                    let dayDigitSum = sumDigits(dayNumber)
                    let numerologyWeightVariation = 1.0 + (Double((seed * 17) % 21) - 10.0) / 100.0

                    // Numerological influence
                    switch dayDigitSum {
                    case 1:
                        tokens.append(StyleToken(
                            name: "pioneering",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 1",
                            originType: .transit
                        ))
                    case 2:
                        tokens.append(StyleToken(
                            name: "receptive",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 2",
                            originType: .transit
                        ))
                    case 3:
                        tokens.append(StyleToken(
                            name: "expressive",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 3",
                            originType: .transit
                        ))
                    case 4:
                        tokens.append(StyleToken(
                            name: "structured",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 4",
                            originType: .transit
                        ))
                    case 5:
                        tokens.append(StyleToken(
                            name: "dynamic",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 5",
                            originType: .transit
                        ))
                    case 6:
                        tokens.append(StyleToken(
                            name: "harmonious",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 6",
                            originType: .transit
                        ))
                    case 7:
                        tokens.append(StyleToken(
                            name: "reflective",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 7",
                            originType: .transit
                        ))
                    case 8:
                        tokens.append(StyleToken(
                            name: "powerful",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 8",
                            originType: .transit
                        ))
                    case 9:
                        tokens.append(StyleToken(
                            name: "completing",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Number 9",
                            originType: .transit
                        ))
                    default:
                        tokens.append(StyleToken(
                            name: "flexible",
                            type: "mood",
                            weight: 1.4 * numerologyWeightVariation,
                            planetarySource: "Daily Signature",
                            aspectSource: "Day Energy",
                            originType: .transit
                        ))
                    }
                    
                    // Add additional daily variation tokens based on seed
                    let dailyVariationTokens = [
                        "resonant", "calibrated", "attuned", "aligned", "grounded",
                        "elevated", "centered", "focused", "integrated", "balanced"
                    ]
                    
                    let selectedVariationToken = dailyVariationTokens[seed % dailyVariationTokens.count]
                    tokens.append(StyleToken(
                        name: selectedVariationToken,
                        type: "mood",
                        weight: 1.3,
                        planetarySource: "Daily Signature",
                        aspectSource: "Daily Variation (seed: \(seed))",
                        originType: .transit
                    ))

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

                    // Add 1-2 daily wildcard tokens using the seed
                    let wildcardOptions = [
                        "unexpected", "juxtaposed", "nuanced", "transitional",
                        "distinctive", "paradoxical", "intuitive", "emergent",
                        "responsive", "calibrated", "resonant", "harmonized",
                        "textured", "articulated", "considered", "attentive"
                    ]

                    let wildcard1 = wildcardOptions[seed % wildcardOptions.count]
                    
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
                        let wildcard2 = wildcardOptions[(seed * 7) % wildcardOptions.count]
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
                        "pale chamomile", "misty lavender", "storm gray", "warm terracotta",
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
