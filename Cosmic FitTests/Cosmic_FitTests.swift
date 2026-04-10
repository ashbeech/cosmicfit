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
            .appendingPathComponent("_reference")
            .appendingPathComponent("fixtures")
    }

    private static func loadFixture(_ filename: String) throws -> Data {
        let url = fixturesURL().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("""
                Fixture not found at \(url.path).
                Tests load fixtures via #filePath-relative path from the source tree.
                Ensure the repo checkout contains _reference/fixtures/\(filename).
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
