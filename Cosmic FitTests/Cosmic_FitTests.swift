//
//  Cosmic_FitTests.swift
//  Cosmic FitTests
//
//  Created by Ashley Davison on 04/05/2025.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - WP2 Blueprint Contract Validation

struct BlueprintModelTests {

    // MARK: - Fixture Loading

    private static func fixturesURL() -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile
            .deletingLastPathComponent()  // Cosmic FitTests/
            .deletingLastPathComponent()  // repo root
        return repoRoot
            .appendingPathComponent("docs")
            .appendingPathComponent("fixtures")
    }

    private static func loadFixture(_ filename: String) throws -> Data {
        let url = fixturesURL().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("""
                Fixture not found at \(url.path).
                Tests load fixtures via #filePath-relative path from the source tree.
                Ensure the repo checkout contains docs/fixtures/\(filename).
                """)
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    // MARK: - Round-Trip Tests

    @Test("Fixture round-trip: Ash (User 1)")
    func roundTripUser1() throws {
        let data = try Self.loadFixture("blueprint_input_user_1.json")
        let decoded = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)
        let reEncoded = try Self.makeEncoder().encode(decoded)
        let reDecoded = try Self.makeDecoder().decode(CosmicBlueprint.self, from: reEncoded)

        #expect(decoded == reDecoded)
    }

    @Test("Fixture round-trip: Maria (User 2)")
    func roundTripUser2() throws {
        let data = try Self.loadFixture("blueprint_input_user_2.json")
        let decoded = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)
        let reEncoded = try Self.makeEncoder().encode(decoded)
        let reDecoded = try Self.makeDecoder().decode(CosmicBlueprint.self, from: reEncoded)

        #expect(decoded == reDecoded)
    }

    // MARK: - Shape Completeness (User 1 — Ash)

    @Test("Shape completeness: Ash — all sections populated")
    func shapeCompletenessUser1() throws {
        let data = try Self.loadFixture("blueprint_input_user_1.json")
        let bp = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)

        #expect(!bp.styleCore.narrativeText.isEmpty)
        #expect(!bp.textures.goodText.isEmpty)
        #expect(!bp.textures.badText.isEmpty)
        #expect(!bp.textures.sweetSpotText.isEmpty)
        #expect(bp.palette.coreColours.count >= 3)
        #expect(bp.palette.accentColours.count >= 2)
        #expect(!bp.palette.narrativeText.isEmpty)
        #expect(!bp.occasions.workText.isEmpty)
        #expect(!bp.occasions.intimateText.isEmpty)
        #expect(!bp.occasions.dailyText.isEmpty)
        #expect(!bp.hardware.metalsText.isEmpty)
        #expect(!bp.hardware.stonesText.isEmpty)
        #expect(!bp.hardware.tipText.isEmpty)
        #expect(bp.hardware.recommendedMetals.count >= 2)
        #expect(bp.hardware.recommendedStones.count >= 2)
        #expect(bp.code.leanInto.count >= 3)
        #expect(bp.code.avoid.count >= 3)
        #expect(bp.code.consider.count >= 3)
        #expect(bp.accessory.paragraphs.count == 3)
        #expect(!bp.pattern.narrativeText.isEmpty)
        #expect(!bp.pattern.tipText.isEmpty)
        #expect(bp.pattern.recommendedPatterns.count >= 2)
        #expect(bp.pattern.avoidPatterns.count >= 2)
        #expect(!bp.engineVersion.isEmpty)
        #expect(!bp.userInfo.birthLocation.isEmpty)
    }

    // MARK: - Shape Completeness (User 2 — Maria)

    @Test("Shape completeness: Maria — all sections populated")
    func shapeCompletenessUser2() throws {
        let data = try Self.loadFixture("blueprint_input_user_2.json")
        let bp = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)

        #expect(!bp.styleCore.narrativeText.isEmpty)
        #expect(!bp.textures.goodText.isEmpty)
        #expect(!bp.textures.badText.isEmpty)
        #expect(!bp.textures.sweetSpotText.isEmpty)
        #expect(bp.palette.coreColours.count >= 3)
        #expect(bp.palette.accentColours.count >= 2)
        #expect(!bp.palette.narrativeText.isEmpty)
        #expect(!bp.occasions.workText.isEmpty)
        #expect(!bp.occasions.intimateText.isEmpty)
        #expect(!bp.occasions.dailyText.isEmpty)
        #expect(!bp.hardware.metalsText.isEmpty)
        #expect(!bp.hardware.stonesText.isEmpty)
        #expect(!bp.hardware.tipText.isEmpty)
        #expect(bp.hardware.recommendedMetals.count >= 2)
        #expect(bp.hardware.recommendedStones.count >= 2)
        #expect(bp.code.leanInto.count >= 3)
        #expect(bp.code.avoid.count >= 3)
        #expect(bp.code.consider.count >= 3)
        #expect(bp.accessory.paragraphs.count == 3)
        #expect(!bp.pattern.narrativeText.isEmpty)
        #expect(!bp.pattern.tipText.isEmpty)
        #expect(bp.pattern.recommendedPatterns.count >= 2)
        #expect(bp.pattern.avoidPatterns.count >= 2)
        #expect(!bp.engineVersion.isEmpty)
    }

    // MARK: - No Silent Empty Fields

    @Test("No silent empty strings in Ash fixture")
    func noEmptyStringsUser1() throws {
        let data = try Self.loadFixture("blueprint_input_user_1.json")
        let bp = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)

        for colour in bp.palette.coreColours + bp.palette.accentColours {
            #expect(!colour.name.isEmpty, "Colour name must not be empty")
            #expect(!colour.hexValue.isEmpty, "Colour hexValue must not be empty")
        }
        for directive in bp.code.leanInto + bp.code.avoid + bp.code.consider {
            #expect(!directive.isEmpty, "Code directive must not be empty")
        }
        for paragraph in bp.accessory.paragraphs {
            #expect(!paragraph.isEmpty, "Accessory paragraph must not be empty")
        }
        for metal in bp.hardware.recommendedMetals {
            #expect(!metal.isEmpty, "Recommended metal must not be empty")
        }
        for stone in bp.hardware.recommendedStones {
            #expect(!stone.isEmpty, "Recommended stone must not be empty")
        }
        for p in bp.pattern.recommendedPatterns + bp.pattern.avoidPatterns {
            #expect(!p.isEmpty, "Pattern entry must not be empty")
        }
    }

    @Test("No silent empty strings in Maria fixture")
    func noEmptyStringsUser2() throws {
        let data = try Self.loadFixture("blueprint_input_user_2.json")
        let bp = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)

        for colour in bp.palette.coreColours + bp.palette.accentColours {
            #expect(!colour.name.isEmpty, "Colour name must not be empty")
            #expect(!colour.hexValue.isEmpty, "Colour hexValue must not be empty")
        }
        for directive in bp.code.leanInto + bp.code.avoid + bp.code.consider {
            #expect(!directive.isEmpty, "Code directive must not be empty")
        }
        for paragraph in bp.accessory.paragraphs {
            #expect(!paragraph.isEmpty, "Accessory paragraph must not be empty")
        }
        for metal in bp.hardware.recommendedMetals {
            #expect(!metal.isEmpty, "Recommended metal must not be empty")
        }
        for stone in bp.hardware.recommendedStones {
            #expect(!stone.isEmpty, "Recommended stone must not be empty")
        }
        for p in bp.pattern.recommendedPatterns + bp.pattern.avoidPatterns {
            #expect(!p.isEmpty, "Pattern entry must not be empty")
        }
    }

    // MARK: - Hex Value Format Validation

    @Test("All colour hex values are valid 6-digit hex")
    func hexValueFormat() throws {
        let hexPattern = /^#[0-9A-Fa-f]{6}$/

        for fixture in ["blueprint_input_user_1.json", "blueprint_input_user_2.json"] {
            let data = try Self.loadFixture(fixture)
            let bp = try Self.makeDecoder().decode(CosmicBlueprint.self, from: data)

            for colour in bp.palette.coreColours + bp.palette.accentColours {
                #expect(colour.hexValue.wholeMatch(of: hexPattern) != nil,
                        "Invalid hex in \(fixture): \(colour.hexValue)")
            }
        }
    }

    // MARK: - BlueprintSection Canonical Key Assertions

    @Test("BlueprintSection has exactly 16 cases with snake_case raw values")
    func blueprintSectionCanonicalKeys() {
        let allCases = BlueprintArchetypeKey.BlueprintSection.allCases
        #expect(allCases.count == 16)

        let snakeCasePattern = /^[a-z][a-z0-9]*(_[a-z0-9]+)*$/
        for section in allCases {
            #expect(section.rawValue.wholeMatch(of: snakeCasePattern) != nil,
                    "BlueprintSection raw value must be snake_case: \(section.rawValue)")
        }
    }

    @Test("BlueprintSection raw values match expected canonical set")
    func blueprintSectionExpectedValues() {
        let expected: Set<String> = [
            "style_core",
            "textures_good", "textures_bad", "textures_sweet_spot",
            "palette_narrative",
            "occasions_work", "occasions_intimate", "occasions_daily",
            "hardware_metals", "hardware_stones", "hardware_tip",
            "accessory_1", "accessory_2", "accessory_3",
            "pattern_narrative", "pattern_tip"
        ]
        let actual = Set(BlueprintArchetypeKey.BlueprintSection.allCases.map(\.rawValue))
        #expect(actual == expected)
    }

    // MARK: - TokenCategory Assertions

    @Test("TokenCategory has exactly 10 cases with lowercase single-word raw values")
    func tokenCategoryCoverage() {
        let allCases = BlueprintToken.TokenCategory.allCases
        #expect(allCases.count == 10)

        let singleWordPattern = /^[a-z]+$/
        for category in allCases {
            #expect(category.rawValue.wholeMatch(of: singleWordPattern) != nil,
                    "TokenCategory raw value must be lowercase single word: \(category.rawValue)")
        }
    }

    @Test("TokenCategory raw values match expected canonical set")
    func tokenCategoryExpectedValues() {
        let expected: Set<String> = [
            "texture", "colour", "silhouette", "metal", "stone",
            "pattern", "accessory", "mood", "structure", "expression"
        ]
        let actual = Set(BlueprintToken.TokenCategory.allCases.map(\.rawValue))
        #expect(actual == expected)
    }

    // MARK: - ColourRole Assertions

    @Test("ColourRole has exactly 3 cases")
    func colourRoleCoverage() {
        let allCases = ColourRole.allCases
        #expect(allCases.count == 3)
        let expected: Set<String> = ["core", "accent", "statement"]
        let actual = Set(allCases.map(\.rawValue))
        #expect(actual == expected)
    }

    // MARK: - BlueprintToken Round-Trip

    @Test("BlueprintToken encode/decode round-trip")
    func tokenRoundTrip() throws {
        let token = BlueprintToken(
            name: "midnight",
            category: .colour,
            weight: 0.85,
            planetarySource: "Venus",
            signSource: "Scorpio",
            houseSource: 8,
            aspectSource: "Venus square Saturn"
        )

        let data = try Self.makeEncoder().encode(token)
        let decoded = try Self.makeDecoder().decode(BlueprintToken.self, from: data)

        #expect(decoded == token)
    }

    // MARK: - BlueprintArchetypeKey Round-Trip

    @Test("BlueprintArchetypeKey encode/decode round-trip")
    func archetypeKeyRoundTrip() throws {
        let key = BlueprintArchetypeKey(
            section: .styleCore,
            archetypeCluster: "venus_scorpio__moon_capricorn__fire_dominant",
            variant: 0
        )

        let data = try Self.makeEncoder().encode(key)
        let decoded = try Self.makeDecoder().decode(BlueprintArchetypeKey.self, from: data)

        #expect(decoded == key)
    }
}

// MARK: - WP3 Engine Tests

struct WP3EngineTests {

    // MARK: - ChartAnalyser

    @Test("ChartAnalyser.signName converts longitude to sign name")
    func signNameFromLongitude() {
        #expect(ChartAnalyser.signName(for: 0.0) == "Aries")
        #expect(ChartAnalyser.signName(for: 45.0) == "Taurus")
        #expect(ChartAnalyser.signName(for: 90.0) == "Cancer")
        #expect(ChartAnalyser.signName(for: 180.0) == "Libra")
        #expect(ChartAnalyser.signName(for: 270.0) == "Capricorn")
        #expect(ChartAnalyser.signName(for: 330.0) == "Pisces")
    }

    @Test("ChartAnalyser.resolveChartRuler returns correct traditional rulers")
    func chartRulerResolution() {
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Aries") == "Mars")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Taurus") == "Venus")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Cancer") == "Moon")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Leo") == "Sun")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Scorpio") == "Mars")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Capricorn") == "Saturn")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Aquarius") == "Saturn")
        #expect(ChartAnalyser.resolveChartRuler(ascendantSign: "Pisces") == "Jupiter")
    }

    // MARK: - ArchetypeKeyGenerator

    @Test("ArchetypeKeyGenerator key format is venus__moon__element")
    func archetypeKeyFormat() {
        let analysis = makeStubAnalysis(
            venusSign: "Scorpio", moonSign: "Capricorn",
            dominantElement: "fire"
        )
        let result = ArchetypeKeyGenerator.generateKey(analysis: analysis)
        #expect(result.archetypeCluster == "venus_scorpio__moon_capricorn__fire_dominant")
        #expect(result.venusComponent == "venus_scorpio")
        #expect(result.moonComponent == "moon_capricorn")
        #expect(result.elementComponent == "fire_dominant")
    }

    @Test("ArchetypeKeyGenerator exact match does not use fallback")
    func archetypeExactMatch() {
        let analysis = makeStubAnalysis(
            venusSign: "Taurus", moonSign: "Cancer",
            dominantElement: "earth"
        )
        let keyResult = ArchetypeKeyGenerator.generateKey(analysis: analysis)
        let keys: Set<String> = ["venus_taurus__moon_cancer__earth_dominant"]
        let (resolved, usedFallback, _) = ArchetypeKeyGenerator.resolveKey(
            idealResult: keyResult, availableKeys: keys
        )
        #expect(resolved == "venus_taurus__moon_cancer__earth_dominant")
        #expect(!usedFallback)
    }

    @Test("ArchetypeKeyGenerator fallback prefers Venus match")
    func archetypeFallbackPrefersVenus() {
        let analysis = makeStubAnalysis(
            venusSign: "Leo", moonSign: "Aquarius",
            dominantElement: "fire"
        )
        let keyResult = ArchetypeKeyGenerator.generateKey(analysis: analysis)
        let keys: Set<String> = [
            "venus_leo__moon_cancer__fire_dominant",
            "venus_aries__moon_aquarius__fire_dominant",
        ]
        let (resolved, usedFallback, _) = ArchetypeKeyGenerator.resolveKey(
            idealResult: keyResult, availableKeys: keys
        )
        #expect(usedFallback)
        #expect(resolved == "venus_leo__moon_cancer__fire_dominant")
    }

    @Test("ArchetypeKeyGenerator sign-affinity sub-scoring")
    func archetypeSignAffinity() {
        let analysis = makeStubAnalysis(
            venusSign: "Gemini", moonSign: "Gemini",
            dominantElement: "air"
        )
        let keyResult = ArchetypeKeyGenerator.generateKey(analysis: analysis)
        let keys: Set<String> = [
            "venus_libra__moon_aquarius__air_dominant",
            "venus_cancer__moon_scorpio__water_dominant",
        ]
        let (resolved, usedFallback, _) = ArchetypeKeyGenerator.resolveKey(
            idealResult: keyResult, availableKeys: keys
        )
        #expect(usedFallback)
        #expect(resolved == "venus_libra__moon_aquarius__air_dominant")
    }

    @Test("ArchetypeKeyGenerator representative clusters returns ≥ 48 keys")
    func representativeClusterCount() {
        let keys = ArchetypeKeyGenerator.enumerateRepresentativeClusterKeys()
        #expect(keys.count >= 48)
        for key in keys {
            #expect(key.contains("__"))
            #expect(key.hasPrefix("venus_"))
            #expect(key.hasSuffix("_dominant"))
        }
    }

    // MARK: - Token Normalisation

    @Test("Token normalisation produces 0.0–1.0 range with max at 1.0")
    func tokenNormalisation() {
        let tokens = [
            BlueprintToken(name: "a", category: .colour, weight: 2.0,
                           planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: nil),
            BlueprintToken(name: "b", category: .colour, weight: 1.0,
                           planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: nil),
            BlueprintToken(name: "c", category: .texture, weight: 3.0,
                           planetarySource: nil, signSource: nil, houseSource: nil, aspectSource: nil),
        ]

        let normalised = BlueprintTokenGenerator.normaliseTokens(tokens)
        let colourWeights = normalised.filter { $0.category == .colour }.map(\.weight)
        let textureWeights = normalised.filter { $0.category == .texture }.map(\.weight)

        #expect(colourWeights.contains(1.0))
        #expect(colourWeights.contains(0.5))
        #expect(textureWeights.contains(1.0))

        for token in normalised {
            #expect(token.weight >= 0.0 && token.weight <= 1.0)
        }
    }

    // MARK: - NarrativeCacheLoader

    @Test("NarrativeCacheLoader returns all 16 section keys for injected entry")
    func narrativeCacheInjection() {
        let loader = NarrativeCacheLoader()
        var entry: NarrativeClusterEntry = [:]
        for section in BlueprintArchetypeKey.BlueprintSection.allCases {
            entry[section.rawValue] = "Test paragraph for \(section.rawValue)"
        }
        loader.injectCache(["venus_aries__moon_aries__fire_dominant": entry])

        let keyResult = ArchetypeKeyGenerator.KeyGenerationResult(
            archetypeCluster: "venus_aries__moon_aries__fire_dominant",
            venusComponent: "venus_aries",
            moonComponent: "moon_aries",
            elementComponent: "fire_dominant",
            usedFallback: false,
            fallbackLog: nil
        )

        let (result, resolvedKey, usedFallback) = loader.lookup(keyResult: keyResult)
        #expect(!usedFallback)
        #expect(resolvedKey == "venus_aries__moon_aries__fire_dominant")
        #expect(result.count == 16)
        for section in BlueprintArchetypeKey.BlueprintSection.allCases {
            #expect(!result[section.rawValue]!.isEmpty)
        }
    }

    @Test("NarrativeCacheLoader returns empty entry for missing cache")
    func narrativeCacheMiss() {
        let loader = NarrativeCacheLoader()
        let keyResult = ArchetypeKeyGenerator.KeyGenerationResult(
            archetypeCluster: "venus_aries__moon_aries__fire_dominant",
            venusComponent: "venus_aries",
            moonComponent: "moon_aries",
            elementComponent: "fire_dominant",
            usedFallback: false,
            fallbackLog: nil
        )
        let (result, _, usedFallback) = loader.lookup(keyResult: keyResult)
        #expect(usedFallback)
        #expect(result.count == 16)
    }

    // MARK: - Helpers

    private func makeStubAnalysis(
        venusSign: String,
        moonSign: String,
        dominantElement: String,
        planetHouses: [String: Int] = [:],
        chartSect: ChartSect = .day,
        chartRuler: String = "Venus"
    ) -> ChartAnalysis {
        let elementCounts: (Int, Int, Int, Int) = {
            switch dominantElement {
            case "fire":  return (5, 1, 1, 1)
            case "earth": return (1, 5, 1, 1)
            case "air":   return (1, 1, 5, 1)
            case "water": return (1, 1, 1, 5)
            default:      return (2, 2, 2, 2)
            }
        }()

        let sectStatus = ChartAnalyser.computePlanetSectStatus(chartSect: chartSect)

        var houseScores: [Int: Double] = [:]
        for h in 1...12 { houseScores[h] = 0.0 }
        for (_, house) in planetHouses { houseScores[house, default: 0] += 0.5 }

        let dominantHouses = houseScores
            .sorted { a, b in a.value != b.value ? a.value > b.value : a.key < b.key }
            .prefix(3).map(\.key)

        let venusHouse = planetHouses["Venus"] ?? 1
        let moonHouse = planetHouses["Moon"] ?? 1

        return ChartAnalysis(
            elementBalance: ElementBalance(
                fire: elementCounts.0, earth: elementCounts.1,
                air: elementCounts.2, water: elementCounts.3
            ),
            modalityBalance: ModalityBalance(cardinal: 3, fixed: 3, mutable: 2),
            chartRuler: chartRuler,
            sunSign: "Sagittarius",
            moonSign: moonSign,
            ascendantSign: "Libra",
            venusSign: venusSign,
            marsSign: "Aries",
            planetSigns: [
                "Sun": "Sagittarius", "Moon": moonSign,
                "Venus": venusSign, "Mars": "Aries",
                "Mercury": "Sagittarius", "Jupiter": "Capricorn",
                "Saturn": "Scorpio"
            ],
            planetDignities: [:],
            planetHouses: planetHouses,
            significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Sun"],
            chartSect: chartSect,
            planetSectStatus: sectStatus,
            houseEmphasis: HouseEmphasis(
                houseScores: houseScores,
                dominantHouses: Array(dominantHouses),
                venusHouseDomain: ChartAnalyser.houseDomainLabels[venusHouse] ?? "identity",
                moonHouseDomain: ChartAnalyser.houseDomainLabels[moonHouse] ?? "identity"
            )
        )
    }
}

// MARK: - Phase 8: House & Sect Integration Tests

struct HouseSectIntegrationTests {

    // MARK: - 8a. Sect Computation

    @Test("Day chart: Sun above horizon (between Desc and Asc)")
    func dayChartSunAboveHorizon() {
        let asc = 180.0
        let sunLong = 90.0
        let sect = ChartAnalyser.computeSect(sunLongitude: sunLong, ascendantLongitude: asc)
        #expect(sect == .day)
    }

    @Test("Night chart: Sun below horizon")
    func nightChartSunBelowHorizon() {
        let asc = 180.0
        let sunLong = 270.0
        let sect = ChartAnalyser.computeSect(sunLongitude: sunLong, ascendantLongitude: asc)
        #expect(sect == .night)
    }

    @Test("Boundary: Sun exactly on Ascendant → night chart")
    func sunOnAscendantBoundary() {
        let asc = 100.0
        let sect = ChartAnalyser.computeSect(sunLongitude: asc, ascendantLongitude: asc)
        #expect(sect == .night)
    }

    @Test("Boundary: Sun exactly on Descendant → day chart")
    func sunOnDescendantBoundary() {
        let asc = 100.0
        let desc = 280.0
        let sect = ChartAnalyser.computeSect(sunLongitude: desc, ascendantLongitude: asc)
        #expect(sect == .day)
    }

    @Test("Planet sect status mapping for day chart")
    func daySectStatusMapping() {
        let status = ChartAnalyser.computePlanetSectStatus(chartSect: .day)
        #expect(status["Sun"] == .sectLight)
        #expect(status["Moon"] == .contraryLuminary)
        #expect(status["Jupiter"] == .beneficOfSect)
        #expect(status["Venus"] == .contraryBenefic)
        #expect(status["Saturn"] == .maleficOfSect)
        #expect(status["Mars"] == .contraryMalefic)
        #expect(status["Mercury"] == .neutral)
    }

    @Test("Planet sect status mapping for night chart")
    func nightSectStatusMapping() {
        let status = ChartAnalyser.computePlanetSectStatus(chartSect: .night)
        #expect(status["Sun"] == .contraryLuminary)
        #expect(status["Moon"] == .sectLight)
        #expect(status["Jupiter"] == .contraryBenefic)
        #expect(status["Venus"] == .beneficOfSect)
        #expect(status["Saturn"] == .contraryMalefic)
        #expect(status["Mars"] == .maleficOfSect)
    }

    // MARK: - 8b. House Emphasis

    @Test("House emphasis: domain labels for Venus and Moon")
    func houseDomainLabels() {
        #expect(ChartAnalyser.houseDomainLabel(for: 1) == "identity")
        #expect(ChartAnalyser.houseDomainLabel(for: 5) == "creativity")
        #expect(ChartAnalyser.houseDomainLabel(for: 10) == "public")
        #expect(ChartAnalyser.houseDomainLabel(for: 12) == "retreat")
    }

    // MARK: - 8c. Token Weighting (two-track model)

    @Test("Token weight excludes house/sect; combo weight includes them")
    func twoTrackWeightingSplit() {
        let analysis = makeAnalysis(
            venusHouse: 10, moonHouse: 4, sect: .night,
            planetSigns: ["Venus": "Scorpio", "Moon": "Capricorn"],
            planetHouses: ["Venus": 10, "Moon": 4]
        )
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let result = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)

        let venusTokens = result.tokens.filter { $0.planetarySource == "Venus" }
        #expect(!venusTokens.isEmpty)

        let venusCombo = result.contributingCombos.first(where: { $0.key == "venus_scorpio" })
        #expect(venusCombo != nil)
    }

    // MARK: - 8e. Overlay Tests

    @Test("Overlay strings are jargon-free")
    func overlayJargonCheck() {
        let analysis = makeAnalysis(
            venusHouse: 10, moonHouse: 4, sect: .day,
            planetSigns: ["Venus": "Scorpio", "Moon": "Capricorn"],
            planetHouses: ["Venus": 10, "Moon": 4]
        )
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let overlays = HouseSectOverlayGenerator.generate(analysis: analysis, dataset: dataset)

        let jargonTerms = ["house", "chart", "Venus", "Moon", "Sun", "Mars",
                           "sect", "angular", "cadent", "succedent", "luminary"]

        let allOverlayTexts = [
            overlays.styleCoreAppend,
            overlays.texturesSweetSpotAppend,
            overlays.occasionsWorkAppend,
            overlays.occasionsIntimateAppend,
            overlays.occasionsDailyAppend
        ].compactMap { $0 }

        for text in allOverlayTexts {
            for term in jargonTerms {
                #expect(!text.localizedCaseInsensitiveContains(term),
                        "Overlay contains jargon term '\(term)': \(text)")
            }
        }
    }

    @Test("Day and night charts produce different overlay text")
    func sectOverlayDifference() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let dayAnalysis = makeAnalysis(
            venusHouse: 10, moonHouse: 4, sect: .day,
            planetSigns: ["Venus": "Scorpio", "Moon": "Capricorn"],
            planetHouses: ["Venus": 10, "Moon": 4]
        )
        let nightAnalysis = makeAnalysis(
            venusHouse: 10, moonHouse: 4, sect: .night,
            planetSigns: ["Venus": "Scorpio", "Moon": "Capricorn"],
            planetHouses: ["Venus": 10, "Moon": 4]
        )

        let dayOverlays = HouseSectOverlayGenerator.generate(analysis: dayAnalysis, dataset: dataset)
        let nightOverlays = HouseSectOverlayGenerator.generate(analysis: nightAnalysis, dataset: dataset)

        #expect(dayOverlays.styleCoreAppend != nightOverlays.styleCoreAppend)
    }

    @Test("Moon overlay routes to textures_sweet_spot for house 4")
    func moonOverlayRoutingTextures() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let analysis = makeAnalysis(
            venusHouse: 1, moonHouse: 4, sect: .day,
            planetSigns: ["Venus": "Aries", "Moon": "Cancer"],
            planetHouses: ["Venus": 1, "Moon": 4]
        )

        let overlays = HouseSectOverlayGenerator.generate(analysis: analysis, dataset: dataset)
        #expect(overlays.texturesSweetSpotAppend != nil)
    }

    @Test("Moon overlay routes to occasions_daily for house 1")
    func moonOverlayRoutingDaily() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let analysis = makeAnalysis(
            venusHouse: 1, moonHouse: 1, sect: .day,
            planetSigns: ["Venus": "Aries", "Moon": "Aries"],
            planetHouses: ["Venus": 1, "Moon": 1]
        )

        let overlays = HouseSectOverlayGenerator.generate(analysis: analysis, dataset: dataset)
        #expect(overlays.occasionsDailyAppend != nil)
    }

    // MARK: - 8f. Pattern Invariants and Determinism

    @Test("Pattern ordering is deterministic across 20 runs")
    func patternDeterminism() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let analysis = makeAnalysis(
            venusHouse: 10, moonHouse: 4, sect: .day,
            planetSigns: ["Venus": "Scorpio", "Moon": "Capricorn",
                          "Sun": "Sagittarius", "Mars": "Aries"],
            planetHouses: ["Venus": 10, "Moon": 4, "Sun": 9, "Mars": 1]
        )

        var previousRecommended: [String]?
        var previousAvoid: [String]?
        for _ in 0..<20 {
            let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
            let resolved = DeterministicResolver.resolve(
                tokens: tokenResult.tokens, analysis: analysis,
                dataset: dataset, contributingCombos: tokenResult.contributingCombos
            )
            if let prevRec = previousRecommended, let prevAvd = previousAvoid {
                #expect(resolved.recommendedPatterns == prevRec,
                        "Recommended pattern output is nondeterministic")
                #expect(resolved.avoidPatterns == prevAvd,
                        "Avoid pattern output is nondeterministic")
            }
            previousRecommended = resolved.recommendedPatterns
            previousAvoid = resolved.avoidPatterns
        }
    }

    // MARK: - Helpers

    private func loadTestDataset() -> AstrologicalStyleDataset? {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        let datasetURL = repoRoot.appendingPathComponent("astrological_style_dataset.json")
        return BlueprintTokenGenerator.loadDataset(from: datasetURL)
    }

    private func makeAnalysis(
        venusHouse: Int,
        moonHouse: Int,
        sect: ChartSect,
        planetSigns: [String: String],
        planetHouses: [String: Int]
    ) -> ChartAnalysis {
        let sectStatus = ChartAnalyser.computePlanetSectStatus(chartSect: sect)

        var houseScores: [Int: Double] = [:]
        for h in 1...12 { houseScores[h] = 0.0 }
        for (_, house) in planetHouses { houseScores[house, default: 0] += 0.5 }

        let dominantHouses = houseScores
            .sorted { a, b in a.value != b.value ? a.value > b.value : a.key < b.key }
            .prefix(3).map(\.key)

        return ChartAnalysis(
            elementBalance: ElementBalance(fire: 3, earth: 2, air: 2, water: 1),
            modalityBalance: ModalityBalance(cardinal: 3, fixed: 3, mutable: 2),
            chartRuler: "Venus",
            sunSign: planetSigns["Sun"] ?? "Sagittarius",
            moonSign: planetSigns["Moon"] ?? "Capricorn",
            ascendantSign: "Libra",
            venusSign: planetSigns["Venus"] ?? "Scorpio",
            marsSign: planetSigns["Mars"] ?? "Aries",
            planetSigns: planetSigns,
            planetDignities: [:],
            planetHouses: planetHouses,
            significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Sun"],
            chartSect: sect,
            planetSectStatus: sectStatus,
            houseEmphasis: HouseEmphasis(
                houseScores: houseScores,
                dominantHouses: Array(dominantHouses),
                venusHouseDomain: ChartAnalyser.houseDomainLabels[venusHouse] ?? "identity",
                moonHouseDomain: ChartAnalyser.houseDomainLabels[moonHouse] ?? "identity"
            )
        )
    }
}

// MARK: - Dataset Backward Compatibility

struct DatasetBackwardCompatibilityTests {

    @Test("Legacy house placement entries (context + modifier only) decode without failure")
    func legacyHousePlacementDecode() throws {
        let legacyJSON = """
        {
            "planet_sign": {},
            "aspects": {},
            "house_placements": {
                "venus_house_1": {
                    "context": "Venus in the 1st house",
                    "modifier": "beauty as first impression"
                }
            },
            "element_balance": {},
            "colour_library": {}
        }
        """.data(using: .utf8)!

        let dataset = try JSONDecoder().decode(AstrologicalStyleDataset.self, from: legacyJSON)
        let entry = dataset.housePlacements["venus_house_1"]
        #expect(entry != nil)
        #expect(entry?.context == "Venus in the 1st house")
        #expect(entry?.keywords == nil)
        #expect(entry?.codeConsiderBias == nil)
        #expect(entry?.leanIntoBias == nil)
        #expect(entry?.hardwareBias == nil)
    }

    @Test("Expanded house placement entries decode all fields")
    func expandedHousePlacementDecode() throws {
        let expandedJSON = """
        {
            "planet_sign": {},
            "aspects": {},
            "house_placements": {
                "venus_house_10": {
                    "context": "Venus in the 10th house",
                    "modifier": "polished, public, career",
                    "keywords": ["polished", "public-facing"],
                    "code_consider_bias": ["prioritize polished finishes"],
                    "occasion_bias": ["work", "public"],
                    "lean_into_bias": ["tailored", "elevated"],
                    "hardware_bias": {
                        "metals": ["silver", "steel"],
                        "stones": ["onyx"]
                    }
                }
            },
            "element_balance": {},
            "colour_library": {}
        }
        """.data(using: .utf8)!

        let dataset = try JSONDecoder().decode(AstrologicalStyleDataset.self, from: expandedJSON)
        let entry = dataset.housePlacements["venus_house_10"]!
        #expect(entry.keywords == ["polished", "public-facing"])
        #expect(entry.codeConsiderBias == ["prioritize polished finishes"])
        #expect(entry.occasionBias == ["work", "public"])
        #expect(entry.leanIntoBias == ["tailored", "elevated"])
        #expect(entry.hardwareBias?.metals == ["silver", "steel"])
        #expect(entry.hardwareBias?.stones == ["onyx"])
    }
}

// MARK: - Hardening Edge Case Tests

struct HardeningEdgeCaseTests {

    @Test("House emphasis: no phantom House 1 ascendant weighting")
    func noPhantomAscendantWeighting() {
        let chart = syntheticChart(
            ascendant: 5.0,
            longitudes: [
                "Sun": 75.0,      // house 3
                "Moon": 275.0,    // house 10
                "Mercury": 130.0, // house 5
                "Venus": 135.0,   // house 5
                "Mars": 190.0,    // house 7 (chart ruler)
                "Jupiter": 35.0,  // house 2
                "Saturn": 245.0,  // house 9
                "Uranus": 320.0,  // house 11
                "Neptune": 350.0, // house 12
                "Pluto": 160.0    // house 6
            ]
        )

        let analysis = ChartAnalyser.analyse(chart: chart)
        #expect((analysis.houseEmphasis.houseScores[1] ?? 0.0) == 0.0)
        #expect(!analysis.houseEmphasis.dominantHouses.contains(1))
    }

    @Test("House emphasis: chart ruler bonus applies in ruler house")
    func chartRulerBonusHousePlacement() {
        let chart = syntheticChart(
            ascendant: 5.0, // Aries rising -> Mars ruler
            longitudes: [
                "Sun": 75.0,
                "Moon": 275.0,
                "Mercury": 130.0,
                "Venus": 135.0,
                "Mars": 190.0, // house 7
                "Jupiter": 35.0,
                "Saturn": 245.0,
                "Uranus": 320.0,
                "Neptune": 350.0,
                "Pluto": 160.0
            ]
        )

        let analysis = ChartAnalyser.analyse(chart: chart)
        let house7 = analysis.houseEmphasis.houseScores[7] ?? 0.0
        // Mars base 0.7 + chart ruler bonus 0.4
        #expect(abs(house7 - 1.1) < 0.0001)
    }

    @Test("Overlay template coverage: specific domain pairs remain >= 10")
    func overlayTemplateCoverageFloor() {
        guard let dataset = loadDataset() else {
            Issue.record("Failed to load dataset")
            return
        }

        var pairCount = 0
        var nonFallbackCount = 0

        for house1 in 1...11 {
            for house2 in (house1 + 1)...12 {
                pairCount += 1
                let analysis = makeOverlayCoverageAnalysis(primaryHouse: house1, secondaryHouse: house2)
                let overlays = HouseSectOverlayGenerator.generate(analysis: analysis, dataset: dataset)
                let text = overlays.occasionsWorkAppend ?? overlays.occasionsDailyAppend ?? ""
                if text.contains("Your style energy concentrates in"), !text.contains("reflects both") {
                    nonFallbackCount += 1
                }
            }
        }

        #expect(pairCount == 66)
        #expect(nonFallbackCount >= 10)
    }

    @Test("Export input_after fixtures for house/sect regression")
    func exportInputAfterFixtures() throws {
        guard let dataset = loadDataset(), let narrativeCache = loadNarrativeCache() else {
            Issue.record("Failed to load dataset or narrative cache")
            return
        }

        let fixtures: [(id: String, birthDate: Date, birthLocation: String, chart: NatalChartCalculator.NatalChart)] = [
            (
                id: "ash",
                birthDate: Self.isoDate("1984-12-11T00:00:00Z"),
                birthLocation: "London, UK",
                chart: NatalChartCalculator.calculateNatalChart(
                    birthDate: Self.isoDate("1984-12-11T00:00:00Z"),
                    latitude: 51.5074,
                    longitude: -0.1278,
                    timeZone: TimeZone(secondsFromGMT: 0)!
                )
            ),
            (
                id: "maria",
                birthDate: Self.isoDate("1989-04-28T00:00:00Z"),
                birthLocation: "Unknown",
                chart: NatalChartCalculator.calculateNatalChart(
                    birthDate: Self.isoDate("1989-04-28T00:00:00Z"),
                    latitude: 51.5074,
                    longitude: -0.1278,
                    timeZone: TimeZone(secondsFromGMT: 0)!
                )
            ),
            (
                id: "day_chart_venus_angular",
                birthDate: Self.isoDate("1991-07-15T12:00:00Z"),
                birthLocation: "Synthetic Fixture",
                chart: syntheticChart(
                    ascendant: 15.0,
                    longitudes: [
                        "Sun": 250.0, "Moon": 45.0, "Mercury": 170.0, "Venus": 285.0,
                        "Mars": 190.0, "Jupiter": 330.0, "Saturn": 20.0, "Uranus": 80.0,
                        "Neptune": 140.0, "Pluto": 210.0
                    ]
                )
            ),
            (
                id: "night_chart_venus_cadent",
                birthDate: Self.isoDate("1993-03-21T00:00:00Z"),
                birthLocation: "Synthetic Fixture",
                chart: syntheticChart(
                    ascendant: 15.0,
                    longitudes: [
                        "Sun": 70.0, "Moon": 350.0, "Mercury": 170.0, "Venus": 80.0,
                        "Mars": 190.0, "Jupiter": 330.0, "Saturn": 20.0, "Uranus": 140.0,
                        "Neptune": 210.0, "Pluto": 280.0
                    ]
                )
            )
        ]

        let outputDir = defaultOutputDir()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        for fixture in fixtures {
            let blueprint = BlueprintComposer.compose(
                chart: fixture.chart,
                birthDate: fixture.birthDate,
                birthLocation: fixture.birthLocation,
                dataset: dataset,
                narrativeCache: narrativeCache
            )
            let data = try encoder.encode(blueprint)
            let fileURL = outputDir.appendingPathComponent("\(fixture.id).json")
            try data.write(to: fileURL, options: .atomic)
            print("[RegressionFixtureExport] Wrote \(fileURL.path)")
        }

        #expect(fixtures.count == 4)
    }

    @Test("Fixture export helper rejects empty narrative cache")
    func loadNarrativeCacheRejectsEmptyCache() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let cacheURL = tempDir.appendingPathComponent("blueprint_narrative_cache.json")
        try "{}".data(using: .utf8)!.write(to: cacheURL, options: .atomic)

        let loader = loadNarrativeCache(from: cacheURL)
        #expect(loader == nil)
    }

    private func loadDataset() -> AstrologicalStyleDataset? {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        return BlueprintTokenGenerator.loadDataset(from: repoRoot.appendingPathComponent("astrological_style_dataset.json"))
    }

    private func loadNarrativeCache(from overrideURL: URL? = nil) -> NarrativeCacheLoader? {
        let cacheURL: URL
        if let overrideURL {
            cacheURL = overrideURL
        } else {
            let testFile = URL(fileURLWithPath: #filePath)
            let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
            cacheURL = repoRoot.appendingPathComponent("blueprint_narrative_cache.json")
        }
        let loader = NarrativeCacheLoader()
        guard loader.loadFromURL(cacheURL), loader.clusterCount > 0 else { return nil }
        return loader
    }

    private func defaultOutputDir() -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile.deletingLastPathComponent().deletingLastPathComponent()
        return repoRoot
            .appendingPathComponent("docs")
            .appendingPathComponent("house_sect_regression")
            .appendingPathComponent("input_after")
    }

    private func makeOverlayCoverageAnalysis(primaryHouse: Int, secondaryHouse: Int) -> ChartAnalysis {
        let scores = Dictionary(uniqueKeysWithValues: (1...12).map { house -> (Int, Double) in
            if house == primaryHouse { return (house, 9.0) }
            if house == secondaryHouse { return (house, 8.5) }
            return (house, 1.0)
        })

        return ChartAnalysis(
            elementBalance: ElementBalance(fire: 3, earth: 2, air: 2, water: 1),
            modalityBalance: ModalityBalance(cardinal: 3, fixed: 3, mutable: 2),
            chartRuler: "Venus",
            sunSign: "Aries",
            moonSign: "Taurus",
            ascendantSign: "Aries",
            venusSign: "Libra",
            marsSign: "Capricorn",
            planetSigns: [
                "Sun": "Aries", "Moon": "Taurus", "Mercury": "Gemini",
                "Venus": "Libra", "Mars": "Capricorn", "Jupiter": "Cancer",
                "Saturn": "Aquarius"
            ],
            planetDignities: [:],
            planetHouses: ["Venus": 10, "Moon": 4, "Mars": 7],
            significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Sun"],
            chartSect: .day,
            planetSectStatus: ChartAnalyser.computePlanetSectStatus(chartSect: .day),
            houseEmphasis: HouseEmphasis(
                houseScores: scores,
                dominantHouses: [primaryHouse, secondaryHouse, 1],
                venusHouseDomain: ChartAnalyser.houseDomainLabel(for: 10) ?? "public",
                moonHouseDomain: ChartAnalyser.houseDomainLabel(for: 4) ?? "foundations"
            )
        )
    }

    private func syntheticChart(
        ascendant: Double,
        longitudes: [String: Double]
    ) -> NatalChartCalculator.NatalChart {
        let planetOrder = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                           "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

        let planets = planetOrder.map { name -> NatalChartCalculator.PlanetPosition in
            let lon = longitudes[name] ?? 0.0
            let zodiac = CoordinateTransformations.decimalDegreesToZodiac(lon)
            return NatalChartCalculator.PlanetPosition(
                name: name,
                symbol: String(name.prefix(1)),
                longitude: lon,
                latitude: 0.0,
                zodiacSign: zodiac.sign,
                zodiacPosition: zodiac.position,
                isRetrograde: false
            )
        }

        let descendant = CoordinateTransformations.normalizeAngle(ascendant + 180.0)
        let midheaven = CoordinateTransformations.normalizeAngle(ascendant + 90.0)
        let imumCoeli = CoordinateTransformations.normalizeAngle(ascendant + 270.0)
        let houseCusps = (0..<12).map { i in
            CoordinateTransformations.normalizeAngle(ascendant + Double(i) * 30.0)
        }

        return NatalChartCalculator.NatalChart(
            planets: planets,
            ascendant: ascendant,
            midheaven: midheaven,
            descendant: descendant,
            imumCoeli: imumCoeli,
            houseCusps: houseCusps,
            wholeSignHouseCusps: houseCusps,
            northNode: 0.0,
            southNode: 180.0,
            vertex: 90.0,
            partOfFortune: 120.0,
            lilith: 240.0,
            chiron: 300.0,
            lunarPhase: 180.0
        )
    }

    private static func isoDate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else {
            fatalError("Invalid ISO date literal: \(value)")
        }
        return date
    }
}

// MARK: - NarrativeTemplateRenderer Tests

struct NarrativeTemplateRendererTests {

    @Test("Placeholder substitution works for all categories")
    func placeholderSubstitutionAllCategories() {
        let template = "Wear {core_colour_1} and {accent_colour_1}. Use {metal_1} hardware with {stone_1}. Try {recommended_pattern_1}. Reach for {texture_good_1}. Avoid {texture_bad_1}. Aim for {sweet_spot_keyword_1}."
        let context: [String: String] = [
            "core_colour_1": "midnight",
            "accent_colour_1": "dusty rose",
            "metal_1": "silver",
            "stone_1": "onyx",
            "recommended_pattern_1": "pinstripe",
            "texture_good_1": "raw denim",
            "texture_bad_1": "cheap polyester",
            "sweet_spot_keyword_1": "structure",
        ]
        let result = NarrativeTemplateRenderer.render(template: template, context: context)

        #expect(result.contains("midnight"))
        #expect(result.contains("dusty rose"))
        #expect(result.contains("silver"))
        #expect(result.contains("onyx"))
        #expect(result.contains("pinstripe"))
        #expect(result.contains("raw denim"))
        #expect(result.contains("cheap polyester"))
        #expect(result.contains("structure"))
        #expect(!result.contains("{"))
        #expect(!result.contains("}"))
    }

    @Test("Unknown placeholders degrade gracefully")
    func unknownPlaceholderDegradation() {
        let template = "This has a {totally_made_up} token."
        let result = NarrativeTemplateRenderer.render(template: template, context: [:])

        #expect(!result.contains("{totally_made_up}"))
        #expect(!result.contains("{"))
    }

    @Test("Empty context replaces known placeholders with fallback")
    func emptyContextProducesCleanOutput() {
        let template = "Your colour is {core_colour_1} with {core_colour_2}."
        let result = NarrativeTemplateRenderer.render(template: template, context: [:])

        #expect(!result.contains("{"))
        #expect(!result.contains("}"))
        #expect(result.contains("a complementary choice"))
    }

    @Test("Template with no placeholders passes through unchanged")
    func noPlaceholderPassthrough() {
        let template = "This is plain prose with no slots."
        let result = NarrativeTemplateRenderer.render(template: template, context: ["core_colour_1": "midnight"])

        #expect(result == template)
    }

    @Test("buildContext maps all resolver fields correctly")
    func buildContextMapping() {
        let resolved = DeterministicResolverResult(
            coreColours: [
                BlueprintColour(name: "midnight", hexValue: "#191970", role: .core),
                BlueprintColour(name: "slate", hexValue: "#708090", role: .core),
            ],
            accentColours: [
                BlueprintColour(name: "dusty rose", hexValue: "#DCAE96", role: .accent),
            ],
            swatchFamilies: [],
            recommendedMetals: ["silver", "steel"],
            recommendedStones: ["onyx", "obsidian"],
            leanInto: [],
            avoid: [],
            consider: [],
            recommendedPatterns: ["pinstripe", "herringbone"],
            avoidPatterns: ["paisley"],
            recommendedTextures: ["raw denim", "structured wool"],
            avoidTextures: ["cheap polyester"],
            sweetSpotKeywords: ["structure"]
        )

        let ctx = NarrativeTemplateRenderer.buildContext(resolved: resolved)

        #expect(ctx["core_colour_1"] == "midnight")
        #expect(ctx["core_colour_2"] == "slate")
        #expect(ctx["accent_colour_1"] == "dusty rose")
        #expect(ctx["metal_1"] == "silver")
        #expect(ctx["metal_2"] == "steel")
        #expect(ctx["stone_1"] == "onyx")
        #expect(ctx["stone_2"] == "obsidian")
        #expect(ctx["recommended_pattern_1"] == "pinstripe")
        #expect(ctx["recommended_pattern_2"] == "herringbone")
        #expect(ctx["avoid_pattern_1"] == "paisley")
        #expect(ctx["texture_good_1"] == "raw denim")
        #expect(ctx["texture_good_2"] == "structured wool")
        #expect(ctx["texture_bad_1"] == "cheap polyester")
        #expect(ctx["sweet_spot_keyword_1"] == "structure")
    }

    @Test("Group B sections are in the groupBSections set")
    func groupBSectionSet() {
        #expect(NarrativeTemplateRenderer.groupBSections.contains("palette_narrative"))
        #expect(NarrativeTemplateRenderer.groupBSections.contains("hardware_metals"))
        #expect(NarrativeTemplateRenderer.groupBSections.contains("textures_good"))
        #expect(NarrativeTemplateRenderer.groupBSections.contains("pattern_narrative"))
        #expect(!NarrativeTemplateRenderer.groupBSections.contains("style_core"))
        #expect(!NarrativeTemplateRenderer.groupBSections.contains("occasions_work"))
        #expect(!NarrativeTemplateRenderer.groupBSections.contains("accessory_1"))
    }
}

// MARK: - BlueprintComposer Template Integration Tests

struct BlueprintComposerTemplateTests {

    @Test("Group A sections pass through without placeholder rendering")
    func groupAPassthrough() {
        let resolved = makeMinimalResolved()
        var narratives: NarrativeClusterEntry = [:]
        for section in BlueprintArchetypeKey.BlueprintSection.allCases {
            narratives[section.rawValue] = "Plain prose for \(section.rawValue)"
        }
        narratives["style_core"] = "Your style is bold and {core_colour_1} would be replaced if this were Group B."
        narratives["occasions_work"] = "Dress sharp. {metal_1} is irrelevant here."
        narratives["accessory_1"] = "One piece matters. {stone_1} should not render."

        let bp = BlueprintComposer.assemble(
            birthDate: Date(), birthLocation: "London", resolved: resolved, narratives: narratives
        )

        #expect(bp.styleCore.narrativeText.contains("{core_colour_1}"))
        #expect(bp.occasions.workText.contains("{metal_1}"))
        #expect(bp.accessory.paragraphs[0].contains("{stone_1}"))
    }

    @Test("Group B sections get placeholders rendered")
    func groupBRendering() {
        let resolved = makeMinimalResolved()
        var narratives: NarrativeClusterEntry = [:]
        for section in BlueprintArchetypeKey.BlueprintSection.allCases {
            narratives[section.rawValue] = "Test for \(section.rawValue)"
        }
        narratives["palette_narrative"] = "Your palette leads with {core_colour_1} and {accent_colour_1}."
        narratives["hardware_metals"] = "Reach for {metal_1} hardware."
        narratives["textures_good"] = "Your best texture is {texture_good_1}."

        let bp = BlueprintComposer.assemble(
            birthDate: Date(), birthLocation: "London", resolved: resolved, narratives: narratives
        )

        #expect(bp.palette.narrativeText.contains("midnight"))
        #expect(!bp.palette.narrativeText.contains("{core_colour_1}"))
        #expect(bp.hardware.metalsText.contains("silver"))
        #expect(!bp.hardware.metalsText.contains("{metal_1}"))
        #expect(bp.textures.goodText.contains("raw denim"))
        #expect(!bp.textures.goodText.contains("{texture_good_1}"))
    }

    @Test("TexturesSection includes deterministic fields")
    func texturesSectionDeterministicFields() {
        let resolved = makeMinimalResolved()
        var narratives: NarrativeClusterEntry = [:]
        for section in BlueprintArchetypeKey.BlueprintSection.allCases {
            narratives[section.rawValue] = "Test for \(section.rawValue)"
        }

        let bp = BlueprintComposer.assemble(
            birthDate: Date(), birthLocation: "London", resolved: resolved, narratives: narratives
        )

        #expect(bp.textures.recommendedTextures == ["raw denim", "structured wool"])
        #expect(bp.textures.avoidTextures == ["cheap polyester", "flimsy lace"])
        #expect(bp.textures.sweetSpotKeywords == ["structure"])
    }

    private func makeMinimalResolved() -> DeterministicResolverResult {
        DeterministicResolverResult(
            coreColours: [
                BlueprintColour(name: "midnight", hexValue: "#191970", role: .core),
                BlueprintColour(name: "slate", hexValue: "#708090", role: .core),
                BlueprintColour(name: "charcoal", hexValue: "#36454F", role: .core),
            ],
            accentColours: [
                BlueprintColour(name: "dusty rose", hexValue: "#DCAE96", role: .accent),
                BlueprintColour(name: "sage", hexValue: "#9CAF88", role: .accent),
            ],
            swatchFamilies: [],
            recommendedMetals: ["silver", "steel"],
            recommendedStones: ["onyx", "obsidian"],
            leanInto: ["structured", "minimal"],
            avoid: ["fussy", "ornate"],
            consider: ["layered"],
            recommendedPatterns: ["pinstripe", "herringbone"],
            avoidPatterns: ["paisley"],
            recommendedTextures: ["raw denim", "structured wool"],
            avoidTextures: ["cheap polyester", "flimsy lace"],
            sweetSpotKeywords: ["structure"]
        )
    }
}

