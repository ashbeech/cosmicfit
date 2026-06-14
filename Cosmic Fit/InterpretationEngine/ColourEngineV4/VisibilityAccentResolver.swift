import Foundation

/// V4.9 — MC Visibility Accent Resolver.
///
/// When the Midheaven is a fire or air sign and the existing accent band
/// lacks coverage in the MC ruler's colour direction, appends one vivid
/// accent with role `.visibility`. Complements DepthOverlayResolver
/// (which handles depth-sign MCs) by covering brightness-sign MCs.
///
/// Runs as step 14d in the pipeline — after accent depth injection (14b)
/// and accent slot sync (14c), before final palette assembly.
enum VisibilityAccentResolver {

    // MARK: - Public Types

    struct VisibilityResult: Codable, Equatable {
        let slot: AccentSlot?
        let mcSign: V4ZodiacSign?
        let rulerPlanet: DriverKey?
        let rulerSign: V4ZodiacSign?
        let applied: Bool
        let skipReason: String?

        static let none = VisibilityResult(
            slot: nil, mcSign: nil, rulerPlanet: nil,
            rulerSign: nil, applied: false, skipReason: nil
        )
    }

    // MARK: - Constants

    private static let visibilitySigns: Set<V4ZodiacSign> = [
        .aries, .gemini, .leo, .libra, .sagittarius, .aquarius
    ]

    private static let alreadyBrightFamilies: Set<PaletteFamily> = [
        .brightSpring, .brightWinter
    ]

    private static let hueCoverageThreshold: Double = 40.0
    private static let chromaticFloor: Double = 15.0
    private static let vibrancyChromaMin: Double = 30.0
    private static let vibrancyLightnessMin: Double = 35.0
    private static let vibrancyLightnessMax: Double = 70.0

    // MARK: - Public API

    static func resolve(
        family: PaletteFamily,
        input: BirthChartColourInput,
        accentHexes: [String],
        accentSlots: [AccentSlot],
        existingPaletteHexes: [String]
    ) -> VisibilityResult {

        // Gate 1: MC must exist and be a fire/air sign
        guard let mc = input.midheaven else {
            return VisibilityResult(
                slot: nil, mcSign: nil, rulerPlanet: nil,
                rulerSign: nil, applied: false, skipReason: "no MC"
            )
        }

        let mcSign = mc.sign
        guard visibilitySigns.contains(mcSign) else {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: nil,
                rulerSign: nil, applied: false,
                skipReason: "MC not a visibility sign"
            )
        }

        // Gate 2: Family must not already be bright/high-contrast
        guard !alreadyBrightFamilies.contains(family) else {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: nil,
                rulerSign: nil, applied: false,
                skipReason: "family already bright"
            )
        }

        // Resolve MC ruler and ruler sign
        let rulerKey = SignArchetypes.domicileRuler(of: mcSign)
        guard let rulerSign = input.sign(for: rulerKey) else {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: rulerKey,
                rulerSign: nil, applied: false,
                skipReason: "ruler planet sign unavailable"
            )
        }

        // Gate 4: Ruler sign must not already be in accent band
        if accentSlots.contains(where: { $0.sourceSign == rulerSign }) {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: rulerKey,
                rulerSign: rulerSign, applied: false,
                skipReason: "ruler sign already in accent band"
            )
        }

        // Get candidates for ruler sign
        let temperature = FamilyProfiles.variables(for: family).temperature
        let candidates = SignAccentExpressions.candidates(
            for: rulerSign, temperature: temperature
        )
        guard !candidates.isEmpty else {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: rulerKey,
                rulerSign: rulerSign, applied: false,
                skipReason: "no accent candidates for ruler sign"
            )
        }

        // Gate 3: Existing accent band must lack coverage in the MC ruler's hue direction
        let targetHue = candidates[0].h
        if isHueCovered(targetHue: targetHue, accentHexes: accentHexes) {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: rulerKey,
                rulerSign: rulerSign, applied: false,
                skipReason: "hue already covered"
            )
        }

        // Colour selection
        let slot = selectVisibilityAccent(
            candidates: candidates,
            rulerKey: rulerKey,
            rulerSign: rulerSign,
            accentHexes: accentHexes,
            existingPaletteHexes: existingPaletteHexes
        )

        guard let chosenSlot = slot else {
            return VisibilityResult(
                slot: nil, mcSign: mcSign, rulerPlanet: rulerKey,
                rulerSign: rulerSign, applied: false,
                skipReason: "no viable candidate after filtering"
            )
        }

        return VisibilityResult(
            slot: chosenSlot, mcSign: mcSign, rulerPlanet: rulerKey,
            rulerSign: rulerSign, applied: true, skipReason: nil
        )
    }

    // MARK: - Hue Coverage Check

    private static func isHueCovered(
        targetHue: Double,
        accentHexes: [String]
    ) -> Bool {
        for hex in accentHexes {
            guard let lab = ColourMath.hexToLab(hex) else { continue }
            let chroma = sqrt(lab.a * lab.a + lab.b * lab.b)
            guard chroma >= chromaticFloor else { continue }
            let hue = atan2(lab.b, lab.a) * 180.0 / .pi
            let normalizedHue = hue < 0 ? hue + 360.0 : hue
            let angularDist = angularDistance(normalizedHue, targetHue)
            if angularDist <= hueCoverageThreshold {
                return true
            }
        }
        return false
    }

    private static func angularDistance(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360.0)
        return diff > 180.0 ? 360.0 - diff : diff
    }

    // MARK: - Colour Selection

    private static func selectVisibilityAccent(
        candidates: [SignExpression],
        rulerKey: DriverKey,
        rulerSign: V4ZodiacSign,
        accentHexes: [String],
        existingPaletteHexes: [String]
    ) -> AccentSlot? {

        // Filter for vibrancy
        let vivid = candidates.filter {
            $0.C >= vibrancyChromaMin &&
            $0.L >= vibrancyLightnessMin &&
            $0.L <= vibrancyLightnessMax
        }

        let pool = vivid.isEmpty
            ? candidates.sorted { $0.C > $1.C }
            : vivid

        // Pick the most distinct candidate (maximum minimum ΔE² from all existing hexes)
        let avoidHexes = existingPaletteHexes + accentHexes
        var best: (hex: String, name: String, dist: Double)?

        for expr in pool {
            let hex = ColourMath.lchToHex(L: expr.L, C: expr.C, h: expr.h)
            let minDist = avoidHexes.reduce(Double.infinity) { bestDist, existing in
                min(bestDist, ColourMath.labDistanceSquared(hex, existing))
            }
            if best == nil || minDist > best!.dist {
                best = (hex: hex, name: expr.name, dist: minDist)
            }
        }

        guard let chosen = best else { return nil }

        return AccentSlot(
            hex: chosen.hex,
            displayName: chosen.name,
            role: .visibility,
            sourcePlanet: rulerKey,
            sourceSign: rulerSign,
            saturationOverrideApplied: false
        )
    }
}
