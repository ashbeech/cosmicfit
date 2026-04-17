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
//   • Byte-identity snapshot against golden JSON for fixture users 1 and 2
//     (§11.3). Set REGENERATE_PALETTE_GRID_GOLDENS=1 to rewrite the
//     goldens from the current output — leave unset for strict compare.
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

// MARK: - §11.3 Golden fixture snapshots
//
// Asserts byte-identical `PaletteGrid` output for the two fixture users
// against a committed golden JSON file. Any unintended change to
// `PaletteGridViewModel.build` or `ColourMath` tone expansion will
// trip these tests; intentional changes require regenerating the
// goldens by re-running with `REGENERATE_PALETTE_GRID_GOLDENS=1`
// in the environment, then committing the updated files.

struct PaletteGridGoldenSnapshotTests {

    @Test("Golden snapshot matches for fixture user 1 (Ash)")
    func goldenSnapshotUser1() throws {
        try assertGoldenMatches(fixture: "blueprint_input_user_1.json",
                                golden:  "palette_grid_golden_user_1.json")
    }

    @Test("Golden snapshot matches for fixture user 2 (Maria)")
    func goldenSnapshotUser2() throws {
        try assertGoldenMatches(fixture: "blueprint_input_user_2.json",
                                golden:  "palette_grid_golden_user_2.json")
    }

    // MARK: - Private

    private func assertGoldenMatches(fixture: String, golden: String) throws {
        let blueprint = try GoldenSnapshotSupport.loadBlueprint(fixture)
        let grid = PaletteGridViewModel.build(from: blueprint.palette)
        let current = try GoldenSnapshotSupport.canonicalJSON(for: grid)

        let goldenURL = GoldenSnapshotSupport.fixturesURL().appendingPathComponent(golden)

        if GoldenSnapshotSupport.shouldRegenerate {
            try current.write(to: goldenURL, options: [.atomic])
            Issue.record("Regenerated golden at \(goldenURL.path). Commit the new file and re-run with REGENERATE_PALETTE_GRID_GOLDENS unset to enforce.")
            return
        }

        let expected: Data
        do {
            expected = try Data(contentsOf: goldenURL)
        } catch {
            Issue.record("Missing golden at \(goldenURL.path). Run tests once with REGENERATE_PALETTE_GRID_GOLDENS=1 to create it, then commit.")
            return
        }

        if current != expected {
            // Write the current output beside the golden with a `.actual`
            // suffix so CI artifacts can be diffed. The file is not part
            // of the commit set; it is purely a debugging aid.
            let actualURL = goldenURL.appendingPathExtension("actual")
            try? current.write(to: actualURL, options: [.atomic])

            let currentString = String(data: current, encoding: .utf8) ?? "<non-utf8>"
            let expectedString = String(data: expected, encoding: .utf8) ?? "<non-utf8>"
            Issue.record("""
                Golden mismatch for \(golden).
                  Expected bytes: \(expected.count), actual bytes: \(current.count).
                  See \(actualURL.lastPathComponent) for the full current output.
                  First 400 chars of current:
                \(String(currentString.prefix(400)))
                  First 400 chars of expected:
                \(String(expectedString.prefix(400)))
                """)
        }
    }
}

// MARK: - Snapshot support (test-only)
//
// Canonical JSON encoder for `PaletteGrid`. Kept private to the test
// target so the production `PaletteGrid` stays minimal (Foundation-only,
// no Codable surface) while still letting us diff byte-for-byte.

enum GoldenSnapshotSupport {

    static var shouldRegenerate: Bool {
        ProcessInfo.processInfo.environment["REGENERATE_PALETTE_GRID_GOLDENS"] == "1"
    }

    static func fixturesURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()    // Cosmic FitTests/
            .deletingLastPathComponent()    // repo root
            .appendingPathComponent("docs")
            .appendingPathComponent("fixtures")
    }

    static func loadBlueprint(_ filename: String) throws -> CosmicBlueprint {
        let url = fixturesURL().appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CosmicBlueprint.self, from: data)
    }

    /// Produce a canonical JSON representation of a `PaletteGrid`. Keys
    /// are sorted and output is pretty-printed so the committed golden
    /// is human-diffable. The encoding is stable across machines and
    /// Xcode versions — `JSONEncoder.OutputFormatting.sortedKeys` +
    /// `prettyPrinted` is documented to produce deterministic byte
    /// output for a given input.
    static func canonicalJSON(for grid: PaletteGrid) throws -> Data {
        let snapshot = PaletteGridSnapshot(from: grid)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    // MARK: - Codable mirror

    fileprivate struct PaletteGridSnapshot: Codable, Equatable {
        let rows: [PaletteRowSnapshot]

        init(from grid: PaletteGrid) {
            self.rows = grid.rows.map(PaletteRowSnapshot.init(from:))
        }
    }

    fileprivate struct PaletteRowSnapshot: Codable, Equatable {
        let role: String
        let anchorName: String?
        let anchorHex: String?
        let cells: [PaletteCellSnapshot]

        init(from row: PaletteRow) {
            self.role = row.role.rawValue
            self.anchorName = row.anchorName
            self.anchorHex = row.anchorHex
            self.cells = row.cells.map(PaletteCellSnapshot.init(from:))
        }
    }

    /// Uses `hex: String?` (null for empty cells) as the stable on-disk
    /// shape. Preferred over a discriminated-union because it stays
    /// trivially diff-readable in PR review.
    fileprivate struct PaletteCellSnapshot: Codable, Equatable {
        let toneIndex: Int
        let hex: String?

        init(from cell: PaletteCell) {
            self.toneIndex = cell.toneIndex
            switch cell.kind {
            case .filled(let hex): self.hex = hex
            case .empty:           self.hex = nil
            }
        }
    }
}
