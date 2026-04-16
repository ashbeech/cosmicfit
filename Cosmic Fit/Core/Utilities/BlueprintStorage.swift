import Foundation

final class BlueprintStorage {
    static let shared = BlueprintStorage()
    private init() {}

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("cosmic_fit_blueprint.json")
    }

    func save(_ blueprint: CosmicBlueprint) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(blueprint)
            try data.write(to: fileURL, options: .atomic)
            print("✅ Blueprint saved to Documents")
        } catch {
            print("❌ Blueprint save failed: \(error.localizedDescription)")
        }
    }

    func load() -> CosmicBlueprint? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CosmicBlueprint.self, from: data)
        } catch {
            print("❌ Blueprint load failed: \(error.localizedDescription)")
            return nil
        }
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ Blueprint deleted from Documents")
    }
}
