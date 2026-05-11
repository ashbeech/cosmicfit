//
//  DerivedAxesEvaluator.swift
//  Cosmic Fit
//
//  Created for Derived Axes System implementation
//

import Foundation

// MARK: - Derived Axes Model

/// Represents the four orthogonal derived axes that describe how style energy manifests
struct DerivedAxes: Codable {
    let action: Double      // 1-10: Movement, drive, direction (driven by Mars/Jupiter/Fire tokens)
    let tempo: Double       // 1-10: Speed, emotional temperature (driven by Lunar phase, aspect density)
    let strategy: Double    // 1-10: Structure, discipline (driven by Saturn/Mercury tokens)
    let visibility: Double  // 1-10: Outward vs inward energy (driven by Sun/MC/Jupiter tokens)
    
    init(action: Double, tempo: Double, strategy: Double, visibility: Double) {
        self.action = min(max(action, 1.0), 10.0)
        self.tempo = min(max(tempo, 1.0), 10.0)
        self.strategy = min(max(strategy, 1.0), 10.0)
        self.visibility = min(max(visibility, 1.0), 10.0)
    }
    
    func debugDescription() -> String {
        return String(format: "Action: %.1f, Tempo: %.1f, Strategy: %.1f, Visibility: %.1f",
                      action, tempo, strategy, visibility)
    }
}
