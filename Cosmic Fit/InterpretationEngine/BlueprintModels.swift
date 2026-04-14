//
//  BlueprintModels.swift
//  Cosmic Fit
//
//  WP2 Blueprint Data Model — Frozen contract for WP3/WP4.
//
//  This file defines the complete typed output of the Blueprint pipeline.
//  It compiles standalone with Foundation only. No dependencies on existing
//  codebase types (StyleToken, InterpretationResult, etc.).
//
//  Field source categories:
//    D  = Deterministic (computed by WP3 DeterministicResolver from WP4 dataset)
//    AI = AI-generated narrative (cached via BlueprintArchetypeKey lookup)
//    U  = User-input passthrough
//    M  = Runtime metadata
//
//  See _reference/blueprint_model_field_sources.md for the full mapping.
//

import Foundation

// MARK: - Root

/// The complete, per-user Cosmic Blueprint output.
/// Assembled by `BlueprintComposer` from deterministic + cached narrative data.
struct CosmicBlueprint: Codable, Equatable {
    let userInfo: BlueprintUserInfo           // U + M (see fields below)
    let styleCore: StyleCoreSection           // AI
    let textures: TexturesSection             // AI
    let palette: PaletteSection               // D + AI
    let occasions: OccasionsSection           // AI
    let hardware: HardwareSection             // D + AI
    let code: CodeSection                     // D
    let accessory: AccessorySection           // AI
    let pattern: PatternSection               // D + AI
    let generatedAt: Date                     // M
    let engineVersion: String                 // M
}

// MARK: - User Info

struct BlueprintUserInfo: Codable, Equatable {
    let birthDate: Date                       // U
    let birthLocation: String                 // U
    let generationDate: Date                  // M — set by engine at generation time
}

// MARK: - Style Core

struct StyleCoreSection: Codable, Equatable {
    /// AI-generated opening narrative (1–2 paragraphs).
    let narrativeText: String                 // AI — key: "style_core"
}

// MARK: - Textures

struct TexturesSection: Codable, Equatable {
    /// AI-generated paragraph describing favourable textures.
    let goodText: String                      // AI — key: "textures_good"
    /// AI-generated paragraph describing textures to avoid.
    let badText: String                       // AI — key: "textures_bad"
    /// AI-generated paragraph describing the ideal texture balance.
    let sweetSpotText: String                 // AI — key: "textures_sweet_spot"
    /// Deterministic list of recommended textures (top 4).
    let recommendedTextures: [String]         // D
    /// Deterministic list of textures to avoid (top 3).
    let avoidTextures: [String]              // D
    /// Deterministic sweet-spot keywords (top 2).
    let sweetSpotKeywords: [String]          // D

    init(goodText: String, badText: String, sweetSpotText: String,
         recommendedTextures: [String] = [], avoidTextures: [String] = [],
         sweetSpotKeywords: [String] = []) {
        self.goodText = goodText
        self.badText = badText
        self.sweetSpotText = sweetSpotText
        self.recommendedTextures = recommendedTextures
        self.avoidTextures = avoidTextures
        self.sweetSpotKeywords = sweetSpotKeywords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        goodText = try container.decode(String.self, forKey: .goodText)
        badText = try container.decode(String.self, forKey: .badText)
        sweetSpotText = try container.decode(String.self, forKey: .sweetSpotText)
        recommendedTextures = try container.decodeIfPresent([String].self, forKey: .recommendedTextures) ?? []
        avoidTextures = try container.decodeIfPresent([String].self, forKey: .avoidTextures) ?? []
        sweetSpotKeywords = try container.decodeIfPresent([String].self, forKey: .sweetSpotKeywords) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case goodText, badText, sweetSpotText
        case recommendedTextures, avoidTextures, sweetSpotKeywords
    }
}

// MARK: - Palette

struct PaletteSection: Codable, Equatable {
    /// Deterministic core colours (typically 3–4).
    let coreColours: [BlueprintColour]        // D
    /// Deterministic accent colours (typically 2–3).
    let accentColours: [BlueprintColour]      // D
    /// Grouped tonal families derived from the anchor colours above.
    /// Each family contains the anchor plus lighter/deeper tonal variants.
    /// Display-only — anchor names are used for narrative placeholders.
    let swatchFamilies: [SwatchFamily]        // D
    /// AI-generated narrative about the user's palette.
    let narrativeText: String                 // AI — key: "palette_narrative"

    init(coreColours: [BlueprintColour], accentColours: [BlueprintColour],
         swatchFamilies: [SwatchFamily] = [], narrativeText: String) {
        self.coreColours = coreColours
        self.accentColours = accentColours
        self.swatchFamilies = swatchFamilies
        self.narrativeText = narrativeText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coreColours = try container.decode([BlueprintColour].self, forKey: .coreColours)
        accentColours = try container.decode([BlueprintColour].self, forKey: .accentColours)
        swatchFamilies = try container.decodeIfPresent([SwatchFamily].self, forKey: .swatchFamilies) ?? []
        narrativeText = try container.decode(String.self, forKey: .narrativeText)
    }

    private enum CodingKeys: String, CodingKey {
        case coreColours, accentColours, swatchFamilies, narrativeText
    }
}

struct BlueprintColour: Codable, Equatable {
    let name: String
    let hexValue: String
    let role: ColourRole
}

enum ColourRole: String, Codable, CaseIterable {
    case core
    case accent
    case statement
}

/// A tonal family grouped around one anchor colour.
struct SwatchFamily: Codable, Equatable {
    let anchorName: String
    let anchorHex: String
    let role: ColourRole
    let tones: [SwatchTone]
}

/// A single derived tone within a swatch family.
struct SwatchTone: Codable, Equatable {
    let name: String
    let hex: String
}

// MARK: - Occasions

struct OccasionsSection: Codable, Equatable {
    /// AI-generated paragraph for work/professional context.
    let workText: String                      // AI — key: "occasions_work"
    /// AI-generated paragraph for intimate/evening context.
    let intimateText: String                  // AI — key: "occasions_intimate"
    /// AI-generated paragraph for daily/casual context.
    let dailyText: String                     // AI — key: "occasions_daily"
}

// MARK: - Hardware

struct HardwareSection: Codable, Equatable {
    /// AI-generated paragraph about recommended metals.
    let metalsText: String                    // AI — key: "hardware_metals"
    /// AI-generated paragraph about recommended stones.
    let stonesText: String                    // AI — key: "hardware_stones"
    /// AI-generated tip paragraph for hardware.
    let tipText: String                       // AI — key: "hardware_tip"
    /// Deterministic list of recommended metals.
    let recommendedMetals: [String]           // D
    /// Deterministic list of recommended stones.
    let recommendedStones: [String]           // D
}

// MARK: - Code

struct CodeSection: Codable, Equatable {
    /// Deterministic list of "lean into" directives (typically 4–6).
    let leanInto: [String]                    // D
    /// Deterministic list of "avoid" directives (typically 4–6).
    let avoid: [String]                       // D
    /// Deterministic list of "consider" directives (typically 3–4).
    let consider: [String]                    // D
}

// MARK: - Accessory

struct AccessorySection: Codable, Equatable {
    /// AI-generated paragraphs (always 3).
    let paragraphs: [String]                  // AI — keys: "accessory_1", "accessory_2", "accessory_3"
}

// MARK: - Pattern

struct PatternSection: Codable, Equatable {
    /// AI-generated narrative about pattern philosophy.
    let narrativeText: String                 // AI — key: "pattern_narrative"
    /// AI-generated tip about pattern usage.
    let tipText: String                       // AI — key: "pattern_tip"
    /// Deterministic list of recommended patterns.
    let recommendedPatterns: [String]         // D
    /// Deterministic list of patterns to avoid.
    let avoidPatterns: [String]               // D
}

// MARK: - Blueprint Token

/// Section-aware style token. Replaces the legacy `StyleToken`.
/// Generated by `BlueprintTokenGenerator` from the WP4 astrological dataset.
struct BlueprintToken: Codable, Equatable {
    let name: String
    let category: TokenCategory
    let weight: Double
    let planetarySource: String?
    let signSource: String?
    let houseSource: Int?
    let aspectSource: String?

    enum TokenCategory: String, Codable, CaseIterable {
        case texture                          // → TexturesSection
        case colour                           // → PaletteSection
        case silhouette                       // → OccasionsSection, CodeSection
        case metal                            // → HardwareSection (metals)
        case stone                            // → HardwareSection (stones)
        case pattern                          // → PatternSection
        case accessory                        // → AccessorySection
        case mood                             // → StyleCoreSection, OccasionsSection
        case structure                        // → CodeSection, TexturesSection
        case expression                       // → StyleCoreSection
    }
}

// MARK: - Archetype Key

/// Key for looking up pre-generated narrative paragraphs from `blueprint_narrative_cache.json`.
/// `section.rawValue` is the canonical JSON key — no mapping table needed.
struct BlueprintArchetypeKey: Codable, Hashable, Equatable {
    let section: BlueprintSection
    let archetypeCluster: String
    let variant: Int

    enum BlueprintSection: String, Codable, CaseIterable {
        case styleCore          = "style_core"
        case texturesGood       = "textures_good"
        case texturesBad        = "textures_bad"
        case texturesSweetSpot  = "textures_sweet_spot"
        case paletteNarrative   = "palette_narrative"
        case occasionsWork      = "occasions_work"
        case occasionsIntimate  = "occasions_intimate"
        case occasionsDaily     = "occasions_daily"
        case hardwareMetals     = "hardware_metals"
        case hardwareStones     = "hardware_stones"
        case hardwareTip        = "hardware_tip"
        case accessoryParagraph1 = "accessory_1"
        case accessoryParagraph2 = "accessory_2"
        case accessoryParagraph3 = "accessory_3"
        case patternNarrative   = "pattern_narrative"
        case patternTip         = "pattern_tip"
    }
}
