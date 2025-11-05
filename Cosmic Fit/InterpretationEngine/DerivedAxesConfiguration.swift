//
//  DerivedAxesConfiguration.swift
//  Cosmic Fit
//
//  Created for Derived Axes System implementation
//

import Foundation

/// Configuration constants for the Derived Axes System
struct DerivedAxesConfiguration {
    
    // MARK: - Evaluation Thresholds
    
    struct Evaluation {
        /// Threshold for considering an axis "high" (used in copy selection)
        static let highThreshold = 7.0
        
        /// Multiplier for strong planetary tokens (Mars, Saturn, Sun)
        static let strongTokenMultiplier = 1.5
        
        /// Multiplier for moderate planetary tokens (Jupiter, Mercury, Venus)
        static let moderateTokenMultiplier = 1.0
        
        /// Multiplier for weak/background tokens
        static let weakTokenMultiplier = 0.5
    }
    
    // MARK: - Copy Selection Configuration
    
    struct CopySelection {
        /// Gap required between action and strategy to trigger kinetic/grounded variants
        static let actionStrategyGap = 2.0
        
        /// Threshold for tempo to trigger fast/slow variants
        static let tempoThreshold = 7.0
        
        /// Threshold for visibility to trigger prominent/subtle variants
        static let visibilityThreshold = 7.0
        
        /// Threshold for strategy to trigger structured/fluid variants
        static let strategyThreshold = 7.0
    }
    
    // MARK: - Micro-Weighting Configuration
    
    struct MicroWeighting {
        /// Enable fine-tuning of section copy based on axis proximity
        static let enabled = false
        
        /// Maximum adjustment percentage for micro-weighting (0.0-1.0)
        static let maxAdjustment = 0.10
    }
    
    // MARK: - Tarot Affinity Configuration
    
    struct TarotAffinity {
        /// Weight multiplier for axis affinity scoring in tarot selection
        static let scoringWeight = 5.0
        
        /// Maximum distance for axis similarity (used in distance calculation)
        static let maxDistance = 20.0
    }
    
    // MARK: - Debug Configuration
    
    struct Debug {
        /// Log detailed axis evaluation to console
        static let logEvaluation = false
        
        /// Log copy selection decisions to console
        static let logCopySelection = false
        
        /// Log tarot axis matching to console
        static let logTarotMatching = false
    }
}
