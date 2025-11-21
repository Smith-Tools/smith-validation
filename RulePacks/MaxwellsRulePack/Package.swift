// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MaxwellsRulePack",
    platforms: [.macOS(.v13)],
    products: [],
    dependencies: [
        // Local dependency on the main smith-validation package to reuse core + rules
        .package(path: "../../")
    ],
    targets: [
        .testTarget(
            name: "MaxwellsRulePackTests",
            dependencies: [
                .product(name: "SmithValidationCore", package: "smith-validation"),
                .product(name: "SmithValidation", package: "smith-validation"),
                .product(name: "MaxwellsTCARules", package: "smith-validation")
            ],
            path: "Tests/MaxwellsRulePackTests"
        )
    ]
)
