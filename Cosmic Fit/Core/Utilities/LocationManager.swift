//
//  LocationManager.swift
//  Cosmic Fit
//
//  Enhanced location manager with persistent device location storage
//  and on-demand access for weather and astronomical calculations
//

import CoreLocation
import Foundation

final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Properties
    private let manager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var lastLocationUpdate: Date?
    
    // Callbacks for one-time requests
    var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var onError: ((Error) -> Void)?
    
    // Callbacks for continuous updates
    private var locationUpdateCallbacks: [(CLLocationCoordinate2D) -> Void] = []
    private var errorCallbacks: [(Error) -> Void] = []
    
    // Configuration
    private let locationUpdateInterval: TimeInterval = 300 // 5 minutes
    private let locationAccuracyThreshold: CLLocationDistance = 100 // meters
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50 // Update when moved 50 meters
        
        // Load cached location if available
        loadCachedLocation()
    }
    
    // MARK: - Public Interface
    
    /// Get the current device location if available
    var deviceLocation: CLLocationCoordinate2D? {
        return currentLocation?.coordinate
    }
    
    /// Get the current device location with additional metadata
    var deviceLocationData: (coordinate: CLLocationCoordinate2D, timestamp: Date, accuracy: CLLocationAccuracy)? {
        guard let location = currentLocation else { return nil }
        return (
            coordinate: location.coordinate,
            timestamp: location.timestamp,
            accuracy: location.horizontalAccuracy
        )
    }
    
    /// Check if we have a reasonably fresh location (within 30 minutes)
    var hasRecentLocation: Bool {
        guard let location = currentLocation,
              let lastUpdate = lastLocationUpdate else { return false }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        let locationAge = Date().timeIntervalSince(location.timestamp)
        
        return timeSinceUpdate < 1800 && locationAge < 1800 && location.horizontalAccuracy < 1000
    }
    
    /// Request location once (legacy method for compatibility)
    func requestOnce() {
        requestLocation { coordinate in
            self.onLocation?(coordinate)
        } onError: { error in
            self.onError?(error)
        }
    }
    
    /// Request location with completion handlers
    func requestLocation(
        onSuccess: @escaping (CLLocationCoordinate2D) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // If we have a recent location, use it immediately
        if hasRecentLocation, let coordinate = deviceLocation {
            print("📍 Using cached device location: \(coordinate.latitude), \(coordinate.longitude)")
            onSuccess(coordinate)
            return
        }
        
        // Store callbacks for when location is received
        self.onLocation = onSuccess
        self.onError = onError
        
        print("📍 Requesting fresh device location...")
        requestLocationPermissionAndUpdate()
    }
    
    /// Start continuous location updates (for apps that need real-time location)
    func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services disabled")
            return
        }
        
        requestLocationPermissionAndUpdate()
        manager.startUpdatingLocation()
        print("📍 Started continuous location updates")
    }
    
    /// Stop continuous location updates
    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        print("📍 Stopped continuous location updates")
    }
    
    /// Add a callback for location updates
    func addLocationUpdateCallback(_ callback: @escaping (CLLocationCoordinate2D) -> Void) {
        locationUpdateCallbacks.append(callback)
    }
    
    /// Add a callback for location errors
    func addErrorCallback(_ callback: @escaping (Error) -> Void) {
        errorCallbacks.append(callback)
    }
    
    /// Force refresh the device location (ignores cache)
    func forceRefreshLocation(
        onSuccess: @escaping (CLLocationCoordinate2D) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        print("📍 Force refreshing device location...")
        
        self.onLocation = onSuccess
        self.onError = onError
        
        requestLocationPermissionAndUpdate()
    }
    
    private func startLocationIfAllowed() {
        guard CLLocationManager.locationServicesEnabled(),
              manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            return
        }
        
        if !locationUpdateCallbacks.isEmpty {
            manager.startUpdatingLocation()
            print("📍 Authorized — starting location updates after permission")
        }
        
        if onLocation != nil {
            manager.requestLocation()
        }
    }
    
    // MARK: - Permission Handling
    private func requestLocationPermissionAndUpdate() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Defer any location start until delegate is triggered
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationIfAllowed()
        case .denied, .restricted:
            let error = NSError(
                domain: "LocationManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location access denied. Please enable location services in Settings."]
            )
            handleLocationError(error)
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: - Caching
    private func cacheLocation(_ location: CLLocation) {
        UserDefaults.standard.set(location.coordinate.latitude, forKey: "CachedLocationLatitude")
        UserDefaults.standard.set(location.coordinate.longitude, forKey: "CachedLocationLongitude")
        UserDefaults.standard.set(location.timestamp, forKey: "CachedLocationTimestamp")
        UserDefaults.standard.set(location.horizontalAccuracy, forKey: "CachedLocationAccuracy")
    }
    
    private func loadCachedLocation() {
        let latitude = UserDefaults.standard.double(forKey: "CachedLocationLatitude")
        let longitude = UserDefaults.standard.double(forKey: "CachedLocationLongitude")
        
        guard latitude != 0 || longitude != 0,
              let timestamp = UserDefaults.standard.object(forKey: "CachedLocationTimestamp") as? Date else {
            return
        }
        
        let accuracy = UserDefaults.standard.double(forKey: "CachedLocationAccuracy")
        
        // Only use cached location if it's less than 24 hours old
        let timeSinceCache = Date().timeIntervalSince(timestamp)
        if timeSinceCache < 86400 { // 24 hours
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let cachedLocation = CLLocation(
                coordinate: coordinate,
                altitude: 0,
                horizontalAccuracy: accuracy,
                verticalAccuracy: -1,
                timestamp: timestamp
            )
            
            self.currentLocation = cachedLocation
            self.lastLocationUpdate = timestamp
            
            print("📍 Loaded cached device location: \(latitude), \(longitude) (age: \(Int(timeSinceCache/60)) minutes)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get a formatted string of the current device location
    func deviceLocationString() -> String? {
        guard let coordinate = deviceLocation else { return nil }
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
    
    /// Check if the device location is suitable for astronomical calculations
    func isLocationSuitableForAstronomy() -> Bool {
        guard let location = currentLocation else { return false }
        
        // Check accuracy (should be better than 1km for astronomy)
        guard location.horizontalAccuracy < 1000 && location.horizontalAccuracy > 0 else {
            return false
        }
        
        // Check age (should be less than 1 hour old)
        let locationAge = Date().timeIntervalSince(location.timestamp)
        return locationAge < 3600
    }
    
    // MARK: - Error Handling
    private func handleLocationError(_ error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        // Call one-time error callback
        onError?(error)
        
        // Call all continuous error callbacks
        errorCallbacks.forEach { $0(error) }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        let locationAge = Date().timeIntervalSince(location.timestamp)
        if locationAge > 60 || location.horizontalAccuracy > 1000 || location.horizontalAccuracy < 0 {
            return
        }
        
        // Check if this is a significant improvement over our current location
        var shouldUpdate = true
        if let currentLocation = self.currentLocation {
            let timeSinceLastUpdate = Date().timeIntervalSince(currentLocation.timestamp)
            let distanceFromLast = location.distance(from: currentLocation)
            
            // Don't update if location hasn't changed much and it's recent
            if timeSinceLastUpdate < locationUpdateInterval &&
               distanceFromLast < locationAccuracyThreshold &&
               location.horizontalAccuracy >= currentLocation.horizontalAccuracy {
                shouldUpdate = false
            }
        }
        
        if shouldUpdate {
            self.currentLocation = location
            self.lastLocationUpdate = Date()
            
            // Cache the location
            cacheLocation(location)
            
            let coordinate = location.coordinate
            
            print("✅ DEVICE LOCATION UPDATE")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📍 Device Location: \(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))")
            print("🎯 Accuracy: ±\(Int(location.horizontalAccuracy))m")
            print("⏰ Timestamp: \(location.timestamp)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // Call one-time location callback
            onLocation?(coordinate)
            
            // Call all continuous location callbacks
            locationUpdateCallbacks.forEach { $0(coordinate) }
            
            // Clear one-time callbacks after use
            onLocation = nil
            onError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        handleLocationError(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 Location authorization changed: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationIfAllowed()
        case .denied, .restricted:
            let error = NSError(
                domain: "LocationManager",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Location access denied or restricted."]
            )
            handleLocationError(error)
            
        case .notDetermined:
            // Don't call requestLocation() yet — wait for the user to decide
            break
            
        @unknown default:
            break
        }
    }
}
