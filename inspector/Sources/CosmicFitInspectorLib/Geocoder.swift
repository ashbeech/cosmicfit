import Foundation
import CoreLocation
import MapKit

public struct GeocoderResult: Encodable {
    public let label: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneId: String
}

public enum InspectorGeocoder {

    /// Uses MKLocalSearch to match the iOS app's MapKit-based location resolution
    /// (MKLocalSearchCompleter → MKLocalSearch). CLGeocoder returns different
    /// centroids for the same city name.
    public static func search(query: String) async -> [GeocoderResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.prefix(5).compactMap { mapItem -> GeocoderResult? in
                let coord = mapItem.placemark.coordinate
                guard CLLocationCoordinate2DIsValid(coord) else { return nil }
                let tz = mapItem.timeZone ?? mapItem.placemark.timeZone ?? TimeZone(secondsFromGMT: 0)!
                let locality = mapItem.placemark.locality
                let admin = mapItem.placemark.administrativeArea
                let country = mapItem.placemark.country
                var parts: [String] = []
                if let locality { parts.append(locality) }
                if let admin, admin != locality { parts.append(admin) }
                if let country { parts.append(country) }
                var label = parts.joined(separator: ", ")
                if label.isEmpty { label = mapItem.name ?? query }
                return GeocoderResult(
                    label: label,
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    timeZoneId: tz.identifier
                )
            }
        } catch {
            print("[Geocoder] MKLocalSearch failed: \(error.localizedDescription)")
            return []
        }
    }
}
