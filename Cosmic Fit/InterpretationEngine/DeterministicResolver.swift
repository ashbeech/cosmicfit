//
//  DeterministicResolver.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Resolves all deterministic (non-AI) Blueprint fields from token arrays.
//  Implements the algorithms from spec §3c: palette, textures, metals/stones,
//  code directives, and patterns. All resolution uses normalised 0.0–1.0 weights.
//

import Foundation

struct DeterministicResolverResult {
    let coreColours: [BlueprintColour]
    let accentColours: [BlueprintColour]
    let swatchFamilies: [SwatchFamily]
    let recommendedMetals: [String]
    let recommendedStones: [String]
    let leanInto: [String]
    let avoid: [String]
    let consider: [String]
    let recommendedPatterns: [String]
    let avoidPatterns: [String]
    let recommendedTextures: [String]
    let avoidTextures: [String]
    let sweetSpotKeywords: [String]
}

struct DeterministicResolver {

    // MARK: - Public API

    static func resolve(
        tokens: [BlueprintToken],
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset,
        contributingCombos: [(key: String, aggregateWeight: Double)]
    ) -> DeterministicResolverResult {
        let palette = resolvePalette(tokens: tokens, colourLibrary: dataset.colourLibrary)
        let hardware = resolveHardware(
            contributingCombos: contributingCombos, dataset: dataset, analysis: analysis
        )
        let code = resolveCode(
            tokens: tokens,
            analysis: analysis,
            contributingCombos: contributingCombos,
            dataset: dataset
        )
        let patterns = resolvePatterns(
            tokens: tokens, analysis: analysis, dataset: dataset
        )
        let textures = resolveTextures(
            tokens: tokens, contributingCombos: contributingCombos, dataset: dataset
        )

        let swatchFamilies = PaletteSwatchGenerator.generateFamilies(
            core: palette.core, accent: palette.accent
        )

        return DeterministicResolverResult(
            coreColours: palette.core,
            accentColours: palette.accent,
            swatchFamilies: swatchFamilies,
            recommendedMetals: hardware.metals,
            recommendedStones: hardware.stones,
            leanInto: code.leanInto,
            avoid: code.avoid,
            consider: code.consider,
            recommendedPatterns: patterns.recommended,
            avoidPatterns: patterns.avoid,
            recommendedTextures: textures.recommended,
            avoidTextures: textures.avoid,
            sweetSpotKeywords: textures.sweetSpot
        )
    }

    // MARK: - Palette Resolution (§3c)

    private struct PaletteResult {
        let core: [BlueprintColour]
        let accent: [BlueprintColour]
    }

    private static func resolvePalette(
        tokens: [BlueprintToken],
        colourLibrary: [String: ColourLibraryEntry]
    ) -> PaletteResult {
        let colourTokens = tokens
            .filter { $0.category == .colour }
            .sorted { tieBreakSort($0, $1) }

        var selected: [BlueprintColour] = []
        var selectedHues: [Double] = []

        for token in colourTokens {
            guard selected.count < 6 else { break }

            let hex: String
            if let libEntry = colourLibrary[token.name] {
                hex = libEntry.hex
            } else {
                hex = findClosestColourHex(name: token.name, library: colourLibrary) ?? "#808080"
            }

            let hue = hueFromHex(hex)

            let tooClose = selectedHues.contains { existingHue in
                hueDistance(hue, existingHue) < 15.0
            }
            if tooClose { continue }

            let role: ColourRole = selected.count < 4 ? .core : .accent
            selected.append(BlueprintColour(
                name: token.name,
                hexValue: hex,
                role: role,
                provenance: .libraryFallback(reason: "pre-resolver-rework legacy path")
            ))
            selectedHues.append(hue)
        }

        selected = applyFallbackIfNeeded(
            selected: selected,
            minCore: 3, minAccent: 2,
            colourLibrary: colourLibrary,
            existingHues: selectedHues
        )

        let core = selected.filter { $0.role == .core }
        let accent = selected.filter { $0.role == .accent }
        return PaletteResult(core: core, accent: accent)
    }

    // MARK: - Hardware Resolution (§3c)

    private struct HardwareResult {
        let metals: [String]
        let stones: [String]
    }

    private static func resolveHardware(
        contributingCombos: [(key: String, aggregateWeight: Double)],
        dataset: AstrologicalStyleDataset,
        analysis: ChartAnalysis
    ) -> HardwareResult {
        let topCombos = Array(contributingCombos.prefix(3))

        var metalCounts: [String: (count: Int, maxWeight: Double)] = [:]
        var stoneCounts: [String: (count: Int, maxWeight: Double)] = [:]

        for combo in topCombos {
            guard let entry = dataset.planetSign[combo.key] else { continue }

            for metal in entry.metals {
                let lower = metal.lowercased()
                let existing = metalCounts[lower] ?? (0, 0)
                metalCounts[lower] = (existing.count + 1, max(existing.maxWeight, combo.aggregateWeight))
            }

            for stone in entry.stones {
                let lower = stone.lowercased()
                let existing = stoneCounts[lower] ?? (0, 0)
                stoneCounts[lower] = (existing.count + 1, max(existing.maxWeight, combo.aggregateWeight))
            }
        }

        // Collect hardware_bias metals/stones from Venus and Moon house placements.
        // These only reorder existing candidates — never introduce new ones.
        var biasMetals: Set<String> = []
        var biasStones: Set<String> = []
        for planet in ["Venus", "Moon"] {
            guard let house = analysis.planetHouses[planet],
                  let placement = dataset.housePlacements["\(planet.lowercased())_house_\(house)"],
                  let hwBias = placement.hardwareBias else { continue }
            for m in hwBias.metals { biasMetals.insert(m.lowercased()) }
            for s in hwBias.stones { biasStones.insert(s.lowercased()) }
        }

        let metals = metalCounts
            .sorted { a, b in
                if a.value.count != b.value.count { return a.value.count > b.value.count }
                if a.value.maxWeight != b.value.maxWeight { return a.value.maxWeight > b.value.maxWeight }
                let aBias: Double = biasMetals.contains(a.key) ? 1.0 : 0.0
                let bBias: Double = biasMetals.contains(b.key) ? 1.0 : 0.0
                return aBias > bBias
            }
            .map(\.key)

        let stones = stoneCounts
            .sorted { a, b in
                if a.value.count != b.value.count { return a.value.count > b.value.count }
                if a.value.maxWeight != b.value.maxWeight { return a.value.maxWeight > b.value.maxWeight }
                let aBias: Double = biasStones.contains(a.key) ? 1.0 : 0.0
                let bBias: Double = biasStones.contains(b.key) ? 1.0 : 0.0
                return aBias > bBias
            }
            .map(\.key)

        return HardwareResult(
            metals: ensureMinimum(metals, min: 2),
            stones: ensureMinimum(stones, min: 2)
        )
    }

    // MARK: - Code Directives Resolution (§3c)

    private struct CodeResult {
        let leanInto: [String]
        let avoid: [String]
        let consider: [String]
    }

    private static func resolveCode(
        tokens: [BlueprintToken],
        analysis: ChartAnalysis,
        contributingCombos: [(key: String, aggregateWeight: Double)],
        dataset: AstrologicalStyleDataset
    ) -> CodeResult {
        var leanIntoItems: [(String, Double)] = []
        var avoidItems: [(String, Double)] = []
        var considerItems: [(String, Double)] = []

        for combo in contributingCombos {
            guard let entry = dataset.planetSign[combo.key] else { continue }

            for item in entry.codeLeaninto {
                leanIntoItems.append((item, combo.aggregateWeight))
            }
            for item in entry.codeAvoid {
                avoidItems.append((item, combo.aggregateWeight))
            }
            for item in entry.codeConsider {
                considerItems.append((item, combo.aggregateWeight))
            }
        }

        // Add aspect-based code modifications
        for aspect in analysis.significantAspects {
            let key = "\(aspect.planet1.lowercased())_\(aspect.aspectType.lowercased())_\(aspect.planet2.lowercased())"
            if let aspectEntry = dataset.aspects[key] {
                if !aspectEntry.codeAdditionLeaninto.isEmpty {
                    leanIntoItems.append((aspectEntry.codeAdditionLeaninto, 1.0))
                }
                if !aspectEntry.codeAdditionAvoid.isEmpty {
                    avoidItems.append((aspectEntry.codeAdditionAvoid, 1.0))
                }
            }
        }

        // Generate anti-tokens from opposites of top 3 lean-into combos
        let topLeanIntoCombos = contributingCombos.prefix(3)
        for combo in topLeanIntoCombos {
            guard let entry = dataset.planetSign[combo.key] else { continue }
            for oppMood in entry.opposites.mood {
                avoidItems.append((oppMood, combo.aggregateWeight * 0.5))
            }
        }

        // House-bias pass: inject lean_into_bias for Venus and Moon before dedup.
        let houseBiasPlanets: [(name: String, leanIntoWeight: Double)] = [
            ("Venus", 0.5), ("Moon", 0.45)
        ]
        for (planet, leanWeight) in houseBiasPlanets {
            guard let house = analysis.planetHouses[planet],
                  let placement = dataset.housePlacements["\(planet.lowercased())_house_\(house)"] else { continue }
            if let biasItems = placement.leanIntoBias {
                for item in biasItems {
                    leanIntoItems.append((item, leanWeight))
                }
            }
        }

        let leanInto = deduplicateAndSort(leanIntoItems, minCount: 4, maxCount: 6)
        var avoid = deduplicateAndSort(avoidItems, minCount: 4, maxCount: 6)

        let leanIntoSet = Set(leanInto.map { $0.lowercased() })
        var movedToConsider: [String] = []
        avoid = avoid.filter { item in
            if leanIntoSet.contains(item.lowercased()) {
                movedToConsider.append(item)
                return false
            }
            return true
        }

        let normalRange = contributingCombos.filter { $0.aggregateWeight >= 0.3 && $0.aggregateWeight <= 0.6 }
        var considerBase = considerItems.filter { item in
            normalRange.contains(where: { combo in
                dataset.planetSign[combo.key]?.codeConsider.contains(item.0) ?? false
            })
        }
        for moved in movedToConsider {
            considerBase.append((moved, 0.5))
        }

        // House-bias pass: inject code_consider_bias for Venus and Moon directly into considerBase.
        // These are pre-curated bounded arrays, not comma-split modifier prose.
        for (planet, _) in houseBiasPlanets {
            guard let house = analysis.planetHouses[planet],
                  let placement = dataset.housePlacements["\(planet.lowercased())_house_\(house)"] else { continue }
            let comboWeight = contributingCombos
                .first(where: { $0.key.hasPrefix(planet.lowercased() + "_") })?.aggregateWeight ?? 0.5
            if let biasItems = placement.codeConsiderBias {
                for item in biasItems {
                    considerBase.append((item, comboWeight * 0.4))
                }
            }
        }

        let consider = deduplicateAndSort(considerBase, minCount: 3, maxCount: 4)

        return CodeResult(leanInto: leanInto, avoid: avoid, consider: consider)
    }

    // MARK: - Pattern Resolution (§3c)
    // House/sect influences must never enter this resolver path.
    // Patterns resolve from token weights only (sign + dignity driven).

    private struct PatternResult {
        let recommended: [String]
        let avoid: [String]
    }

    private static func resolvePatterns(
        tokens: [BlueprintToken],
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset
    ) -> PatternResult {
        let patternTokens = tokens
            .filter { $0.category == .pattern }
            .sorted { tieBreakSort($0, $1) }

        let recommended = stableUnique(
            patternTokens
                .filter { $0.weight >= 0.3 }
                .map(\.name)
        ).prefix(6)

        var avoidPatterns: [String] = []
        let relevantPlanets = buildPatternAvoidSources(analysis: analysis, dataset: dataset)
        for (key, _) in relevantPlanets {
            guard let entry = dataset.planetSign[key] else { continue }
            avoidPatterns += entry.patterns.avoid
        }
        let dedupedAvoid = stableUnique(avoidPatterns).prefix(4)

        return PatternResult(
            recommended: ensureMinimum(Array(recommended), min: 2),
            avoid: ensureMinimum(Array(dedupedAvoid), min: 2)
        )
    }

    /// Builds token-derived pattern avoid sources (no combo dependency).
    private static func buildPatternAvoidSources(
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset
    ) -> [(key: String, weight: Double)] {
        let planetNames = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                           "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
        var sources: [(key: String, weight: Double)] = []
        for name in planetNames {
            guard let sign = analysis.planetSigns[name] else { continue }
            let key = "\(name.lowercased())_\(sign.lowercased())"
            guard dataset.planetSign[key] != nil else { continue }
            sources.append((key: key, weight: Double(planetWeightRank(name))))
        }
        let ascKey = "ascendant_\(analysis.ascendantSign.lowercased())"
        if dataset.planetSign[ascKey] != nil {
            sources.append((key: ascKey, weight: Double(planetWeightRank("Ascendant"))))
        }
        return sources.sorted { $0.weight > $1.weight }
    }

    // MARK: - Texture Resolution (§3c)

    private struct TextureResult {
        let recommended: [String]
        let avoid: [String]
        let sweetSpot: [String]
    }

    private static func resolveTextures(
        tokens: [BlueprintToken],
        contributingCombos: [(key: String, aggregateWeight: Double)],
        dataset: AstrologicalStyleDataset
    ) -> TextureResult {
        let textureTokens = tokens
            .filter { $0.category == .texture }
            .sorted { tieBreakSort($0, $1) }

        let recommended = stableUnique(
            textureTokens
                .filter { $0.weight >= 0.3 }
                .map(\.name)
        ).prefix(4)

        var avoidItems: [(String, Double)] = []
        let topCombos = Array(contributingCombos.prefix(3))
        for combo in topCombos {
            guard let entry = dataset.planetSign[combo.key] else { continue }
            for tex in entry.textures.bad {
                avoidItems.append((tex, combo.aggregateWeight))
            }
            for tex in entry.opposites.textures {
                avoidItems.append((tex, combo.aggregateWeight * 0.8))
            }
        }
        let avoidDeduped = deduplicateAndSort(avoidItems, minCount: 2, maxCount: 3)

        let structureTokens = tokens
            .filter { $0.category == .structure }
            .sorted { tieBreakSort($0, $1) }

        let sweetSpot = stableUnique(
            structureTokens
                .filter { $0.weight >= 0.5 }
                .map(\.name)
        ).prefix(2)

        return TextureResult(
            recommended: ensureMinimum(Array(recommended), min: 2),
            avoid: ensureMinimum(avoidDeduped, min: 2),
            sweetSpot: ensureMinimum(Array(sweetSpot), min: 1)
        )
    }

    // MARK: - Colour Utilities

    private static func hueFromHex(_ hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let rgb = UInt32(cleaned, radix: 16) else { return 0 }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        guard delta > 0 else { return 0 }

        var hue: Double
        if maxC == r {
            hue = 60.0 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
        } else if maxC == g {
            hue = 60.0 * (((b - r) / delta) + 2)
        } else {
            hue = 60.0 * (((r - g) / delta) + 4)
        }

        if hue < 0 { hue += 360 }
        return hue
    }

    private static func hueDistance(_ h1: Double, _ h2: Double) -> Double {
        let diff = abs(h1 - h2)
        return min(diff, 360.0 - diff)
    }

    private static func findClosestColourHex(
        name: String,
        library: [String: ColourLibraryEntry]
    ) -> String? {
        let lower = name.lowercased()
        for (key, entry) in library {
            if key.lowercased().contains(lower) || lower.contains(key.lowercased()) {
                return entry.hex
            }
        }
        return library.values.first?.hex
    }

    // MARK: - Fallback Logic (§3c)

    private static func applyFallbackIfNeeded(
        selected: [BlueprintColour],
        minCore: Int, minAccent: Int,
        colourLibrary: [String: ColourLibraryEntry],
        existingHues: [Double]
    ) -> [BlueprintColour] {
        var result = selected
        let coreCount = result.filter { $0.role == .core }.count
        let accentCount = result.filter { $0.role == .accent }.count

        var hues = existingHues

        if coreCount < minCore {
            let defaults: [(String, String)] = [
                ("charcoal", "#36454F"),
                ("slate", "#708090"),
                ("ivory", "#FFFFF0"),
                ("midnight", "#191970")
            ]
            for (name, hex) in defaults where coreCount + result.count < minCore + accentCount {
                let hue = hueFromHex(hex)
                let tooClose = hues.contains { hueDistance($0, hue) < 15.0 }
                if !tooClose {
                    result.append(BlueprintColour(
                        name: name,
                        hexValue: hex,
                        role: .core,
                        provenance: .libraryFallback(reason: "pre-resolver-rework legacy path")
                    ))
                    hues.append(hue)
                }
                if result.filter({ $0.role == .core }).count >= minCore { break }
            }
        }

        if accentCount < minAccent {
            let defaults: [(String, String)] = [
                ("dusty rose", "#DCAE96"),
                ("sage", "#9CAF88"),
                ("amber", "#FFBF00")
            ]
            for (name, hex) in defaults {
                let hue = hueFromHex(hex)
                let tooClose = hues.contains { hueDistance($0, hue) < 15.0 }
                if !tooClose {
                    result.append(BlueprintColour(
                        name: name,
                        hexValue: hex,
                        role: .accent,
                        provenance: .libraryFallback(reason: "pre-resolver-rework legacy path")
                    ))
                    hues.append(hue)
                }
                if result.filter({ $0.role == .accent }).count >= minAccent { break }
            }
        }

        return result
    }

    // MARK: - Sort & Deduplicate Helpers

    /// Tie-break: higher weight wins; if tied, prefer higher basePlanetWeight source.
    private static func tieBreakSort(_ a: BlueprintToken, _ b: BlueprintToken) -> Bool {
        if a.weight != b.weight { return a.weight > b.weight }
        let aBase = planetWeightRank(a.planetarySource)
        let bBase = planetWeightRank(b.planetarySource)
        return aBase > bBase
    }

    private static func planetWeightRank(_ source: String?) -> Int {
        switch source {
        case "Venus":     return 10
        case "Moon":      return 9
        case "Ascendant": return 8
        case "Sun":       return 7
        case "Mars":      return 6
        case "Saturn":    return 5
        case "Jupiter":   return 4
        case "Mercury":   return 3
        default:          return 1
        }
    }

    private static func deduplicateAndSort(
        _ items: [(String, Double)],
        minCount: Int,
        maxCount: Int
    ) -> [String] {
        var seen: Set<String> = []
        let sorted = items.sorted { $0.1 > $1.1 }
        var result: [String] = []

        for (item, _) in sorted {
            let key = item.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(item)
            if result.count >= maxCount { break }
        }

        return result
    }

    private static func ensureMinimum(_ items: [String], min: Int) -> [String] {
        guard items.count < min else { return items }
        var result = items
        while result.count < min {
            result.append("(see Blueprint for details)")
        }
        return result
    }

    /// Preserves first-seen order from already weight-sorted arrays.
    /// Replaces `Array(Set(...))` to avoid nondeterministic ordering.
    private static func stableUnique(_ items: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for item in items {
            let key = item.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(item)
        }
        return result
    }
}
