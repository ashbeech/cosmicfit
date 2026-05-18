//
//  DailyFitTypes.swift
//  Cosmic Fit
//
//  Foundation types for the Daily Fit 2-stage pipeline.
//  Phase 0: Data contracts only — no logic beyond validation.
//

import Foundation

// MARK: - Stage 1 Nested Types

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
}

// MARK: - Stage 1 Output

/// Pure astrological distillation for a given day and user. No style decisions.
struct DailyEnergySnapshot: Codable {
    /// Six-energy vibe profile (21-point budget). Source: natal + transits + lunar + progressed.
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
    /// All 14 categories with their daily scores.
    let allScores: [StyleEssenceScore]
    /// Top 3 categories by score — the ones rendered on the radar chart.
    let visibleCategories: [StyleEssenceScore]
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
    /// 0.0 = Structured, 1.0 = Draped
    let structuredDraped: Double
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

    // MARK: - Backward-Compatible Decoding

    private enum CodingKeys: String, CodingKey {
        case tarotCard, styleEditVariant, dailyPalette, vibrancy, contrast, metalTone
        case essenceProfile, silhouetteProfile, vibeBreakdown, axes
        case dominantTransits, lunarContext, dailyTextures, dailyPattern, generatedAt
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
    }

    init(tarotCard: TarotCard, styleEditVariant: StyleEditVariant,
         dailyPalette: DailyPaletteSelection, vibrancy: Double,
         contrast: Double, metalTone: Double,
         essenceProfile: StyleEssenceProfile,
         silhouetteProfile: SilhouetteProfile,
         vibeBreakdown: VibeBreakdown, axes: DerivedAxes,
         dominantTransits: [DailyTransitSummary],
         lunarContext: LunarContext, dailyTextures: [String],
         dailyPattern: String?, generatedAt: Date) {
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

        static let `default` = Stage2Sensitivity(
            paletteJitter: 0.08, vibrancyCoeff: 0.35,
            contrastCoeff: 0.40, silhouetteAxisScale: 2.0,
            metalNudgePerHit: 0.10
        )
    }

    let sourceWeights: SourceWeights
    let signEnergyMap: SignEnergyMap
    let planetAxisMap: PlanetAxisMap
    let selectionWeights: SelectionWeights
    let axisTuning: AxisTuning
    let stage2Sensitivity: Stage2Sensitivity
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
            "Aries":       [.classic: 0.9,  .playful: 1.3,  .romantic: 1.0, .utility: 1.0, .drama: 1.4,  .edge: 1.2],
            "Taurus":      [.classic: 1.5,  .playful: 0.9,  .romantic: 1.3, .utility: 1.2, .drama: 0.85, .edge: 1.0],
            "Gemini":      [.classic: 0.85, .playful: 1.5,  .romantic: 1.0, .utility: 1.0, .drama: 1.0,  .edge: 1.2],
            "Cancer":      [.classic: 1.1,  .playful: 1.0,  .romantic: 1.4, .utility: 1.2, .drama: 0.95, .edge: 1.0],
            "Leo":         [.classic: 0.9,  .playful: 1.3,  .romantic: 1.0, .utility: 0.9, .drama: 1.5,  .edge: 1.0],
            "Virgo":       [.classic: 1.5,  .playful: 0.95, .romantic: 0.9, .utility: 1.4, .drama: 0.85, .edge: 1.0],
            "Libra":       [.classic: 1.3,  .playful: 1.2,  .romantic: 1.4, .utility: 1.0, .drama: 0.95, .edge: 0.9],
            "Scorpio":     [.classic: 1.0,  .playful: 0.85, .romantic: 0.9, .utility: 1.1, .drama: 1.5,  .edge: 1.3],
            "Sagittarius": [.classic: 0.9,  .playful: 1.4,  .romantic: 1.0, .utility: 1.0, .drama: 1.2,  .edge: 1.2],
            "Capricorn":   [.classic: 1.5,  .playful: 0.85, .romantic: 0.95, .utility: 1.4, .drama: 1.0, .edge: 1.0],
            "Aquarius":    [.classic: 0.85, .playful: 1.2,  .romantic: 0.9, .utility: 1.1, .drama: 1.0,  .edge: 1.5],
            "Pisces":      [.classic: 0.9,  .playful: 1.1,  .romantic: 1.5, .utility: 1.0, .drama: 1.0,  .edge: 1.2],
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
            planetAxisMap: planets,
            selectionWeights: selection,
            axisTuning: .default,
            stage2Sensitivity: .default
        )
    }()
}
