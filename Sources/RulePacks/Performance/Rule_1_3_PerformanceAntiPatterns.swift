// Sources/RulePacks/Performance/Rule_1_3_PerformanceAntiPatterns.swift
// Performance Rule 1.3: Performance Anti-Patterns validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Performance Rule 1.3: Performance Anti-Patterns Validator
///
/// Detects:
/// - Excessive string concatenations
/// - Force unwrapping and force casting that may cause crashes
/// - Large value types that impact performance
///
/// Rationale:
/// - String concatenations in loops can be O(n²) instead of O(n)
/// - Force operations can cause crashes and are generally unsafe
/// - Large value types copied frequently can impact performance
/// - These anti-patterns are common sources of performance issues in Swift apps
public struct PerformanceRule_1_3_PerformanceAntiPatterns: ValidatableRule {

    public struct Configuration {
        public let maxStringConcatenations: Int
        public let maxForceCasts: Int
        public let maxLargeValueTypes: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxStringConcatenations: Int = 10,
            maxForceCasts: Int = 5,
            maxLargeValueTypes: Int = 20,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxStringConcatenations = maxStringConcatenations
            self.maxForceCasts = maxForceCasts
            self.maxLargeValueTypes = maxLargeValueTypes
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for performance anti-pattern violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Analyze syntax for performance anti-patterns
        let analyzer = AntiPatternAnalyzer(syntax: context.syntax)

        // Check for excessive string concatenations
        let concatenations = analyzer.findStringConcatenations()
        if concatenations.count > configuration.maxStringConcatenations {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.3: Performance Anti-Patterns (String Concatenations)",
                context: context,
                line: concatenations.first?.lineNumber ?? 1,
                message: "Found \(concatenations.count) string concatenations (threshold: \(configuration.maxStringConcatenations))",
                recommendation: "Use StringBuilder or array joined with separator for multiple string concatenations.",
                metadata: [
                    "concatenations": "\(concatenations.count)",
                    "threshold": "\(configuration.maxStringConcatenations)",
                    "excess": "\(concatenations.count - configuration.maxStringConcatenations)"
                ]
            )
            violations.append(violation)
        }

        // Check for excessive force casts and unwrapping
        let forceOperations = analyzer.findForceOperations()
        if forceOperations.count > configuration.maxForceCasts {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.3: Performance Anti-Patterns (Force Operations)",
                context: context,
                line: forceOperations.first?.lineNumber ?? 1,
                message: "Found \(forceOperations.count) force operations (threshold: \(configuration.maxForceCasts))",
                recommendation: "Use optional binding, guard let, or conditional casting instead of force operations.",
                metadata: [
                    "forceOperations": "\(forceOperations.count)",
                    "threshold": "\(configuration.maxForceCasts)",
                    "excess": "\(forceOperations.count - configuration.maxForceCasts)"
                ]
            )
            violations.append(violation)
        }

        // Check for large value types
        let largeValueTypes = analyzer.findLargeValueTypes()
        if largeValueTypes.count > configuration.maxLargeValueTypes {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.3: Performance Anti-Patterns (Large Value Types)",
                context: context,
                line: largeValueTypes.first?.lineNumber ?? 1,
                message: "Found \(largeValueTypes.count) large value types (threshold: \(configuration.maxLargeValueTypes))",
                recommendation: "Consider using classes for large types or breaking them into smaller components.",
                metadata: [
                    "largeValueTypes": "\(largeValueTypes.count)",
                    "threshold": "\(configuration.maxLargeValueTypes)",
                    "excess": "\(largeValueTypes.count - configuration.maxLargeValueTypes)"
                ]
            )
            violations.append(violation)
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for performance anti-pattern violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for performance anti-pattern violations
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

    /// Validate multiple source file contexts for performance anti-pattern violations
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

// MARK: - Anti-Pattern Analyzer

private struct AntiPatternAnalyzer {
    let syntax: SourceFileSyntax

    func findStringConcatenations() -> [AntiPatternInfo] {
        var concatenations: [AntiPatternInfo] = []
        let walker = StringConcatenationWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        concatenations.append(contentsOf: walker.concatenations)
        return concatenations
    }

    func findForceOperations() -> [AntiPatternInfo] {
        var forceOperations: [AntiPatternInfo] = []
        let walker = ForceOperationWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        forceOperations.append(contentsOf: walker.forceOperations)
        return forceOperations
    }

    func findLargeValueTypes() -> [AntiPatternInfo] {
        var largeValueTypes: [AntiPatternInfo] = []
        let walker = LargeValueTypeWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        largeValueTypes.append(contentsOf: walker.largeValueTypes)
        return largeValueTypes
    }
}

// MARK: - Syntax Walkers

private class StringConcatenationWalker: SyntaxVisitor {
    var concatenations: [AntiPatternInfo] = []

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let operatorText = node.operator.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if this is a string concatenation (+ operator)
        if operatorText == "+" {
            // Try to determine if operands are strings
            let leftType = inferStringType(node.leftOperand)
            let rightType = inferStringType(node.rightOperand)

            if leftType || rightType {
                let concatenation = AntiPatternInfo(
                    lineNumber: node.position.line,
                    pattern: "string_concatenation"
                )
                concatenations.append(concatenation)
            }
        }

        return .visitChildren
    }

    private func inferStringType(_ expr: ExprSyntax) -> Bool {
        let expression = expr.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for string literals
        if expression.hasPrefix("\"") && expression.hasSuffix("\"") {
            return true
        }

        // Check for common string types and methods
        let stringIndicators = [
            "String", "NSString", "description", "localizedDescription",
            "debugDescription", "stringLiteral"
        ]

        for indicator in stringIndicators {
            if expression.contains(indicator) {
                return true
            }
        }

        return false
    }
}

private class ForceOperationWalker: SyntaxVisitor {
    var forceOperations: [AntiPatternInfo] = []

    override func visit(_ node: ForceUnwrapExprSyntax) -> SyntaxVisitorContinueKind {
        let forceOp = AntiPatternInfo(
            lineNumber: node.position.line,
            pattern: "force_unwrap"
        )
        forceOperations.append(forceOp)
        return .visitChildren
    }

    override func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        if node.questionOrExclamationMark?.text == "!" {
            let forceOp = AntiPatternInfo(
                lineNumber: node.position.line,
                pattern: "force_cast"
            )
            forceOperations.append(forceOp)
        }
        return .visitChildren
    }
}

private class LargeValueTypeWalker: SyntaxVisitor {
    var largeValueTypes: [AntiPatternInfo] = []

    private let potentiallyLargeTypes = [
        "Data", "NSData", "UIImage", "NSImage", "CIImage",
        "AVAsset", "URLSession", "URLResponse", "URLRequest",
        "Array", "Dictionary", "Set", "String", "NSMutableString"
    ]

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Analyze struct properties to estimate size
        let propertyAnalyzer = StructPropertyAnalyzer()
        node.memberBlock.walk(propertyAnalyzer)

        if propertyAnalyzer.estimatedSize > 1024 { // > 1KB estimated size
            let largeType = AntiPatternInfo(
                lineNumber: node.position.line,
                pattern: "large_value_type"
            )
            largeValueTypes.append(largeType)
        }

        return .skipChildren // We've analyzed the struct already
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check for large type declarations
        for binding in node.bindings {
            if let typeAnnotation = binding.typeAnnotation {
                let typeName = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

                if isPotentiallyLargeType(typeName) {
                    let largeType = AntiPatternInfo(
                        lineNumber: node.position.line,
                        pattern: "large_value_type"
                    )
                    largeValueTypes.append(largeType)
                }
            }
        }

        return .visitChildren
    }

    private func isPotentiallyLargeType(_ typeName: String) -> Bool {
        // Check for collections with large capacities
        if typeName.contains("Array") || typeName.contains("Dictionary") || typeName.contains("Set") {
            return true
        }

        // Check for data types
        if typeName.contains("Data") || typeName.contains("Data") {
            return true
        }

        // Check for other known large types
        return potentiallyLargeTypes.contains { typeName.contains($0) }
    }
}

// MARK: - Supporting Classes

private class StructPropertyAnalyzer: SyntaxVisitor {
    var estimatedSize = 0

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            if let typeAnnotation = binding.typeAnnotation {
                let typeName = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                estimatedSize += estimateTypeSize(typeName)
            }
        }
        return .visitChildren
    }

    private func estimateTypeSize(_ typeName: String) -> Int {
        // Basic size estimation in bytes
        let baseSizes: [String: Int] = [
            "Int": 8, "Int8": 1, "Int16": 2, "Int32": 4, "Int64": 8,
            "UInt": 8, "UInt8": 1, "UInt16": 2, "UInt32": 4, "UInt64": 8,
            "Float": 4, "Double": 8, "CGFloat": 8,
            "Bool": 1, "String": 24, "Character": 1
        ]

        // Check exact matches first
        if let size = baseSizes[typeName] {
            return size
        }

        // Check for partial matches (Array<T>, etc.)
        for (type, size) in baseSizes {
            if typeName.contains(type) {
                return size * 10 // Assume collections are larger
            }
        }

        // Default size for unknown types
        return 16
    }
}

// MARK: - Data Structures

private struct AntiPatternInfo {
    let lineNumber: Int
    let pattern: String
}

// MARK: - Convenience Methods

public extension PerformanceRule_1_3_PerformanceAntiPatterns {
    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = PerformanceRule_1_3_PerformanceAntiPatterns()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = PerformanceRule_1_3_PerformanceAntiPatterns()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = PerformanceRule_1_3_PerformanceAntiPatterns()
        return validator.validate(contexts: contexts)
    }

    /// Validate a project directory
    /// - Parameter directoryURL: Directory URL containing Swift files
    /// - Returns: Collection of architectural violations
    /// - Throws: File system errors
    static func validate(directory: URL) throws -> ViolationCollection {
        let swiftFiles = try FileUtils.findSwiftFiles(in: directory)
        let parsedFiles = try swiftFiles.compactMap { try? SourceFileSyntax.parse(from: $0) }
        return validate(sourceFiles: parsedFiles)
    }
}