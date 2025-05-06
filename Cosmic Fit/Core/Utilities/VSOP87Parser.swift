//
//  VSOP87Parser.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

class VSOP87Parser {
    // Dictionary to cache parsed coefficient data
    static var coefficientCache: [String: [[VSOP87Term]]] = [:]
    
    /// Parse VSOP87 data from file and convert to VSOP87Term array
    static func parseCoefficients(for planet: String, coordinate: String) -> [[VSOP87Term]]? {
        // Check if we already have this data cached
        let key = "\(planet)_\(coordinate)"
        if let cachedData = coefficientCache[key] {
            return cachedData
        }
        
        // Construct filename based on planet and coordinate
        // Typical format: "VSOP87D.mer" for Mercury
        let filename = "VSOP87D.\(planet)"
        
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: nil),
              let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("Failed to load VSOP87 data file: \(filename)")
            return nil
        }
        
        // Parse the file contents
        let parsedData = parseVSOP87FileContents(fileContents, coordinate: coordinate)
        
        // Cache the parsed data
        coefficientCache[key] = parsedData
        
        return parsedData
    }
    
    /// Parse the contents of a VSOP87 file for a specific coordinate (L, B, or R)
    private static func parseVSOP87FileContents(_ contents: String, coordinate: String) -> [[VSOP87Term]] {
        var result: [[VSOP87Term]] = []
        var currentSeriesTerms: [VSOP87Term] = []
        var currentPower = -1
        var isReadingCorrectCoordinate = false
        
        // Split into lines
        let lines = contents.components(separatedBy: .newlines)
        
        for line in lines {
            // Skip empty lines
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            
            // Check for header lines indicating the coordinate and power
            if line.contains("VSOP87") {
                // If starts with "VSOP87", this is a header line
                
                // Check if this section is for the coordinate we want (L, B, or R)
                if line.contains(" \(coordinate) ") || line.contains("\(coordinate)/") {
                    isReadingCorrectCoordinate = true
                    
                    // Extract the power (check for patterns like "T**0", "T**1", etc.)
                    if let powerRange = line.range(of: "T\\*\\*([0-9])", options: .regularExpression) {
                        let powerString = line[powerRange].dropFirst(3) // Remove "T**"
                        if let power = Int(powerString) {
                            // If we were reading terms for a previous power, add them to the result
                            if currentPower >= 0 && !currentSeriesTerms.isEmpty {
                                result.append(currentSeriesTerms)
                                currentSeriesTerms = []
                            }
                            currentPower = power
                        }
                    }
                } else {
                    isReadingCorrectCoordinate = false
                }
                continue
            }
            
            // If we're not in the correct coordinate section, skip
            if !isReadingCorrectCoordinate || currentPower < 0 {
                continue
            }
            
            // Parse data line - expected format is numeric values separated by whitespace
            let components = line.components(separatedBy: .whitespaces)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            // VSOP87 typically has 3 values per term: A, B, C
            if components.count >= 3,
               let a = Double(components[0]),
               let b = Double(components[1]),
               let c = Double(components[2]) {
                let term = VSOP87Term(a: a, b: b, c: c)
                currentSeriesTerms.append(term)
            }
        }
        
        // Add the last series if needed
        if !currentSeriesTerms.isEmpty {
            result.append(currentSeriesTerms)
        }
        
        return result
    }
    
    /// Initialize the parser by preloading key planet data
    static func initialize() {
        // Preload data for all planets
        let planets = ["mer", "ven", "ear", "mar", "jup", "sat", "ura", "nep"]
        let coordinates = ["L", "B", "R"]
        
        for planet in planets {
            for coordinate in coordinates {
                _ = parseCoefficients(for: planet, coordinate: coordinate)
            }
        }
    }
}
