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
        // Preserve pre-extraction behaviour: malformed hex falls back to
        // (0, 0, 0.5). `ColourMath.hexToHSL` returns nil for malformed input,
        // so the nil-coalescing here reproduces the old inline fallback exactly.
        let (h, s, l) = ColourMath.hexToHSL(hex) ?? (0, 0, 0.5)
        return [
            SwatchTone(
                name: "soft \(name)",
                hex: ColourMath.hslToHex(h: h, s: max(s - 0.12, 0.0), l: min(l + 0.18, 0.95))
            ),
            SwatchTone(
                name: name,
                hex: hex
            ),
            SwatchTone(
                name: "deep \(name)",
                hex: ColourMath.hslToHex(h: h, s: min(s + 0.08, 1.0), l: max(l - 0.15, 0.05))
            ),
        ]
    }

    private static func generateAccentTones(name: String, hex: String) -> [SwatchTone] {
        let (h, s, l) = ColourMath.hexToHSL(hex) ?? (0, 0, 0.5)
        return [
            SwatchTone(
                name: "soft \(name)",
                hex: ColourMath.hslToHex(h: h, s: max(s - 0.15, 0.0), l: min(l + 0.20, 0.95))
            ),
            SwatchTone(
                name: name,
                hex: hex
            ),
        ]
    }
}
