import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - ColourMath tests

struct ColourMathTests {

    @Test("hexToHSL returns nil for malformed hex")
    func hexToHSLRejectsBadHex() {
        #expect(ColourMath.hexToHSL("") == nil)
        #expect(ColourMath.hexToHSL("abc") == nil)
        #expect(ColourMath.hexToHSL("#ZZZZZZ") == nil)
        #expect(ColourMath.hexToHSL("#12345") == nil)
        #expect(ColourMath.hexToHSL("#1234567") == nil)
    }

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
        accent: [BlueprintColour] = fullAccent,
        support: [BlueprintColour]? = fullSupport
    ) -> PaletteSection {
        PaletteSection(
            neutrals: neutrals, coreColours: core, accentColours: accent,
            supportColours: support,
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
        colour("sage",     "#7AA18C", role: .core),
        colour("caramel",  "#B08254", role: .core),
        colour("slate",    "#4B5A6E", role: .core),
        colour("warm tan", "#D4C4A0", role: .core),
    ]

    private static let fullAccent: [BlueprintColour] = [
        colour("saffron",  "#D4A23C", role: .accent),
        colour("rose",     "#C97D7D", role: .accent),
        colour("teal",     "#3C7A85", role: .accent),
        colour("midnight", "#1F2A44", role: .accent),
    ]

    private static let fullSupport: [BlueprintColour] = [
        colour("ink navy",       "#1B2A4A", role: .support),
        colour("cool charcoal",  "#3B3F42", role: .support),
        colour("slate",          "#5B6770", role: .support),
        colour("midnight olive", "#2F3A2B", role: .support),
    ]

    // MARK: - Helpers for new two-section structure

    private static func allCells(from grid: PaletteGrid) -> [PaletteCell] {
        grid.sections.flatMap(\.cells)
    }

    private static func mainSection(of grid: PaletteGrid) -> PaletteGrid.Section {
        grid.sections[0]
    }

    private static func accentSection(of grid: PaletteGrid) -> PaletteGrid.Section {
        grid.sections[1]
    }

    // MARK: - Shape

    @Test("Output has two sections with correct titles")
    func hasTwoSections() {
        let grid = PaletteGridViewModel.build(from: Self.v4Section())
        #expect(grid.sections.count == 2)
        #expect(grid.sections[0].title == "Core Palette")
        #expect(grid.sections[1].title == "Accent Colours")
    }

    @Test("Main section has 16 cells (4x4), accent section has 4 cells")
    func producesExpectedCellCounts() {
        let grid = PaletteGridViewModel.build(from: Self.v4Section())
        #expect(Self.mainSection(of: grid).cells.count == 16)
        #expect(Self.accentSection(of: grid).cells.count == 4)

        var mainFilled = 0
        for cell in Self.mainSection(of: grid).cells {
            if case .filled = cell.kind { mainFilled += 1 }
        }
        #expect(mainFilled == 12, "Expected 12 filled main cells (4 neutral + 4 core + 4 support, no anchors/signatures in fixture), got \(mainFilled)")

        var accentFilled = 0
        for cell in Self.accentSection(of: grid).cells {
            if case .filled = cell.kind { accentFilled += 1 }
        }
        #expect(accentFilled == 4, "Expected 4 filled accent cells, got \(accentFilled)")
    }

    @Test("Accent section preserves template order (not Lab-sorted)")
    func accentSectionPreservesTemplateOrder() {
        let grid = PaletteGridViewModel.build(from: Self.v4Section())
        let accentNames = Self.accentSection(of: grid).cells.compactMap { cell -> String? in
            guard case .filled(_, let name) = cell.kind else { return nil }
            return name
        }
        #expect(accentNames == ["saffron", "rose", "teal", "midnight"])
    }

    // MARK: - Greedy Lab chain (main section only)

    @Test("Main section chain seeds with the lightest (highest Lab L*) swatch")
    func chainSeedsWithLightestSwatch() {
        let section = Self.v4Section(
            neutrals: [
                Self.colour("deep-teal",  "#14444E", role: .neutral),
                Self.colour("mid-rust",   "#8A3B1F", role: .neutral),
                Self.colour("paper",      "#F8F2E3", role: .neutral),
                Self.colour("deep-brown", "#2B1B0F", role: .neutral),
            ],
            core: [
                Self.colour("mustard", "#C7A02B", role: .core),
                Self.colour("forest",  "#254D32", role: .core),
                Self.colour("coral",   "#D07556", role: .core),
                Self.colour("plum",    "#4A1F3A", role: .core),
            ],
            accent: [
                Self.colour("aubergine", "#2E1221", role: .accent),
                Self.colour("ochre",     "#B78328", role: .accent),
                Self.colour("teal",      "#2F6B6B", role: .accent),
                Self.colour("oxblood",   "#541517", role: .accent),
            ],
            support: [
                Self.colour("slate",   "#566270", role: .support),
                Self.colour("cocoa",   "#40261B", role: .support),
                Self.colour("saffron", "#D89A2E", role: .support),
                Self.colour("moss",    "#4E5A2D", role: .support),
            ]
        )

        let grid = PaletteGridViewModel.build(from: section)
        let mainCells = Self.mainSection(of: grid).cells
        guard case .filled(_, let firstName) = mainCells[0].kind else {
            Issue.record("First cell not filled")
            return
        }
        #expect(firstName == "paper",
                "Chain must seed with the lightest (Lab L*) swatch; got '\(firstName)'")
    }

    @Test("Main section chain is 2-opt locally optimal in Lab space")
    func chainIs2OptLocallyOptimal() {
        let section = Self.v4Section(
            neutrals: [
                Self.colour("cream",     "#F2E8D4", role: .neutral),
                Self.colour("camel",     "#C19A6B", role: .neutral),
                Self.colour("bark",      "#3D2C1F", role: .neutral),
                Self.colour("ink-brown", "#2B1E15", role: .neutral),
            ],
            core: [
                Self.colour("saffron",   "#D89A2E", role: .core),
                Self.colour("teal",      "#2F6B6B", role: .core),
                Self.colour("rust",      "#A0421F", role: .core),
                Self.colour("forest",    "#254D32", role: .core),
            ],
            accent: [
                Self.colour("mustard",   "#C7A02B", role: .accent),
                Self.colour("slate",     "#566270", role: .accent),
                Self.colour("oxblood",   "#541517", role: .accent),
                Self.colour("moss",      "#4E5A2D", role: .accent),
            ],
            support: [
                Self.colour("sand",      "#E1C69A", role: .support),
                Self.colour("plum",      "#4A1F3A", role: .support),
                Self.colour("paper",     "#F8F2E3", role: .support),
                Self.colour("charcoal",  "#333333", role: .support),
            ]
        )

        let grid = PaletteGridViewModel.build(from: section)
        let hexes: [String] = Self.mainSection(of: grid).cells.compactMap { cell in
            guard case .filled(let hex, _) = cell.kind else { return nil }
            return hex
        }
        #expect(hexes.count >= 4)

        func totalCost(_ path: [String]) -> Double {
            var sum = 0.0
            for k in 1..<path.count {
                sum += ColourMath.labDistanceSquared(path[k - 1], path[k])
            }
            return sum
        }

        let baseCost = totalCost(hexes)
        for i in 1..<(hexes.count - 1) {
            for j in (i + 1)..<hexes.count {
                var swapped = hexes
                swapped[i...j].reverse()
                let newCost = totalCost(swapped)
                #expect(newCost + 1e-9 >= baseCost,
                        "2-opt violation at (i=\(i), j=\(j)): reversing shortens chain from \(baseCost) to \(newCost)")
            }
        }
    }

    @Test("Determinism: repeated builds yield identical grids")
    func deterministicBuild() {
        let section = Self.v4Section()
        let first = PaletteGridViewModel.build(from: section)
        for run in 1..<10 {
            let repeated = PaletteGridViewModel.build(from: section)
            #expect(repeated == first, "Rebuild #\(run) diverged from first")
        }
    }

    @Test("Fewer than 16 main inputs pads trailing cells with .empty")
    func padsShortInputs() {
        let section = Self.v4Section(support: nil)
        let grid = PaletteGridViewModel.build(from: section)
        let mainCells = Self.mainSection(of: grid).cells

        #expect(mainCells.count == 16)

        var filledCount = 0
        for cell in mainCells {
            if case .filled = cell.kind { filledCount += 1 }
        }
        #expect(filledCount == 8, "Expected 8 filled (4 neutral + 4 core, no support/anchors), got \(filledCount)")

        for i in 8..<16 {
            if case .filled = mainCells[i].kind {
                Issue.record("Expected trailing cell \(i) to be .empty")
            }
        }
    }

    @Test("Similar hues land adjacent in main section: petrol / teal / forest-green together")
    func similarHuesAdjacent() {
        let petrol = Self.colour("petrol", "#1B3A4B", role: .neutral)
        let teal   = Self.colour("teal",   "#3C7A85", role: .core)
        let forest = Self.colour("forest", "#254D32", role: .core)

        let others: [BlueprintColour] = [
            Self.colour("red-1",    "#C0392B", role: .neutral),
            Self.colour("red-2",    "#B22222", role: .neutral),
            Self.colour("red-3",    "#E74C3C", role: .neutral),
            Self.colour("orange-1", "#E67E22", role: .core),
            Self.colour("orange-2", "#D35400", role: .core),
            Self.colour("yellow-1", "#F1C40F", role: .support),
            Self.colour("yellow-2", "#E8D93A", role: .support),
            Self.colour("purple-1", "#8E44AD", role: .support),
            Self.colour("purple-2", "#6A1B9A", role: .support),
        ]

        let neutrals = [petrol] + others.filter { $0.role == .neutral }
        let core = [teal, forest] + others.filter { $0.role == .core }
        let support = others.filter { $0.role == .support }

        let section = Self.v4Section(
            neutrals: neutrals,
            core: core,
            accent: Self.fullAccent,
            support: support
        )
        let grid = PaletteGridViewModel.build(from: section)
        let mainCells = Self.mainSection(of: grid).cells

        let targetNames: Set<String> = ["petrol", "teal", "forest"]
        let indices = mainCells.enumerated().compactMap { pair -> Int? in
            guard case .filled(_, let name) = pair.element.kind,
                  targetNames.contains(name) else { return nil }
            return pair.offset
        }
        #expect(indices.count == 3, "Expected 3 target cells, got \(indices.count)")
        if indices.count == 3 {
            let sorted = indices.sorted()
            #expect(sorted[2] - sorted[0] == 2,
                    "petrol/teal/forest should be contiguous; got indices \(sorted)")
        }
    }

    // MARK: - Malformed hex

    @Test("Malformed hex anchor: produces a filled cell backed by the fallback sentinel")
    func malformedHexFallsBackToSentinel() {
        let badCore: [BlueprintColour] = [
            Self.colour("glitch",  "not-a-hex", role: .core),
            Self.fullCore[1],
            Self.fullCore[2],
            Self.fullCore[3],
        ]
        let grid = PaletteGridViewModel.build(from: Self.v4Section(core: badCore))
        let mainCells = Self.mainSection(of: grid).cells

        #expect(mainCells.count == 16)

        var filledCount = 0
        var fallbackCount = 0
        for cell in mainCells {
            guard case .filled(let hex, let name) = cell.kind else { continue }
            filledCount += 1
            if hex.caseInsensitiveCompare(PaletteGridViewModel.malformedHexFallback) == .orderedSame,
               name == "glitch" {
                fallbackCount += 1
            }
        }
        #expect(filledCount == 12, "Malformed anchor should still produce a filled cell (12 from neutral+core+support)")
        #expect(fallbackCount == 1, "Exactly one fallback-hex cell expected, got \(fallbackCount)")
    }

    // MARK: - Helpers

    private static func nameOf(_ cell: PaletteCell) -> String {
        if case .filled(_, let name) = cell.kind { return name }
        return ""
    }
}

// MARK: - §5 Golden fixture snapshots

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

enum GoldenSnapshotSupport {

    static var shouldRegenerate: Bool {
        ProcessInfo.processInfo.environment["REGENERATE_PALETTE_GRID_GOLDENS"] == "1"
    }

    static func fixturesURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
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

    static func canonicalJSON(for grid: PaletteGrid) throws -> Data {
        let snapshot = PaletteGridSnapshot(from: grid)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    // MARK: - Codable mirror

    fileprivate struct PaletteGridSnapshot: Codable, Equatable {
        let sections: [SectionSnapshot]

        init(from grid: PaletteGrid) {
            self.sections = grid.sections.map(SectionSnapshot.init(from:))
        }
    }

    fileprivate struct SectionSnapshot: Codable, Equatable {
        let title: String
        let columnCount: Int
        let cells: [PaletteCellSnapshot]

        init(from section: PaletteGrid.Section) {
            self.title = section.title
            self.columnCount = section.columnCount
            self.cells = section.cells.map(PaletteCellSnapshot.init(from:))
        }
    }

    fileprivate struct PaletteCellSnapshot: Codable, Equatable {
        let hex: String?
        let anchorName: String?

        init(from cell: PaletteCell) {
            switch cell.kind {
            case .filled(let hex, let name):
                self.hex = hex
                self.anchorName = name
            case .empty:
                self.hex = nil
                self.anchorName = nil
            }
        }
    }
}

// MARK: - P5 Live-wiring integration tests

@Suite(.serialized)
struct PaletteLiveWiringTests {

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
        #expect(grid.sections.count == 2)

        let mainFilled = grid.sections[0].cells.reduce(into: 0) { acc, cell in
            if case .filled = cell.kind { acc += 1 }
        }
        let accentFilled = grid.sections[1].cells.reduce(into: 0) { acc, cell in
            if case .filled = cell.kind { acc += 1 }
        }
        #expect(mainFilled == 16,
                "Placeholder main section should have 16 filled cells (4 neutral + 4 core + 4 support + 2 anchors + 2 signatures), got \(mainFilled)")
        #expect(accentFilled == 4,
                "Placeholder accent section should have 4 filled cells, got \(accentFilled)")

        let second = ColourPaletteView.placeholder()
        #expect(grid == second, "Placeholder must be deterministic across calls")
    }

    @Test("Fixture palette sections meet legacy contract (3-4 core, 2+ accent)",
          arguments: ["blueprint_input_user_1.json", "blueprint_input_user_2.json"])
    func fixturePaletteContract(filename: String) throws {
        let blueprint = try GoldenSnapshotSupport.loadBlueprint(filename)
        let section = blueprint.palette
        #expect((3...4).contains(section.coreColours.count),
                "Core count \(section.coreColours.count) outside [3,4] for \(filename)")
        #expect(section.accentColours.count >= 2,
                "Accent count \(section.accentColours.count) < 2 for \(filename)")
    }

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
