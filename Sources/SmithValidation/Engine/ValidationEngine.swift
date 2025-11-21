// Engine/ValidationEngine.swift
// Core validation engine that orchestrates rule execution

import Foundation
import SmithValidationCore
import SwiftSyntax

/// Main validation engine that executes rules against files and directories
public class ValidationEngine: ValidationEngineProtocol {

    /// Configuration for validation engine behavior
    public struct Configuration {
        public let enableCaching: Bool
        public let enableParallelExecution: Bool
        public let maxConcurrentValidations: Int
        public let timeoutPerFile: TimeInterval

        public init(
            enableCaching: Bool = true,
            enableParallelExecution: Bool = false,
            maxConcurrentValidations: Int = 4,
            timeoutPerFile: TimeInterval = 30.0
        ) {
            self.enableCaching = enableCaching
            self.enableParallelExecution = enableParallelExecution
            self.maxConcurrentValidations = maxConcurrentValidations
            self.timeoutPerFile = timeoutPerFile
        }
    }

    private let configuration: Configuration
    private var parseCache: [String: SourceFileContext] = [:]

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single file with multiple rules
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - filePath: Path to the file to validate
    /// - Returns: Combined violation collection from all rules
    /// - Throws: ValidationError for file processing errors
    public func validate(rules: [any ValidatableRule], filePath: String) throws -> ViolationCollection {
        let context = try parseFile(filePath: filePath)
        return validate(rules: rules, context: context)
    }

    /// Validate multiple files with multiple rules
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - filePaths: Array of file paths to validate
    /// - Returns: Combined violation collection from all rules and files
    /// - Throws: ValidationError for file processing errors
    public func validate(rules: [any ValidatableRule], filePaths: [String]) throws -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for filePath in filePaths {
            let fileViolations = try validate(rules: rules, filePath: filePath)
            allViolations.append(contentsOf: fileViolations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    /// Validate a directory with multiple rules
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - directory: Directory path to validate
    ///   - recursive: Whether to search recursively in subdirectories
    /// - Returns: Combined violation collection from all rules and files
    /// - Throws: ValidationError for directory processing errors
    public func validate(
        rules: [any ValidatableRule],
        directory: String,
        recursive: Bool = true
    ) throws -> ViolationCollection {
        let swiftFiles = try FileUtils.findSwiftFiles(in: URL(fileURLWithPath: directory))
        let filePaths = swiftFiles.map { $0.path }

        return try validate(rules: rules, filePaths: filePaths)
    }

    /// Validate with parsed context for performance
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - context: Pre-parsed source file context
    /// - Returns: Combined violation collection from all rules
    public func validate(rules: [any ValidatableRule], context: SourceFileContext) -> ViolationCollection {
        var allViolations: [ArchitecturalViolation] = []

        for rule in rules {
            let violations = rule.validate(context: context)
            allViolations.append(contentsOf: violations.violations)
        }

        return ViolationCollection(violations: allViolations)
    }

    /// Get statistics about validation performance
    /// - Returns: Validation statistics
    public func getStatistics() -> ValidationStatistics {
        return ValidationStatistics(
            cacheHits: parseCache.count,
            cacheSize: parseCache.count,
            cachingEnabled: configuration.enableCaching
        )
    }

    /// Clear the parsing cache
    public func clearCache() {
        parseCache.removeAll()
    }

    // MARK: - Private Methods

    /// Parse a file and return source context (with caching if enabled)
    /// - Parameter filePath: Path to the Swift file
    /// - Returns: Parsed source file context
    /// - Throws: ValidationError for parsing errors
    private func parseFile(filePath: String) throws -> SourceFileContext {
        let fileURL = URL(fileURLWithPath: filePath)

        // Check cache first if enabled
        if configuration.enableCaching {
            if let cachedContext = parseCache[filePath] {
                return cachedContext
            }
        }

        // Parse the file
        do {
            let syntax = try SourceFileSyntax.parse(from: fileURL)
            let context = SourceFileContext(path: filePath, url: fileURL, syntax: syntax)

            // Cache the result if enabled
            if configuration.enableCaching {
                parseCache[filePath] = context
            }

            return context
        } catch {
            throw ValidationError.parsingError(error)
        }
    }
}

/// Statistics about validation engine performance
public struct ValidationStatistics {
    public let cacheHits: Int
    public let cacheSize: Int
    public let cachingEnabled: Bool

    public init(cacheHits: Int, cacheSize: Int, cachingEnabled: Bool) {
        self.cacheHits = cacheHits
        self.cacheSize = cacheSize
        self.cachingEnabled = cachingEnabled
    }
}

/// Protocol for validation engines (allows for future extensibility)
public protocol ValidationEngineProtocol {
    func validate(rules: [any ValidatableRule], filePath: String) throws -> ViolationCollection
    func validate(rules: [any ValidatableRule], filePaths: [String]) throws -> ViolationCollection
    func validate(rules: [any ValidatableRule], directory: String, recursive: Bool) throws -> ViolationCollection
}