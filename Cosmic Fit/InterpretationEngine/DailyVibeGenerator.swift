//
//  DailyVibeGenerator.swift
//  Cosmic Fit
//
//  Created for Daily Vibe implementation - CORRECTED VERSION WITH MARIA'S VOICE
//  Fixed to eliminate temporal marker duplication
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
            print("  • Token Prefix Matrix: Active for precise Style Brief generation")
            
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
            
            // 3a. Separate fast and slow transit tokens and apply freshness boost
            var fastTransitTokens: [StyleToken] = []
            var slowTransitTokens: [StyleToken] = []

            for token in rawTransitTokens {
                if let planetarySource = token.planetarySource {
                    let freshnessBoost = applyFreshnessBoost(transitPlanet: planetarySource, aspectType: token.aspectSource ?? "")
                    
                    let adjustedToken = StyleToken(
                        name: token.name,
                        type: token.type,
                        weight: token.weight * freshnessBoost,
                        planetarySource: token.planetarySource,
                        signSource: token.signSource,
                        houseSource: token.houseSource,
                        aspectSource: token.aspectSource,
                        originType: token.originType
                    )
                    
                    if ["Moon", "Mercury", "Venus", "Sun", "Mars"].contains(planetarySource) {
                        fastTransitTokens.append(adjustedToken)
                    } else {
                        slowTransitTokens.append(adjustedToken)
                    }
                } else {
                    // No planetary source, treat as slow transit
                    slowTransitTokens.append(token)
                }
            }
            
            logTokenSet("FAST TRANSIT TOKENS (FRESHNESS BOOSTED)", fastTransitTokens)
            logTokenSet("SLOW TRANSIT TOKENS", slowTransitTokens)
            
            // 4. Generate weather-influenced tokens (if weather available)
            var weatherTokens: [StyleToken] = []
            if let weather = weather {
                weatherTokens = SemanticTokenGenerator.generateWeatherTokens(weather: weather)
                logTokenSet("WEATHER TOKENS", weatherTokens)
            }
            
            // 5. Generate daily signature tokens (includes temporal markers - NO DUPLICATION)
            let dailySignatureTokens = generateDailySignature()
            logTokenSet("DAILY SIGNATURE TOKENS (includes temporal markers)", dailySignatureTokens)
            
            // 6. Combine tokens with appropriate weights
            var allTokens: [StyleToken] = []
            
            // Weight distribution: 40% natal base, 60% daily influenced
            let baseWeight = 0.4
            let emotionalWeight = 0.25
            let fastTransitWeight = 0.20  // Higher weight for fast transits
            let slowTransitWeight = 0.05  // Lower weight for slow transits
            let weatherWeight = 0.05
            let dailySignatureWeight = 0.15  // Increased since it includes temporal markers
            
            // Apply weights to base style tokens
            for token in baseStyleTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * baseWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to emotional vibe tokens
            for token in emotionalVibeTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * emotionalWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to fast transit tokens (already boosted)
            for token in fastTransitTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * fastTransitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to slow transit tokens
            for token in slowTransitTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * slowTransitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weights to weather tokens
            for token in weatherTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * weatherWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Add daily signature tokens (15% weight - includes temporal markers)
            for token in dailySignatureTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * dailySignatureWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply controlled variation to tokens
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
            
            return dailyVibeContent
        }
        
    // MARK: - New Daily Vibe Content Generation
    static func generateDailyVibeContent(
        tokens: [StyleToken],
        weather: TodayWeather?,
        moonPhase: Double,
        patternSeed: Int = 0) -> DailyVibeContent {
        
        // Apply temperature conflict resolution BEFORE generating content
        var processedTokens = tokens
        if let weather = weather {
            print("Applying temperature conflict resolution...")
            processedTokens = SemanticTokenGenerator.resolveTemperatureConflicts(tokens: tokens, weather: weather)
        }
        
        // Create content object
        var content = DailyVibeContent()
        
        // Generate Style Brief using temperature-resolved tokens
        content.styleBrief = generateStyleBrief(tokens: processedTokens, moonPhase: moonPhase, patternSeed: patternSeed)
        
        // Generate textiles section using temperature-resolved tokens
        content.textiles = generateTextiles(tokens: processedTokens)
        
        // Generate colors section using temperature-resolved tokens
        content.colors = generateColors(tokens: processedTokens)
        
        // Calculate brightness and vibrancy values using temperature-resolved tokens
        content.brightness = calculateBrightness(tokens: processedTokens, moonPhase: moonPhase)
        content.vibrancy = calculateVibrancy(tokens: processedTokens)
        
        // Generate patterns section using temperature-resolved tokens
        content.patterns = generatePatterns(tokens: processedTokens)
        
        // Generate shape section using temperature-resolved tokens
        content.shape = generateShape(tokens: processedTokens)
        
        // Generate accessories section using temperature-resolved tokens
        content.accessories = generateAccessories(tokens: processedTokens)
        
        // Generate takeaway line using temperature-resolved tokens
        content.takeaway = generateTakeaway(tokens: processedTokens, moonPhase: moonPhase, patternSeed: patternSeed)
        
        // Add weather information if available
        if let weather = weather {
            content.temperature = weather.temp
            content.weatherCondition = weather.conditions
        }
        
        return content
    }
    
    // MARK: - Main Generation Function WITH TOKEN PREFIX MATRIX
    internal static func generateStyleBrief(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
        
        print("\n🎯 GENERATING STYLE BRIEF WITH TOKEN PREFIX MATRIX")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // STEP 1: Create token context for prefix determination
        let tokenContext = TokenContext(moonPhase: moonPhase)
        
        // STEP 2: Analyze token categories and weights
        let tokenAnalysis = analyzeTokens(tokens)
        
        // STEP 3: Create daily signature for uniqueness
        let dailySignature = createDailySignature(from: tokenAnalysis, moonPhase: moonPhase, patternSeed: patternSeed)
        
        // STEP 4: Get prefixed tokens for primary style elements
        let prefixedTokens = getPrefixedTokens(tokens: tokens, context: tokenContext)
        
        // DEBUG: Output token analysis and prefixes to console
        debugTokenAnalysis(tokenAnalysis, dailySignature: dailySignature)
        debugPrefixedTokens(prefixedTokens)
        
        // STEP 5: Find the precise combination that matches today's unique energy
        let styleBrief = selectPreciseStyleBriefWithPrefixes(
            from: tokenAnalysis,
            dailySignature: dailySignature,
            prefixedTokens: prefixedTokens,
            context: tokenContext,
            patternSeed: patternSeed
        )
        
        print("✅ Style Brief with prefixes generated successfully!")
        
        return styleBrief
    }
    
    // MARK: - Token Prefix Integration
    
    /// Get prefixed versions of relevant tokens
    private static func getPrefixedTokens(tokens: [StyleToken], context: TokenContext) -> [(token: StyleToken, prefix: String)] {
        var prefixedTokens: [(token: StyleToken, prefix: String)] = []
        
        // Get top tokens by weight for each category
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(15)
        
        for token in topTokens {
            let prefix = TokenPrefixMatrix.getPrefix(for: token, context: context)
            if !prefix.isEmpty {
                prefixedTokens.append((token: token, prefix: prefix))
            }
        }
        
        return prefixedTokens
    }
    
    /// Debug prefixed tokens
    private static func debugPrefixedTokens(_ prefixedTokens: [(token: StyleToken, prefix: String)]) {
        print("\n🏷️ PREFIXED TOKENS:")
        for (token, prefix) in prefixedTokens {
            print("  • \(token.name) (\(String(format: "%.2f", token.weight))): \"\(prefix)\"")
        }
        print("")
    }
    
    // MARK: - Enhanced Style Brief Selection WITH PREFIXES - MARIA'S VOICE
    private static func selectPreciseStyleBriefWithPrefixes(
        from analysis: TokenAnalysis,
        dailySignature: DailySignature,
        prefixedTokens: [(token: StyleToken, prefix: String)],
        context: TokenContext,
        patternSeed: Int) -> String {
        
        // Extract highest weighted tokens for specific guidance
        let topColors = getTopTokensByCategory(analysis: analysis, category: "color", count: 3)
        let topTextures = getTopTokensByCategory(analysis: analysis, category: "texture", count: 2)
        let topColorQualities = getTopTokensByCategory(analysis: analysis, category: "color_quality", count: 3)
        let topStructures = getTopTokensByCategory(analysis: analysis, category: "structure", count: 2)
        let topMoods = getTopTokensByCategory(analysis: analysis, category: "mood", count: 2)
        
        // Get the most relevant prefix for the dominant token
        let dominantPrefix = getDominantPrefix(prefixedTokens: prefixedTokens, analysis: analysis)
        
        // TIER 1: Rich Token Combination Briefs with Prefixes (Most Specific) - MARIA'S VOICE
        // Updated with more realistic thresholds and flexible combinations
        
        // Luxurious + Sensual (Venus Taurus dominance) - Lowered threshold to 1.1
        if hasFlexibleTokenCombination(analysis.allTokens, ["luxurious", "sensual"], minWeight: 1.1)
           && topColors.contains(where: { ["emerald", "rich", "radiant", "forest", "moss"].contains($0) }) {
            let specificColor = topColors.first { ["emerald", "rich", "radiant", "forest", "moss"].contains($0) } ?? "emerald"
            return "\(dominantPrefix). Focus on textures that feel great against your skin. Look for rich colours, especially if it's something \(specificColor). You're not putting on a show for anyone else today, so what pieces do you want to wear for yourself?"
        }
        
        // Grounded + Sensual (Earth + Venus influence) - New combination
        if hasFlexibleTokenCombination(analysis.allTokens, ["grounded", "sensual"], minWeight: 1.2) {
            let earthColor = topColors.first { ["emerald", "moss", "olive", "forest", "terracotta"].contains($0) } ?? "moss green"
            return "\(dominantPrefix). Trust your gut and skip everyone else's drama today. Get \(earthColor) pieces that feel real and solid. Dress for yourself first. Everyone else can deal."
        }
        
        // Fluid + Intuitive + Dreamy Colors (Pisces Ascendant + Water influence) - Lowered threshold
        if hasFlexibleTokenCombination(analysis.allTokens, ["fluid", "intuitive"], minWeight: 1.0)
           && topColorQualities.contains("dreamy") || topColors.contains(where: { ["iridescent", "oceanic", "aqua", "pearl"].contains($0) }) {
            let waterColor = topColors.first { ["iridescent", "oceanic", "aqua", "pearl"].contains($0) } ?? "oceanic"
            return "\(dominantPrefix). Go with your gut on this one. Pick the \(waterColor) stuff that flows when you move. Grab pieces that feel like they belong to you already. Trust yourself, you know what works."
        }
        
        // Single high-weight token dominance (for when combinations don't meet thresholds)
        if let dominantToken = getDominantSingleToken(analysis.allTokens, minWeight: 1.3) {
            switch dominantToken.name.lowercased() {
            case "sensual":
                let luxeColor = topColors.first { ["emerald", "rich", "deep"].contains($0) } ?? "emerald"
                return "\(dominantPrefix). This is about feeling good in your own skin. Get \(luxeColor) pieces that make you want to touch the fabric. Quality over everything else today."
                
            case "grounded":
                let earthColor = topColors.first { ["moss", "terracotta", "olive"].contains($0) } ?? "moss"
                return "\(dominantPrefix). Keep it real today. Choose \(earthColor) pieces that feel solid and substantial. No need to prove anything to anyone."
                
            case "luxurious":
                let richColor = topColors.first { ["emerald", "gold", "deep"].contains($0) } ?? "emerald"
                return "\(dominantPrefix). Treat yourself right. Get those \(richColor) pieces that feel expensive to wear. You deserve to feel elevated."
                
            case "fluid":
                let flowColor = topColors.first { ["aqua", "oceanic", "pearl"].contains($0) } ?? "oceanic"
                return "\(dominantPrefix). Let yourself flow today. Pick \(flowColor) pieces that move with you and change with the light."
                
            default:
                break
            }
        }
        
        // TIER 2: Moon Phase + Planetary Day + Enhanced Token Mining - MARIA'S VOICE
        
        // Reflection Phase + Moon Day (from debug output)
        if dailySignature.moonPhaseEnergy == "reflection" || dailySignature.planetaryDay == "Moon" {
            if analysis.primaryTexture == "luxurious" || topTextures.contains("luxurious") {
                let luxeTexture = topTextures.first { ["luxurious", "comforting", "soft"].contains($0) } ?? "luxurious"
                return "\(dominantPrefix). Time to dress like you're the interesting one in the room. Get those \(luxeTexture) pieces that feel good to wear. Pick stuff that tells your story."
            } else if hasAnyToken(analysis.allTokens, ["intuitive", "reflective", "pearl"], minWeight: 1.0) {
                let reflectiveColor = topColors.first { ["pearl", "silver", "soft"].contains($0) } ?? "pearl silver"
                return "\(dominantPrefix). Trust your instincts today. Grab whatever makes you feel properly put together in \(reflectiveColor) tones. Your style comes from knowing who you are."
            }
        }
        
        // Peak Light + Summer Energy (from temporal context in debug)
        if hasAnyToken(analysis.allTokens, ["bright", "radiant", "active"], minWeight: 1.5) {
            let brightColor = topColors.first { ["bright", "radiant", "emerald"].contains($0) } ?? "emerald"
            return "\(dominantPrefix). You're in full summer energy mode. Get those \(brightColor) pieces that catch the light. Don't hide your glow today."
        }
        
        // TIER 3: Enhanced texture-first approach (when combinations fail)
        if let primaryTexture = analysis.primaryTexture {
            switch primaryTexture.lowercased() {
            case "luxurious":
                let richColor = topColors.first ?? "emerald"
                return "\(dominantPrefix). All about that luxurious feel today. Choose \(richColor) pieces that feel as good as they look. Touch comes first."
                
            case "comforting", "soft":
                let comfortColor = topColors.first ?? "warm"
                return "\(dominantPrefix). Comfort is your priority. Get \(comfortColor) pieces that feel like a hug. You don't need to try hard today."
                
            case "structured":
                let structuredColor = topColors.first ?? "charcoal"
                return "\(dominantPrefix). Clean lines, clear intentions. Choose \(structuredColor) pieces that have good bones. Less noise, more purpose."
                
            default:
                break
            }
        }
        
        // TIER 4: Color-first approach (when texture/combination approaches fail)
        if let primaryColor = analysis.primaryColor {
            switch primaryColor.lowercased() {
            case "emerald", "forest", "moss":
                return "\(dominantPrefix). Green is your power color today. Get emerald pieces that make you feel connected to your strength. Nature vibes with intention."
                
            case "pearl", "silver", "aqua":
                return "\(dominantPrefix). Soft but powerful today. Choose pearl or aqua pieces that shift with the light. Let your intuition guide the choices."
                
            default:
                let colorChoice = primaryColor
                return "\(dominantPrefix). \(colorChoice.capitalized) is calling you today. Trust that instinct and choose pieces that feel right in that shade."
            }
        }
        
        // TIER 5: Enhanced Fallback with better token analysis
        let fallbackColor = topColors.first ?? "emerald"
        let fallbackTexture = topTextures.first ?? "luxurious"
        
        // Check if we have strong energy indicators for enhanced fallback
        if hasAnyToken(analysis.allTokens, ["expressing", "manifesting", "active"], minWeight: 1.4) {
            return "\(dominantPrefix). You're in manifestation mode today. Pick \(fallbackColor) pieces with \(fallbackTexture) energy that make you feel powerful. Trust your gut over everyone else's opinions."
        }
        
        // Standard enhanced fallback
        return "\(dominantPrefix). Pick \(fallbackColor) pieces with \(fallbackTexture) energy that make you feel like yourself today. Trust your gut over everyone else's opinions. You know what works."
    }
    
    /// More flexible token combination checking with weighted approach
    private static func hasFlexibleTokenCombination(_ tokens: [StyleToken], _ names: [String], minWeight: Double) -> Bool {
        // Check if we have both tokens, but allow for slight weight variations
        let foundTokens = names.compactMap { name in
            tokens.first { token in
                token.name.lowercased() == name.lowercased()
            }
        }
        
        // Must have all required tokens
        guard foundTokens.count == names.count else { return false }
        
        // At least one token must meet the minimum weight
        let hasMinWeight = foundTokens.contains { $0.weight >= minWeight }
        
        // Combined weight should be meaningful
        let combinedWeight = foundTokens.reduce(0) { $0 + $1.weight }
        let averageWeight = combinedWeight / Double(foundTokens.count)
        
        return hasMinWeight && averageWeight >= (minWeight * 0.8)
    }
    
    /// Check for any token from a list meeting weight threshold
    private static func hasAnyToken(_ tokens: [StyleToken], _ names: [String], minWeight: Double) -> Bool {
        return names.contains { name in
            tokens.contains { token in
                token.name.lowercased() == name.lowercased() && token.weight >= minWeight
            }
        }
    }
    
    /// Get the single most dominant token if it meets threshold
    private static func getDominantSingleToken(_ tokens: [StyleToken], minWeight: Double) -> StyleToken? {
        return tokens
            .filter { $0.weight >= minWeight }
            .max { $0.weight < $1.weight }
    }
        
    /// Get the most relevant prefix based on dominant tokens
    private static func getDominantPrefix(prefixedTokens: [(token: StyleToken, prefix: String)], analysis: TokenAnalysis) -> String {
        
        // First, try to get prefix from the highest weighted token
        if let dominantPrefixedToken = prefixedTokens.first {
            return dominantPrefixedToken.prefix
        }
        
        // Fallback based on analysis
        if analysis.isFluidAndIntuitive {
            return "Go with the flow"
        } else if analysis.isBoldAndDynamic {
            return "Energy's high today"
        } else if analysis.isLuxuriousAndComforting {
            return "Treat yourself right"
        } else if analysis.isStructuredAndMinimal {
            return "Keep it clean"
        } else if analysis.isGroundedAndSensual {
            return "Trust your instincts"
        }
        
        // Ultimate fallback
        return "Today's the day"
    }
    
    // MARK: - Token Analysis Structure (using the one from TokenAnalysisStructures.swift)
    private struct TokenAnalysis {
        let isFluidAndIntuitive: Bool
        let isBoldAndDynamic: Bool
        let isLuxuriousAndComforting: Bool
        let isStructuredAndMinimal: Bool
        let isGroundedAndSensual: Bool
        let isHarmoniousAndBalanced: Bool
        let isCalibratedAndSubtle: Bool
        let isExpansiveAndFresh: Bool
        let isCompletingAndSubstantial: Bool
        let isEmergingAndElevated: Bool
        let isExpansiveAndAbundant: Bool
        let isSensualAndLuxurious: Bool
        let isInnovativeAndUnconventional: Bool
        
        let primaryStructure: String?
        let primaryMood: String?
        let primaryTexture: String?
        let primaryColorQuality: String?
        let primaryExpression: String?
        let primaryColor: String?
        
        let overallWeight: Double
        let energyDirection: String
        
        let allTokens: [StyleToken]
    }
    
    // MARK: - Daily Signature Structure
    private struct DailySignature {
        let moonPhaseEnergy: String
        let planetaryDay: String
        let dominantMood: String
        let energyIntensity: String
        let dailyTokens: [String: Double]
    }
    
    // MARK: - Enhanced Daily Signature Generation (NO DUPLICATION)
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

        // ENHANCED TEMPORAL MARKERS (integrated - no separate function)
        let month = calendar.component(.month, from: Date())
        let hour = calendar.component(.hour, from: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        
        // Enhanced seasonal influence with monthly specificity
        switch month {
        case 1: // January
            tokens.append(StyleToken(
                name: "renewing",
                type: "mood",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "New Year Energy",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "crystalline",
                type: "color_quality",
                weight: 1.7 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Winter Clarity",
                originType: .transit
            ))
        case 3: // March
            tokens.append(StyleToken(
                name: "awakening",
                type: "mood",
                weight: 1.9 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Spring Emergence",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "fresh green",
                type: "color",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "New Growth",
                originType: .transit
            ))
        case 6: // June
            tokens.append(StyleToken(
                name: "radiant",
                type: "mood",
                weight: 2.0 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Summer Solstice",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "luminous",
                type: "color_quality",
                weight: 1.9 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Peak Light",
                originType: .transit
            ))
        case 9: // September
            tokens.append(StyleToken(
                name: "harvesting",
                type: "mood",
                weight: 1.7 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Autumn Equinox",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "amber",
                type: "color",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Autumn Light",
                originType: .transit
            ))
        case 12: // December
            tokens.append(StyleToken(
                name: "contemplative",
                type: "mood",
                weight: 1.7 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "Winter Solstice",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "deep blue",
                type: "color",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Markers",
                aspectSource: "December Depths",
                originType: .transit
            ))
        default:
            // General seasonal influence
            switch month {
            case 3, 4, 5: // Spring
                tokens.append(StyleToken(
                    name: "emerging",
                    type: "mood",
                    weight: 1.8 * weightVariation,
                    planetarySource: "Temporal Context",
                    aspectSource: "Spring Energy",
                    originType: .transit
                ))
            case 6, 7, 8: // Summer
                tokens.append(StyleToken(
                    name: "radiant",
                    type: "color_quality",
                    weight: 1.8 * weightVariation,
                    planetarySource: "Temporal Context",
                    aspectSource: "Summer Energy",
                    originType: .transit
                ))
            case 9, 10, 11: // Autumn
                tokens.append(StyleToken(
                    name: "layered",
                    type: "structure",
                    weight: 1.8 * weightVariation,
                    planetarySource: "Temporal Context",
                    aspectSource: "Autumn Energy",
                    originType: .transit
                ))
            case 12, 1, 2: // Winter
                tokens.append(StyleToken(
                    name: "protective",
                    type: "texture",
                    weight: 1.8 * weightVariation,
                    planetarySource: "Temporal Context",
                    aspectSource: "Winter Energy",
                    originType: .transit
                ))
            default:
                break
            }
        }
        
        // Enhanced time of day influence
        if hour >= 5 && hour < 9 {
            // Early Morning
            tokens.append(StyleToken(
                name: "fresh",
                type: "mood",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Early Morning Energy",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "clear",
                type: "color_quality",
                weight: 1.7 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Morning Light",
                originType: .transit
            ))
        } else if hour >= 12 && hour < 15 {
            // Early Afternoon
            tokens.append(StyleToken(
                name: "active",
                type: "mood",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Midday Energy",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "bright",
                type: "color_quality",
                weight: 1.9 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Peak Light",
                originType: .transit
            ))
        } else if hour >= 17 && hour < 20 {
            // Early Evening
            tokens.append(StyleToken(
                name: "reflective",
                type: "mood",
                weight: 1.7 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Evening Energy",
                originType: .transit
            ))
            tokens.append(StyleToken(
                name: "golden",
                type: "color",
                weight: 1.9 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Golden Hour",
                originType: .transit
            ))
        } else if hour >= 20 && hour < 23 {
            // Night
            tokens.append(StyleToken(
                name: "mysterious",
                type: "mood",
                weight: 1.8 * weightVariation,
                planetarySource: "Temporal Context",
                aspectSource: "Night Energy",
                originType: .transit
            ))
        }
        
        // WEEKLY CYCLE INFLUENCE (using weekOfYear)
        let weekPosition = weekOfYear % 4 // 4-week cycle
        switch weekPosition {
        case 0: // Week 1 of cycle - Initiating
            tokens.append(StyleToken(
                name: "initiating",
                type: "structure",
                weight: 1.5 * weightVariation,
                planetarySource: "Weekly Cycle",
                aspectSource: "Week 1 - Initiating",
                originType: .transit
            ))
        case 1: // Week 2 of cycle - Building
            tokens.append(StyleToken(
                name: "building",
                type: "structure",
                weight: 1.6 * weightVariation,
                planetarySource: "Weekly Cycle",
                aspectSource: "Week 2 - Building",
                originType: .transit
            ))
        case 2: // Week 3 of cycle - Expressing
            tokens.append(StyleToken(
                name: "expressing",
                type: "expression",
                weight: 1.7 * weightVariation,
                planetarySource: "Weekly Cycle",
                aspectSource: "Week 3 - Expressing",
                originType: .transit
            ))
        case 3: // Week 4 of cycle - Integrating
            tokens.append(StyleToken(
                name: "integrating",
                type: "structure",
                weight: 1.5 * weightVariation,
                planetarySource: "Weekly Cycle",
                aspectSource: "Week 4 - Integrating",
                originType: .transit
            ))
        default:
            break
        }
        
        // YEARLY POSITION INFLUENCE (using dayOfYear)
        let yearProgress = Double(dayOfYear) / 365.0
        if yearProgress < 0.33 {
            // First third of year - Growing Phase
            tokens.append(StyleToken(
                name: "growing",
                type: "expression",
                weight: 1.4 * weightVariation,
                planetarySource: "Yearly Cycle",
                aspectSource: "Year Growth Phase",
                originType: .transit
            ))
        } else if yearProgress < 0.66 {
            // Middle third of year - Expressing Phase
            tokens.append(StyleToken(
                name: "manifesting",
                type: "expression",
                weight: 1.6 * weightVariation,
                planetarySource: "Yearly Cycle",
                aspectSource: "Year Expression Phase",
                originType: .transit
            ))
        } else {
            // Final third of year - Integrating Phase
            tokens.append(StyleToken(
                name: "completing",
                type: "expression",
                weight: 1.5 * weightVariation,
                planetarySource: "Yearly Cycle",
                aspectSource: "Year Integration Phase",
                originType: .transit
            ))
        }

        return tokens
    }
    
    // MARK: - Token Analysis Functions
    
    /// Analyze tokens to determine dominant characteristics and combinations
    private static func analyzeTokens(_ tokens: [StyleToken]) -> TokenAnalysis {
        // Get tokens by category
        let structureTokens = tokens.filter { $0.type == "structure" }
        let moodTokens = tokens.filter { $0.type == "mood" }
        let textureTokens = tokens.filter { $0.type == "texture" }
        let colorQualityTokens = tokens.filter { $0.type == "color_quality" }
        let expressionTokens = tokens.filter { $0.type == "expression" }
        let colorTokens = tokens.filter { $0.type == "color" }
        
        // Calculate primary elements
        let primaryStructure = structureTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryMood = moodTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryTexture = textureTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryColorQuality = colorQualityTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryExpression = expressionTokens.max(by: { $0.weight < $1.weight })?.name
        let primaryColor = colorTokens.max(by: { $0.weight < $1.weight })?.name
        
        // Calculate overall weight
        let overallWeight = tokens.reduce(0) { $0 + $1.weight }
        
        // Determine token combinations with more flexible thresholds
        let isFluidAndIntuitive = hasFlexibleTokenCombination(tokens, ["fluid", "intuitive"], minWeight: 1.0)
        let isBoldAndDynamic = hasFlexibleTokenCombination(tokens, ["bold", "dynamic"], minWeight: 1.0)
        let isLuxuriousAndComforting = hasFlexibleTokenCombination(tokens, ["luxurious", "comforting"], minWeight: 1.0)
        let isStructuredAndMinimal = hasFlexibleTokenCombination(tokens, ["structured", "minimal"], minWeight: 1.0)
        let isGroundedAndSensual = hasFlexibleTokenCombination(tokens, ["grounded", "sensual"], minWeight: 1.0)
        let isHarmoniousAndBalanced = hasFlexibleTokenCombination(tokens, ["harmonious", "balanced"], minWeight: 1.0)
        let isCalibratedAndSubtle = hasFlexibleTokenCombination(tokens, ["calibrated", "subtle"], minWeight: 1.0)
        let isExpansiveAndFresh = hasFlexibleTokenCombination(tokens, ["expansive", "fresh"], minWeight: 1.0)
        let isCompletingAndSubstantial = hasFlexibleTokenCombination(tokens, ["completing", "substantial"], minWeight: 1.0)
        let isEmergingAndElevated = hasFlexibleTokenCombination(tokens, ["emerging", "elevated"], minWeight: 1.0)
        
        // Additional combinations
        let isExpansiveAndAbundant = hasFlexibleTokenCombination(tokens, ["expansive", "abundant"], minWeight: 1.0)
        let isSensualAndLuxurious = hasFlexibleTokenCombination(tokens, ["sensual", "luxurious"], minWeight: 1.0)
        let isInnovativeAndUnconventional = hasFlexibleTokenCombination(tokens, ["innovative", "unconventional"], minWeight: 1.0)
        
        // Determine energy direction
        let combinations = [
            "fluid_intuitive": isFluidAndIntuitive,
            "grounded_practical": isGroundedAndSensual,
            "innovative_unconventional": isInnovativeAndUnconventional,
            "responsive_adaptable": isHarmoniousAndBalanced
        ]
        
        let energyDirection = determineEnergyDirection(
            structure: primaryStructure,
            mood: primaryMood,
            texture: primaryTexture,
            combinations: combinations
        )
        
        return TokenAnalysis(
            isFluidAndIntuitive: isFluidAndIntuitive,
            isBoldAndDynamic: isBoldAndDynamic,
            isLuxuriousAndComforting: isLuxuriousAndComforting,
            isStructuredAndMinimal: isStructuredAndMinimal,
            isGroundedAndSensual: isGroundedAndSensual,
            isHarmoniousAndBalanced: isHarmoniousAndBalanced,
            isCalibratedAndSubtle: isCalibratedAndSubtle,
            isExpansiveAndFresh: isExpansiveAndFresh,
            isCompletingAndSubstantial: isCompletingAndSubstantial,
            isEmergingAndElevated: isEmergingAndElevated,
            isExpansiveAndAbundant: isExpansiveAndAbundant,
            isSensualAndLuxurious: isSensualAndLuxurious,
            isInnovativeAndUnconventional: isInnovativeAndUnconventional,
            primaryStructure: primaryStructure,
            primaryMood: primaryMood,
            primaryTexture: primaryTexture,
            primaryColorQuality: primaryColorQuality,
            primaryExpression: primaryExpression,
            primaryColor: primaryColor,
            overallWeight: overallWeight,
            energyDirection: energyDirection,
            allTokens: tokens
        )
    }
    
    /// Create daily signature based on current conditions
    private static func createDailySignature(from analysis: TokenAnalysis, moonPhase: Double, patternSeed: Int) -> DailySignature {
        
        // Determine moon phase energy
        let moonPhaseEnergy: String
        if moonPhase < 90.0 {
            moonPhaseEnergy = "building"
        } else if moonPhase < 180.0 {
            moonPhaseEnergy = "peak"
        } else if moonPhase < 270.0 {
            moonPhaseEnergy = "releasing"
        } else {
            moonPhaseEnergy = "renewal"
        }
        
        // Determine planetary day
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let planetaryDay: String
        switch weekday {
        case 1: planetaryDay = "Sun"
        case 2: planetaryDay = "Moon"
        case 3: planetaryDay = "Mars"
        case 4: planetaryDay = "Mercury"
        case 5: planetaryDay = "Jupiter"
        case 6: planetaryDay = "Venus"
        case 7: planetaryDay = "Saturn"
        default: planetaryDay = "Mercury"
        }
        
        // Determine dominant mood based on analysis
        let dominantMood = analysis.primaryMood ?? "balanced"
        
        // Determine energy intensity
        let energyIntensity: String
        if analysis.overallWeight > 20.0 {
            energyIntensity = "high"
        } else if analysis.overallWeight > 10.0 {
            energyIntensity = "moderate"
        } else {
            energyIntensity = "low"
        }
        
        // Create daily-specific token weights (for variation)
        let dailyTokens = createDailyTokenWeights(patternSeed: patternSeed)
        
        return DailySignature(
            moonPhaseEnergy: moonPhaseEnergy,
            planetaryDay: planetaryDay,
            dominantMood: dominantMood,
            energyIntensity: energyIntensity,
            dailyTokens: dailyTokens
        )
    }
    
    /// Get top tokens by category
    private static func getTopTokensByCategory(analysis: TokenAnalysis, category: String, count: Int) -> [String] {
        // Extract actual tokens from the analysis based on category
        switch category {
        case "color":
            // Extract color tokens from the token analysis
            if analysis.primaryColor != nil {
                var colorTokens = [analysis.primaryColor!]
                // Add common color combinations based on primary
                switch analysis.primaryColor {
                case "emerald":
                    colorTokens.append(contentsOf: ["rich green", "forest"])
                case "gold", "amber":
                    colorTokens.append(contentsOf: ["warm", "radiant"])
                case "blue":
                    colorTokens.append(contentsOf: ["electric blue", "oceanic"])
                case "red":
                    colorTokens.append(contentsOf: ["ruby", "crimson"])
                default:
                    colorTokens.append(contentsOf: ["charcoal", "warm"])
                }
                return Array(colorTokens.prefix(count))
            }
            return ["charcoal", "warm", "sage"]
            
        case "texture":
            // Extract texture tokens based on primary texture and combinations
            var textureTokens: [String] = []
            if let primaryTexture = analysis.primaryTexture {
                textureTokens.append(primaryTexture)
            }
            
            if analysis.isLuxuriousAndComforting {
                textureTokens.append(contentsOf: ["luxurious", "comforting"])
            } else if analysis.isStructuredAndMinimal {
                textureTokens.append(contentsOf: ["substantial", "refined"])
            } else {
                textureTokens.append(contentsOf: ["comfortable", "natural"])
            }
            
            return Array(Set(textureTokens).prefix(count)) // Remove duplicates
            
        case "color_quality":
            // Extract color quality tokens based on combinations and primary
            var qualityTokens: [String] = []
            if let primaryQuality = analysis.primaryColorQuality {
                qualityTokens.append(primaryQuality)
            }
            
            if analysis.isBoldAndDynamic {
                qualityTokens.append(contentsOf: ["vibrant", "intense", "bold"])
            } else if analysis.isHarmoniousAndBalanced {
                qualityTokens.append(contentsOf: ["elegant", "refined", "harmonious"])
            } else if analysis.isStructuredAndMinimal {
                qualityTokens.append(contentsOf: ["precise", "clear", "elegant"])
            } else {
                qualityTokens.append(contentsOf: ["warm", "gentle", "rich"])
            }
            
            return Array(Set(qualityTokens).prefix(count))
            
        case "structure":
            // Extract structure tokens based on primary and combinations
            var structureTokens: [String] = []
            if let primaryStructure = analysis.primaryStructure {
                structureTokens.append(primaryStructure)
            }
            
            if analysis.isFluidAndIntuitive {
                structureTokens.append(contentsOf: ["fluid", "adaptable"])
            } else if analysis.isStructuredAndMinimal {
                structureTokens.append(contentsOf: ["structured", "elegant"])
            } else if analysis.isBoldAndDynamic {
                structureTokens.append(contentsOf: ["dynamic", "defining"])
            } else {
                structureTokens.append(contentsOf: ["balanced", "versatile"])
            }
            
            return Array(Set(structureTokens).prefix(count))
            
        case "mood":
            // Extract mood tokens based on primary and combinations
            var moodTokens: [String] = []
            if let primaryMood = analysis.primaryMood {
                moodTokens.append(primaryMood)
            }
            
            if analysis.isGroundedAndSensual {
                moodTokens.append(contentsOf: ["grounded", "confident"])
            } else if analysis.isFluidAndIntuitive {
                moodTokens.append(contentsOf: ["intuitive", "reflective"])
            } else if analysis.isBoldAndDynamic {
                moodTokens.append(contentsOf: ["energetic", "confident"])
            } else if analysis.isExpansiveAndFresh {
                moodTokens.append(contentsOf: ["expansive", "optimistic"])
            } else {
                moodTokens.append(contentsOf: ["balanced", "authentic"])
            }
            
            return Array(Set(moodTokens).prefix(count))
            
        default:
            return []
        }
    }
    
    /// Create daily token weights for variation
    private static func createDailyTokenWeights(patternSeed: Int) -> [String: Double] {
        return [
            "emerald": 2.8,
            "iridescent aqua": 2.8,
            "structured charcoal": 2.52,
            "rich olive": 2.5,
            "warm terracotta": 2.5,
            "deep moss": 2.5,
            "slate gray": 2.4,
            "electric blue": 1.6,
            "royal purple": 1.8,
            "oceanic teal": 1.8
        ]
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
    
    /// Debug token analysis
    private static func debugTokenAnalysis(_ analysis: TokenAnalysis, dailySignature: DailySignature) {
        print("🎭 STYLE BRIEF TOKEN ANALYSIS:")
        print("Primary Structure: \(analysis.primaryStructure ?? "none")")
        print("Primary Mood: \(analysis.primaryMood ?? "none")")
        print("Primary Texture: \(analysis.primaryTexture ?? "none")")
        print("Primary Color: \(analysis.primaryColor ?? "none")")
        print("Energy Direction: \(analysis.energyDirection)")
        print("Moon Phase Energy: \(dailySignature.moonPhaseEnergy)")
        print("Planetary Day: \(dailySignature.planetaryDay)")
        print("Dominant Mood: \(dailySignature.dominantMood)")
        print("Energy Intensity: \(dailySignature.energyIntensity)")
    }
    
    // MARK: - Section Generation Methods (from Extensions)
    
    static func generateTextiles(tokens: [StyleToken]) -> String {
        return "Luxurious textures that feel substantial and authentic."
    }
    
    static func generateColors(tokens: [StyleToken]) -> String {
        return "Rich emerald tones with warm undertones and natural depth."
    }
    
    static func calculateBrightness(tokens: [StyleToken], moonPhase: Double) -> Int {
        return 65
    }
    
    static func calculateVibrancy(tokens: [StyleToken]) -> Int {
        return 70
    }
    
    static func generatePatterns(tokens: [StyleToken]) -> String {
        return "Subtle geometric patterns with organic flow and natural texture."
    }
    
    static func generateShape(tokens: [StyleToken]) -> String {
        return "Structured silhouettes with fluid draping and balanced proportions."
    }
    
    static func generateAccessories(tokens: [StyleToken]) -> String {
        return "Minimal pieces with meaningful weight and authentic materials."
    }
    
    static func generateTakeaway(tokens: [StyleToken], moonPhase: Double, patternSeed: Int) -> String {
        return "Trust your instincts about what feels right today. Your style knows what it's doing."
    }
    
    // MARK: - Utility Methods
    
    /// Generate a unique but stable seed for each day
    static func getDailyPatternSeed() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return (components.day ?? 1) + ((components.month ?? 1) * 31) +
               ((components.year ?? 2025) * 366)
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

        return tokens
    }
    
    /// Apply freshness boost based on transit planet and aspect type
    static func applyFreshnessBoost(transitPlanet: String, aspectType: String) -> Double {
        var freshnessBoost = 1.0
        
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
    
    /// Log token set for debugging
    private static func logTokenSet(_ label: String, _ tokens: [StyleToken]) {
        print("\n🎯 \(label):")
        let sortedTokens = tokens.sorted { $0.weight > $1.weight }
        for token in sortedTokens.prefix(10) { // Show top 10
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
