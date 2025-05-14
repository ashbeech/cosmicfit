//
//  DebugLogger.swift
//  Cosmic Fit
//
//  Created to provide detailed interpretation assembly debugging
//

import Foundation

/// Utility for detailed debug logging of interpretation assembly process
class DebugLogger {
    
    // MARK: - Logging Levels
    
    /// Different levels of detail for debugging
    enum LogLevel: Int {
        case none = 0      // No logging
        case basic = 1     // Basic section headers
        case detailed = 2  // Full token influence details
        case verbose = 3   // Exhaustive token evaluation and paragraph building
    }
    
    // MARK: - Properties
    
    /// Current logging level
    static var level: LogLevel = .verbose
    
    /// Whether to include token weights in logs
    static var showWeights = true
    
    /// Whether to show source information (planets, signs, houses)
    static var showSources = true
    
    /// Whether section separators should be used
    static var useSeparators = true
    
    // MARK: - Basic Logging
    
    /// Log a simple message
    static func log(_ message: String) {
        guard level.rawValue >= LogLevel.basic.rawValue else { return }
        print(message)
    }
    
    /// Log a section header
    static func logSection(_ sectionName: String) {
        guard level.rawValue >= LogLevel.basic.rawValue else { return }
        
        if useSeparators {
            print("\n🔶 GENERATING SECTION: \(sectionName) 🔶")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } else {
            print("\n🔶 GENERATING SECTION: \(sectionName)")
        }
    }
    
    /// Log the end of a section
    static func logSectionEnd(_ sectionName: String) {
        guard level.rawValue >= LogLevel.basic.rawValue else { return }
        
        if useSeparators {
            print("✅ COMPLETED SECTION: \(sectionName)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } else {
            print("✅ COMPLETED SECTION: \(sectionName)")
        }
    }
    
    // MARK: - Paragraph Logging
    
    /// Log a generated paragraph with its influencing tokens
    static func logParagraph(_ paragraph: String, influencedBy tokens: [StyleToken] = [],
                            decisionFactors: [String] = []) {
        guard level.rawValue >= LogLevel.detailed.rawValue else { return }
        
        print("\n📝 PARAGRAPH OUTPUT:")
        print(paragraph)
        
        if !tokens.isEmpty {
            print("\n🧩 INFLUENCING TOKENS:")
            for token in tokens {
                var tokenInfo = "  • \(token.name)"
                
                if showWeights {
                    tokenInfo += " (weight: \(String(format: "%.2f", token.weight)))"
                }
                
                if showSources, let source = getSourceDescription(for: token) {
                    tokenInfo += " - \(source)"
                }
                
                print(tokenInfo)
            }
        }
        
        if !decisionFactors.isEmpty {
            print("\n🔍 DECISION FACTORS:")
            for factor in decisionFactors {
                print("  • \(factor)")
            }
        }
        
        print("")
    }
    
    /// Log a specific text choice and the tokens that influenced it
    static func logTextChoice(text: String, reason: String,
                             influencedBy tokens: [StyleToken] = []) {
        guard level.rawValue >= LogLevel.verbose.rawValue else { return }
        
        print("\n🔤 TEXT CHOICE: \"\(text)\"")
        print("📌 REASON: \(reason)")
        
        if !tokens.isEmpty {
            print("🧩 KEY TOKENS:")
            for token in tokens {
                var tokenInfo = "  • \(token.name)"
                
                if showWeights {
                    tokenInfo += " (weight: \(String(format: "%.2f", token.weight)))"
                }
                
                if showSources, let source = getSourceDescription(for: token) {
                    tokenInfo += " - \(source)"
                }
                
                print(tokenInfo)
            }
        }
        
        print("")
    }
    
    // MARK: - Token Analysis
    
    /// Log detailed token evaluation for a section
    static func logTokenEvaluation(sectionName: String, tokens: [StyleToken]) {
        guard level.rawValue >= LogLevel.verbose.rawValue else { return }
        
        print("\n🔬 TOKEN EVALUATION FOR: \(sectionName)")
        
        // Group tokens by type
        var tokensByType: [String: [StyleToken]] = [:]
        for token in tokens {
            if tokensByType[token.type] == nil {
                tokensByType[token.type] = []
            }
            tokensByType[token.type]?.append(token)
        }
        
        // Print tokens by type
        for (type, typeTokens) in tokensByType.sorted(by: { $0.key < $1.key }) {
            print("\n  📊 \(type.uppercased())")
            
            // Sort by weight
            let sortedTokens = typeTokens.sorted { $0.weight > $1.weight }
            for token in sortedTokens {
                var tokenInfo = "    • \(token.name)"
                
                if showWeights {
                    tokenInfo += " (weight: \(String(format: "%.2f", token.weight)))"
                }
                
                if showSources, let source = getSourceDescription(for: token) {
                    tokenInfo += " - \(source)"
                }
                
                print(tokenInfo)
            }
        }
        
        // Count tokens by planetary source
        var sourceCount: [String: Int] = [:]
        for token in tokens {
            if let source = token.planetarySource {
                sourceCount[source, default: 0] += 1
            }
        }
        
        if !sourceCount.isEmpty {
            print("\n  🪐 PLANETARY INFLUENCE:")
            for (source, count) in sourceCount.sorted(by: { $0.value > $1.value }) {
                print("    • \(source): \(count) tokens")
            }
        }
        
        // Count tokens by house
        var houseCount: [Int: Int] = [:]
        for token in tokens where token.houseSource != nil {
            if let house = token.houseSource {
                houseCount[house, default: 0] += 1
            }
        }
        
        if !houseCount.isEmpty {
            print("\n  🏠 HOUSE INFLUENCE:")
            for (house, count) in houseCount.sorted(by: { $0.key < $1.key }) {
                print("    • House \(house): \(count) tokens")
            }
        }
        
        print("")
    }
    
    /// Log decision points in the paragraph assembly
    static func logDecisionPoint(description: String, options: [String],
                                selectedOption: String, reason: String) {
        guard level.rawValue >= LogLevel.verbose.rawValue else { return }
        
        print("\n🔀 DECISION POINT: \(description)")
        print("  Options:")
        for (index, option) in options.enumerated() {
            let marker = option == selectedOption ? "✓" : " "
            print("  \(marker) [\(index + 1)] \(option)")
        }
        print("  Selected: \"\(selectedOption)\"")
        print("  Reason: \(reason)")
        print("")
    }
    
    // MARK: - Helper Methods
    
    /// Get a formatted description of a token's source
    private static func getSourceDescription(for token: StyleToken) -> String? {
        var sources: [String] = []
        
        if let planet = token.planetarySource {
            sources.append(planet)
        }
        
        if let sign = token.signSource {
            sources.append(sign)
        }
        
        if let house = token.houseSource {
            sources.append("House \(house)")
        }
        
        if let aspect = token.aspectSource {
            sources.append(aspect)
        }
        
        return sources.isEmpty ? nil : sources.joined(separator: ", ")
    }
    
    /// Log theme selection process
    static func logThemeSelection(tokens: [StyleToken], selectedTheme: String,
                                 scoredThemes: [(name: String, score: Double)]) {
        guard level.rawValue >= LogLevel.detailed.rawValue else { return }
        
        print("\n🎨 THEME SELECTION")
        print("  Selected Theme: \(selectedTheme)")
        
        if !scoredThemes.isEmpty {
            print("\n  Theme Scores:")
            for (index, theme) in scoredThemes.enumerated() {
                let marker = theme.name == selectedTheme ? "✓" : " "
                print("  \(marker) [\(index + 1)] \(theme.name): \(String(format: "%.2f", theme.score))")
            }
        }
        
        // Log top tokens that influenced the theme
        let topTokens = tokens.sorted(by: { $0.weight > $1.weight }).prefix(5)
        if !topTokens.isEmpty {
            print("\n  Top Influencing Tokens:")
            for token in topTokens {
                var tokenInfo = "    • \(token.name)"
                
                if showWeights {
                    tokenInfo += " (weight: \(String(format: "%.2f", token.weight)))"
                }
                
                if showSources, let source = getSourceDescription(for: token) {
                    tokenInfo += " - \(source)"
                }
                
                print(tokenInfo)
            }
        }
        
        print("")
    }
}
