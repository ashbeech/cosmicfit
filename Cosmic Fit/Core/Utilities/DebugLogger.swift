//
//  DebugLogger.swift
//  Cosmic Fit
//
//  Enhanced debug logging system for interpretation generation
//

import Foundation

/// Comprehensive debug logging system for the Cosmic Fit interpretation engine
struct DebugLogger {
    
    // MARK: - Log Levels
    
    enum LogLevel: String, CaseIterable {
        case verbose = "VERBOSE"
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case none = "NONE"
        
        var priority: Int {
            switch self {
            case .verbose: return 0
            case .debug: return 1
            case .info: return 2
            case .warning: return 3
            case .error: return 4
            case .none: return 5
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Current minimum log level
    static var currentLogLevel: LogLevel = .info
    
    /// Whether to enable detailed paragraph assembly logging
    static var enableParagraphAssemblyLogging: Bool = false
    
    /// Whether to enable token debugging
    static var enableTokenDebugLogging: Bool = false
    
    // MARK: - Basic Logging Methods
    
    /// Log a verbose message
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .verbose, message: message, file: file, function: function, line: line)
    }
    
    /// Log a debug message
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    /// Log an info message
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// Log an error message
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    // MARK: - Specialized Logging Methods
    
    /// Log a token set with detailed analysis
    static func tokenSet(_ title: String, _ tokens: [StyleToken]) {
        guard enableTokenDebugLogging && currentLogLevel.priority <= LogLevel.debug.priority else { return }
        
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
        for (source, count) in sourceCounts.sorted(by: { $0.key < $1.key }) {
            print("    • \(source): \(count) tokens")
        }
    }
    
    /// Log paragraph assembly details
    static func paragraphAssembly(sectionName: String, paragraphText: String, tokens: [StyleToken]) {
        guard enableParagraphAssemblyLogging && currentLogLevel.priority <= LogLevel.debug.priority else { return }
        
        print("\n📝 PARAGRAPH ASSEMBLY: \(sectionName.uppercased()) 📝")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Show the generated text
        print("📄 Generated Text:")
        let lines = paragraphText.components(separatedBy: ". ")
        for (index, line) in lines.enumerated() {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("  \(index + 1). \(line.trimmingCharacters(in: .whitespacesAndNewlines))\(line.hasSuffix(".") ? "" : ".")")
            }
        }
        
        // Show influential tokens
        print("\n🎯 Influential Tokens:")
        let sortedTokens = tokens.sorted { $0.weight > $1.weight }.prefix(5)
        for (index, token) in sortedTokens.enumerated() {
            var sourceInfo = ""
            if let planet = token.planetarySource {
                sourceInfo += " from \(planet)"
            }
            if let sign = token.signSource {
                sourceInfo += " in \(sign)"
            }
            if let house = token.houseSource {
                sourceInfo += " (House \(house))"
            }
            
            print("  \(index + 1). \(token.name): \(String(format: "%.2f", token.weight))\(sourceInfo)")
        }
        
        // Text analysis
        print("\n📊 Text Analysis:")
        print("  • Character count: \(paragraphText.count)")
        print("  • Word count: \(paragraphText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)")
        print("  • Sentence count: \(paragraphText.components(separatedBy: ". ").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count)")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// Log individual sentence generation with influencing tokens
    static func sentence(text: String, influencedBy tokens: [StyleToken], inSection section: String) {
        guard enableParagraphAssemblyLogging && currentLogLevel.priority <= LogLevel.verbose.priority else { return }
        
        print("🔤 SENTENCE (\(section)):")
        print("  Text: \"\(text.trimmingCharacters(in: .whitespacesAndNewlines))\"")
        
        if !tokens.isEmpty {
            print("  Influenced by:")
            for token in tokens.prefix(3) {
                var sourceInfo = ""
                if let planet = token.planetarySource {
                    sourceInfo += " [\(planet)]"
                }
                if let sign = token.signSource {
                    sourceInfo += " [\(sign)]"
                }
                print("    • \(token.name) (\(String(format: "%.2f", token.weight)))\(sourceInfo)")
            }
        }
        print("")
    }
    
    /// Log chart calculation details
    static func chartCalculation(_ chartName: String, details: [String: Any]) {
        guard currentLogLevel.priority <= LogLevel.debug.priority else { return }
        
        print("\n⭐ CHART CALCULATION: \(chartName.uppercased()) ⭐")
        for (key, value) in details.sorted(by: { $0.key < $1.key }) {
            print("  • \(key): \(value)")
        }
        print("")
    }
    
    /// Log time measurements
    static func timeMeasurement(_ operationName: String, timeElapsed: TimeInterval) {
        guard currentLogLevel.priority <= LogLevel.debug.priority else { return }
        
        let formattedTime = String(format: "%.3f", timeElapsed)
        print("⏱️ TIMING: \(operationName) completed in \(formattedTime)s")
    }
    
    /// Log memory usage information
    static func memoryUsage(_ context: String) {
        guard currentLogLevel.priority <= LogLevel.verbose.priority else { return }
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryMB = Double(info.resident_size) / 1024 / 1024
            print("🧠 MEMORY (\(context)): \(String(format: "%.2f", memoryMB)) MB")
        }
    }
    
    // MARK: - Core Logging Method
    
    /// Core logging method that handles all log output
    private static func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        guard level.priority >= currentLogLevel.priority else { return }
        
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let emoji = levelEmoji(for: level)
        
        // Format: [TIMESTAMP] EMOJI LEVEL [FILE:LINE] MESSAGE
        print("[\(timestamp)] \(emoji) \(level.rawValue) [\(fileName):\(line)] \(message)")
    }
    
    /// Get emoji for log level
    private static func levelEmoji(for level: LogLevel) -> String {
        switch level {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .none: return ""
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
