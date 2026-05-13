import Foundation

public enum ResourcePaths {

    public static let packageRoot: URL = {
        let execURL = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])
            .resolvingSymlinksInPath()
        var candidate = execURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let pkgSwift = candidate.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: pkgSwift.path) {
                return candidate
            }
            candidate = candidate.deletingLastPathComponent()
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }()

    public static var resourcesDirectory: URL {
        packageRoot.appendingPathComponent("Resources")
    }

    public static var astrologicalStyleDatasetURL: URL {
        resourcesDirectory.appendingPathComponent("astrological_style_dataset.json")
    }

    public static var blueprintNarrativeCacheURL: URL {
        resourcesDirectory.appendingPathComponent("blueprint_narrative_cache.json")
    }

    public static var swissEphemerisDirectory: URL {
        resourcesDirectory
    }

    public static var vsop87DataDirectory: URL {
        resourcesDirectory.appendingPathComponent("VSOP87Data")
    }

    public static var presetsURL: URL {
        resourcesDirectory.appendingPathComponent("presets.json")
    }

    public static func validateResources() -> [String] {
        var missing: [String] = []
        let required: [(String, URL)] = [
            ("astrological_style_dataset.json", astrologicalStyleDatasetURL),
            ("blueprint_narrative_cache.json", blueprintNarrativeCacheURL),
            ("seas_18.se1", resourcesDirectory.appendingPathComponent("seas_18.se1")),
        ]
        for (label, url) in required {
            if !FileManager.default.fileExists(atPath: url.path) {
                missing.append(label)
            }
        }
        let vsop87Dir = vsop87DataDirectory
        if !FileManager.default.fileExists(atPath: vsop87Dir.appendingPathComponent("VSOP87D.ear").path) {
            missing.append("VSOP87Data/VSOP87D.ear")
        }
        return missing
    }
}
