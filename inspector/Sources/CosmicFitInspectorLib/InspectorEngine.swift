import Foundation
import CoreLocation

public actor InspectorEngine {

    private var blueprintCache: [String: CosmicBlueprint] = [:]
    private var blueprintDiagnosticsCache: [String: BlueprintDiagnosticReport] = [:]
    private var dataset: AstrologicalStyleDataset?
    private var narrativeCache: NarrativeCacheLoader?
    private var isBootstrapped = false
    private static let debugLogPath = "/Users/ash/dev/mobile_apps/cosmicfit/.cursor/debug-455be3.log"
    private static let debugSessionId = "455be3"

    public init() {}

    public static var engineVersion: String {
        BlueprintComposer.engineVersion
    }

    // MARK: - Bootstrap

    public func bootstrap() throws {
        guard !isBootstrapped else { return }

        let inspectorDefaults = UserDefaults(suiteName: "com.cosmicfit.inspector") ?? .standard
        TarotRecencyTracker.shared = TarotRecencyTracker(userDefaults: inspectorDefaults)
        TarotVariantRotationTracker.shared = TarotVariantRotationTracker(defaults: inspectorDefaults)

        SwissEphemerisBootstrap.initialise(ephemerisDirectoryPath: ResourcePaths.swissEphemerisDirectory.path)
        VSOP87Parser.setDataDirectory(ResourcePaths.vsop87DataDirectory)
        VSOP87Parser.loadData()
        BlueprintLensEngine.setTarotCardsURL(ResourcePaths.tarotCardsURL)

        guard FileManager.default.fileExists(atPath: ResourcePaths.tarotCardsURL.path) else {
            throw InspectorError.missingResource("TarotCards.json")
        }

        guard let ds = BlueprintTokenGenerator.loadDataset(from: ResourcePaths.astrologicalStyleDatasetURL) else {
            throw InspectorError.missingResource("astrological_style_dataset.json")
        }
        self.dataset = ds

        let nc = NarrativeCacheLoader()
        guard nc.loadFromURL(ResourcePaths.blueprintNarrativeCacheURL) else {
            throw InspectorError.missingResource("blueprint_narrative_cache.json")
        }
        self.narrativeCache = nc

        isBootstrapped = true
        print("[InspectorEngine] Bootstrap complete")
    }

    // MARK: - Resolve

    public func resolve(request: InspectorRequest) throws -> InspectorResponse {
        guard isBootstrapped, let dataset = dataset, let narrativeCache = narrativeCache else {
            throw InspectorError.notBootstrapped
        }

        let runId = "inspector-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(8))"
        let resolveStart = CFAbsoluteTimeGetCurrent()
        // #region agent log
        emitDebugLog(
            runId: runId,
            hypothesisId: "H2",
            location: "InspectorEngine.swift:63",
            message: "resolve request start",
            data: [
                "targetDate": request.targetDate,
                "composeBlueprint": request.options?.composeBlueprint ?? true,
                "includeProgressed": request.options?.includeProgressed ?? true,
                "dailyFitEngineId": request.options?.dailyFitEngineId ?? "nil",
                "hasProfileId": request.options?.profileId != nil,
                "resetTarotHistory": request.options?.resetTarotHistory ?? false,
                "resetEssenceRecencyHistory": request.options?.resetEssenceRecencyHistory ?? false
            ]
        )
        // #endregion

        let birth = request.birth
        let birthDate = BirthInstantResolver.resolve(
            birthDate: birth.birthDate ?? "",
            birthTime: birth.birthTime,
            unknownTime: birth.unknownTime,
            timeZoneId: birth.timeZoneId,
            legacyDateISO: birth.dateISO
        )
        let tz = TimeZone(identifier: birth.timeZoneId) ?? TimeZone(secondsFromGMT: 0)!

        let profileHash = AppProfileIdentity.profileHash(
            birthDate: birthDate,
            latitude: birth.latitude,
            longitude: birth.longitude,
            profileId: request.options?.profileId
        )
        let displayName = DisplayNameGenerator.name(forProfileHash: profileHash)

        let engineDescriptor = resolveDailyFitEngine(from: request)

        if request.options?.resetTarotHistory == true {
            TarotRecencyTracker.shared.clearProfile(
                profileHash: profileHash,
                dailyFitEngineId: engineDescriptor.id
            )
        }

        if request.options?.resetEssenceRecencyHistory == true {
            VisibleEssenceRecencyTracker.shared.clearProfile(
                profileHash: profileHash,
                dailyFitEngineId: engineDescriptor.id
            )
        }

        let natalChart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate, latitude: birth.latitude,
            longitude: birth.longitude, timeZone: tz
        )

        let targetDate = DailyFitDateResolver.targetInstant(from: request.targetDate)

        var progressedChart: NatalChartCalculator.NatalChart? = nil
        let includeProgressed = request.options?.includeProgressed ?? true
        let progressedStart = CFAbsoluteTimeGetCurrent()
        if includeProgressed {
            // App uses today's age for all daily-fit dates, not target-date age.
            let currentAge = NatalChartCalculator.calculateCurrentAge(from: birthDate)
            progressedChart = NatalChartCalculator.calculateProgressedChart(
                birthDate: birthDate, targetAge: currentAge,
                latitude: birth.latitude, longitude: birth.longitude,
                timeZone: tz, progressAnglesMethod: .solarArc
            )
        }
        // #region agent log
        emitDebugLog(
            runId: runId,
            hypothesisId: "H3",
            location: "InspectorEngine.swift:114",
            message: "progressed chart segment complete",
            data: [
                "includeProgressed": includeProgressed,
                "durationMs": Int((CFAbsoluteTimeGetCurrent() - progressedStart) * 1000)
            ]
        )
        // #endregion

        let composeBlueprint = request.options?.composeBlueprint ?? true
        let hadBlueprintInCache = blueprintCache[profileHash] != nil
        let blueprintStart = CFAbsoluteTimeGetCurrent()
        var blueprint: CosmicBlueprint? = blueprintCache[profileHash]
        var blueprintDiagnostics: BlueprintDiagnosticReport? = blueprintDiagnosticsCache[profileHash]
        if blueprint == nil {
            guard composeBlueprint else {
                throw InspectorError.blueprintRequired
            }
            let composed = BlueprintComposer.composeFull(
                chart: natalChart, birthDate: birthDate,
                birthLocation: birth.locationLabel,
                dataset: dataset, narrativeCache: narrativeCache
            )
            blueprintCache[profileHash] = composed.blueprint
            blueprintDiagnosticsCache[profileHash] = composed.diagnostics
            blueprint = composed.blueprint
            blueprintDiagnostics = composed.diagnostics
        }
        // #region agent log
        emitDebugLog(
            runId: runId,
            hypothesisId: "H4",
            location: "InspectorEngine.swift:143",
            message: "blueprint resolution complete",
            data: [
                "hadBlueprintInCache": hadBlueprintInCache,
                "composeBlueprint": composeBlueprint,
                "durationMs": Int((CFAbsoluteTimeGetCurrent() - blueprintStart) * 1000)
            ]
        )
        // #endregion

        guard let bp = blueprint else {
            throw InspectorError.blueprintRequired
        }

        let progChart = progressedChart ?? natalChart
        let fallbackDeviceLat = InspectorDefaults.defaultDeviceLatitude
        let fallbackDeviceLon = InspectorDefaults.defaultDeviceLongitude
        let deviceLat = request.options?.deviceLatitude ?? fallbackDeviceLat
        let deviceLon = request.options?.deviceLongitude ?? fallbackDeviceLon
        let deviceCoord = CLLocationCoordinate2D(latitude: deviceLat, longitude: deviceLon)
        let transits = NatalChartCalculator.calculateTransits(natalChart: natalChart, date: targetDate, overrideDeviceLocation: deviceCoord)
        let julianDay = JulianDateCalculator.calculateJulianDate(from: targetDate)
        let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)

        // Same diagnostic pipeline as inspector tests; Stage 1/2 math matches app `generateSnapshot` + `generatePayload`.
        let diagnosticsStart = CFAbsoluteTimeGetCurrent()
        let (payload, report) = DailyFitDiagnostics.generateReport(
            natalChart: natalChart,
            progressedChart: progChart,
            transits: transits,
            moonPhaseDegrees: moonPhase,
            profileHash: profileHash,
            blueprint: bp,
            date: targetDate,
            calibration: engineDescriptor.calibration,
            dailyFitEngineId: engineDescriptor.id
        )
        // #region agent log
        emitDebugLog(
            runId: runId,
            hypothesisId: "H1",
            location: "InspectorEngine.swift:186",
            message: "diagnostics generation complete",
            data: [
                "dailyFitEngineId": engineDescriptor.id,
                "durationMs": Int((CFAbsoluteTimeGetCurrent() - diagnosticsStart) * 1000),
                "tarotScoreCount": report.tarotCardScores.count
            ]
        )
        // #endregion

        let verdicts = VerdictRunner.run(
            payload: payload,
            report: report,
            profileHash: profileHash,
            targetDate: targetDate,
            dailyFitEngineId: engineDescriptor.id
        )
        // #region agent log
        emitDebugLog(
            runId: runId,
            hypothesisId: "H2",
            location: "InspectorEngine.swift:207",
            message: "resolve request complete",
            data: [
                "dailyFitEngineId": engineDescriptor.id,
                "verdictCount": verdicts.count,
                "totalDurationMs": Int((CFAbsoluteTimeGetCurrent() - resolveStart) * 1000)
            ]
        )
        // #endregion

        return InspectorResponse(
            meta: ResponseMeta(
                engineVersion: Self.engineVersion,
                computedAt: Date(),
                profileHash: profileHash,
                dailyFitEngineId: engineDescriptor.id,
                dailyFitEngineDisplayName: engineDescriptor.displayName,
                dailyFitEngineFingerprint: engineDescriptor.fingerprint
            ),
            profile: ProfileInfo(displayName: displayName, birth: birth),
            natal: NatalChartDTO(from: natalChart),
            progressed: progressedChart.map { NatalChartDTO(from: $0) },
            blueprint: bp,
            blueprintDiagnostics: blueprintDiagnostics,
            dailyFit: DailyFitResult(payload: payload, diagnostics: report),
            verdicts: verdicts
        )
    }

    public func invalidateBlueprint(forHash hash: String) {
        blueprintCache.removeValue(forKey: hash)
        blueprintDiagnosticsCache.removeValue(forKey: hash)
    }

    public func clearTarotHistory(profileHash: String, dailyFitEngineId: String) {
        TarotRecencyTracker.shared.clearProfile(
            profileHash: profileHash,
            dailyFitEngineId: dailyFitEngineId
        )
    }

    private func resolveDailyFitEngine(from request: InspectorRequest) -> DailyFitEngineDescriptor {
        let requestedId = request.options?.dailyFitEngineId ?? InspectorDefaults.dailyFitEngineId
        if let descriptor = DailyFitEngineRegistry.descriptor(for: requestedId) {
            return descriptor
        }
        #if DEBUG
        print("[InspectorEngine] Unknown dailyFitEngineId '\(requestedId)'; falling back to production")
        #endif
        return DailyFitEngineRegistry.descriptor(for: DailyFitEngineRegistry.productionId)!
    }

    private func emitDebugLog(
        runId: String,
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any]
    ) {
        var payload: [String: Any] = [
            "sessionId": Self.debugSessionId,
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        payload["id"] = "log_\(payload["timestamp"] ?? 0)_\(UUID().uuidString.prefix(8))"

        guard JSONSerialization.isValidJSONObject(payload),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let line = String(data: jsonData, encoding: .utf8)?.appending("\n"),
              let lineData = line.data(using: .utf8) else {
            return
        }

        let logURL = URL(fileURLWithPath: Self.debugLogPath)
        if FileManager.default.fileExists(atPath: Self.debugLogPath) {
            guard let handle = try? FileHandle(forWritingTo: logURL) else { return }
            defer { try? handle.close() }
            try? handle.seekToEnd()
            try? handle.write(contentsOf: lineData)
        } else {
            try? lineData.write(to: logURL)
        }
    }
}

public enum InspectorError: Error, CustomStringConvertible {
    case notBootstrapped
    case missingResource(String)
    case blueprintRequired

    public var description: String {
        switch self {
        case .notBootstrapped: return "Engine not bootstrapped. Call bootstrap() first."
        case .missingResource(let name): return "Required resource missing: \(name)"
        case .blueprintRequired: return "Blueprint composition is required but was disabled."
        }
    }
}
