//
//  VSOP87DataManager.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation

class VSOP87DataManager {
    static let shared = VSOP87DataManager()
    
    private init() {
        loadData()
    }
    
    /// Load all VSOP87 data from files
    private func loadData() {
        // Load planet data
        loadPlanetData(planet: "mer", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "ven", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "ear", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "mar", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "jup", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "sat", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "ura", coordinates: ["L", "B", "R"])
        loadPlanetData(planet: "nep", coordinates: ["L", "B", "R"])
    }
    
    /// Load data for a specific planet
    private func loadPlanetData(planet: String, coordinates: [String]) {
        print("Loading VSOP87 data for \(planet)...")
        
        for coordinate in coordinates {
            if let terms = VSOP87Parser.parseCoefficients(for: planet, coordinate: coordinate) {
                print("  Successfully loaded \(planet) \(coordinate) data: \(terms.count) series")
            } else {
                print("  Failed to load \(planet) \(coordinate) data!")
            }
        }
    }
}
