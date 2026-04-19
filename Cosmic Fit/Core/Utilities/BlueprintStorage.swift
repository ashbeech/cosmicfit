import Foundation

// MARK: - Convenience for blueprint-to-UI fallback logic

extension String {
    /// Returns `self` if non-empty, otherwise `nil`. Lets callers use
    /// `blueprint.field.nonEmpty ?? placeholder` without a separate check.
    var nonEmpty: String? { isEmpty ? nil : self }
}

extension Array {
    /// Returns `nil` when the array is empty so the `??` fallback pattern
    /// works cleanly: `blueprint.items.nilIfEmpty ?? placeholderItems`.
    var nilIfEmpty: [Element]? { isEmpty ? nil : self }
}

extension Notification.Name {
    /// Posted on the main queue after a `CosmicBlueprint` is successfully
    /// persisted via `BlueprintStorage.shared.save(_:)`. Observers (e.g.
    /// the Style Guide palette path) can use this to refresh from the
    /// latest blueprint without polling.
    static let blueprintDidUpdate = Notification.Name("cosmicFitBlueprintDidUpdate")
}

final class BlueprintStorage {
    static let shared = BlueprintStorage()

    /// Bump this when the PaletteSection (or any persisted model) shape changes
    /// in a way that requires regeneration. On load, if the stored version
    /// doesn't match, the file is deleted and nil is returned.
    static let schemaVersion = 2

    private static let schemaVersionKey = "cosmicFitBlueprintSchemaVersion"

    private init() {
        migrateIfNeeded()
    }

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("cosmic_fit_blueprint.json")
    }

    private func migrateIfNeeded() {
        let stored = UserDefaults.standard.integer(forKey: Self.schemaVersionKey)
        if stored < Self.schemaVersion {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
                print("Blueprint wiped — schema version \(stored) → \(Self.schemaVersion)")
            }
            UserDefaults.standard.set(Self.schemaVersion, forKey: Self.schemaVersionKey)
        }
    }

    func save(_ blueprint: CosmicBlueprint) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(blueprint)
            try data.write(to: fileURL, options: .atomic)
            UserDefaults.standard.set(Self.schemaVersion, forKey: Self.schemaVersionKey)
            print("Blueprint saved to Documents (schema v\(Self.schemaVersion))")
            let post = {
                NotificationCenter.default.post(name: .blueprintDidUpdate, object: nil)
            }
            if Thread.isMainThread { post() } else { DispatchQueue.main.async(execute: post) }
        } catch {
            print("Blueprint save failed: \(error.localizedDescription)")
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
            print("Blueprint load failed: \(error.localizedDescription)")
            return nil
        }
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
        print("Blueprint deleted from Documents")
    }
}
