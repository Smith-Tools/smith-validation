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
                .product(name: "PklSwift", package: "pkl-swift"),
            ],
            path: "Sources/SmithValidationCore/Sources/SmithValidationCore"
        ),
        // Generated PKL configuration
        .target(
            name: "GeneratedConfig",
            dependencies: [
                .product(name: "PklSwift", package: "pkl-swift"),
                "SmithValidationCore",
            ],
            path: "Sources/GeneratedConfig"
        ),
        // Maxwells TCA rules (symlinked rule sources)
        .target(
            name: "MaxwellsTCARules",
            dependencies: [
                "SmithValidationCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/RulePacks",
            sources: [
                "TCA/Rule_1_1_MonolithicFeatures.swift",
                "TCA/Rule_1_2_ClosureInjection.swift",
                "TCA/Rule_1_3_CodeDuplication.swift",
                "TCA/Rule_1_4_UnclearOrganization.swift",
                "TCA/Rule_1_5_TightlyCoupledState.swift",
                "TCA/Rule_2_1_ErrorHandling.swift",
                "TCA/Rule_2_2_ReducibleComplexity.swift",
                "TCA/TCARegistrar.swift",
                "SwiftUI/Rule_SwiftUI_1_ViewBodyComplexity.swift",
                "SwiftUI/Rule_SwiftUI_1_2_StateManagement.swift",
                "SwiftUI/SwiftUIRegistrar.swift",
                // Temporarily disabled Performance rules due to SwiftSyntax API issues
                // "Performance/Rule_1_1_MemoryManagement.swift",
                // "Performance/Rule_1_2_CPUUsagePatterns.swift",
                // "Performance/Rule_1_3_PerformanceAntiPatterns.swift",
                // "Performance/Rule_1_4_ConcurrencyIssues.swift",
                // "Performance/PerformanceRegistrar.swift",
                "General/Rule_General_1_CircularDependencies.swift",
                "General/Rule_General_1_2_ModuleDependencies.swift",
                "General/GeneralRegistrar.swift",
                "RulePackRegistry.swift"
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
                // GeneratedConfig temporarily disabled
                // "GeneratedConfig",
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
