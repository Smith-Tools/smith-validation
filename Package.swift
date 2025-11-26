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
        // Core validation framework
        .library(
            name: "SmithValidationCore",
            targets: ["SmithValidationCore"]
        ),
        // Validation library
        .library(
            name: "SmithValidation",
            targets: ["SmithValidation"]
        ),
        // TCA-specific rules
        .library(
            name: "MaxwellsTCARules",
            targets: ["MaxwellsTCARules"]
        ),
        // CLI tool for AI agent integration
        .executable(
            name: "smith-validation",
            targets: ["smith-validation"]
        ),
    ],
    dependencies: [
        // SwiftSyntax for AST analysis
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        // Swift Testing for architectural rules execution
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
        // PKL for configuration management
        .package(url: "https://github.com/apple/pkl-swift.git", from: "0.2.0"),
        // SourceKitten for deep analysis
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.34.1")
    ],
    targets: [
        // Core validation framework
        .target(
            name: "SmithValidationCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SourceKittenFramework", package: "SourceKitten")
            ],
            path: "Sources/SmithValidationCore"
        ),
        // High-level validation library
        .target(
            name: "SmithValidation",
            dependencies: [
                "SmithValidationCore",
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "PklSwift", package: "pkl-swift")
            ],
            path: "Sources/SmithValidation"
        ),
        // TCA-specific rules
        .target(
            name: "MaxwellsTCARules",
            dependencies: [
                "SmithValidationCore"
            ],
            path: "Sources/MaxwellsTCARules"
        ),
        // CLI tool (maintaining existing regex-based approach for backward compatibility)
        .executableTarget(
            name: "smith-validation",
            dependencies: [], // Keep current regex implementation working
            path: "Sources/smith-validation"
        ),
    ]
)
