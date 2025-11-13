//
//  EngineConfig.swift
//  Cosmic Fit
//
//  Created for Phase 1: Axis Token Source Implementation
//  Centralized configuration constants to prevent drift
//

import Foundation

/// Central configuration for Interpretation Engine Phase 1
/// All numeric thresholds and caps should be defined here to ensure consistency
struct EngineConfig {
    
    // MARK: - Transit Capping
    
    /// Maximum transit token share as fraction of total pool (0.65 = 65%)
    /// Increased to allow daily energy to breathe and create meaningful variation
    static let transitCap: Double = 0.65
    
    /// Target transit share for distribution scaling (40% for meaningful daily shifts)
    static let transitTargetShare: Double = 0.40
    
    // MARK: - Axis Token Generation
    
    /// Minimum axis token share (5%)
    static let axisShareMin: Double = 0.05
    
    /// Maximum axis token share (25%)
    static let axisShareMax: Double = 0.25
    
    /// Default target axis share before gap adjustment (15%)
    static let axisShareDefault: Double = 0.15
    
    /// How strongly semantic gaps amplify axis weighting (2.0 = double the gap effect)
    static let gapAmplificationFactor: Double = 2.0
    
    /// Hysteresis smoothing factor for axis share (0.3 = 30% of last value, 70% of new value)
    static let hysteresisAlpha: Double = 0.3
    
    // MARK: - Axis Calculation from Features
    
    /// Scale factor for angular momentum contribution to action axis
    static let angularMomentumScale: Double = 5.0
    
    /// Weight per transit aspect for action calculation
    static let transitContributionToAction: Double = 0.5
    
    /// Weight per aspect for tempo density calculation
    static let aspectDensityWeight: Double = 0.3
    
    // MARK: - Debug Configuration
    
    /// Enable verbose Phase 1 logging
    static let enablePhase1Logging: Bool = true
    
    /// Enable axis token generation debug output
    static let enableAxisDebug: Bool = true
    
    /// Enable transit capping debug output
    static let enableTransitCapDebug: Bool = true
    
    /// Enable token merging debug output
    static let enableMergeDebug: Bool = true
    
    // MARK: - Tarot Selection Scoring Weights (Phase 2 Vibe-Driven Correction)
    
    /// Target vibe alignment weight (50% - now primary driver for fashion/style selection)
    static let tarotVibeWeight: Double = 0.50
    
    /// Target axis similarity weight (35% - secondary structural consideration)
    static let tarotAxisWeight: Double = 0.35
    
    /// Target token boost weight (15% - contextual bonus)
    static let tarotTokenBoostWeight: Double = 0.15
    
    /// Multiplier for dominant energy to ensure it drives selection (applied to vibe score)
    static let dominantEnergyMultiplier: Double = 2.5
    
    /// Base axis floor before vibe-adaptive adjustments (Stage 1 filter)
    static let axisFloorBase: Double = 0.60
    
    /// Minimum vibe alignment threshold for card to be considered (0-1 scale)
    /// Cards below this threshold get heavily penalized even if axes match well
    static let vibeAlignmentFloor: Double = 0.30
    
    /// Enable vibe-adaptive axis floor filtering (allows romantic cards with lower axes to pass)
    static let enableVibeAdaptiveFiltering: Bool = true
    
    /// Vibe alignment thresholds for adaptive axis floor adjustments
    static let vibeAdaptiveStrongThreshold: Double = 0.55  // Strong vibe match
    static let vibeAdaptiveMediumThreshold: Double = 0.40  // Medium vibe match
    
    /// Axis floor reductions for vibe-adaptive filtering
    static let vibeAdaptiveStrongReduction: Double = 0.15  // Reduce floor by 15% for strong vibe
    static let vibeAdaptiveMediumReduction: Double = 0.10  // Reduce floor by 10% for medium vibe
    
    /// Minimum axis floor (safety limit - never go below this)
    static let axisFloorMinimum: Double = 0.45
    
    /// Epsilon threshold for tie-breaking (cards within this range are considered tied)
    static let tarotTieBreakEpsilon: Double = 0.15
    
    /// Enable vibe-first tie-breaking (prioritize vibe over axes in close matches)
    static let enableVibeFirstTieBreaking: Bool = true
    
    /// Optional: Stronger recency penalty for variety (tune if needed)
    static let tarotRecencyStrongPenalty: Double = 0.18  // Increased from default 0.12
    static let tarotRecencyWindowDays: Int = 10  // Increased from 7 for longer memory
}

