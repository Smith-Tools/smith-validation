// Tests/SmithValidationTests/TCAArchitecturalRules.swift
// TCA architectural rules implemented as Swift Tests

import Foundation
import Testing
import SmithValidationCore
import SwiftSyntax
import SwiftParser

@Suite("TCA Architectural Rules")
struct TCAArchitecturalRules {

    /// Test that TCA reducers have proper error handling
    @Test("Reducers should have error handling")
    func reducerErrorHandling() async throws {
        let sourceFiles = await getSourceFilesFromEnvironment()

        for file in sourceFiles {
            let violations = await analyzeForMissingErrorHandling(file)

            for violation in violations {
                Issue.record(
                    "Missing error handling in reducer: \(violation.description)",
                    sourceLocation: SourceLocation(fileURL: URL(fileURLWithPath: violation.file), line: violation.line),
                    associatedError: ArchitecturalViolation.critical(
                        rule: "TCA-Error-Handling",
                        file: violation.file,
                        line: violation.line,
                        message: "Action enum lacks error handling cases",
                        recommendation: "Add error-related action cases like 'errorOccurred(String)' or 'loadFailed(Error)' to handle async operation failures"
                    )
                )
            }
        }
    }

    /// Test that TCA features aren't monolithic
    @Test("Features should not be monolithic")
    func featureMonolithicCheck() async throws {
        let sourceFiles = await getSourceFilesFromEnvironment()

        for file in sourceFiles {
            let violations = await analyzeForMonolithicFeatures(file)

            for violation in violations {
                Issue.record(
                    "Monolithic feature detected: \(violation.description)",
                    sourceLocation: SourceLocation(fileURL: URL(fileURLWithPath: violation.file), line: violation.line),
                    associatedError: ArchitecturalViolation.high(
                        rule: "TCA-Monolithic-Features",
                        file: violation.file,
                        line: violation.line,
                        message: violation.description,
                        recommendation: "Consider extracting separate features. State structs should ideally have <15 properties."
                    )
                )
            }
        }
    }

    // MARK: - Private Analysis Methods

    private func getSourceFilesFromEnvironment() async -> [URL] {
        guard let projectPath = ProcessInfo.processInfo.environment["SMITH_PROJECT_PATH"] else {
            return []
        }

        do {
            return try FileUtils.findSwiftFiles(in: URL(fileURLWithPath: projectPath))
        } catch {
            return []
        }
    }

    private func analyzeForMissingErrorHandling(_ file: URL) async -> [ViolationInfo] {
        var violations: [ViolationInfo] = []

        do {
            let source = try String(contentsOf: file)
            let syntax = try Parser.parse(source: source)

            // Simple pattern matching for error handling in Actions
            let lines = source.components(separatedBy: .newlines)
            var hasErrorHandling = false

            for (index, line) in lines.enumerated() {
                if line.contains("enum Action") || line.contains("enum Actions") {
                    // Look for error-related cases in the following lines
                    let actionBlock = lines.dropFirst(index).prefix(20)
                    hasErrorHandling = actionBlock.contains { actionLine in
                        actionLine.lowercased().contains("error") ||
                        actionLine.lowercased().contains("failure") ||
                        actionLine.lowercased().contains("failed")
                    }

                    if !hasErrorHandling {
                        violations.append(ViolationInfo(
                            file: file.path,
                            line: index + 1,
                            description: "Action enum lacks error handling cases"
                        ))
                    }
                    break
                }
            }
        } catch {
            // Skip files that can't be parsed
        }

        return violations
    }

    private func analyzeForMonolithicFeatures(_ file: URL) async -> [ViolationInfo] {
        var violations: [ViolationInfo] = []

        do {
            let source = try String(contentsOf: file)
            let syntax = try Parser.parse(source: source)

            // Simple pattern matching for state and action complexity
            let lines = source.components(separatedBy: .newlines)

            // Look for State structs with too many properties
            for (index, line) in lines.enumerated() {
                if line.contains("struct State") || line.contains("struct") && line.contains("State") {
                    // Count properties in this struct
                    let structBlock = lines.dropFirst(index)
                    var propertyCount = 0
                    var braceDepth = 0

                    for blockLine in structBlock {
                        if blockLine.contains("{") {
                            braceDepth += 1
                        } else if blockLine.contains("}") {
                            braceDepth -= 1
                            if braceDepth == 0 { break }
                        } else if braceDepth == 1 && (blockLine.contains("var ") || blockLine.contains("let ")) {
                            propertyCount += 1
                        }
                    }

                    if propertyCount > 15 {
                        violations.append(ViolationInfo(
                            file: file.path,
                            line: index + 1,
                            description: "State struct has \(propertyCount) properties (threshold: 15)"
                        ))
                    }
                }
            }
        } catch {
            // Skip files that can't be parsed
        }

        return violations
    }
}

// MARK: - Supporting Types

private struct ViolationInfo {
    let file: String
    let line: Int
    let description: String
}