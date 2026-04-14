//
//  PaletteSwatchGenerator.swift
//  Cosmic Fit
//
//  Deterministic tonal expansion of Blueprint anchor colours into grouped swatch families.
//  Core anchors get 3 tones (softened, true, deepened); accent anchors get 2 (softened, true).
//  All derived tones have deterministic names and hex values.
//  Only anchor names are used in narrative placeholders — derived tones are display-only.
//

import Foundation

struct PaletteSwatchGenerator {

    /// Generates grouped swatch families from resolved anchor colours.
    /// - Core anchors → 3-tone family (softened, true anchor, deepened)
    /// - Accent anchors → 2-tone family (softened, true anchor)
    static func generateFamilies(
        core: [BlueprintColour],
        accent: [BlueprintColour]
    ) -> [SwatchFamily] {
        var families: [SwatchFamily] = []

        for colour in core {
            let tones = generateCoreTones(name: colour.name, hex: colour.hexValue)
            families.append(SwatchFamily(
                anchorName: colour.name,
                anchorHex: colour.hexValue,
                role: .core,
                tones: tones
            ))
        }

        for colour in accent {
            let tones = generateAccentTones(name: colour.name, hex: colour.hexValue)
            families.append(SwatchFamily(
                anchorName: colour.name,
                anchorHex: colour.hexValue,
                role: .accent,
                tones: tones
            ))
        }

        return families
    }

    // MARK: - Tone Generation

    private static func generateCoreTones(name: String, hex: String) -> [SwatchTone] {
        let (h, s, l) = hexToHSL(hex)
        return [
            SwatchTone(
                name: "soft \(name)",
                hex: hslToHex(h: h, s: max(s - 0.12, 0.0), l: min(l + 0.18, 0.95))
            ),
            SwatchTone(
                name: name,
                hex: hex
            ),
            SwatchTone(
                name: "deep \(name)",
                hex: hslToHex(h: h, s: min(s + 0.08, 1.0), l: max(l - 0.15, 0.05))
            ),
        ]
    }

    private static func generateAccentTones(name: String, hex: String) -> [SwatchTone] {
        let (h, s, l) = hexToHSL(hex)
        return [
            SwatchTone(
                name: "soft \(name)",
                hex: hslToHex(h: h, s: max(s - 0.15, 0.0), l: min(l + 0.20, 0.95))
            ),
            SwatchTone(
                name: name,
                hex: hex
            ),
        ]
    }

    // MARK: - Colour Space Conversions

    private static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt32(cleaned, radix: 16) else {
            return (0, 0, 0.5)
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

    private static func hslToHex(h: Double, s: Double, l: Double) -> String {
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
