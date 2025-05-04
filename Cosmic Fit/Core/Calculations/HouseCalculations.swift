//
//  HouseCalculations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation

class HouseCalculations {
    // Calculate houses using the Placidus system
    static func calculatePlacidusHouses(ascendant: Double, midheaven: Double) -> [House] {
        var houses: [House] = []
        
        // House 1 (Ascendant)
        houses.append(House(number: 1, cusp: ascendant))
        
        // House 10 (Midheaven)
        houses.append(House(number: 10, cusp: midheaven))
        
        // Calculate intermediate house cusps
        // For a complete implementation, calculate houses 2, 3, 11, 12 using Placidus formulas
        // Then calculate opposite houses (4, 5, 6, 7, 8, 9) by adding 180° to their opposites
        
        // Simplified implementation for demo purposes:
        // House 2 (30° from Ascendant in simple equal house system)
        houses.append(House(number: 2, cusp: AstronomicalUtils.normalizeAngle(ascendant + 30)))
        
        // House 3
        houses.append(House(number: 3, cusp: AstronomicalUtils.normalizeAngle(ascendant + 60)))
        
        // House 4 (Imum Coeli - opposite to Midheaven)
        houses.append(House(number: 4, cusp: AstronomicalUtils.normalizeAngle(midheaven + 180)))
        
        // Houses 5-9, 11-12 (simplified)
        houses.append(House(number: 5, cusp: AstronomicalUtils.normalizeAngle(ascendant + 120)))
        houses.append(House(number: 6, cusp: AstronomicalUtils.normalizeAngle(ascendant + 150)))
        houses.append(House(number: 7, cusp: AstronomicalUtils.normalizeAngle(ascendant + 180)))
        houses.append(House(number: 8, cusp: AstronomicalUtils.normalizeAngle(ascendant + 210)))
        houses.append(House(number: 9, cusp: AstronomicalUtils.normalizeAngle(ascendant + 240)))
        houses.append(House(number: 11, cusp: AstronomicalUtils.normalizeAngle(midheaven + 30)))
        houses.append(House(number: 12, cusp: AstronomicalUtils.normalizeAngle(midheaven + 60)))
        
        // Sort houses by number
        return houses.sorted { $0.number < $1.number }
    }
    
    // Find which house a planet falls into
    static func findHouse(position: Double, houses: [House]) -> Int {
        for i in 0..<houses.count {
            let currentHouse = houses[i]
            let nextHouse = houses[(i + 1) % houses.count]
            
            var start = currentHouse.cusp
            var end = nextHouse.cusp
            
            // Handle case where house spans 0° Aries
            if end < start {
                end += 360.0
            }
            
            var normalizedPosition = position
            if normalizedPosition < start {
                normalizedPosition += 360.0
            }
            
            if normalizedPosition >= start && normalizedPosition < end {
                return currentHouse.number
            }
        }
        
        // Default to house 1 if not found (shouldn't happen)
        return 1
    }
}
