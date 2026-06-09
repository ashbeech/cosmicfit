import Foundation

/// V4.7 — Post-family MC/Moon depth overlay.
///
/// Evaluates whether the Midheaven and Moon signs indicate depth
/// that the chosen family template fails to express. When depth is
/// underrepresented, substitutes one support colour and optionally
/// the deep anchor with a richer note derived from the MC/Moon sign
/// archetype projected into the family's perceptual envelope.
///
/// Runs after family/template lookup + winter-compression, before
/// AccentResolver. Neutrals and core colours are never modified.
enum DepthOverlayResolver {

    // MARK: - Public API

    struct OverlayResult: Codable, Equatable {
        let supportSubstitution: SupportSubstitution?
        let deepAnchorSubstitution: DeepAnchorSubstitution?
        let accentDepthInjection: AccentDepthInjection?
        let applied: Bool

        static let none = OverlayResult(
            supportSubstitution: nil,
            deepAnchorSubstitution: nil,
            accentDepthInjection: nil,
            applied: false
        )
    }

    struct SupportSubstitution: Codable, Equatable {
        let slotIndex: Int
        let originalColour: String
        let replacementColour: String
        let replacementHex: String
        let sourceSign: V4ZodiacSign
        let sourceRole: DepthSource
    }

    struct DeepAnchorSubstitution: Codable, Equatable {
        let originalColour: String
        let replacementColour: String
        let replacementHex: String
        let sourceSign: V4ZodiacSign
        let sourceRole: DepthSource
    }

    struct AccentDepthInjection: Codable, Equatable {
        let slotIndex: Int
        let originalHex: String
        let replacementHex: String
        let replacementName: String
        let sourceSign: V4ZodiacSign
    }

    enum DepthSource: String, Codable, Equatable {
        case midheaven = "Midheaven"
        case moon = "Moon"
    }

    /// Evaluate and apply depth overlay to palette support/deep-anchor.
    static func resolve(
        family: PaletteFamily,
        input: BirthChartColourInput,
        palette: PaletteTriadV4
    ) -> (palette: PaletteTriadV4, overlay: OverlayResult) {
        guard shouldApplyOverlay(family: family, input: input) else {
            return (palette, .none)
        }

        let depthSigns = rankedDepthSigns(input: input)
        guard !depthSigns.isEmpty else {
            return (palette, .none)
        }

        let envelope = ChartSignatureResolver.envelope(for: family)
        var supportSub: SupportSubstitution?
        var anchorSub: DeepAnchorSubstitution?
        var modifiedPalette = palette

        // Try support substitution from highest-ranked depth sign.
        // MC should usually own the visible public-image depth note.
        if let support = palette.supportColours, !support.isEmpty {
            for depthSign in depthSigns {
                if let sub = resolveSupport(
                    sign: depthSign.sign,
                    source: depthSign.source,
                    existingSupport: support,
                    envelope: envelope,
                    family: family
                ) {
                    supportSub = sub
                    var newSupport = support
                    newSupport[sub.slotIndex] = sub.replacementColour
                    modifiedPalette = PaletteTriadV4(
                        neutrals: palette.neutrals,
                        coreColours: palette.coreColours,
                        accentColours: palette.accentColours,
                        supportColours: newSupport,
                        lightAnchor: palette.lightAnchor,
                        deepAnchor: palette.deepAnchor
                    )
                    break
                }
            }
        }

        // Try deep anchor substitution if family anchor is shallow.
        // If support already used the strongest sign, prefer the next
        // qualified depth sign for the anchor so MC + Moon can both speak.
        if familyAnchorIsShallow(family: family) {
            let anchorDepthSigns = anchorRanking(
                depthSigns: depthSigns,
                supportSubstitution: supportSub
            )
            for depthSign in anchorDepthSigns {
                if let sub = resolveDeepAnchor(
                    sign: depthSign.sign,
                    source: depthSign.source,
                    currentAnchor: modifiedPalette.deepAnchor,
                    envelope: envelope,
                    family: family
                ) {
                    anchorSub = sub
                    modifiedPalette = PaletteTriadV4(
                        neutrals: modifiedPalette.neutrals,
                        coreColours: modifiedPalette.coreColours,
                        accentColours: modifiedPalette.accentColours,
                        supportColours: modifiedPalette.supportColours,
                        lightAnchor: modifiedPalette.lightAnchor,
                        deepAnchor: sub.replacementColour
                    )
                    break
                }
            }
        }

        let applied = supportSub != nil || anchorSub != nil
        let overlay = OverlayResult(
            supportSubstitution: supportSub,
            deepAnchorSubstitution: anchorSub,
            accentDepthInjection: nil,
            applied: applied
        )
        return (modifiedPalette, overlay)
    }

    // MARK: - Activation Gate

    private static let deepFamilies: Set<PaletteFamily> = [
        .deepAutumn, .deepWinter, .trueWinter, .brightWinter
    ]

    private static let depthSigns: Set<V4ZodiacSign> = [
        .scorpio, .taurus, .capricorn, .cancer, .pisces
    ]

    private static func shouldApplyOverlay(
        family: PaletteFamily,
        input: BirthChartColourInput
    ) -> Bool {
        if deepFamilies.contains(family) { return false }

        let mcQualifies = input.midheaven.map { depthSigns.contains($0.sign) } ?? false
        let moonQualifies = depthSigns.contains(input.moon.sign)
        return mcQualifies || moonQualifies
    }

    // MARK: - Depth Sign Ranking

    private struct RankedDepth {
        let sign: V4ZodiacSign
        let source: DepthSource
        let strength: Double
    }

    private static let signDepthStrength: [V4ZodiacSign: Double] = [
        .scorpio: 1.0,
        .capricorn: 0.85,
        .taurus: 0.75,
        .cancer: 0.5,
        .pisces: 0.4,
    ]

    private static func rankedDepthSigns(input: BirthChartColourInput) -> [RankedDepth] {
        var candidates: [RankedDepth] = []

        if let mc = input.midheaven, let strength = signDepthStrength[mc.sign] {
            candidates.append(RankedDepth(
                sign: mc.sign, source: .midheaven, strength: strength * 1.1
            ))
        }

        if let strength = signDepthStrength[input.moon.sign] {
            candidates.append(RankedDepth(
                sign: input.moon.sign, source: .moon, strength: strength
            ))
        }

        candidates.sort { $0.strength > $1.strength }

        // Deduplicate by sign (keep stronger source)
        var seen: Set<V4ZodiacSign> = []
        return candidates.filter { seen.insert($0.sign).inserted }
    }

    // MARK: - Support Resolution

    /// Deep-note colour candidates by sign, for support-slot injection.
    /// These are warm/earthy/wine tones that work as "grounding depth"
    /// across seasonal families without breaking coherence.
    private static let supportDepthPool: [V4ZodiacSign: [(name: String, hex: String)]] = [
        .scorpio: [
            ("oxblood", "#4A1C20"),
            ("bark brown", "#5C4033"),
            ("black cherry", "#3A0F1E"),
            ("dark terracotta", "#9E4E3A"),
        ],
        .taurus: [
            ("bitter chocolate", "#3A2A1E"),
            ("bark brown", "#5C4033"),
            ("cocoa", "#7B5B3A"),
            ("warm olive", "#706238"),
        ],
        .capricorn: [
            ("espresso", "#3C2415"),
            ("deep olive", "#3C4B27"),
            ("ink brown", "#2B1E15"),
        ],
        .cancer: [
            ("mist navy", "#6B7B8D"),
            ("soft navy", "#4F5D73"),
        ],
        .pisces: [
            ("soft navy", "#4F5D73"),
            ("mist navy", "#6B7B8D"),
        ],
    ]

    private static func resolveSupport(
        sign: V4ZodiacSign,
        source: DepthSource,
        existingSupport: [String],
        envelope: ChartSignatureResolver.Envelope,
        family: PaletteFamily
    ) -> SupportSubstitution? {
        guard let pool = supportDepthPool[sign], !pool.isEmpty else { return nil }

        // Candidate order encodes sign semantics: Scorpio should prefer
        // oxblood/wine before terracotta, Taurus should prefer bitter
        // chocolate/bark before lighter cocoa. A true depth overlay must be
        // allowed to sit below the family envelope in support/anchor slots.
        for candidate in pool {
            guard let lab = ColourMath.hexToLab(candidate.hex) else { continue }
            guard lab.L >= 12, lab.L <= envelope.lightness.max + 10 else { continue }
            let chosen = candidate

            // Replace the last support slot (least prominent position)
            let slotIndex = existingSupport.count - 1

            return SupportSubstitution(
                slotIndex: slotIndex,
                originalColour: existingSupport[slotIndex],
                replacementColour: chosen.name,
                replacementHex: chosen.hex,
                sourceSign: sign,
                sourceRole: source
            )
        }

        return nil
    }

    // MARK: - Deep Anchor Resolution

    private static let shallowAnchorFamilies: Set<PaletteFamily> = [
        .softSummer, .trueSummer, .lightSummer, .lightSpring, .trueSpring
    ]

    private static func familyAnchorIsShallow(family: PaletteFamily) -> Bool {
        shallowAnchorFamilies.contains(family)
    }

    private static let anchorDepthPool: [V4ZodiacSign: (name: String, hex: String)] = [
        .scorpio:    ("black cherry", "#3A0F1E"),
        .taurus:     ("bitter chocolate", "#3A2A1E"),
        .capricorn:  ("espresso", "#3C2415"),
        .cancer:     ("ink navy", "#1B2A4A"),
        .pisces:     ("ink navy", "#1B2A4A"),
    ]

    private static func anchorRanking(
        depthSigns: [RankedDepth],
        supportSubstitution: SupportSubstitution?
    ) -> [RankedDepth] {
        guard let support = supportSubstitution else { return depthSigns }

        let secondary = depthSigns.filter {
            $0.sign != support.sourceSign || $0.source != support.sourceRole
        }
        let primary = depthSigns.filter {
            $0.sign == support.sourceSign && $0.source == support.sourceRole
        }
        return secondary + primary
    }

    private static func resolveDeepAnchor(
        sign: V4ZodiacSign,
        source: DepthSource,
        currentAnchor: String,
        envelope: ChartSignatureResolver.Envelope,
        family: PaletteFamily
    ) -> DeepAnchorSubstitution? {
        guard let candidate = anchorDepthPool[sign] else { return nil }

        let currentHex = PaletteLibrary.hex(for: currentAnchor)
        guard let currentLab = ColourMath.hexToLab(currentHex),
              let candidateLab = ColourMath.hexToLab(candidate.hex) else {
            return nil
        }

        // Only substitute if candidate is meaningfully darker
        let currentL = currentLab.L
        let candidateL = candidateLab.L
        guard candidateL < currentL - 5.0 else { return nil }

        return DeepAnchorSubstitution(
            originalColour: currentAnchor,
            replacementColour: candidate.name,
            replacementHex: candidate.hex,
            sourceSign: sign,
            sourceRole: source
        )
    }

    // MARK: - Accent Depth Injection (post-accent pass)

    private static let accentInjectionSigns: Set<V4ZodiacSign> = [
        .scorpio, .capricorn, .taurus
    ]

    private static let darkAccentLightnessThreshold: Double = 40.0

    /// Runs after AccentResolver. If MC is a strong depth sign and the
    /// accent band is entirely light/medium (no L < 40), injects one
    /// dark accent from the MC sign's expression table into the contrast
    /// slot (last accent position).
    static func injectAccentDepth(
        input: BirthChartColourInput,
        family: PaletteFamily,
        accentHexes: [String],
        existingPaletteHexes: [String],
        previousOverlay: OverlayResult
    ) -> (accentHexes: [String], overlay: OverlayResult) {
        guard previousOverlay.applied else {
            return (accentHexes, previousOverlay)
        }

        guard let mc = input.midheaven,
              accentInjectionSigns.contains(mc.sign) else {
            return (accentHexes, previousOverlay)
        }

        guard !accentHexes.isEmpty else {
            return (accentHexes, previousOverlay)
        }

        let hasExistingDarkAccent = accentHexes.contains { hex in
            guard let lab = ColourMath.hexToLab(hex) else { return false }
            return lab.L < darkAccentLightnessThreshold
        }
        guard !hasExistingDarkAccent else {
            return (accentHexes, previousOverlay)
        }

        let temperature = FamilyProfiles.variables(for: family).temperature
        let candidates = SignAccentExpressions.candidates(for: mc.sign, temperature: temperature)
        guard !candidates.isEmpty else {
            return (accentHexes, previousOverlay)
        }

        let darkCandidates = candidates
            .filter { $0.L < darkAccentLightnessThreshold }
            .sorted { $0.L < $1.L }

        guard !darkCandidates.isEmpty else {
            return (accentHexes, previousOverlay)
        }

        let avoidHexes = existingPaletteHexes + accentHexes
        var bestCandidate: (hex: String, name: String, dist: Double)?

        for expr in darkCandidates {
            let hex = ColourMath.lchToHex(L: expr.L, C: expr.C, h: expr.h)
            let minDist = avoidHexes.reduce(Double.infinity) { best, existing in
                min(best, ColourMath.labDistanceSquared(hex, existing))
            }
            if bestCandidate == nil || minDist > bestCandidate!.dist {
                bestCandidate = (hex: hex, name: expr.name, dist: minDist)
            }
        }

        guard let chosen = bestCandidate else {
            return (accentHexes, previousOverlay)
        }

        let slotIndex = accentHexes.count - 1
        var newAccents = accentHexes
        let originalHex = newAccents[slotIndex]
        newAccents[slotIndex] = chosen.hex

        let injection = AccentDepthInjection(
            slotIndex: slotIndex,
            originalHex: originalHex,
            replacementHex: chosen.hex,
            replacementName: chosen.name,
            sourceSign: mc.sign
        )

        let updatedOverlay = OverlayResult(
            supportSubstitution: previousOverlay.supportSubstitution,
            deepAnchorSubstitution: previousOverlay.deepAnchorSubstitution,
            accentDepthInjection: injection,
            applied: true
        )

        return (accentHexes: newAccents, overlay: updatedOverlay)
    }
}
