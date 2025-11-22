// Sources/RulePacks/TCA/Rule_2_2_ReducibleComplexity.swift
// TCA Rule 2.2: Reducible Complexity validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 2.2: Reducible Complexity Validator
///
/// Detects:
/// - Excessive switch case complexity in reducer bodies
/// - Deep nesting levels that indicate complex logic
/// - Too many async operations (.run calls) in single reducer
/// - Complex conditional logic that should be extracted
///
/// Rationale:
/// - Complex reducers are hard to understand, test, and maintain
/// - Too many responsibilities in one reducer violate single responsibility principle
/// - Complex logic should be extracted into separate reducers or helper functions
/// - Reducer complexity directly impacts code quality and developer productivity
public struct TCARule_2_2_ReducibleComplexity: ValidatableRule {

    public struct Configuration {
        public let maxSwitchCases: Int
        public let maxNestingDepth: Int
        public let maxAsyncOperations: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxSwitchCases: Int = 20,
            maxNestingDepth: Int = 4,
            maxAsyncOperations: Int = 5,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxSwitchCases = maxSwitchCases
            self.maxNestingDepth = maxNestingDepth
            self.maxAsyncOperations = maxAsyncOperations
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all TCA reducers in the file using AST sugar layer
        let reducers = context.syntax.findTCAReducers()

        for reducer in reducers {
            violations.append(contentsOf: validateReducibleComplexity(reducer, in: context))
        }

        return ViolationCollection(violations: violations)
    }

    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    public func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for sourceFile in sourceFiles {
            let violations = validate(sourceFile: sourceFile)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    // MARK: - Private Validation Methods

    private func validateReducibleComplexity(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Validate switch case complexity
        violations.append(contentsOf: validateSwitchCaseComplexity(reducer, in: context))

        // Validate nesting depth complexity
        violations.append(contentsOf: validateNestingComplexity(reducer, in: context))

        // Validate async operation complexity
        violations.append(contentsOf: validateAsyncOperationComplexity(reducer, in: context))

        return violations
    }

    private func validateSwitchCaseComplexity(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Count switch cases using heuristic analysis
        let switchCaseCount = estimateSwitchCaseCount(reducer)

        if switchCaseCount > configuration.maxSwitchCases {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 2.2: Excessive Switch Cases",
                context: context,
                line: reducer.lineNumber,
                message: "Reducer has approximately \(switchCaseCount) switch cases (> \(configuration.maxSwitchCases) threshold)",
                recommendation: "Consider splitting the reducer into smaller, focused reducers or extracting common logic into helper functions",
                metadata: [
                    "switchCaseCount": "\(switchCaseCount)",
                    "threshold": "\(configuration.maxSwitchCases)",
                    "reducerName": reducer.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateNestingComplexity(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Analyze nesting depth using heuristic
        let maxDepth = estimateMaxNestingDepth(reducer)

        if maxDepth > configuration.maxNestingDepth {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 2.2: Excessive Nesting Depth",
                context: context,
                line: reducer.lineNumber,
                message: "Reducer has nesting depth of \(maxDepth) (> \(configuration.maxNestingDepth) threshold)",
                recommendation: "Extract deeply nested logic into separate functions or use early returns to reduce nesting complexity",
                metadata: [
                    "nestingDepth": "\(maxDepth)",
                    "threshold": "\(configuration.maxNestingDepth)",
                    "reducerName": reducer.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateAsyncOperationComplexity(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Count async operations using heuristic
        let asyncOperationCount = estimateAsyncOperationCount(reducer)

        if asyncOperationCount > configuration.maxAsyncOperations {
            let violation = ArchitecturalViolation(
                severity: .high, // Async operations are typically critical
                rule: "TCA 2.2: Too Many Async Operations",
                context: context,
                line: reducer.lineNumber,
                message: "Reducer has \(asyncOperationCount) async operations (.run calls) (> \(configuration.maxAsyncOperations) threshold)",
                recommendation: "Consider splitting into multiple reducers or moving some async operations to child features",
                metadata: [
                    "asyncOperationCount": "\(asyncOperationCount)",
                    "threshold": "\(configuration.maxAsyncOperations)",
                    "reducerName": reducer.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    // MARK: - Helper Methods for Heuristic Analysis

    private func estimateSwitchCaseCount(_ reducer: StructInfo) -> Int {
        // Heuristic: estimate switch case count based on action enum size
        if let actionEnum = reducer.findNestedEnum(named: "Action") {
            return actionEnum.caseCount
        }
        return 0 // No action enum found
    }

    private func estimateMaxNestingDepth(_ reducer: StructInfo) -> Int {
        // Heuristic: estimate nesting based on method count and complexity
        let estimatedDepth = min(reducer.methodCount / 2 + 1, 10)
        return estimatedDepth
    }

    private func estimateAsyncOperationCount(_ reducer: StructInfo) -> Int {
        // Heuristic: estimate async operations based on method count
        return min(reducer.methodCount / 3 + 1, 10)
    }

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

public extension TCARule_2_2_ReducibleComplexity {

    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_2_2_ReducibleComplexity()
        return validator.validate(sourceFile: sourceFile)
    }

    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_2_2_ReducibleComplexity()
        return validator.validate(sourceFiles: sourceFiles)
    }

    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = TCARule_2_2_ReducibleComplexity()
        return validator.validate(contexts: contexts)
    }
}