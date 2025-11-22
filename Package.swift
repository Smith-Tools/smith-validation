// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        // Core framework for architectural analysis
        .library(
            name: "SmithValidationCore",
            targets: ["SmithValidationCore"]
        ),
        // CLI tool for AI agent integration
        .executable(
            name: "smith-validation",
            targets: ["smith-validation"]
        ),
    ],
    dependencies: [
        // NO SwiftSyntax dependency - lightweight regex-based analysis
        // Swift Testing for architectural rules execution (optional, not used in main CLI)
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        // CLI tool for AI agent integration - NO SwiftSyntax dependency!
        .executableTarget(
            name: "smith-validation",
            dependencies: [], // Pure Foundation + Regex - FAST compilation!
            path: "Sources/smith-validation"
        ),
    ]
)
