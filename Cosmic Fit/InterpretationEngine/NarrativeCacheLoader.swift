//
//  NarrativeCacheLoader.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Loads blueprint_narrative_cache.json from the app bundle and provides
//  lookup by archetype cluster key. Handles cache miss via nearest-match
//  fallback from ArchetypeKeyGenerator.
//

import Foundation

/// Loaded cache entry: all 16 narrative section strings for one archetype cluster.
typealias NarrativeClusterEntry = [String: String]

final class NarrativeCacheLoader {

    static let shared = NarrativeCacheLoader()

    private var cache: [String: NarrativeClusterEntry]?
    private var availableKeys: Set<String> = []

    // MARK: - Loading

    /// Loads the narrative cache from the app bundle.
    /// Call once at startup; subsequent calls are no-ops if already loaded.
    @discardableResult
    func loadFromBundle(bundle: Bundle = .main) -> Bool {
        guard cache == nil else { return true }

        guard let url = bundle.url(
            forResource: "blueprint_narrative_cache",
            withExtension: "json"
        ) else {
            print("[NarrativeCacheLoader] blueprint_narrative_cache.json not found in bundle.")
            return false
        }

        return loadFromURL(url)
    }

    /// Loads the narrative cache from an arbitrary file URL.
    @discardableResult
    func loadFromURL(_ url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(
                [String: NarrativeClusterEntry].self,
                from: data
            )
            self.cache = decoded
            self.availableKeys = Set(decoded.keys)
            print("[NarrativeCacheLoader] Loaded \(decoded.count) archetype clusters.")
            return true
        } catch {
            print("[NarrativeCacheLoader] Failed to load cache: \(error)")
            return false
        }
    }

    /// Injects a pre-loaded cache (useful for testing without file I/O).
    func injectCache(_ entries: [String: NarrativeClusterEntry]) {
        self.cache = entries
        self.availableKeys = Set(entries.keys)
    }

    // MARK: - Lookup

    /// Looks up all 16 narrative strings for the given archetype key result.
    /// Uses nearest-match fallback if the exact key is not in the cache.
    func lookup(
        keyResult: ArchetypeKeyGenerator.KeyGenerationResult
    ) -> (entry: NarrativeClusterEntry, resolvedKey: String, usedFallback: Bool) {
        guard let cache = cache, !cache.isEmpty else {
            return (emptyEntry(), keyResult.archetypeCluster, true)
        }

        let (resolvedKey, usedFallback, log) = ArchetypeKeyGenerator.resolveKey(
            idealResult: keyResult,
            availableKeys: availableKeys
        )

        if usedFallback, let log = log {
            print(log)
        }

        if let entry = cache[resolvedKey] {
            return (entry, resolvedKey, usedFallback)
        }

        return (emptyEntry(), resolvedKey, true)
    }

    /// Looks up a single section's narrative text.
    func lookupSection(
        section: BlueprintArchetypeKey.BlueprintSection,
        keyResult: ArchetypeKeyGenerator.KeyGenerationResult
    ) -> String {
        let (entry, _, _) = lookup(keyResult: keyResult)
        return entry[section.rawValue] ?? ""
    }

    // MARK: - Diagnostics

    var clusterCount: Int { cache?.count ?? 0 }
    var isLoaded: Bool { cache != nil }

    // MARK: - Private

    private func emptyEntry() -> NarrativeClusterEntry {
        var entry: NarrativeClusterEntry = [:]
        for section in BlueprintArchetypeKey.BlueprintSection.allCases {
            entry[section.rawValue] = ""
        }
        return entry
    }
}
