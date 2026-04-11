//
//  ArchetypeKeyGenerator.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Generates archetype cluster keys for narrative cache lookup.
//  Key format: <venus_sign>__<moon_sign>__<element_group>
//
//  Implements the nearest-match fallback algorithm from spec §3d:
//    1. Exact match first
//    2. Component distance scoring (Venus mismatch = 3, Moon = 2, Element = 1)
//    3. Sign-affinity sub-scoring (same-element near-miss = -0.5)
//    4. Tie-break: prefer Venus match, then alphabetical
//    5. Logging of all fallback decisions
//

import Foundation

struct ArchetypeKeyGenerator {

    // MARK: - Public API

    struct KeyGenerationResult {
        let archetypeCluster: String
        let venusComponent: String
        let moonComponent: String
        let elementComponent: String
        let usedFallback: Bool
        let fallbackLog: String?
    }

    /// Generates the archetype cluster key for a given chart analysis.
    static func generateKey(analysis: ChartAnalysis) -> KeyGenerationResult {
        let venusComp = "venus_\(analysis.venusSign.lowercased())"
        let moonComp = "moon_\(analysis.moonSign.lowercased())"
        let elementComp = "\(analysis.elementBalance.dominant)_dominant"

        let idealKey = "\(venusComp)__\(moonComp)__\(elementComp)"

        return KeyGenerationResult(
            archetypeCluster: idealKey,
            venusComponent: venusComp,
            moonComponent: moonComp,
            elementComponent: elementComp,
            usedFallback: false,
            fallbackLog: nil
        )
    }

    /// Resolves the actual key to use by matching against available cache keys.
    /// Returns the exact key if it exists, or the nearest match via the fallback algorithm.
    static func resolveKey(
        idealResult: KeyGenerationResult,
        availableKeys: Set<String>
    ) -> (resolvedKey: String, usedFallback: Bool, log: String?) {
        let ideal = idealResult.archetypeCluster

        // Step 1: exact match
        if availableKeys.contains(ideal) {
            return (ideal, false, nil)
        }

        // Step 2-4: nearest match
        guard !availableKeys.isEmpty else {
            let log = "[ArchetypeKeyGenerator] No keys in cache. Original: \(ideal)"
            return (ideal, true, log)
        }

        let userVenus = idealResult.venusComponent
        let userMoon = idealResult.moonComponent
        let userElement = idealResult.elementComponent

        let userVenusSign = extractSign(from: userVenus)
        let userMoonSign = extractSign(from: userMoon)

        var bestKey = ""
        var bestDistance = Double.greatestFiniteMagnitude

        let sortedKeys = availableKeys.sorted()

        for candidateKey in sortedKeys {
            let components = candidateKey.components(separatedBy: "__")
            guard components.count == 3 else { continue }

            let candVenus = components[0]
            let candMoon = components[1]
            let candElement = components[2]

            // Base distance
            var distance: Double = 0
            let venusMatch = candVenus == userVenus
            let moonMatch = candMoon == userMoon
            let elementMatch = candElement == userElement

            if !venusMatch { distance += 3.0 }
            if !moonMatch { distance += 2.0 }
            if !elementMatch { distance += 1.0 }

            // Sign-affinity sub-scoring: same-element near-miss reduces distance by 0.5
            if !venusMatch {
                let candVenusSign = extractSign(from: candVenus)
                if sameElement(userVenusSign, candVenusSign) {
                    distance -= 0.5
                }
            }
            if !moonMatch {
                let candMoonSign = extractSign(from: candMoon)
                if sameElement(userMoonSign, candMoonSign) {
                    distance -= 0.5
                }
            }

            // Tie-break: prefer Venus match; then alphabetical (handled by sorted iteration)
            if distance < bestDistance || (distance == bestDistance && venusMatch) {
                bestDistance = distance
                bestKey = candidateKey
            }
        }

        let log = """
            [ArchetypeKeyGenerator] Fallback used.
              Original key: \(ideal)
              Matched key:  \(bestKey)
              Distance:     \(bestDistance)
            """

        return (bestKey, true, log)
    }

    // MARK: - Cluster Enumeration

    /// Generates all archetype cluster keys for the backfill script.
    /// Returns ~576 keys (12 Venus × 12 Moon × 4 elements).
    static func enumerateAllClusterKeys() -> [String] {
        let signs = ["aries", "taurus", "gemini", "cancer", "leo", "virgo",
                     "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]
        let elements = ["fire", "earth", "air", "water"]

        var keys: [String] = []
        for venus in signs {
            for moon in signs {
                for element in elements {
                    keys.append("venus_\(venus)__moon_\(moon)__\(element)_dominant")
                }
            }
        }
        return keys
    }

    /// Returns a reduced set of ~80-100 representative cluster keys by grouping
    /// Moon signs by element and collapsing to the cardinal sign of each element group.
    static func enumerateRepresentativeClusterKeys() -> [String] {
        let signs = ["aries", "taurus", "gemini", "cancer", "leo", "virgo",
                     "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]
        let elements = ["fire", "earth", "air", "water"]

        let moonRepresentatives: [String: String] = [
            "aries": "aries", "leo": "aries", "sagittarius": "aries",
            "taurus": "taurus", "virgo": "taurus", "capricorn": "taurus",
            "gemini": "gemini", "libra": "gemini", "aquarius": "gemini",
            "cancer": "cancer", "scorpio": "cancer", "pisces": "cancer"
        ]

        var keys: Set<String> = []
        for venus in signs {
            for moon in signs {
                let moonRep = moonRepresentatives[moon] ?? moon
                for element in elements {
                    keys.insert("venus_\(venus)__moon_\(moonRep)__\(element)_dominant")
                }
            }
        }
        return keys.sorted()
    }

    // MARK: - Private Helpers

    private static let signElements: [String: String] = [
        "aries": "fire", "taurus": "earth", "gemini": "air", "cancer": "water",
        "leo": "fire", "virgo": "earth", "libra": "air", "scorpio": "water",
        "sagittarius": "fire", "capricorn": "earth", "aquarius": "air", "pisces": "water"
    ]

    private static func extractSign(from component: String) -> String {
        if component.hasPrefix("venus_") {
            return String(component.dropFirst(6))
        } else if component.hasPrefix("moon_") {
            return String(component.dropFirst(5))
        }
        return component
    }

    private static func sameElement(_ sign1: String, _ sign2: String) -> Bool {
        guard let e1 = signElements[sign1.lowercased()],
              let e2 = signElements[sign2.lowercased()] else { return false }
        return e1 == e2
    }
}
