//
//  PaletteValidator.swift
//  Cosmic Fit
//
//  V4.5 — Post-assembly palette diagnostics.
//  Two checks:
//    1. Accent diversity guard (actionable): pairwise Delta E >= 8 among 4 accents
//    2. Global palette diagnostic (passive): pairwise Delta E >= 5 among all 20 colours
//
//  Neither check alters colours in the global diagnostic case.
//  The accent guard is enforced inside AccentResolver before reaching here.
//

import Foundation

enum PaletteValidator {

    struct DiagnosticResult {
        let accentPairsBelow8: [(Int, Int, Double)]
        let globalPairsBelow5: [(Int, Int, Double)]
        var accentDiversityPassed: Bool { accentPairsBelow8.isEmpty }
        var globalDiversityPassed: Bool { globalPairsBelow5.isEmpty }
    }

    /// Runs both accent and global diversity checks.
    /// - Parameters:
    ///   - accentHexes: The 4 accent hex values
    ///   - allHexes: All 20 palette hex values (neutrals + core + accent + support + anchors + signatures)
    /// - Returns: Diagnostic result with any failing pairs
    static func validate(accentHexes: [String], allHexes: [String]) -> DiagnosticResult {
        let accentPairs = checkPairwise(hexes: accentHexes, thresholdSquared: 64.0)
        let globalPairs = checkPairwise(hexes: allHexes, thresholdSquared: 25.0)

        if !accentPairs.isEmpty {
            print("[PaletteValidator] WARNING: \(accentPairs.count) accent pair(s) below Delta E 8")
        }
        if !globalPairs.isEmpty {
            print("[PaletteValidator] INFO: \(globalPairs.count) global pair(s) below Delta E 5")
        }

        return DiagnosticResult(
            accentPairsBelow8: accentPairs,
            globalPairsBelow5: globalPairs
        )
    }

    private static func checkPairwise(
        hexes: [String],
        thresholdSquared: Double
    ) -> [(Int, Int, Double)] {
        var failures: [(Int, Int, Double)] = []
        for i in 0..<hexes.count {
            for j in (i + 1)..<hexes.count {
                let dist = ColourMath.labDistanceSquared(hexes[i], hexes[j])
                if dist < thresholdSquared {
                    failures.append((i, j, dist.squareRoot()))
                }
            }
        }
        return failures
    }
}
