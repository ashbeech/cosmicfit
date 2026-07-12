//
//  SG4ValidatorParityTests.swift
//  Cosmic FitTests
//
//  SG-4 deliverable 2: the Python↔Swift validator parity test.
//
//  tools/sg4_parity_fixture.py runs every corpus case through the Python
//  write gate (tools/sg_validation.py) and bakes the verdicts into
//  data/style_guide/sg4_parity_fixture.json. This suite replays the same
//  corpus through the Swift StyleGuideCoherenceValidator and asserts the
//  error/warning code sets match exactly — proving the two layers load the
//  same rules (style_guide_rules.json) and agree on their semantics.
//
//  The corpus is 40+ crafted cases (every check, block + near-miss pass) plus
//  ~80 real sections sampled from the SG-4 cache. Regenerate the fixture
//  whenever the rules or the Python gate change.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixture decoding

private struct ParityFixture: Decodable {
    let allowedPlaceholders: [String]
    let groupASections: [String]
    let groupBSections: [String]
    let gateCases: [GateCase]

    enum CodingKeys: String, CodingKey {
        case allowedPlaceholders = "allowed_placeholders"
        case groupASections = "group_a_sections"
        case groupBSections = "group_b_sections"
        case gateCases = "gate_cases"
    }
}

private struct GateCase: Decodable {
    let id: String
    let sectionKey: String
    let coreKeywords: [String]
    let existingClusterTexts: [String]
    let allowedLeakPhrases: [String]
    let text: String
    let expected: Expected

    struct Expected: Decodable {
        let passed: Bool
        let errorCodes: [String]
        let warningCodes: [String]
        let tooLongBlock: Bool

        enum CodingKeys: String, CodingKey {
            case passed
            case errorCodes = "error_codes"
            case warningCodes = "warning_codes"
            case tooLongBlock = "too_long_block"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sectionKey = "section_key"
        case coreKeywords = "core_keywords"
        case existingClusterTexts = "existing_cluster_texts"
        case allowedLeakPhrases = "allowed_leak_phrases"
        case text, expected
    }
}

private enum SG4Parity {
    static func fixture() throws -> ParityFixture {
        let data = try Data(contentsOf: StyleGuideDataURL.sg4ParityFixture())
        return try JSONDecoder().decode(ParityFixture.self, from: data)
    }

    static func validator() throws -> StyleGuideCoherenceValidator {
        let v = StyleGuideCoherenceValidator(
            rulesURL: StyleGuideDataURL.styleGuideRules(),
            rankedTablesURL: StyleGuideDataURL.rankedDomainTables())
        return try #require(v, "validator failed to load rules / ranked tables")
    }
}

// MARK: - Tests

@Suite("SG-4: Python↔Swift validator parity")
struct SG4ValidatorParityTests {

    @Test("Structural constants match the Python gate (placeholders, section groups)")
    func structuralConstants() throws {
        let fx = try SG4Parity.fixture()
        #expect(Set(fx.allowedPlaceholders) == StyleGuideCoherenceValidator.allowedPlaceholders)
        #expect(Set(fx.groupASections) == StyleGuideCoherenceValidator.groupASections)
        #expect(Set(fx.groupBSections) == StyleGuideCoherenceValidator.groupBSections)
    }

    @Test("Every fixture case reproduces the Python gate verdict exactly")
    func gateCaseParity() throws {
        let fx = try SG4Parity.fixture()
        let validator = try SG4Parity.validator()
        #expect(fx.gateCases.count >= 100, "parity corpus unexpectedly small: \(fx.gateCases.count)")

        for c in fx.gateCases {
            let result = validator.validateParagraph(
                text: c.text,
                sectionKey: c.sectionKey,
                coreKeywords: c.coreKeywords,
                existingClusterTexts: c.existingClusterTexts,
                allowedLeakPhrases: c.allowedLeakPhrases)

            #expect(result.passed == c.expected.passed,
                    "\(c.id): passed=\(result.passed), Python says \(c.expected.passed); errors=\(result.errors)")
            #expect(result.errorCodes == c.expected.errorCodes,
                    "\(c.id): error codes \(result.errorCodes) != Python \(c.expected.errorCodes)")
            #expect(result.warningCodes == c.expected.warningCodes,
                    "\(c.id): warning codes \(result.warningCodes) != Python \(c.expected.warningCodes)")

            let tooLong = validator.isTooLong(text: c.text, sectionKey: c.sectionKey)
            #expect(tooLong == c.expected.tooLongBlock,
                    "\(c.id): too_long_block=\(tooLong), Python says \(c.expected.tooLongBlock)")
        }
    }

    @Test("Validator loads from the app bundle resources")
    func bundleLoad() throws {
        // The rules + tables ship as Resources symlinks; the app-facing
        // initialiser must find them in the app bundle.
        let bundle = Bundle(for: NarrativeCacheLoader.self)
        let validator = StyleGuideCoherenceValidator(bundle: bundle)
        #expect(validator != nil, "bundle-based init failed: check Resources symlinks for style_guide_rules.json / ranked_domain_tables.json")
    }
}
