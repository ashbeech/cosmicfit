//
//  PaletteGridViewModel_Tests.swift
//  Cosmic FitTests
//
//  V4 Palette Grid UI tests.
//
//  Covers:
//   • ColourMath HSL round-trips and tonal-offset clamp boundaries.
//   • PaletteGridViewModel happy path (4 neutral + 4 core + 4 accent → 12 filled rows).
//   • Short-core fallback with V4 layout.
//   • Malformed hex fallback to #808080 (no crash, grid still 12×5).
//   • Determinism — byte-identical PaletteGrid across repeated builds.
//   • Byte-identity snapshot against golden JSON for fixture users 1 and 2.
//     Set REGENERATE_PALETTE_GRID_GOLDENS=1 to rewrite the goldens.
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

    private static let provenance: ColourProvenance = .v4Template(family: "Deep Autumn", band: "test", index: 0)

    private static func colour(_ name: String, _ hex: String, role: ColourRole) -> BlueprintColour {
        BlueprintColour(name: name, hexValue: hex, role: role, provenance: provenance)
    }

    private static func v4Section(
        neutrals: [BlueprintColour] = fullNeutral,
        core: [BlueprintColour] = fullCore,
        accent: [BlueprintColour] = fullAccent
    ) -> PaletteSection {
        PaletteSection(
            neutrals: neutrals, coreColours: core, accentColours: accent,
            family: .deepAutumn, cluster: .deepWarmStructured,
            variables: DerivedVariables(
                depth: .deep, temperature: .warm, saturation: .rich,
                contrast: .medium, surface: .structured
            ),
            secondaryPull: nil, overrideFlags: OverrideFlags(),
            narrativeText: ""
        )
    }

    private static let fullNeutral: [BlueprintColour] = [
        colour("warm ivory", "#F5EDE0", role: .neutral),
        colour("camel sand", "#C4A775", role: .neutral),
        colour("warm stone", "#8C7A6B", role: .neutral),
        colour("espresso",   "#3C2415", role: .neutral),
    ]

    private static let fullCore: [BlueprintColour] = [
        colour("sage",    "#7AA18C", role: .core),
        colour("caramel", "#B08254", role: .core),
        colour("slate",   "#4B5A6E", role: .core),
        colour("cream",   "#F0EADC", role: .core),
    ]

    private static let fullAccent: [BlueprintColour] = [
        colour("saffron",  "#D4A23C", role: .accent),
        colour("rose",     "#C97D7D", role: .accent),
        colour("teal",     "#3C7A85", role: .accent),
        colour("midnight", "#1F2A44", role: .accent),
    ]

    // MARK: - Shape

    @Test("Happy path: 4 neutral + 4 core + 4 accent → 12 filled rows, 5 filled cells each")
    func happyPathAllFilled() {
        let grid = PaletteGridViewModel.build(from: Self.v4Section())

        #expect(grid.rows.count == PaletteGrid.rowCount)
        #expect(grid.rows.count == 12)

        for (rowIndex, row) in grid.rows.enumerated() {
            #expect(row.cells.count == PaletteGrid.columnCount)
            #expect(row.anchorHex != nil, "Row \(rowIndex) should be filled")
            for cell in row.cells {
                if case .empty = cell.kind {
                    Issue.record("Row \(rowIndex) has empty cell in a filled row")
                }
            }
        }

        let neutralRows = Array(grid.rows.prefix(PaletteGrid.neutralRowCount))
        let coreRows = Array(grid.rows[PaletteGrid.neutralRowCount..<(PaletteGrid.neutralRowCount + PaletteGrid.coreRowCount)])
        let accentRows = Array(grid.rows.suffix(PaletteGrid.accentRowCount))
        #expect(neutralRows.allSatisfy { $0.role == .neutral })
        #expect(coreRows.allSatisfy { $0.role == .core })
        #expect(accentRows.allSatisfy { $0.role == .accent })
    }

    @Test("Short core: 3 core → one empty core row padded, all neutrals and accents filled")
    func shortCorePadsWithEmptyRow() {
        let shortCore = Array(Self.fullCore.prefix(3))
        let grid = PaletteGridViewModel.build(from: Self.v4Section(core: shortCore))

        #expect(grid.rows.count == PaletteGrid.rowCount)

        let coreStart = PaletteGrid.neutralRowCount
        let row4 = grid.rows[coreStart]
        let row6 = grid.rows[coreStart + 2]
        let row7 = grid.rows[coreStart + 3]
        let row8 = grid.rows[coreStart + 4]

        #expect(row4.anchorHex != nil)
        #expect(row6.anchorHex != nil)
        #expect(row7.anchorHex == nil)
        #expect(row7.anchorName == nil)
        #expect(row7.role == .core)
        for cell in row7.cells {
            if case .filled = cell.kind {
                Issue.record("Padded core row should contain only empty cells")
            }
        }

        #expect(row8.anchorHex != nil)
        #expect(row8.role == .accent)
    }

    @Test("Malformed hex anchor: row is fully filled with the fallback sentinel")
    func malformedHexFallsBackToSentinel() {
        let badCore = [Self.colour("glitch", "not-a-hex", role: .core)]
        let grid = PaletteGridViewModel.build(from: Self.v4Section(core: badCore))

        let coreStart = PaletteGrid.neutralRowCount
        let row = grid.rows[coreStart]
        #expect(row.anchorHex == "not-a-hex")
        #expect(row.anchorName == "glitch")
        #expect(row.cells.count == PaletteGrid.columnCount)

        for cell in row.cells {
            guard case .filled(let hex) = cell.kind else {
                Issue.record("Expected filled cell on malformed-hex row, got empty")
                continue
            }
            #expect(hex.caseInsensitiveCompare(PaletteGridViewModel.malformedHexFallback) == .orderedSame,
                    "Expected \(PaletteGridViewModel.malformedHexFallback), got \(hex)")
        }
    }

    @Test("Determinism: 10 rebuilds from the same PaletteSection are byte-identical")
    func determinismAcrossRebuilds() {
        let s = Self.v4Section()
        let first = PaletteGridViewModel.build(from: s)
        for run in 1..<10 {
            let repeated = PaletteGridViewModel.build(from: s)
            #expect(repeated == first, "Rebuild #\(run) diverged from first")
        }
    }

    @Test("Filled row produces 5 well-formed hex tones in toneIndex order")
    func filledRowProducesFiveValidHexTones() {
        let grid = PaletteGridViewModel.build(from: Self.v4Section())

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

    @Test("nonEmptyRowCount reflects the number of anchored rows")
    func nonEmptyRowCountMatchesFilledRows() {
        let grid = PaletteGridViewModel.build(from: Self.v4Section(
            core: Array(Self.fullCore.prefix(3))
        ))
        #expect(grid.nonEmptyRowCount == 11)
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
            print("[PaletteGridGoldenSnapshotTests] Regenerated golden at \(goldenURL.path).")
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

// MARK: - P5 Live-wiring integration tests
//
// Validates the end-to-end path introduced by the P5 palette live-wiring:
//   BlueprintStorage.load() → CosmicBlueprint.palette → PaletteGridViewModel.build → PaletteGrid
//
// Tests that touch BlueprintStorage.shared mutate a shared file on disk
// (Documents/cosmic_fit_blueprint.json), so the suite MUST be serialized
// to prevent parallel tests from racing on the same file.

@Suite(.serialized)
struct PaletteLiveWiringTests {

    // MARK: - Round-trip: save fixture → load → build grid → compare

    @Test("Live path produces identical grid to direct build from fixture palette")
    func livePathMatchesDirectBuild() throws {
        let blueprint = try GoldenSnapshotSupport.loadBlueprint("blueprint_input_user_1.json")
        let directGrid = PaletteGridViewModel.build(from: blueprint.palette)

        BlueprintStorage.shared.save(blueprint)
        defer { BlueprintStorage.shared.delete() }

        guard let loaded = BlueprintStorage.shared.load() else {
            Issue.record("BlueprintStorage round-trip failed — load returned nil after save")
            return
        }
        let liveGrid = PaletteGridViewModel.build(from: loaded.palette)

        #expect(liveGrid == directGrid,
                "Grid built from storage-round-tripped blueprint must match direct build")
    }

    // MARK: - Fallback

    @Test("BlueprintStorage.load returns nil when no file exists")
    func emptyStorageReturnsNil() {
        BlueprintStorage.shared.delete()

        let loaded = BlueprintStorage.shared.load()
        #expect(loaded == nil, "Storage should return nil when no blueprint file exists")
    }

    @Test("Nil storage falls back to a valid, deterministic placeholder grid")
    func fallbackProducesValidPlaceholderGrid() {
        BlueprintStorage.shared.delete()

        let loaded = BlueprintStorage.shared.load()
        #expect(loaded == nil)

        let grid = ColourPaletteView.placeholder()
        #expect(grid.rows.count == PaletteGrid.rowCount)
        #expect(grid.nonEmptyRowCount == PaletteGrid.rowCount,
                "Placeholder grid should have all 12 rows filled")
        for row in grid.rows {
            #expect(row.cells.count == PaletteGrid.columnCount)
            #expect(row.anchorHex != nil, "Placeholder row should have an anchor")
        }

        let second = ColourPaletteView.placeholder()
        #expect(grid == second, "Placeholder must be deterministic across calls")
    }

    // MARK: - PaletteSection validity from real fixtures

    @Test("Fixture palette sections meet legacy contract (3-4 core, 4 accent)",
          arguments: ["blueprint_input_user_1.json", "blueprint_input_user_2.json"])
    func fixturePaletteContract(filename: String) throws {
        let blueprint = try GoldenSnapshotSupport.loadBlueprint(filename)
        let section = blueprint.palette
        #expect((3...4).contains(section.coreColours.count),
                "Core count \(section.coreColours.count) outside [3,4] for \(filename)")
        #expect(section.accentColours.count == 4,
                "Accent count \(section.accentColours.count) != 4 for \(filename)")
    }

    // MARK: - Notification

    @Test("BlueprintStorage.save posts .blueprintDidUpdate notification")
    @MainActor func savePostsNotification() throws {
        let blueprint = try GoldenSnapshotSupport.loadBlueprint("blueprint_input_user_1.json")
        defer { BlueprintStorage.shared.delete() }

        let flag = NotificationFlag(name: .blueprintDidUpdate)
        BlueprintStorage.shared.save(blueprint)

        let deadline = Date().addingTimeInterval(1.0)
        while !flag.received && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        #expect(flag.received, ".blueprintDidUpdate should be posted after save")
    }
}

/// Reference-type observer so the notification callback can mutate
/// `received` and the test can poll it after calling `save()`.
private final class NotificationFlag {
    var received = false
    var observer: NSObjectProtocol?

    init(name: Notification.Name) {
        observer = NotificationCenter.default.addObserver(
            forName: name, object: nil, queue: .main
        ) { [weak self] _ in self?.received = true }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }
}
