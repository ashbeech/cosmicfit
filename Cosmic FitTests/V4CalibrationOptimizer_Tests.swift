import XCTest
@testable import Cosmic_Fit

/// Optimizer that finds the best centroid + scale parameters to maximize
/// V4 regression match rate. Writes results to a file for manual review.
final class V4CalibrationOptimizer_Tests: XCTestCase {

    struct V4DatasetRow: Codable {
        let id: String
        let birthData: String
        let location: String
        let expected: ExpectedOutput
    }
    struct ExpectedOutput: Codable {
        let family: String
    }
    struct V4PlacementRow: Codable {
        let id: String
        let placements: BirthChartColourInput
    }

    struct RowData {
        let id: String
        let expectedFamily: String
        let depth: Double
        let warmth: Double
        let saturation: Double
        let contrast: Double
        let structure: Double
        let fireAir: Double
        let earthWater: Double
    }

    func testOptimizeCentroidsAndScales() throws {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        let dataset = try JSONDecoder().decode(
            [V4DatasetRow].self,
            from: Data(contentsOf: fixturesDir.appendingPathComponent("v4_dataset.json"))
        )
        let placements = try JSONDecoder().decode(
            [V4PlacementRow].self,
            from: Data(contentsOf: fixturesDir.appendingPathComponent("v4_placements.json"))
        )
        let placementLookup = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.placements) })

        var rows: [RowData] = []
        for row in dataset {
            guard let input = placementLookup[row.id] else { continue }
            let normalized = Normalizer.normalizeDrivers(input: input)
            let rawBase = Scoring.accumulateRawScores(normalized: normalized)
            var rawMod = rawBase
            var flags = OverrideFlags()
            Modifiers.applyAll(input: input, scores: &rawMod, flags: &flags)
            let fa = FamilyMapping.countFireAir(input: input)
            let ew = FamilyMapping.countEarthWater(input: input)
            rows.append(RowData(
                id: row.id,
                expectedFamily: row.expected.family,
                depth: Double(rawMod.depth),
                warmth: Double(rawMod.warmth),
                saturation: Double(rawMod.saturation),
                contrast: Double(rawMod.contrast),
                structure: Double(rawMod.structure),
                fireAir: Double(fa),
                earthWater: Double(ew)
            ))
        }

        let families = [
            "Light Spring", "True Spring", "Bright Spring",
            "Light Summer", "True Summer", "Soft Summer",
            "Soft Autumn", "True Autumn", "Deep Autumn",
            "Deep Winter", "True Winter", "Bright Winter"
        ]

        // Compute centroids from the data
        var centroids: [String: [Double]] = [:]
        for family in families {
            let familyRows = rows.filter { $0.expectedFamily == family }
            guard !familyRows.isEmpty else { continue }
            let n = Double(familyRows.count)
            let meanD = familyRows.map(\.depth).reduce(0, +) / n
            let meanW = familyRows.map(\.warmth).reduce(0, +) / n
            let meanS = familyRows.map(\.saturation).reduce(0, +) / n
            let meanC = familyRows.map(\.contrast).reduce(0, +) / n
            let meanSt = familyRows.map(\.structure).reduce(0, +) / n
            let meanFA = familyRows.map(\.fireAir).reduce(0, +) / n
            let meanEW = familyRows.map(\.earthWater).reduce(0, +) / n
            centroids[family] = [meanD, meanW, meanS, meanC, meanSt, meanFA, meanEW]
        }

        // Grid search over scale parameters
        var bestAccuracy = 0
        var bestScales = [1.0, 1.0, 1.0, 1.0, 1.0, 25.0, 25.0]
        var report = ""

        let scaleOptions: [[Double]] = [
            [0.5, 1.0, 1.5, 2.0],
            [0.5, 1.0, 1.5, 2.0],
            [0.5, 1.0, 1.5, 2.0],
            [0.5, 1.0, 1.5, 2.0],
            [0.5, 1.0, 1.5, 2.0],
            [15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 50.0],
            [15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 50.0],
        ]

        for sD in scaleOptions[0] {
            for sW in scaleOptions[1] {
                for sS in scaleOptions[2] {
                    for sC in scaleOptions[3] {
                        for sSt in scaleOptions[4] {
                            for sFA in scaleOptions[5] {
                                for sEW in scaleOptions[6] {
                                    let scales = [sD, sW, sS, sC, sSt, sFA, sEW]
                                    let accuracy = computeAccuracy(rows: rows, centroids: centroids, scales: scales)
                                    if accuracy > bestAccuracy {
                                        bestAccuracy = accuracy
                                        bestScales = scales
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        report += "Best accuracy: \(bestAccuracy)/\(rows.count)\n"
        report += "Best scales: depth=\(bestScales[0]) warmth=\(bestScales[1]) sat=\(bestScales[2]) contrast=\(bestScales[3]) structure=\(bestScales[4]) fireAir=\(bestScales[5]) earthWater=\(bestScales[6])\n\n"

        // Show mismatches with best scales
        let mismatches = classifyAll(rows: rows, centroids: centroids, scales: bestScales)
        report += "Mismatches with best scales:\n"
        for (id, expected, actual) in mismatches {
            report += "  \(id): expected=\(expected) actual=\(actual)\n"
        }

        report += "\nCentroids:\n"
        for family in families {
            if let c = centroids[family] {
                report += "  \(family): depth=\(String(format: "%.1f", c[0])) warmth=\(String(format: "%.1f", c[1])) sat=\(String(format: "%.1f", c[2])) con=\(String(format: "%.1f", c[3])) str=\(String(format: "%.1f", c[4])) fa=\(String(format: "%.1f", c[5])) ew=\(String(format: "%.1f", c[6]))\n"
            }
        }

        let reportURL = fixturesDir.appendingPathComponent("v4_optimizer_report.txt")
        try report.write(to: reportURL, atomically: true, encoding: .utf8)
    }

    private func computeAccuracy(rows: [RowData], centroids: [String: [Double]], scales: [Double]) -> Int {
        var correct = 0
        for row in rows {
            let predicted = classify(row: row, centroids: centroids, scales: scales)
            if predicted == row.expectedFamily { correct += 1 }
        }
        return correct
    }

    private func classifyAll(rows: [RowData], centroids: [String: [Double]], scales: [Double]) -> [(String, String, String)] {
        var mismatches: [(String, String, String)] = []
        for row in rows {
            let predicted = classify(row: row, centroids: centroids, scales: scales)
            if predicted != row.expectedFamily {
                mismatches.append((row.id, row.expectedFamily, predicted))
            }
        }
        return mismatches
    }

    private func classify(row: RowData, centroids: [String: [Double]], scales: [Double]) -> String {
        var bestFamily = ""
        var bestDist = Double.greatestFiniteMagnitude
        let features = [row.depth, row.warmth, row.saturation, row.contrast, row.structure, row.fireAir, row.earthWater]
        for (family, centroid) in centroids {
            var dist = 0.0
            for i in 0..<7 {
                let d = (features[i] - centroid[i]) * scales[i]
                dist += d * d
            }
            if dist < bestDist {
                bestDist = dist
                bestFamily = family
            }
        }
        return bestFamily
    }
}
