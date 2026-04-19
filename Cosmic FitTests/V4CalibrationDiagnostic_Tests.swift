import XCTest
@testable import Cosmic_Fit

/// Diagnostic test that computes raw scores for all 100 V4 rows and reports
/// the score distribution per expected bucket. Used to tune thresholds.
final class V4CalibrationDiagnostic_Tests: XCTestCase {

    struct V4DatasetRow: Codable {
        let id: String
        let birthData: String
        let location: String
        let expected: ExpectedOutput
    }

    struct ExpectedOutput: Codable {
        let family: String
        let depth: String
        let temperature: String
        let saturation: String
        let contrast: String
        let surface: String
        let cluster: String
    }

    struct V4PlacementRow: Codable {
        let id: String
        let placements: BirthChartColourInput
    }

    func testPrintScoreDistribution() throws {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        let datasetData = try Data(contentsOf: fixturesDir.appendingPathComponent("v4_dataset.json"))
        let dataset = try JSONDecoder().decode([V4DatasetRow].self, from: datasetData)

        let placementData = try Data(contentsOf: fixturesDir.appendingPathComponent("v4_placements.json"))
        let placements = try JSONDecoder().decode([V4PlacementRow].self, from: placementData)

        let placementLookup = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.placements) })

        var depthScores: [String: [Int]] = ["Light": [], "Medium": [], "Deep": []]
        var warmthScores: [String: [Int]] = ["Cool": [], "Neutral": [], "Warm": []]
        var satScores: [String: [Int]] = ["Soft": [], "Muted": [], "Rich": []]
        var contrastScores: [String: [Int]] = ["Low": [], "Medium": [], "High": []]
        var structureScores: [String: [Int]] = ["Soft": [], "Balanced": [], "Structured": []]
        var familyScores: [String: [(String, DerivedVariables, RawVariableScores)]] = [:]

        for row in dataset {
            guard let input = placementLookup[row.id] else { continue }

            let normalized = Normalizer.normalizeDrivers(input: input)
            let rawBase = Scoring.accumulateRawScores(normalized: normalized)

            var rawMod = rawBase
            var flags = OverrideFlags()
            Modifiers.applyAll(input: input, scores: &rawMod, flags: &flags)

            depthScores[row.expected.depth, default: []].append(rawMod.depth)
            warmthScores[row.expected.temperature, default: []].append(rawMod.warmth)
            satScores[row.expected.saturation, default: []].append(rawMod.saturation)
            contrastScores[row.expected.contrast, default: []].append(rawMod.contrast)
            structureScores[row.expected.surface, default: []].append(rawMod.structure)

            let vars = Thresholds.deriveAll(from: rawMod)
            familyScores[row.expected.family, default: []].append((row.id, vars, rawMod))
        }

        var report = ""

        func addDistribution(_ title: String, _ buckets: [String], _ scores: [String: [Int]]) {
            report += "\n=== \(title) ===\n"
            for bucket in buckets {
                let s = (scores[bucket] ?? []).sorted()
                guard !s.isEmpty else { continue }
                report += "  \(bucket) (n=\(s.count)): min=\(s.first!) max=\(s.last!) median=\(s[s.count/2]) all=\(s)\n"
            }
        }

        addDistribution("DEPTH", ["Light", "Medium", "Deep"], depthScores)
        addDistribution("TEMPERATURE", ["Cool", "Neutral", "Warm"], warmthScores)
        addDistribution("SATURATION", ["Soft", "Muted", "Rich"], satScores)
        addDistribution("CONTRAST", ["Low", "Medium", "High"], contrastScores)
        addDistribution("SURFACE", ["Soft", "Balanced", "Structured"], structureScores)

        report += "\n=== PER-FAMILY SCORE DISTRIBUTIONS ===\n"
        let familyOrder = [
            "Light Spring", "True Spring", "Bright Spring",
            "Light Summer", "True Summer", "Soft Summer",
            "Soft Autumn", "True Autumn", "Deep Autumn",
            "Deep Winter", "True Winter", "Bright Winter"
        ]
        for family in familyOrder {
            let entries = familyScores[family] ?? []
            guard !entries.isEmpty else { continue }
            let depths = entries.map { $0.2.depth }.sorted()
            let warmths = entries.map { $0.2.warmth }.sorted()
            let sats = entries.map { $0.2.saturation }.sorted()
            let cons = entries.map { $0.2.contrast }.sorted()
            let strs = entries.map { $0.2.structure }.sorted()
            let fireAirs = entries.map { (id, _, _) -> Int in
                FamilyMapping.countFireAir(input: placementLookup[id]!)
            }.sorted()
            let earthWaters = entries.map { (id, _, _) -> Int in
                FamilyMapping.countEarthWater(input: placementLookup[id]!)
            }.sorted()
            report += "\n  \(family) (n=\(entries.count)):\n"
            report += "    depth: \(depths)\n"
            report += "    warmth: \(warmths)\n"
            report += "    sat: \(sats)\n"
            report += "    contrast: \(cons)\n"
            report += "    structure: \(strs)\n"
            report += "    fireAir: \(fireAirs)\n"
            report += "    earthWater: \(earthWaters)\n"
        }

        let reportURL = fixturesDir.appendingPathComponent("v4_calibration_diagnostic.txt")
        try report.write(to: reportURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Per-Row Feature Dump

    struct PerRowRecord: Codable {
        let id: String
        let expectedFamily: String
        let actualFamily: String
        let match: Bool
        let depth: Int
        let warmth: Int
        let saturation: Int
        let contrast: Int
        let structure: Int
        let fireAir: Int
        let earthWater: Int
    }

    func testDumpPerRowClassification() throws {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        let datasetData = try Data(contentsOf: fixturesDir.appendingPathComponent("v4_dataset.json"))
        let dataset = try JSONDecoder().decode([V4DatasetRow].self, from: datasetData)

        let placementData = try Data(contentsOf: fixturesDir.appendingPathComponent("v4_placements.json"))
        let placements = try JSONDecoder().decode([V4PlacementRow].self, from: placementData)

        let placementLookup = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.placements) })

        var rows: [PerRowRecord] = []

        for row in dataset {
            guard let input = placementLookup[row.id] else { continue }

            let normalized = Normalizer.normalizeDrivers(input: input)
            let rawBase = Scoring.accumulateRawScores(normalized: normalized)
            var rawMod = rawBase
            var flags = OverrideFlags()
            Modifiers.applyAll(input: input, scores: &rawMod, flags: &flags)

            let result = ColourEngine.evaluateStrict(input: input)
            let fa = FamilyMapping.countFireAir(input: input)
            let ew = FamilyMapping.countEarthWater(input: input)

            rows.append(PerRowRecord(
                id: row.id,
                expectedFamily: row.expected.family,
                actualFamily: result.family.rawValue,
                match: result.family.rawValue == row.expected.family,
                depth: rawMod.depth,
                warmth: rawMod.warmth,
                saturation: rawMod.saturation,
                contrast: rawMod.contrast,
                structure: rawMod.structure,
                fireAir: fa,
                earthWater: ew
            ))
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(rows)
        let outputURL = fixturesDir.appendingPathComponent("v4_per_row_classification.json")
        try jsonData.write(to: outputURL, options: .atomic)

        let matchCount = rows.filter(\.match).count
        let mismatches = rows.filter { !$0.match }
        print("V4 Classification: \(matchCount)/\(rows.count) matches")
        for m in mismatches {
            print("  \(m.id): expected=\(m.expectedFamily) actual=\(m.actualFamily) | d=\(m.depth) w=\(m.warmth) s=\(m.saturation) c=\(m.contrast) st=\(m.structure) fa=\(m.fireAir) ew=\(m.earthWater)")
        }
    }

    // MARK: - Maria & Ash Diagnostic

    func testDumpMariaAshScores() throws {
        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        var report = ""
        for name in ["maria", "ash"] {
            let url = fixturesDir.appendingPathComponent("v4_locked_placements_\(name).json")
            let data = try Data(contentsOf: url)
            let input = try JSONDecoder().decode(BirthChartColourInput.self, from: data)

            let normalized = Normalizer.normalizeDrivers(input: input)
            let rawBase = Scoring.accumulateRawScores(normalized: normalized)
            var rawMod = rawBase
            var flags = OverrideFlags()
            Modifiers.applyAll(input: input, scores: &rawMod, flags: &flags)

            let result = ColourEngine.evaluateStrict(input: input)
            let fa = FamilyMapping.countFireAir(input: input)
            let ew = FamilyMapping.countEarthWater(input: input)

            report += "\(name.uppercased()): family=\(result.family.rawValue) | d=\(rawMod.depth) w=\(rawMod.warmth) s=\(rawMod.saturation) c=\(rawMod.contrast) st=\(rawMod.structure) fa=\(fa) ew=\(ew)\n"
            report += "  flags: earthDepth=\(flags.earthDepthOverrideApplied) winterComp=\(flags.winterCompressionApplied) coolLean=\(flags.coolLeanDeepAutumn) scorpio=\(flags.scorpioDensityApplied) capVirgo=\(flags.capricornVirgoCoolingApplied) faChroma=\(flags.fireAirChromaApplied) waterSoft=\(flags.waterSofteningApplied) surfPres=\(flags.surfacePreservationApplied)\n"
            report += "  variables: depth=\(result.variables.depth.rawValue) temp=\(result.variables.temperature.rawValue) sat=\(result.variables.saturation.rawValue) contrast=\(result.variables.contrast.rawValue) surface=\(result.variables.surface.rawValue)\n"
            report += "  secondaryPull: \(result.secondaryPull?.rawValue ?? "nil")\n\n"
        }

        let outputURL = fixturesDir.appendingPathComponent("v4_maria_ash_diagnostic.txt")
        try report.write(to: outputURL, atomically: true, encoding: .utf8)
    }
}
