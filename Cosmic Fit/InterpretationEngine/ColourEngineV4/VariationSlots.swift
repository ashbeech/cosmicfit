import Foundation

enum VariationSlots {

    struct CuratedSubstitution {
        enum Band: String { case neutral, core, accent, support }
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
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "slate"),
            ],
            .lightSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "rose quartz"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "seafoam"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "warm stone"),
            ],
        ],

        // ── True Spring ──
        .trueSpring: [
            .brightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bright gold"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "electric blue"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "slate"),
            ],
        ],

        // ── Bright Spring ──
        .brightSpring: [
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "clear cyan"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "royal blue"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel sand"),
            ],
            .trueAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bronze"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "deep teal"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "graphite"),
            ],
        ],

        // ── Light Summer ──
        .lightSummer: [
            .trueSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "berry mauve"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "soft violet"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "cocoa"),
            ],
            .lightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "apricot"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "peach"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "mist navy"),
            ],
        ],

        // ── True Summer ──
        .trueSummer: [
            .softSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "dusty plum"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "smoky periwinkle"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel"),
            ],
            .softAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "soft copper"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "muted teal"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "slate"),
            ],
            .trueWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 2, sourceColourName: "icy blue"),
                CuratedSubstitution(band: .core,    targetIndex: 0, sourceColourName: "cobalt"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel"),
            ],
        ],

        // ── Soft Summer ──
        .softSummer: [
            .trueSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "berry mauve"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "soft violet"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "cocoa"),
            ],
            .softAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "moss green"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "olive sage"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "slate"),
            ],
        ],

        // ── Soft Autumn ──
        .softAutumn: [
            .trueAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bronze"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "ochre"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "graphite"),
            ],
            .deepAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "copper"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "dark terracotta"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "midnight olive"),
            ],
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 2, sourceColourName: "steel grey"),
                CuratedSubstitution(band: .core,    targetIndex: 2, sourceColourName: "icy teal"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel sand"),
            ],
        ],

        // ── True Autumn ──
        .trueAutumn: [
            .deepAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "deep amber"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "forest teal"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "midnight olive"),
            ],
            .trueSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "goldenrod"),
                CuratedSubstitution(band: .core,    targetIndex: 2, sourceColourName: "marigold"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "graphite"),
            ],
        ],

        // ── Deep Autumn ──
        .deepAutumn: [
            .trueAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "warm auburn"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "ochre"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "graphite"),
            ],
            .deepWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 2, sourceColourName: "cool ruby"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "petrol"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "cocoa"),
            ],
        ],

        // ── Deep Winter ──
        .deepWinter: [
            .deepAutumn: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "copper"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "oxblood"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "midnight olive"),
            ],
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "true red"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "royal blue"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel sand"),
            ],
        ],

        // ── True Winter ──
        .trueWinter: [
            .brightWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "clear cyan"),
                CuratedSubstitution(band: .core,    targetIndex: 2, sourceColourName: "magenta red"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel sand"),
            ],
            .trueSummer: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "pewter"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "sage aqua"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "cocoa"),
            ],
        ],

        // ── Bright Winter ──
        .brightWinter: [
            .brightSpring: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "bright gold"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "bright teal"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "slate"),
            ],
            .trueWinter: [
                CuratedSubstitution(band: .accent,  targetIndex: 3, sourceColourName: "fuchsia red"),
                CuratedSubstitution(band: .core,    targetIndex: 3, sourceColourName: "clear pine"),
                CuratedSubstitution(band: .support, targetIndex: 3, sourceColourName: "camel"),
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
        var supports = base.supportColours ?? []
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
            case .support:
                guard entry.targetIndex < supports.count else { continue }
                original = supports[entry.targetIndex]
                supports[entry.targetIndex] = entry.sourceColourName
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
            accentColours: accents,
            supportColours: supports.isEmpty ? base.supportColours : supports,
            lightAnchor: base.lightAnchor,
            deepAnchor: base.deepAnchor
        )
        let trace = VariationTrace(
            pullFamily: pull.rawValue,
            pullStrength: strength,
            substitutions: substitutions
        )
        return (variedPalette, trace)
    }
}
