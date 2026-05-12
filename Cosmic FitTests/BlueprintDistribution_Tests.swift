//
//  BlueprintDistribution_Tests.swift
//  Cosmic FitTests
//
//  Parts 3B–3E: Distribution histograms for Style Guide tokens across
//  the 48-chart ExtendedCalibrationProfiles population.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite(.serialized) struct BlueprintDistribution_Tests {

    // MARK: - Helpers

    private func allTokenSets() -> [(chart: ExtendedCalibrationProfiles.ChartSpec, tokens: [StyleToken])] {
        ExtendedCalibrationProfiles.allCharts.map { chart in
            let tokens = SemanticTokenGenerator.generateStyleGuideTokens(natal: chart.natalChart)
            return (chart: chart, tokens: tokens)
        }
    }

    // MARK: - 3B: Token Weight Distribution

    @Test("3B — token weight distribution across all charts")
    func tokenWeightDistribution() {
        let sets = allTokenSets()

        var countByType: [String: Int] = [:]
        var weightByType: [String: Double] = [:]
        var allWeights: [Double] = []

        for (_, tokens) in sets {
            for token in tokens {
                countByType[token.type, default: 0] += 1
                weightByType[token.type, default: 0.0] += token.weight
                allWeights.append(token.weight)
            }
        }

        let sortedTypes = countByType.keys.sorted()

        var report = ""
        report += CalibrationReportHelper.renderHistogram(
            title: "3B — Token Count by Type (n=\(sets.count) charts)",
            data: sortedTypes.map { (label: $0, count: countByType[$0]!) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3B — Total Weight by Type",
            data: sortedTypes.map { (label: $0, count: Int(weightByType[$0]!)) }
        )
        report += "\n"
        report += CalibrationReportHelper.summaryStats(label: "All token weights", values: allWeights)
        report += "\n\n"

        for typeName in sortedTypes {
            let weights = sets.flatMap { $0.tokens.filter { $0.type == typeName }.map(\.weight) }
            report += CalibrationReportHelper.summaryStats(label: typeName, values: weights)
            report += "\n"
        }

        print(report)
        #expect(countByType.count > 0, "Should produce at least one token type")
    }

    // MARK: - 3C: Resolver Output Distribution

    @Test("3C — texture, pattern, accessory token distribution")
    func resolverOutputDistribution() {
        let sets = allTokenSets()
        let targetTypes: Set<String> = ["textile", "texture", "pattern", "accessory"]

        var nameFrequency: [String: Int] = [:]
        var namesByType: [String: [String: Int]] = [:]

        for (_, tokens) in sets {
            let filtered = tokens.filter { targetTypes.contains($0.type) }
            for token in filtered {
                nameFrequency[token.name, default: 0] += 1
                namesByType[token.type, default: [:]][token.name, default: 0] += 1
            }
        }

        var report = ""
        let sortedNames = nameFrequency.sorted { $0.value > $1.value }
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Material/Pattern/Accessory Token Frequency (top 30)",
            data: Array(sortedNames.prefix(30).map { (label: $0.key, count: $0.value) })
        )
        report += "\n"

        for typeName in targetTypes.sorted() {
            guard let names = namesByType[typeName] else { continue }
            let sorted = names.sorted { $0.value > $1.value }
            report += CalibrationReportHelper.renderHistogram(
                title: "3C — '\(typeName)' token name frequency",
                data: Array(sorted.prefix(15).map { (label: $0.key, count: $0.value) })
            )
            report += "\n"
        }

        print(report)
        #expect(!nameFrequency.isEmpty, "Should produce at least some material/pattern/accessory tokens")
    }

    // MARK: - 3D: Palette Family Distribution

    @Test("3D — element vs palette token correlation")
    func paletteElementCorrelation() {
        let sets = allTokenSets()
        let colourTypes: Set<String> = ["colour", "colour_quality"]

        var coloursByElement: [String: [String]] = [:]

        for (chart, tokens) in sets {
            let colourTokenNames = tokens
                .filter { colourTypes.contains($0.type) }
                .map(\.name)
            coloursByElement[chart.elementDominance, default: []].append(contentsOf: colourTokenNames)
        }

        let warmKeywords: Set<String> = [
            "warm", "gold", "amber", "red", "orange", "crimson", "scarlet",
            "copper", "rust", "flame", "terracotta", "coral", "sunny", "fire",
            "golden", "burnished", "bronze", "saffron"
        ]
        let coolKeywords: Set<String> = [
            "cool", "blue", "aqua", "teal", "silver", "ice", "ocean",
            "navy", "slate", "steel", "cerulean", "frost", "water",
            "marine", "sapphire", "midnight", "indigo"
        ]

        var report = "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3D — Element vs Colour Token Correlation\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"

        for element in ["fire", "earth", "air", "water", "balanced"] {
            let names = coloursByElement[element] ?? []
            guard !names.isEmpty else {
                report += "  \(element): no colour tokens\n"
                continue
            }

            let warmCount = names.filter { name in
                warmKeywords.contains(where: { name.lowercased().contains($0) })
            }.count
            let coolCount = names.filter { name in
                coolKeywords.contains(where: { name.lowercased().contains($0) })
            }.count
            let neutralCount = names.count - warmCount - coolCount

            report += "  \(element.padding(toLength: 10, withPad: " ", startingAt: 0))  "
            report += "total=\(String(format: "%3d", names.count))  "
            report += "warm=\(String(format: "%3d", warmCount))  "
            report += "cool=\(String(format: "%3d", coolCount))  "
            report += "neutral=\(String(format: "%3d", neutralCount))\n"

            let uniqueNames = Dictionary(grouping: names, by: { $0 }).mapValues(\.count)
            let top5 = uniqueNames.sorted { $0.value > $1.value }.prefix(5)
            report += "             top tokens: \(top5.map { "\($0.key)(\($0.value))" }.joined(separator: ", "))\n"
        }

        print(report)
        #expect(!coloursByElement.isEmpty, "Should produce colour tokens for at least one element group")
    }

    // MARK: - 3E: Token Category Coverage

    @Test("3E — every token type appears for some charts")
    func tokenCategoryCoverage() {
        let sets = allTokenSets()

        let allTypes = Set(sets.flatMap { $0.tokens.map(\.type) })

        let requiredGroups: [(check: String, alternatives: Set<String>)] = [
            ("texture/textile", ["texture", "textile"]),
            ("colour/colour_quality", ["colour", "colour_quality"]),
            ("expression", ["expression"]),
            ("mood", ["mood"]),
            ("structure", ["structure"]),
            ("pattern", ["pattern"]),
            ("accessory", ["accessory"]),
        ]

        var report = "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3E — Token Type Coverage\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"
        report += "  All types found: \(allTypes.sorted().joined(separator: ", "))\n\n"

        for (name, alts) in requiredGroups {
            let found = !alts.isDisjoint(with: allTypes)
            report += "  \(name.padding(toLength: 25, withPad: " ", startingAt: 0))  \(found ? "✅" : "❌")  "
            report += "matched: \(alts.intersection(allTypes).sorted().joined(separator: ", "))\n"
            #expect(found, "Required token group '\(name)' not found. Have types: \(allTypes.sorted())")
        }

        print(report)
    }

    // MARK: - 3C (Full): DeterministicResolver Output Distribution

    @Test("3C — resolver texture/hardware/code/pattern distribution across all charts")
    func resolverFullOutputDistribution() {
        guard let dataset = BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset()
        ) else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }

        var textureFreq: [String: Int] = [:]
        var metalFreq: [String: Int] = [:]
        var stoneFreq: [String: Int] = [:]
        var leanIntoFreq: [String: Int] = [:]
        var avoidFreq: [String: Int] = [:]
        var patternRecommended: [String: Int] = [:]
        var patternAvoided: [String: Int] = [:]

        for chart in ExtendedCalibrationProfiles.allCharts {
            let analysis = ChartAnalyser.analyse(chart: chart.natalChart)
            let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
            let resolved = DeterministicResolver.resolveNonPalette(
                tokens: tokenResult.tokens,
                analysis: analysis,
                dataset: tokenResult.dataset,
                contributingCombos: tokenResult.contributingCombos
            )

            for t in resolved.recommendedTextures { textureFreq[t, default: 0] += 1 }
            for m in resolved.recommendedMetals { metalFreq[m, default: 0] += 1 }
            for s in resolved.recommendedStones { stoneFreq[s, default: 0] += 1 }
            for k in resolved.leanInto { leanIntoFreq[k, default: 0] += 1 }
            for k in resolved.avoid { avoidFreq[k, default: 0] += 1 }
            for p in resolved.recommendedPatterns { patternRecommended[p, default: 0] += 1 }
            for p in resolved.avoidPatterns { patternAvoided[p, default: 0] += 1 }
        }

        var report = ""
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Recommended Textures (resolver)",
            data: textureFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Recommended Metals (resolver)",
            data: metalFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Recommended Stones (resolver)",
            data: stoneFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Code: Lean Into keywords",
            data: leanIntoFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Code: Avoid keywords",
            data: avoidFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Recommended Patterns (resolver)",
            data: patternRecommended.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Avoided Patterns (resolver)",
            data: patternAvoided.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )

        let totalCharts = ExtendedCalibrationProfiles.allCharts.count
        let universalLeanInto = leanIntoFreq.filter { $0.value == totalCharts }
        if !universalLeanInto.isEmpty {
            report += "\n⚠️ Keywords in 'lean into' for ALL \(totalCharts) charts (no discriminating power):\n"
            report += "  \(universalLeanInto.keys.sorted().joined(separator: ", "))\n"
        }

        print(report)
        CalibrationReportHelper.writeReport(prefix: "blueprint_resolver_distribution", content: report)

        #expect(!textureFreq.isEmpty, "Resolver should produce at least some textures")
        #expect(!metalFreq.isEmpty, "Resolver should produce at least some metals")
    }

    // MARK: - 3D (Full): V4 Palette Family & Cluster Distribution

    @Test("3D — V4 PaletteFamily and PaletteCluster distribution across all charts")
    func v4FamilyClusterDistribution() {
        var familyFreq: [String: Int] = [:]
        var clusterFreq: [String: Int] = [:]
        var familyByElement: [String: [String: Int]] = [:]

        for chart in ExtendedCalibrationProfiles.allCharts {
            let analysis = ChartAnalyser.analyse(chart: chart.natalChart)
            let adapted = ChartInputAdapter.adapt(analysis: analysis, natalChart: chart.natalChart)
            let colourResult = ColourEngine.evaluateProduction(input: adapted.colourInput)

            let familyName = colourResult.family.rawValue
            let clusterName = colourResult.cluster.rawValue
            familyFreq[familyName, default: 0] += 1
            clusterFreq[clusterName, default: 0] += 1
            familyByElement[chart.elementDominance, default: [:]][familyName, default: 0] += 1
        }

        var report = ""
        report += CalibrationReportHelper.renderHistogram(
            title: "3D — V4 PaletteFamily Distribution (n=\(ExtendedCalibrationProfiles.allCharts.count))",
            data: familyFreq.sorted { $0.key < $1.key }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3D — V4 PaletteCluster Distribution",
            data: clusterFreq.sorted { $0.key < $1.key }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"

        report += "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3D — Family by Element Dominance\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"
        for element in ["fire", "earth", "air", "water", "balanced"] {
            guard let families = familyByElement[element] else { continue }
            let sorted = families.sorted { $0.value > $1.value }
            report += "  \(element):\n"
            for (f, c) in sorted {
                report += "    \(f.padding(toLength: 20, withPad: " ", startingAt: 0))  \(c)\n"
            }
            report += "\n"
        }

        print(report)
        CalibrationReportHelper.writeReport(prefix: "blueprint_v4_family_cluster", content: report)

        #expect(familyFreq.count > 1, "Should produce more than one PaletteFamily across 48 charts")
        #expect(clusterFreq.count > 1, "Should produce more than one PaletteCluster across 48 charts")
    }

    // MARK: - 3E (Full): Narrative Cache Key Distribution

    @Test("3E — archetype key distribution and fallback distance across all charts")
    func narrativeCacheKeyDistribution() {
        guard let dataset = BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset()
        ) else {
            Issue.record("Failed to load astrological_style_dataset.json")
            return
        }

        let narrativeCache = NarrativeCacheLoader()
        let cacheURL = StyleGuideDataURL.blueprintNarrativeCache()
        guard narrativeCache.loadFromURL(cacheURL) else {
            Issue.record("Failed to load blueprint_narrative_cache.json")
            return
        }

        var idealKeyFreq: [String: Int] = [:]
        var resolvedKeyFreq: [String: Int] = [:]
        var exactMatchCount = 0
        var fallbackCount = 0
        var fallbackDetails: [(chartId: String, ideal: String, resolved: String)] = []

        for chart in ExtendedCalibrationProfiles.allCharts {
            let analysis = ChartAnalyser.analyse(chart: chart.natalChart)
            let keyResult = ArchetypeKeyGenerator.generateKey(analysis: analysis)
            idealKeyFreq[keyResult.archetypeCluster, default: 0] += 1

            let (_, resolvedKey, usedFallback) = narrativeCache.lookup(keyResult: keyResult)
            resolvedKeyFreq[resolvedKey, default: 0] += 1

            if usedFallback {
                fallbackCount += 1
                fallbackDetails.append((chartId: chart.id, ideal: keyResult.archetypeCluster, resolved: resolvedKey))
            } else {
                exactMatchCount += 1
            }
        }

        let totalCharts = ExtendedCalibrationProfiles.allCharts.count
        let exactPct = Double(exactMatchCount) / Double(totalCharts) * 100.0

        var report = ""
        report += CalibrationReportHelper.renderHistogram(
            title: "3E — Ideal Archetype Key Distribution (n=\(totalCharts))",
            data: idealKeyFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3E — Resolved Key Distribution (after fallback)",
            data: resolvedKeyFreq.sorted { $0.value > $1.value }.map { (label: $0.key, count: $0.value) }
        )
        report += "\n"

        report += "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3E — Cache Hit Summary\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"
        report += "  Exact matches:  \(exactMatchCount)/\(totalCharts) (\(String(format: "%.1f", exactPct))%)\n"
        report += "  Fallbacks:      \(fallbackCount)/\(totalCharts)\n"
        report += "  Unique ideal keys: \(idealKeyFreq.count)\n"
        report += "  Unique resolved keys: \(resolvedKeyFreq.count)\n"
        report += "  Cache cluster count: \(narrativeCache.clusterCount)\n\n"

        if !fallbackDetails.isEmpty {
            report += "  Fallback details:\n"
            for d in fallbackDetails {
                report += "    \(d.chartId): \(d.ideal) → \(d.resolved)\n"
            }
        }

        print(report)
        CalibrationReportHelper.writeReport(prefix: "blueprint_narrative_cache_distribution", content: report)

        #expect(exactMatchCount + fallbackCount == totalCharts)
    }

    // MARK: - Combined Report

    @Test("Generate blueprint distribution report")
    func generateCombinedReport() {
        let sets = allTokenSets()

        var report = """
        ╔══════════════════════════════════════════════════════════════
        ║  BLUEPRINT DISTRIBUTION REPORT
        ║  Charts: \(sets.count)
        ║  Generated: \(Date())
        ╚══════════════════════════════════════════════════════════════

        """

        // --- 3B: Token Weight Distribution ---
        var countByType: [String: Int] = [:]
        var weightByType: [String: Double] = [:]
        var allWeights: [Double] = []

        for (_, tokens) in sets {
            for token in tokens {
                countByType[token.type, default: 0] += 1
                weightByType[token.type, default: 0.0] += token.weight
                allWeights.append(token.weight)
            }
        }

        let sortedTypes = countByType.keys.sorted()

        report += CalibrationReportHelper.renderHistogram(
            title: "3B — Token Count by Type",
            data: sortedTypes.map { (label: $0, count: countByType[$0]!) }
        )
        report += "\n"
        report += CalibrationReportHelper.renderHistogram(
            title: "3B — Total Weight by Type",
            data: sortedTypes.map { (label: $0, count: Int(weightByType[$0]!)) }
        )
        report += "\n"
        report += CalibrationReportHelper.summaryStats(label: "All token weights", values: allWeights)
        report += "\n"
        for typeName in sortedTypes {
            let weights = sets.flatMap { $0.tokens.filter { $0.type == typeName }.map(\.weight) }
            report += CalibrationReportHelper.summaryStats(label: typeName, values: weights)
            report += "\n"
        }
        report += "\n"

        // --- 3C: Resolver Output Distribution ---
        let targetTypes: Set<String> = ["textile", "texture", "pattern", "accessory"]
        var nameFrequency: [String: Int] = [:]
        for (_, tokens) in sets {
            for token in tokens where targetTypes.contains(token.type) {
                nameFrequency[token.name, default: 0] += 1
            }
        }
        let sortedNames = nameFrequency.sorted { $0.value > $1.value }
        report += CalibrationReportHelper.renderHistogram(
            title: "3C — Material/Pattern/Accessory Token Frequency (top 30)",
            data: Array(sortedNames.prefix(30).map { (label: $0.key, count: $0.value) })
        )
        report += "\n"

        // --- 3D: Element vs Colour Token Correlation ---
        let colourTypes: Set<String> = ["colour", "colour_quality"]
        var coloursByElement: [String: [String]] = [:]
        for (chart, tokens) in sets {
            let names = tokens.filter { colourTypes.contains($0.type) }.map(\.name)
            coloursByElement[chart.elementDominance, default: []].append(contentsOf: names)
        }

        let warmKeywords: Set<String> = [
            "warm", "gold", "amber", "red", "orange", "crimson", "scarlet",
            "copper", "rust", "flame", "terracotta", "coral", "sunny", "fire",
            "golden", "burnished", "bronze", "saffron"
        ]
        let coolKeywords: Set<String> = [
            "cool", "blue", "aqua", "teal", "silver", "ice", "ocean",
            "navy", "slate", "steel", "cerulean", "frost", "water",
            "marine", "sapphire", "midnight", "indigo"
        ]

        report += "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3D — Element vs Colour Token Correlation\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"

        for element in ["fire", "earth", "air", "water", "balanced"] {
            let names = coloursByElement[element] ?? []
            guard !names.isEmpty else {
                report += "  \(element): no colour tokens\n"
                continue
            }
            let warmCount = names.filter { n in warmKeywords.contains(where: { n.lowercased().contains($0) }) }.count
            let coolCount = names.filter { n in coolKeywords.contains(where: { n.lowercased().contains($0) }) }.count
            let neutralCount = names.count - warmCount - coolCount
            report += "  \(element.padding(toLength: 10, withPad: " ", startingAt: 0))  "
            report += "total=\(String(format: "%3d", names.count))  "
            report += "warm=\(String(format: "%3d", warmCount))  "
            report += "cool=\(String(format: "%3d", coolCount))  "
            report += "neutral=\(String(format: "%3d", neutralCount))\n"
        }
        report += "\n"

        // --- 3E: Token Type Coverage ---
        let allFoundTypes = Set(sets.flatMap { $0.tokens.map(\.type) })
        report += "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3E — Token Type Coverage\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"
        report += "  All types found: \(allFoundTypes.sorted().joined(separator: ", "))\n\n"

        let requiredGroups: [(String, Set<String>)] = [
            ("texture/textile", ["texture", "textile"]),
            ("colour/colour_quality", ["colour", "colour_quality"]),
            ("expression", ["expression"]),
            ("mood", ["mood"]),
            ("structure", ["structure"]),
            ("pattern", ["pattern"]),
            ("accessory", ["accessory"]),
        ]
        for (name, alts) in requiredGroups {
            let found = !alts.isDisjoint(with: allFoundTypes)
            report += "  \(name.padding(toLength: 25, withPad: " ", startingAt: 0))  \(found ? "PASS" : "FAIL")  "
            report += "matched: \(alts.intersection(allFoundTypes).sorted().joined(separator: ", "))\n"
        }
        report += "\n"

        // --- Per-chart summary ---
        report += "╔══════════════════════════════════════════════════════════════\n"
        report += "║  Per-Chart Token Summary\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"

        for (chart, tokens) in sets {
            let typeBreakdown = Dictionary(grouping: tokens, by: \.type).mapValues(\.count)
            let totalWeight = tokens.reduce(0.0) { $0 + $1.weight }
            report += "  \(chart.id.padding(toLength: 28, withPad: " ", startingAt: 0))  "
            report += "tokens=\(String(format: "%3d", tokens.count))  "
            report += "weight=\(String(format: "%7.1f", totalWeight))  "
            report += "types=\(typeBreakdown.sorted(by: { $0.key < $1.key }).map { "\($0.key):\($0.value)" }.joined(separator: " "))\n"
        }

        let url = CalibrationReportHelper.writeReport(prefix: "blueprint_distribution", content: report)
        if let url {
            print("📊 Report written to: \(url.path)")
        }
        #expect(url != nil, "Report should be written to disk")
    }

    // MARK: - 3A: Real Ephemeris Chart Computation + Manifest Auto-Generation

    @Test("3A — compute charts from birth specs and generate manifest")
    func realEphemerisManifestGeneration() {
        let ephemerisCharts = ExtendedCalibrationProfiles.allChartsWithEphemeris
        guard ephemerisCharts.first?.source == .ephemeris else {
            print("⚠️ Production ephemeris not available — skipping manifest generation")
            return
        }

        var manifest: [[String: Any]] = []
        var coverageSummary: [String: Any] = [:]
        var sunSignCounts: [Int: Int] = [:]
        var risingSignCounts: [Int: Int] = [:]
        var elementCounts: [String: Int] = [:]
        var sectCounts: [String: Int] = [:]
        var stelliumCount = 0
        var venusConditionCounts: [String: Int] = [:]

        for chart in ephemerisCharts {
            var entry: [String: Any] = [
                "id": chart.id,
                "label": chart.label,
                "sunSign": chart.sunSign,
                "moonSign": chart.moonSign,
                "risingSign": chart.risingSign,
                "elementDominance": chart.elementDominance,
                "sect": chart.sect,
                "hasStellium": chart.hasStellium,
                "venusCondition": chart.venusCondition,
                "source": chart.source.rawValue
            ]

            let analysis = ChartAnalyser.analyse(chart: chart.natalChart)
            entry["chartRuler"] = analysis.chartRuler
            entry["dominantPlanets"] = analysis.dominantPlanets
            entry["aspectCount"] = analysis.significantAspects.count

            manifest.append(entry)

            sunSignCounts[chart.sunSign, default: 0] += 1
            risingSignCounts[chart.risingSign, default: 0] += 1
            elementCounts[chart.elementDominance, default: 0] += 1
            sectCounts[chart.sect, default: 0] += 1
            if chart.hasStellium { stelliumCount += 1 }
            venusConditionCounts[chart.venusCondition, default: 0] += 1
        }

        coverageSummary["sunSigns"] = sunSignCounts
        coverageSummary["risingSigns"] = risingSignCounts
        coverageSummary["elementDominance"] = elementCounts
        coverageSummary["sect"] = sectCounts
        coverageSummary["stelliumCharts"] = stelliumCount
        coverageSummary["venusCondition"] = venusConditionCounts

        var report = "╔══════════════════════════════════════════════════════════════\n"
        report += "║  3A — Real Ephemeris Manifest (auto-generated)\n"
        report += "║  Charts: \(ephemerisCharts.count)\n"
        report += "║  Source: blueprint_birth_specs.json → NatalChartCalculator\n"
        report += "╚══════════════════════════════════════════════════════════════\n\n"

        report += "Coverage:\n"
        report += "  Sun signs represented: \(sunSignCounts.keys.sorted().count)/12\n"
        report += "  Rising signs represented: \(risingSignCounts.keys.sorted().count)/12\n"
        report += "  Element dominance: \(elementCounts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "  "))\n"
        report += "  Sect: \(sectCounts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "  "))\n"
        report += "  Stellium charts: \(stelliumCount)\n"
        report += "  Venus condition: \(venusConditionCounts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "  "))\n\n"

        report += "Per-chart details:\n"
        for chart in ephemerisCharts {
            let analysis = ChartAnalyser.analyse(chart: chart.natalChart)
            let signs = chart.signs.map(String.init).joined(separator: ",")
            report += "  \(chart.id.padding(toLength: 25, withPad: " ", startingAt: 0))  "
            report += "☉=\(chart.sunSign) ☽=\(chart.moonSign) ASC=\(chart.risingSign)  "
            report += "\(chart.elementDominance.padding(toLength: 9, withPad: " ", startingAt: 0))  "
            report += "\(chart.sect.padding(toLength: 5, withPad: " ", startingAt: 0))  "
            report += "ruler=\(analysis.chartRuler)  "
            report += "signs=[\(signs)]\n"
        }

        CalibrationReportHelper.writeReport(prefix: "blueprint_ephemeris_manifest", content: report)

        #expect(sunSignCounts.keys.count >= 10, "Should have at least 10 Sun signs represented")
        #expect(ephemerisCharts.count >= 50, "Should have at least 50 computed charts")
    }
}
