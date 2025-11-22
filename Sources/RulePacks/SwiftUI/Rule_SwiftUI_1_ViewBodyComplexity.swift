// Sources/RulePacks/SwiftUI/Rule_SwiftUI_1_ViewBodyComplexity.swift
// SwiftUI Rule 1.1: View Body Complexity validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// SwiftUI Rule 1.1: View Body Complexity Validator
///
/// Detects:
/// - Excessive lines of code in View body (complex UI logic)
/// - Deep nesting levels in SwiftUI View body
/// - Too many conditional statements in view body
/// - Excessive use of View modifiers that indicate complex UI
///
/// Rationale:
/// - Complex View bodies are hard to read, maintain, and test
/// - SwiftUI favors composition over complexity in View body
/// - Complex views should be broken down into smaller, focused child views
/// - Excessive modifiers suggest opportunities for View composition or ViewModifier extraction
public struct SwiftUIRule_1_1_ViewBodyComplexity: ValidatableRule {

    public struct Configuration {
        public let maxViewBodyLines: Int
        public let maxNestingDepth: Int
        public let maxConditionalStatements: Int
        public let maxViewModifiers: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxViewBodyLines: Int = 100,
            maxNestingDepth: Int = 8,
            maxConditionalStatements: Int = 15,
            maxViewModifiers: Int = 30,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxViewBodyLines = maxViewBodyLines
            self.maxNestingDepth = maxNestingDepth
            self.maxConditionalStatements = maxConditionalStatements
            self.maxViewModifiers = maxViewModifiers
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for View body complexity violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all SwiftUI Views in the file using AST sugar layer
        let swiftUIViews = context.syntax.findSwiftUIViews()

        for view in swiftUIViews {
            violations.append(contentsOf: validateViewBodyComplexity(view, in: context))
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for View body complexity violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for View body complexity violations
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

    private func validateViewBodyComplexity(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Validate view body size complexity
        violations.append(contentsOf: validateViewBodySize(view, in: context))

        // Validate nesting depth complexity
        violations.append(contentsOf: validateViewNestingDepth(view, in: context))

        // Validate conditional logic complexity
        violations.append(contentsOf: validateConditionalComplexity(view, in: context))

        // Validate modifier usage complexity
        violations.append(contentsOf: validateModifierComplexity(view, in: context))

        return violations
    }

    private func validateViewBodySize(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Estimate view body complexity using heuristics
        let estimatedBodyLines = estimateViewBodySize(view)

        if estimatedBodyLines > configuration.maxViewBodyLines {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "SwiftUI 1.1: Complex View Body",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View has estimated body size of ~\(estimatedBodyLines) lines (> \(configuration.maxViewBodyLines) threshold)",
                recommendation: "Consider breaking down the complex view into smaller, focused child views or extract common UI components into separate View structs",
                metadata: [
                    "estimatedBodyLines": "\(estimatedBodyLines)",
                    "threshold": "\(configuration.maxViewBodyLines)",
                    "viewName": view.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateViewNestingDepth(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Estimate nesting depth using heuristic
        let estimatedDepth = estimateViewNestingDepth(view)

        if estimatedDepth > configuration.maxNestingDepth {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "SwiftUI 1.1: Excessive Nesting Depth",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View has estimated nesting depth of \(estimatedDepth) (> \(configuration.maxNestingDepth) threshold)",
                recommendation: "Extract deeply nested UI components into separate child views or use container views to reduce nesting complexity",
                metadata: [
                    "nestingDepth": "\(estimatedDepth)",
                    "threshold": "\(configuration.maxNestingDepth)",
                    "viewName": view.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateConditionalComplexity(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Estimate conditional logic complexity using heuristic
        let estimatedConditionalCount = estimateConditionalComplexity(view)

        if estimatedConditionalCount > configuration.maxConditionalStatements {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "SwiftUI 1.1: Excessive Conditional Logic",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View has estimated \(estimatedConditionalCount) conditional statements (> \(configuration.maxConditionalStatements) threshold)",
                recommendation: "Consider extracting conditional UI components into computed properties or separate child views, and use enum-based state machines for complex conditions",
                metadata: [
                    "conditionalStatements": "\(estimatedConditionalCount)",
                    "threshold": "\(configuration.maxConditionalStatements)",
                    "viewName": view.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateModifierComplexity(_ view: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Estimate modifier usage complexity using heuristic
        let estimatedModifierCount = estimateModifierComplexity(view)

        if estimatedModifierCount > configuration.maxViewModifiers {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "SwiftUI 1.1: Excessive View Modifiers",
                context: context,
                line: view.lineNumber,
                message: "SwiftUI View has estimated \(estimatedModifierCount) View modifiers (> \(configuration.maxViewModifiers) threshold)",
                recommendation: "Extract common modifier chains into ViewModifier structs or use custom container views to reduce modifier chaining complexity",
                metadata: [
                    "modifierCount": "\(estimatedModifierCount)",
                    "threshold": "\(configuration.maxViewModifiers)",
                    "viewName": view.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    // MARK: - Helper Methods for Heuristic Analysis

    private func estimateViewBodySize(_ view: StructInfo) -> Int {
        // More conservative heuristic: only count methods if there are many
        if view.methodCount <= 1 {
            return 30 // Base size for simple views
        }
        return min(view.methodCount * 5 + 25, 200)
    }

    private func estimateViewNestingDepth(_ view: StructInfo) -> Int {
        // More conservative: only penalize if there are significant methods
        if view.methodCount <= 2 {
            return 2 // Base nesting for simple views
        }
        return min(view.methodCount / 3 + 2, 8)
    }

    private func estimateConditionalComplexity(_ view: StructInfo) -> Int {
        // More conservative: base conditional count on method complexity
        if view.methodCount <= 1 {
            return 2 // Base conditionals for simple views
        }
        return min(view.methodCount + 1, 12)
    }

    private func estimateModifierComplexity(_ view: StructInfo) -> Int {
        // More conservative: base modifier count on actual property usage
        if view.propertyCount <= 2 && view.methodCount <= 1 {
            return 8 // Base modifiers for simple views
        }
        return min((view.propertyCount * 2) + (view.methodCount * 1) + 5, 25)
    }

    /// Validate multiple source file contexts for View body complexity violations
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

public extension SwiftUIRule_1_1_ViewBodyComplexity {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = SwiftUIRule_1_1_ViewBodyComplexity()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = SwiftUIRule_1_1_ViewBodyComplexity()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = SwiftUIRule_1_1_ViewBodyComplexity()
        return validator.validate(contexts: contexts)
    }
}