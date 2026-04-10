// DAILY FIT ONLY -- Not in scope for Blueprint rebuild. Do not modify during Blueprint work.
//
//  InterpretationTextLibraryShim.swift
//  Cosmic Fit
//
//  ⚠️ COMPILE-ONLY SHIM — Full file archived at _archive/InterpretationTextLibrary.swift ⚠️
//
//  WP1 ARCHIVING NOTE:
//  `InterpretationTextLibrary.swift` has been moved to _archive/ per the WP1 spec.
//  This shim keeps the `InterpretationTextLibrary` symbol available so the remaining
//  Daily Fit-only files continue to compile while their runtime callpaths stay
//  disconnected during the Blueprint rebuild.
//
//  The extracted planet-in-sign token tables live at:
//  `_archive/extracted_planet_sign_token_tables.json`

import Foundation

struct InterpretationTextLibrary {

    // MARK: - getText (used by DailyVibeGenerator)

    static func getText(forKey key: String, tokens: [StyleToken]? = nil) -> String? {
        return nil
    }

    // MARK: - TokenGeneration (used by SemanticTokenGenerator)

    struct TokenGeneration {
        struct PlanetInSign {
            struct Sun {
                static let descriptions: [String: [(String, String)]] = [:]
            }
            struct Moon {
                static let descriptions: [String: [(String, String)]] = [:]
            }
            struct Venus {
                static let descriptions: [String: [(String, String)]] = [:]
            }
            struct Mars {
                static let descriptions: [String: [(String, String)]] = [:]
            }
            struct Mercury {
                static let descriptions: [String: [(String, String)]] = [:]
            }
            struct OuterPlanets {
                static let jupiter: [(String, String)] = []
                static let saturn: [(String, String)] = []
                static let uranus: [(String, String)] = []
                static let neptune: [(String, String)] = []
                static let pluto: [(String, String)] = []
            }
            struct ElementalFallbacks {
                static let fire: [(String, String)] = []
                static let earth: [(String, String)] = []
                static let air: [(String, String)] = []
                static let water: [(String, String)] = []
            }
            struct Retrograde {
                static let venus: [(String, String)] = []
                static let mars: [(String, String)] = []
                static let mercury: [(String, String)] = []
            }
        }
    }
}
