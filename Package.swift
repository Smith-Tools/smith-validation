// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "smith-validation",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "smith-validation",
            targets: ["smith-validation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.34.1"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1")
    ],
    targets: [
        .executableTarget(
            name: "smith-validation",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/smith-validation"
        ),
        .testTarget(
            name: "SmithValidationTests",
            dependencies: [
                "smith-validation",
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Tests/SmithValidationTests"
        ),
        .testTarget(
            name: "EngineTests",
            dependencies: [
                "smith-validation",
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Tests/EngineTests"
        ),
    ]
)
