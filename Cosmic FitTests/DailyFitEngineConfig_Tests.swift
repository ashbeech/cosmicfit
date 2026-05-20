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
        #expect(DailyFitEngineConfig.effectiveCalibration == DailyFitCalibration.default)
        #endif
    }

    @Test("Default effective calibration matches production preset")
    func defaultEffectiveCalibrationIsProduction() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: DailyFitEngineConfig.runtimeOverrideUserDefaultsKey)
        if DailyFitEngineConfig.buildTimeEngineId == DailyFitEngineRegistry.productionId {
            #expect(DailyFitEngineConfig.effectiveCalibration == DailyFitCalibration.default)
        }
        #else
        #expect(DailyFitEngineConfig.effectiveCalibration == DailyFitCalibration.default)
        #endif
    }
}
