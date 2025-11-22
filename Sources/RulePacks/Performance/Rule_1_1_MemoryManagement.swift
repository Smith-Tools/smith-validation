// Sources/RulePacks/Performance/Rule_1_1_MemoryManagement.swift
// Performance Rule 1.1: Memory Management validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Performance Rule 1.1: Memory Management Validator
///
/// Detects:
/// - Potential retain cycles in closures
/// - Excessive strong references in classes
/// - Memory allocation patterns that may cause issues
///
/// Rationale:
/// - Memory management issues are a common source of performance problems
/// - Retain cycles can lead to memory leaks
/// - Excessive strong references can prevent proper deallocation
/// - Large memory allocations can cause performance degradation
public struct PerformanceRule_1_1_MemoryManagement: ValidatableRule {

    public struct Configuration {
        public let maxRetainCycles: Int
        public let maxStrongReferences: Int
        public let maxMemoryAllocations: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxRetainCycles: Int = 5,
            maxStrongReferences: Int = 50,
            maxMemoryAllocations: Int = 100,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxRetainCycles = maxRetainCycles
            self.maxStrongReferences = maxStrongReferences
            self.maxMemoryAllocations = maxMemoryAllocations
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for memory management violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Analyze syntax for memory management patterns
        let analyzer = MemoryAnalyzer(syntax: context.syntax)

        // Check for potential retain cycles
        let retainCycles = analyzer.findPotentialRetainCycles()
        if retainCycles.count > configuration.maxRetainCycles {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.1: Memory Management (Retain Cycles)",
                context: context,
                line: retainCycles.first?.lineNumber ?? 1,
                message: "Found \(retainCycles.count) potential retain cycles (threshold: \(configuration.maxRetainCycles))",
                recommendation: "Use weak or unowned references for closure capture lists and delegate patterns.",
                metadata: [
                    "retainCycles": "\(retainCycles.count)",
                    "threshold": "\(configuration.maxRetainCycles)",
                    "excess": "\(retainCycles.count - configuration.maxRetainCycles)"
                ]
            )
            violations.append(violation)
        }

        // Check for excessive strong references
        let strongRefs = analyzer.countStrongReferences()
        if strongRefs > configuration.maxStrongReferences {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.1: Memory Management (Strong References)",
                context: context,
                line: 1,
                message: "Found \(strongRefs) strong references (threshold: \(configuration.maxStrongReferences))",
                recommendation: "Consider using weak or unowned references where appropriate to prevent retain cycles.",
                metadata: [
                    "strongReferences": "\(strongRefs)",
                    "threshold": "\(configuration.maxStrongReferences)",
                    "excess": "\(strongRefs - configuration.maxStrongReferences)"
                ]
            )
            violations.append(violation)
        }

        // Check for large memory allocations
        let allocations = analyzer.findLargeMemoryAllocations()
        if allocations.count > configuration.maxMemoryAllocations {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.1: Memory Management (Large Allocations)",
                context: context,
                line: allocations.first?.lineNumber ?? 1,
                message: "Found \(allocations.count) large memory allocations (threshold: \(configuration.maxMemoryAllocations))",
                recommendation: "Consider using lazy loading, object pooling, or more efficient data structures.",
                metadata: [
                    "allocations": "\(allocations.count)",
                    "threshold": "\(configuration.maxMemoryAllocations)",
                    "excess": "\(allocations.count - configuration.maxMemoryAllocations)"
                ]
            )
            violations.append(violation)
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for memory management violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for memory management violations
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

    /// Validate multiple source file contexts for memory management violations
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

// MARK: - Memory Analyzer

private struct MemoryAnalyzer {
    let syntax: SourceFileSyntax

    func findPotentialRetainCycles() -> [RetainCycleInfo] {
        var cycles: [RetainCycleInfo] = []

        // Look for closure patterns that might create retain cycles
        let closureWalker = RetainCycleWalker(viewMode: .sourceAccurate)
        syntax.walk(closureWalker)
        cycles.append(contentsOf: closureWalker.foundCycles)

        return cycles
    }

    func countStrongReferences() -> Int {
        var count = 0

        // Count class declarations, property declarations, and strong references
        let walker = StrongReferenceWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        count = walker.strongReferenceCount

        return count
    }

    func findLargeMemoryAllocations() -> [MemoryAllocationInfo] {
        var allocations: [MemoryAllocationInfo] = []

        // Look for large array allocations, data operations, etc.
        let walker = MemoryAllocationWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        allocations.append(contentsOf: walker.foundAllocations)

        return allocations
    }
}

// MARK: - Syntax Walkers

private class RetainCycleWalker: SyntaxVisitor {
    var foundCycles: [RetainCycleInfo] = []

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        // Analyze closure capture lists for potential retain cycles
        if let captureList = node.signature?.captureList {
            for capture in captureList {
                if case .weak = capture.specifier {
                    continue // weak captures are safe
                }

                // Check if capture might create a retain cycle
                if capture.name != nil {
                    let cycle = RetainCycleInfo(
                        lineNumber: node.position.line
                    )
                    foundCycles.append(cycle)
                }
            }
        }
        return .visitChildren
    }
}

private class StrongReferenceWalker: SyntaxVisitor {
    var strongReferenceCount = 0

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        strongReferenceCount += 1
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Count non-weak properties
        for binding in node.bindings {
            if let type = binding.typeAnnotation?.type,
               type.description.contains("class") {
                strongReferenceCount += 1
            }
        }
        return .visitChildren
    }
}

private class MemoryAllocationWalker: SyntaxVisitor {
    var foundAllocations: [MemoryAllocationInfo] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description

        // Look for large allocation patterns
        let largeAllocationPatterns = [
            "Array(repeating:",
            "Data(count:",
            "NSMutableData",
            "malloc",
            "calloc"
        ]

        for pattern in largeAllocationPatterns {
            if functionName.contains(pattern) {
                let allocation = MemoryAllocationInfo(
                    lineNumber: node.position.line,
                    type: pattern
                )
                foundAllocations.append(allocation)
                break
            }
        }

        return .visitChildren
    }
}

// MARK: - Data Structures

private struct RetainCycleInfo {
    let lineNumber: Int
}

private struct MemoryAllocationInfo {
    let lineNumber: Int
    let type: String
}

// MARK: - Convenience Methods

public extension PerformanceRule_1_1_MemoryManagement {
    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = PerformanceRule_1_1_MemoryManagement()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = PerformanceRule_1_1_MemoryManagement()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = PerformanceRule_1_1_MemoryManagement()
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