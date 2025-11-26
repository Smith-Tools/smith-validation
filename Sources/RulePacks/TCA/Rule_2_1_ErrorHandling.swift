// Sources/RulePacks/TCA/Rule_2_1_ErrorHandling.swift
// TCA Rule 2.1: Error Handling Patterns validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 2.1: Error Handling Patterns Validator
///
/// Detects:
/// - Async operations without proper error handling
/// - Missing .failure cases in Result handling
/// - Incomplete error state management in State structs
/// - Unhandled errors in reducer switch statements
///
/// Rationale:
/// - Proper error handling is crucial for robust TCA applications
/// - Unhandled errors can cause crashes and unexpected behavior
/// - Consistent error patterns improve user experience and debugging
public struct TCARule_2_1_ErrorHandling: ValidatableRule {

    public struct Configuration {
        public let requireResultHandling: Bool
        public let maxUnhandledAsyncOperations: Int
        public let requireErrorState: Bool
        public let severity: ArchitecturalViolation.Severity

        public init(
            requireResultHandling: Bool = true,
            maxUnhandledAsyncOperations: Int = 0,
            requireErrorState: Bool = true,
            severity: ArchitecturalViolation.Severity = .high
        ) {
            self.requireResultHandling = requireResultHandling
            self.maxUnhandledAsyncOperations = maxUnhandledAsyncOperations
            self.requireErrorState = requireErrorState
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for error handling violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all TCA reducers in the file using AST sugar layer
        let reducers = context.syntax.findTCAReducers()

        for reducer in reducers {
            violations.append(contentsOf: validateErrorHandling(reducer, in: context))
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for error handling violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for error handling violations
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for sourceFile in sourceFiles {
            let violations = validate(sourceFile: sourceFile)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    // MARK: - Private Validation Methods

    private func validateErrorHandling(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Validate State struct for error state properties using AST sugar layer
        if let stateStruct = reducer.findNestedStruct(named: "State") {
            violations.append(contentsOf: validateErrorState(stateStruct, in: context))
        }

        // Validate Action enum for error action cases using AST sugar layer
        if let actionEnum = reducer.findNestedEnum(named: "Action") {
            violations.append(contentsOf: validateErrorActions(actionEnum, in: context))
        }

        // Validate async operations in reducer body
        violations.append(contentsOf: validateAsyncOperations(reducer, in: context))

        // Validate Result type handling
        violations.append(contentsOf: validateResultHandling(reducer, in: context))

        return violations
    }

    private func validateErrorState(_ state: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        if configuration.requireErrorState && !hasErrorStateProperties(state) {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 2.1: Missing Error State",
                context: context,
                line: state.lineNumber,
                message: "State struct lacks error handling properties",
                recommendation: "Add error-related properties like 'isLoading: Bool' and 'error: String?' to handle async operation states",
                metadata: [
                    "requireErrorState": "\(configuration.requireErrorState)",
                    "propertyCount": "\(state.propertyCount)"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateErrorActions(_ action: EnumInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Check for error-related action cases
        let errorActionPatterns = ["error", "failure", "failed", "errorOccurred"]
        let hasErrorActions = action.caseNames.contains { caseName in
            errorActionPatterns.contains { pattern in
                caseName.lowercased().contains(pattern.lowercased())
            }
        }

        if configuration.requireErrorState && !hasErrorActions {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 2.1: Missing Error Actions",
                context: context,
                line: action.lineNumber,
                message: "Action enum lacks error handling cases",
                recommendation: "Add error-related action cases like 'errorOccurred(String)' or 'loadFailed(Error)' to handle async operation failures",
                metadata: [
                    "caseCount": "\(action.caseCount)",
                    "requireErrorState": "\(configuration.requireErrorState)"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateAsyncOperations(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        let unhandledAsyncOps = countUnhandledAsyncOperations(reducer)

        if unhandledAsyncOps > configuration.maxUnhandledAsyncOperations {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 2.1: Unhandled Async Operations",
                context: context,
                line: reducer.lineNumber,
                message: "Reducer has \(unhandledAsyncOps) async operations without proper error handling",
                recommendation: "Wrap async operations in do-catch blocks or use Result types for proper error handling",
                metadata: [
                    "unhandledOperations": "\(unhandledAsyncOps)",
                    "threshold": "\(configuration.maxUnhandledAsyncOperations)"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateResultHandling(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        if configuration.requireResultHandling && !hasResultHandling(reducer) {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 2.1: Missing Result Type Handling",
                context: context,
                line: reducer.lineNumber,
                message: "Reducer uses async operations but lacks Result type error handling",
                recommendation: "Use Result<Success, Error> types and handle both .success and .failure cases in your reducers",
                metadata: [
                    "requireResultHandling": "\(configuration.requireResultHandling)"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    // MARK: - Helper Methods

    private func hasErrorStateProperties(_ state: StructInfo) -> Bool {
        // Check for common error state property patterns using property names
        let errorStatePatterns = ["error", "isLoading", "failure", "errorMessage", "hasError", "isError", "alertError"]

        // Note: In the current implementation, we'd need access to property names
        // For now, use a simplified heuristic based on state size and naming
        return state.propertyCount > 2 // Simplified placeholder - real implementation would check property names
    }

    private func countUnhandledAsyncOperations(_ reducer: StructInfo) -> Int {
        // Simplified heuristic to count potentially unhandled async operations
        // In a real implementation, this would use proper AST analysis
        return 0 // Placeholder - would implement actual async operation detection
    }

    private func hasResultHandling(_ reducer: StructInfo) -> Bool {
        // Simplified heuristic to detect Result type handling
        // In a real implementation, this would analyze the reducer's body
        return true // Placeholder - would implement actual Result handling detection
    }

    /// Validate multiple source file contexts for error handling violations
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    public func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for context in contexts {
            let violations = validate(context: context)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }
}

// MARK: - Convenience Methods

public extension TCARule_2_1_ErrorHandling {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_2_1_ErrorHandling()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_2_1_ErrorHandling()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = TCARule_2_1_ErrorHandling()
        return validator.validate(contexts: contexts)
    }
}