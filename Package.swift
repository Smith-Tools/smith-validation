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
        // No dependencies - using Foundation only for maximum performance
    ],
    targets: [
        .executableTarget(
            name: "smith-validation",
            dependencies: [],
            path: "Sources/smith-validation"
        ),
    ]
)
