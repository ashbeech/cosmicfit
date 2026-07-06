//
//  ChartAestheticProfile.swift
//  Cosmic Fit
//
//  SG-1 (Style Guide Quality Overhaul, Phase 1a/1b/1e).
//
//  Derives the chart's aesthetic profile: the binding style decisions
//  (orientation, register, metal strategy, finish lane, temperature,
//  coreFormula, excluded keywords, confidence) that gate runtime overlays
//  and, from SG-2 onward, condition resolvers and cache generation.
//
//  Two derivation levels share one code path:
//
//  - COARSE profile: pure function of the narrative cache key
//    (Venus sign + Moon sign + dominant element). The cached prose is
//    written to this profile, so everything that can appear inside cached
//    paragraphs (register, temperature, finish, metal strategy and above
//    all coreFormula) derives from these three inputs ONLY.
//  - FINE profile: adds full-chart signals (Moon house, dominant houses,
//    stelliums, element margins) on top of the same coarse core. Fine
//    signals refine orientation, confidence and the overlay policy; they
//    NEVER alter coreFormula or the register/temperature/finish/metal
//    lanes (key-purity rule, master plan fifth-pass amendment 2).
//
//  The full language-neutral spec lives in
//  docs/style_guide/decisions/profile_derivation.md and the golden test
//  vectors in docs/style_guide/golden/profile_expectations.json. The 16
//  golden guides are the fitted anchors: where a rule and a guide
//  disagree, the guide wins and the rule here was amended.
//

import Foundation

struct ChartAestheticProfile: Equatable {

    // MARK: - Dimensions

    enum Orientation: String, Equatable {
        case selfContained
        case communityOriented
        case balanced
    }

    enum AestheticRegister: String, Equatable {
        case quietLuxury
        case boldExpression
        case versatileAdaptive
    }

    enum MetalStrategy: String, Equatable {
        case warmDominant
        case coolDominant
        case dualRegister
        case mixedFree
    }

    enum FinishLane: String, Equatable {
        case muted
        case polished
        case mixed
    }

    enum Temperature: String, Equatable {
        case warm
        case cool
        case neutral
    }

    enum Confidence: String, Equatable {
        case high
        case low
    }

    /// How runtime overlays behave for this chart (Phase 1e conflict policy).
    /// - full: signals agree; overlays may use their strongest lane-matching variants.
    /// - neutralPreferred: low-confidence profile; overlays use moderate/neutral
    ///   variants where they exist and never assert a strong lane.
    /// - suppressConflicting: a fine signal (e.g. a stellium whose character
    ///   fights the coarse register, Wren's Aries stellium) contradicts the
    ///   coarse lane; conflicting overlay text is suppressed, neutral variants
    ///   are used elsewhere. The coarse lane is never flipped.
    enum OverlayPolicy: String, Equatable {
        case full
        case neutralPreferred
        case suppressConflicting
    }

    let orientation: Orientation
    let aestheticRegister: AestheticRegister
    let metalStrategy: MetalStrategy
    let finishLane: FinishLane
    let temperature: Temperature
    let coreKeywords: [String]
    let coreFormula: String
    /// Keywords whose POSITIVE ASSERTION is off-lane for this chart.
    /// Consumed by SG-4's aesthetic-lane validator, which must be
    /// assertion-aware: Avoid/pass-over sections may name what they reject
    /// ("pass over loud brights" is compliant), only positive assertions
    /// ("a loud statement necklace completes the look") violate.
    /// Runtime overlay strings are single positive-assertion sentences, so
    /// the overlay screen in HouseSectOverlayGenerator may match plainly.
    let excludedAestheticKeywords: [String]
    let confidence: Confidence
    let overlayPolicy: OverlayPolicy
    /// Signs holding 3+ planets (fine profile only; empty for coarse).
    let stelliumSigns: [String]

    // MARK: - Fine derivation (full ChartAnalysis)

    static func derive(from analysis: ChartAnalysis) -> ChartAestheticProfile {
        let venus = analysis.venusSign
        let moon = analysis.moonSign
        let element = analysis.elementBalance.dominant

        let core = coarseCore(venusSign: venus, moonSign: moon, dominantElement: element)

        // Orientation: coarse sign/element score refined by Moon house.
        let moonHouse = analysis.planetHouses["Moon"]
        let score = orientationScore(venusSign: venus, moonSign: moon, dominantElement: element)
            + moonHouseOrientationAdjustment(moonHouse)
        let orientation = orientationLane(for: score)

        // Stelliums: 3+ planets sharing a sign (all ten bodies).
        let stelliums = stelliumSigns(in: analysis.planetSigns)

        // Confidence: LOW when the element margin is slim or the register
        // vote was a three-way tie (Loom and Wren are the golden anchors).
        let margin = elementDominanceMargin(analysis.elementBalance)
        let confidence: Confidence =
            (margin < elementMarginThreshold || core.registerVoteWasThreeWayTie) ? .low : .high

        // Overlay policy (Phase 1e): a stellium whose register character
        // fights the coarse register (Wren's Aries stellium vs its
        // versatile lane) forces suppress/neutral. A reinforcing stellium
        // (Slate's Capricorn, Mist's Pisces) changes nothing. Low
        // confidence alone prefers neutral variants.
        let conflictingStellium = stelliums.contains { sign in
            let character = registerCharacter(of: sign)
            // Only a bold-vs-non-bold mismatch is a genuine conflict;
            // quiet vs versatile is a mild difference, not a contradiction.
            return character != core.register
                && (character == .boldExpression || core.register == .boldExpression)
        }
        let overlayPolicy: OverlayPolicy
        if conflictingStellium {
            overlayPolicy = .suppressConflicting
        } else if confidence == .low {
            overlayPolicy = .neutralPreferred
        } else {
            overlayPolicy = .full
        }

        return ChartAestheticProfile(
            orientation: orientation,
            aestheticRegister: core.register,
            metalStrategy: core.metalStrategy,
            finishLane: core.finishLane,
            temperature: core.temperature,
            coreKeywords: core.coreKeywords,
            coreFormula: core.coreFormula,
            excludedAestheticKeywords: excludedKeywords(
                register: core.register, orientation: orientation
            ),
            confidence: confidence,
            overlayPolicy: overlayPolicy,
            stelliumSigns: stelliums
        )
    }

    // MARK: - Coarse derivation (cache key only)

    /// Builds the coarse profile from a narrative cache cluster key of the
    /// form `venus_<sign>__moon_<sign>__<element>_dominant`.
    static func coarseProfile(fromClusterKey key: String) -> ChartAestheticProfile? {
        let components = key.components(separatedBy: "__")
        guard components.count == 3,
              components[0].hasPrefix("venus_"),
              components[1].hasPrefix("moon_"),
              components[2].hasSuffix("_dominant") else { return nil }
        let venus = String(components[0].dropFirst("venus_".count)).capitalized
        let moon = String(components[1].dropFirst("moon_".count)).capitalized
        let element = String(components[2].dropLast("_dominant".count)).lowercased()
        return coarseProfile(venusSign: venus, moonSign: moon, dominantElement: element)
    }

    static func coarseProfile(
        venusSign: String,
        moonSign: String,
        dominantElement: String
    ) -> ChartAestheticProfile {
        let core = coarseCore(
            venusSign: venusSign, moonSign: moonSign, dominantElement: dominantElement
        )
        let score = orientationScore(
            venusSign: venusSign, moonSign: moonSign, dominantElement: dominantElement
        )
        let orientation = orientationLane(for: score)
        // Coarse confidence knows nothing about element margins; only a
        // three-way register split marks it low.
        let confidence: Confidence = core.registerVoteWasThreeWayTie ? .low : .high
        return ChartAestheticProfile(
            orientation: orientation,
            aestheticRegister: core.register,
            metalStrategy: core.metalStrategy,
            finishLane: core.finishLane,
            temperature: core.temperature,
            coreKeywords: core.coreKeywords,
            coreFormula: core.coreFormula,
            excludedAestheticKeywords: excludedKeywords(
                register: core.register, orientation: orientation
            ),
            confidence: confidence,
            overlayPolicy: confidence == .low ? .neutralPreferred : .full,
            stelliumSigns: []
        )
    }

    // MARK: - Shared key-pure core

    private struct CoarseCore {
        let register: AestheticRegister
        let registerVoteWasThreeWayTie: Bool
        let temperature: Temperature
        let finishLane: FinishLane
        let metalStrategy: MetalStrategy
        let coreFormula: String
        let coreKeywords: [String]
    }

    private static func coarseCore(
        venusSign: String,
        moonSign: String,
        dominantElement: String
    ) -> CoarseCore {
        let (register, threeWayTie) = registerVote(
            venusSign: venusSign, moonSign: moonSign, dominantElement: dominantElement
        )
        let temperature = temperature(forVenusSign: venusSign)
        let finish = finishLane(register: register, venusSign: venusSign)
        let metals = metalStrategy(
            temperature: temperature, register: register, finish: finish,
            venusSign: venusSign, moonSign: moonSign
        )
        let formula = FormulaVocabulary.compose(
            venusSign: venusSign, moonSign: moonSign,
            dominantElement: dominantElement, register: register
        )
        var keywords = formula.components(separatedBy: " + ")
        keywords.append(registerKeyword(register))
        return CoarseCore(
            register: register,
            registerVoteWasThreeWayTie: threeWayTie,
            temperature: temperature,
            finishLane: finish,
            metalStrategy: metals,
            coreFormula: formula,
            coreKeywords: keywords
        )
    }

    // MARK: - Register (element + Venus sign + Moon sign majority vote)

    /// The register character each sign carries when it votes.
    static func registerCharacter(of sign: String) -> AestheticRegister {
        switch sign {
        case "Taurus", "Cancer", "Scorpio", "Capricorn", "Pisces":
            return .quietLuxury
        case "Aries", "Leo", "Sagittarius":
            return .boldExpression
        default: // Gemini, Virgo, Libra, Aquarius
            return .versatileAdaptive
        }
    }

    private static func registerCharacter(ofElement element: String) -> AestheticRegister {
        switch element {
        case "fire":          return .boldExpression
        case "earth", "water": return .quietLuxury
        default:              return .versatileAdaptive // air
        }
    }

    private static func registerVote(
        venusSign: String,
        moonSign: String,
        dominantElement: String
    ) -> (AestheticRegister, threeWayTie: Bool) {
        let votes = [
            registerCharacter(ofElement: dominantElement),
            registerCharacter(of: venusSign),
            registerCharacter(of: moonSign)
        ]
        var counts: [AestheticRegister: Int] = [:]
        for vote in votes { counts[vote, default: 0] += 1 }
        if let winner = counts.first(where: { $0.value >= 2 })?.key {
            return (winner, false)
        }
        // Three-way split: neutral lane tie-break (golden anchor: Wren).
        return (.versatileAdaptive, true)
    }

    private static func registerKeyword(_ register: AestheticRegister) -> String {
        switch register {
        case .quietLuxury:       return "quiet luxury"
        case .boldExpression:    return "bold expression"
        case .versatileAdaptive: return "versatile"
        }
    }

    // MARK: - Temperature (Venus element with sign nuances)

    /// Venus element sets the lane (earth/fire warm, air/water cool).
    /// Sign nuances, anchored by the golden set: Scorpio Venus is warm-deep
    /// despite water (Tide); Virgo Venus is the genuine neutral lane (Flint).
    static func temperature(forVenusSign venus: String) -> Temperature {
        switch venus {
        case "Scorpio": return .warm   // warm-deep nuance maps onto warm
        case "Virgo":   return .neutral
        case "Aries", "Leo", "Sagittarius", "Taurus", "Capricorn":
            return .warm
        default:
            return .cool // Gemini, Libra, Aquarius, Cancer, Pisces
        }
    }

    // MARK: - Finish lane (register base + Venus-sign inflection)

    /// Register sets the base (quiet muted, bold polished, versatile mixed);
    /// the Venus sign nudges one step along muted < mixed < polished.
    /// Golden anchors: Flint (versatile + Virgo = muted), Frost (versatile +
    /// Aquarius = polished), Hearth (quiet + Leo = mixed), Wren (versatile +
    /// Cancer = muted), Loom (versatile + Pisces = mixed).
    private static func finishLane(
        register: AestheticRegister, venusSign: String
    ) -> FinishLane {
        let base: Int
        switch register {
        case .quietLuxury:       base = 0
        case .versatileAdaptive: base = 1
        case .boldExpression:    base = 2
        }
        let lean: Int
        switch venusSign {
        case "Taurus", "Cancer", "Virgo", "Scorpio", "Capricorn":
            lean = -1
        case "Aries", "Leo", "Aquarius":
            lean = +1
        default: // Gemini, Libra, Sagittarius, Pisces
            lean = 0
        }
        switch max(0, min(2, base + lean)) {
        case 0:  return .muted
        case 2:  return .polished
        default: return .mixed
        }
    }

    // MARK: - Metal strategy (temperature lane + register + sign nuance)

    /// Moon signs that read as cool/structural metal (Saturnian or Martial),
    /// creating the dual-register split against a warm Venus when the finish
    /// stays single-minded. Golden anchors: Slate (Capricorn Moon, muted) and
    /// Cinder (Aries Moon, polished) are dualRegister; Hearth (Capricorn Moon
    /// but MIXED finish, the flash absorbs the contrast) stays warmDominant.
    private static let coolStructuralMoons: Set<String> = [
        "Capricorn", "Aquarius", "Aries", "Virgo", "Gemini", "Libra"
    ]

    private static func metalStrategy(
        temperature: Temperature,
        register: AestheticRegister,
        finish: FinishLane,
        venusSign: String,
        moonSign: String
    ) -> MetalStrategy {
        // Versatile charts with a mixed finish roam freely (Zephyr, Breeze, Loom).
        if register == .versatileAdaptive && finish == .mixed {
            return .mixedFree
        }
        // Cool and neutral lanes anchor on cool metal (Cove, Mist, Frost, Flint, Wren).
        if temperature == .cool || temperature == .neutral {
            return .coolDominant
        }
        // Warm lane. A Sagittarius Venus scales up to eclectic statement
        // mixing rather than a single register (Blaze).
        if venusSign == "Sagittarius" {
            return .mixedFree
        }
        // Warm Venus + cool/structural Moon + single-minded finish splits
        // into warm personal / cool structural (Slate, Cinder).
        if coolStructuralMoons.contains(moonSign) && finish != .mixed {
            return .dualRegister
        }
        return .warmDominant // Ember, Moss, Tide, Ripple, Hearth
    }

    // MARK: - Orientation

    /// Sign leans for the Venus placement (whose taste the aesthetic serves).
    /// Values fitted to the 16 golden vectors; see profile_derivation.md.
    private static func venusOrientationLean(_ sign: String) -> Int {
        switch sign {
        case "Scorpio", "Aries", "Cancer":
            return -2 // strategic privacy / decisive own-taste / protective shelter
        case "Taurus", "Virgo", "Pisces", "Aquarius":
            return -1 // Aquarius Venus is the independent iconoclast, not the joiner
        case "Capricorn":
            return 0  // status-aware, neither pole (Moss balances)
        case "Sagittarius":
            return +2 // dresses for the widest possible audience (Blaze)
        default:
            return +1 // Gemini, Leo, Libra
        }
    }

    /// Sign leans for the Moon placement (where comfort comes from).
    private static func moonOrientationLean(_ sign: String) -> Int {
        switch sign {
        case "Scorpio", "Capricorn", "Aries":
            return -2 // fortress comfort (Slate, Cove, Cinder)
        case "Taurus", "Cancer", "Virgo", "Pisces":
            return -1
        default:
            return +1 // Gemini, Leo, Libra, Sagittarius, Aquarius
        }
    }

    private static func elementOrientationLean(_ element: String) -> Int {
        switch element {
        case "air":           return +1
        case "fire", "water": return -1
        default:              return 0 // earth
        }
    }

    private static func orientationScore(
        venusSign: String, moonSign: String, dominantElement: String
    ) -> Int {
        venusOrientationLean(venusSign)
            + moonOrientationLean(moonSign)
            + elementOrientationLean(dominantElement)
    }

    /// Fine-only refinement: the Moon's house colours where comfort is
    /// sought. The 11th is the community signal named by the master plan;
    /// angular-private and hidden houses pull inward. One house step can
    /// never flip a clear pole on its own (|adjustment| = 1 vs threshold 2),
    /// which is exactly how Slate's Moon-in-11th is absorbed without
    /// flipping her selfContained lane.
    private static func moonHouseOrientationAdjustment(_ house: Int?) -> Int {
        guard let house else { return 0 }
        switch house {
        case 3, 7, 11:      return +1
        case 1, 4, 8, 12:   return -1
        default:            return 0
        }
    }

    private static func orientationLane(for score: Int) -> Orientation {
        if score >= 2 { return .communityOriented }
        if score <= -2 { return .selfContained }
        return .balanced
    }

    // MARK: - Excluded aesthetic keywords

    /// Profile-specific exclusions so a bold chart is never penalised for
    /// "bold". Lists validated against all 16 golden guides (no guide
    /// positively asserts a keyword its profile excludes; Avoid/pass-over
    /// mentions are exempt by the assertion-aware rule).
    /// "statement" is NOT excluded for quietLuxury: Slate's own golden
    /// ideal uses "a statement belt" positively, and guides win over rules.
    private static func excludedKeywords(
        register: AestheticRegister, orientation: Orientation
    ) -> [String] {
        var keywords: [String]
        switch register {
        case .quietLuxury:
            keywords = ["bold", "global", "adventurous", "expansive", "loud"]
        case .boldExpression:
            keywords = ["muted", "understated"]
        case .versatileAdaptive:
            // Wren's guide is the anchor: a conflicted chart's heat must
            // never surface as bold/statement/fierce vocabulary. No
            // versatile golden guide asserts any of these positively.
            keywords = ["bold", "statement", "fierce", "never deviate"]
        }
        if orientation == .selfContained {
            keywords.append(contentsOf: ["community", "belonging", "collective", "tribe"])
        }
        return keywords
    }

    // MARK: - Stelliums

    /// A stellium is 3+ planets sharing a sign, counted across all ten
    /// bodies (Slate's Capricorn stellium is Moon + Saturn + Uranus +
    /// Neptune). Stelliums are not a first-class ChartAnalysis field, so
    /// the profile computes them explicitly. They reinforce confidence and
    /// feed the overlay conflict policy; per the key-purity rule they never
    /// alter register, formula, or any other coarse lane.
    static func stelliumSigns(in planetSigns: [String: String]) -> [String] {
        let planets = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                       "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]
        var counts: [String: Int] = [:]
        for planet in planets {
            if let sign = planetSigns[planet] {
                counts[sign, default: 0] += 1
            }
        }
        return counts.filter { $0.value >= 3 }.keys.sorted()
    }

    // MARK: - Element margin

    static let elementMarginThreshold = 2

    static func elementDominanceMargin(_ balance: ElementBalance) -> Int {
        let counts = [balance.fire, balance.earth, balance.air, balance.water].sorted(by: >)
        return counts[0] - counts[1]
    }
}

// MARK: - Formula vocabulary (SG-1 golden entries; SG-2 ships full tables)

/// coreFormula = register skeleton + per-sign vocabulary, a pure function
/// of the coarse cluster key. The register skeleton fixes the SHAPE
/// (<structure pole> + <softness/flow pole> + <accent/depth signature>);
/// the Venus sign fills slots 1 and 3, the Moon sign fills slot 2.
///
/// Venus structure entries carry register-inflected variants where the
/// golden set anchored them (Ripple: Taurus "structure" -> water-register
/// "soft structure"; Hearth: Leo "dark drama" -> quietLuxury "quiet
/// grandeur"). Moon rows and Venus accent slots compose verbatim across
/// registers (golden README "Mechanism anchors" finding).
///
/// SG-1 ships the mechanism plus the vocabulary anchored by the 16 golden
/// guides (which covers all 12 Venus signs and all 12 Moon signs once).
/// SG-2 ships the full register-inflected `formula_vocabulary` tables in
/// the dataset with 576-key coverage tests.
enum FormulaVocabulary {

    struct VenusEntry {
        /// Default structure-pole vocabulary (slot 1).
        let structure: String
        /// Register-inflected slot-1 variants (sparse; default fills gaps).
        let structureByRegister: [ChartAestheticProfile.AestheticRegister: String]
        /// Water-dominant slot-1 inflection (overrides when no register
        /// variant matched and the chart is water dominant).
        let structureWaterVariant: String?
        /// Accent/depth signature vocabulary (slot 3), verbatim across registers.
        let accent: String

        init(
            structure: String,
            structureByRegister: [ChartAestheticProfile.AestheticRegister: String] = [:],
            structureWaterVariant: String? = nil,
            accent: String
        ) {
            self.structure = structure
            self.structureByRegister = structureByRegister
            self.structureWaterVariant = structureWaterVariant
            self.accent = accent
        }
    }

    /// Venus-sign vocabulary (slots 1 and 3). Anchors in comments.
    static let venusVocabulary: [String: VenusEntry] = [
        "Aries":       VenusEntry(structure: "clean impact", accent: "one hot accent"),                    // Ember
        "Taurus":      VenusEntry(structure: "structure",
                                  structureWaterVariant: "soft structure",
                                  accent: "a touch of quiet depth"),                                       // Slate, Ripple
        "Gemini":      VenusEntry(structure: "crisp separation", accent: "one clever contrast"),           // Zephyr
        "Cancer":      VenusEntry(structure: "soft shelter", accent: "one sentimental keepsake"),          // Cove, Wren
        "Leo":         VenusEntry(structure: "dark drama",
                                  structureByRegister: [.quietLuxury: "quiet grandeur"],
                                  accent: "one molten flash"),                                             // Cinder, Hearth
        "Virgo":       VenusEntry(structure: "precise fit", accent: "one meticulous detail"),              // Flint
        "Libra":       VenusEntry(structure: "balanced proportions", accent: "one refined touch"),         // Breeze
        "Scorpio":     VenusEntry(structure: "close drape", accent: "one warm point of light"),            // Tide
        "Sagittarius": VenusEntry(structure: "expansive colour", accent: "one theatrical finish"),         // Blaze
        "Capricorn":   VenusEntry(structure: "enduring structure", accent: "one living texture"),          // Moss
        "Aquarius":    VenusEntry(structure: "clean geometry", accent: "one polished signal"),             // Frost
        "Pisces":      VenusEntry(structure: "weightless layers", accent: "one pearl of light")            // Mist, Loom
    ]

    /// Moon-sign softness/flow vocabulary (slot 2), verbatim across registers.
    static let moonVocabulary: [String: String] = [
        "Aries":       "sharp edges",       // Cinder
        "Taurus":      "sensory comfort",   // Moss
        "Gemini":      "light movement",    // Breeze, Wren
        "Cancer":      "hidden depth",      // Tide
        "Leo":         "athletic space",    // Blaze
        "Virgo":       "honest fabric",     // Flint, Loom
        "Libra":       "cool composure",    // Frost
        "Scorpio":     "quiet undercurrent",// Cove
        "Sagittarius": "fast movement",     // Ember
        "Capricorn":   "softness",          // Slate, Hearth
        "Aquarius":    "mobile layers",     // Zephyr
        "Pisces":      "blurred edges"      // Mist, Ripple
    ]

    /// Deterministic composition: coarse key in, one formula string out.
    static func compose(
        venusSign: String,
        moonSign: String,
        dominantElement: String,
        register: ChartAestheticProfile.AestheticRegister
    ) -> String {
        guard let venus = venusVocabulary[venusSign],
              let flow = moonVocabulary[moonSign] else {
            // Unknown sign labels cannot occur from the production key
            // space; return a register skeleton placeholder for safety.
            return "considered structure + ease of movement + one quiet signature"
        }
        let structure: String
        if let registerVariant = venus.structureByRegister[register] {
            structure = registerVariant
        } else if dominantElement == "water", let waterVariant = venus.structureWaterVariant {
            structure = waterVariant
        } else {
            structure = venus.structure
        }
        return "\(structure) + \(flow) + \(venus.accent)"
    }
}
