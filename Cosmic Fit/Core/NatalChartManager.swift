//
//  NatalChartManager.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 06/05/2025.
//

import Foundation
import CoreLocation

class NatalChartManager {
    // MARK: - Properties
    private var birthDate: Date?
    private var birthLocation: CLLocation?
    private var timeZone: TimeZone?
    
    // MARK: - Singleton
    static let shared = NatalChartManager()
    private init() {}
    
    // MARK: - Public Methods
    /// Calculate a natal chart based on the provided birth information
    /// - Parameters:
    ///   - date: Date of birth
    ///   - latitude: Birth location latitude
    ///   - longitude: Birth location longitude
    ///   - timeZone: Time zone of birth location
    /// - Returns: Formatted natal chart data
    func calculateNatalChart(date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> [String: Any] {
        self.birthDate = date
        self.birthLocation = CLLocation(latitude: latitude, longitude: longitude)
        self.timeZone = timeZone
        
        // Calculate the natal chart
        let chart = NatalChartCalculator.calculateNatalChart(
            birthDate: date,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone
        )
        
        // Format the chart data for display
        let formattedChart = NatalChartCalculator.formatNatalChart(chart)
        
        return formattedChart
    }
    
    /// Calculate a progressed chart based on birth information
    /// - Parameters:
    ///   - date: Date of birth
    ///   - latitude: Birth location latitude
    ///   - longitude: Birth location longitude
    ///   - timeZone: Time zone of birth location
    /// - Returns: Formatted progressed chart data
    func calculateProgressedChart(date: Date,
                                  latitude: Double,
                                  longitude: Double,
                                  timeZone: TimeZone) -> [String: Any] {
        
        // Calculate current age
        let targetAge = NatalChartCalculator.calculateCurrentAge(from: date)
        
        // Calculate the progressed chart
        let chart = NatalChartCalculator.calculateProgressedChart(
            birthDate: date,
            targetAge: targetAge,
            latitude: latitude,
            longitude: longitude,
            timeZone: timeZone,
            progressAnglesMethod: .solarArc
        )
        
        // Format the chart data for display
        let formattedChart = NatalChartCalculator.formatNatalChart(chart)
        
        return formattedChart
    }
    
    /// Generate interpretations for a natal chart
    /// - Parameter chart: The calculated natal chart
    /// - Returns: Dictionary of interpretations for different chart elements
    func interpretNatalChart(chart: NatalChartCalculator.NatalChart) -> [String: String] {
        return AstrologicalInterpreter.interpretNatalChart(chart)
    }
    
    /// Save the current natal chart to local storage
    /// - Parameter name: Name to identify the saved chart
    /// - Returns: Boolean indicating success
    func saveNatalChart(name: String) -> Bool {
        guard let birthDate = birthDate,
              let birthLocation = birthLocation,
              let timeZone = timeZone else {
            return false
        }
        
        let savedChart = SavedChart(
            name: name,
            birthDate: birthDate,
            latitude: birthLocation.coordinate.latitude,
            longitude: birthLocation.coordinate.longitude,
            timeZoneIdentifier: timeZone.identifier
        )
        
        return SavedChartStorage.shared.saveChart(savedChart)
    }
    
    /// Load a saved natal chart
    /// - Parameter name: Name of the saved chart
    /// - Returns: Formatted natal chart data if available
    func loadNatalChart(name: String) -> [String: Any]? {
        guard let savedChart = SavedChartStorage.shared.loadChart(name: name) else {
            return nil
        }
        
        guard let timeZone = TimeZone(identifier: savedChart.timeZoneIdentifier) else {
            return nil
        }
        
        return calculateNatalChart(
            date: savedChart.birthDate,
            latitude: savedChart.latitude,
            longitude: savedChart.longitude,
            timeZone: timeZone
        )
    }
    
    /// Get a list of all saved natal charts
    /// - Returns: Array of saved chart names
    func getSavedChartNames() -> [String] {
        return SavedChartStorage.shared.getAllChartNames()
    }
    
    /// Delete a saved natal chart
    /// - Parameter name: Name of the chart to delete
    /// - Returns: Boolean indicating success
    func deleteNatalChart(name: String) -> Bool {
        return SavedChartStorage.shared.deleteChart(name: name)
    }
    
    /// Calculate typed transit aspects (PREFERRED - no dictionary conversion)
    /// - Parameter natalChart: The base natal chart
    /// - Returns: Array of typed TransitAspect structs
    func calculateTypedTransits(natalChart: NatalChartCalculator.NatalChart) -> [NatalChartCalculator.TransitAspect] {
        return NatalChartCalculator.calculateTransits(natalChart: natalChart)
    }
    
    /// Calculate a transit chart (current planetary positions relative to natal chart)
    /// - Parameter natalChart: The base natal chart
    /// - Returns: Transit chart data (DEPRECATED - use calculateTypedTransits instead)
    func calculateTransitChart(natalChart: NatalChartCalculator.NatalChart) -> [String: Any] {
        var transitData: [String: Any] = [:]
        
        // Calculate transit aspects
        let transitAspects = NatalChartCalculator.calculateTransits(natalChart: natalChart)
        let formattedAspects = NatalChartCalculator.formatTransitAspects(transitAspects)
        
        // Group aspects by category
        let groupedAspects = NatalChartCalculator.groupTransitAspectsByCategory(formattedAspects)
        
        // Add to transit data
        transitData["aspects"] = formattedAspects
        transitData["groupedAspects"] = groupedAspects
        
        // Get current date for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        transitData["date"] = dateFormatter.string(from: Date())
        
        return transitData
    }
    
    /*
     /// Calculate a transit chart (current planetary positions relative to natal chart)
     /// - Parameter natalChart: The base natal chart
     /// - Returns: Transit chart data
     func calculateTransitChart(natalChart: NatalChartCalculator.NatalChart) -> [String: Any] {
     // Calculate current planetary positions
     let currentDate = Date()
     let currentJulianDay = JulianDateCalculator.calculateJulianDate(from: currentDate)
     
     // This is a simplified implementation that would need to be expanded
     // with actual transit calculations
     var transitData: [String: Any] = [:]
     
     // Calculate current positions of planets
     let sunPosition = AstronomicalCalculator.calculateSunPosition(julianDay: currentJulianDay)
     let sunLongitude = sunPosition.longitude
     let (sunSign, sunPos) = CoordinateTransformations.decimalDegreesToZodiac(sunLongitude)
     
     let moonPosition = AstronomicalCalculator.calculateMoonPosition(julianDay: currentJulianDay)
     let moonLongitude = moonPosition.longitude
     let (moonSign, moonPos) = CoordinateTransformations.decimalDegreesToZodiac(moonLongitude)
     
     let mercuryPosition = VSOP87Parser.calculateGeocentricCoordinates(planet: .mercury, julianDay: currentJulianDay)
     let mercuryLongitude = CoordinateTransformations.radiansToDegrees(mercuryPosition.longitude)
     let (mercurySign, mercuryPos) = CoordinateTransformations.decimalDegreesToZodiac(mercuryLongitude)
     
     // Add current planet positions to transit data
     transitData["Sun"] = [
     "longitude": sunLongitude,
     "formattedPosition": "\(sunPos) \(CoordinateTransformations.getZodiacSignName(sign: sunSign))",
     "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: sunSign),
     "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: sunSign)
     ]
     
     transitData["Moon"] = [
     "longitude": moonLongitude,
     "formattedPosition": "\(moonPos) \(CoordinateTransformations.getZodiacSignName(sign: moonSign))",
     "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: moonSign),
     "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: moonSign)
     ]
     
     transitData["Mercury"] = [
     "longitude": mercuryLongitude,
     "formattedPosition": "\(mercuryPos) \(CoordinateTransformations.getZodiacSignName(sign: mercurySign))",
     "zodiacSign": CoordinateTransformations.getZodiacSignName(sign: mercurySign),
     "zodiacSymbol": CoordinateTransformations.getZodiacSignSymbol(sign: mercurySign)
     ]
     
     return transitData
     }
     */
}

// MARK: - Saved Chart Models
struct SavedChart: Codable {
    let name: String
    let birthDate: Date
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
}

// MARK: - Saved Chart Storage
class SavedChartStorage {
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let chartKeysKey = "NatalChartKeys"
    
    // MARK: - Singleton
    static let shared = SavedChartStorage()
    private init() {}
    
    // MARK: - Public Methods
    func saveChart(_ chart: SavedChart) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(chart)
            
            userDefaults.set(data, forKey: "Chart_\(chart.name)")
            
            // Update list of chart keys
            var chartKeys = userDefaults.stringArray(forKey: chartKeysKey) ?? []
            if !chartKeys.contains(chart.name) {
                chartKeys.append(chart.name)
                userDefaults.set(chartKeys, forKey: chartKeysKey)
            }
            
            return true
        } catch {
            print("Error saving chart: \(error)")
            return false
        }
    }
    
    func loadChart(name: String) -> SavedChart? {
        guard let data = userDefaults.data(forKey: "Chart_\(name)") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let chart = try decoder.decode(SavedChart.self, from: data)
            return chart
        } catch {
            print("Error loading chart: \(error)")
            return nil
        }
    }
    
    func deleteChart(name: String) -> Bool {
        userDefaults.removeObject(forKey: "Chart_\(name)")
        
        var chartKeys = userDefaults.stringArray(forKey: chartKeysKey) ?? []
        chartKeys.removeAll { $0 == name }
        userDefaults.set(chartKeys, forKey: chartKeysKey)
        
        return true
    }
    
    func getAllChartNames() -> [String] {
        return userDefaults.stringArray(forKey: chartKeysKey) ?? []
    }
}
