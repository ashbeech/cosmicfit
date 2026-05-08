//
//  ColourMath.swift
//  Cosmic Fit
//
//  Shared HSL/hex colour-space utility. Extracted verbatim from
//  PaletteSwatchGenerator (see `docs/palette_grid_spec_v1.md` §7.3) so
//  both the engine's authoritative tone generator and the UI's display-only
//  grid tone expansion can share a single implementation.
//
//  Foundation-only; no UIKit. The engine layer has no view dependency.
//

import Foundation

enum ColourMath {

    /// Hex → (h, s, l). Returns `nil` for malformed input so the call site
    /// can decide on a fallback (the generator falls back to a neutral grey
    /// to preserve its pre-extraction behaviour; the grid view-model falls
    /// back to `#808080` and logs a warning).
    static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double)? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else {
            return nil
        }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        let l = (maxC + minC) / 2.0

        guard delta > 0 else {
            return (0, 0, l)
        }

        let s = l > 0.5
            ? delta / (2.0 - maxC - minC)
            : delta / (maxC + minC)

        var h: Double
        if maxC == r {
            h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxC == g {
            h = (b - r) / delta + 2
        } else {
            h = (r - g) / delta + 4
        }
        h = h / 6.0
        if h < 0 { h += 1.0 }

        return (h, s, l)
    }

    /// Hex → CIE Lab (D65). Returns `nil` for malformed input. Uses the
    /// standard sRGB → linear RGB → XYZ → Lab pipeline; the absolute values
    /// are IEC 61966-2-1 + CIE 15:2004 compliant to within double-precision
    /// rounding, which is well inside what the grid's greedy nearest-neighbour
    /// sort needs (we only compare relative ΔE distances).
    static func hexToLab(_ hex: String) -> (L: Double, a: Double, b: Double)? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else {
            return nil
        }

        // sRGB channels in [0, 1].
        let rSRGB = Double((rgb >> 16) & 0xFF) / 255.0
        let gSRGB = Double((rgb >> 8) & 0xFF) / 255.0
        let bSRGB = Double(rgb & 0xFF) / 255.0

        // sRGB → linear (IEC 61966-2-1).
        func linearize(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let r = linearize(rSRGB)
        let g = linearize(gSRGB)
        let b = linearize(bSRGB)

        // Linear sRGB (D65) → XYZ. Matrix from IEC 61966-2-1.
        let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
        let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
        let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

        // Normalise against D65 reference white.
        let xn = 0.95047
        let yn = 1.00000
        let zn = 1.08883

        func f(_ t: Double) -> Double {
            let epsilon = 216.0 / 24389.0          // (6/29)^3
            let kappa   = 24389.0 / 27.0           // (29/3)^3 — exact rational form
            return t > epsilon ? pow(t, 1.0 / 3.0) : (kappa * t + 16.0) / 116.0
        }

        let fx = f(x / xn)
        let fy = f(y / yn)
        let fz = f(z / zn)

        let L = 116.0 * fy - 16.0
        let a = 500.0 * (fx - fy)
        let bLab = 200.0 * (fy - fz)

        return (L, a, bLab)
    }

    /// CIE Lab (D65) → hex (sRGB). Inverse of `hexToLab`. Out-of-gamut
    /// coordinates are gamut-clipped per-channel to `[0, 1]`; this can
    /// desaturate but never produces invalid hex output. Use for
    /// `chart-signature → swatch` projection; not intended as a round-trip
    /// of `hexToLab` for arbitrary Lab values.
    static func labToHex(L: Double, a: Double, b: Double) -> String {
        // Lab → XYZ (D65). Uses the exact rational kappa/epsilon pair so
        // round-trips with `hexToLab` agree to the last bit.
        let fy = (L + 16.0) / 116.0
        let fx = a / 500.0 + fy
        let fz = fy - b / 200.0

        func finv(_ t: Double) -> Double {
            let epsilon = 6.0 / 29.0
            return t > epsilon
                ? t * t * t
                : 3.0 * epsilon * epsilon * (t - 4.0 / 29.0)
        }

        let xn = 0.95047
        let yn = 1.00000
        let zn = 1.08883

        let x = xn * finv(fx)
        let y = yn * finv(fy)
        let z = zn * finv(fz)

        // XYZ (D65) → linear sRGB.
        let rLin = x *  3.2404542 + y * -1.5371385 + z * -0.4985314
        let gLin = x * -0.9692660 + y *  1.8760108 + z *  0.0415560
        let bLin = x *  0.0556434 + y * -0.2040259 + z *  1.0572252

        // Linear → sRGB, with channel-wise gamut clip.
        func encode(_ c: Double) -> Int {
            let clipped = min(max(c, 0.0), 1.0)
            let srgb = clipped <= 0.0031308
                ? 12.92 * clipped
                : 1.055 * pow(clipped, 1.0 / 2.4) - 0.055
            return Int((srgb * 255.0).rounded())
        }

        return String(format: "#%02X%02X%02X", encode(rLin), encode(gLin), encode(bLin))
    }

    /// CIE LCH (cylindrical Lab) → hex. Hue is in degrees. Convenience
    /// wrapper around `labToHex` for code paths that want to reason about
    /// chroma + hue independently (e.g. envelope clamping for
    /// chart-signature swatches).
    static func lchToHex(L: Double, C: Double, h: Double) -> String {
        let rad = h * .pi / 180.0
        let a = C * cos(rad)
        let b = C * sin(rad)
        return labToHex(L: L, a: a, b: b)
    }

    /// Squared ΔE76 (Euclidean Lab distance) between two hexes. Returns
    /// `.infinity` when either side fails to parse so malformed entries sort
    /// to the end without polluting the greedy chain. Squared because we only
    /// use it for comparisons — skipping the `sqrt` is both faster and avoids
    /// a spurious float rounding step.
    static func labDistanceSquared(_ lhs: String, _ rhs: String) -> Double {
        guard let a = hexToLab(lhs), let b = hexToLab(rhs) else { return .infinity }
        let dL = a.L - b.L
        let da = a.a - b.a
        let db = a.b - b.b
        return dL * dL + da * da + db * db
    }

    static func hslToHex(h: Double, s: Double, l: Double) -> String {
        guard s > 0 else {
            let v = Int(round(l * 255))
            return String(format: "#%02X%02X%02X", v, v, v)
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q

        func hueToRGB(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1.0 / 6.0 { return p + (q - p) * 6 * t }
            if t < 1.0 / 2.0 { return q }
            if t < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - t) * 6 }
            return p
        }

        let r = Int(round(hueToRGB(p, q, h + 1.0 / 3.0) * 255))
        let g = Int(round(hueToRGB(p, q, h) * 255))
        let b = Int(round(hueToRGB(p, q, h - 1.0 / 3.0) * 255))

        return String(format: "#%02X%02X%02X", min(r, 255), min(g, 255), min(b, 255))
    }
}
