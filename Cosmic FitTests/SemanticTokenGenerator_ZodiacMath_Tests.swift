import Testing
import Foundation
@testable import Cosmic_Fit

@Suite("SemanticTokenGenerator Zodiac Math")
struct SemanticTokenGenerator_ZodiacMath_Tests {

    // Expected mappings for 1-based zodiac signs (Aries=1 … Pisces=12)
    private static let expectedElements: [(sign: Int, name: String, element: String)] = [
        (1,  "Aries",       "fire"),
        (2,  "Taurus",      "earth"),
        (3,  "Gemini",      "air"),
        (4,  "Cancer",      "water"),
        (5,  "Leo",         "fire"),
        (6,  "Virgo",       "earth"),
        (7,  "Libra",       "air"),
        (8,  "Scorpio",     "water"),
        (9,  "Sagittarius", "fire"),
        (10, "Capricorn",   "earth"),
        (11, "Aquarius",    "air"),
        (12, "Pisces",      "water"),
    ]

    private static let expectedModalities: [(sign: Int, name: String, modality: String)] = [
        (1,  "Aries",       "cardinal"),
        (2,  "Taurus",      "fixed"),
        (3,  "Gemini",      "mutable"),
        (4,  "Cancer",      "cardinal"),
        (5,  "Leo",         "fixed"),
        (6,  "Virgo",       "mutable"),
        (7,  "Libra",       "cardinal"),
        (8,  "Scorpio",     "fixed"),
        (9,  "Sagittarius", "mutable"),
        (10, "Capricorn",   "cardinal"),
        (11, "Aquarius",    "fixed"),
        (12, "Pisces",      "mutable"),
    ]

    @Test("All 12 signs map to correct element")
    func testSignElements() {
        for entry in Self.expectedElements {
            let result = SemanticTokenGenerator.getSignElement(sign: entry.sign)
            #expect(result == entry.element,
                    "\(entry.name) (sign \(entry.sign)): expected element '\(entry.element)', got '\(result)'")
        }
    }

    @Test("All 12 signs map to correct modality")
    func testSignModalities() {
        for entry in Self.expectedModalities {
            let result = SemanticTokenGenerator.getSignModality(sign: entry.sign)
            #expect(result == entry.modality,
                    "\(entry.name) (sign \(entry.sign)): expected modality '\(entry.modality)', got '\(result)'")
        }
    }

    @Test("Out-of-range signs return safe defaults")
    func testOutOfRangeSigns() {
        #expect(SemanticTokenGenerator.getSignElement(sign: 0) == "fire")
        #expect(SemanticTokenGenerator.getSignElement(sign: 13) == "fire")
        #expect(SemanticTokenGenerator.getSignElement(sign: -1) == "fire")
        #expect(SemanticTokenGenerator.getSignModality(sign: 0) == "cardinal")
        #expect(SemanticTokenGenerator.getSignModality(sign: 13) == "cardinal")
    }

    @Test("Element mapping matches DailyEnergyEngine grouping")
    func testConsistencyWithDailyEnergyEngine() {
        // Fire signs: 1, 5, 9
        for sign in [1, 5, 9] {
            #expect(SemanticTokenGenerator.getSignElement(sign: sign) == "fire",
                    "Sign \(sign) should be fire")
        }
        // Earth signs: 2, 6, 10
        for sign in [2, 6, 10] {
            #expect(SemanticTokenGenerator.getSignElement(sign: sign) == "earth",
                    "Sign \(sign) should be earth")
        }
        // Air signs: 3, 7, 11
        for sign in [3, 7, 11] {
            #expect(SemanticTokenGenerator.getSignElement(sign: sign) == "air",
                    "Sign \(sign) should be air")
        }
        // Water signs: 4, 8, 12
        for sign in [4, 8, 12] {
            #expect(SemanticTokenGenerator.getSignElement(sign: sign) == "water",
                    "Sign \(sign) should be water")
        }
    }
}
