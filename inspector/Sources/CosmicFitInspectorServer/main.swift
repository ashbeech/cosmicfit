import Foundation
import Hummingbird
import CosmicFitInspectorLib

let missing = ResourcePaths.validateResources()
if !missing.isEmpty {
    print("ERROR: Missing required resources:")
    for m in missing { print("  - \(m)") }
    print("Ensure inspector/Resources/ symlinks point to the correct files.")
    Foundation.exit(1)
}

let engine = InspectorEngine()
try await engine.bootstrap()

let router = buildRouter(engine: engine)

let app = Application(
    router: router,
    configuration: .init(address: .hostname("127.0.0.1", port: 7777))
)

print("╔══════════════════════════════════════════════╗")
print("║  Cosmic Fit Inspector                        ║")
print("║  http://127.0.0.1:7777                       ║")
print("║  Press Ctrl+C to stop                        ║")
print("╠──────────────────────────────────────────────╣")
print("║  Built: \(BuildStamp.timestamp)")
for listing in InspectorDefaults.dailyFitEngineListings() {
    let tag = listing.isExperimental ? " (exp)" : ""
    let short = String(listing.fingerprint.prefix(12))
    print("║  ▸ \(listing.id)\(tag): \(short)…")
}
print("╚══════════════════════════════════════════════╝")

try await app.runService()
