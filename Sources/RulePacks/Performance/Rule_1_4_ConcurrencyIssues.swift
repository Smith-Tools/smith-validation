// Sources/RulePacks/Performance/Rule_1_4_ConcurrencyIssues.swift
// Performance Rule 1.4: Concurrency Issues validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Performance Rule 1.4: Concurrency Issues Validator
///
/// Detects:
/// - Excessive shared resources without proper synchronization
/// - Blocking calls that can cause performance issues
/// - Main thread operations that should be background tasks
///
/// Rationale:
/// - Concurrency issues can cause race conditions, deadlocks, and performance problems
/// - Blocking calls on the main thread can freeze the UI
/// - Shared resources without proper synchronization can lead to data corruption
/// - Early detection helps ensure thread safety and responsive applications
public struct PerformanceRule_1_4_ConcurrencyIssues: ValidatableRule {

    public struct Configuration {
        public let maxSharedResources: Int
        public let maxBlockingCalls: Int
        public let allowMainThreadOperations: Bool
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxSharedResources: Int = 10,
            maxBlockingCalls: Int = 5,
            allowMainThreadOperations: Bool = false,
            severity: ArchitecturalViolation.Severity = .high
        ) {
            self.maxSharedResources = maxSharedResources
            self.maxBlockingCalls = maxBlockingCalls
            self.allowMainThreadOperations = allowMainThreadOperations
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for concurrency violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Analyze syntax for concurrency issues
        let analyzer = ConcurrencyAnalyzer(syntax: context.syntax)

        // Check for excessive shared resources
        let sharedResources = analyzer.findSharedResources()
        if sharedResources.count > configuration.maxSharedResources {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.4: Concurrency Issues (Shared Resources)",
                context: context,
                line: sharedResources.first?.lineNumber ?? 1,
                message: "Found \(sharedResources.count) shared resources without synchronization (threshold: \(configuration.maxSharedResources))",
                recommendation: "Use proper synchronization mechanisms like actors, serial queues, or locks for shared resources.",
                metadata: [
                    "sharedResources": "\(sharedResources.count)",
                    "threshold": "\(configuration.maxSharedResources)",
                    "excess": "\(sharedResources.count - configuration.maxSharedResources)"
                ]
            )
            violations.append(violation)
        }

        // Check for blocking calls
        let blockingCalls = analyzer.findBlockingCalls()
        if blockingCalls.count > configuration.maxBlockingCalls {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "Performance 1.4: Concurrency Issues (Blocking Calls)",
                context: context,
                line: blockingCalls.first?.lineNumber ?? 1,
                message: "Found \(blockingCalls.count) potentially blocking calls (threshold: \(configuration.maxBlockingCalls))",
                recommendation: "Move blocking operations to background queues or use async alternatives.",
                metadata: [
                    "blockingCalls": "\(blockingCalls.count)",
                    "threshold": "\(configuration.maxBlockingCalls)",
                    "excess": "\(blockingCalls.count - configuration.maxBlockingCalls)"
                ]
            )
            violations.append(violation)
        }

        // Check for main thread operations (if not allowed)
        if !configuration.allowMainThreadOperations {
            let mainThreadOps = analyzer.findMainThreadOperations()
            for mainThreadOp in mainThreadOps {
                let violation = ArchitecturalViolation(
                    severity: configuration.severity,
                    rule: "Performance 1.4: Concurrency Issues (Main Thread Operations)",
                    context: context,
                    line: mainThreadOp.lineNumber,
                    message: "Found potentially blocking main thread operation: \(mainThreadOp.operation)",
                    recommendation: "Move heavy operations to background queues using DispatchQueue.global or async/await.",
                    metadata: [
                        "operation": mainThreadOp.operation,
                        "type": mainThreadOp.type
                    ]
                )
                violations.append(violation)
            }
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for concurrency violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for concurrency violations
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

    /// Validate multiple source file contexts for concurrency violations
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

// MARK: - Concurrency Analyzer

private struct ConcurrencyAnalyzer {
    let syntax: SourceFileSyntax

    func findSharedResources() -> [ConcurrencyIssueInfo] {
        var sharedResources: [ConcurrencyIssueInfo] = []
        let walker = SharedResourceWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        sharedResources.append(contentsOf: walker.sharedResources)
        return sharedResources
    }

    func findBlockingCalls() -> [ConcurrencyIssueInfo] {
        var blockingCalls: [ConcurrencyIssueInfo] = []
        let walker = BlockingCallWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        blockingCalls.append(contentsOf: walker.blockingCalls)
        return blockingCalls
    }

    func findMainThreadOperations() -> [MainThreadOperationInfo] {
        var mainThreadOps: [MainThreadOperationInfo] = []
        let walker = MainThreadWalker(viewMode: .sourceAccurate)
        syntax.walk(walker)
        mainThreadOps.append(contentsOf: walker.mainThreadOperations)
        return mainThreadOps
    }
}

// MARK: - Syntax Walkers

private class SharedResourceWalker: SyntaxVisitor {
    var sharedResources: [ConcurrencyIssueInfo] = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            if let typeAnnotation = binding.typeAnnotation {
                let typeName = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)

                // Check for shared resource patterns
                let sharedResourceTypes = [
                    "NSLock", "NSRecursiveLock", "NSCondition", "NSConditionLock",
                    "DispatchSemaphore", "DispatchGroup", "DispatchQueue",
                    "Mutex", "Atomic", "ThreadSafe", "Synchronized"
                ]

                if sharedResourceTypes.contains(where: typeName.contains) {
                    let resource = ConcurrencyIssueInfo(
                        lineNumber: node.position.line,
                        type: "shared_resource",
                        name: typeName
                    )
                    sharedResources.append(resource)
                }
            }
        }

        // Check for global/static variables that might be shared
        if node.modifiers.contains(where: { $0.name.text == "static" || $0.name.text == "class" }) {
            let resource = ConcurrencyIssueInfo(
                lineNumber: node.position.line,
                type: "global_shared_resource",
                name: node.bindings.first?.pattern.description ?? "unknown"
            )
            sharedResources.append(resource)
        }

        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check for classes with potential shared state
        if node.modifiers.contains(where: { $0.name.text == "open" || $0.name.text == "public" }) {
            // Look for mutable properties in public classes
            let propertyWalker = PublicPropertyWalker()
            node.memberBlock.walk(propertyWalker)

            if propertyWalker.hasMutableProperties {
                let resource = ConcurrencyIssueInfo(
                    lineNumber: node.position.line,
                    type: "public_class_shared_state",
                    name: node.name.text
                )
                sharedResources.append(resource)
            }
        }
        return .visitChildren
    }
}

private class PublicPropertyWalker: SyntaxVisitor {
    var hasMutableProperties = false

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if this is a mutable property
        let isMutable = node.bindings.contains { binding in
            binding.initializer != nil || !binding.isImmutable
        }

        if isMutable {
            hasMutableProperties = true
            return .skipChildren // Found what we were looking for
        }

        return .visitChildren
    }
}

private class BlockingCallWalker: SyntaxVisitor {
    var blockingCalls: [ConcurrencyIssueInfo] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for known blocking operations
        let blockingPatterns = [
            "DispatchQueue.main.sync", "DispatchQueue.global().sync",
            "Thread.sleep", "usleep", "nanosleep",
            "wait()", "waitFor", "synchronous", "sync",
            "FileManager.default.contentsOf", "Data(contentsOf:)",
            "String(contentsOf:)", "String(contentsOfFile:)",
            "UIImage(named:)", "UIImage(contentsOfFile:)",
            "URLSession.shared.dataTask", "NSURLConnection.sendSynchronousRequest",
            "RunLoop.current.run", "CFRunLoopRun"
        ]

        for pattern in blockingPatterns {
            if functionName.contains(pattern) {
                let blockingCall = ConcurrencyIssueInfo(
                    lineNumber: node.position.line,
                    type: "blocking_call",
                    name: functionName
                )
                blockingCalls.append(blockingCall)
                break
            }
        }

        return .visitChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let operatorText = node.operator.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for blocking queue operations
        if operatorText == "!" {
            let leftOperand = node.leftOperand.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if leftOperand.contains("DispatchQueue") || leftOperand.contains("RunLoop") {
                let blockingCall = ConcurrencyIssueInfo(
                    lineNumber: node.position.line,
                    type: "queue_sync",
                    name: leftOperand
                )
                blockingCalls.append(blockingCall)
            }
        }

        return .visitChildren
    }
}

private class MainThreadWalker: SyntaxVisitor {
    var mainThreadOperations: [MainThreadOperationInfo] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for operations that should not be on main thread
        let heavyOperationPatterns = [
            "URLSession.shared.dataTask", "NSData.dataWithContentsOfURL",
            "NSString.stringWithContentsOfURL", "UIImageJPEGRepresentation",
            "UIImagePNGRepresentation", "FileManager.default.contentsOfDirectory",
            "FileManager.default.subpathsOfDirectory", "FileManager.default.createDirectory",
            "CoreData", "fetchRequest", "saveContext", "performBackgroundTask"
        ]

        // Check for synchronous network operations
        let syncNetworkPatterns = [
            "URLSession.shared.synchronousDataTask",
            "NSURLConnection.sendSynchronousRequest"
        ]

        // Check for heavy file operations
        let heavyFilePatterns = [
            "FileManager.default.copyItem",
            "FileManager.default.removeItem",
            "FileManager.default.moveItem"
        ]

        var operationType: String
        var shouldReport = false

        if heavyOperationPatterns.contains(where: functionName.contains) {
            operationType = "heavy_operation"
            shouldReport = true
        } else if syncNetworkPatterns.contains(where: functionName.contains) {
            operationType = "sync_network"
            shouldReport = true
        } else if heavyFilePatterns.contains(where: functionName.contains) {
            operationType = "heavy_file_operation"
            shouldReport = true
        } else {
            operationType = "unknown"
        }

        if shouldReport {
            let mainThreadOp = MainThreadOperationInfo(
                lineNumber: node.position.line,
                operation: functionName,
                type: operationType
            )
            mainThreadOperations.append(mainThreadOp)
        }

        return .visitChildren
    }
}

// MARK: - Data Structures

private struct ConcurrencyIssueInfo {
    let lineNumber: Int
    let type: String
    let name: String
}

private struct MainThreadOperationInfo {
    let lineNumber: Int
    let operation: String
    let type: String
}

// MARK: - Convenience Methods

public extension PerformanceRule_1_4_ConcurrencyIssues {
    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = PerformanceRule_1_4_ConcurrencyIssues()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = PerformanceRule_1_4_ConcurrencyIssues()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = PerformanceRule_1_4_ConcurrencyIssues()
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