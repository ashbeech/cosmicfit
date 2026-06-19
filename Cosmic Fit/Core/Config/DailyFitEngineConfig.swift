//
//  DailyFitEngineConfig.swift
//  Cosmic Fit
//
//  Resolves the active Daily Fit engine preset from build config and (DEBUG) UserDefaults.
//

import Foundation

enum DailyFitEngineConfig {

    static let plistEngineIdKey = "DAILY_FIT_ENGINE_ID"

    #if DEBUG
    static let runtimeOverrideUserDefaultsKey = "dailyFitEngineIdRuntimeOverride"
    #endif

    /// Engine id from Info.plist (`DAILY_FIT_ENGINE_ID` via xcconfig). Validated against the registry.
    static let buildTimeEngineId: String = {
        validatedEngineId(rawBuildTimeEngineIdFromPlist() ?? DailyFitEngineRegistry.productionId)
    }()

    /// `true` when this install is built for production / App Store behaviour (Sky Forward, no dev engine tools).
    /// DEBUG builds with `DAILY_FIT_ENGINE_ID = production` in xcconfig match Release here.
    static var isProductionBuildMode: Bool {
        #if DEBUG
        return buildTimeEngineId == DailyFitEngineRegistry.productionId
        #else
        return true
        #endif
    }

    /// Profile engine picker + force refresh — only when DEBUG and xcconfig selects a non-production preset.
    static var allowsDevEngineTools: Bool {
        #if DEBUG
        return !isProductionBuildMode
        #else
        return false
        #endif
    }

    /// Clears stale DEBUG engine override when running a production-configured build.
    static func applyProductionBuildModeSanityChecks() {
        #if DEBUG
        guard isProductionBuildMode else { return }
        runtimeOverrideEngineId = nil
        #endif
    }

    #if DEBUG
    /// DEBUG-only Profile override (picker in P5). Read/write for tests and future UI.
    static var runtimeOverrideEngineId: String? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: runtimeOverrideUserDefaultsKey),
                  !raw.isEmpty else {
                return nil
            }
            return raw
        }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: runtimeOverrideUserDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: runtimeOverrideUserDefaultsKey)
            }
        }
    }
    #endif

    /// Process-wide effective engine id (build + DEBUG override). Release always returns `production`.
    static var effectiveEngineId: String {
        #if DEBUG
        guard allowsDevEngineTools else {
            return DailyFitEngineRegistry.productionId
        }
        let candidate = runtimeOverrideEngineId ?? buildTimeEngineId
        return validatedEngineId(candidate)
        #else
        return DailyFitEngineRegistry.productionId
        #endif
    }

    static var effectiveCalibration: DailyFitCalibration {
        DailyFitEngineRegistry.calibration(for: effectiveEngineId)
    }

    // MARK: - Validation

    static func validatedEngineId(_ raw: String) -> String {
        if DailyFitEngineRegistry.descriptor(for: raw) != nil {
            return raw
        }
        logUnknownEngineWarning(raw)
        return DailyFitEngineRegistry.productionId
    }

    private static func rawBuildTimeEngineIdFromPlist() -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: plistEngineIdKey) as? String,
              !raw.isEmpty,
              !raw.hasPrefix("$(") else {
            return nil
        }
        return raw
    }

    private static func logUnknownEngineWarning(_ id: String) {
        #if DEBUG
        print("[DailyFitEngineConfig] Unknown dailyFitEngineId '\(id)'; falling back to production")
        #endif
    }
}
