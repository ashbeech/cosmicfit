import Foundation
import CoreLocation

public actor InspectorEngine {

    private var blueprintCache: [String: CosmicBlueprint] = [:]
    private var blueprintDiagnosticsCache: [String: BlueprintDiagnosticReport] = [:]
    private var dataset: AstrologicalStyleDataset?
    private var narrativeCache: NarrativeCacheLoader?
    private var isBootstrapped = false

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

        let natalChart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate, latitude: birth.latitude,
            longitude: birth.longitude, timeZone: tz
        )

        let targetDate = DailyFitDateResolver.targetInstant(from: request.targetDate)

        var progressedChart: NatalChartCalculator.NatalChart? = nil
        let includeProgressed = request.options?.includeProgressed ?? true
        if includeProgressed {
            // App uses today's age for all daily-fit dates, not target-date age.
            let currentAge = NatalChartCalculator.calculateCurrentAge(from: birthDate)
            progressedChart = NatalChartCalculator.calculateProgressedChart(
                birthDate: birthDate, targetAge: currentAge,
                latitude: birth.latitude, longitude: birth.longitude,
                timeZone: tz, progressAnglesMethod: .solarArc
            )
        }

        let composeBlueprint = request.options?.composeBlueprint ?? true
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

        let verdicts = VerdictRunner.run(
            payload: payload,
            report: report,
            profileHash: profileHash,
            targetDate: targetDate,
            dailyFitEngineId: engineDescriptor.id
        )

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
