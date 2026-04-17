//
//  BlueprintTokenGenerator.swift
//  Cosmic Fit
//
//  WP3 — Blueprint Interpretation Engine
//
//  Loads the WP4 astrological style dataset and generates section-aware
//  BlueprintToken arrays. Applies the weighting formula from §3b of the spec:
//
//    rawWeight = basePlanetWeight × dignityModifier × chartRulerMultiplier × aspectModifier
//    normalisedWeight = rawWeight / maxRawWeightInCategory
//

import Foundation

// MARK: - WP4 Dataset Decodable Types

struct AstrologicalStyleDataset: Codable {
    let planetSign: [String: PlanetSignEntry]
    let aspects: [String: AspectEntry]
    let housePlacements: [String: HousePlacementEntry]
    let elementBalance: [String: ElementBalanceEntry]
    let colourLibrary: [String: ColourLibraryEntry]

    enum CodingKeys: String, CodingKey {
        case planetSign = "planet_sign"
        case aspects
        case housePlacements = "house_placements"
        case elementBalance = "element_balance"
        case colourLibrary = "colour_library"
    }
}

struct PlanetSignEntry: Codable {
    let stylePhilosophy: String
    let textures: TextureData
    let colours: ColourData
    let metals: [String]
    let stones: [String]
    let patterns: PatternData
    let silhouetteKeywords: [String]
    let occasionModifiers: OccasionModifierData
    let codeLeaninto: [String]
    let codeAvoid: [String]
    let codeConsider: [String]
    let opposites: OppositesData

    enum CodingKeys: String, CodingKey {
        case stylePhilosophy = "style_philosophy"
        case textures, colours, metals, stones, patterns
        case silhouetteKeywords = "silhouette_keywords"
        case occasionModifiers = "occasion_modifiers"
        case codeLeaninto = "code_leaninto"
        case codeAvoid = "code_avoid"
        case codeConsider = "code_consider"
        case opposites
    }
}

struct TextureData: Codable {
    let good: [String]
    let bad: [String]
    let sweetSpotKeywords: [String]

    enum CodingKeys: String, CodingKey {
        case good, bad
        case sweetSpotKeywords = "sweet_spot_keywords"
    }
}

struct ColourData: Codable {
    let primary: [ColourEntry]
    let accent: [ColourEntry]
    let avoid: [String]
}

struct ColourEntry: Codable {
    let name: String
    let hex: String
}

struct PatternData: Codable {
    let recommended: [String]
    let avoid: [String]
}

struct OccasionModifierData: Codable {
    let work: String
    let intimate: String
    let daily: String
}

struct OppositesData: Codable {
    let textures: [String]
    let colours: [String]
    let silhouettes: [String]
    let mood: [String]
}

struct AspectEntry: Codable {
    let effect: String
    let textureModifier: String
    let colourModifier: String
    let codeAdditionLeaninto: String
    let codeAdditionAvoid: String

    enum CodingKeys: String, CodingKey {
        case effect
        case textureModifier = "texture_modifier"
        case colourModifier = "colour_modifier"
        case codeAdditionLeaninto = "code_addition_leaninto"
        case codeAdditionAvoid = "code_addition_avoid"
    }
}

struct HousePlacementEntry: Codable {
    let context: String
    let modifier: String
    let keywords: [String]?
    let codeConsiderBias: [String]?
    let occasionBias: [String]?
    let leanIntoBias: [String]?
    let hardwareBias: HardwareBias?

    struct HardwareBias: Codable {
        let metals: [String]
        let stones: [String]
    }

    enum CodingKeys: String, CodingKey {
        case context, modifier, keywords
        case codeConsiderBias = "code_consider_bias"
        case occasionBias = "occasion_bias"
        case leanIntoBias = "lean_into_bias"
        case hardwareBias = "hardware_bias"
    }
}

struct ElementBalanceEntry: Codable {
    let overallEnergy: String
    let paletteBias: String
    let textureBias: String

    enum CodingKeys: String, CodingKey {
        case overallEnergy = "overall_energy"
        case paletteBias = "palette_bias"
        case textureBias = "texture_bias"
    }
}

struct ColourLibraryEntry: Codable {
    let hex: String
    let associations: [String]
}

// MARK: - Token Generator

struct BlueprintTokenGenerator {

    // MARK: - Public API

    struct TokenGenerationResult {
        let tokens: [BlueprintToken]
        let dataset: AstrologicalStyleDataset
        let contributingCombos: [(key: String, aggregateWeight: Double)]
    }

    static func generate(
        analysis: ChartAnalysis,
        dataset: AstrologicalStyleDataset
    ) -> TokenGenerationResult {
        var rawTokens: [BlueprintToken] = []

        let relevantPlanets = buildRelevantPlanetList(analysis: analysis)
        var comboWeights: [String: Double] = [:]

        for (planetName, signName) in relevantPlanets {
            let key = "\(planetName.lowercased())_\(signName.lowercased())"
            guard let entry = dataset.planetSign[key] else { continue }

            let baseWeight = basePlanetWeight(for: planetName)
            let dignity = analysis.planetDignities[planetName] ?? .peregrine
            let dignityMod = dignityModifier(for: dignity)
            let chartRulerMul = planetName == analysis.chartRuler ? 2.5 : 1.0
            let aspectMod = bestAspectModifier(for: planetName, aspects: analysis.significantAspects)

            let house = analysis.planetHouses[planetName]
            let sectMod = Self.sectModifier(for: planetName, sectStatus: analysis.planetSectStatus)
            let houseMod = Self.houseModifier(for: house)

            let tokenRaw = baseWeight * dignityMod * chartRulerMul * aspectMod
            let comboRaw = tokenRaw * sectMod * houseMod

            comboWeights[key] = (comboWeights[key] ?? 0) + comboRaw

            let aspectStr = analysis.significantAspects
                .first(where: { $0.planet1 == planetName || $0.planet2 == planetName })
                .map { "\($0.planet1) \($0.aspectType) \($0.planet2)" }

            rawTokens += generateTokensFromEntry(
                entry: entry,
                rawWeight: tokenRaw,
                planetarySource: planetName,
                signSource: signName,
                houseSource: house,
                aspectSource: aspectStr
            )
        }

        let normalised = normaliseTokens(rawTokens)

        let sortedCombos = comboWeights
            .map { (key: $0.key, aggregateWeight: $0.value) }
            .sorted { $0.aggregateWeight > $1.aggregateWeight }

        return TokenGenerationResult(
            tokens: normalised,
            dataset: dataset,
            contributingCombos: sortedCombos
        )
    }

    // MARK: - House & Sect Modifiers (combo weight only)

    private static func houseModifier(for house: Int?) -> Double {
        guard let h = house else { return 1.0 }
        switch h {
        case 1, 10:  return 1.25
        case 4, 7:   return 1.19
        case 2, 5, 8: return 1.15
        case 11:     return 1.12
        case 6, 12:  return 1.04
        case 3, 9:   return 1.02
        default:     return 1.0
        }
    }

    private static func sectModifier(for planet: String, sectStatus: [String: PlanetSectStatus]) -> Double {
        guard let status = sectStatus[planet] else { return 1.0 }
        switch status {
        case .sectLight:        return 1.10
        case .beneficOfSect:    return 1.08
        case .maleficOfSect:    return 1.03
        case .contraryBenefic:  return 1.00
        case .contraryMalefic:  return 0.92
        case .contraryLuminary: return 0.96
        case .neutral:          return 1.00
        }
    }

    // MARK: - Dataset Loading

    static func loadDataset(from bundle: Bundle = .main) -> AstrologicalStyleDataset? {
        guard let url = bundle.url(
            forResource: "astrological_style_dataset",
            withExtension: "json"
        ) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AstrologicalStyleDataset.self, from: data)
        } catch {
            print("[BlueprintTokenGenerator] Failed to load dataset: \(error)")
            return nil
        }
    }

    static func loadDataset(from url: URL) -> AstrologicalStyleDataset? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AstrologicalStyleDataset.self, from: data)
        } catch {
            print("[BlueprintTokenGenerator] Failed to load dataset from \(url): \(error)")
            return nil
        }
    }

    // MARK: - Planet Weighting

    private static func basePlanetWeight(for planet: String) -> Double {
        switch planet {
        case "Venus":                     return 1.0
        case "Moon":                      return 0.9
        case "Ascendant":                 return 0.85
        case "Sun":                       return 0.8
        case "Mars":                      return 0.7
        case "Saturn":                    return 0.5
        case "Jupiter", "Mercury":        return 0.4
        case "Uranus", "Neptune", "Pluto": return 0.3
        default:                          return 0.2
        }
    }

    private static func dignityModifier(for dignity: DignityStatus) -> Double {
        switch dignity {
        case .domicile:   return 1.6
        case .exaltation: return 1.5
        case .peregrine:  return 1.0
        case .detriment:  return 0.8
        case .fall:       return 0.7
        }
    }

    private static func bestAspectModifier(
        for planet: String,
        aspects: [ChartAspect]
    ) -> Double {
        let relevant = aspects.filter { $0.planet1 == planet || $0.planet2 == planet }
        guard !relevant.isEmpty else { return 1.0 }

        return relevant.map { aspectTypeModifier(for: $0.aspectType) }.max() ?? 1.0
    }

    private static func aspectTypeModifier(for type: String) -> Double {
        switch type {
        case "Conjunction":             return 1.3
        case "Trine", "Sextile":       return 1.15
        case "Square", "Opposition":   return 0.85
        default:                        return 1.0
        }
    }

    // MARK: - Token Generation from Dataset Entry

    private static func generateTokensFromEntry(
        entry: PlanetSignEntry,
        rawWeight: Double,
        planetarySource: String,
        signSource: String,
        houseSource: Int?,
        aspectSource: String?
    ) -> [BlueprintToken] {
        var tokens: [BlueprintToken] = []

        for texture in entry.textures.good {
            tokens.append(BlueprintToken(
                name: texture, category: .texture, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        for keyword in entry.textures.sweetSpotKeywords {
            tokens.append(BlueprintToken(
                name: keyword, category: .structure, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        for colour in entry.colours.primary {
            tokens.append(BlueprintToken(
                name: colour.name, category: .colour, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource,
                sourceColourRole: .primary
            ))
        }

        for colour in entry.colours.accent {
            tokens.append(BlueprintToken(
                name: colour.name, category: .colour, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource,
                sourceColourRole: .accent
            ))
        }

        for metal in entry.metals {
            tokens.append(BlueprintToken(
                name: metal, category: .metal, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        for stone in entry.stones {
            tokens.append(BlueprintToken(
                name: stone, category: .stone, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        for pattern in entry.patterns.recommended {
            tokens.append(BlueprintToken(
                name: pattern, category: .pattern, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        for keyword in entry.silhouetteKeywords {
            tokens.append(BlueprintToken(
                name: keyword, category: .silhouette, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        tokens.append(BlueprintToken(
            name: entry.stylePhilosophy, category: .expression, weight: rawWeight,
            planetarySource: planetarySource, signSource: signSource,
            houseSource: houseSource, aspectSource: aspectSource
        ))

        let moodKeywords = entry.stylePhilosophy
            .components(separatedBy: ", ")
            .prefix(3)
        for keyword in moodKeywords {
            tokens.append(BlueprintToken(
                name: keyword.trimmingCharacters(in: .whitespaces),
                category: .mood, weight: rawWeight,
                planetarySource: planetarySource, signSource: signSource,
                houseSource: houseSource, aspectSource: aspectSource
            ))
        }

        return tokens
    }

    // MARK: - Normalisation

    /// Normalises raw weights within each TokenCategory to a 0.0–1.0 range.
    /// normalisedWeight = rawWeight / maxRawWeightInCategory
    static func normaliseTokens(_ tokens: [BlueprintToken]) -> [BlueprintToken] {
        var maxByCategory: [BlueprintToken.TokenCategory: Double] = [:]
        for token in tokens {
            let current = maxByCategory[token.category] ?? 0
            if token.weight > current {
                maxByCategory[token.category] = token.weight
            }
        }

        return tokens.map { token in
            let maxRaw = maxByCategory[token.category] ?? 1.0
            let normalised = maxRaw > 0 ? token.weight / maxRaw : 0
            return BlueprintToken(
                name: token.name,
                category: token.category,
                weight: normalised,
                planetarySource: token.planetarySource,
                signSource: token.signSource,
                houseSource: token.houseSource,
                aspectSource: token.aspectSource,
                sourceColourRole: token.sourceColourRole
            )
        }
    }

    // MARK: - Planet List

    /// Builds the list of (planet, sign) pairs that contribute tokens.
    /// Includes all chart planets plus Ascendant as a synthetic "planet".
    private static func buildRelevantPlanetList(
        analysis: ChartAnalysis
    ) -> [(String, String)] {
        var list: [(String, String)] = []

        let planetNames = ["Sun", "Moon", "Mercury", "Venus", "Mars",
                           "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"]

        for name in planetNames {
            if let sign = analysis.planetSigns[name] {
                list.append((name, sign))
            }
        }

        list.append(("Ascendant", analysis.ascendantSign))

        return list
    }
}
