//
//  ParagraphAssembler.swift
//  Cosmic Fit
//

import Foundation

struct ParagraphAssembler {
    
    // MARK: - Blueprint Structure Generation
    
    /// Generate complete blueprint interpretation for Cosmic Fit profile
    /// - Parameters:
    ///   - tokens: Array of weighted style tokens from the natal chart
    ///   - birthInfo: Optional birth date/time/location string for header
    /// - Returns: A fully formatted blueprint interpretation
    static func generateBlueprintInterpretation(tokens: [StyleToken], birthInfo: String? = nil) -> String {
        // Log tokens for validation
        logTokensForValidation(tokens)
        
        // Build the complete blueprint with all sections
        var blueprint = ""
        
        // Upper sections - all using Whole Sign system
        blueprint += "## Style Essence\n\n"
        blueprint += generateEssenceSection(from: tokens) + "\n\n"
        
        blueprint += "## Celestial Style ID\n\n"
        blueprint += generateCoreSection(from: tokens) + "\n\n"
        
        blueprint += "## Expression\n\n"
        blueprint += generateExpressionSection(from: tokens) + "\n\n"
        
        blueprint += "## Magnetism\n\n"
        blueprint += generateMagnetismSection(from: tokens) + "\n\n"
        
        blueprint += "## Emotional Dressing\n\n"
        blueprint += generateEmotionalDressingSection(from: tokens) + "\n\n"
        
        blueprint += "## Planetary Frequency\n\n"
        blueprint += generatePlanetaryFrequencySection(from: tokens) + "\n\n"
        
        // Add Style Tensions section - new addition
        blueprint += "## Style Tensions\n\n"
        blueprint += generateStyleTensionsSection(from: tokens) + "\n\n"
        
        blueprint += "---\n\n"
        
        // Fabric guide - using Whole Sign system
        blueprint += "# Energetic Fabric Guide\n\n"
        blueprint += generateFabricRecommendations(from: tokens) + "\n\n"
        
        // Style pulse - 90% natal, 10% progressed flavor (handled by token weighting)
        blueprint += "# Style Pulse\n\n"
        blueprint += generateStylePulse(from: tokens) + "\n\n"
        
        blueprint += "---\n\n"
        
        // Fashion guidance - using Whole Sign system
        blueprint += "# Fashion Dos & Don'ts\n\n"
        blueprint += generateFashionGuidance(from: tokens) + "\n\n"
        
        // Color guidance - 70% natal, 30% progressed (handled by token weighting)
        blueprint += "# Elemental Colours\n\n"
        blueprint += generateColorRecommendations(from: tokens) + "\n\n"
        
        // Wardrobe storyline - 60% progressed with Placidus, 40% natal (handled by token weighting)
        blueprint += "# Wardrobe Storyline\n\n"
        blueprint += generateWardrobeStoryline(from: tokens)
        
        return blueprint
    }
    
    // MARK: - Debug Helper
    
    private static func logTokensForValidation(_ tokens: [StyleToken]) {
        print("\n🪙 TOKEN VALIDATION FOR BLUEPRINT 🪙")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
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
            print("🔷 \(type.uppercased()) TOKENS:")
            
            // Sort by weight (highest first)
            let sorted = typeTokens.sorted { $0.weight > $1.weight }
            for token in sorted {
                print("  • \(token.description())")
            }
            print("")
        }
        
        // Count tokens by planetary source
        var planetaryCounts: [String: Int] = [:]
        for token in tokens {
            if let planet = token.planetarySource {
                planetaryCounts[planet, default: 0] += 1
            }
        }
        
        print("🪐 PLANETARY SOURCE COUNTS:")
        for (planet, count) in planetaryCounts.sorted(by: { $0.key < $1.key }) {
            print("  • \(planet): \(count) tokens")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    // MARK: - Style Push-Pull Tension Detection
    
    /// Detects style push-pull conflicts from the token set
    /// - Parameter tokens: Array of weighted style tokens
    /// - Returns: Array of descriptive strings identifying style tensions
    static func detectStylePushPullConflicts(from tokens: [StyleToken]) -> [String] {
        let pairs: [(String, String, String)] = [
            ("fluid", "structured", "A tension exists between flow and form. Your outfits might oscillate between surrender and definition."),
            ("intuitive", "practical", "You sense your way through style, but also crave function. Dressing may feel like balancing instinct with purpose."),
            ("minimal", "expressive", "You prefer restraint, yet there's a desire to be seen. Your look may shift between quiet and pronounced statements."),
            ("airy", "grounded", "Your chart straddles weightlessness and rootedness, creating a dialogue between freedom and stability."),
            ("bold", "reserved", "Sometimes loud, sometimes soft. You dress to declare and sometimes to disappear."),
            ("emotive", "cool", "You feel deeply but show selectively. Style becomes a method of managing what's visible."),
            ("playful", "serious", "You oscillate between lighthearted expression and grounded purpose in how you present yourself."),
            ("luxurious", "minimal", "A pull exists between lavish richness and clean simplicity. Your style negotiates abundance and restraint."),
            ("vibrant", "muted", "Your wardrobe might swing between saturated statements and quiet neutrals as you balance visibility and subtlety."),
            ("classic", "experimental", "You honor tradition while craving novelty. Your style weaves between timeless pieces and unexpected choices."),
            ("soft", "structured", "Your chart balances yielding textures with architectural forms, creating a conversation between comfort and definition.")
        ]
        
        // Extract all token names as a set for efficient lookup
        let tokenNames = Set(tokens.map { $0.name })
        var found: [String] = []
        
        // Check for each push-pull pair
        for (a, b, description) in pairs {
            // Only add conflicts where both opposing tokens are present
            if tokenNames.contains(a) && tokenNames.contains(b) {
                found.append(description)
            }
        }
        
        return found
    }
    
    /// Generates style tensions paragraph based on push-pull conflicts
    static func generateStyleTensionsSection(from tokens: [StyleToken]) -> String {
        let conflicts = detectStylePushPullConflicts(from: tokens)
        
        if conflicts.isEmpty {
            return "Your style shows a harmonious integration of elements without significant opposing tensions. Your chart suggests a natural coherence between different aspects of your style expression."
        }
        
        var result = "Your chart reveals meaningful tensions that add depth to your style profile:\n\n"
        for (index, conflict) in conflicts.enumerated() {
            result += "- " + conflict
            if index < conflicts.count - 1 {
                result += "\n"
            }
        }
        
        // Add a closing insight if tensions were found
        if !conflicts.isEmpty {
            result += "\n\nThese contrasts aren't flaws—they're dimensions. The most compelling personal style emerges from resolving these creative tensions in ways that feel authentic to you."
        }
        
        return result
    }
    
    // MARK: - Upper Blueprint Sections (100% Natal, Whole Sign)
    
    /// Generates the Essence paragraph based on Sun, Venus, and Ascendant signs using Whole Sign
    static func generateEssenceSection(from tokens: [StyleToken]) -> String {
        // Get top 3 tokens by weight
        let topTokens = tokens
            .filter { $0.type == "mood" || $0.type == "texture" || $0.type == "structure" }
            .sorted { $0.weight > $1.weight }
            .prefix(3)
        
        // Check for dominant elements
        let hasEarthy = tokens.contains { $0.name == "earthy" && $0.weight > 2.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 2.0 }
        let hasBold = tokens.contains { $0.name == "bold" && $0.weight > 2.0 }
        let hasIntuitive = tokens.contains { $0.name == "intuitive" && $0.weight > 2.0 }
        
        // Extract key themes from top tokens
        var themes: [String] = []
        for token in topTokens {
            themes.append(token.name)
        }
        
        // Process 12th house influence (dreamlike) - using Whole Sign house
        let has12thHouse = tokens.contains { $0.houseSource == 12 && $0.weight > 2.0 }
        
        // Build the essence paragraph
        var essence = ""
        
        // Opening statement based on dominant characteristics
        if hasEarthy && hasIntuitive {
            essence += "You walk the line between earth and ether, rooted yet always sensing something deeper. "
        } else if hasEarthy {
            essence += "You embody a grounded presence, drawing strength from what feels stable and real. "
        } else if hasFluid {
            essence += "There's a flowing energy to your presence that's adaptable, intuitive, and subtly responsive. "
        } else if hasBold {
            essence += "You project a confident energy that leaves an impression—unmistakable, defined, and purposeful. "
        } else {
            essence += "Your style essence balances personal expression with authentic presence. "
        }
        
        // Second statement about force/energy
        if hasBold {
            essence += "There's a compelling force in your presence, a clear kind of intention. "
        } else {
            essence += "There's a quiet force in your presence, a soft kind of defiance. "
        }
        
        // Third statement about energy quality
        if hasBold {
            essence += "Your energy isn't subtle, but it resonates deeply. "
        } else {
            essence += "Your energy isn't loud, but it lingers meaningfully. "
        }
        
        // Fourth statement about dressing philosophy
        if has12thHouse {
            essence += "You dress like someone who remembers dreams and honors them through "
        } else {
            essence += "You dress like someone who remembers every version of yourself and honors them through "
        }
        
        essence += "texture, color, and the way fabric falls. "
        
        // Closing statement
        essence += "This blueprint reflects a wardrobe built on "
        
        // Add the three themes as closing qualities
        if themes.count >= 3 {
            essence += themes[0] + ", " + themes[1] + ", and " + themes[2] + "."
        } else if themes.count == 2 {
            essence += themes[0] + " and " + themes[1] + "."
        } else if themes.count == 1 {
            essence += themes[0] + " and authentic expression."
        } else {
            essence += "intuition, integrity, and evolution."
        }
        
        return essence
    }
    
    /// Generates the Core paragraph based on Sun, Venus, and Moon signs using Whole Sign
    static func generateCoreSection(from tokens: [StyleToken]) -> String {
        // Get tokens specifically from Sun, Venus, and Moon
        let coreTokens = tokens.filter {
            $0.planetarySource == "Sun" ||
            $0.planetarySource == "Venus" ||
            $0.planetarySource == "Moon"
        }
        
        // Check for element clusters
        let earthTokenCount = coreTokens.filter {
            $0.name == "grounded" || $0.name == "earthy" ||
            $0.name == "stable" || $0.name == "practical"
        }.count
        
        let waterTokenCount = coreTokens.filter {
            $0.name == "fluid" || $0.name == "emotional" ||
            $0.name == "intuitive" || $0.name == "sensitive"
        }.count
        
        let fireTokenCount = coreTokens.filter {
            $0.name == "bold" || $0.name == "energetic" ||
            $0.name == "passionate" || $0.name == "dynamic"
        }.count
        
        let airTokenCount = coreTokens.filter {
            $0.name == "communicative" || $0.name == "intellectual" ||
            $0.name == "social" || $0.name == "adaptable"
        }.count
        
        // Determine dominant element and descriptors
        var dominantElement = "balanced"
        var descriptors: [String] = []
        
        if earthTokenCount > waterTokenCount && earthTokenCount > fireTokenCount && earthTokenCount > airTokenCount {
            dominantElement = "earth"
            descriptors = ["grounded", "instinctual", "tactile"]
        } else if waterTokenCount > earthTokenCount && waterTokenCount > fireTokenCount && waterTokenCount > airTokenCount {
            dominantElement = "water"
            descriptors = ["intuitive", "flowing", "receptive"]
        } else if fireTokenCount > earthTokenCount && fireTokenCount > waterTokenCount && fireTokenCount > airTokenCount {
            dominantElement = "fire"
            descriptors = ["passionate", "energetic", "expressive"]
        } else if airTokenCount > earthTokenCount && airTokenCount > waterTokenCount && airTokenCount > fireTokenCount {
            dominantElement = "air"
            descriptors = ["communicative", "versatile", "intellectual"]
        } else {
            descriptors = ["balanced", "harmonious", "multifaceted"]
        }
        
        // Build core paragraph
        var core = ""
        
        if descriptors.count >= 3 {
            core += descriptors[0].capitalized + ", " + descriptors[1] + ", and " + descriptors[2] + "—"
        } else {
            core += "Naturally expressive and authentic—"
        }
        
        switch dominantElement {
        case "earth":
            core += "your foundation is built on clothing that feels like home."
        case "water":
            core += "your foundation is built on clothing that flows with your emotions."
        case "fire":
            core += "your foundation is built on clothing that expresses your energy."
        case "air":
            core += "your foundation is built on clothing that adapts to your social contexts."
        default:
            core += "your foundation is built on clothing that balances multiple aspects of your identity."
        }
        
        return core
    }
    
    /// Generates the Expression paragraph based on Ascendant and Mercury/Mars using Whole Sign
    static func generateExpressionSection(from tokens: [StyleToken]) -> String {
        let ascendantTokens = tokens.filter { $0.planetarySource == "Ascendant" }
        let mercuryMarsTokens = tokens.filter {
            ($0.planetarySource == "Mercury" || $0.planetarySource == "Mars") &&
            ($0.houseSource == 1 || $0.houseSource == 3 || $0.houseSource == 5)
        }
        
        // Check for expression styles based on Venus modality
        let hasCardinalVenus = tokens.contains {
            $0.planetarySource == "Venus" &&
            ($0.signSource == "Aries" || $0.signSource == "Cancer" ||
             $0.signSource == "Libra" || $0.signSource == "Capricorn")
        }
        
        let hasFixedVenus = tokens.contains {
            $0.planetarySource == "Venus" &&
            ($0.signSource == "Taurus" || $0.signSource == "Leo" ||
             $0.signSource == "Scorpio" || $0.signSource == "Aquarius")
        }
        
        let hasMutableVenus = tokens.contains {
            $0.planetarySource == "Venus" &&
            ($0.signSource == "Gemini" || $0.signSource == "Virgo" ||
             $0.signSource == "Sagittarius" || $0.signSource == "Pisces")
        }
        
        // Get descriptive adjectives for expression
        var expressionStyle = ""
        var intentionStyle = ""
        
        // Determine expression style from Venus modality
        if hasCardinalVenus {
            expressionStyle = "Directed and intentional"
        } else if hasFixedVenus {
            expressionStyle = "Consistent and defined"
        } else if hasMutableVenus {
            expressionStyle = "Adaptable and fluid"
        } else {
            expressionStyle = "Personal and authentic"
        }
        
        // Get intention style from Ascendant + Mercury/Mars
        let allExpressionTokens = ascendantTokens + mercuryMarsTokens
        
        let hasSubtle = allExpressionTokens.contains { $0.name == "subtle" || $0.name == "refined" }
        let hasBold = allExpressionTokens.contains { $0.name == "bold" || $0.name == "expressive" }
        let hasPractical = allExpressionTokens.contains { $0.name == "practical" || $0.name == "functional" }
        let hasCreative = allExpressionTokens.contains { $0.name == "creative" || $0.name == "playful" }
        
        if hasSubtle && hasPractical {
            intentionStyle = "subtle edge with practical intention"
        } else if hasSubtle && hasCreative {
            intentionStyle = "subtle creativity with artistic intention"
        } else if hasBold && hasPractical {
            intentionStyle = "bold presence with practical intention"
        } else if hasBold && hasCreative {
            intentionStyle = "bold creativity with expressive intention"
        } else if hasSubtle {
            intentionStyle = "subtle nuance with personal intention"
        } else if hasBold {
            intentionStyle = "bold statement with personal intention"
        } else if hasPractical {
            intentionStyle = "practical approach with functional intention"
        } else if hasCreative {
            intentionStyle = "creative flair with artistic intention"
        } else {
            intentionStyle = "personal style with authentic intention"
        }
        
        // Compose expression paragraph
        var expression = expressionStyle + ". You favor a " + intentionStyle + ". "
        
        expression += "You choose clothes that do more than look good—they "
        
        if hasPractical {
            expression += "serve a purpose, adapt to your needs, and support your daily journey."
        } else if hasCreative {
            expression += "tell a story, evoke emotion, and reflect your creative spirit."
        } else if hasSubtle {
            expression += "hold weight, memory, and meaning beyond what others might notice."
        } else {
            expression += "express your authentic self and communicate your presence."
        }
        
        return expression
    }
    
    /// Generates the Magnetism paragraph based on Venus placement and aspects using Whole Sign
    static func generateMagnetismSection(from tokens: [StyleToken]) -> String {
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        let visualHouseTokens = tokens.filter { $0.houseSource == 1 || $0.houseSource == 7 }
        let retrogradeTokens = tokens.filter {
            $0.name.contains("reflective") || $0.name.contains("introspective")
        }
        
        // Aggregate influence scores
        let venusInfluence = venusTokens.reduce(0.0) { $0 + $1.weight }
        let moonInfluence = moonTokens.reduce(0.0) { $0 + $1.weight }
        let visualInfluence = visualHouseTokens.reduce(0.0) { $0 + $1.weight }
        let retroInfluence = retrogradeTokens.reduce(0.0) { $0 + $1.weight }
        
        // Determine dominant celestial influence on magnetism
        enum Lure { case venus, moon, visual, balanced }
        let dominantLure: Lure
        switch max(venusInfluence, moonInfluence, visualInfluence) {
        case venusInfluence: dominantLure = .venus
        case moonInfluence: dominantLure = .moon
        case visualInfluence: dominantLure = .visual
        default: dominantLure = .balanced
        }
        
        // High-level qualities pulled from the wider token pool
        let hasQuiet = tokens.contains { $0.name == "quiet" || $0.name == "subtle" }
        let hasBold = tokens.contains { $0.name == "bold" || $0.name == "radiant" }
        let hasDeep = tokens.contains { $0.name == "deep" || $0.name == "intense" }
        let hasPlayful = tokens.contains { $0.name == "playful" || $0.name == "expressive" }
        
        // Primary quality string
        var magnetismQuality: String
        switch (hasQuiet, hasBold, hasDeep, hasPlayful) {
        case (true, false, true, _):
            magnetismQuality = "Quiet strength and depth"
        case (true, false, _, true):
            magnetismQuality = "Subtle playfulness and charm"
        case (_, true, true, _):
            magnetismQuality = "Powerful presence and depth"
        case (_, true, _, true):
            magnetismQuality = "Radiant charisma and playfulness"
        case (true, _, _, _):
            magnetismQuality = "Subtle presence and authenticity"
        case (_, true, _, _):
            magnetismQuality = "Bold energy and confidence"
        case (_, _, true, _):
            magnetismQuality = "Deep resonance and substance"
        case (_, _, _, true):
            magnetismQuality = "Playful spirit and versatility"
        default:
            magnetismQuality = "Authentic presence and natural appeal"
        }
        
        // Append dominant lure nuance
        switch dominantLure {
        case .venus:
            magnetismQuality += " (visually harmonious and naturally relational)."
        case .moon:
            magnetismQuality += " (emotionally resonant and naturally inviting)."
        case .visual:
            magnetismQuality += " (poised for connection—one-to-one interactions feel immediate)."
        case .balanced:
            magnetismQuality += "."
        }
        
        // Impact string
        var magnetismImpact: String
        if hasQuiet || (!hasBold && !hasPlayful) {
            magnetismImpact = " People may not always notice your outfit first, but they remember how it felt."
        } else {
            magnetismImpact = " Your style creates an immediate impression that lingers in others' memories."
        }
        
        // Retrograde undertone
        if retroInfluence > 0 {
            magnetismImpact += " A retrograde undertone makes the allure contemplative—others sense unspoken stories."
        }
        
        return magnetismQuality + magnetismImpact
    }
    
    /// Generates the Emotional Dressing paragraph based on Moon placement using Whole Sign
    static func generateEmotionalDressingSection(from tokens: [StyleToken]) -> String {
        let moonTokens = tokens.filter { $0.planetarySource == "Moon" }
        let neptuneTokens = tokens.filter {
            $0.planetarySource == "Neptune" ||
            $0.signSource == "Pisces" ||
            $0.houseSource == 12
        }
        
        // Weighted impact
        let moonDepth = moonTokens.reduce(0.0) { $0 + $1.weight }
        let neptuneDepth = neptuneTokens.reduce(0.0) { $0 + $1.weight }
        
        let hasProtective = tokens.contains { $0.name.contains("protective") }
        let hasIntuitive = tokens.contains { $0.name.contains("intuitive") }
        let hasEmotional = tokens.contains { $0.name.contains("emotional") }
        let hasHonest = tokens.contains {
            $0.name.contains("honest") || $0.name.contains("authentic")
        }
        
        var emotionalStyle = ""
        
        // Base narrative from combinations
        if hasHonest && hasEmotional {
            emotionalStyle = "You dress as a form of honest self-reflection—truthful, tactile, and emotionally expressive."
        } else if hasEmotional && hasProtective {
            emotionalStyle = "You dress as emotional protection, creating a safe boundary between your sensitive core and the outside world."
        } else if hasEmotional && hasIntuitive {
            emotionalStyle = "You dress intuitively, in harmony with emotional currents—flowing, responsive, and personal."
        } else if hasProtective {
            emotionalStyle = "Your clothing creates a protective boundary, regulating how much of yourself you share."
        } else if hasIntuitive {
            emotionalStyle = "You follow intuition, aligning inner landscape with outer expression."
        } else if hasEmotional {
            emotionalStyle = "Your choices reflect your emotional state, expressing your inner world."
        } else if hasHonest {
            emotionalStyle = "Your style reflects a commitment to authenticity, choosing pieces that resonate with your true self."
        } else {
            emotionalStyle = "You balance emotional expression with practical considerations."
        }
        
        // Layer in lunar/Neptunian potency
        if moonDepth > neptuneDepth * 1.2 {
            emotionalStyle += " Emotional comfort and security are consistently your first checkpoints when dressing."
        } else if neptuneDepth > moonDepth * 1.2 {
            emotionalStyle += " A dreamlike, imaginative quality consistently influences how you clothe yourself."
        } else if moonDepth > 0 && neptuneDepth > 0 {
            emotionalStyle += " You balance emotional comfort with artistic imagination—clothes feel like living, breathing memories."
        }
        
        return emotionalStyle
    }
    
    /// Generates the Planetary Frequency paragraph based on elemental dominance using Whole Sign
    static func generatePlanetaryFrequencySection(from tokens: [StyleToken]) -> String {
        // Count tokens by element
        var earthCount = tokens.filter { $0.name == "earthy" || $0.name == "grounded" }.count
        var waterCount = tokens.filter { $0.name == "watery" || $0.name == "fluid" }.count
        var fireCount = tokens.filter { $0.name == "fiery" || $0.name == "dynamic" }.count
        var airCount = tokens.filter { $0.name == "airy" || $0.name == "intellectual" }.count
        var metalCount = tokens.filter { $0.name == "structured" || $0.name == "disciplined" }.count
        
        // Apply weighting based on planetary sources
        earthCount = max(earthCount, tokens.filter {
            $0.planetarySource == "Venus" &&
            ($0.signSource == "Taurus" || $0.signSource == "Virgo" || $0.signSource == "Capricorn")
        }.count * 2)
        
        waterCount = max(waterCount, tokens.filter {
            $0.planetarySource == "Moon" &&
            ($0.signSource == "Cancer" || $0.signSource == "Scorpio" || $0.signSource == "Pisces")
        }.count * 2)
        
        fireCount = max(fireCount, tokens.filter {
            $0.planetarySource == "Sun" &&
            ($0.signSource == "Aries" || $0.signSource == "Leo" || $0.signSource == "Sagittarius")
        }.count * 2)
        
        airCount = max(airCount, tokens.filter {
            $0.planetarySource == "Mercury" &&
            ($0.signSource == "Gemini" || $0.signSource == "Libra" || $0.signSource == "Aquarius")
        }.count * 2)
        
        metalCount = max(metalCount, tokens.filter {
            $0.planetarySource == "Saturn"
        }.count * 2)
        
        // Determine primary and secondary elements
        var elements: [(String, Int)] = [
            ("earth", earthCount),
            ("water", waterCount),
            ("fire", fireCount),
            ("air", airCount),
            ("metal", metalCount)
        ]
        elements.sort { $0.1 > $1.1 }
        
        var frequency = ""
        
        if elements[0].1 > 0 && elements[1].1 > 0 {
            frequency = elements[0].0.capitalized + "-heavy with pulses of " + elements[1].0
            
            if elements[2].1 > 0 {
                frequency += " and " + elements[2].0
            }
            
            frequency += ". "
        } else if elements[0].1 > 0 {
            frequency = "Predominantly " + elements[0].0 + "-oriented. "
        } else {
            frequency = "Balanced across elemental influences. "
        }
        
        // Add descriptive content based on primary element
        switch elements[0].0 {
        case "earth":
            frequency += "You are drawn to what feels lived-in, weathered, and raw—with details that speak softly but stay."
        case "water":
            frequency += "You are drawn to what flows, adapts, and carries emotional resonance—with details that evoke feeling and memory."
        case "fire":
            frequency += "You are drawn to what energizes, transforms, and expresses vitality—with details that catch the light and command attention."
        case "air":
            frequency += "You are drawn to what communicates, connects, and conceptualizes—with details that stimulate the mind and facilitate exchange."
        case "metal":
            frequency += "You are drawn to what endures, structures, and refines—with details that demonstrate craftsmanship and longevity."
        default:
            frequency += "You are drawn to a balance of elements—incorporating details that address multiple sensory and emotional needs."
        }
        
        return frequency
    }
    
    // MARK: - Fabric Guide (100% Natal, Whole Sign)
    
    /// Generates fabric recommendations based on chart elements using Whole Sign
    static func generateFabricRecommendations(from tokens: [StyleToken]) -> String {
        var nourishingFabrics: [String] = []
        var depletingFabrics: [String] = []
        var groundingTextures: [String] = []
        var activatingTextures: [String] = []
        
        // Analyze tokens for fabric preferences - focus on Venus-sourced tokens first
        let venusTokens = tokens.filter { $0.planetarySource == "Venus" }
        
        // Check for strong elemental affinities
        if tokens.contains(where: { $0.name == "earthy" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["raw denim", "washed cotton", "linen"])
            groundingTextures.append(contentsOf: ["nubby", "coarse", "textured"])
        }
        
        if tokens.contains(where: { $0.name == "watery" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["silk", "rayon", "modal"])
            groundingTextures.append(contentsOf: ["flowing", "draping", "liquid"])
        }
        
        if tokens.contains(where: { $0.name == "fiery" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["wool", "leather", "textured knits"])
            activatingTextures.append(contentsOf: ["ribbed", "raised", "structured"])
        }
        
        if tokens.contains(where: { $0.name == "airy" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["cotton voile", "lightweight linen", "gauze"])
            activatingTextures.append(contentsOf: ["light", "breathable", "translucent"])
        }
        
        // Check for specific texture preferences
        if tokens.contains(where: { $0.name == "soft" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["cashmere", "brushed cotton", "jersey"])
            groundingTextures.append(contentsOf: ["plush", "brushed", "velvety"])
        }
        
        if tokens.contains(where: { $0.name == "structured" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["wool gabardine", "heavy cotton", "denim"])
            depletingFabrics.append("unstructured synthetics")
            activatingTextures.append(contentsOf: ["crisp", "substantial", "supportive"])
        }
        
        if tokens.contains(where: { $0.name == "fluid" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["silk", "lyocell", "rayon"])
            depletingFabrics.append(contentsOf: ["stiff brocades", "crisp organza"])
            groundingTextures.append(contentsOf: ["flowing", "draping", "liquid"])
        }
        
        if tokens.contains(where: { $0.name == "textured" && $0.weight > 2.0 }) {
            nourishingFabrics.append(contentsOf: ["tweed", "bouclé", "corduroy"])
            depletingFabrics.append("flat synthetics")
            groundingTextures.append(contentsOf: ["varied", "tactile", "dimensional"])
        }
        
        // Add more Venus-specific fabrics
        for token in venusTokens {
            if token.name == "luxurious" {
                nourishingFabrics.append(contentsOf: ["silk", "cashmere", "fine wool"])
            } else if token.name == "practical" {
                nourishingFabrics.append(contentsOf: ["cotton", "wool", "linen"])
            } else if token.name == "sensual" {
                nourishingFabrics.append(contentsOf: ["velvet", "silk", "soft leather"])
            }
        }
        
        // Default options if no strong preferences
        if nourishingFabrics.isEmpty {
            nourishingFabrics = ["natural fibers", "breathable cotton", "textured weaves"]
        }
        
        if depletingFabrics.isEmpty {
            depletingFabrics = ["high-shine synthetics", "overly processed materials", "fabrics that restrict movement"]
        }
        
        if groundingTextures.isEmpty {
            groundingTextures = ["tactile", "natural", "dimensional"]
        }
        
        if activatingTextures.isEmpty {
            activatingTextures = ["structured", "crisp", "defined"]
        }
        
        // Remove duplicates
        nourishingFabrics = Array(Set(nourishingFabrics))
        depletingFabrics = Array(Set(depletingFabrics))
        groundingTextures = Array(Set(groundingTextures))
        activatingTextures = Array(Set(activatingTextures))
        
        // Format the fabric guide
        var guide = ""
        
        guide += "## Nourishing Fabrics:\n\n"
        guide += nourishingFabrics.joined(separator: ", ") + ".\n\n"
        
        guide += "## Depleting Fabrics:\n\n"
        guide += depletingFabrics.joined(separator: ", ") + ".\n\n"
        
        guide += "## Grounding Textures:\n\n"
        guide += groundingTextures.joined(separator: ", ") + ".\n\n"
        
        guide += "## Activating Textures:\n\n"
        guide += activatingTextures.joined(separator: ", ") + "."
        
        return guide
    }
    
    // MARK: - Style Pulse (90% natal, 10% progressed flavor)
    
    /// Generates style pulse elements (keywords, priorities, journey)
    /// - Tokens weighted: 90% natal, 10% progressed flavor
    static func generateStylePulse(from tokens: [StyleToken]) -> String {
        // Get top 5 keywords by weight
        let styleKeywords = tokens
            .filter { $0.weight >= 2.5 }
            .sorted { $0.weight > $1.weight }
            .prefix(5)
            .map { $0.name }
        
        // Get sensory priorities
        let sensoryTokens = tokens
            .filter { ($0.type == "texture" || $0.type == "mood") && $0.weight >= 2.5 }
            .sorted { $0.weight > $1.weight }
        
        // Determine sensory priorities based on token types
        var sensoryPriority = ""
        if sensoryTokens.contains(where: { $0.type == "texture" }) {
            sensoryPriority = "Texture and feel first; how clothing rests on the body is more important than how it photographs."
        } else if sensoryTokens.contains(where: { $0.name == "visual" || $0.name == "expressive" }) {
            sensoryPriority = "Visual impact first; how clothing appears and communicates is your primary consideration."
        } else if sensoryTokens.contains(where: { $0.name == "comfortable" || $0.name == "practical" }) {
            sensoryPriority = "Comfort and function first; how clothing performs and feels during daily activities guides your choices."
        } else {
            sensoryPriority = "Balance of sensory experiences; you consider both how clothing feels and how it presents visually."
        }
        
        // Determine style journey based on planetary placements
        var styleJourney = ""
        
        // Look for Moon/Venus hard aspects
        let hasMoonVenusHardAspect = tokens.contains {
            $0.aspectSource?.contains("Moon") == true &&
            $0.aspectSource?.contains("Venus") == true &&
            ($0.aspectSource?.contains("square") == true || $0.aspectSource?.contains("opposition") == true)
        }
        
        // Look for North Node in style-related houses
        let hasNorthNodeInStyleHouse = tokens.contains {
            $0.planetarySource == "North Node" &&
            ($0.houseSource == 1 || $0.houseSource == 2 || $0.houseSource == 6)
        }
        
        // Look for strong Pluto or Saturn
        let hasStrongPlutoOrSaturn = tokens.contains {
            ($0.planetarySource == "Pluto" || $0.planetarySource == "Saturn") &&
            $0.weight >= 3.0
        }
        
        if hasMoonVenusHardAspect {
            styleJourney = "From rebellious self-protection to embodied self-expression, "
        } else if hasNorthNodeInStyleHouse {
            styleJourney = "From seeking external validation to authentic self-discovery, "
        } else if hasStrongPlutoOrSaturn {
            styleJourney = "From controlled presentation to empowered self-mastery, "
        } else {
            styleJourney = "From exploration to refinement, "
        }
        
        // Add flavor of progressed chart (10%) - subtle influence from progressed tokens
        let hasProgressedTokens = tokens.contains { $0.planetarySource?.contains("Progressed") == true }
        
        if hasProgressedTokens {
            styleJourney += "you've been evolving toward a more "
            
            // Look for progressed Moon sign influence
            if tokens.contains(where: {
                $0.planetarySource?.contains("Progressed Moon") == true &&
                ($0.signSource == "Aries" || $0.signSource == "Leo" || $0.signSource == "Sagittarius")
            }) {
                styleJourney += "energized and expressive style. "
            } else if tokens.contains(where: {
                $0.planetarySource?.contains("Progressed Moon") == true &&
                ($0.signSource == "Taurus" || $0.signSource == "Virgo" || $0.signSource == "Capricorn")
            }) {
                styleJourney += "grounded and practical style. "
            } else if tokens.contains(where: {
                $0.planetarySource?.contains("Progressed Moon") == true &&
                ($0.signSource == "Gemini" || $0.signSource == "Libra" || $0.signSource == "Aquarius")
            }) {
                styleJourney += "intellectual and communicative style. "
            } else if tokens.contains(where: {
                $0.planetarySource?.contains("Progressed Moon") == true &&
                ($0.signSource == "Cancer" || $0.signSource == "Scorpio" || $0.signSource == "Pisces")
            }) {
                styleJourney += "intuitive and emotionally responsive style. "
            } else {
                styleJourney += "authentic personal style. "
            }
        }
        
        // Complete the journey description
        if tokens.contains(where: { $0.name == "grounded" || $0.name == "earthy" }) {
            styleJourney += "Your evolution has been steady, soulful, and deeply felt."
        } else if tokens.contains(where: { $0.name == "passionate" || $0.name == "dynamic" }) {
            styleJourney += "Your evolution has been energetic, transformative, and boldly expressed."
        } else if tokens.contains(where: { $0.name == "adaptable" || $0.name == "intellectual" }) {
            styleJourney += "Your evolution has been thoughtful, communicative, and always evolving."
        } else if tokens.contains(where: { $0.name == "sensitive" || $0.name == "intuitive" }) {
            styleJourney += "Your evolution has been intuitive, responsive, and emotionally attuned."
        } else {
            styleJourney += "Your evolution has been personal, meaningful, and authentically yours."
        }
        
        // Format the style pulse section
        var pulse = ""
        
        pulse += "## Style Keywords:\n\n"
        pulse += styleKeywords.joined(separator: ", ") + ".\n\n"
        
        pulse += "## Sensory Priorities:\n\n"
        pulse += sensoryPriority + "\n\n"
        
        pulse += "## Style Journey Notes:\n\n"
        pulse += styleJourney
        
        return pulse
    }
    
    // MARK: - Fashion Guidance (100% Natal, Whole Sign)
    
    /// Generates fashion do's and don'ts based on chart elements using Whole Sign
    static func generateFashionGuidance(from tokens: [StyleToken]) -> String {
        // Identify top consistent tokens for "lean into"
        let topTokens = tokens
            .filter { $0.weight > 2.5 }
            .sorted { $0.weight > $1.weight }
            .prefix(6)
        
        var leanIntoItems: [String] = []
        
        // Create phrases from tokens
        for token in topTokens {
            switch token.name {
            case "layered", "structured":
                leanIntoItems.append("layering with intention")
            case "comfortable", "practical":
                leanIntoItems.append("structured comfort")
            case "bold", "expressive":
                leanIntoItems.append("expressive details")
            case "earthy", "grounded":
                leanIntoItems.append("warm neutrals")
            case "slow", "intentional":
                leanIntoItems.append("slow fashion")
            case "textured", "tactile":
                leanIntoItems.append("textured surfaces")
            case "vintage", "nostalgic":
                leanIntoItems.append("reworking pieces")
            case "balanced", "harmonic":
                leanIntoItems.append("balanced proportions")
            default:
                leanIntoItems.append(token.name + " elements")
            }
        }
        
        // Identify conflicting tokens for "release"
        var releaseItems: [String] = []
        
        // Look for opposing qualities
        let hasStructured = tokens.contains { $0.name == "structured" && $0.weight > 2.0 }
        let hasFluid = tokens.contains { $0.name == "fluid" && $0.weight > 2.0 }
        
        let hasMinimal = tokens.contains { $0.name == "minimal" && $0.weight > 2.0 }
        let hasMaximal = tokens.contains { ($0.name == "maximal" || $0.name == "decorative") && $0.weight > 2.0 }
        
        let hasMatte = tokens.contains { ($0.name == "matte" || $0.name == "earthy") && $0.weight > 2.0 }
        let hasShiny = tokens.contains { ($0.name == "shiny" || $0.name == "glossy") && $0.weight > 2.0 }
        
        let hasRevealing = tokens.contains { ($0.name == "revealing" || $0.name == "sensual") && $0.weight > 2.0 }
        let hasModest = tokens.contains { ($0.name == "modest" || $0.name == "protective") && $0.weight > 2.0 }
        
        // Add opposing release items based on token conflicts
        if hasStructured && !hasFluid {
            releaseItems.append("overly fluid silhouettes that lack definition")
        } else if hasFluid && !hasStructured {
            releaseItems.append("stiff silhouettes that ignore your rhythm")
        }
        
        if hasMinimal && !hasMaximal {
            releaseItems.append("overly decorative or busy patterns")
        } else if hasMaximal && !hasMinimal {
            releaseItems.append("excessively minimal pieces that lack character")
        }
        
        if hasMatte && !hasShiny {
            releaseItems.append("anything high-shine or overly polished")
        } else if hasShiny && !hasMatte {
            releaseItems.append("flat, textureless fabrics that lack depth")
        }
        
        if hasModest && !hasRevealing {
            releaseItems.append("overly revealing pieces that create discomfort")
        } else if hasRevealing && !hasModest {
            releaseItems.append("unnecessarily concealing layers that hide your natural form")
        }
        
        // Add general releases based on dominant elements
        if tokens.contains(where: { $0.name == "authentic" && $0.weight > 2.5 }) {
            releaseItems.append("trend-driven looks that don't resonate personally")
        }
        
        if tokens.contains(where: { $0.name == "intentional" && $0.weight > 2.5 }) {
            releaseItems.append("impulse purchases without consideration for longevity")
        }
        
        // Ensure we have at least some release items
        if releaseItems.isEmpty {
            releaseItems = ["overly trend-driven looks", "pieces that don't feel authentic to you", "fast fashion without personal meaning"]
        }
        
        // Identify "watch out for" warnings
        var watchOutForItem = ""
        
        if tokens.contains(where: { ($0.name == "subtle" || $0.name == "quiet") && $0.weight > 2.5 }) {
            watchOutForItem = "Mistaking simplicity for invisibility. You can be subtle and still be seen."
        } else if tokens.contains(where: { ($0.name == "bold" || $0.name == "expressive") && $0.weight > 2.5 }) {
            watchOutForItem = "Confusing loudness with impact. True power can be focused and intentional."
        } else if tokens.contains(where: { ($0.name == "practical" || $0.name == "functional") && $0.weight > 2.5 }) {
            watchOutForItem = "Sacrificing beauty for function. The two can and should coexist."
        } else if tokens.contains(where: { ($0.name == "unique" || $0.name == "creative") && $0.weight > 2.5 }) {
            watchOutForItem = "Pursuing originality at the expense of wearability. Your best pieces will be both unique and practical."
        } else {
            watchOutForItem = "Letting external expectations override your authentic preferences. Your style is most powerful when it's truly yours."
        }
        
        // Format the fashion guidance section
        var guidance = ""
        
        guidance += "## Lean into:\n\n"
        guidance += leanIntoItems.joined(separator: ", ") + ".\n\n"
        
        guidance += "## Release:\n\n"
        guidance += releaseItems.joined(separator: ", ") + ".\n\n"
        
        guidance += "## Watch Out For:\n\n"
        guidance += watchOutForItem
        
        return guidance
    }
    
    // MARK: - Color Recommendations (70% natal, 30% progressed)
    
    /// Generates color recommendations - tokens weighted: 70% natal, 30% progressed
    static func generateColorRecommendations(from tokens: [StyleToken]) -> String {
        // Extract color tokens specifically - prioritize specific color names over general qualities
        let colorTokens = tokens.filter { $0.type == "color" }
        
        // Organize tokens by category based on their sources and names
        var elementalColors: [String] = []
        var currentPhaseColors: [String] = []
        var powerColors: [String] = []
        
        // Extract specific color names from color tokens
        var specificColorNames: [String] = []
        let topColorTokens = colorTokens.sorted { $0.weight > $1.weight }.prefix(8)
        
        for token in topColorTokens {
            // Add specific color names (these are the nuanced colors like "iridescent aqua", "warm terracotta")
            if !["white", "black", "red", "blue", "green", "yellow", "orange", "purple", "brown", "gray"].contains(token.name) {
                specificColorNames.append(token.name)
            }
        }
        
        // If we have specific color names from the nuanced color system, use those
        if !specificColorNames.isEmpty {
            elementalColors.append(contentsOf: Array(Set(specificColorNames)))
        } else {
            // Fallback to token analysis for elemental colors
            if tokens.contains(where: { $0.name == "earthy" }) {
                elementalColors.append(contentsOf: ["olive", "terracotta", "moss", "ochre", "walnut", "sand", "umber"])
            }
            
            if tokens.contains(where: { $0.name == "watery" }) {
                elementalColors.append(contentsOf: ["navy ink", "teal", "indigo", "slate blue", "stormy gray", "deep aqua"])
            }
            
            if tokens.contains(where: { $0.name == "airy" }) {
                elementalColors.append(contentsOf: ["pale blue", "silver gray", "cloud white", "light lavender", "sky"])
            }
            
            if tokens.contains(where: { $0.name == "fiery" }) {
                elementalColors.append(contentsOf: ["oxblood", "rust", "amber", "burnt orange", "burgundy", "ruby"])
            }
        }
        
        // Current phase colors based on progressed planets (30% influence)
        let hasProgressedVenus = tokens.contains { $0.planetarySource?.contains("Progressed Venus") == true }
        let hasProgressedMars = tokens.contains { $0.planetarySource?.contains("Progressed Mars") == true }
        let hasProgressedMoon = tokens.contains { $0.planetarySource?.contains("Progressed Moon") == true }
        
        if hasProgressedVenus {
            currentPhaseColors.append("dusty rose")
        }
        
        if hasProgressedMars {
            currentPhaseColors.append("burnt sienna")
        }
        
        if hasProgressedMoon {
            currentPhaseColors.append("silver gray")
        }
        
        // Look for moon phase tokens to add current phase colors
        let moonPhaseTokens = tokens.filter { $0.aspectSource?.contains("Moon Phase") == true }
        for token in moonPhaseTokens {
            if token.type == "color" {
                currentPhaseColors.append(token.name)
            }
        }
        
        // If no progressed planets and no moon phase colors, add some generic current phase colors
        if currentPhaseColors.isEmpty {
            currentPhaseColors = ["muted sage", "faded black", "soft cream"]
        }
        
        // Generate power colors based on token analysis
        if tokens.contains(where: { $0.name == "bold" && $0.weight > 2.5 }) {
            powerColors.append("deep oxblood")
            powerColors.append("electric blue")
        }
        
        if tokens.contains(where: { $0.name == "grounded" && $0.weight > 2.5 }) {
            powerColors.append("forest green")
            powerColors.append("charcoal")
        }
        
        if tokens.contains(where: { $0.name == "magnetic" && $0.weight > 2.5 }) {
            powerColors.append("royal purple")
            powerColors.append("midnight blue")
        }
        
        if tokens.contains(where: { $0.name == "transformative" && $0.weight > 2.5 }) {
            powerColors.append("deep burgundy")
            powerColors.append("metallic bronze")
        }
        
        // Check for specific power color tokens from the color system
        let powerColorTokens = colorTokens.filter {
            $0.name.contains("royal") || $0.name.contains("deep") || $0.name.contains("electric") ||
            $0.name.contains("rich") || $0.name.contains("intense") || $0.name.contains("bold")
        }
        for token in powerColorTokens.prefix(3) {
            powerColors.append(token.name)
        }
        
        // Default options if no strong preferences
        if elementalColors.isEmpty {
            elementalColors = ["stone", "navy", "charcoal", "cream"]
        }
        
        if powerColors.isEmpty {
            powerColors = ["deep indigo", "matte silver", "burgundy"]
        }
        
        // Remove duplicates and limit selections
        elementalColors = Array(Set(elementalColors))
        currentPhaseColors = Array(Set(currentPhaseColors))
        powerColors = Array(Set(powerColors))
        
        // Limit to reasonable numbers
        elementalColors = Array(elementalColors.prefix(5))
        currentPhaseColors = Array(currentPhaseColors.prefix(4))
        powerColors = Array(powerColors.prefix(3))
        
        // Format color recommendations
        var colors = ""
        
        colors += "## Elemental Colours:\n\n"
        colors += elementalColors.joined(separator: ", ") + ".\n\n"
        
        colors += "## Current Phase Colours:\n\n"
        colors += currentPhaseColors.joined(separator: ", ") + ".\n\n"
        
        colors += "## Power Colours:\n\n"
        colors += powerColors.joined(separator: ", ") + "."
        
        return colors
    }
    
    // MARK: - Wardrobe Storyline (60% progressed with Placidus, 40% natal)
    
    /// Generates wardrobe storyline - tokens weighted: 60% progressed with Placidus, 40% natal
    static func generateWardrobeStoryline(from tokens: [StyleToken]) -> String {
        // Determine past arc
        var pastArc = ""
        
        // Look for Moon/Venus hard aspects or dominant Scorpio/Capricorn
        let hasMoonVenusHardAspect = tokens.contains {
            $0.aspectSource?.contains("Moon") == true &&
            $0.aspectSource?.contains("Venus") == true &&
            ($0.aspectSource?.contains("square") == true || $0.aspectSource?.contains("opposition") == true)
        }
        
        let hasStrongFixedSigns = tokens.contains {
            ($0.signSource == "Taurus" || $0.signSource == "Leo" ||
             $0.signSource == "Scorpio" || $0.signSource == "Aquarius") &&
            $0.weight > 2.5
        }
        
        let has8thOr12thHouse = tokens.contains { $0.houseSource == 8 || $0.houseSource == 12 }
        
        if hasMoonVenusHardAspect || has8thOr12thHouse {
            pastArc = "Style as armor—layers that protected and defined your identity. "
            
            if hasStrongFixedSigns {
                pastArc += "Edgy, expressive, unafraid to resist the mainstream."
            } else {
                pastArc += "Distinctive, personal, with elements that kept others at a distance when needed."
            }
        } else if hasStrongFixedSigns {
            pastArc = "Style as definition—consistent elements that established your visual identity. "
            pastArc += "Reliable, recognizable, with signature pieces that became your calling card."
        } else {
            pastArc = "Style as exploration—trying different approaches to discover what resonates. "
            pastArc += "Varied, experimental, with phases that reflected your evolving sense of self."
        }
        
        // Determine present phase - emphasize progressed planets (60% influence)
        var presentPhase = ""
        
        // Look for progressed planets using Placidus house system
        let hasProgressedMoon = tokens.contains { $0.planetarySource?.contains("Progressed Moon") == true }
        let hasProgressedVenus = tokens.contains { $0.planetarySource?.contains("Progressed Venus") == true }
        
        if hasProgressedMoon && hasProgressedVenus {
            presentPhase = "Emotionally attuned and aesthetically refined. Your current phase integrates emotional awareness with visual harmony. "
            presentPhase += "You're drawn to pieces that reflect your inner state while maintaining a cohesive visual language."
        } else if hasProgressedMoon {
            presentPhase = "Emotionally responsive and intuitive. Your current phase prioritizes how clothing feels on multiple levels. "
            presentPhase += "You're drawn to pieces that support your emotional well-being and inner sense of security."
        } else if hasProgressedVenus {
            presentPhase = "Aesthetically evolved and relationally aware. Your current phase emphasizes visual harmony and social connection. "
            presentPhase += "You're drawn to pieces that communicate your values while creating meaningful impression."
        } else {
            // Fall back to natal chart influences (40%)
            let hasEarthVenusOrMoon = tokens.contains {
                ($0.planetarySource == "Venus" || $0.planetarySource == "Moon") &&
                ($0.signSource == "Taurus" || $0.signSource == "Virgo" || $0.signSource == "Capricorn")
            }
            
            let hasBalancedTokens = tokens.contains { $0.name == "balanced" || $0.name == "harmonious" }
            let hasIntentionalTokens = tokens.contains { $0.name == "intentional" || $0.name == "refined" }
            
            if hasEarthVenusOrMoon {
                presentPhase = "Streamlined and intentional. You know what suits your energy, and you choose with care. "
                presentPhase += "Fewer pieces, stronger presence."
            } else if hasBalancedTokens {
                presentPhase = "Harmonious and integrated. You've found balance between different aspects of your style. "
                presentPhase += "Versatile, adaptable, with pieces that work together in multiple ways."
            } else if hasIntentionalTokens {
                presentPhase = "Refined and purposeful. Your choices reflect deeper considerations about quality and impact. "
                presentPhase += "Thoughtful curation, meaningful selection."
            } else {
                presentPhase = "Authentic and present. Your style reflects who you are now, not who you were or should be. "
                presentPhase += "Honest, current, responsive to your actual life."
            }
        }
        
        // Determine emerging chapter - emphasize progressive trends using Placidus house system
        var emergingChapter = ""
        
        // Prioritize progressed Ascendant/MC from Placidus system (part of the 60% progressed influence)
        let hasProgressedAscendant = tokens.contains { $0.planetarySource?.contains("Progressed Ascendant") == true }
        let hasProgressedMC = tokens.contains { $0.planetarySource?.contains("Progressed MC") == true }
        
        if hasProgressedAscendant || hasProgressedMC {
            emergingChapter = "Evolution of self-expression and public identity. "
            
            if hasProgressedAscendant && hasProgressedMC {
                emergingChapter += "As your ascendant and midheaven progress, you're entering a phase where both personal and public expression are shifting. "
            } else if hasProgressedAscendant {
                emergingChapter += "As your ascendant progresses, you're entering a phase of renewed self-definition and personal presence. "
            } else {
                emergingChapter += "As your midheaven evolves, you're entering a phase of reconnection with your public role and visible impact. "
            }
            
            emergingChapter += "This chapter invites conscious integration of evolving identity with enduring essence."
        } else {
            // Fall back to transformative themes or general evolution
            let hasTransformativeTokens = tokens.contains { $0.name == "transformative" || $0.name == "evolutionary" }
            
            if hasTransformativeTokens {
                emergingChapter = "Reclamation and refinement. You're honoring the past versions of yourself "
                emergingChapter += "through custom, quality, and a slow, soulful approach to style."
            } else if tokens.contains(where: { $0.name == "innovative" || $0.name == "unique" }) {
                emergingChapter = "Innovation and personalization. You're moving toward more custom, unique expressions "
                emergingChapter += "that integrate technical advances with personal meaning."
            } else if tokens.contains(where: { $0.name == "authentic" || $0.name == "honest" }) {
                emergingChapter = "Authenticity and integrity. You're evolving toward choices that align deeply with your values, "
                emergingChapter += "prioritizing ethical production and personal resonance."
            } else {
                emergingChapter = "Integration and evolution. You're bringing together the most resonant elements of past phases "
                emergingChapter += "while staying open to new approaches that honor your current self."
            }
        }
        
        // Format wardrobe storyline
        var storyline = ""
        
        storyline += "## Past Arc:\n\n"
        storyline += pastArc + "\n\n"
        
        storyline += "## Present Phase:\n\n"
        storyline += presentPhase + "\n\n"
        
        storyline += "## Emerging Chapter:\n\n"
        storyline += emergingChapter
        
        return storyline
    }
}
