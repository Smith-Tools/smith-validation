// Frameworks/TCA/Rule_1_4_UnclearOrganization.swift
// TCA Rule 1.4: Unclear Organization validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 1.4: Unclear Organization Validator
///
/// Detects TCA code organization issues that indicate architectural decay:
/// - 5+ vague helper methods with unclear responsibilities
/// - Generic method names like `processStuff`, `handleThings`
/// - Methods that don't clearly express their intent
/// - Helper functions that reduce code readability
///
/// Rationale:
/// - Vague method names make code harder to understand and maintain
/// - Unclear organization suggests the reducer has too many responsibilities
/// - Well-named methods improve code documentation and readability
/// - Good organization is essential for long-term maintainability
public struct TCARule_1_4_UnclearOrganization: ValidatableRule {

    public struct Configuration {
        public let severity: ArchitecturalViolation.Severity
        public let maxVagueMethods: Int
        public let vagueMethodPatterns: Set<String>
        public let minMethodNameLength: Int

        public init(
            severity: ArchitecturalViolation.Severity = .medium,
            maxVagueMethods: Int = 5,
            minMethodNameLength: Int = 3,
            vagueMethodPatterns: Set<String> = [
                // Generic patterns
                "process", "handle", "manage", "perform", "execute",
                "do", "run", "work", "setup", "update", "apply",
                "clear", "reset", "load", "save", "fetch", "get",

                // Common anti-patterns
                "stuff", "things", "data", "item", "value", "result",
                "temp", "helper", "util", "common", "shared"
            ]
        ) {
            self.severity = severity
            self.maxVagueMethods = maxVagueMethods
            self.minMethodNameLength = minMethodNameLength
            self.vagueMethodPatterns = vagueMethodPatterns
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for unclear organization violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all TCA reducers in the file
        let reducers = context.syntax.findTCAReducers()

        for reducer in reducers {
            violations.append(contentsOf: validateReducer(reducer, in: context))
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for unclear organization violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for unclear organization violations
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

    private func validateReducer(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Analyze helper methods in the reducer
        let analyzer = HelperMethodAnalyzer()
        analyzer.analyze(reducer.syntax)

        let vagueMethods = analyzer.vagueMethods
        if vagueMethods.count >= configuration.maxVagueMethods {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.4: Unclear Organization",
                context: context,
                line: analyzer.firstVagueMethodLineNumber,
                message: "Found \(vagueMethods.count) vague helper methods (threshold: \(configuration.maxVagueMethods))",
                recommendation: "Rename helper methods to clearly express their purpose and consider extracting related functionality into separate features.",
                metadata: [
                    "vagueMethodCount": "\(vagueMethods.count)",
                    "threshold": "\(configuration.maxVagueMethods)",
                    "vagueMethods": vagueMethods.joined(separator: ", "),
                    "reducerName": reducer.name,
                    "impact": "Reduced code readability and maintainability"
                ]
            )
            violations.append(violation)
        }

        // Also detect overly short method names (likely too generic)
        let shortMethods = analyzer.shortMethodNames
        if shortMethods.count >= 3 {
            let violation = ArchitecturalViolation(
                severity: .low, // Lower severity for short names
                rule: "TCA 1.4: Unclear Organization",
                file: "Unknown",
                line: analyzer.firstShortMethodLineNumber,
                message: "Found \(shortMethods.count) helper methods with short or unclear names",
                recommendation: "Rename methods to be more descriptive of their specific purpose.",
                metadata: [
                    "shortMethodCount": "\(shortMethods.count)",
                    "shortMethods": shortMethods.joined(separator: ", "),
                    "minLength": "\(configuration.minMethodNameLength)",
                    "reducerName": reducer.name
                ]
            )
            violations.append(violation)
        }

        return violations
    }
}

// MARK: - Convenience Methods

public extension TCARule_1_4_UnclearOrganization {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_1_4_UnclearOrganization()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_1_4_UnclearOrganization()
        return validator.validate(sourceFiles: sourceFiles)
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

// MARK: - Analysis Helper Classes

/// Analyzes helper methods within TCA reducers for organization issues
private class HelperMethodAnalyzer {
    struct VagueMethod {
        let name: String
        let lineNumber: Int
        let reason: String
    }

    var vagueMethods: [String] = []
    var shortMethodNames: [String] = []
    var firstVagueMethodLineNumber: Int = 1
    var firstShortMethodLineNumber: Int = 1

    func analyze(_ syntax: StructDeclSyntax) {
        let visitor = HelperMethodVisitor()
        visitor.walk(syntax)

        vagueMethods = visitor.vagueMethods.map { $0.name }
        shortMethodNames = visitor.shortMethodNames.map { $0.name }

        if let firstVague = visitor.vagueMethods.first {
            firstVagueMethodLineNumber = firstVague.lineNumber
        }

        if let firstShort = visitor.shortMethodNames.first {
            firstShortMethodLineNumber = firstShort.lineNumber
        }
    }
}

/// Visits TCA reducers to analyze helper methods
private class HelperMethodVisitor: SyntaxVisitor {
    struct MethodInfo {
        let name: String
        let lineNumber: Int
        let fullName: String
    }

    var vagueMethods: [MethodInfo] = []
    var shortMethodNames: [MethodInfo] = []
    private let vaguePatterns: Set<String>

    init(vaguePatterns: Set<String> = [
        "process", "handle", "manage", "perform", "execute",
        "do", "run", "work", "setup", "update", "apply",
        "clear", "reset", "load", "save", "fetch", "get",
        "stuff", "things", "data", "item", "value", "result",
        "temp", "helper", "util", "common", "shared"
    ]) {
        self.vaguePatterns = vaguePatterns
        super.init(viewMode: .fixedUp)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        analyzeMethod(node)
        return .skipChildren
    }

    private func analyzeMethod(_ functionDecl: FunctionDeclSyntax) {
        let identifier = functionDecl.name
        let methodName = identifier.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let lineNumber = getLineNumber(from: functionDecl)

        // Check if method is vague
        if isVagueMethod(methodName) {
            let methodInfo = MethodInfo(
                name: methodName,
                lineNumber: lineNumber,
                fullName: functionDecl.description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            vagueMethods.append(methodInfo)
        }

        // Check if method name is too short/generic
        if methodName.count < 4 && !methodName.isEmpty {
            let methodInfo = MethodInfo(
                name: methodName,
                lineNumber: lineNumber,
                fullName: functionDecl.description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            shortMethodNames.append(methodInfo)
        }
    }

    private func isVagueMethod(_ methodName: String) -> Bool {
        let lowercased = methodName.lowercased()

        // Check against vague patterns
        for pattern in vaguePatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }

        // Check for common anti-patterns
        if lowercased.hasPrefix("process") ||
           lowercased.hasPrefix("handle") ||
           lowercased.hasPrefix("update") ||
           lowercased.hasPrefix("apply") ||
           lowercased.hasPrefix("set") ||
           lowercased.hasPrefix("get") {
            return true
        }

        // Check for generic suffixes
        if lowercased.hasSuffix("data") ||
           lowercased.hasSuffix("info") ||
           lowercased.hasSuffix("item") ||
           lowercased.hasSuffix("value") ||
           lowercased.hasSuffix("result") ||
           lowercased.hasSuffix("state") {
            return true
        }

        // Check for numeric suffixes (often indicate poor naming)
        if lowercased.last?.isNumber == true {
            return true
        }

        return false
    }

    private func getLineNumber(from node: some SyntaxProtocol) -> Int {
        let source = node.root.description
        let position = node.position.utf8Offset
        let substring = String(source.prefix(position))
        return substring.components(separatedBy: .newlines).count
    }
}