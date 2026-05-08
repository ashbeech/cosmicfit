//
//  SignArchetypes.swift
//  Cosmic Fit
//
//  V4.5 — Shared sign-archetype LCH primitives and envelope projection.
//  Extracted from ChartSignatureResolver to be reused by AccentResolver.
//
//  V4.6 — SignAccentExpressions: temperature-conditioned multi-candidate
//  table for accent resolution. AccentResolver now picks from this table
//  via spike scoring instead of projecting the single-archetype into an
//  envelope. ChartSignatureResolver continues to use the original
//  archetypes for luminary/ruler signatures (unchanged).
//

import Foundation

// MARK: - Sign Expression (accent candidate)

struct SignExpression: Equatable {
    let L: Double
    let C: Double
    let h: Double
    let name: String
}

// MARK: - SignArchetypes

enum SignArchetypes {

    // MARK: - Archetype Table (signatures only)

    typealias Archetype = ChartSignatureResolver.Archetype

    static let archetypes: [V4ZodiacSign: Archetype] = ChartSignatureResolver.archetypes

    // MARK: - Family Envelope

    typealias Envelope = ChartSignatureResolver.Envelope

    static func envelope(for family: PaletteFamily) -> Envelope {
        ChartSignatureResolver.envelope(for: family)
    }

    // MARK: - Domicile Rulership (Ptolemaic)

    static func domicileRuler(of sign: V4ZodiacSign) -> DriverKey {
        switch sign {
        case .aries:       return .mars
        case .taurus:      return .venus
        case .gemini:      return .mercury
        case .cancer:      return .moon
        case .leo:         return .sun
        case .virgo:       return .mercury
        case .libra:       return .venus
        case .scorpio:     return .mars
        case .sagittarius: return .jupiter
        case .capricorn:   return .saturn
        case .aquarius:    return .saturn
        case .pisces:      return .jupiter
        }
    }

}

// MARK: - Sign Accent Expressions (temperature-conditioned candidates)

enum SignAccentExpressions {

    /// Returns the accent candidate list for a given sign + family temperature.
    /// Candidates are ordered most-canonical-first (tie-breaking signal).
    static func candidates(for sign: V4ZodiacSign, temperature: Temperature) -> [SignExpression] {
        expressions[sign]?[temperature] ?? []
    }

    // MARK: - Full Table (12 signs × 3 temperatures × 3-4 candidates)

    static let expressions: [V4ZodiacSign: [Temperature: [SignExpression]]] = [

        // ── Aries (Mars · Fire) ──────────────────────────────────
        .aries: [
            .warm: [
                SignExpression(L: 50, C: 62, h:  28, name: "Crimson Ember"),
                SignExpression(L: 55, C: 50, h:  42, name: "Burnt Sienna"),
                SignExpression(L: 60, C: 55, h:  18, name: "Warm Coral"),
            ],
            .cool: [
                SignExpression(L: 48, C: 52, h: 350, name: "Rose Madder"),
                SignExpression(L: 42, C: 55, h: 335, name: "Cool Berry"),
                SignExpression(L: 55, C: 45, h:   5, name: "Iced Crimson"),
            ],
            .neutral: [
                SignExpression(L: 48, C: 60, h:  25, name: "Cardinal Red"),
                SignExpression(L: 52, C: 48, h:  35, name: "Russet"),
                SignExpression(L: 55, C: 50, h:  15, name: "Terra Rose"),
            ],
        ],

        // ── Taurus (Venus · Earth) ──────────────────────────────
        .taurus: [
            .warm: [
                SignExpression(L: 45, C: 38, h: 100, name: "Olive Moss"),
                SignExpression(L: 52, C: 35, h:  90, name: "Warm Sage"),
                SignExpression(L: 55, C: 40, h:  85, name: "Golden Lichen"),
            ],
            .cool: [
                SignExpression(L: 38, C: 35, h: 155, name: "Forest Evergreen"),
                SignExpression(L: 48, C: 40, h: 170, name: "Minted Green"),
                SignExpression(L: 42, C: 38, h: 180, name: "Teal Moss"),
            ],
            .neutral: [
                SignExpression(L: 42, C: 32, h: 130, name: "Fertile Moss"),
                SignExpression(L: 48, C: 38, h: 145, name: "Jade Green"),
                SignExpression(L: 50, C: 30, h: 115, name: "Dusty Sage"),
            ],
        ],

        // ── Gemini (Mercury · Air) ──────────────────────────────
        .gemini: [
            .warm: [
                SignExpression(L: 42, C: 30, h: 195, name: "Mercury Teal"),
                SignExpression(L: 38, C: 28, h: 208, name: "Warm Petrol"),
                SignExpression(L: 45, C: 25, h: 182, name: "Verdigris"),
            ],
            .cool: [
                SignExpression(L: 62, C: 40, h: 200, name: "Mercurial Teal"),
                SignExpression(L: 68, C: 42, h: 190, name: "Cool Citrine"),
                SignExpression(L: 65, C: 38, h: 210, name: "Iced Aqua"),
            ],
            .neutral: [
                SignExpression(L: 50, C: 32, h: 195, name: "Mercury Air"),
                SignExpression(L: 55, C: 28, h: 205, name: "Warm Aqua"),
                SignExpression(L: 48, C: 30, h: 185, name: "Verdigris"),
            ],
        ],

        // ── Cancer (Moon · Water) ───────────────────────────────
        .cancer: [
            .warm: [
                SignExpression(L: 42, C: 18, h: 198, name: "Moonlit Teal"),
                SignExpression(L: 38, C: 15, h: 208, name: "Deep Moonstone"),
                SignExpression(L: 45, C: 20, h: 188, name: "Warm Sea Pearl"),
            ],
            .cool: [
                SignExpression(L: 78, C: 12, h: 225, name: "Lunar Silver"),
                SignExpression(L: 72, C: 18, h: 245, name: "Misty Blue"),
                SignExpression(L: 75, C: 15, h: 260, name: "Iced Pearl"),
            ],
            .neutral: [
                SignExpression(L: 55, C: 16, h: 210, name: "Moonstone"),
                SignExpression(L: 50, C: 18, h: 225, name: "Soft Silver"),
                SignExpression(L: 52, C: 14, h: 198, name: "Opal Teal"),
            ],
        ],

        // ── Leo (Sun · Fire) ────────────────────────────────────
        .leo: [
            .warm: [
                SignExpression(L: 72, C: 55, h:  78, name: "Solar Gold"),
                SignExpression(L: 58, C: 50, h:  62, name: "Antique Brass"),
                SignExpression(L: 55, C: 58, h:  52, name: "Amber Flame"),
            ],
            .cool: [
                SignExpression(L: 62, C: 42, h: 200, name: "Cool Topaz"),
                SignExpression(L: 55, C: 40, h: 275, name: "Regal Blue"),
                SignExpression(L: 72, C: 18, h: 250, name: "Platinum Frost"),
            ],
            .neutral: [
                SignExpression(L: 68, C: 52, h:  75, name: "Burnished Gold"),
                SignExpression(L: 62, C: 48, h:  68, name: "Rich Topaz"),
                SignExpression(L: 70, C: 50, h:  82, name: "Honey"),
            ],
        ],

        // ── Virgo (Mercury · Earth) ─────────────────────────────
        .virgo: [
            .warm: [
                SignExpression(L: 52, C: 28, h:  95, name: "Warm Sage"),
                SignExpression(L: 50, C: 25, h:  85, name: "Golden Khaki"),
                SignExpression(L: 55, C: 30, h:  90, name: "Warm Fern"),
            ],
            .cool: [
                SignExpression(L: 55, C: 22, h: 150, name: "Sage Mist"),
                SignExpression(L: 48, C: 28, h: 165, name: "Cool Fern"),
                SignExpression(L: 50, C: 25, h: 175, name: "Teal Sage"),
            ],
            .neutral: [
                SignExpression(L: 52, C: 22, h: 105, name: "Sage Earth"),
                SignExpression(L: 48, C: 25, h: 115, name: "Muted Olive"),
                SignExpression(L: 55, C: 20, h: 125, name: "Dusty Fern"),
            ],
        ],

        // ── Libra (Venus · Air) ─────────────────────────────────
        .libra: [
            .warm: [
                SignExpression(L: 42, C: 28, h: 340, name: "Warm Mauve"),
                SignExpression(L: 38, C: 25, h: 332, name: "Dusky Plum"),
                SignExpression(L: 45, C: 22, h: 348, name: "Burnished Rose"),
            ],
            .cool: [
                SignExpression(L: 68, C: 30, h: 295, name: "Iced Orchid"),
                SignExpression(L: 62, C: 35, h: 305, name: "Cool Mauve"),
                SignExpression(L: 72, C: 28, h: 285, name: "Lilac"),
            ],
            .neutral: [
                SignExpression(L: 52, C: 28, h: 345, name: "Venus Rose"),
                SignExpression(L: 48, C: 25, h: 335, name: "Dusty Rose"),
                SignExpression(L: 55, C: 22, h: 352, name: "Soft Pink"),
            ],
        ],

        // ── Scorpio (Mars/Pluto · Water) ────────────────────────
        .scorpio: [
            .warm: [
                SignExpression(L: 28, C: 45, h:  18, name: "Oxblood"),
                SignExpression(L: 32, C: 40, h:  30, name: "Dark Sienna"),
                SignExpression(L: 25, C: 42, h:  10, name: "Burnt Wine"),
            ],
            .cool: [
                SignExpression(L: 30, C: 40, h: 335, name: "Deep Plum"),
                SignExpression(L: 25, C: 42, h: 320, name: "Aubergine"),
                SignExpression(L: 28, C: 35, h: 310, name: "Midnight Berry"),
            ],
            .neutral: [
                SignExpression(L: 26, C: 42, h:  15, name: "Deep Wine"),
                SignExpression(L: 30, C: 38, h:   5, name: "Garnet"),
                SignExpression(L: 28, C: 40, h: 355, name: "Dark Cherry"),
            ],
        ],

        // ── Sagittarius (Jupiter · Fire) ────────────────────────
        .sagittarius: [
            .warm: [
                SignExpression(L: 55, C: 60, h:  55, name: "Ember"),
                SignExpression(L: 65, C: 55, h:  80, name: "Saffron Gold"),
                SignExpression(L: 45, C: 50, h:  40, name: "Burnt Copper"),
            ],
            .cool: [
                SignExpression(L: 35, C: 55, h: 310, name: "Royal Violet"),
                SignExpression(L: 50, C: 40, h: 320, name: "Iced Plum"),
            ],
            .neutral: [
                SignExpression(L: 40, C: 45, h: 330, name: "Deep Mauve"),
                SignExpression(L: 50, C: 55, h:  65, name: "Rich Amber"),
            ],
        ],

        // ── Capricorn (Saturn · Earth) ──────────────────────────
        .capricorn: [
            .warm: [
                SignExpression(L: 32, C: 22, h:  55, name: "Dark Bronze"),
                SignExpression(L: 28, C: 18, h:  40, name: "Warm Slate"),
                SignExpression(L: 30, C: 25, h:  50, name: "Umber"),
            ],
            .cool: [
                SignExpression(L: 25, C: 15, h: 260, name: "Saturn Slate"),
                SignExpression(L: 28, C: 18, h: 245, name: "Cool Graphite"),
                SignExpression(L: 32, C: 22, h: 235, name: "Steel Blue"),
            ],
            .neutral: [
                SignExpression(L: 25, C: 14, h: 255, name: "Dark Slate"),
                SignExpression(L: 32, C: 16, h: 220, name: "Pewter"),
                SignExpression(L: 28, C: 18, h: 240, name: "Gunmetal"),
            ],
        ],

        // ── Aquarius (Saturn · Air) ─────────────────────────────
        .aquarius: [
            .warm: [
                SignExpression(L: 38, C: 32, h: 200, name: "Deep Electric Teal"),
                SignExpression(L: 35, C: 28, h: 212, name: "Warm Prussian"),
                SignExpression(L: 42, C: 25, h: 192, name: "Burnished Teal"),
            ],
            .cool: [
                SignExpression(L: 55, C: 42, h: 215, name: "Electric Teal"),
                SignExpression(L: 60, C: 38, h: 225, name: "Iced Cyan"),
                SignExpression(L: 52, C: 45, h: 240, name: "Arctic Blue"),
            ],
            .neutral: [
                SignExpression(L: 48, C: 35, h: 205, name: "Aqua Blue"),
                SignExpression(L: 45, C: 32, h: 215, name: "Cerulean"),
                SignExpression(L: 50, C: 28, h: 195, name: "Muted Teal"),
            ],
        ],

        // ── Pisces (Jupiter · Water) ────────────────────────────
        .pisces: [
            .warm: [
                SignExpression(L: 38, C: 25, h: 195, name: "Deep Ocean"),
                SignExpression(L: 42, C: 22, h: 188, name: "Warm Aquamarine"),
                SignExpression(L: 35, C: 28, h: 205, name: "Midnight Teal"),
            ],
            .cool: [
                SignExpression(L: 70, C: 25, h: 205, name: "Cool Aquamarine"),
                SignExpression(L: 72, C: 22, h: 215, name: "Icy Seafoam"),
                SignExpression(L: 65, C: 28, h: 225, name: "Pale Ocean"),
            ],
            .neutral: [
                SignExpression(L: 50, C: 25, h: 190, name: "Ocean Mist"),
                SignExpression(L: 48, C: 22, h: 200, name: "Soft Aqua"),
                SignExpression(L: 45, C: 28, h: 182, name: "Lagoon"),
            ],
        ],
    ]
}
