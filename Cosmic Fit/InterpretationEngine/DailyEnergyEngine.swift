import Foundation

/// Stateless engine that converts raw astrological inputs into energy profiles.
enum DailyEnergyEngine {

    // MARK: - Public API

    /// Generate a 21-point VibeBreakdown from astrological inputs.
    /// This is pure astrology — no Style Guide (`CosmicBlueprint`), no style decisions.
    static func generateVibeProfile(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        date: Date,
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard
    ) -> VibeBreakdown {
        var rawScores = emptyEnergyScores()
        accumulateWeightedVibeScores(
            into: &rawScores,
            weights: calibration.sourceWeights,
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            moonPhaseDegrees: moonPhaseDegrees,
            date: date,
            calibration: calibration
        )
        applySignMultipliersIfNeeded(
            to: &rawScores,
            sunSign: extractSunSignName(from: natalChart),
            calibration: calibration,
            enabled: calibration.signMultiplierPolicy.applyToDailyVibe
        )
        return normaliseToTwentyOne(rawScores)
    }

    // MARK: - Phase 2: Snapshot Assembly

    /// Generate a complete DailyEnergySnapshot — the Stage 1 pipeline output.
    static func generateSnapshot(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        profileHash: String,
        date: Date = Date(),
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard,
        dailyFitEngineId engineId: String? = nil
    ) -> DailyEnergySnapshot {
        let effectiveMode = DailyFitEngineRegistry.resolvedMode(explicit: mode, engineId: engineId)
        let resolvedEngineId = DailyFitEngineRegistry.engineId(for: calibration, mode: effectiveMode)

        let dailySeed = dailySeed(
            profileHash: profileHash,
            date: date,
            engineId: resolvedEngineId,
            mode: effectiveMode
        )
        let axes = evaluateAxes(
            natalChart: natalChart, progressedChart: progressedChart,
            transits: transits, moonPhaseDegrees: moonPhaseDegrees,
            dailySeed: dailySeed, calibration: calibration,
            mode: effectiveMode
        )

        var chartVibe: VibeBreakdown?
        var skyVibe: VibeBreakdown?
        var chartAxes: DerivedAxes?
        var skyRawScores: [Energy: Double]?
        if effectiveMode.usesSkyForwardPipeline {
            chartVibe = generatePartialVibeProfile(
                natalChart: natalChart,
                progressedChart: progressedChart,
                transits: transits,
                moonPhaseDegrees: moonPhaseDegrees,
                date: date,
                weights: stage1ChartSourceWeights,
                calibration: calibration,
                shouldApplySignMultipliers: calibration.signMultiplierPolicy.applyToChartAnchor
            )
            var noSkyAttribution: [EnergyAttributionEntry]? = nil
            let skyResult: (breakdown: VibeBreakdown, rawScores: [Energy: Double])
            if effectiveMode.usesSkyFidelityVibe {
                // v1.0.2: fingerprinted sky mix + normalised transits + continuous lunar.
                skyResult = generateSkyFidelityVibeProfileWithRaw(
                    natalChart: natalChart,
                    transits: transits,
                    moonPhaseDegrees: moonPhaseDegrees,
                    date: date,
                    calibration: calibration,
                    shouldApplySignMultipliers: calibration.signMultiplierPolicy.applyToDailyVibe,
                    attribution: &noSkyAttribution
                )
            } else {
                skyResult = generatePartialVibeProfileWithRaw(
                    natalChart: natalChart,
                    progressedChart: progressedChart,
                    transits: transits,
                    moonPhaseDegrees: moonPhaseDegrees,
                    date: date,
                    weights: stage1SkySourceWeights,
                    calibration: calibration,
                    shouldApplySignMultipliers: calibration.signMultiplierPolicy.applyToDailyVibe
                )
            }
            skyVibe = skyResult.breakdown
            skyRawScores = skyResult.rawScores
            chartAxes = evaluateChartAnchorAxes(
                natalChart: natalChart,
                progressedChart: progressedChart,
                calibration: DailyFitCalibration.default
            )
        }

        let vibeProfile: VibeBreakdown
        if effectiveMode.usesSkyForwardPipeline, let skyVibe {
            vibeProfile = skyVibe
        } else {
            vibeProfile = generateVibeProfile(
                natalChart: natalChart, progressedChart: progressedChart,
                transits: transits, moonPhaseDegrees: moonPhaseDegrees,
                date: date, calibration: calibration, mode: effectiveMode
            )
        }

        // v1.0.2 sky-fidelity path only: date-keyed named lunar event (D2 phase-label
        // override + §6h special-event surfacing). nil on every pre-v1.0.2 path.
        let namedLunarEvent: LunarEvent? = effectiveMode.usesSkyFidelityVibe
            ? LunarEventDetector.detect(date: date)
            : nil

        var skySalienceSimple: SkySalienceProfile? = effectiveMode.usesSkyForwardPipeline
            ? computeSkySalience(from: transits, date: date)
            : nil
        if let event = namedLunarEvent, event.isSpecialEvent, let base = skySalienceSimple {
            skySalienceSimple = injectNamedEventDriver(into: base, event: event)
        }

        return DailyEnergySnapshot(
            vibeProfile: vibeProfile,
            axes: axes,
            dominantTransits: extractDominantTransits(from: transits),
            lunarContext: buildLunarContext(
                moonPhaseDegrees: moonPhaseDegrees,
                namedEvent: namedLunarEvent
            ),
            dailySeed: dailySeed,
            profileHash: profileHash,
            generatedAt: date,
            chartVibeProfile: chartVibe,
            skyVibeProfile: skyVibe,
            chartAxes: chartAxes,
            vibeRawScores: skyRawScores,
            skySalience: skySalienceSimple
        )
    }

    // MARK: - Planet Energy Base Map

    private static let planetEnergyBase: [String: [Energy: Double]] = [
        "Sun":     [.drama: 0.3, .classic: 0.3, .playful: 0.2, .edge: 0.1, .romantic: 0.1],
        "Moon":    [.romantic: 0.4, .classic: 0.2, .playful: 0.2, .drama: 0.1, .utility: 0.1],
        "Mercury": [.playful: 0.3, .utility: 0.3, .classic: 0.2, .edge: 0.2],
        "Venus":   [.romantic: 0.4, .classic: 0.3, .playful: 0.2, .drama: 0.1],
        "Mars":    [.drama: 0.3, .edge: 0.3, .utility: 0.2, .playful: 0.2],
        "Jupiter": [.drama: 0.3, .playful: 0.3, .romantic: 0.2, .classic: 0.2],
        "Saturn":  [.classic: 0.4, .utility: 0.4, .drama: 0.1, .edge: 0.1],
        "Uranus":  [.edge: 0.5, .playful: 0.2, .drama: 0.2, .utility: 0.1],
        "Neptune": [.romantic: 0.4, .edge: 0.3, .drama: 0.2, .playful: 0.1],
        "Pluto":   [.drama: 0.4, .edge: 0.3, .romantic: 0.1, .utility: 0.1, .classic: 0.1]
    ]

    // MARK: - Element Boosts

    private static let elementBoosts: [String: [Energy: Double]] = [
        "Fire":  [.drama: 0.1, .playful: 0.05],
        "Earth": [.classic: 0.1, .utility: 0.05],
        "Air":   [.playful: 0.1, .edge: 0.05],
        "Water": [.romantic: 0.1, .drama: 0.05]
    ]

    /// Skips element boosts when natal Sun sign map already strongly weights the same energy.
    private static func effectiveElementBoost(
        element: String,
        energy: Energy,
        natalSunSign: String,
        calibration: DailyFitCalibration
    ) -> Double {
        let boost = elementBoosts[element]?[energy] ?? 0.0
        guard boost > 0, let threshold = calibration.elementBoostDedupeThreshold else {
            return boost
        }
        let signMultiplier = calibration.signEnergyMap.multiplier(forSign: natalSunSign, energy: energy)
        if signMultiplier > threshold {
            return 0.0
        }
        return boost
    }

    // MARK: - Lunar Phase Energy Biases

    private static let lunarPhaseEnergies: [MoonPhaseInterpreter.Phase: [Energy: Double]] = [
        .newMoon:        [.utility: 0.4, .classic: 0.3, .edge: 0.1, .romantic: 0.1, .drama: 0.05, .playful: 0.05],
        .waxingCrescent: [.playful: 0.35, .edge: 0.3, .drama: 0.15, .utility: 0.1, .classic: 0.05, .romantic: 0.05],
        .firstQuarter:   [.playful: 0.35, .edge: 0.3, .drama: 0.15, .utility: 0.1, .classic: 0.05, .romantic: 0.05],
        .waxingGibbous:  [.drama: 0.35, .romantic: 0.3, .playful: 0.15, .classic: 0.1, .edge: 0.05, .utility: 0.05],
        .fullMoon:       [.drama: 0.35, .playful: 0.3, .romantic: 0.15, .edge: 0.1, .classic: 0.05, .utility: 0.05],
        .waningGibbous:  [.classic: 0.35, .romantic: 0.3, .drama: 0.15, .utility: 0.1, .playful: 0.05, .edge: 0.05],
        .lastQuarter:    [.utility: 0.35, .edge: 0.3, .classic: 0.15, .drama: 0.1, .playful: 0.05, .romantic: 0.05],
        .waningCrescent: [.utility: 0.35, .edge: 0.3, .classic: 0.15, .drama: 0.1, .playful: 0.05, .romantic: 0.05]
    ]

    // MARK: - Natal/Progressed Contribution

    private static func accumulateChartContribution(
        chart: NatalChartCalculator.NatalChart,
        weight: Double,
        natalSunSign: String,
        calibration: DailyFitCalibration,
        into scores: inout [Energy: Double],
        attribution: inout [EnergyAttributionEntry]?,
        sourceTag: String = "natal"
    ) {
        for planet in chart.planets {
            guard let baseEnergies = planetEnergyBase[planet.name] else { continue }
            let element = signElement(forZodiacSign: planet.zodiacSign)
            let signName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            let label = "\(planet.name) in \(signName)"

            for energy in Energy.allCases {
                let base = baseEnergies[energy] ?? 0.0
                let boost = effectiveElementBoost(
                    element: element, energy: energy,
                    natalSunSign: natalSunSign, calibration: calibration
                )
                let raw = base + boost
                let weighted = raw * weight
                scores[energy]! += weighted

                attribution?.append(EnergyAttributionEntry(
                    source: sourceTag,
                    label: label,
                    energy: energy.rawValue,
                    rawContribution: raw,
                    weightedContribution: weighted
                ))
            }
        }
    }

    private static func accumulateChartContribution(
        chart: NatalChartCalculator.NatalChart,
        weight: Double,
        natalSunSign: String,
        calibration: DailyFitCalibration,
        into scores: inout [Energy: Double]
    ) {
        var noAttribution: [EnergyAttributionEntry]? = nil
        accumulateChartContribution(
            chart: chart, weight: weight,
            natalSunSign: natalSunSign, calibration: calibration,
            into: &scores, attribution: &noAttribution
        )
    }

    // MARK: - Transit Contribution

    private static func accumulateTransitContribution(
        transits: [NatalChartCalculator.TransitAspect],
        weight: Double,
        into scores: inout [Energy: Double],
        attribution: inout [EnergyAttributionEntry]?
    ) {
        for transit in transits {
            guard let baseEnergies = planetEnergyBase[transit.transitPlanet] else { continue }

            let orbStrength = max(0.0, 1.0 - transit.orb / 10.0)
            let isHard = isHardAspect(transit.aspectType)
            let isSoft = isSoftAspect(transit.aspectType)
            let label = "\(transit.transitPlanet) \(transit.aspectType) \(transit.natalPlanet)"

            for energy in Energy.allCases {
                var contribution = (baseEnergies[energy] ?? 0.0) * orbStrength

                if isHard {
                    if energy == .drama || energy == .edge { contribution *= 1.3 }
                } else if isSoft {
                    if energy == .romantic || energy == .classic { contribution *= 1.3 }
                }

                let weighted = contribution * weight
                scores[energy]! += weighted

                attribution?.append(EnergyAttributionEntry(
                    source: "transit",
                    label: label,
                    energy: energy.rawValue,
                    rawContribution: contribution,
                    weightedContribution: weighted
                ))
            }
        }
    }

    private static func accumulateTransitContribution(
        transits: [NatalChartCalculator.TransitAspect],
        weight: Double,
        into scores: inout [Energy: Double]
    ) {
        var noAttribution: [EnergyAttributionEntry]? = nil
        accumulateTransitContribution(
            transits: transits, weight: weight, into: &scores,
            attribution: &noAttribution
        )
    }

    // MARK: - Lunar Contribution

    private static func accumulateLunarContribution(
        moonPhaseDegrees: Double,
        weight: Double,
        into scores: inout [Energy: Double],
        attribution: inout [EnergyAttributionEntry]?
    ) {
        let phase = MoonPhaseInterpreter.Phase.fromDegrees(moonPhaseDegrees)
        let biases = lunarPhaseEnergies[phase] ?? [:]
        let label = phase.description

        for energy in Energy.allCases {
            let raw = biases[energy] ?? 0.0
            let weighted = raw * weight
            scores[energy]! += weighted

            attribution?.append(EnergyAttributionEntry(
                source: "lunar",
                label: label,
                energy: energy.rawValue,
                rawContribution: raw,
                weightedContribution: weighted
            ))
        }
    }

    private static func accumulateLunarContribution(
        moonPhaseDegrees: Double,
        weight: Double,
        into scores: inout [Energy: Double]
    ) {
        var noAttribution: [EnergyAttributionEntry]? = nil
        accumulateLunarContribution(
            moonPhaseDegrees: moonPhaseDegrees, weight: weight, into: &scores,
            attribution: &noAttribution
        )
    }

    // MARK: - Current Sun Contribution

    private static func accumulateCurrentSunContribution(
        date: Date,
        weight: Double,
        natalSunSign: String,
        calibration: DailyFitCalibration,
        into scores: inout [Energy: Double],
        attribution: inout [EnergyAttributionEntry]?
    ) {
        let element = currentSunElement(for: date)
        let label = "\(element) season"

        for energy in Energy.allCases {
            let base = 1.0 / Double(Energy.allCases.count)
            let boost = effectiveElementBoost(
                element: element, energy: energy,
                natalSunSign: natalSunSign, calibration: calibration
            )
            let raw = base + boost
            let weighted = raw * weight
            scores[energy]! += weighted

            attribution?.append(EnergyAttributionEntry(
                source: "currentSun",
                label: label,
                energy: energy.rawValue,
                rawContribution: raw,
                weightedContribution: weighted
            ))
        }
    }

    private static func accumulateCurrentSunContribution(
        date: Date,
        weight: Double,
        natalSunSign: String,
        calibration: DailyFitCalibration,
        into scores: inout [Energy: Double]
    ) {
        var noAttribution: [EnergyAttributionEntry]? = nil
        accumulateCurrentSunContribution(
            date: date, weight: weight,
            natalSunSign: natalSunSign, calibration: calibration,
            into: &scores, attribution: &noAttribution
        )
    }

    private static func emptyEnergyScores() -> [Energy: Double] {
        Dictionary(uniqueKeysWithValues: Energy.allCases.map { ($0, 0.0) })
    }

    private static func accumulateWeightedVibeScores(
        into scores: inout [Energy: Double],
        weights: DailyFitCalibration.SourceWeights,
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        date: Date,
        calibration: DailyFitCalibration
    ) {
        let natalSunSign = extractSunSignName(from: natalChart)
        accumulateChartContribution(
            chart: natalChart, weight: weights.natal,
            natalSunSign: natalSunSign, calibration: calibration, into: &scores
        )
        accumulateChartContribution(
            chart: progressedChart, weight: weights.progressed,
            natalSunSign: natalSunSign, calibration: calibration, into: &scores
        )
        accumulateTransitContribution(transits: transits, weight: weights.transits, into: &scores)
        accumulateLunarContribution(moonPhaseDegrees: moonPhaseDegrees, weight: weights.lunarPhase, into: &scores)
        accumulateCurrentSunContribution(
            date: date, weight: weights.currentSun,
            natalSunSign: natalSunSign, calibration: calibration, into: &scores
        )
    }

    private static func applySignMultipliers(
        to scores: inout [Energy: Double],
        sunSign: String,
        calibration: DailyFitCalibration
    ) {
        for energy in Energy.allCases {
            let multiplier = calibration.signEnergyMap.multiplier(forSign: sunSign, energy: energy)
            scores[energy]! *= multiplier
        }
    }

    private static func applySignMultipliersIfNeeded(
        to scores: inout [Energy: Double],
        sunSign: String,
        calibration: DailyFitCalibration,
        enabled: Bool
    ) {
        guard enabled else { return }
        applySignMultipliers(to: &scores, sunSign: sunSign, calibration: calibration)
    }

    private static func signMultipliersForTrace(
        sunSign: String,
        calibration: DailyFitCalibration,
        appliedToDailyVibe: Bool
    ) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: Energy.allCases.map { energy in
            let mult = appliedToDailyVibe
                ? calibration.signEnergyMap.multiplier(forSign: sunSign, energy: energy)
                : 1.0
            return (energy.rawValue, mult)
        })
    }

    /// Chart-only source mix for Stage 1 anchor reads.
    private static let stage1ChartSourceWeights = DailyFitCalibration.SourceWeights(
        natal: 0.85, transits: 0, lunarPhase: 0, progressed: 0.15, currentSun: 0
    )

    /// Sky-only source mix for Stage 1 daily outside-energy reads.
    /// Lunar dominates (0.60) to drive phase-to-phase energy shifts;
    /// transits (0.25) differentiate within a phase; currentSun (0.15) adds seasonal colour.
    private static let stage1SkySourceWeights = DailyFitCalibration.SourceWeights(
        natal: 0, transits: 0.25, lunarPhase: 0.60, progressed: 0, currentSun: 0.15
    )

    /// Vibe from a partial source mix (chart-only or sky-only slices).
    private static func generatePartialVibeProfile(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        date: Date,
        weights: DailyFitCalibration.SourceWeights,
        calibration: DailyFitCalibration,
        shouldApplySignMultipliers: Bool
    ) -> VibeBreakdown {
        return generatePartialVibeProfileWithRaw(
            natalChart: natalChart, progressedChart: progressedChart,
            transits: transits, moonPhaseDegrees: moonPhaseDegrees,
            date: date, weights: weights, calibration: calibration,
            shouldApplySignMultipliers: shouldApplySignMultipliers
        ).breakdown
    }

    /// Vibe from a partial source mix, also returning pre-normalisation raw scores.
    private static func generatePartialVibeProfileWithRaw(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        date: Date,
        weights: DailyFitCalibration.SourceWeights,
        calibration: DailyFitCalibration,
        shouldApplySignMultipliers: Bool
    ) -> (breakdown: VibeBreakdown, rawScores: [Energy: Double]) {
        var rawScores = emptyEnergyScores()
        accumulateWeightedVibeScores(
            into: &rawScores,
            weights: weights,
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            moonPhaseDegrees: moonPhaseDegrees,
            date: date,
            calibration: calibration
        )
        if shouldApplySignMultipliers {
            applySignMultipliers(
                to: &rawScores,
                sunSign: extractSunSignName(from: natalChart),
                calibration: calibration
            )
        }
        return (normaliseToTwentyOne(rawScores), rawScores)
    }

    // MARK: - Sky Forward v1.0.2 sky-fidelity vibe (audit F1/F2/F3/F5/F6)

    /// Tightest-orb transit per transiting planet, then the top `limit` by orb (ascending).
    /// Shared by the reference axis path (`computeAxisRawScoreSkyOnly`) and the v1.0.2
    /// sky-fidelity vibe path so both bound transit influence to the same dominant set,
    /// preventing the combinatorial/outer-planet saturation that made nominal weights
    /// fiction in v1.0.1 (audit §2.2). Extracted verbatim from the axis path (same ordering,
    /// including its dictionary-iteration tie behaviour) so the v1.0.1 axis output stays byte-identical.
    static func dominantTransits(
        _ transits: [NatalChartCalculator.TransitAspect],
        limit: Int = 5
    ) -> [NatalChartCalculator.TransitAspect] {
        var bestByPlanet: [String: NatalChartCalculator.TransitAspect] = [:]
        for transit in transits {
            let planet = transit.transitPlanet
            if let existing = bestByPlanet[planet] {
                if transit.orb < existing.orb { bestByPlanet[planet] = transit }
            } else {
                bestByPlanet[planet] = transit
            }
        }
        return Array(bestByPlanet.values.sorted { $0.orb < $1.orb }.prefix(limit))
    }

    /// Canonical lunar-phase anchors in cycle order (every 45°): new 0°, waxingCrescent 45°,
    /// firstQuarter 90°, waxingGibbous 135°, full 180°, waningGibbous 225°, lastQuarter 270°,
    /// waningCrescent 315°. Used by the continuous blend.
    private static let orderedLunarPhaseAnchors: [MoonPhaseInterpreter.Phase] = [
        .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous,
        .fullMoon, .waningGibbous, .lastQuarter, .waningCrescent
    ]

    /// F1 + F2: continuous (raised-cosine) blend between the two adjacent lunar-phase energy
    /// anchors, replacing v1.0.1's 8-bucket step lookup. Peaks exactly at the 180° full-moon
    /// (and 0° new-moon) anchor regardless of sample timing, so a full moon is never missed by
    /// falling outside a 6° bucket. Each anchor vector sums to 1.0, so the blend does too.
    /// Handles the 315°↔360°/0° modular wrap.
    static func continuousLunarEnergies(moonPhaseDegrees: Double) -> [Energy: Double] {
        var deg = moonPhaseDegrees.truncatingRemainder(dividingBy: 360.0)
        if deg < 0 { deg += 360.0 }
        let count = orderedLunarPhaseAnchors.count            // 8
        let segment = 360.0 / Double(count)                   // 45°
        let rawIndex = deg / segment                          // [0, 8)
        let floorIndex = rawIndex.rounded(.down)
        let i = Int(floorIndex) % count
        let next = (i + 1) % count                            // wraps 315°→0°
        let f = rawIndex - floorIndex                         // [0, 1) position within segment
        let w = 0.5 - 0.5 * cos(f * .pi)                      // raised-cosine (smoothstep); 0 at f=0, 1 at f=1
        let a = lunarPhaseEnergies[orderedLunarPhaseAnchors[i]] ?? [:]
        let b = lunarPhaseEnergies[orderedLunarPhaseAnchors[next]] ?? [:]
        var result: [Energy: Double] = [:]
        for energy in Energy.allCases {
            result[energy] = (a[energy] ?? 0.0) * (1.0 - w) + (b[energy] ?? 0.0) * w
        }
        return result
    }

    /// Proximity to a syzygy (exact full OR new moon): `|cos(moonPhaseDegrees)|`.
    /// =1 at 0° and 180°, =0 at the 90°/270° quarters.
    static func syzygyProximity(moonPhaseDegrees: Double) -> Double {
        abs(cos(moonPhaseDegrees * .pi / 180.0))
    }

    /// F3: continuous lunar contribution with significance amplification. The lunar weight is
    /// scaled by `(1 + k·syzygyProximity)`, so the moon swells near full/new and sits at baseline
    /// at the quarters — making full-moon days separable from ordinary churn. New moons are boosted
    /// equally to full moons (syzygy = both), which is intended.
    private static func accumulateContinuousLunarContribution(
        moonPhaseDegrees: Double,
        weight: Double,
        significanceCoeff k: Double,
        into scores: inout [Energy: Double],
        attribution: inout [EnergyAttributionEntry]?
    ) {
        let biases = continuousLunarEnergies(moonPhaseDegrees: moonPhaseDegrees)
        let amplifiedWeight = weight * (1.0 + k * syzygyProximity(moonPhaseDegrees: moonPhaseDegrees))
        let label = MoonPhaseInterpreter.Phase.fromDegrees(moonPhaseDegrees).description
        for energy in Energy.allCases {
            let raw = biases[energy] ?? 0.0
            let weighted = raw * amplifiedWeight
            scores[energy]! += weighted
            attribution?.append(EnergyAttributionEntry(
                source: "lunar",
                label: label,
                energy: energy.rawValue,
                rawContribution: raw,
                weightedContribution: weighted
            ))
        }
    }

    /// §2.2 + F5 + F6: normalised transit contribution. Mirrors the axis path — only the
    /// top-5 tightest-orb transits (one per planet) contribute, each scaled by
    /// `orbStrength · speedDamp · minorAspectDiscount` before distributing across the 6-energy
    /// base vector. Bounds the transit sum (≤5 hits) so the fixed lunar contribution is no longer
    /// swamped by 41–83 un-normalised in-orb transits, making the nominal sky mix real.
    private static func accumulateDominantTransitContribution(
        transits: [NatalChartCalculator.TransitAspect],
        weight: Double,
        into scores: inout [Energy: Double],
        attribution: inout [EnergyAttributionEntry]?
    ) {
        for transit in dominantTransits(transits, limit: 5) {
            guard let baseEnergies = planetEnergyBase[transit.transitPlanet] else { continue }
            let orbStrength = max(0.0, 1.0 - transit.orb / 10.0)
            let speedDamp = axisSpeedDamping[transit.transitPlanet] ?? 0.71
            // Rec 5: minor aspects (quintile/semi-sextile/…) discounted to 0.5 via the salience map.
            let minorAspectDiscount = transitAspectWeights[transit.aspectType.lowercased()] ?? 0.5
            let strength = orbStrength * speedDamp * minorAspectDiscount
            let label = "\(transit.transitPlanet) \(transit.aspectType) \(transit.natalPlanet)"
            for energy in Energy.allCases {
                let contribution = (baseEnergies[energy] ?? 0.0) * strength
                let weighted = contribution * weight
                scores[energy]! += weighted
                attribution?.append(EnergyAttributionEntry(
                    source: "transit",
                    label: label,
                    energy: energy.rawValue,
                    rawContribution: contribution,
                    weightedContribution: weighted
                ))
            }
        }
    }

    /// v1.0.2 sky-fidelity daily vibe: the fingerprinted sky mix (`skyVibeWeights`) with
    /// normalised transits + continuous significance-weighted lunar. Parallel to
    /// `generatePartialVibeProfileWithRaw`; used only on the `.stage2SkyFidelity` path.
    /// Natal/progressed are anchor-only (0), matching the legacy `stage1SkySourceWeights`.
    private static func generateSkyFidelityVibeProfileWithRaw(
        natalChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        date: Date,
        calibration: DailyFitCalibration,
        shouldApplySignMultipliers: Bool,
        attribution: inout [EnergyAttributionEntry]?
    ) -> (breakdown: VibeBreakdown, rawScores: [Energy: Double]) {
        let sky = calibration.skyVibeWeights
            ?? DailyFitCalibration.SkyVibeWeights(transits: 0.25, lunar: 0.60, currentSun: 0.15)
        let k = calibration.lunarSignificanceCoeff ?? 0.0
        let natalSunSign = extractSunSignName(from: natalChart)
        var rawScores = emptyEnergyScores()
        accumulateDominantTransitContribution(
            transits: transits, weight: sky.transits,
            into: &rawScores, attribution: &attribution
        )
        accumulateContinuousLunarContribution(
            moonPhaseDegrees: moonPhaseDegrees, weight: sky.lunar, significanceCoeff: k,
            into: &rawScores, attribution: &attribution
        )
        accumulateCurrentSunContribution(
            date: date, weight: sky.currentSun,
            natalSunSign: natalSunSign, calibration: calibration,
            into: &rawScores, attribution: &attribution
        )
        if shouldApplySignMultipliers {
            applySignMultipliers(to: &rawScores, sunSign: natalSunSign, calibration: calibration)
        }
        return (normaliseToTwentyOne(rawScores), rawScores)
    }

    /// Natal+progressed axes without transits, moon, or jitter — chart baseline.
    private static func evaluateChartAnchorAxes(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        calibration: DailyFitCalibration
    ) -> DerivedAxes {
        let moonMods = moonPhaseAxisModulations(0)
        var scores = [String: Double]()
        for axis in axisNames {
            var discardEntries: [AxisAttributionEntry] = []
            let raw = computeAxisRawScore(
                axis: axis,
                natalChart: natalChart,
                progressedChart: progressedChart,
                transits: [],
                moonMods: moonMods,
                lunarPhaseName: "Chart anchor",
                calibration: calibration,
                includeTransits: false,
                includeMoon: false,
                jitter: 0,
                entries: &discardEntries
            )
            scores[axis] = scaleToAxis(raw, spread: calibration.axisTuning.sigmoidSpread)
        }
        return DerivedAxes(
            action: scores["action"]!, tempo: scores["tempo"]!,
            strategy: scores["strategy"]!, visibility: scores["visibility"]!
        )
    }

    private static func dailySeed(
        profileHash: String,
        date: Date,
        engineId: String,
        mode: DailyFitEngineMode
    ) -> Int {
        let descriptor = DailyFitEngineRegistry.descriptor(for: engineId)
        let policy = descriptor?.dailySeedPolicy ?? .sharedProfileDate
        if policy == .includesEngineId, mode.usesSkyForwardPipeline {
            let dateString = stage1SeedDateFormatter.string(from: date)
            return DailySeedGenerator.intSeed(from: "\(profileHash)_\(dateString)_\(engineId)")
        }
        return DailySeedGenerator.generateDailySeed(profileHash: profileHash, for: date)
    }

    private static let stage1SeedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()

    // MARK: - Normalisation (Largest-Remainder Method)

    private static func normaliseToTwentyOne(_ rawScores: [Energy: Double]) -> VibeBreakdown {
        let total = rawScores.values.reduce(0.0, +)
        guard total > 0 else {
            return VibeBreakdown(classic: 4, playful: 4, romantic: 4, utility: 3, drama: 3, edge: 3)
        }

        let orderedEnergies = Energy.allCases
        let ideals: [(Energy, Double)] = orderedEnergies.map { ($0, (rawScores[$0]! / total) * 21.0) }
        var bases: [Energy: Int] = [:]
        var remainders: [(Energy, Double)] = []

        for (energy, ideal) in ideals {
            let floored = Int(ideal)
            bases[energy] = floored
            remainders.append((energy, ideal - Double(floored)))
        }

        var allocated = bases.values.reduce(0, +)
        remainders.sort { $0.1 > $1.1 }

        var idx = 0
        while allocated < 21 && idx < remainders.count {
            bases[remainders[idx].0]! += 1
            allocated += 1
            idx += 1
        }

        // Clamp to 0-10 and redistribute if clamping changes total
        var clamped: [Energy: Int] = [:]
        var overflow = 0
        for energy in orderedEnergies {
            let val = bases[energy]!
            if val > 10 {
                overflow += val - 10
                clamped[energy] = 10
            } else if val < 0 {
                overflow += val
                clamped[energy] = 0
            } else {
                clamped[energy] = val
            }
        }

        // Redistribute overflow to unclamped energies (largest remainder first)
        if overflow > 0 {
            let sortedByRemainder = remainders
                .filter { clamped[$0.0]! < 10 }
                .sorted { $0.1 > $1.1 }

            for (energy, _) in sortedByRemainder {
                guard overflow > 0 else { break }
                let room = 10 - clamped[energy]!
                let add = min(room, overflow)
                clamped[energy]! += add
                overflow -= add
            }
        }

        return VibeBreakdown(
            classic: clamped[.classic]!,
            playful: clamped[.playful]!,
            romantic: clamped[.romantic]!,
            utility: clamped[.utility]!,
            drama: clamped[.drama]!,
            edge: clamped[.edge]!
        )
    }

    // MARK: - Diagnostic Hooks (Phase 6)

    /// Internal-only snapshot generation that also returns intermediate values
    /// for DailyFitDiagnosticReport. Not used in production paths.
    struct SnapshotTrace {
        let rawScores: [String: Double]
        let postMultiplierScores: [String: Double]
        let rawAxisScores: [String: Double]
        let sourceContributions: [String: Double]
        let attributionEntries: [EnergyAttributionEntry]
        let axisAttribution: [AxisAttributionBreakdown]
        let signMultipliers: [String: Double]
        /// Natal Sun signEnergyMap values when chart-anchor policy applies (stage1 only).
        let chartAnchorSignMultipliers: [String: Double]?
        let engineMode: String
    }

    static func generateSnapshotWithTrace(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        profileHash: String,
        date: Date = Date(),
        calibration: DailyFitCalibration = .default,
        mode: DailyFitEngineMode = .standard,
        dailyFitEngineId engineId: String? = nil
    ) -> (snapshot: DailyEnergySnapshot, trace: SnapshotTrace) {
        let effectiveMode = DailyFitEngineRegistry.resolvedMode(explicit: mode, engineId: engineId)
        let weights = calibration.sourceWeights
        let attributionWeights: DailyFitCalibration.SourceWeights
        if effectiveMode.usesSkyFidelityVibe {
            // v1.0.2: decompose against the fingerprinted sky mix so the trace's
            // source shares reflect the actual sky-fidelity vibe (A1 gate measures this).
            let sky = calibration.skyVibeWeights
                ?? DailyFitCalibration.SkyVibeWeights(transits: 0.25, lunar: 0.60, currentSun: 0.15)
            attributionWeights = DailyFitCalibration.SourceWeights(
                natal: 0, transits: sky.transits, lunarPhase: sky.lunar,
                progressed: 0, currentSun: sky.currentSun
            )
        } else if effectiveMode.usesSkyForwardPipeline {
            attributionWeights = stage1SkySourceWeights
        } else {
            attributionWeights = weights
        }
        var rawScores: [Energy: Double] = [:]
        for energy in Energy.allCases { rawScores[energy] = 0.0 }
        var natalScores: [Energy: Double] = [:]
        var transitScores: [Energy: Double] = [:]
        var lunarScores: [Energy: Double] = [:]
        var progressedScores: [Energy: Double] = [:]
        var currentSunScores: [Energy: Double] = [:]
        for energy in Energy.allCases {
            natalScores[energy] = 0; transitScores[energy] = 0
            lunarScores[energy] = 0; progressedScores[energy] = 0
            currentSunScores[energy] = 0
        }
        var attributionEntries: [EnergyAttributionEntry]? = []
        let natalSunSign = extractSunSignName(from: natalChart)
        accumulateChartContribution(
            chart: natalChart, weight: attributionWeights.natal,
            natalSunSign: natalSunSign, calibration: calibration,
            into: &natalScores, attribution: &attributionEntries, sourceTag: "natal"
        )
        accumulateChartContribution(
            chart: progressedChart, weight: attributionWeights.progressed,
            natalSunSign: natalSunSign, calibration: calibration,
            into: &progressedScores, attribution: &attributionEntries, sourceTag: "progressed"
        )
        if effectiveMode.usesSkyFidelityVibe {
            let k = calibration.lunarSignificanceCoeff ?? 0.0
            accumulateDominantTransitContribution(transits: transits, weight: attributionWeights.transits, into: &transitScores, attribution: &attributionEntries)
            accumulateContinuousLunarContribution(moonPhaseDegrees: moonPhaseDegrees, weight: attributionWeights.lunarPhase, significanceCoeff: k, into: &lunarScores, attribution: &attributionEntries)
        } else {
            accumulateTransitContribution(transits: transits, weight: attributionWeights.transits, into: &transitScores, attribution: &attributionEntries)
            accumulateLunarContribution(moonPhaseDegrees: moonPhaseDegrees, weight: attributionWeights.lunarPhase, into: &lunarScores, attribution: &attributionEntries)
        }
        accumulateCurrentSunContribution(
            date: date, weight: attributionWeights.currentSun,
            natalSunSign: natalSunSign, calibration: calibration,
            into: &currentSunScores, attribution: &attributionEntries
        )
        for energy in Energy.allCases {
            rawScores[energy] = natalScores[energy]! + transitScores[energy]!
                + lunarScores[energy]! + progressedScores[energy]! + currentSunScores[energy]!
        }
        var postMultiplier = rawScores
        let sunSign = natalSunSign
        let applyDailyMult = calibration.signMultiplierPolicy.applyToDailyVibe
        applySignMultipliersIfNeeded(
            to: &postMultiplier,
            sunSign: sunSign,
            calibration: calibration,
            enabled: applyDailyMult
        )
        let signMultipliers = signMultipliersForTrace(
            sunSign: sunSign,
            calibration: calibration,
            appliedToDailyVibe: applyDailyMult
        )
        var postDict = Dictionary(uniqueKeysWithValues: postMultiplier.map { ($0.key.rawValue, $0.value) })
        let resolvedEngineId = DailyFitEngineRegistry.engineId(for: calibration, mode: effectiveMode)
        let dailySeed = dailySeed(
            profileHash: profileHash,
            date: date,
            engineId: resolvedEngineId,
            mode: effectiveMode
        )
        var axisAttribution: [AxisAttributionBreakdown]? = []
        let axes = evaluateAxes(
            natalChart: natalChart, progressedChart: progressedChart,
            transits: transits, moonPhaseDegrees: moonPhaseDegrees,
            dailySeed: dailySeed, calibration: calibration,
            mode: effectiveMode,
            attributionOut: &axisAttribution
        )
        let totalRaw = rawScores.values.reduce(0.0, +)
        let natalTotal = natalScores.values.reduce(0.0, +)
        let transitTotal = transitScores.values.reduce(0.0, +)
        let lunarTotal = lunarScores.values.reduce(0.0, +)
        let progTotal = progressedScores.values.reduce(0.0, +)
        let sunTotal = currentSunScores.values.reduce(0.0, +)
        let denom = max(totalRaw, 0.001)
        let contributions: [String: Double] = [
            "natal": natalTotal / denom,
            "transits": transitTotal / denom,
            "lunar": lunarTotal / denom,
            "progressed": progTotal / denom,
            "currentSun": sunTotal / denom,
        ]

        var chartVibe: VibeBreakdown?
        var skyVibe: VibeBreakdown?
        var chartAxes: DerivedAxes?
        var skyRawScores: [Energy: Double]?
        var chartAnchorSignMultipliers: [String: Double]?
        if effectiveMode.usesSkyForwardPipeline {
            chartVibe = generatePartialVibeProfile(
                natalChart: natalChart,
                progressedChart: progressedChart,
                transits: transits,
                moonPhaseDegrees: moonPhaseDegrees,
                date: date,
                weights: stage1ChartSourceWeights,
                calibration: calibration,
                shouldApplySignMultipliers: calibration.signMultiplierPolicy.applyToChartAnchor
            )
            var noSkyAttribution: [EnergyAttributionEntry]? = nil
            let skyResult: (breakdown: VibeBreakdown, rawScores: [Energy: Double])
            if effectiveMode.usesSkyFidelityVibe {
                // v1.0.2: fingerprinted sky mix + normalised transits + continuous lunar.
                skyResult = generateSkyFidelityVibeProfileWithRaw(
                    natalChart: natalChart,
                    transits: transits,
                    moonPhaseDegrees: moonPhaseDegrees,
                    date: date,
                    calibration: calibration,
                    shouldApplySignMultipliers: calibration.signMultiplierPolicy.applyToDailyVibe,
                    attribution: &noSkyAttribution
                )
            } else {
                skyResult = generatePartialVibeProfileWithRaw(
                    natalChart: natalChart,
                    progressedChart: progressedChart,
                    transits: transits,
                    moonPhaseDegrees: moonPhaseDegrees,
                    date: date,
                    weights: stage1SkySourceWeights,
                    calibration: calibration,
                    shouldApplySignMultipliers: calibration.signMultiplierPolicy.applyToDailyVibe
                )
            }
            skyVibe = skyResult.breakdown
            skyRawScores = skyResult.rawScores
            chartAxes = evaluateChartAnchorAxes(
                natalChart: natalChart,
                progressedChart: progressedChart,
                calibration: DailyFitCalibration.default
            )
            if calibration.signMultiplierPolicy.applyToChartAnchor {
                chartAnchorSignMultipliers = Dictionary(uniqueKeysWithValues: Energy.allCases.map { energy in
                    (
                        energy.rawValue,
                        calibration.signEnergyMap.multiplier(forSign: sunSign, energy: energy)
                    )
                })
            }
        }

        let vibeProfile: VibeBreakdown
        if effectiveMode.usesSkyForwardPipeline, let skyVibe {
            vibeProfile = skyVibe
        } else {
            vibeProfile = normaliseToTwentyOne(postMultiplier)
        }

        // v1.0.2 sky-fidelity path only: date-keyed named lunar event (D2 phase-label
        // override + §6h special-event surfacing). nil on every pre-v1.0.2 path.
        let namedLunarEvent: LunarEvent? = effectiveMode.usesSkyFidelityVibe
            ? LunarEventDetector.detect(date: date)
            : nil

        var skySalience: SkySalienceProfile? = effectiveMode.usesSkyForwardPipeline
            ? computeSkySalience(from: transits, date: date)
            : nil
        if let event = namedLunarEvent, event.isSpecialEvent, let base = skySalience {
            skySalience = injectNamedEventDriver(into: base, event: event)
        }

        let snapshot = DailyEnergySnapshot(
            vibeProfile: vibeProfile, axes: axes,
            dominantTransits: extractDominantTransits(from: transits),
            lunarContext: buildLunarContext(
                moonPhaseDegrees: moonPhaseDegrees,
                namedEvent: namedLunarEvent
            ),
            dailySeed: dailySeed, profileHash: profileHash, generatedAt: date,
            chartVibeProfile: chartVibe,
            skyVibeProfile: skyVibe,
            chartAxes: chartAxes,
            vibeRawScores: skyRawScores,
            skySalience: skySalience
        )
        var rawDict = Dictionary(uniqueKeysWithValues: rawScores.map { ($0.key.rawValue, $0.value) })
        if effectiveMode.usesSkyForwardPipeline, let skyRawScores {
            rawDict = Dictionary(uniqueKeysWithValues: skyRawScores.map { ($0.key.rawValue, $0.value) })
            if !applyDailyMult {
                postDict = rawDict
            }
        }
        let rawAxisDict = Dictionary(uniqueKeysWithValues: (axisAttribution ?? []).map {
            ($0.axis, $0.rawScore)
        })
        let modeLabel: String
        switch effectiveMode {
        case .stage2SkyFidelity: modeLabel = "stage2SkyFidelity"
        case .stage1Experimental: modeLabel = "stage1Experimental"
        case .standard: modeLabel = "standard"
        }
        let trace = SnapshotTrace(
            rawScores: rawDict, postMultiplierScores: postDict,
            rawAxisScores: rawAxisDict, sourceContributions: contributions,
            attributionEntries: attributionEntries ?? [],
            axisAttribution: axisAttribution ?? [],
            signMultipliers: signMultipliers,
            chartAnchorSignMultipliers: chartAnchorSignMultipliers,
            engineMode: modeLabel
        )
        return (snapshot, trace)
    }

    // MARK: - Helpers

    private static func extractSunSignName(from chart: NatalChartCalculator.NatalChart) -> String {
        guard let sun = chart.planets.first(where: { $0.name == "Sun" }) else {
            return "Aries"
        }
        return CoordinateTransformations.getZodiacSignName(sign: sun.zodiacSign)
    }

    private static func signElement(forZodiacSign sign: Int) -> String {
        // 1-based zodiac: Aries=1, Taurus=2, ..., Pisces=12
        switch sign {
        case 1, 5, 9:   return "Fire"   // Aries, Leo, Sagittarius
        case 2, 6, 10:  return "Earth"  // Taurus, Virgo, Capricorn
        case 3, 7, 11:  return "Air"    // Gemini, Libra, Aquarius
        case 4, 8, 12:  return "Water"  // Cancer, Scorpio, Pisces
        default:        return "Fire"
        }
    }

    private static func currentSunElement(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        // Approximate tropical sign → element. Only element matters for this 5% source.
        switch (month, day) {
        case (3, 21...31), (4, 1...19):                         return "Fire"   // Aries
        case (4, 20...30), (5, 1...20):                         return "Earth"  // Taurus
        case (5, 21...31), (6, 1...20):                         return "Air"    // Gemini
        case (6, 21...30), (7, 1...22):                         return "Water"  // Cancer
        case (7, 23...31), (8, 1...22):                         return "Fire"   // Leo
        case (8, 23...31), (9, 1...22):                         return "Earth"  // Virgo
        case (9, 23...30), (10, 1...22):                        return "Air"    // Libra
        case (10, 23...31), (11, 1...21):                       return "Water"  // Scorpio
        case (11, 22...30), (12, 1...21):                       return "Fire"   // Sagittarius
        case (12, 22...31), (1, 1...19):                        return "Earth"  // Capricorn
        case (1, 20...31), (2, 1...18):                         return "Air"    // Aquarius
        case (2, 19...29), (3, 1...20):                         return "Water"  // Pisces
        default:                                                return "Earth"  // Capricorn
        }
    }

    private static let hardAspects: Set<String> = ["conjunction", "square", "opposition"]
    private static let softAspects: Set<String> = ["trine", "sextile"]

    private static func isHardAspect(_ type: String) -> Bool { hardAspects.contains(type.lowercased()) }
    private static func isSoftAspect(_ type: String) -> Bool { softAspects.contains(type.lowercased()) }

    // MARK: - Phase 2: Axes Evaluation

    private static let axisNames = ["action", "tempo", "strategy", "visibility"]

    /// Element modifiers per axis — determines how a planet's sign placement
    /// affects its axis contribution. Wide range (0.3–1.8) ensures axes use
    /// their full 1–10 range, correcting the legacy 5–8 clustering.
    private static let axisElementModifiers: [String: [String: Double]] = [
        "action":     ["Fire": 1.8, "Air": 1.0, "Earth": 0.3, "Water": 0.5],
        "tempo":      ["Fire": 1.2, "Air": 1.6, "Earth": 0.4, "Water": 0.9],
        "strategy":   ["Fire": 0.3, "Air": 0.7, "Earth": 1.8, "Water": 1.0],
        "visibility": ["Fire": 1.8, "Air": 1.3, "Earth": 0.5, "Water": 0.3],
    ]

    private static func evaluateAxes(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        dailySeed: Int,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode = .standard
    ) -> DerivedAxes {
        var nilAttribution: [AxisAttributionBreakdown]? = nil
        return evaluateAxes(
            natalChart: natalChart,
            progressedChart: progressedChart,
            transits: transits,
            moonPhaseDegrees: moonPhaseDegrees,
            dailySeed: dailySeed,
            calibration: calibration,
            mode: mode,
            attributionOut: &nilAttribution
        )
    }

    private static func evaluateAxes(
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonPhaseDegrees: Double,
        dailySeed: Int,
        calibration: DailyFitCalibration,
        mode: DailyFitEngineMode,
        attributionOut: inout [AxisAttributionBreakdown]?
    ) -> DerivedAxes {
        var rng = SeededRandomGenerator(seed: dailySeed)
        let moonMods = moonPhaseAxisModulations(moonPhaseDegrees)
        let lunar = buildLunarContext(moonPhaseDegrees: moonPhaseDegrees)
        var scores = [String: Double]()
        var breakdowns: [AxisAttributionBreakdown] = []

        for axis in axisNames {
            let jitter = Double.random(
                in: -calibration.axisTuning.jitterRange...calibration.axisTuning.jitterRange,
                using: &rng
            )
            var entries: [AxisAttributionEntry] = []
            let raw: Double
            if mode.usesSkyForwardPipeline {
                raw = computeAxisRawScoreSkyOnly(
                    axis: axis,
                    transits: transits,
                    moonMods: moonMods,
                    lunarPhaseName: lunar.phaseName,
                    calibration: calibration,
                    jitter: jitter,
                    entries: &entries
                )
            } else {
                raw = computeAxisRawScore(
                    axis: axis,
                    natalChart: natalChart,
                    progressedChart: progressedChart,
                    transits: transits,
                    moonMods: moonMods,
                    lunarPhaseName: lunar.phaseName,
                    calibration: calibration,
                    includeTransits: true,
                    includeMoon: true,
                    jitter: jitter,
                    entries: &entries
                )
            }
            let final = scaleToAxis(raw, spread: calibration.axisTuning.sigmoidSpread)
            scores[axis] = final
            if attributionOut != nil {
                entries.sort { abs($0.contribution) > abs($1.contribution) }
                breakdowns.append(AxisAttributionBreakdown(
                    axis: axis,
                    rawScore: raw,
                    finalAxisValue: final,
                    entries: entries
                ))
            }
        }

        attributionOut = breakdowns.isEmpty ? nil : breakdowns

        return DerivedAxes(
            action: scores["action"]!, tempo: scores["tempo"]!,
            strategy: scores["strategy"]!, visibility: scores["visibility"]!
        )
    }

    /// Sky-only axis raw score: transits + moon + jitter (no natal/progressed).
    /// Uses only the tightest-orb transit per planet (max 5) to prevent
    /// outer-planet saturation from full ephemeris.
    /// Applies sqrt-dampened speed factors so slow outer planets (Neptune, Pluto)
    /// don't anchor axes for weeks — lets fast-moving bodies drive daily variation.
    private static func computeAxisRawScoreSkyOnly(
        axis: String,
        transits: [NatalChartCalculator.TransitAspect],
        moonMods: [String: Double],
        lunarPhaseName: String,
        calibration: DailyFitCalibration,
        jitter: Double,
        entries: inout [AxisAttributionEntry]
    ) -> Double {
        let dominant = dominantTransits(transits, limit: 5)
        var raw = 0.0
        for transit in dominant {
            let w = calibration.planetAxisMap.weight(forPlanet: transit.transitPlanet, axis: axis)
            let sign = transit.transitZodiacSign ?? 1
            let element = signElement(forZodiacSign: sign)
            let em = axisElementModifiers[axis]?[element] ?? 1.0
            let orbStrength = max(0.0, 1.0 - transit.orb / 10.0)
            let speedDamp = axisSpeedDamping[transit.transitPlanet] ?? 0.71
            let contrib = w * em * orbStrength * speedDamp
            raw += contrib
            entries.append(AxisAttributionEntry(
                source: "transit",
                label: "\(transit.transitPlanet) \(transit.aspectType) \(transit.natalPlanet) · \(CoordinateTransformations.getZodiacSignName(sign: sign)) (\(element))",
                axis: axis,
                contribution: contrib
            ))
        }
        let moonMod = moonMods[axis] ?? 0.0
        if moonMod != 0 {
            raw += moonMod
            entries.append(AxisAttributionEntry(
                source: "lunar",
                label: "\(lunarPhaseName) — moon phase nudge on \(axis)",
                axis: axis,
                contribution: moonMod
            ))
        }
        if jitter != 0 {
            raw += jitter
            entries.append(AxisAttributionEntry(
                source: "jitter",
                label: "Daily seed jitter",
                axis: axis,
                contribution: jitter
            ))
        }
        return raw
    }

    private static func computeAxisRawScore(
        axis: String,
        natalChart: NatalChartCalculator.NatalChart,
        progressedChart: NatalChartCalculator.NatalChart,
        transits: [NatalChartCalculator.TransitAspect],
        moonMods: [String: Double],
        lunarPhaseName: String,
        calibration: DailyFitCalibration,
        includeTransits: Bool,
        includeMoon: Bool,
        jitter: Double,
        entries: inout [AxisAttributionEntry]
    ) -> Double {
        let sw = calibration.sourceWeights
        var raw = 0.0

        for planet in natalChart.planets {
            let w = calibration.planetAxisMap.weight(forPlanet: planet.name, axis: axis)
            let element = signElement(forZodiacSign: planet.zodiacSign)
            let em = axisElementModifiers[axis]?[element] ?? 1.0
            let contrib = w * em * sw.natal
            raw += contrib
            let signName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            entries.append(AxisAttributionEntry(
                source: "natal",
                label: "\(planet.name) in \(signName) (\(element))",
                axis: axis,
                contribution: contrib
            ))
        }

        for planet in progressedChart.planets {
            let w = calibration.planetAxisMap.weight(forPlanet: planet.name, axis: axis)
            let element = signElement(forZodiacSign: planet.zodiacSign)
            let em = axisElementModifiers[axis]?[element] ?? 1.0
            let contrib = w * em * sw.progressed
            raw += contrib
            let signName = CoordinateTransformations.getZodiacSignName(sign: planet.zodiacSign)
            entries.append(AxisAttributionEntry(
                source: "progressed",
                label: "\(planet.name) progressed in \(signName) (\(element))",
                axis: axis,
                contribution: contrib
            ))
        }

        if includeTransits {
            for transit in transits {
                let w = calibration.planetAxisMap.weight(
                    forPlanet: transit.transitPlanet, axis: axis
                )
                let orbStrength = max(0.0, 1.0 - transit.orb / 10.0)
                let contrib = w * orbStrength * sw.transits
                raw += contrib
                entries.append(AxisAttributionEntry(
                    source: "transit",
                    label: "\(transit.transitPlanet) \(transit.aspectType) \(transit.natalPlanet)",
                    axis: axis,
                    contribution: contrib
                ))
            }
        }

        let baseline = axisBaseline(axis, calibration: calibration)
        raw -= baseline
        entries.append(AxisAttributionEntry(
            source: "baseline",
            label: "Chart centering (natal + progressed anchor subtracted)",
            axis: axis,
            contribution: -baseline
        ))

        if includeMoon {
            let moonMod = moonMods[axis] ?? 0.0
            if moonMod != 0 {
                raw += moonMod
                entries.append(AxisAttributionEntry(
                    source: "lunar",
                    label: "\(lunarPhaseName) — moon phase nudge on \(axis)",
                    axis: axis,
                    contribution: moonMod
                ))
            }
        }
        if jitter != 0 {
            raw += jitter
            entries.append(AxisAttributionEntry(
                source: "jitter",
                label: "Daily seed jitter",
                axis: axis,
                contribution: jitter
            ))
        }
        return raw
    }

    /// Baseline = sum of all planet axis weights × combined chart source weight.
    /// Centering raw scores around 0 lets the sigmoid produce balanced 1–10 output.
    private static func axisBaseline(
        _ axis: String, calibration: DailyFitCalibration
    ) -> Double {
        let planets = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                       "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
        let total = planets.reduce(0.0) {
            $0 + calibration.planetAxisMap.weight(forPlanet: $1, axis: axis)
        }
        return total * (calibration.sourceWeights.natal
                        + calibration.sourceWeights.progressed)
    }

    /// Full moon boosts action & visibility, new moon boosts strategy.
    /// fullMoonProximity: 0 at new moon, 1 at full moon.
    /// NOT inverted — legacy AxisVolatilityEngine had this backwards.
    private static func moonPhaseAxisModulations(
        _ moonPhaseDegrees: Double
    ) -> [String: Double] {
        let fraction = moonPhaseDegrees / 360.0
        let fullMoonProximity = 1.0 - abs(fraction - 0.5) * 2.0
        return [
            "action":     fullMoonProximity * 0.6 - 0.3,
            "tempo":      fullMoonProximity * 0.4 - 0.2,
            "strategy":  -fullMoonProximity * 0.4 + 0.2,
            "visibility": fullMoonProximity * 0.6 - 0.3,
        ]
    }

    /// Sigmoid mapping: tanh maps any real to (-1,1), then scaled to 1–10.
    /// Spread factor controls how aggressively raw scores reach extremes.
    private static func scaleToAxis(_ rawScore: Double, spread: Double = 2.0) -> Double {
        let normalised = tanh(rawScore * spread)
        return 1.0 + (normalised + 1.0) * 4.5
    }

    // MARK: - Phase 2: Dominant Transit Extraction

    private static let transitPlanetWeights: [String: Double] = [
        "Moon": 0.3, "Mercury": 0.4, "Venus": 0.5, "Sun": 0.6, "Mars": 0.7,
        "Jupiter": 0.8, "Saturn": 0.85, "Uranus": 0.9, "Neptune": 0.9,
        "Pluto": 1.0,
    ]

    private static let transitAspectWeights: [String: Double] = [
        "conjunction": 1.0, "opposition": 0.85, "square": 0.85,
        "trine": 0.7, "sextile": 0.6,
    ]

    private static let standardMaxOrbs: [String: Double] = [
        "conjunction": 10.0, "opposition": 10.0, "square": 8.0,
        "trine": 8.0, "sextile": 6.0,
    ]

    private static func extractDominantTransits(
        from transits: [NatalChartCalculator.TransitAspect],
        limit: Int = 5
    ) -> [DailyTransitSummary] {
        guard !transits.isEmpty else { return [] }

        let scored = transits.map { transit
            -> (NatalChartCalculator.TransitAspect, Double) in
            let key = transit.aspectType.lowercased()
            let maxOrb = standardMaxOrbs[key] ?? 10.0
            let orbTightness = max(0.0, 1.0 - abs(transit.orb) / maxOrb)
            let pw = transitPlanetWeights[transit.transitPlanet] ?? 0.5
            let aw = transitAspectWeights[key] ?? 0.5
            return (transit, orbTightness * pw * aw)
        }

        let sorted = scored.sorted { $0.1 > $1.1 }
        let top = Array(sorted.prefix(limit))
        guard let maxStr = top.first?.1, maxStr > 0 else { return [] }

        return top.map { transit, strength in
            DailyTransitSummary(
                transitPlanet: transit.transitPlanet,
                natalPlanet: transit.natalPlanet,
                aspect: transit.aspectType,
                strength: strength / maxStr
            )
        }
    }

    // MARK: - Adaptive Sky Salience (Stage 1 Experimental)

    private static let salienceSpeedFactors: [String: Double] = [
        "Moon": 1.0, "Mercury": 0.9, "Venus": 0.85, "Sun": 0.8, "Mars": 0.7,
        "Jupiter": 0.4, "Saturn": 0.3, "Uranus": 0.2, "Neptune": 0.15, "Pluto": 0.1,
    ]

    /// Sqrt-dampened speed factors for axis computation. Gentler than salienceSpeedFactors
    /// so outer planets still contribute meaningfully to axes, but fast movers dominate
    /// day-to-day variance. Prevents visibility/action/strategy from being anchored by
    /// tight outer-planet aspects for weeks.
    private static let axisSpeedDamping: [String: Double] = [
        "Moon": 1.0, "Mercury": 0.95, "Venus": 0.92, "Sun": 0.89, "Mars": 0.84,
        "Jupiter": 0.63, "Saturn": 0.55, "Uranus": 0.45, "Neptune": 0.39, "Pluto": 0.32,
    ]

    private static let salienceEssenceCategories: [String: StyleEssenceCategory] = [
        "Mars": .drama, "Venus": .romantic, "Sun": .magnetic,
        "Moon": .playful, "Mercury": .eclectic, "Jupiter": .maximalist,
        "Saturn": .minimal, "Uranus": .effortless, "Neptune": .sensual, "Pluto": .edgy,
    ]

    static func computeSkySalience(
        from transits: [NatalChartCalculator.TransitAspect],
        date: Date
    ) -> SkySalienceProfile {
        guard !transits.isEmpty else {
            return SkySalienceProfile(entries: [], topDrivers: [], dominantNarrative: nil)
        }

        var rawEntries: [(transit: NatalChartCalculator.TransitAspect, raw: Double, speed: Double, freshness: Double)] = []

        for transit in transits {
            let key = transit.aspectType.lowercased()
            let maxOrb = standardMaxOrbs[key] ?? 10.0
            let orbTightness = max(0.0, 1.0 - abs(transit.orb) / maxOrb)
            let aspectWeight = transitAspectWeights[key] ?? 0.5
            let speedFactor = salienceSpeedFactors[transit.transitPlanet] ?? 0.5

            let freshnessBonus: Double
            if abs(transit.orb) < 0.5 {
                freshnessBonus = 0.3
            } else if transit.applying {
                freshnessBonus = 0.1
            } else if abs(transit.orb) > 3.0 {
                freshnessBonus = -0.2
            } else {
                freshnessBonus = -0.1
            }

            let rawSalience = orbTightness * aspectWeight * speedFactor + freshnessBonus
            rawEntries.append((transit, rawSalience, speedFactor, freshnessBonus))
        }

        let maxRaw = rawEntries.map(\.raw).max() ?? 1.0
        let normFactor = maxRaw > 0 ? maxRaw : 1.0

        var entries: [SkySalienceProfile.SalienceEntry] = rawEntries.map { item in
            SkySalienceProfile.SalienceEntry(
                planet: item.transit.transitPlanet,
                aspect: item.transit.aspectType,
                natalTarget: item.transit.natalPlanet,
                rawStrength: item.raw,
                speedFactor: item.speed,
                freshnessBonus: item.freshness,
                salience: max(0, item.raw / normFactor),
                essenceCategory: salienceEssenceCategories[item.transit.transitPlanet]
            )
        }

        // Sort by salience descending, tie-break alphabetically on planet for determinism
        entries.sort { a, b in
            if a.salience != b.salience { return a.salience > b.salience }
            return a.planet < b.planet
        }

        // Dedup: keep only the highest-salience entry per essence category for top drivers
        var seenCategories = Set<StyleEssenceCategory>()
        var topDrivers: [SkySalienceProfile.SalienceEntry] = []
        for entry in entries {
            guard let cat = entry.essenceCategory, !seenCategories.contains(cat) else {
                if entry.essenceCategory == nil && topDrivers.count < 3 {
                    topDrivers.append(entry)
                }
                continue
            }
            seenCategories.insert(cat)
            topDrivers.append(entry)
            if topDrivers.count >= 3 { break }
        }

        let narrative: String?
        if let top = topDrivers.first {
            narrative = "\(top.planet) \(top.aspect) \(top.natalTarget)"
        } else {
            narrative = nil
        }

        return SkySalienceProfile(
            entries: entries,
            topDrivers: topDrivers,
            dominantNarrative: narrative
        )
    }

    /// §6h named-event surfacing: on special-event days (supermoon / micromoon / eclipse)
    /// prepend a Moon-led driver to the day's salience profile so every downstream consumer
    /// reads the event — the accent ranking (Moon's essence category becomes the sky's top
    /// driver, cooldown-exempt), the essence transit boost, intensity/tempo derivation, and
    /// the plan's salienceDrivers/skyJustification strings, which carry the event label.
    /// Fingerprint-neutral: no calibration change; pre-v1.0.2 paths never call this.
    static func injectNamedEventDriver(
        into profile: SkySalienceProfile,
        event: LunarEvent
    ) -> SkySalienceProfile {
        let driver = SkySalienceProfile.SalienceEntry(
            planet: "Moon",
            aspect: event.eventLabel,
            natalTarget: "Earth",
            rawStrength: event.strength,
            speedFactor: salienceSpeedFactors["Moon"] ?? 1.0,
            freshnessBonus: 0.0,
            salience: 1.0,
            essenceCategory: salienceEssenceCategories["Moon"]
        )
        // Prepend as the top driver; drop lower entries sharing the Moon's essence category
        // so topDrivers keeps one entry per category (mirrors computeSkySalience's dedup).
        let dedupedTop = profile.topDrivers.filter { $0.essenceCategory != driver.essenceCategory }
        return SkySalienceProfile(
            entries: [driver] + profile.entries,
            topDrivers: [driver] + dedupedTop.prefix(2),
            dominantNarrative: "\(driver.planet) \(driver.aspect) \(driver.natalTarget)"
        )
    }

    // MARK: - Phase 2: Lunar Context

    private static func buildLunarContext(
        moonPhaseDegrees: Double,
        namedEvent: LunarEvent? = nil
    ) -> LunarContext {
        let phase = MoonPhaseInterpreter.Phase.fromDegrees(moonPhaseDegrees)
        let element: String
        switch phase {
        case .newMoon, .fullMoon:              element = "Water"
        case .firstQuarter, .lastQuarter:      element = "Fire"
        case .waxingCrescent, .waningCrescent: element = "Air"
        case .waxingGibbous, .waningGibbous:   element = "Earth"
        }
        let normalized = moonPhaseDegrees
            .truncatingRemainder(dividingBy: 360.0)

        // D2 (F2, second half): near a syzygy the date-keyed LunarEventDetector overrides the
        // 6°-bucket phase name so a true full moon always reads "Full Moon" instead of the
        // mislabelled "Waning Gibbous". Only on the v1.0.2 sky-fidelity path (nil elsewhere).
        var phaseName = phase.description
        if let namedEvent {
            phaseName = namedEvent.phaseLabel
        }

        return LunarContext(
            phaseName: phaseName,
            isWaxing: normalized >= 0 && normalized < 180.0,
            element: element,
            phaseDegrees: moonPhaseDegrees,
            namedEvent: namedEvent.flatMap {
                $0.isSpecialEvent
                    ? NamedLunarEventSummary(label: $0.eventLabel, strength: $0.strength)
                    : nil
            }
        )
    }
}
