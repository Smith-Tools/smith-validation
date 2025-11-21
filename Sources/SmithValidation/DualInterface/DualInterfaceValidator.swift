// DualInterface/DualInterfaceValidator.swift
// Support for both sugar-coated and raw AST validation interfaces

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Validator that supports both high-level and low-level validation interfaces
public class DualInterfaceValidator {

    /// Validation interface preference
    public enum InterfacePreference {
        case preferContext   // Use validate(context:) when available
        case preferFilePath  // Use validate(filePath:) when available
        case automatic       // Choose based on what's available
    }

    private let interfacePreference: InterfacePreference

    public init(interfacePreference: InterfacePreference = .automatic) {
        self.interfacePreference = interfacePreference
    }

    /// Validate using the best available interface for the given rule
    /// - Parameters:
    ///   - rule: The validation rule to execute
    ///   - filePath: Path to the file to validate
    /// - Returns: Collection of architectural violations
    /// - Throws: ValidationError for processing errors
    public func validateWithInterface(
        rule: any ValidatableRule,
        filePath: String
    ) throws -> ViolationCollection {
        return try validateWithInterface(rule: rule, context: nil, filePath: filePath)
    }

    /// Validate using the best available interface for the given rule
    /// - Parameters:
    ///   - rule: The validation rule to execute
    ///   - context: Pre-parsed source file context (optional)
    /// - Returns: Collection of architectural violations
    /// - Throws: ValidationError for processing errors
    public func validateWithInterface(
        rule: any ValidatableRule,
        context: SourceFileContext?
    ) throws -> ViolationCollection {
        return try validateWithInterface(rule: rule, context: context, filePath: nil)
    }

    /// Validate multiple rules using their preferred interfaces
    /// - Parameters:
    ///   - rules: Array of validation rules to execute
    ///   - filePath: Path to the file to validate
    /// - Returns: Combined violation collection from all rules
    /// - Throws: ValidationError for processing errors
    public func validateMultipleWithInterface(
        rules: [any ValidatableRule],
        filePath: String
    ) throws -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        // For efficiency, parse the file once if any rules need context
        var context: SourceFileContext?
        let needsContext = rules.anySatisfy { rule in
            shouldUseContextInterface(for: rule)
        }

        if needsContext {
            context = try parseFile(filePath: filePath)
        }

        for rule in rules {
            let violations = try validateWithInterface(rule: rule, context: context, filePath: filePath)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    /// Validate with explicit context preference override
    /// - Parameters:
    ///   - rule: The validation rule to execute
    ///   - context: Pre-parsed source file context
    ///   - filePath: Path to the file (required if context is nil)
    /// - Returns: Collection of architectural violations
    /// - Throws: ValidationError for processing errors
    private func validateWithInterface(
        rule: any ValidatableRule,
        context: SourceFileContext?,
        filePath: String?
    ) throws -> ViolationCollection {
        switch interfacePreference {
        case .preferContext:
            if let context = context {
                return rule.validate(context: context)
            } else if let filePath = filePath {
                return rule.validate(filePath: filePath)
            } else {
                throw ValidationError.invalidConfiguration("Either context or filePath must be provided")
            }

        case .preferFilePath:
            if let filePath = filePath {
                return rule.validate(filePath: filePath)
            } else if let context = context {
                return rule.validate(context: context)
            } else {
                throw ValidationError.invalidConfiguration("Either context or filePath must be provided")
            }

        case .automatic:
            if shouldUseContextInterface(for: rule), let context = context {
                return rule.validate(context: context)
            } else if let filePath = filePath {
                return rule.validate(filePath: filePath)
            } else if let context = context {
                // Fallback to context if we have it
                return rule.validate(context: context)
            } else {
                throw ValidationError.invalidConfiguration("Either context or filePath must be provided")
            }
        }
    }

    /// Check if a rule should use the context interface
    /// - Parameter rule: The rule to check
    /// - Returns: True if context interface is preferred
    private func shouldUseContextInterface(for rule: some ValidatableRule) -> Bool {
        // For now, default to context interface for better performance
        // In a real implementation, this could check rule metadata
        // or performance characteristics
        return true
    }

    /// Parse a file and return source context
    /// - Parameter filePath: Path to the Swift file
    /// - Returns: Parsed source file context
    /// - Throws: ValidationError for parsing errors
    private func parseFile(filePath: String) throws -> SourceFileContext {
        let fileURL = URL(fileURLWithPath: filePath)

        do {
            let syntax = try SourceFileSyntax.parse(from: fileURL)
            return SourceFileContext(path: filePath, url: fileURL, syntax: syntax)
        } catch {
            throw ValidationError.parsingError(error)
        }
    }
}

/// Extension for Array to support anySatisfy on older Swift versions
extension Array {
    func anySatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for element in self {
            if try predicate(element) {
                return true
            }
        }
        return false
    }
}