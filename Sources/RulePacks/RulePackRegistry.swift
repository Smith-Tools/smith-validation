// Sources/RulePacks/RulePackRegistry.swift
// RulePack Discovery and Registration

import Foundation
import SmithValidationCore

/// Registry for discovering and managing multiple RulePacks
public struct RulePackRegistry {

    /// All available RulePacks in the system
    public static let availableRulePacks: [RulePackInfo] = [
        RulePackInfo(
            name: "TCA",
            description: "The Composable Architecture architectural rules",
            rules: registerTCARules()
        ),
        RulePackInfo(
            name: "SwiftUI",
            description: "SwiftUI architectural rules and best practices",
            rules: registerSwiftUIRules()
        ),
        // RulePackInfo(
        //     name: "Performance",
        //     description: "Performance optimization and anti-pattern detection rules",
        //     rules: registerPerformanceRules()
        // ),
        RulePackInfo(
            name: "General",
            description: "General architecture rules applicable to all Swift projects",
            rules: registerGeneralRules()
        ),
        // Future RulePacks can be added here:
        // RulePackInfo(
        //     name: "SwiftLint",
        //     description: "SwiftLint compatibility rules",
        //     rules: registerSwiftLintRules()
        // ),
    ]

    /// Get rules for a specific RulePack by name
    public static func rulesForPack(_ packName: String) -> [any ValidatableRule]? {
        return availableRulePacks.first { $0.name == packName }?.rules
    }

    /// Get all RulePack names
    public static var allPackNames: [String] {
        return availableRulePacks.map { $0.name }
    }
}

/// Information about a RulePack
public struct RulePackInfo {
    public let name: String
    public let description: String
    public let rules: [any ValidatableRule]
}
