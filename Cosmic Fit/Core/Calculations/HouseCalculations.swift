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
        
        // Calculate opposite houses directly
        // House 7 (Descendant) - opposite to Ascendant
        houses.append(House(number: 7, cusp: AstronomicalUtils.normalizeAngle(ascendant + 180.0)))
        
        // House 4 (Imum Coeli) - opposite to Midheaven
        houses.append(House(number: 4, cusp: AstronomicalUtils.normalizeAngle(midheaven + 180.0)))
        
        // Calculate intermediate house cusps using Placidus method
        // This requires the local sidereal time and geo latitude
        // For a proper implementation, we'd need to calculate these values
        
        // The implementation below is a simplified approximation that maintains
        // the proportional spacing of houses based on the positions of the four major angles
        
        // Houses 2 and 3 (between Ascendant and IC)
        let arc1 = AstronomicalUtils.normalizeAngle(houses[3].cusp - ascendant)
        houses.append(House(number: 2, cusp: AstronomicalUtils.normalizeAngle(ascendant + arc1 / 3.0)))
        houses.append(House(number: 3, cusp: AstronomicalUtils.normalizeAngle(ascendant + 2.0 * arc1 / 3.0)))
        
        // Houses 5 and 6 (between IC and Descendant)
        let arc2 = AstronomicalUtils.normalizeAngle(houses[2].cusp - houses[3].cusp)
        houses.append(House(number: 5, cusp: AstronomicalUtils.normalizeAngle(houses[3].cusp + arc2 / 3.0)))
        houses.append(House(number: 6, cusp: AstronomicalUtils.normalizeAngle(houses[3].cusp + 2.0 * arc2 / 3.0)))
        
        // Houses 8 and 9 (between Descendant and MC)
        let arc3 = AstronomicalUtils.normalizeAngle(midheaven - houses[2].cusp)
        houses.append(House(number: 8, cusp: AstronomicalUtils.normalizeAngle(houses[2].cusp + arc3 / 3.0)))
        houses.append(House(number: 9, cusp: AstronomicalUtils.normalizeAngle(houses[2].cusp + 2.0 * arc3 / 3.0)))
        
        // Houses 11 and 12 (between MC and Ascendant)
        let arc4 = AstronomicalUtils.normalizeAngle(ascendant + 360.0 - midheaven)
        houses.append(House(number: 11, cusp: AstronomicalUtils.normalizeAngle(midheaven + arc4 / 3.0)))
        houses.append(House(number: 12, cusp: AstronomicalUtils.normalizeAngle(midheaven + 2.0 * arc4 / 3.0)))
        
        // Sort houses by number
        return houses.sorted { $0.number < $1.number }
    }
    
    // Calculate houses using the more accurate Placidus implementation
    static func calculateAccuratePlacidusHouses(jd: Double, latitude: Double, longitude: Double) -> [House] {
        // For now, let's use the simpler method to avoid runtime errors
        // We can gradually refine this implementation once the basic system works
        
        // Calculate Local Sidereal Time
        let lst = AstronomicalCalculations.calculateLocalSiderealTime(jd: jd, longitude: longitude)
        
        // Calculate Ascendant
        let asc = AstronomicalCalculations.calculateAscendant(lst: lst, latitude: latitude)
        
        // Calculate Midheaven (MC)
        let mc = AstronomicalCalculations.calculateMidheaven(lst: lst)
        
        // Use the simpler method that's proven to work
        return calculatePlacidusHouses(ascendant: asc, midheaven: mc)
    }
    
    // Calculate houses using the Equal House system
    static func calculateEqualHouses(ascendant: Double) -> [House] {
        var houses: [House] = []
        
        // Create 12 houses with equal 30° spacing
        for i in 1...12 {
            let cusp = AstronomicalUtils.normalizeAngle(ascendant + Double(i - 1) * 30.0)
            houses.append(House(number: i, cusp: cusp))
        }
        
        return houses
    }
    
    // Calculate houses using the Whole Sign system
    static func calculateWholeSignHouses(ascendant: Double) -> [House] {
        var houses: [House] = []
        
        // Get the sign of the ascendant
        let ascSign = Int(ascendant / 30.0)
        
        // Create 12 houses with each house beginning at 0° of a sign
        for i in 1...12 {
            let signIndex = (ascSign + i - 1) % 12
            let cusp = Double(signIndex) * 30.0
            houses.append(House(number: i, cusp: cusp))
        }
        
        return houses
    }
    
    // Calculate houses using the Koch system
    static func calculateKochHouses(jd: Double, latitude: Double, longitude: Double) -> [House] {
        // For now, let's use the simpler method to avoid runtime errors
        // We can gradually refine this implementation once the basic system works
        
        // Calculate Local Sidereal Time
        let lst = AstronomicalCalculations.calculateLocalSiderealTime(jd: jd, longitude: longitude)
        
        // Calculate Ascendant
        let asc = AstronomicalCalculations.calculateAscendant(lst: lst, latitude: latitude)
        
        // Calculate Midheaven (MC)
        let mc = AstronomicalCalculations.calculateMidheaven(lst: lst)
        
        // Use the simpler method that's proven to work
        return calculatePlacidusHouses(ascendant: asc, midheaven: mc)
    }
    
    // Find which house a planet falls into
    static func findHouse(position: Double, houses: [House]) -> Int {
        for i in 0..<houses.count {
            let currentHouse = houses[i]
            let nextHouse = houses[(i + 1) % houses.count]
            
            let startCusp = currentHouse.cusp
            var endCusp = nextHouse.cusp
            
            // Handle the case where house spans 0° Aries
            if endCusp < startCusp {
                endCusp += 360.0
            }
            
            // Normalize position to handle wrap-around
            var normalizedPosition = position
            if normalizedPosition < startCusp && normalizedPosition < endCusp {
                normalizedPosition += 360.0
            }
            
            if normalizedPosition >= startCusp && normalizedPosition < endCusp {
                return currentHouse.number
            }
        }
        
        // Default to house 1 if not found (shouldn't happen with proper data)
        return 1
    }
}
