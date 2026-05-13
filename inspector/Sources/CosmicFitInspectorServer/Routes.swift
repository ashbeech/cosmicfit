import Foundation
import Hummingbird
import CosmicFitInspectorLib

func buildRouter(engine: InspectorEngine) -> Router<BasicRequestContext> {
    let router = Router(context: BasicRequestContext.self)

    let jsonEncoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }()

    // MARK: - Health

    router.get("/api/health") { _, _ -> Response in
        let payload: [String: String] = ["ok": "true", "engineVersion": InspectorEngine.engineVersion]
        let body = try jsonEncoder.encode(payload)
        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: body))
        )
    }

    // MARK: - Presets

    router.get("/api/presets") { _, _ -> Response in
        let presets = PresetCatalog.loadPresets()
        let body = try jsonEncoder.encode(presets)
        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: body))
        )
    }

    // MARK: - Geocode

    router.get("/api/geocode") { request, _ -> Response in
        let query = request.uri.queryParameters.get("q") ?? ""
        guard !query.isEmpty else {
            return Response(
                status: .badRequest,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: .init(string: "{\"error\":\"q parameter required\"}"))
            )
        }
        let results = await InspectorGeocoder.search(query: query)
        let body = try jsonEncoder.encode(["results": results])
        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: body))
        )
    }

    // MARK: - Inspect

    router.post("/api/inspect") { request, context -> Response in
        let body = try await request.body.collect(upTo: 1_000_000)
        let decoder = JSONDecoder()
        let inspectRequest = try decoder.decode(InspectorRequest.self, from: body)
        let response = try await engine.resolve(request: inspectRequest)
        let responseData = try jsonEncoder.encode(response)
        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: .init(data: responseData))
        )
    }

    // MARK: - Static Files

    router.get("/") { _, _ -> Response in
        serveStaticFile(named: "index.html", contentType: "text/html")
    }

    router.get("/styles.css") { _, _ -> Response in
        serveStaticFile(named: "styles.css", contentType: "text/css")
    }

    router.get("/app.js") { _, _ -> Response in
        serveStaticFile(named: "app.js", contentType: "application/javascript")
    }

    return router
}

private func serveStaticFile(named filename: String, contentType: String) -> Response {
    if let bundleURL = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Web") ??
                       Bundle.module.url(forResource: filename, withExtension: nil) {
        if let data = try? Data(contentsOf: bundleURL) {
            return Response(
                status: .ok,
                headers: [.contentType: contentType],
                body: .init(byteBuffer: .init(data: data))
            )
        }
    }

    let sourceWeb = ResourcePaths.packageRoot
        .appendingPathComponent("Sources/CosmicFitInspectorServer/Web")
        .appendingPathComponent(filename)
    if let data = try? Data(contentsOf: sourceWeb) {
        return Response(
            status: .ok,
            headers: [.contentType: contentType],
            body: .init(byteBuffer: .init(data: data))
        )
    }

    return Response(status: .notFound, body: .init(byteBuffer: .init(string: "Not found: \(filename)")))
}
