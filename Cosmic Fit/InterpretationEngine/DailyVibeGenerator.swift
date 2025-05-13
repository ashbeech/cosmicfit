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
        moonPhase: Double) -> String {
        
        print("\n☀️ GENERATING DAILY COSMIC VIBE ☀️")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // 1. Generate tokens for base style resonance (100% natal, Whole Sign)
        let baseStyleTokens = SemanticTokenGenerator.generateBaseStyleTokens(natal: natalChart)
        
        // 2. Generate tokens for emotional vibe of day (60% progressed Moon, 40% natal Moon, Placidus)
        let emotionalVibeTokens = SemanticTokenGenerator.generateEmotionalVibeTokens(
            natal: natalChart,
            progressed: progressedChart
        )
        
        // 3. Generate tokens from planetary transits (Placidus houses)
        let transitTokens = SemanticTokenGenerator.generateTransitTokens(
            transits: transits,
            natal: natalChart
        )
        
        // 4. Generate tokens from moon phase
        let moonPhaseTokens = SemanticTokenGenerator.generateMoonPhaseTokens(moonPhase: moonPhase)
        
        // 5. Generate tokens from weather if available
        var weatherTokens: [StyleToken] = []
        if let weather = weather {
            weatherTokens = SemanticTokenGenerator.generateWeatherTokens(weather: weather)
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
        
        // 7. Generate the daily vibe paragraphs
        let dailyVibe = assembleDailyVibe(tokens: allTokens, weather: weather, moonPhase: moonPhase)
        
        print("✅ Daily vibe generated successfully!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return dailyVibe
    }
    
    // MARK: - Private Helper Methods
    
    /// Assemble the daily vibe text from tokens
    private static func assembleDailyVibe(tokens: [StyleToken], weather: TodayWeather?, moonPhase: Double) -> String {
        // 1. Create opening based on weather and moon phase
        var dailyVibe = createDailyVibeOpening(weather: weather, moonPhase: moonPhase) + "\n\n"
        
        // 2. Add style resonance paragraph
        dailyVibe += createStyleResonanceParagraph(tokens: tokens) + "\n\n"
        
        // 3. Add emotional vibe paragraph
        dailyVibe += createEmotionalVibeParagraph(tokens: tokens, moonPhase: moonPhase) + "\n\n"
        
        // 4. Add transit impact paragraph
        dailyVibe += createTransitImpactParagraph(tokens: tokens) + "\n\n"
        
        // 5. Add practical styling suggestions
        dailyVibe += createStylingGuidance(tokens: tokens, weather: weather)
        
        return dailyVibe
    }
    
    /// Create opening sentence based on weather and moon phase
    private static func createDailyVibeOpening(weather: TodayWeather?, moonPhase: Double) -> String {
        var opening = "# Your Cosmic Fit Daily Vibe\n\n"
        
        // Format today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let todayString = dateFormatter.string(from: Date())
        opening += "## \(todayString)\n\n"
        
        // Create moon phase descriptor
        let moonPhaseDescription = getMoonPhaseDescription(moonPhase)
        
        // Create weather-based opening if available
        if let weather = weather {
            let tempFeeling = weather.temp < 15 ? "cool" : (weather.temp > 25 ? "warm" : "mild")
            let conditions = weather.conditions.lowercased()
            
            if conditions.contains("rain") || conditions.contains("shower") {
                opening += "With today's rainy weather, \(tempFeeling) temperatures, and the \(moonPhaseDescription) Moon, your cosmic fit calls for intentional layers and mood-enhancing choices."
            } else if conditions.contains("cloud") {
                opening += "Under today's cloudy skies, \(tempFeeling) temperatures, and the \(moonPhaseDescription) Moon, your cosmic fit invites nuanced textures and subtle definition."
            } else if conditions.contains("sun") || conditions.contains("clear") {
                opening += "With today's clear skies, \(tempFeeling) temperatures, and the \(moonPhaseDescription) Moon, your cosmic fit embraces clarity of expression and purposeful choices."
            } else if conditions.contains("snow") {
                opening += "In today's snowy landscape, with the \(moonPhaseDescription) Moon overhead, your cosmic fit focuses on protective layers with emotional resonance."
            } else if conditions.contains("wind") {
                opening += "Against today's winds and the backdrop of a \(moonPhaseDescription) Moon, your cosmic fit emphasizes structure and intentional flexibility."
            } else {
                opening += "Today's cosmic weather, with the \(moonPhaseDescription) Moon, suggests a style approach that balances your core essence with current energetic currents."
            }
        } else {
            // Weather-independent opening
            opening += "Today's cosmic weather, with the \(moonPhaseDescription) Moon, invites you to dress in alignment with both your core essence and current planetary energies."
        }
        
        return opening
    }
    
    /// Create style resonance paragraph based on base style tokens
    private static func createStyleResonanceParagraph(tokens: [StyleToken]) -> String {
        var paragraph = "## Base Style Resonance\n\n"
        
        // Extract dominant style characteristics
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 1.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 1.0 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 1.0 }
        let hasSubtle = tokens.contains { $0.name == "subtle" && $0.weight > 1.0 }
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 1.0 }
        let hasEthereal = tokens.contains { $0.name == "ethereal" || $0.name == "dreamy" && $0.weight > 1.0 }
        
        // Get top tokens for keywords
        let topTokens = tokens
            .filter { $0.weight > 1.0 }
            .sorted { $0.weight > $1.weight }
            .prefix(3)
            .map { $0.name }
        
        // Create first sentence based on dominant characteristic
        if hasStructured {
            paragraph += "Your core style essence today remains grounded in structure and definition. "
        } else if hasFluid {
            paragraph += "Your core style essence today flows with adaptability and intuitive movement. "
        } else if hasBold {
            paragraph += "Your core style essence today emanates confident energy and clear presence. "
        } else if hasSubtle {
            paragraph += "Your core style essence today expresses through nuance and thoughtful detail. "
        } else if hasEarthy {
            paragraph += "Your core style essence today connects with tactile grounding and practical wisdom. "
        } else if hasEthereal {
            paragraph += "Your core style essence today channels dreamlike intuition and fluid boundaries. "
        } else {
            paragraph += "Your core style essence today balances multiple energies with authentic expression. "
        }
        
        // Add keywords from top tokens
        if !topTokens.isEmpty {
            paragraph += "The qualities of " + topTokens.joined(separator: ", ") + " inform your baseline style energy, providing a consistent foundation regardless of daily fluctuations."
        } else {
            paragraph += "Your authentic style foundation provides consistent orientation regardless of daily fluctuations."
        }
        
        return paragraph
    }
    
    /// Create emotional vibe paragraph based on emotional tokens and moon phase
    private static func createEmotionalVibeParagraph(tokens: [StyleToken], moonPhase: Double) -> String {
        var paragraph = "## Emotional Vibe Today\n\n"
        
        // Extract emotional tone characteristics
        let hasIntrospective = tokens.contains { ($0.name == "introspective" || $0.name == "reflective") && $0.weight > 0.8 }
        let hasExpressive = tokens.contains { ($0.name == "expressive" || $0.name == "communicative") && $0.weight > 0.8 }
        let hasSensitive = tokens.contains { ($0.name == "sensitive" || $0.name == "intuitive") && $0.weight > 0.8 }
        let hasGrounded = tokens.contains { ($0.name == "grounded" || $0.name == "stable") && $0.weight > 0.8 }
        let hasIntense = tokens.contains { ($0.name == "intense" || $0.name == "passionate") && $0.weight > 0.8 }
        
        // Get moon phase qualities
        let isWaxing = moonPhase >= 0 && moonPhase < 180
        let isWaning = moonPhase >= 180 && moonPhase < 360
        let isNewMoon = moonPhase >= 0 && moonPhase < 45
        let isFullMoon = moonPhase >= 135 && moonPhase < 225
        
        // Create first sentence based on emotional tone and moon phase
        if hasIntrospective {
            paragraph += "Your emotional landscape today has a reflective, inward-focused quality. "
            if isWaning {
                paragraph += "This aligns with the waning moon's energy of release and processing. "
            } else if isNewMoon {
                paragraph += "The new moon amplifies this introspective quality, inviting deeper self-connection. "
            }
        } else if hasExpressive {
            paragraph += "Your emotional landscape today has an outward, communicative quality. "
            if isWaxing {
                paragraph += "This harmonizes with the waxing moon's energy of growth and expansion. "
            } else if isFullMoon {
                paragraph += "The full moon amplifies this expressive quality, bringing emotions to the surface. "
            }
        } else if hasSensitive {
            paragraph += "Your emotional landscape today has a sensitive, receptive quality. "
            if isFullMoon {
                paragraph += "The full moon intensifies this sensitivity, heightening your emotional awareness. "
            } else {
                paragraph += "The moon's current phase may bring subtle emotional currents to your awareness. "
            }
        } else if hasGrounded {
            paragraph += "Your emotional landscape today has a stable, centered quality. "
            paragraph += "This provides emotional steadiness regardless of the moon's phase. "
        } else if hasIntense {
            paragraph += "Your emotional landscape today has a potent, transformative quality. "
            if isFullMoon {
                paragraph += "The full moon amplifies this intensity, bringing powerful feelings to consciousness. "
            } else {
                paragraph += "The moon's current phase adds a layer of depth to your emotional experience. "
            }
        } else {
            paragraph += "Your emotional landscape today has a balanced, flowing quality. "
            paragraph += "The moon's current phase offers subtle emotional currents to navigate. "
        }
        
        // Add styling advice based on emotional tone
        paragraph += "Express this emotionally by choosing "
        
        if hasIntrospective {
            paragraph += "pieces that create a sense of protective comfort and self-containment. Layers that can be adjusted throughout the day will accommodate your changing inner landscape."
        } else if hasExpressive {
            paragraph += "pieces that facilitate connection and communication. Consider colors and shapes that externalize your inner state in ways that feel authentic and affirming."
        } else if hasSensitive {
            paragraph += "gentle textures and responsive fabrics. Prioritize physical comfort today, as your body is processing subtle energies and needs supportive materials."
        } else if hasGrounded {
            paragraph += "materials with substance and presence. The stability in your emotional field allows you to wear pieces with definition and structure without feeling confined."
        } else if hasIntense {
            paragraph += "pieces that can channel and transform emotional energy. Consider garments that have personal significance or transformative quality."
        } else {
            paragraph += "items that balance comfort with expression. Your emotional flexibility today allows for adaptability in how you present yourself."
        }
        
        return paragraph
    }
    
    /// Create transit impact paragraph based on transit tokens
    private static func createTransitImpactParagraph(tokens: [StyleToken]) -> String {
        var paragraph = "## Planetary Influences\n\n"
        
        // Extract transit characteristics from tokens
        let significantTransits = tokens.filter {
            $0.aspectSource != nil &&
            $0.aspectSource!.contains("transit") &&
            $0.weight > 0.5
        }.sorted { $0.weight > $1.weight }
        
        // If we have significant transits, describe them
        if !significantTransits.isEmpty {
            // Get the most significant transit
            if let topTransit = significantTransits.first {
                if let source = topTransit.aspectSource {
                    if source.contains("Venus") {
                        paragraph += "Venus transits are highlighting your aesthetic sensibilities today. "
                        paragraph += "This planetary influence brings a heightened appreciation for beauty, harmony, and pleasure. "
                        paragraph += "Express this through thoughtful color coordination and pieces that feel good against your skin. "
                    } else if source.contains("Mercury") {
                        paragraph += "Mercury transits are activating your communication style today. "
                        paragraph += "This planetary influence brings mental clarity and expressive communication. "
                        paragraph += "Consider incorporating subtle message elements or pieces that facilitate conversation. "
                    } else if source.contains("Mars") {
                        paragraph += "Mars transits are energizing your personal expression today. "
                        paragraph += "This planetary influence brings dynamic energy and assertive action. "
                        paragraph += "Channel this through pieces with defined structure and intentional edge. "
                    } else if source.contains("Jupiter") {
                        paragraph += "Jupiter transits are expanding your style potential today. "
                        paragraph += "This planetary influence brings optimism and a sense of possibility. "
                        paragraph += "Consider expressing this through one statement piece or a more expansive silhouette. "
                    } else if source.contains("Saturn") {
                        paragraph += "Saturn transits are refining your approach to style today. "
                        paragraph += "This planetary influence brings discipline and structural integrity. "
                        paragraph += "Express this through quality over quantity and attention to proper fit and proportion. "
                    } else if source.contains("Uranus") {
                        paragraph += "Uranus transits are innovating your style approach today. "
                        paragraph += "This planetary influence brings unexpected shifts and creative breakthroughs. "
                        paragraph += "Consider incorporating one unconventional element that expresses your unique perspective. "
                    } else if source.contains("Neptune") {
                        paragraph += "Neptune transits are dissolving boundaries in your style expression today. "
                        paragraph += "This planetary influence brings intuitive flow and spiritual connection. "
                        paragraph += "Express this through layers with subtle transparency or pieces with fluid movement. "
                    } else if source.contains("Pluto") {
                        paragraph += "Pluto transits are transforming aspects of your style identity today. "
                        paragraph += "This planetary influence brings depth and potential for renewal. "
                        paragraph += "Consider incorporating pieces with transformative quality or personal significance. "
                    } else if source.contains("Moon") {
                        paragraph += "Lunar transits are cycling through your emotional style patterns today. "
                        paragraph += "This fleeting influence brings shifting moods and intuitive responses. "
                        paragraph += "Stay adaptable with layers or accessories that can be adjusted as your feelings evolve. "
                    } else if source.contains("Sun") {
                        paragraph += "Solar transits are illuminating your authentic style expression today. "
                        paragraph += "This vital influence brings clarity and conscious intention. "
                        paragraph += "Express this through pieces that feel aligned with your core identity and purpose. "
                    } else {
                        paragraph += "Today's planetary transits are creating subtle shifts in your style energy. "
                        paragraph += "These cosmic influences invite mindful adjustments to your personal expression. "
                        paragraph += "Consider how your outfit can reflect both your stable essence and current cosmic weather. "
                    }
                } else {
                    // Default if we can't identify the transit source
                    paragraph += "Today's planetary positions create a unique cosmic weather pattern that influences your style expression. "
                    paragraph += "These transient energies invite you to adapt your core style essence to current conditions. "
                    paragraph += "Consider how your outfit can both ground your identity and respond to the day's particular qualities. "
                }
            } else {
                // Default if we don't have significant transits
                paragraph += "Today's planetary positions create a relatively neutral background for your personal style expression. "
                paragraph += "This allows your core essence to shine through with minimal cosmic interference. "
                paragraph += "Focus on pieces that authentically reflect your baseline style preferences and personal comfort. "
            }
        } else {
            // Default if we don't have transit data
            paragraph += "Today's planetary positions form a unique cosmic pattern that colors your personal style expression. "
            paragraph += "While subtle, these transient energies create a specific backdrop for how your style is received and experienced. "
            paragraph += "Tune into how different pieces feel today, as the planetary weather may shift how colors and textures resonate with you. "
        }
        
        return paragraph
    }
    
    /// Create practical styling guidance based on all tokens and weather
    private static func createStylingGuidance(tokens: [StyleToken], weather: TodayWeather?) -> String {
        var guidance = "## Today's Styling Guidance\n\n"
        
        // Extract top style tokens
        let topTokens = tokens
            .filter { $0.type == "structure" || $0.type == "texture" || $0.type == "mood" }
            .sorted { $0.weight > $1.weight }
            .prefix(5)
        
        // Create style keywords line
        var keywords: [String] = []
        for token in topTokens {
            keywords.append(token.name)
        }
        
        if !keywords.isEmpty {
            guidance += "**Style Keywords:** " + keywords.joined(separator: ", ") + "\n\n"
        } else {
            guidance += "**Style Keywords:** balanced, authentic, responsive\n\n"
        }
        
        // Add specific guidance based on token presence
        guidance += "**Focus Areas:**\n\n"
        
        // Color guidance
        if tokens.contains(where: { $0.name == "earthy" && $0.weight > 0.8 }) {
            guidance += "- **Colors:** Warm neutrals, terracotta, olive, or any earth tones that ground your energy\n"
        } else if tokens.contains(where: { $0.name == "watery" && $0.weight > 0.8 }) {
            guidance += "- **Colors:** Deep blues, teal, or fluid gradients that express emotional depth\n"
        } else if tokens.contains(where: { $0.name == "airy" && $0.weight > 0.8 }) {
            guidance += "- **Colors:** Light blues, whites, or subtle pastels that create mental space\n"
        } else if tokens.contains(where: { $0.name == "fiery" && $0.weight > 0.8 }) {
            guidance += "- **Colors:** Warm reds, oranges, or vibrant accents that express vital energy\n"
        } else {
            guidance += "- **Colors:** Choose tones that resonate with your current emotional state while grounding your core essence\n"
        }
        
        // Texture guidance
        if tokens.contains(where: { $0.name == "structured" && $0.weight > 0.8 }) {
            guidance += "- **Textures:** Crisp, defined fabrics with intentional weight and presence\n"
        } else if tokens.contains(where: { $0.name == "fluid" && $0.weight > 0.8 }) {
            guidance += "- **Textures:** Flowing, adaptable materials that move with your body\n"
        } else if tokens.contains(where: { $0.name == "tactile" && $0.weight > 0.8 }) {
            guidance += "- **Textures:** Richly textured surfaces that invite touch and sensory engagement\n"
        } else if tokens.contains(where: { $0.name == "layered" && $0.weight > 0.8 }) {
            guidance += "- **Textures:** Combinations of different weights and densities that create depth\n"
        } else {
            guidance += "- **Textures:** Select materials that support both physical comfort and emotional expression\n"
        }
        
        // Structure guidance
        if tokens.contains(where: { $0.name == "bold" && $0.weight > 0.8 }) {
            guidance += "- **Structure:** Defined silhouettes with intentional presence and clear lines\n"
        } else if tokens.contains(where: { $0.name == "subtle" && $0.weight > 0.8 }) {
            guidance += "- **Structure:** Understated shapes that reveal their quality through detail and fit\n"
        } else if tokens.contains(where: { $0.name == "balanced" && $0.weight > 0.8 }) {
            guidance += "- **Structure:** Harmonious proportions that create visual balance and ease\n"
        } else if tokens.contains(where: { $0.name == "dynamic" && $0.weight > 0.8 }) {
            guidance += "- **Structure:** Pieces that facilitate movement and active engagement\n"
        } else {
            guidance += "- **Structure:** Create a silhouette that honors your body's current needs and energy level\n"
        }
        
        // Add weather-specific guidance if available
        if let weather = weather {
            guidance += "\n**Weather Adaptation:**\n\n"
            
            // Temperature guidance
            if weather.temp < 10 {
                guidance += "- **Temperature:** With today's cold conditions, focus on insulating layers that maintain your style expression\n"
            } else if weather.temp < 20 {
                guidance += "- **Temperature:** With today's cool temperatures, incorporate strategic layers that can be adjusted\n"
            } else if weather.temp < 30 {
                guidance += "- **Temperature:** With today's moderate temperatures, balance comfort with style expression\n"
            } else {
                guidance += "- **Temperature:** With today's warmth, choose breathable fabrics that maintain your style integrity\n"
            }
            
            // Conditions guidance
            let conditions = weather.conditions.lowercased()
            if conditions.contains("rain") || conditions.contains("shower") {
                guidance += "- **Conditions:** Incorporate water-resistant elements that protect without compromising expression\n"
            } else if conditions.contains("snow") {
                guidance += "- **Conditions:** Select insulating, water-resistant pieces with visual interest despite functional needs\n"
            } else if conditions.contains("wind") {
                guidance += "- **Conditions:** Choose pieces that stay anchored in breeze while maintaining intended silhouette\n"
            } else if conditions.contains("cloud") {
                guidance += "- **Conditions:** Consider how colors and textures will read in diffused light\n"
            } else if conditions.contains("sun") || conditions.contains("clear") {
                guidance += "- **Conditions:** Pay attention to how fabrics and colors respond to direct sunlight\n"
            }
        }
        
        // Final integrative prompt
        guidance += "\nToday, let your style be a dynamic conversation between your core essence and the current cosmic weather. The most authentic expression comes when you honor both your foundation and the present moment."
        
        return guidance
    }
    
    /// Get moon phase description
    private static func getMoonPhaseDescription(_ phase: Double) -> String {
        if phase < 45.0 {
            return "New"
        } else if phase < 90.0 {
            return "Waxing Crescent"
        } else if phase < 135.0 {
            return "First Quarter"
        } else if phase < 180.0 {
            return "Waxing Gibbous"
        } else if phase < 225.0 {
            return "Full"
        } else if phase < 270.0 {
            return "Waning Gibbous"
        } else if phase < 315.0 {
            return "Last Quarter"
        } else {
            return "Waning Crescent"
        }
    }
}
