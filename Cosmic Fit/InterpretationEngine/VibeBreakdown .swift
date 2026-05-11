//
//  VibeBreakdown.swift
//  Cosmic Fit
//
//  Defines the Energy enum and VibeBreakdown model used by the daily fit pipeline.
//

import Foundation

// MARK: - Energy Enum

/// Represents the six style energies
public enum Energy: String, CaseIterable, Codable {
    case classic
    case playful
    case romantic
    case utility
    case drama
    case edge
}

// MARK: - Vibe Breakdown Structure

struct VibeBreakdown: Codable {
    let classic: Int
    let playful: Int
    let romantic: Int
    let utility: Int
    let drama: Int
    let edge: Int
    
    init(classic: Int, playful: Int, romantic: Int, utility: Int, drama: Int, edge: Int) {
        self.classic = min(max(classic, 0), 10)
        self.playful = min(max(playful, 0), 10)
        self.romantic = min(max(romantic, 0), 10)
        self.utility = min(max(utility, 0), 10)
        self.drama = min(max(drama, 0), 10)
        self.edge = min(max(edge, 0), 10)
    }
    
    var totalPoints: Int {
        return classic + playful + romantic + utility + drama + edge
    }
    
    var isValid: Bool {
        return totalPoints == 21
    }
    
    func debugDescription() -> String {
        return "Classic: \(classic), Playful: \(playful), Romantic: \(romantic), Utility: \(utility), Drama: \(drama), Edge: \(edge) [Total: \(totalPoints)]"
    }
    
    // MARK: - Helper Methods (Unambiguous Enum-Based API)
    
    var dominantEnergy: Energy {
        let scored: [(Energy, Int)] = Energy.allCases.map { ($0, value(for: $0)) }
        return scored.max(by: { $0.1 < $1.1 })?.0 ?? .classic
    }
    
    var dominantEnergyName: String {
        return dominantEnergy.rawValue
    }
    
    var secondaryEnergy: Energy {
        let scored: [(Energy, Int)] = Energy.allCases.map { ($0, value(for: $0)) }
        let sorted = scored.sorted(by: { $0.1 > $1.1 })
        return sorted.count > 1 ? sorted[1].0 : .classic
    }
    
    var secondaryEnergyName: String {
        return secondaryEnergy.rawValue
    }
    
    func value(for energy: Energy) -> Int {
        switch energy {
        case .classic: return classic
        case .playful: return playful
        case .romantic: return romantic
        case .utility: return utility
        case .drama: return drama
        case .edge: return edge
        }
    }
    
    func value(for name: String) -> Int {
        guard let energy = Energy(rawValue: name.lowercased()) else { return 0 }
        return value(for: energy)
    }
}
