import Foundation
import CoreLocation

public struct GeocoderResult: Encodable {
    public let label: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneId: String
}

public enum InspectorGeocoder {

    public static func search(query: String) async -> [GeocoderResult] {
        await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(query) { placemarks, error in
                guard let placemarks = placemarks, error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let results = placemarks.compactMap { pm -> GeocoderResult? in
                    guard let loc = pm.location else { return nil }
                    let tz = pm.timeZone ?? TimeZone(secondsFromGMT: 0)!
                    let parts = [pm.locality, pm.administrativeArea, pm.country].compactMap { $0 }
                    let label = parts.joined(separator: ", ")
                    return GeocoderResult(
                        label: label.isEmpty ? query : label,
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude,
                        timeZoneId: tz.identifier
                    )
                }
                continuation.resume(returning: results)
            }
        }
    }
}
