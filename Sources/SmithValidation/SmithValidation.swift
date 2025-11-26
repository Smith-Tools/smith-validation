// SmithValidation.swift
// High-level validation library providing easy access to SmithValidationCore functionality

import Foundation
import SmithValidationCore
import Testing
import PklSwift

/// Main SmithValidation library entry point
public struct SmithValidation {

    /// Validate a Swift project using default configuration
    /// - Parameter projectPath: Path to the Swift project to validate
    /// - Returns: Validation results
    public static func validate(projectPath: String) async throws -> ViolationCollection {
        // TODO: Implement full validation engine
        // For now, return empty violation collection
        return ViolationCollection(violations: [])
    }

    /// Validate using PKL configuration
    /// - Parameters:
    ///   - projectPath: Path to the Swift project
    ///   - configPath: Path to the PKL configuration file
    /// - Returns: Validation results
    public static func validateWithConfig(
        projectPath: String,
        configPath: String
    ) async throws -> ViolationCollection {
        // TODO: Implement PKL configuration loading
        return ViolationCollection(violations: [])
    }

    /// Run Swift Testing based validation
    /// - Parameter projectPath: Path to validate
    /// - Returns: Test results
    public static func runTests(projectPath: String) async throws -> TestRun {
        // TODO: Implement Swift Testing integration
        return TestRun(
            projectPath: projectPath,
            status: .completed,
            violations: []
        )
    }

    // MARK: - Private Helpers

    private static func findSwiftFiles(in projectPath: String) throws -> [URL] {
        var files: [URL] = []

        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: projectPath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return files }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" && !fileURL.path.contains(".build") {
                files.append(fileURL)
            }
        }

        return files
    }
}

// MARK: - Supporting Types

public struct TestRun {
    public let projectPath: String
    public let status: TestStatus
    public let violations: [ArchitecturalViolation]

    public enum TestStatus {
        case running
        case completed
        case failed(String)
    }
}