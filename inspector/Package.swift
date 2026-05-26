// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CosmicFitInspector",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/vsmithers1087/SwissEphemeris.git", exact: "0.0.99"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    ],
    targets: [
        // Single library that compiles the engine sources + inspector glue together
        // so all internal engine types are visible without requiring `public`.
        .target(
            name: "CosmicFitInspectorLib",
            dependencies: [
                .product(name: "SwissEphemeris", package: "swissephemeris"),
            ],
            path: "Sources/CosmicFitInspectorLib",
            linkerSettings: [
                .linkedFramework("CoreLocation"),
                .linkedFramework("MapKit"),
            ]
        ),
        .executableTarget(
            name: "cosmicfit-inspector",
            dependencies: [
                "CosmicFitInspectorLib",
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Sources/CosmicFitInspectorServer",
            resources: [
                .copy("Web"),
            ]
        ),
        .testTarget(
            name: "InspectorEngineTests",
            dependencies: ["CosmicFitInspectorLib"],
            path: "Tests/InspectorEngineTests"
        ),
    ]
)
