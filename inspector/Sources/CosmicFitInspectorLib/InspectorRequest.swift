import Foundation

public struct InspectorRequest: Codable {
    public let preset: String?
    public let birth: BirthInput
    public let targetDate: String
    public let options: InspectOptions?
}

public struct BirthInput: Codable {
    /// yyyy-MM-dd calendar date in the birth timezone (preferred).
    public let birthDate: String?
    /// HH:mm in the birth timezone; ignored when `unknownTime` is true.
    public let birthTime: String?
    /// Legacy combined instant; used only when `birthDate` is absent.
    public let dateISO: String?
    public let unknownTime: Bool
    public let latitude: Double
    public let longitude: Double
    public let timeZoneId: String
    public let locationLabel: String
}

public struct InspectOptions: Codable {
    public let composeBlueprint: Bool?
    public let includeProgressed: Bool?
    /// When set, matches `userProfile.id` in the app (otherwise uses chartId).
    public let profileId: String?
    /// Clears tarot recency + variant rotation for the resolved profile hash before computing.
    public let resetTarotHistory: Bool?
}
