import Foundation

enum PaletteLibrary {

    static let library: [PaletteFamily: PaletteTriadV4] = [
        .lightSpring: PaletteTriadV4(
            neutrals: ["warm white", "buttercream", "pale sand", "light camel"],
            coreColours: ["honey yellow", "light peach", "aqua mint", "apple green"],
            accentColours: ["apricot", "rich honey", "clear aqua", "fresh leaf"],
            lightAnchor: "warm white",
            deepAnchor: "warm charcoal"
        ),
        .trueSpring: PaletteTriadV4(
            neutrals: ["warm ivory", "camel sand", "light khaki", "warm stone"],
            coreColours: ["marigold", "coral", "fresh green", "bright aqua"],
            accentColours: ["tomato red", "goldenrod", "bright jade", "clear aqua"],
            lightAnchor: "warm ivory",
            deepAnchor: "graphite"
        ),
        .brightSpring: PaletteTriadV4(
            neutrals: ["clear ivory", "warm navy", "graphite", "clear camel"],
            coreColours: ["poppy", "bright teal", "vivid yellow", "bright blue"],
            accentColours: ["lacquer coral", "acid lime", "bright gold", "clear aqua"],
            lightAnchor: "clear ivory",
            deepAnchor: "clear black"
        ),
        .lightSummer: PaletteTriadV4(
            neutrals: ["soft white", "pearl grey", "cool taupe", "mist navy"],
            coreColours: ["powder blue", "shell pink", "seafoam", "lavender mist"],
            accentColours: ["silver", "icy aqua", "soft lilac", "rose quartz"],
            lightAnchor: "soft white",
            deepAnchor: "mist navy"
        ),
        .trueSummer: PaletteTriadV4(
            neutrals: ["dove grey", "mushroom taupe", "soft navy", "cool stone"],
            coreColours: ["dusty blue", "rose mauve", "sage aqua", "soft violet"],
            accentColours: ["pewter", "mist teal", "lavender grey", "berry mauve"],
            lightAnchor: "cool ivory",
            deepAnchor: "soft navy"
        ),
        .softSummer: PaletteTriadV4(
            neutrals: ["stone grey", "mushroom", "smoked navy", "muted charcoal"],
            coreColours: ["eucalyptus", "muted rose", "moss sage", "smoky periwinkle"],
            accentColours: ["smoke grey", "dusty plum", "sea glass", "faded mauve"],
            lightAnchor: "smoke white",
            deepAnchor: "muted charcoal"
        ),
        .softAutumn: PaletteTriadV4(
            neutrals: ["camel", "warm taupe", "oatmeal", "olive beige"],
            coreColours: ["terracotta", "olive sage", "muted teal", "soft rust"],
            accentColours: ["deep honey", "warm sienna", "moss green", "muted amber"],
            lightAnchor: "bone",
            deepAnchor: "bitter chocolate"
        ),
        .trueAutumn: PaletteTriadV4(
            neutrals: ["camel", "cocoa", "warm olive", "deep khaki"],
            coreColours: ["rust", "moss", "ochre", "deep teal"],
            accentColours: ["bronze", "amber", "olive gold", "warm auburn"],
            lightAnchor: "bone",
            deepAnchor: "espresso"
        ),
        .deepAutumn: PaletteTriadV4(
            neutrals: ["espresso", "warm charcoal", "deep olive", "bark brown"],
            coreColours: ["oxblood", "forest teal", "dark pine", "dark terracotta"],
            accentColours: ["deep honey", "warm umber", "copper", "deep amber"],
            lightAnchor: "warm cream",
            deepAnchor: "ink brown"
        ),
        .deepWinter: PaletteTriadV4(
            neutrals: ["black", "ink navy", "graphite", "cool charcoal"],
            coreColours: ["black cherry", "petrol", "dark emerald", "blue-black"],
            accentColours: ["silver", "gunmetal", "cool ruby", "icy teal"],
            lightAnchor: "optic white",
            deepAnchor: "black"
        ),
        .trueWinter: PaletteTriadV4(
            neutrals: ["black", "optic white", "graphite", "icy grey"],
            coreColours: ["cobalt", "crimson", "blue-red", "clear pine"],
            accentColours: ["silver", "icy blue", "deep magenta", "hard white"],
            lightAnchor: "optic white",
            deepAnchor: "black"
        ),
        .brightWinter: PaletteTriadV4(
            neutrals: ["black", "bright white", "ink navy", "steel grey"],
            coreColours: ["midnight", "royal blue", "hot pink", "icy teal"],
            accentColours: ["frost grey", "electric fuchsia", "clear cyan", "deep red"],
            lightAnchor: "bright white",
            deepAnchor: "black"
        ),
    ]

    static func palette(for family: PaletteFamily) -> PaletteTriadV4 {
        library[family]!
    }

    // MARK: - Support Colour Templates (V4.2)

    static let supportLibrary: [PaletteFamily: [String]] = [
        .lightSpring:  ["pearl grey", "cool taupe", "soft slate", "mist navy"],
        .trueSpring:   ["cool stone", "mist navy", "soft navy", "graphite"],
        .brightSpring: ["dove grey", "muted charcoal", "smoked navy", "slate"],
        .lightSummer:  ["buttercream", "pale sand", "light camel", "warm stone"],
        .trueSummer:   ["warm taupe", "warm stone", "camel", "cocoa"],
        .softSummer:   ["oatmeal", "warm taupe", "olive beige", "camel"],
        .softAutumn:   ["cool stone", "soft navy", "muted charcoal", "slate"],
        .trueAutumn:   ["cool stone", "steel grey", "ink navy", "graphite"],
        .deepAutumn:   ["ink navy", "cool charcoal", "slate", "midnight olive"],
        .deepWinter:   ["warm charcoal", "espresso", "bark brown", "cocoa"],
        .trueWinter:   ["warm taupe", "deep khaki", "espresso", "camel"],
        .brightWinter: ["warm stone", "deep khaki", "cocoa", "camel sand"],
    ]

    static func supportPalette(for family: PaletteFamily) -> [String] {
        supportLibrary[family]!
    }

    // MARK: - Colour Name to Hex

    static let colourNameToHex: [String: String] = [
        // Light Spring
        "warm white": "#FAF5EF",
        "buttercream": "#F5E6C8",
        "pale sand": "#E8D5B7",
        "light camel": "#C9A96E",
        "honey yellow": "#E8A317",
        "light peach": "#FFCBA4",
        "aqua mint": "#7FFFD4",
        "apple green": "#A4C639",
        "apricot": "#FBCEB1",
        "rich honey": "#D4AF37",
        "clear aqua": "#00CED1",
        "fresh leaf": "#71BC78",

        // True Spring
        "warm ivory": "#FFFFF0",
        "camel sand": "#C4A35A",
        "light khaki": "#C3B091",
        "warm stone": "#A89F91",
        "marigold": "#EAA221",
        "coral": "#FF7F50",
        "fresh green": "#4AE082",
        "bright aqua": "#08E8DE",
        "tomato red": "#FF6347",
        "goldenrod": "#DAA520",
        "bright jade": "#00A86B",

        // Bright Spring
        "clear ivory": "#FFFDF0",
        "warm navy": "#384C70",
        "graphite": "#4B4F54",
        "clear camel": "#C19A6B",
        "poppy": "#E35335",
        "bright teal": "#009B8D",
        "vivid yellow": "#FFE302",
        "bright blue": "#0080FF",
        "lacquer coral": "#E2583E",
        "acid lime": "#B0BF1A",
        "bright gold": "#FFD700",

        // Light Summer
        "soft white": "#F5F0EB",
        "pearl grey": "#C9C0BB",
        "cool taupe": "#B0A093",
        "mist navy": "#6B7B8D",
        "powder blue": "#B0E0E6",
        "shell pink": "#FFB4B4",
        "seafoam": "#93E9BE",
        "lavender mist": "#E6E6FA",
        "silver": "#C0C0C0",
        "icy aqua": "#B0F0F0",
        "soft lilac": "#C8A2C8",
        "rose quartz": "#F7CACA",

        // True Summer
        "dove grey": "#9C9A9A",
        "mushroom taupe": "#9E8E82",
        "soft navy": "#4F5D73",
        "cool stone": "#8A8D8F",
        "dusty blue": "#6E8FAD",
        "rose mauve": "#C08081",
        "sage aqua": "#7DA98E",
        "soft violet": "#9B87A4",
        "pewter": "#8B8E90",
        "mist teal": "#7EBDB4",
        "lavender grey": "#B4A7C7",
        "berry mauve": "#966676",

        // Soft Summer
        "stone grey": "#928E85",
        "mushroom": "#ADA39A",
        "smoked navy": "#3B4B5E",
        "muted charcoal": "#636B6F",
        "eucalyptus": "#6E9E8E",
        "muted rose": "#C29290",
        "moss sage": "#7A8B6A",
        "smoky periwinkle": "#8E82A7",
        "smoke grey": "#7C7D7D",
        "dusty plum": "#7E6585",
        "sea glass": "#89C4B0",
        "faded mauve": "#B09DA7",

        // Soft Autumn
        "camel": "#C19A6B",
        "warm taupe": "#AF9B88",
        "oatmeal": "#D2C6B2",
        "olive beige": "#B3A580",
        "terracotta": "#CC6644",
        "olive sage": "#8B8B4B",
        "muted teal": "#5E8E8E",
        "soft rust": "#B7654E",
        "deep honey": "#C9A84C",
        "warm sienna": "#BD7E55",
        "moss green": "#6B7F3E",
        "muted amber": "#CA8B39",

        // True Autumn
        "cocoa": "#7B5B3A",
        "warm olive": "#706238",
        "deep khaki": "#786D4E",
        "rust": "#B7410E",
        "moss": "#5B7744",
        "ochre": "#CC7722",
        "deep teal": "#014D4E",
        "bronze": "#CD7F32",
        "amber": "#FFBF00",
        "olive gold": "#A28C3A",
        "warm auburn": "#A0522D",

        // Deep Autumn
        "espresso": "#3C2415",
        "warm charcoal": "#4A4244",
        "deep olive": "#3C4B27",
        "bark brown": "#5C4033",
        "oxblood": "#4A1C20",
        "forest teal": "#0B4F4A",
        "dark pine": "#254D32",
        "dark terracotta": "#9E4E3A",
        "warm umber": "#8E7530",
        "copper": "#B87333",
        "deep amber": "#A36D2A",

        // Deep Winter
        "black": "#0A0A0A",
        "ink navy": "#1B2A4A",
        "cool charcoal": "#3B3F42",
        "black cherry": "#4D0F28",
        "petrol": "#1B3A4B",
        "dark emerald": "#014421",
        "blue-black": "#0D1B2A",
        "gunmetal": "#53565A",
        "cool ruby": "#9B1B30",
        "icy teal": "#5FADA5",

        // True Winter
        "optic white": "#FEFEFA",
        "icy grey": "#D6D6D6",
        "cobalt": "#0047AB",
        "crimson": "#DC143C",
        "blue-red": "#8A2BE2",
        "clear pine": "#2E8B57",
        "icy blue": "#A5F2F3",
        "deep magenta": "#C81585",
        "hard white": "#FAFAFA",

        // Bright Winter
        "bright white": "#FFFFFF",
        "steel grey": "#71797E",
        "midnight": "#191970",
        "royal blue": "#4169E1",
        "hot pink": "#CC0066",
        "frost grey": "#DBE0E3",
        "electric fuchsia": "#FF00FF",
        "clear cyan": "#00FFFF",
        "deep red": "#CC0000",

        // Support-only colours (V4.2)
        "slate": "#5B6770",
        "midnight olive": "#2F3A2B",
        "soft slate": "#8B9DAF",

        // Universal anchors (V4.3)
        // Light-edge anchors — each tinted to its family's temperature.
        "cool ivory": "#F3F3EE",
        "smoke white": "#E8E6E2",
        "bone": "#EFE6D3",
        "warm cream": "#F2E8D4",
        // Deep-edge anchors — each tinted to its family's temperature.
        "clear black": "#0D1014",
        "bitter chocolate": "#3A2A1E",
        "ink brown": "#2B1E15",

        // V4.8 — Black eligibility swatches
        "soft black": "#1A1A1E",
        "black brown": "#1C1210",
    ]

    static func hex(for colourName: String) -> String {
        colourNameToHex[colourName] ?? "#808080"
    }

    /// Nearest wardrobe colour token to `hex` in perceptual Lab space (for consistent UI labels).
    static func nearestColourName(forHex hex: String) -> String {
        nearestColourName(forHex: hex, excluding: [])
    }

    /// Nearest wardrobe token in Lab space, skipping any names in `excluding`
    /// (matched case-insensitively). Used so chart signature swatches are not
    /// labelled with the same token as a template row that already uses a
    /// different hex.
    static func nearestColourName(forHex hex: String, excluding: Set<String>) -> String {
        let blocked = Set(excluding.map { $0.lowercased() })
        guard ColourMath.hexToLab(hex) != nil else {
            return "palette colour"
        }
        var bestName = ""
        var bestDist = Double.infinity
        for (name, candidateHex) in colourNameToHex {
            guard !blocked.contains(name.lowercased()) else { continue }
            let d = ColourMath.labDistanceSquared(hex, candidateHex)
            if d < bestDist - 1e-9 {
                bestDist = d
                bestName = name
            } else if abs(d - bestDist) <= 1e-9 && (bestName.isEmpty || name < bestName) {
                bestName = name
            }
        }
        if !bestName.isEmpty { return bestName }
        if !blocked.isEmpty { return nearestColourName(forHex: hex, excluding: []) }
        return "palette colour"
    }

    /// Stable display names for the luminary + ruler signature pair: the second
    /// label never reuses the first, and neither reuses any `claimedTemplateNames`.
    static func signaturePairLabels(
        luminaryHex: String,
        rulerHex: String,
        claimedTemplateNames: Set<String>
    ) -> (luminary: String, ruler: String) {
        var claimed = Set(claimedTemplateNames.map { $0.lowercased() })
        let luminary = nearestColourName(forHex: luminaryHex, excluding: claimed)
        claimed.insert(luminary.lowercased())
        let ruler = nearestColourName(forHex: rulerHex, excluding: claimed)
        return (luminary, ruler)
    }

    /// Deduplicated accent display labels. For each accent slot, if its
    /// `displayName` (case-insensitive) collides with a name already claimed
    /// by template bands (or a preceding accent), it is replaced with the
    /// nearest `colourNameToHex` token for that accent's hex. Returns labels
    /// in the same order as the input slots.
    static func deduplicatedAccentLabels(
        slots: [AccentSlot],
        templateNames: [String],
        claimedTemplateNames: Set<String>
    ) -> [String] {
        var claimed = Set(claimedTemplateNames.map { $0.lowercased() })
        return slots.map { slot in
            let raw = slot.displayName.lowercased()
            if claimed.contains(raw) {
                let renamed = nearestColourName(forHex: slot.hex, excluding: claimed)
                claimed.insert(renamed.lowercased())
                return renamed
            } else {
                claimed.insert(raw)
                return slot.displayName
            }
        }
    }

    /// Deduplicated labels for template-sourced accent names (fallback path
    /// when no accent slots are present).
    static func deduplicatedAccentLabelsFromTemplate(
        names: [String],
        claimedTemplateNames: Set<String>
    ) -> [String] {
        var claimed = Set(claimedTemplateNames.map { $0.lowercased() })
        return names.map { name in
            let raw = name.lowercased()
            if claimed.contains(raw) {
                let renamed = nearestColourName(
                    forHex: hex(for: name), excluding: claimed
                )
                claimed.insert(renamed.lowercased())
                return renamed
            } else {
                claimed.insert(raw)
                return name
            }
        }
    }
}
