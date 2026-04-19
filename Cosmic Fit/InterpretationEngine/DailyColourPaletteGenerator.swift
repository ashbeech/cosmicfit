// DAILY FIT ONLY -- Not in scope for Blueprint rebuild. Do not modify during Blueprint work.
//
//  DailyColourPaletteGenerator.swift
//  Cosmic Fit
//
//  Generates Daily Fit colour palette by selecting from Style Guide colours
//  based on dominant vibe and transit influences
//

import Foundation

class DailyColourPaletteGenerator {
    
    // MARK: - Main Selection Method
    
    /// Select 3 colours from Style Guide for today's Daily Fit palette
    /// - Parameters:
    ///   - styleGuideColours: All colour tokens from user's Style Guide
    ///   - vibeBreakdown: Today's vibe breakdown (determines colour mood)
    ///   - transits: Today's transit aspects (modulates colour selection)
    ///   - derivedAxes: Today's derived axes (influences colour energy)
    /// - Returns: Array of 3 StyleTokens representing today's colour palette
    static func selectDailyColours(
        from styleGuideColours: [StyleToken],
        vibeBreakdown: VibeBreakdown,
        transits: [NatalChartCalculator.TransitAspect],
        derivedAxes: DerivedAxes
    ) -> [StyleToken] {
        
        print("\n🎨 DAILY COLOUR PALETTE SELECTION 🎨")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Style Guide colours available: \(styleGuideColours.count)")
        print("🎭 Dominant vibe: \(vibeBreakdown.dominantEnergyName) (\(vibeBreakdown.value(for: vibeBreakdown.dominantEnergy))/10)")
        print("🎭 Secondary vibe: \(vibeBreakdown.secondaryEnergyName) (\(vibeBreakdown.value(for: vibeBreakdown.secondaryEnergy))/10)")
        
        // Filter to only colour tokens
        let colourTokens = styleGuideColours.filter { $0.type == "colour" }
        
        guard !colourTokens.isEmpty else {
            print("⚠️  No colour tokens in Style Guide - returning empty palette")
            return []
        }
        
        print("🎨 Style Guide colour tokens: \(colourTokens.count)")
        
        // Score each Style Guide colour for today's context
        var scoredColours: [(token: StyleToken, score: Double)] = []
        
        for colourToken in colourTokens {
            let score = scoreColourForToday(
                colourToken: colourToken,
                vibeBreakdown: vibeBreakdown,
                transits: transits,
                derivedAxes: derivedAxes
            )
            scoredColours.append((colourToken, score))
        }
        
        // Sort by score descending
        scoredColours.sort { $0.score > $1.score }
        
        // Select top 3 with diversity check
        let selectedColours = selectTop3WithDiversity(from: scoredColours, vibeBreakdown: vibeBreakdown)
        
        print("\n✅ SELECTED DAILY COLOURS:")
        for (index, token) in selectedColours.enumerated() {
            let vibeAlignment = getVibeAlignment(for: token.name)
            print("  \(index + 1). \(token.name) (weight: \(String(format: "%.2f", token.weight)), vibe: \(vibeAlignment), source: \(token.planetarySource ?? "unknown"))")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        return selectedColours
    }
    
    // MARK: - Colour Scoring
    
    /// Score a Style Guide colour for today's relevance
    private static func scoreColourForToday(
        colourToken: StyleToken,
        vibeBreakdown: VibeBreakdown,
        transits: [NatalChartCalculator.TransitAspect],
        derivedAxes: DerivedAxes
    ) -> Double {
        
        var score = colourToken.weight // Start with Style Guide weight (natally important colours)
        
        // 1. VIBE ALIGNMENT BONUS (most important)
        let vibeAlignment = getVibeAlignment(for: colourToken.name)
        let dominantVibe = vibeBreakdown.dominantEnergy
        let secondaryVibe = vibeBreakdown.secondaryEnergy
        
        if vibeAlignment.contains(dominantVibe) {
            score += 5.0 // Strong boost for dominant vibe match
        }
        if vibeAlignment.contains(secondaryVibe) {
            score += 2.5 // Medium boost for secondary vibe match
        }
        
        // 2. PLANETARY TRANSIT AMPLIFICATION
        // If colour's planetary source has strong transits today, boost it
        if let planetarySource = colourToken.planetarySource {
            let transitBoost = calculateTransitBoost(for: planetarySource, transits: transits)
            score += transitBoost
        }
        
        // 3. DERIVED AXES MODULATION
        // High action/tempo → favour dynamic colours
        // High visibility → favour bold colours
        // High strategy → favour sophisticated colours
        let axisBoost = calculateAxisBoost(for: colourToken.name, axes: derivedAxes)
        score += axisBoost
        
        return score
    }
    
    /// Get vibe energies that align with a colour name
    private static func getVibeAlignment(for colourName: String) -> Set<Energy> {
        let name = colourName.lowercased()
        var alignments: Set<Energy> = []
        
        // Romantic colours
        if ["pale yellow", "seafoam", "opalescent blue", "rose", "pearl", "lavender", 
            "cream", "soft blue", "pale gold", "sage green", "pale pink"].contains(name) {
            alignments.insert(.romantic)
        }
        
        // Classic colours
        if ["navy", "charcoal", "slate gray", "cream", "white", "black", "grey", "gray",
            "stone", "pearl gray", "cloud white", "structured charcoal"].contains(name) {
            alignments.insert(.classic)
        }
        
        // Playful colours
        if ["bright yellow", "yellow", "electric blue", "turquoise", "bright orange",
            "coral", "lime", "bright red", "neon", "vibrant"].contains(name) {
            alignments.insert(.playful)
        }
        
        // Drama colours
        if ["royal purple", "burgundy", "deep burgundy", "crimson", "ruby", "wine red",
            "oxblood", "midnight blue", "black", "deep orange", "burnt orange"].contains(name) {
            alignments.insert(.drama)
        }
        
        // Utility colours (earthy, practical)
        if ["olive", "moss", "forest green", "brown", "warm brown", "dark brown",
            "khaki", "taupe", "rust", "charcoal", "navy"].contains(name) {
            alignments.insert(.utility)
        }
        
        // Edge colours
        if ["electric blue", "neon", "metallic", "silver", "platinum", "abyssal black",
            "acid", "electric", "shocking"].contains(name) {
            alignments.insert(.edge)
        }
        
        // Neutral colours can align with multiple vibes (lower priority)
        if alignments.isEmpty {
            // Check for compound names (e.g., "abundant indigo")
            if name.contains("blue") {
                alignments.insert(.romantic)
                alignments.insert(.classic)
            } else if name.contains("purple") {
                alignments.insert(.drama)
            } else if name.contains("green") {
                alignments.insert(.utility)
            } else if name.contains("yellow") || name.contains("gold") {
                alignments.insert(.romantic)
            }
        }
        
        return alignments
    }
    
    /// Calculate transit boost for a planetary source
    private static func calculateTransitBoost(for planet: String, transits: [NatalChartCalculator.TransitAspect]) -> Double {
        // Count impactful transits for this planet
        let impactfulAspects = transits.filter { aspect in
            (aspect.transitPlanet == planet || aspect.natalPlanet == planet) &&
            aspect.orb < 1.5 && // Tight orb
            ["Conjunction", "Opposition", "Square", "Trine", "Sextile"].contains(aspect.aspectType)
        }
        
        // More transits = more boost (but cap at reasonable level)
        return min(Double(impactfulAspects.count) * 0.5, 2.0)
    }
    
    /// Calculate axis-based boost for colour energy
    private static func calculateAxisBoost(for colourName: String, axes: DerivedAxes) -> Double {
        let name = colourName.lowercased()
        var boost = 0.0
        
        // High action → dynamic, bold colours
        if axes.action > 7.0 {
            if ["red", "orange", "bright", "bold", "crimson", "ruby"].contains(where: { name.contains($0) }) {
                boost += 1.0
            }
        }
        
        // High visibility → striking, noticeable colours
        if axes.visibility > 7.0 {
            if ["royal", "bright", "electric", "bold", "vibrant", "striking"].contains(where: { name.contains($0) }) {
                boost += 1.0
            }
        }
        
        // Low tempo (slow day) → soft, muted colours
        if axes.tempo < 5.0 {
            if ["pale", "soft", "muted", "gentle", "subtle"].contains(where: { name.contains($0) }) {
                boost += 0.5
            }
        }
        
        // High strategy → sophisticated, complex colours
        if axes.strategy > 7.0 {
            if ["navy", "charcoal", "slate", "sophisticated", "deep", "rich"].contains(where: { name.contains($0) }) {
                boost += 0.5
            }
        }
        
        return boost
    }
    
    // MARK: - Selection with Diversity
    
    /// Select top 3 colours ensuring diversity
    private static func selectTop3WithDiversity(
        from scoredColours: [(token: StyleToken, score: Double)],
        vibeBreakdown: VibeBreakdown
    ) -> [StyleToken] {
        
        guard !scoredColours.isEmpty else { return [] }
        
        var selected: [StyleToken] = []
        
        // 1. First colour: Highest scoring (usually dominant vibe match)
        selected.append(scoredColours[0].token)
        
        // 2. Second colour: Different vibe family if possible
        if scoredColours.count > 1 {
            let firstAlignment = getVibeAlignment(for: selected[0].name)
            
            // Try to find a colour with different vibe alignment
            if let differentColour = scoredColours.dropFirst().first(where: { scored in
                let alignment = getVibeAlignment(for: scored.token.name)
                return alignment != firstAlignment && !selected.contains(where: { $0.name == scored.token.name })
            }) {
                selected.append(differentColour.token)
            } else {
                // Fallback: just take second highest
                selected.append(scoredColours[1].token)
            }
        }
        
        // 3. Third colour: Grounding/neutral or accent
        if scoredColours.count > 2 {
            // Prefer a classic/neutral as third (grounding)
            if let neutralColour = scoredColours.dropFirst(2).first(where: { scored in
                let alignment = getVibeAlignment(for: scored.token.name)
                return alignment.contains(.classic) && !selected.contains(where: { $0.name == scored.token.name })
            }) {
                selected.append(neutralColour.token)
            } else {
                // Fallback: third highest that isn't already selected
                if let thirdColour = scoredColours.dropFirst(2).first(where: { scored in
                    !selected.contains(where: { $0.name == scored.token.name })
                }) {
                    selected.append(thirdColour.token)
                } else if selected.count < 3 && scoredColours.count >= 3 {
                    // Last resort: take third item even if similar
                    selected.append(scoredColours[2].token)
                }
            }
        }
        
        // Ensure exactly 3 colours (fill with top scoring if needed)
        while selected.count < 3 && selected.count < scoredColours.count {
            if let nextColour = scoredColours.first(where: { scored in
                !selected.contains(where: { $0.name == scored.token.name })
            }) {
                selected.append(nextColour.token)
            } else {
                break
            }
        }
        
        return selected
    }

    // MARK: - V4 Daily Colour Selection

    /// Deterministic daily 3-colour pick from the V4 palette. Rotates across
    /// the 12 anchors (4 neutral + 4 core + 4 accent) using a day-based seed
    /// so each day surfaces a different combination while always picking one
    /// from each band.
    struct V4DailyPalette: Codable {
        let dailyHexes: [String]
        let dailyNames: [String]
        let allPaletteHexes: [String]
    }

    static func selectV4DailyColours(
        from palette: PaletteSection,
        date: Date = Date()
    ) -> V4DailyPalette? {
        guard let neutrals = palette.neutrals, !neutrals.isEmpty,
              !palette.coreColours.isEmpty, !palette.accentColours.isEmpty else {
            return nil
        }

        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0

        let neutralPick = neutrals[dayIndex % neutrals.count]
        let corePick = palette.coreColours[(dayIndex / neutrals.count) % palette.coreColours.count]
        let accentPick = palette.accentColours[(dayIndex / (neutrals.count * palette.coreColours.count)) % palette.accentColours.count]

        let dailyHexes = [corePick.hexValue, accentPick.hexValue, neutralPick.hexValue]
        let dailyNames = [corePick.name, accentPick.name, neutralPick.name]
        let allHexes = neutrals.map(\.hexValue) + palette.coreColours.map(\.hexValue) + palette.accentColours.map(\.hexValue)

        return V4DailyPalette(
            dailyHexes: dailyHexes,
            dailyNames: dailyNames,
            allPaletteHexes: allHexes
        )
    }
}

