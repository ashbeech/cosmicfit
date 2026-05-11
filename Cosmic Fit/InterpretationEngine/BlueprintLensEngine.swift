//
//  BlueprintLensEngine.swift
//  Cosmic Fit
//
//  Phase 3: Stage 2 engine — selects tarot card + style edit variant
//  from a DailyEnergySnapshot. Phase 4 will add palette/texture/assembly.
//

import Foundation

/// Stage 2 engine. Stateless — all methods are static.
/// Takes a DailyEnergySnapshot (Stage 1 output) and selects what the user sees.
enum BlueprintLensEngine {

    // MARK: - Public API

    /// Select a tarot card and style-edit variant for the day.
    /// Records the selection in recency and rotation trackers.
    static func selectTarotAndStyleEdit(
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default
    ) -> (tarotCard: TarotCard, styleEditVariant: StyleEditVariant) {
        let allCards = loadAndNormaliseCards()
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt
        )
        let weights = calibration.selectionWeights
        let vibeVector = buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = buildAxesVector(from: snapshot.axes)

        var scoredCards: [(card: TarotCard, normAxes: [String: Double], score: Double)] = []

        for (card, normAxes) in allCards {
            let vibeScore = cosineSimilarity(card.energyAffinity, vibeVector)
            let axisScore: Double
            if normAxes.isEmpty {
                axisScore = 0.5
            } else {
                axisScore = cosineSimilarity(normAxes, axesVector)
            }
            let transit = transitBoost(
                for: card, dominantTransits: snapshot.dominantTransits
            )
            let recency = recencyPenalty(
                for: card.name, recentSelections: recentSelections
            )
            let total = (vibeScore * weights.vibeWeight)
                      + (axisScore * weights.axisWeight)
                      + (transit * weights.transitBoost)
                      - recency
            scoredCards.append((card, normAxes, total))
        }

        scoredCards.sort { $0.score > $1.score }

        guard let topCandidate = scoredCards.first else {
            let fallback = TarotCard(
                name: "The Fool", imagePath: "Cards/00-TheFool",
                arcana: .major, suit: nil, number: nil,
                keywords: [], themes: [],
                energyAffinity: [:], axesAffinity: nil,
                description: "", reversedKeywords: [],
                symbolism: [], styleEdits: nil
            )
            let variant = selectVariant(for: fallback, profileHash: snapshot.profileHash)
            return (fallback, variant)
        }

        let selected: TarotCard
        if scoredCards.count >= 2,
           abs(topCandidate.score - scoredCards[1].score) < 0.01 {
            let pick = snapshot.dailySeed % 2
            selected = scoredCards[pick].card
        } else {
            selected = topCandidate.card
        }

        TarotRecencyTracker.shared.storeCardSelection(
            selected.name,
            profileHash: snapshot.profileHash,
            date: snapshot.generatedAt
        )

        let variant = selectVariant(for: selected, profileHash: snapshot.profileHash)
        return (selected, variant)
    }

    // MARK: - Card Loading & Normalisation

    private static var cachedCards: [(card: TarotCard, normAxes: [String: Double])]?

    static func loadAndNormaliseCards() -> [(card: TarotCard, normAxes: [String: Double])] {
        if let cached = cachedCards { return cached }

        guard let url = Bundle.main.url(forResource: "TarotCards", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        guard let cards = try? JSONDecoder().decode([TarotCard].self, from: data) else {
            return []
        }

        let normalised: [(TarotCard, [String: Double])] = cards.map { card in
            var normAxes: [String: Double] = [:]
            if let raw = card.axesAffinity {
                for (key, value) in raw {
                    normAxes[key] = value / 100.0
                }
            }
            return (card, normAxes)
        }

        cachedCards = normalised
        return normalised
    }

    /// Allows tests to clear the cached deck so the next call reloads from JSON.
    static func _resetCardCache() {
        cachedCards = nil
    }

    // MARK: - Vibe & Axes Vectors

    /// Normalise the 21-point vibe profile to fractions summing to 1.0.
    /// Divides each energy by 21 — NOT by 100 (legacy bug fix).
    static func buildVibeVector(from vibe: VibeBreakdown) -> [String: Double] {
        var vec: [String: Double] = [:]
        for energy in Energy.allCases {
            vec[energy.rawValue] = Double(vibe.value(for: energy)) / 21.0
        }
        return vec
    }

    /// Normalise snapshot axes (1–10) to 0–1 by dividing by 10.
    static func buildAxesVector(from axes: DerivedAxes) -> [String: Double] {
        [
            "action":     axes.action / 10.0,
            "tempo":      axes.tempo / 10.0,
            "strategy":   axes.strategy / 10.0,
            "visibility": axes.visibility / 10.0,
        ]
    }

    // MARK: - Cosine Similarity

    /// Standard cosine similarity over two sparse [String: Double] vectors.
    /// Returns 0.0 if either vector is the zero vector.
    static func cosineSimilarity(
        _ a: [String: Double], _ b: [String: Double]
    ) -> Double {
        let allKeys = Set(a.keys).union(b.keys)
        var dot = 0.0, magA = 0.0, magB = 0.0
        for key in allKeys {
            let va = a[key] ?? 0.0
            let vb = b[key] ?? 0.0
            dot  += va * vb
            magA += va * va
            magB += vb * vb
        }
        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0.0 }
        return dot / denom
    }

    // MARK: - Transit Boost

    /// Planet-to-energy affinity map (mirrored from DailyEnergyEngine.planetEnergyBase).
    private static let planetEnergyAffinities: [String: [String: Double]] = [
        "Sun":     ["drama": 0.3, "classic": 0.3, "playful": 0.2, "edge": 0.1, "romantic": 0.1],
        "Moon":    ["romantic": 0.4, "classic": 0.2, "playful": 0.2, "drama": 0.1, "utility": 0.1],
        "Mercury": ["playful": 0.3, "utility": 0.3, "classic": 0.2, "edge": 0.2],
        "Venus":   ["romantic": 0.4, "classic": 0.3, "playful": 0.2, "drama": 0.1],
        "Mars":    ["drama": 0.3, "edge": 0.3, "utility": 0.2, "playful": 0.2],
        "Jupiter": ["drama": 0.3, "playful": 0.3, "romantic": 0.2, "classic": 0.2],
        "Saturn":  ["classic": 0.4, "utility": 0.4, "drama": 0.1, "edge": 0.1],
        "Uranus":  ["edge": 0.5, "playful": 0.2, "drama": 0.2, "utility": 0.1],
        "Neptune": ["romantic": 0.4, "edge": 0.3, "drama": 0.2, "playful": 0.1],
        "Pluto":   ["drama": 0.4, "edge": 0.3, "romantic": 0.1, "utility": 0.1, "classic": 0.1],
    ]

    /// Sum of alignment between each dominant transit's planet energies
    /// and the card's energy affinities, weighted by transit strength. Capped at 1.0.
    private static func transitBoost(
        for card: TarotCard,
        dominantTransits: [DailyTransitSummary]
    ) -> Double {
        guard !dominantTransits.isEmpty else { return 0.0 }
        var total = 0.0
        for transit in dominantTransits {
            guard let planetEnergies = planetEnergyAffinities[transit.transitPlanet] else {
                continue
            }
            var alignment = 0.0
            for (energy, planetAff) in planetEnergies {
                let cardAff = card.energyAffinity[energy] ?? 0.0
                alignment += planetAff * cardAff
            }
            total += alignment * transit.strength
        }
        return min(total, 1.0)
    }

    // MARK: - Recency Penalty

    /// 0.3 if shown in last 3 days, 0.15 if in last 7, 0.0 otherwise.
    private static func recencyPenalty(
        for cardName: String,
        recentSelections: [(cardName: String, daysAgo: Int)]
    ) -> Double {
        guard let match = recentSelections.first(where: { $0.cardName == cardName }) else {
            return 0.0
        }
        if match.daysAgo <= 3 { return 0.3 }
        if match.daysAgo <= 7 { return 0.15 }
        return 0.0
    }

    // MARK: - Variant Selection (Rotation-Based)

    /// Selects the next style-edit variant by rotation, not by scoring.
    /// Falls back to a minimal placeholder if the card has no `styleEdits`.
    private static func selectVariant(
        for card: TarotCard, profileHash: String
    ) -> StyleEditVariant {
        guard let edits = card.styleEdits, !edits.isEmpty else {
            return StyleEditVariant(
                variant: "I",
                title: card.name,
                description: "Style guidance inspired by \(card.name).",
                energyEmphasis: [:],
                axesEmphasis: [:],
                dailyRitual: nil,
                wardrobeReflection: nil
            )
        }
        let index = TarotVariantRotationTracker.shared.nextVariantIndex(
            forCard: card.name, profileHash: profileHash
        )
        let safeIndex = index % edits.count
        return edits[safeIndex]
    }

    // MARK: - Phase 4: Full Payload Assembly

    /// Generate the complete DailyFitPayload from Style Guide data (`CosmicBlueprint`) and energy snapshot.
    /// This is the sole public entry point for Stage 2 after Phase 4.
    static func generatePayload(
        blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default
    ) -> DailyFitPayload {
        let (tarotCard, styleEditVariant) = selectTarotAndStyleEdit(
            snapshot: snapshot,
            calibration: calibration
        )
        let palette = selectDailyPalette(from: blueprint.palette, snapshot: snapshot)
        let vibrancy = deriveVibrancy(from: blueprint.palette, snapshot: snapshot)
        let contrast = deriveContrast(from: blueprint.palette, snapshot: snapshot)
        let metalTone = deriveMetalTone(from: blueprint, snapshot: snapshot)
        let essence = deriveStyleEssenceProfile(from: snapshot)
        let silhouette = deriveSilhouetteProfile(from: blueprint, snapshot: snapshot)
        let textures = selectDailyTextures(from: blueprint.textures, snapshot: snapshot)
        let pattern = selectDailyPattern(from: blueprint.pattern, snapshot: snapshot)

        return DailyFitPayload(
            tarotCard: tarotCard,
            styleEditVariant: styleEditVariant,
            dailyPalette: palette,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone,
            essenceProfile: essence,
            silhouetteProfile: silhouette,
            vibeBreakdown: snapshot.vibeProfile,
            axes: snapshot.axes,
            dominantTransits: snapshot.dominantTransits,
            lunarContext: snapshot.lunarContext,
            dailyTextures: textures,
            dailyPattern: pattern,
            generatedAt: snapshot.generatedAt
        )
    }

    // MARK: - Diagnostic Hook (Phase 6)

    /// Internal-only payload generation that also returns intermediate traces.
    struct PayloadTrace {
        let tarotScores: [(cardName: String, vibeScore: Double, axisScore: Double, transitBoost: Double, recencyPenalty: Double, totalScore: Double)]
        let variantRotationIndex: Int
        let paletteTrace: (candidateCount: Int, scoredColours: [(name: String, role: String, score: Double)], diversitySwapApplied: Bool)
        let textureTrace: (available: [String], scores: [(name: String, score: Double)])
        let patternTrace: (gatePassed: Bool, visibilityValue: Double, dominantEnergy: String)
        let vibrancyBaseline: Double
        let vibrancyModulation: Double
        let contrastBaseline: Double
        let contrastModulation: Double
        let metalToneBaseline: Double
        let metalToneModulation: Double
        let silhouetteBaselines: (mf: Double, ar: Double, sd: Double)
    }

    static func generatePayloadWithTrace(
        blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default
    ) -> (payload: DailyFitPayload, trace: PayloadTrace) {
        let allCards = loadAndNormaliseCards()
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(
            profileHash: snapshot.profileHash, referenceDate: snapshot.generatedAt
        )
        let weights = calibration.selectionWeights
        let vibeVector = buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = buildAxesVector(from: snapshot.axes)
        var scoredCards: [(card: TarotCard, normAxes: [String: Double], vibeScore: Double, axisScore: Double, tBoost: Double, rPenalty: Double, total: Double)] = []
        for (card, normAxes) in allCards {
            let vibeScore = cosineSimilarity(card.energyAffinity, vibeVector)
            let axisScore = normAxes.isEmpty ? 0.5 : cosineSimilarity(normAxes, axesVector)
            let tBoost = transitBoost(for: card, dominantTransits: snapshot.dominantTransits)
            let rPenalty = recencyPenalty(for: card.name, recentSelections: recentSelections)
            let total = (vibeScore * weights.vibeWeight) + (axisScore * weights.axisWeight) + (tBoost * weights.transitBoost) - rPenalty
            scoredCards.append((card, normAxes, vibeScore, axisScore, tBoost, rPenalty, total))
        }
        scoredCards.sort { $0.total > $1.total }
        let topScoreEntries = scoredCards.prefix(10).map {
            (cardName: $0.card.name, vibeScore: $0.vibeScore, axisScore: $0.axisScore, transitBoost: $0.tBoost, recencyPenalty: $0.rPenalty, totalScore: $0.total)
        }
        let selected: TarotCard
        if scoredCards.count >= 2, abs(scoredCards[0].total - scoredCards[1].total) < 0.01 {
            selected = scoredCards[snapshot.dailySeed % 2].card
        } else if let first = scoredCards.first {
            selected = first.card
        } else {
            let fallback = TarotCard(
                name: "The Fool", imagePath: "Cards/00-TheFool",
                arcana: .major, suit: nil, number: nil,
                keywords: [], themes: [],
                energyAffinity: [:], axesAffinity: nil,
                description: "", reversedKeywords: [],
                symbolism: [], styleEdits: nil
            )
            let variant = selectVariant(for: fallback, profileHash: snapshot.profileHash)
            let emptyPayload = DailyFitPayload(
                tarotCard: fallback, styleEditVariant: variant,
                dailyPalette: selectDailyPalette(from: blueprint.palette, snapshot: snapshot),
                vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
                essenceProfile: deriveStyleEssenceProfile(from: snapshot),
                silhouetteProfile: deriveSilhouetteProfile(from: blueprint, snapshot: snapshot),
                vibeBreakdown: snapshot.vibeProfile, axes: snapshot.axes,
                dominantTransits: snapshot.dominantTransits,
                lunarContext: snapshot.lunarContext, dailyTextures: [], dailyPattern: nil,
                generatedAt: snapshot.generatedAt
            )
            let emptyTrace = PayloadTrace(
                tarotScores: [], variantRotationIndex: 0,
                paletteTrace: (0, [], false),
                textureTrace: ([], []),
                patternTrace: (false, 0, "classic"),
                vibrancyBaseline: 0.5, vibrancyModulation: 0,
                contrastBaseline: 0.5, contrastModulation: 0,
                metalToneBaseline: 0.5, metalToneModulation: 0,
                silhouetteBaselines: (0.5, 0.5, 0.5)
            )
            return (emptyPayload, emptyTrace)
        }
        TarotRecencyTracker.shared.storeCardSelection(selected.name, profileHash: snapshot.profileHash, date: snapshot.generatedAt)
        let variantIdx = TarotVariantRotationTracker.shared.peekNextVariantIndex(forCard: selected.name, profileHash: snapshot.profileHash)
        let variant = selectVariant(for: selected, profileHash: snapshot.profileHash)

        // Palette trace
        var candidates: [BlueprintColour] = []
        candidates.append(contentsOf: blueprint.palette.coreColours)
        candidates.append(contentsOf: blueprint.palette.accentColours)
        if let n = blueprint.palette.neutrals { candidates.append(contentsOf: n) }
        if let s = blueprint.palette.supportColours { candidates.append(contentsOf: s) }
        if let l = blueprint.palette.luminarySignature { candidates.append(l) }
        if let r = blueprint.palette.rulerSignature { candidates.append(r) }
        let palette = selectDailyPalette(from: blueprint.palette, snapshot: snapshot)
        let paletteHexSet = Set(palette.colours.map(\.hexValue))
        let preSwapTopHexes = Set(candidates.prefix(3).map(\.hexValue))
        let diversitySwap = paletteHexSet != preSwapTopHexes && candidates.count >= 4

        var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
        let vibeTotal = 21.0
        let scoredColours: [(String, String, Double)] = candidates.map { colour in
            let aligned = roleEnergyAlignment[colour.role] ?? [.classic, .romantic]
            let base = aligned.reduce(0.0) { sum, energy in sum + Double(snapshot.vibeProfile.value(for: energy)) / vibeTotal }
            let jitter = Double.random(in: 0..<0.001, using: &rng)
            return (colour.name, colour.role.rawValue, base + jitter)
        }

        // Vibrancy trace
        let vibBaseline: Double
        switch blueprint.palette.variables?.saturation {
        case .soft:  vibBaseline = 0.25
        case .muted: vibBaseline = 0.50
        case .rich:  vibBaseline = 0.75
        case nil:    vibBaseline = 0.50
        }
        let vibe = snapshot.vibeProfile
        let vibPush = Double(vibe.value(for: .drama) + vibe.value(for: .edge)) / 21.0
        let vibPull = Double(vibe.value(for: .utility) + vibe.value(for: .classic)) / 21.0
        let vibMod = (vibPush - vibPull) * 0.15
        let vibrancy = max(0.0, min(1.0, vibBaseline + vibMod))

        // Contrast trace
        let conBaseline: Double
        switch blueprint.palette.variables?.contrast {
        case .low:    conBaseline = 0.25
        case .medium: conBaseline = 0.50
        case .high:   conBaseline = 0.75
        case nil:     conBaseline = 0.50
        }
        let visNorm = snapshot.axes.visibility / 10.0
        let conMod = (visNorm - 0.5) * 0.20
        let contrast = max(0.0, min(1.0, conBaseline + conMod))

        let metalTone = deriveMetalTone(from: blueprint, snapshot: snapshot)
        let tempVal: Double
        switch blueprint.palette.variables?.temperature {
        case .cool:    tempVal = 0.2
        case .neutral: tempVal = 0.5
        case .warm:    tempVal = 0.8
        case nil:      tempVal = 0.5
        }
        var warmCount = 0, coolCount = 0
        for metal in blueprint.hardware.recommendedMetals {
            let lower = metal.lowercased()
            if coolMetals.contains(where: { lower.contains($0) }) { coolCount += 1 }
            else if warmMetals.contains(where: { lower.contains($0) }) { warmCount += 1 }
        }
        let metalLean = Double(warmCount) / Double(max(1, warmCount + coolCount))
        let mtBaseline = tempVal * 0.6 + metalLean * 0.4
        let mtMod = metalTone - mtBaseline

        let essence = deriveStyleEssenceProfile(from: snapshot)
        let silhouette = deriveSilhouetteProfile(from: blueprint, snapshot: snapshot)
        let positives = blueprint.code.leanInto + blueprint.code.consider
        let negatives = blueprint.code.avoid
        let mfBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: mfLeft, rightKeywords: mfRight)
        let arBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: arLeft, rightKeywords: arRight)
        let sdBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: sdLeft, rightKeywords: sdRight)

        let textures = selectDailyTextures(from: blueprint.textures, snapshot: snapshot)
        let axesNorm: [String: Double] = [
            "action": snapshot.axes.action / 10.0, "tempo": snapshot.axes.tempo / 10.0,
            "strategy": snapshot.axes.strategy / 10.0, "visibility": snapshot.axes.visibility / 10.0,
        ]
        let textureScores: [(String, Double)] = blueprint.textures.recommendedTextures.map { texture in
            let lower = texture.lowercased()
            var score = 0.5
            for (keyword, affinities) in textureAxisAffinity {
                if lower.contains(keyword) {
                    score = affinities.reduce(0.0) { $0 + $1.value * (axesNorm[$1.key] ?? 0.5) }
                    break
                }
            }
            return (texture, score)
        }

        let dominant = snapshot.vibeProfile.dominantEnergy
        let gatePassed = snapshot.axes.visibility >= 6.0 && (dominant == .drama || dominant == .playful || dominant == .edge)
        let pattern = selectDailyPattern(from: blueprint.pattern, snapshot: snapshot)

        let payload = DailyFitPayload(
            tarotCard: selected, styleEditVariant: variant,
            dailyPalette: palette, vibrancy: vibrancy, contrast: contrast,
            metalTone: metalTone, essenceProfile: essence,
            silhouetteProfile: silhouette, vibeBreakdown: snapshot.vibeProfile,
            axes: snapshot.axes, dominantTransits: snapshot.dominantTransits,
            lunarContext: snapshot.lunarContext, dailyTextures: textures,
            dailyPattern: pattern, generatedAt: snapshot.generatedAt
        )
        let trace = PayloadTrace(
            tarotScores: Array(topScoreEntries),
            variantRotationIndex: variantIdx,
            paletteTrace: (candidates.count, scoredColours, diversitySwap),
            textureTrace: (blueprint.textures.recommendedTextures, textureScores),
            patternTrace: (gatePassed, snapshot.axes.visibility, dominant.rawValue),
            vibrancyBaseline: vibBaseline, vibrancyModulation: vibMod,
            contrastBaseline: conBaseline, contrastModulation: conMod,
            metalToneBaseline: mtBaseline, metalToneModulation: mtMod,
            silhouetteBaselines: (mfBase, arBase, sdBase)
        )
        return (payload, trace)
    }

    // MARK: - Daily Palette Selection

    /// Maps each ColourRole to the energies it resonates with.
    /// Used to score colours for today's energy profile.
    private static let roleEnergyAlignment: [ColourRole: [Energy]] = [
        .core:      [.classic, .romantic],
        .accent:    [.drama, .playful],
        .neutral:   [.utility, .classic],
        .support:   [.romantic, .playful],
        .signature: [.drama, .edge],
        .statement: [.drama, .edge],
        .anchor:    [.utility, .classic],
    ]

    /// Roles that carry visual punch — reserved for drama-driven days.
    private static let statementRoles: Set<ColourRole> =
        [.accent, .signature, .statement]

    /// Select 3 colours from the Style Guide palette, influenced by today's energy.
    /// Every colour in the output MUST come from the user's PaletteSection.
    ///
    /// Drama-driven slot allocation:
    ///   drama 0–3 → 0 statement, 3 grounding  (quiet day, no accents)
    ///   drama   4 → 1 statement, 2 grounding  (moderate pop)
    ///   drama 5+  → 2 statement, 1 grounding  (bold day, still anchored)
    private static func selectDailyPalette(
        from palette: PaletteSection,
        snapshot: DailyEnergySnapshot
    ) -> DailyPaletteSelection {
        var candidates: [BlueprintColour] = []
        candidates.append(contentsOf: palette.coreColours)
        candidates.append(contentsOf: palette.accentColours)
        if let neutrals = palette.neutrals {
            candidates.append(contentsOf: neutrals)
        }
        if let support = palette.supportColours {
            candidates.append(contentsOf: support)
        }
        if let lum = palette.luminarySignature {
            candidates.append(lum)
        }
        if let ruler = palette.rulerSignature {
            candidates.append(ruler)
        }

        // Luminary + ruler signatures can resolve to the same hex after LCH clamping
        // into the family envelope; template bands can also repeat a hex. Daily picks
        // must never repeat the same colour twice.
        candidates = dedupeCandidatesByHexPreservingOrder(candidates)

        let allHexes = buildAllPaletteHexes(from: palette)

        guard candidates.count >= 3 else {
            let picks = candidates.map {
                DailyColourPick(name: $0.name, hexValue: $0.hexValue,
                                role: $0.role.rawValue)
            }
            return DailyPaletteSelection(
                colours: Array(picks.prefix(3)),
                allPaletteHexes: allHexes
            )
        }

        var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
        let vibeTotal = 21.0

        var scored: [(colour: BlueprintColour, score: Double)] = candidates.map { colour in
            let aligned = roleEnergyAlignment[colour.role] ?? [.classic, .romantic]
            let base = aligned.reduce(0.0) { sum, energy in
                sum + Double(snapshot.vibeProfile.value(for: energy)) / vibeTotal
            }
            let jitter = Double.random(in: 0..<0.001, using: &rng)
            return (colour, base + jitter)
        }
        scored.sort { $0.score > $1.score }

        let statementPool = scored.filter { statementRoles.contains($0.colour.role) }
        let groundingPool = scored.filter { !statementRoles.contains($0.colour.role) }

        let drama = snapshot.vibeProfile.value(for: .drama)
        let maxStatementSlots: Int
        if drama <= 3 {
            maxStatementSlots = 0
        } else if drama <= 4 {
            maxStatementSlots = 1
        } else {
            maxStatementSlots = 2
        }

        let actualStatement = min(maxStatementSlots, statementPool.count)
        let actualGrounding = min(3 - actualStatement, groundingPool.count)

        var selected: [(colour: BlueprintColour, score: Double)] = []
        selected.append(contentsOf: statementPool.prefix(actualStatement))
        selected.append(contentsOf: groundingPool.prefix(actualGrounding))

        if selected.count < 3 {
            let usedHexes = Set(selected.map {
                normalizedPaletteHex($0.colour.hexValue)
            })
            for item in scored {
                if selected.count >= 3 { break }
                let key = normalizedPaletteHex(item.colour.hexValue)
                if !usedHexes.contains(key) {
                    selected.append(item)
                }
            }
        }

        let picks = selected.map {
            DailyColourPick(name: $0.colour.name, hexValue: $0.colour.hexValue,
                            role: $0.colour.role.rawValue)
        }
        return DailyPaletteSelection(colours: picks, allPaletteHexes: allHexes)
    }

    /// Normalises hex for equality (trim, `#`, uppercase).
    private static func normalizedPaletteHex(_ hex: String) -> String {
        let t = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if t.hasPrefix("#") { return t }
        return "#" + t
    }

    /// Keeps the first swatch per hex when building the daily candidate pool.
    private static func dedupeCandidatesByHexPreservingOrder(
        _ colours: [BlueprintColour]
    ) -> [BlueprintColour] {
        var seen = Set<String>()
        var out: [BlueprintColour] = []
        out.reserveCapacity(colours.count)
        for c in colours {
            let key = normalizedPaletteHex(c.hexValue)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            out.append(c)
        }
        return out
    }

    /// Flat array of all hex values from the Style Guide palette for the context ring.
    private static func buildAllPaletteHexes(
        from palette: PaletteSection
    ) -> [String] {
        var hexes: [String] = []
        if let neutrals = palette.neutrals {
            hexes.append(contentsOf: neutrals.map(\.hexValue))
        }
        hexes.append(contentsOf: palette.coreColours.map(\.hexValue))
        hexes.append(contentsOf: palette.accentColours.map(\.hexValue))
        if let support = palette.supportColours {
            hexes.append(contentsOf: support.map(\.hexValue))
        }
        if let lum = palette.luminarySignature {
            hexes.append(lum.hexValue)
        }
        if let ruler = palette.rulerSignature {
            hexes.append(ruler.hexValue)
        }
        return hexes
    }

    // MARK: - Vibrancy Derivation

    /// Blueprint-anchored vibrancy: baseline from Saturation enum, modulated by energy.
    /// Soft Summer stays muted, Deep Autumn stays vibrant — both vary daily.
    private static func deriveVibrancy(
        from palette: PaletteSection,
        snapshot: DailyEnergySnapshot
    ) -> Double {
        let baseline: Double
        switch palette.variables?.saturation {
        case .soft:  baseline = 0.25
        case .muted: baseline = 0.50
        case .rich:  baseline = 0.75
        case nil:    baseline = 0.50
        }
        let vibe = snapshot.vibeProfile
        let push = Double(vibe.value(for: .drama) + vibe.value(for: .edge)) / 21.0
        let pull = Double(vibe.value(for: .utility) + vibe.value(for: .classic)) / 21.0
        let modulation = (push - pull) * 0.15
        return max(0.0, min(1.0, baseline + modulation))
    }

    // MARK: - Contrast Derivation

    /// Blueprint-anchored contrast: baseline from ContrastLevel enum,
    /// modulated by the visibility axis.
    private static func deriveContrast(
        from palette: PaletteSection,
        snapshot: DailyEnergySnapshot
    ) -> Double {
        let baseline: Double
        switch palette.variables?.contrast {
        case .low:    baseline = 0.25
        case .medium: baseline = 0.50
        case .high:   baseline = 0.75
        case nil:     baseline = 0.50
        }
        let visNorm = snapshot.axes.visibility / 10.0
        let modulation = (visNorm - 0.5) * 0.20
        return max(0.0, min(1.0, baseline + modulation))
    }

    // MARK: - Metal Tone Derivation

    private static let warmMetals: Set<String> =
        ["gold", "brass", "copper", "bronze"]
    private static let coolMetals: Set<String> =
        ["silver", "platinum", "pewter", "white gold", "steel"]
    private static let firePlanets: Set<String> =
        ["Mars", "Jupiter", "Sun"]
    private static let waterPlanets: Set<String> =
        ["Moon", "Neptune", "Pluto"]

    /// Blueprint-anchored metal tone: 0.0 = cool, 0.5 = mixed, 1.0 = warm.
    /// Baseline from Temperature enum + recommendedMetals keyword scan,
    /// modulated by fire/water transits and lunar phase.
    private static func deriveMetalTone(
        from blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot
    ) -> Double {
        let tempVal: Double
        switch blueprint.palette.variables?.temperature {
        case .cool:    tempVal = 0.2
        case .neutral: tempVal = 0.5
        case .warm:    tempVal = 0.8
        case nil:      tempVal = 0.5
        }

        var warmCount = 0, coolCount = 0
        for metal in blueprint.hardware.recommendedMetals {
            let lower = metal.lowercased()
            // Check cool first — "white gold" must not false-positive as warm
            if coolMetals.contains(where: { lower.contains($0) }) {
                coolCount += 1
            } else if warmMetals.contains(where: { lower.contains($0) }) {
                warmCount += 1
            }
        }
        let metalLean = Double(warmCount) / Double(max(1, warmCount + coolCount))
        let baseline = tempVal * 0.6 + metalLean * 0.4

        var fireHits = 0, waterHits = 0
        for transit in snapshot.dominantTransits {
            if firePlanets.contains(transit.transitPlanet) { fireHits += 1 }
            if waterPlanets.contains(transit.transitPlanet) { waterHits += 1 }
        }
        let fireNudge = min(Double(fireHits) * 0.05, 0.10)
        let waterNudge = min(Double(waterHits) * 0.05, 0.10)

        let phase = snapshot.lunarContext.phaseName.lowercased()
        let lunarNudge: Double
        if phase.contains("full") {
            lunarNudge = -0.03
        } else if phase.contains("new") {
            lunarNudge = 0.03
        } else {
            lunarNudge = 0.0
        }

        return max(0.0, min(1.0, baseline + fireNudge - waterNudge + lunarNudge))
    }

    // MARK: - Style Essence Profile (14-Category Radar)

    /// Energy-weight matrix: each of the 14 style categories has weighted
    /// affinity to the 6 base energies. Weights per row need not sum to 1;
    /// they express relative sensitivity.
    private static let essenceCategoryWeights: [StyleEssenceCategory: [Energy: Double]] = [
        .edgy:        [.edge: 0.50, .drama: 0.25, .playful: 0.10, .utility: 0.10, .classic: 0.00, .romantic: 0.05],
        .romantic:    [.romantic: 0.50, .classic: 0.20, .drama: 0.15, .playful: 0.10, .edge: 0.00, .utility: 0.05],
        .classic:     [.classic: 0.50, .utility: 0.20, .romantic: 0.15, .drama: 0.05, .playful: 0.05, .edge: 0.05],
        .utility:     [.utility: 0.50, .classic: 0.25, .playful: 0.10, .edge: 0.05, .romantic: 0.05, .drama: 0.05],
        .drama:       [.drama: 0.50, .edge: 0.20, .romantic: 0.15, .playful: 0.10, .classic: 0.05, .utility: 0.00],
        .playful:     [.playful: 0.45, .drama: 0.15, .edge: 0.15, .romantic: 0.10, .utility: 0.10, .classic: 0.05],
        .polished:    [.classic: 0.40, .utility: 0.25, .romantic: 0.15, .drama: 0.10, .edge: 0.00, .playful: 0.10],
        .effortless:  [.playful: 0.35, .utility: 0.30, .romantic: 0.15, .classic: 0.10, .edge: 0.05, .drama: 0.05],
        .sensual:     [.romantic: 0.40, .drama: 0.25, .edge: 0.15, .playful: 0.10, .classic: 0.05, .utility: 0.05],
        .magnetic:    [.drama: 0.35, .romantic: 0.25, .edge: 0.15, .classic: 0.10, .playful: 0.10, .utility: 0.05],
        .grounded:    [.utility: 0.40, .classic: 0.30, .playful: 0.10, .romantic: 0.10, .edge: 0.05, .drama: 0.05],
        .eclectic:    [.playful: 0.30, .edge: 0.25, .drama: 0.20, .romantic: 0.10, .utility: 0.10, .classic: 0.05],
        .minimal:     [.utility: 0.40, .classic: 0.30, .romantic: 0.05, .playful: 0.05, .edge: 0.05, .drama: 0.15],
        .maximalist:  [.drama: 0.40, .playful: 0.25, .edge: 0.15, .romantic: 0.10, .classic: 0.05, .utility: 0.05],
    ]

    /// Axis influence on certain categories. Each entry maps an axis name
    /// to a modifier (positive = boost when axis is high).
    private static let essenceAxisModifiers: [StyleEssenceCategory: [String: Double]] = [
        .polished:    ["strategy": 0.10, "visibility": 0.05],
        .effortless:  ["tempo": 0.10, "action": -0.05],
        .magnetic:    ["visibility": 0.15],
        .grounded:    ["strategy": 0.10, "action": -0.05],
        .eclectic:    ["action": 0.10, "tempo": 0.05],
        .minimal:     ["strategy": 0.10, "visibility": -0.10],
        .maximalist:  ["visibility": 0.15, "action": 0.05],
        .sensual:     ["visibility": 0.10, "tempo": 0.05],
        .drama:       ["visibility": 0.10],
        .edgy:        ["action": 0.10],
    ]

    /// Score all 14 style-essence categories from the snapshot's vibe profile
    /// and axes, then select the top 3. Pure energy readout — not
    /// constrained by Blueprint.
    static func deriveStyleEssenceProfile(
        from snapshot: DailyEnergySnapshot
    ) -> StyleEssenceProfile {
        let v = snapshot.vibeProfile
        let vibeTotal = 21.0
        let normVibe: [Energy: Double] = Dictionary(
            uniqueKeysWithValues: Energy.allCases.map {
                ($0, Double(v.value(for: $0)) / vibeTotal)
            }
        )
        let axesNorm: [String: Double] = [
            "action": snapshot.axes.action / 10.0,
            "tempo": snapshot.axes.tempo / 10.0,
            "strategy": snapshot.axes.strategy / 10.0,
            "visibility": snapshot.axes.visibility / 10.0,
        ]

        var scores: [StyleEssenceScore] = []
        for category in StyleEssenceCategory.allCases {
            let weights = essenceCategoryWeights[category] ?? [:]
            var raw = 0.0
            for energy in Energy.allCases {
                raw += (weights[energy] ?? 0.0) * (normVibe[energy] ?? 0.0)
            }
            if let axisMods = essenceAxisModifiers[category] {
                for (axis, modifier) in axisMods {
                    let axisVal = axesNorm[axis] ?? 0.5
                    raw += modifier * (axisVal - 0.5)
                }
            }
            scores.append(StyleEssenceScore(
                category: category,
                score: max(0.0, min(1.0, raw))
            ))
        }

        let sorted = scores.sorted { $0.score > $1.score }
        let topThree = Array(sorted.prefix(3))

        return StyleEssenceProfile(
            allScores: scores,
            visibleCategories: topThree
        )
    }

    // MARK: - Silhouette Profile Derivation

    // Keyword → axis maps for CodeSection directive scanning.
    // Left keywords push toward 0.0, right keywords push toward 1.0.
    // Documented here for maintainability — these are the only structured
    // signals available for silhouette baseline (StyleCoreSection has only
    // narrativeText which cannot be reliably parsed).
    private static let mfLeft =
        ["masculine", "sharp", "tailored", "utilitarian", "rugged"]
    private static let mfRight =
        ["feminine", "delicate", "graceful", "flowing", "soft"]
    private static let arLeft =
        ["angular", "geometric", "structured", "square", "pointed"]
    private static let arRight =
        ["rounded", "curved", "soft", "organic", "draped"]
    private static let sdLeft =
        ["structured", "tailored", "crisp", "stiff", "architectural"]
    private static let sdRight =
        ["draped", "relaxed", "loose", "fluid", "unstructured"]

    /// Blueprint-dominated silhouette with small axes modulation.
    /// Baseline (~75%) from CodeSection keyword scanning;
    /// modulation (~25%) from action/visibility/strategy axes.
    private static func deriveSilhouetteProfile(
        from blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot
    ) -> SilhouetteProfile {
        let positives = blueprint.code.leanInto + blueprint.code.consider
        let negatives = blueprint.code.avoid

        let mfBase = keywordBaseline(
            positives: positives, negatives: negatives,
            leftKeywords: mfLeft, rightKeywords: mfRight
        )
        let arBase = keywordBaseline(
            positives: positives, negatives: negatives,
            leftKeywords: arLeft, rightKeywords: arRight
        )
        let sdBase = keywordBaseline(
            positives: positives, negatives: negatives,
            leftKeywords: sdLeft, rightKeywords: sdRight
        )

        let visNorm = snapshot.axes.visibility / 10.0
        let actNorm = snapshot.axes.action / 10.0
        let strNorm = snapshot.axes.strategy / 10.0

        return SilhouetteProfile(
            masculineFeminine: max(0.0, min(1.0,
                mfBase + (visNorm - 0.5) * 0.25)),
            angularRounded: max(0.0, min(1.0,
                arBase + (actNorm - 0.5) * -0.20)),
            structuredDraped: max(0.0, min(1.0,
                sdBase + (strNorm - 0.5) * -0.25))
        )
    }

    /// Compute a 0.0–1.0 baseline from keyword scanning of CodeSection directives.
    /// Positive directives (leanInto, consider): left keywords → leftHits, right → rightHits.
    /// Negative directives (avoid): left keywords → rightHits, right → leftHits.
    /// Returns 0.5 (neutral) when no keywords match.
    private static func keywordBaseline(
        positives: [String],
        negatives: [String],
        leftKeywords: [String],
        rightKeywords: [String]
    ) -> Double {
        var leftHits = 0, rightHits = 0
        for directive in positives {
            let lower = directive.lowercased()
            for kw in leftKeywords where lower.contains(kw) { leftHits += 1 }
            for kw in rightKeywords where lower.contains(kw) { rightHits += 1 }
        }
        for directive in negatives {
            let lower = directive.lowercased()
            for kw in leftKeywords where lower.contains(kw) { rightHits += 1 }
            for kw in rightKeywords where lower.contains(kw) { leftHits += 1 }
        }
        let total = leftHits + rightHits
        guard total > 0 else { return 0.5 }
        return Double(rightHits) / Double(total)
    }

    // MARK: - Daily Texture Selection

    /// Keyword-to-axis affinity map for scoring Blueprint textures against daily axes.
    private static let textureAxisAffinity: [String: [String: Double]] = [
        "silk":      ["visibility": 0.8, "tempo": 0.6],
        "velvet":    ["visibility": 0.9, "action": 0.3],
        "cashmere":  ["strategy": 0.4, "tempo": 0.3],
        "linen":     ["action": 0.5, "tempo": 0.4],
        "leather":   ["action": 0.8, "strategy": 0.7, "visibility": 0.6],
        "denim":     ["action": 0.7, "strategy": 0.6],
        "wool":      ["strategy": 0.5],
        "cotton":    ["action": 0.6, "tempo": 0.5],
        "suede":     ["visibility": 0.5, "strategy": 0.4],
        "tweed":     ["strategy": 0.8, "visibility": 0.4],
        "satin":     ["visibility": 0.7, "tempo": 0.6],
        "jersey":    ["action": 0.7, "tempo": 0.7],
        "chiffon":   ["visibility": 0.6, "tempo": 0.5],
        "corduroy":  ["strategy": 0.6, "action": 0.4],
    ]

    /// Select 2–3 textures from the Blueprint's recommended list based on axes.
    /// Every texture in the output comes from the Blueprint — no invented values.
    private static func selectDailyTextures(
        from textures: TexturesSection,
        snapshot: DailyEnergySnapshot
    ) -> [String] {
        let axesNorm: [String: Double] = [
            "action":     snapshot.axes.action / 10.0,
            "tempo":      snapshot.axes.tempo / 10.0,
            "strategy":   snapshot.axes.strategy / 10.0,
            "visibility": snapshot.axes.visibility / 10.0,
        ]

        var scored: [(String, Double)] = textures.recommendedTextures.map { texture in
            let lower = texture.lowercased()
            var score = 0.5
            for (keyword, affinities) in textureAxisAffinity {
                if lower.contains(keyword) {
                    score = affinities.reduce(0.0) {
                        $0 + $1.value * (axesNorm[$1.key] ?? 0.5)
                    }
                    break
                }
            }
            return (texture, score)
        }
        scored.sort { $0.1 > $1.1 }

        guard scored.count >= 2 else { return scored.map(\.0) }
        let takeThree = scored.count >= 3
            && scored[2].1 >= scored[1].1 * 0.8
        return Array(scored.prefix(takeThree ? 3 : 2)).map(\.0)
    }

    // MARK: - Daily Pattern Selection

    /// Keyword affinities for gating patterns to the dominant energy.
    private static let patternEnergyKeywords: [Energy: [String]] = [
        .drama:   ["stripe", "animal", "bold", "large", "geometric"],
        .playful: ["polka", "gingham", "dot", "colour", "color",
                   "fun", "check"],
        .edge:    ["abstract", "asymmetric", "mixed", "deconstructed"],
    ]

    /// Optionally select a pattern — only when energy calls for it.
    /// Gate: visibility ≥ 6.0 AND dominant energy is Drama, Playful, or Edge.
    private static func selectDailyPattern(
        from patterns: PatternSection,
        snapshot: DailyEnergySnapshot
    ) -> String? {
        let dominant = snapshot.vibeProfile.dominantEnergy
        guard snapshot.axes.visibility >= 6.0,
              dominant == .drama || dominant == .playful || dominant == .edge
        else { return nil }
        guard !patterns.recommendedPatterns.isEmpty else { return nil }

        let keywords = patternEnergyKeywords[dominant] ?? []
        var scored: [(String, Double)] = patterns.recommendedPatterns.map { pattern in
            let lower = pattern.lowercased()
            let score = keywords.reduce(0.0) {
                $0 + (lower.contains($1) ? 1.0 : 0.0)
            }
            return (pattern, score)
        }
        scored.sort { $0.1 > $1.1 }

        let topScore = scored[0].1
        let tied = scored.filter { $0.1 == topScore }
        if tied.count > 1 {
            var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
            let idx = Int.random(in: 0..<tied.count, using: &rng)
            return tied[idx].0
        }
        return scored[0].0
    }

    // MARK: - Console Diagnostics

    #if DEBUG
    /// Prints a comprehensive Daily Fit pipeline trace to the console,
    /// matching the format used by BlueprintComposer's decision tree diagnostics.
    /// Call after payload generation to see inputs, processing, and outputs.
    static func logDailyFitDiagnostics(
        snapshot: DailyEnergySnapshot,
        payload: DailyFitPayload,
        blueprint: CosmicBlueprint
    ) {
        let p = "[DailyFitDiag]"
        let f2 = { (v: Double) -> String in String(format: "%.2f", v) }
        let f3 = { (v: Double) -> String in String(format: "%.3f", v) }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMM yyyy"
        let dateStr = dateFormatter.string(from: payload.generatedAt)

        print("\(p) ╔══════════════════════════════════════════════════════════════")
        print("\(p) ║  DAILY FIT PIPELINE — FULL DIAGNOSTIC")
        print("\(p) ║  \(dateStr)  ·  seed \(snapshot.dailySeed)")
        print("\(p) ╚══════════════════════════════════════════════════════════════")

        // ── 1. ENERGY SNAPSHOT (Stage 1 Output) ──
        print("\(p)")
        print("\(p) ── 1. ENERGY SNAPSHOT ──────────────────────────────────────")
        let cal = DailyFitCalibration.default
        let sw = cal.sourceWeights
        print("\(p) Source weights: natal=\(f2(sw.natal)) transits=\(f2(sw.transits)) lunar=\(f2(sw.lunarPhase)) progressed=\(f2(sw.progressed)) currentSun=\(f2(sw.currentSun))")
        let vibe = snapshot.vibeProfile
        print("\(p) Vibe profile (21-point budget, total=\(vibe.totalPoints)):")
        let energies: [(String, Int)] = [
            ("Classic", vibe.classic), ("Playful", vibe.playful),
            ("Romantic", vibe.romantic), ("Utility", vibe.utility),
            ("Drama", vibe.drama), ("Edge", vibe.edge)
        ]
        for (name, value) in energies {
            let bar = String(repeating: "█", count: value) + String(repeating: "░", count: 10 - value)
            print("\(p)   \(name.padding(toLength: 10, withPad: " ", startingAt: 0)) \(bar) \(value)/10")
        }
        print("\(p) Dominant energy: \(vibe.dominantEnergy.rawValue)")

        // Axes
        print("\(p)")
        print("\(p) Derived axes (1–10 scale):")
        let axes = snapshot.axes
        let axesList: [(String, Double)] = [
            ("Action", axes.action), ("Tempo", axes.tempo),
            ("Strategy", axes.strategy), ("Visibility", axes.visibility)
        ]
        for (name, value) in axesList {
            let filled = Int(value)
            let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: 10 - filled)
            print("\(p)   \(name.padding(toLength: 12, withPad: " ", startingAt: 0)) \(bar) \(f2(value))")
        }

        // Transits
        print("\(p)")
        print("\(p) Active transits (\(snapshot.dominantTransits.count)):")
        if snapshot.dominantTransits.isEmpty {
            print("\(p)   (none)")
        } else {
            for t in snapshot.dominantTransits {
                print("\(p)   \(t.transitPlanet) \(t.aspect) \(t.natalPlanet)  strength=\(f2(t.strength))")
            }
        }

        // Lunar
        print("\(p)")
        print("\(p) Lunar context:")
        let lc = snapshot.lunarContext
        print("\(p)   Phase: \(lc.phaseName) (\(lc.isWaxing ? "waxing" : "waning"))  element=\(lc.element)  degrees=\(f2(lc.phaseDegrees))")

        // ── 2. TAROT CARD SELECTION ──
        print("\(p)")
        print("\(p) ── 2. TAROT CARD SELECTION ─────────────────────────────────")
        let allCards = loadAndNormaliseCards()
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(
            profileHash: snapshot.profileHash, referenceDate: snapshot.generatedAt
        )
        let vibeVector = buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = buildAxesVector(from: snapshot.axes)
        let weights = DailyFitCalibration.default.selectionWeights

        var scoredForLog: [(name: String, vibe: Double, axis: Double, transit: Double, recency: Double, total: Double)] = []
        for (card, normAxes) in allCards {
            let vibeScore = cosineSimilarity(card.energyAffinity, vibeVector)
            let axisScore = normAxes.isEmpty ? 0.5 : cosineSimilarity(normAxes, axesVector)
            let tBoost = transitBoost(for: card, dominantTransits: snapshot.dominantTransits)
            let rPenalty = recencyPenalty(for: card.name, recentSelections: recentSelections)
            let total = (vibeScore * weights.vibeWeight) + (axisScore * weights.axisWeight) + (tBoost * weights.transitBoost) - rPenalty
            scoredForLog.append((card.name, vibeScore, axisScore, tBoost, rPenalty, total))
        }
        scoredForLog.sort { $0.total > $1.total }

        print("\(p) Selection weights: vibe=\(f2(weights.vibeWeight)) axis=\(f2(weights.axisWeight)) transitBoost=\(f2(weights.transitBoost))")
        print("\(p) Top 10 candidates:")
        for (i, entry) in scoredForLog.prefix(10).enumerated() {
            let marker = entry.name == payload.tarotCard.name ? "→" : " "
            let recStr = entry.recency > 0 ? " penalty=\(f2(entry.recency))" : ""
            print("\(p) \(marker) #\(String(i + 1).padding(toLength: 2, withPad: " ", startingAt: 0)) \(entry.name.padding(toLength: 24, withPad: " ", startingAt: 0)) vibe=\(f3(entry.vibe)) axis=\(f3(entry.axis)) transit=\(f3(entry.transit))\(recStr)  TOTAL=\(f3(entry.total))")
        }

        print("\(p)")
        print("\(p) ✦ Selected: \(payload.tarotCard.name)")
        print("\(p)   Style edit: \"\(payload.styleEditVariant.title)\" (variant \(payload.styleEditVariant.variant))")
        if let ritual = payload.styleEditVariant.dailyRitual {
            print("\(p)   Daily ritual: \"\(String(ritual.prefix(80)))\(ritual.count > 80 ? "…" : "")\"")
        } else {
            print("\(p)   Daily ritual: (none)")
        }
        if let reflection = payload.styleEditVariant.wardrobeReflection {
            print("\(p)   Wardrobe reflection: \"\(String(reflection.prefix(80)))\(reflection.count > 80 ? "…" : "")\"")
        } else {
            print("\(p)   Wardrobe reflection: (none)")
        }

        // ── 3. COLOUR PALETTE ──
        print("\(p)")
        print("\(p) ── 3. COLOUR PALETTE ───────────────────────────────────────")
        print("\(p) Style Guide palette family: \(blueprint.palette.family?.rawValue ?? "(none)")")
        let drama = snapshot.vibeProfile.value(for: .drama)
        let slotLabel: String
        if drama <= 3 { slotLabel = "0 statement / 3 grounding (quiet)" }
        else if drama <= 4 { slotLabel = "1 statement / 2 grounding (moderate)" }
        else { slotLabel = "2 statement / 1 grounding (bold)" }
        print("\(p) Drama=\(drama) → slot allocation: \(slotLabel)")
        print("\(p) Daily picks (\(payload.dailyPalette.colours.count)):")
        for (i, colour) in payload.dailyPalette.colours.enumerated() {
            print("\(p)   \(i + 1). \(colour.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(colour.hexValue)  role=\(colour.role)")
        }
        print("\(p) Full palette hexes: \(payload.dailyPalette.allPaletteHexes.count) colours available")

        // ── 4. STYLE PALETTE SCALES ──
        print("\(p)")
        print("\(p) ── 4. STYLE PALETTE SCALES ─────────────────────────────────")

        let satLabel: String = blueprint.palette.variables.map { "\($0.saturation)" } ?? "nil"
        let conLabel: String = blueprint.palette.variables.map { "\($0.contrast)" } ?? "nil"
        let tempLabel: String = blueprint.palette.variables.map { "\($0.temperature)" } ?? "nil"

        let vibBaseline: Double
        switch blueprint.palette.variables?.saturation {
        case .soft:  vibBaseline = 0.25
        case .muted: vibBaseline = 0.50
        case .rich:  vibBaseline = 0.75
        case nil:    vibBaseline = 0.50
        }
        let vibPush = Double(vibe.value(for: .drama) + vibe.value(for: .edge)) / 21.0
        let vibPull = Double(vibe.value(for: .utility) + vibe.value(for: .classic)) / 21.0
        let vibMod = (vibPush - vibPull) * 0.15

        print("\(p) Vibrancy:")
        print("\(p)   Style Guide saturation: \(satLabel) → baseline=\(f2(vibBaseline))")
        print("\(p)   Push (drama+edge)/21 = \(f3(vibPush))   Pull (utility+classic)/21 = \(f3(vibPull))")
        print("\(p)   Modulation: (\(f3(vibPush)) - \(f3(vibPull))) × 0.15 = \(f3(vibMod))")
        print("\(p)   Final: \(f2(vibBaseline)) + \(f3(vibMod)) = \(f3(payload.vibrancy))")

        let conBaseline: Double
        switch blueprint.palette.variables?.contrast {
        case .low:    conBaseline = 0.25
        case .medium: conBaseline = 0.50
        case .high:   conBaseline = 0.75
        case nil:     conBaseline = 0.50
        }
        let visNorm = axes.visibility / 10.0
        let conMod = (visNorm - 0.5) * 0.20

        print("\(p) Contrast:")
        print("\(p)   Style Guide contrast: \(conLabel) → baseline=\(f2(conBaseline))")
        print("\(p)   Visibility axis normalised: \(f3(visNorm))")
        print("\(p)   Modulation: (\(f3(visNorm)) - 0.5) × 0.20 = \(f3(conMod))")
        print("\(p)   Final: \(f2(conBaseline)) + \(f3(conMod)) = \(f3(payload.contrast))")

        let tempVal: Double
        switch blueprint.palette.variables?.temperature {
        case .cool:    tempVal = 0.2
        case .neutral: tempVal = 0.5
        case .warm:    tempVal = 0.8
        case nil:      tempVal = 0.5
        }
        var warmCount = 0, coolCount = 0
        for metal in blueprint.hardware.recommendedMetals {
            let lower = metal.lowercased()
            if coolMetals.contains(where: { lower.contains($0) }) { coolCount += 1 }
            else if warmMetals.contains(where: { lower.contains($0) }) { warmCount += 1 }
        }
        let metalLean = Double(warmCount) / Double(max(1, warmCount + coolCount))
        let mtBaseline = tempVal * 0.6 + metalLean * 0.4

        print("\(p) Metal tone (0=cool, 1=warm):")
        print("\(p)   Style Guide temperature: \(tempLabel) → tempVal=\(f2(tempVal))")
        print("\(p)   Metals: warm=\(warmCount) cool=\(coolCount) → lean=\(f2(metalLean))")
        print("\(p)   Baseline: \(f2(tempVal))×0.6 + \(f2(metalLean))×0.4 = \(f3(mtBaseline))")
        print("\(p)   Final (after transit/lunar nudge): \(f3(payload.metalTone))")

        // ── 5. STYLE ESSENCE (14-Category Radar) ──
        print("\(p)")
        print("\(p) ── 5. STYLE ESSENCE (14-CATEGORY RADAR) ────────────────────")
        let ep = payload.essenceProfile
        print("\(p) All 14 categories (sorted by score):")
        let sortedEssences = ep.allScores.sorted { $0.score > $1.score }
        for (i, entry) in sortedEssences.enumerated() {
            let marker = ep.visibleCategories.contains(where: { $0.category == entry.category }) ? "★" : " "
            let bar = String(repeating: "█", count: Int(entry.score * 20)) + String(repeating: "░", count: 20 - Int(entry.score * 20))
            print("\(p) \(marker) #\(String(i + 1).padding(toLength: 2, withPad: " ", startingAt: 0)) \(entry.category.label.padding(toLength: 12, withPad: " ", startingAt: 0)) \(bar) \(f3(entry.score))")
        }
        print("\(p) Top 3 displayed: \(ep.visibleCategories.map { "\($0.category.label)=\(f3($0.score))" }.joined(separator: "  ·  "))")

        // ── 6. SILHOUETTE PROFILE ──
        print("\(p)")
        print("\(p) ── 6. SILHOUETTE PROFILE ───────────────────────────────────")
        let sp = payload.silhouetteProfile
        let positives = blueprint.code.leanInto + blueprint.code.consider
        let negatives = blueprint.code.avoid

        let mfBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: mfLeft, rightKeywords: mfRight)
        let arBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: arLeft, rightKeywords: arRight)
        let sdBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: sdLeft, rightKeywords: sdRight)

        let actNorm = axes.action / 10.0
        let strNorm = axes.strategy / 10.0

        print("\(p)   Masculine ← → Feminine:")
        print("\(p)     Baseline (keyword scan): \(f3(mfBase))  +  (vis \(f2(visNorm)) - 0.5) × 0.25 = \(f3(sp.masculineFeminine))")
        print("\(p)   Angular ← → Rounded:")
        print("\(p)     Baseline (keyword scan): \(f3(arBase))  +  (act \(f2(actNorm)) - 0.5) × -0.20 = \(f3(sp.angularRounded))")
        print("\(p)   Structured ← → Draped:")
        print("\(p)     Baseline (keyword scan): \(f3(sdBase))  +  (str \(f2(strNorm)) - 0.5) × -0.25 = \(f3(sp.structuredDraped))")

        // ── 7. TEXTURES ──
        print("\(p)")
        print("\(p) ── 7. TEXTURES ─────────────────────────────────────────────")
        print("\(p) Style Guide recommends: \(blueprint.textures.recommendedTextures.joined(separator: ", "))")
        print("\(p) Daily selection: \(payload.dailyTextures.joined(separator: ", "))")

        // ── 8. PATTERN ──
        print("\(p)")
        print("\(p) ── 8. PATTERN ──────────────────────────────────────────────")
        let dominant = vibe.dominantEnergy
        let gatePassed = axes.visibility >= 6.0 && (dominant == .drama || dominant == .playful || dominant == .edge)
        print("\(p) Gate check: visibility=\(f2(axes.visibility)) dominant=\(dominant.rawValue) → \(gatePassed ? "PASSED" : "BLOCKED")")
        if let pat = payload.dailyPattern {
            print("\(p) Selected pattern: \(pat)")
        } else {
            print("\(p) No pattern selected (gate blocked or no candidates)")
        }

        // ── 9. PAYLOAD SUMMARY ──
        print("\(p)")
        print("\(p) ╔══════════════════════════════════════════════════════════════")
        print("\(p) ║  PAYLOAD SUMMARY")
        print("\(p) ╠══════════════════════════════════════════════════════════════")
        print("\(p) ║  Tarot:       \(payload.tarotCard.name) — \(payload.styleEditVariant.title)")
        print("\(p) ║  Colours:     \(payload.dailyPalette.colours.map { "\($0.name) (\($0.hexValue))" }.joined(separator: "  ·  "))")
        print("\(p) ║  Vibrancy:    \(f2(payload.vibrancy))   Contrast: \(f2(payload.contrast))   Metal tone: \(f2(payload.metalTone))")
        print("\(p) ║  Essence:     \(ep.visibleCategories.map { "\($0.category.label)=\(f2($0.score))" }.joined(separator: "  "))")
        print("\(p) ║  Silhouette:  M/F=\(f2(sp.masculineFeminine))  A/R=\(f2(sp.angularRounded))  S/D=\(f2(sp.structuredDraped))")
        print("\(p) ║  Textures:    \(payload.dailyTextures.joined(separator: ", "))")
        print("\(p) ║  Pattern:     \(payload.dailyPattern ?? "(none)")")
        print("\(p) ║  Ritual:      \(payload.styleEditVariant.dailyRitual != nil ? "yes" : "none")")
        print("\(p) ║  Reflection:  \(payload.styleEditVariant.wardrobeReflection != nil ? "yes" : "none")")
        print("\(p) ╚══════════════════════════════════════════════════════════════")
    }
    #endif
}
