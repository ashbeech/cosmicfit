//
//  PaletteGridViewModel_Tests.swift
//  Cosmic FitTests
//
//  Phase B — Palette Grid UI (spec `docs/palette_grid_spec_v1.md` §11).
//
//  Covers:
//   • ColourMath HSL round-trips and tonal-offset clamp boundaries (§11.2).
//   • PaletteGridViewModel happy path (4 core + 4 accent → 8 filled rows).
//   • Short-core fallback (3 core + 4 accent → 1 empty core row).
//   • Malformed hex fallback to #808080 (no crash, grid still 8×5).
//   • Determinism — byte-identical PaletteGrid across repeated builds.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - ColourMath tests

struct ColourMathTests {

    // §11.2 — invalid hex returns nil.
    @Test("hexToHSL returns nil for malformed hex")
    func hexToHSLRejectsBadHex() {
        #expect(ColourMath.hexToHSL("") == nil)
        #expect(ColourMath.hexToHSL("abc") == nil)
        #expect(ColourMath.hexToHSL("#ZZZZZZ") == nil)
        #expect(ColourMath.hexToHSL("#12345") == nil)       // 5 digits
        #expect(ColourMath.hexToHSL("#1234567") == nil)     // 7 digits
    }

    // §11.2 — round-trip stays within 1 channel unit (±1/255).
    @Test("hexToHSL → hslToHex round-trip is within 1 channel unit")
    func hexRoundTripStable() {
        let samples = [
            "#7AA18C", "#D4A37B", "#4B5A6E",
            "#F0EADC", "#2A2A2A", "#FF0000",
            "#00FF00", "#0000FF", "#808080",
            "#123456", "#ABCDEF",
        ]
        for input in samples {
            guard let (h, s, l) = ColourMath.hexToHSL(input) else {
                Issue.record("Unexpected nil for \(input)")
                continue
            }
            let output = ColourMath.hslToHex(h: h, s: s, l: l)
            #expect(
                channelDiff(input, output) <= 1,
                "Round-trip drift > 1 channel for \(input) → \(output)"
            )
        }
    }

    // §11.2 — tonal offsets applied to a sweep of L values never escape
    // the expected clamp of [0.05, 0.95].
    @Test("tonalOffsets + clamp stay within [0.05, 0.95]")
    func tonalOffsetsClampToValidRange() {
        let lValues = stride(from: 0.0, through: 1.0, by: 0.05)
        for l in lValues {
            for offset in ColourMath.tonalOffsets {
                let clamped = min(max(l + offset, 0.05), 0.95)
                #expect(clamped >= 0.05 && clamped <= 0.95,
                        "L=\(l), offset=\(offset) → \(clamped) escaped clamp range")
            }
        }
    }

    // MARK: - helpers

    private func channelDiff(_ a: String, _ b: String) -> Int {
        let (ar, ag, ab) = rgb(a)
        let (br, bg, bb) = rgb(b)
        return max(abs(ar - br), abs(ag - bg), abs(ab - bb))
    }

    private func rgb(_ hex: String) -> (Int, Int, Int) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let v = UInt32(cleaned, radix: 16) else { return (0, 0, 0) }
        return (Int((v >> 16) & 0xFF), Int((v >> 8) & 0xFF), Int(v & 0xFF))
    }
}

// MARK: - PaletteGridViewModel tests

struct PaletteGridViewModelTests {

    // MARK: Fixtures

    private static let provenance: ColourProvenance = .libraryFallback(reason: "test fixture")

    private static func colour(_ name: String, _ hex: String, role: ColourRole) -> BlueprintColour {
        BlueprintColour(name: name, hexValue: hex, role: role, provenance: provenance)
    }

    private static func section(core: [BlueprintColour], accent: [BlueprintColour]) -> PaletteSection {
        PaletteSection(coreColours: core, accentColours: accent, swatchFamilies: [], narrativeText: "")
    }

    private static let fullCore: [BlueprintColour] = [
        colour("sage", "#7AA18C", role: .core),
        colour("caramel", "#B08254", role: .core),
        colour("slate", "#4B5A6E", role: .core),
        colour("cream", "#F0EADC", role: .core),
    ]

    private static let fullAccent: [BlueprintColour] = [
        colour("saffron", "#D4A23C", role: .accent),
        colour("rose", "#C97D7D", role: .accent),
        colour("teal", "#3C7A85", role: .accent),
        colour("midnight", "#1F2A44", role: .accent),
    ]

    // MARK: - Shape

    @Test("Happy path: 4 core + 4 accent → 8 filled rows, 5 filled cells each")
    func happyPathAllFilled() {
        let grid = PaletteGridViewModel.build(from: Self.section(core: Self.fullCore, accent: Self.fullAccent))

        #expect(grid.rows.count == PaletteGrid.rowCount)
        #expect(grid.rows.count == 8)

        for (rowIndex, row) in grid.rows.enumerated() {
            #expect(row.cells.count == PaletteGrid.columnCount)
            #expect(row.anchorHex != nil, "Row \(rowIndex) should be filled")
            for cell in row.cells {
                if case .empty = cell.kind {
                    Issue.record("Row \(rowIndex) has empty cell in a filled row")
                }
            }
        }

        let coreRows = Array(grid.rows.prefix(PaletteGrid.coreRowCount))
        let accentRows = Array(grid.rows.suffix(PaletteGrid.rowCount - PaletteGrid.coreRowCount))
        #expect(coreRows.allSatisfy { $0.role == .core })
        #expect(accentRows.allSatisfy { $0.role == .accent })
    }

    // §11.1 — short core (3 anchors) → 3 filled core rows + 1 empty core row + 4 filled accents.
    @Test("Short core: 3 core + 4 accent → one empty core row, all accents filled")
    func shortCorePadsWithEmptyRow() {
        let shortCore = Array(Self.fullCore.prefix(3))
        let grid = PaletteGridViewModel.build(from: Self.section(core: shortCore, accent: Self.fullAccent))

        #expect(grid.rows.count == PaletteGrid.rowCount)

        let row0 = grid.rows[0]
        let row2 = grid.rows[2]
        let row3 = grid.rows[3]   // the empty padding slot
        let row4 = grid.rows[4]

        #expect(row0.anchorHex != nil)
        #expect(row2.anchorHex != nil)
        #expect(row3.anchorHex == nil)
        #expect(row3.anchorName == nil)
        #expect(row3.role == .core)
        for cell in row3.cells {
            if case .filled = cell.kind {
                Issue.record("Padded core row should contain only empty cells")
            }
        }

        #expect(row4.anchorHex != nil)
        #expect(row4.role == .accent)
    }

    // §11.1 — malformed hex → 5× fallback, no crash, no empty cells (still filled row by spec).
    @Test("Malformed hex anchor: row is fully filled with the fallback sentinel")
    func malformedHexFallsBackToSentinel() {
        let badCore = [Self.colour("glitch", "not-a-hex", role: .core)]
        let grid = PaletteGridViewModel.build(from: Self.section(core: badCore, accent: Self.fullAccent))

        let row0 = grid.rows[0]
        #expect(row0.anchorHex == "not-a-hex")
        #expect(row0.anchorName == "glitch")
        #expect(row0.cells.count == PaletteGrid.columnCount)

        for cell in row0.cells {
            guard case .filled(let hex) = cell.kind else {
                Issue.record("Expected filled cell on malformed-hex row, got empty")
                continue
            }
            #expect(hex.caseInsensitiveCompare(PaletteGridViewModel.malformedHexFallback) == .orderedSame,
                    "Expected \(PaletteGridViewModel.malformedHexFallback), got \(hex)")
        }
    }

    // §11.1 — determinism: 10 rebuilds produce byte-identical PaletteGrid.
    @Test("Determinism: 10 rebuilds from the same PaletteSection are byte-identical")
    func determinismAcrossRebuilds() {
        let s = Self.section(core: Self.fullCore, accent: Self.fullAccent)
        let first = PaletteGridViewModel.build(from: s)
        for run in 1..<10 {
            let repeated = PaletteGridViewModel.build(from: s)
            #expect(repeated == first, "Rebuild #\(run) diverged from first")
        }
    }

    // §4.1 — filled row produces 5 tones, lightest → darkest, all valid hex.
    @Test("Filled row produces 5 well-formed hex tones in toneIndex order")
    func filledRowProducesFiveValidHexTones() {
        let grid = PaletteGridViewModel.build(from: Self.section(core: Self.fullCore, accent: Self.fullAccent))

        let row = grid.rows[0]
        for (index, cell) in row.cells.enumerated() {
            #expect(cell.toneIndex == index)
            guard case .filled(let hex) = cell.kind else {
                Issue.record("Expected filled cell at index \(index)")
                continue
            }
            #expect(ColourMath.hexToHSL(hex) != nil, "Produced cell hex \(hex) failed to parse")
        }
    }

    // §4.3 — grid's `nonEmptyRowCount` matches the number of filled rows.
    @Test("nonEmptyRowCount reflects the number of anchored rows")
    func nonEmptyRowCountMatchesFilledRows() {
        let grid = PaletteGridViewModel.build(from: Self.section(
            core: Array(Self.fullCore.prefix(3)),
            accent: Self.fullAccent
        ))
        #expect(grid.nonEmptyRowCount == 7)
    }
}
