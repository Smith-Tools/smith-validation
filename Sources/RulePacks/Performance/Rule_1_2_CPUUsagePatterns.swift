// Sources/RulePacks/Performance/Rule_1_2_CPUUsagePatterns.swift
// Performance Rule 1.2: CPU Usage Patterns validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Performance Rule 1.2: CPU Usage Patterns Validator
///
/// Detects:
/// - Excessive nested loops
/// - Deep recursive function calls
/// - Complex calculation patterns that may impact performance
///
/// Rationale:
/// - Excessive nested loops can lead to exponential time complexity
/// - Deep recursion can cause stack overflow and performance issues
/// - Complex calculations in hot paths can impact overall app performance
/// - Early detection helps optimize algorithms before performance issues become critical
public struct PerformanceRule_1_2_CPUUsagePatterns: ValidatableRule {

    public struct Configuration {
        public let maxNestedLoops: Int
        public let maxRecursiveDepth: Int
        public let maxComplexCalculations: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxNestedLoops: Int = 3,
            maxRecursiveDepth: Int = 10,
            maxComplexCalculations: Int = 20,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxNestedLoops = maxNestedLoops
            self.maxRecursiveDepth = maxRecursiveDepth
            self.maxComplexCalculations = maxComplexCalculations
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for CPU usage pattern violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Analyze syntax for CPU-intensive patterns
        let analyzer = CPUUsageAnalyzer(syntax: context.syntax)

        // Check for excessive nested loops
        let nestedLoops = analyzer.findNestedLoops()
        for nestedLoop in nestedLoops {
            if nestedLoop.depth > configuration.maxNestedLoops {
                let violation = ArchitecturalViolation(
                    severity: configuration.severity,
                    rule: "Performance 1.2: CPU Usage Patterns (Nested Loops)",
                    context: context,
                    line: nestedLoop.lineNumber,
                    message: "Found nested loop with depth \(nestedLoop.depth) (threshold: \(configuration.maxNestedLoops))",
                    recommendation: "Consider refactoring nested loops into separate functions or using more efficient algorithms.",
                    metadata: [
                        "loopDepth": "\(nestedLoop.depth)",
                        "threshold": "\(configuration.maxNestedLoops)",
                        "excess": "\(nestedLoop.depth - configuration.maxNestedLoops)"
                    ]
                )
                violations.append(violation)
            }
        }

        // Check for deep recursion
        let recursiveFunctions = analyzer.findRecursiveFunctions()
        for recursiveFunc in recursiveFunctions {
            if recursiveFunc.estimatedDepth > configuration.maxRecursiveDepth {
                let violation = ArchitecturalViolation(
                    severity: configuration.severity,
                    rule: "Performance 1.2: CPU Usage Patterns (Deep Recursion)",
                    context: context,
                    line: recursiveFunc.lineNumber,
                    message: "Function '\(recursiveFunc.name)' has estimated recursion depth \(recursiveFunc.estimatedDepth) (threshold: \(configuration.maxRecursiveDepth))",
                    recommendation: "Consider converting to iterative approach or implement tail recursion optimization.",
                    metadata: [
                        "functionName": recursiveFunc.name,
                        "recursionDepth": "\(recursiveFunc.estimatedDepth)",
                        "threshold": "\(configuration.maxRecursiveDepth)",
                        "excess": "\(recursiveFunc.estimatedDepth - configuration.maxRecursiveDepth)"
                    ]
                )
                violations.append(violation)
            }
        }

        // Check for complex calculations
        let complexCalculations = analyzer.findComplexCalculations()
        if complexCalculations.count > configuration.maxComplexCalculations {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.2: CPU Usage Patterns (Complex Calculations)",
                context: context,
                line: complexCalculations.first?.lineNumber ?? 1,
                message: "Found \(complexCalculations.count) complex calculation patterns (threshold: \(configuration.maxComplexCalculations))",
                recommendation: "Consider caching results, using more efficient algorithms, or moving calculations off the main thread.",
                metadata: [
                    "calculations": "\(complexCalculations.count)",
                    "threshold": "\(configuration.maxComplexCalculations)",
                    "excess": "\(complexCalculations.count - configuration.maxComplexCalculations)"
                ]
            )
            violations.append(violation)
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for CPU usage pattern violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for CPU usage pattern violations
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

    /// Validate multiple source file contexts for CPU usage pattern violations
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

// MARK: - CPU Usage Analyzer

private struct CPUUsageAnalyzer {
    let syntax: SourceFileSyntax

    func findNestedLoops() -> [NestedLoopInfo] {
        var loops: [NestedLoopInfo] = []
        let walker = NestedLoopWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        loops.append(contentsOf: walker.nestedLoops)
        return loops
    }

    func findRecursiveFunctions() -> [RecursiveFunctionInfo] {
        var functions: [RecursiveFunctionInfo] = []
        let walker = RecursiveFunctionWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        functions.append(contentsOf: walker.recursiveFunctions)
        return functions
    }

    func findComplexCalculations() -> [ComplexCalculationInfo] {
        var calculations: [ComplexCalculationInfo] = []
        let walker = ComplexCalculationWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        calculations.append(contentsOf: walker.complexCalculations)
        return calculations
    }
}

// MARK: - Syntax Walkers

private class NestedLoopWalker: SyntaxVisitor {
    var nestedLoops: [NestedLoopInfo] = []
    private var loopStack: [LoopInfo] = []

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        let loopInfo = LoopInfo(
            type: "for",
            lineNumber: node.position.line
        )
        loopStack.append(loopInfo)

        // If this is a nested loop, record it
        if loopStack.count > 1 {
            let nestedLoop = NestedLoopInfo(
                lineNumber: loopInfo.lineNumber,
                depth: loopStack.count
            )
            nestedLoops.append(nestedLoop)
        }

        let result = .visitChildren
        loopStack.removeLast()
        return result
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        let loopInfo = LoopInfo(
            type: "while",
            lineNumber: node.position.line
        )
        loopStack.append(loopInfo)

        // If this is a nested loop, record it
        if loopStack.count > 1 {
            let nestedLoop = NestedLoopInfo(
                lineNumber: loopInfo.lineNumber,
                depth: loopStack.count
            )
            nestedLoops.append(nestedLoop)
        }

        let result = .visitChildren
        loopStack.removeLast()
        return result
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        let loopInfo = LoopInfo(
            type: "repeat-while",
            lineNumber: node.position.line
        )
        loopStack.append(loopInfo)

        // If this is a nested loop, record it
        if loopStack.count > 1 {
            let nestedLoop = NestedLoopInfo(
                lineNumber: loopInfo.lineNumber,
                depth: loopStack.count
            )
            nestedLoops.append(nestedLoop)
        }

        let result = .visitChildren
        loopStack.removeLast()
        return result
    }
}

private class RecursiveFunctionWalker: SyntaxVisitor {
    var recursiveFunctions: [RecursiveFunctionInfo] = []
    private var currentFunction: String?

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        currentFunction = node.name.text

        // Analyze function body for recursive calls
        let recursiveWalker = RecursiveCallWalker(functionName: currentFunction!)
        node.body?.walk(recursiveWalker)

        if recursiveWalker.hasRecursiveCall {
            let recursiveFunc = RecursiveFunctionInfo(
                name: currentFunction!,
                lineNumber: node.position.line,
                estimatedDepth: recursiveWalker.estimatedDepth
            )
            recursiveFunctions.append(recursiveFunc)
        }

        currentFunction = nil
        return .skipChildren // We've already analyzed the body
    }
}

private class RecursiveCallWalker: SyntaxVisitor {
    let functionName: String
    var hasRecursiveCall = false
    var estimatedDepth = 1 // Base estimate
    private var callDepth = 0

    init(functionName: String) {
        self.functionName = functionName
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let calledFunction = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if calledFunction == functionName {
            hasRecursiveCall = true
            callDepth += 1
            estimatedDepth = max(estimatedDepth, callDepth + 1) // Estimate based on nesting
        }

        return .visitChildren
    }
}

private class ComplexCalculationWalker: SyntaxVisitor {
    var complexCalculations: [ComplexCalculationInfo] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Look for computationally expensive operations
        let expensivePatterns = [
            "sorted(by:", "sort()", "filter(", "map(", "reduce(", "flatMap(",
            "enumerate()", "reversed()", "dropFirst(", "dropLast(",
            "prefix(", "suffix(", "split("
        ]

        // Also look for nested function calls
        let hasNestedCalls = node.arguments.contains { arg in
            arg.expression.as(FunctionCallExprSyntax.self) != nil
        }

        let isExpensive = expensivePatterns.contains { functionName.contains($0) } || hasNestedCalls

        if isExpensive {
            let calculation = ComplexCalculationInfo(
                lineNumber: node.position.line,
                operation: functionName,
                complexity: hasNestedCalls ? .high : .medium
            )
            complexCalculations.append(calculation)
        }

        return .visitChildren
    }
}

// MARK: - Data Structures

private struct LoopInfo {
    let type: String
    let lineNumber: Int
}

private struct NestedLoopInfo {
    let lineNumber: Int
    let depth: Int
}

private struct RecursiveFunctionInfo {
    let name: String
    let lineNumber: Int
    let estimatedDepth: Int
}

private struct ComplexCalculationInfo {
    let lineNumber: Int
    let operation: String
    let complexity: CalculationComplexity
}

private enum CalculationComplexity {
    case medium
    case high
}

// MARK: - Convenience Methods

public extension PerformanceRule_1_2_CPUUsagePatterns {
    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = PerformanceRule_1_2_CPUUsagePatterns()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = PerformanceRule_1_2_CPUUsagePatterns()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = PerformanceRule_1_2_CPUUsagePatterns()
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