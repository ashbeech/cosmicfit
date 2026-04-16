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

// MARK: - CosmicFitAuthService

final class CosmicFitAuthService {
    static let shared = CosmicFitAuthService()

    private let defaults = UserDefaults.standard
    private let lastUserIdKey = "CosmicFitLastUserId"
    private let appInstalledKey = "CosmicFitAppInstalled"

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUserId: String?
    private(set) var currentUserEmail: String?

    private init() {
        handleFreshInstallIfNeeded()
    }

    // MARK: - Fresh install detection

    /// iOS Keychain persists across app reinstalls. On a fresh install
    /// we must clear any stale session tokens left from a previous install.
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

    func sendOTP(email: String) async throws {
        do {
            let _: SendOTPResponse = try await supabase.functions.invoke(
                "send-otp",
                options: .init(body: ["email": email])
            )
            print("✅ sendOTP succeeded")
        } catch {
            print("❌ sendOTP failed: \(error)")
            print("❌ sendOTP error type: \(type(of: error))")
            throw error
        }
    }

    func verifyOTP(email: String, code: String) async throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response: VerifyOTPResponse = try await supabase.functions.invoke(
            "verify-otp",
            options: .init(body: ["email": email, "code": code]),
            decoder: decoder
        )

        try await supabase.auth.setSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )

        await checkSession()
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
            defaults.removeObject(forKey: lastUserIdKey)
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
        UserProfileStorage.shared.deleteUserProfile()
        BlueprintStorage.shared.delete()
    }
}
