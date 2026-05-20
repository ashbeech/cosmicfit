//
//  DailyFitTypes_Tests.swift
//  Cosmic FitTests
//
//  Phase 0 acceptance tests for DailyFitTypes contracts.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Test Fixtures

extension DailyTransitSummary {
    static func fixture(
        transitPlanet: String = "Mars",
        natalPlanet: String = "Venus",
        aspect: String = "trine",
        strength: Double = 0.75
    ) -> DailyTransitSummary {
        DailyTransitSummary(
            transitPlanet: transitPlanet,
            natalPlanet: natalPlanet,
            aspect: aspect,
            strength: strength
        )
    }
}

extension LunarContext {
    static func fixture(
        phaseName: String = "Waxing Crescent",
        isWaxing: Bool = true,
        element: String = "Fire",
        phaseDegrees: Double = 45.0
    ) -> LunarContext {
        LunarContext(
            phaseName: phaseName,
            isWaxing: isWaxing,
            element: element,
            phaseDegrees: phaseDegrees
        )
    }
}

extension DailyEnergySnapshot {
    static func fixture(
        vibeProfile: VibeBreakdown = VibeBreakdown(classic: 5, playful: 3, romantic: 4, utility: 3, drama: 3, edge: 3),
        axes: DerivedAxes = DerivedAxes(action: 6.0, tempo: 5.0, strategy: 7.0, visibility: 4.0),
        dominantTransits: [DailyTransitSummary] = [.fixture()],
        lunarContext: LunarContext = .fixture(),
        dailySeed: Int = 42,
        profileHash: String = "test-profile-hash",
        generatedAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> DailyEnergySnapshot {
        DailyEnergySnapshot(
            vibeProfile: vibeProfile,
            axes: axes,
            dominantTransits: dominantTransits,
            lunarContext: lunarContext,
            dailySeed: dailySeed,
            profileHash: profileHash,
            generatedAt: generatedAt
        )
    }
}

extension EssenceTriangle {
    static func fixture(
        classic: Double = 0.4,
        edgy: Double = 0.35,
        grounded: Double = 0.25
    ) -> EssenceTriangle {
        EssenceTriangle(classic: classic, edgy: edgy, grounded: grounded)
    }
}

extension StyleEssenceProfile {
    static func fixture() -> StyleEssenceProfile {
        let scores: [StyleEssenceScore] = StyleEssenceCategory.allCases.map { cat in
            let value: Double
            switch cat {
            case .classic:  value = 0.40
            case .edgy:     value = 0.35
            case .grounded: value = 0.25
            default:        value = 0.02
            }
            return StyleEssenceScore(category: cat, score: value)
        }
        let top3 = scores.sorted { $0.score > $1.score }.prefix(3)
        return StyleEssenceProfile(allScores: scores, visibleCategories: Array(top3))
    }
}

extension SilhouetteProfile {
    static func fixture(
        masculineFeminine: Double = 0.6,
        angularRounded: Double = 0.45,
        structuredDraped: Double = 0.3
    ) -> SilhouetteProfile {
        SilhouetteProfile(
            masculineFeminine: masculineFeminine,
            angularRounded: angularRounded,
            structuredDraped: structuredDraped
        )
    }
}

extension DailyColourPick {
    static func fixture(
        name: String = "Burnt Sienna",
        hexValue: String = "#A0522D",
        role: String = "core"
    ) -> DailyColourPick {
        DailyColourPick(name: name, hexValue: hexValue, role: role)
    }
}

extension DailyPaletteSelection {
    static func fixture(
        colours: [DailyColourPick] = [
            .fixture(),
            .fixture(name: "Warm Ivory", hexValue: "#F5EDE0", role: "neutral"),
            .fixture(name: "Deep Teal", hexValue: "#3C7A85", role: "accent"),
        ],
        allPaletteHexes: [String] = ["#A0522D", "#F5EDE0", "#3C7A85", "#191970", "#708090"]
    ) -> DailyPaletteSelection {
        DailyPaletteSelection(colours: colours, allPaletteHexes: allPaletteHexes)
    }
}

extension DailyFitPayload {
    static func fixture(
        tarotCard: TarotCard = fixtureTarotCard(),
        styleEditVariant: StyleEditVariant = fixtureStyleEditVariant(),
        dailyPalette: DailyPaletteSelection = .fixture(),
        vibrancy: Double = 0.65,
        contrast: Double = 0.55,
        metalTone: Double = 0.7,
        essenceProfile: StyleEssenceProfile = .fixture(),
        silhouetteProfile: SilhouetteProfile = .fixture(),
        vibeBreakdown: VibeBreakdown = VibeBreakdown(classic: 5, playful: 3, romantic: 4, utility: 3, drama: 3, edge: 3),
        axes: DerivedAxes = DerivedAxes(action: 6.0, tempo: 5.0, strategy: 7.0, visibility: 4.0),
        dominantTransits: [DailyTransitSummary] = [.fixture()],
        lunarContext: LunarContext = .fixture(),
        dailyTextures: [String] = ["structured wool", "raw denim"],
        dailyPattern: String? = "herringbone",
        generatedAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> DailyFitPayload {
        DailyFitPayload(
            tarotCard: tarotCard,
            styleEditVariant: styleEditVariant,
            dailyPalette: dailyPalette,
            vibrancy: vibrancy,
            contrast: contrast,
            metalTone: metalTone,
            essenceProfile: essenceProfile,
            silhouetteProfile: silhouetteProfile,
            vibeBreakdown: vibeBreakdown,
            axes: axes,
            dominantTransits: dominantTransits,
            lunarContext: lunarContext,
            dailyTextures: dailyTextures,
            dailyPattern: dailyPattern,
            generatedAt: generatedAt
        )
    }

    private static func fixtureTarotCard() -> TarotCard {
        TarotCard(
            name: "The Fool",
            imagePath: "Cards/00-TheFool",
            arcana: .major,
            suit: nil,
            number: nil,
            keywords: ["adventure", "freedom", "spontaneity"],
            themes: ["new beginnings", "trust"],
            energyAffinity: ["playful": 0.8, "drama": 0.5, "edge": 0.6],
            axesAffinity: ["action": 70.0, "tempo": 65.0, "strategy": 30.0, "visibility": 80.0],
            description: "A leap of faith into the unknown.",
            reversedKeywords: ["recklessness", "naivety"],
            symbolism: ["cliff", "white rose", "small dog"],
            styleEdits: [fixtureStyleEditVariant()]
        )
    }

    private static func fixtureStyleEditVariant() -> StyleEditVariant {
        StyleEditVariant(
            variant: "I",
            title: "The Adventurer",
            description: "Step into the unknown with bold, open-hearted confidence.",
            energyEmphasis: ["playful": 0.8, "drama": 0.5],
            axesEmphasis: ["action": 70, "visibility": 60],
            dailyRitual: nil,
            wardrobeReflection: nil
        )
    }
}

// MARK: - Helpers

private func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    return encoder
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}

// MARK: - Tests

struct DailyFitTypesTests {

    // MARK: T0.1 — DailyEnergySnapshot Codable round-trip

    @Test("T0.1: DailyEnergySnapshot encodes to JSON and decodes back with all fields intact")
    func testDailyEnergySnapshotCodableRoundTrip() throws {
        let original = DailyEnergySnapshot.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(DailyEnergySnapshot.self, from: data)

        #expect(decoded.vibeProfile.classic == original.vibeProfile.classic)
        #expect(decoded.vibeProfile.playful == original.vibeProfile.playful)
        #expect(decoded.vibeProfile.romantic == original.vibeProfile.romantic)
        #expect(decoded.vibeProfile.utility == original.vibeProfile.utility)
        #expect(decoded.vibeProfile.drama == original.vibeProfile.drama)
        #expect(decoded.vibeProfile.edge == original.vibeProfile.edge)
        #expect(decoded.axes.action == original.axes.action)
        #expect(decoded.axes.tempo == original.axes.tempo)
        #expect(decoded.axes.strategy == original.axes.strategy)
        #expect(decoded.axes.visibility == original.axes.visibility)
        #expect(decoded.dominantTransits == original.dominantTransits)
        #expect(decoded.lunarContext == original.lunarContext)
        #expect(decoded.dailySeed == original.dailySeed)
        #expect(decoded.profileHash == original.profileHash)
        #expect(decoded.generatedAt == original.generatedAt)
    }

    // MARK: T0.2 — DailyFitPayload Codable round-trip

    @Test("T0.2: DailyFitPayload encodes to JSON and decodes back with all fields intact")
    func testDailyFitPayloadCodableRoundTrip() throws {
        let original = DailyFitPayload.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(DailyFitPayload.self, from: data)

        #expect(decoded.tarotCard.name == original.tarotCard.name)
        #expect(decoded.tarotCard.imagePath == original.tarotCard.imagePath)
        #expect(decoded.styleEditVariant.title == original.styleEditVariant.title)
        #expect(decoded.styleEditVariant.variant == original.styleEditVariant.variant)
        #expect(decoded.styleEditVariant.description == original.styleEditVariant.description)
        #expect(decoded.dailyPalette == original.dailyPalette)
        #expect(decoded.vibrancy == original.vibrancy)
        #expect(decoded.contrast == original.contrast)
        #expect(decoded.metalTone == original.metalTone)
        #expect(decoded.essenceProfile == original.essenceProfile)
        #expect(decoded.silhouetteProfile == original.silhouetteProfile)
        #expect(decoded.vibeBreakdown.classic == original.vibeBreakdown.classic)
        #expect(decoded.axes.action == original.axes.action)
        #expect(decoded.dominantTransits == original.dominantTransits)
        #expect(decoded.lunarContext == original.lunarContext)
        #expect(decoded.dailyTextures == original.dailyTextures)
        #expect(decoded.dailyPattern == original.dailyPattern)
        #expect(decoded.generatedAt == original.generatedAt)
        #expect(decoded.dailyFitEngineId == nil)
        #expect(decoded.resolvedDailyFitEngineId == DailyFitEngineRegistry.productionId)
    }

    @Test("T0.2b: dailyFitEngineId round-trips when present")
    func testDailyFitPayloadEngineIdCodableRoundTrip() throws {
        let original = DailyFitPayload.fixture().withDailyFitEngineId(DailyFitEngineRegistry.legacyBaselineId)
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(DailyFitPayload.self, from: data)
        #expect(decoded.dailyFitEngineId == DailyFitEngineRegistry.legacyBaselineId)
        #expect(decoded.resolvedDailyFitEngineId == DailyFitEngineRegistry.legacyBaselineId)
    }

    // MARK: T0.3 — DailyTransitSummary Codable round-trip

    @Test("T0.3: DailyTransitSummary encodes and decodes with equality preserved")
    func testDailyTransitSummaryCodableRoundTrip() throws {
        let original = DailyTransitSummary.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(DailyTransitSummary.self, from: data)
        #expect(decoded == original)
    }

    // MARK: T0.4 — LunarContext Codable round-trip

    @Test("T0.4: LunarContext encodes and decodes with equality preserved")
    func testLunarContextCodableRoundTrip() throws {
        let original = LunarContext.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(LunarContext.self, from: data)
        #expect(decoded == original)
    }

    // MARK: T0.5 — DailyPaletteSelection Codable round-trip

    @Test("T0.5: DailyPaletteSelection encodes and decodes with equality preserved")
    func testDailyPaletteSelectionCodableRoundTrip() throws {
        let original = DailyPaletteSelection.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(DailyPaletteSelection.self, from: data)
        #expect(decoded == original)
    }

    // MARK: T0.6 — DailyColourPick Codable round-trip

    @Test("T0.6: DailyColourPick encodes and decodes with equality preserved")
    func testDailyColourPickCodableRoundTrip() throws {
        let original = DailyColourPick.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(DailyColourPick.self, from: data)
        #expect(decoded == original)
    }

    // MARK: T0.7 — Default calibration source weights normalised

    @Test("T0.7: Default calibration source weights sum to 1.0")
    func testDefaultCalibrationSourceWeightsNormalised() {
        #expect(DailyFitCalibration.default.sourceWeights.isNormalised)
    }

    // MARK: T0.8 — Default calibration has all 12 signs

    @Test("T0.8: Default calibration sign energy map contains all 12 zodiac signs")
    func testDefaultCalibrationHasAll12Signs() {
        #expect(DailyFitCalibration.default.signEnergyMap.multipliers.count == 12)
    }

    // MARK: T0.9 — Default calibration has all 10 planets

    @Test("T0.9: Default calibration planet axis map contains all 10 planets (Sun–Pluto)")
    func testDefaultCalibrationHasAll10Planets() {
        #expect(DailyFitCalibration.default.planetAxisMap.weights.count == 10)
    }

    // MARK: T0.10 — Sign multipliers in range

    @Test("T0.10: Every sign-energy multiplier in default calibration is between 0.5 and 2.0")
    func testDefaultCalibrationSignMultipliersInRange() {
        for (sign, energies) in DailyFitCalibration.default.signEnergyMap.multipliers {
            for (energy, multiplier) in energies {
                #expect(multiplier >= 0.5 && multiplier <= 2.0,
                        "\(sign)/\(energy): multiplier \(multiplier) outside 0.5–2.0")
            }
        }
    }

    // MARK: T0.11 — Selection weights sum to one

    @Test("T0.11: Default calibration selection weights sum to 1.0 (within 0.001)")
    func testDefaultCalibrationSelectionWeightsSumToOne() {
        let sw = DailyFitCalibration.default.selectionWeights
        let sum = sw.vibeWeight + sw.axisWeight + sw.transitBoost
        #expect(abs(sum - 1.0) < 0.001, "Selection weights sum to \(sum), expected ~1.0")
    }

    // MARK: T0.12 — VibeBreakdown field access through snapshot

    @Test("T0.12: VibeBreakdown fields are accessible through DailyEnergySnapshot")
    func testVibeBreakdownFieldsAccessible() {
        let snapshot = DailyEnergySnapshot.fixture()
        #expect(snapshot.vibeProfile.classic == 5)
        #expect(snapshot.vibeProfile.playful == 3)
        #expect(snapshot.vibeProfile.romantic == 4)
        #expect(snapshot.vibeProfile.utility == 3)
        #expect(snapshot.vibeProfile.drama == 3)
        #expect(snapshot.vibeProfile.edge == 3)
    }

    // MARK: T0.13 — DerivedAxes field access through snapshot

    @Test("T0.13: DerivedAxes fields are accessible through DailyEnergySnapshot")
    func testDerivedAxesFieldsAccessible() {
        let snapshot = DailyEnergySnapshot.fixture()
        #expect(snapshot.axes.action == 6.0)
        #expect(snapshot.axes.tempo == 5.0)
        #expect(snapshot.axes.strategy == 7.0)
        #expect(snapshot.axes.visibility == 4.0)
    }

    // MARK: T0.14 — EssenceTriangle Codable round-trip

    @Test("T0.14: EssenceTriangle encodes, decodes, and preserves Equatable equality")
    func testEssenceTriangleCodableRoundTrip() throws {
        let original = EssenceTriangle.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(EssenceTriangle.self, from: data)
        #expect(decoded == original)
    }

    // MARK: T0.15 — EssenceTriangle normalised to one

    @Test("T0.15: EssenceTriangle fixture values sum to approximately 1.0")
    func testEssenceTriangleNormalisedToOne() {
        let triangle = EssenceTriangle.fixture(classic: 0.4, edgy: 0.35, grounded: 0.25)
        let sum = triangle.classic + triangle.edgy + triangle.grounded
        #expect(abs(sum - 1.0) < 0.001, "Essence triangle sum is \(sum), expected ~1.0")
    }

    // MARK: T0.16 — SilhouetteProfile Codable round-trip

    @Test("T0.16: SilhouetteProfile encodes, decodes, and preserves Equatable equality")
    func testSilhouetteProfileCodableRoundTrip() throws {
        let original = SilhouetteProfile.fixture()
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(SilhouetteProfile.self, from: data)
        #expect(decoded == original)
    }

    // MARK: T0.17 — SilhouetteProfile values in range

    @Test("T0.17: All SilhouetteProfile values are between 0.0 and 1.0 inclusive")
    func testSilhouetteProfileValuesInRange() {
        let profile = SilhouetteProfile.fixture()
        #expect(profile.masculineFeminine >= 0.0 && profile.masculineFeminine <= 1.0)
        #expect(profile.angularRounded >= 0.0 && profile.angularRounded <= 1.0)
        #expect(profile.structuredDraped >= 0.0 && profile.structuredDraped <= 1.0)
    }

    // MARK: T0.18 — DailyFitPayload new fields accessible

    @Test("T0.18: DailyFitPayload new fields (vibrancy, contrast, metalTone, essenceProfile, silhouetteProfile) are accessible and populated")
    func testDailyFitPayloadContainsNewFields() {
        let payload = DailyFitPayload.fixture()
        #expect(payload.vibrancy == 0.65)
        #expect(payload.contrast == 0.55)
        #expect(payload.metalTone == 0.7)
        #expect(payload.essenceProfile.allScores.count == 14)
        #expect(payload.essenceProfile.visibleCategories.count == 3)
        let topCat = payload.essenceProfile.visibleCategories[0].category
        #expect(topCat == .classic, "Fixture top category should be classic, got \(topCat)")
        #expect(payload.silhouetteProfile.masculineFeminine == 0.6)
        #expect(payload.silhouetteProfile.angularRounded == 0.45)
        #expect(payload.silhouetteProfile.structuredDraped == 0.3)
    }
}
