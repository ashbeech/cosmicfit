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

    enum Element: String, Codable, CaseIterable {
        case fire, earth, air, water
    }

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }
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
    let midheaven: PlacementInput?

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

    func degree(for driver: DriverKey) -> Double? {
        switch driver {
        case .ascendant: return ascendant.degree
        case .venus: return venus.degree
        case .sun: return sun.degree
        case .moon: return moon.degree
        case .mercury: return mercury.degree
        case .mars: return mars.degree
        case .saturn: return saturn.degree
        case .jupiter: return jupiter.degree
        case .pluto: return pluto?.degree
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
    var deepAnchorOverriddenToBlack: Bool = false
    /// SG-2 Phase 2e Layer A: a warm Venus floor undid a cool-deep family flip
    /// (e.g. Slate: deepWinter -> deepAutumn). Trace/audit only.
    var venusWarmFloorApplied: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        earthDepthOverrideApplied     = try c.decodeIfPresent(Bool.self, forKey: .earthDepthOverrideApplied) ?? false
        winterCompressionApplied      = try c.decodeIfPresent(Bool.self, forKey: .winterCompressionApplied) ?? false
        coolLeanDeepAutumn            = try c.decodeIfPresent(Bool.self, forKey: .coolLeanDeepAutumn) ?? false
        scorpioDensityApplied         = try c.decodeIfPresent(Bool.self, forKey: .scorpioDensityApplied) ?? false
        capricornVirgoCoolingApplied  = try c.decodeIfPresent(Bool.self, forKey: .capricornVirgoCoolingApplied) ?? false
        fireAirChromaApplied          = try c.decodeIfPresent(Bool.self, forKey: .fireAirChromaApplied) ?? false
        waterSofteningApplied         = try c.decodeIfPresent(Bool.self, forKey: .waterSofteningApplied) ?? false
        surfacePreservationApplied    = try c.decodeIfPresent(Bool.self, forKey: .surfacePreservationApplied) ?? false
        deepAnchorOverriddenToBlack   = try c.decodeIfPresent(Bool.self, forKey: .deepAnchorOverriddenToBlack) ?? false
        venusWarmFloorApplied         = try c.decodeIfPresent(Bool.self, forKey: .venusWarmFloorApplied) ?? false
    }
}

// MARK: - Palette Output

struct PaletteTriadV4: Codable, Equatable {
    let neutrals: [String]
    let coreColours: [String]
    let accentColours: [String]
    let supportColours: [String]?
    let lightAnchor: String
    let deepAnchor: String

    init(
        neutrals: [String],
        coreColours: [String],
        accentColours: [String],
        supportColours: [String]? = nil,
        lightAnchor: String,
        deepAnchor: String
    ) {
        self.neutrals = neutrals
        self.coreColours = coreColours
        self.accentColours = accentColours
        self.supportColours = supportColours
        self.lightAnchor = lightAnchor
        self.deepAnchor = deepAnchor
    }

    // Back-compat decode: existing cached blueprints may not have anchor fields.
    // We accept them but then synthesise safe defaults during decode.
    enum CodingKeys: String, CodingKey {
        case neutrals, coreColours, accentColours, supportColours, lightAnchor, deepAnchor
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.neutrals = try c.decode([String].self, forKey: .neutrals)
        self.coreColours = try c.decode([String].self, forKey: .coreColours)
        self.accentColours = try c.decode([String].self, forKey: .accentColours)
        self.supportColours = try c.decodeIfPresent([String].self, forKey: .supportColours)
        self.lightAnchor = try c.decodeIfPresent(String.self, forKey: .lightAnchor) ?? "warm ivory"
        self.deepAnchor = try c.decodeIfPresent(String.self, forKey: .deepAnchor) ?? "espresso"
    }
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

// MARK: - Accent Slots (V4.5)

enum AccentRole: String, Codable, CaseIterable {
    case signature = "Signature"
    case contrast = "Contrast"
    case depth = "Depth"
    case lift = "Lift"
    case visibility = "Visibility"
}

struct AccentSlot: Codable, Equatable {
    let hex: String
    let displayName: String
    let role: AccentRole
    let sourcePlanet: DriverKey
    let sourceSign: V4ZodiacSign
    let saturationOverrideApplied: Bool
}

// MARK: - Final Result

struct ColourEngineResult: Codable, Equatable {
    let variables: DerivedVariables
    let family: PaletteFamily
    let cluster: PaletteCluster
    let palette: PaletteTriadV4
    let secondaryPull: PaletteFamily?
    let trace: FamilyDecisionTrace
    /// V4.4 — chart-derived hero colour (Sun's sign projected into family
    /// envelope). Hex. Invariant to secondary pulls.
    let luminarySignature: String
    /// V4.4 — chart-derived signature colour (Ascendant's domicile ruler
    /// sign projected into family envelope). Hex. Invariant to secondary
    /// pulls.
    let rulerSignature: String
    /// V4.5 — chart-derived accent slots (4 functional roles).
    let accentSlots: [AccentSlot]
    /// V4.7 — MC/Moon depth overlay trace.
    let depthOverlay: DepthOverlayResolver.OverlayResult
    /// V4.8 — Black eligibility trace.
    let blackEligibility: BlackEligibilityResolver.BlackResult
    /// V4.9 — MC visibility accent trace.
    let visibilityAccent: VisibilityAccentResolver.VisibilityResult

    init(
        variables: DerivedVariables,
        family: PaletteFamily,
        cluster: PaletteCluster,
        palette: PaletteTriadV4,
        secondaryPull: PaletteFamily?,
        trace: FamilyDecisionTrace,
        luminarySignature: String,
        rulerSignature: String,
        accentSlots: [AccentSlot] = [],
        depthOverlay: DepthOverlayResolver.OverlayResult = .none,
        blackEligibility: BlackEligibilityResolver.BlackResult = .ineligible,
        visibilityAccent: VisibilityAccentResolver.VisibilityResult = .none
    ) {
        self.variables = variables
        self.family = family
        self.cluster = cluster
        self.palette = palette
        self.secondaryPull = secondaryPull
        self.trace = trace
        self.luminarySignature = luminarySignature
        self.rulerSignature = rulerSignature
        self.accentSlots = accentSlots
        self.depthOverlay = depthOverlay
        self.blackEligibility = blackEligibility
        self.visibilityAccent = visibilityAccent
    }

    enum CodingKeys: String, CodingKey {
        case variables, family, cluster, palette, secondaryPull, trace
        case luminarySignature, rulerSignature, accentSlots, depthOverlay
        case blackEligibility, visibilityAccent
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.variables = try c.decode(DerivedVariables.self, forKey: .variables)
        self.family = try c.decode(PaletteFamily.self, forKey: .family)
        self.cluster = try c.decode(PaletteCluster.self, forKey: .cluster)
        self.palette = try c.decode(PaletteTriadV4.self, forKey: .palette)
        self.secondaryPull = try c.decodeIfPresent(PaletteFamily.self, forKey: .secondaryPull)
        self.trace = try c.decode(FamilyDecisionTrace.self, forKey: .trace)
        self.luminarySignature = try c.decodeIfPresent(String.self, forKey: .luminarySignature) ?? "#808080"
        self.rulerSignature = try c.decodeIfPresent(String.self, forKey: .rulerSignature) ?? "#808080"
        self.accentSlots = try c.decodeIfPresent([AccentSlot].self, forKey: .accentSlots) ?? []
        self.depthOverlay = try c.decodeIfPresent(DepthOverlayResolver.OverlayResult.self, forKey: .depthOverlay) ?? .none
        self.blackEligibility = try c.decodeIfPresent(BlackEligibilityResolver.BlackResult.self, forKey: .blackEligibility) ?? .ineligible
        self.visibilityAccent = try c.decodeIfPresent(VisibilityAccentResolver.VisibilityResult.self, forKey: .visibilityAccent) ?? .none
    }
}
