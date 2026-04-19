import XCTest
@testable import Cosmic_Fit

/// Hard-gate regression tests for the V4 engine, split into two independent gates:
///
/// 1. **Classification gate** — family, cluster, variables, secondary pull.
///    Permanent and frozen; never changes when variation rules evolve.
///
/// 2. **Palette gate** — neutrals, coreColours, accentColours.
///    Changes when variation substitution rules are updated.
///
/// Uses `evaluateStrict(input:)` only. Never uses tolerant/production mode.
final class V4CalibrationRegression_Tests: XCTestCase {

    // MARK: - Fixture Types

    struct V4DatasetRow: Codable {
        let id: String
        let birthData: String
        let location: String
        let expected: ExpectedOutput
    }

    struct ExpectedOutput: Codable {
        let family: String
        let secondaryPull: String?
        let depth: String
        let temperature: String
        let saturation: String
        let contrast: String
        let surface: String
        let cluster: String
        let neutrals: [String]
        let coreColours: [String]
        let accentColours: [String]
    }

    struct V4PlacementRow: Codable {
        let id: String
        let placements: BirthChartColourInput
    }

    struct RegressionMismatch {
        let id: String
        let field: String
        let expected: String
        let actual: String
    }

    // MARK: - Classification Gate (frozen)

    func testClassificationGate() throws {
        let dataset = try loadDataset()
        let placements = try loadPlacements()
        let placementLookup = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.placements) })

        var mismatches: [RegressionMismatch] = []

        for row in dataset {
            guard let input = placementLookup[row.id] else {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "placements", expected: "present", actual: "missing"
                ))
                continue
            }

            let result = ColourEngine.evaluateStrict(input: input)
            let expected = row.expected

            if result.family.rawValue != expected.family {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "family",
                    expected: expected.family, actual: result.family.rawValue
                ))
            }
            if result.variables.depth.rawValue != expected.depth {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "depth",
                    expected: expected.depth, actual: result.variables.depth.rawValue
                ))
            }
            if result.variables.temperature.rawValue != expected.temperature {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "temperature",
                    expected: expected.temperature, actual: result.variables.temperature.rawValue
                ))
            }
            if result.variables.saturation.rawValue != expected.saturation {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "saturation",
                    expected: expected.saturation, actual: result.variables.saturation.rawValue
                ))
            }
            if result.variables.contrast.rawValue != expected.contrast {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "contrast",
                    expected: expected.contrast, actual: result.variables.contrast.rawValue
                ))
            }
            if result.variables.surface.rawValue != expected.surface {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "surface",
                    expected: expected.surface, actual: result.variables.surface.rawValue
                ))
            }
            if result.cluster.rawValue != expected.cluster {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "cluster",
                    expected: expected.cluster, actual: result.cluster.rawValue
                ))
            }
            if result.secondaryPull?.rawValue != expected.secondaryPull {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "secondaryPull",
                    expected: expected.secondaryPull ?? "nil",
                    actual: result.secondaryPull?.rawValue ?? "nil"
                ))
            }
        }

        if !mismatches.isEmpty {
            let summary = mismatches.prefix(20).map { m in
                "  \(m.id).\(m.field): expected=\(m.expected) actual=\(m.actual)"
            }.joined(separator: "\n")
            XCTFail("Classification gate: \(mismatches.count) mismatch(es).\n\(summary)")
        }
    }

    // MARK: - Palette Gate (updated when variation rules change)

    func testPaletteGate() throws {
        let dataset = try loadDataset()
        let placements = try loadPlacements()
        let placementLookup = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.placements) })

        var mismatches: [RegressionMismatch] = []
        var regeneratedRows: [[String: Any]] = []
        let shouldRegenerate = ProcessInfo.processInfo.environment["REGENERATE_V4_PALETTE_EXPECTATIONS"] == "1"

        for row in dataset {
            guard let input = placementLookup[row.id] else { continue }

            let result = ColourEngine.evaluateStrict(input: input)
            let expected = row.expected

            if shouldRegenerate {
                var expDict: [String: Any] = [
                    "family": expected.family,
                    "depth": expected.depth,
                    "temperature": expected.temperature,
                    "saturation": expected.saturation,
                    "contrast": expected.contrast,
                    "surface": expected.surface,
                    "cluster": expected.cluster,
                    "neutrals": result.palette.neutrals,
                    "coreColours": result.palette.coreColours,
                    "accentColours": result.palette.accentColours,
                ]
                if let pull = result.secondaryPull {
                    expDict["secondaryPull"] = pull.rawValue
                }
                let rowDict: [String: Any] = [
                    "id": row.id,
                    "birthData": row.birthData,
                    "location": row.location,
                    "expected": expDict,
                ]
                regeneratedRows.append(rowDict)
            }

            if result.palette.neutrals != expected.neutrals {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "palette.neutrals",
                    expected: expected.neutrals.joined(separator: ", "),
                    actual: result.palette.neutrals.joined(separator: ", ")
                ))
            }
            if result.palette.coreColours != expected.coreColours {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "palette.coreColours",
                    expected: expected.coreColours.joined(separator: ", "),
                    actual: result.palette.coreColours.joined(separator: ", ")
                ))
            }
            if result.palette.accentColours != expected.accentColours {
                mismatches.append(RegressionMismatch(
                    id: row.id, field: "palette.accentColours",
                    expected: expected.accentColours.joined(separator: ", "),
                    actual: result.palette.accentColours.joined(separator: ", ")
                ))
            }
        }

        if shouldRegenerate && !regeneratedRows.isEmpty {
            writeRegeneratedDataset(regeneratedRows)
            print("Regenerated v4_dataset.json with current palette expectations (\(regeneratedRows.count) rows)")
        }

        if !mismatches.isEmpty && !shouldRegenerate {
            writeActualFile(mismatches: mismatches)
            let summary = mismatches.prefix(20).map { m in
                "  \(m.id).\(m.field): expected=\(m.expected) actual=\(m.actual)"
            }.joined(separator: "\n")
            XCTFail("Palette gate: \(mismatches.count) mismatch(es). Run with REGENERATE_V4_PALETTE_EXPECTATIONS=1 to update.\n\(summary)")
        }
    }

    // MARK: - Fixture Loading

    private func loadDataset() throws -> [V4DatasetRow] {
        guard let url = locateFixture(named: "v4_dataset.json") else {
            throw XCTSkip("v4_dataset.json not found — generate fixtures first")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([V4DatasetRow].self, from: data)
    }

    private func loadPlacements() throws -> [V4PlacementRow] {
        guard let url = locateFixture(named: "v4_placements.json") else {
            throw XCTSkip("v4_placements.json not found — run placement generation first")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([V4PlacementRow].self, from: data)
    }

    private func locateFixture(named name: String) -> URL? {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")
        let url = fixturesDir.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Diagnostics

    private func writeActualFile(mismatches: [RegressionMismatch]) {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        let entries = mismatches.map { m -> [String: String] in
            ["id": m.id, "field": m.field, "expected": m.expected, "actual": m.actual]
        }

        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: entries,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return }

        let actualURL = fixturesDir.appendingPathComponent("v4_regression.actual.json")
        try? jsonData.write(to: actualURL, options: [.atomic])
        print("V4 regression diff written to: \(actualURL.path)")
    }

    private func writeRegeneratedDataset(_ rows: [[String: Any]]) {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: rows,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return }

        let url = fixturesDir.appendingPathComponent("v4_dataset.json")
        try? jsonData.write(to: url, options: [.atomic])
    }
}
