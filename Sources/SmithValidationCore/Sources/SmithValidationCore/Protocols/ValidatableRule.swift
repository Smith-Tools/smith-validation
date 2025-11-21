// Protocols/ValidatableRule.swift
// Core protocol for validation rules

import Foundation
import SwiftSyntax

/// Protocol that all validation rules must conform to
/// Provides both sugar-coated and raw AST interfaces for maximum flexibility
public protocol ValidatableRule {
    /// Validate using the high-level SourceFileContext interface
    /// - Parameter context: The source file context with path and parsed AST
    /// - Returns: Collection of architectural violations
    func validate(context: SourceFileContext) -> ViolationCollection

    /// Validate using the simple file path interface
    /// - Parameter filePath: Path to the Swift file to validate
    /// - Returns: Collection of architectural violations
    func validate(filePath: String) -> ViolationCollection
}

/// Default implementation for the file path interface
public extension ValidatableRule {
    /// Default implementation that reads file, parses it, and calls context-based validation
    func validate(filePath: String) -> ViolationCollection {
        do {
            let url = URL(fileURLWithPath: filePath)
            let syntax = try SourceFileSyntax.parse(from: url)
            let context = SourceFileContext(path: filePath, url: url, syntax: syntax)
            return validate(context: context)
        } catch {
            // Return a violation collection with a parsing error
            let parsingViolation = ArchitecturalViolation.critical(
                rule: String(describing: type(of: self)),
                file: filePath,
                line: 0,
                message: "Failed to parse Swift file: \(error.localizedDescription)",
                recommendation: "Check that the file contains valid Swift syntax"
            )
            return ViolationCollection(violations: [parsingViolation])
        }
    }
}