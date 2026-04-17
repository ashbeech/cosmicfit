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

    /// Display-side tone offsets for grid expansion. Lightest → darkest.
    /// See §4.1 of the palette grid spec. These are UI-only; they do NOT
    /// mutate `SwatchFamily.tones`, which remains the engine's authoritative
    /// per-family tonal set.
    static let tonalOffsets: [Double] = [+0.30, +0.15, 0.0, -0.15, -0.30]

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
