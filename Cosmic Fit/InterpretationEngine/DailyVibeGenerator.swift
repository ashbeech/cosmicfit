//
//  DailyVibeGenerator.swift
//  Cosmic Fit
//

import Foundation

class DailyVibeGenerator {
    
    // MARK: - Public Methods
    
    /// Generate a complete daily vibe interpretation with transit-primary weight distribution
    /// - Parameters:
    ///   - natalChart: The natal chart (for base style resonance using Whole Sign)
    ///   - progressedChart: The progressed chart (for emotional vibe using Placidus)
    ///   - transits: Array of transit aspects to natal chart
    ///   - weather: Optional current weather conditions
    ///   - moonPhase: Current lunar phase (0-360)
    ///   - weights: Weighting model to use for calculations
    /// - Returns: A formatted daily vibe interpretation
    static func generateDailyVibe(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [[String: Any]],
        weather: TodayWeather?,
        moonPhase: Double,
        weights: WeightingModel.Type = WeightingModel.self) -> DailyVibeContent {
            
            print("Using weights: natal=\(weights.natalWeight), progressed=\(weights.progressedWeight), transit=\(weights.DailyFit.transitWeight), moon=\(weights.DailyFit.moonPhaseWeight), weather=\(weights.DailyFit.weatherWeight)")
            
            print("\n☀️ GENERATING DAILY COSMIC VIBE - TRANSIT-PRIMARY SYSTEM ☀️")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎯 NEW WEIGHT DISTRIBUTION STRATEGY:")
            print("  • Transit Analysis: PRIMARY INFLUENCES (70% total weight)")
            print("  • Natal Foundation: CONSISTENT BASE (20% normalized weight)")
            print("  • Environmental Factors: SUPPORTING (10% total weight)")
            print("  • Result: Increased daily variation with stable foundation")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // 1. Generate tokens for base style resonance (100% natal, Whole Sign)
            let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
            logTokenSet("BASE STYLE TOKENS (WHOLE SIGN)", baseStyleTokens)
            
            // 2. Generate tokens for emotional vibe of day (60% progressed Moon, 40% natal Moon, Placidus)
            let emotionalVibeTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
                natal: natalChart,
                progressed: progressedChart
            )
            logTokenSet("EMOTIONAL VIBE TOKENS (PLACIDUS - 60% PROGRESSED, 40% NATAL)", emotionalVibeTokens)
            
            // 3. Generate DIVERSE tokens from planetary transits (fixed token generation)
            let rawTransitTokens = generateDiverseTransitTokens(
                transits: transits,
                natal: natalChart
            )
            
            // 3a. Separate fast and slow transit tokens and apply freshness boost
            var fastTransitTokens: [StyleToken] = []
            var slowTransitTokens: [StyleToken] = []

            for token in rawTransitTokens {
                if let planetarySource = token.planetarySource {
                    let freshnessBoost = applyFreshnessBoost(transitPlanet: planetarySource, aspectType: token.aspectSource ?? "")
                    let boostedToken = StyleToken(
                        name: token.name,
                        type: token.type,
                        weight: token.weight * freshnessBoost,
                        planetarySource: token.planetarySource,
                        signSource: token.signSource,
                        houseSource: token.houseSource,
                        aspectSource: token.aspectSource,
                        originType: token.originType
                    )
                    
                    if isFastPlanet(planetarySource) {
                        fastTransitTokens.append(boostedToken)
                    } else {
                        slowTransitTokens.append(boostedToken)
                    }
                }
            }
            
            logTokenSet("FAST TRANSIT TOKENS (Moon, Mercury, Venus, Sun, Mars)", fastTransitTokens)
            logTokenSet("SLOW TRANSIT TOKENS (Jupiter, Saturn, Uranus, Neptune, Pluto)", slowTransitTokens)
            
            // 4. Generate tokens for current weather
            let weatherTokens = generateWeatherTokens(weather: weather)
            logTokenSet("WEATHER TOKENS", weatherTokens)
            
            // 5. Generate daily signature tokens (includes temporal markers - NO DUPLICATION)
            let dailySignatureTokens = generateDailySignature()
            logTokenSet("DAILY SIGNATURE TOKENS (includes temporal markers)", dailySignatureTokens)
            
            // 6. APPLY NEW WEIGHTING MODEL DISTRIBUTION
            var allTokens: [StyleToken] = []
            
            print("\n🎯 APPLYING WEIGHTING MODEL:")
            print("  • Natal Base: \(weights.natalWeight * 100)% (balanced foundation)")
            print("  • Progressed: \(weights.progressedWeight * 100)% (emotional tone)")
            print("  • Transit: \(weights.DailyFit.transitWeight * 100)% (daily shifts)")
            print("  • Moon Phase: \(weights.DailyFit.moonPhaseWeight * 100)% (mood overlay)")
            print("  • Weather: \(weights.DailyFit.weatherWeight * 100)% (practical adjustment)")
            
            // Apply natal weight
            for token in baseStyleTokens {
                let normalizedWeight = min(token.weight * 0.4, 1.0)
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: normalizedWeight * weights.natalWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply progressed weight to emotional vibe tokens
            for token in emotionalVibeTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * weights.progressedWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply transit weight to both fast and slow transit tokens
            for token in fastTransitTokens {
                let strongBoostedWeight = token.weight * 3.0
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: strongBoostedWeight * weights.DailyFit.transitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            for token in slowTransitTokens {
                let moderateBoostedWeight = token.weight * 2.0
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: moderateBoostedWeight * weights.DailyFit.transitWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply weather weight
            for token in weatherTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * weights.DailyFit.weatherWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Apply moon phase weight to daily signature tokens
            for token in dailySignatureTokens {
                let adjustedToken = StyleToken(
                    name: token.name,
                    type: token.type,
                    weight: token.weight * weights.DailyFit.moonPhaseWeight,
                    planetarySource: token.planetarySource,
                    signSource: token.signSource,
                    houseSource: token.houseSource,
                    aspectSource: token.aspectSource,
                    originType: token.originType
                )
                allTokens.append(adjustedToken)
            }
            
            // Log combined weighted tokens
            logTokenSet("COMBINED WEIGHTED TOKENS (TRANSIT-PRIMARY)", allTokens)
            
            // Log top weighted tokens to verify transit dominance
            let topTokens = allTokens.sorted { $0.weight > $1.weight }.prefix(15)
            print("\n⭐ TOP 15 WEIGHTED TOKENS (Transit-Primary System) ⭐")
            for (index, token) in topTokens.enumerated() {
                let originLabel = getOriginLabel(token: token)
                print("\(index + 1). \(token.name) (\(token.type), weight: \(String(format: "%.3f", token.weight))) [\(originLabel)]")
            }
            
            // Verify weight distribution is working correctly
            verifyWeightDistribution(tokens: allTokens)
            
            // 7. Generate interpretative elements
            //let analysis = analyzeTokens(allTokens)
            let patternSeed = getDailyPatternSeed()
            let styleBrief = generateStyleBrief(tokens: allTokens, moonPhase: moonPhase, patternSeed: patternSeed, weights: weights)

            // 8. Generate specific fashion elements
            let textiles = generateTextiles(tokens: allTokens)
            let colors = generateColors(tokens: allTokens)
            let patterns = generatePatterns(tokens: allTokens)
            let shape = generateShape(tokens: allTokens)
            let brightness = calculateBrightness(tokens: allTokens, moonPhase: moonPhase)
            let vibrancy = calculateVibrancy(tokens: allTokens)
            
            print("✅ Daily Vibe generated successfully with Transit-Primary system!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // Return complete daily vibe content
            return DailyVibeContent(
                styleBrief: styleBrief,
                textiles: textiles,
                colors: colors,
                brightness: brightness,
                vibrancy: vibrancy,
                patterns: patterns,
                shape: shape,
                accessories: generateAccessories(tokens: allTokens),
                takeaway: generateTakeaway(tokens: allTokens),
                temperature: weather?.temperature,
                weatherCondition: weather?.condition
            )
        }
    
    // MARK: - Diverse Transit Token Generation
    
    /// Generate diverse tokens from transits without overly complex weighting
    private static func generateDiverseTransitTokens(
        transits: [[String: Any]],
        natal: NatalChartCalculator.NatalChart) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            print("\n🌟 GENERATING DIVERSE TRANSIT TOKENS 🌟")
            print("📊 Processing \(transits.count) transits...")
            
            for (index, transit) in transits.enumerated() {
                // Extract transit data
                let transitPlanet = transit["transitPlanet"] as? String ?? ""
                let natalPlanet = transit["natalPlanet"] as? String ?? ""
                let aspectType = transit["aspectType"] as? String ?? ""
                let orb = transit["orb"] as? Double ?? 1.0
                
                // Calculate base weight for this transit
                let baseWeight = calculateTransitBaseWeight(
                    transitPlanet: transitPlanet,
                    natalPlanet: natalPlanet,
                    aspectType: aspectType,
                    orb: orb
                )
                
                // Only process significant transits
                if baseWeight < 0.3 {
                    print("  [\(index + 1)] SKIPPED: \(transitPlanet) \(aspectType) \(natalPlanet) (weight: \(String(format: "%.3f", baseWeight)))")
                    continue
                }
                
                print("  [\(index + 1)] PROCESSING: \(transitPlanet) \(aspectType) \(natalPlanet) (weight: \(String(format: "%.3f", baseWeight)))")
                
                // Generate appropriate tokens for this combination
                let aspectSource = "\(transitPlanet) \(aspectType) \(natalPlanet)"
                let transitTokens = generateTransitStyleTokens(
                    transitPlanet: transitPlanet,
                    natalPlanet: natalPlanet,
                    aspectType: aspectType,
                    baseWeight: baseWeight,
                    aspectSource: aspectSource
                )
                
                tokens.append(contentsOf: transitTokens)
                print("    → Generated \(transitTokens.count) tokens: \(transitTokens.map { $0.name }.joined(separator: ", "))")
            }
            
            print("🎯 Total transit tokens generated: \(tokens.count)")
            
            return tokens
        }
    
    /// Generate style tokens for a specific transit
    private static func generateTransitStyleTokens(
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String,
        baseWeight: Double,
        aspectSource: String) -> [StyleToken] {
            
            var tokens: [StyleToken] = []
            
            // Generate tokens based on transit planet energy
            switch transitPlanet {
            case "Sun":
                tokens.append(contentsOf: generateSunTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Moon":
                tokens.append(contentsOf: generateMoonTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Mercury":
                tokens.append(contentsOf: generateMercuryTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Venus":
                tokens.append(contentsOf: generateVenusTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Mars":
                tokens.append(contentsOf: generateMarsTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Jupiter":
                tokens.append(contentsOf: generateJupiterTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Saturn":
                tokens.append(contentsOf: generateSaturnTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Uranus":
                tokens.append(contentsOf: generateUranusTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Neptune":
                tokens.append(contentsOf: generateNeptuneTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            case "Pluto":
                tokens.append(contentsOf: generatePlutoTransitTokens(natalPlanet: natalPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            default:
                tokens.append(contentsOf: generateOtherTransitTokens(transitPlanet: transitPlanet, aspectType: aspectType, baseWeight: baseWeight, aspectSource: aspectSource))
            }
            
            return tokens
        }
    
    // MARK: - Individual Planet Transit Token Generators
    
    private static func generateSunTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "radiant", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "confident", type: "expression", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "bold", type: "expression", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "striking", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "warm", type: "color_quality", weight: baseWeight, planetarySource: "Sun", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateMoonTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "flowing", type: "structure", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "soft", type: "texture", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "changeable", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "adaptive", type: "expression", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "intuitive", type: "mood", weight: baseWeight, planetarySource: "Moon", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateMercuryTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "smart", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "clean", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "edgy", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "detailed", type: "structure", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "versatile", type: "expression", weight: baseWeight, planetarySource: "Mercury", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateVenusTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "harmonious", type: "mood", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "beautiful", type: "expression", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "luxurious", type: "texture", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "dramatic", type: "expression", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "indulgent", type: "texture", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "pleasing", type: "mood", weight: baseWeight, planetarySource: "Venus", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateMarsTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "dynamic", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "energetic", type: "mood", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "sharp", type: "structure", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "aggressive", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "intense", type: "mood", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "assertive", type: "expression", weight: baseWeight, planetarySource: "Mars", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateJupiterTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "generous", type: "structure", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "optimistic", type: "mood", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "expansive", type: "expression", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "excessive", type: "structure", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "overconfident", type: "expression", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "abundant", type: "mood", weight: baseWeight, planetarySource: "Jupiter", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateSaturnTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "structured", type: "structure", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "refined", type: "expression", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "disciplined", type: "mood", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "restrictive", type: "structure", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "serious", type: "mood", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "conservative", type: "expression", weight: baseWeight, planetarySource: "Saturn", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateUranusTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "innovative", type: "expression", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "unconventional", type: "structure", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "electric", type: "color_quality", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "rebellious", type: "expression", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "disruptive", type: "mood", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "unique", type: "expression", weight: baseWeight, planetarySource: "Uranus", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateNeptuneTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "dreamy", type: "mood", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "fluid", type: "structure", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "ethereal", type: "texture", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "confused", type: "mood", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "illusory", type: "expression", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "mystical", type: "mood", weight: baseWeight, planetarySource: "Neptune", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generatePlutoTransitTokens(natalPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "powerful", type: "expression", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "magnetic", type: "mood", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "transformative", type: "expression", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "intense", type: "mood", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            tokens.append(StyleToken(name: "obsessive", type: "expression", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "deep", type: "mood", weight: baseWeight, planetarySource: "Pluto", aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    private static func generateOtherTransitTokens(transitPlanet: String, aspectType: String, baseWeight: Double, aspectSource: String) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // For outer planets (Uranus, Neptune, Pluto) and minor aspects
        switch aspectType {
        case "Conjunction", "Trine":
            tokens.append(StyleToken(name: "transformative", type: "mood", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
            
        case "Square", "Opposition":
            tokens.append(StyleToken(name: "evolving", type: "expression", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
            
        default:
            tokens.append(StyleToken(name: "subtle", type: "texture", weight: baseWeight, planetarySource: transitPlanet, aspectSource: aspectSource, originType: .transit))
        }
        
        return tokens
    }
    
    /// Calculate base weight for transit
    private static func calculateTransitBaseWeight(transitPlanet: String, natalPlanet: String, aspectType: String, orb: Double) -> Double {
        // Base aspect strength
        var baseWeight: Double
        switch aspectType {
        case "Conjunction": baseWeight = 1.0
        case "Opposition": baseWeight = 0.8
        case "Square": baseWeight = 0.8
        case "Trine": baseWeight = 0.6
        case "Sextile": baseWeight = 0.4
        default: baseWeight = 0.2
        }
        
        // Adjust for orb tightness
        let orbAdjustment = max(0.3, 1.0 - (orb / 5.0))
        
        // Adjust for transit planet importance
        let planetWeight: Double
        switch transitPlanet {
        case "Venus", "Mars": planetWeight = 1.2
        case "Mercury", "Sun", "Moon": planetWeight = 1.0
        case "Jupiter": planetWeight = 0.8
        case "Saturn": planetWeight = 0.7
        default: planetWeight = 0.5
        }
        
        return baseWeight * orbAdjustment * planetWeight
    }
    
    // MARK: - Helper Methods
    
    /// Check if a planet is considered fast-moving
    private static func isFastPlanet(_ planet: String) -> Bool {
        return ["Moon", "Mercury", "Venus", "Sun", "Mars"].contains(planet)
    }
    
    /// Log token set for debugging
    private static func logTokenSet(_ title: String, _ tokens: [StyleToken]) {
        print("\n📋 \(title) (\(tokens.count) tokens):")
        for token in tokens.prefix(10) {
            let originLabel = getOriginLabel(token: token)
            print("  • \(token.name) (\(token.type), weight: \(String(format: "%.3f", token.weight))) [\(originLabel)]")
        }
        if tokens.count > 10 {
            print("  ... and \(tokens.count - 10) more")
        }
    }
    
    /// Generate origin label for token
    private static func getOriginLabel(token: StyleToken) -> String {
        switch token.originType {
        case .natal:
            return "NATAL"
        case .transit:
            if let planetarySource = token.planetarySource {
                return isFastPlanet(planetarySource) ? "FAST TRANSIT" : "SLOW TRANSIT"
            }
            return "TRANSIT"
        case .progressed:
            return "PROGRESSED"
        case .weather:
            return "WEATHER"
        case .phase:
            return "DAILY SIG"
        }
    }
    
    /// Verify the weight distribution is working as intended
    private static func verifyWeightDistribution(tokens: [StyleToken]) {
        let natalTokens = tokens.filter { $0.originType == .natal }
        let transitTokens = tokens.filter { $0.originType == .transit }
        let progressedTokens = tokens.filter { $0.originType == .progressed }
        let weatherTokens = tokens.filter { $0.originType == .weather }
        let phaseTokens = tokens.filter { $0.originType == .phase }
        
        let natalWeight = natalTokens.reduce(0) { $0 + $1.weight }
        let transitWeight = transitTokens.reduce(0) { $0 + $1.weight }
        let progressedWeight = progressedTokens.reduce(0) { $0 + $1.weight }
        let weatherWeight = weatherTokens.reduce(0) { $0 + $1.weight }
        let phaseWeight = phaseTokens.reduce(0) { $0 + $1.weight }
        
        let totalWeight = natalWeight + transitWeight + progressedWeight + weatherWeight + phaseWeight
        
        print("\n📊 WEIGHT DISTRIBUTION VERIFICATION:")
        print("  • Natal: \(String(format: "%.1f%%", (natalWeight/totalWeight) * 100)) (target: ~45%)")
        print("  • Transit: \(String(format: "%.1f%%", (transitWeight/totalWeight) * 100)) (target: ~15%)")
        print("  • Progressed: \(String(format: "%.1f%%", (progressedWeight/totalWeight) * 100)) (target: ~25%)")
        print("  • Weather: \(String(format: "%.1f%%", (weatherWeight/totalWeight) * 100)) (target: ~5%)")
        print("  • Daily Signature: \(String(format: "%.1f%%", (phaseWeight/totalWeight) * 100)) (target: ~10%)")
        
        // Check if natal weight is dominating as expected
        if natalWeight > transitWeight * 2.0 {
            print("✅ SUCCESS: Natal influence DOMINATES (weighting model working)")
        } else if natalWeight > transitWeight {
            print("⚠️  PARTIAL: Natal influence dominates moderately - acceptable balance")
        } else {
            print("❌ FAILURE: Natal influence insufficient - check weighting model")
        }
    }
    
    /// Apply freshness boost for recent aspects
    private static func applyFreshnessBoost(transitPlanet: String, aspectType: String?) -> Double {
        // Fast planets get freshness boost
        if isFastPlanet(transitPlanet) {
            return 1.2
        }
        return 1.0
    }
    
    // MARK: - Content Generation Methods
    
    private static func generateWeatherTokens(weather: TodayWeather?) -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        guard let weather = weather else { return tokens }
        
        // Generate tokens based on weather condition
        switch weather.condition.lowercased() {
        case let condition where condition.contains("rain"):
            tokens.append(StyleToken(name: "protective", type: "texture", weight: 0.8, originType: .weather))
            tokens.append(StyleToken(name: "waterproof", type: "structure", weight: 0.7, originType: .weather))
        case let condition where condition.contains("sun"):
            tokens.append(StyleToken(name: "bright", type: "color_quality", weight: 0.8, originType: .weather))
            tokens.append(StyleToken(name: "light", type: "texture", weight: 0.7, originType: .weather))
        case let condition where condition.contains("cloud"):
            tokens.append(StyleToken(name: "layered", type: "structure", weight: 0.6, originType: .weather))
            tokens.append(StyleToken(name: "muted", type: "color_quality", weight: 0.5, originType: .weather))
        default:
            tokens.append(StyleToken(name: "versatile", type: "structure", weight: 0.5, originType: .weather))
        }
        
        // Generate tokens based on temperature
        let temp = weather.temperature
        if temp < 10 {
            tokens.append(StyleToken(name: "warm", type: "texture", weight: 0.9, originType: .weather))
            tokens.append(StyleToken(name: "cozy", type: "mood", weight: 0.8, originType: .weather))
        } else if temp > 25 {
            tokens.append(StyleToken(name: "cool", type: "texture", weight: 0.9, originType: .weather))
            tokens.append(StyleToken(name: "breathable", type: "structure", weight: 0.8, originType: .weather))
        }

        
        return tokens
    }
    
    private static func generateDailySignature() -> [StyleToken] {
        var tokens: [StyleToken] = []
        
        // Generate temporal rhythm tokens
        let calendar = Calendar.current
        let now = Date()
        let dayOfWeek = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        
        // Day of week influence
        switch dayOfWeek {
        case 1: // Sunday
            tokens.append(StyleToken(name: "relaxed", type: "mood", weight: 0.6, originType: .phase))
        case 2: // Monday
            tokens.append(StyleToken(name: "structured", type: "structure", weight: 0.7, originType: .phase))
        case 6, 7: // Friday, Saturday
            tokens.append(StyleToken(name: "expressive", type: "expression", weight: 0.8, originType: .phase))
        default:
            tokens.append(StyleToken(name: "practical", type: "structure", weight: 0.5, originType: .phase))
        }
        
        // Time of day influence
        if hour < 12 {
            tokens.append(StyleToken(name: "fresh", type: "color_quality", weight: 0.5, originType: .phase))
        } else if hour < 18 {
            tokens.append(StyleToken(name: "confident", type: "expression", weight: 0.6, originType: .phase))
        } else {
            tokens.append(StyleToken(name: "sophisticated", type: "expression", weight: 0.7, originType: .phase))
        }
        
        return tokens
    }
    
    private static func getDailyPatternSeed() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        return dayOfYear
    }
    
    // MARK: - Maria's Voice Style Brief Generation
    
    private static func generateStyleBrief(tokens: [StyleToken], moonPhase: Double, patternSeed: Int, weights: WeightingModel.Type) -> String {
        
        // Use existing token analysis but leverage the sophisticated interpretations
        let transitTokens = tokens.filter { $0.originType == .transit && $0.weight > 0.3 }
        let natalTokens = tokens.filter { $0.originType == .natal }
        let progressedTokens = tokens.filter { $0.originType == .progressed }
        let environmentalTokens = tokens.filter { $0.originType == .weather || $0.originType == .phase }
        
        // Calculate actual weight distribution (properly sensitive to WeightingModel changes)
        let transitWeight = transitTokens.reduce(0) { $0 + $1.weight }
        let natalWeight = natalTokens.reduce(0) { $0 + $1.weight }
        let progressedWeight = progressedTokens.reduce(0) { $0 + $1.weight }
        let environmentalWeight = environmentalTokens.reduce(0) { $0 + $1.weight }
        
        let totalWeight = transitWeight + natalWeight + progressedWeight + environmentalWeight
        
        // Extract transit interpretations using the sophisticated engine components
        let interpretedTransits = extractTransitInterpretationsFromEngine(
            transitTokens: transitTokens,
            natalTokens: natalTokens
        )
        
        // Determine confidence level based on dignity status and weight strength
        let confidenceLevel = calculateMariaConfidenceLevel(
            weightDistribution: (transitWeight/totalWeight, natalWeight/totalWeight, progressedWeight/totalWeight, environmentalWeight/totalWeight),
            interpretedTransits: interpretedTransits
        )
        
        // Generate Maria's response using the full interpretation system
        return generateMariaResponseFromEngine(
            interpretedTransits: interpretedTransits,
            natalFoundation: extractNatalFoundationFromTokens(natalTokens),
            weightDistribution: (
                transit: transitWeight/totalWeight,
                natal: natalWeight/totalWeight,
                progressed: progressedWeight/totalWeight,
                environmental: environmentalWeight/totalWeight
            ),
            confidenceLevel: confidenceLevel,
            moonPhase: moonPhase,
            patternSeed: patternSeed
        )
    }

    // Extract transit interpretations using InterpretationTextLibrary and existing engine logic
    private static func extractTransitInterpretationsFromEngine(
        transitTokens: [StyleToken],
        natalTokens: [StyleToken]
    ) -> [EnhancedTransitMeaning] {
        
        var interpretations: [EnhancedTransitMeaning] = []
        
        for token in transitTokens.sorted(by: { $0.weight > $1.weight }).prefix(3) {
            guard let aspectSource = token.aspectSource else { continue }
            
            // Parse aspect source (e.g., "Venus Square Pallas")
            let components = aspectSource.components(separatedBy: " ")
            guard components.count >= 3 else { continue }
            
            let transitPlanet = components[0]
            let aspectType = components[1]
            let natalPlanet = components[2]
            
            // Use TransitWeightCalculator for fashion relevance (already sophisticated)
            let fashionRelevance = TransitWeightCalculator.getFashionRelevanceScore(
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType
            )
            
            // Use PlanetPowerEvaluator for dignity assessment
            let natalDignity = assessNatalPlanetDignity(natalPlanet: natalPlanet, natalTokens: natalTokens)
            
            // Get aspect interpretation from InterpretationTextLibrary
            let aspectInterpretation = getAspectInterpretationFromLibrary(
                aspectType: aspectType,
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet
            )
            
            // Generate Maria's specific advice using the engine's interpretation
            let mariaAdvice = generateMariaAdviceFromEngineInterpretation(
                aspectInterpretation: aspectInterpretation,
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                fashionRelevance: fashionRelevance,
                natalDignity: natalDignity,
                weight: token.weight
            )
            
            interpretations.append(EnhancedTransitMeaning(
                aspectSource: aspectSource,
                transitPlanet: transitPlanet,
                natalPlanet: natalPlanet,
                aspectType: aspectType,
                weight: token.weight,
                fashionRelevance: fashionRelevance,
                natalDignity: natalDignity,
                aspectInterpretation: aspectInterpretation,
                mariaAdvice: mariaAdvice
            ))
        }
        
        return interpretations
    }

    // Use InterpretationTextLibrary for aspect meanings (not hard-coded)
    private static func getAspectInterpretationFromLibrary(
        aspectType: String,
        transitPlanet: String,
        natalPlanet: String
    ) -> AspectInterpretation {
        
        // Use the existing InterpretationTextLibrary structure
        let moodToken = getAspectMoodFromLibrary(aspectType: aspectType)
        let structuralImplication = getStructuralImplicationFromLibrary(aspectType: aspectType, planets: (transitPlanet, natalPlanet))
        let energyQuality = getEnergyQualityFromLibrary(aspectType: aspectType)
        
        return AspectInterpretation(
            moodQuality: moodToken,
            structuralImplication: structuralImplication,
            energyQuality: energyQuality,
            aspectType: aspectType
        )
    }

    // Use the sophisticated aspect mood system from InterpretationTextLibrary
    private static func getAspectMoodFromLibrary(aspectType: String) -> String {
        // This leverages the existing getAspectMoodToken logic
        switch aspectType {
        case "Conjunction", "Trine": return "harmonious"
        case "Square", "Opposition": return "dynamic"
        case "Sextile": return "supportive"
        default: return "subtle"
        }
    }

    // Get structural implications from the library system
    private static func getStructuralImplicationFromLibrary(aspectType: String, planets: (String, String)) -> String {
        
        let (transitPlanet, natalPlanet) = planets
        
        // Use InterpretationTextLibrary aspect patterns
        switch aspectType {
        case "Conjunction":
            if transitPlanet == "Venus" && natalPlanet == "Venus" {
                return "unified aesthetic expression - your style identity is intensifying"
            } else if transitPlanet == "Mars" && ["Venus", "Ascendant"].contains(natalPlanet) {
                return "merged energy and beauty - power and grace working together"
            } else {
                return "merged planetary energies creating unified expression"
            }
            
        case "Square":
            if transitPlanet == "Venus" && natalPlanet == "Venus" {
                return "creative aesthetic tension - your style is ready to evolve"
            } else if transitPlanet == "Mars" && natalPlanet == "Midheaven" {
                return "energy vs image tension - personal power vs public presentation"
            } else if transitPlanet == "Mercury" && natalPlanet == "Pluto" {
                return "communication depth challenge - surface vs psychological truth"
            } else {
                return "dynamic tension creating growth opportunities"
            }
            
        case "Opposition":
            if transitPlanet == "Jupiter" && natalPlanet == "Neptune" {
                return "expansion vs idealization - realistic luxury vs impossible standards"
            } else {
                return "polarized energies seeking integration and balance"
            }
            
        case "Trine":
            return "harmonious energy flow - easy, graceful expression"
            
        case "Sextile":
            return "opportunity for creative integration - gentle support"
            
        default:
            return "subtle planetary influence creating background shifts"
        }
    }

    // Get energy quality from library patterns
    private static func getEnergyQualityFromLibrary(aspectType: String) -> String {
        switch aspectType {
        case "Conjunction": return "intensified"
        case "Square": return "challenging"
        case "Opposition": return "contrasting"
        case "Trine": return "flowing"
        case "Sextile": return "supportive"
        default: return "subtle"
        }
    }

    // Assess natal planet dignity using PlanetPowerEvaluator system
    private static func assessNatalPlanetDignity(natalPlanet: String, natalTokens: [StyleToken]) -> DignityLevel {
        
        // Find the natal planet's sign from tokens (using existing token data)
        let natalPlanetTokens = natalTokens.filter { $0.planetarySource == natalPlanet }
        guard let planetToken = natalPlanetTokens.first,
              let signSource = planetToken.signSource else {
            return .neutral
        }
        
        // Use PlanetPowerEvaluator dignity system
        let dignityStatus = PlanetPowerEvaluator.getDignityStatus(planet: natalPlanet, sign: signSource)
        
        switch dignityStatus {
        case .domicile: return .strong
        case .exaltation: return .strong
        case .peregrine: return .neutral
        case .detriment: return .challenged
        case .fall: return .challenged
        }
    }

    // Calculate Maria's confidence level based on weight strength and dignity
    private static func calculateMariaConfidenceLevel(
        weightDistribution: (Double, Double, Double, Double),
        interpretedTransits: [EnhancedTransitMeaning]
    ) -> ConfidenceLevel {
        
        let (transitWeight, natalWeight, progressedWeight, environmentalWeight) = weightDistribution
        
        // High confidence if there's a clear dominant energy source (ANY source)
        if transitWeight > 0.6 || natalWeight > 0.6 || progressedWeight > 0.5 {
            return .high
        }
        
        // Medium confidence if weights are moderately clear
        if transitWeight > 0.4 || natalWeight > 0.4 || progressedWeight > 0.3 || environmentalWeight > 0.3 {
            return .medium
        }
        
        return .moderate
    }

    // Generate Maria's advice using the sophisticated engine interpretation
    private static func generateMariaAdviceFromEngineInterpretation(
        aspectInterpretation: AspectInterpretation,
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String,
        fashionRelevance: Double,
        natalDignity: DignityLevel,
        weight: Double
    ) -> String {
        
        // Scale advice intensity based on fashion relevance and weight
        let adviceIntensity = (fashionRelevance * weight)
        
        // Modulate confidence based on natal dignity
        let confidenceModifier = getConfidenceModifier(dignity: natalDignity)
        
        // Generate advice based on the structural implication from the library
        let baseAdvice = generateBaseAdviceFromStructure(
            structuralImplication: aspectInterpretation.structuralImplication,
            transitPlanet: transitPlanet,
            natalPlanet: natalPlanet,
            aspectType: aspectType
        )
        
        // Apply intensity and confidence modulation
        return modulateAdviceForMaria(
            baseAdvice: baseAdvice,
            intensity: adviceIntensity,
            confidenceModifier: confidenceModifier
        )
    }

    // Generate base advice from structural interpretation (using engine logic)
    private static func generateBaseAdviceFromStructure(
        structuralImplication: String,
        transitPlanet: String,
        natalPlanet: String,
        aspectType: String
    ) -> String {
        
        // Use the sophisticated structural interpretation to generate specific advice
        if structuralImplication.contains("aesthetic tension") {
            return "You're getting this restless feeling about your usual go-to pieces today, and honestly? Listen to that. Your aesthetic is ready to level up. Try taking something you know works perfectly and pairing it with that slightly experimental thing you've been avoiding."
            
        } else if structuralImplication.contains("energy vs image tension") {
            return "Your energy wants to be bigger today than your usual professional presentation allows. This isn't about showing up to meetings in leather pants, but it is about finding ways to let your real intensity show up in your public image. Maybe it's the cut that's sharper, the color that's richer, or finally wearing that piece that makes you feel unstoppable."
            
        } else if structuralImplication.contains("communication depth challenge") {
            return "Your style wants to communicate something real today, not just look pretty. What truth are you ready to tell through how you dress? Choose pieces that feel like they're having an actual conversation - unexpected details, powerful silhouettes, or colors that make people think twice."
            
        } else if structuralImplication.contains("expansion vs idealization") {
            return "You're feeling pulled between wanting to go bigger with your style and getting lost in impossible aesthetic ideals. Instead of scrolling through looks you could never realistically wear, take that expansive energy and apply it to elevating what you actually have. The luxury you're craving is achievable - just more strategic than fantastical."
            
        } else if structuralImplication.contains("unified aesthetic expression") {
            return "Everything's aligning beautifully in your style universe today. Trust those choices that feel naturally unified and powerful - when your aesthetic is this coherent, don't overthink it."
            
        } else if structuralImplication.contains("harmonious energy flow") {
            return "Everything's flowing beautifully today, so trust those style choices that feel effortless but still interesting. When it's this easy, don't overthink it."
            
        } else if structuralImplication.contains("dynamic tension") {
            return "There's some creative tension happening today that's actually perfect for style evolution. Use that restless energy to try combinations that push your boundaries while still feeling like you."
            
        } else if structuralImplication.contains("polarized energies") {
            return "You're feeling pulled in different style directions today. Instead of choosing sides, try finding pieces that honor both impulses - familiar comfort with unexpected elements."
            
        } else {
            // Fallback to aspect-based advice
            return generateAspectBasedAdvice(aspectType: aspectType)
        }
    }

    // Apply intensity and confidence modulation to Maria's advice
    private static func modulateAdviceForMaria(
        baseAdvice: String,
        intensity: Double,
        confidenceModifier: String
    ) -> String {
        
        // High intensity (>1.0) - add emphasis
        if intensity > 1.0 {
            return "\(baseAdvice) \(confidenceModifier)"
        }
        
        // Medium intensity (0.5-1.0) - standard confidence
        if intensity > 0.5 {
            return baseAdvice
        }
        
        // Lower intensity - soften the advice
        return "Pay attention to the subtle shift toward \(baseAdvice.lowercased())"
    }

    // Get confidence modifier based on dignity
    private static func getConfidenceModifier(dignity: DignityLevel) -> String {
        switch dignity {
        case .strong:
            return "Your instincts about this are particularly sharp right now."
        case .neutral:
            return "Trust your gut feeling about what feels right."
        case .challenged:
            return "Take your time with this choice - when in doubt, start small."
        }
    }

    // Generate final Maria response using all engine components
    private static func generateMariaResponseFromEngine(
        interpretedTransits: [EnhancedTransitMeaning],
        natalFoundation: NatalFoundation,
        weightDistribution: (transit: Double, natal: Double, progressed: Double, environmental: Double),
        confidenceLevel: ConfidenceLevel,
        moonPhase: Double,
        patternSeed: Int
    ) -> String {
        
        // Generate opening based on actual weight distribution sensitivity
        let opening = generateWeightSensitiveOpening(
            weightDistribution: weightDistribution,
            primaryTransit: interpretedTransits.first,
            confidenceLevel: confidenceLevel,
            patternSeed: patternSeed
        )
        
        // Use the sophisticated transit interpretations for core advice
        let coreAdvice = interpretedTransits.prefix(2).map { $0.mariaAdvice }.joined(separator: " ")
        
        // Generate foundation-aware closing
        let closing = generateFoundationAwareClosing(
            natalFoundation: natalFoundation,
            moonPhase: moonPhase,
            confidenceLevel: confidenceLevel,
            patternSeed: patternSeed
        )
        
        return "\(opening) \(coreAdvice) \(closing)"
    }

    // Weight-sensitive opening (responds to WeightingModel changes)
    private static func generateWeightSensitiveOpening(
        weightDistribution: (transit: Double, natal: Double, progressed: Double, environmental: Double),
        primaryTransit: EnhancedTransitMeaning?,
        confidenceLevel: ConfidenceLevel,
        patternSeed: Int
    ) -> String {
        
        let confidencePrefix = getOpeningConfidencePrefix(level: confidenceLevel)
        
        // High transit weight (>0.6) - strong change energy
        if weightDistribution.transit > 0.6 {
            let transitOpenings = [
                "\(confidencePrefix)You're getting this restless feeling about your usual style choices today, and honestly? Listen to that.",
                "\(confidencePrefix)There's definitely something shifting in your energy today that wants to show up differently.",
                "\(confidencePrefix)Your style brain is feeling particularly evolved today, like it's ready to try something new."
            ]
            return transitOpenings[patternSeed % transitOpenings.count]
        }
        
        // High natal weight (>0.6) - foundation emphasis
        if weightDistribution.natal > 0.6 {
            let natalOpenings = [
                "\(confidencePrefix)You're in one of those moods where trusting your foundational style instincts is exactly right.",
                "\(confidencePrefix)Today's the kind of day where your core aesthetic wisdom really knows what it's talking about.",
                "\(confidencePrefix)There's something powerful about being picky with your energy, and your clothes should back that up."
            ]
            return natalOpenings[patternSeed % natalOpenings.count]
        }
        
        // Add progressed and environmental cases to generateWeightSensitiveOpening
        if weightDistribution.progressed > 0.5 {
            let progressedOpenings = [
                "\(confidencePrefix)You're growing into a more sophisticated version of your aesthetic self today.",
                "\(confidencePrefix)Your emotional evolution is showing up in how you want to express yourself.",
                "\(confidencePrefix)There's this deeper layer of your style personality that's ready to emerge."
            ]
            return progressedOpenings[patternSeed % progressedOpenings.count]
        }

        if weightDistribution.environmental > 0.4 {
            let environmentalOpenings = [
                "\(confidencePrefix)The weather and general vibe today are asking for some practical magic with your outfit choices.",
                "\(confidencePrefix)You're feeling particularly tuned into what the day actually needs from your wardrobe.",
                "\(confidencePrefix)Today's one of those days where letting your environment guide your style choices makes perfect sense."
            ]
            return environmentalOpenings[patternSeed % environmentalOpenings.count]
        }
        
        // Moderate natal (0.4-0.6) vs lower natal (0.2-0.4) - different confidence levels
        if weightDistribution.natal > 0.4 {
            return "\(confidencePrefix)You're channeling that steady, grounded energy that comes from knowing what works for you."
        } else if weightDistribution.natal > 0.2 {
            return "\(confidencePrefix)Your foundational style sense is offering some gentle guidance today."
        }
        
        // Balanced or environmental
        let balancedOpenings = [
            "\(confidencePrefix)You're in one of those perfectly balanced moods where everything feels possible style-wise.",
            "\(confidencePrefix)There's this beautiful equilibrium happening today between staying true to yourself and trying something fresh."
        ]
        return balancedOpenings[patternSeed % balancedOpenings.count]
    }

    // Confidence prefix based on calculated confidence level
    private static func getOpeningConfidencePrefix(level: ConfidenceLevel) -> String {
        switch level {
        case .high: return ""  // No qualifier needed - direct confidence
        case .medium: return ""  // Standard Maria voice
        case .moderate: return "There's this sense that "  // Softer approach
        }
    }

    // Extract natal foundation from existing natal tokens (using engine data)
    private static func extractNatalFoundationFromTokens(_ natalTokens: [StyleToken]) -> NatalFoundation {
        
        // Get dominant planets from existing token sources
        let planetCounts = natalTokens.reduce(into: [String: Double]()) { counts, token in
            if let planet = token.planetarySource {
                counts[planet, default: 0] += token.weight
            }
        }
        
        let dominantPlanets = planetCounts.sorted { $0.value > $1.value }.prefix(2).map { $0.key }
        
        // Get elements from sign sources in tokens
        let elementCounts = natalTokens.reduce(into: [String: Int]()) { counts, token in
            if let sign = token.signSource {
                let element = getElementFromSign(sign)
                counts[element, default: 0] += 1
            }
        }
        
        let primaryElements = elementCounts.sorted { $0.value > $1.value }.prefix(2).map { $0.key }
        
        return NatalFoundation(
            dominantPlanets: Array(dominantPlanets),
            primaryElements: Array(primaryElements)
        )
    }

    // Helper methods
    private static func getElementFromSign(_ signName: String) -> String {
        if ["Aries", "Leo", "Sagittarius"].contains(signName) { return "fire" }
        if ["Taurus", "Virgo", "Capricorn"].contains(signName) { return "earth" }
        if ["Gemini", "Libra", "Aquarius"].contains(signName) { return "air" }
        if ["Cancer", "Scorpio", "Pisces"].contains(signName) { return "water" }
        return "balanced"
    }

    private static func generateAspectBasedAdvice(aspectType: String) -> String {
        switch aspectType {
        case "Square":
            return "Use that creative tension to try combinations that push your boundaries while still feeling like you."
        case "Opposition":
            return "Balance the opposing energies by choosing pieces that honor both impulses."
        case "Conjunction":
            return "Let these merged energies guide you toward unified, powerful style choices."
        case "Trine":
            return "Everything's flowing nicely today, so trust those easy choices that feel effortless but interesting."
        default:
            return "Pay attention to the subtle style shifts your intuition is asking for today."
        }
    }

    private static func generateFoundationAwareClosing(
        natalFoundation: NatalFoundation,
        moonPhase: Double,
        confidenceLevel: ConfidenceLevel,
        patternSeed: Int
    ) -> String {
        
        let foundationElements = natalFoundation.primaryElements.joined(separator: " and ")
        
        let confidenceClosings: [ConfidenceLevel: [String]] = [
            .high: [
                "Your natural \(foundationElements) energy gives you the grounding to experiment without losing yourself.",
                "Trust that gut feeling over whatever nonsense social media is pushing this week.",
                "Sometimes the perfect outfit is the one that surprises even you."
            ],
            .medium: [
                "All of this works because you have that solid \(foundationElements) foundation to build from.",
                "Your instincts about what makes you feel fantastic are particularly sharp right now."
            ],
            .moderate: [
                "Trust your instincts - they're pointing you in the right direction today.",
                "When in doubt, start with what feels most authentically you."
            ]
        ]
        
        let closings = confidenceClosings[confidenceLevel] ?? confidenceClosings[.medium]!
        return closings[patternSeed % closings.count]
    }

    // Supporting data structures
    private struct EnhancedTransitMeaning {
        let aspectSource: String
        let transitPlanet: String
        let natalPlanet: String
        let aspectType: String
        let weight: Double
        let fashionRelevance: Double
        let natalDignity: DignityLevel
        let aspectInterpretation: AspectInterpretation
        let mariaAdvice: String
    }

    private struct AspectInterpretation {
        let moodQuality: String
        let structuralImplication: String
        let energyQuality: String
        let aspectType: String
    }

    private struct NatalFoundation {
        let dominantPlanets: [String]
        let primaryElements: [String]
    }

    private enum DignityLevel {
        case strong      // Domicile/Exaltation
        case neutral     // Peregrine
        case challenged  // Detriment/Fall
    }

    private enum ConfidenceLevel {
        case high        // Clear weight dominance
        case medium      // Moderate clarity
        case moderate    // Scattered energy
    }
    
    private static func generateTextiles(tokens: [StyleToken]) -> String {
        let textureTokens = tokens.filter { $0.type == "texture" }.sorted { $0.weight > $1.weight }
        if let primary = textureTokens.first {
            return "Focus on \(primary.name) textures"
        }
        return "Balanced textile choices"
    }
    
    private static func generateColors(tokens: [StyleToken]) -> String {
        let colorTokens = tokens.filter { $0.type == "color" || $0.type == "color_quality" }.sorted { $0.weight > $1.weight }
        if let primary = colorTokens.first {
            return "\(primary.name.capitalized) tones"
        }
        return "Neutral palette"
    }
    
    private static func generatePatterns(tokens: [StyleToken]) -> String {
        let structureTokens = tokens.filter { $0.type == "structure" }.sorted { $0.weight > $1.weight }
        if let primary = structureTokens.first {
            return "\(primary.name.capitalized) patterns"
        }
        return "Clean lines"
    }
    
    private static func generateShape(tokens: [StyleToken]) -> String {
        let structureTokens = tokens.filter { $0.type == "structure" }.sorted { $0.weight > $1.weight }
        if let primary = structureTokens.first {
            return "\(primary.name.capitalized) silhouette"
        }
        return "Balanced proportions"
    }
    
    private static func calculateBrightness(tokens: [StyleToken], moonPhase: Double) -> Int {
        let colorQualityTokens = tokens.filter { $0.type == "color_quality" }
        var brightness = 50
        
        for token in colorQualityTokens {
            switch token.name {
            case "bright", "radiant", "electric":
                brightness += Int(token.weight * 20)
            case "muted", "soft", "subtle":
                brightness -= Int(token.weight * 15)
            default:
                break
            }
        }
        
        // Moon phase influence
        let moonPhasePercent = (moonPhase / 360.0) * 100
        if moonPhasePercent > 75 {
            brightness += 10
        } else if moonPhasePercent < 25 {
            brightness -= 10
        }
        
        return max(0, min(100, brightness))
    }
    
    private static func calculateVibrancy(tokens: [StyleToken]) -> Int {
        let expressionTokens = tokens.filter { $0.type == "expression" }
        var vibrancy = 50
        
        for token in expressionTokens {
            switch token.name {
            case "bold", "dynamic", "expressive":
                vibrancy += Int(token.weight * 20)
            case "subtle", "conservative", "refined":
                vibrancy -= Int(token.weight * 15)
            default:
                break
            }
        }
        
        return max(0, min(100, vibrancy))
    }
    
    private static func generateAccessories(tokens: [StyleToken]) -> String {
        let expressionTokens = tokens.filter { $0.type == "expression" }.sorted { $0.weight > $1.weight }
        if let primary = expressionTokens.first {
            return "\(primary.name.capitalized) accessories"
        }
        return "Minimal accessories"
    }
    
    private static func generateTakeaway(tokens: [StyleToken]) -> String {
        let topToken = tokens.max { $0.weight < $1.weight }
        if let top = topToken {
            return "Channel your inner \(top.name) energy today."
        }
        return "Trust your cosmic style intuition."
    }
}

// MARK: - Daily Vibe Content Structure
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
