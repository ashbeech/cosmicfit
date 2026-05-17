//
//  DebugConfiguration.swift
//  Cosmic Fit
//
//  Central configuration for debug capabilities throughout the app
//

import Foundation

/// Central debug configuration that eliminates duplication
struct DebugConfiguration {
    
    // MARK: - Entitlement Override
    
    /// When true, `EntitlementManager` bypasses StoreKit and reports full access.
    /// Set to `true` during feature development so locked sections are accessible.
    /// Defaults to `false` so the app launches in production-like mode for testing.
    /// Only compiles under #if DEBUG — zero footprint in release builds.
    #if DEBUG
    static var overrideEntitlementUnlocked: Bool = true
    #endif
    
    // MARK: - Debug Control
    
    /// Master debug flag - controls all debug functionality
    static var isDebugEnabled: Bool {
        #if DEBUG
        return _isDebugEnabled
        #else
        return false
        #endif
    }
    
    private static var _isDebugEnabled: Bool = false
    
    /// Enable/disable debug mode at runtime
    static func setDebugMode(_ enabled: Bool) {
        #if DEBUG
        _isDebugEnabled = enabled
        DebugLogger.currentLogLevel = enabled ? .debug : .info
        DebugLogger.enableParagraphAssemblyLogging = enabled
        DebugLogger.enableTokenDebugLogging = enabled
        #endif
    }
    
    // MARK: - Debug Logging Levels
    
    static var currentLogLevel: DebugLogger.LogLevel {
        return isDebugEnabled ? .debug : .info
    }
    
    static var enableParagraphAssemblyLogging: Bool {
        return isDebugEnabled
    }
    
    static var enableTokenDebugLogging: Bool {
        return isDebugEnabled
    }
    
    // MARK: - Debug Method Selection
    
    /// Execute debug version of code block if debug enabled, otherwise production version
    static func executeWithDebug<T>(
        debug: () -> T,
        production: () -> T
    ) -> T {
        return isDebugEnabled ? debug() : production()
    }
    
    /// Execute debug logging conditionally
    static func debugLog(_ block: () -> Void) {
        guard isDebugEnabled else { return }
        block()
    }
}
