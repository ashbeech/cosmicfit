//
//  DailyFitEngineConfig.swift
//  CosmicFitInspectorLib
//
//  Minimal shim so symlinked app sources that reference DailyFitEngineConfig compile.
//  The inspector resolves engine IDs per-request via InspectorEngine, not via this type.
//

import Foundation

enum DailyFitEngineConfig {
    static var effectiveEngineId: String {
        DailyFitEngineRegistry.productionId
    }

    static var effectiveCalibration: DailyFitCalibration {
        DailyFitEngineRegistry.calibration(for: effectiveEngineId)
    }
}
