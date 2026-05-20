import Foundation

public struct PresetProfile: Codable {
    public let id: String
    public let label: String
    public let birthDateUTC: String
    public let latitude: Double
    public let longitude: Double
    public let timeZoneId: String
    public let elementDominance: String

    public var displayName: String {
        let hash = DisplayNameGenerator.profileHash(
            dateISO: birthDateUTC, latitude: latitude, longitude: longitude,
            timeZoneId: timeZoneId, unknownTime: false
        )
        return DisplayNameGenerator.name(forProfileHash: hash)
    }

    public var birthInput: BirthInput {
        let datePart = String(birthDateUTC.prefix(10))
        let timePart = birthDateUTC.count >= 16 ? String(birthDateUTC.dropFirst(11).prefix(5)) : "00:00"
        return BirthInput(
            birthDate: datePart,
            birthTime: timePart,
            dateISO: nil,
            unknownTime: false,
            latitude: latitude,
            longitude: longitude,
            timeZoneId: timeZoneId,
            locationLabel: label
        )
    }
}

public enum PresetCatalog {

    private static var _presets: [PresetProfile]?

    public static func loadPresets(from url: URL? = nil) -> [PresetProfile] {
        if let cached = _presets { return cached }

        let resolvedURL = url ?? ResourcePaths.presetsURL
        guard FileManager.default.fileExists(atPath: resolvedURL.path),
              let data = try? Data(contentsOf: resolvedURL),
              let decoded = try? JSONDecoder().decode([PresetProfile].self, from: data) else {
            print("[PresetCatalog] presets.json not found or invalid at \(resolvedURL.path)")
            return []
        }
        _presets = decoded
        return decoded
    }
}
