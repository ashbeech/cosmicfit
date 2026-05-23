import Foundation

public struct InspectorResponse: Encodable {
    public let meta: ResponseMeta
    public let profile: ProfileInfo
    let natal: NatalChartDTO
    let progressed: NatalChartDTO?
    let blueprint: CosmicBlueprint?
    let blueprintDiagnostics: BlueprintDiagnosticReport?
    let dailyFit: DailyFitResult
    let verdicts: [VerdictRow]
}

public struct ResponseMeta: Encodable {
    public let engineVersion: String
    public let computedAt: Date
    public let profileHash: String
    public let dailyFitEngineId: String
    public let dailyFitEngineDisplayName: String
    public let dailyFitEngineFingerprint: String
}

public struct ProfileInfo: Encodable {
    public let displayName: String
    public let birth: BirthInput
}

struct NatalChartDTO: Encodable {
    let planets: [PlanetDTO]
    let ascendant: Double
    let midheaven: Double
    let descendant: Double
    let imumCoeli: Double
    let houseCusps: [Double]
    let wholeSignHouseCusps: [Double]
    let northNode: Double
    let southNode: Double
    let lunarPhase: Double

    struct PlanetDTO: Encodable {
        let name: String
        let symbol: String
        let longitude: Double
        let latitude: Double
        let zodiacSign: Int
        let zodiacPosition: String
        let isRetrograde: Bool
    }

    init(from chart: NatalChartCalculator.NatalChart) {
        self.planets = chart.planets.map {
            PlanetDTO(name: $0.name, symbol: $0.symbol,
                      longitude: $0.longitude, latitude: $0.latitude,
                      zodiacSign: $0.zodiacSign, zodiacPosition: $0.zodiacPosition,
                      isRetrograde: $0.isRetrograde)
        }
        self.ascendant = chart.ascendant
        self.midheaven = chart.midheaven
        self.descendant = chart.descendant
        self.imumCoeli = chart.imumCoeli
        self.houseCusps = chart.houseCusps
        self.wholeSignHouseCusps = chart.wholeSignHouseCusps
        self.northNode = chart.northNode
        self.southNode = chart.southNode
        self.lunarPhase = chart.lunarPhase
    }
}

struct DailyFitResult: Encodable {
    let payload: DailyFitPayload
    let diagnostics: DailyFitDiagnosticReport
}

struct VerdictRow: Encodable {
    let id: String
    let status: String
    let expected: String
    let actual: String
    let docRef: String?
}
