//
//  AccentResolver.swift
//  Cosmic Fit
//
//  V4.8 — Chart-derived accent colour resolution with hard hue-separation
//  gates. Accent slots surface placements whose colour story is
//  underrepresented by the core palette, then pick candidates that
//  maximise hue novelty while staying harmonious within the family's
//  perceptual envelope.
//
//  Key changes from V4.7:
//    • Hard hue-angle gate with relaxation ladder (40° → 30° → 20° → 10° → 0°)
//      replaces soft-score-only approach. Accents must occupy a distinct hue
//      zone from both the core palette and previously chosen accents.
//    • Chosen accent hues are tracked and fed into each subsequent iteration,
//      preventing accent-to-accent hue doubling.
//    • Core hue set is chroma-filtered (C ≥ 10) so that near-neutral colours
//      with noisy hue angles don't generate phantom occupancy.
//    • Lab distance gate retained as secondary guard (ΔE ≥ 8).
//

import Foundation

enum AccentResolver {

    // MARK: - Public API

    static func resolve(
        family: PaletteFamily,
        input: BirthChartColourInput,
        personalPaletteHexes: [String] = []
    ) -> [AccentSlot] {
        let temperature = FamilyProfiles.variables(for: family).temperature
        let env = SignArchetypes.envelope(for: family)

        let sources = selectAccentSources(input: input, temperature: temperature)

        let coreHues = personalPaletteHexes.compactMap { hex -> Double? in
            guard let lab = ColourMath.hexToLab(hex) else { return nil }
            let C = sqrt(lab.a * lab.a + lab.b * lab.b)
            guard C >= hueSetChromaFloor else { return nil }
            let h = atan2(lab.b, lab.a) * 180.0 / .pi
            return h < 0 ? h + 360.0 : h
        }

        let roles: [AccentRole] = [.signature, .contrast]
        let slotCount = roles.count
        var chosenHexes: [String] = []
        var chosenHues: [Double] = []
        var slots: [AccentSlot] = []

        for (i, (planet, sign)) in sources.prefix(slotCount).enumerated() {
            let candidates = SignAccentExpressions.candidates(for: sign, temperature: temperature)
            let slot = selectBestCandidate(
                candidates: candidates,
                role: roles[i],
                planet: planet,
                sign: sign,
                corePaletteHexes: personalPaletteHexes,
                coreHues: coreHues,
                chosenHexes: chosenHexes,
                chosenHues: chosenHues,
                chromaFloor: env.chroma.min
            )
            chosenHexes.append(slot.hex)
            if let lab = ColourMath.hexToLab(slot.hex) {
                let h = atan2(lab.b, lab.a) * 180.0 / .pi
                chosenHues.append(h < 0 ? h + 360.0 : h)
            }
            slots.append(slot)
        }

        return slots
    }

    // MARK: - Element Percentages (retained for external use)

    static func elementPercentages(input: BirthChartColourInput) -> [V4ZodiacSign.Element: Double] {
        var totals: [V4ZodiacSign.Element: Double] = [.fire: 0, .earth: 0, .air: 0, .water: 0]
        for (key, weight) in DriverWeights.weights {
            guard let sign = input.sign(for: key) else { continue }
            totals[sign.element, default: 0] += Double(weight)
        }
        return totals
    }

    // MARK: - Source Selection (underrepresented-first)

    /// Identifies which chart placements sit in elements the core palette
    /// does NOT already express (counter-temperature), then ranks by
    /// driver weight. Deduplicates by sign so each accent slot surfaces
    /// a distinct zodiac colour story.
    private static func selectAccentSources(
        input: BirthChartColourInput,
        temperature: Temperature
    ) -> [(DriverKey, V4ZodiacSign)] {
        let coreElements = coreCoveredElements(for: temperature)

        struct Placement {
            let key: DriverKey
            let sign: V4ZodiacSign
            let weight: Int
            let isUnderrepresented: Bool
        }

        var placements: [Placement] = []
        for (key, weight) in DriverWeights.weights.sorted(by: { $0.value > $1.value }) {
            guard let sign = input.sign(for: key) else { continue }
            placements.append(Placement(
                key: key, sign: sign, weight: weight,
                isUnderrepresented: !coreElements.contains(sign.element)
            ))
        }
        if let plutoSign = input.pluto?.sign {
            placements.append(Placement(
                key: .pluto, sign: plutoSign, weight: 0,
                isUnderrepresented: !coreElements.contains(plutoSign.element)
            ))
        }

        placements.sort { a, b in
            let aScore = (a.isUnderrepresented ? 100 : 0) + a.weight
            let bScore = (b.isUnderrepresented ? 100 : 0) + b.weight
            if aScore != bScore { return aScore > bScore }
            return a.key.rawValue < b.key.rawValue
        }

        var sources: [(DriverKey, V4ZodiacSign)] = []
        var usedSigns: Set<V4ZodiacSign> = []

        for p in placements {
            guard !usedSigns.contains(p.sign) else { continue }
            sources.append((p.key, p.sign))
            usedSigns.insert(p.sign)
            if sources.count >= 4 { break }
        }

        while sources.count < 4 {
            sources.append((.sun, input.sun.sign))
        }

        return sources
    }

    /// Elements whose colour story the family's core template already
    /// tells. Warm families express earth/fire (reds, browns, golds,
    /// greens); cool families express water/air (blues, teals, violets).
    /// Accents should prioritise the *other* group.
    private static func coreCoveredElements(
        for temperature: Temperature
    ) -> Set<V4ZodiacSign.Element> {
        switch temperature {
        case .warm:    return [.fire, .earth]
        case .cool:    return [.water, .air]
        case .neutral: return [.fire, .earth]
        }
    }

    // MARK: - Spike Scorer (hue novelty)

    /// Scores a candidate accent against the assembled core palette.
    ///
    ///   score = minΔE(candidate, avoidanceSet)
    ///         + hueNoveltyBonus(candidate vs coreHues)
    ///         − chromaPenalty(if chroma < floor)
    ///
    /// The hue novelty bonus rewards candidates whose hue angle is far
    /// from any colour already in the palette, penalising "hue doubling"
    /// even when raw Lab distance is high (e.g. a light gold vs dark
    /// terracotta — different lightness but same warm hue zone).
    private static func spikeScore(
        candidateHex: String,
        candidateHue: Double,
        candidateChroma: Double,
        corePaletteHexes: [String],
        coreHues: [Double],
        chromaFloor: Double
    ) -> Double {
        var minDeltaE: Double = 100.0
        if !corePaletteHexes.isEmpty {
            let minDistSq = corePaletteHexes.reduce(Double.infinity) { best, paletteHex in
                min(best, ColourMath.labDistanceSquared(candidateHex, paletteHex))
            }
            minDeltaE = minDistSq.isFinite ? minDistSq.squareRoot() : 0
        }

        var minHueDist: Double = 180.0
        for coreHue in coreHues {
            minHueDist = min(minHueDist, shortestAngularDistance(candidateHue, coreHue))
        }
        let hueNoveltyBonus = min(minHueDist / 30.0, 1.0) * 15.0

        let chromaPenalty: Double = candidateChroma < chromaFloor
            ? (chromaFloor - candidateChroma) * 0.5
            : 0.0

        return minDeltaE + hueNoveltyBonus - chromaPenalty
    }

    private static func shortestAngularDistance(_ a: Double, _ b: Double) -> Double {
        let raw = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(raw, 360 - raw)
    }

    // MARK: - Configuration

    private static let hueSetChromaFloor: Double = 10.0
    private static let hueThresholdLadder: [Double] = [40, 30, 20, 10, 0]
    private static let pairwiseLabThreshold: Double = 64.0 // ΔE ≥ 8 squared

    // MARK: - Candidate Selection

    private static func selectBestCandidate(
        candidates: [SignExpression],
        role: AccentRole,
        planet: DriverKey,
        sign: V4ZodiacSign,
        corePaletteHexes: [String],
        coreHues: [Double],
        chosenHexes: [String],
        chosenHues: [Double],
        chromaFloor: Double
    ) -> AccentSlot {
        let avoidanceSet = corePaletteHexes + chosenHexes
        let allAvoidHues = coreHues + chosenHues

        var scored: [(expr: SignExpression, score: Double, hex: String, hue: Double)] = candidates.map { expr in
            let hex = ColourMath.lchToHex(L: expr.L, C: expr.C, h: expr.h)
            let score = spikeScore(
                candidateHex: hex,
                candidateHue: expr.h,
                candidateChroma: expr.C,
                corePaletteHexes: avoidanceSet,
                coreHues: allAvoidHues,
                chromaFloor: chromaFloor
            )
            return (expr, score, hex, expr.h)
        }

        scored.sort { $0.score > $1.score }

        for threshold in hueThresholdLadder {
            for entry in scored {
                let passesLab = chosenHexes.allSatisfy { chosen in
                    ColourMath.labDistanceSquared(entry.hex, chosen) >= pairwiseLabThreshold
                }
                let passesHue = allAvoidHues.allSatisfy { avoidHue in
                    shortestAngularDistance(entry.hue, avoidHue) >= threshold
                }
                if passesLab && passesHue {
                    return AccentSlot(
                        hex: entry.hex,
                        displayName: entry.expr.name,
                        role: role,
                        sourcePlanet: planet,
                        sourceSign: sign,
                        saturationOverrideApplied: false
                    )
                }
            }
        }

        let best = scored[0]
        return AccentSlot(
            hex: best.hex,
            displayName: best.expr.name,
            role: role,
            sourcePlanet: planet,
            sourceSign: sign,
            saturationOverrideApplied: false
        )
    }
}
