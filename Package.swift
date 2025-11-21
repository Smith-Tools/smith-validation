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
        // Core framework (now local target)
        .library(
            name: "SmithValidationCore",
            targets: ["SmithValidationCore"]
        ),
        // Library for architectural validation
        .library(
            name: "SmithValidation",
            targets: ["SmithValidation"]
        ),
        // Maxwells TCA rules for TCA-specific validation
        .library(
            name: "MaxwellsTCARules",
            targets: ["MaxwellsTCARules"]
        ),
        // Optional CLI tool for standalone usage
        .executable(
            name: "smith-validation",
            targets: ["smith-validation"]
        ),
    ],
    dependencies: [
        // SwiftSyntax for parsing and analysis (updated for Swift Testing compatibility)
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        // Swift Testing for modern testing framework
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
        // PKL Swift bindings for in-process config loading
        .package(url: "https://github.com/apple/pkl-swift.git", from: "0.7.1"),
    ],
    targets: [
        // Local core framework
        .target(
            name: "SmithValidationCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/SmithValidationCore/Sources/SmithValidationCore"
        ),
        // Maxwells TCA rules (symlinked rule sources)
        .target(
            name: "MaxwellsTCARules",
            dependencies: [
                "SmithValidationCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/MaxwellsTCARules",
            sources: [
                "Rule_1_1_MonolithicFeatures.swift",
                "Rule_1_2_ClosureInjection.swift",
                "Rule_1_3_CodeDuplication.swift",
                "Rule_1_4_UnclearOrganization.swift",
                "Rule_1_5_TightlyCoupledState.swift",
                "Registrar.swift"
            ]
        ),
        // Core library
        .target(
            name: "SmithValidation",
            dependencies: [
                "SmithValidationCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "PklSwift", package: "pkl-swift"),
            ],
            path: "Sources/SmithValidation"
        ),

        // CLI tool
        .executableTarget(
            name: "smith-validation",
            dependencies: [
                "SmithValidation",
                "SmithValidationCore",
                "MaxwellsTCARules",
            ],
            path: "Sources/smith-validation"
        ),

  
        // Test suite using Swift Testing
        .testTarget(
            name: "SmithValidationTests",
            dependencies: [
                "SmithValidation",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests"
        ),
    ]
)
