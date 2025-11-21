// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MaxwellsRulePack",
    platforms: [.macOS(.v13)],
    products: [],
    dependencies: [
        // Local dependency on the main smith-validation package to reuse core + rules
        .package(path: "../../"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0")
    ],
    targets: [
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
