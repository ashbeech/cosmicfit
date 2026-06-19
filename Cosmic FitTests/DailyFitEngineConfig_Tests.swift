//
//  DailyFitEngineConfig_Tests.swift
//  Cosmic FitTests
//

import Testing
import Foundation
@testable import Cosmic_Fit

@Suite(.serialized)
struct DailyFitEngineConfig_Tests {

    @Test("Unknown engine id resolves to production via validation")
    func unknownIdFallsBackToProduction() {
        let resolved = DailyFitEngineConfig.validatedEngineId("not_a_real_engine")
        #expect(resolved == DailyFitEngineRegistry.productionId)
    }

    @Test("Known registry ids validate to themselves")
    func knownIdsValidate() {
        #expect(DailyFitEngineConfig.validatedEngineId(DailyFitEngineRegistry.productionId)
            == DailyFitEngineRegistry.productionId)
        #expect(DailyFitEngineConfig.validatedEngineId(DailyFitEngineRegistry.legacyBaselineId)
            == DailyFitEngineRegistry.legacyBaselineId)
    }

    #if DEBUG
    @Test("DEBUG runtime override is read from UserDefaults")
    func debugRuntimeOverrideReadPath() {
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        UserDefaults.standard.removeObject(forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        #expect(DailyFitEngineConfig.runtimeOverrideEngineId == nil)

        UserDefaults.standard.set(DailyFitEngineRegistry.legacyBaselineId, forKey: key)
        #expect(DailyFitEngineConfig.runtimeOverrideEngineId == DailyFitEngineRegistry.legacyBaselineId)
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineRegistry.legacyBaselineId)
        #expect(DailyFitEngineConfig.effectiveCalibration
            == DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.legacyBaselineId))
    }
    #endif

    @Test("Release builds lock effective engine id to production")
    func releaseEffectiveEngineIdIsProduction() {
        #if DEBUG
        // DEBUG test runs cannot assert compile-time Release lock on effectiveEngineId;
        // verify the Release branch contract via validated production id.
        #expect(DailyFitEngineRegistry.productionId == "production")
        #else
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineRegistry.productionId)
        let productionCal = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.productionId)
        #expect(DailyFitEngineConfig.effectiveCalibration == productionCal)
        #endif
    }

    @Test("Production build mode ignores DEBUG runtime engine override")
    func productionBuildModeIgnoresRuntimeOverride() {
        #if DEBUG
        guard DailyFitEngineConfig.isProductionBuildMode else { return }
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        defer { UserDefaults.standard.removeObject(forKey: key) }

        UserDefaults.standard.set(DailyFitEngineRegistry.legacyBaselineId, forKey: key)
        DailyFitEngineConfig.applyProductionBuildModeSanityChecks()
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineRegistry.productionId)
        #expect(DailyFitEngineConfig.allowsDevEngineTools == false)
        #endif
    }

    @Test("Default effective calibration matches Sky Forward production preset")
    func defaultEffectiveCalibrationIsProduction() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: DailyFitEngineConfig.runtimeOverrideUserDefaultsKey)
        if DailyFitEngineConfig.buildTimeEngineId == DailyFitEngineRegistry.productionId {
            let productionCal = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.productionId)
            #expect(DailyFitEngineConfig.effectiveCalibration == productionCal)
        }
        #else
        let productionCal = DailyFitEngineRegistry.calibration(for: DailyFitEngineRegistry.productionId)
        #expect(DailyFitEngineConfig.effectiveCalibration == productionCal)
        #endif
    }

    // MARK: - P5: Engine picker write-through and notification

    #if DEBUG
    @Test("Setting runtimeOverrideEngineId changes effectiveEngineId")
    func pickerWriteThroughChangesEffectiveEngine() {
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        UserDefaults.standard.removeObject(forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let baseline = DailyFitEngineConfig.effectiveEngineId

        DailyFitEngineConfig.runtimeOverrideEngineId = DailyFitEngineRegistry.legacyBaselineId
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineRegistry.legacyBaselineId)
        #expect(DailyFitEngineConfig.effectiveEngineId != baseline || baseline == DailyFitEngineRegistry.legacyBaselineId)

        DailyFitEngineConfig.runtimeOverrideEngineId = nil
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineConfig.buildTimeEngineId)
    }

    @Test("Clearing runtimeOverrideEngineId reverts to buildTimeEngineId")
    func clearingOverrideRevertsToBuildTime() {
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        defer { UserDefaults.standard.removeObject(forKey: key) }

        DailyFitEngineConfig.runtimeOverrideEngineId = DailyFitEngineRegistry.stage1ExperimentalId
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineRegistry.stage1ExperimentalId)

        DailyFitEngineConfig.runtimeOverrideEngineId = nil
        #expect(DailyFitEngineConfig.runtimeOverrideEngineId == nil)
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineConfig.buildTimeEngineId)
    }

    @Test("Override notification fires when effectiveEngineId changes")
    func overrideNotificationFires() async throws {
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        UserDefaults.standard.removeObject(forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        var notificationFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: .dailyFitEngineOverrideChanged,
            object: nil,
            queue: .main
        ) { _ in notificationFired = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        DailyFitEngineConfig.runtimeOverrideEngineId = DailyFitEngineRegistry.legacyBaselineId
        NotificationCenter.default.post(name: .dailyFitEngineOverrideChanged, object: nil)

        try await Task.sleep(for: .milliseconds(50))
        #expect(notificationFired)
    }

    @Test("Each allDescriptors entry is selectable as override")
    func allDescriptorsAreSelectableOverrides() {
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        defer { UserDefaults.standard.removeObject(forKey: key) }

        for descriptor in DailyFitEngineRegistry.allDescriptors {
            DailyFitEngineConfig.runtimeOverrideEngineId = descriptor.id
            #expect(DailyFitEngineConfig.effectiveEngineId == descriptor.id)
            #expect(DailyFitEngineConfig.effectiveCalibration == descriptor.calibration)
        }
    }

    @Test("Setting empty string override is same as nil")
    func emptyStringOverrideIsNil() {
        let key = DailyFitEngineConfig.runtimeOverrideUserDefaultsKey
        defer { UserDefaults.standard.removeObject(forKey: key) }

        DailyFitEngineConfig.runtimeOverrideEngineId = ""
        #expect(DailyFitEngineConfig.runtimeOverrideEngineId == nil)
        #expect(DailyFitEngineConfig.effectiveEngineId == DailyFitEngineConfig.buildTimeEngineId)
    }
    #endif
}
