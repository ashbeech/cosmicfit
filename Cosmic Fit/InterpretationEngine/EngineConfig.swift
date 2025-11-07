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
    
    /// Maximum transit token share as fraction of total pool (0.35 = 35%)
    static let transitCap: Double = 0.35
    
    /// Target transit share for distribution scaling (should match cap to avoid conflict)
    static let transitTargetShare: Double = 0.35
    
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
}

