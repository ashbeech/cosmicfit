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
            analysis: analysis,
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

        return DeterministicResolverResult(
            coreColours: palette.core,
            accentColours: palette.accent,
            swatchFamilies: [],
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

    /// Production path for V4 blueprint composition where palette anchors are
    /// provided exclusively by `ColourEngineV4`. This skips legacy palette
    /// resolution while retaining deterministic non-palette outputs used by
    /// narrative rendering and section content.
    static func resolveNonPalette(
        tokens: [BlueprintToken],
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset,
        contributingCombos: [(key: String, aggregateWeight: Double)]
    ) -> DeterministicResolverResult {
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

        return DeterministicResolverResult(
            coreColours: [],
            accentColours: [],
            swatchFamilies: [],
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

    // MARK: Family-Coherence Parameters (Phase 2/3 — Palette Calibration Programme)
    //
    // The composite score uses additive blending of token weight and family fit:
    //   compositeScore = (1 - familyFitWeight) × weight + familyFitWeight × familyFitScore
    // This lets high-fit colours from lower-weight planets compete with
    // low-fit colours from high-weight planets (e.g. Pluto-sourced oxblood
    // can beat Moon-sourced pearl when the target profile is warm/deep).

    private static let familyFitWeight: Double = 0.6
    private static let crossPoolMinFamilyFit: Double = 0.45
    private static let fallbackMinFamilyFit: Double = 0.35

    private static func resolvePalette(
        tokens: [BlueprintToken],
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset,
        contributingCombos: [(key: String, aggregateWeight: Double)]
    ) -> PaletteResult {
        let colourLibrary = dataset.colourLibrary
        let colourTokens = tokens
            .filter { $0.category == .colour }
            .sorted { tieBreakSort($0, $1) }

        let targetProfile = deriveTargetProfileFromChart(analysis: analysis)

        #if DEBUG
        print("🎨🎨🎨 [Palette/Calibration v2 ADDITIVE] Venus=\(analysis.venusSign) dominant=\(analysis.elementBalance.dominant) sect=\(analysis.chartSect)")
        print("🎨🎨🎨 [Palette/Calibration v2] Target: \(targetProfile.temperature.rawValue)/\(targetProfile.depth.rawValue)/\(targetProfile.chroma.rawValue)")
        print("🎨🎨🎨 [Palette/Calibration v2] Formula: (1-\(familyFitWeight))×weight + \(familyFitWeight)×fit")
        #endif

        let primaryPool = colourTokens.filter { $0.sourceColourRole == .primary }
        let accentPool = colourTokens.filter { $0.sourceColourRole == .accent }

        let sortedPrimaryPool = primaryPool.sorted {
            compositeSortScore($0, library: colourLibrary, target: targetProfile) >
            compositeSortScore($1, library: colourLibrary, target: targetProfile)
        }
        let sortedAccentPool = accentPool.sorted {
            compositeSortScore($0, library: colourLibrary, target: targetProfile) >
            compositeSortScore($1, library: colourLibrary, target: targetProfile)
        }

        func logDeduplicatedPool(_ pool: [BlueprintToken], label: String) {
            var seen = Set<String>()
            var rank = 0
            for t in pool {
                guard rank < 8 else { break }
                if seen.contains(t.name) { continue }
                seen.insert(t.name)
                rank += 1
                let sc = compositeSortScore(t, library: colourLibrary, target: targetProfile)
                let hex = resolveHex(name: t.name, library: colourLibrary)
                let cls = classifyColour(hex: hex, library: colourLibrary, name: t.name)
                let fit = familyFitScore(hex: hex, library: colourLibrary, name: t.name, target: targetProfile)
                print("🎨   \(rank). \(t.name) (\(hex)) w=\(String(format: "%.3f", t.weight)) fit=\(String(format: "%.2f", fit)) composite=\(String(format: "%.3f", sc)) [\(cls.temperature.rawValue)/\(cls.depth.rawValue)/\(cls.chroma.rawValue)] from \(t.planetarySource ?? "?")/\(t.signSource ?? "?")")
            }
        }

        #if DEBUG
        print("🎨 Primary pool top 8 (deduplicated):")
        logDeduplicatedPool(sortedPrimaryPool, label: "Primary")
        print("🎨 Accent pool top 8 (deduplicated):")
        logDeduplicatedPool(sortedAccentPool, label: "Accent")
        #endif

        let comboRankIndex = indexComboRanks(contributingCombos)

        var selected: [BlueprintColour] = []

        // Hue-gap is enforced WITHIN each band, not across bands.
        // A dark burgundy accent next to a bitter chocolate core is
        // desirable — they serve different roles. Sharing hues between
        // bands starves the accent pool when the target profile is
        // warm/deep (all warm colours cluster in 0-30° hue range).
        var coreHues: [Double] = []
        var accentHues: [Double] = []

        // Pass 1 — fill core band from the primary-sourced pool.
        selected += selectAnchors(
            from: sortedPrimaryPool,
            desiredCount: coreDesired,
            role: .core,
            sourceRole: .primary,
            colourLibrary: colourLibrary,
            comboRankIndex: comboRankIndex,
            selectedHues: &coreHues
        )

        // Pass 2 — fill accent band from the accent-sourced pool.
        selected += selectAnchors(
            from: sortedAccentPool,
            desiredCount: accentDesired,
            role: .accent,
            sourceRole: .accent,
            colourLibrary: colourLibrary,
            comboRankIndex: comboRankIndex,
            selectedHues: &accentHues
        )

        // Pass 3 — cross-pool escalation with family-fit gate.
        // Escalation respects per-band hue tracking.
        selected = applyCrossPoolEscalation(
            selected: selected,
            primaryPool: sortedPrimaryPool,
            accentPool: sortedAccentPool,
            colourLibrary: colourLibrary,
            comboRankIndex: comboRankIndex,
            targetProfile: targetProfile,
            coreHues: &coreHues,
            accentHues: &accentHues
        )

        // Pass 4 — library fallback with family-fit gate.
        selected = applyLibraryFallback(
            selected: selected,
            fallbackPool: dataset.fallbackPalettePool ?? [],
            colourLibrary: colourLibrary,
            targetProfile: targetProfile,
            coreHues: &coreHues,
            accentHues: &accentHues
        )

        // Rank-sort (§9.2): ascending by contributorRank; cross-pool and
        // library-fallback entries sort to the end.
        let core = selected
            .filter { $0.role == .core }
            .sorted(by: provenanceRankSort)
        let accent = selected
            .filter { $0.role == .accent }
            .sorted(by: provenanceRankSort)

        #if DEBUG
        print("🎨🎨🎨 === FINAL PALETTE (v2 ADDITIVE, per-band hue-gap) ===")
        for c in core { print("🎨   CORE: \(c.name) (\(c.hexValue)) — \(provenanceSummary(c))") }
        for c in accent { print("🎨   ACCENT: \(c.name) (\(c.hexValue)) — \(provenanceSummary(c))") }
        #endif

        logPaletteProvenance(core: core, accent: accent)
        logFamilyCoherence(targetProfile, core: core, accent: accent, library: colourLibrary)
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
                let info = hueInfoFromHex(hex)

                // Achromatic colours (ink, charcoal, pearl) have meaningless
                // hue and never block or get blocked by hue distance. Only
                // check hue-gap between two chromatic colours.
                if !info.isAchromatic {
                    let tooClose = selectedHues.contains { existing in
                        hueDistance(info.hue, existing) < currentGap
                    }
                    if tooClose { continue }
                }

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
                if !info.isAchromatic {
                    selectedHues.append(info.hue)
                }
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
        targetProfile: ColourFamilyProfile,
        coreHues: inout [Double],
        accentHues: inout [Double]
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
                targetProfile: targetProfile,
                selectedHues: &coreHues
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
                targetProfile: targetProfile,
                selectedHues: &accentHues
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
        targetProfile: ColourFamilyProfile,
        selectedHues: inout [Double]
    ) -> [BlueprintColour] {
        var borrowed: [BlueprintColour] = []
        var blocked = usedNames

        for token in pool where !blocked.contains(token.name) {
            if borrowed.count >= deficit { break }
            let hex = resolveHex(name: token.name, library: colourLibrary)
            let info = hueInfoFromHex(hex)
            if !info.isAchromatic {
                let tooClose = selectedHues.contains { hueDistance($0, info.hue) < 15.0 }
                if tooClose { continue }
            }

            let fit = familyFitScore(hex: hex, library: colourLibrary, name: token.name, target: targetProfile)
            if fit < crossPoolMinFamilyFit { continue }

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
            if !info.isAchromatic {
                selectedHues.append(info.hue)
            }
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
        colourLibrary: [String: ColourLibraryEntry],
        targetProfile: ColourFamilyProfile,
        coreHues: inout [Double],
        accentHues: inout [Double]
    ) -> [BlueprintColour] {
        var result = selected
        let usedNames = Set(result.map(\.name))

        if fallbackPool.isEmpty {
            print("[Resolver] Warning: astrological_style_dataset.json has no fallback_palette_pool; library fallback unavailable.")
            return result
        }

        func padBand(role: ColourRole, minimum: Int, reasonContext: String,
                      hues: inout [Double]) {
            var count = result.filter { $0.role == role }.count
            guard count < minimum else { return }

            for candidate in fallbackPool where candidate.role == role {
                if count >= minimum { break }
                if usedNames.contains(candidate.name) { continue }
                let info = hueInfoFromHex(candidate.hex)
                if !info.isAchromatic {
                    let tooClose = hues.contains { hueDistance($0, info.hue) < 15.0 }
                    if tooClose { continue }
                }

                let fit = familyFitScore(
                    hex: candidate.hex, library: colourLibrary,
                    name: candidate.name, target: targetProfile
                )
                if fit < fallbackMinFamilyFit { continue }

                result.append(BlueprintColour(
                    name: candidate.name,
                    hexValue: candidate.hex,
                    role: role,
                    provenance: .libraryFallback(
                        reason: "\(reasonContext) — padded from fallback_palette_pool"
                    )
                ))
                if !info.isAchromatic {
                    hues.append(info.hue)
                }
                count += 1
            }
        }

        padBand(role: .core, minimum: coreMinimum,
                reasonContext: "core band below minimum after escalation",
                hues: &coreHues)
        padBand(role: .accent, minimum: accentMinimum,
                reasonContext: "accent band below minimum after escalation",
                hues: &accentHues)

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
        case .v4Template:                            return 0
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

    private static func provenanceSummary(_ colour: BlueprintColour) -> String {
        switch colour.provenance {
        case let .chartDerived(comboKey, rank, sourceRole, gap):
            return "\(sourceRole) from \(comboKey) (rank \(rank), gap \(String(format: "%.0f", gap))°)"
        case let .crossPoolEscalation(comboKey, rank, originalRole, gap, reason):
            return "crossPool(\(originalRole)) from \(comboKey) (rank \(rank), gap \(String(format: "%.0f", gap))°) — \(reason)"
        case let .libraryFallback(reason):
            return "fallback — \(reason)"
        case let .v4Template(family, band, index):
            return "v4Template(\(family)/\(band)[\(index)])"
        }
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
                case .v4Template:
                    chart += 1
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

    // MARK: - Family Coherence (Phase 2/3 — Palette Calibration Programme)

    private static let signElements: [String: String] = [
        "Aries": "fire", "Taurus": "earth", "Gemini": "air", "Cancer": "water",
        "Leo": "fire", "Virgo": "earth", "Libra": "air", "Scorpio": "water",
        "Sagittarius": "fire", "Capricorn": "earth", "Aquarius": "air", "Pisces": "water"
    ]

    /// Derives the target palette family from chart-level characteristics
    /// rather than from the colour tokens themselves. This prevents the
    /// feedback loop where a cool/light token pool self-reinforces.
    ///
    /// Signals used:
    /// - **Temperature**: Venus sign element (fire/earth → warm, air → cool,
    ///   water → neutral unless air-dominant → cool)
    /// - **Depth**: chart sect (night → deep, day → medium; earth/water
    ///   dominant nudges day charts toward deep)
    /// - **Chroma**: night charts default muted; day charts use element
    ///   balance (earth/water → muted, fire → moderate, air → moderate)
    private static func deriveTargetProfileFromChart(
        analysis: ChartAnalysis
    ) -> ColourFamilyProfile {
        let venusElement = signElements[analysis.venusSign] ?? "fire"
        let dominant = analysis.elementBalance.dominant
        let isNight = analysis.chartSect == .night

        let temperature: ColourTemperature = {
            switch venusElement {
            case "fire", "earth":
                return .warm
            case "water":
                return dominant == "air" ? .cool : .neutral
            case "air":
                return dominant == "fire" ? .neutral : .cool
            default:
                return .neutral
            }
        }()

        let depth: ColourDepth = {
            if isNight { return .deep }
            if dominant == "earth" || dominant == "water" { return .deep }
            return .medium
        }()

        let chroma: ColourChroma = {
            if isNight { return .muted }
            switch dominant {
            case "earth", "water": return .muted
            case "fire":           return .moderate
            default:               return .moderate
            }
        }()

        return ColourFamilyProfile(temperature: temperature, depth: depth, chroma: chroma)
    }

    /// Classifies a colour using explicit library metadata when available,
    /// falling back to algorithmic derivation from hex.
    private static func classifyColour(
        hex: String,
        library: [String: ColourLibraryEntry],
        name: String
    ) -> ColourFamilyProfile {
        if let entry = library[name],
           let t = entry.temperature, let d = entry.depth, let c = entry.chroma {
            return ColourFamilyProfile(temperature: t, depth: d, chroma: c)
        }
        return deriveProfileFromHex(hex)
    }

    /// Algorithmic classification from hex value. Provides reasonable defaults
    /// for any colour without requiring manual annotation.
    private static func deriveProfileFromHex(_ hex: String) -> ColourFamilyProfile {
        guard let hsl = ColourMath.hexToHSL(hex) else {
            return ColourFamilyProfile(temperature: .neutral, depth: .medium, chroma: .moderate)
        }

        let hueDeg = hsl.h * 360.0
        let sat = hsl.s
        let light = hsl.l

        let temperature: ColourTemperature
        if sat < 0.10 {
            temperature = .neutral
        } else if hueDeg < 75 || hueDeg >= 335 {
            temperature = .warm
        } else if hueDeg >= 170 && hueDeg < 275 {
            temperature = .cool
        } else {
            temperature = .neutral
        }

        let depth: ColourDepth
        if light < 0.35 {
            depth = .deep
        } else if light > 0.65 {
            depth = .light
        } else {
            depth = .medium
        }

        let chroma: ColourChroma
        if sat < 0.25 {
            chroma = .muted
        } else if sat > 0.65 {
            chroma = .bright
        } else {
            chroma = .moderate
        }

        return ColourFamilyProfile(temperature: temperature, depth: depth, chroma: chroma)
    }

    /// Scores how well a colour fits the target profile. Returns 0.0–1.0.
    /// Depth is the heaviest axis (0.30/step) because light↔deep drift is the
    /// primary coherence failure the calibration programme addresses.
    /// Temperature 0.20/step, chroma 0.10/step.
    private static func familyFitScore(
        hex: String,
        library: [String: ColourLibraryEntry],
        name: String,
        target: ColourFamilyProfile
    ) -> Double {
        let profile = classifyColour(hex: hex, library: library, name: name)
        var score = 1.0
        score -= Double(axisDistance(profile.temperature, target.temperature)) * 0.20
        score -= Double(axisDistance(profile.depth, target.depth)) * 0.30
        score -= Double(axisDistance(profile.chroma, target.chroma)) * 0.10
        return max(score, 0.0)
    }

    private static func axisDistance(_ a: ColourTemperature, _ b: ColourTemperature) -> Int {
        let order: [ColourTemperature] = [.warm, .neutral, .cool]
        guard let ai = order.firstIndex(of: a), let bi = order.firstIndex(of: b) else { return 0 }
        return abs(ai - bi)
    }

    private static func axisDistance(_ a: ColourDepth, _ b: ColourDepth) -> Int {
        let order: [ColourDepth] = [.deep, .medium, .light]
        guard let ai = order.firstIndex(of: a), let bi = order.firstIndex(of: b) else { return 0 }
        return abs(ai - bi)
    }

    private static func axisDistance(_ a: ColourChroma, _ b: ColourChroma) -> Int {
        let order: [ColourChroma] = [.muted, .moderate, .bright]
        guard let ai = order.firstIndex(of: a), let bi = order.firstIndex(of: b) else { return 0 }
        return abs(ai - bi)
    }

    /// Composite sort score: additive blend of token weight and family-fit.
    /// Lets deeply relevant colours from outer planets (Pluto, Neptune)
    /// compete with chart-dominant but off-family colours.
    private static func compositeSortScore(
        _ token: BlueprintToken,
        library: [String: ColourLibraryEntry],
        target: ColourFamilyProfile
    ) -> Double {
        let hex = resolveHex(name: token.name, library: library)
        let fit = familyFitScore(hex: hex, library: library, name: token.name, target: target)
        return (1.0 - familyFitWeight) * token.weight + familyFitWeight * fit
    }

    private static func logFamilyCoherence(
        _ profile: ColourFamilyProfile,
        core: [BlueprintColour],
        accent: [BlueprintColour],
        library: [String: ColourLibraryEntry]
    ) {
        #if DEBUG
        print("[Palette] Target family: \(profile.temperature.rawValue)/\(profile.depth.rawValue)/\(profile.chroma.rawValue)")
        for anchor in core + accent {
            let fit = familyFitScore(hex: anchor.hexValue, library: library, name: anchor.name, target: profile)
            let cls = classifyColour(hex: anchor.hexValue, library: library, name: anchor.name)
            print("[Palette]   \(anchor.role.rawValue) \(anchor.name): fit=\(String(format: "%.2f", fit)) (\(cls.temperature.rawValue)/\(cls.depth.rawValue)/\(cls.chroma.rawValue))")
        }
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

    /// Saturation threshold below which a colour is considered achromatic.
    /// Achromatic colours (ink, charcoal, pearl, etc.) have meaningless hue
    /// values and should not block chromatic neighbours on hue distance.
    private static let achromaticSaturationThreshold: Double = 0.12

    private struct HueInfo {
        let hue: Double
        let isAchromatic: Bool
    }

    private static func hueInfoFromHex(_ hex: String) -> HueInfo {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let rgb = UInt32(cleaned, radix: 16) else {
            return HueInfo(hue: 0, isAchromatic: true)
        }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        let saturation = maxC > 0 ? delta / maxC : 0
        let achromatic = saturation < achromaticSaturationThreshold

        guard delta > 0 else { return HueInfo(hue: 0, isAchromatic: true) }

        var hue: Double
        if maxC == r {
            hue = 60.0 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
        } else if maxC == g {
            hue = 60.0 * (((b - r) / delta) + 2)
        } else {
            hue = 60.0 * (((r - g) / delta) + 4)
        }

        if hue < 0 { hue += 360 }
        return HueInfo(hue: hue, isAchromatic: achromatic)
    }

    private static func hueFromHex(_ hex: String) -> Double {
        hueInfoFromHex(hex).hue
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
