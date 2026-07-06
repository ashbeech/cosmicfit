//
//  SG1ComposedExport.swift
//  Cosmic FitTests
//
//  SG-1 (Style Guide Quality Overhaul, Phase 1) — composed-output snapshot
//  exporter used to produce the before/after Slate diff required by the
//  SG-1 gate evidence ("Slate composed output diff shows: MC/community
//  language removed, no '..', no uppercase domainPairImplication").
//
//  Opt-in: the test is a no-op unless the SG1_EXPORT_DIR environment
//  variable is set (pass as TEST_RUNNER_SG1_EXPORT_DIR on the xcodebuild
//  command line). Timestamps are pinned so re-runs diff cleanly.
//
//  The "slate" fixture uses the REAL reference birth data (1989-04-28
//  04:30 Athens = 01:30 UTC), which yields Asc Pisces, MC Sagittarius and
//  Moon in the 11th whole-sign house — the exact chart exhibiting the two
//  diagnosed overlay contradictions. The "maria_midnight_london" fixture
//  matches the SG-0 baseline (docs/house_sect_regression/input_after/
//  maria.json) so the double-period/uppercase fix is diffable against
//  baseline_maria_pre_overhaul.md.
//

import Testing
import Foundation
@testable import Cosmic_Fit

struct SG1ComposedExport {

    private static let pinnedDate: Date = {
        ISO8601DateFormatter().date(from: "2026-07-06T00:00:00Z")!
    }()

    private static var exportDir: String? {
        ProcessInfo.processInfo.environment["SG1_EXPORT_DIR"]
    }

    @Test("Export SG-1 composed snapshots (no-op unless SG1_EXPORT_DIR is set)")
    func exportComposedSnapshots() throws {
        guard let dirPath = Self.exportDir, !dirPath.isEmpty else { return }

        guard let dataset = BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath)
        ) else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }
        let narrativeCache = NarrativeCacheLoader()
        guard narrativeCache.loadFromURL(
            StyleGuideDataURL.blueprintNarrativeCache(testFilePath: #filePath)
        ), narrativeCache.clusterCount > 0 else {
            Issue.record("Failed to load blueprint_narrative_cache.json")
            return
        }

        let fixtures: [(id: String, birthDate: Date, location: String, lat: Double, lon: Double)] = [
            // Real Slate/reference chart: 1989-04-28 04:30 Athens (EEST, UTC+3).
            ("slate", Self.isoDate("1989-04-28T01:30:00Z"), "Athens, Greece", 37.9855765, 23.7283762),
            // SG-0 baseline chart (midnight London) for like-for-like diffing.
            ("maria_midnight_london", Self.isoDate("1989-04-28T00:00:00Z"), "Unknown", 51.5074, -0.1278),
            ("ash", Self.isoDate("1984-12-11T00:00:00Z"), "London, UK", 51.5074, -0.1278)
        ]

        let outputDir = URL(fileURLWithPath: dirPath, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        for fixture in fixtures {
            let chart = NatalChartCalculator.calculateNatalChart(
                birthDate: fixture.birthDate,
                latitude: fixture.lat,
                longitude: fixture.lon,
                timeZone: TimeZone(secondsFromGMT: 0)!
            )
            let blueprint = BlueprintComposer.compose(
                chart: chart,
                birthDate: fixture.birthDate,
                birthLocation: fixture.location,
                dataset: dataset,
                narrativeCache: narrativeCache
            )
            let frozen = Self.pinTimestamps(in: blueprint)
            let data = try encoder.encode(frozen)
            let fileURL = outputDir.appendingPathComponent("\(fixture.id).json")
            try data.write(to: fileURL, options: .atomic)
            print("[SG1ComposedExport] Wrote \(fileURL.path)")
        }
    }

    private static func pinTimestamps(in bp: CosmicBlueprint) -> CosmicBlueprint {
        CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: bp.userInfo.birthDate,
                birthLocation: bp.userInfo.birthLocation,
                generationDate: pinnedDate
            ),
            styleCore: bp.styleCore,
            textures: bp.textures,
            palette: bp.palette,
            occasions: bp.occasions,
            hardware: bp.hardware,
            code: bp.code,
            accessory: bp.accessory,
            pattern: bp.pattern,
            generatedAt: pinnedDate,
            engineVersion: bp.engineVersion
        )
    }

    private static func isoDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
