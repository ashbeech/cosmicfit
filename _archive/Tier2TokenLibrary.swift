//
//  Tier2TokenLibrary.swift
//  Cosmic Fit
//
//  ⚠️ NOT CURRENTLY USED ⚠️
//
//  ARCHITECTURAL DECISION (Dec 2025):
//  This file contains a comprehensive Tier 2 token system that was designed for
//  dynamic generation of fashion copy from astrological data. However, the app
//  now uses PRE-WRITTEN TEMPLATES for both Style Guide and Daily Fit content.
//
//  KEPT FOR REFERENCE:
//  - Contains 130+ fashion descriptor tokens
//  - Full traceability system (Tier 2 → Tier 1 → Natal chart)
//  - Comprehensive developer documentation
//  - May be useful if architecture changes in future
//
//  CURRENT APPROACH:
//  - Style Guide: Pre-written paragraphs selected via Tier 1 pattern matching
//  - Daily Fit: Static paragraphs attached to Tarot cards (78 × 3 = 234 paragraphs)
//  - Both use Tier 1 tokens only (no Tier 2 generation needed)
//
//  To re-enable: Uncomment generation call in SemanticTokenGenerator.swift
//

import Foundation

// MARK: - DEVELOPER DOCUMENTATION

/*
 
 ═══════════════════════════════════════════════════════════════════════════════
 TIER 2 TOKEN SYSTEM - COMPREHENSIVE GUIDE
 ═══════════════════════════════════════════════════════════════════════════════
 
 OVERVIEW:
 ─────────
 The Tier 2 system bridges the gap between astrological energy (Tier 1) and
 actionable fashion guidance (Tier 2). It enables specific, shoppable recommendations
 while maintaining full traceability back to the natal chart.
 
 
 TWO-TIER ARCHITECTURE:
 ──────────────────────
 
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                         NATAL CHART                                     │
 │                              ↓                                          │
 │  TIER 1: ENERGETIC FOUNDATION (200-300 tokens)                         │
 │  → "What's your VIBE?"                                                  │
 │  → Examples: fluid, bold, tactile, intuitive, structured               │
 │  → Generated from: Planets, signs, houses, aspects                     │
 │                              ↓                                          │
 │  TIER 2: APPLIED STYLE (50-100 tokens)                                 │
 │  → "What should you WEAR?"                                             │
 │  → Examples: bias_cut, matte_finish, column_shape, v_neck             │
 │  → Generated from: Matching Tier 1 energy patterns                     │
 │                              ↓                                          │
 │              ┌───────────────┴──────────────┐                          │
 │              ↓                               ↓                          │
 │      STYLE GUIDE (Static)          DAILY FIT (Dynamic)                 │
 │   • Full natal expression          • Transit-filtered subset           │
 │   • All Tier 2 tokens              • Effort-level filtered             │
 │   • Comprehensive guidance         • Today's specific advice           │
 └─────────────────────────────────────────────────────────────────────────┘
 
 
 USAGE FOR STYLE GUIDE:
 ──────────────────────
 The Style Guide uses Tier 2 tokens to populate 4 main sections:
 
 1. STYLE CORE
    Purpose: Define user's foundational style identity
    Uses token types:
    - formality (elevated_casual, polished_minimal, etc.)
    - aesthetic_complexity (monochromatic_dressing, eclectic_mixing, etc.)
    - garment_preference (dress_preference, separates_preference, etc.)
    - styling_approach (uniform_dressing, investment_pieces, etc.)
    - body_relationship (body_confident, modest_coverage, etc.)
    
    Example query:
    ```
    let formalityTokens = allTokens.filter { $0.type == "formality" && $0.isTier2 }
    let topFormality = formalityTokens.max { $0.weight < $1.weight }
    // → User's natural formality level: "elevated_casual" (weight: 3.8)
    
    Display: "Your style naturally gravitates toward elevated casual pieces
             that balance polish with comfort."
    ```
 
 2. FABRIC GUIDE
    Purpose: Recommend specific fabrics and textures
    Uses token types:
    - fabric_behavior (holds_own_shape, behaves_like_water, etc.)
    - fabric_weight (substantial_weight, heavy, dense, etc.)
    - fabric_type (silk_preference, linen_preference, etc.)
    - tactile_quality (smooth_hand, cooling_sensation, etc.)
    - surface_finish (matte_finish, pearlescent, etc.)
    
    Example query:
    ```
    let fabricTokens = allTokens.filter {
        ["fabric_behavior", "fabric_type", "tactile_quality"].contains($0.type) && $0.isTier2
    }.sorted { $0.weight > $1.weight }
    
    let prioritize = fabricTokens.prefix(3)  // Top 3
    let explore = fabricTokens.dropFirst(3).prefix(3)  // Next 3
    
    Display:
    "PRIORITIZE: Silk, cashmere, linen
     EXPLORE: Modal, cotton knits, soft denim"
    ```
 
 3. COLOUR GUIDE
    Purpose: Organize color palette into functional categories
    Uses token types:
    - color (from Tier 1, already comprehensive)
    - color_application (color_as_statement, color_as_accent, etc.)
    
    Example query:
    ```
    let colorTokens = allTokens.filter { $0.type == "colour" && $0.isTier1 }
    let applicationTokens = allTokens.filter { $0.type == "color_application" && $0.isTier2 }
    
    // Organize by application type
    if applicationTokens.contains(where: { $0.name == "color_as_foundation" && $0.weight > 3.0 }) {
        let baseColors = colorTokens.filter { isNeutral($0.name) }
        // Display as "Base Palette"
    }
    ```
 
 4. DO'S & DON'TS
    Purpose: Specific actionable recommendations and anti-recommendations
    Uses token types:
    - silhouette (structured_silhouette, draped_silhouette, etc.)
    - garment_specific (wide_leg_pants, fitted_not_tight, etc.)
    - neckline (scoop_neck, v_neck, etc.)
    - sleeve (bell_sleeve, statement_sleeve, etc.)
    - proportion (oversized, fitted, dramatic_proportions, etc.)
    - coverage (modest_coverage, balanced_coverage, etc.)
    
    Example query:
    ```
    let doTokens = allTokens.filter { $0.weight > 3.5 && $0.isTier2 }
    let dontTokens = allTokens.filter {
        guard let opposite = $0.oppositeOf else { return false }
        return $0.isTier2
    }
    
    Display:
    "DO'S:
     • Draped silhouettes (4.5)
     • V-neck styles (3.8)
     • Flowing fabrics (4.2)
     
     DON'TS:
     • Structured silhouettes (opposite of draped)
     • Rigid fabrics (opposite of flows)"
    ```
 
 
 USAGE FOR DAILY FIT:
 ────────────────────
 The Daily Fit uses the SAME Tier 2 tokens but filters/weights them differently:
 
 FILTERING APPROACH:
 ```
 // 1. Generate base Tier 2 from natal chart (same as Style Guide)
 let baseTier2 = Tier2TokenLibrary.generateTier2Tokens(from: tier1NatalTokens)
 
 // 2. Score each Tier 2 token against today's transits
 let todayTier2 = baseTier2.map { tier2Token in
     // Check if today's Tier 1 transits align with this Tier 2's source energies
     let transitAlignment = calculateTransitAlignment(tier2Token, todayTransits)
     return tier2Token.withWeight(tier2Token.weight * transitAlignment)
 }
 
 // 3. Filter by effort level (based on day's complexity)
 let effortLevel = calculateDayEffortLevel(transits, weather, moonPhase)
 let filteredTier2 = todayTier2.filter { token in
     guard let tokenEffort = token.effortLevel else { return true }
     return tokenEffort == effortLevel
 }
 
 // 4. Select top tokens for today's copy
 let topSilhouettes = filteredTier2.filter { $0.type == "silhouette" }.prefix(2)
 let topFabrics = filteredTier2.filter { $0.type == "fabric_behavior" }.prefix(3)
 ```
 
 EFFORT LEVEL USAGE (High Priestess pattern):
 ```
 // Low Effort Day (simple transits, calm weather):
 effortFilter: .low
 → oversized_silhouette, jersey, enveloping_knit, high_neckline
 
 // Medium Effort Day (moderate transits):
 effortFilter: .medium
 → body_skimming, refuses_friction, translucent_over_opaque
 
 // High Effort Day (powerful transits, special occasion):
 effortFilter: .high
 → floor_grazing, intimidatingly_calm, singular_substantial_accessory
 ```
 
 COPY GENERATION EXAMPLE:
 ```
 // For Knight of Pentacles energy:
 let silhouette = topTokens.first { $0.type == "silhouette" }
 // → "structured_silhouette"
 
 let surface = topTokens.first { $0.type == "surface_finish" }
 // → "matte_finish"
 
 let behavior = topTokens.first { $0.type == "fabric_behavior" }
 // → "holds_own_shape"
 
 let copy = """
 Put the flimsy layers on pause; they're just distractions. 
 Your aesthetic intuition is pulling you toward the substantial. 
 Think \(surface.name.readableForm()) that absorb light and weaves that 
 \(behavior.name.readableForm()). Trust your hands to find pieces that 
 have grit and gravity.
 """
 ```
 
 
 TOKEN CATEGORIES REFERENCE:
 ───────────────────────────
 
 PHYSICAL FORM (how clothes shape the body):
 • silhouette - Overall shape (structured, draped, oversized, etc.)
 • proportion - Size relationships (fitted, oversized, dramatic, etc.)
 • fit - Body-to-garment relationship (doesn't_cling, open_and_airy, etc.)
 • line_quality - Visual lines (crisp_outlines, long_continuous_line, etc.)
 
 MATERIAL PROPERTIES (fabric characteristics):
 • fabric_behavior - How fabric moves (holds_shape, cascades, ripples, etc.)
 • fabric_weight - Heaviness/density (substantial, heavy, visual_weight, etc.)
 • fabric_type - Specific materials (silk, linen, cotton, etc.)
 • surface_finish - Light interaction (matte, pearlescent, opaque, etc.)
 • tactile_quality - Touch experience (smooth_hand, cooling, grit, etc.)
 
 GARMENT SPECIFICS (actual clothing items):
 • garment_type - Specific items (jersey, column_skirt, technical_fabrics, etc.)
 • garment_preference - Wardrobe building approach (dress vs separates, etc.)
 • garment_specific - Particular styles (wide_leg_pants, maxi_dress, etc.)
 • neckline - Neck openings (scoop, v-neck, cowl, etc.)
 • sleeve - Arm coverage (sleeveless, bell_sleeve, statement_sleeve, etc.)
 • length - Garment length (ankle_length, floor_grazing, midi, etc.)
 
 PATTERN & VISUAL (print and visual effects):
 • pattern_type - Print style (rhythmic, gradient, geometric, organic, etc.)
 • pattern_scale - Print size (micro_print, macro_print, statement_print)
 • pattern_density - Print coverage (dense_pattern, sparse_pattern)
 • visual_effect - Overall impression (luminosity, visual_silence, etc.)
 
 STYLING PHILOSOPHY (how to approach dressing):
 • formality - Dress-up level (elevated_casual, polished_minimal, etc.)
 • aesthetic_complexity - Visual complexity (monochromatic, maximalist, etc.)
 • styling_approach - Wardrobe philosophy (uniform, intuitive, planned, etc.)
 • color_application - Color usage (statement, accent, foundation, etc.)
 
 LIFESTYLE & CONTEXT (real-world application):
 • context - Life situations (work_casual, social_visibility, etc.)
 • body_relationship - Body-mind connection (confident, modest, comfort, etc.)
 • coverage - Skin exposure comfort (modest, balanced, revealing, etc.)
 • layering_approach - Layer strategy (minimal, translucent_over_opaque, etc.)
 
 CONSTRUCTION (technical garment details):
 • engineering - Build approach (engineered_not_draped, aerodynamic, etc.)
 • garment_detail - Specific features (hood, accessories, etc.)
 
 
 EXTENSIBILITY:
 ──────────────
 To add new Tier 2 tokens in the future:
 
 1. Analyze new copy for specific fashion descriptors
 2. Identify which Tier 1 energies would generate that descriptor
 3. Add to allTokens array:
 
    Tier2TokenDefinition(
        name: "your_descriptor",
        type: "appropriate_category",
        sourceEnergy: ["tier1_token1", "tier1_token2"],
        oppositeOf: "opposite_token_if_exists",
        effortLevel: .medium,  // if applicable
        tags: ["searchable", "metadata", "keywords"]
    )
 
 4. Tokens auto-generate next time generateStyleGuideTokens() is called
 
 
 QUERYING PATTERNS:
 ──────────────────
 
 // Get all tokens of a specific type
 let silhouettes = Tier2TokenLibrary.filterByType(tokens, type: "silhouette")
 
 // Get tokens with specific tag
 let protectiveItems = Tier2TokenLibrary.filterByTag(tokens, tag: "protective")
 
 // Get top weighted Tier 2 tokens
 let topRecommendations = Tier2TokenLibrary.topTokens(tokens, count: 10)
 
 // Get tokens by effort level
 let lowEffortOptions = tokens.filter { $0.effortLevel == .low && $0.isTier2 }
 
 // Find push-pull tensions
 let tensions = tokens.filter { token in
     guard let opposite = token.oppositeOf else { return false }
     return tokens.contains { $0.name == opposite && $0.weight > 2.5 }
 }
 
 
 TRACEABILITY:
 ─────────────
 Every Tier 2 token maintains full lineage:
 
 Tier 2 Token: bias_cut (weight: 4.2)
   ↓ sourceEnergyTokens: ["fluid", "soft"]
   ↓ Tier 1: fluid (weight: 4.5)
   ↓   ↓ planetarySource: Venus
   ↓   ↓ signSource: Pisces
   ↓   ↓ originType: .natal
   ↓
 User can see: "Bias cut recommended because of Venus in Pisces"
 
 ═══════════════════════════════════════════════════════════════════════════════
 
 */

/// Library of Tier 2 applied style tokens
/// These tokens represent specific, actionable style recommendations
/// derived from foundational energetic tokens (Tier 1)
struct Tier2TokenLibrary {
    
    // MARK: - Token Definitions
    
    /// Complete library of all Tier 2 tokens
    /// Each token includes:
    /// - name: Unique identifier
    /// - type: Category (silhouette, fabric_behavior, surface_finish, etc.)
    /// - sourceEnergy: Which Tier 1 tokens generate this
    /// - oppositeOf: For push-pull tension detection
    /// - effortLevel: For style variation systems (e.g., High Priestess)
    /// - tags: Additional searchable metadata
    static let allTokens: [Tier2TokenDefinition] = [
        
        // MARK: - SILHOUETTE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Define overall garment shape and structure
        // USAGE:
        //   Style Guide → "Do's & Don'ts" section (top 3-5 weighted)
        //   Daily Fit → Primary silhouette recommendation for the day
        // DISPLAY EXAMPLE:
        //   "DO: Draped silhouettes that move with you"
        //   "DON'T: Rigid, structured shapes that feel confining"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "structured_silhouette",
            type: "silhouette",
            sourceEnergy: ["structured", "grounded", "solid"],
            tags: ["rigid", "defined", "architectural"]
        ),
        
        Tier2TokenDefinition(
            name: "architectural_silhouette",
            type: "silhouette",
            sourceEnergy: ["structured", "bold", "solid"],
            tags: ["engineered", "geometric", "support"]
        ),
        
        Tier2TokenDefinition(
            name: "defined_shapes",
            type: "silhouette",
            sourceEnergy: ["structured", "practical", "solid"],
            tags: ["crisp", "deliberate", "not_asking_questions"]
        ),
        
        Tier2TokenDefinition(
            name: "column_shape",
            type: "silhouette",
            sourceEnergy: ["fluid", "minimal", "elongating"],
            tags: ["vertical", "continuous", "streamlined"]
        ),
        
        Tier2TokenDefinition(
            name: "bias_cut",
            type: "silhouette",
            sourceEnergy: ["fluid", "graceful", "adaptive"],
            tags: ["diagonal", "draping", "body_following"]
        ),
        
        Tier2TokenDefinition(
            name: "draped_silhouette",
            type: "silhouette",
            sourceEnergy: ["fluid", "soft", "flowing"],
            tags: ["cascading", "rippling", "water_like"]
        ),
        
        Tier2TokenDefinition(
            name: "streamlined_shape",
            type: "silhouette",
            sourceEnergy: ["minimal", "modern", "fluid"],
            tags: ["aerodynamic", "sleek", "futuristic"]
        ),
        
        Tier2TokenDefinition(
            name: "oversized_silhouette",
            type: "silhouette",
            sourceEnergy: ["contained", "protective", "comfortable"],
            effortLevel: .low,
            tags: ["swallowing", "enveloping", "buffer_zone"]
        ),
        
        Tier2TokenDefinition(
            name: "body_skimming",
            type: "silhouette",
            sourceEnergy: ["mysterious", "subtle", "reserved"],
            effortLevel: .medium,
            tags: ["hints_not_reveals", "close_but_not_tight", "suggestive"]
        ),
        
        Tier2TokenDefinition(
            name: "enveloping_shape",
            type: "silhouette",
            sourceEnergy: ["protective", "introspective", "contained"],
            effortLevel: .low,
            tags: ["cocoon", "fortress", "refuge"]
        ),
        
        // MARK: - FABRIC BEHAVIOR TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Describe how fabric moves and interacts with the body
        // USAGE:
        //   Style Guide → "Fabric Guide" section (descriptive copy)
        //   Daily Fit → Fabric characteristic for today's outfit
        // DISPLAY EXAMPLE:
        //   "Seek fabrics that cascade and pool at the ankles"
        //   "Avoid materials that hold their own shape rigidly"
        // COPY INTEGRATION:
        //   "Think matte finishes that absorb light and weaves that hold their own shape"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "holds_own_shape",
            type: "fabric_behavior",
            sourceEnergy: ["structured", "solid", "grounded"],
            oppositeOf: "flutters",
            tags: ["independent", "self_supporting", "shape_retention"]
        ),
        
        Tier2TokenDefinition(
            name: "stands_away_from_body",
            type: "fabric_behavior",
            sourceEnergy: ["structured", "architectural"],
            oppositeOf: "clings",
            tags: ["space_creating", "distinct", "separate"]
        ),
        
        Tier2TokenDefinition(
            name: "offers_resistance",
            type: "fabric_behavior",
            sourceEnergy: ["solid", "grounded", "substantial"],
            tags: ["pushback", "tension", "active"]
        ),
        
        Tier2TokenDefinition(
            name: "anchors",
            type: "fabric_behavior",
            sourceEnergy: ["grounded", "solid", "heavy"],
            oppositeOf: "flutters",
            tags: ["weighted", "grounding", "stabilizing"]
        ),
        
        Tier2TokenDefinition(
            name: "behaves_like_water",
            type: "fabric_behavior",
            sourceEnergy: ["fluid", "adaptable", "flowing"],
            tags: ["liquid", "continuous_movement", "responsive"]
        ),
        
        Tier2TokenDefinition(
            name: "ripples_with_movement",
            type: "fabric_behavior",
            sourceEnergy: ["fluid", "dynamic", "graceful"],
            tags: ["waves", "undulating", "kinetic"]
        ),
        
        Tier2TokenDefinition(
            name: "cascades",
            type: "fabric_behavior",
            sourceEnergy: ["fluid", "flowing", "vertical"],
            tags: ["falling", "waterfall", "downward_flow"]
        ),
        
        Tier2TokenDefinition(
            name: "pools_at_ankles",
            type: "fabric_behavior",
            sourceEnergy: ["fluid", "abundant", "dramatic"],
            tags: ["gathering", "puddling", "floor_touching"]
        ),
        
        Tier2TokenDefinition(
            name: "flows_with_fluidity",
            type: "fabric_behavior",
            sourceEnergy: ["fluid", "modern", "continuous"],
            tags: ["uninterrupted", "seamless", "effortless"]
        ),
        
        Tier2TokenDefinition(
            name: "refuses_friction",
            type: "fabric_behavior",
            sourceEnergy: ["smooth", "cool", "contained"],
            effortLevel: .medium,
            tags: ["slippery", "gliding", "low_resistance"]
        ),
        
        Tier2TokenDefinition(
            name: "skims_body",
            type: "fabric_behavior",
            sourceEnergy: ["mysterious", "subtle", "revealing"],
            effortLevel: .medium,
            tags: ["hints", "follows_loosely", "suggests"]
        ),
        
        Tier2TokenDefinition(
            name: "absorbs_light",
            type: "fabric_behavior",
            sourceEnergy: ["mysterious", "dense", "matte"],
            effortLevel: .high,
            tags: ["non_reflective", "receding", "shadowy"]
        ),
        
        Tier2TokenDefinition(
            name: "creates_gliding_effect",
            type: "fabric_behavior",
            sourceEnergy: ["mysterious", "fluid", "long"],
            effortLevel: .high,
            tags: ["obscures_footwork", "floating", "hovering"]
        ),
        
        // MARK: - SURFACE FINISH TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How fabric surface interacts with light
        // USAGE:
        //   Style Guide → "Fabric Guide" for texture recommendations
        //   Daily Fit → Surface quality for today's aesthetic
        // DISPLAY EXAMPLE:
        //   "Materials with a pearlescent quality or subtle sheen"
        //   "Matte finishes that absorb rather than reflect light"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "matte_finish",
            type: "surface_finish",
            sourceEnergy: ["structured", "grounded", "serious"],
            oppositeOf: "shiny",
            tags: ["light_absorbing", "non_reflective", "flat"]
        ),
        
        Tier2TokenDefinition(
            name: "opaque",
            type: "surface_finish",
            sourceEnergy: ["solid", "structured", "concealing"],
            oppositeOf: "transparent",
            tags: ["non_see_through", "dense", "solid"]
        ),
        
        Tier2TokenDefinition(
            name: "pearlescent",
            type: "surface_finish",
            sourceEnergy: ["luminous", "ethereal", "light"],
            tags: ["iridescent", "soft_glow", "subtle_shimmer"]
        ),
        
        Tier2TokenDefinition(
            name: "subtle_sheen",
            type: "surface_finish",
            sourceEnergy: ["luminous", "refined", "elegant"],
            tags: ["gentle_shine", "low_gloss", "hint_of_light"]
        ),
        
        Tier2TokenDefinition(
            name: "satin_finish",
            type: "surface_finish",
            sourceEnergy: ["luminous", "smooth", "luxurious"],
            tags: ["silky", "lustrous", "light_catching"]
        ),
        
        Tier2TokenDefinition(
            name: "metallic",
            type: "surface_finish",
            sourceEnergy: ["bold", "modern", "reflective"],
            tags: ["high_shine", "industrial", "futuristic"]
        ),
        
        Tier2TokenDefinition(
            name: "polished",
            type: "surface_finish",
            sourceEnergy: ["refined", "smooth", "luxurious"],
            tags: ["buffed", "gleaming", "perfected"]
        ),
        
        Tier2TokenDefinition(
            name: "light_absorbing",
            type: "surface_finish",
            sourceEnergy: ["mysterious", "dense", "receding"],
            effortLevel: .high,
            tags: ["matte", "deep", "non_reflective"]
        ),
        
        Tier2TokenDefinition(
            name: "translucent",
            type: "surface_finish",
            sourceEnergy: ["mysterious", "layered", "veiled"],
            effortLevel: .medium,
            tags: ["semi_sheer", "filtering_light", "obscuring"]
        ),
        
        // MARK: - FABRIC WEIGHT TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Physical heaviness and density of materials
        // USAGE:
        //   Style Guide → "Fabric Guide" for material substance
        //   Daily Fit → Weather and energy-appropriate weight
        // DISPLAY EXAMPLE:
        //   "Substantial weights that feel like a shield"
        //   "Lightweight, airy materials for ease of movement"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "substantial_weight",
            type: "fabric_weight",
            sourceEnergy: ["grounded", "solid", "heavy"],
            tags: ["dense", "thick", "hefty"]
        ),
        
        Tier2TokenDefinition(
            name: "heavy",
            type: "fabric_weight",
            sourceEnergy: ["grounded", "solid", "anchoring"],
            oppositeOf: "lightweight",
            tags: ["weighted", "substantial", "gravity"]
        ),
        
        Tier2TokenDefinition(
            name: "dense",
            type: "fabric_weight",
            sourceEnergy: ["solid", "structured", "compact"],
            tags: ["tight_weave", "substantial", "solid"]
        ),
        
        Tier2TokenDefinition(
            name: "apocalypse_proof",
            type: "fabric_weight",
            sourceEnergy: ["durable", "solid", "lasting"],
            tags: ["indestructible", "heavy_duty", "armor_like"]
        ),
        
        Tier2TokenDefinition(
            name: "visual_weight",
            type: "fabric_weight",
            sourceEnergy: ["substantial", "dense", "presence"],
            effortLevel: .high,
            tags: ["heavy_looking", "presence_adding", "gravitational"]
        ),
        
        // MARK: - TACTILE QUALITY TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How fabric feels against skin
        // USAGE:
        //   Style Guide → "Fabric Guide" for sensory preferences
        //   Daily Fit → Comfort and sensory alignment for today
        // DISPLAY EXAMPLE:
        //   "Smooth hand feel with a cooling sensation"
        //   "Satisfying textures that offer grit and gravity"
        // NOTE: Moon placements heavily influence these tokens
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "grit_and_gravity",
            type: "tactile_quality",
            sourceEnergy: ["grounded", "textured", "substantial"],
            tags: ["rough_refined", "tactile", "presence"]
        ),
        
        Tier2TokenDefinition(
            name: "satisfying_texture",
            type: "tactile_quality",
            sourceEnergy: ["tactile", "grounded", "quality"],
            tags: ["pleasant_weight", "rewarding", "tangible"]
        ),
        
        Tier2TokenDefinition(
            name: "smooth_hand",
            type: "tactile_quality",
            sourceEnergy: ["smooth", "refined", "luxurious"],
            tags: ["silky", "pleasant_touch", "refined"]
        ),
        
        Tier2TokenDefinition(
            name: "cooling_sensation",
            type: "tactile_quality",
            sourceEnergy: ["airy", "fresh", "refreshing"],
            tags: ["temperature_lowering", "crisp", "reviving"]
        ),
        
        Tier2TokenDefinition(
            name: "cool_hand_feel",
            type: "tactile_quality",
            sourceEnergy: ["composed", "smooth", "calm"],
            effortLevel: .medium,
            tags: ["temperature", "soothing", "crisp"]
        ),
        
        Tier2TokenDefinition(
            name: "soft_jersey",
            type: "tactile_quality",
            sourceEnergy: ["comfortable", "soft", "casual"],
            effortLevel: .low,
            tags: ["knit", "stretchy", "cozy"]
        ),
        
        // MARK: - LINE QUALITY TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Visual lines and edges created by garment construction
        // USAGE:
        //   Style Guide → "Style Core" for aesthetic approach
        //   Daily Fit → Line quality for today's visual impact
        // DISPLAY EXAMPLE:
        //   "Crisp outlines that cut through the noise"
        //   "Long, continuous lines that elongate the frame"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "crisp_outlines",
            type: "line_quality",
            sourceEnergy: ["structured", "defined", "sharp"],
            tags: ["cut_glass", "precise", "exact"]
        ),
        
        Tier2TokenDefinition(
            name: "clean_outline",
            type: "line_quality",
            sourceEnergy: ["minimal", "structured", "clear"],
            tags: ["uncluttered", "engineered", "definite"]
        ),
        
        Tier2TokenDefinition(
            name: "defined_edges",
            type: "line_quality",
            sourceEnergy: ["structured", "architectural", "clear"],
            tags: ["sharp", "distinct", "unmistakable"]
        ),
        
        Tier2TokenDefinition(
            name: "long_continuous_line",
            type: "line_quality",
            sourceEnergy: ["fluid", "vertical", "elongating"],
            tags: ["unbroken", "seamless", "stretching"]
        ),
        
        Tier2TokenDefinition(
            name: "uncomplicated_lines",
            type: "line_quality",
            sourceEnergy: ["minimal", "simple", "clean"],
            tags: ["straightforward", "uncluttered", "direct"]
        ),
        
        Tier2TokenDefinition(
            name: "vertical_draw",
            type: "line_quality",
            sourceEnergy: ["elongating", "uplifting", "streamlined"],
            tags: ["upward", "lengthening", "eye_guiding"]
        ),
        
        Tier2TokenDefinition(
            name: "blurred_edges",
            type: "line_quality",
            sourceEnergy: ["soft", "ethereal", "transitional"],
            tags: ["gradient", "undefined", "dissolving"]
        ),
        
        // MARK: - PROPORTION/LENGTH TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Garment length and proportional relationships
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for length preferences
        //   Daily Fit → Specific length recommendation for today
        // DISPLAY EXAMPLE:
        //   "Floor-grazing lengths that create a gliding effect"
        //   "Ankle-length pieces that pool elegantly"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "elongating_frame",
            type: "proportion",
            sourceEnergy: ["vertical", "lengthening", "statuesque"],
            tags: ["height_adding", "stretching", "extending"]
        ),
        
        Tier2TokenDefinition(
            name: "ankle_length",
            type: "length",
            sourceEnergy: ["fluid", "modest", "coverage"],
            tags: ["pooling_point", "midi_to_maxi", "grazing"]
        ),
        
        Tier2TokenDefinition(
            name: "floor_grazing",
            type: "length",
            sourceEnergy: ["dramatic", "mysterious", "coverage"],
            effortLevel: .high,
            tags: ["maximum_length", "sweeping", "touching_ground"]
        ),
        
        Tier2TokenDefinition(
            name: "obscures_footwork",
            type: "length",
            sourceEnergy: ["mysterious", "gliding", "concealing"],
            effortLevel: .high,
            tags: ["hides_feet", "creates_hover", "floor_length"]
        ),
        
        // MARK: - FIT TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Relationship between garment and body (tight vs loose)
        // USAGE:
        //   Style Guide → "Style Core" for comfort preferences
        //   Daily Fit → Today's body-comfort alignment
        // DISPLAY EXAMPLE:
        //   "Fits that don't cling but still suggest shape"
        //   "Open, airy silhouettes with breathing room"
        // NOTE: Strongly influenced by Moon (comfort) and Mars (body confidence)
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "doesnt_cling",
            type: "fit",
            sourceEnergy: ["structured", "independent", "space_creating"],
            oppositeOf: "body_hugging",
            tags: ["separation", "breathing_room", "non_adhesive"]
        ),
        
        Tier2TokenDefinition(
            name: "open_and_airy",
            type: "fit",
            sourceEnergy: ["breathable", "spacious", "free"],
            tags: ["room_to_breathe", "non_restrictive", "expansive"]
        ),
        
        Tier2TokenDefinition(
            name: "buffer_zone_creating",
            type: "fit",
            sourceEnergy: ["protective", "oversized", "space_making"],
            effortLevel: .low,
            tags: ["personal_space", "distance", "barrier"]
        ),
        
        // MARK: - PATTERN TYPE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Print and pattern style preferences
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for pattern guidance
        //   Daily Fit → Pattern recommendation based on today's energy
        // DISPLAY EXAMPLE:
        //   "Rhythmic, grounded patterns rather than loud abstracts"
        //   "Gradient washes that blur edges softly"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "rhythmic_pattern",
            type: "pattern_type",
            sourceEnergy: ["grounded", "structured", "consistent"],
            oppositeOf: "abstract",
            tags: ["repetitive", "geometric", "predictable"]
        ),
        
        Tier2TokenDefinition(
            name: "grounded_pattern",
            type: "pattern_type",
            sourceEnergy: ["earthy", "solid", "stable"],
            oppositeOf: "loud",
            tags: ["understated", "anchored", "calm"]
        ),
        
        Tier2TokenDefinition(
            name: "gradient_pattern",
            type: "pattern_type",
            sourceEnergy: ["fluid", "transitional", "ethereal"],
            tags: ["ombre", "fading", "blending"]
        ),
        
        Tier2TokenDefinition(
            name: "soft_wash",
            type: "pattern_type",
            sourceEnergy: ["soft", "subtle", "watercolor"],
            tags: ["diluted", "muted", "gentle"]
        ),
        
        // MARK: - VISUAL EFFECT TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Overall visual impression and psychological impact
        // USAGE:
        //   Style Guide → "Style Essence" for vibe description
        //   Daily Fit → Today's aesthetic goal/metaphor
        // DISPLAY EXAMPLE:
        //   "The aesthetic equivalent of drinking eight glasses of water"
        //   "Dress like you're the only adult in the room"
        // NOTE: These often work as copy metaphors and conceptual anchors
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "visual_silence",
            type: "visual_effect",
            sourceEnergy: ["minimal", "calm", "muted"],
            tags: ["quiet", "undemanding", "peaceful"]
        ),
        
        Tier2TokenDefinition(
            name: "structural_integrity",
            type: "visual_effect",
            sourceEnergy: ["structured", "solid", "dependable"],
            tags: ["reliable_looking", "stable", "engineered"]
        ),
        
        Tier2TokenDefinition(
            name: "implies_life_together",
            type: "visual_effect",
            sourceEnergy: ["organized", "competent", "polished"],
            tags: ["controlled", "managed", "adult"]
        ),
        
        Tier2TokenDefinition(
            name: "luminosity",
            type: "visual_effect",
            sourceEnergy: ["radiant", "glowing", "light_filled"],
            tags: ["brightness", "illumination", "glow"]
        ),
        
        Tier2TokenDefinition(
            name: "catches_light",
            type: "visual_effect",
            sourceEnergy: ["reflective", "dynamic", "shimmering"],
            tags: ["light_play", "sparkle", "gleam"]
        ),
        
        Tier2TokenDefinition(
            name: "diffuses_light",
            type: "visual_effect",
            sourceEnergy: ["soft", "ethereal", "glowing"],
            tags: ["scatters", "softens", "halos"]
        ),
        
        Tier2TokenDefinition(
            name: "elongates_frame",
            type: "visual_effect",
            sourceEnergy: ["vertical", "lengthening", "flattering"],
            tags: ["height_creating", "stretching", "slimming"]
        ),
        
        Tier2TokenDefinition(
            name: "creates_visual_riddle",
            type: "visual_effect",
            sourceEnergy: ["mysterious", "layered", "complex"],
            effortLevel: .medium,
            tags: ["puzzling", "intriguing", "ambiguous"]
        ),
        
        Tier2TokenDefinition(
            name: "adds_visual_weight",
            type: "visual_effect",
            sourceEnergy: ["substantial", "presence", "grounding"],
            effortLevel: .high,
            tags: ["imposing", "heavy_looking", "substantial"]
        ),
        
        // MARK: - GARMENT TYPE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Specific garment categories and items
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for wardrobe building
        //   Daily Fit → Specific item recommendations
        // DISPLAY EXAMPLE:
        //   "Column skirts that create a sleek vertical line"
        //   "Technical fabrics with modern functionality"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "monochromatic_separates",
            type: "garment_type",
            sourceEnergy: ["minimal", "cohesive", "elongating"],
            tags: ["tonal", "matched_set", "continuous"]
        ),
        
        Tier2TokenDefinition(
            name: "technical_fabrics",
            type: "garment_type",
            sourceEnergy: ["modern", "functional", "innovative"],
            tags: ["performance", "engineered", "futuristic"]
        ),
        
        Tier2TokenDefinition(
            name: "sheer_overlays",
            type: "garment_type",
            sourceEnergy: ["layered", "ethereal", "transparent"],
            tags: ["veiling", "translucent", "filtering"]
        ),
        
        Tier2TokenDefinition(
            name: "jersey",
            type: "garment_type",
            sourceEnergy: ["comfortable", "soft", "stretchy"],
            effortLevel: .low,
            tags: ["knit", "forgiving", "easy"]
        ),
        
        Tier2TokenDefinition(
            name: "enveloping_knit",
            type: "garment_type",
            sourceEnergy: ["cozy", "protective", "soft"],
            effortLevel: .low,
            tags: ["wrap_like", "cocoon", "warm"]
        ),
        
        Tier2TokenDefinition(
            name: "column_skirt",
            type: "garment_type",
            sourceEnergy: ["sleek", "vertical", "minimal"],
            effortLevel: .high,
            tags: ["straight", "narrow", "elongating"]
        ),
        
        // MARK: - GARMENT DETAIL TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Specific garment features and accessories
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for detail preferences
        //   Daily Fit → Feature recommendations (e.g., "utilize a hood")
        // DISPLAY EXAMPLE:
        //   "Accessories singular and substantial, like a talisman"
        //   "High necklines that signal unavailability"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "high_neckline",
            type: "neckline",
            sourceEnergy: ["contained", "modest", "protective"],
            effortLevel: .low,
            tags: ["covered", "closed", "sealed"]
        ),
        
        Tier2TokenDefinition(
            name: "hood",
            type: "garment_detail",
            sourceEnergy: ["protective", "concealing", "private"],
            effortLevel: .low,
            tags: ["hiding", "coverage", "unavailable"]
        ),
        
        Tier2TokenDefinition(
            name: "singular_substantial_accessory",
            type: "garment_detail",
            sourceEnergy: ["statement", "minimal", "powerful"],
            effortLevel: .high,
            tags: ["talisman", "focal_point", "one_piece"]
        ),
        
        // MARK: - LAYERING APPROACH TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How to combine multiple garment pieces
        // USAGE:
        //   Style Guide → "Style Core" for layering philosophy
        //   Daily Fit → Layering strategy for today
        // DISPLAY EXAMPLE:
        //   "Minimal layering to let the fabric speak for itself"
        //   "Layer translucent over opaque to create visual riddles"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "minimal_layering",
            type: "layering_approach",
            sourceEnergy: ["minimal", "clean", "uncluttered"],
            tags: ["simple", "few_pieces", "streamlined"]
        ),
        
        Tier2TokenDefinition(
            name: "translucent_over_opaque",
            type: "layering_approach",
            sourceEnergy: ["mysterious", "veiled", "complex"],
            effortLevel: .medium,
            tags: ["sheer_over_solid", "revealing_concealing", "dual_layer"]
        ),
        
        // MARK: - ENGINEERING/CONSTRUCTION TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How garments are technically constructed
        // USAGE:
        //   Style Guide → "Fabric Guide" for construction preferences
        //   Daily Fit → Construction approach for today's energy
        // DISPLAY EXAMPLE:
        //   "A clean outline that feels engineered rather than draped"
        //   "Architectural support through internal structure"
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "engineered_not_draped",
            type: "engineering",
            sourceEnergy: ["structured", "architectural", "calculated"],
            oppositeOf: "organic",
            tags: ["designed", "constructed", "planned"]
        ),
        
        Tier2TokenDefinition(
            name: "architectural_support",
            type: "engineering",
            sourceEnergy: ["structured", "supportive", "foundational"],
            tags: ["internal_structure", "boning", "framework"]
        ),
        
        Tier2TokenDefinition(
            name: "aerodynamic",
            type: "engineering",
            sourceEnergy: ["streamlined", "modern", "sleek"],
            tags: ["wind_resistant", "smooth", "efficient"]
        ),
        
        // MARK: - METAPHOR/CONCEPT TOKENS (for copy generation)
        
        Tier2TokenDefinition(
            name: "shield_against_world",
            type: "visual_effect",
            sourceEnergy: ["protective", "defensive", "solid"],
            tags: ["armor", "barrier", "defense"]
        ),
        
        Tier2TokenDefinition(
            name: "adult_in_room",
            type: "visual_effect",
            sourceEnergy: ["mature", "serious", "responsible"],
            tags: ["competent", "authoritative", "grown"]
        ),
        
        Tier2TokenDefinition(
            name: "restored_from_within",
            type: "visual_effect",
            sourceEnergy: ["luminous", "healthy", "renewed"],
            tags: ["rejuvenated", "rested", "glowing"]
        ),
        
        Tier2TokenDefinition(
            name: "living_in_better_timeline",
            type: "visual_effect",
            sourceEnergy: ["futuristic", "optimistic", "forward"],
            tags: ["upgraded", "evolved", "next_level"]
        ),
        
        Tier2TokenDefinition(
            name: "fabric_fortress",
            type: "visual_effect",
            sourceEnergy: ["protective", "enclosed", "safe"],
            effortLevel: .low,
            tags: ["refuge", "sanctuary", "shield"]
        ),
        
        Tier2TokenDefinition(
            name: "well_kept_secret",
            type: "visual_effect",
            sourceEnergy: ["mysterious", "private", "knowing"],
            effortLevel: .medium,
            tags: ["enigmatic", "withholding", "intriguing"]
        ),
        
        Tier2TokenDefinition(
            name: "intimidatingly_calm",
            type: "visual_effect",
            sourceEnergy: ["composed", "still", "powerful"],
            effortLevel: .high,
            tags: ["unshakeable", "statuesque", "commanding"]
        ),
        
        // MARK: - FORMALITY SPECTRUM TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Natural formality level and occasion appropriateness
        // USAGE:
        //   Style Guide → "Style Core" to define baseline formality
        //   Daily Fit → Adjust formality based on day's energy
        // DISPLAY EXAMPLE:
        //   "Your style gravitates toward elevated casual pieces"
        //   "Lived-in luxury that feels both refined and relaxed"
        // QUERY PATTERN:
        //   ```
        //   let formalityLevel = tokens
        //       .filter { $0.type == "formality" && $0.isTier2 }
        //       .max { $0.weight < $1.weight }
        //   // Use this to set Style Guide baseline formality description
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "elevated_casual",
            type: "formality",
            sourceEnergy: ["refined", "comfortable", "polished"],
            tags: ["smart_casual", "dressed_up_casual", "polished_ease"]
        ),
        
        Tier2TokenDefinition(
            name: "relaxed_elegance",
            type: "formality",
            sourceEnergy: ["elegant", "comfortable", "effortless"],
            tags: ["ease", "unstudied", "natural_polish"]
        ),
        
        Tier2TokenDefinition(
            name: "polished_minimal",
            type: "formality",
            sourceEnergy: ["minimal", "refined", "intentional"],
            tags: ["clean", "precise", "considered"]
        ),
        
        Tier2TokenDefinition(
            name: "lived_in_luxe",
            type: "formality",
            sourceEnergy: ["comfortable", "luxurious", "relaxed"],
            tags: ["worn_in", "broken_in", "casual_luxury"]
        ),
        
        Tier2TokenDefinition(
            name: "perpetually_polished",
            type: "formality",
            sourceEnergy: ["refined", "organized", "precise"],
            tags: ["always_ready", "put_together", "crisp"]
        ),
        
        Tier2TokenDefinition(
            name: "undone_elegance",
            type: "formality",
            sourceEnergy: ["elegant", "relaxed", "effortless"],
            tags: ["slightly_disheveled", "artfully_casual", "ease"]
        ),
        
        Tier2TokenDefinition(
            name: "occasion_adaptable",
            type: "formality",
            sourceEnergy: ["versatile", "balanced", "adaptable"],
            tags: ["dress_up_or_down", "flexible", "context_aware"]
        ),
        
        // MARK: - AESTHETIC COMPLEXITY TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How visually complex outfits should be
        // USAGE:
        //   Style Guide → "Style Core" for wardrobe approach philosophy
        //   Daily Fit → Today's complexity level (minimal vs maximalist)
        // DISPLAY EXAMPLE:
        //   "Monochromatic separates that create visual continuity"
        //   "Eclectic mixing of patterns and textures for depth"
        // QUERY PATTERN:
        //   ```
        //   let complexity = tokens.filter { $0.type == "aesthetic_complexity" }
        //   if complexity.contains(where: { $0.name == "maximalist" && $0.weight > 3.0 }) {
        //       // User thrives with visual abundance
        //   } else if complexity.contains(where: { $0.name == "curated_minimal" }) {
        //       // User prefers edited simplicity
        //   }
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "monochromatic_dressing",
            type: "aesthetic_complexity",
            sourceEnergy: ["minimal", "cohesive", "singular"],
            tags: ["one_color", "tonal", "unified", "head_to_toe"]
        ),
        
        Tier2TokenDefinition(
            name: "tonal_variations",
            type: "aesthetic_complexity",
            sourceEnergy: ["subtle", "refined", "nuanced"],
            tags: ["shade_play", "depth", "sophisticated"]
        ),
        
        Tier2TokenDefinition(
            name: "eclectic_mixing",
            type: "aesthetic_complexity",
            sourceEnergy: ["expressive", "creative", "bold"],
            oppositeOf: "monochromatic_dressing",
            tags: ["pattern_mixing", "unexpected", "varied"]
        ),
        
        Tier2TokenDefinition(
            name: "maximalist",
            type: "aesthetic_complexity",
            sourceEnergy: ["abundant", "expressive", "bold"],
            oppositeOf: "curated_minimal",
            tags: ["more_is_more", "layered", "rich", "abundance"]
        ),
        
        Tier2TokenDefinition(
            name: "curated_minimal",
            type: "aesthetic_complexity",
            sourceEnergy: ["minimal", "intentional", "refined"],
            oppositeOf: "maximalist",
            tags: ["less_is_more", "edited", "precise", "restrained"]
        ),
        
        Tier2TokenDefinition(
            name: "textural_layering",
            type: "aesthetic_complexity",
            sourceEnergy: ["layered", "tactile", "complex"],
            tags: ["dimension", "depth", "sensory"]
        ),
        
        Tier2TokenDefinition(
            name: "color_story_focused",
            type: "aesthetic_complexity",
            sourceEnergy: ["colorful", "expressive", "bold"],
            tags: ["palette_driven", "chromatic", "vibrant"]
        ),
        
        Tier2TokenDefinition(
            name: "neutral_foundation",
            type: "aesthetic_complexity",
            sourceEnergy: ["grounded", "classic", "versatile"],
            tags: ["base_palette", "earthy", "timeless"]
        ),
        
        // MARK: - PROPORTION & SCALE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Size relationships and volume placement
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for fit preferences
        //   Daily Fit → Proportion recommendation for today
        // DISPLAY EXAMPLE:
        //   "Oversized silhouettes that swallow the figure comfortably"
        //   "Fitted proportions that define without restricting"
        // PUSH-PULL DETECTION:
        //   If both "oversized" and "fitted" have high weights → style tension
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "oversized",
            type: "proportion",
            sourceEnergy: ["comfortable", "relaxed", "modern"],
            oppositeOf: "fitted",
            tags: ["baggy", "roomy", "generous"]
        ),
        
        Tier2TokenDefinition(
            name: "fitted",
            type: "proportion",
            sourceEnergy: ["defined", "sleek", "confident"],
            oppositeOf: "oversized",
            tags: ["tailored", "close_to_body", "shaped"]
        ),
        
        Tier2TokenDefinition(
            name: "tailored",
            type: "proportion",
            sourceEnergy: ["refined", "structured", "polished"],
            tags: ["custom_fit", "precise", "shaped"]
        ),
        
        Tier2TokenDefinition(
            name: "dramatic_proportions",
            type: "proportion",
            sourceEnergy: ["bold", "theatrical", "expressive"],
            tags: ["exaggerated", "statement", "extreme"]
        ),
        
        Tier2TokenDefinition(
            name: "understated_proportions",
            type: "proportion",
            sourceEnergy: ["subtle", "balanced", "classic"],
            oppositeOf: "dramatic_proportions",
            tags: ["normal", "unremarkable", "quiet"]
        ),
        
        Tier2TokenDefinition(
            name: "volume_at_top",
            type: "proportion",
            sourceEnergy: ["bold", "expressive", "structured"],
            tags: ["statement_sleeves", "shoulder_focus", "upper_emphasis"]
        ),
        
        Tier2TokenDefinition(
            name: "volume_at_bottom",
            type: "proportion",
            sourceEnergy: ["fluid", "dramatic", "feminine"],
            tags: ["full_skirts", "wide_legs", "lower_emphasis"]
        ),
        
        Tier2TokenDefinition(
            name: "balanced_proportions",
            type: "proportion",
            sourceEnergy: ["balanced", "harmonious", "classic"],
            tags: ["even", "symmetrical", "proportionate"]
        ),
        
        Tier2TokenDefinition(
            name: "boxy",
            type: "proportion",
            sourceEnergy: ["structured", "modern", "minimal"],
            tags: ["square", "geometric", "straight"]
        ),
        
        Tier2TokenDefinition(
            name: "gathered_volume",
            type: "proportion",
            sourceEnergy: ["romantic", "feminine", "textural"],
            tags: ["ruched", "shirred", "bunched"]
        ),
        
        // MARK: - PATTERN SCALE & DENSITY TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Print size, type, and visual density
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for pattern preferences
        //   Daily Fit → Pattern recommendation aligned with day's energy
        // DISPLAY EXAMPLE:
        //   "Micro prints for subtle visual interest"
        //   "Macro, statement prints that command attention"
        // QUERY PATTERN:
        //   ```
        //   let patternScale = tokens.filter { $0.type == "pattern_scale" }
        //   let patternType = tokens.filter { $0.type == "pattern_type" }
        //   // Combine: "geometric" + "macro" = "large geometric prints"
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "micro_print",
            type: "pattern_scale",
            sourceEnergy: ["subtle", "refined", "minimal"],
            tags: ["tiny", "ditsy", "delicate"]
        ),
        
        Tier2TokenDefinition(
            name: "macro_print",
            type: "pattern_scale",
            sourceEnergy: ["bold", "dramatic", "expressive"],
            oppositeOf: "micro_print",
            tags: ["large_scale", "oversized", "statement"]
        ),
        
        Tier2TokenDefinition(
            name: "statement_print",
            type: "pattern_scale",
            sourceEnergy: ["bold", "expressive", "confident"],
            tags: ["focal_point", "eye_catching", "dominant"]
        ),
        
        Tier2TokenDefinition(
            name: "dense_pattern",
            type: "pattern_density",
            sourceEnergy: ["complex", "rich", "abundant"],
            oppositeOf: "sparse_pattern",
            tags: ["busy", "filled", "intricate"]
        ),
        
        Tier2TokenDefinition(
            name: "sparse_pattern",
            type: "pattern_density",
            sourceEnergy: ["minimal", "clean", "spacious"],
            oppositeOf: "dense_pattern",
            tags: ["open", "breathing_room", "scattered"]
        ),
        
        Tier2TokenDefinition(
            name: "geometric_pattern",
            type: "pattern_type",
            sourceEnergy: ["structured", "modern", "precise"],
            tags: ["angular", "mathematical", "ordered"]
        ),
        
        Tier2TokenDefinition(
            name: "organic_pattern",
            type: "pattern_type",
            sourceEnergy: ["natural", "fluid", "soft"],
            oppositeOf: "geometric_pattern",
            tags: ["floral", "flowing", "nature_inspired"]
        ),
        
        Tier2TokenDefinition(
            name: "abstract_pattern",
            type: "pattern_type",
            sourceEnergy: ["creative", "expressive", "unconventional"],
            tags: ["artistic", "non_representational", "interpretive"]
        ),
        
        // MARK: - GARMENT PREFERENCE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: High-level wardrobe building approach
        // USAGE:
        //   Style Guide → "Style Core" for wardrobe strategy
        //   NOT used in Daily Fit (too strategic for daily use)
        // DISPLAY EXAMPLE:
        //   "You naturally gravitate toward dresses for effortless dressing"
        //   "Separates allow you the mix-and-match flexibility you crave"
        // QUERY PATTERN:
        //   ```
        //   let isPrimarlyDresses = tokens.contains {
        //       $0.name == "dress_preference" && $0.weight > 3.5
        //   }
        //   if isPrimarlyDresses {
        //       // Recommend building wardrobe around dresses
        //   }
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "dress_preference",
            type: "garment_preference",
            sourceEnergy: ["fluid", "feminine", "easy"],
            oppositeOf: "separates_preference",
            tags: ["one_piece", "effortless", "instant_outfit"]
        ),
        
        Tier2TokenDefinition(
            name: "separates_preference",
            type: "garment_preference",
            sourceEnergy: ["versatile", "practical", "mix_match"],
            oppositeOf: "dress_preference",
            tags: ["modular", "flexible", "combinable"]
        ),
        
        Tier2TokenDefinition(
            name: "jumpsuit_inclination",
            type: "garment_preference",
            sourceEnergy: ["modern", "streamlined", "easy"],
            tags: ["one_piece", "contemporary", "structured_ease"]
        ),
        
        Tier2TokenDefinition(
            name: "suiting_affinity",
            type: "garment_preference",
            sourceEnergy: ["structured", "polished", "powerful"],
            tags: ["coordinated_sets", "matching", "formal"]
        ),
        
        // MARK: - SPECIFIC GARMENT TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Concrete, shoppable garment recommendations
        // USAGE:
        //   Style Guide → "Do's & Don'ts" with specific examples
        //   Daily Fit → Today's specific garment suggestion
        // DISPLAY EXAMPLE:
        //   "Wide-leg pants for flowing, modern ease"
        //   "Fitted (not tight) pieces that define your shape"
        // SHOPPING INTEGRATION:
        //   These tokens are specific enough to guide actual purchases
        //   Can be used for future shopping recommendation features
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "wide_leg_pants",
            type: "garment_specific",
            sourceEnergy: ["fluid", "relaxed", "modern"],
            tags: ["palazzo", "flowing_pants", "statement_bottom"]
        ),
        
        Tier2TokenDefinition(
            name: "fitted_not_tight",
            type: "garment_specific",
            sourceEnergy: ["defined", "comfortable", "flattering"],
            tags: ["tailored", "body_following", "shape_showing"]
        ),
        
        Tier2TokenDefinition(
            name: "straight_leg_pants",
            type: "garment_specific",
            sourceEnergy: ["classic", "balanced", "timeless"],
            tags: ["neutral_silhouette", "versatile", "unfussy"]
        ),
        
        Tier2TokenDefinition(
            name: "maxi_dress",
            type: "garment_specific",
            sourceEnergy: ["fluid", "feminine", "dramatic"],
            tags: ["floor_length", "flowing", "statement"]
        ),
        
        Tier2TokenDefinition(
            name: "midi_length",
            type: "garment_specific",
            sourceEnergy: ["elegant", "balanced", "modest"],
            tags: ["calf_length", "flattering", "versatile"]
        ),
        
        Tier2TokenDefinition(
            name: "mini_length",
            type: "garment_specific",
            sourceEnergy: ["bold", "confident", "playful"],
            tags: ["short", "leg_showing", "youthful"]
        ),
        
        Tier2TokenDefinition(
            name: "blazer_structured",
            type: "garment_specific",
            sourceEnergy: ["structured", "polished", "professional"],
            tags: ["tailored_jacket", "formal", "sharp"]
        ),
        
        Tier2TokenDefinition(
            name: "cardigan_soft",
            type: "garment_specific",
            sourceEnergy: ["soft", "comfortable", "cozy"],
            tags: ["knit_layer", "gentle", "wrap"]
        ),
        
        Tier2TokenDefinition(
            name: "shirt_crisp",
            type: "garment_specific",
            sourceEnergy: ["crisp", "clean", "polished"],
            tags: ["button_down", "fresh", "classic"]
        ),
        
        Tier2TokenDefinition(
            name: "oversized_outerwear",
            type: "garment_specific",
            sourceEnergy: ["comfortable", "modern", "protective"],
            tags: ["coat", "relaxed", "enveloping"]
        ),
        
        // MARK: - NECKLINE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Neck opening styles and shapes
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for neckline guidance
        //   Daily Fit → Specific neckline for today
        // DISPLAY EXAMPLE:
        //   "V-necks that elongate and open the neckline"
        //   "High necklines or hoods for privacy and protection"
        // COMBINATION PATTERNS:
        //   Neckline + Silhouette + Fabric = Complete garment picture
        //   Example: "v_neck" + "draped_silhouette" + "silk" = flowing v-neck dress
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "scoop_neck",
            type: "neckline",
            sourceEnergy: ["soft", "feminine", "gentle"],
            tags: ["curved", "flattering", "classic"]
        ),
        
        Tier2TokenDefinition(
            name: "v_neck",
            type: "neckline",
            sourceEnergy: ["elongating", "flattering", "vertical"],
            tags: ["lengthening", "angular", "opening"]
        ),
        
        Tier2TokenDefinition(
            name: "boat_neck",
            type: "neckline",
            sourceEnergy: ["elegant", "balanced", "horizontal"],
            tags: ["widening", "classic", "refined"]
        ),
        
        Tier2TokenDefinition(
            name: "cowl_neck",
            type: "neckline",
            sourceEnergy: ["soft", "draped", "luxurious"],
            tags: ["draping", "fluid", "elegant"]
        ),
        
        Tier2TokenDefinition(
            name: "square_neck",
            type: "neckline",
            sourceEnergy: ["structured", "modern", "bold"],
            tags: ["geometric", "angular", "statement"]
        ),
        
        Tier2TokenDefinition(
            name: "halter_neck",
            type: "neckline",
            sourceEnergy: ["bold", "confident", "athletic"],
            tags: ["shoulder_baring", "supportive", "sporty_elegant"]
        ),
        
        Tier2TokenDefinition(
            name: "turtleneck",
            type: "neckline",
            sourceEnergy: ["covered", "sleek", "modern"],
            tags: ["high_coverage", "streamlined", "sophisticated"]
        ),
        
        Tier2TokenDefinition(
            name: "crew_neck",
            type: "neckline",
            sourceEnergy: ["classic", "casual", "balanced"],
            tags: ["round", "standard", "versatile"]
        ),
        
        Tier2TokenDefinition(
            name: "off_shoulder",
            type: "neckline",
            sourceEnergy: ["romantic", "feminine", "bold"],
            tags: ["shoulder_baring", "dramatic", "sensual"]
        ),
        
        Tier2TokenDefinition(
            name: "asymmetric_neckline",
            type: "neckline",
            sourceEnergy: ["modern", "edgy", "unconventional"],
            tags: ["one_shoulder", "uneven", "interesting"]
        ),
        
        // MARK: - SLEEVE LENGTH & STYLE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Arm coverage and sleeve styling
        // USAGE:
        //   Style Guide → "Do's & Don'ts" for sleeve preferences
        //   Daily Fit → Sleeve detail for today
        // DISPLAY EXAMPLE:
        //   "Statement sleeves for dramatic upper body focus"
        //   "Three-quarter sleeves for elegant practicality"
        // SEASONAL NOTE:
        //   Can be weighted by weather for Daily Fit
        //   Style Guide shows full range regardless of season
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "sleeveless",
            type: "sleeve",
            sourceEnergy: ["bold", "confident", "warm_weather"],
            tags: ["bare_arms", "athletic", "minimal"]
        ),
        
        Tier2TokenDefinition(
            name: "cap_sleeve",
            type: "sleeve",
            sourceEnergy: ["feminine", "subtle", "modest"],
            tags: ["short", "delicate", "gentle_coverage"]
        ),
        
        Tier2TokenDefinition(
            name: "short_sleeve",
            type: "sleeve",
            sourceEnergy: ["casual", "practical", "balanced"],
            tags: ["above_elbow", "standard", "versatile"]
        ),
        
        Tier2TokenDefinition(
            name: "three_quarter_sleeve",
            type: "sleeve",
            sourceEnergy: ["elegant", "practical", "flattering"],
            tags: ["midi_sleeve", "versatile", "refined"]
        ),
        
        Tier2TokenDefinition(
            name: "long_sleeve",
            type: "sleeve",
            sourceEnergy: ["covered", "elegant", "classic"],
            tags: ["full_coverage", "formal", "traditional"]
        ),
        
        Tier2TokenDefinition(
            name: "bell_sleeve",
            type: "sleeve",
            sourceEnergy: ["romantic", "dramatic", "feminine"],
            tags: ["flared", "flowing", "statement"]
        ),
        
        Tier2TokenDefinition(
            name: "puff_sleeve",
            type: "sleeve",
            sourceEnergy: ["romantic", "playful", "feminine"],
            tags: ["volume", "gathered", "statement"]
        ),
        
        Tier2TokenDefinition(
            name: "statement_sleeve",
            type: "sleeve",
            sourceEnergy: ["bold", "dramatic", "expressive"],
            tags: ["focal_point", "oversized", "architectural"]
        ),
        
        // MARK: - BODY RELATIONSHIP TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How user relates to their body through clothing
        // USAGE:
        //   Style Guide → "Style Core" for understanding comfort zones
        //   Daily Fit → Today's body-comfort alignment
        // DISPLAY EXAMPLE:
        //   "You dress with body confidence, celebrating your form"
        //   "Comfort-prioritizing fits that honor movement needs"
        // SENSITIVE CATEGORY:
        //   These tokens should be presented with care and body-positive framing
        //   Focus on empowerment and authentic comfort, not judgment
        // MOON INFLUENCE:
        //   Strongly tied to Moon placement (emotional comfort)
        //   Mars also influences (body confidence/boldness)
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "body_confident",
            type: "body_relationship",
            sourceEnergy: ["confident", "bold", "comfortable"],
            tags: ["shape_celebrating", "form_showing", "ease"]
        ),
        
        Tier2TokenDefinition(
            name: "body_conscious",
            type: "body_relationship",
            sourceEnergy: ["contained", "modest", "careful"],
            tags: ["aware", "selective", "strategic"]
        ),
        
        Tier2TokenDefinition(
            name: "modest_coverage",
            type: "coverage",
            sourceEnergy: ["contained", "protected", "comfortable"],
            tags: ["covered", "conservative", "private"]
        ),
        
        Tier2TokenDefinition(
            name: "balanced_coverage",
            type: "coverage",
            sourceEnergy: ["balanced", "comfortable", "confident"],
            tags: ["moderate", "versatile", "adaptable"]
        ),
        
        Tier2TokenDefinition(
            name: "revealing_strategic",
            type: "coverage",
            sourceEnergy: ["confident", "bold", "selective"],
            tags: ["intentional_exposure", "chosen_focus", "calculated"]
        ),
        
        Tier2TokenDefinition(
            name: "movement_freedom",
            type: "body_relationship",
            sourceEnergy: ["comfortable", "active", "unrestricted"],
            tags: ["flexible", "athletic", "unencumbered", "range_of_motion"]
        ),
        
        Tier2TokenDefinition(
            name: "comfort_prioritizing",
            type: "body_relationship",
            sourceEnergy: ["comfortable", "practical", "sensory"],
            tags: ["ease_first", "feel_over_look", "wearability"]
        ),
        
        Tier2TokenDefinition(
            name: "body_neutral",
            type: "body_relationship",
            sourceEnergy: ["balanced", "versatile", "adaptable"],
            tags: ["neither_tight_nor_loose", "middle_ground", "flexible"]
        ),
        
        Tier2TokenDefinition(
            name: "sensory_sensitive",
            type: "body_relationship",
            sourceEnergy: ["tactile", "sensitive", "particular"],
            tags: ["texture_aware", "feeling_focused", "discerning"]
        ),
        
        // MARK: - CONTEXT/LIFESTYLE TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How style adapts to life situations and contexts
        // USAGE:
        //   Style Guide → "Style Core" for lifestyle understanding
        //   Daily Fit → Less relevant (focused on today, not life patterns)
        // DISPLAY EXAMPLE:
        //   "Your work style favors creative expression over corporate polish"
        //   "You dress consistently, preferring a signature look over mood variations"
        // QUERY PATTERN:
        //   ```
        //   let workStyle = tokens.filter {
        //       $0.type == "context" && $0.tags?.contains("workplace") == true
        //   }
        //   let socialStyle = tokens.filter {
        //       $0.name.contains("social_visibility")
        //   }
        //   // Combine to understand professional vs social styling differences
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "work_casual",
            type: "context",
            sourceEnergy: ["professional", "comfortable", "practical"],
            tags: ["office_appropriate", "business_casual", "workplace"]
        ),
        
        Tier2TokenDefinition(
            name: "work_elevated",
            type: "context",
            sourceEnergy: ["professional", "polished", "authoritative"],
            tags: ["formal_workplace", "executive", "power_dressing"]
        ),
        
        Tier2TokenDefinition(
            name: "work_creative",
            type: "context",
            sourceEnergy: ["creative", "expressive", "individual"],
            tags: ["artistic_workplace", "personality_showing", "flexible"]
        ),
        
        Tier2TokenDefinition(
            name: "social_visibility_comfortable",
            type: "context",
            sourceEnergy: ["confident", "expressive", "bold"],
            tags: ["attention_comfortable", "seen", "presence"]
        ),
        
        Tier2TokenDefinition(
            name: "social_visibility_reserved",
            type: "context",
            sourceEnergy: ["reserved", "contained", "subtle"],
            oppositeOf: "social_visibility_comfortable",
            tags: ["blend_in", "understated", "low_key"]
        ),
        
        Tier2TokenDefinition(
            name: "style_consistency",
            type: "context",
            sourceEnergy: ["consistent", "reliable", "stable"],
            oppositeOf: "mood_dressing",
            tags: ["uniform", "signature_look", "predictable"]
        ),
        
        Tier2TokenDefinition(
            name: "mood_dressing",
            type: "context",
            sourceEnergy: ["expressive", "adaptable", "emotional"],
            oppositeOf: "style_consistency",
            tags: ["feeling_responsive", "variable", "intuitive"]
        ),
        
        Tier2TokenDefinition(
            name: "multipurpose_wardrobe",
            type: "context",
            sourceEnergy: ["versatile", "practical", "efficient"],
            tags: ["day_to_night", "adaptable", "transitional"]
        ),
        
        Tier2TokenDefinition(
            name: "occasion_specific",
            type: "context",
            sourceEnergy: ["intentional", "prepared", "organized"],
            tags: ["purpose_built", "designated", "context_aware"]
        ),
        
        // MARK: - ADDITIONAL FABRIC SPECIFICS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Specific fabric material recommendations
        // USAGE:
        //   Style Guide → "Fabric Guide" for shopping guidance
        //   Daily Fit → Material recommendation for today
        // DISPLAY EXAMPLE:
        //   "Silk for luxurious fluidity and refined drape"
        //   "Linen for relaxed, natural texture with lived-in ease"
        // SHOPPING VALUE:
        //   These are directly shoppable - users can search for these materials
        //   More actionable than "soft" or "fluid" (Tier 1)
        // VENUS INFLUENCE:
        //   Strongly tied to Venus sign for fabric preferences
        //   Venus in earth signs → natural_fibers, cotton, linen
        //   Venus in water signs → silk_preference, flowing materials
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "natural_fibers",
            type: "fabric_type",
            sourceEnergy: ["natural", "breathable", "quality"],
            tags: ["cotton", "linen", "wool", "silk"]
        ),
        
        Tier2TokenDefinition(
            name: "synthetic_technical",
            type: "fabric_type",
            sourceEnergy: ["modern", "functional", "practical"],
            tags: ["performance", "engineered", "innovative"]
        ),
        
        Tier2TokenDefinition(
            name: "silk_preference",
            type: "fabric_type",
            sourceEnergy: ["luxurious", "smooth", "refined"],
            tags: ["elegant", "fluid", "premium"]
        ),
        
        Tier2TokenDefinition(
            name: "cotton_preference",
            type: "fabric_type",
            sourceEnergy: ["comfortable", "breathable", "practical"],
            tags: ["natural", "versatile", "everyday"]
        ),
        
        Tier2TokenDefinition(
            name: "linen_preference",
            type: "fabric_type",
            sourceEnergy: ["relaxed", "natural", "textured"],
            tags: ["breathable", "casual_elegant", "lived_in"]
        ),
        
        Tier2TokenDefinition(
            name: "wool_preference",
            type: "fabric_type",
            sourceEnergy: ["structured", "warm", "substantial"],
            tags: ["insulating", "classic", "crisp"]
        ),
        
        Tier2TokenDefinition(
            name: "cashmere_preference",
            type: "fabric_type",
            sourceEnergy: ["luxurious", "soft", "refined"],
            tags: ["premium", "tactile", "investment"]
        ),
        
        Tier2TokenDefinition(
            name: "denim_preference",
            type: "fabric_type",
            sourceEnergy: ["casual", "durable", "versatile"],
            tags: ["workwear", "everyday", "timeless"]
        ),
        
        Tier2TokenDefinition(
            name: "leather_preference",
            type: "fabric_type",
            sourceEnergy: ["bold", "luxurious", "edgy"],
            tags: ["statement", "durable", "investment"]
        ),
        
        Tier2TokenDefinition(
            name: "velvet_preference",
            type: "fabric_type",
            sourceEnergy: ["luxurious", "tactile", "rich"],
            tags: ["plush", "sensual", "elevated"]
        ),
        
        // MARK: - COLOR APPLICATION TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: How to USE colors functionally in outfits
        // USAGE:
        //   Style Guide → "Colour Guide" to organize palette
        //   Daily Fit → Color usage strategy for today
        // DISPLAY EXAMPLE:
        //   "BASE COLORS (foundation): Cream, soft grey, warm white
        //    ACCENT COLORS (flexibility): Sage, muted teal
        //    STATEMENT COLORS (impact): Rust, terracotta"
        // QUERY PATTERN:
        //   ```
        //   let colorTokens = allTokens.filter { $0.type == "colour" && $0.isTier1 }
        //   let applicationTokens = allTokens.filter { $0.type == "color_application" }
        //   
        //   if applicationTokens.contains(where: { $0.name == "color_as_foundation" }) {
        //       let baseColors = colorTokens.filter { isNeutral($0.name) }
        //       // Display these as "Base Palette"
        //   }
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "color_as_statement",
            type: "color_application",
            sourceEnergy: ["bold", "expressive", "confident"],
            tags: ["focal_point", "primary_interest", "attention_grabbing"]
        ),
        
        Tier2TokenDefinition(
            name: "color_as_accent",
            type: "color_application",
            sourceEnergy: ["subtle", "balanced", "intentional"],
            tags: ["small_doses", "strategic", "punctuation"]
        ),
        
        Tier2TokenDefinition(
            name: "color_as_foundation",
            type: "color_application",
            sourceEnergy: ["grounded", "versatile", "base"],
            tags: ["neutrals", "everyday", "building_blocks"]
        ),
        
        Tier2TokenDefinition(
            name: "saturated_colors",
            type: "color_application",
            sourceEnergy: ["bold", "vibrant", "expressive"],
            oppositeOf: "muted_colors",
            tags: ["rich", "full_intensity", "pure"]
        ),
        
        Tier2TokenDefinition(
            name: "muted_colors",
            type: "color_application",
            sourceEnergy: ["subtle", "refined", "soft"],
            oppositeOf: "saturated_colors",
            tags: ["desaturated", "dusty", "greyed"]
        ),
        
        // MARK: - STYLING APPROACH TOKENS
        // ════════════════════════════════════════════════════════════════
        // PURPOSE: Wardrobe philosophy and dressing methodology
        // USAGE:
        //   Style Guide → "Style Core" for wardrobe building philosophy
        //   NOT used in Daily Fit (too meta for daily recommendations)
        // DISPLAY EXAMPLE:
        //   "You thrive with uniform dressing - a signature look you can rely on"
        //   "Intuitive styling serves you best - dress by feeling, not formula"
        // QUERY PATTERN:
        //   ```
        //   let approach = tokens.filter { $0.type == "styling_approach" }
        //   let topApproach = approach.max { $0.weight < $1.weight }
        //   
        //   // Use to frame entire Style Guide philosophy
        //   if topApproach.name == "investment_pieces" {
        //       // Frame guide around "buy less, buy better"
        //   } else if topApproach.name == "trend_responsive" {
        //       // Frame guide around staying current
        //   }
        //   ```
        // ════════════════════════════════════════════════════════════════
        
        Tier2TokenDefinition(
            name: "uniform_dressing",
            type: "styling_approach",
            sourceEnergy: ["consistent", "minimal", "efficient"],
            tags: ["capsule", "signature_look", "repetitive"]
        ),
        
        Tier2TokenDefinition(
            name: "intuitive_styling",
            type: "styling_approach",
            sourceEnergy: ["intuitive", "creative", "mood_responsive"],
            tags: ["feeling_led", "spontaneous", "instinctual"]
        ),
        
        Tier2TokenDefinition(
            name: "planned_outfits",
            type: "styling_approach",
            sourceEnergy: ["organized", "intentional", "prepared"],
            tags: ["pre_planned", "thought_through", "deliberate"]
        ),
        
        Tier2TokenDefinition(
            name: "investment_pieces",
            type: "styling_approach",
            sourceEnergy: ["quality", "timeless", "considered"],
            tags: ["buy_less_better", "long_term", "curated"]
        ),
        
        Tier2TokenDefinition(
            name: "trend_responsive",
            type: "styling_approach",
            sourceEnergy: ["modern", "current", "adaptable"],
            tags: ["seasonal", "fresh", "now"]
        ),
        
        Tier2TokenDefinition(
            name: "timeless_foundation",
            type: "styling_approach",
            sourceEnergy: ["classic", "enduring", "stable"],
            oppositeOf: "trend_responsive",
            tags: ["ageless", "permanent", "lasting"]
        )
    ]
    
    // MARK: - Token Generation Methods
    
    /// Generate Tier 2 tokens from Tier 1 energetic tokens
    /// - Parameters:
    ///   - tier1Tokens: Array of foundational energetic tokens
    ///   - minimumMatches: Minimum number of source energy matches required (default: 2)
    ///   - effortFilter: Optional filter for specific effort levels
    /// - Returns: Array of generated Tier 2 StyleTokens
    static func generateTier2Tokens(
        from tier1Tokens: [StyleToken],
        minimumMatches: Int = 2,
        effortFilter: EffortLevel? = nil
    ) -> [StyleToken] {
        
        var tier2Tokens: [StyleToken] = []
        
        // Extract high-weighted Tier 1 token names
        let dominantEnergies = Set(
            tier1Tokens
                .filter { $0.weight > 2.5 && $0.isTier1 }
                .map { $0.name.lowercased() }
        )
        
        print("\n🎨 TIER 2 TOKEN GENERATION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Dominant Tier 1 energies (\(dominantEnergies.count)): \(dominantEnergies.sorted().joined(separator: ", "))")
        
        // Try to match each Tier 2 definition
        for definition in allTokens {
            // Skip if effort level filter doesn't match
            if let requiredEffort = effortFilter,
               let tokenEffort = definition.effortLevel,
               tokenEffort != requiredEffort {
                continue
            }
            
            // Count how many source energies match
            let sourceEnergySet = Set(definition.sourceEnergy.map { $0.lowercased() })
            let matchingEnergies = sourceEnergySet.intersection(dominantEnergies)
            let matchCount = matchingEnergies.count
            
            // Require minimum number of matches
            if matchCount >= minimumMatches {
                // Find matching Tier 1 tokens to calculate weight
                let matchingTier1Tokens = tier1Tokens.filter {
                    sourceEnergySet.contains($0.name.lowercased())
                }
                
                guard !matchingTier1Tokens.isEmpty else { continue }
                
                // Calculate average weight from matching Tier 1 tokens
                let totalWeight = matchingTier1Tokens.reduce(0.0) { $0 + $1.weight }
                let averageWeight = totalWeight / Double(matchingTier1Tokens.count)
                
                // Inherit planetary/sign sources from highest weighted matching token
                let strongestSource = matchingTier1Tokens.max(by: { $0.weight < $1.weight })
                
                // Create Tier 2 token
                let tier2Token = StyleToken(
                    name: definition.name,
                    type: definition.type,
                    weight: averageWeight,
                    planetarySource: strongestSource?.planetarySource,
                    signSource: strongestSource?.signSource,
                    houseSource: strongestSource?.houseSource,
                    aspectSource: nil, // Tier 2 doesn't track aspects directly
                    originType: strongestSource?.originType ?? .natal,
                    tier: .tier2_applied,
                    sourceEnergyTokens: Array(matchingEnergies),
                    oppositeOf: definition.oppositeOf,
                    effortLevel: definition.effortLevel,
                    tags: definition.tags
                )
                
                tier2Tokens.append(tier2Token)
                
                print("  ✅ Generated: \(tier2Token.name) (weight: \(String(format: "%.2f", averageWeight))) from [\(matchingEnergies.sorted().joined(separator: ", "))]")
            }
        }
        
        print("\n✅ Generated \(tier2Tokens.count) Tier 2 tokens")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return tier2Tokens.sorted { $0.weight > $1.weight }
    }
    
    /// Filter Tier 2 tokens by type
    static func filterByType(_ tokens: [StyleToken], type: String) -> [StyleToken] {
        return tokens.filter { $0.type == type && $0.isTier2 }
    }
    
    /// Filter Tier 2 tokens by tags
    static func filterByTag(_ tokens: [StyleToken], tag: String) -> [StyleToken] {
        return tokens.filter { token in
            guard let tags = token.tags else { return false }
            return tags.contains(tag) && token.isTier2
        }
    }
    
    /// Get top N Tier 2 tokens by weight
    static func topTokens(_ tokens: [StyleToken], count: Int = 10) -> [StyleToken] {
        return tokens
            .filter { $0.isTier2 }
            .sorted { $0.weight > $1.weight }
            .prefix(count)
            .map { $0 }
    }
}

// MARK: - Tier 2 Token Definition Structure

/// Definition structure for Tier 2 tokens before instantiation
struct Tier2TokenDefinition {
    let name: String
    let type: String
    let sourceEnergy: [String]
    let oppositeOf: String?
    let effortLevel: EffortLevel?
    let tags: [String]
    
    init(name: String,
         type: String,
         sourceEnergy: [String],
         oppositeOf: String? = nil,
         effortLevel: EffortLevel? = nil,
         tags: [String] = []) {
        self.name = name
        self.type = type
        self.sourceEnergy = sourceEnergy
        self.oppositeOf = oppositeOf
        self.effortLevel = effortLevel
        self.tags = tags
    }
}

