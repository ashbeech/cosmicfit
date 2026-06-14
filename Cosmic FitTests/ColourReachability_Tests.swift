//
//  ColourReachability_Tests.swift
//  Cosmic FitTests
//
//  Asserts that the stage1_experimental colour selection pipeline achieves
//  full-range coverage over a multi-day window: every Style Guide band
//  (including anchors and signatures) appears at least once in daily picks,
//  hero rotation occurs, and per-day invariants (3 unique hexes, from-blueprint) hold.
//

import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Fixtures

private let engineId = DailyFitEngineRegistry.stage1ExperimentalId
private let cal = SkyForwardV2Support.stage1Calibration

private func fullRangeBlueprint() -> CosmicBlueprint {
    func colour(_ name: String, _ hex: String, _ role: ColourRole, band: String = "") -> BlueprintColour {
        BlueprintColour(
            name: name, hexValue: hex, role: role,
            provenance: .v4Template(family: "Bright Spring", band: band.isEmpty ? role.rawValue : band, index: 0)
        )
    }
    let palette = PaletteSection(
        neutrals: [
            colour("Warm White", "#FAF9F6", .neutral, band: "neutrals"),
            colour("Sand", "#C2B280", .neutral, band: "neutrals"),
            colour("Soft Charcoal", "#36454F", .neutral, band: "neutrals"),
            colour("Espresso", "#3C2415", .neutral, band: "neutrals"),
        ],
        coreColours: [
            colour("Poppy", "#E35335", .core, band: "core"),
            colour("Coral Blaze", "#FF6F61", .core, band: "core"),
            colour("Amber", "#FFBF00", .core, band: "core"),
            colour("Forest Green", "#228B22", .core, band: "core"),
        ],
        accentColours: [
            colour("Cerulean", "#007BA7", .accent, band: "accent"),
            colour("Electric Violet", "#8B00FF", .accent, band: "accent"),
        ],
        supportColours: [
            colour("Dusty Rose", "#DCAE96", .support, band: "support"),
            colour("Sage", "#BCB88A", .support, band: "support"),
            colour("Lavender", "#E6E6FA", .support, band: "support"),
            colour("Powder Blue", "#B0E0E6", .support, band: "support"),
        ],
        lightAnchor: colour("Optic White", "#FEFEFE", .anchor, band: "lightAnchor"),
        deepAnchor: colour("True Black", "#0A0A0A", .anchor, band: "deepAnchor"),
        luminarySignature: colour("Cool Ruby", "#C84346", .signature, band: "luminarySignature"),
        rulerSignature: colour("Deep Teal", "#005F5F", .signature, band: "rulerSignature"),
        family: .brightSpring, cluster: .mediumNeutralElectric,
        variables: DerivedVariables(
            depth: .light, temperature: .warm,
            saturation: .rich, contrast: .high,
            surface: .balanced
        ),
        secondaryPull: nil,
        overrideFlags: OverrideFlags(),
        narrativeText: "Full-range test palette."
    )
    return CosmicBlueprint(
        userInfo: BlueprintUserInfo(
            birthDate: Date(timeIntervalSince1970: 0),
            birthLocation: "London, UK",
            generationDate: Date(timeIntervalSince1970: 1_700_000_000)
        ),
        styleCore: StyleCoreSection(narrativeText: "Test style."),
        textures: TexturesSection(
            goodText: "Good.", badText: "Bad.", sweetSpotText: "Sweet.",
            recommendedTextures: ["cotton", "silk", "linen", "denim"],
            avoidTextures: ["polyester"], sweetSpotKeywords: ["natural"]
        ),
        palette: palette,
        occasions: OccasionsSection(workText: "W.", intimateText: "I.", dailyText: "D."),
        hardware: HardwareSection(
            metalsText: "M.", stonesText: "S.", tipText: "T.",
            recommendedMetals: ["gold", "silver"], recommendedStones: ["ruby"]
        ),
        code: CodeSection(
            leanInto: ["bold", "electric", "energetic"],
            avoid: ["muted", "dull"],
            consider: ["playful"]
        ),
        accessory: AccessorySection(paragraphs: ["A1."]),
        pattern: PatternSection(
            narrativeText: "Pattern.", tipText: "Tip.",
            recommendedPatterns: ["abstract", "floral", "stripes"],
            avoidPatterns: ["camo"]
        ),
        generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
        engineVersion: "4.7"
    )
}

private func snapshot(for date: Date) -> DailyEnergySnapshot {
    let base = SkyForwardV2Support.date(year: 2026, month: 5, day: 21)
    let dayOffset = Int(date.timeIntervalSince(base) / 86400)
    return DailyEnergyEngine.generateSnapshot(
        natalChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarNatalSigns),
        progressedChart: SkyForwardV2Support.chart(signs: SkyForwardV2Support.briarProgressedSigns),
        transits: SkyForwardV2Support.briarTransits(for: date, dayOffset: dayOffset),
        moonPhaseDegrees: SkyForwardV2Support.moonPhase(for: date, base: base),
        profileHash: "colour_reachability_test",
        date: date,
        calibration: cal,
        mode: .stage1Experimental,
        dailyFitEngineId: engineId
    )
}

private func generatePayload(for date: Date, blueprint: CosmicBlueprint) -> DailyFitPayload {
    let snap = snapshot(for: date)
    return DailyFitPipeline.generate(
        blueprint: blueprint,
        snapshot: snap,
        calibration: cal,
        dailyFitEngineId: engineId
    )
}

// MARK: - Tests

@Suite("ColourReachability", .serialized)
struct ColourReachability_Tests {

    init() {
        TarotCalibrationTestSupport.installIsolatedTrackers()
    }

    @Test("Every Style Guide band appears in daily picks within 60 days")
    func allBandsReachable() {
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let bp = fullRangeBlueprint()
        let start = SkyForwardV2Support.date(year: 2026, month: 6, day: 1)

        var seenBands = Set<String>()

        // First payload gives us the allPaletteHexes from the engine
        let firstPayload = generatePayload(for: start, blueprint: bp)
        let allBlueprintHexes = Set(firstPayload.dailyPalette.allPaletteHexes.map { ColourRecencyTracker.normalizeHex($0) })

        let anchorHexes: Set<String> = {
            var s = Set<String>()
            if let h = bp.palette.lightAnchor?.hexValue { s.insert(ColourRecencyTracker.normalizeHex(h)) }
            if let h = bp.palette.deepAnchor?.hexValue { s.insert(ColourRecencyTracker.normalizeHex(h)) }
            return s
        }()
        let signatureHexes: Set<String> = {
            var s = Set<String>()
            if let h = bp.palette.luminarySignature?.hexValue { s.insert(ColourRecencyTracker.normalizeHex(h)) }
            if let h = bp.palette.rulerSignature?.hexValue { s.insert(ColourRecencyTracker.normalizeHex(h)) }
            return s
        }()

        var anchorSeen = false
        var signatureSeen = false

        for offset in 0..<60 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let payload = generatePayload(for: date, blueprint: bp)
            let picks = payload.dailyPalette.colours

            for pick in picks {
                let norm = ColourRecencyTracker.normalizeHex(pick.hexValue)
                #expect(allBlueprintHexes.contains(norm),
                        "Colour \(pick.name) hex \(pick.hexValue) not in blueprint palette")
                seenBands.insert(pick.role)
                if anchorHexes.contains(norm) { anchorSeen = true }
                if signatureHexes.contains(norm) { signatureSeen = true }
            }
        }

        #expect(seenBands.contains("anchor"), "Anchor band never appeared in 60 days")
        #expect(anchorSeen, "No anchor hex appeared in 60 days")
        #expect(signatureSeen, "No signature hex appeared in 60 days")
        #expect(seenBands.contains("core"), "Core band never appeared")
        #expect(seenBands.contains("neutral"), "Neutral band never appeared")
        #expect(seenBands.contains("support"), "Support band never appeared")
    }

    @Test("Three unique hexes every day (T4.4c invariant)")
    func threeUniqueHexes() {
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let bp = fullRangeBlueprint()
        let start = SkyForwardV2Support.date(year: 2026, month: 6, day: 1)

        for offset in 0..<45 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let payload = generatePayload(for: date, blueprint: bp)
            let hexes = payload.dailyPalette.colours.map(\.hexValue)
            let unique = Set(hexes.map { ColourRecencyTracker.normalizeHex($0) })
            #expect(unique.count == 3, "Day \(offset): expected 3 unique hexes, got \(unique.count): \(hexes)")
        }
    }

    @Test("All daily picks come from the blueprint palette (T4.2 invariant)")
    func allFromBlueprint() {
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let bp = fullRangeBlueprint()
        let start = SkyForwardV2Support.date(year: 2026, month: 6, day: 1)
        let firstPayload = generatePayload(for: start, blueprint: bp)
        let allHexes = Set(firstPayload.dailyPalette.allPaletteHexes.map { ColourRecencyTracker.normalizeHex($0) })

        for offset in 0..<45 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let payload = generatePayload(for: date, blueprint: bp)
            for pick in payload.dailyPalette.colours {
                let norm = ColourRecencyTracker.normalizeHex(pick.hexValue)
                #expect(allHexes.contains(norm),
                        "Day \(offset): \(pick.name) (\(pick.hexValue)) not in blueprint")
            }
        }
    }

    @Test("Hero is not constant — rotation occurs over 30 days")
    func heroRotates() {
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let bp = fullRangeBlueprint()
        let start = SkyForwardV2Support.date(year: 2026, month: 6, day: 1)

        var heroHexes = Set<String>()
        for offset in 0..<30 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let payload = generatePayload(for: date, blueprint: bp)
            if let hero = payload.dailyPalette.colours.first {
                heroHexes.insert(ColourRecencyTracker.normalizeHex(hero.hexValue))
            }
        }
        #expect(heroHexes.count >= 3, "Hero should rotate — saw only \(heroHexes.count) distinct heroes in 30 days")
    }

    @Test("Reinforce/high-drama days keep a statement-role hero (coherence guard)")
    func statementHeroOnReinforceDays() {
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let bp = fullRangeBlueprint()
        let start = SkyForwardV2Support.date(year: 2026, month: 6, day: 1)

        let statementRoles: Set<String> = ["accent", "statement", "signature"]

        for offset in 0..<45 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let snap = snapshot(for: date)
            let rawEssence = BlueprintLensEngine.resolveEssenceProfile(from: snap, mode: .stage1Experimental)
            let rawSilhouette = BlueprintLensEngine.deriveSilhouetteProfile(
                from: bp, snapshot: snap, calibration: cal, mode: .stage1Experimental
            )
            let (plan, _) = DailyNarrativeSelector.select(
                snapshot: snap,
                blueprint: bp,
                calibration: cal,
                precomputedEssence: rawEssence,
                precomputedSilhouette: rawSilhouette,
                dailyFitEngineId: engineId
            )

            let payload = generatePayload(for: date, blueprint: bp)

            if plan.relationship == .reinforce && plan.paletteDirective.maxStatementSlots >= 2 {
                if let hero = payload.dailyPalette.colours.first {
                    #expect(statementRoles.contains(hero.role),
                            "Day \(offset) (reinforce): hero role '\(hero.role)' should be statement-side")
                }
            }
        }
    }

    @Test("Anchor appears as hero at least once within 60 grounded-eligible days")
    func anchorAsHero() {
        TarotCalibrationTestSupport.resetTrackersForProfile()
        let bp = fullRangeBlueprint()
        let start = SkyForwardV2Support.date(year: 2026, month: 6, day: 1)

        var anchorAsHeroSeen = false
        let anchorHexes: Set<String> = {
            var s = Set<String>()
            if let h = bp.palette.lightAnchor?.hexValue { s.insert(ColourRecencyTracker.normalizeHex(h)) }
            if let h = bp.palette.deepAnchor?.hexValue { s.insert(ColourRecencyTracker.normalizeHex(h)) }
            return s
        }()

        for offset in 0..<60 {
            let date = start.addingTimeInterval(Double(offset) * 86400)
            let payload = generatePayload(for: date, blueprint: bp)
            if let hero = payload.dailyPalette.colours.first {
                let norm = ColourRecencyTracker.normalizeHex(hero.hexValue)
                if anchorHexes.contains(norm) {
                    anchorAsHeroSeen = true
                    break
                }
            }
        }
        #expect(anchorAsHeroSeen, "Anchor never appeared as hero in 60 days")
    }

    @Test("ColourRecencyTracker stores and retrieves correctly")
    func trackerBasics() {
        let defaults = UserDefaults(suiteName: "com.cosmicfit.colour.test.\(UUID().uuidString)")!
        let tracker = ColourRecencyTracker(defaults: defaults)
        let today = SkyForwardV2Support.date(year: 2026, month: 6, day: 10)
        let yesterday = today.addingTimeInterval(-86400)

        tracker.storeDailyColours(
            shownHexes: ["#FF0000", "#00FF00", "#0000FF"],
            heroHex: "#FF0000",
            profileHash: "test_profile",
            date: yesterday,
            dailyFitEngineId: "test_engine"
        )

        let daysSinceRed = tracker.daysSinceShown(
            hex: "#FF0000", profileHash: "test_profile",
            referenceDate: today, dailyFitEngineId: "test_engine"
        )
        #expect(daysSinceRed == 1)

        let daysSinceHeroRed = tracker.daysSinceHero(
            hex: "#FF0000", profileHash: "test_profile",
            referenceDate: today, dailyFitEngineId: "test_engine"
        )
        #expect(daysSinceHeroRed == 1)

        let daysSinceHeroGreen = tracker.daysSinceHero(
            hex: "#00FF00", profileHash: "test_profile",
            referenceDate: today, dailyFitEngineId: "test_engine"
        )
        #expect(daysSinceHeroGreen == nil)

        let neverShown = tracker.daysSinceShown(
            hex: "#FFFFFF", profileHash: "test_profile",
            referenceDate: today, dailyFitEngineId: "test_engine"
        )
        #expect(neverShown == nil)

        let debt = tracker.coverageDebt(
            hex: "#FFFFFF", profileHash: "test_profile",
            referenceDate: today, dailyFitEngineId: "test_engine"
        )
        #expect(debt == 1.0)

        let redDebt = tracker.coverageDebt(
            hex: "#FF0000", profileHash: "test_profile",
            referenceDate: today, dailyFitEngineId: "test_engine"
        )
        #expect(redDebt > 0.0 && redDebt < 0.15)
    }
}
