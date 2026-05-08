//
//  ChartSignatureResolver.swift
//  Cosmic Fit
//
//  V4.4 — personal chart-signature colours. Produces two swatches per
//  user that sit alongside the family template + anchors:
//
//  - Luminary signature → hero colour, derived from the Sun's sign.
//  - Ruler signature    → signature colour, derived from the sign of the
//                         traditional domicile ruler of the Ascendant.
//
//  Both are computed by taking a classical sign archetype (an LCH
//  "colour affinity" for each zodiac sign) and projecting it into the
//  family's perceptual envelope (lightness ladder, chroma ceiling, hue
//  arc). This way two Deep Autumns with different Sun signs can share
//  the Deep Autumn template + anchors yet still get visibly different
//  hero/signature cells — the first layer of user-level individuation
//  beyond family classification and secondary pulls.
//
//  Deterministic, Foundation-only, pull-invariant. No chart data beyond
//  the sign-level `BirthChartColourInput` is required.
//

import Foundation

enum ChartSignatureResolver {

    // MARK: - Public API

    /// Luminary hero colour — always derived from the Sun's sign. The Sun
    /// is the classical "core identity" body across both Hellenistic and
    /// modern traditions, so using it regardless of sect keeps the
    /// algorithm predictable without needing horizon/house data.
    static func luminarySignature(
        family: PaletteFamily,
        input: BirthChartColourInput
    ) -> String {
        let sign = input.sun.sign
        return hex(for: sign, family: family)
    }

    /// Ruler signature colour — derived from the sign of the traditional
    /// domicile ruler of the Ascendant. We look up the Ascendant sign's
    /// ruling planet, read that planet's own sign off the input, and
    /// project that sign's archetype into the family envelope.
    ///
    /// Uses traditional Ptolemaic rulerships (Scorpio → Mars, Aquarius →
    /// Saturn, Pisces → Jupiter) so the resolver works with only the
    /// seven classical bodies we already capture as required input.
    static func rulerSignature(
        family: PaletteFamily,
        input: BirthChartColourInput
    ) -> String {
        let rulerPlanet = domicileRuler(of: input.ascendant.sign)
        let rulerSign = input.sign(for: rulerPlanet) ?? input.ascendant.sign
        return hex(for: rulerSign, family: family)
    }

    // MARK: - Internal: sign → hex pipeline

    private static func hex(for sign: V4ZodiacSign, family: PaletteFamily) -> String {
        let archetype = archetypes[sign]!
        let envelope = envelope(for: family)

        let L = envelope.lightness.clamp(archetype.L)
        let C = envelope.chroma.clamp(archetype.C)
        let h = envelope.hue.clampCircular(archetype.h)

        return ColourMath.lchToHex(L: L, C: C, h: h)
    }

    // MARK: - Sign archetype table

    /// Classical sign → colour archetype, expressed as a CIE LCH triplet.
    /// Values are hand-calibrated against the Firmicus / Agrippa / Lilly
    /// tradition of planetary/zodiacal colour correspondences, but
    /// expressed in a perceptually uniform space so they can be safely
    /// projected into any family envelope without gamut surprises.
    ///
    /// - `L`: CIE L\* (0–100). Lower = darker.
    /// - `C`: CIE C\* chroma (0–128 practical range). Higher = more saturated.
    /// - `h`: CIE hue angle in degrees (0 = red, 90 = yellow, 180 = teal,
    ///        270 = blue-violet).
    struct Archetype: Equatable {
        let L: Double
        let C: Double
        let h: Double
    }

    static let archetypes: [V4ZodiacSign: Archetype] = [
        .aries:       Archetype(L: 48, C: 60, h:  28),  // vivid red, martial
        .taurus:      Archetype(L: 42, C: 32, h: 130),  // earth-green, fertile
        .gemini:      Archetype(L: 72, C: 50, h:  85),  // bright yellow, airy
        .cancer:      Archetype(L: 78, C: 12, h: 225),  // silvery pale-blue
        .leo:         Archetype(L: 72, C: 55, h:  78),  // gold, solar
        .virgo:       Archetype(L: 52, C: 22, h: 105),  // sage / drab, Mercurial
        .libra:       Archetype(L: 75, C: 28, h:  10),  // rose, Venusian
        .scorpio:     Archetype(L: 26, C: 42, h:  15),  // deep wine-red
        .sagittarius: Archetype(L: 35, C: 55, h: 310),  // royal purple, Jovial
        .capricorn:   Archetype(L: 22, C: 12, h: 260),  // dark slate, Saturnine
        .aquarius:    Archetype(L: 55, C: 42, h: 215),  // electric blue-teal
        .pisces:      Archetype(L: 70, C: 25, h: 185),  // aquamarine
    ]

    // MARK: - Family envelope

    /// A perceptual envelope describing which Lab region a family's
    /// signature swatches may occupy. Derived from the family's canonical
    /// `DerivedVariables` (depth → L\* ladder, saturation → chroma ceiling,
    /// temperature → hue arc) so the envelope and the family template are
    /// guaranteed to stay in sync.
    struct Envelope: Equatable {
        let lightness: ClosedLabRange
        let chroma: ClosedLabRange
        let hue: HueArc
    }

    static func envelope(for family: PaletteFamily) -> Envelope {
        let variables = FamilyProfiles.variables(for: family)
        return Envelope(
            lightness: lightnessRange(for: variables.depth),
            chroma: chromaRange(for: variables.saturation),
            hue: hueArc(for: variables.temperature)
        )
    }

    private static func lightnessRange(for depth: DepthLevel) -> ClosedLabRange {
        switch depth {
        case .light:  return ClosedLabRange(min: 70, max: 92)
        case .medium: return ClosedLabRange(min: 40, max: 75)
        case .deep:   return ClosedLabRange(min: 18, max: 48)
        }
    }

    private static func chromaRange(for saturation: Saturation) -> ClosedLabRange {
        switch saturation {
        case .soft:  return ClosedLabRange(min:  6, max: 22)
        case .muted: return ClosedLabRange(min: 14, max: 32)
        case .rich:  return ClosedLabRange(min: 22, max: 60)
        }
    }

    private static func hueArc(for temperature: Temperature) -> HueArc {
        switch temperature {
        case .warm:    return HueArc(start:  10, end:  95)   // red → yellow-green
        case .neutral: return HueArc(start:   0, end: 360)   // full circle (no clamp)
        case .cool:    return HueArc(start: 170, end: 310)   // teal → magenta
        }
    }

    // MARK: - Domicile rulership (traditional)

    /// Ptolemaic domicile lord of each sign. Tradition assigns two signs
    /// per planet (other than the luminaries), so this mapping is stable
    /// and requires no modern outer planets.
    private static func domicileRuler(of sign: V4ZodiacSign) -> DriverKey {
        switch sign {
        case .aries:       return .mars
        case .taurus:      return .venus
        case .gemini:      return .mercury
        case .cancer:      return .moon
        case .leo:         return .sun
        case .virgo:       return .mercury
        case .libra:       return .venus
        case .scorpio:     return .mars
        case .sagittarius: return .jupiter
        case .capricorn:   return .saturn
        case .aquarius:    return .saturn
        case .pisces:      return .jupiter
        }
    }
}

// MARK: - Envelope primitives

/// Closed inclusive range over the real line, with a linear clamp. Used
/// for CIE L\* and C\* because those axes are unbounded linearly (no
/// wraparound), unlike hue.
struct ClosedLabRange: Equatable {
    let min: Double
    let max: Double

    func clamp(_ value: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}

/// An arc on the hue circle `[0, 360)` expressed as `(start, end)` going
/// counter-clockwise. If `end < start` the arc wraps over 0 (e.g. the
/// warm arc can be written as `start=345, end=95`); we don't rely on
/// wrap in the built-in envelopes but the clamp supports it.
///
/// `clampCircular` snaps any hue outside the arc to whichever endpoint is
/// closer on the circle, preserving the sign's general direction (warm
/// targets land on the warm edge, cool targets on the cool edge) without
/// collapsing everything to a single hue.
struct HueArc: Equatable {
    let start: Double
    let end: Double

    func contains(_ hue: Double) -> Bool {
        let normalized = hue.modulo360()
        if start == 0 && end == 360 { return true }   // full circle
        if start <= end {
            return normalized >= start && normalized <= end
        } else {
            return normalized >= start || normalized <= end
        }
    }

    func clampCircular(_ hue: Double) -> Double {
        let normalized = hue.modulo360()
        if contains(normalized) { return normalized }
        let distToStart = shortestAngularDistance(from: normalized, to: start)
        let distToEnd   = shortestAngularDistance(from: normalized, to: end)
        return distToStart <= distToEnd ? start : end
    }

    private func shortestAngularDistance(from a: Double, to b: Double) -> Double {
        let raw = abs(a - b).truncatingRemainder(dividingBy: 360)
        return Swift.min(raw, 360 - raw)
    }
}

private extension Double {
    func modulo360() -> Double {
        let r = truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }
}
