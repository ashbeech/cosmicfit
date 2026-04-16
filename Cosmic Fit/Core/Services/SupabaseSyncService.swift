import Foundation
import Supabase

final class SupabaseSyncService {
    static let shared = SupabaseSyncService()
    private init() {}

    private var isSyncing = false

    // MARK: - Push

    func syncProfileToSupabase(_ profile: UserProfile) async throws {
        guard CosmicFitAuthService.shared.isAuthenticated,
              let userId = CosmicFitAuthService.shared.currentUserId else { return }

        struct ProfilePayload: Encodable {
            let id: String
            let first_name: String
            let birth_date: String
            let birth_location: String
            let latitude: Double
            let longitude: Double
            let timezone_identifier: String
        }

        let payload = ProfilePayload(
            id: userId,
            first_name: profile.firstName,
            birth_date: ISO8601DateFormatter().string(from: profile.birthDate),
            birth_location: profile.birthLocation,
            latitude: profile.latitude,
            longitude: profile.longitude,
            timezone_identifier: profile.timeZoneIdentifier
        )

        try await supabase
            .from("profiles")
            .upsert(payload, onConflict: "id")
            .execute()

        print("✅ Profile synced to Supabase")
    }

    func syncBlueprintToSupabase(_ blueprint: CosmicBlueprint) async throws {
        guard CosmicFitAuthService.shared.isAuthenticated,
              let userId = CosmicFitAuthService.shared.currentUserId else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let blueprintData = try encoder.encode(blueprint)
        guard let blueprintJSON = String(data: blueprintData, encoding: .utf8) else { return }

        let payload: [String: String] = [
            "user_id": userId,
            "blueprint_json": blueprintJSON,
            "generated_at": ISO8601DateFormatter().string(from: blueprint.generatedAt),
            "engine_version": blueprint.engineVersion
        ]

        try await supabase
            .from("user_blueprints")
            .upsert(payload, onConflict: "user_id")
            .execute()

        print("✅ Blueprint synced to Supabase")
    }

    func syncPreferencesToSupabase() async throws {
        guard CosmicFitAuthService.shared.isAuthenticated,
              let userId = CosmicFitAuthService.shared.currentUserId else { return }

        let payload: [String: String] = [
            "id": userId
        ]

        try await supabase
            .from("user_preferences")
            .upsert(payload, onConflict: "id")
            .execute()
    }

    // MARK: - Pull

    func pullProfileFromSupabase() async throws -> UserProfile? {
        guard CosmicFitAuthService.shared.isAuthenticated,
              let userId = CosmicFitAuthService.shared.currentUserId else { return nil }

        struct RemoteProfile: Decodable {
            let first_name: String?
            let birth_date: String?
            let birth_location: String?
            let latitude: Double?
            let longitude: Double?
            let timezone_identifier: String?
        }

        let response: RemoteProfile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        guard let firstName = response.first_name,
              let birthDateStr = response.birth_date,
              let birthDate = ISO8601DateFormatter().date(from: birthDateStr),
              let location = response.birth_location,
              let lat = response.latitude,
              let lon = response.longitude,
              let tzId = response.timezone_identifier else {
            return nil
        }

        return UserProfile(
            id: userId,
            firstName: firstName,
            birthDate: birthDate,
            birthLocation: location,
            latitude: lat,
            longitude: lon,
            timeZoneIdentifier: tzId,
            createdAt: Date(),
            lastModified: Date()
        )
    }

    func pullBlueprintFromSupabase() async throws -> CosmicBlueprint? {
        guard CosmicFitAuthService.shared.isAuthenticated,
              let userId = CosmicFitAuthService.shared.currentUserId else { return nil }

        struct RemoteBlueprint: Decodable {
            let blueprint_json: String
        }

        let response: RemoteBlueprint = try await supabase
            .from("user_blueprints")
            .select("blueprint_json")
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = response.blueprint_json.data(using: .utf8) else { return nil }
        return try decoder.decode(CosmicBlueprint.self, from: data)
    }

    // MARK: - Full sync

    func performFullSync() async {
        guard CosmicFitAuthService.shared.isAuthenticated else { return }
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        print("🔄 Starting full sync...")

        // Push local profile
        if let profile = UserProfileStorage.shared.loadUserProfile() {
            do {
                try await syncProfileToSupabase(profile)
            } catch {
                print("⚠️ Profile sync failed: \(error.localizedDescription)")
            }
        }

        // Push local blueprint
        if let blueprint = BlueprintStorage.shared.load() {
            do {
                try await syncBlueprintToSupabase(blueprint)
            } catch {
                print("⚠️ Blueprint sync failed: \(error.localizedDescription)")
            }
        }

        print("✅ Full sync complete")
    }
}
