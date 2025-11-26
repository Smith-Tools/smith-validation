// Frameworks/TCA/Rule_1_1_MonolithicFeatures.swift
// TCA Rule 1.1: Monolithic Features validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 1.1: Monolithic Features Validator
///
/// Detects:
/// - State structs with >15 properties (threshold for monolithic features)
/// - Action enums with >40 cases (threshold for monolithic features)
///
/// Rationale:
/// - Large State structs indicate multiple features crammed into one reducer
/// - Large Action enums suggest too much responsibility in a single feature
/// - Both patterns lead to maintenance issues and testing complexity
public struct TCARule_1_1_MonolithicFeatures: ValidatableRule {

    public struct Configuration {
        public let maxStateProperties: Int
        public let maxActionCases: Int
        public let severity: ArchitecturalViolation.Severity

        public init(
            maxStateProperties: Int = 15,
            maxActionCases: Int = 40,
            severity: ArchitecturalViolation.Severity = .high
        ) {
            self.maxStateProperties = maxStateProperties
            self.maxActionCases = maxActionCases
            self.severity = severity
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for monolithic feature violations
    /// - Parameter context: The source file context with path information
    /// - Returns: Collection of architectural violations
    public func validate(context: SourceFileContext) -> ViolationCollection {
        var violations: [ArchitecturalViolation] = []

        // Find all TCA reducers in the file
        let reducers = context.syntax.findTCAReducers()

        for reducer in reducers {
            // Validate State struct
            if let stateStruct = reducer.findNestedStruct(named: "State") {
                violations.append(contentsOf: validateStateStruct(stateStruct, in: context))
            }

            // Validate Action enum
            if let actionEnum = reducer.findNestedEnum(named: "Action") {
                violations.append(contentsOf: validateActionEnum(actionEnum, in: context))
            }
        }

        return ViolationCollection(violations: violations)
    }

    /// Validate a single Swift file for monolithic feature violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for monolithic feature violations
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

    private func validateStateStruct(_ state: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        if state.propertyCount > configuration.maxStateProperties {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.1: Monolithic Features (State Size)",
                context: context,
                line: state.lineNumber,
                message: "State struct has \(state.propertyCount) properties (threshold: \(configuration.maxStateProperties))",
                recommendation: "Consider extracting separate features. State structs should ideally have <\(configuration.maxStateProperties) properties.",
                metadata: [
                    "propertyCount": "\(state.propertyCount)",
                    "threshold": "\(configuration.maxStateProperties)",
                    "excess": "\(state.propertyCount - configuration.maxStateProperties)"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func validateActionEnum(_ action: EnumInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        if action.caseCount > configuration.maxActionCases {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.1: Monolithic Features (Action Size)",
                context: context,
                line: action.lineNumber,
                message: "Action enum has \(action.caseCount) cases (threshold: \(configuration.maxActionCases))",
                recommendation: "Consider splitting into multiple features. Action enums should ideally have <\(configuration.maxActionCases) cases.",
                metadata: [
                    "caseCount": "\(action.caseCount)",
                    "threshold": "\(configuration.maxActionCases)",
                    "excess": "\(action.caseCount - configuration.maxActionCases)"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    /// Validate multiple source file contexts for monolithic feature violations
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

public extension TCARule_1_1_MonolithicFeatures {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_1_1_MonolithicFeatures()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_1_1_MonolithicFeatures()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = TCARule_1_1_MonolithicFeatures()
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

    /// Find all Swift files in a directory recursively
    /// - Parameter directory: Directory URL to search
    /// - Returns: Array of Swift file URLs
    /// - Throws: File system errors
    private static func findSwiftFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else {
            throw ValidationError.directoryNotFound(directory)
        }

        var swiftFiles: [URL] = []

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
        let directoryEnumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        for case let fileURL as URL in directoryEnumerator! {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }

            if resourceValues.isDirectory == true {
                // Recursively search subdirectories
                swiftFiles.append(contentsOf: try findSwiftFiles(in: fileURL))
            } else if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }
}

// MARK: - Error Types

public enum ValidationError: Error, LocalizedError {
    case directoryNotFound(URL)
    case fileNotFound(URL)
    case parsingError(Error)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let url):
            return "Directory not found: \(url.path)"
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .parsingError(let error):
            return "Parsing error: \(error.localizedDescription)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}