import Foundation

public struct InspectorRequest: Codable {
    public let preset: String?
    public let birth: BirthInput
    public let targetDate: String
    public let options: InspectOptions?
}

public struct BirthInput: Codable {
    public let dateISO: String
    public let unknownTime: Bool
    public let latitude: Double
    public let longitude: Double
    public let timeZoneId: String
    public let locationLabel: String
}

public struct InspectOptions: Codable {
    public let composeBlueprint: Bool?
    public let includeProgressed: Bool?
}
