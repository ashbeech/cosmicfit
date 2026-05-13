import Foundation

public actor InspectorEngine {

    private var blueprintCache: [String: CosmicBlueprint] = [:]
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

        SwissEphemerisBootstrap.initialise(ephemerisDirectoryPath: ResourcePaths.swissEphemerisDirectory.path)
        VSOP87Parser.setDataDirectory(ResourcePaths.vsop87DataDirectory)
        VSOP87Parser.loadData()

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
        let profileHash = DisplayNameGenerator.profileHash(
            dateISO: birth.dateISO, latitude: birth.latitude, longitude: birth.longitude,
            timeZoneId: birth.timeZoneId, unknownTime: birth.unknownTime
        )
        let displayName = DisplayNameGenerator.name(forProfileHash: profileHash)

        let birthDate = parseBirthDate(birth)
        let tz = TimeZone(identifier: birth.timeZoneId) ?? TimeZone(secondsFromGMT: 0)!

        let natalChart = NatalChartCalculator.calculateNatalChart(
            birthDate: birthDate, latitude: birth.latitude,
            longitude: birth.longitude, timeZone: tz
        )

        let targetDate = parseTargetDate(request.targetDate)

        var progressedChart: NatalChartCalculator.NatalChart? = nil
        let includeProgressed = request.options?.includeProgressed ?? true
        if includeProgressed {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: targetDate).year ?? 30
            let clampedAge = max(0, age)
            progressedChart = NatalChartCalculator.calculateProgressedChart(
                birthDate: birthDate, targetAge: clampedAge,
                latitude: birth.latitude, longitude: birth.longitude,
                timeZone: tz, progressAnglesMethod: .solarArc
            )
        }

        let shouldCompose = request.options?.composeBlueprint ?? true
        var blueprint: CosmicBlueprint? = nil
        if shouldCompose {
            if let cached = blueprintCache[profileHash] {
                blueprint = cached
            } else {
                let composed = BlueprintComposer.compose(
                    chart: natalChart, birthDate: birthDate,
                    birthLocation: birth.locationLabel,
                    dataset: dataset, narrativeCache: narrativeCache
                )
                blueprintCache[profileHash] = composed
                blueprint = composed
            }
        }

        guard let bp = blueprint else {
            throw InspectorError.blueprintRequired
        }

        let progChart = progressedChart ?? natalChart
        let transits = NatalChartCalculator.calculateTransits(natalChart: natalChart, date: targetDate)
        let julianDay = JulianDateCalculator.calculateJulianDate(from: targetDate)
        let moonPhase = AstronomicalCalculator.calculateLunarPhase(julianDay: julianDay)

        let (payload, report) = DailyFitDiagnostics.generateReport(
            natalChart: natalChart,
            progressedChart: progChart,
            transits: transits,
            moonPhaseDegrees: moonPhase,
            profileHash: profileHash,
            blueprint: bp,
            date: targetDate
        )

        let verdicts = VerdictRunner.run(payload: payload, report: report)

        return InspectorResponse(
            meta: ResponseMeta(
                engineVersion: Self.engineVersion,
                computedAt: Date(),
                profileHash: profileHash
            ),
            profile: ProfileInfo(displayName: displayName, birth: birth),
            natal: NatalChartDTO(from: natalChart),
            progressed: progressedChart.map { NatalChartDTO(from: $0) },
            blueprint: bp,
            dailyFit: DailyFitResult(payload: payload, diagnostics: report),
            verdicts: verdicts
        )
    }

    public func invalidateBlueprint(forHash hash: String) {
        blueprintCache.removeValue(forKey: hash)
    }

    // MARK: - Date Parsing

    private func parseBirthDate(_ birth: BirthInput) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: birth.dateISO) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: birth.dateISO) { return d }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: birth.timeZoneId) ?? TimeZone(secondsFromGMT: 0)
        if let d = df.date(from: birth.dateISO) {
            if birth.unknownTime {
                return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: d) ?? d
            }
            return d
        }
        return Date()
    }

    private func parseTargetDate(_ dateStr: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.date(from: dateStr) ?? Date()
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
