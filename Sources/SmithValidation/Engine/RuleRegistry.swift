// Engine/RuleRegistry.swift
// Registry for managing validation rules and metadata

import Foundation
import SmithValidationCore

/// Registry for organizing and managing validation rules
public class RuleRegistry {

    /// Rule metadata
    public struct RuleMetadata {
        public let name: String
        public let description: String
        public let category: RuleCategory
        public let severity: ArchitecturalViolation.Severity
        public let version: String
        public let enabledByDefault: Bool

        public init(
            name: String,
            description: String,
            category: RuleCategory,
            severity: ArchitecturalViolation.Severity,
            version: String,
            enabledByDefault: Bool = true
        ) {
            self.name = name
            self.description = description
            self.category = category
            self.severity = severity
            self.version = version
            self.enabledByDefault = enabledByDefault
        }
    }

    /// Rule categories for organization
    public enum RuleCategory: String, CaseIterable {
        case architecture = "Architecture"
        case tca = "TCA"
        case performance = "Performance"
        case maintainability = "Maintainability"
        case security = "Security"
        case testing = "Testing"

        public var description: String {
            switch self {
            case .architecture: return "General architectural patterns"
            case .tca: return "The Composable Architecture specific rules"
            case .performance: return "Performance-related validations"
            case .maintainability: return "Code maintainability and readability"
            case .security: return "Security-focused validations"
            case .testing: return "Testing-related validations"
            }
        }
    }

    /// Registered rules with metadata
    private var registeredRules: [String: RegisteredRule] = [:]

    /// Initialize with built-in rules
    public init() {
        registerBuiltinRules()
    }

    /// Register a rule with metadata
    /// - Parameters:
    ///   - rule: The validation rule to register
    ///   - metadata: Metadata about the rule
    public func register(rule: any ValidatableRule, metadata: RuleMetadata) {
        registeredRules[metadata.name] = RegisteredRule(rule: rule, metadata: metadata)
    }

    /// Get all registered rules
    /// - Returns: Array of all registered rules
    public func getAllRules() -> [any ValidatableRule] {
        return registeredRules.values.map { $0.rule }
    }

    /// Get rules by category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of rules in the specified category
    public func getRulesByCategory(_ category: RuleCategory) -> [any ValidatableRule] {
        return registeredRules.values
            .filter { $0.metadata.category == category }
            .map { $0.rule }
    }

    /// Get rule metadata
    /// - Parameter name: The name of the rule
    /// - Returns: Metadata for the rule, nil if not found
    public func getMetadata(for name: String) -> RuleMetadata? {
        return registeredRules[name]?.metadata
    }

    /// Get all rules grouped by category
    /// - Returns: Dictionary of rules grouped by category
    public func getRulesByCategory() -> [RuleCategory: [any ValidatableRule]] {
        var grouped: [RuleCategory: [any ValidatableRule]] = [:]

        for category in RuleCategory.allCases {
            grouped[category] = getRulesByCategory(category)
        }

        return grouped
    }

    /// Generate a summary of registered rules
    /// - Returns: Human-readable summary
    public func generateSummary() -> String {
        var summary = "📋 Registered Validation Rules:\n"

        let rulesByCategory = getRulesByCategory()
        for (category, rules) in rulesByCategory.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            if !rules.isEmpty {
                summary += "\n\(category.rawValue) (\(rules.count) rules):\n"
                for registeredRule in registeredRules.values
                    .filter({ $0.metadata.category == category })
                    .sorted(by: { $0.metadata.name < $1.metadata.name }) {
                    let _ = registeredRule.rule
                    let meta = registeredRule.metadata
                    summary += "  ✅ \(meta.name) v\(meta.version) - \(meta.description)\n"
                }
            }
        }

        return summary
    }

    // MARK: - Private Methods

    /// Register built-in validation rules
    private func registerBuiltinRules() {
        // Note: Built-in rules will be registered here when the legacy rules
        // are converted to the new architecture. For now, this is a placeholder
        // that demonstrates how built-in rules would be registered.

        // Example of how built-in rules would be registered:
        // let rule1 = TCARule_1_1_MonolithicFeatures()
        // let metadata1 = RuleMetadata(
        //     name: "TCA-1.1-MonolithicFeatures",
        //     description: "Detects monolithic State structs and Action enums",
        //     category: .tca,
        //     severity: .high,
        //     version: "1.0.0"
        // )
        // register(rule: rule1, metadata: metadata1)
    }
}

/// Internal representation of a registered rule
private struct RegisteredRule {
    let rule: any ValidatableRule
    let metadata: RuleRegistry.RuleMetadata
}