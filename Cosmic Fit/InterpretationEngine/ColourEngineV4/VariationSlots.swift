import Foundation

enum VariationSlots {

    struct CuratedSubstitution {
        enum Band: String { case neutral, core, accent }
        let band: Band
        let targetIndex: Int
        let sourceColourName: String
    }

    // MARK: - Curated Substitution Map

    static let substitutionMap: [PaletteFamily: [PaletteFamily: [CuratedSubstitution]]] = [

        // ── Light Spring ──
        .lightSpring: [
            .brightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bright gold"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "vivid yellow"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "clear camel"),
            ],
            .lightSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "rose quartz"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "seafoam"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "cool taupe"),
            ],
        ],

        // ── True Spring ──
        .trueSpring: [
            .brightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bright gold"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "electric blue"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "warm navy"),
            ],
        ],

        // ── Bright Spring ──
        .brightSpring: [
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "clear cyan"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "royal blue"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "steel grey"),
            ],
            .trueAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bronze"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "deep teal"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "cocoa"),
            ],
        ],

        // ── Light Summer ──
        .lightSummer: [
            .trueSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "berry mauve"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "soft violet"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "cool stone"),
            ],
            .lightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "apricot"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "peach"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "light camel"),
            ],
        ],

        // ── True Summer ──
        .trueSummer: [
            .softSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "dusty plum"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "smoky periwinkle"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "muted charcoal"),
            ],
            .softAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "soft copper"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "muted teal"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "warm taupe"),
            ],
            .trueWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 2, sourceColourName: "icy blue"),
                CuratedSubstitution(band: .core,    targetIndex: 0, sourceColourName: "cobalt"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "icy grey"),
            ],
        ],

        // ── Soft Summer ──
        .softSummer: [
            .trueSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "berry mauve"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "soft violet"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "cool stone"),
            ],
            .softAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "moss green"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "olive sage"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "olive beige"),
            ],
        ],

        // ── Soft Autumn ──
        .softAutumn: [
            .trueAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bronze"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "ochre"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "deep khaki"),
            ],
            .deepAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "copper"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "dark terracotta"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "bark brown"),
            ],
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 2, sourceColourName: "steel grey"),
                CuratedSubstitution(band: .core,    targetIndex: 2, sourceColourName: "icy teal"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "ink navy"),
            ],
        ],

        // ── True Autumn ──
        .trueAutumn: [
            .deepAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "deep amber"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "forest teal"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "espresso"),
            ],
            .trueSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "goldenrod"),
                CuratedSubstitution(band: .core,    targetIndex: 2, sourceColourName: "marigold"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "warm stone"),
            ],
        ],

        // ── Deep Autumn ──
        .deepAutumn: [
            .trueAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "warm auburn"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "ochre"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "cocoa"),
            ],
            .deepWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 2, sourceColourName: "cool ruby"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "petrol"),
                CuratedSubstitution(band: .neutral, targetIndex: 1, sourceColourName: "cool charcoal"),
            ],
        ],

        // ── Deep Winter ──
        .deepWinter: [
            .deepAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "copper"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "oxblood"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "warm charcoal"),
            ],
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "true red"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "royal blue"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "steel grey"),
            ],
        ],

        // ── True Winter ──
        .trueWinter: [
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "clear cyan"),
                CuratedSubstitution(band: .core,    targetIndex: 2, sourceColourName: "magenta red"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "ink navy"),
            ],
            .trueSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "pewter"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "sage aqua"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "dove grey"),
            ],
        ],

        // ── Bright Winter ──
        .brightWinter: [
            .brightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bright gold"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "bright teal"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "warm navy"),
            ],
            .trueWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "fuchsia red"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "clear pine"),
                CuratedSubstitution(band: .neutral, targetIndex: 3, sourceColourName: "icy grey"),
            ],
        ],
    ]

    // MARK: - Flag-to-Pull Alignment

    private static let flagAlignmentTable: [PaletteFamily: [KeyPath<OverrideFlags, Bool>]] = [
        .deepWinter:    [\.winterCompressionApplied, \.coolLeanDeepAutumn, \.scorpioDensityApplied, \.capricornVirgoCoolingApplied],
        .trueWinter:    [\.winterCompressionApplied, \.capricornVirgoCoolingApplied],
        .brightWinter:  [\.winterCompressionApplied, \.fireAirChromaApplied],
        .brightSpring:  [\.fireAirChromaApplied],
        .softSummer:    [\.waterSofteningApplied],
        .trueSummer:    [\.waterSofteningApplied],
        .lightSummer:   [\.waterSofteningApplied],
        .deepAutumn:    [\.earthDepthOverrideApplied, \.scorpioDensityApplied],
        .trueAutumn:    [\.earthDepthOverrideApplied],
        .softAutumn:    [\.surfacePreservationApplied],
        .lightSpring:   [],
        .trueSpring:    [],
    ]

    // MARK: - Pull Strength

    static func pullStrength(
        secondaryPull: PaletteFamily,
        flags: OverrideFlags
    ) -> Int {
        let alignedPaths = flagAlignmentTable[secondaryPull] ?? []
        let alignedCount = alignedPaths.filter { flags[keyPath: $0] }.count
        return min(1 + alignedCount, 3)
    }

    // MARK: - Apply Variation

    static func apply(
        base: PaletteTriadV4,
        family: PaletteFamily,
        secondaryPull: PaletteFamily?,
        overrideFlags: OverrideFlags
    ) -> (palette: PaletteTriadV4, trace: VariationTrace) {
        guard let pull = secondaryPull,
              let entries = substitutionMap[family]?[pull] else {
            return (base, .none)
        }

        let strength = pullStrength(secondaryPull: pull, flags: overrideFlags)
        let activeEntries = Array(entries.prefix(strength))

        var neutrals = base.neutrals
        var cores = base.coreColours
        var accents = base.accentColours
        var substitutions: [VariationSubstitution] = []

        for entry in activeEntries {
            let original: String
            switch entry.band {
            case .neutral:
                original = neutrals[entry.targetIndex]
                neutrals[entry.targetIndex] = entry.sourceColourName
            case .core:
                original = cores[entry.targetIndex]
                cores[entry.targetIndex] = entry.sourceColourName
            case .accent:
                original = accents[entry.targetIndex]
                accents[entry.targetIndex] = entry.sourceColourName
            }
            substitutions.append(VariationSubstitution(
                band: entry.band.rawValue,
                slotIndex: entry.targetIndex,
                originalColour: original,
                replacedWith: entry.sourceColourName,
                fromFamily: pull.rawValue
            ))
        }

        let variedPalette = PaletteTriadV4(
            neutrals: neutrals,
            coreColours: cores,
            accentColours: accents
        )
        let trace = VariationTrace(
            pullFamily: pull.rawValue,
            pullStrength: strength,
            substitutions: substitutions
        )
        return (variedPalette, trace)
    }
}
