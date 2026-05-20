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
        var rawScores: [Energy: Double] = [:]
        for energy in Energy.allCases { rawScores[energy] = 0.0 }

        let weights = calibration.sourceWeights

        // Step 1: Accumulate raw energy scores from each source
        accumulateChartContribution(
            chart: natalChart, weight: weights.natal, into: &rawScores
        )
        accumulateChartContribution(
            chart: progressedChart, weight: weights.progressed, into: &rawScores
        )
        accumulateTransitContribution(
            transits: transits, weight: weights.transits, into: &rawScores
        )
        accumulateLunarContribution(
            moonPhaseDegrees: moonPhaseDegrees, weight: weights.lunarPhase, into: &rawScores
        )
        accumulateCurrentSunContribution(
            date: date, weight: weights.currentSun, into: &rawScores
        )

        // Step 2: Apply sun-sign multipliers
        let sunSign = extractSunSignName(from: natalChart)
        for energy in Energy.allCases {
            let multiplier = calibration.signEnergyMap.multiplier(forSign: sunSign, energy: energy)
            rawScores[energy]! *= multiplier
        }

        if mode == .stage1Experimental {
            applyStage1TransitVibeNudge(transits: transits, into: &rawScores)
        }

        // Step 3: Normalise to 21 integer points
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

        let vibeProfile = generateVibeProfile(
            natalChart: natalChart, progressedChart: progressedChart,
            transits: transits, moonPhaseDegrees: moonPhaseDegrees,
            date: date, calibration: calibration, mode: effectiveMode
        )
        let dailySeed = dailySeed(
            profileHash: profileHash,
            date: date,
            engineId: resolvedEngineId,
            mode: effectiveMode
        )
        let axes = evaluateAxes(
            natalChart: natalChart, progressedChart: progressedChart,
            transits: transits, moonPhaseDegrees: moonPhaseDegrees,
            dailySeed: dailySeed, calibration: calibration
        )
        return DailyEnergySnapshot(
            vibeProfile: vibeProfile,
            axes: axes,
            dominantTransits: extractDominantTransits(from: transits),
            lunarContext: buildLunarContext(moonPhaseDegrees: moonPhaseDegrees),
            dailySeed: dailySeed,
            profileHash: profileHash,
            generatedAt: date
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
        into scores: inout [Energy: Double]
    ) {
        for planet in chart.planets {
            guard let baseEnergies = planetEnergyBase[planet.name] else { continue }
            let element = signElement(forZodiacSign: planet.zodiacSign)
            let boosts = elementBoosts[element] ?? [:]

            for energy in Energy.allCases {
                let base = baseEnergies[energy] ?? 0.0
                let boost = boosts[energy] ?? 0.0
                scores[energy]! += (base + boost) * weight
            }
        }
    }

    // MARK: - Transit Contribution

    private static func accumulateTransitContribution(
        transits: [NatalChartCalculator.TransitAspect],
        weight: Double,
        into scores: inout [Energy: Double]
    ) {
        for transit in transits {
            guard let baseEnergies = planetEnergyBase[transit.transitPlanet] else { continue }

            let orbStrength = max(0.0, 1.0 - transit.orb / 10.0)
            let isHard = isHardAspect(transit.aspectType)
            let isSoft = isSoftAspect(transit.aspectType)

            for energy in Energy.allCases {
                var contribution = (baseEnergies[energy] ?? 0.0) * orbStrength

                if isHard {
                    if energy == .drama || energy == .edge { contribution *= 1.3 }
                } else if isSoft {
                    if energy == .romantic || energy == .classic { contribution *= 1.3 }
                }

                scores[energy]! += contribution * weight
            }
        }
    }

    // MARK: - Lunar Contribution

    private static func accumulateLunarContribution(
        moonPhaseDegrees: Double,
        weight: Double,
        into scores: inout [Energy: Double]
    ) {
        let phase = MoonPhaseInterpreter.Phase.fromDegrees(moonPhaseDegrees)
        let biases = lunarPhaseEnergies[phase] ?? [:]

        for energy in Energy.allCases {
            scores[energy]! += (biases[energy] ?? 0.0) * weight
        }
    }

    // MARK: - Current Sun Contribution

    private static func accumulateCurrentSunContribution(
        date: Date,
        weight: Double,
        into scores: inout [Energy: Double]
    ) {
        let element = currentSunElement(for: date)
        let boosts = elementBoosts[element] ?? [:]

        for energy in Energy.allCases {
            let base = 1.0 / Double(Energy.allCases.count)
            let boost = boosts[energy] ?? 0.0
            scores[energy]! += (base + boost) * weight
        }
    }

    // MARK: - Stage 1 experimental (central mode branch helpers)

    /// Boosts raw vibe scores from the tightest transit before quantisation (Stage 1 redesign).
    private static func applyStage1TransitVibeNudge(
        transits: [NatalChartCalculator.TransitAspect],
        into rawScores: inout [Energy: Double]
    ) {
        guard let tightest = transits.min(by: { abs($0.orb) < abs($1.orb) }),
              let baseEnergies = planetEnergyBase[tightest.transitPlanet] else {
            return
        }
        let strength = max(0.0, 1.0 - abs(tightest.orb) / 10.0)
        for energy in Energy.allCases {
            rawScores[energy]! += (baseEnergies[energy] ?? 0.0) * strength * 0.35
        }
    }

    private static func dailySeed(
        profileHash: String,
        date: Date,
        engineId: String,
        mode: DailyFitEngineMode
    ) -> Int {
        let descriptor = DailyFitEngineRegistry.descriptor(for: engineId)
        let policy = descriptor?.dailySeedPolicy ?? .sharedProfileDate
        if policy == .includesEngineId, mode == .stage1Experimental {
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
        accumulateChartContribution(chart: natalChart, weight: weights.natal, into: &natalScores)
        accumulateChartContribution(chart: progressedChart, weight: weights.progressed, into: &progressedScores)
        accumulateTransitContribution(transits: transits, weight: weights.transits, into: &transitScores)
        accumulateLunarContribution(moonPhaseDegrees: moonPhaseDegrees, weight: weights.lunarPhase, into: &lunarScores)
        accumulateCurrentSunContribution(date: date, weight: weights.currentSun, into: &currentSunScores)
        for energy in Energy.allCases {
            rawScores[energy] = natalScores[energy]! + transitScores[energy]!
                + lunarScores[energy]! + progressedScores[energy]! + currentSunScores[energy]!
        }
        let rawDict = Dictionary(uniqueKeysWithValues: rawScores.map { ($0.key.rawValue, $0.value) })
        let sunSign = extractSunSignName(from: natalChart)
        var postMultiplier = rawScores
        for energy in Energy.allCases {
            postMultiplier[energy]! *= calibration.signEnergyMap.multiplier(forSign: sunSign, energy: energy)
        }
        if effectiveMode == .stage1Experimental {
            applyStage1TransitVibeNudge(transits: transits, into: &postMultiplier)
        }
        let postDict = Dictionary(uniqueKeysWithValues: postMultiplier.map { ($0.key.rawValue, $0.value) })
        let vibeProfile = normaliseToTwentyOne(postMultiplier)
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
            dailySeed: dailySeed, calibration: calibration
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
        let snapshot = DailyEnergySnapshot(
            vibeProfile: vibeProfile, axes: axes,
            dominantTransits: extractDominantTransits(from: transits),
            lunarContext: buildLunarContext(moonPhaseDegrees: moonPhaseDegrees),
            dailySeed: dailySeed, profileHash: profileHash, generatedAt: date
        )
        let rawAxisDict = axisNames.reduce(into: [String: Double]()) { result, axis in
            var raw = 0.0
            for planet in natalChart.planets {
                let w = calibration.planetAxisMap.weight(forPlanet: planet.name, axis: axis)
                let em = axisElementModifiers[axis]?[signElement(forZodiacSign: planet.zodiacSign)] ?? 1.0
                raw += w * em * weights.natal
            }
            result[axis] = raw
        }
        let trace = SnapshotTrace(
            rawScores: rawDict, postMultiplierScores: postDict,
            rawAxisScores: rawAxisDict, sourceContributions: contributions
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
        calibration: DailyFitCalibration
    ) -> DerivedAxes {
        let sw = calibration.sourceWeights
        var rng = SeededRandomGenerator(seed: dailySeed)
        let moonMods = moonPhaseAxisModulations(moonPhaseDegrees)
        var scores = [String: Double]()

        for axis in axisNames {
            var raw = 0.0

            for planet in natalChart.planets {
                let w = calibration.planetAxisMap.weight(forPlanet: planet.name, axis: axis)
                let em = axisElementModifiers[axis]?[
                    signElement(forZodiacSign: planet.zodiacSign)
                ] ?? 1.0
                raw += w * em * sw.natal
            }

            for planet in progressedChart.planets {
                let w = calibration.planetAxisMap.weight(forPlanet: planet.name, axis: axis)
                let em = axisElementModifiers[axis]?[
                    signElement(forZodiacSign: planet.zodiacSign)
                ] ?? 1.0
                raw += w * em * sw.progressed
            }

            for transit in transits {
                let w = calibration.planetAxisMap.weight(
                    forPlanet: transit.transitPlanet, axis: axis
                )
                raw += w * max(0.0, 1.0 - transit.orb / 10.0) * sw.transits
            }

            raw -= axisBaseline(axis, calibration: calibration)
            raw += moonMods[axis] ?? 0.0
            raw += Double.random(in: -calibration.axisTuning.jitterRange...calibration.axisTuning.jitterRange, using: &rng)
            scores[axis] = scaleToAxis(raw, spread: calibration.axisTuning.sigmoidSpread)
        }

        return DerivedAxes(
            action: scores["action"]!, tempo: scores["tempo"]!,
            strategy: scores["strategy"]!, visibility: scores["visibility"]!
        )
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

    // MARK: - Phase 2: Lunar Context

    private static func buildLunarContext(
        moonPhaseDegrees: Double
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
        return LunarContext(
            phaseName: phase.description,
            isWaxing: normalized >= 0 && normalized < 180.0,
            element: element,
            phaseDegrees: moonPhaseDegrees
        )
    }
}
