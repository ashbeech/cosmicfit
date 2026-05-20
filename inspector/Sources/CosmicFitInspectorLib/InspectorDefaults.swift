import Foundation

public struct DailyFitEngineListing: Encodable {
    public let id: String
    public let displayName: String
    public let summary: String
    public let isExperimental: Bool
    public let fingerprint: String
}

public enum InspectorDefaults {

    /// Server default Daily Fit engine id from `DAILY_FIT_ENGINE_ID`, validated against the registry.
    public static let dailyFitEngineId: String = {
        let raw = ProcessInfo.processInfo.environment["DAILY_FIT_ENGINE_ID"]
            ?? DailyFitEngineRegistry.productionId
        if DailyFitEngineRegistry.descriptor(for: raw) != nil {
            return raw
        }
        #if DEBUG
        print("[InspectorDefaults] Unknown DAILY_FIT_ENGINE_ID '\(raw)'; using production")
        #endif
        return DailyFitEngineRegistry.productionId
    }()

    public static var dailyFitEngineCount: Int {
        DailyFitEngineRegistry.allDescriptors.count
    }

    public static func dailyFitEngineListings() -> [DailyFitEngineListing] {
        DailyFitEngineRegistry.allDescriptors.map {
            DailyFitEngineListing(
                id: $0.id,
                displayName: $0.displayName,
                summary: $0.summary,
                isExperimental: $0.isExperimental,
                fingerprint: $0.fingerprint
            )
        }
    }
}
