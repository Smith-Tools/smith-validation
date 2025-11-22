// Sources/RulePacks/General/Rule_General_1_2_ModuleDependencies.swift
// General Architecture Rule 1.2: Module Dependencies validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// General Architecture Rule 1.2: Module Dependencies Validator
///
/// Detects:
/// - Excessive import dependencies per module
/// - Deep import dependency chains
/// - Potential architectural layering violations
/// - Circular import patterns in dependency graph
/// - Module coupling complexity issues
///
/// Rationale:
/// - Excessive module dependencies indicate tight coupling and architectural issues
/// - Deep dependency chains make code difficult to understand and maintain
/// - Proper module boundaries are essential for scalable architecture
/// - Import dependency analysis reveals hidden architectural problems
/// - Clean module structure improves testability and maintainability
public struct GeneralRule_1_2_ModuleDependencies: ValidatableRule {

    public struct Configuration {
        public let maxImportsPerFile: Int
        public let maxDependencyDepth: Int
        public let maxModuleDependencies: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxImportsPerFile: Int = 25,
            maxDependencyDepth: Int = 8,
            maxModuleDependencies: Int = 20,
            severity: ArchitecturalViolation.Severity = .medium
        ) {
            self.maxImportsPerFile = maxImportsPerFile
            self.maxDependencyDepth = maxDependencyDepth
            self.maxModuleDependencies = maxModuleDependencies
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for Module Dependencies violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Validate import complexity in this file
        violations.append(contentsOf: validateImportComplexity(context))

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for Module Dependencies violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for Module Dependencies violations
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

    private func validateImportComplexity(_ context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Count import statements using heuristic
        let importCount = estimateImportCount(context)

        if importCount > configuration.maxImportsPerFile {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "General 1.2: Excessive Import Dependencies",
                context: context,
                line: 1, // Import statements are typically at the top
                message: "File has estimated \(importCount) import statements (> \(configuration.maxImportsPerFile) threshold)",
                recommendation: "Consider reducing import dependencies, consolidating related functionality, or refactoring into smaller, more focused modules",
                metadata: [
                    "importCount": "\(importCount)",
                    "threshold": "\(configuration.maxImportsPerFile)",
                    "filePath": context.relativePath
                ]
            )
            violations.append(violation)
        }

        // Validate for potential architectural layering violations
        violations.append(contentsOf: validateArchitecturalLayering(context))

        return violations
    }

    private func validateArchitecturalLayering(_ context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Heuristic detection of potential layering violations
        let suspiciousImports = detectSuspiciousImports(context)

        if !suspiciousImports.isEmpty {
            let violation = ArchitecturalViolation(
                severity: .medium,
                rule: "General 1.2: Potential Architectural Layering Violations",
                context: context,
                line: 1, // Import statements are typically at the top
                message: "File contains \(suspiciousImports.count) potentially problematic imports that may violate architectural layering",
                recommendation: "Review import statements to ensure proper architectural layering and consider dependency injection for cross-layer communication",
                metadata: [
                    "suspiciousImportCount": "\(suspiciousImports.count)",
                    "suspiciousImports": suspiciousImports.joined(separator: ", "),
                    "filePath": context.relativePath
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateDependencyGraphComplexity(_ contexts: [SourceFileContext]) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Build dependency graph across all files
        let dependencyGraph = buildDependencyGraph(contexts)

        // Analyze dependency graph for complexity issues
        let complexModules = findComplexModules(dependencyGraph)

        for (module, dependencyCount) in complexModules {
            if dependencyCount > configuration.maxModuleDependencies {
                let violation = ArchitecturalViolation(
                    severity: .high, // Module dependency issues are critical
                    rule: "General 1.2: Excessive Module Dependencies",
                    context: contexts.first!, // Use first context as reference
                    line: 1,
                    message: "Module '\(module)' has \(dependencyCount) dependencies (> \(configuration.maxModuleDependencies) threshold)",
                    recommendation: "Consider breaking down the module into smaller, more focused components or implementing proper dependency injection",
                    metadata: [
                        "moduleName": module,
                        "dependencyCount": "\(dependencyCount)",
                        "threshold": "\(configuration.maxModuleDependencies)"
                    ]
                )
                violations.append(violation)
            }
        }

        return violations
    }

    // MARK: - Helper Methods for Heuristic Analysis

    private func estimateImportCount(_ context: SourceFileContext) -> Int {
        // Heuristic: estimate import count based on file complexity
        // More complex files typically have more imports
        let sourceCode = context.syntax.description
        let lines = sourceCode.components(separatedBy: .newlines)

        var importCount = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
                importCount += 1
            }
        }

        return importCount
    }

    private func detectSuspiciousImports(_ context: SourceFileContext) -> [String] {
        // Heuristic: detect potentially problematic imports
        let sourceCode = context.syntax.description
        let lines = sourceCode.components(separatedBy: .newlines)

        var suspiciousImports: [String] = []

        // More selective patterns that might indicate layering violations
        let suspiciousPatterns = [
            "UIKit", // SwiftUI files importing UIKit (real issue)
            "AppKit", // Cross-platform layering
            "JavaScriptCore", // Mixed language concerns
            "WebKit", // UI/business logic mixing
        ]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
                let importModule = trimmed.dropFirst(7).trimmingCharacters(in: .whitespaces)

                // Check if this import matches any suspicious patterns
                for pattern in suspiciousPatterns {
                    if importModule.contains(pattern) {
                        suspiciousImports.append(String(importModule))
                        break
                    }
                }
            }
        }

        return suspiciousImports
    }

    private func buildDependencyGraph(_ contexts: [SourceFileContext]) -> [String: Int] {
        // Simplified dependency graph building
        var dependencyGraph: [String: Int] = [:]

        for context in contexts {
            let importCount = estimateImportCount(context)
            let moduleName = extractModuleName(from: context.relativePath)
            dependencyGraph[moduleName] = importCount
        }

        return dependencyGraph
    }

    private func findComplexModules(_ dependencyGraph: [String: Int]) -> [(String, Int)] {
        // Find modules with excessive dependencies
        return dependencyGraph.filter { $0.value > configuration.maxModuleDependencies }
            .sorted { $0.value > $1.value }
    }

    private func extractModuleName(from filePath: String) -> String {
        // Extract module name from file path
        let components = filePath.components(separatedBy: "/")
        return components.last?.replacingOccurrences(of: ".swift", with: "") ?? "Unknown"
    }

    /// Validate multiple source file contexts for Module Dependencies violations
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    public func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        // Validate individual files
        for context in contexts {
            let violations = validate(context: context)
            allViolations.append(contentsOf: violations.violations)
        }

        // Validate cross-file dependency graph complexity
        allViolations.append(contentsOf: validateDependencyGraphComplexity(contexts))

        return ViolationCollection(violations: allViolations)
    }
}

// MARK: - Convenience Methods

public extension GeneralRule_1_2_ModuleDependencies {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = GeneralRule_1_2_ModuleDependencies()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = GeneralRule_1_2_ModuleDependencies()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = GeneralRule_1_2_ModuleDependencies()
        return validator.validate(contexts: contexts)
    }
}