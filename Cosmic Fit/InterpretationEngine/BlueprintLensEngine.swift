//
//  BlueprintLensEngine.swift
//  Cosmic Fit
//
//  Phase 3: Stage 2 engine — selects tarot card + style edit variant
//  from a DailyEnergySnapshot. Phase 4 will add palette/texture/assembly.
//

import Foundation

/// Shared scale sensitivity constants for Stage-1 Experimental mode.
/// Single source of truth for both derivation (BlueprintLensEngine) and
/// envelope bounds (PersonalScaleEnvelopeCalculator).
enum Stage1ScaleSensitivity {
    // Vibrancy — vibe push/pull and tempo axis modulation scales
    static let vibeScale: Double = 0.80
    static let tempoScale: Double = 0.30
    static let tempoNormMin: Double = 0.1
    static let tempoNormMax: Double = 1.0

    // Contrast — axis blend weights for Stage 1 two-axis formula
    static let contrastVisWeight: Double = 0.6
    static let contrastStrWeight: Double = 0.4
    /// Mathematical max of |(visNorm-0.5)*visW + (strNorm-0.5)*strW| for envelope bounds.
    /// visNorm ∈ [0.1, 1.0] → (visNorm-0.5) max = 0.5; same for strNorm.
    /// Max positive blend = 0.5*0.6 + 0.5*0.4 = 0.50.
    static let contrastMaxBlendNorm: Double = 0.50

    // Metal tone — transit and lunar nudge bounds
    static let metalNudgeCap: Double = 0.30
    static let metalNudgeCapStandard: Double = 0.10
    static let lunarNamedPhaseNudge: Double = 0.03
    static let lunarDegreeScale: Double = 0.15
    /// Maximum absolute contribution from lunar degree mod: |((0 or 1) - 0.5) * lunarDegreeScale|
    static var lunarDegreeMaxAbs: Double { lunarDegreeScale * 0.5 }
}

/// Stage 2 engine. Stateless — all methods are static.
/// Takes a DailyEnergySnapshot (Stage 1 output) and selects what the user sees.
enum BlueprintLensEngine {

    // MARK: - Engine id resolution (P3 namespacing)

    private static func dailyFitEngineId(
        for calibration: DailyFitCalibration,
        mode: DailyFitEngineMode = .standard
    ) -> String {
        DailyFitEngineRegistry.engineId(for: calibration, mode: mode)
    }

    // MARK: - Public API

    /// Select a tarot card and style-edit variant for the day.
    /// Records the selection in recency and rotation trackers.
    /// When narrativeIntent is non-nil, uses joint (card, variant) bridge selection.
    static func selectTarotAndStyleEdit(
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        dailyFitEngineId explicitEngineId: String? = nil,
        narrativeIntent: NarrativeIntent? = nil
    ) -> (tarotCard: TarotCard, styleEditVariant: StyleEditVariant) {
        let result = selectTarotAndStyleEditWithBridgeTrace(
            snapshot: snapshot,
            calibration: calibration,
            dailyFitEngineId: explicitEngineId,
            narrativeIntent: narrativeIntent
        )
        return (result.card, result.variant)
    }

    struct TarotSelectionResult {
        let card: TarotCard
        let variant: StyleEditVariant
        let variantWasScored: Bool
        let rotationIndex: Int
        let bridgeTrace: NarrativeBridgeTrace?
        let categoryBoostApplied: Bool
    }

    /// Unified tarot+variant selection used by both generatePayload and generatePayloadWithTrace.
    static func selectTarotAndStyleEditWithBridgeTrace(
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        dailyFitEngineId explicitEngineId: String? = nil,
        narrativeIntent: NarrativeIntent? = nil
    ) -> TarotSelectionResult {
        let engineId = explicitEngineId ?? dailyFitEngineId(for: calibration)
        let allCards = loadAndNormaliseCards()
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt,
            dailyFitEngineId: engineId
        )

        // Stage-1 narrative bridge path: joint (card, variant) selection
        if let intent = narrativeIntent, calibration.narrativeSelection != nil {
            let bridgeResult = NarrativeTarotBridgeSelector.select(
                snapshot: snapshot,
                allCards: allCards,
                recentSelections: recentSelections,
                intent: intent,
                calibration: calibration,
                dailySeed: snapshot.dailySeed
            )

            TarotRecencyTracker.shared.storeCardSelection(
                bridgeResult.candidate.card.name,
                profileHash: snapshot.profileHash,
                date: snapshot.generatedAt,
                dailyFitEngineId: engineId
            )

            return TarotSelectionResult(
                card: bridgeResult.candidate.card,
                variant: bridgeResult.candidate.variant,
                variantWasScored: true,
                rotationIndex: bridgeResult.candidate.variantIndex,
                bridgeTrace: bridgeResult.bridgeTrace,
                categoryBoostApplied: true
            )
        }

        // Production / nil-intent path: existing card-first selection (unchanged)
        let weights = calibration.selectionWeights
        let vibeVector = buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = buildAxesVector(from: snapshot.axes)

        var scoredCards: [(card: TarotCard, normAxes: [String: Double], score: Double)] = []

        for (card, normAxes) in allCards {
            let breakdown = TarotCardScoring.scoreCard(
                card: card, normAxes: normAxes,
                vibeVector: vibeVector, axesVector: axesVector,
                weights: weights,
                recentSelections: recentSelections,
                dominantTransits: snapshot.dominantTransits
            )
            scoredCards.append((card, normAxes, breakdown.total))
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
            let variantResult = selectVariant(
                for: fallback, profileHash: snapshot.profileHash,
                dailyFitEngineId: engineId, narrativeIntent: nil,
                dailySeed: snapshot.dailySeed
            )
            return TarotSelectionResult(
                card: fallback, variant: variantResult.variant,
                variantWasScored: false, rotationIndex: 0,
                bridgeTrace: nil, categoryBoostApplied: false
            )
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
            date: snapshot.generatedAt,
            dailyFitEngineId: engineId
        )

        let variantResult = selectVariant(
            for: selected, profileHash: snapshot.profileHash,
            dailyFitEngineId: engineId, narrativeIntent: nil,
            dailySeed: snapshot.dailySeed
        )
        return TarotSelectionResult(
            card: selected, variant: variantResult.variant,
            variantWasScored: false, rotationIndex: variantResult.rotationIndex,
            bridgeTrace: nil, categoryBoostApplied: false
        )
    }

    // MARK: - Card Loading & Normalisation

    private static var cachedCards: [(card: TarotCard, normAxes: [String: Double])]?
    private static var tarotCardsURLOverride: URL?

    /// Used by the inspector server where Bundle.main does not include TarotCards.json.
    static func setTarotCardsURL(_ url: URL) {
        tarotCardsURLOverride = url
        cachedCards = nil
    }

    static func loadAndNormaliseCards() -> [(card: TarotCard, normAxes: [String: Double])] {
        if let cached = cachedCards { return cached }

        let url = tarotCardsURLOverride
            ?? Bundle.main.url(forResource: "TarotCards", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else {
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

    // MARK: - Transit Boost / Recency Penalty (forwarded to TarotCardScoring)

    private static func transitBoost(
        for card: TarotCard,
        dominantTransits: [DailyTransitSummary]
    ) -> Double {
        TarotCardScoring.transitBoost(for: card, dominantTransits: dominantTransits)
    }

    private static func recencyPenalty(
        for cardName: String,
        recentSelections: [(cardName: String, daysAgo: Int)]
    ) -> Double {
        TarotCardScoring.recencyPenalty(for: cardName, recentSelections: recentSelections)
    }

    // MARK: - Variant Selection (Rotation-Based)

    struct VariantSelectionResult {
        let variant: StyleEditVariant
        let wasScored: Bool
        let rotationIndex: Int
    }

    /// Selects style-edit variant by narrative intent scoring (stage-1) or rotation fallback.
    private static func selectVariant(
        for card: TarotCard,
        profileHash: String,
        dailyFitEngineId: String,
        narrativeIntent: NarrativeIntent?,
        dailySeed: Int
    ) -> VariantSelectionResult {
        guard let edits = card.styleEdits, !edits.isEmpty else {
            return VariantSelectionResult(
                variant: StyleEditVariant(
                    variant: "I",
                    title: card.name,
                    description: "Style guidance inspired by \(card.name).",
                    energyEmphasis: [:],
                    axesEmphasis: [:],
                    dailyRitual: nil,
                    wardrobeReflection: nil
                ),
                wasScored: false,
                rotationIndex: 0
            )
        }

        if let intent = narrativeIntent {
            let target = intent.tarot.targetEnergyVector
            var scored: [(index: Int, score: Double)] = []
            for (index, edit) in edits.enumerated() {
                let vec = NarrativeSelectionDirectives.energyDictionary(from: edit.energyEmphasis)
                let score = NarrativeSelectionDirectives.cosineSimilarity(vec, target)
                scored.append((index, score))
            }
            scored.sort { $0.score > $1.score }

            var selectedIndex = scored.first?.index ?? 0
            if scored.count >= 2, abs(scored[0].score - scored[1].score) < 0.01 {
                selectedIndex = scored[dailySeed % edits.count].index
            }

            if intent.relationship == NarrativeRelationship.soften, scored.count >= 3 {
                let top3 = scored.prefix(3)
                if let minDrama = top3.min(by: {
                    ($0.index < edits.count ? edits[$0.index].energyEmphasis["drama"] ?? 0.5 : 0.5)
                    < ($1.index < edits.count ? edits[$1.index].energyEmphasis["drama"] ?? 0.5 : 0.5)
                }) {
                    selectedIndex = minDrama.index
                }
            }

            return VariantSelectionResult(
                variant: edits[selectedIndex],
                wasScored: true,
                rotationIndex: selectedIndex
            )
        }

        let index = TarotVariantRotationTracker.shared.nextVariantIndex(
            forCard: card.name, profileHash: profileHash, dailyFitEngineId: dailyFitEngineId
        )
        let safeIndex = index % edits.count
        return VariantSelectionResult(
            variant: edits[safeIndex],
            wasScored: false,
            rotationIndex: safeIndex
        )
    }

    // MARK: - Phase 4: Full Payload Assembly

    /// Generate the complete DailyFitPayload from Style Guide data (`CosmicBlueprint`) and energy snapshot.
    /// This is the sole public entry point for Stage 2 after Phase 4.
    static func generatePayload(
        blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard,
        dailyFitEngineId engineId: String? = nil,
        precomputedEssence: StyleEssenceProfile? = nil,
        precomputedSilhouette: SilhouetteProfile? = nil,
        narrativeIntent: NarrativeIntent? = nil
    ) -> DailyFitPayload {
        let effectiveMode = DailyFitEngineRegistry.resolvedMode(explicit: mode, engineId: engineId)
        let resolvedEngineId = DailyFitEngineRegistry.engineId(for: calibration, mode: effectiveMode)
        let essence = precomputedEssence ?? resolveEssenceProfile(from: snapshot, mode: effectiveMode)
        let tarotResult = selectTarotAndStyleEditWithBridgeTrace(
            snapshot: snapshot,
            calibration: calibration,
            dailyFitEngineId: resolvedEngineId,
            narrativeIntent: narrativeIntent
        )
        let tarotCard = tarotResult.card
        let styleEditVariant = tarotResult.variant
        let palette = selectDailyPalette(
            from: blueprint.palette,
            snapshot: snapshot,
            calibration: calibration,
            narrativeIntent: narrativeIntent
        )
        let scaleDirective = narrativeIntent?.scales
        let vibrancy = deriveVibrancy(
            from: blueprint.palette, snapshot: snapshot, calibration: calibration,
            mode: effectiveMode, scaleDirective: scaleDirective
        )
        let contrast = deriveContrast(
            from: blueprint.palette, snapshot: snapshot, calibration: calibration,
            mode: effectiveMode, scaleDirective: scaleDirective
        )
        let metalTone = deriveMetalTone(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: effectiveMode
        )
        let silhouette = precomputedSilhouette ?? deriveSilhouetteProfile(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: effectiveMode
        )
        let textures = selectDailyTextures(from: blueprint.textures, snapshot: snapshot, mode: effectiveMode)
        let pattern = selectDailyPattern(
            from: blueprint.pattern, snapshot: snapshot, mode: effectiveMode
        )

        let presentation = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: blueprint,
            calibration: calibration,
            mode: effectiveMode,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone
        )

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
            generatedAt: snapshot.generatedAt,
            dailyFitEngineId: resolvedEngineId,
            scalePresentation: presentation
        )
    }

    /// Internal-only payload generation that also returns intermediate traces.
    struct PayloadTrace {
        let tarotScores: [(cardName: String, vibeScore: Double, axisScore: Double, transitBoost: Double, recencyPenalty: Double, totalScore: Double)]
        let variantRotationIndex: Int
        let tarotVariantWasScored: Bool
        let tarotCategoryBoostApplied: Bool
        let narrativeBridgeTrace: NarrativeBridgeTrace?
        let paletteTrace: (candidateCount: Int, scoredColours: [(name: String, role: String, score: Double)], diversitySwapApplied: Bool, selectionStrategy: String, coreAnchorSwapApplied: Bool)
        let paletteStatementSlotCount: Int
        let paletteSelectionPath: String
        let narrativeBiasApplied: Bool
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
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard,
        dailyFitEngineId engineId: String? = nil,
        precomputedEssence: StyleEssenceProfile? = nil,
        precomputedSilhouette: SilhouetteProfile? = nil,
        narrativeIntent: NarrativeIntent? = nil
    ) -> (payload: DailyFitPayload, trace: PayloadTrace) {
        let effectiveMode = DailyFitEngineRegistry.resolvedMode(explicit: mode, engineId: engineId)
        let resolvedEngineId = DailyFitEngineRegistry.engineId(for: calibration, mode: effectiveMode)

        // Unified tarot+variant selection (single source of truth for both paths)
        let tarotResult = selectTarotAndStyleEditWithBridgeTrace(
            snapshot: snapshot,
            calibration: calibration,
            dailyFitEngineId: resolvedEngineId,
            narrativeIntent: narrativeIntent
        )
        let selected = tarotResult.card
        let variant = tarotResult.variant
        let variantIdx = tarotResult.rotationIndex
        let tarotCategoryBoostApplied = tarotResult.categoryBoostApplied

        // Build tarot score trace for inspector (card-level scores only, same formula)
        let allCards = loadAndNormaliseCards()
        let recentSelections = TarotRecencyTracker.shared.getRecentSelections(
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt,
            dailyFitEngineId: resolvedEngineId
        )
        let weights = calibration.selectionWeights
        let vibeVector = buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = buildAxesVector(from: snapshot.axes)
        let traceIntent: NarrativeIntent? = tarotCategoryBoostApplied ? narrativeIntent : nil
        let traceTuning: DailyFitCalibration.NarrativeSelectionTuning? = tarotCategoryBoostApplied ? calibration.narrativeSelection : nil
        var scoredCards: [(card: TarotCard, breakdown: TarotCardScoring.ScoreBreakdown)] = []
        for (card, normAxes) in allCards {
            let breakdown = TarotCardScoring.scoreCard(
                card: card, normAxes: normAxes,
                vibeVector: vibeVector, axesVector: axesVector,
                weights: weights,
                recentSelections: recentSelections,
                dominantTransits: snapshot.dominantTransits,
                intent: traceIntent, tuning: traceTuning
            )
            scoredCards.append((card, breakdown))
        }
        scoredCards.sort { $0.breakdown.total > $1.breakdown.total }
        let topScoreEntries = scoredCards.prefix(10).map {
            (cardName: $0.card.name, vibeScore: $0.breakdown.vibeScore, axisScore: $0.breakdown.axisScore, transitBoost: $0.breakdown.transitBoost, recencyPenalty: $0.breakdown.recencyPenalty, totalScore: $0.breakdown.total)
        }

        guard !allCards.isEmpty else {
            let fallback = TarotCard(
                name: "The Fool", imagePath: "Cards/00-TheFool",
                arcana: .major, suit: nil, number: nil,
                keywords: [], themes: [],
                energyAffinity: [:], axesAffinity: nil,
                description: "", reversedKeywords: [],
                symbolism: [], styleEdits: nil
            )
            let fallbackVariant = StyleEditVariant(
                variant: "I", title: fallback.name,
                description: "Style guidance inspired by \(fallback.name).",
                energyEmphasis: [:], axesEmphasis: [:],
                dailyRitual: nil, wardrobeReflection: nil
            )
            let essence = precomputedEssence ?? resolveEssenceProfile(from: snapshot, mode: effectiveMode)
            let silhouette = precomputedSilhouette ?? deriveSilhouetteProfile(
                from: blueprint, snapshot: snapshot, calibration: calibration, mode: effectiveMode
            )
            let emptyPresentation = PersonalScaleEnvelopeCalculator.makePresentation(
                blueprint: blueprint, calibration: calibration,
                mode: effectiveMode, vibrancy: 0.5, contrast: 0.5, metalTone: 0.5
            )
            let emptyPayload = DailyFitPayload(
                tarotCard: fallback, styleEditVariant: fallbackVariant,
                dailyPalette: selectDailyPalette(
                    from: blueprint.palette, snapshot: snapshot,
                    calibration: calibration, narrativeIntent: narrativeIntent
                ),
                vibrancy: 0.5, contrast: 0.5, metalTone: 0.5,
                essenceProfile: essence,
                silhouetteProfile: silhouette,
                vibeBreakdown: snapshot.vibeProfile, axes: snapshot.axes,
                dominantTransits: snapshot.dominantTransits,
                lunarContext: snapshot.lunarContext, dailyTextures: [], dailyPattern: nil,
                generatedAt: snapshot.generatedAt,
                dailyFitEngineId: resolvedEngineId,
                scalePresentation: emptyPresentation
            )
            let emptyTrace = PayloadTrace(
                tarotScores: [], variantRotationIndex: 0,
                tarotVariantWasScored: false,
                tarotCategoryBoostApplied: false,
                narrativeBridgeTrace: nil,
                paletteTrace: (0, [], false, calibration.stage2Sensitivity.paletteSelectionStrategy.rawValue, false),
                paletteStatementSlotCount: 0,
                paletteSelectionPath: narrativeIntent != nil ? "narrativeSlots" : "pureSkyScoring",
                narrativeBiasApplied: narrativeIntent != nil,
                textureTrace: ([], []),
                patternTrace: (false, 0, "classic"),
                vibrancyBaseline: 0.5, vibrancyModulation: 0,
                contrastBaseline: 0.5, contrastModulation: 0,
                metalToneBaseline: 0.5, metalToneModulation: 0,
                silhouetteBaselines: (0.5, 0.5, 0.5)
            )
            return (emptyPayload, emptyTrace)
        }

        // Palette trace
        let candidates = buildPaletteCandidates(from: blueprint.palette)
        let paletteResult = selectDailyPaletteWithTrace(
            from: blueprint.palette, snapshot: snapshot, calibration: calibration,
            narrativeIntent: narrativeIntent
        )
        let palette = paletteResult.selection
        let paletteHexSet = Set(palette.colours.map(\.hexValue))
        let preSwapTopHexes = Set(candidates.prefix(3).map(\.hexValue))
        let diversitySwap = paletteHexSet != preSwapTopHexes && candidates.count >= 4
        let strategy = calibration.stage2Sensitivity.paletteSelectionStrategy

        let scored = scorePaletteCandidates(candidates, snapshot: snapshot, calibration: calibration)
        let scoredColours: [(String, String, Double)] = scored.map { ($0.colour.name, $0.colour.role.rawValue, $0.score) }

        let coreAnchorSwapped: Bool
        if strategy == .coreAnchoredRanking {
            let rawTop3Hexes: Set<String> = {
                var hexes = Set<String>()
                for item in scored {
                    if hexes.count >= 3 { break }
                    hexes.insert(normalizedPaletteHex(item.colour.hexValue))
                }
                return hexes
            }()
            coreAnchorSwapped = paletteHexSet != rawTop3Hexes
        } else {
            coreAnchorSwapped = false
        }

        // Vibrancy trace
        let vibBaseline: Double
        switch blueprint.palette.variables?.saturation {
        case .soft:  vibBaseline = 0.25
        case .muted: vibBaseline = 0.50
        case .rich:  vibBaseline = 0.75
        case nil:    vibBaseline = 0.50
        }
        let traceVibe = (effectiveMode == .stage1Experimental)
            ? (snapshot.skyVibeProfile ?? snapshot.vibeProfile)
            : snapshot.vibeProfile
        let vibPush = Double(traceVibe.value(for: .drama) + traceVibe.value(for: .edge)) / 21.0
        let vibPull = Double(traceVibe.value(for: .utility) + traceVibe.value(for: .classic)) / 21.0
        let vibMod = (vibPush - vibPull) * calibration.stage2Sensitivity.vibrancyCoeff
        let scaleDirective = narrativeIntent?.scales
        let vibrancy = deriveVibrancy(
            from: blueprint.palette, snapshot: snapshot, calibration: calibration,
            mode: effectiveMode, scaleDirective: scaleDirective
        )

        // Contrast trace
        let conBaseline: Double
        switch blueprint.palette.variables?.contrast {
        case .low:    conBaseline = 0.25
        case .medium: conBaseline = 0.50
        case .high:   conBaseline = 0.75
        case nil:     conBaseline = 0.50
        }
        let visNorm = snapshot.axes.visibility / 10.0
        let conMod = (visNorm - 0.5) * calibration.stage2Sensitivity.contrastCoeff
        let contrast = deriveContrast(
            from: blueprint.palette, snapshot: snapshot, calibration: calibration,
            mode: effectiveMode, scaleDirective: scaleDirective
        )

        let metalTone = deriveMetalTone(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: effectiveMode
        )
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

        let essence = precomputedEssence ?? resolveEssenceProfile(from: snapshot, mode: effectiveMode)
        let silhouette = precomputedSilhouette ?? deriveSilhouetteProfile(
            from: blueprint, snapshot: snapshot, calibration: calibration, mode: effectiveMode
        )
        let positives = blueprint.code.leanInto + blueprint.code.consider
        let negatives = blueprint.code.avoid
        let mfBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: mfLeft, rightKeywords: mfRight)
        let arBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: arLeft, rightKeywords: arRight)
        let sdBase = keywordBaseline(positives: positives, negatives: negatives, leftKeywords: sdLeft, rightKeywords: sdRight)

        let presentationForTrace = PersonalScaleEnvelopeCalculator.makePresentation(
            blueprint: blueprint,
            calibration: calibration,
            mode: effectiveMode,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone
        )

        let textures = selectDailyTextures(from: blueprint.textures, snapshot: snapshot, mode: effectiveMode)
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

        let dominant: Energy
        if effectiveMode == .stage1Experimental, let raw = snapshot.vibeRawScores {
            dominant = snapshot.vibeProfile.dominantEnergy(rawTieBreak: raw)
        } else {
            dominant = snapshot.vibeProfile.dominantEnergy
        }
        let gatePassed = snapshot.axes.visibility >= 6.0 && (dominant == .drama || dominant == .playful || dominant == .edge)
        let pattern = selectDailyPattern(
            from: blueprint.pattern, snapshot: snapshot, mode: effectiveMode
        )

        let payload = DailyFitPayload(
            tarotCard: selected, styleEditVariant: variant,
            dailyPalette: palette, vibrancy: vibrancy, contrast: contrast,
            metalTone: metalTone, essenceProfile: essence,
            silhouetteProfile: silhouette, vibeBreakdown: snapshot.vibeProfile,
            axes: snapshot.axes, dominantTransits: snapshot.dominantTransits,
            lunarContext: snapshot.lunarContext, dailyTextures: textures,
            dailyPattern: pattern, generatedAt: snapshot.generatedAt,
            dailyFitEngineId: resolvedEngineId,
            scalePresentation: presentationForTrace
        )
        let trace = PayloadTrace(
            tarotScores: Array(topScoreEntries),
            variantRotationIndex: variantIdx,
            tarotVariantWasScored: tarotResult.variantWasScored,
            tarotCategoryBoostApplied: tarotCategoryBoostApplied,
            narrativeBridgeTrace: tarotResult.bridgeTrace,
            paletteTrace: (candidates.count, scoredColours, diversitySwap, strategy.rawValue, coreAnchorSwapped),
            paletteStatementSlotCount: paletteResult.statementSlotCount,
            paletteSelectionPath: paletteResult.selectionPath,
            narrativeBiasApplied: narrativeIntent != nil,
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
    /// Strategy is controlled by `calibration.stage2Sensitivity.paletteSelectionStrategy`:
    ///   `.dramaSlots`           — drama-driven statement/grounding slot quotas (production)
    ///   `.coreAnchoredRanking`  — pure score ranking with at-least-one-core anchor
    private static func selectDailyPalette(
        from palette: PaletteSection,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        narrativeIntent: NarrativeIntent? = nil
    ) -> DailyPaletteSelection {
        selectDailyPaletteWithTrace(
            from: palette, snapshot: snapshot, calibration: calibration, narrativeIntent: narrativeIntent
        ).selection
    }

    private struct PaletteSelectionResult {
        let selection: DailyPaletteSelection
        let statementSlotCount: Int
        let selectionPath: String
    }

    private static func selectDailyPaletteWithTrace(
        from palette: PaletteSection,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        narrativeIntent: NarrativeIntent? = nil
    ) -> PaletteSelectionResult {
        let candidates = buildPaletteCandidates(from: palette)
        let allHexes = buildAllPaletteHexes(from: palette)

        guard candidates.count >= 3 else {
            let picks = candidates.map {
                DailyColourPick(name: $0.name, hexValue: $0.hexValue,
                                role: $0.role.rawValue)
            }
            return PaletteSelectionResult(
                selection: DailyPaletteSelection(
                    colours: Array(picks.prefix(3)),
                    allPaletteHexes: allHexes
                ),
                statementSlotCount: 0,
                selectionPath: calibration.stage2Sensitivity.paletteSelectionStrategy.rawValue
            )
        }

        let strategy = calibration.stage2Sensitivity.paletteSelectionStrategy
        let selected: [(colour: BlueprintColour, score: Double)]
        var statementSlotCount = 0
        var selectionPath = strategy.rawValue

        switch strategy {
        case .dramaSlots:
            let scored = scorePaletteCandidates(candidates, snapshot: snapshot, calibration: calibration)
            selected = selectViaDramaSlots(scored: scored, snapshot: snapshot)
        case .coreAnchoredRanking:
            let scored = scorePaletteCandidates(candidates, snapshot: snapshot, calibration: calibration)
            selected = selectViaCoreAnchoredRanking(scored: scored)
        case .pureSkyScoring:
            let vibeSource = snapshot.skyVibeProfile ?? snapshot.vibeProfile
            let baseScored = scorePaletteCandidates(
                candidates, snapshot: snapshot, calibration: calibration, vibeSource: vibeSource
            )
            if let intent = narrativeIntent, let tuning = calibration.narrativeSelection {
                var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
                let narrativeScored = NarrativeSelectionDirectives.applyNarrativePaletteScoring(
                    baseScored: baseScored,
                    intent: intent,
                    tuning: tuning,
                    roleEnergyAlignment: roleEnergyAlignment,
                    seededJitter: { _ in Double.random(in: 0..<1.0, using: &rng) }
                )
                let slotResult = NarrativeSelectionDirectives.selectViaNarrativeSlots(
                    scored: narrativeScored,
                    intent: intent,
                    normalizeHex: normalizedPaletteHex
                )
                selected = slotResult.selected
                statementSlotCount = slotResult.statementSlotCount
                selectionPath = "narrativeSlots"
            } else {
                selected = selectViaPureSkyScoring(scored: baseScored)
                selectionPath = "pureSkyScoring"
            }
        }

        let picks = selected.map {
            DailyColourPick(name: $0.colour.name, hexValue: $0.colour.hexValue,
                            role: $0.colour.role.rawValue)
        }
        return PaletteSelectionResult(
            selection: DailyPaletteSelection(colours: picks, allPaletteHexes: allHexes),
            statementSlotCount: statementSlotCount,
            selectionPath: selectionPath
        )
    }

    /// Build the deduped candidate pool from the Style Guide palette.
    private static func buildPaletteCandidates(from palette: PaletteSection) -> [BlueprintColour] {
        var candidates: [BlueprintColour] = []
        candidates.append(contentsOf: palette.coreColours)
        candidates.append(contentsOf: palette.accentColours)
        if let neutrals = palette.neutrals { candidates.append(contentsOf: neutrals) }
        if let support = palette.supportColours { candidates.append(contentsOf: support) }
        if let lum = palette.luminarySignature { candidates.append(lum) }
        if let ruler = palette.rulerSignature { candidates.append(ruler) }
        return dedupeCandidatesByHexPreservingOrder(candidates)
    }

    /// Score every candidate colour against today's vibe profile.
    private static func scorePaletteCandidates(
        _ candidates: [BlueprintColour],
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration,
        vibeSource: VibeBreakdown? = nil
    ) -> [(colour: BlueprintColour, score: Double)] {
        var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
        let vibe = vibeSource ?? snapshot.vibeProfile
        let vibeTotal = 21.0
        var scored: [(colour: BlueprintColour, score: Double)] = candidates.map { colour in
            let aligned = roleEnergyAlignment[colour.role] ?? [.classic, .romantic]
            let base = aligned.reduce(0.0) { sum, energy in
                sum + Double(vibe.value(for: energy)) / vibeTotal
            }
            let jitter = Double.random(in: 0..<calibration.stage2Sensitivity.paletteJitter, using: &rng)
            let profileBias = deterministicProfileColourBias(
                profileHash: snapshot.profileHash,
                colourHex: colour.hexValue
            )
            return (colour, base + jitter + profileBias)
        }
        scored.sort { $0.score > $1.score }
        return scored
    }

    /// Drama-driven slot allocation (original production algorithm).
    private static func selectViaDramaSlots(
        scored: [(colour: BlueprintColour, score: Double)],
        snapshot: DailyEnergySnapshot
    ) -> [(colour: BlueprintColour, score: Double)] {
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
            let usedHexes = Set(selected.map { normalizedPaletteHex($0.colour.hexValue) })
            for item in scored {
                if selected.count >= 3 { break }
                let key = normalizedPaletteHex(item.colour.hexValue)
                if !usedHexes.contains(key) {
                    selected.append(item)
                }
            }
        }
        return selected
    }

    /// Pure score ranking with an at-least-one-core anchor guarantee.
    private static func selectViaCoreAnchoredRanking(
        scored: [(colour: BlueprintColour, score: Double)]
    ) -> [(colour: BlueprintColour, score: Double)] {
        var top3: [(colour: BlueprintColour, score: Double)] = []
        var usedHexes = Set<String>()
        for item in scored {
            if top3.count >= 3 { break }
            let key = normalizedPaletteHex(item.colour.hexValue)
            guard !usedHexes.contains(key) else { continue }
            usedHexes.insert(key)
            top3.append(item)
        }

        let hasCore = top3.contains { $0.colour.role == .core }
        if !hasCore {
            let bestCore = scored.first {
                $0.colour.role == .core && !usedHexes.contains(normalizedPaletteHex($0.colour.hexValue))
            }
            if let core = bestCore, let lowestIdx = top3.indices.max(by: { top3[$0].score > top3[$1].score }) {
                top3[lowestIdx] = core
            }
        }

        top3.sort { $0.score > $1.score }
        return top3
    }

    /// Pure top-3 by score — no role guarantees (Stage 1 pureSkyScoring).
    private static func selectViaPureSkyScoring(
        scored: [(colour: BlueprintColour, score: Double)]
    ) -> [(colour: BlueprintColour, score: Double)] {
        var top3: [(colour: BlueprintColour, score: Double)] = []
        var usedHexes = Set<String>()
        for item in scored {
            if top3.count >= 3 { break }
            let key = normalizedPaletteHex(item.colour.hexValue)
            guard !usedHexes.contains(key) else { continue }
            usedHexes.insert(key)
            top3.append(item)
        }
        return top3
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

    /// Deterministic per-profile nudge to reduce cross-profile palette collisions.
    private static func deterministicProfileColourBias(
        profileHash: String,
        colourHex: String
    ) -> Double {
        let key = "\(profileHash)|\(normalizedPaletteHex(colourHex))"
        let seed = DailySeedGenerator.intSeed(from: key)
        let bucket = abs(seed % 1000)
        return Double(bucket) / 1000.0 * 0.012
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
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard,
        scaleDirective: ScaleDirective? = nil
    ) -> Double {
        let baseline: Double
        switch palette.variables?.saturation {
        case .soft:  baseline = 0.25
        case .muted: baseline = 0.50
        case .rich:  baseline = 0.75
        case nil:    baseline = 0.50
        }
        let vibe = (mode == .stage1Experimental)
            ? (snapshot.skyVibeProfile ?? snapshot.vibeProfile)
            : snapshot.vibeProfile

        var final: Double
        if mode == .stage1Experimental {
            let push = Double(vibe.value(for: .drama) + vibe.value(for: .edge)) / 21.0
            let pull = Double(vibe.value(for: .utility) + vibe.value(for: .classic) + vibe.value(for: .romantic)) / 21.0
            let vibeModulation = (push - pull) * Stage1ScaleSensitivity.vibeScale
            let tempoMod = (snapshot.axes.tempo / 10.0 - 0.5) * Stage1ScaleSensitivity.tempoScale
            final = baseline + vibeModulation + tempoMod
        } else {
            let push = Double(vibe.value(for: .drama) + vibe.value(for: .edge)) / 21.0
            let pull = Double(vibe.value(for: .utility) + vibe.value(for: .classic)) / 21.0
            let modulation = (push - pull) * calibration.stage2Sensitivity.vibrancyCoeff
            final = baseline + modulation
        }

        if let directive = scaleDirective {
            if let cap = directive.vibrancyCap {
                final = min(final, cap)
            }
            if directive.pullTowardBaseline {
                final = baseline * directive.baselineBlend + final * (1.0 - directive.baselineBlend)
            }
        }

        return max(0.0, min(1.0, final))
    }

    // MARK: - Contrast Derivation

    /// Blueprint-anchored contrast: baseline from ContrastLevel enum,
    /// modulated by axes. Stage 1 uses visibility + strategy blend for more variation.
    private static func deriveContrast(
        from palette: PaletteSection,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard,
        scaleDirective: ScaleDirective? = nil
    ) -> Double {
        let baseline: Double
        switch palette.variables?.contrast {
        case .low:    baseline = 0.25
        case .medium: baseline = 0.50
        case .high:   baseline = 0.75
        case nil:     baseline = 0.50
        }
        let coeff = calibration.stage2Sensitivity.contrastCoeff
        let modulation: Double
        if mode == .stage1Experimental {
            let visNorm = snapshot.axes.visibility / 10.0
            let strNorm = snapshot.axes.strategy / 10.0
            modulation = ((visNorm - 0.5) * Stage1ScaleSensitivity.contrastVisWeight + (strNorm - 0.5) * Stage1ScaleSensitivity.contrastStrWeight) * coeff
        } else {
            let visNorm = snapshot.axes.visibility / 10.0
            modulation = (visNorm - 0.5) * coeff
        }

        var final = baseline + modulation
        if let directive = scaleDirective {
            if let cap = directive.contrastCap {
                final = min(final, cap)
            }
            if directive.pullTowardBaseline {
                final = baseline * directive.baselineBlend + final * (1.0 - directive.baselineBlend)
            }
        }
        return max(0.0, min(1.0, final))
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
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard
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
        let nudgeCap = mode == .stage1Experimental
            ? Stage1ScaleSensitivity.metalNudgeCap
            : Stage1ScaleSensitivity.metalNudgeCapStandard
        let fireNudge = min(Double(fireHits) * calibration.stage2Sensitivity.metalNudgePerHit, nudgeCap)
        let waterNudge = min(Double(waterHits) * calibration.stage2Sensitivity.metalNudgePerHit, nudgeCap)

        let phase = snapshot.lunarContext.phaseName.lowercased()
        let lunarNudge: Double
        if phase.contains("full") {
            lunarNudge = -Stage1ScaleSensitivity.lunarNamedPhaseNudge
        } else if phase.contains("new") {
            lunarNudge = Stage1ScaleSensitivity.lunarNamedPhaseNudge
        } else {
            lunarNudge = 0.0
        }

        let lunarMetalMod: Double
        if mode == .stage1Experimental {
            let fraction = snapshot.lunarContext.phaseDegrees / 360.0
            lunarMetalMod = (fraction - 0.5) * Stage1ScaleSensitivity.lunarDegreeScale
        } else {
            lunarMetalMod = 0.0
        }

        return max(0.0, min(1.0, baseline + fireNudge - waterNudge + lunarNudge + lunarMetalMod))
    }

    // MARK: - Style Essence Profile (14-Category Radar)

    /// Single dispatch point for mode-dependent essence derivation.
    static func resolveEssenceProfile(
        from snapshot: DailyEnergySnapshot,
        mode: DailyFitEngineMode
    ) -> StyleEssenceProfile {
        switch mode {
        case .stage1Experimental:
            return deriveStyleEssenceProfileStage1Experimental(from: snapshot)
        case .standard:
            return deriveStyleEssenceProfile(from: snapshot)
        }
    }

    static func essenceCategoryWeights(for category: StyleEssenceCategory) -> [Energy: Double] {
        essenceCategoryWeights[category] ?? [:]
    }

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

    /// Score all 14 style-essence categories from normalized vibe and optional axis inputs.
    private static func scoreEssenceCategories(
        normVibe: [Energy: Double],
        axesNorm: [String: Double]?,
        axisDeltaNorm: [String: Double]?,
        dominantTransits: [DailyTransitSummary],
        stage1Mode: Bool
    ) -> [StyleEssenceScore] {
        var scores: [StyleEssenceScore] = []
        for category in StyleEssenceCategory.allCases {
            let weights = essenceCategoryWeights[category] ?? [:]
            var raw = 0.0
            for energy in Energy.allCases {
                raw += (weights[energy] ?? 0.0) * (normVibe[energy] ?? 0.0)
            }
            if let axisMods = essenceAxisModifiers[category] {
                for (axis, modifier) in axisMods {
                    if let delta = axisDeltaNorm?[axis] {
                        raw += modifier * stage1AxisEssenceMultiplier * delta
                    } else {
                        let axisVal = axesNorm?[axis] ?? 0.5
                        let scale = stage1Mode ? stage1AxisEssenceMultiplier : 1.0
                        raw += modifier * scale * (axisVal - 0.5)
                    }
                }
            }
            if stage1Mode {
                var boostedCategories = Set<StyleEssenceCategory>()
                for transit in dominantTransits.prefix(3) {
                    if let boosted = stage1TransitEssenceCategories[transit.transitPlanet],
                       boosted == category,
                       !boostedCategories.contains(boosted) {
                        let cappedStrength = min(transit.strength, 0.50)
                        raw += cappedStrength * stage1TransitEssenceBoost
                        boostedCategories.insert(boosted)
                    }
                }
            }
            scores.append(StyleEssenceScore(
                category: category,
                score: max(0.0, raw)
            ))
        }
        return scores
    }

    private static func normalizedVibeMap(_ vibe: VibeBreakdown) -> [Energy: Double] {
        let vibeTotal = 21.0
        return Dictionary(
            uniqueKeysWithValues: Energy.allCases.map {
                ($0, Double(vibe.value(for: $0)) / vibeTotal)
            }
        )
    }

    private static func finalizeEssenceScores(_ scores: [StyleEssenceScore]) -> StyleEssenceProfile {
        let peak = scores.map(\.score).max() ?? 1.0
        let scale = peak > 0 ? 1.0 / peak : 1.0
        let normalised = scores.map {
            StyleEssenceScore(category: $0.category, score: min(1.0, $0.score * scale))
        }
        let sorted = normalised.sorted { $0.score > $1.score }
        return StyleEssenceProfile(
            allScores: normalised,
            visibleCategories: Array(sorted.prefix(3))
        )
    }

    /// Score all 14 style-essence categories from the snapshot's vibe profile
    /// and axes, then select the top 3. Pure energy readout — not
    /// constrained by Blueprint.
    static func deriveStyleEssenceProfile(
        from snapshot: DailyEnergySnapshot
    ) -> StyleEssenceProfile {
        let axesNorm: [String: Double] = [
            "action": snapshot.axes.action / 10.0,
            "tempo": snapshot.axes.tempo / 10.0,
            "strategy": snapshot.axes.strategy / 10.0,
            "visibility": snapshot.axes.visibility / 10.0,
        ]
        let scores = scoreEssenceCategories(
            normVibe: normalizedVibeMap(snapshot.vibeProfile),
            axesNorm: axesNorm,
            axisDeltaNorm: nil,
            dominantTransits: snapshot.dominantTransits,
            stage1Mode: false
        )
        let clamped = scores.map {
            StyleEssenceScore(category: $0.category, score: min(1.0, $0.score))
        }
        let sorted = clamped.sorted { $0.score > $1.score }
        return StyleEssenceProfile(
            allScores: clamped,
            visibleCategories: Array(sorted.prefix(3))
        )
    }

    /// Axis modifier scale for stage1Experimental essence (stage1Experimental mode only).
    private static let stage1AxisEssenceMultiplier = 1.6
    /// Transit boost per matching dominant transit for stage1Experimental essence.
    private static let stage1TransitEssenceBoost = 0.35
    /// Amplifies sky−chart vibe delta before essence category scoring (Stage 1).
    private static let stage1EssenceVibeDeltaAmplification = 1.8

    /// Stage 1 experimental: today's outside-energy essence, with chart anchor for contrast.
    static func deriveStyleEssenceProfileStage1Experimental(
        from snapshot: DailyEnergySnapshot
    ) -> StyleEssenceProfile {
        let chartVibe = snapshot.chartVibeProfile ?? snapshot.vibeProfile
        let skyVibe = snapshot.skyVibeProfile ?? snapshot.vibeProfile
        let chartNorm = normalizedVibeMap(chartVibe)
        let skyNorm = normalizedVibeMap(skyVibe)
        var deltaNorm: [Energy: Double] = [:]
        for energy in Energy.allCases {
            deltaNorm[energy] = stage1EssenceVibeDeltaAmplification
                * ((skyNorm[energy] ?? 0) - (chartNorm[energy] ?? 0))
        }

        let axisDeltaNorm: [String: Double]? = snapshot.chartAxes.map { chart in
            [
                "action": (snapshot.axes.action - chart.action) / 9.0,
                "tempo": (snapshot.axes.tempo - chart.tempo) / 9.0,
                "strategy": (snapshot.axes.strategy - chart.strategy) / 9.0,
                "visibility": (snapshot.axes.visibility - chart.visibility) / 9.0,
            ]
        }
        let todayScores = scoreEssenceCategories(
            normVibe: deltaNorm,
            axesNorm: nil,
            axisDeltaNorm: axisDeltaNorm,
            dominantTransits: snapshot.dominantTransits,
            stage1Mode: true
        )
        var profile = finalizeEssenceScores(todayScores)

        let chartScores = scoreEssenceCategories(
            normVibe: chartNorm,
            axesNorm: nil,
            axisDeltaNorm: nil,
            dominantTransits: [],
            stage1Mode: false
        )
        let chartProfile = finalizeEssenceScores(chartScores)
        profile = StyleEssenceProfile(
            allScores: profile.allScores,
            visibleCategories: profile.visibleCategories,
            chartAnchorScores: chartProfile.allScores
        )
        return profile
    }

    private static let stage1TransitEssenceCategories: [String: StyleEssenceCategory] = [
        "Mars": .drama, "Venus": .romantic, "Sun": .magnetic,
        "Moon": .sensual, "Mercury": .playful, "Jupiter": .maximalist,
        "Saturn": .minimal, "Uranus": .edgy, "Neptune": .sensual, "Pluto": .edgy,
    ]

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
    static func deriveSilhouetteProfile(
        from blueprint: CosmicBlueprint,
        snapshot: DailyEnergySnapshot,
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard
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

        if mode == .stage1Experimental {
            let skyVis = snapshot.axes.visibility
            let skyAct = snapshot.axes.action
            let skyStr = snapshot.axes.strategy
            let mf = 0.5 + tanh((skyVis - 5.5) / 4.5) * 0.45
            let ar = 0.5 + tanh((skyAct - 5.5) / 4.5) * 0.45
            let sd = 0.5 + tanh((skyStr - 5.5) / 4.5) * 0.45
            return SilhouetteProfile(
                masculineFeminine: mf,
                angularRounded: ar,
                structuredDraped: sd,
                chartAnchorMF: mfBase,
                chartAnchorAR: arBase,
                chartAnchorSD: sdBase
            )
        }

        let s = calibration.stage2Sensitivity.silhouetteAxisScale

        let visNorm = snapshot.axes.visibility / 10.0
        let actNorm = snapshot.axes.action / 10.0
        let strNorm = snapshot.axes.strategy / 10.0

        return SilhouetteProfile(
            masculineFeminine: max(0.0, min(1.0,
                mfBase + (visNorm - 0.5) * 0.25 * s)),
            angularRounded: max(0.0, min(1.0,
                arBase + (actNorm - 0.5) * -0.20 * s)),
            structuredDraped: max(0.0, min(1.0,
                sdBase + (strNorm - 0.5) * -0.25 * s))
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
        "knit":      ["strategy": 0.6, "tempo": 0.4],
        "flannel":   ["action": 0.5, "strategy": 0.5],
        "bonded":    ["strategy": 0.7, "action": 0.5],
        "stretch":   ["tempo": 0.7, "action": 0.5],
        "matte":     ["strategy": 0.5, "visibility": 0.3],
    ]

    /// Select 2–3 textures from the Blueprint's recommended list based on axes.
    /// Every texture in the output comes from the Blueprint — no invented values.
    /// Stage 1 experimental adds sky-vibe energy modulation for day-to-day variation.
    private static func selectDailyTextures(
        from textures: TexturesSection,
        snapshot: DailyEnergySnapshot,
        mode: DailyFitEngineMode = .standard
    ) -> [String] {
        let axesNorm: [String: Double] = [
            "action":     snapshot.axes.action / 10.0,
            "tempo":      snapshot.axes.tempo / 10.0,
            "strategy":   snapshot.axes.strategy / 10.0,
            "visibility": snapshot.axes.visibility / 10.0,
        ]

        let skyVibe = mode == .stage1Experimental
            ? (snapshot.skyVibeProfile ?? snapshot.vibeProfile)
            : nil

        var scored: [(String, Double)] = textures.recommendedTextures.map { texture in
            let lower = texture.lowercased()
            var score = 0.5
            for (keyword, affinities) in textureAxisAffinity {
                if lower.contains(keyword) {
                    let weightSum = affinities.values.reduce(0.0, +)
                    guard weightSum > 0 else { break }
                    score = affinities.reduce(0.0) {
                        $0 + $1.value * (axesNorm[$1.key] ?? 0.5)
                    } / weightSum
                    break
                }
            }
            if let vibe = skyVibe {
                score += textureVibeBonus(lower: lower, vibe: vibe)
            }
            return (texture, score)
        }

        if mode == .stage1Experimental, let topScore = scored.max(by: { $0.1 < $1.1 })?.1, topScore > 0 {
            let threshold = topScore * 0.85
            let tiedGroup = scored.filter { $0.1 >= threshold }
            if tiedGroup.count > 1 {
                var rng = SeededRandomGenerator(seed: snapshot.dailySeed &+ 7)
                let shuffled = tiedGroup.shuffled(using: &rng)
                let rest = scored.filter { $0.1 < threshold }
                scored = shuffled + rest.sorted { $0.1 > $1.1 }
            } else {
                scored.sort { $0.1 > $1.1 }
            }
        } else {
            scored.sort { $0.1 > $1.1 }
        }

        guard scored.count >= 2 else { return scored.map(\.0) }
        let takeThree = scored.count >= 3
            && scored[2].1 >= scored[1].1 * 0.8
        return Array(scored.prefix(takeThree ? 3 : 2)).map(\.0)
    }

    private static let textureEnergyAffinity: [String: [Energy: Double]] = [
        "silk":      [.romantic: 0.3, .drama: 0.2],
        "velvet":    [.drama: 0.4, .romantic: 0.2],
        "cashmere":  [.classic: 0.3, .romantic: 0.2],
        "linen":     [.utility: 0.3, .playful: 0.2],
        "leather":   [.edge: 0.4, .drama: 0.2],
        "denim":     [.utility: 0.3, .edge: 0.2],
        "wool":      [.classic: 0.3, .utility: 0.2],
        "cotton":    [.utility: 0.3, .playful: 0.2],
        "suede":     [.romantic: 0.3, .classic: 0.1],
        "tweed":     [.classic: 0.4, .utility: 0.2],
        "satin":     [.romantic: 0.3, .drama: 0.3],
        "jersey":    [.playful: 0.3, .utility: 0.2],
        "chiffon":   [.romantic: 0.3, .playful: 0.2],
        "corduroy":  [.classic: 0.3, .edge: 0.1],
        "knit":      [.classic: 0.3, .utility: 0.2],
        "flannel":   [.utility: 0.3, .classic: 0.2],
        "bonded":    [.utility: 0.3, .edge: 0.2],
        "stretch":   [.playful: 0.3, .utility: 0.2],
        "matte":     [.utility: 0.2, .classic: 0.2],
    ]

    private static func textureVibeBonus(lower: String, vibe: VibeBreakdown) -> Double {
        let total = 21.0
        for (keyword, affinities) in textureEnergyAffinity {
            if lower.contains(keyword) {
                return affinities.reduce(0.0) {
                    $0 + $1.value * (Double(vibe.value(for: $1.key)) / total)
                }
            }
        }
        return 0.0
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
        snapshot: DailyEnergySnapshot,
        mode: DailyFitEngineMode = .standard
    ) -> String? {
        let dominant: Energy
        if mode == .stage1Experimental, let raw = snapshot.vibeRawScores {
            dominant = snapshot.vibeProfile.dominantEnergy(rawTieBreak: raw)
        } else {
            dominant = snapshot.vibeProfile.dominantEnergy
        }
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

        if mode == .stage1Experimental, let topScore = scored.first?.1, topScore > 0 {
            let topPatterns = scored.filter { $0.1 >= topScore * 0.8 }
            var rng = SeededRandomGenerator(seed: snapshot.dailySeed)
            let idx = Int.random(in: 0..<topPatterns.count, using: &rng)
            return topPatterns[idx].0
        }

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
        blueprint: CosmicBlueprint,
        calibration: DailyFitCalibration = .default,
        essenceConflictTrace: EssenceConflictTrace? = nil
    ) {
        let p = "[DailyFitDiag]"
        let f2 = { (v: Double) -> String in String(format: "%.2f", v) }
        let f3 = { (v: Double) -> String in String(format: "%.3f", v) }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE d MMM yyyy"
        let dateStr = dateFormatter.string(from: payload.generatedAt)

        print("\(p) ╔══════════════════════════════════════════════════════════════")
        print("\(p) ║  DAILY FIT PIPELINE — FULL DIAGNOSTIC")
        let engineId = dailyFitEngineId(for: calibration)
        let fingerprint = DailyFitEngineRegistry.fingerprint(for: calibration)
        print("\(p) ║  \(dateStr)  ·  seed \(snapshot.dailySeed)")
        print("\(p) ║  engine \(engineId)  ·  fingerprint \(fingerprint.prefix(12))…")
        print("\(p) ╚══════════════════════════════════════════════════════════════")

        // ── 1. ENERGY SNAPSHOT (Stage 1 Output) ──
        print("\(p)")
        print("\(p) ── 1. ENERGY SNAPSHOT ──────────────────────────────────────")
        let cal = calibration
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
            profileHash: snapshot.profileHash,
            referenceDate: snapshot.generatedAt,
            dailyFitEngineId: engineId
        )
        let vibeVector = buildVibeVector(from: snapshot.vibeProfile)
        let axesVector = buildAxesVector(from: snapshot.axes)
        let weights = calibration.selectionWeights

        var scoredForLog: [(name: String, vibe: Double, axis: Double, transit: Double, recency: Double, total: Double)] = []
        for (card, normAxes) in allCards {
            let bd = TarotCardScoring.scoreCard(
                card: card, normAxes: normAxes,
                vibeVector: vibeVector, axesVector: axesVector,
                weights: weights,
                recentSelections: recentSelections,
                dominantTransits: snapshot.dominantTransits
            )
            scoredForLog.append((card.name, bd.vibeScore, bd.axisScore, bd.transitBoost, bd.recencyPenalty, bd.total))
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
        let paletteStrategy = cal.stage2Sensitivity.paletteSelectionStrategy
        print("\(p) Strategy: \(paletteStrategy.rawValue)")
        let drama = snapshot.vibeProfile.value(for: .drama)
        if paletteStrategy == .dramaSlots {
            let slotLabel: String
            if drama <= 3 { slotLabel = "0 statement / 3 grounding (quiet)" }
            else if drama <= 4 { slotLabel = "1 statement / 2 grounding (moderate)" }
            else { slotLabel = "2 statement / 1 grounding (bold)" }
            print("\(p) Drama=\(drama) → slot allocation: \(slotLabel)")
        } else {
            print("\(p) Drama=\(drama) (no slot allocation — pure ranking)")
        }
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
        let vibCoeff = cal.stage2Sensitivity.vibrancyCoeff
        let vibMod = (vibPush - vibPull) * vibCoeff

        print("\(p) Vibrancy:")
        print("\(p)   Style Guide saturation: \(satLabel) → baseline=\(f2(vibBaseline))")
        print("\(p)   Push (drama+edge)/21 = \(f3(vibPush))   Pull (utility+classic)/21 = \(f3(vibPull))")
        print("\(p)   Modulation: (\(f3(vibPush)) - \(f3(vibPull))) × \(f2(vibCoeff)) = \(f3(vibMod))")
        print("\(p)   Final: \(f2(vibBaseline)) + \(f3(vibMod)) = \(f3(payload.vibrancy))")

        let conBaseline: Double
        switch blueprint.palette.variables?.contrast {
        case .low:    conBaseline = 0.25
        case .medium: conBaseline = 0.50
        case .high:   conBaseline = 0.75
        case nil:     conBaseline = 0.50
        }
        let visNorm = axes.visibility / 10.0
        let conCoeff = cal.stage2Sensitivity.contrastCoeff
        let conMod = (visNorm - 0.5) * conCoeff

        print("\(p) Contrast:")
        print("\(p)   Style Guide contrast: \(conLabel) → baseline=\(f2(conBaseline))")
        print("\(p)   Visibility axis normalised: \(f3(visNorm))")
        print("\(p)   Modulation: (\(f3(visNorm)) - 0.5) × \(f2(conCoeff)) = \(f3(conMod))")
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

        // Essence conflict resolution trace (Stage 1 only)
        if let conflictTrace = essenceConflictTrace {
            for s in conflictTrace.suppressions {
                print("\(p) ⚠️ CONFLICT RESOLVED: \(s.suppressedCategory.uppercased()) (score=\(f3(s.suppressedScore))) suppressed — conflicts with \(s.keptCategory.uppercased()) [\(s.reason)]")
                if let rep = s.replacementCategory, let repScore = s.replacementScore {
                    print("\(p)   → Promoted \(rep.uppercased()) (score=\(f3(repScore))) into top 3")
                }
            }
        }

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
        print("\(p)   Structured ← → Relaxed:")
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
