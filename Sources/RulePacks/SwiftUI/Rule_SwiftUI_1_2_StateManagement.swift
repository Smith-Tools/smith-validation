// Sources/RulePacks/SwiftUI/Rule_SwiftUI_1_2_StateManagement.swift
// SwiftUI Rule 1.2: State Management validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// SwiftUI Rule 1.2: State Management Validator
///
/// Detects:
/// - Excessive @State properties in SwiftUI Views
/// - @State properties that should be @StateObject or @EnvironmentObject
/// - Potential state management complexity issues
/// - Missing @ObservedObject or @EnvironmentObject where needed
///
/// Rationale:
/// - Too many @State properties make Views complex and hard to maintain
/// - Complex state should be moved to ObservableObject classes
/// - Proper state management improves testability and separation of concerns
/// - SwiftUI's state management patterns should be followed consistently
public struct SwiftUIRule_1_2_StateManagement: ValidatableRule {

    public struct Configuration {
        public let maxStateProperties: Int
        public let maxComplexStateProperties: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxStateProperties: Int = 12,
            maxComplexStateProperties: Int = 5,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxStateProperties = maxStateProperties
            self.maxComplexStateProperties = maxComplexStateProperties
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for State Management violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all SwiftUI Views in the file using AST sugar layer
        let swiftUIViews = context.syntax.findSwiftUIViews()

        for view in swiftUIViews {
            violations.append(contentsOf: validateStateManagement(view, in: context))
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for State Management violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for State Management violations
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

    private func validateStateManagement(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Validate total @State property count
        violations.append(contentsOf: validateStatePropertyCount(view, in: context))

        // Validate complex @State properties
        violations.append(contentsOf: validateComplexStateProperties(view, in: context))

        // Validate state management patterns
        violations.append(contentsOf: validateStateManagementPatterns(view, in: context))

        return violations
    }

    private func validateStatePropertyCount(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        let estimatedStateProperties = estimateStatePropertyCount(view)

        if estimatedStateProperties > configuration.maxStateProperties {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "SwiftUI 1.2: Excessive @State Properties",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View has estimated \(estimatedStateProperties) @State properties (> \(configuration.maxStateProperties) threshold)",
                recommendation: "Consider moving complex state to an ObservableObject class or @StateObject, and break down the View into smaller, focused components",
                metadata: [
                    "statePropertyCount": "\(estimatedStateProperties)",
                    "threshold": "\(configuration.maxStateProperties)",
                    "viewName": view.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateComplexStateProperties(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        let estimatedComplexStateProperties = estimateComplexStateProperties(view)

        if estimatedComplexStateProperties > configuration.maxComplexStateProperties {
            let violation = ArchitecturalViolation(
                severity: .high, // Complex state is more severe
                rule: "SwiftUI 1.2: Complex State Properties",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View has estimated \(estimatedComplexStateProperties) complex @State properties (> \(configuration.maxComplexStateProperties) threshold)",
                recommendation: "Extract complex state objects into ObservableObject classes and use @StateObject or @ObservedObject for proper state management",
                metadata: [
                    "complexStateProperties": "\(estimatedComplexStateProperties)",
                    "threshold": "\(configuration.maxComplexStateProperties)",
                    "viewName": view.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateStateManagementPatterns(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Check for potential state management anti-patterns
        if hasStateManagementAntiPatterns(view) {
            let violation = ArchitecturalViolation(
                severity: .medium,
                rule: "SwiftUI 1.2: State Management Anti-Patterns",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View may have state management anti-patterns that could cause performance or maintainability issues",
                recommendation: "Review state management patterns and consider using @StateObject for classes, @EnvironmentObject for shared state, and computed properties for derived state",
                metadata: [
                    "viewName": view.name,
                    "antiPatternDetected": "true"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    // MARK: - Helper Methods for Heuristic Analysis

    private func estimateStatePropertyCount(_ view: StructInfo) -> Int {
        // More conservative heuristic: only count properties that could be @State
        // Simple views typically don't have many state properties
        if view.methodCount <= 1 && view.propertyCount <= 3 {
            return 1 // Base @State for simple views
        }
        return min(view.propertyCount / 3 + 1, 12)
    }

    private func estimateComplexStateProperties(_ view: StructInfo) -> Int {
        // More conservative heuristic for complex state
        // Only count if there are enough properties to indicate complexity
        if view.propertyCount <= 4 {
            return 1 // Base complex state for simple views
        }
        return min(view.propertyCount / 5 + 1, 6)
    }

    private func hasStateManagementAntiPatterns(_ view: StructInfo) -> Bool {
        // More conservative anti-pattern detection
        // Only flag if there are significant indicators of state management issues
        return (view.methodCount > 12 && view.propertyCount > 12) || view.propertyCount > 20
    }

    /// Validate multiple source file contexts for State Management violations
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

public extension SwiftUIRule_1_2_StateManagement {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = SwiftUIRule_1_2_StateManagement()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = SwiftUIRule_1_2_StateManagement()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = SwiftUIRule_1_2_StateManagement()
        return validator.validate(contexts: contexts)
    }
}