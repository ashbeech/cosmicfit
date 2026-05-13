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

    private static func loadFixture(_ filename: String) throws -> Data {
        guard let url = FixtureLocator.fixtureURL(named: filename) else {
            Issue.record("""
                Fixture not found: \(filename).
                Tests load fixtures via #filePath-relative path from the source tree.
                Checked: docs/fixtures/\(filename) and docs/archive/fixtures/\(filename).
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

    @Test("ColourRole has exactly 6 cases (V4.3: +anchor)")
    func colourRoleCoverage() {
        let allCases = ColourRole.allCases
        #expect(allCases.count == 7)
        let expected: Set<String> = [
            "neutral", "core", "accent", "statement", "support", "anchor", "signature"
        ]
        let actual = Set(allCases.map(\.rawValue))
        #expect(actual == expected)
    }

    @Test("Blueprint JSON contract round-trip preserves V4 palette fields")
    func v4PaletteJsonContractRoundTrip() throws {
        let provenance: ColourProvenance = .v4Template(family: "Deep Autumn", band: "test", index: 0)
        var flags = OverrideFlags()
        flags.scorpioDensityApplied = true
        flags.capricornVirgoCoolingApplied = true
        flags.fireAirChromaApplied = true
        flags.waterSofteningApplied = false
        flags.earthDepthOverrideApplied = true
        flags.winterCompressionApplied = false
        flags.surfacePreservationApplied = true
        flags.coolLeanDeepAutumn = false
        let palette = PaletteSection(
            neutrals: [
                BlueprintColour(name: "warm ivory", hexValue: "#F5EDE0", role: .neutral, provenance: provenance),
                BlueprintColour(name: "camel sand", hexValue: "#C4A775", role: .neutral, provenance: provenance),
                BlueprintColour(name: "warm stone", hexValue: "#8C7A6B", role: .neutral, provenance: provenance),
                BlueprintColour(name: "espresso", hexValue: "#3C2415", role: .neutral, provenance: provenance),
            ],
            coreColours: [
                BlueprintColour(name: "sage", hexValue: "#7AA18C", role: .core, provenance: provenance),
                BlueprintColour(name: "caramel", hexValue: "#B08254", role: .core, provenance: provenance),
                BlueprintColour(name: "slate", hexValue: "#4B5A6E", role: .core, provenance: provenance),
                BlueprintColour(name: "cream", hexValue: "#F0EADC", role: .core, provenance: provenance),
            ],
            accentColours: [
                BlueprintColour(name: "saffron", hexValue: "#D4A23C", role: .accent, provenance: provenance),
                BlueprintColour(name: "dusty rose", hexValue: "#C97D7D", role: .accent, provenance: provenance),
                BlueprintColour(name: "teal", hexValue: "#3C7A85", role: .accent, provenance: provenance),
                BlueprintColour(name: "midnight blue", hexValue: "#1F2A44", role: .accent, provenance: provenance),
            ],
            family: .deepAutumn,
            cluster: .deepWarmStructured,
            variables: DerivedVariables(depth: .deep, temperature: .warm, saturation: .rich, contrast: .medium, surface: .structured),
            secondaryPull: .deepWinter,
            overrideFlags: flags,
            narrativeText: "V4 test palette"
        )

        let blueprint = CosmicBlueprint(
            userInfo: BlueprintUserInfo(
                birthDate: Date(timeIntervalSince1970: 500_000_000),
                birthLocation: "London, UK",
                generationDate: Date(timeIntervalSince1970: 500_000_100)
            ),
            styleCore: StyleCoreSection(narrativeText: "Style core"),
            textures: TexturesSection(goodText: "Good", badText: "Bad", sweetSpotText: "Sweet"),
            palette: palette,
            occasions: OccasionsSection(workText: "Work", intimateText: "Intimate", dailyText: "Daily"),
            hardware: HardwareSection(
                metalsText: "Metals",
                stonesText: "Stones",
                tipText: "Tip",
                recommendedMetals: ["silver", "gold"],
                recommendedStones: ["onyx", "amber"]
            ),
            code: CodeSection(leanInto: ["lean"], avoid: ["avoid"], consider: ["consider"]),
            accessory: AccessorySection(paragraphs: ["a", "b", "c"]),
            pattern: PatternSection(
                narrativeText: "Pattern narrative",
                tipText: "Pattern tip",
                recommendedPatterns: ["pinstripe"],
                avoidPatterns: ["paisley"]
            ),
            generatedAt: Date(timeIntervalSince1970: 500_000_200),
            engineVersion: "2.0.0"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(blueprint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CosmicBlueprint.self, from: encoded)

        #expect(decoded.palette.isV4)
        #expect((decoded.palette.neutrals ?? []).count == 4)
        #expect(decoded.palette.family == PaletteFamily.deepAutumn)
        #expect(decoded.palette.cluster == PaletteCluster.deepWarmStructured)
        #expect(decoded.palette.variables?.depth == .deep)
        #expect(decoded.palette.secondaryPull == PaletteFamily.deepWinter)
        #expect(decoded.palette.overrideFlags?.earthDepthOverrideApplied == true)
        #expect(decoded.palette.overrideFlags?.surfacePreservationApplied == true)
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
        BlueprintTokenGenerator.loadDataset(from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath))
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
        BlueprintTokenGenerator.loadDataset(from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath))
    }

    private func loadNarrativeCache(from overrideURL: URL? = nil) -> NarrativeCacheLoader? {
        let cacheURL: URL
        if let overrideURL {
            cacheURL = overrideURL
        } else {
            cacheURL = StyleGuideDataURL.blueprintNarrativeCache(testFilePath: #filePath)
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
                BlueprintColour(name: "midnight", hexValue: "#191970", role: .core, provenance: .libraryFallback(reason: "test stub")),
                BlueprintColour(name: "slate", hexValue: "#708090", role: .core, provenance: .libraryFallback(reason: "test stub")),
            ],
            accentColours: [
                BlueprintColour(name: "dusty rose", hexValue: "#DCAE96", role: .accent, provenance: .libraryFallback(reason: "test stub")),
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
        #expect(ctx["metal_1"] == "silver tones")
        #expect(ctx["metal_2"] == "steel tones")
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
                BlueprintColour(name: "midnight", hexValue: "#191970", role: .core, provenance: .libraryFallback(reason: "test stub")),
                BlueprintColour(name: "slate", hexValue: "#708090", role: .core, provenance: .libraryFallback(reason: "test stub")),
                BlueprintColour(name: "charcoal", hexValue: "#36454F", role: .core, provenance: .libraryFallback(reason: "test stub")),
            ],
            accentColours: [
                BlueprintColour(name: "dusty rose", hexValue: "#DCAE96", role: .accent, provenance: .libraryFallback(reason: "test stub")),
                BlueprintColour(name: "sage", hexValue: "#9CAF88", role: .accent, provenance: .libraryFallback(reason: "test stub")),
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

// MARK: - Palette Calibration Diagnostic

struct PaletteCalibrationDiagnostic {

    @Test("Ash palette contains warm/deep colours after additive formula")
    func ashPaletteCalibration() throws {
        guard ProcessInfo.processInfo.environment["PALETTE_CALIBRATION_DIAGNOSTIC"] == "1" else {
            return
        }
        guard let dataset = BlueprintTokenGenerator.loadDataset(
            from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath)
        ) else {
            Issue.record("Failed to load dataset")
            return
        }

        let chart = NatalChartCalculator.calculateNatalChart(
            birthDate: ISO8601DateFormatter().date(from: "1984-12-11T00:00:00Z")!,
            latitude: 51.5074, longitude: -0.1278,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        let analysis = ChartAnalyser.analyse(chart: chart)

        // Diagnostic: check what Venus sign the calculator actually produces
        #expect(analysis.venusSign == "Sagittarius",
                "Expected Venus in Sagittarius but got \(analysis.venusSign). planetSigns=\(analysis.planetSigns)")

        // Diagnostic: check token provenance for venus
        let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
        let venusTokenKeys = tokenResult.contributingCombos
            .filter { $0.key.hasPrefix("venus_") }
            .map { "\($0.key) w=\(String(format: "%.3f", $0.aggregateWeight))" }
        #expect(!venusTokenKeys.isEmpty, "No venus tokens found. Combos: \(tokenResult.contributingCombos.map(\.key))")

        let resolved = DeterministicResolver.resolve(
            tokens: tokenResult.tokens, analysis: analysis,
            dataset: dataset, contributingCombos: tokenResult.contributingCombos
        )

        let allColours = resolved.coreColours + resolved.accentColours
        let allNames = allColours.map { $0.name.lowercased() }
        let allNamesJoined = allNames.joined(separator: ", ")

        // Build provenance info for debugging
        let provenanceInfo = allColours.map { c -> String in
            switch c.provenance {
            case let .chartDerived(comboKey, _, _, _): return "\(c.name)←\(comboKey)"
            case let .crossPoolEscalation(comboKey, _, _, _, _): return "\(c.name)←xpool(\(comboKey))"
            case .libraryFallback: return "\(c.name)←fallback"
            case let .v4Template(family, band, _): return "\(c.name)←v4(\(family)/\(band))"
            case let .chartDerivedAccent(role, planet, _, _): return "\(c.name)←accent(\(role)/\(planet))"
            }
        }.joined(separator: ", ")

        print("[PaletteCalibrationDiagnostic] Venus tokens: \(venusTokenKeys). Palette provenance: \(provenanceInfo)")

        // Pearl and soft white should NOT be in the palette with additive formula
        let hasPearl = allNames.contains("pearl")
        let hasSoftWhite = allNames.contains("soft white")
        #expect(!hasPearl, "Pearl should be demoted. Palette: \(allNamesJoined)")
        #expect(!hasSoftWhite, "Soft white should be demoted. Palette: \(allNamesJoined)")

        // Warm/deep colours should appear
        let warmDeepNames = ["warm ochre", "burnt sienna", "dark burgundy", "oxblood",
                             "worn leather", "deep teal", "warm taupe", "ink"]
        let warmDeepCount = allNames.filter { name in warmDeepNames.contains(name) }.count
        #expect(warmDeepCount >= 5,
                "Expected ≥5 warm/deep colours, got \(warmDeepCount). Palette: \(allNamesJoined)")
    }
}

// MARK: - Hardware Allocation Audit (100 synthetic users)

struct HardwareAllocationAuditTests {

    private static let allSigns = [
        "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
        "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
    ]

    private static let signElements: [String: String] = [
        "Aries": "fire", "Taurus": "earth", "Gemini": "air", "Cancer": "water",
        "Leo": "fire", "Virgo": "earth", "Libra": "air", "Scorpio": "water",
        "Sagittarius": "fire", "Capricorn": "earth", "Aquarius": "air", "Pisces": "water"
    ]

    private static let warmMetals: Set<String> = [
        "yellow gold", "rose gold", "warm bronze", "polished brass",
        "bright copper", "polished copper", "soft gold", "aged brass",
        "hammered gold", "oxidised copper", "gilded finishes", "gilded bronze",
        "polished brass", "polished copper"
    ]

    private static let coolMetals: Set<String> = [
        "sterling silver", "polished silver", "brushed silver", "silver",
        "white gold", "platinum", "matte platinum", "surgical steel",
        "titanium", "gunmetal", "blackened silver", "oxidised steel",
        "matte white gold", "antique silver", "opal-set silver"
    ]

    private func loadTestDataset() -> AstrologicalStyleDataset? {
        BlueprintTokenGenerator.loadDataset(from: StyleGuideDataURL.astrologicalStyleDataset(testFilePath: #filePath))
    }

    private struct SyntheticUser {
        let id: Int
        let venusSign: String
        let moonSign: String
        let sunSign: String
        let marsSign: String
        let ascendantSign: String
        let sect: ChartSect
    }

    private func generateSyntheticUsers() -> [SyntheticUser] {
        let signs = Self.allSigns
        var users: [SyntheticUser] = []
        var id = 0

        for venusSign in signs {
            let moonIndex = (signs.firstIndex(of: venusSign)! + 3) % 12
            let sunIndex = (signs.firstIndex(of: venusSign)! + 1) % 12
            let marsIndex = (signs.firstIndex(of: venusSign)! + 5) % 12
            let ascIndex = (signs.firstIndex(of: venusSign)! + 7) % 12

            // Two users per Venus sign: one day sect, one night sect
            for sect in [ChartSect.day, ChartSect.night] {
                users.append(SyntheticUser(
                    id: id, venusSign: venusSign, moonSign: signs[moonIndex],
                    sunSign: signs[sunIndex], marsSign: signs[marsIndex],
                    ascendantSign: signs[ascIndex], sect: sect
                ))
                id += 1
            }

            // Third user: shifted Moon for variety
            let moonIndex2 = (signs.firstIndex(of: venusSign)! + 6) % 12
            users.append(SyntheticUser(
                id: id, venusSign: venusSign, moonSign: signs[moonIndex2],
                sunSign: signs[sunIndex], marsSign: signs[marsIndex],
                ascendantSign: signs[ascIndex], sect: .night
            ))
            id += 1

            // Fourth user: shifted Ascendant
            let ascIndex2 = (signs.firstIndex(of: venusSign)! + 10) % 12
            users.append(SyntheticUser(
                id: id, venusSign: venusSign, moonSign: signs[moonIndex],
                sunSign: signs[sunIndex], marsSign: signs[marsIndex],
                ascendantSign: signs[ascIndex2], sect: .day
            ))
            id += 1
        }

        // Additional edge cases: same sign stelliums
        for sign in signs.prefix(4) {
            users.append(SyntheticUser(
                id: id, venusSign: sign, moonSign: sign,
                sunSign: sign, marsSign: sign,
                ascendantSign: signs[(signs.firstIndex(of: sign)! + 6) % 12],
                sect: .night
            ))
            id += 1
        }

        return users
    }

    private func makeAnalysis(user: SyntheticUser) -> ChartAnalysis {
        let signs = [
            "Sun": user.sunSign, "Moon": user.moonSign,
            "Venus": user.venusSign, "Mars": user.marsSign,
            "Mercury": Self.allSigns[(Self.allSigns.firstIndex(of: user.sunSign)! + 2) % 12],
            "Jupiter": Self.allSigns[(Self.allSigns.firstIndex(of: user.sunSign)! + 4) % 12],
            "Saturn": Self.allSigns[(Self.allSigns.firstIndex(of: user.sunSign)! + 8) % 12]
        ]

        var fire = 0, earth = 0, air = 0, water = 0
        for (_, sign) in signs {
            switch Self.signElements[sign] {
            case "fire": fire += 1
            case "earth": earth += 1
            case "air": air += 1
            case "water": water += 1
            default: break
            }
        }
        if let ascEl = Self.signElements[user.ascendantSign] {
            switch ascEl {
            case "fire": fire += 1
            case "earth": earth += 1
            case "air": air += 1
            case "water": water += 1
            default: break
            }
        }

        let houses: [String: Int] = [
            "Sun": 5, "Moon": 4, "Venus": 7, "Mars": 10,
            "Mercury": 3, "Jupiter": 9, "Saturn": 11
        ]

        var houseScores: [Int: Double] = [:]
        for h in 1...12 { houseScores[h] = 0.0 }
        for (_, house) in houses { houseScores[house, default: 0] += 0.5 }

        let dominantHouses = houseScores
            .sorted { a, b in a.value != b.value ? a.value > b.value : a.key < b.key }
            .prefix(3).map(\.key)

        let sectStatus = ChartAnalyser.computePlanetSectStatus(chartSect: user.sect)

        return ChartAnalysis(
            elementBalance: ElementBalance(fire: fire, earth: earth, air: air, water: water),
            modalityBalance: ModalityBalance(cardinal: 3, fixed: 3, mutable: 2),
            chartRuler: "Venus",
            sunSign: user.sunSign,
            moonSign: user.moonSign,
            ascendantSign: user.ascendantSign,
            venusSign: user.venusSign,
            marsSign: user.marsSign,
            planetSigns: signs,
            planetDignities: [:],
            planetHouses: houses,
            significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Sun"],
            chartSect: user.sect,
            planetSectStatus: sectStatus,
            houseEmphasis: HouseEmphasis(
                houseScores: houseScores,
                dominantHouses: Array(dominantHouses),
                venusHouseDomain: ChartAnalyser.houseDomainLabels[7] ?? "partnerships",
                moonHouseDomain: ChartAnalyser.houseDomainLabels[4] ?? "home"
            )
        )
    }

    @Test("Hardware allocation produces non-empty metals and stones for 52 synthetic users")
    func hardwareNonEmpty() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let users = generateSyntheticUsers()
        #expect(users.count >= 52)

        for user in users {
            let analysis = makeAnalysis(user: user)
            let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
            let resolved = DeterministicResolver.resolveNonPalette(
                tokens: tokenResult.tokens, analysis: analysis,
                dataset: dataset, contributingCombos: tokenResult.contributingCombos
            )

            #expect(resolved.recommendedMetals.count >= 2,
                    "User \(user.id) (Venus \(user.venusSign)): got \(resolved.recommendedMetals.count) metals — expected ≥2")
            #expect(resolved.recommendedStones.count >= 2,
                    "User \(user.id) (Venus \(user.venusSign)): got \(resolved.recommendedStones.count) stones — expected ≥2")

            let hasPlaceholder = resolved.recommendedMetals.contains("(see Blueprint for details)")
            #expect(!hasPlaceholder,
                    "User \(user.id) (Venus \(user.venusSign)): metals fell back to placeholder — \(resolved.recommendedMetals)")
        }
    }

    @Test("Hardware allocation includes variety and warm metals surface for warm-Venus users")
    func hardwareTemperatureDistribution() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let users = generateSyntheticUsers()
        var noMetalUsers: [Int] = []
        var distinctTopMetals: Set<String> = []
        var warmPresenceCount = 0
        var coolPresenceCount = 0
        var mixedCount = 0

        for user in users {
            let analysis = makeAnalysis(user: user)
            let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
            let resolved = DeterministicResolver.resolveNonPalette(
                tokens: tokenResult.tokens, analysis: analysis,
                dataset: dataset, contributingCombos: tokenResult.contributingCombos
            )

            let metals = resolved.recommendedMetals
            if metals.isEmpty || metals.allSatisfy({ $0 == "(see Blueprint for details)" }) {
                noMetalUsers.append(user.id)
                continue
            }

            if let top = metals.first { distinctTopMetals.insert(top.lowercased()) }

            let hasWarmAny = metals.contains { Self.warmMetals.contains($0.lowercased()) }
            let hasCoolAny = metals.contains { Self.coolMetals.contains($0.lowercased()) }

            if hasWarmAny { warmPresenceCount += 1 }
            if hasCoolAny { coolPresenceCount += 1 }
            if hasWarmAny && hasCoolAny { mixedCount += 1 }

            print("[HardwareAudit] User \(user.id) Venus=\(user.venusSign) Moon=\(user.moonSign) Asc=\(user.ascendantSign) → \(metals.prefix(5).joined(separator: ", "))")
        }

        print("[HardwareAudit] Population: \(users.count) users")
        print("[HardwareAudit] Warm metals present: \(warmPresenceCount)")
        print("[HardwareAudit] Cool metals present: \(coolPresenceCount)")
        print("[HardwareAudit] Mixed warm+cool: \(mixedCount)")
        print("[HardwareAudit] Distinct top metals: \(distinctTopMetals.count) — \(distinctTopMetals.sorted().joined(separator: ", "))")

        #expect(noMetalUsers.isEmpty,
                "Users with no metals: \(noMetalUsers)")
        #expect(distinctTopMetals.count >= 4,
                "Only \(distinctTopMetals.count) distinct top metals across \(users.count) users — insufficient variety")
        #expect(warmPresenceCount > users.count / 3,
                "Warm metals appeared for only \(warmPresenceCount)/\(users.count) users — warm metals underrepresented")
        #expect(coolPresenceCount > users.count / 3,
                "Cool metals appeared for only \(coolPresenceCount)/\(users.count) users — cool metals underrepresented")
        #expect(mixedCount > users.count / 4,
                "Only \(mixedCount)/\(users.count) users got mixed warm+cool — widened combo window should produce blended results")
    }

    @Test("Cool-sign Moon or Ascendant can surface silver-family metals in top 3")
    func silverSurfacesForCoolPlacements() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let coolMoonSigns = ["Capricorn", "Aquarius", "Virgo", "Scorpio"]
        let coolAscSigns = ["Pisces", "Aquarius", "Capricorn", "Virgo"]
        var silverSurfacedCount = 0
        var testedCount = 0

        for moonSign in coolMoonSigns {
            for ascSign in coolAscSigns {
                let user = SyntheticUser(
                    id: testedCount, venusSign: "Aries", moonSign: moonSign,
                    sunSign: "Taurus", marsSign: "Gemini",
                    ascendantSign: ascSign, sect: .night
                )

                let analysis = makeAnalysis(user: user)
                let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
                let resolved = DeterministicResolver.resolveNonPalette(
                    tokens: tokenResult.tokens, analysis: analysis,
                    dataset: dataset, contributingCombos: tokenResult.contributingCombos
                )

                let top3 = resolved.recommendedMetals.prefix(3).map { $0.lowercased() }
                let hasSilverFamily = top3.contains { Self.coolMetals.contains($0) }

                if hasSilverFamily { silverSurfacedCount += 1 }
                testedCount += 1

                print("[SilverAudit] Moon=\(moonSign) Asc=\(ascSign) → \(resolved.recommendedMetals.joined(separator: ", ")) | silver in top 3: \(hasSilverFamily)")
            }
        }

        #expect(silverSurfacedCount >= testedCount / 3,
                "Silver-family metals surfaced in only \(silverSurfacedCount)/\(testedCount) cool-placement users — expected at least a third")
    }

    @Test("Hardware allocation is deterministic across 20 runs")
    func hardwareDeterminism() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let user = SyntheticUser(
            id: 0, venusSign: "Aries", moonSign: "Capricorn",
            sunSign: "Taurus", marsSign: "Gemini",
            ascendantSign: "Pisces", sect: .night
        )

        let analysis = makeAnalysis(user: user)
        var previousMetals: [String]?
        var previousStones: [String]?

        for _ in 0..<20 {
            let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
            let resolved = DeterministicResolver.resolveNonPalette(
                tokens: tokenResult.tokens, analysis: analysis,
                dataset: dataset, contributingCombos: tokenResult.contributingCombos
            )

            if let prev = previousMetals {
                #expect(resolved.recommendedMetals == prev,
                        "Metal output is nondeterministic")
            }
            if let prev = previousStones {
                #expect(resolved.recommendedStones == prev,
                        "Stone output is nondeterministic")
            }
            previousMetals = resolved.recommendedMetals
            previousStones = resolved.recommendedStones
        }
    }

    @Test("Night chart with Capricorn stellium surfaces silver/platinum in top metals")
    func capricornStelliumNightChart() {
        guard let dataset = loadTestDataset() else {
            Issue.record("Failed to load dataset"); return
        }

        let signs: [String: String] = [
            "Sun": "Taurus", "Moon": "Capricorn", "Venus": "Taurus",
            "Mars": "Gemini", "Mercury": "Aries",
            "Jupiter": "Gemini", "Saturn": "Capricorn",
            "Uranus": "Capricorn", "Neptune": "Capricorn"
        ]

        let houses: [String: Int] = [
            "Sun": 2, "Moon": 10, "Venus": 2, "Mars": 3,
            "Mercury": 1, "Jupiter": 3, "Saturn": 10,
            "Uranus": 10, "Neptune": 10
        ]

        var houseScores: [Int: Double] = [:]
        for h in 1...12 { houseScores[h] = 0.0 }
        for (_, house) in houses { houseScores[house, default: 0] += 0.5 }
        let dominantHouses = houseScores
            .sorted { a, b in a.value != b.value ? a.value > b.value : a.key < b.key }
            .prefix(3).map(\.key)

        let sectStatus = ChartAnalyser.computePlanetSectStatus(chartSect: .night)

        let analysis = ChartAnalysis(
            elementBalance: ElementBalance(fire: 1, earth: 4, air: 2, water: 1),
            modalityBalance: ModalityBalance(cardinal: 4, fixed: 2, mutable: 2),
            chartRuler: "Venus",
            sunSign: "Taurus", moonSign: "Capricorn",
            ascendantSign: "Pisces", venusSign: "Taurus", marsSign: "Gemini",
            planetSigns: signs, planetDignities: ["Venus": .domicile],
            planetHouses: houses, significantAspects: [],
            dominantPlanets: ["Venus", "Moon", "Saturn"],
            chartSect: .night, planetSectStatus: sectStatus,
            houseEmphasis: HouseEmphasis(
                houseScores: houseScores,
                dominantHouses: Array(dominantHouses),
                venusHouseDomain: ChartAnalyser.houseDomainLabels[2] ?? "resources",
                moonHouseDomain: ChartAnalyser.houseDomainLabels[10] ?? "career"
            )
        )

        let tokenResult = BlueprintTokenGenerator.generate(analysis: analysis, dataset: dataset)
        let resolved = DeterministicResolver.resolveNonPalette(
            tokens: tokenResult.tokens, analysis: analysis,
            dataset: dataset, contributingCombos: tokenResult.contributingCombos
        )

        let allMetals = resolved.recommendedMetals.map { $0.lowercased() }
        let top5 = Array(allMetals.prefix(5))
        let silverFamily = top5.filter {
            $0.contains("silver") || $0.contains("platinum") || $0.contains("white gold")
        }

        print("[CapStellium] Night chart, Venus domicile Taurus, Cap stellium (Moon+Saturn+Uranus+Neptune)")
        print("[CapStellium] All metals: \(resolved.recommendedMetals.joined(separator: ", "))")
        print("[CapStellium] Silver-family in top 5: \(silverFamily)")

        #expect(silverFamily.count >= 2,
                "Capricorn stellium + night chart should surface ≥2 silver-family metals in top 5, got \(silverFamily) from \(top5)")
    }
}
