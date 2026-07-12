import Foundation

/// Canonical Style Guide JSON on disk: `data/style_guide/` at the repository root.
/// `Cosmic Fit/Resources/` contains symlinks to these files so the app bundle ships the same data.
enum StyleGuideDataURL {
    private static func repoRoot(testFilePath: String) -> URL {
        URL(fileURLWithPath: testFilePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static func astrologicalStyleDataset(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath)
            .appendingPathComponent("data/style_guide/astrological_style_dataset.json")
    }

    static func blueprintNarrativeCache(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath)
            .appendingPathComponent("data/style_guide/blueprint_narrative_cache.json")
    }

    static func rankedDomainTables(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath)
            .appendingPathComponent("data/style_guide/ranked_domain_tables.json")
    }

    static func styleGuideRules(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath)
            .appendingPathComponent("data/style_guide/style_guide_rules.json")
    }

    /// SG-4 candidate narrative cache (576 clusters, coach genre). The shipped
    /// v1 cache stays at blueprintNarrativeCache() until the SG-4 gate approves
    /// the cutover.
    static func sg4NarrativeCache(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath)
            .appendingPathComponent("data/style_guide/blueprint_narrative_cache_sg4.json")
    }

    static func sg4ParityFixture(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath)
            .appendingPathComponent("data/style_guide/sg4_parity_fixture.json")
    }
}
