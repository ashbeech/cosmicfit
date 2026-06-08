//
//  AccentResolver.swift
//  Cosmic Fit
//
//  V4.10 — Collapse to a single accent when two resolved slots share the
//  same hue family (< 30° Lab hue separation, both chromatic).
//
//  V4.9 — Chart-derived accent colour resolution with core-hue skip rule.
//  Accents cannot occupy a core hue zone unless every underrepresented
//  placement has been exhausted. If a placement's entire candidate pool
//  overlaps core hues, skip to the next underrepresented placement.
//
//  Key changes from V4.8:
//    • Core-hue gate (hard floor at 20°) separated from accent-to-accent
//      gate (relaxation ladder). Core gate never relaxes during normal
//      selection — the resolver skips the source instead.
//    • Two-phase source traversal: underrepresented first, then represented.
//      Terminal fallback may break core gate only after all sources exhausted.
//    • AccentSource struct replaces raw tuples for deterministic traversal.
//    • hasAnyCoreHueViableCandidate pre-check avoids entering selection
//      when entire pool overlaps core.
//

import Foundation

enum AccentResolver {

    // MARK: - Configuration

    private static let hueSetChromaFloor: Double = 10.0
    private static let coreHueMinimumAngle: Double = 20.0
    private static let collapseHueThreshold: Double = 30.0
    private static let accentHueThresholdLadder: [Double] = [40, 30, 20, 10, 0]
    private static let pairwiseLabThreshold: Double = 64.0 // ΔE ≥ 8 squared

    // MARK: - Source Metadata

    struct AccentSource {
        let planet: DriverKey
        let sign: V4ZodiacSign
        let isUnderrepresented: Bool
        let rank: Int
    }

    // MARK: - Selection Mode

    private enum SelectionMode {
        case strictCoreGate
        case terminalFallback
    }

    // MARK: - Public API

    static func resolve(
        family: PaletteFamily,
        input: BirthChartColourInput,
        personalPaletteHexes: [String] = []
    ) -> [AccentSlot] {
        let temperature = FamilyProfiles.variables(for: family).temperature
        let env = SignArchetypes.envelope(for: family)

        let coreHues = personalPaletteHexes.compactMap { hex -> Double? in
            guard let lab = ColourMath.hexToLab(hex) else { return nil }
            let C = sqrt(lab.a * lab.a + lab.b * lab.b)
            guard C >= hueSetChromaFloor else { return nil }
            let h = atan2(lab.b, lab.a) * 180.0 / .pi
            return h < 0 ? h + 360.0 : h
        }

        let rankedSources = selectAccentSources(input: input, temperature: temperature)
        let underrepresented = rankedSources.filter { $0.isUnderrepresented }
        let represented = rankedSources.filter { !$0.isUnderrepresented }

        let roles: [AccentRole] = [.signature, .contrast]
        var chosenHexes: [String] = []
        var chosenHues: [Double] = []
        var usedSigns: Set<V4ZodiacSign> = []
        var slots: [AccentSlot] = []

        for role in roles {
            var selected: AccentSlot? = nil

            // Phase 1: underrepresented sources (hard core gate)
            for src in underrepresented {
                if usedSigns.contains(src.sign) { continue }
                let candidates = SignAccentExpressions.candidates(for: src.sign, temperature: temperature)
                if candidates.isEmpty { continue }
                if !hasAnyCoreHueViableCandidate(candidates: candidates, coreHues: coreHues) { continue }

                selected = selectBestCandidate(
                    candidates: candidates,
                    role: role,
                    planet: src.planet,
                    sign: src.sign,
                    corePaletteHexes: personalPaletteHexes,
                    coreHues: coreHues,
                    chosenHexes: chosenHexes,
                    chosenHues: chosenHues,
                    chromaFloor: env.chroma.min,
                    mode: .strictCoreGate
                )
                if selected != nil { break }
            }

            // Phase 2: represented sources (hard core gate)
            if selected == nil {
                for src in represented {
                    if usedSigns.contains(src.sign) { continue }
                    let candidates = SignAccentExpressions.candidates(for: src.sign, temperature: temperature)
                    if candidates.isEmpty { continue }
                    if !hasAnyCoreHueViableCandidate(candidates: candidates, coreHues: coreHues) { continue }

                    selected = selectBestCandidate(
                        candidates: candidates,
                        role: role,
                        planet: src.planet,
                        sign: src.sign,
                        corePaletteHexes: personalPaletteHexes,
                        coreHues: coreHues,
                        chosenHexes: chosenHexes,
                        chosenHues: chosenHues,
                        chromaFloor: env.chroma.min,
                        mode: .strictCoreGate
                    )
                    if selected != nil { break }
                }
            }

            // Phase 3: terminal fallback (may break core gate)
            if selected == nil {
                let fallbackSource = firstAvailableSource(from: rankedSources, excluding: usedSigns)
                    ?? rankedSources[0]
                let candidates = SignAccentExpressions.candidates(for: fallbackSource.sign, temperature: temperature)

                selected = selectBestCandidate(
                    candidates: candidates,
                    role: role,
                    planet: fallbackSource.planet,
                    sign: fallbackSource.sign,
                    corePaletteHexes: personalPaletteHexes,
                    coreHues: coreHues,
                    chosenHexes: chosenHexes,
                    chosenHues: chosenHues,
                    chromaFloor: env.chroma.min,
                    mode: .terminalFallback
                )
            }

            let slot = selected!
            slots.append(slot)
            chosenHexes.append(slot.hex)
            if let lab = ColourMath.hexToLab(slot.hex) {
                let h = atan2(lab.b, lab.a) * 180.0 / .pi
                chosenHues.append(h < 0 ? h + 360.0 : h)
            }
            usedSigns.insert(slot.sourceSign)
        }

        return collapseSimilarAccents(slots, personalPaletteHexes: personalPaletteHexes)
    }

    // MARK: - Collapse Similar Accents

    /// When two accents occupy the same hue family they read as one wardrobe move.
    /// Keep the slot with the stronger chart driver; break ties toward Signature.
    private static func collapseSimilarAccents(
        _ slots: [AccentSlot],
        personalPaletteHexes: [String]
    ) -> [AccentSlot] {
        guard slots.count == 2 else { return slots }
        let first = slots[0]
        let second = slots[1]

        guard shouldCollapse(first, second) else { return slots }
        return [preferredAccentSlot(first, second, personalPaletteHexes: personalPaletteHexes)]
    }

    private static func shouldCollapse(_ a: AccentSlot, _ b: AccentSlot) -> Bool {
        guard let hueA = chromaticHue(forHex: a.hex),
              let hueB = chromaticHue(forHex: b.hex) else {
            return false
        }
        return shortestAngularDistance(hueA, hueB) < collapseHueThreshold
    }

    private static func preferredAccentSlot(
        _ a: AccentSlot,
        _ b: AccentSlot,
        personalPaletteHexes: [String]
    ) -> AccentSlot {
        let weightA = DriverWeights.weight(for: a.sourcePlanet)
        let weightB = DriverWeights.weight(for: b.sourcePlanet)
        if weightA != weightB {
            return weightA > weightB ? a : b
        }
        if a.role == .signature && b.role != .signature { return a }
        if b.role == .signature && a.role != .signature { return b }
        return minPaletteDistanceSlot(a, b, personalPaletteHexes: personalPaletteHexes)
    }

    private static func minPaletteDistanceSlot(
        _ a: AccentSlot,
        _ b: AccentSlot,
        personalPaletteHexes: [String]
    ) -> AccentSlot {
        func minDistance(_ hex: String) -> Double {
            personalPaletteHexes.map { ColourMath.labDistanceSquared(hex, $0) }.min() ?? 0
        }
        return minDistance(a.hex) >= minDistance(b.hex) ? a : b
    }

    private static func chromaticHue(forHex hex: String) -> Double? {
        guard let lab = ColourMath.hexToLab(hex) else { return nil }
        let chroma = sqrt(lab.a * lab.a + lab.b * lab.b)
        guard chroma >= hueSetChromaFloor else { return nil }
        let h = atan2(lab.b, lab.a) * 180.0 / .pi
        return h < 0 ? h + 360.0 : h
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

    // MARK: - Source Selection

    private static func selectAccentSources(
        input: BirthChartColourInput,
        temperature: Temperature
    ) -> [AccentSource] {
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

        var sources: [AccentSource] = []
        var usedSigns: Set<V4ZodiacSign> = []

        for (rank, p) in placements.enumerated() {
            guard !usedSigns.contains(p.sign) else { continue }
            sources.append(AccentSource(
                planet: p.key, sign: p.sign,
                isUnderrepresented: p.isUnderrepresented, rank: rank
            ))
            usedSigns.insert(p.sign)
        }

        return sources
    }

    private static func coreCoveredElements(
        for temperature: Temperature
    ) -> Set<V4ZodiacSign.Element> {
        switch temperature {
        case .warm:    return [.fire, .earth]
        case .cool:    return [.water, .air]
        case .neutral: return [.fire, .earth]
        }
    }

    private static func firstAvailableSource(
        from sources: [AccentSource],
        excluding usedSigns: Set<V4ZodiacSign>
    ) -> AccentSource? {
        sources.first { !usedSigns.contains($0.sign) }
    }

    // MARK: - Gate Helpers

    private static func passesCoreHueGate(candidateHue: Double, coreHues: [Double]) -> Bool {
        coreHues.allSatisfy { coreHue in
            shortestAngularDistance(candidateHue, coreHue) >= coreHueMinimumAngle
        }
    }

    private static func passesAccentHueGate(candidateHue: Double, chosenHues: [Double], threshold: Double) -> Bool {
        chosenHues.allSatisfy { accentHue in
            shortestAngularDistance(candidateHue, accentHue) >= threshold
        }
    }

    private static func hasAnyCoreHueViableCandidate(candidates: [SignExpression], coreHues: [Double]) -> Bool {
        if coreHues.isEmpty { return true }
        return candidates.contains { expr in
            let hex = ColourMath.lchToHex(L: expr.L, C: expr.C, h: expr.h)
            let hue = labHue(forHex: hex) ?? expr.h
            return passesCoreHueGate(candidateHue: hue, coreHues: coreHues)
        }
    }

    private static func labHue(forHex hex: String) -> Double? {
        guard let lab = ColourMath.hexToLab(hex) else { return nil }
        let h = atan2(lab.b, lab.a) * 180.0 / .pi
        return h < 0 ? h + 360.0 : h
    }

    // MARK: - Spike Scorer (hue novelty)

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
        chromaFloor: Double,
        mode: SelectionMode
    ) -> AccentSlot? {
        let avoidanceSet = corePaletteHexes + chosenHexes
        let allHuesForScoring = coreHues + chosenHues

        var scored: [(expr: SignExpression, score: Double, hex: String, hue: Double)] = candidates.map { expr in
            let hex = ColourMath.lchToHex(L: expr.L, C: expr.C, h: expr.h)
            let hue = labHue(forHex: hex) ?? expr.h
            let score = spikeScore(
                candidateHex: hex,
                candidateHue: hue,
                candidateChroma: expr.C,
                corePaletteHexes: avoidanceSet,
                coreHues: allHuesForScoring,
                chromaFloor: chromaFloor
            )
            return (expr, score, hex, hue)
        }

        scored.sort { $0.score > $1.score }

        for accentThreshold in accentHueThresholdLadder {
            for entry in scored {
                let passesLab = chosenHexes.allSatisfy { chosen in
                    ColourMath.labDistanceSquared(entry.hex, chosen) >= pairwiseLabThreshold
                }
                let passesAccentHue = passesAccentHueGate(
                    candidateHue: entry.hue, chosenHues: chosenHues, threshold: accentThreshold
                )
                let passesCoreHue = passesCoreHueGate(candidateHue: entry.hue, coreHues: coreHues)

                switch mode {
                case .strictCoreGate:
                    if passesLab && passesAccentHue && passesCoreHue {
                        return AccentSlot(
                            hex: entry.hex,
                            displayName: entry.expr.name,
                            role: role,
                            sourcePlanet: planet,
                            sourceSign: sign,
                            saturationOverrideApplied: false
                        )
                    }
                case .terminalFallback:
                    if passesLab && passesAccentHue {
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
        }

        switch mode {
        case .strictCoreGate:
            return nil
        case .terminalFallback:
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
}
