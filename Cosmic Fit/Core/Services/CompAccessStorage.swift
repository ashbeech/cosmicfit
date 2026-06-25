import Foundation
import Security

/// Cached comp-code grant persisted in Keychain.
struct CompAccessGrant: Codable, Equatable {
    let code: String
    let grantedAt: Date
    let expiresAt: Date?
    /// 1-based slot among limited codes such as FIRST50 (from server `redemptionPosition`).
    let redemptionPosition: Int?

    var isValid: Bool { expiresAt == nil || expiresAt! > Date() }

    var isFirst50Code: Bool {
        let normalized = code.uppercased()
        return normalized == "FIRST50" || normalized == "BETATESTER"
    }
}

/// Keychain-backed storage for the local comp access grant.
/// Separate from StoreKit — these two paths are OR'd in EntitlementManager.
enum CompAccessStorage {

    private static let service = "com.cosmicfit.comp-access"
    private static let account = "current_grant"

    static func load() -> CompAccessGrant? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return try? JSONDecoder.cosmicFitISO.decode(CompAccessGrant.self, from: data)
    }

    static func save(_ grant: CompAccessGrant) {
        guard let data = try? JSONEncoder.cosmicFitISO.encode(grant) else { return }
        let query: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrService as String:    service,
            kSecAttrAccount as String:    account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let attrs: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - ISO8601 JSON Coding helpers

private extension JSONDecoder {
    static let cosmicFitISO: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

private extension JSONEncoder {
    static let cosmicFitISO: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
