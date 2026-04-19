import Foundation

// MARK: - Core Variable Enums

enum DepthLevel: String, Codable, Equatable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case deep = "Deep"
}

enum Temperature: String, Codable, Equatable, CaseIterable {
    case cool = "Cool"
    case neutral = "Neutral"
    case warm = "Warm"
}

enum Saturation: String, Codable, Equatable, CaseIterable {
    case soft = "Soft"
    case muted = "Muted"
    case rich = "Rich"
}

enum ContrastLevel: String, Codable, Equatable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum SurfaceQuality: String, Codable, Equatable, CaseIterable {
    case soft = "Soft"
    case balanced = "Balanced"
    case structured = "Structured"
}

// MARK: - Family & Cluster

enum PaletteFamily: String, Codable, Equatable, CaseIterable {
    case lightSpring = "Light Spring"
    case trueSpring = "True Spring"
    case brightSpring = "Bright Spring"
    case lightSummer = "Light Summer"
    case trueSummer = "True Summer"
    case softSummer = "Soft Summer"
    case softAutumn = "Soft Autumn"
    case trueAutumn = "True Autumn"
    case deepAutumn = "Deep Autumn"
    case deepWinter = "Deep Winter"
    case trueWinter = "True Winter"
    case brightWinter = "Bright Winter"
}

enum PaletteCluster: String, Codable, Equatable, CaseIterable {
    case lightAiryWarm = "Light Airy Warm"
    case lightAiryCool = "Light Airy Cool"
    case mediumWarmGrounded = "Medium Warm Grounded"
    case mediumWarmMuted = "Medium Warm Muted"
    case mediumNeutralElectric = "Medium Neutral Electric"
    case mediumCoolSoft = "Medium Cool Soft"
    case mediumCoolMuted = "Medium Cool Muted"
    case deepWarmStructured = "Deep Warm Structured"
    case deepCoolControlled = "Deep Cool Controlled"
    case deepCoolHighContrast = "Deep Cool High-Contrast"
}

// MARK: - Signs & Drivers

enum V4ZodiacSign: String, Codable, Equatable, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
}

enum DriverKey: String, Codable, Equatable, CaseIterable {
    case ascendant = "Ascendant"
    case venus = "Venus"
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case mars = "Mars"
    case saturn = "Saturn"
    case jupiter = "Jupiter"
    case pluto = "Pluto"

    var isCorePlacement: Bool {
        switch self {
        case .ascendant, .venus, .sun, .moon: return true
        default: return false
        }
    }
}

// MARK: - Input Types

struct PlacementInput: Codable, Equatable {
    let sign: V4ZodiacSign
    let degree: Double?

    init(sign: V4ZodiacSign, degree: Double? = nil) {
        self.sign = sign
        self.degree = degree
    }
}

struct BirthChartColourInput: Codable, Equatable {
    let ascendant: PlacementInput
    let venus: PlacementInput
    let sun: PlacementInput
    let moon: PlacementInput
    let mercury: PlacementInput
    let mars: PlacementInput
    let saturn: PlacementInput
    let jupiter: PlacementInput
    let pluto: PlacementInput?

    func sign(for driver: DriverKey) -> V4ZodiacSign? {
        switch driver {
        case .ascendant: return ascendant.sign
        case .venus: return venus.sign
        case .sun: return sun.sign
        case .moon: return moon.sign
        case .mercury: return mercury.sign
        case .mars: return mars.sign
        case .saturn: return saturn.sign
        case .jupiter: return jupiter.sign
        case .pluto: return pluto?.sign
        }
    }

    var coreDriverSigns: [V4ZodiacSign] {
        [ascendant.sign, venus.sign, sun.sign, moon.sign]
    }

    var allCorePlacements: [(DriverKey, PlacementInput)] {
        [(.ascendant, ascendant), (.venus, venus), (.sun, sun), (.moon, moon)]
    }

    var allOuterPlacements: [(DriverKey, PlacementInput)] {
        [(.mercury, mercury), (.mars, mars), (.saturn, saturn), (.jupiter, jupiter)]
    }
}

// MARK: - Internal Scoring State

struct RawVariableScores: Codable, Equatable {
    var depth: Int
    var warmth: Int
    var saturation: Int
    var contrast: Int
    var structure: Int

    static let zero = RawVariableScores(depth: 0, warmth: 0, saturation: 0, contrast: 0, structure: 0)
}

struct WeightedDriver: Codable, Equatable {
    let key: DriverKey
    let sign: V4ZodiacSign
    let weight: Int
}

struct NormalizedDriverSet: Codable, Equatable {
    let drivers: [WeightedDriver]
    let hasPluto: Bool
    let plutoSign: V4ZodiacSign?
}

struct DerivedVariables: Codable, Equatable {
    var depth: DepthLevel
    var temperature: Temperature
    var saturation: Saturation
    var contrast: ContrastLevel
    var surface: SurfaceQuality
}

// MARK: - Override Tracking

struct OverrideFlags: Codable, Equatable {
    var earthDepthOverrideApplied: Bool = false
    var winterCompressionApplied: Bool = false
    var coolLeanDeepAutumn: Bool = false
    var scorpioDensityApplied: Bool = false
    var capricornVirgoCoolingApplied: Bool = false
    var fireAirChromaApplied: Bool = false
    var waterSofteningApplied: Bool = false
    var surfacePreservationApplied: Bool = false
}

// MARK: - Palette Output

struct PaletteTriadV4: Codable, Equatable {
    let neutrals: [String]
    let coreColours: [String]
    let accentColours: [String]
}

// MARK: - Decision Trace

struct FamilyDecisionTrace: Codable, Equatable {
    let rawScoresBeforeModifiers: RawVariableScores
    let rawScoresAfterModifiers: RawVariableScores
    let normalizedDrivers: NormalizedDriverSet
    let variablesBeforeOverrides: DerivedVariables
    let variablesAfterOverrides: DerivedVariables
    let overrideFlags: OverrideFlags
    let family: PaletteFamily
    let cluster: PaletteCluster
    let secondaryPull: PaletteFamily?
    let variation: VariationTrace
}

// MARK: - Variation

struct VariationSubstitution: Codable, Equatable {
    let band: String
    let slotIndex: Int
    let originalColour: String
    let replacedWith: String
    let fromFamily: String
}

struct VariationTrace: Codable, Equatable {
    let pullFamily: String?
    let pullStrength: Int
    let substitutions: [VariationSubstitution]

    static let none = VariationTrace(pullFamily: nil, pullStrength: 0, substitutions: [])
}

// MARK: - Final Result

struct ColourEngineResult: Codable, Equatable {
    let variables: DerivedVariables
    let family: PaletteFamily
    let cluster: PaletteCluster
    let palette: PaletteTriadV4
    let secondaryPull: PaletteFamily?
    let trace: FamilyDecisionTrace
}
