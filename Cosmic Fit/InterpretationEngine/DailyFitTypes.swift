//
//  DailyFitTypes.swift
//  Cosmic Fit
//
//  Foundation types for the Daily Fit 2-stage pipeline.
//  Phase 0: Data contracts only — no logic beyond validation.
//

import Foundation

// MARK: - Stage 1 Nested Types

// MARK: - Sky Salience (Adaptive Transit Weighting)

/// Speed-weighted, freshness-aware salience profile for the day's transits.
/// Replaces fixed planet weights with adaptive scoring that surfaces fast-moving,
/// currently-active signals over slow background outer-planet noise.
/// Diagnostic fuel for Plan 2 — kept separate from production dominant-transit logic.
struct SkySalienceProfile: Codable, Equatable {
    struct SalienceEntry: Codable, Equatable {
        let planet: String
        let aspect: String
        let natalTarget: String
        let rawStrength: Double
        let speedFactor: Double
        let freshnessBonus: Double
        let salience: Double
        let essenceCategory: StyleEssenceCategory?
    }

    let entries: [SalienceEntry]
    let topDrivers: [SalienceEntry]
    let dominantNarrative: String?
}

/// Lightweight summary of an active transit for Stage 2 and UI consumption.
struct DailyTransitSummary: Codable, Equatable {
    /// Transiting planet name, e.g. "Mars"
    let transitPlanet: String
    /// Natal planet being aspected, e.g. "Venus"
    let natalPlanet: String
    /// Aspect type, e.g. "conjunction", "trine", "square"
    let aspect: String
    /// Normalised strength of the transit, 0.0–1.0
    let strength: Double
}

/// A named special lunar event for the day — the rarer `LunarEvent.isSpecialEvent` days
/// (Supermoon / Micromoon / Solar Eclipse / Lunar Eclipse). Sky Forward v1.0.2 §6h follow-up:
/// plain full/new moons already surface through `phaseName`, so only special events are attached.
struct NamedLunarEventSummary: Codable, Equatable {
    /// User-facing label, e.g. "Supermoon", "Lunar Eclipse".
    let label: String
    /// 0–1 significance scalar from the detector (1 = exact/central).
    let strength: Double
}

/// Lunar phase context for the day's energy.
struct LunarContext: Codable, Equatable {
    /// Human-readable phase name, e.g. "Waxing Crescent", "Full Moon"
    let phaseName: String
    /// Whether the moon is waxing (true) or waning (false)
    let isWaxing: Bool
    /// Element derived from the lunar phase family (not the moon's zodiac sign):
    /// new/full → Water, quarters → Fire, crescents → Air, gibbous → Earth.
    let element: String
    /// Raw phase angle in degrees, 0–360, for computation
    let phaseDegrees: Double
    /// Named special lunar event (supermoon/micromoon/eclipse). nil on ordinary days, on
    /// every pre-v1.0.2 engine path, and on legacy frozen payloads (the key is omitted when
    /// nil, so v1.0.1 output stays byte-identical).
    let namedEvent: NamedLunarEventSummary?

    init(phaseName: String, isWaxing: Bool, element: String, phaseDegrees: Double,
         namedEvent: NamedLunarEventSummary? = nil) {
        self.phaseName = phaseName
        self.isWaxing = isWaxing
        self.element = element
        self.phaseDegrees = phaseDegrees
        self.namedEvent = namedEvent
    }
}

// MARK: - Stage 1 Output

/// Pure astrological distillation for a given day and user. No style decisions.
struct DailyEnergySnapshot: Codable {
    /// Blended vibe profile (21-point budget) used for tarot/palette selection.
    let vibeProfile: VibeBreakdown
    /// Four orthogonal style-manifestation axes, each 1–10. Source: planet weights.
    let axes: DerivedAxes
    /// Top active transits for the day, sorted by strength descending.
    let dominantTransits: [DailyTransitSummary]
    /// Lunar phase context: phase name, waxing/waning, element, degrees.
    let lunarContext: LunarContext
    /// Deterministic seed derived from date + profile, for reproducible randomness.
    let dailySeed: Int
    /// Hash of the user's natal profile, for cache invalidation and tracking.
    let profileHash: String
    /// Timestamp of generation. Set from the supplied date parameter, NOT Date().
    let generatedAt: Date
    /// Natal+progressed vibe only (Stage 1): chart anchor — who you are.
    let chartVibeProfile: VibeBreakdown?
    /// Transits+lunar+current-sun vibe only (Stage 1): today's outside energy.
    let skyVibeProfile: VibeBreakdown?
    /// Natal+progressed axes only (Stage 1): chart anchor for silhouette/essence delta.
    let chartAxes: DerivedAxes?
    /// Raw (pre-normalisation) vibe scores for tie-breaking when integer points are equal.
    let vibeRawScores: [Energy: Double]?
    /// Adaptive salience profile for stage1_experimental diagnostics. nil in production.
    let skySalience: SkySalienceProfile?

    init(
        vibeProfile: VibeBreakdown,
        axes: DerivedAxes,
        dominantTransits: [DailyTransitSummary],
        lunarContext: LunarContext,
        dailySeed: Int,
        profileHash: String,
        generatedAt: Date,
        chartVibeProfile: VibeBreakdown? = nil,
        skyVibeProfile: VibeBreakdown? = nil,
        chartAxes: DerivedAxes? = nil,
        vibeRawScores: [Energy: Double]? = nil,
        skySalience: SkySalienceProfile? = nil
    ) {
        self.vibeProfile = vibeProfile
        self.axes = axes
        self.dominantTransits = dominantTransits
        self.lunarContext = lunarContext
        self.dailySeed = dailySeed
        self.profileHash = profileHash
        self.generatedAt = generatedAt
        self.chartVibeProfile = chartVibeProfile
        self.skyVibeProfile = skyVibeProfile
        self.chartAxes = chartAxes
        self.vibeRawScores = vibeRawScores
        self.skySalience = skySalience
    }
}

// MARK: - Stage 2 Nested Types

// MARK: - Style Essence (14-Category Radar System)

/// The 14 style-energy categories that describe the outfit energy of a day.
/// Each category has a fixed angular position on a 14-axis radar chart.
enum StyleEssenceCategory: String, CaseIterable, Codable {
    case edgy
    case romantic
    case classic
    case utility
    case drama
    case playful
    case polished
    case effortless
    case sensual
    case magnetic
    case grounded
    case eclectic
    case minimal
    case maximalist

    /// Display label for the UI (uppercased).
    var label: String { rawValue.uppercased() }

    /// Fixed angle in radians on the 14-axis radar. Evenly spaced,
    /// starting from top-centre (−π/2) going clockwise.
    var angle: Double {
        guard let idx = Self.allCases.firstIndex(of: self) else { return 0 }
        let step = (2.0 * .pi) / Double(Self.allCases.count)
        return -.pi / 2.0 + Double(idx) * step
    }
}

/// A single category's score on the radar.
struct StyleEssenceScore: Codable, Equatable {
    let category: StyleEssenceCategory
    /// Normalised strength, 0.0–1.0.
    let score: Double
}

/// Full 14-category essence profile with top-3 selection.
struct StyleEssenceProfile: Codable, Equatable {
    /// All 14 categories with their daily scores (today's signal in Stage 1 sky-forward mode).
    let allScores: [StyleEssenceScore]
    /// Top 3 categories by score — the ones rendered on the radar chart.
    let visibleCategories: [StyleEssenceScore]
    /// Chart-anchor scores (Stage 1 only): baseline essence from natal chart. nil in production.
    let chartAnchorScores: [StyleEssenceScore]?

    init(
        allScores: [StyleEssenceScore],
        visibleCategories: [StyleEssenceScore],
        chartAnchorScores: [StyleEssenceScore]? = nil
    ) {
        self.allScores = allScores
        self.visibleCategories = visibleCategories
        self.chartAnchorScores = chartAnchorScores
    }
}

/// Legacy three-vertex essence. Retained only for backward-compatible Codable
/// decoding of frozen payloads saved before the 14-category migration.
struct EssenceTriangle: Codable, Equatable {
    let classic: Double
    let edgy: Double
    let grounded: Double
}

/// Three bipolar silhouette scales. Each 0.0–1.0.
/// Style Guide (`CosmicBlueprint`) provides ~70-80% baseline; daily axes modulate ~20-30%.
struct SilhouetteProfile: Codable, Equatable {
    /// 0.0 = Masculine, 1.0 = Feminine
    let masculineFeminine: Double
    /// 0.0 = Angular, 1.0 = Rounded
    let angularRounded: Double
    /// 0.0 = Structured, 1.0 = Relaxed
    let structuredDraped: Double
    /// Style Guide keyword baseline (Stage 1 inspector reference only).
    var chartAnchorMF: Double?
    var chartAnchorAR: Double?
    var chartAnchorSD: Double?

    init(
        masculineFeminine: Double,
        angularRounded: Double,
        structuredDraped: Double,
        chartAnchorMF: Double? = nil,
        chartAnchorAR: Double? = nil,
        chartAnchorSD: Double? = nil
    ) {
        self.masculineFeminine = masculineFeminine
        self.angularRounded = angularRounded
        self.structuredDraped = structuredDraped
        self.chartAnchorMF = chartAnchorMF
        self.chartAnchorAR = chartAnchorAR
        self.chartAnchorSD = chartAnchorSD
    }
}

/// A single colour pick for the daily palette.
struct DailyColourPick: Codable, Equatable {
    /// Colour name, e.g. "Burnt Sienna"
    let name: String
    /// Hex value matching BlueprintColour.hexValue naming, e.g. "#A0522D"
    let hexValue: String
    /// Role from Style Guide palette, e.g. "core", "accent", "neutral", "support"
    let role: String
}

/// Three daily colours selected from the Style Guide palette.
struct DailyPaletteSelection: Codable, Equatable {
    /// Exactly 3 colours chosen for the day.
    let colours: [DailyColourPick]
    /// Full Style Guide palette hex values for the context ring.
    let allPaletteHexes: [String]
}

// MARK: - Stage 2 Output

/// Everything the Daily Fit UI needs to render. All fields populated; only
/// `dailyPattern` is optional (retained for diagnostics and future use).
struct DailyFitPayload: Codable {
    /// Selected tarot card for the day's headline.
    let tarotCard: TarotCard
    /// Chosen style-edit variant with dailyRitual and wardrobeReflection.
    let styleEditVariant: StyleEditVariant

    /// Three colours from the user's Style Guide palette.
    let dailyPalette: DailyPaletteSelection
    /// Style Guide–anchored vibrancy with energy modulation. Range 0.0–1.0.
    let vibrancy: Double
    /// Style Guide–anchored contrast with axes modulation. Range 0.0–1.0.
    let contrast: Double
    /// Metal tone: 0.0 = cool, 0.5 = mixed, 1.0 = warm. Style Guide–anchored.
    let metalTone: Double

    /// 14-category style essence radar profile (top 3 displayed).
    let essenceProfile: StyleEssenceProfile
    /// Three bipolar silhouette scales, Style Guide–anchored with axes modulation.
    let silhouetteProfile: SilhouetteProfile

    /// Full 6-energy vibe profile (passthrough from snapshot).
    let vibeBreakdown: VibeBreakdown
    /// Full 4-axis profile (passthrough from snapshot).
    let axes: DerivedAxes
    /// Active transits (passthrough from snapshot).
    let dominantTransits: [DailyTransitSummary]
    /// Lunar phase context (passthrough from snapshot).
    let lunarContext: LunarContext

    /// 2–3 texture names from Style Guide. Computed but not displayed in current UI.
    let dailyTextures: [String]
    /// Optional pattern from Style Guide. Retained for diagnostics/future.
    let dailyPattern: String?

    /// Timestamp of generation. Set from the supplied date parameter, NOT Date().
    let generatedAt: Date

    /// User-relative scale metadata for UI presentation. nil on legacy frozen payloads.
    let scalePresentation: PersonalScalePresentation?

    /// Resolved narrative brief (Stage 1 only). nil for production engine.
    let narrativeBrief: DailyNarrativeBrief?

    /// Engine preset id stamped when frozen (optional in JSON; missing → production).
    let dailyFitEngineId: String?

    /// Calibration fingerprint stamped when frozen (B3 cache invalidation). `nil` on legacy
    /// frozen payloads (pre-v1.0.2) → treated as a mismatch against any non-nil current fingerprint,
    /// so a fingerprint-only cutover (engine id stays `production`) busts the cache and users see
    /// the new read instead of a stale one.
    let calibrationFingerprint: String?

    /// Stored id for freeze/load checks; missing field decodes as production.
    var resolvedDailyFitEngineId: String {
        dailyFitEngineId ?? DailyFitEngineRegistry.productionId
    }

    // MARK: - Backward-Compatible Decoding

    private enum CodingKeys: String, CodingKey {
        case tarotCard, styleEditVariant, dailyPalette, vibrancy, contrast, metalTone
        case essenceProfile, silhouetteProfile, vibeBreakdown, axes
        case dominantTransits, lunarContext, dailyTextures, dailyPattern, generatedAt
        case dailyFitEngineId, calibrationFingerprint, narrativeBrief, scalePresentation
        case essenceTriangle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tarotCard = try c.decode(TarotCard.self, forKey: .tarotCard)
        styleEditVariant = try c.decode(StyleEditVariant.self, forKey: .styleEditVariant)
        dailyPalette = try c.decode(DailyPaletteSelection.self, forKey: .dailyPalette)
        vibrancy = try c.decode(Double.self, forKey: .vibrancy)
        contrast = try c.decode(Double.self, forKey: .contrast)
        metalTone = try c.decode(Double.self, forKey: .metalTone)
        silhouetteProfile = try c.decode(SilhouetteProfile.self, forKey: .silhouetteProfile)
        vibeBreakdown = try c.decode(VibeBreakdown.self, forKey: .vibeBreakdown)
        axes = try c.decode(DerivedAxes.self, forKey: .axes)
        dominantTransits = try c.decode([DailyTransitSummary].self, forKey: .dominantTransits)
        lunarContext = try c.decode(LunarContext.self, forKey: .lunarContext)
        dailyTextures = try c.decode([String].self, forKey: .dailyTextures)
        dailyPattern = try c.decodeIfPresent(String.self, forKey: .dailyPattern)
        generatedAt = try c.decode(Date.self, forKey: .generatedAt)
        dailyFitEngineId = try c.decodeIfPresent(String.self, forKey: .dailyFitEngineId)
        calibrationFingerprint = try c.decodeIfPresent(String.self, forKey: .calibrationFingerprint)
        scalePresentation = try c.decodeIfPresent(PersonalScalePresentation.self, forKey: .scalePresentation)
        narrativeBrief = try c.decodeIfPresent(DailyNarrativeBrief.self, forKey: .narrativeBrief)

        if let newProfile = try? c.decode(StyleEssenceProfile.self, forKey: .essenceProfile) {
            essenceProfile = newProfile
        } else if let legacy = try? c.decode(EssenceTriangle.self, forKey: .essenceTriangle) {
            essenceProfile = StyleEssenceProfile.fromLegacy(legacy)
        } else {
            essenceProfile = StyleEssenceProfile.neutral
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tarotCard, forKey: .tarotCard)
        try c.encode(styleEditVariant, forKey: .styleEditVariant)
        try c.encode(dailyPalette, forKey: .dailyPalette)
        try c.encode(vibrancy, forKey: .vibrancy)
        try c.encode(contrast, forKey: .contrast)
        try c.encode(metalTone, forKey: .metalTone)
        try c.encode(essenceProfile, forKey: .essenceProfile)
        try c.encode(silhouetteProfile, forKey: .silhouetteProfile)
        try c.encode(vibeBreakdown, forKey: .vibeBreakdown)
        try c.encode(axes, forKey: .axes)
        try c.encode(dominantTransits, forKey: .dominantTransits)
        try c.encode(lunarContext, forKey: .lunarContext)
        try c.encode(dailyTextures, forKey: .dailyTextures)
        try c.encodeIfPresent(dailyPattern, forKey: .dailyPattern)
        try c.encode(generatedAt, forKey: .generatedAt)
        try c.encodeIfPresent(dailyFitEngineId, forKey: .dailyFitEngineId)
        try c.encodeIfPresent(calibrationFingerprint, forKey: .calibrationFingerprint)
        try c.encodeIfPresent(scalePresentation, forKey: .scalePresentation)
        try c.encodeIfPresent(narrativeBrief, forKey: .narrativeBrief)
    }

    init(tarotCard: TarotCard, styleEditVariant: StyleEditVariant,
         dailyPalette: DailyPaletteSelection, vibrancy: Double,
         contrast: Double, metalTone: Double,
         essenceProfile: StyleEssenceProfile,
         silhouetteProfile: SilhouetteProfile,
         vibeBreakdown: VibeBreakdown, axes: DerivedAxes,
         dominantTransits: [DailyTransitSummary],
         lunarContext: LunarContext, dailyTextures: [String],
         dailyPattern: String?, generatedAt: Date,
         dailyFitEngineId: String? = nil,
         calibrationFingerprint: String? = nil,
         scalePresentation: PersonalScalePresentation? = nil,
         narrativeBrief: DailyNarrativeBrief? = nil) {
        self.tarotCard = tarotCard
        self.styleEditVariant = styleEditVariant
        self.dailyPalette = dailyPalette
        self.vibrancy = vibrancy
        self.contrast = contrast
        self.metalTone = metalTone
        self.essenceProfile = essenceProfile
        self.silhouetteProfile = silhouetteProfile
        self.vibeBreakdown = vibeBreakdown
        self.axes = axes
        self.dominantTransits = dominantTransits
        self.lunarContext = lunarContext
        self.dailyTextures = dailyTextures
        self.dailyPattern = dailyPattern
        self.generatedAt = generatedAt
        self.dailyFitEngineId = dailyFitEngineId
        self.calibrationFingerprint = calibrationFingerprint
        self.scalePresentation = scalePresentation
        self.narrativeBrief = narrativeBrief
    }

    /// Copy with engine id stamped at freeze time (generation paths omit this field).
    func withDailyFitEngineId(_ engineId: String) -> DailyFitPayload {
        DailyFitPayload(
            tarotCard: tarotCard,
            styleEditVariant: styleEditVariant,
            dailyPalette: dailyPalette,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone,
            essenceProfile: essenceProfile,
            silhouetteProfile: silhouetteProfile,
            vibeBreakdown: vibeBreakdown,
            axes: axes,
            dominantTransits: dominantTransits,
            lunarContext: lunarContext,
            dailyTextures: dailyTextures,
            dailyPattern: dailyPattern,
            generatedAt: generatedAt,
            dailyFitEngineId: engineId,
            calibrationFingerprint: calibrationFingerprint,
            scalePresentation: scalePresentation,
            narrativeBrief: narrativeBrief
        )
    }

    /// Copy with the calibration fingerprint stamped at freeze time (B3 cache invalidation).
    func withCalibrationFingerprint(_ fingerprint: String?) -> DailyFitPayload {
        DailyFitPayload(
            tarotCard: tarotCard,
            styleEditVariant: styleEditVariant,
            dailyPalette: dailyPalette,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone,
            essenceProfile: essenceProfile,
            silhouetteProfile: silhouetteProfile,
            vibeBreakdown: vibeBreakdown,
            axes: axes,
            dominantTransits: dominantTransits,
            lunarContext: lunarContext,
            dailyTextures: dailyTextures,
            dailyPattern: dailyPattern,
            generatedAt: generatedAt,
            dailyFitEngineId: dailyFitEngineId,
            calibrationFingerprint: fingerprint,
            scalePresentation: scalePresentation,
            narrativeBrief: narrativeBrief
        )
    }

    /// Copy with narrative brief attached (pipeline use only).
    func withNarrativeBrief(_ brief: DailyNarrativeBrief?) -> DailyFitPayload {
        DailyFitPayload(
            tarotCard: tarotCard,
            styleEditVariant: styleEditVariant,
            dailyPalette: dailyPalette,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone,
            essenceProfile: essenceProfile,
            silhouetteProfile: silhouetteProfile,
            vibeBreakdown: vibeBreakdown,
            axes: axes,
            dominantTransits: dominantTransits,
            lunarContext: lunarContext,
            dailyTextures: dailyTextures,
            dailyPattern: dailyPattern,
            generatedAt: generatedAt,
            dailyFitEngineId: dailyFitEngineId,
            calibrationFingerprint: calibrationFingerprint,
            scalePresentation: scalePresentation,
            narrativeBrief: brief
        )
    }
}

// MARK: - StyleEssenceProfile Helpers

extension StyleEssenceProfile {
    /// Converts a legacy 3-vertex EssenceTriangle into a 14-category profile.
    /// The three legacy values map to their closest new categories; the remaining
    /// 11 categories receive a small uniform score.
    static func fromLegacy(_ et: EssenceTriangle) -> StyleEssenceProfile {
        let baseScore = 0.02
        var scores: [StyleEssenceScore] = StyleEssenceCategory.allCases.map {
            StyleEssenceScore(category: $0, score: baseScore)
        }
        let mapping: [(StyleEssenceCategory, Double)] = [
            (.classic, et.classic), (.edgy, et.edgy), (.grounded, et.grounded)
        ]
        for (cat, value) in mapping {
            if let idx = scores.firstIndex(where: { $0.category == cat }) {
                scores[idx] = StyleEssenceScore(category: cat, score: value)
            }
        }
        let sorted = scores.sorted { $0.score > $1.score }
        return StyleEssenceProfile(allScores: scores, visibleCategories: Array(sorted.prefix(3)))
    }

    /// Even-weighted fallback when no data is available.
    static let neutral: StyleEssenceProfile = {
        let even = 1.0 / Double(StyleEssenceCategory.allCases.count)
        let scores = StyleEssenceCategory.allCases.map {
            StyleEssenceScore(category: $0, score: even)
        }
        return StyleEssenceProfile(allScores: scores, visibleCategories: Array(scores.prefix(3)))
    }()
}

// MARK: - Narrative Resolver Types

/// How chart identity and sky weather relate on a given day.
enum NarrativeRelationship: String, Codable, Equatable, CaseIterable {
    case reinforce
    case stretch
    case soften
    case contrast
}

/// Deprecated v1 copy container; decode-only for legacy freezes. Not generated or displayed.
struct DailyNarrativeBrief: Codable, Equatable {
    let anchorCategories: [StyleEssenceCategory]
    let weatherCategories: [StyleEssenceCategory]
    let relationship: NarrativeRelationship
    let resolvedTheme: String
    let instruction: String
    let avoid: String
    let foundationControls: [String]
    let accentControls: [String]
    let essenceCaption: String?
    let paletteCaption: String?
    let scalesCaption: String?
}

/// Diagnostic trace for narrative resolution decisions.
struct NarrativeTrace: Codable, Equatable {
    let anchorTop3: [String]
    let weatherTop3: [String]
    let overlapCount: Int
    let silhouetteDeltaMF: Double?
    let silhouetteDeltaAR: Double?
    let silhouetteDeltaSD: Double?
    let chosenRelationship: NarrativeRelationship
    let templateKey: String
}

/// Inspector trace for narrative selection bias (trace export only).
struct NarrativeIntentTrace: Codable, Equatable {
    let relationship: String
    let anchorTop3: [String]
    let weatherTop3: [String]
    let accentCategory: String
    let foundationCategory: String
    let overlapCount: Int
    let themeLexiconKey: String?
    let coherenceGap: String?
}

/// Post-selection coherence heuristic for QA (trace export only).
struct NarrativeCoherenceTrace: Codable, Equatable {
    let paletteAccentRoleMatch: Bool
    let paletteStatementSlotCount: Int
    let tarotCategoryBoostApplied: Bool
    let tarotVariantScored: Bool
    let variantBridgeSimilarity: Double?
    let bridgePass: Bool?
    let overallPass: Bool
}

/// Inspector-only QA for tarot style-edit bridge quality (trace export).
struct NarrativeBridgeTrace: Codable, Equatable {
    let selectedCardName: String
    let selectedVariantTitle: String
    let selectedVariantIndex: Int
    let variantBridgeSimilarity: Double
    let bestPairTotalScore: Double
    let runnerUpPairTotalScore: Double
    let bridgeMargin: Double
    let bestVariantSimilarityInPool: Double
    let funnelCardCount: Int
    let pairsEvaluated: Int
    let contrastWeatherWins: Bool?
    let bridgePass: Bool
    let variantRecencySwapped: Bool
    let variantFormBridgeSimilarity: Double?
    let formBridgePass: Bool?
    let structureGateApplied: Bool?

    init(
        selectedCardName: String, selectedVariantTitle: String, selectedVariantIndex: Int,
        variantBridgeSimilarity: Double, bestPairTotalScore: Double, runnerUpPairTotalScore: Double,
        bridgeMargin: Double, bestVariantSimilarityInPool: Double,
        funnelCardCount: Int, pairsEvaluated: Int,
        contrastWeatherWins: Bool?, bridgePass: Bool,
        variantRecencySwapped: Bool = false,
        variantFormBridgeSimilarity: Double? = nil,
        formBridgePass: Bool? = nil,
        structureGateApplied: Bool? = nil
    ) {
        self.selectedCardName = selectedCardName
        self.selectedVariantTitle = selectedVariantTitle
        self.selectedVariantIndex = selectedVariantIndex
        self.variantBridgeSimilarity = variantBridgeSimilarity
        self.bestPairTotalScore = bestPairTotalScore
        self.runnerUpPairTotalScore = runnerUpPairTotalScore
        self.bridgeMargin = bridgeMargin
        self.bestVariantSimilarityInPool = bestVariantSimilarityInPool
        self.funnelCardCount = funnelCardCount
        self.pairsEvaluated = pairsEvaluated
        self.contrastWeatherWins = contrastWeatherWins
        self.bridgePass = bridgePass
        self.variantRecencySwapped = variantRecencySwapped
        self.variantFormBridgeSimilarity = variantFormBridgeSimilarity
        self.formBridgePass = formBridgePass
        self.structureGateApplied = structureGateApplied
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        selectedCardName = try c.decode(String.self, forKey: .selectedCardName)
        selectedVariantTitle = try c.decode(String.self, forKey: .selectedVariantTitle)
        selectedVariantIndex = try c.decode(Int.self, forKey: .selectedVariantIndex)
        variantBridgeSimilarity = try c.decode(Double.self, forKey: .variantBridgeSimilarity)
        bestPairTotalScore = try c.decode(Double.self, forKey: .bestPairTotalScore)
        runnerUpPairTotalScore = try c.decode(Double.self, forKey: .runnerUpPairTotalScore)
        bridgeMargin = try c.decode(Double.self, forKey: .bridgeMargin)
        bestVariantSimilarityInPool = try c.decode(Double.self, forKey: .bestVariantSimilarityInPool)
        funnelCardCount = try c.decode(Int.self, forKey: .funnelCardCount)
        pairsEvaluated = try c.decode(Int.self, forKey: .pairsEvaluated)
        contrastWeatherWins = try c.decodeIfPresent(Bool.self, forKey: .contrastWeatherWins)
        bridgePass = try c.decode(Bool.self, forKey: .bridgePass)
        variantRecencySwapped = try c.decodeIfPresent(Bool.self, forKey: .variantRecencySwapped) ?? false
        variantFormBridgeSimilarity = try c.decodeIfPresent(Double.self, forKey: .variantFormBridgeSimilarity)
        formBridgePass = try c.decodeIfPresent(Bool.self, forKey: .formBridgePass)
        structureGateApplied = try c.decodeIfPresent(Bool.self, forKey: .structureGateApplied)
    }
}

// MARK: - Daily Narrative Plan (Plan 2)

/// Intensity level derived from sky salience concentration.
enum IntensityLevel: String, Codable, CaseIterable, Equatable {
    case low, moderate, high, peak
}

/// Tempo emphasis derived from Moon's position in salience profile.
enum TempoEmphasis: String, Codable, CaseIterable, Equatable {
    case slow, steady, dynamic
}

/// Plan-owned texture selection constraint.
struct TextureDirective: Codable, Equatable {
    let preferredAffinities: [String]
    let intensityBias: Double
}

/// Plan-owned pattern selection constraint.
struct PatternDirective: Codable, Equatable {
    let gateEnabled: Bool
    let preferredEnergy: String?
}

/// Single forward-looking narrative decision for the day.
/// Decided BEFORE any surface is selected; every visible surface reads from this plan.
struct DailyNarrativePlan: Codable, Equatable {
    let relationship: NarrativeRelationship
    let accentEssence: StyleEssenceCategory
    let supportingEssences: [StyleEssenceCategory]
    let anchorEssences: [StyleEssenceCategory]

    let intensityLevel: IntensityLevel
    let tempoEmphasis: TempoEmphasis

    let targetVibrancy: Double
    let targetContrast: Double
    let targetMetalTone: Double
    let targetSilhouette: SilhouetteProfile

    let paletteDirective: PaletteDirective
    let tarotDirective: TarotDirective
    let scaleDirective: ScaleDirective?
    let textureDirective: TextureDirective
    let patternDirective: PatternDirective

    let salienceDrivers: [String]
    let skyJustification: String
    let coherenceTrace: CoherenceValidationResult?
}

/// Record of a single essence category suppressed to avoid contradictory narrative.
struct EssenceConflictSuppression: Codable, Equatable {
    let suppressedCategory: String
    let suppressedScore: Double
    let keptCategory: String
    let replacementCategory: String?
    let replacementScore: Double?
    let reason: String
}

/// Trace of essence conflict resolution applied to the visible top 3 (Stage 1 only).
struct EssenceConflictTrace: Codable, Equatable {
    let suppressions: [EssenceConflictSuppression]
}

// MARK: - Calibration Surface

/// Single config surface for every tunable weight in the Daily Fit pipeline.
/// Code-defined (not serialised). All nested structs are Equatable.
struct DailyFitCalibration: Equatable {

    /// How much each astrological source contributes to the energy snapshot.
    /// All values 0–1, must sum to 1.0.
    struct SourceWeights: Equatable {
        /// Stable natal foundation. ~0.40.
        let natal: Double
        /// Daily variation driver from transits. ~0.25.
        let transits: Double
        /// Emotional/cyclical rhythm from lunar phase. ~0.15.
        let lunarPhase: Double
        /// Slow personal evolution from progressed chart. ~0.15.
        let progressed: Double
        /// Seasonal background colour from current sun sign. ~0.05.
        let currentSun: Double

        /// True when the five weights sum to 1.0 (within floating-point tolerance).
        var isNormalised: Bool {
            abs((natal + transits + lunarPhase + progressed + currentSun) - 1.0) < 0.001
        }
    }

    /// Controls where natal Sun `signEnergyMap` multipliers are applied.
    struct SignMultiplierPolicy: Equatable {
        /// Standard full-mix path and stage1 sky payload (`vibeProfile` / `skyVibeProfile`).
        let applyToDailyVibe: Bool
        /// stage1 chart anchor comparison slice only (`chartVibeProfile`).
        let applyToChartAnchor: Bool

        static let productionDefault = SignMultiplierPolicy(
            applyToDailyVibe: true, applyToChartAnchor: false
        )
        static let stage1OptionA = SignMultiplierPolicy(
            applyToDailyVibe: false, applyToChartAnchor: true
        )
        static let off = SignMultiplierPolicy(
            applyToDailyVibe: false, applyToChartAnchor: false
        )
    }

    /// Per-sign energy multipliers. Each sign maps to all six Energy values.
    /// Multipliers cluster around 1.0 (range ~0.85–1.5).
    struct SignEnergyMap: Equatable {
        /// [signName: [Energy: multiplier]]. 12 entries expected.
        let multipliers: [String: [Energy: Double]]

        /// Safe lookup with fallback to 1.0 (neutral).
        func multiplier(forSign sign: String, energy: Energy) -> Double {
            multipliers[sign]?[energy] ?? 1.0
        }
    }

    /// Per-planet axis contribution weights.
    struct PlanetAxisMap: Equatable {
        /// [planetName: [axisName: weight]]. 10 entries expected (Sun–Pluto).
        let weights: [String: [String: Double]]

        /// Safe lookup with fallback to 0.0 (no contribution).
        func weight(forPlanet planet: String, axis: String) -> Double {
            weights[planet]?[axis] ?? 0.0
        }
    }

    /// Stage 2 selection influence weights.
    struct SelectionWeights: Equatable {
        /// How much vibe breakdown influences Stage 2 selection.
        let vibeWeight: Double
        /// How much axes influence Stage 2 selection.
        let axisWeight: Double
        /// Extra weight when a transit's planet aligns with selection.
        let transitBoost: Double
    }

    /// Axis evaluation tuning: sigmoid spread and jitter range.
    struct AxisTuning: Equatable {
        /// Multiplier inside tanh(raw × spread). Higher = more extreme axis values.
        let sigmoidSpread: Double
        /// Symmetric jitter applied per axis from seeded RNG.
        let jitterRange: Double

        static let `default` = AxisTuning(sigmoidSpread: 1.4, jitterRange: 0.18)
    }

    /// How 3 daily palette colours are selected from the Style Guide pool.
    enum PaletteSelectionStrategy: String, Equatable {
        /// Drama-driven statement/grounding slot quotas (production default).
        case dramaSlots
        /// Pure score ranking with at-least-one-core anchor.
        case coreAnchoredRanking
        /// Pure top-3 by sky vibe score (Stage 1 experimental).
        case pureSkyScoring
    }

    /// Stage 2 output sensitivity: palette, scales, silhouette coefficients.
    struct Stage2Sensitivity: Equatable {
        /// Palette colour scoring jitter ceiling.
        let paletteJitter: Double
        /// Vibrancy modulation coefficient (push-pull × this).
        let vibrancyCoeff: Double
        /// Contrast modulation coefficient (vis-0.5 × this).
        let contrastCoeff: Double
        /// Silhouette axis modulation multiplier (applied to each axis term).
        let silhouetteAxisScale: Double
        /// Metal tone transit nudge per hit.
        let metalNudgePerHit: Double
        /// Which palette selection algorithm to use.
        let paletteSelectionStrategy: PaletteSelectionStrategy

        init(paletteJitter: Double, vibrancyCoeff: Double,
             contrastCoeff: Double, silhouetteAxisScale: Double,
             metalNudgePerHit: Double,
             paletteSelectionStrategy: PaletteSelectionStrategy = .dramaSlots) {
            self.paletteJitter = paletteJitter
            self.vibrancyCoeff = vibrancyCoeff
            self.contrastCoeff = contrastCoeff
            self.silhouetteAxisScale = silhouetteAxisScale
            self.metalNudgePerHit = metalNudgePerHit
            self.paletteSelectionStrategy = paletteSelectionStrategy
        }

        static let `default` = Stage2Sensitivity(
            paletteJitter: 0.08, vibrancyCoeff: 0.35,
            contrastCoeff: 0.40, silhouetteAxisScale: 2.0,
            metalNudgePerHit: 0.10
        )
    }

    /// Stage-1 narrative selection tunables (§15.6). nil on production presets.
    struct NarrativeSelectionTuning: Equatable {
        let categoryBoostWeight: Double
        let rolePreferenceBonus: Double
        let categoryEnergyWeight: Double
        let narrativePaletteJitter: Double
        let softenVibrancyCap: Double
        let softenContrastCap: Double
        let softenBaselineBlend: Double
        let intenseAnchorRestrainedWeatherBlend: Double

        // Tarot bridge tunables (§5.4)
        let variantBridgeWeight: Double
        let bridgeCandidatePoolSize: Int
        let minVariantBridgeSimilarity: Double
        let minBridgeMargin: Double
        let pairScoreTieEpsilon: Double

        // Tarot form bridge tunables
        let variantFormBridgeWeight: Double
        let structureSkyWeight: Double
        let structureSilhouetteWeight: Double
        let minFormBridgeSimilarity: Double
        let structureVariantStrategyFloor: Int
        let structureSliderThreshold: Double

        // Visible essence recency gate
        let visibleEssenceCooldownDays: Int

        // Colour coverage/recency tunables (stage1 full-range selection)
        let colourCoverageWeight: Double
        let colourCoverageFloorEnabled: Bool
        let colourHeroRotationEnabled: Bool

        static let stage1Default = NarrativeSelectionTuning(
            categoryBoostWeight: 0.15,
            rolePreferenceBonus: 0.12,
            categoryEnergyWeight: 0.18,
            narrativePaletteJitter: 0.06,
            softenVibrancyCap: 0.72,
            softenContrastCap: 0.70,
            softenBaselineBlend: 0.70,
            intenseAnchorRestrainedWeatherBlend: 0.50,
            variantBridgeWeight: 0.25,
            bridgeCandidatePoolSize: 15,
            minVariantBridgeSimilarity: 0.50,
            minBridgeMargin: 0.01,
            pairScoreTieEpsilon: 0.01,
            variantFormBridgeWeight: 0.20,
            structureSkyWeight: 0.35,
            structureSilhouetteWeight: 0.65,
            minFormBridgeSimilarity: 0.45,
            structureVariantStrategyFloor: 50,
            structureSliderThreshold: 0.15,
            visibleEssenceCooldownDays: 2,
            colourCoverageWeight: 0.10,
            colourCoverageFloorEnabled: true,
            colourHeroRotationEnabled: true
        )
    }

    /// Sky-vibe source mix for the Sky Forward v1.0.2 sky-fidelity path (§audit Rec 6).
    /// Promotes the previously-hardcoded `DailyEnergyEngine.stage1SkySourceWeights`
    /// constant (transits/lunar/currentSun) into the fingerprinted calibration, so two
    /// v1.0.2 tunings no longer share a fingerprint. `nil` on every pre-v1.0.2 preset →
    /// the engine falls back to the legacy `stage1SkySourceWeights` constant (v1.0.1 path
    /// stays byte-identical). Natal/progressed are anchor-only (0) so are not represented.
    struct SkyVibeWeights: Equatable {
        let transits: Double
        let lunar: Double
        let currentSun: Double
    }

    let sourceWeights: SourceWeights
    let signEnergyMap: SignEnergyMap
    let signMultiplierPolicy: SignMultiplierPolicy
    /// When natal Sun `signEnergyMap` multiplier for an energy exceeds this value,
    /// matching `elementBoosts` are skipped (daily weather stacking dedupe). `nil` = legacy stacking.
    let elementBoostDedupeThreshold: Double?
    let planetAxisMap: PlanetAxisMap
    let selectionWeights: SelectionWeights
    let axisTuning: AxisTuning
    let stage2Sensitivity: Stage2Sensitivity
    let narrativeSelection: NarrativeSelectionTuning?
    /// v1.0.2 sky-fidelity: fingerprinted sky-vibe mix. `nil` → legacy `stage1SkySourceWeights`.
    let skyVibeWeights: SkyVibeWeights?
    /// v1.0.2 sky-fidelity: lunar significance amplification `k` in `1 + k·syzygyProximity`
    /// (=1 at exact full AND new moon, =0 at quarters). `nil` → no amplification (legacy path).
    let lunarSignificanceCoeff: Double?

    init(
        sourceWeights: SourceWeights,
        signEnergyMap: SignEnergyMap,
        signMultiplierPolicy: SignMultiplierPolicy,
        planetAxisMap: PlanetAxisMap,
        selectionWeights: SelectionWeights,
        axisTuning: AxisTuning,
        stage2Sensitivity: Stage2Sensitivity,
        elementBoostDedupeThreshold: Double? = 1.30,
        narrativeSelection: NarrativeSelectionTuning? = nil,
        skyVibeWeights: SkyVibeWeights? = nil,
        lunarSignificanceCoeff: Double? = nil
    ) {
        self.sourceWeights = sourceWeights
        self.signEnergyMap = signEnergyMap
        self.signMultiplierPolicy = signMultiplierPolicy
        self.planetAxisMap = planetAxisMap
        self.selectionWeights = selectionWeights
        self.axisTuning = axisTuning
        self.stage2Sensitivity = stage2Sensitivity
        self.elementBoostDedupeThreshold = elementBoostDedupeThreshold
        self.narrativeSelection = narrativeSelection
        self.skyVibeWeights = skyVibeWeights
        self.lunarSignificanceCoeff = lunarSignificanceCoeff
    }
}

// MARK: - Default Calibration

extension DailyFitCalibration {
    /// Sensible starting calibration derived from the legacy codebase.
    /// Source weights from the audit; sign multipliers from
    /// VibeBreakdownGenerator.getSunSignEnergyPreference(); planet-axis
    /// weights from DerivedAxesEvaluator axis evaluation functions.
    static let `default`: DailyFitCalibration = {
        let source = SourceWeights(
            natal: 0.28, transits: 0.35, lunarPhase: 0.22,
            progressed: 0.10, currentSun: 0.05
        )

        let signs = SignEnergyMap(multipliers: [
            "Aries":       [.classic: 0.95, .playful: 1.3,  .romantic: 1.0, .utility: 1.0, .drama: 1.35, .edge: 1.2],
            "Taurus":      [.classic: 1.5,  .playful: 0.9,  .romantic: 1.3, .utility: 1.2, .drama: 0.85, .edge: 1.0],
            "Gemini":      [.classic: 0.85, .playful: 1.5,  .romantic: 1.0, .utility: 1.0, .drama: 1.0,  .edge: 1.2],
            "Cancer":      [.classic: 1.1,  .playful: 1.0,  .romantic: 1.4, .utility: 1.05, .drama: 0.95, .edge: 1.0],
            "Leo":         [.classic: 0.9,  .playful: 1.3,  .romantic: 1.0, .utility: 0.95, .drama: 1.35, .edge: 1.0],
            "Virgo":       [.classic: 1.5,  .playful: 0.95, .romantic: 0.9, .utility: 1.30, .drama: 0.85, .edge: 1.0],
            "Libra":       [.classic: 1.3,  .playful: 1.30, .romantic: 1.4, .utility: 1.0, .drama: 0.95, .edge: 0.95],
            "Scorpio":     [.classic: 1.0,  .playful: 0.85, .romantic: 0.95, .utility: 1.00, .drama: 1.35, .edge: 1.3],
            "Sagittarius": [.classic: 0.9,  .playful: 1.4,  .romantic: 1.0, .utility: 1.0, .drama: 1.2,  .edge: 1.2],
            "Capricorn":   [.classic: 1.5,  .playful: 0.85, .romantic: 0.95, .utility: 1.4, .drama: 1.0, .edge: 1.0],
            "Aquarius":    [.classic: 0.85, .playful: 1.2,  .romantic: 0.9, .utility: 1.00, .drama: 1.0,  .edge: 1.5],
            "Pisces":      [.classic: 0.9,  .playful: 1.1,  .romantic: 1.5, .utility: 1.0, .drama: 1.0,  .edge: 1.25],
        ])

        let planets = PlanetAxisMap(weights: [
            "Sun":     ["action": 0.0, "tempo": 0.0, "strategy": 0.0, "visibility": 0.9],
            "Moon":    ["action": 0.0, "tempo": 0.7, "strategy": 0.0, "visibility": 0.0],
            "Mercury": ["action": 0.0, "tempo": 0.0, "strategy": 0.6, "visibility": 0.0],
            "Venus":   ["action": 0.0, "tempo": 0.0, "strategy": 0.0, "visibility": 0.3],
            "Mars":    ["action": 0.9, "tempo": 0.0, "strategy": 0.0, "visibility": 0.0],
            "Jupiter": ["action": 0.5, "tempo": 0.0, "strategy": 0.0, "visibility": 0.6],
            "Saturn":  ["action": 0.0, "tempo": 0.0, "strategy": 0.9, "visibility": 0.0],
            "Uranus":  ["action": 0.3, "tempo": 0.3, "strategy": 0.0, "visibility": 0.3],
            "Neptune": ["action": 0.0, "tempo": 0.2, "strategy": 0.0, "visibility": 0.1],
            "Pluto":   ["action": 0.3, "tempo": 0.0, "strategy": 0.3, "visibility": 0.2],
        ])

        let selection = SelectionWeights(
            vibeWeight: 0.50, axisWeight: 0.35, transitBoost: 0.15
        )

        return DailyFitCalibration(
            sourceWeights: source,
            signEnergyMap: signs,
            signMultiplierPolicy: .productionDefault,
            planetAxisMap: planets,
            selectionWeights: selection,
            axisTuning: .default,
            stage2Sensitivity: .default
        )
    }()
}
