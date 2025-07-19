//
//  DailyVibeGenerator.swift
//  Cosmic Fit
//
//  Created for Daily Vibe implementation - FIXED VERSION
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
        
        // Generate Style Brief instead of title and mainParagraph
        content.styleBrief = generateStyleBrief(tokens: tokens, moonPhase: moonPhase, patternSeed: patternSeed)
        
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
    
    /// Generate a Style Brief in Maria's authentic voice with daily variation and no repeats
    internal static func generateStyleBrief(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
        
        // STEP 1: Analyze token categories and weights
        let tokenAnalysis = analyzeTokens(tokens)
        
        // STEP 2: Create daily signature for uniqueness
        let dailySignature = createDailySignature(from: tokenAnalysis, moonPhase: moonPhase, patternSeed: patternSeed)
        
        // DEBUG: Output token analysis to console
        debugTokenAnalysis(tokenAnalysis, dailySignature: dailySignature)
        
        // STEP 3: Find the precise combination that matches today's unique energy
        let styleBrief = selectPreciseStyleBrief(from: tokenAnalysis, dailySignature: dailySignature, patternSeed: patternSeed)
        
        return styleBrief
    }
    
    // MARK: - Daily Signature Structure
    private struct DailySignature {
        let moonPhaseEnergy: String      // "building", "peak", "releasing", "renewal"
        let planetaryDay: String         // "Venus", "Jupiter", "Mars", etc.
        let dominantMood: String         // "responsive", "calibrated", "harmonious", etc.
        let energyIntensity: String      // "subtle", "moderate", "intense"
        let transitPressure: String      // "evolving", "stable", "transforming"
        let seasonalInfluence: String    // "expansive", "grounded", "flowing"
        let uniqueKey: String           // Combination key for no-repeat tracking
    }
    
    // keep pasting from Claude chat here -->
    
    // MARK: - Enhanced Token Analysis Structure
    private struct TokenAnalysis {
        // Existing properties...
        let dominantStructure: [String: Double]
        let dominantMood: [String: Double]
        let dominantTexture: [String: Double]
        let dominantColorQuality: [String: Double]
        let dominantExpression: [String: Double]
        
        // Enhanced daily detection
        let moonPhaseTokens: [String: Double]
        let dailySignatureTokens: [String: Double]
        let temporalTokens: [String: Double]
        let transitTokens: [String: Double]
        
        // Key combinations (existing)
        let isFluidAndIntuitive: Bool
        let isSensualAndLuxurious: Bool
        let isGroundedAndPractical: Bool
        let isInnovativeAndUnconventional: Bool
        let isResponsiveAndAdaptable: Bool
        let isDreamyAndEthereal: Bool
        let isRichAndVibrant: Bool
        let isSubtleAndNuanced: Bool
        let isExpansiveAndAbundant: Bool
        let isComfortableAndSoft: Bool
        
        // NEW: Daily-specific combinations
        let isReflectiveAndDissolving: Bool
        let isHarmoniousAndBalanced: Bool
        let isCalibratedAndSubtle: Bool
        let isExpansiveAndFresh: Bool
        let isCompletingAndSubstantial: Bool
        let isEmergingAndElevated: Bool
        
        // Primary characteristics
        let primaryStructure: String?
        let primaryMood: String?
        let primaryTexture: String?
        let primaryColorQuality: String?
        let primaryExpression: String?
        
        // Overall energy assessment
        let overallWeight: Double
        let energyDirection: String
    }
    
    // MARK: - Daily Signature Creation
    private static func createDailySignature(from analysis: TokenAnalysis, moonPhase: Double, patternSeed: Int) -> DailySignature {
        
        // Determine moon phase energy
        let moonPhaseEnergy: String
        if moonPhase < 90 {
            moonPhaseEnergy = "renewal"       // New Moon to First Quarter
        } else if moonPhase < 180 {
            moonPhaseEnergy = "building"      // First Quarter to Full Moon
        } else if moonPhase < 270 {
            moonPhaseEnergy = "releasing"     // Full Moon to Last Quarter
        } else {
            moonPhaseEnergy = "reflection"    // Last Quarter to New Moon
        }
        
        // Extract planetary day from daily signature tokens
        let planetaryDay = extractPlanetaryDay(from: analysis.dailySignatureTokens)
        
        // Get dominant mood (most weighted mood token)
        let dominantMood = analysis.primaryMood ?? "balanced"
        
        // Determine energy intensity from overall token weights
        let energyIntensity: String
        if analysis.overallWeight > 15.0 {
            energyIntensity = "intense"
        } else if analysis.overallWeight > 10.0 {
            energyIntensity = "moderate"
        } else {
            energyIntensity = "subtle"
        }
        
        // Assess transit pressure from evolving tokens
        let evolvingWeight = analysis.dominantColorQuality["evolving"] ?? 0.0
        let transitPressure: String
        if evolvingWeight > 0.5 {
            transitPressure = "transforming"
        } else if evolvingWeight > 0.2 {
            transitPressure = "evolving"
        } else {
            transitPressure = "stable"
        }
        
        // Extract seasonal influence from temporal tokens
        let seasonalInfluence = extractSeasonalInfluence(from: analysis.temporalTokens)
        
        // Create unique key for no-repeat tracking
        let uniqueKey = "\(moonPhaseEnergy)_\(planetaryDay)_\(dominantMood)_\(energyIntensity)_\(patternSeed % 7)"
        
        return DailySignature(
            moonPhaseEnergy: moonPhaseEnergy,
            planetaryDay: planetaryDay,
            dominantMood: dominantMood,
            energyIntensity: energyIntensity,
            transitPressure: transitPressure,
            seasonalInfluence: seasonalInfluence,
            uniqueKey: uniqueKey
        )
    }

    // MARK: - Enhanced Token Analysis
    private static func analyzeTokens(_ tokens: [StyleToken]) -> TokenAnalysis {
        var dominantStructure: [String: Double] = [:]
        var dominantMood: [String: Double] = [:]
        var dominantTexture: [String: Double] = [:]
        var dominantColorQuality: [String: Double] = [:]
        var dominantExpression: [String: Double] = [:]
        
        // NEW: Daily-specific token categories
        var moonPhaseTokens: [String: Double] = [:]
        var dailySignatureTokens: [String: Double] = [:]
        var temporalTokens: [String: Double] = [:]
        var transitTokens: [String: Double] = [:]
        
        // Extract tokens by category and source
        for token in tokens where token.weight > 0.8 {
            switch token.type.lowercased() {
            case "structure":
                dominantStructure[token.name] = token.weight
            case "mood":
                dominantMood[token.name] = token.weight
            case "texture":
                dominantTexture[token.name] = token.weight
            case "color_quality":
                dominantColorQuality[token.name] = token.weight
            case "expression":
                dominantExpression[token.name] = token.weight
            default:
                break
            }
            
            // Categorize by source for daily variation
            if let source = token.planetarySource {
                if source.contains("Moon Phase") {
                    moonPhaseTokens[token.name] = token.weight
                } else if source.contains("Daily Signature") {
                    dailySignatureTokens[token.name] = token.weight
                } else if source.contains("Temporal Context") {
                    temporalTokens[token.name] = token.weight
                }
            }
            
            // Track transit tokens by aspect source
            if let aspectSource = token.aspectSource, aspectSource.contains("freshness adjusted") {
                transitTokens[token.name] = token.weight
            }
        }
        
        // Find primary characteristics
        let primaryStructure = dominantStructure.max(by: { $0.value < $1.value })?.key
        let primaryMood = dominantMood.max(by: { $0.value < $1.value })?.key
        let primaryTexture = dominantTexture.max(by: { $0.value < $1.value })?.key
        let primaryColorQuality = dominantColorQuality.max(by: { $0.value < $1.value })?.key
        let primaryExpression = dominantExpression.max(by: { $0.value < $1.value })?.key
        
        // Existing combinations
        let isFluidAndIntuitive = hasTokenCombination(tokens, ["fluid", "intuitive"], minWeight: 0.8)
        let isSensualAndLuxurious = hasTokenCombination(tokens, ["sensual", "luxurious"], minWeight: 0.8)
        let isGroundedAndPractical = hasTokenCombination(tokens, ["grounded", "practical"], minWeight: 0.8)
        let isInnovativeAndUnconventional = hasTokenCombination(tokens, ["innovative", "unconventional"], minWeight: 0.8)
        let isResponsiveAndAdaptable = hasTokenCombination(tokens, ["responsive", "adaptable"], minWeight: 0.8)
        let isDreamyAndEthereal = hasTokenCombination(tokens, ["dreamy", "ethereal"], minWeight: 0.8)
        let isRichAndVibrant = hasTokenCombination(tokens, ["rich", "vibrant"], minWeight: 0.8)
        let isSubtleAndNuanced = hasTokenCombination(tokens, ["subtle", "nuanced"], minWeight: 0.8)
        let isExpansiveAndAbundant = hasTokenCombination(tokens, ["expansive", "abundant"], minWeight: 0.8)
        let isComfortableAndSoft = hasTokenCombination(tokens, ["comforting", "soft"], minWeight: 0.8)
        
        // NEW: Daily-specific combinations
        let isReflectiveAndDissolving = hasTokenCombination(tokens, ["reflective", "dissolving"], minWeight: 0.8)
        let isHarmoniousAndBalanced = hasTokenCombination(tokens, ["harmonious", "balanced"], minWeight: 0.8)
        let isCalibratedAndSubtle = hasTokenCombination(tokens, ["calibrated", "subtle"], minWeight: 0.8)
        let isExpansiveAndFresh = hasTokenCombination(tokens, ["expansive", "fresh"], minWeight: 0.8)
        let isCompletingAndSubstantial = hasTokenCombination(tokens, ["completing", "substantial"], minWeight: 0.8)
        let isEmergingAndElevated = hasTokenCombination(tokens, ["emerging", "elevated"], minWeight: 0.8)
        
        // Calculate overall energy weight
        let overallWeight = tokens.filter { $0.weight > 0.8 }.map { $0.weight }.reduce(0, +)
        
        // Determine energy direction
        let energyDirection = determineEnergyDirection(
            structure: primaryStructure,
            mood: primaryMood,
            texture: primaryTexture,
            combinations: [
                "fluid_intuitive": isFluidAndIntuitive,
                "sensual_luxurious": isSensualAndLuxurious,
                "grounded_practical": isGroundedAndPractical,
                "innovative_unconventional": isInnovativeAndUnconventional,
                "responsive_adaptable": isResponsiveAndAdaptable
            ]
        )
        
        return TokenAnalysis(
            dominantStructure: dominantStructure,
            dominantMood: dominantMood,
            dominantTexture: dominantTexture,
            dominantColorQuality: dominantColorQuality,
            dominantExpression: dominantExpression,
            moonPhaseTokens: moonPhaseTokens,
            dailySignatureTokens: dailySignatureTokens,
            temporalTokens: temporalTokens,
            transitTokens: transitTokens,
            isFluidAndIntuitive: isFluidAndIntuitive,
            isSensualAndLuxurious: isSensualAndLuxurious,
            isGroundedAndPractical: isGroundedAndPractical,
            isInnovativeAndUnconventional: isInnovativeAndUnconventional,
            isResponsiveAndAdaptable: isResponsiveAndAdaptable,
            isDreamyAndEthereal: isDreamyAndEthereal,
            isRichAndVibrant: isRichAndVibrant,
            isSubtleAndNuanced: isSubtleAndNuanced,
            isExpansiveAndAbundant: isExpansiveAndAbundant,
            isComfortableAndSoft: isComfortableAndSoft,
            isReflectiveAndDissolving: isReflectiveAndDissolving,
            isHarmoniousAndBalanced: isHarmoniousAndBalanced,
            isCalibratedAndSubtle: isCalibratedAndSubtle,
            isExpansiveAndFresh: isExpansiveAndFresh,
            isCompletingAndSubstantial: isCompletingAndSubstantial,
            isEmergingAndElevated: isEmergingAndElevated,
            primaryStructure: primaryStructure,
            primaryMood: primaryMood,
            primaryTexture: primaryTexture,
            primaryColorQuality: primaryColorQuality,
            primaryExpression: primaryExpression,
            overallWeight: overallWeight,
            energyDirection: energyDirection
        )
    }
    
    // MARK: - Precise Style Brief Selection with Daily Variation
    private static func selectPreciseStyleBrief(from analysis: TokenAnalysis, dailySignature: DailySignature, patternSeed: Int) -> String {
        
        // TIER 1: Moon Phase + Planetary Day Specific Combinations
        
        // Waning Crescent + Venus Day (Reflective + Harmonious)
        if dailySignature.moonPhaseEnergy == "reflection" && dailySignature.planetaryDay == "Venus" {
            if analysis.isHarmoniousAndBalanced {
                return "There's this quiet confidence floating around today that doesn't need to shout to be heard. Your body knows exactly what it wants to wear, that thing that makes you feel properly sorted without trying too hard. Trust that gut feeling over whatever nonsense social media is pushing this week. True style comes from knowing yourself, not from following every trend that pops up on TikTok."
            } else if analysis.isCalibratedAndSubtle {
                return "You're in one of those reflective moods where you want to dress like the most interesting person in the room through presence alone. This is about picking pieces that tell a story about who you're becoming, the evolved version of yourself. You want clothes that feel like they're part of your personal evolution."
            } else {
                return "Today is all about that sweet spot where comfort meets authenticity. You want to look put-together without sacrificing how you actually feel in your body. This is about finding pieces that make you feel like the most grounded, centered version of yourself while still looking effortlessly chic."
            }
        }
        
        // Waning Gibbous + Jupiter Day (Completing + Expansive)
        if dailySignature.moonPhaseEnergy == "releasing" && dailySignature.planetaryDay == "Jupiter" {
            if analysis.isCompletingAndSubstantial {
                return "You're in one of those moods where you just want to trust your gut and not deal with anyone's nonsense today. There's something powerful about being picky with your energy, and your clothes should back that up. You want stuff that feels real and substantial, not like you're putting on a show. It's about dressing for you first, with that quiet confidence that says \"I know exactly who I am.\" The vibe today is asking for clothes that feel like the best kind of armour."
            } else if analysis.isExpansiveAndFresh {
                return "There's this fresh energy buzzing around today that wants you to try something slightly unexpected. Your body knows what it's craving, maybe that piece everyone compliments but you rarely wear? Trust that little nudge toward the not so obvious choice instead of reaching for your comfort zone uniform. Sometimes the perfect outfit is the one that surprises even you."
            }
        }
        
        // Building + Any Day (First Quarter to Full Moon)
        if dailySignature.moonPhaseEnergy == "building" {
            if analysis.isSensualAndLuxurious && dailySignature.planetaryDay == "Venus" {
                return "You're basically a human magnet today, drawing in all the right people and conversations. Your style should flow with that same easy intelligence. Think clothes that move with you, not against you. Pieces that feel like they're part of you already. You're channeling this adaptable energy that can shift to match any situation while still being totally you. Just trust your instincts on every single choice."
            } else if analysis.isInnovativeAndUnconventional {
                return "There's definitely a shift happening today, but you're riding the wave of innovation like a pro. Your brain is making connections other people are missing, and your style should reflect that same cutting-edge intelligence. This is about looking like you get something the rest of the world hasn't figured out yet. You're not trying to fit in because you're busy creating the next thing everyone else will want to copy later."
            }
        }
        
        // Renewal Phase (New Moon area)
        if dailySignature.moonPhaseEnergy == "renewal" {
            if analysis.isEmergingAndElevated {
                return "Your imagination's going wild today, friend. Perfect time to play with perception a bit. That thing you've been saving for \"the right occasion\"? This is actually it. Stop waiting for permission from the fashion police to wear what makes you feel fantastic. Your instincts about combining things that \"shouldn't\" go together are spot on right now, so maybe trust yourself more than those style rules you read in a magazine ages ago."
            } else if analysis.isGroundedAndPractical {
                return "You're in full earth goddess mode today, but make it practical. You want to look like someone who has their life together while staying completely approachable. This is about finding that sweet spot between being approachable and being impressive. You're channeling the energy of someone who can handle whatever comes their way while still looking effortlessly put-together."
            }
        }
        
        // TIER 2: Mood + Energy Intensity Combinations
        
        if dailySignature.dominantMood == "calibrated" && dailySignature.energyIntensity == "moderate" {
            return "There's this interesting balance today between wanting to feel completely comfortable and also wanting to make a statement. You're looking for that perfect sweet spot where you feel totally yourself but also powerfully present. Trust what feels substantial and calibrated to your actual energy."
        }
        
        if dailySignature.dominantMood == "harmonious" && analysis.isFluidAndIntuitive {
            return "You're floating between worlds today, and your style should reflect that harmonious energy. This is about trusting those dreamy instincts and letting yourself flow with whatever feels right. Your body knows what it wants today, and that's the only voice you need to listen to."
        }
        
        if dailySignature.dominantMood == "responsive" && dailySignature.energyIntensity == "intense" {
            return "You're in one of those moods where you want to dress for who you're becoming, not who you were yesterday. Pick pieces that feel like they're part of your evolution, that make you feel like you're growing into something better. Trust that responsive instinct that wants to adapt and flow."
        }
        
        // TIER 3: Daily Signature Specific
        
        switch dailySignature.planetaryDay {
        case "Venus":
            return "Today's about making choices that feel genuinely beautiful and harmonious. Pick pieces that make you feel like you can handle whatever comes your way with grace. You want to look like someone who knows what they're doing, with that quiet confidence that doesn't need to prove anything."
            
        case "Jupiter":
            return "There's definitely an expansive energy happening today, and you're riding the wave like a pro. Your instincts about what feels abundant and generous are spot on right now. This is about looking like you get something about growth that others haven't figured out yet."
            
        case "Mars":
            return "You're in full action mode today, and your wardrobe should reflect that same dynamic energy. This is about picking pieces that make you feel ready for anything. Trust that instinct that wants to move and accomplish things."
            
        case "Mercury":
            return "Your communication game is strong today, friend. Perfect time to let your style speak as clearly as your words. Pick pieces that feel like they're translating your thoughts into visual form. Trust your instincts about what feels articulate."
            
        default:
            break
        }
        
        // TIER 4: Energy Direction Fallbacks (with daily qualifiers)
        
        switch analysis.energyDirection {
        case "flowing":
            if dailySignature.energyIntensity == "subtle" {
                return "Your body knows what it wants today, and it's asking for pieces that flow like water. Pick things that feel right from the inside out, not what you think you should wear. Trust your instincts about what makes you feel most fluid and natural."
            } else {
                return "You're basically a magnet for the right energy today. Your style should move with that same flowing intelligence. Think pieces that respond to your body rather than fighting against it."
            }
            
        case "grounded":
            if dailySignature.transitPressure == "transforming" {
                return "Today's about making choices that feel genuinely solid while staying open to change. Pick pieces that make you feel rooted but not rigid. You want that perfect balance between stability and evolution."
            } else {
                return "You're channeling some serious earth energy today. Pick pieces that make you feel properly grounded and substantial. Trust what feels real and authentic rather than trendy."
            }
            
        case "innovative":
            return "Your brain is making connections other people are missing today. Your style should reflect that same cutting-edge thinking. This is about looking like you're already living in the future everyone else is trying to catch up to."
            
        case "nurturing":
            return "There's this beautiful caring energy around you today that wants to be reflected in how you show up. Pick pieces that feel both comforting to you and welcoming to others. Trust what feels genuinely nurturing."
            
        case "intense":
            return "You're in one of those powerful moods where everything you choose matters more than usual. Pick pieces that can handle that intensity and make you feel like you can transform whatever you touch."
            
        default: // "balanced"
            return "Your instincts are perfectly calibrated today. Pick pieces that feel right from the inside out, not what you think you should wear. Trust yourself completely - you know exactly what works."
        }
    }

    // MARK: - Helper Functions
    private static func hasTokenCombination(_ tokens: [StyleToken], _ names: [String], minWeight: Double) -> Bool {
        return names.allSatisfy { name in
            tokens.contains { token in
                token.name.lowercased() == name.lowercased() && token.weight >= minWeight
            }
        }
    }

    private static func determineEnergyDirection(structure: String?, mood: String?, texture: String?, combinations: [String: Bool]) -> String {
        if combinations["fluid_intuitive"] == true || structure == "fluid" {
            return "flowing"
        }
        if combinations["grounded_practical"] == true || mood == "grounded" {
            return "grounded"
        }
        if combinations["innovative_unconventional"] == true || structure == "unconventional" {
            return "innovative"
        }
        if combinations["responsive_adaptable"] == true || texture == "comforting" {
            return "nurturing"
        }
        if texture == "luxurious" || mood == "sensual" {
            return "intense"
        }
        return "balanced"
    }

    private static func extractPlanetaryDay(from dailyTokens: [String: Double]) -> String {
        // Look for planetary day indicators in the token sources
        if dailyTokens.keys.contains(where: { $0.contains("Venus") }) {
            return "Venus"
        } else if dailyTokens.keys.contains(where: { $0.contains("Jupiter") }) {
            return "Jupiter"
        } else if dailyTokens.keys.contains(where: { $0.contains("Mars") }) {
            return "Mars"
        } else if dailyTokens.keys.contains(where: { $0.contains("Mercury") }) {
            return "Mercury"
        }
        return "Balanced"
    }

    /*
    // MARK: - Maria's Style Brief Selection
    private static func selectMariaStyleBrief(from analysis: TokenAnalysis, moonPhase: Double, patternSeed: Int) -> String {
        
        // TIER 1: Highly specific combinations (Maria's exact voice from examples)
        
        // Luxurious + Sensual + Fluid (Venus Taurus + Pisces Ascendant dominance)
        if analysis.isSensualAndLuxurious && analysis.isFluidAndIntuitive {
            return "You're in one of those moods where you just want to trust your gut and not deal with anyone's nonsense today. There's something powerful about being picky with your energy, and your clothes should back that up. You want stuff that feels real and substantial, not like you're putting on a show. It's about dressing for you first, with that quiet confidence that says \"I know exactly who I am.\" The vibe today is asking for clothes that feel like the best kind of armour."
        }
        
        // Responsive + Adaptable + Fluid (Dynamic daily energy)
        if analysis.isResponsiveAndAdaptable && analysis.isFluidAndIntuitive {
            return "You're basically a human magnet today, drawing in all the right people and conversations. Your style should flow with that same easy intelligence. Think clothes that move with you, not against you. Pieces that feel like they're part of you already. You're channeling this adaptable energy that can shift to match any situation while still being totally you. Just trust your instincts on every single choice."
        }
        
        // Innovative + Unconventional + Expressive (Strong Uranus/Saturn influence)
        if analysis.isInnovativeAndUnconventional && (analysis.primaryExpression == "innovative" || analysis.primaryExpression == "visible") {
            return "There's definitely a shift happening today, but you're riding the wave of innovation like a pro. Your brain is making connections other people are missing, and your style should reflect that same cutting-edge intelligence. This is about looking like you get something the rest of the world hasn't figured out yet. You're not trying to fit in because you're busy creating the next thing everyone else will want to copy later."
        }
        
        // Rich + Vibrant + Expressive (Strong creative energy)
        if analysis.isRichAndVibrant && (analysis.primaryMood == "expansive" || analysis.primaryExpression == "playful") {
            return "Your imagination's going wild today, friend. Perfect time to play with perception a bit. That thing you've been saving for \"the right occasion\"? This is actually it. Stop waiting for permission from the fashion police to wear what makes you feel fantastic. Your instincts about combining things that \"shouldn't\" go together are spot on right now, so maybe trust yourself more than those style rules you read in a magazine ages ago."
        }
        
        // Grounded + Practical + Comfortable (Earth energy dominance)
        if analysis.isGroundedAndPractical && analysis.isComfortableAndSoft {
            return "You're in full earth goddess mode today, but make it practical. You want to look like someone who has their life together while staying completely approachable. This is about finding that sweet spot between being approachable and being impressive. You're channeling the energy of someone who can handle whatever comes their way while still looking effortlessly put-together."
        }
        
        // Subtle + Nuanced + Sophisticated (Refined energy)
        if analysis.isSubtleAndNuanced && (analysis.primaryColorQuality == "vintage" || analysis.primaryColorQuality == "contemplative") {
            return "There's this quiet confidence floating around today that doesn't need to shout to be heard. Your body knows exactly what it wants to wear, that thing that makes you feel properly sorted without trying too hard. Trust that gut feeling over whatever nonsense social media is pushing this week. True style comes from knowing yourself, not from following every trend that pops up on TikTok."
        }
        
        // Expansive + Abundant + Expressive (Jupiter influence)
        if analysis.isExpansiveAndAbundant && analysis.primaryMood == "expansive" {
            return "There's this fresh energy buzzing around today that wants you to try something slightly unexpected. Your body knows what it's craving, maybe that piece everyone compliments but you rarely wear? Trust that little nudge toward the not so obvious choice instead of reaching for your comfort zone uniform. Sometimes the perfect outfit is the one that surprises even you."
        }
        
        // TIER 2: Primary characteristic combinations
        
        // Fluid + Intuitive primary combination
        if analysis.primaryStructure == "fluid" && analysis.primaryExpression == "intuitive" {
            return "You're floating between worlds today, and your style should reflect that ethereal energy. This is about trusting those dreamy instincts and letting yourself flow with whatever feels right. Your body knows what it wants today, and that's the only voice you need to listen to. Pick pieces that feel right from the inside out, not what you think you should wear."
        }
        
        // Luxurious + Sensual primary combination
        if analysis.primaryTexture == "luxurious" && analysis.primaryMood == "sensual" {
            return "Today is all about that sweet spot where comfort meets authenticity. You want to look put-together without sacrificing how you actually feel in your body. This is about finding pieces that make you feel like the most grounded, centered version of yourself while still looking effortlessly chic. Trust what feels substantial and real."
        }
        
        // Innovative + Unconventional primary combination
        if analysis.primaryExpression == "innovative" && analysis.primaryStructure == "unconventional" {
            return "There's definitely a shift happening today, and you're riding the wave like a pro. Your brain is making connections other people are missing, and your style should reflect that same cutting-edge intelligence. This is about looking like you get something the rest of the world hasn't figured out yet."
        }
        
        // Grounded + Practical primary combination
        if analysis.primaryMood == "grounded" && analysis.primaryStructure == "practical" {
            return "You're in full earth goddess mode today, but make it practical. You want to look like someone who has their life together while staying completely approachable. This is about finding that sweet spot between being impressive and being real."
        }
        
        // TIER 3: Energy direction based responses
        
        switch analysis.energyDirection {
        case "flowing":
            return "You're basically a human magnet today, drawing in all the right people and conversations. Your style should flow with that same easy intelligence. Think clothes that move with you, not against you. Pieces that feel like they're part of you already."
            
        case "grounded":
            return "Today's about making choices that feel genuinely powerful. Pick pieces that make you feel like you can handle whatever comes your way. You want to look like someone who knows what they're doing, with that quiet confidence that doesn't need to prove anything."
            
        case "innovative":
            return "Your imagination's going wild today, friend. Perfect time to try that thing you've been saving for \"the right occasion.\" Stop waiting for permission from the fashion police to wear what makes you feel fantastic. Trust your instincts about what makes you feel most like yourself."
            
        case "nurturing":
            return "There's this interesting balance today between wanting to feel completely comfortable and also wanting to make a statement. You're looking for that perfect sweet spot where you feel totally yourself but also powerfully present."
            
        case "intense":
            return "You're in one of those moods where you want to dress for who you're becoming, not who you were yesterday. Pick pieces that feel like they're part of your evolution, that make you feel like you're growing into something better."
            
        default: // "balanced"
            return "Your body knows what it wants today. Pick pieces that feel right from the inside out, not what you think you should wear. Trust your instincts about what makes you feel most like yourself. Sometimes the best outfits are the ones that surprise even you."
        }
    }
     */
    
    private static func extractSeasonalInfluence(from temporalTokens: [String: Double]) -> String {
        if temporalTokens["expansive"] != nil {
            return "expansive"
        } else if temporalTokens["grounding"] != nil {
            return "grounding"
        } else if temporalTokens["flowing"] != nil {
            return "flowing"
        }
        return "balanced"
    }

    // MARK: - Enhanced Debug Helper
    private static func debugTokenAnalysis(_ analysis: TokenAnalysis, dailySignature: DailySignature) {
        print("🎭 ENHANCED STYLE BRIEF TOKEN ANALYSIS:")
        print("Energy Direction: \(analysis.energyDirection)")
        print("Moon Phase Energy: \(dailySignature.moonPhaseEnergy)")
        print("Planetary Day: \(dailySignature.planetaryDay)")
        print("Dominant Mood: \(dailySignature.dominantMood)")
        print("Energy Intensity: \(dailySignature.energyIntensity)")
        print("Transit Pressure: \(dailySignature.transitPressure)")
        print("Unique Key: \(dailySignature.uniqueKey)")
        print("Primary Structure: \(analysis.primaryStructure ?? "none")")
        print("Primary Mood: \(analysis.primaryMood ?? "none")")
        print("Primary Texture: \(analysis.primaryTexture ?? "none")")
        print("Key Combinations:")
        print("  • Fluid + Intuitive: \(analysis.isFluidAndIntuitive)")
        print("  • Sensual + Luxurious: \(analysis.isSensualAndLuxurious)")
        print("  • Grounded + Practical: \(analysis.isGroundedAndPractical)")
        print("  • Innovative + Unconventional: \(analysis.isInnovativeAndUnconventional)")
        print("  • Responsive + Adaptable: \(analysis.isResponsiveAndAdaptable)")
        print("Daily-Specific Combinations:")
        print("  • Reflective + Dissolving: \(analysis.isReflectiveAndDissolving)")
        print("  • Harmonious + Balanced: \(analysis.isHarmoniousAndBalanced)")
        print("  • Calibrated + Subtle: \(analysis.isCalibratedAndSubtle)")
        print("  • Expansive + Fresh: \(analysis.isExpansiveAndFresh)")
        print("  • Completing + Substantial: \(analysis.isCompletingAndSubstantial)")
        print("  • Emerging + Elevated: \(analysis.isEmergingAndElevated)")
    }
    
    /// Generate textiles recommendations with FIXED placeholder replacement
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
        
        // Create the fabric description with more concrete language
        var description = selectedFabrics.joined(separator: ", ")
        
        // Add more specific descriptive guidance based on characteristics
        if hasSoft && hasTextured {
            description += "—look for fabrics that feel good against your skin and have interesting surface texture. Choose materials that provide comfort while adding visual interest."
        } else if hasStructured && hasEarthy {
            description += "—focus on substantial fabrics with natural character. Choose materials that hold their shape and feel grounded and authentic."
        } else if hasFluid && hasLayered {
            description += "—select fabrics that drape well and layer easily without bulk. Choose materials that move with your body and create graceful silhouettes."
        } else if hasLuxurious {
            description += "—prioritize quality over quantity. Choose fabrics that feel elevated and well-made, focusing on how they enhance your overall presence."
        } else {
            description += "—select fabrics that support both comfort and style. Choose materials that feel appropriate for your day's activities while expressing your personal aesthetic."
        }
        
        // Ensure proper capitalization at start
        return description.capitalizingFirstLetter()
    }

    /// Generate color recommendations with more concrete guidance
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
        
        // Create the color description with concrete guidance
        var description = selectedColors.joined(separator: ", ")
        
        // Add specific guidance about how to use these colors
        if hasDark || hasMuted {
            description += ". Use these deeper tones as your foundation colors, adding lighter accents as needed."
        } else if hasLight || hasAiry {
            description += ". Use these lighter shades to create a fresh, open feeling, adding deeper tones for contrast."
        } else if hasVibrant || hasFiery {
            description += ". Use these stronger colors strategically as statement pieces or accents rather than overwhelming your entire look."
        } else {
            description += ". These colors work well both as base tones and accent colors, giving you flexibility in how you combine them."
        }
        
        // Ensure proper capitalization at start
        return description.capitalizingFirstLetter()
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

    /// Generate pattern recommendations with more specific guidance
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
        
        // Pattern suggestions based on characteristics with concrete guidance
        var patterns = ""
        
        if hasMinimal && hasTextured {
            patterns = "Subtle texture over bold prints\(dailyPatternEmphasis). Consider woven textures, gentle cable knits, or fabric with natural variation rather than graphic patterns."
        } else if hasExpressive && hasEclectic {
            patterns = "Statement prints with personality\(dailyPatternEmphasis). Look for geometric patterns, artistic prints, or vintage-inspired designs that reflect your unique style."
        } else if hasStructured && hasMinimal {
            patterns = "Clean lines and geometric simplicity\(dailyPatternEmphasis). Think subtle stripes, small checks, or architectural patterns that add visual interest without complexity."
        } else if hasFluid && hasExpressive {
            patterns = "Organic, flowing patterns\(dailyPatternEmphasis). Consider watercolor effects, botanical prints, or abstract patterns that have movement and natural rhythm."
        } else if hasSubtle {
            patterns = "Tone-on-tone and barely-there patterns\(dailyPatternEmphasis). Look for monochromatic textures, subtle weaves, or patterns that reveal themselves up close."
        } else if hasEclectic {
            patterns = "Mix of pattern scales and styles\(dailyPatternEmphasis). Combine different pattern types thoughtfully—perhaps a small print with a larger one, or stripes with florals."
        } else {
            patterns = "Balanced, wearable patterns\(dailyPatternEmphasis). Choose prints that feel authentic to your style and work well with the rest of your wardrobe."
        }
        
        // Ensure proper capitalization at start
        return patterns.capitalizingFirstLetter()
    }

    /// Generate shape recommendations with more actionable guidance
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
        
        // Shape description based on characteristics with actionable guidance
        var shape = ""
        
        if hasStructured && hasProtective {
            shape = "Defined silhouettes with coverage\(dailyShapeEmphasis). Think blazers, structured coats, or well-tailored pieces that create clear lines while providing comfort and security."
        } else if hasFluid && hasLayered {
            shape = "Soft layers and flowing silhouettes\(dailyShapeEmphasis). Consider cardigans, flowing tops, or draped pieces that move with you and create graceful dimensions."
        } else if hasMinimal && hasBalanced {
            shape = "Clean, proportioned silhouettes\(dailyShapeEmphasis). Focus on well-fitted basics, simple cuts, and pieces where the fit and proportion are the main design elements."
        } else if hasExpressive && hasLayered {
            shape = "Interesting volumes and proportions\(dailyShapeEmphasis). Mix fitted and loose pieces, play with sleeve shapes, or choose items with architectural details."
        } else if hasProtective {
            shape = "Comfortable, enveloping shapes\(dailyShapeEmphasis). Look for pieces that feel like soft armor—cozy sweaters, wrap styles, or clothes that create a sense of personal space."
        } else {
            shape = "Balanced, flattering proportions\(dailyShapeEmphasis). Choose silhouettes that make you feel confident and comfortable, whether that's fitted, relaxed, or somewhere in between."
        }
        
        // Ensure proper capitalization at start
        return shape.capitalizingFirstLetter()
    }

    /// Generate accessories recommendations with FIXED placeholder replacement
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
        
        // Accessories description based on characteristics - FIXED VERSION without duplication
        var accessories = ""
        
        if hasMinimal && hasProtective {
            accessories = "One meaningful piece\(dailyAccessoryEmphasis). Choose a single item that feels significant—a watch, ring, or necklace that serves as both function and personal anchor. Keep everything else minimal. Fragrance: something grounding like cedarwood or clean musk."
        } else if hasExpressive && hasEclectic {
            accessories = "Statement pieces that tell your story\(dailyAccessoryEmphasis). Select accessories that reflect your personality and invite conversation—interesting jewelry, a distinctive bag, or unique details. Focus on one primary piece with subtle supporting elements. Fragrance: something complex like spiced amber or rich citrus."
        } else if hasStructured && hasEarthy {
            accessories = "Natural materials with clear purpose\(dailyAccessoryEmphasis). Choose accessories made from leather, wood, metal, or stone that feel substantial and authentic. Each piece should have a clear function and add to your overall presence. Fragrance: something woody like sandalwood or vetiver."
        } else if hasWatery && hasProtective {
            accessories = "Flowing, adaptive pieces\(dailyAccessoryEmphasis). Select accessories that move with you and can adapt to different situations—scarves, soft bags, or jewelry with organic shapes. Choose items that provide comfort and flexibility. Fragrance: something fresh like sea salt or clean aquatic notes."
        } else {
            accessories = "Thoughtful, intentional selections\(dailyAccessoryEmphasis). Choose accessories that enhance your look without overwhelming it. Each piece should feel like it belongs and adds to your overall sense of put-togetherness. Fragrance: something that complements your natural scent and mood today."
        }
        
        // Ensure proper capitalization at start
        return accessories.capitalizingFirstLetter()
    }

    /// Generate final takeaway message with more practical guidance
    static func generateTakeaway(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
        // Create takeaway options that are more practical and actionable
        var takeawayOptions: [String] = []
        
        // Based on dominant token combinations - more concrete advice
        if tokens.contains(where: { $0.name == "authentic" && $0.weight > 1.5 }) {
            takeawayOptions.append("Choose what feels genuinely you, not what you think you should wear.")
            takeawayOptions.append("Your best style choices come from knowing yourself, not following trends.")
        }
        
        if tokens.contains(where: { $0.name == "intuitive" && $0.weight > 1.5 }) {
            takeawayOptions.append("Trust your first instinct about what to wear—it's usually right.")
            takeawayOptions.append("Pay attention to how different clothes make you feel, not just how they look.")
        }
        
        if tokens.contains(where: { $0.name == "balanced" && $0.weight > 1.5 }) {
            takeawayOptions.append("Good style is about finding the right balance for you, not perfection.")
            takeawayOptions.append("Mix comfortable and polished elements to create looks that work for your life.")
        }
        
        if tokens.contains(where: { $0.name == "expressive" && $0.weight > 1.5 }) {
            takeawayOptions.append("Let one element of your outfit be the star, and keep everything else supporting.")
            takeawayOptions.append("Express yourself through your clothes, but make sure you can live comfortably in them.")
        }
        
        // Based on moon phase - practical lunar guidance
        if moonPhase < 90.0 {
            // New Moon to First Quarter - new beginnings
            takeawayOptions.append("Begin with intention. The rest will follow.")
            takeawayOptions.append("New cycles start with quiet commitment, not grand gestures.")
        } else if moonPhase < 180.0 {
            // First Quarter to Full Moon - building energy
            takeawayOptions.append("Growth happens in the tension between comfort and challenge.")
            takeawayOptions.append("The path forward reveals itself one step at a time.")
        } else if moonPhase < 270.0 {
            // Full Moon to Last Quarter - WANING ENERGY (this is the fix!)
            takeawayOptions.append("Release what no longer serves you today.")
            takeawayOptions.append("There's wisdom in knowing when to let go.")
            takeawayOptions.append("Trust the process of natural endings.")
            takeawayOptions.append("What you release creates space for what's coming.")
        } else {
            // Last Quarter to New Moon - releasing and preparing
            takeawayOptions.append("Release what no longer serves before seeking what's next.")
            takeawayOptions.append("Completion is just another form of beginning.")
        }
        
        // Add practical daily guidance
        takeawayOptions.append("Dress for how you want to feel today, not just how you think you should look.")
        takeawayOptions.append("Choose comfort and confidence over what others might expect.")
        takeawayOptions.append("The best outfit is one that makes you forget about your clothes and focus on your day.")
        takeawayOptions.append("When in doubt, choose the option that feels most like you.")
        takeawayOptions.append("Style is about enhancing who you are, not creating who you think you should be.")
        
        // Use seed to select takeaway consistently for the day
        let index = patternSeed % takeawayOptions.count
        return takeawayOptions[index]
    }

    // MARK: - NEW: Daily Freshness Methods (same as before)

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
            ", with today's focus on fine pinstripes",
            ", emphasizing tonal texture today",
            ", highlighting subtle shadowed stripes",
            ", with attention to speckled details",
            ", incorporating subtle check patterns",
            ", focusing on irregular dot patterns",
            ", emphasizing organic textures",
            ", highlighting geometric simplicity",
            ", with today's emphasis on fluid stripes",
            ", focusing on balanced asymmetry",
            ", leaning toward textural contrast",
            ", with gentle gradients"
        ]
        
        return patternOptions[seed % patternOptions.count]
    }

    /// Get daily shape emphasis
    static func getDailyShapeEmphasis(seed: Int) -> String {
        let shapeOptions = [
            ", emphasizing shoulder definition",
            ", with focus on sleeve volume",
            ", highlighting waist proportion",
            ", with attention to collar structure",
            ", emphasizing sleeve length",
            ", focusing on horizontal lines",
            ", with definition at the hip",
            ", emphasizing vertical proportions",
            ", with attention to neckline shape",
            ", highlighting layering proportions",
            ", with focus on hem detail",
            ", balancing fitted and fluid elements"
        ]
        
        return shapeOptions[seed % shapeOptions.count]
    }

    /// Get daily accessory emphasis
    static func getDailyAccessoryEmphasis(seed: Int) -> String {
        let accessoryOptions = [
            " (focus on wrist elements)",
            " (emphasize neck adornment)",
            " (highlight metal details)",
            " (choose one powerful element)",
            " (prioritize natural materials)",
            " (play with textural contrast)",
            " (select meaningful pieces)",
            " (consider symbolic weight)",
            " (include handcrafted details)",
            " (emphasize personal significance)",
            " (choose organic forms)",
            " (balance scale and proportion)"
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
    
    // MARK: - Helper methods for token checking
    
    /// Check if tokens contain textured characteristics
    private static func hasTextured(_ tokens: [StyleToken]) -> Bool {
        return tokens.contains { $0.name == "textured" && $0.weight > 1.5 }
    }
    
    /// Check if tokens contain comfortable characteristics
    private static func hasComfortable(_ tokens: [StyleToken]) -> Bool {
        return tokens.contains { $0.name == "comfortable" && $0.weight > 1.5 }
    }
    
    /// Check if tokens contain expressive characteristics
    private static func hasExpressive(_ tokens: [StyleToken]) -> Bool {
        return tokens.contains { $0.name == "expressive" && $0.weight > 1.5 }
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

// MARK: - String Extension for Proper Capitalization
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

/// Structure to hold all daily vibe content
struct DailyVibeContent: Codable {
    // Main content - Style Brief replaces title and mainParagraph
    var styleBrief: String = ""
    
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
