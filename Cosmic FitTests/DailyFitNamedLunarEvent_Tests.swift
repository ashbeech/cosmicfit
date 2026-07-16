//
//  DailyFitNamedLunarEvent_Tests.swift
//  Cosmic FitTests
//
//  Sky Forward v1.0.2 §6h follow-up — named lunar events (Supermoon / Micromoon / Eclipse)
//  surface into the narrative + accent path. Event dates come from the pinned 2026 almanac
//  (docs/fixtures/lunar_events_2026.json); the detector itself is cross-checked against that
//  almanac in inspector/Tests/InspectorEngineTests/LunarEventDetector_Tests.swift. These tests
//  cover the SURFACING: snapshot/payload carry the named event, the salience profile leads
//  with it (accent influence), and pre-v1.0.2 paths plus ordinary days stay untouched.
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite
struct DailyFitNamedLunarEvent_Tests {

    typealias S = SkyForwardV2Support

    static let hash = "named_event_v102"
    static let specialLabels: Set<String> = ["Supermoon", "Micromoon", "Solar Eclipse", "Lunar Eclipse"]

    /// Noon-UTC instant — the once-daily production sampling cadence (matches the detector
    /// cross-check and the fidelity gates).
    static func noon(_ year: Int, _ month: Int, _ day: Int) -> Date {
        S.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    /// The pinned 2026 almanac's special-event days.
    static let specialDays: [(date: Date, label: String)] = [
        (noon(2026, 1, 3), "Supermoon"),
        (noon(2026, 11, 24), "Supermoon"),
        (noon(2026, 12, 24), "Supermoon"),
        (noon(2026, 3, 3), "Lunar Eclipse"),
        (noon(2026, 8, 28), "Lunar Eclipse"),
        (noon(2026, 2, 17), "Solar Eclipse"),
        (noon(2026, 8, 12), "Solar Eclipse"),
    ]

    /// Mid-cycle day, no syzygy within the ±7° window (full moon Apr 2, new moon Apr 17).
    static let ordinaryDay = noon(2026, 4, 10)
    /// Plain full moon (Pink Moon) — full-moon family but NOT a special event in the almanac.
    static let plainFullMoonDay = noon(2026, 4, 2)

    static func snapshot(for date: Date, engineId: String) -> DailyEnergySnapshot {
        let base = S.date(year: 2026, month: 5, day: 21)
        let dayOffset = Int(date.timeIntervalSince(base) / 86400)
        return DailyEnergyEngine.generateSnapshot(
            natalChart: S.chart(signs: S.briarNatalSigns),
            progressedChart: S.chart(signs: S.briarProgressedSigns),
            transits: S.briarTransits(for: date, dayOffset: dayOffset),
            moonPhaseDegrees: S.moonPhase(for: date, base: base),
            profileHash: hash,
            date: date,
            calibration: DailyFitEngineRegistry.calibration(for: engineId),
            mode: DailyFitEngineRegistry.mode(for: engineId),
            dailyFitEngineId: engineId
        )
    }

    static func v102Snapshot(for date: Date) -> DailyEnergySnapshot {
        snapshot(for: date, engineId: S.gateEngineId)
    }

    static func v102Plan(for date: Date) -> DailyNarrativePlan {
        let snapshot = v102Snapshot(for: date)
        let calibration = S.gateCalibration
        let essence = BlueprintLensEngine.resolveEssenceProfile(from: snapshot, mode: S.gateMode)
        let silhouette = BlueprintLensEngine.deriveSilhouetteProfile(
            from: S.briarBlueprint, snapshot: snapshot, calibration: calibration, mode: S.gateMode
        )
        let (plan, _) = DailyNarrativeSelector.select(
            snapshot: snapshot, blueprint: S.briarBlueprint, calibration: calibration,
            precomputedEssence: essence, precomputedSilhouette: silhouette,
            dailyFitEngineId: S.gateEngineId
        )
        return plan
    }

    // MARK: - Special-event days reach the surface

    @Test("All 2026 almanac special-event days: snapshot + payload carry the named event")
    func specialDaysCarryNamedEvent() {
        for (date, label) in Self.specialDays {
            let snapshot = Self.v102Snapshot(for: date)
            #expect(snapshot.lunarContext.namedEvent?.label == label,
                    "\(S.isoString(for: date)): expected \(label), got \(String(describing: snapshot.lunarContext.namedEvent))")
            if let strength = snapshot.lunarContext.namedEvent?.strength {
                #expect(strength >= 0.0 && strength <= 1.0)
            }

            // Payload passthrough — what the device build reads.
            let payload = DailyFitPipeline.generate(
                blueprint: S.briarBlueprint,
                snapshot: snapshot,
                calibration: S.gateCalibration,
                dailyFitEngineId: S.gateEngineId
            )
            #expect(payload.lunarContext.namedEvent?.label == label,
                    "\(S.isoString(for: date)): payload must carry the named event")
        }
    }

    @Test("Special-event days: salience profile leads with the event driver (accent influence)")
    func specialDaysLeadSalience() {
        for (date, label) in Self.specialDays {
            let snapshot = Self.v102Snapshot(for: date)
            let top = snapshot.skySalience?.topDrivers.first
            #expect(top?.planet == "Moon" && top?.aspect == label,
                    "\(S.isoString(for: date)): top salience driver should be the \(label) event, got \(String(describing: top))")
            #expect(top?.salience == 1.0)
            #expect(top?.essenceCategory == .playful,
                    "Event driver must carry the Moon's essence category so the accent ranking reads it")
            // One entry per essence category is preserved in topDrivers (dedup invariant).
            let cats = (snapshot.skySalience?.topDrivers ?? []).compactMap(\.essenceCategory)
            #expect(cats.count == Set(cats).count)
        }
    }

    @Test("Special-event days: narrative plan references the event and reads high/peak intensity")
    func specialDaysReachNarrativePlan() {
        for (date, label) in Self.specialDays {
            let plan = Self.v102Plan(for: date)
            #expect(plan.skyJustification.contains(label),
                    "\(S.isoString(for: date)): skyJustification should reference \(label); got \"\(plan.skyJustification)\"")
            #expect(plan.salienceDrivers.first?.contains(label) == true,
                    "\(S.isoString(for: date)): leading salience driver should reference \(label)")
            #expect(plan.intensityLevel == .high || plan.intensityLevel == .peak,
                    "\(S.isoString(for: date)): a named event day should read high/peak intensity, got \(plan.intensityLevel)")
        }
    }

    // MARK: - Ordinary days do NOT get named-event surfacing

    @Test("Ordinary day: no named event on snapshot, salience, or plan")
    func ordinaryDayHasNoNamedEvent() {
        let snapshot = Self.v102Snapshot(for: Self.ordinaryDay)
        #expect(snapshot.lunarContext.namedEvent == nil)
        for driver in snapshot.skySalience?.topDrivers ?? [] {
            #expect(!Self.specialLabels.contains(driver.aspect),
                    "Ordinary day must not carry an event driver; got \(driver.aspect)")
        }
        let plan = Self.v102Plan(for: Self.ordinaryDay)
        for label in Self.specialLabels {
            #expect(!plan.skyJustification.contains(label))
        }
    }

    @Test("Plain full moon: D2 phase label applies but no special-event surfacing")
    func plainFullMoonIsNotSpecial() {
        let snapshot = Self.v102Snapshot(for: Self.plainFullMoonDay)
        #expect(snapshot.lunarContext.phaseName == "Full Moon",
                "D2 override: a true full moon always reads \"Full Moon\"")
        #expect(snapshot.lunarContext.namedEvent == nil,
                "A plain full moon is not a named special event")
        for driver in snapshot.skySalience?.topDrivers ?? [] {
            #expect(!Self.specialLabels.contains(driver.aspect))
        }
    }

    // MARK: - v1.0.1 rollback path untouched

    @Test("v1.0.1 rollback preset: no named-event detection or surfacing, even on event days")
    func rollbackPathUntouched() {
        for (date, _) in Self.specialDays {
            let snapshot = Self.snapshot(for: date, engineId: DailyFitEngineRegistry.skyForwardV101Id)
            #expect(snapshot.lunarContext.namedEvent == nil,
                    "\(S.isoString(for: date)): v1.0.1 path must never attach a named event")
            for driver in snapshot.skySalience?.topDrivers ?? [] {
                #expect(!Self.specialLabels.contains(driver.aspect),
                        "\(S.isoString(for: date)): v1.0.1 salience must not carry an event driver")
            }
        }
    }

    // MARK: - Determinism

    @Test("Named-event surfacing is deterministic (pure function of chart + date)")
    func namedEventDeterministic() {
        let date = Self.specialDays[0].date
        let s1 = Self.v102Snapshot(for: date)
        let s2 = Self.v102Snapshot(for: date)
        #expect(s1.lunarContext == s2.lunarContext)
        #expect(s1.skySalience?.topDrivers == s2.skySalience?.topDrivers)
        #expect(s1.skySalience?.dominantNarrative == s2.skySalience?.dominantNarrative)
    }

    // MARK: - Frozen-payload backward compatibility

    @Test("Legacy lunarContext JSON (no namedEvent key) still decodes; nil is omitted on encode")
    func legacyLunarContextDecodes() throws {
        let legacyJSON = #"{"phaseName":"Waxing Crescent","isWaxing":true,"element":"Air","phaseDegrees":60}"#
        let decoded = try JSONDecoder().decode(LunarContext.self, from: Data(legacyJSON.utf8))
        #expect(decoded.namedEvent == nil)

        let reencoded = try JSONEncoder().encode(decoded)
        let text = String(decoding: reencoded, as: UTF8.self)
        #expect(!text.contains("namedEvent"),
                "nil namedEvent must be omitted so pre-v1.0.2 output stays byte-identical")
    }
}
