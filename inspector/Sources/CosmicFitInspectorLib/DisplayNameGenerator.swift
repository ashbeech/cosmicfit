import Foundation
import CryptoKit

enum DisplayNameGenerator {

    private static let names: [String] = [
        "Aurora", "Cedar", "Wren", "Indigo", "Slate", "Linden",
        "Marlow", "Sable", "Briar", "Juno", "Ash", "Quill",
        "Onyx", "Pax", "Vesper", "Larkin", "Sloan", "Wilder",
        "Echo", "Iris", "Reed", "Magnolia", "Lior", "Soren",
    ]

    /// Deterministic display name from a profile hash string.
    /// Same inputs always yield the same name.
    public static func name(forProfileHash hash: String) -> String {
        let digest = SHA256.hash(data: Data(hash.utf8))
        let bytes = Array(digest)
        let index = (UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 |
                      UInt32(bytes[2]) << 8  | UInt32(bytes[3])) % UInt32(names.count)
        return names[Int(index)]
    }

    /// Builds the canonical profile hash from birth inputs.
    public static func profileHash(dateISO: String, latitude: Double, longitude: Double,
                                    timeZoneId: String, unknownTime: Bool) -> String {
        let lat4 = String(format: "%.4f", latitude)
        let lon4 = String(format: "%.4f", longitude)
        let raw = "\(dateISO)|\(lat4)|\(lon4)|\(timeZoneId)|\(unknownTime)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
