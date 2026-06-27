import Foundation
import Supabase

// MARK: - Notification Names

extension Notification.Name {
    static let cosmicFitAuthStateChanged = Notification.Name("cosmicFitAuthStateChanged")
    static let cosmicFitDeepLinkReceived = Notification.Name("cosmicFitDeepLinkReceived")
}

// MARK: - Response types for edge functions

private struct SendOTPResponse: Decodable {
    let success: Bool
}

private struct VerifyOTPResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
}

private struct SignUpWithProfileResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
}

private struct EdgeErrorBody: Decodable {
    let error: EdgeErrorDetail
}

private struct EdgeErrorDetail: Decodable {
    let code: String
    let message: String
}

// MARK: - Auth Errors

enum CosmicFitAuthError: Error {
    case emailAlreadyRegistered
    case networkError(Error)
    case serverError(String)
}

// MARK: - CosmicFitAuthService

final class CosmicFitAuthService {
    static let shared = CosmicFitAuthService()

    private let defaults = UserDefaults.standard
    private let lastUserIdKey = "CosmicFitLastUserId"
    private let appInstalledKey = "CosmicFitAppInstalled"
    private let accountEmailKey = "CosmicFitAccountEmail"

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUserId: String?
    private(set) var currentUserEmail: String?

    private init() {
        handleFreshInstallIfNeeded()
    }

    // MARK: - Fresh install detection

    private func handleFreshInstallIfNeeded() {
        if !defaults.bool(forKey: appInstalledKey) {
            defaults.set(true, forKey: appInstalledKey)
            Task {
                try? await supabase.auth.signOut()
                print("🔑 Fresh install detected — cleared stale Keychain tokens")
            }
        }
    }

    // MARK: - Session

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            applySession(session)
        } catch {
            clearState(clearLocal: false)
        }
    }

    // MARK: - OTP flow

    private func invokeEdgeFunction(_ name: String, body: Data) async throws -> Data {
        guard let baseURL = SupabaseConfig.url,
              let apiKey = SupabaseConfig.publishableKey else {
            throw CosmicFitAuthError.serverError("Supabase not configured")
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

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CosmicFitAuthError.serverError("Invalid response")
        }

        if httpResponse.statusCode >= 400 {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ Edge function \(name) failed: HTTP \(httpResponse.statusCode) — \(errorBody)")
            throw FunctionsError.httpError(code: httpResponse.statusCode, data: data)
        }

        return data
    }

    func sendOTP(email: String) async throws {
        do {
            let body = try JSONEncoder().encode(["email": email])
            let data = try await invokeEdgeFunction("send-otp", body: body)
            let _ = try JSONDecoder().decode(SendOTPResponse.self, from: data)
            print("✅ sendOTP succeeded")
        } catch {
            if case FunctionsError.httpError(let code, let data) = error {
                let body = String(data: data, encoding: .utf8) ?? "nil"
                print("❌ sendOTP failed: HTTP \(code) — \(body)")
            } else {
                print("❌ sendOTP failed: \(error)")
            }
            throw error
        }
    }

    func verifyOTP(email: String, code: String) async throws {
        struct Body: Encodable { let email: String; let code: String }
        let body = try JSONEncoder().encode(Body(email: email, code: code))
        let data = try await invokeEdgeFunction("verify-otp", body: body)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(VerifyOTPResponse.self, from: data)

        try await supabase.auth.setSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        defaults.set(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), forKey: accountEmailKey)
        await checkSession()
    }

    // MARK: - Signup with profile (no OTP)

    func signUpWithProfile(email: String, profile: UserProfile) async throws {
        let normalised = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        struct ProfilePayload: Encodable {
            let first_name: String
            let birth_date: String
            let birth_location: String
            let latitude: Double
            let longitude: Double
            let timezone_identifier: String
            let birth_time_is_unknown: Bool
        }

        struct SignUpBody: Encodable {
            let email: String
            let profile: ProfilePayload
        }

        let body = SignUpBody(
            email: normalised,
            profile: ProfilePayload(
                first_name: profile.firstName,
                birth_date: ISO8601DateFormatter().string(from: profile.birthDate),
                birth_location: profile.birthLocation,
                latitude: profile.latitude,
                longitude: profile.longitude,
                timezone_identifier: profile.timeZoneIdentifier,
                birth_time_is_unknown: profile.birthTimeIsUnknown
            )
        )

        do {
            let bodyData = try JSONEncoder().encode(body)
            let responseData = try await invokeEdgeFunction("signup-with-profile", body: bodyData)
            let response = try decoder.decode(SignUpWithProfileResponse.self, from: responseData)

            try await supabase.auth.setSession(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            defaults.set(normalised, forKey: accountEmailKey)
            await checkSession()
            print("✅ signUpWithProfile succeeded for \(normalised)")
        } catch {
            if let emailExistsError = parseEmailExistsError(error) {
                throw emailExistsError
            }
            print("❌ signUpWithProfile failed: \(error)")
            throw error
        }
    }

    // MARK: - Account email

    var accountEmail: String? {
        defaults.string(forKey: accountEmailKey)
    }

    func clearAccountEmail() {
        defaults.removeObject(forKey: accountEmailKey)
    }

    func clearLastUserId() {
        defaults.removeObject(forKey: lastUserIdKey)
    }

    // MARK: - Account deletion

    func deleteAccount() async throws {
        struct DeleteAccountResponse: Decodable {
            let success: Bool
        }

        let data = try await invokeEdgeFunction("delete-account", body: Data("{}".utf8))
        let response = try JSONDecoder().decode(DeleteAccountResponse.self, from: data)
        guard response.success else {
            throw CosmicFitAuthError.serverError("Account deletion failed")
        }

        try? await supabase.auth.signOut()
        clearState(clearLocal: true)
        clearAccountEmail()
        clearLastUserId()
        UserProfileStorage.shared.clearLocalUserGeneratedContent()
        print("✅ Account deleted")
    }

    // MARK: - Sign out

    func signOut() async throws {
        try await supabase.auth.signOut()
        clearState(clearLocal: true)
    }

    // MARK: - Auth state listener

    func listenForAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session, !session.isExpired {
                        applySession(session)
                    } else {
                        clearState(clearLocal: false)
                    }
                case .signedIn, .tokenRefreshed:
                    await checkSession()
                case .signedOut:
                    clearState(clearLocal: true)
                default:
                    break
                }
            }
        }
    }

    // MARK: - Private

    private func applySession(_ session: Session) {
        let userId = session.user.id.uuidString
        let email = session.user.email
        let previousUserId = defaults.string(forKey: lastUserIdKey)

        if let previousUserId, previousUserId != userId {
            purgeLocalUserData()
        }
        defaults.set(userId, forKey: lastUserIdKey)

        if let email {
            defaults.set(email, forKey: accountEmailKey)
        }

        let update = { [self] in
            self.currentUserId = userId
            self.currentUserEmail = email
            self.isAuthenticated = true
            NotificationCenter.default.post(
                name: .cosmicFitAuthStateChanged,
                object: nil,
                userInfo: ["isAuthenticated": true]
            )
            print("✅ Auth session applied — user: \(userId)")
        }

        if Thread.isMainThread { update() } else { DispatchQueue.main.async(execute: update) }
    }

    private func clearState(clearLocal: Bool) {
        if clearLocal {
            CompAccessStorage.clear()
            Task { @MainActor in await EntitlementManager.shared.checkEntitlement() }
        }

        let update = { [self] in
            self.isAuthenticated = false
            self.currentUserId = nil
            self.currentUserEmail = nil
            NotificationCenter.default.post(
                name: .cosmicFitAuthStateChanged,
                object: nil,
                userInfo: ["isAuthenticated": false]
            )
        }

        if Thread.isMainThread { update() } else { DispatchQueue.main.async(execute: update) }
    }

    private func purgeLocalUserData() {
        print("⚠️ Different user detected — purging local data")
        UserProfileStorage.shared.clearLocalUserGeneratedContent()
        CompAccessStorage.clear()
        Task { @MainActor in await EntitlementManager.shared.checkEntitlement() }
    }

    private func parseEmailExistsError(_ error: Error) -> CosmicFitAuthError? {
        guard let functionsError = error as? FunctionsError else { return nil }
        switch functionsError {
        case .httpError(let code, let data):
            guard code == 409 else { return nil }
            if let body = try? JSONDecoder().decode(EdgeErrorBody.self, from: data),
               body.error.code == "EMAIL_EXISTS" {
                return .emailAlreadyRegistered
            }
            return nil
        default:
            return nil
        }
    }
}
