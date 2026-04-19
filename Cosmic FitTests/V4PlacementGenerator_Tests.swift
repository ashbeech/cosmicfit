import XCTest
import CoreLocation
@testable import Cosmic_Fit

/// One-shot fixture generator: converts V4 dataset birth data into frozen
/// chart placements (BirthChartColourInput) for calibration regression.
///
/// Guarded by REGENERATE_V4_PLACEMENTS environment variable.
/// After running, commit the output to `docs/fixtures/v4_placements.json`.
/// This fixture is then the calibration input of truth.
final class V4PlacementGenerator_Tests: XCTestCase {

    private static let shouldRegenerate: Bool = {
        ProcessInfo.processInfo.environment["REGENERATE_V4_PLACEMENTS"] == "1"
    }()

    // MARK: - Geocoding lookup (static for determinism)

    private static let locationCoordinates: [String: (lat: Double, lon: Double, tz: String)] = [
        "Mumbai, India": (18.9750, 72.8258, "Asia/Kolkata"),
        "Bangkok, Thailand": (13.7563, 100.5018, "Asia/Bangkok"),
        "Reykjavik, Iceland": (64.1466, -21.9426, "Atlantic/Reykjavik"),
        "Honolulu, USA": (21.3069, -157.8583, "Pacific/Honolulu"),
        "Mexico City, Mexico": (19.4326, -99.1332, "America/Mexico_City"),
        "Auckland, New Zealand": (-36.8485, 174.7633, "Pacific/Auckland"),
        "London, UK": (51.5074, -0.1278, "Europe/London"),
        "Tokyo, Japan": (35.6762, 139.6503, "Asia/Tokyo"),
        "Cape Town, South Africa": (-33.9249, 18.4241, "Africa/Johannesburg"),
        "Singapore, Singapore": (1.3521, 103.8198, "Asia/Singapore"),
        "Dubai, UAE": (25.2048, 55.2708, "Asia/Dubai"),
        "Los Angeles, USA": (34.0522, -118.2437, "America/Los_Angeles"),
        "Seoul, South Korea": (37.5665, 126.9780, "Asia/Seoul"),
        "Buenos Aires, Argentina": (-34.6037, -58.3816, "America/Argentina/Buenos_Aires"),
        "New York, USA": (40.7128, -74.0060, "America/New_York"),
        "Lagos, Nigeria": (6.5244, 3.3792, "Africa/Lagos"),
        "Rio de Janeiro, Brazil": (-22.9068, -43.1729, "America/Sao_Paulo"),
        "Nairobi, Kenya": (-1.2921, 36.8219, "Africa/Nairobi"),
        "Athens, Greece": (37.9838, 23.7275, "Europe/Athens"),
        "Sydney, Australia": (-33.8688, 151.2093, "Australia/Sydney"),
    ]

    // MARK: - Dataset row type

    private struct V4DatasetRow: Codable {
        let id: String
        let birthData: String
        let location: String
    }

    private struct V4PlacementRow: Codable {
        let id: String
        let placements: BirthChartColourInput
    }

    // MARK: - Generator

    func testGenerateAndFreezePlacements() throws {
        guard Self.shouldRegenerate else {
            throw XCTSkip("Set REGENERATE_V4_PLACEMENTS=1 to run placement generation")
        }

        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        let datasetURL = fixturesDir.appendingPathComponent("v4_dataset.json")
        let datasetData = try Data(contentsOf: datasetURL)
        let rows = try JSONDecoder().decode([V4DatasetRow].self, from: datasetData)

        var placements: [V4PlacementRow] = []
        var failures: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for row in rows {
            guard let coords = Self.locationCoordinates[row.location] else {
                failures.append("\(row.id): unknown location '\(row.location)'")
                continue
            }

            guard let tz = TimeZone(identifier: coords.tz) else {
                failures.append("\(row.id): unknown timezone '\(coords.tz)'")
                continue
            }

            dateFormatter.timeZone = tz
            guard let birthDate = dateFormatter.date(from: row.birthData) else {
                failures.append("\(row.id): unparseable birth data '\(row.birthData)'")
                continue
            }

            let chart = NatalChartCalculator.calculateNatalChart(
                birthDate: birthDate,
                latitude: coords.lat,
                longitude: coords.lon,
                timeZone: tz
            )

            let analysis = ChartAnalyser.analyse(chart: chart)
            let adapted = ChartInputAdapter.adapt(analysis: analysis, natalChart: chart)

            placements.append(V4PlacementRow(id: row.id, placements: adapted.colourInput))
        }

        XCTAssertTrue(failures.isEmpty, "Failed to generate placements:\n\(failures.joined(separator: "\n"))")
        XCTAssertEqual(placements.count, rows.count, "Should generate placement for every row")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let outputData = try encoder.encode(placements)

        let outputURL = fixturesDir.appendingPathComponent("v4_placements.json")
        try outputData.write(to: outputURL, options: [.atomic])

        print("Frozen \(placements.count) placements to: \(outputURL.path)")
        print("IMPORTANT: Commit this file. It is now the calibration input of truth.")
    }

    // MARK: - Maria & Ash Fixture Generator

    func testGenerateMariaAshFixtures() throws {
        guard Self.shouldRegenerate else {
            throw XCTSkip("Set REGENERATE_V4_PLACEMENTS=1 to run Maria/Ash fixture generation")
        }

        let fixturesDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let profiles: [(name: String, birthData: String, location: String)] = [
            ("maria", "1991-06-13 05:30", "Buenos Aires, Argentina"),
            ("ash", "1996-10-09 16:10", "London, UK"),
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for profile in profiles {
            guard let coords = Self.locationCoordinates[profile.location] else {
                XCTFail("Unknown location for \(profile.name): \(profile.location)")
                continue
            }
            guard let tz = TimeZone(identifier: coords.tz) else {
                XCTFail("Unknown timezone for \(profile.name)")
                continue
            }

            dateFormatter.timeZone = tz
            guard let birthDate = dateFormatter.date(from: profile.birthData) else {
                XCTFail("Unparseable birth date for \(profile.name)")
                continue
            }

            let chart = NatalChartCalculator.calculateNatalChart(
                birthDate: birthDate,
                latitude: coords.lat,
                longitude: coords.lon,
                timeZone: tz
            )
            let analysis = ChartAnalyser.analyse(chart: chart)
            let adapted = ChartInputAdapter.adapt(analysis: analysis, natalChart: chart)

            let data = try encoder.encode(adapted.colourInput)
            let url = fixturesDir.appendingPathComponent("v4_locked_placements_\(profile.name).json")
            try data.write(to: url, options: [.atomic])

            print("Frozen \(profile.name) placements to: \(url.path)")

            let result = ColourEngine.evaluateStrict(input: adapted.colourInput)
            print("  \(profile.name) → family: \(result.family.rawValue), depth: \(result.variables.depth.rawValue), temp: \(result.variables.temperature.rawValue)")
            print("  trace.winterCompression: \(result.trace.overrideFlags.winterCompressionApplied)")
        }
    }
}
