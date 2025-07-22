//
//  DebugLogger.swift
//  Cosmic Fit
//
//  Unified debug logging system that eliminates duplication
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
                    sourceInfo += " (\(planet)"
                    if let aspect = token.aspectSource {
                        sourceInfo += " - \(aspect)"
                    }
                    sourceInfo += ")"
                }
                print("    • \(token.name): \(String(format: "%.2f", token.weight))\(sourceInfo)")
            }
        }
    }
    
    /// Log paragraph assembly details
    static func paragraphAssembly(sectionName: String, paragraphText: String, tokens: [StyleToken]) {
        guard enableParagraphAssemblyLogging && currentLogLevel.priority <= LogLevel.debug.priority else { return }
        
        print("\n📝 PARAGRAPH ASSEMBLY: \(sectionName.uppercased()) 📝")
        print("  ✨ Generated Text Length: \(paragraphText.count) characters")
        print("  🪙 Tokens Used: \(tokens.count)")
        
        // Show top influencing tokens
        let topTokens = tokens.sorted { $0.weight > $1.weight }.prefix(5)
        print("  🎯 Top Influencing Tokens:")
        for (index, token) in topTokens.enumerated() {
            print("    \(index + 1). \(token.name) (weight: \(String(format: "%.2f", token.weight)))")
        }
        
        // Show first 100 characters of generated text
        let preview = paragraphText.count > 100 ?
            String(paragraphText.prefix(100)) + "..." :
            paragraphText
        print("  💬 Text Preview: \"\(preview)\"")
    }
    
    /// Log section generation
    static func sectionGeneration(_ sectionName: String, tokensUsed: [StyleToken], result: String) {
        guard enableParagraphAssemblyLogging && currentLogLevel.priority <= LogLevel.debug.priority else { return }
        
        print("\n🔧 SECTION: \(sectionName.uppercased()) 🔧")
        print("  📊 Tokens Analyzed: \(tokensUsed.count)")
        print("  📏 Output Length: \(result.count) characters")
        
        // Log key tokens that influenced this section
        let significantTokens = tokensUsed.filter { $0.weight > 1.5 }.sorted { $0.weight > $1.weight }
        if !significantTokens.isEmpty {
            print("  🎯 Significant Tokens:")
            for token in significantTokens.prefix(3) {
                print("    • \(token.name): \(String(format: "%.2f", token.weight))")
            }
        }
    }
    
    /// Log sentence generation with context
    static func sentenceGeneration(_ sentence: String, tokens: [StyleToken], section: String, context: String) {
        guard enableParagraphAssemblyLogging && currentLogLevel.priority <= LogLevel.verbose.priority else { return }
        
        print("  🗣️ [\(section)] \(context): \"\(sentence)\"")
        
        // Log tokens that influenced this specific sentence
        let relevantTokens = tokens.filter { sentence.lowercased().contains($0.name.lowercased()) }
        if !relevantTokens.isEmpty {
            print("      📍 Influenced by: \(relevantTokens.map { $0.name }.joined(separator: ", "))")
        }
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
    
    // MARK: - Interpretation Engine Specific Logging
    
    /// Log blueprint generation start
    static func blueprintGenerationStart(_ tokens: [StyleToken]) {
        guard currentLogLevel.priority <= LogLevel.info.priority else { return }
        
        print("\n🧩 GENERATING COSMIC FIT BLUEPRINT 🧩")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if enableTokenDebugLogging {
            tokenSet("BLUEPRINT TOKENS", tokens)
            logTokenAnalysisForBlueprint(tokens)
        }
    }
    
    /// Log daily vibe generation start
    static func dailyVibeGenerationStart(natal: NatalChartCalculator.NatalChart, progressed: NatalChartCalculator.NatalChart, transits: [[String: Any]]) {
        guard currentLogLevel.priority <= LogLevel.info.priority else { return }
        
        print("\n☀️ GENERATING DAILY COSMIC VIBE ☀️")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if enableTokenDebugLogging {
            print("📊 CHART DATA ANALYSIS:")
            print("Natal Sun Sign: \(CoordinateTransformations.getZodiacSignName(sign: natal.planets.first(where: { $0.name == "Sun" })?.zodiacSign ?? 0))")
            print("Natal Moon Sign: \(CoordinateTransformations.getZodiacSignName(sign: natal.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0))")
            print("Progressed Moon Sign: \(CoordinateTransformations.getZodiacSignName(sign: progressed.planets.first(where: { $0.name == "Moon" })?.zodiacSign ?? 0))")
            print("Natal Ascendant Sign: \(CoordinateTransformations.getZodiacSignName(sign: CoordinateTransformations.decimalDegreesToZodiac(natal.ascendant).sign))")
            print("Total transit aspects: \(transits.count)")
        }
    }
    
    /// Log token analysis for blueprint
    private static func logTokenAnalysisForBlueprint(_ tokens: [StyleToken]) {
        guard enableTokenDebugLogging else { return }
        
        info("Analyzing token set for Blueprint generation")
        
        // Count tokens by source
        var planetaryCounts: [String: Int] = [:]
        for token in tokens {
            if let planet = token.planetarySource {
                planetaryCounts[planet, default: 0] += 1
            }
        }
        
        // Log planetary distributions
        debug("Planetary token distribution:")
        for (planet, count) in planetaryCounts.sorted(by: { $0.value > $1.value }) {
            debug("  • \(planet): \(count) tokens")
        }
        
        // Log top tokens by weight
        let topTokensByWeight = tokens.sorted { $0.weight > $1.weight }.prefix(10)
        debug("Top 10 tokens by weight:")
        for (index, token) in topTokensByWeight.enumerated() {
            debug("  \(index+1). \(token.name): \(String(format: "%.2f", token.weight))")
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
