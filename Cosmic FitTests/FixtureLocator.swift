import Foundation

enum FixtureLocator {
    static func repoRoot(testFilePath: String = #filePath) -> URL {
        URL(fileURLWithPath: testFilePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static func primaryFixturesDirectory(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath).appendingPathComponent("docs/fixtures")
    }

    static func archiveFixturesDirectory(testFilePath: String = #filePath) -> URL {
        repoRoot(testFilePath: testFilePath).appendingPathComponent("docs/archive/fixtures")
    }

    static func fixtureDirectories(testFilePath: String = #filePath) -> [URL] {
        [
            primaryFixturesDirectory(testFilePath: testFilePath),
            archiveFixturesDirectory(testFilePath: testFilePath),
        ]
    }

    static func fixtureURL(named name: String, testFilePath: String = #filePath) -> URL? {
        for directory in fixtureDirectories(testFilePath: testFilePath) {
            let candidate = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
