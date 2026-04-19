//
//  NarrativeTemplateRenderer.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Substitutes named placeholders in narrative cache templates with the user's
//  actual resolved deterministic values. Group B sections flow through render();
//  Group A sections bypass this entirely.
//

import Foundation

struct NarrativeTemplateRenderer {

    // MARK: - Canonical Placeholder Vocabulary

    static let groupBSections: Set<String> = [
        "palette_narrative",
        "pattern_narrative", "pattern_tip",
        "hardware_metals", "hardware_stones", "hardware_tip",
        "textures_good", "textures_bad", "textures_sweet_spot",
    ]

    static let allPlaceholders: Set<String> = {
        var set = Set<String>()
        for i in 1...4 { set.insert("neutral_colour_\(i)") }
        for i in 1...4 { set.insert("core_colour_\(i)") }
        for i in 1...4 { set.insert("accent_colour_\(i)") }
        set.insert("family")
        set.insert("cluster")
        set.insert("depth")
        set.insert("temperature")
        set.insert("saturation")
        set.insert("contrast")
        set.insert("surface")
        for i in 1...4 { set.insert("recommended_pattern_\(i)") }
        for i in 1...2 { set.insert("avoid_pattern_\(i)") }
        for i in 1...3 { set.insert("metal_\(i)") }
        for i in 1...3 { set.insert("stone_\(i)") }
        for i in 1...4 { set.insert("texture_good_\(i)") }
        for i in 1...3 { set.insert("texture_bad_\(i)") }
        for i in 1...2 { set.insert("sweet_spot_keyword_\(i)") }
        return set
    }()

    // MARK: - Rendering

    private static let placeholderPattern = try! NSRegularExpression(
        pattern: "\\{([a-z_0-9]+)\\}",
        options: []
    )

    static func render(template: String, context: [String: String]) -> String {
        let nsTemplate = template as NSString
        let fullRange = NSRange(location: 0, length: nsTemplate.length)
        let matches = placeholderPattern.matches(in: template, options: [], range: fullRange)

        guard !matches.isEmpty else { return template }

        var replacements: [(range: NSRange, replacement: String)] = []
        for match in matches {
            let tokenRange = match.range(at: 1)
            guard tokenRange.location != NSNotFound else { continue }
            let token = nsTemplate.substring(with: tokenRange)

            let replacement: String
            if let value = context[token], !value.isEmpty {
                replacement = value
            } else if allPlaceholders.contains(token) {
                replacement = "a complementary choice"
            } else {
                print("[NarrativeTemplateRenderer] Warning: unrecognised placeholder {\(token)}")
                replacement = ""
            }
            replacements.append((range: match.range, replacement: replacement))
        }

        let mutable = NSMutableString(string: template)
        for item in replacements.reversed() {
            mutable.replaceCharacters(in: item.range, with: item.replacement)
        }
        return mutable as String
    }

    // MARK: - Context Builder

    static func buildContext(resolved: DeterministicResolverResult) -> [String: String] {
        var ctx: [String: String] = [:]

        for (i, c) in resolved.coreColours.enumerated() {
            ctx["core_colour_\(i + 1)"] = c.name
        }
        for (i, c) in resolved.accentColours.prefix(2).enumerated() {
            ctx["accent_colour_\(i + 1)"] = c.name
        }
        for (i, m) in resolved.recommendedMetals.enumerated() {
            ctx["metal_\(i + 1)"] = m
        }
        for (i, s) in resolved.recommendedStones.enumerated() {
            ctx["stone_\(i + 1)"] = s
        }
        for (i, p) in resolved.recommendedPatterns.enumerated() {
            ctx["recommended_pattern_\(i + 1)"] = p
        }
        for (i, p) in resolved.avoidPatterns.enumerated() {
            ctx["avoid_pattern_\(i + 1)"] = p
        }
        for (i, t) in resolved.recommendedTextures.enumerated() {
            ctx["texture_good_\(i + 1)"] = t
        }
        for (i, t) in resolved.avoidTextures.enumerated() {
            ctx["texture_bad_\(i + 1)"] = t
        }
        for (i, k) in resolved.sweetSpotKeywords.enumerated() {
            ctx["sweet_spot_keyword_\(i + 1)"] = k
        }

        return ctx
    }

    /// Builds V4 palette placeholders from a colour engine result. Merge into
    /// the main context so palette_narrative templates can reference family,
    /// variables, and all 12 colour names.
    static func buildV4PaletteContext(colourResult: ColourEngineResult) -> [String: String] {
        var ctx: [String: String] = [:]

        for (i, name) in colourResult.palette.neutrals.enumerated() {
            ctx["neutral_colour_\(i + 1)"] = name
        }
        for (i, name) in colourResult.palette.coreColours.enumerated() {
            ctx["core_colour_\(i + 1)"] = name
        }
        for (i, name) in colourResult.palette.accentColours.enumerated() {
            ctx["accent_colour_\(i + 1)"] = name
        }

        ctx["family"] = colourResult.family.rawValue
        ctx["cluster"] = colourResult.cluster.rawValue
        ctx["depth"] = colourResult.variables.depth.rawValue
        ctx["temperature"] = colourResult.variables.temperature.rawValue
        ctx["saturation"] = colourResult.variables.saturation.rawValue
        ctx["contrast"] = colourResult.variables.contrast.rawValue
        ctx["surface"] = colourResult.variables.surface.rawValue

        return ctx
    }
}
