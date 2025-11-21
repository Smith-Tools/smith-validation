// Legacy/LegacyRuleAdapter.swift
// Adapter for legacy rules to work with the new engine architecture

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Adapter that wraps legacy validation rules to work with the new engine
public class LegacyRuleAdapter {

    /// Convert legacy rule classes to ValidatableRule protocol
    /// - Parameter legacyRule: A legacy rule instance
    /// - Returns: A rule conforming to ValidatableRule
    public static func adapt<T>(_ legacyRule: T) -> any ValidatableRule where T: LegacyValidationRule {
        return AdaptedRule(wrappedRule: legacyRule)
    }

    /// Load and adapt multiple legacy rules
    /// - Parameter legacyRules: Array of legacy rule instances
    /// - Returns: Array of adapted rules conforming to ValidatableRule
    public static func adaptMany<T>(_ legacyRules: [T]) -> [any ValidatableRule] where T: LegacyValidationRule {
        return legacyRules.map { adapt($0) }
    }
}

/// Protocol for legacy validation rules that need adaptation
public protocol LegacyValidationRule {
    /// Legacy validation method (for backward compatibility)
    func validate(sourceFile: SourceFileSyntax) -> ViolationCollection

    /// Get the rule name
    var ruleName: String { get }
}

/// Internal adapter class that wraps legacy rules
private struct AdaptedRule: ValidatableRule {
    let wrappedRule: any LegacyValidationRule

    init(wrappedRule: any LegacyValidationRule) {
        self.wrappedRule = wrappedRule
    }

    func validate(context: SourceFileContext) -> ViolationCollection {
        return wrappedRule.validate(sourceFile: context.syntax)
    }

    func validate(filePath: String) -> ViolationCollection {
        do {
            let url = URL(fileURLWithPath: filePath)
            let syntax = try SourceFileSyntax.parse(from: url)
            return wrappedRule.validate(sourceFile: syntax)
        } catch {
            let parsingViolation = ArchitecturalViolation.critical(
                rule: wrappedRule.ruleName,
                file: filePath,
                line: 0,
                message: "Failed to parse Swift file: \(error.localizedDescription)",
                recommendation: "Check that the file contains valid Swift syntax"
            )
            return ViolationCollection(violations: [parsingViolation])
        }
    }
}