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
//  SG-2 Phase 2.5: dual-shape decode.
//    - v1 (shipped): each cluster is a flat map of section -> string.
//    - v2: each section value may be an object
//        { text, sectionIntro, rankedItems, tests, traps }
//      and the cluster carries cluster-level `coreFormula` / `closing`.
//      A top-level or per-cluster `schema_version` is recorded.
//  A plain-string section value ALWAYS decodes as v1 `{ text: <string> }`, so
//  the shipped v1 cache and the 2-cluster fixture still load unchanged.
//

import Foundation

/// Loaded cache entry: all narrative section strings for one archetype cluster.
typealias NarrativeClusterEntry = [String: String]

/// SG-2 Phase 2.5: one section's structured content. `text` is always present
/// (v1 collapses to just this); the rest are populated only by a v2 cache.
struct NarrativeStructuredSection: Equatable {
    let text: String
    let sectionIntro: String?
    let rankedItems: [RankedItem]?
    let tests: [String]?
    let traps: [Trap]?

    init(text: String, sectionIntro: String? = nil, rankedItems: [RankedItem]? = nil,
         tests: [String]? = nil, traps: [Trap]? = nil) {
        self.text = text
        self.sectionIntro = sectionIntro
        self.rankedItems = rankedItems
        self.tests = tests
        self.traps = traps
    }
}

/// SG-2 Phase 2.5: one cluster's structured entry (sections + cluster-level
/// output-contract fields).
struct NarrativeStructuredEntry: Equatable {
    let sections: [String: NarrativeStructuredSection]
    let coreFormula: String?
    let closing: String?
    let schemaVersion: Int?
}

final class NarrativeCacheLoader {

    static let shared = NarrativeCacheLoader()

    private var cache: [String: NarrativeClusterEntry]?
    private var structuredCache: [String: NarrativeStructuredEntry] = [:]
    private var availableKeys: Set<String> = []
    private(set) var schemaVersion: Int = 1

    /// Cluster-level keys that are NOT sections (v2 metadata).
    private static let reservedClusterKeys: Set<String> = ["coreFormula", "closing", "schema_version"]

    // MARK: - Loading

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

    /// Loads the narrative cache from an arbitrary file URL. Decodes both v1
    /// (plain-string sections) and v2 (structured sections + cluster fields).
    @discardableResult
    func loadFromURL(_ url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[NarrativeCacheLoader] Unexpected top-level JSON shape.")
                return false
            }
            ingest(root: root)
            print("[NarrativeCacheLoader] Loaded \(cache?.count ?? 0) archetype clusters (schema v\(schemaVersion)).")
            return true
        } catch {
            print("[NarrativeCacheLoader] Failed to load cache: \(error)")
            return false
        }
    }

    /// Builds both the legacy flat map and the structured map from a raw
    /// `[String: Any]` decoded root.
    private func ingest(root: [String: Any]) {
        var flat: [String: NarrativeClusterEntry] = [:]
        var structured: [String: NarrativeStructuredEntry] = [:]

        // Top-level schema_version (v2 files place it as a sibling of clusters).
        var topSchemaVersion = 1
        if let v = root["schema_version"] as? Int { topSchemaVersion = v }

        for (key, value) in root {
            if key == "schema_version" { continue }
            guard let clusterDict = value as? [String: Any] else { continue }

            let entry = Self.parseCluster(clusterDict, topSchemaVersion: topSchemaVersion)
            structured[key] = entry
            flat[key] = entry.sections.mapValues { $0.text }
        }

        self.schemaVersion = topSchemaVersion
        self.cache = flat
        self.structuredCache = structured
        self.availableKeys = Set(flat.keys)
    }

    private static func parseCluster(
        _ dict: [String: Any], topSchemaVersion: Int
    ) -> NarrativeStructuredEntry {
        var sections: [String: NarrativeStructuredSection] = [:]
        for (k, v) in dict where !reservedClusterKeys.contains(k) {
            sections[k] = parseSection(v)
        }
        return NarrativeStructuredEntry(
            sections: sections,
            coreFormula: dict["coreFormula"] as? String,
            closing: dict["closing"] as? String,
            schemaVersion: (dict["schema_version"] as? Int) ?? topSchemaVersion
        )
    }

    private static func parseSection(_ value: Any) -> NarrativeStructuredSection {
        // v1: a bare string.
        if let text = value as? String {
            return NarrativeStructuredSection(text: text)
        }
        // v2: an object.
        guard let obj = value as? [String: Any] else {
            return NarrativeStructuredSection(text: "")
        }
        let rankedItems = (obj["rankedItems"] as? [[String: Any]])?.map { item in
            RankedItem(
                name: item["name"] as? String ?? "",
                role: item["role"] as? String ?? "",
                useCase: item["useCase"] as? String
            )
        }
        let traps = (obj["traps"] as? [[String: Any]])?.map { t in
            Trap(failure: t["failure"] as? String ?? "", fix: t["fix"] as? String ?? "")
        }
        return NarrativeStructuredSection(
            text: obj["text"] as? String ?? "",
            sectionIntro: obj["sectionIntro"] as? String,
            rankedItems: rankedItems,
            tests: obj["tests"] as? [String],
            traps: traps
        )
    }

    /// Injects a pre-loaded (legacy flat) cache — useful for testing.
    func injectCache(_ entries: [String: NarrativeClusterEntry]) {
        self.cache = entries
        self.availableKeys = Set(entries.keys)
        self.structuredCache = entries.mapValues { sections in
            NarrativeStructuredEntry(
                sections: sections.mapValues { NarrativeStructuredSection(text: $0) },
                coreFormula: nil, closing: nil, schemaVersion: 1
            )
        }
    }

    /// Injects a pre-loaded structured cache (v2 fixtures) for testing.
    func injectStructured(_ entries: [String: NarrativeStructuredEntry]) {
        self.structuredCache = entries
        self.cache = entries.mapValues { $0.sections.mapValues { $0.text } }
        self.availableKeys = Set(entries.keys)
    }

    // MARK: - Lookup

    /// Looks up all narrative strings for the given archetype key result.
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

    /// SG-2 Phase 2.5: looks up the structured entry (section objects +
    /// cluster-level coreFormula/closing), carrying the same nearest-match
    /// fallback as `lookup`.
    func lookupStructured(
        keyResult: ArchetypeKeyGenerator.KeyGenerationResult
    ) -> (entry: NarrativeStructuredEntry?, resolvedKey: String, usedFallback: Bool) {
        guard !structuredCache.isEmpty else {
            return (nil, keyResult.archetypeCluster, true)
        }
        let (resolvedKey, usedFallback, log) = ArchetypeKeyGenerator.resolveKey(
            idealResult: keyResult,
            availableKeys: availableKeys
        )
        if usedFallback, let log = log { print(log) }
        return (structuredCache[resolvedKey], resolvedKey, usedFallback)
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
