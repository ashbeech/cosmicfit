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
        let palette = resolvePalette(
            tokens: tokens,
            dataset: dataset,
            contributingCombos: contributingCombos
        )
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

    // MARK: - Palette Resolution (Phase A §6 — multi-pass selector)

    private struct PaletteResult {
        let core: [BlueprintColour]
        let accent: [BlueprintColour]
    }

    /// Band targets. Core wants 4 but a minimum of 3 is acceptable; accent
    /// wants exactly 4 after Phase A. Cross-pool and library fallback passes
    /// fire only when the own-pool + hue-gap ladder passes underflow.
    private static let coreDesired = 4
    private static let accentDesired = 4
    private static let coreMinimum = 3
    private static let accentMinimum = 4

    /// Hue-gap ladder — own-pool only. Cross-pool and library fallback
    /// passes use the tightest rung (15°) to stay coherent with chart-derived
    /// picks; see §6.1.
    private static let hueGapLadder: [Double] = [15.0, 12.0, 10.0]

    private static func resolvePalette(
        tokens: [BlueprintToken],
        dataset: AstrologicalStyleDataset,
        contributingCombos: [(key: String, aggregateWeight: Double)]
    ) -> PaletteResult {
        let colourLibrary = dataset.colourLibrary
        let colourTokens = tokens
            .filter { $0.category == .colour }
            .sorted { tieBreakSort($0, $1) }

        let primaryPool = colourTokens.filter { $0.sourceColourRole == .primary }
        let accentPool = colourTokens.filter { $0.sourceColourRole == .accent }

        let comboRankIndex = indexComboRanks(contributingCombos)

        var selected: [BlueprintColour] = []
        var selectedHues: [Double] = []

        // Pass 1 — fill core band from the primary-sourced pool.
        selected += selectAnchors(
            from: primaryPool,
            desiredCount: coreDesired,
            role: .core,
            sourceRole: .primary,
            colourLibrary: colourLibrary,
            comboRankIndex: comboRankIndex,
            selectedHues: &selectedHues
        )

        // Pass 2 — fill accent band from the accent-sourced pool.
        selected += selectAnchors(
            from: accentPool,
            desiredCount: accentDesired,
            role: .accent,
            sourceRole: .accent,
            colourLibrary: colourLibrary,
            comboRankIndex: comboRankIndex,
            selectedHues: &selectedHues
        )

        // Pass 3 — cross-pool escalation when either band missed its minimum.
        selected = applyCrossPoolEscalation(
            selected: selected,
            primaryPool: primaryPool,
            accentPool: accentPool,
            colourLibrary: colourLibrary,
            comboRankIndex: comboRankIndex,
            selectedHues: &selectedHues
        )

        // Pass 4 — library fallback (Option A: dataset-sourced pool).
        selected = applyLibraryFallback(
            selected: selected,
            fallbackPool: dataset.fallbackPalettePool ?? [],
            selectedHues: &selectedHues
        )

        // Rank-sort (§9.2): ascending by contributorRank; cross-pool and
        // library-fallback entries sort to the end.
        let core = selected
            .filter { $0.role == .core }
            .sorted(by: provenanceRankSort)
        let accent = selected
            .filter { $0.role == .accent }
            .sorted(by: provenanceRankSort)

        logPaletteProvenance(core: core, accent: accent)
        return PaletteResult(core: core, accent: accent)
    }

    // MARK: - Pass 1 & 2 — Own-Pool Selection with Hue-Gap Ladder

    private static func selectAnchors(
        from pool: [BlueprintToken],
        desiredCount: Int,
        role: ColourRole,
        sourceRole: DatasetColourRole,
        colourLibrary: [String: ColourLibraryEntry],
        comboRankIndex: [String: Int],
        selectedHues: inout [Double]
    ) -> [BlueprintColour] {
        var picked: [BlueprintColour] = []
        var usedTokens: Set<String> = []
        var ladderIndex = 0

        while picked.count < desiredCount, ladderIndex < hueGapLadder.count {
            let currentGap = hueGapLadder[ladderIndex]
            var madeProgress = false

            for token in pool where !usedTokens.contains(token.name) {
                let hex = resolveHex(name: token.name, library: colourLibrary)
                let hue = hueFromHex(hex)
                let tooClose = selectedHues.contains { existing in
                    hueDistance(hue, existing) < currentGap
                }
                if tooClose { continue }

                let comboKey = makeComboKey(
                    planet: token.planetarySource,
                    sign: token.signSource
                )
                let rank = comboRankIndex[comboKey] ?? Int.max / 2

                picked.append(BlueprintColour(
                    name: token.name,
                    hexValue: hex,
                    role: role,
                    provenance: .chartDerived(
                        comboKey: comboKey,
                        contributorRank: rank,
                        sourceRole: sourceRole,
                        hueGapApplied: currentGap
                    )
                ))
                selectedHues.append(hue)
                usedTokens.insert(token.name)
                madeProgress = true

                if picked.count == desiredCount { break }
            }

            if !madeProgress {
                ladderIndex += 1
            }
        }

        return picked
    }

    // MARK: - Pass 3 — Cross-Pool Escalation

    /// If either band is short of its minimum after pass 1 / pass 2, pull
    /// additional anchors from the opposite dataset pool. Selected entries
    /// carry `.crossPoolEscalation` provenance noting the original role and
    /// the reason. Uses the tightest hue-gap (15°) so cross-pool picks stay
    /// chart-coherent.
    private static func applyCrossPoolEscalation(
        selected: [BlueprintColour],
        primaryPool: [BlueprintToken],
        accentPool: [BlueprintToken],
        colourLibrary: [String: ColourLibraryEntry],
        comboRankIndex: [String: Int],
        selectedHues: inout [Double]
    ) -> [BlueprintColour] {
        var result = selected

        let coreCount = result.filter { $0.role == .core }.count
        if coreCount < coreMinimum {
            let deficit = coreMinimum - coreCount
            let added = borrowFromOppositePool(
                pool: accentPool,
                usedNames: Set(result.map(\.name)),
                deficit: deficit,
                intoRole: .core,
                originalRole: .accent,
                reason: "core band underflow after own-pool pass",
                colourLibrary: colourLibrary,
                comboRankIndex: comboRankIndex,
                selectedHues: &selectedHues
            )
            result += added
        }

        let accentCount = result.filter { $0.role == .accent }.count
        if accentCount < accentMinimum {
            let deficit = accentMinimum - accentCount
            let added = borrowFromOppositePool(
                pool: primaryPool,
                usedNames: Set(result.map(\.name)),
                deficit: deficit,
                intoRole: .accent,
                originalRole: .primary,
                reason: "accent band underflow after own-pool pass",
                colourLibrary: colourLibrary,
                comboRankIndex: comboRankIndex,
                selectedHues: &selectedHues
            )
            result += added
        }

        return result
    }

    private static func borrowFromOppositePool(
        pool: [BlueprintToken],
        usedNames: Set<String>,
        deficit: Int,
        intoRole: ColourRole,
        originalRole: DatasetColourRole,
        reason: String,
        colourLibrary: [String: ColourLibraryEntry],
        comboRankIndex: [String: Int],
        selectedHues: inout [Double]
    ) -> [BlueprintColour] {
        var borrowed: [BlueprintColour] = []
        var blocked = usedNames

        for token in pool where !blocked.contains(token.name) {
            if borrowed.count >= deficit { break }
            let hex = resolveHex(name: token.name, library: colourLibrary)
            let hue = hueFromHex(hex)
            let tooClose = selectedHues.contains { hueDistance($0, hue) < 15.0 }
            if tooClose { continue }

            let comboKey = makeComboKey(
                planet: token.planetarySource,
                sign: token.signSource
            )
            let rank = comboRankIndex[comboKey] ?? Int.max / 2

            borrowed.append(BlueprintColour(
                name: token.name,
                hexValue: hex,
                role: intoRole,
                provenance: .crossPoolEscalation(
                    comboKey: comboKey,
                    contributorRank: rank,
                    originalRole: originalRole,
                    hueGapApplied: 15.0,
                    reason: reason
                )
            ))
            selectedHues.append(hue)
            blocked.insert(token.name)
        }

        return borrowed
    }

    // MARK: - Pass 4 — Library Fallback (§6.5, Option A)

    /// Dataset-sourced fallback pool. Option A from §6.5 (v1.1 rev 3): the
    /// curated defaults live in `astrological_style_dataset.json` under the
    /// top-level `fallback_palette_pool` key, not in Swift, so colour data
    /// stays in a single source of truth. Array order defines padding
    /// priority. The diagnostic (§8) confirms this path is not reached for
    /// any fixture or tested synthetic chart, so the pool is effectively a
    /// safety net rather than a hot path.
    private static func applyLibraryFallback(
        selected: [BlueprintColour],
        fallbackPool: [FallbackPaletteEntry],
        selectedHues: inout [Double]
    ) -> [BlueprintColour] {
        var result = selected
        let usedNames = Set(result.map(\.name))

        if fallbackPool.isEmpty {
            // Dataset did not ship a `fallback_palette_pool`. The resolver
            // cannot pad from anywhere, so bands may underflow their
            // minimums. Log once per resolve so the regression is visible
            // in test output — production datasets are required to ship
            // the pool (see `validate_dataset.py`).
            print("[Resolver] Warning: astrological_style_dataset.json has no fallback_palette_pool; library fallback unavailable.")
            return result
        }

        func padBand(role: ColourRole, minimum: Int, reasonContext: String) {
            var count = result.filter { $0.role == role }.count
            guard count < minimum else { return }

            for candidate in fallbackPool where candidate.role == role {
                if count >= minimum { break }
                if usedNames.contains(candidate.name) { continue }
                let hue = hueFromHex(candidate.hex)
                let tooClose = selectedHues.contains { hueDistance($0, hue) < 15.0 }
                if tooClose { continue }

                result.append(BlueprintColour(
                    name: candidate.name,
                    hexValue: candidate.hex,
                    role: role,
                    provenance: .libraryFallback(
                        reason: "\(reasonContext) — padded from fallback_palette_pool"
                    )
                ))
                selectedHues.append(hue)
                count += 1
            }
        }

        padBand(role: .core, minimum: coreMinimum,
                reasonContext: "core band below minimum after escalation")
        padBand(role: .accent, minimum: accentMinimum,
                reasonContext: "accent band below minimum after escalation")

        return result
    }

    // MARK: - Rank-Sorting (§9.2)

    /// Ascending by contributorRank. Library-fallback provenance is treated
    /// as `Int.max` so fallback entries always sort to the end. Cross-pool
    /// escalation keeps its real rank so the highest-signal borrowed
    /// anchors still win tie-break against padding material.
    private static func provenanceRankSort(
        _ a: BlueprintColour,
        _ b: BlueprintColour
    ) -> Bool {
        let ra = provenanceRank(a.provenance)
        let rb = provenanceRank(b.provenance)
        if ra != rb { return ra < rb }
        return a.name < b.name
    }

    private static func provenanceRank(_ provenance: ColourProvenance) -> Int {
        switch provenance {
        case let .chartDerived(_, rank, _, _):       return rank
        case let .crossPoolEscalation(_, rank, _, _, _): return rank
        case .libraryFallback:                       return Int.max
        }
    }

    private static func indexComboRanks(
        _ contributingCombos: [(key: String, aggregateWeight: Double)]
    ) -> [String: Int] {
        var out: [String: Int] = [:]
        for (offset, entry) in contributingCombos.enumerated() {
            out[entry.key] = offset
        }
        return out
    }

    private static func makeComboKey(planet: String?, sign: String?) -> String {
        let p = (planet ?? "unknown").lowercased()
        let s = (sign ?? "unknown").lowercased()
        return "\(p)_\(s)"
    }

    private static func resolveHex(
        name: String,
        library: [String: ColourLibraryEntry]
    ) -> String {
        if let libEntry = library[name] { return libEntry.hex }
        return findClosestColourHex(name: name, library: library) ?? "#808080"
    }

    private static func logPaletteProvenance(
        core: [BlueprintColour],
        accent: [BlueprintColour]
    ) {
        #if DEBUG
        func summarise(_ anchors: [BlueprintColour]) -> String {
            var chart = 0, cross = 0, fallback = 0
            var ranks: [Int] = []
            var maxGap: Double = 0
            for anchor in anchors {
                switch anchor.provenance {
                case let .chartDerived(_, rank, _, gap):
                    chart += 1; ranks.append(rank); maxGap = max(maxGap, gap)
                case let .crossPoolEscalation(_, rank, _, gap, _):
                    cross += 1; ranks.append(rank); maxGap = max(maxGap, gap)
                case .libraryFallback:
                    fallback += 1
                }
            }
            let rankRange: String
            if let lo = ranks.min(), let hi = ranks.max() {
                rankRange = "ranks \(lo)–\(hi)"
            } else {
                rankRange = "no ranks"
            }
            let gapNote = maxGap > 0 ? String(format: "hue-gap %.0f°", maxGap) : "n/a"
            return "\(chart) chart-derived (\(rankRange), \(gapNote)); "
                + "\(cross) cross-pool; \(fallback) fallback"
        }
        print("[Palette] core: \(summarise(core)); accent: \(summarise(accent)).")
        #endif
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
