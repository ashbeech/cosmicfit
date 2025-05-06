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
        var houses: [House] = []
        
        // Calculate Local Sidereal Time
        let lst = AstronomicalCalculations.calculateLocalSiderealTime(jd: jd, longitude: longitude)
        
        // Calculate Ascendant
        let asc = AstronomicalCalculations.calculateAscendant(lst: lst, latitude: latitude)
        houses.append(House(number: 1, cusp: asc))
        
        // Calculate Midheaven (MC)
        let mc = AstronomicalCalculations.calculateMidheaven(lst: lst)
        houses.append(House(number: 10, cusp: mc))
        
        // Calculate obliquity of the ecliptic
        let obliquity = AstronomicalUtils.obliquityOfEcliptic(jd: jd)
        let obliquityRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        // Convert latitude to radians
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        
        // Calculate house cusps using Placidus system
        // For houses 11 and 12
        for i in 1...2 {
            // Semi-arc calculation
            let ra = i * 30.0
            let raRad = AstronomicalUtils.degreesToRadians(ra)
            
            // Calculate intermediate value
            let a = atan2(tan(obliquityRad) * sin(raRad), cos(raRad))
            let d = atan2(sin(a) * sin(obliquityRad), cos(a))
            
            // Calculate semi-diurnal arc
            let H = acos(-tan(latRad) * tan(d))
            
            // Calculate house cusps
            let R = (3.0 - Double(i)) / 3.0
            let cusP = 2.0 * atan2(tan((H * R + .pi / 2.0) / 2.0) * cos(latRad), cos(d))
            let ra1 = AstronomicalUtils.normalizeAngle(AstronomicalUtils.radiansToDegrees(cusP + raRad))
            
            // Convert to ecliptic longitude
            let ecliptic = AstronomicalCalculations.equatorialToEcliptic(rightAscension: ra1, declination: 0, obliquity: obliquity)
            
            houses.append(House(number: 9 + i, cusp: AstronomicalUtils.normalizeAngle(ecliptic.longitude)))
        }
        
        // For houses 2 and 3
        for i in 1...2 {
            // Semi-arc calculation
            let ra = 180.0 + i * 30.0
            let raRad = AstronomicalUtils.degreesToRadians(ra)
            
            // Calculate intermediate value
            let a = atan2(tan(obliquityRad) * sin(raRad), cos(raRad))
            let d = atan2(sin(a) * sin(obliquityRad), cos(a))
            
            // Calculate semi-diurnal arc
            let H = acos(-tan(latRad) * tan(d))
            
            // Calculate house cusps
            let R = (3.0 - Double(i)) / 3.0
            let cusP = 2.0 * atan2(tan((H * R + .pi / 2.0) / 2.0) * cos(latRad), cos(d))
            let ra1 = AstronomicalUtils.normalizeAngle(AstronomicalUtils.radiansToDegrees(cusP + raRad))
            
            // Convert to ecliptic longitude
            let ecliptic = AstronomicalCalculations.equatorialToEcliptic(rightAscension: ra1, declination: 0, obliquity: obliquity)
            
            houses.append(House(number: i + 1, cusp: AstronomicalUtils.normalizeAngle(ecliptic.longitude)))
        }
        
        // Calculate remaining houses as opposites
        houses.append(House(number: 4, cusp: AstronomicalUtils.normalizeAngle(mc + 180.0)))
        houses.append(House(number: 5, cusp: AstronomicalUtils.normalizeAngle(houses[8].cusp + 180.0)))
        houses.append(House(number: 6, cusp: AstronomicalUtils.normalizeAngle(houses[7].cusp + 180.0)))
        houses.append(House(number: 7, cusp: AstronomicalUtils.normalizeAngle(asc + 180.0)))
        houses.append(House(number: 8, cusp: AstronomicalUtils.normalizeAngle(houses[1].cusp + 180.0)))
        houses.append(House(number: 9, cusp: AstronomicalUtils.normalizeAngle(houses[2].cusp + 180.0)))
        
        // Sort houses by number
        return houses.sorted { $0.number < $1.number }
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
        var houses: [House] = []
        
        // Calculate Local Sidereal Time
        let lst = AstronomicalCalculations.calculateLocalSiderealTime(jd: jd, longitude: longitude)
        
        // Calculate Ascendant and Midheaven
        let asc = AstronomicalCalculations.calculateAscendant(lst: lst, latitude: latitude)
        let mc = AstronomicalCalculations.calculateMidheaven(lst: lst)
        
        // Add Ascendant, Midheaven and their opposites
        houses.append(House(number: 1, cusp: asc))
        houses.append(House(number: 10, cusp: mc))
        houses.append(House(number: 7, cusp: AstronomicalUtils.normalizeAngle(asc + 180.0)))
        houses.append(House(number: 4, cusp: AstronomicalUtils.normalizeAngle(mc + 180.0)))
        
        // Calculate obliquity of the ecliptic
        let obliquity = AstronomicalUtils.obliquityOfEcliptic(jd: jd)
        
        // Convert to radians
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        let obliquityRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        // Convert MC to right ascension
        let mcRA = AstronomicalUtils.degreesToRadians(lst * 15.0)
        
        // Calculate house cusps for houses 11, 12, 2, 3
        for i in [11, 12, 2, 3] {
            // Calculate the house position in the diurnal arc
            let housePos = (Double(i) - 1.0) / 3.0
            let angle = asin(sin(latRad) * sin(mcRA + .pi/2.0 * (housePos - 1.0)))
            
            // Calculate the ecliptic longitude
            let lon = AstronomicalUtils.radiansToDegrees(atan2(
                tan(angle) / cos(obliquityRad),
                cos(mcRA + .pi/2.0 * (housePos - 1.0))
            ))
            
            houses.append(House(number: i, cusp: AstronomicalUtils.normalizeAngle(lon)))
        }
        
        // Calculate opposite houses
        houses.append(House(number: 5, cusp: AstronomicalUtils.normalizeAngle(houses[8].cusp + 180.0)))
        houses.append(House(number: 6, cusp: AstronomicalUtils.normalizeAngle(houses[7].cusp + 180.0)))
        houses.append(House(number: 8, cusp: AstronomicalUtils.normalizeAngle(houses[1].cusp + 180.0)))
        houses.append(House(number: 9, cusp: AstronomicalUtils.normalizeAngle(houses[2].cusp + 180.0)))
        
        // Sort houses by number
        return houses.sorted { $0.number < $1.number }
    }
    
    // Find which house a planet falls into
    static func findHouse(position: Double, houses: [House]) -> Int {
        for i in 0..<houses.count {
            let currentHouse = houses[i]
            let nextHouse = houses[(i + 1) % houses.count]
            
            var startCusp = currentHouse.cusp
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
