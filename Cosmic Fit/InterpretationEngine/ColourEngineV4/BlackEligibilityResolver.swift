import Foundation

/// V4.8 — Black eligibility resolver.
///
/// Many users instinctively reach for black regardless of seasonal family.
/// The colour engine should validate and guide that instinct when the chart
/// supports it, rather than leaving black out of non-Winter palettes entirely.
///
/// Runs after DepthOverlayResolver. Evaluates whether chart placements
/// justify upgrading the deep anchor to a black or near-black swatch.
/// Families whose template already includes black are skipped.
///
/// The resolver does NOT give everyone black. It requires concrete chart
/// evidence — Scorpio/Capricorn/Pluto prominence, 8th/10th house weight,
/// or high-contrast family membership.
enum BlackEligibilityResolver {

    // MARK: - Public Types

    enum BlackMode: String, Codable, Equatable {
        case trueBlack = "true black"
        case softBlack = "soft black"
        case blackBrown = "black brown"
        case blackCherry = "black cherry"
        case inkNavy = "ink navy"
    }

    struct BlackResult: Codable, Equatable {
        let mode: BlackMode?
        let colourName: String?
        let hex: String?
        let originalDeepAnchor: String?
        let eligible: Bool
        let score: Double
        let signals: [String]

        static let ineligible = BlackResult(
            mode: nil, colourName: nil, hex: nil,
            originalDeepAnchor: nil,
            eligible: false, score: 0, signals: []
        )
    }

    // MARK: - Families that already have black in their deep anchor

    private static let familiesWithBlack: Set<PaletteFamily> = [
        .deepWinter, .trueWinter, .brightWinter, .brightSpring
    ]

    private static let blackNamedAnchors: Set<String> = [
        "black", "clear black", "soft black", "black brown",
        "ink brown", "blue-black"
    ]

    // MARK: - Scoring thresholds

    private static let eligibilityThreshold: Double = 2.0

    // MARK: - Public API

    /// Evaluate black eligibility from chart input. Returns the recommended
    /// black mode and the modified palette if eligible.
    static func resolve(
        family: PaletteFamily,
        input: BirthChartColourInput,
        palette: PaletteTriadV4,
        winterCompressionApplied: Bool
    ) -> (palette: PaletteTriadV4, result: BlackResult) {
        if familiesWithBlack.contains(family) {
            return (palette, .ineligible)
        }
        if winterCompressionApplied {
            return (palette, .ineligible)
        }

        let (score, signals) = computeScore(input: input)

        guard score >= eligibilityThreshold else {
            return (palette, BlackResult(
                mode: nil, colourName: nil, hex: nil,
                originalDeepAnchor: nil,
                eligible: false, score: score, signals: signals
            ))
        }

        let mode = selectMode(family: family, score: score)
        let (colourName, hex) = colourForMode(mode)

        // Skip if the anchor is already a black-family swatch (by name).
        // "bitter chocolate" and "espresso" are dark but not black —
        // they should be replaceable. "black", "clear black", "soft black",
        // "black brown", "ink brown" are already in the black family.
        let anchorIsAlreadyBlack = blackNamedAnchors.contains(
            palette.deepAnchor.lowercased()
        )
        guard !anchorIsAlreadyBlack else {
            return (palette, BlackResult(
                mode: mode, colourName: colourName, hex: hex,
                originalDeepAnchor: palette.deepAnchor,
                eligible: true, score: score, signals: signals
            ))
        }

        let modifiedPalette = PaletteTriadV4(
            neutrals: palette.neutrals,
            coreColours: palette.coreColours,
            accentColours: palette.accentColours,
            supportColours: palette.supportColours,
            lightAnchor: palette.lightAnchor,
            deepAnchor: colourName
        )

        return (modifiedPalette, BlackResult(
            mode: mode, colourName: colourName, hex: hex,
            originalDeepAnchor: palette.deepAnchor,
            eligible: true, score: score, signals: signals
        ))
    }

    // MARK: - Score Computation

    /// Each chart signal contributes a weight. Cumulative score >= threshold
    /// grants black eligibility. Designed so a single strong signal (e.g.
    /// Scorpio MC alone) is not quite enough, but two moderate signals are.
    private static func computeScore(
        input: BirthChartColourInput
    ) -> (score: Double, signals: [String]) {
        var score: Double = 0
        var signals: [String] = []

        // Scorpio placements (the strongest black-permission signal)
        let scorpioDrivers: [(label: String, sign: V4ZodiacSign?, weight: Double)] = [
            ("Scorpio MC", input.midheaven?.sign, 1.5),
            ("Scorpio Asc", input.ascendant.sign, 1.3),
            ("Scorpio Venus", input.venus.sign, 1.0),
            ("Scorpio Moon", input.moon.sign, 0.8),
            ("Scorpio Sun", input.sun.sign, 0.7),
            ("Scorpio Mars", input.mars.sign, 0.6),
        ]
        for driver in scorpioDrivers {
            if driver.sign == .scorpio {
                score += driver.weight
                signals.append(driver.label)
            }
        }

        // Capricorn placements (black as authority / structure)
        let capricornDrivers: [(label: String, sign: V4ZodiacSign?, weight: Double)] = [
            ("Capricorn MC", input.midheaven?.sign, 1.2),
            ("Capricorn Asc", input.ascendant.sign, 1.0),
            ("Capricorn Venus", input.venus.sign, 0.7),
            ("Capricorn Saturn", input.saturn.sign, 0.6),
            ("Capricorn Moon", input.moon.sign, 0.5),
            ("Capricorn Sun", input.sun.sign, 0.5),
        ]
        for driver in capricornDrivers {
            if driver.sign == .capricorn {
                score += driver.weight
                signals.append(driver.label)
            }
        }

        // Pluto prominence (Pluto = transformation, depth, black)
        if let plutoSign = input.pluto?.sign {
            if plutoSign == .scorpio {
                score += 0.8
                signals.append("Pluto in Scorpio")
            } else if plutoSign == .capricorn {
                score += 0.5
                signals.append("Pluto in Capricorn")
            }
        }

        // Aquarius placements (black as modern edge / uniform)
        let aquariusDrivers: [(label: String, sign: V4ZodiacSign?, weight: Double)] = [
            ("Aquarius Asc", input.ascendant.sign, 0.7),
            ("Aquarius MC", input.midheaven?.sign, 0.6),
            ("Aquarius Venus", input.venus.sign, 0.5),
        ]
        for driver in aquariusDrivers {
            if driver.sign == .aquarius {
                score += driver.weight
                signals.append(driver.label)
            }
        }

        // Saturn prominence in the chart (Saturn = restriction, severity, black)
        if input.saturn.sign == .scorpio || input.saturn.sign == .capricorn || input.saturn.sign == .aquarius {
            score += 0.4
            signals.append("Saturn in \(input.saturn.sign.rawValue)")
        }

        return (score, signals)
    }

    // MARK: - Mode Selection

    /// Choose the right shade of black based on the family's temperature
    /// and the chart's score (higher scores get darker blacks).
    private static func selectMode(family: PaletteFamily, score: Double) -> BlackMode {
        let vars = FamilyProfiles.variables(for: family)

        switch vars.temperature {
        case .warm:
            return score >= 3.5 ? .trueBlack : .blackBrown
        case .cool:
            if vars.contrast == .high || score >= 3.5 {
                return .trueBlack
            }
            return score >= 2.5 ? .softBlack : .inkNavy
        case .neutral:
            return score >= 3.0 ? .trueBlack : .softBlack
        }
    }

    // MARK: - Colour Mapping

    private static func colourForMode(_ mode: BlackMode) -> (name: String, hex: String) {
        switch mode {
        case .trueBlack:
            return ("black", "#0A0A0A")
        case .softBlack:
            return ("soft black", "#1A1A1E")
        case .blackBrown:
            return ("black brown", "#1C1210")
        case .blackCherry:
            return ("black cherry", "#4D0F28")
        case .inkNavy:
            return ("ink navy", "#1B2A4A")
        }
    }
}
