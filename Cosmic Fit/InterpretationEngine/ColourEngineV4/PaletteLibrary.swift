import Foundation

enum PaletteLibrary {

    static let library: [PaletteFamily: PaletteTriadV4] = [
        .lightSpring: PaletteTriadV4(
            neutrals: ["warm white", "buttercream", "pale sand", "light camel"],
            coreColours: ["honey yellow", "peach", "aqua mint", "lime"],
            accentColours: ["apricot", "soft gold", "clear aqua", "fresh leaf"]
        ),
        .trueSpring: PaletteTriadV4(
            neutrals: ["warm ivory", "camel sand", "light khaki", "warm stone"],
            coreColours: ["marigold", "coral", "fresh green", "clear turquoise"],
            accentColours: ["tomato red", "goldenrod", "bright jade", "clear aqua"]
        ),
        .brightSpring: PaletteTriadV4(
            neutrals: ["clear ivory", "warm navy", "graphite", "clear camel"],
            coreColours: ["poppy", "bright teal", "vivid yellow", "electric blue"],
            accentColours: ["lacquer coral", "acid lime", "bright gold", "clear aqua"]
        ),
        .lightSummer: PaletteTriadV4(
            neutrals: ["soft white", "pearl grey", "cool taupe", "mist navy"],
            coreColours: ["powder blue", "shell pink", "seafoam", "lavender mist"],
            accentColours: ["silver", "icy aqua", "soft lilac", "rose quartz"]
        ),
        .trueSummer: PaletteTriadV4(
            neutrals: ["dove grey", "mushroom taupe", "soft navy", "cool stone"],
            coreColours: ["dusty blue", "rose mauve", "sage aqua", "soft violet"],
            accentColours: ["pewter", "mist teal", "lavender grey", "berry mauve"]
        ),
        .softSummer: PaletteTriadV4(
            neutrals: ["stone grey", "mushroom", "smoked navy", "muted charcoal"],
            coreColours: ["eucalyptus", "muted rose", "moss sage", "smoky periwinkle"],
            accentColours: ["brushed pewter", "dusty plum", "sea glass", "faded mauve"]
        ),
        .softAutumn: PaletteTriadV4(
            neutrals: ["camel", "warm taupe", "oatmeal", "olive beige"],
            coreColours: ["terracotta", "olive sage", "muted teal", "soft rust"],
            accentColours: ["antique gold", "soft copper", "moss green", "muted amber"]
        ),
        .trueAutumn: PaletteTriadV4(
            neutrals: ["camel", "cocoa", "warm olive", "deep khaki"],
            coreColours: ["rust", "moss", "ochre", "deep teal"],
            accentColours: ["bronze", "amber", "olive gold", "warm auburn"]
        ),
        .deepAutumn: PaletteTriadV4(
            neutrals: ["espresso", "warm charcoal", "deep olive", "bark brown"],
            coreColours: ["oxblood", "forest teal", "forest green", "dark terracotta"],
            accentColours: ["antique gold", "aged brass", "copper", "deep amber"]
        ),
        .deepWinter: PaletteTriadV4(
            neutrals: ["black", "ink navy", "graphite", "cool charcoal"],
            coreColours: ["black cherry", "petrol", "dark emerald", "blue-black"],
            accentColours: ["silver", "gunmetal", "cool ruby", "icy teal"]
        ),
        .trueWinter: PaletteTriadV4(
            neutrals: ["black", "optic white", "graphite", "icy grey"],
            coreColours: ["cobalt", "crimson", "blue-red", "clear pine"],
            accentColours: ["silver", "icy blue", "fuchsia red", "hard white"]
        ),
        .brightWinter: PaletteTriadV4(
            neutrals: ["black", "bright white", "ink navy", "steel grey"],
            coreColours: ["midnight", "royal blue", "magenta red", "icy teal"],
            accentColours: ["chrome silver", "electric fuchsia", "clear cyan", "true red"]
        ),
    ]

    static func palette(for family: PaletteFamily) -> PaletteTriadV4 {
        library[family]!
    }

    // MARK: - Colour Name to Hex

    static let colourNameToHex: [String: String] = [
        // Light Spring
        "warm white": "#FAF5EF",
        "buttercream": "#F5E6C8",
        "pale sand": "#E8D5B7",
        "light camel": "#C9A96E",
        "honey yellow": "#E8A317",
        "peach": "#FFCBA4",
        "aqua mint": "#7FFFD4",
        "lime": "#A4C639",
        "apricot": "#FBCEB1",
        "soft gold": "#D4AF37",
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
        "clear turquoise": "#08E8DE",
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
        "electric blue": "#0080FF",
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
        "brushed pewter": "#7C7D7D",
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
        "antique gold": "#C9A84C",
        "soft copper": "#BD7E55",
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
        "forest green": "#254D32",
        "dark terracotta": "#9E4E3A",
        "aged brass": "#8E7530",
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
        "fuchsia red": "#C81585",
        "hard white": "#FAFAFA",

        // Bright Winter
        "bright white": "#FFFFFF",
        "steel grey": "#71797E",
        "midnight": "#191970",
        "royal blue": "#4169E1",
        "magenta red": "#CC0066",
        "chrome silver": "#DBE0E3",
        "electric fuchsia": "#FF00FF",
        "clear cyan": "#00FFFF",
        "true red": "#CC0000",
    ]

    static func hex(for colourName: String) -> String {
        colourNameToHex[colourName] ?? "#808080"
    }
}
