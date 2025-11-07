//
//  AstroFeatures.swift
//  Cosmic Fit
//
//  Created for Phase 1: Axis Token Source Implementation
//  Raw astrological data container for axis calculation
//

import Foundation

// MARK: - Aspect Model

/// Represents an astrological aspect between two celestial bodies
struct Aspect: Codable {
    let planet1: String
    let planet2: String
    let type: String        // e.g., "Conjunction", "Trine", "Square"
    let orb: Double         // Orb in degrees
    let isApplying: Bool    // Whether aspect is applying or separating
    
    /// Calculate aspect strength based on orb (tighter = stronger)
    var strength: Double {
        let maxOrb = 10.0  // Maximum orb considered
        return max(0, 1.0 - (orb / maxOrb))
    }
    
    /// Check if this is a hard aspect (tension)
    var isHard: Bool {
        return ["Square", "Opposition", "Quincunx"].contains(type)
    }
    
    /// Check if this is a soft aspect (flow)
    var isSoft: Bool {
        return ["Trine", "Sextile"].contains(type)
    }
}

// MARK: - Astro Features

/// Raw astrological features extracted from charts for axis derivation
/// This struct is computed BEFORE token generation to avoid circular dependency
struct AstroFeatures {
    
    // MARK: - Raw Astrological Data
    
    let natalAspects: [Aspect]
    let transitAspects: [Aspect]
    let progressedAspects: [Aspect]
    let lunarPhase: Double          // 0-1 (0 = new moon, 0.5 = full moon)
    let weatherConditions: TodayWeather?
    
    // MARK: - Computed Metrics for Axis Derivation
    
    /// Total angular momentum from aspect orbs (tighter aspects = more energy)
    let totalAngularMomentum: Double
    
    /// Structural tension from hard vs soft aspects
    let structuralTension: Double
    
    /// Visibility index from luminaries and angle prominence
    let visibilityIndex: Double
    
    // MARK: - Initialization
    
    init(
        natalAspects: [Aspect],
        transitAspects: [Aspect],
        progressedAspects: [Aspect],
        lunarPhase: Double,
        weatherConditions: TodayWeather?
    ) {
        self.natalAspects = natalAspects
        self.transitAspects = transitAspects
        self.progressedAspects = progressedAspects
        self.lunarPhase = lunarPhase
        self.weatherConditions = weatherConditions
        
        // Compute derived metrics
        self.totalAngularMomentum = Self.calculateAngularMomentum(
            natalAspects: natalAspects,
            transitAspects: transitAspects,
            progressedAspects: progressedAspects
        )
        
        self.structuralTension = Self.calculateStructuralTension(
            natalAspects: natalAspects,
            transitAspects: transitAspects,
            progressedAspects: progressedAspects
        )
        
        self.visibilityIndex = Self.calculateVisibilityIndex(
            natalAspects: natalAspects,
            transitAspects: transitAspects,
            progressedAspects: progressedAspects
        )
    }
    
    // MARK: - Metric Calculations
    
    /// Calculate angular momentum from aspect density and tightness
    private static func calculateAngularMomentum(
        natalAspects: [Aspect],
        transitAspects: [Aspect],
        progressedAspects: [Aspect]
    ) -> Double {
        // Weight transits more heavily for daily momentum
        let natalMomentum = natalAspects.reduce(0.0) { $0 + $1.strength } * 0.3
        let transitMomentum = transitAspects.reduce(0.0) { $0 + $1.strength } * 1.0
        let progressedMomentum = progressedAspects.reduce(0.0) { $0 + $1.strength } * 0.5
        
        return (natalMomentum + transitMomentum + progressedMomentum) / 3.0
    }
    
    /// Calculate structural tension from hard vs soft aspect ratio
    private static func calculateStructuralTension(
        natalAspects: [Aspect],
        transitAspects: [Aspect],
        progressedAspects: [Aspect]
    ) -> Double {
        let allAspects = natalAspects + transitAspects + progressedAspects
        
        guard !allAspects.isEmpty else { return 0.5 }
        
        let hardAspects = allAspects.filter { $0.isHard }.count
        let softAspects = allAspects.filter { $0.isSoft }.count
        let total = hardAspects + softAspects
        
        guard total > 0 else { return 0.5 }
        
        // Returns 0-1 where 1 = all hard aspects, 0 = all soft aspects
        return Double(hardAspects) / Double(total)
    }
    
    /// Calculate visibility index from luminary and angle aspects
    private static func calculateVisibilityIndex(
        natalAspects: [Aspect],
        transitAspects: [Aspect],
        progressedAspects: [Aspect]
    ) -> Double {
        let luminaries = ["Sun", "Moon"]
        let angles = ["Ascendant", "Midheaven", "MC", "ASC"]
        
        let allAspects = natalAspects + transitAspects + progressedAspects
        
        let luminaryAspects = allAspects.filter {
            luminaries.contains($0.planet1) || luminaries.contains($0.planet2)
        }
        
        let angleAspects = allAspects.filter {
            angles.contains($0.planet1) || angles.contains($0.planet2)
        }
        
        // Combine luminary and angle prominence with more weight to angles
        let luminaryScore = Double(luminaryAspects.count) * 0.4
        let angleScore = Double(angleAspects.count) * 0.6
        
        // Normalize to 0-1 range (assume max ~10 relevant aspects)
        return min(1.0, (luminaryScore + angleScore) / 10.0)
    }
    
    // MARK: - Debug Description
    
    func debugDescription() -> String {
        return """
        AstroFeatures:
          Natal Aspects: \(natalAspects.count)
          Transit Aspects: \(transitAspects.count)
          Progressed Aspects: \(progressedAspects.count)
          Lunar Phase: \(String(format: "%.2f", lunarPhase))
          Angular Momentum: \(String(format: "%.2f", totalAngularMomentum))
          Structural Tension: \(String(format: "%.2f", structuralTension))
          Visibility Index: \(String(format: "%.2f", visibilityIndex))
        """
    }
}

