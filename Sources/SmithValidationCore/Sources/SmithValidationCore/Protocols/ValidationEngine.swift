// Protocols/ValidationEngine.swift
// Protocol for validation engines that execute rules

import Foundation

/// Protocol for validation engines that can execute rules against files
public protocol ValidationEngine {
    /// Validate a single file with multiple rules
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - filePath: Path to the file to validate
    /// - Returns: Combined violation collection from all rules
    func validate(rules: [any ValidatableRule], filePath: String) -> ViolationCollection

    /// Validate multiple files with multiple rules
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - filePaths: Array of file paths to validate
    /// - Returns: Combined violation collection from all rules and files
    func validate(rules: [any ValidatableRule], filePaths: [String]) -> ViolationCollection

    /// Validate a directory with multiple rules
    /// - Parameters:
    ///   - rules: Array of rules to execute
    ///   - directory: Directory path to validate
    ///   - recursive: Whether to search recursively in subdirectories
    /// - Returns: Combined violation collection from all rules and files
    func validate(rules: [any ValidatableRule], directory: String, recursive: Bool) throws -> ViolationCollection
}