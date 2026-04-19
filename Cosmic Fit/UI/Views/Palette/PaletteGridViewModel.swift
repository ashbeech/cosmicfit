//
//  PaletteGridViewModel.swift
//  Cosmic Fit
//
//  Pure-function transform `PaletteSection` → `PaletteGrid`. Foundation-only,
//  deterministic, unit-testable.
//
//  V4 layout: 4 neutral rows + 4 core rows + 4 accent rows = 12 rows × 5 tones.
//  The only expansion this layer performs is the display-side 1→5 tonal expansion
//  per row via `ColourMath.tonalOffsets`.
//

import Foundation

enum PaletteGridViewModel {

    /// Build the 5×12 grid from a `PaletteSection`. Always returns exactly
    /// `PaletteGrid.rowCount` rows × `PaletteGrid.columnCount` cells.
    /// Deterministic — same input produces byte-identical output.
    static func build(from section: PaletteSection) -> PaletteGrid {
        var rows: [PaletteRow] = []
        rows.reserveCapacity(PaletteGrid.rowCount)

        let neutrals = section.neutrals ?? []
        for i in 0..<PaletteGrid.neutralRowCount {
            if i < neutrals.count {
                rows.append(buildFilledRow(anchor: neutrals[i], role: .neutral))
            } else {
                rows.append(buildEmptyRow(role: .neutral))
            }
        }

        for i in 0..<PaletteGrid.coreRowCount {
            if i < section.coreColours.count {
                rows.append(buildFilledRow(anchor: section.coreColours[i], role: .core))
            } else {
                rows.append(buildEmptyRow(role: .core))
            }
        }

        for i in 0..<PaletteGrid.accentRowCount {
            if i < section.accentColours.count {
                rows.append(buildFilledRow(anchor: section.accentColours[i], role: .accent))
            } else {
                rows.append(buildEmptyRow(role: .accent))
            }
        }

        return PaletteGrid(rows: rows)
    }

    // MARK: - Row builders

    private static func buildFilledRow(anchor: BlueprintColour, role: ColourRole) -> PaletteRow {
        let hexes = expandToFiveTones(anchorHex: anchor.hexValue)
        let cells = hexes.enumerated().map { index, hex in
            PaletteCell(kind: .filled(hex: hex), toneIndex: index)
        }
        return PaletteRow(
            role: role,
            anchorName: anchor.name,
            anchorHex: anchor.hexValue,
            cells: cells
        )
    }

    private static func buildEmptyRow(role: ColourRole) -> PaletteRow {
        let cells = (0..<PaletteGrid.columnCount).map {
            PaletteCell(kind: .empty, toneIndex: $0)
        }
        return PaletteRow(role: role, anchorName: nil, anchorHex: nil, cells: cells)
    }

    // MARK: - Tone expansion

    /// Sentinel hex used when the anchor's hex cannot be parsed. Matches the
    /// spec's §7.2 fallback requirement. Surface via a constant so tests can
    /// assert against it without hard-coding the literal in two places.
    static let malformedHexFallback: String = "#808080"

    private static let lightnessClamp: ClosedRange<Double> = 0.05...0.95
    private static let saturationDelta: Double = 0.08

    /// Expand an anchor hex to 5 display tones (lightest → darkest) using
    /// `ColourMath.tonalOffsets`. Malformed hex → 5× `malformedHexFallback`
    /// with one warning logged (never throws, never crashes).
    private static func expandToFiveTones(anchorHex: String) -> [String] {
        guard let (h, s, l) = ColourMath.hexToHSL(anchorHex) else {
            print("[PaletteGridViewModel] Warning: invalid hex '\(anchorHex)', falling back to \(malformedHexFallback)")
            return Array(repeating: malformedHexFallback, count: PaletteGrid.columnCount)
        }

        return ColourMath.tonalOffsets.map { offset in
            let newL = clamp(l + offset, to: lightnessClamp)
            let newS = clamp(s, to: (s - saturationDelta)...(s + saturationDelta))
            let clampedS = clamp(newS, to: 0.0...1.0)
            return ColourMath.hslToHex(h: h, s: clampedS, l: newL)
        }
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
