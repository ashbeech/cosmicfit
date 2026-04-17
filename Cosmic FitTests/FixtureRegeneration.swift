//
//  FixtureRegeneration.swift
//  Cosmic FitTests
//
//  Palette Engine Rework (Phase A) §11 — fixture regeneration.
//
//  Regenerates `docs/fixtures/blueprint_input_user_1.json` and
//  `blueprint_input_user_2.json` against the post-Phase-A resolver.
//  Preserves each fixture's `userInfo` (birthDate + birthLocation) exactly;
//  every other section is re-derived from the production pipeline.
//
//  Timestamps in the regenerated output are pinned to `regenerationDate`
//  below so re-runs of this test produce byte-identical fixtures (given a
//  deterministic engine — see §12.2 determinism test). Without pinning,
//  `generatedAt` and `generationDate` would update to wall-clock time and
//  churn the fixtures on every test run.
//

import Testing
import Foundation
@testable import Cosmic_Fit

struct FixtureRegeneration {

    /// Pinned generation timestamp embedded in the regenerated fixtures so
    /// the output is byte-stable across test runs. If the fixtures need to
    /// be re-dated (e.g. a future Phase-A++ regen), bump this constant.
    private static let regenerationDate: Date = {
        ISO8601DateFormatter().date(from: "2026-04-17T00:00:00Z")!
    }()

    @Test("Regenerate blueprint_input_user_1 and _user_2 against new resolver")
    func regenerateBothFixtures() throws {
        guard let dataset = Self.loadDataset() else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }
        guard let narrativeCache = Self.loadNarrativeCache() else {
            Issue.record("Failed to load blueprint_narrative_cache.json")
            return
        }

        try regenerate(
            fixtureFilename: "blueprint_input_user_1.json",
            birthDate: Self.isoDate("1984-12-11T00:00:00Z"),
            birthLocation: "London, UK",
            latitude: 51.5074, longitude: -0.1278,
            dataset: dataset, narrativeCache: narrativeCache
        )

        try regenerate(
            fixtureFilename: "blueprint_input_user_2.json",
            birthDate: Self.isoDate("1989-04-28T00:00:00Z"),
            birthLocation: "Unknown",
            latitude: 51.5074, longitude: -0.1278,
            dataset: dataset, narrativeCache: narrativeCache
        )
    }

    // MARK: - Regeneration

    private func regenerate(
        fixtureFilename: String,
        birthDate: Date,
        birthLocation: String,
        latitude: Double,
        longitude: Double,
        dataset: AstrologicalStyleDataset,
        narrativeCache: NarrativeCacheLoader
    ) throws {
        let chart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate,
            latitude: latitude, longitude: longitude,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        let composed = BlueprintComposer.compose(
            chart: chart,
            birthDate: birthDate,
            birthLocation: birthLocation,
            dataset: dataset,
            narrativeCache: narrativeCache
        )

        let frozen = Self.pinTimestamps(in: composed, to: Self.regenerationDate)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let fixtureURL = Self.fixturesURL().appendingPathComponent(fixtureFilename)
        let data = try encoder.encode(frozen)
        try data.write(to: fixtureURL, options: .atomic)
        print("[FixtureRegeneration] Wrote \(fixtureURL.path)")

        // Contract check — no point regenerating if the new shape violates
        // the §11.4 updated checklist.
        #expect(frozen.palette.accentColours.count == 4,
                "Regenerated fixture \(fixtureFilename) must have exactly 4 accents")
        #expect(frozen.palette.coreColours.count >= 3,
                "Regenerated fixture \(fixtureFilename) must have at least 3 core colours")
    }

    // MARK: - Timestamp Pinning

    private static func pinTimestamps(
        in bp: CosmicBlueprint,
        to frozen: Date
    ) -> CosmicBlueprint {
        CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: bp.userInfo.birthDate,
                birthLocation: bp.userInfo.birthLocation,
                generationDate: frozen
            ),
            styleCore: bp.styleCore,
            textures: bp.textures,
            palette: bp.palette,
            occasions: bp.occasions,
            hardware: bp.hardware,
            code: bp.code,
            accessory: bp.accessory,
            pattern: bp.pattern,
            generatedAt: frozen,
            engineVersion: bp.engineVersion
        )
    }

    // MARK: - Support

    private static func loadDataset() -> AstrologicalStyleDataset? {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        return BlueprintTokenGenerator.loadDataset(
            from: repoRoot.appendingPathComponent("astrological_style_dataset.json")
        )
    }

    private static func loadNarrativeCache() -> NarrativeCacheLoader? {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        let cacheURL = repoRoot.appendingPathComponent("blueprint_narrative_cache.json")
        let loader = NarrativeCacheLoader()
        guard loader.loadFromURL(cacheURL), loader.clusterCount > 0 else { return nil }
        return loader
    }

    private static func fixturesURL() -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        return repoRoot.appendingPathComponent("docs").appendingPathComponent("fixtures")
    }

    private static func isoDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
