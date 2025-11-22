// Frameworks/TCA/Rule_1_3_CodeDuplication.swift
// TCA Rule 1.3: Code Duplication validation

import Foundation
import SmithValidationCore
import SwiftSyntax

/// TCA Rule 1.3: Code Duplication Validator
///
/// Detects real TCA code duplication anti-patterns that impact maintainability:
/// - Duplicate action handlers with similar logic
/// - Repeated state transformations across cases
/// - Similar async operation patterns
///
/// Rationale:
/// - Code duplication creates maintenance burden
/// - Changes must be made in multiple places
/// - Increases risk of inconsistencies and bugs
/// - Violates DRY principles in TCA reducers
public struct TCARule_1_3_CodeDuplication: ValidatableRule {

    public struct Configuration {
        public let severity: ArchitecturalViolation.Severity
        public let similarityThreshold: Double
        public let minLineCountForComparison: Int
        public let detectDuplicateAsyncPatterns: Bool

        public init(
            severity: ArchitecturalViolation.Severity = .medium,
            similarityThreshold: Double = 0.75, // 75% similarity threshold
            minLineCountForComparison: Int = 3,   // Minimum lines to consider for comparison
            detectDuplicateAsyncPatterns: Bool = true
        ) {
            self.severity = severity
            self.similarityThreshold = similarityThreshold
            self.minLineCountForComparison = minLineCountForComparison
            self.detectDuplicateAsyncPatterns = detectDuplicateAsyncPatterns
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Validate a single Swift file context for code duplication violations
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

    /// Validate a single Swift file for code duplication violations
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    public func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        // Create a dummy context for backward compatibility
        let context = SourceFileContext(path: "<unknown>", url: URL(fileURLWithPath: "/unknown"), syntax: sourceFile)
        return validate(context: context)
    }

    /// Validate multiple files for code duplication violations
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

    /// Validate multiple source file contexts for code duplication violations
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

    // MARK: - Private Validation Methods

    private func validateReducer(_ reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        // Find the body property and analyze switch statements
        let bodyAnalyzer = ReducerBodyAnalyzer()
        bodyAnalyzer.analyze(reducer.syntax)

        // Detect duplicate action handlers
        violations.append(contentsOf: detectDuplicateActionHandlers(bodyAnalyzer, reducer: reducer, in: context))

        // Detect duplicate state transformations
        violations.append(contentsOf: detectDuplicateStateTransformations(bodyAnalyzer, reducer: reducer, in: context))

        // Detect duplicate async patterns
        if configuration.detectDuplicateAsyncPatterns {
            violations.append(contentsOf: detectDuplicateAsyncPatterns(bodyAnalyzer, reducer: reducer, in: context))
        }

        return violations
    }

    private func detectDuplicateActionHandlers(_ analyzer: ReducerBodyAnalyzer, reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        for duplicateGroup in analyzer.duplicateActionHandlers {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.3: Duplicate Action Handlers",
                context: context,
                line: duplicateGroup.firstLineNumber,
                message: "Found duplicate logic in action handlers: \(duplicateGroup.caseNames.joined(separator: ", "))",
                recommendation: "Extract common logic into a private helper method or reuse the same action case.",
                metadata: [
                    "duplicateCases": duplicateGroup.caseNames.joined(separator: ","),
                    "similarity": "\(Int(duplicateGroup.similarity * 100))%",
                    "reducerName": reducer.name,
                    "impact": "Maintenance burden and inconsistency risk"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func detectDuplicateStateTransformations(_ analyzer: ReducerBodyAnalyzer, reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        for duplicateGroup in analyzer.duplicateStateTransformations {
            let violation = ArchitecturalViolation(
                severity: configuration.severity,
                rule: "TCA 1.3: Duplicate State Transformations",
                context: context,
                line: duplicateGroup.firstLineNumber,
                message: "Found duplicate state transformation logic in: \(duplicateGroup.caseNames.joined(separator: ", "))",
                recommendation: "Extract common state transformation into a helper method or consolidate action cases.",
                metadata: [
                    "duplicateCases": duplicateGroup.caseNames.joined(separator: ","),
                    "similarity": "\(Int(duplicateGroup.similarity * 100))%",
                    "reducerName": reducer.name,
                    "impact": "State mutation inconsistency"
                ]
            )
            violations.append(violation)
        }

        return violations
    }

    private func detectDuplicateAsyncPatterns(_ analyzer: ReducerBodyAnalyzer, reducer: StructInfo, in context: SourceFileContext) -> [ArchitecturalViolation] {
        var violations: [ArchitecturalViolation] = []

        for duplicateGroup in analyzer.duplicateAsyncPatterns {
            let violation = ArchitecturalViolation(
                severity: .low, // Lower severity for async patterns
                rule: "TCA 1.3: Duplicate Async Patterns",
                context: context,
                line: duplicateGroup.firstLineNumber,
                message: "Found duplicate async operation patterns in: \(duplicateGroup.caseNames.joined(separator: ", "))",
                recommendation: "Create a shared async operation helper or consolidate the async logic.",
                metadata: [
                    "duplicateCases": duplicateGroup.caseNames.joined(separator: ","),
                    "patternType": duplicateGroup.patternType,
                    "reducerName": reducer.name,
                    "impact": "Code duplication in async operations"
                ]
            )
            violations.append(violation)
        }

        return violations
    }
}

// MARK: - Convenience Methods

public extension TCARule_1_3_CodeDuplication {

    /// Quick validation using default configuration
    /// - Parameter sourceFile: The Swift file to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFile: SourceFileSyntax) -> ViolationCollection {
        let validator = TCARule_1_3_CodeDuplication()
        return validator.validate(sourceFile: sourceFile)
    }

    /// Quick validation using default configuration for multiple files
    /// - Parameter sourceFiles: Array of Swift files to validate
    /// - Returns: Collection of architectural violations
    static func validate(sourceFiles: [SourceFileSyntax]) -> ViolationCollection {
        let validator = TCARule_1_3_CodeDuplication()
        return validator.validate(sourceFiles: sourceFiles)
    }

    /// Validate multiple source file contexts
    /// - Parameter contexts: Array of source file contexts with path information
    /// - Returns: Collection of architectural violations
    static func validate(contexts: [SourceFileContext]) -> ViolationCollection {
        let validator = TCARule_1_3_CodeDuplication()
        return validator.validate(contexts: contexts)
    }

    /// Validate a project directory
    /// - Parameter directoryURL: Directory URL containing Swift files
    /// - Returns: Collection of architectural violations
    /// - Throws: File system errors
    static func validate(directory: URL) throws -> ViolationCollection {
        let swiftFiles = try findSwiftFiles(in: directory)
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

// MARK: - Analysis Helper Classes

/// Analyzes TCA reducer body for code duplication patterns
private class ReducerBodyAnalyzer {
    struct DuplicateGroup {
        let caseNames: [String]
        let similarity: Double
        let firstLineNumber: Int
        let pattern: [String]
    }

    var duplicateActionHandlers: [DuplicateGroup] = []
    var duplicateStateTransformations: [DuplicateGroup] = []
    var duplicateAsyncPatterns: [AsyncPatternGroup] = []

    func analyze(_ syntax: StructDeclSyntax) {
        let visitor = ReducerBodyVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntax)

        if let bodyProperty = visitor.bodyProperty {
            analyzeReducerBody(bodyProperty)
        }
    }

    private func analyzeReducerBody(_ bodyProperty: VariableDeclSyntax) {
        guard let binding = bodyProperty.bindings.first,
              let closureExpr = binding.initializer?.value.as(ClosureExprSyntax.self) else { return }

        let switchAnalyzer = SwitchStatementAnalyzer()
        switchAnalyzer.analyze(closureExpr)

        // Analyze for duplicate patterns
        findDuplicateActionHandlers(switchAnalyzer)
        findDuplicateStateTransformations(switchAnalyzer)
        findDuplicateAsyncPatterns(switchAnalyzer)
    }

    private func findDuplicateActionHandlers(_ analyzer: SwitchStatementAnalyzer) {
        let actionHandlers = analyzer.actionHandlers

        for i in 0..<actionHandlers.count {
            for j in (i + 1)..<actionHandlers.count {
                let similarity = calculateSimilarity(
                    actionHandlers[i].normalizedLogic,
                    actionHandlers[j].normalizedLogic
                )

                if similarity > 0.75 { // 75% similarity threshold
                    let group = DuplicateGroup(
                        caseNames: [
                            actionHandlers[i].caseName,
                            actionHandlers[j].caseName
                        ],
                        similarity: similarity,
                        firstLineNumber: actionHandlers[i].lineNumber,
                        pattern: actionHandlers[i].normalizedLogic
                    )
                    duplicateActionHandlers.append(group)
                }
            }
        }
    }

    private func findDuplicateStateTransformations(_ analyzer: SwitchStatementAnalyzer) {
        let stateTransformations = analyzer.stateTransformations

        for i in 0..<stateTransformations.count {
            for j in (i + 1)..<stateTransformations.count {
                let similarity = calculateSimilarity(
                    stateTransformations[i].transformations,
                    stateTransformations[j].transformations
                )

                if similarity > 0.75 { // 75% similarity threshold
                    let group = DuplicateGroup(
                        caseNames: [
                            stateTransformations[i].caseName,
                            stateTransformations[j].caseName
                        ],
                        similarity: similarity,
                        firstLineNumber: stateTransformations[i].lineNumber,
                        pattern: stateTransformations[i].transformations
                    )
                    duplicateStateTransformations.append(group)
                }
            }
        }
    }

    private func findDuplicateAsyncPatterns(_ analyzer: SwitchStatementAnalyzer) {
        let asyncPatterns = analyzer.asyncPatterns

        for i in 0..<asyncPatterns.count {
            for j in (i + 1)..<asyncPatterns.count {
                if asyncPatterns[i].patternType == asyncPatterns[j].patternType {
                    let group = AsyncPatternGroup(
                        caseNames: [
                            asyncPatterns[i].caseName,
                            asyncPatterns[j].caseName
                        ],
                        patternType: asyncPatterns[i].patternType,
                        firstLineNumber: asyncPatterns[i].lineNumber
                    )
                    duplicateAsyncPatterns.append(group)
                }
            }
        }
    }

    private func calculateSimilarity(_ code1: [String], _ code2: [String]) -> Double {
        guard !code1.isEmpty && !code2.isEmpty else { return 0.0 }

        let set1 = Set(code1)
        let set2 = Set(code2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)

        return Double(intersection.count) / Double(union.count)
    }
}

struct AsyncPatternGroup {
    let caseNames: [String]
    let patternType: String
    let firstLineNumber: Int
}

/// Visits TCA reducer structure to find the body property
private class ReducerBodyVisitor: SyntaxVisitor {
    var bodyProperty: VariableDeclSyntax?

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if let identifier = node.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier,
           identifier.text.trimmingCharacters(in: .whitespacesAndNewlines) == "body" {
            bodyProperty = node
            return .skipChildren
        }
        return .visitChildren
    }
}

/// Analyzes switch statements within TCA reducers
private class SwitchStatementAnalyzer {
    struct ActionHandler {
        let caseName: String
        let lineNumber: Int
        let normalizedLogic: [String]
    }

    struct StateTransformation {
        let caseName: String
        let lineNumber: Int
        let transformations: [String]
    }

    struct AsyncPattern {
        let caseName: String
        let lineNumber: Int
        let patternType: String
    }

    var actionHandlers: [ActionHandler] = []
    var stateTransformations: [StateTransformation] = []
    var asyncPatterns: [AsyncPattern] = []

    func analyze(_ closureExpr: ClosureExprSyntax) {
        let visitor = SwitchStatementVisitor(viewMode: .sourceAccurate)
        visitor.walk(closureExpr)

        actionHandlers = visitor.actionHandlers
        stateTransformations = visitor.stateTransformations
        asyncPatterns = visitor.asyncPatterns
    }
}

/// Visits switch statements to extract code patterns
private class SwitchStatementVisitor: SyntaxVisitor {
    var actionHandlers: [SwitchStatementAnalyzer.ActionHandler] = []
    var stateTransformations: [SwitchStatementAnalyzer.StateTransformation] = []
    var asyncPatterns: [SwitchStatementAnalyzer.AsyncPattern] = []

    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        for caseItem in node.cases {
            if let switchCase = caseItem.as(SwitchCaseSyntax.self) {
                analyzeSwitchCase(switchCase)
            }
        }
        return .skipChildren
    }

    private func analyzeSwitchCase(_ caseItem: SwitchCaseSyntax) {
        guard let caseLabel = caseItem.label.as(SwitchCaseLabelSyntax.self) else { return }

        let caseName = caseLabel.caseItems.first?.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
        let lineNumber = getLineNumber(from: caseItem)

        // Extract statements from the case
        var statements: [String] = []
        var transformations: [String] = []

        for statement in caseItem.statements {
            let statementText = statement.description.trimmingCharacters(in: .whitespacesAndNewlines)
            statements.append(statementText)

            // Look for state mutations
            if statementText.contains("state.") || statementText.contains("var ") {
                transformations.append(statementText)
            }

            // Look for async patterns
            if statementText.contains(".run") || statementText.contains("await") {
                let patternType = detectAsyncPatternType(statementText)
                let asyncPattern = SwitchStatementAnalyzer.AsyncPattern(
                    caseName: caseName,
                    lineNumber: lineNumber,
                    patternType: patternType
                )
                asyncPatterns.append(asyncPattern)
            }
        }

        if statements.count >= 3 { // Only consider cases with substantial logic
            let normalizedLogic = normalizeCode(statements)

            let actionHandler = SwitchStatementAnalyzer.ActionHandler(
                caseName: caseName,
                lineNumber: lineNumber,
                normalizedLogic: normalizedLogic
            )
            actionHandlers.append(actionHandler)

            if !transformations.isEmpty {
                let stateTransform = SwitchStatementAnalyzer.StateTransformation(
                    caseName: caseName,
                    lineNumber: lineNumber,
                    transformations: transformations
                )
                stateTransformations.append(stateTransform)
            }
        }
    }

    private func normalizeCode(_ statements: [String]) -> [String] {
        return statements
            .map { statement in
                // Normalize by removing variable names, literals, and whitespace variations
                statement
                    .replacingOccurrences(of: "\\b\\w+\\.", with: "obj.", options: .regularExpression)
                    .replacingOccurrences(of: "\"[^\"]*\"", with: "\"LITERAL\"", options: .regularExpression)
                    .replacingOccurrences(of: "\\d+", with: "NUM", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty }
    }

    private func detectAsyncPatternType(_ statement: String) -> String {
        if statement.contains("fetch") || statement.contains("load") {
            return "DataFetch"
        } else if statement.contains("save") || statement.contains("store") {
            return "DataSave"
        } else if statement.contains("send") {
            return "ActionSend"
        } else {
            return "GenericAsync"
        }
    }

    private func getLineNumber(from node: some SyntaxProtocol) -> Int {
        let source = node.root.description
        let position = node.position.utf8Offset
        let substring = String(source.prefix(position))
        return substring.components(separatedBy: .newlines).count
    }
}