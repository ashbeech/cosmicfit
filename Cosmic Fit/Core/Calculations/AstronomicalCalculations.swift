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
        // Calculate Greenwich Sidereal Time (GST)
        let theta = AstronomicalUtils.greenwichSiderealTime(jd: jd)
        
        // Calculate nutation
        let nutation = AstronomicalUtils.nutation(jd: jd)
        
        // Mean obliquity of the ecliptic
        let epsilon = AstronomicalUtils.obliquityOfEcliptic(jd: jd)
        
        // True obliquity
        let trueEpsilon = epsilon + nutation.obliquity
        
        // Apparent sidereal time at Greenwich
        let apparentTheta = theta + nutation.longitude * cos(AstronomicalUtils.degreesToRadians(trueEpsilon)) / 15.0
        
        // Convert GST to Local Sidereal Time by adding the longitude (in degrees)
        // East longitude is positive, West is negative
        let lst = apparentTheta + longitude / 15.0
        
        return AstronomicalUtils.normalizeAngle(lst * 15.0) // Convert from hours to degrees
    }
    
    // Calculate ascendant (rising sign)
    static func calculateAscendant(lst: Double, latitude: Double) -> Double {
        // Convert to radians for trigonometric functions
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        let lstRad = AstronomicalUtils.degreesToRadians(lst)
        
        // Get obliquity of the ecliptic
        let jd = 2451545.0 // J2000.0 as default, will be more accurate if real JD is used
        let obliquityRad = AstronomicalUtils.degreesToRadians(AstronomicalUtils.obliquityOfEcliptic(jd: jd))
        
        // Formula for calculating the ascendant
        // tan(ascendant) = -cos(lst) / (sin(lst) * cos(obliquity) - tan(latitude) * sin(obliquity))
        let numerator = -cos(lstRad)
        let denominator = sin(lstRad) * cos(obliquityRad) - tan(latRad) * sin(obliquityRad)
        
        var ascRad = atan2(numerator, denominator)
        
        // Convert back to degrees
        var asc = AstronomicalUtils.radiansToDegrees(ascRad)
        
        // Normalize to 0-360 range
        asc = AstronomicalUtils.normalizeAngle(asc)
        
        return asc
    }
    
    // Calculate Midheaven (MC)
    static func calculateMidheaven(lst: Double) -> Double {
        // The Midheaven is the point where the ecliptic crosses the local meridian
        // Get obliquity of the ecliptic
        let jd = 2451545.0 // J2000.0 as default, will be more accurate if real JD is used
        let obliquity = AstronomicalUtils.obliquityOfEcliptic(jd: jd)
        let obliquityRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        // Convert LST to radians
        let lstRad = AstronomicalUtils.degreesToRadians(lst)
        
        // Calculate Midheaven using formula from Astronomical Algorithms by Jean Meeus
        let tanMC = tan(lstRad) / cos(obliquityRad)
        let mcRad = atan(tanMC)
        
        // Convert to degrees
        var mc = AstronomicalUtils.radiansToDegrees(mcRad)
        
        // Adjust quadrant
        if sin(lstRad) < 0 {
            mc += 180.0
        }
        
        // Normalize to 0-360 range
        mc = AstronomicalUtils.normalizeAngle(mc)
        
        return mc
    }
    
    // Convert equatorial to ecliptic coordinates
    static func equatorialToEcliptic(rightAscension: Double, declination: Double, obliquity: Double) -> (longitude: Double, latitude: Double) {
        let raRad = AstronomicalUtils.degreesToRadians(rightAscension)
        let declRad = AstronomicalUtils.degreesToRadians(declination)
        let oblRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        // Calculate ecliptic longitude
        let y = sin(raRad) * cos(oblRad) + tan(declRad) * sin(oblRad)
        let x = cos(raRad)
        let longRad = atan2(y, x)
        
        // Calculate ecliptic latitude
        let latRad = asin(sin(declRad) * cos(oblRad) - cos(declRad) * sin(oblRad) * sin(raRad))
        
        // Convert to degrees
        let longitude = AstronomicalUtils.radiansToDegrees(longRad)
        let latitude = AstronomicalUtils.radiansToDegrees(latRad)
        
        return (AstronomicalUtils.normalizeAngle(longitude), latitude)
    }
    
    // Convert ecliptic to equatorial coordinates
    static func eclipticToEquatorial(longitude: Double, latitude: Double, obliquity: Double) -> (rightAscension: Double, declination: Double) {
        let lonRad = AstronomicalUtils.degreesToRadians(longitude)
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        let oblRad = AstronomicalUtils.degreesToRadians(obliquity)
        
        // Calculate right ascension
        let y = sin(lonRad) * cos(oblRad) - tan(latRad) * sin(oblRad)
        let x = cos(lonRad)
        let raRad = atan2(y, x)
        
        // Calculate declination
        let sinDec = sin(latRad) * cos(oblRad) + cos(latRad) * sin(oblRad) * sin(lonRad)
        let declRad = asin(sinDec)
        
        // Convert to degrees
        let ra = AstronomicalUtils.radiansToDegrees(raRad)
        let decl = AstronomicalUtils.radiansToDegrees(declRad)
        
        return (AstronomicalUtils.normalizeAngle(ra), decl)
    }
    
    // Calculate parallax correction
    static func parallaxCorrection(longitude: Double, latitude: Double, distance: Double,
                                  geoLat: Double, geoLong: Double, height: Double, siderealTime: Double) -> (longitude: Double, latitude: Double) {
        // Convert to radians
        let lonRad = AstronomicalUtils.degreesToRadians(longitude)
        let latRad = AstronomicalUtils.degreesToRadians(latitude)
        let geoLatRad = AstronomicalUtils.degreesToRadians(geoLat)
        let lstRad = AstronomicalUtils.degreesToRadians(siderealTime)
        
        // Earth radius in AU (astronomical units)
        let earthRadius = 6378.137 / 149597870.7 // km to AU
        
        // Geocentric coordinates to rectangular coordinates
        let x = distance * cos(latRad) * cos(lonRad)
        let y = distance * cos(latRad) * sin(lonRad)
        let z = distance * sin(latRad)
        
        // Observer's position
        let rho = earthRadius * cos(geoLatRad)
        let obsX = rho * cos(lstRad)
        let obsY = rho * sin(lstRad)
        let obsZ = earthRadius * sin(geoLatRad)
        
        // Topocentric rectangular coordinates
        let topoX = x - obsX
        let topoY = y - obsY
        let topoZ = z - obsZ
        
        // Convert back to spherical coordinates
        let topoDistance = sqrt(topoX * topoX + topoY * topoY + topoZ * topoZ)
        let topoLongRad = atan2(topoY, topoX)
        let topoLatRad = asin(topoZ / topoDistance)
        
        // Convert to degrees
        let topoLong = AstronomicalUtils.radiansToDegrees(topoLongRad)
        let topoLat = AstronomicalUtils.radiansToDegrees(topoLatRad)
        
        return (AstronomicalUtils.normalizeAngle(topoLong), topoLat)
    }
}
