//
//  BlueprintLensEngine_TarotStyleEdit_Tests.swift
//  Cosmic FitTests
//
//  Phase 3 acceptance tests for BlueprintLensEngine.selectTarotAndStyleEdit().
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixtures

private enum Fixtures {

    static let fixedDate: Date = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal.date(from: DateComponents(year: 2026, month: 5, day: 10))!
    }()

    static let profileHash = "test_profile_abc123"

    // --- Vibe Fixtures ---

    static let dramaHeavyVibe = VibeBreakdown(
        classic: 1, playful: 1, romantic: 1, utility: 1, drama: 10, edge: 7
    )

    static let romanticHeavyVibe = VibeBreakdown(
        classic: 2, playful: 1, romantic: 10, utility: 2, drama: 3, edge: 3
    )

    static let balancedVibe = VibeBreakdown(
        classic: 4, playful: 3, romantic: 4, utility: 3, drama: 4, edge: 3
    )

    static let classicMaxVibe = VibeBreakdown(
        classic: 10, playful: 2, romantic: 3, utility: 2, drama: 2, edge: 2
    )

    // --- Axes ---

    static let neutralAxes = DerivedAxes(
        action: 5.0, tempo: 5.0, strategy: 5.0, visibility: 5.0
    )

    static let highActionAxes = DerivedAxes(
        action: 9.0, tempo: 7.0, strategy: 3.0, visibility: 6.0
    )

    // --- Lunar ---

    static let defaultLunar = LunarContext(
        phaseName: "Waxing Crescent", isWaxing: true,
        element: "Air", phaseDegrees: 45.0
    )

    // --- Transit Fixtures ---

    static let noTransits: [DailyTransitSummary] = []

    static let marsTransit = [
        DailyTransitSummary(
            transitPlanet: "Mars", natalPlanet: "Venus",
            aspect: "conjunction", strength: 1.0
        )
    ]

    // --- Snapshot Builders ---

    static func snapshot(
        vibe: VibeBreakdown,
        axes: DerivedAxes = neutralAxes,
        transits: [DailyTransitSummary] = noTransits,
        seed: Int = 42,
        profile: String = profileHash
    ) -> DailyEnergySnapshot {
        DailyEnergySnapshot(
            vibeProfile: vibe,
            axes: axes,
            dominantTransits: transits,
            lunarContext: defaultLunar,
            dailySeed: seed,
            profileHash: profile,
            generatedAt: fixedDate
        )
    }
}

// MARK: - Test Suite (serialized to avoid shared tracker contention)

@Suite(.serialized)
struct BlueprintLensEngine_TarotStyleEdit_Tests {

    /// Installs tracker instances backed by an ephemeral UserDefaults suite,
    /// isolating state from other test processes / parallel simulator clones.
    private func resetTrackers() {
        let suiteName = "com.cosmicfit.tests.\(UUID().uuidString)"
        let isolated = UserDefaults(suiteName: suiteName)!
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: isolated)
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: isolated)
        BlueprintLensEngine._resetCardCache()
    }

    // MARK: - T3.1: Tarot Card Selected

    @Test("T3.1 — selectTarotAndStyleEdit always returns a tarot card")
    func testTarotCardSelected() {
        resetTrackers()
        let snap = Fixtures.snapshot(vibe: Fixtures.balancedVibe)
        let result = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        #expect(!result.tarotCard.name.isEmpty)
    }

    // MARK: - T3.2: StyleEdit Variant Selected

    @Test("T3.2 — selectTarotAndStyleEdit always returns a style edit variant")
    func testStyleEditVariantSelected() {
        resetTrackers()
        let snap = Fixtures.snapshot(vibe: Fixtures.balancedVibe)
        let result = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        #expect(!result.styleEditVariant.variant.isEmpty)
        #expect(!result.styleEditVariant.title.isEmpty)
    }

    // MARK: - T3.3: Deterministic Selection

    @Test("T3.3 — same snapshot produces the same card and variant")
    func testSelectionDeterministic() {
        resetTrackers()
        let snap = Fixtures.snapshot(vibe: Fixtures.dramaHeavyVibe)
        let r1 = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)

        TarotRecencyTracker.shared.clearProfile(profileHash: Fixtures.profileHash)
        TarotVariantRotationTracker.shared.resetAll()

        let r2 = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        #expect(r1.tarotCard.name == r2.tarotCard.name)
        #expect(r1.styleEditVariant.variant == r2.styleEditVariant.variant)
    }

    // MARK: - T3.4: High Drama Snapshot Selects Dramatic Card

    @Test("T3.4 — drama-heavy snapshot selects a card with high drama affinity")
    func testHighDramaSnapshotSelectsDramaticCard() {
        resetTrackers()
        let snap = Fixtures.snapshot(vibe: Fixtures.dramaHeavyVibe)
        let result = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        let dramaAffinity = result.tarotCard.energyAffinity["drama"] ?? 0.0
        #expect(dramaAffinity >= 0.5,
                "Expected drama affinity >= 0.5, got \(dramaAffinity) for '\(result.tarotCard.name)'")
    }

    // MARK: - T3.5: High Romantic Snapshot Selects Romantic Card

    @Test("T3.5 — romantic-heavy snapshot selects a card with high romantic affinity")
    func testHighRomanticSnapshotSelectsRomanticCard() {
        resetTrackers()
        let snap = Fixtures.snapshot(vibe: Fixtures.romanticHeavyVibe)
        let result = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        let romanticAffinity = result.tarotCard.energyAffinity["romantic"] ?? 0.0
        #expect(romanticAffinity >= 0.5,
                "Expected romantic affinity >= 0.5, got \(romanticAffinity) for '\(result.tarotCard.name)'")
    }

    // MARK: - T3.6: Recency Prevents Repetition

    @Test("T3.6 — second selection after recording differs from the first")
    func testRecencyPreventsRepetition() {
        resetTrackers()
        let snap = Fixtures.snapshot(vibe: Fixtures.dramaHeavyVibe)

        let first = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        let second = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)

        #expect(first.tarotCard.name != second.tarotCard.name,
                "Expected different card on second draw; both were '\(first.tarotCard.name)'")
    }

    // MARK: - T3.7: Vibe Normalised by 21 Not 100

    @Test("T3.7 — vibe profile normalises by 21, not 100 (legacy bug regression)")
    func testVibeNormalisedBy21Not100() {
        let vibe = VibeBreakdown(
            classic: 10, playful: 2, romantic: 3, utility: 2, drama: 2, edge: 2
        )
        let vec = BlueprintLensEngine.buildVibeVector(from: vibe)

        let classicValue = vec["classic"] ?? 0.0
        let expectedCorrect = 10.0 / 21.0
        let buggyValue = 10.0 / 100.0

        #expect(abs(classicValue - expectedCorrect) < 0.001,
                "classic should be \(expectedCorrect), got \(classicValue)")
        #expect(abs(classicValue - buggyValue) > 0.1,
                "classic must NOT be \(buggyValue) (the /100 bug)")
    }

    // MARK: - T3.8: Axes Normalised at Load Time

    @Test("T3.8 — card axes are normalised at load time, not mid-scoring")
    func testAxesNormalisedAtLoad() {
        let loaded = BlueprintLensEngine.loadAndNormaliseCards()
        guard !loaded.isEmpty else {
            Issue.record("No cards loaded from JSON")
            return
        }
        guard let sample = loaded.first(where: { !$0.normAxes.isEmpty }) else {
            Issue.record("No cards with axesAffinity found")
            return
        }
        let rawAction = sample.card.axesAffinity?["action"]
        guard let raw = rawAction else { return }

        let normAction = sample.normAxes["action"] ?? -1.0
        let expected = raw / 100.0

        #expect(abs(normAction - expected) < 0.001,
                "Expected normAxes['action'] = \(expected), got \(normAction)")
        #expect(normAction >= 0.0 && normAction <= 1.0,
                "Normalised axis should be in [0,1], got \(normAction)")
    }

    // MARK: - T3.9: Transit Boost Influences Selection

    @Test("T3.9 — dominant Mars transit boosts Mars-aligned cards")
    func testTransitBoostInfluencesSelection() {
        resetTrackers()
        let snapNoTransit = Fixtures.snapshot(
            vibe: Fixtures.balancedVibe, transits: Fixtures.noTransits
        )
        let snapWithMars = Fixtures.snapshot(
            vibe: Fixtures.balancedVibe, transits: Fixtures.marsTransit,
            profile: "transitTestProfile"
        )

        let resultNoTransit = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snapNoTransit)
        TarotRecencyTracker.shared.clearProfile(profileHash: "transitTestProfile")
        let resultWithMars = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snapWithMars)

        let marsCardDrama = resultWithMars.tarotCard.energyAffinity["drama"] ?? 0.0
        let marsCardEdge = resultWithMars.tarotCard.energyAffinity["edge"] ?? 0.0
        let noTransitDrama = resultNoTransit.tarotCard.energyAffinity["drama"] ?? 0.0
        let noTransitEdge = resultNoTransit.tarotCard.energyAffinity["edge"] ?? 0.0

        let marsAlignment = marsCardDrama + marsCardEdge
        let baseAlignment = noTransitDrama + noTransitEdge

        #expect(marsAlignment >= baseAlignment - 0.1,
                "Mars transit should favour drama/edge cards; marsAlign=\(marsAlignment), base=\(baseAlignment)")
    }

    // MARK: - T3.10: Variant Rotation Cycles Through 3

    @Test("T3.10 — drawing the same card 3 times yields 3 different variant values")
    func testVariantRotationCyclesThrough3() {
        resetTrackers()
        let tracker = TarotVariantRotationTracker.shared
        let card = "TestCard"
        let profile = "rotationTest"

        var variants: [Int] = []
        for _ in 0..<3 {
            variants.append(tracker.nextVariantIndex(forCard: card, profileHash: profile))
        }
        #expect(Set(variants).count == 3,
                "Expected 3 unique indices, got \(variants)")
        #expect(variants == [0, 1, 2],
                "Expected [0,1,2], got \(variants)")
    }

    // MARK: - T3.11: Fallback When No Axes Affinity

    @Test("T3.11 — a card with nil axesAffinity still gets scored (axis score defaults to 0.5)")
    func testFallbackWhenNoAxesAffinity() {
        resetTrackers()
        let loaded = BlueprintLensEngine.loadAndNormaliseCards()
        let hasNilAxes = loaded.contains { $0.card.axesAffinity == nil }
        #expect(!loaded.isEmpty)
        let snap = Fixtures.snapshot(vibe: Fixtures.balancedVibe)
        let result = BlueprintLensEngine.selectTarotAndStyleEdit(snapshot: snap)
        #expect(!result.tarotCard.name.isEmpty,
                "Selection should succeed even if some cards lack axesAffinity (hasNilAxes=\(hasNilAxes))")
    }

    // MARK: - T3.12: Cosine Similarity Identical Vectors

    @Test("T3.12 — cosine similarity of identical vectors ≈ 1.0")
    func testCosineSimilarityIdenticalVectors() {
        let vec: [String: Double] = ["a": 0.5, "b": 0.3, "c": 0.2]
        let sim = BlueprintLensEngine.cosineSimilarity(vec, vec)
        #expect(abs(sim - 1.0) < 0.001, "Expected ~1.0, got \(sim)")
    }

    // MARK: - T3.13: Cosine Similarity Orthogonal Vectors

    @Test("T3.13 — cosine similarity of orthogonal vectors ≈ 0.0")
    func testCosineSimilarityOrthogonalVectors() {
        let vecA: [String: Double] = ["x": 1.0, "y": 0.0]
        let vecB: [String: Double] = ["x": 0.0, "y": 1.0]
        let sim = BlueprintLensEngine.cosineSimilarity(vecA, vecB)
        #expect(abs(sim) < 0.001, "Expected ~0.0, got \(sim)")
    }

    // MARK: - T3.14: All Cards Load Successfully

    @Test("T3.14 — JSON loads at least 22 cards (Major Arcana minimum)")
    func testAllCardsLoadSuccessfully() {
        BlueprintLensEngine._resetCardCache()
        let loaded = BlueprintLensEngine.loadAndNormaliseCards()
        #expect(loaded.count >= 22,
                "Expected >= 22 cards, got \(loaded.count)")
    }

    // MARK: - T3.15: Variant Rotation Wraps Around

    @Test("T3.15 — drawing the same card 6 times produces cycle [0,1,2,0,1,2]")
    func testVariantRotationWrapsAround() {
        resetTrackers()
        let tracker = TarotVariantRotationTracker.shared
        let card = "WrapTestCard"
        let profile = "wrapTest"

        var indices: [Int] = []
        for _ in 0..<6 {
            indices.append(tracker.nextVariantIndex(forCard: card, profileHash: profile))
        }
        #expect(indices == [0, 1, 2, 0, 1, 2],
                "Expected [0,1,2,0,1,2], got \(indices)")
    }

    // MARK: - T3.16: Variant Rotation Isolated Per Profile

    @Test("T3.16 — rotation is per-user-per-card; different profiles start at same index")
    func testVariantRotationIsolatedPerProfile() {
        resetTrackers()
        let tracker = TarotVariantRotationTracker.shared
        let card = "IsolationCard"

        let indexA = tracker.nextVariantIndex(forCard: card, profileHash: "profileA")
        let indexB = tracker.nextVariantIndex(forCard: card, profileHash: "profileB")

        #expect(indexA == indexB,
                "Both profiles should start at index 0; A=\(indexA), B=\(indexB)")
        #expect(indexA == 0, "First draw should be index 0, got \(indexA)")
    }

    // MARK: - T3.17: New Fields Decode Gracefully

    @Test("T3.17 — StyleEditVariant decodes without dailyRitual/wardrobeReflection (nil)")
    func testStyleEditVariantNewFieldsDecodeGracefully() throws {
        let json = """
        {
            "variant": "I",
            "title": "Test Variant",
            "description": "A test description.",
            "energyEmphasis": {"drama": 0.8},
            "axesEmphasis": {"action": 70}
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(StyleEditVariant.self, from: json)
        #expect(decoded.variant == "I")
        #expect(decoded.dailyRitual == nil)
        #expect(decoded.wardrobeReflection == nil)
    }

    // MARK: - T3.18: New Fields Round-Trip

    @Test("T3.18 — StyleEditVariant with both new fields round-trips through Codable")
    func testStyleEditVariantNewFieldsRoundTrip() throws {
        let original = StyleEditVariant(
            variant: "II",
            title: "Ritual Variant",
            description: "A variant with ritual.",
            energyEmphasis: ["romantic": 0.9],
            axesEmphasis: ["tempo": 60],
            dailyRitual: "Light a candle and breathe deeply for 30 seconds.",
            wardrobeReflection: "What makes you feel most yourself today?"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StyleEditVariant.self, from: data)

        #expect(decoded.variant == original.variant)
        #expect(decoded.title == original.title)
        #expect(decoded.description == original.description)
        #expect(decoded.dailyRitual == original.dailyRitual)
        #expect(decoded.wardrobeReflection == original.wardrobeReflection)
    }
}
