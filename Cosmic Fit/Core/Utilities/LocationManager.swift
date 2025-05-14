//
//  LocationManager.swift
//  Cosmic Fit
//
//  Lightweight one‑shot location grabber
//

import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var onError: ((Error) -> Void)?
    
    func requestOnce() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        if let loc = locs.first { onLocation?(loc.coordinate) }
    }
    
    // Replace the existing locationManager(_:didFailWithError:) with this
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
        onError?(error)
    }
}
