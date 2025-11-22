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
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.34.1")
    ],
    targets: [
        .executableTarget(
            name: "smith-validation",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten")
            ],
            path: "Sources/smith-validation"
        ),
    ]
)
