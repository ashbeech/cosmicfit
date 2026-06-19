import Foundation
import Supabase

/// Talks to `redeem-code` and `check-comp-access` edge functions.
/// Mirrors the URLSession pattern in CosmicFitAuthService.
@MainActor
final class PromoCodeService {
    static let shared = PromoCodeService()
    private init() {}

    enum PromoError: LocalizedError {
        case notConfigured
        case invalidCode
        case codeExpired
        case networkError(Error)
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Server not configured. Please try again later."
            case .invalidCode:   return "Invalid or exhausted code."
            case .codeExpired:   return "This code has expired."
            case .networkError:  return "Network error. Check your connection and try again."
            case .serverError(let msg): return msg
            }
        }
    }

    /// Redeem a promo code. On success, persists the grant locally and
    /// triggers an entitlement refresh so UI updates immediately.
    func redeem(code: String) async throws -> CompAccessGrant {
        guard SupabaseConfig.isConfigured else { throw PromoError.notConfigured }

        var body: [String: Any] = [
            "code": code,
            "clientInstallId": ClientInstallIdentity.id,
        ]

        #if DEBUG
        body["isDevBuild"] = true
        #endif

        let data = try await invokeEdgeFunction("redeem-code", body: body)
        let response = try parseRedeemResponse(data)
        CompAccessStorage.save(response)
        await EntitlementManager.shared.checkEntitlement()
        return response
    }

    /// Removes comp access for this install on the server and locally, then refreshes entitlements.
    func revokeCompAccess() async throws {
        guard SupabaseConfig.isConfigured else {
            CompAccessStorage.clear()
            await EntitlementManager.shared.checkEntitlement()
            return
        }

        let body: [String: Any] = [
            "clientInstallId": ClientInstallIdentity.id,
        ]

        _ = try await invokeEdgeFunction("revoke-comp-access", body: body)
        CompAccessStorage.clear()
        await EntitlementManager.shared.checkEntitlement()
    }

    /// Attempt to restore comp access from the server (e.g. after reinstall).
    /// Silent — does not throw on "no access found", only on hard errors.
    func restoreCompAccessIfNeeded() async {
        guard CompAccessStorage.load()?.isValid != true else { return }
        guard SupabaseConfig.isConfigured else { return }

        let body: [String: Any] = [
            "clientInstallId": ClientInstallIdentity.id,
        ]

        do {
            let data = try await invokeEdgeFunction("check-comp-access", body: body)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["hasCompAccess"] as? Bool == true,
                  let grantObj = json["grant"] as? [String: Any] else {
                return
            }
            if let grant = parseGrantObject(grantObj), grant.isValid {
                CompAccessStorage.save(grant)
                await EntitlementManager.shared.checkEntitlement()
            }
        } catch {
            print("[PromoCode] Silent restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Edge function invocation (matches CosmicFitAuthService pattern)

    private func invokeEdgeFunction(_ name: String, body: [String: Any]) async throws -> Data {
        guard let baseURL = SupabaseConfig.url,
              let apiKey = SupabaseConfig.publishableKey else {
            throw PromoError.notConfigured
        }

        let url = baseURL.appendingPathComponent("functions/v1/\(name)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        if let session = try? await supabase.auth.session, !session.isExpired {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PromoError.serverError("Invalid response")
        }

        if httpResponse.statusCode >= 400 {
            if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = errJson["error"] as? [String: Any],
               let errCode = errObj["code"] as? String {
                switch errCode {
                case "INVALID_CODE": throw PromoError.invalidCode
                case "CODE_EXPIRED": throw PromoError.codeExpired
                case "RATE_LIMITED": throw PromoError.serverError("Too many attempts. Please wait a moment.")
                default:             throw PromoError.serverError(errObj["message"] as? String ?? "Unknown error")
                }
            }
            throw PromoError.serverError("Server error (\(httpResponse.statusCode))")
        }

        return data
    }

    // MARK: - Response parsing

    private func parseRedeemResponse(_ data: Data) throws -> CompAccessGrant {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["ok"] as? Bool == true,
              let grantObj = json["grant"] as? [String: Any],
              let grant = parseGrantObject(grantObj) else {
            throw PromoError.serverError("Unexpected response format")
        }
        return grant
    }

    private func parseGrantObject(_ obj: [String: Any]) -> CompAccessGrant? {
        guard let code = obj["code"] as? String,
              let grantedAtStr = obj["grantedAt"] as? String else {
            return nil
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let grantedAt = formatter.date(from: grantedAtStr) ?? Date()
        var expiresAt: Date?
        if let expiresStr = obj["expiresAt"] as? String {
            expiresAt = formatter.date(from: expiresStr)
        }
        return CompAccessGrant(code: code, grantedAt: grantedAt, expiresAt: expiresAt)
    }
}
