//
//  AstronomicalCalculations.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation
import CoreLocation

class AstronomicalCalculations {
    // Calculate Local Sidereal Time
    static func calculateLocalSiderealTime(jd: Double, longitude: Double) -> Double {
        // Calculate T - centuries since J2000.0
        let t = (jd - 2451545.0) / 36525.0
        
        // Calculate Greenwich Sidereal Time (GST)
        var theta = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
                   0.000387933 * t * t - t * t * t / 38710000.0
        
        // Normalize to 0-360 range
        theta = AstronomicalUtils.normalizeAngle(theta)
        
        // Convert GST to Local Sidereal Time by adding the longitude
        let lst = theta + longitude
        
        return AstronomicalUtils.normalizeAngle(lst)
    }
    
    // Calculate ascendant (rising sign)
    static func calculateAscendant(lst: Double, latitude: Double) -> Double {
        // Convert degrees to radians for trigonometric functions
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        let lstRad = AstronomicalUtils.degreesToRadians(lst)
        
        // Formula for calculating the ascendant
        let tanAsc = -cos(lstRad) / (sin(lstRad) * cos(latRad) - tan(0.0) * sin(latRad))
        var ascRad = atan(tanAsc)
        
        // Convert back to degrees
        var asc = AstronomicalUtils.radiansToDegrees(ascRad)
        
        // Adjust quadrant
        if cos(lstRad) > 0 {
            asc += 180.0
        }
        
        return AstronomicalUtils.normalizeAngle(asc)
    }
    
    // Calculate Midheaven (MC)
    static func calculateMidheaven(lst: Double) -> Double {
        // The Midheaven is the point where the ecliptic crosses the local meridian
        // In simple terms, it's approximately the LST converted to ecliptic longitude
        return AstronomicalUtils.normalizeAngle(lst)
    }
    
    // Convert equatorial to ecliptic coordinates
    static func equatorialToEcliptic(rightAscension: Double, declination: Double, obliquity: Double) -> (longitude: Double, latitude: Double) {
        let raRad = AstronomicalUtils.degreesToRadians(rightAscension)
        let declRad = AstronomicalUtils.degreesToRadians(declination)
        let oblRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        let sinLat = sin(declRad) * cos(oblRad) - cos(declRad) * sin(oblRad) * sin(raRad)
        let lat = AstronomicalUtils.radiansToDegrees(asin(sinLat))
        
        let y = sin(raRad) * cos(oblRad) + tan(declRad) * sin(oblRad)
        let x = cos(raRad)
        var lon = AstronomicalUtils.radiansToDegrees(atan2(y, x))
        
        lon = AstronomicalUtils.normalizeAngle(lon)
        
        return (lon, lat)
    }
    
    // Convert ecliptic to equatorial coordinates
    static func eclipticToEquatorial(longitude: Double, latitude: Double, obliquity: Double) -> (rightAscension: Double, declination: Double) {
        let lonRad = AstronomicalUtils.degreesToRadians(longitude)
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        let oblRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        let sinDec = sin(latRad) * cos(oblRad) + cos(latRad) * sin(oblRad) * sin(lonRad)
        let dec = AstronomicalUtils.radiansToDegrees(asin(sinDec))
        
        let y = sin(lonRad) * cos(oblRad) - tan(latRad) * sin(oblRad)
        let x = cos(lonRad)
        var ra = AstronomicalUtils.radiansToDegrees(atan2(y, x))
        
        ra = AstronomicalUtils.normalizeAngle(ra)
        
        return (ra, dec)
    }
}
