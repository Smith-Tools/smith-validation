// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MaxwellsRulePack",
    platforms: [.macOS(.v13)],
    products: [
        // Compiler plugin for TCA architectural validation
        .library(
            name: "MaxwellsTCARulesPlugin",
            targets: ["MaxwellsTCARulesPlugin"]
        )
    ],
    dependencies: [
        // Local dependency on the main smith-validation package to reuse core + rules
        .package(path: "../../"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
        // SwiftSyntax for compiler plugin support
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0")
    ],
    targets: [
        // Swift compiler plugin for TCA rules (eliminates post-pass parsing)
        .macro(
            name: "MaxwellsTCARulesPlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            path: "Sources/MaxwellsTCARulesPlugin"
        ),
        .testTarget(
            name: "MaxwellsRulePackTests",
            dependencies: [
                .product(name: "SmithValidationCore", package: "smith-validation"),
                .product(name: "SmithValidation", package: "smith-validation"),
                .product(name: "MaxwellsTCARules", package: "smith-validation"),
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/MaxwellsRulePackTests"
        )
    ]
)
