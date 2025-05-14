//
//  DebugLogger.swift
//  Cosmic Fit
//
//  Created for detailed paragraph assembly debugging
//

import Foundation

/// Debug logging utility specifically for the interpretation engine
class DebugLogger {
    
    // MARK: - Log Levels
    
    enum LogLevel: Int, Comparable {
        case none = 0
        case error = 1
        case warning = 2
        case info = 3
        case debug = 4
        case verbose = 5
        
        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    // MARK: - Properties
    
    /// Current log level - set to .none to disable all logging
    static var currentLogLevel: LogLevel = .verbose
    
    /// Enable/disable paragraph assembly logging specifically
    static var enableParagraphAssemblyLogging = true
    
    /// Enable/disable token debug logging
    static var enableTokenDebugLogging = true
    
    // MARK: - Standard Logging Methods
    
    /// Log an error message
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if currentLogLevel >= .error {
            log("❌ ERROR: \(message)", file: file, function: function, line: line)
        }
    }
    
    /// Log a warning message
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if currentLogLevel >= .warning {
            log("⚠️ WARNING: \(message)", file: file, function: function, line: line)
        }
    }
    
    /// Log an informational message
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if currentLogLevel >= .info {
            log("ℹ️ INFO: \(message)", file: file, function: function, line: line)
        }
    }
    
    /// Log a debug message
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if currentLogLevel >= .debug {
            log("🔍 DEBUG: \(message)", file: file, function: function, line: line)
        }
    }
    
    /// Log a verbose message
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if currentLogLevel >= .verbose {
            log("📝 VERBOSE: \(message)", file: file, function: function, line: line)
        }
    }
    
    // MARK: - Paragraph Assembly Logging
    
    /// Log information about a paragraph being assembled
    static func paragraphAssembly(sectionName: String, paragraphText: String, tokens: [StyleToken]) {
        guard enableParagraphAssemblyLogging else { return }
        
        // Create a separator based on section name length
        let separatorLength = min(max(sectionName.count, 20), 100)
        let separator = String(repeating: "━", count: separatorLength)
        
        // Begin section
        print("\n🔄 PARAGRAPH ASSEMBLY: \(sectionName.uppercased()) 🔄")
        print(separator)
        
        // Print the paragraph text
        print("📄 PARAGRAPH TEXT:")
        print(paragraphText)
        print("")
        
        // Show tokens that influenced this paragraph
        logInfluentialTokens(tokens)
        
        // Show astrological factors
        logAstrologicalFactors(tokens)
        
        // End separator
        print(separator)
    }
    
    /// Log a specific sentence being added to a paragraph with its influencing tokens
    static func sentence(text: String, influencedBy tokens: [StyleToken], inSection section: String) {
        guard enableParagraphAssemblyLogging else { return }
        
        // Create a smaller separator
        let separator = String(repeating: "┄", count: 60)
        
        print("\n📝 SENTENCE: [\(section)]")
        print(separator)
        
        // Print the sentence text
        print("\"" + text + "\"")
        
        // Show top tokens (limited to 3 for readability)
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(3)
        if !topTokens.isEmpty {
            print("🏷️ TOP INFLUENCING TOKENS:")
            for token in topTokens {
                print("  • \(token.name) (\(token.type)): weight \(String(format: "%.2f", token.weight))")
                
                // Add source information if available
                var sourceInfo = ""
                if let planet = token.planetarySource {
                    sourceInfo += " from \(planet)"
                }
                if let sign = token.signSource {
                    sourceInfo += " in \(sign)"
                }
                if let house = token.houseSource {
                    sourceInfo += " in house \(house)"
                }
                if let aspect = token.aspectSource {
                    sourceInfo += " via \(aspect)"
                }
                
                if !sourceInfo.isEmpty {
                    print("    \(sourceInfo)")
                }
            }
        }
        
        print(separator)
    }
    
    /// Log transition between paragraphs
    static func paragraphTransition(from: String, to: String) {
        guard enableParagraphAssemblyLogging else { return }
        
        print("\n🔀 PARAGRAPH TRANSITION")
        print("┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
        print("FROM: \(from)")
        print("TO: \(to)")
        print("┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
    }
    
    // MARK: - Token Debugging
    
    /// Log token set with descriptive title
    static func tokenSet(_ title: String, _ tokens: [StyleToken]) {
        guard enableTokenDebugLogging else { return }
        
        print("\n🪙 \(title) 🪙")
        print("  ▶ Count: \(tokens.count)")
        
        // Group by type
        var tokensByType: [String: [StyleToken]] = [:]
        for token in tokens {
            if tokensByType[token.type] == nil {
                tokensByType[token.type] = []
            }
            tokensByType[token.type]?.append(token)
        }
        
        // Print by type with weights
        for (type, typeTokens) in tokensByType.sorted(by: { $0.key < $1.key }) {
            print("  📊 \(type.uppercased())")
            
            // Sort by weight (highest first)
            let sorted = typeTokens.sorted { $0.weight > $1.weight }
            for token in sorted {
                var sourceInfo = ""
                if let planet = token.planetarySource {
                    sourceInfo += "[\(planet)]"
                }
                if let sign = token.signSource {
                    sourceInfo += "[\(sign)]"
                }
                if let house = token.houseSource {
                    sourceInfo += "[House \(house)]"
                }
                if let aspect = token.aspectSource {
                    sourceInfo += "[\(aspect)]"
                }
                
                print("    • \(token.name): \(String(format: "%.2f", token.weight)) \(sourceInfo)")
            }
        }
        
        // Count tokens by source
        var sourceCounts: [String: Int] = [:]
        for token in tokens {
            var source = "Unknown"
            if let planet = token.planetarySource {
                source = planet
            } else if let aspect = token.aspectSource {
                source = aspect
            }
            sourceCounts[source, default: 0] += 1
        }
        
        print("  🔍 SOURCE DISTRIBUTION:")
        for (source, count) in sourceCounts.sorted(by: { $0.value > $1.value }) {
            print("    • \(source): \(count) tokens")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Log a message with file, function, and line information
    private static func log(_ message: String, file: String, function: String, line: Int) {
        // Extract file name without path and extension
        let fileName = URL(fileURLWithPath: file).lastPathComponent.components(separatedBy: ".").first ?? file
        
        print("\(message) [\(fileName):\(line) \(function)]")
    }
    
    /// Log tokens that influenced a paragraph
    private static func logInfluentialTokens(_ tokens: [StyleToken]) {
        print("🏷️ INFLUENTIAL TOKENS:")
        
        // Group tokens by type for better organization
        var tokensByType: [String: [StyleToken]] = [:]
        for token in tokens {
            if tokensByType[token.type] == nil {
                tokensByType[token.type] = []
            }
            tokensByType[token.type]?.append(token)
        }
        
        // Print by type with weights
        for (type, typeTokens) in tokensByType.sorted(by: { $0.key < $1.key }) {
            print("  📊 \(type.uppercased())")
            
            // Sort by weight (highest first) and only show top 3 per type
            let sorted = typeTokens.sorted { $0.weight > $1.weight }.prefix(3)
            for token in sorted {
                print("    • \(token.name): \(String(format: "%.2f", token.weight))")
            }
        }
    }
    
    /// Log astrological factors that influenced a paragraph
    private static func logAstrologicalFactors(_ tokens: [StyleToken]) {
        print("🔮 ASTROLOGICAL FACTORS:")
        
        // Group by planetary source
        var planetarySources: [String: [StyleToken]] = [:]
        for token in tokens where token.planetarySource != nil {
            if planetarySources[token.planetarySource!] == nil {
                planetarySources[token.planetarySource!] = []
            }
            planetarySources[token.planetarySource!]?.append(token)
        }
        
        // Print by planetary source
        for (planet, planetTokens) in planetarySources.sorted(by: { $0.key < $1.key }) {
            // Get sign and house info if available
            var signInfo = ""
            var houseInfo = ""
            
            if let sign = planetTokens.first?.signSource {
                signInfo = " in \(sign)"
            }
            
            if let house = planetTokens.first?.houseSource {
                houseInfo = " in House \(house)"
            }
            
            print("  • \(planet)\(signInfo)\(houseInfo)")
            
            // Show top tokens for this planet (limited to 2 for readability)
            let topTokens = planetTokens.sorted { $0.weight > $1.weight }.prefix(2)
            for token in topTokens {
                print("      → \(token.name) (\(String(format: "%.2f", token.weight)))")
            }
        }
        
        // Group by aspect source
        var aspectSources: [String] = []
        for token in tokens where token.aspectSource != nil {
            if !aspectSources.contains(token.aspectSource!) {
                aspectSources.append(token.aspectSource!)
            }
        }
        
        // Print aspects
        if !aspectSources.isEmpty {
            print("  • Aspects:")
            for aspect in aspectSources.sorted() {
                print("      → \(aspect)")
            }
        }
    }
}

// Extension to make arrays of style tokens loggable
extension Array where Element == StyleToken {
    /// Log this array of tokens with the given title
    func debugLog(title: String) {
        DebugLogger.tokenSet(title, self)
    }
}
