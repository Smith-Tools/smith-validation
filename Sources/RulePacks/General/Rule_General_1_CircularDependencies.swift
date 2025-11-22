// Sources/RulePacks/General/Rule_General_1_CircularDependencies.swift
// General Architecture Rule 1: Circular Dependencies validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// General Architecture Rule 1: Circular Dependencies Validator
///
/// Detects:
/// - Circular import dependencies between modules/files
/// - Circular references between structs/classes
/// - Circular dependency patterns that can cause compilation issues
///
/// Rationale:
/// - Circular dependencies make code difficult to understand and maintain
/// - They can cause compilation failures and runtime issues
/// - Breaking circular dependencies improves code modularity
public struct GeneralRule_1_CircularDependencies: ValidatableRule {

    public struct Configuration {
        public let maxDependencyDepth: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxDependencyDepth: Int = 10,
            severity: ArchitecturalViolation.Severity = .high
        ) {
            self.maxDependencyDepth = maxDependencyDepth
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for circular dependency violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Detect circular import patterns
        violations.append(contentsOf: validateCircularImports(context))

        // Detect circular type dependencies
        violations.append(contentsOf: validateCircularTypeDependencies(context))

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for circular dependency violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for circular dependency violations
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

    private func validateCircularImports(_ context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Simplified heuristic for circular import detection
        // In a real implementation, this would analyze import statements across files
        let imports = extractImports(from: context.syntax)

        // Check for suspicious import patterns that might indicate circular dependencies
        for importStatement in imports {
            if isPotentialCircularImport(importStatement, in: context) {
                let violation = ArchitecturalViolation(
                    severity: configuration.severity,
                    rule: "General 1.1: Circular Import Dependencies",
                    context: context,
                    line: 1, // Import statements are typically at the top
                    message: "Potential circular import dependency detected",
                    recommendation: "Consider refactoring to break circular dependencies by moving shared code to a separate module",
                    metadata: [
                        "importModule": importStatement,
                        "filePath": context.relativePath
                    ]
                )
                violations.append(violation)
            }
        }

        return violations
    }

    private func validateCircularTypeDependencies(_ context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Simplified heuristic for circular type dependency detection
        let typeDefinitions = extractTypeDefinitions(from: context.syntax)

        for typeDef in typeDefinitions {
            if hasCircularTypeReference(typeDef, in: context) {
                let violation = ArchitecturalViolation(
                    severity: .medium, // Type circular dependencies are less severe than import cycles
                    rule: "General 1.2: Circular Type Dependencies",
                    context: context,
                    line: typeDef.lineNumber,
                    message: "Type '\(typeDef.name)' may have circular type dependencies",
                    recommendation: "Consider using protocols, dependency injection, or restructuring to break the circular reference",
                    metadata: [
                        "typeName": typeDef.name,
                        "typeKind": typeDef.kind
                    ]
                )
                violations.append(violation)
            }
        }

        return violations
    }

    // MARK: - Helper Methods

    private func extractImports(from syntax: SourceFileSyntax) -> [String] {
        var imports: [String] = []

        // Simplified import extraction - in real implementation would use proper AST traversal
        let sourceCode = syntax.description
        let lines = sourceCode.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
                let importModule = trimmed.dropFirst(7).trimmingCharacters(in: .whitespaces)
                imports.append(String(importModule))
            }
        }

        return imports
    }

    private func extractTypeDefinitions(from syntax: SourceFileSyntax) -> [TypeInfo] {
        var types: [TypeInfo] = []

        // Simplified type extraction - in real implementation would use proper AST traversal
        let sourceCode = syntax.description
        let lines = sourceCode.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("class ") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count > 1 {
                    let typeName = components[1].replacingOccurrences(of: ":", with: "")
                    types.append(TypeInfo(name: typeName, kind: "class", lineNumber: index + 1))
                }
            } else if trimmed.hasPrefix("struct ") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count > 1 {
                    let typeName = components[1].replacingOccurrences(of: ":", with: "")
                    types.append(TypeInfo(name: typeName, kind: "struct", lineNumber: index + 1))
                }
            } else if trimmed.hasPrefix("enum ") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count > 1 {
                    let typeName = components[1].replacingOccurrences(of: ":", with: "")
                    types.append(TypeInfo(name: typeName, kind: "enum", lineNumber: index + 1))
                }
            }
        }

        return types
    }

    private func isPotentialCircularImport(_ importModule: String, in context: SourceFileContext) -> Bool {
        // Simplified heuristic for potential circular import detection
        // In a real implementation, this would analyze the actual dependency graph

        let fileName = URL(fileURLWithPath: context.relativePath).deletingPathExtension().lastPathComponent

        // If import module name matches file name (case-insensitive), it might be circular
        return importModule.lowercased() == fileName.lowercased()
    }

    private func hasCircularTypeReference(_ type: TypeInfo, in context: SourceFileContext) -> Bool {
        // Simplified heuristic for circular type reference detection
        // In a real implementation, this would analyze the full type dependency graph

        // For now, return false as a placeholder
        return false
    }

    /// Validate multiple source file contexts for circular dependency violations
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

// MARK: - Supporting Types

private struct TypeInfo {
    let name: String
    let kind: String // "class", "struct", "enum"
    let lineNumber: Int
}

// MARK: - Convenience Methods

public extension GeneralRule_1_CircularDependencies {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = GeneralRule_1_CircularDependencies()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = GeneralRule_1_CircularDependencies()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = GeneralRule_1_CircularDependencies()
        return validator.validate(contexts: contexts)
    }
}