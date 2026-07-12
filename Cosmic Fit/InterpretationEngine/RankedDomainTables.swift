//
//  RankedDomainTables.swift
//  Cosmic Fit
//
//  SG-2 (Style Guide Quality Overhaul, Phase 2d).
//
//  Profile-conditional ranked domain tables: colours-by-role, textures with
//  use-cases, and accessory category specs. Keyed by the ChartAestheticProfile
//  dimensions so every matrix combination resolves to a real table (no empty
//  lookups). Loaded from `data/style_guide/ranked_domain_tables.json`.
//
//  These feed:
//    - SG-3 generation prompts (fill the output-contract `rankedItems`);
//    - the resolver's profile conditioning.
//
//  Frozen at the end of SG-2 (see injection_contract_freeze.md).
//

import Foundation

// MARK: - Decodable shapes

struct RankedColourNamed: Codable, Equatable {
    let name: String
    let role: String
}

struct RankedColourTable: Codable, Equatable {
    let neutrals: [RankedColourNamed]
    let accents: [RankedColourNamed]
    let relief: [RankedColourNamed]
    let passOver: [String]
}

struct RankedTextureRow: Codable, Equatable {
    let name: String
    let useCase: String
    let rank: Int
}

struct RankedAccessoryCategory: Codable, Equatable {
    let category: String
    let decision: String        // "include" | "omit"
    let reason: String
    let material: String?
    let finish: String?
}

struct RankedAccessoryTable: Codable, Equatable {
    let categories: [RankedAccessoryCategory]
}

struct RankedDomainTables: Codable, Equatable {
    let schemaVersion: Int
    let coloursByRole: [String: RankedColourTable]
    let textures: [String: [RankedTextureRow]]
    let accessorySpecs: [String: RankedAccessoryTable]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case coloursByRole = "colours_by_role"
        case textures
        case accessorySpecs = "accessory_specs"
    }
}

// MARK: - Loader + resolver

final class RankedDomainTablesLoader {

    static let shared = RankedDomainTablesLoader()

    private(set) var tables: RankedDomainTables?

    // MARK: Loading

    @discardableResult
    func loadFromBundle(bundle: Bundle = .main) -> Bool {
        guard tables == nil else { return true }
        guard let url = bundle.url(
            forResource: "ranked_domain_tables", withExtension: "json"
        ) else {
            print("[RankedDomainTablesLoader] ranked_domain_tables.json not found in bundle.")
            return false
        }
        return loadFromURL(url)
    }

    @discardableResult
    func loadFromURL(_ url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            self.tables = try JSONDecoder().decode(RankedDomainTables.self, from: data)
            return true
        } catch {
            print("[RankedDomainTablesLoader] Failed to load: \(error)")
            return false
        }
    }

    func inject(_ tables: RankedDomainTables) { self.tables = tables }

    // MARK: - Key construction (frozen contract)

    /// Colour table key: `<temperature>_<register>`, or `<temperature>_water_dominant`
    /// when the chart's dominant element is water (the distinct water lane).
    static func colourKey(
        temperature: ChartAestheticProfile.Temperature,
        register: ChartAestheticProfile.AestheticRegister,
        isWaterDominant: Bool
    ) -> String {
        isWaterDominant
            ? "\(temperature.rawValue)_water_dominant"
            : "\(temperature.rawValue)_\(register.rawValue)"
    }

    /// Texture table key: `water_dominant` for water charts, else the register.
    static func textureKey(
        register: ChartAestheticProfile.AestheticRegister,
        isWaterDominant: Bool
    ) -> String {
        isWaterDominant ? "water_dominant" : register.rawValue
    }

    /// Accessory table key: `<register>_<orientation>_<finishLane>`.
    static func accessoryKey(
        register: ChartAestheticProfile.AestheticRegister,
        orientation: ChartAestheticProfile.Orientation,
        finishLane: ChartAestheticProfile.FinishLane
    ) -> String {
        "\(register.rawValue)_\(orientation.rawValue)_\(finishLane.rawValue)"
    }

    // MARK: - Resolution (profile → table)

    func colourTable(
        for profile: ChartAestheticProfile, isWaterDominant: Bool = false
    ) -> RankedColourTable? {
        let key = Self.colourKey(
            temperature: profile.temperature,
            register: profile.aestheticRegister,
            isWaterDominant: isWaterDominant
        )
        // Fall back to the non-water register table if a water table is absent.
        return tables?.coloursByRole[key]
            ?? tables?.coloursByRole[
                Self.colourKey(temperature: profile.temperature,
                               register: profile.aestheticRegister,
                               isWaterDominant: false)]
    }

    func textureTable(
        for profile: ChartAestheticProfile, isWaterDominant: Bool = false
    ) -> [RankedTextureRow]? {
        let key = Self.textureKey(
            register: profile.aestheticRegister, isWaterDominant: isWaterDominant
        )
        return tables?.textures[key] ?? tables?.textures[profile.aestheticRegister.rawValue]
    }

    func accessoryTable(for profile: ChartAestheticProfile) -> RankedAccessoryTable? {
        let key = Self.accessoryKey(
            register: profile.aestheticRegister,
            orientation: profile.orientation,
            finishLane: profile.finishLane
        )
        return tables?.accessorySpecs[key]
    }
}
