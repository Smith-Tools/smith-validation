// Sources/smith-validation/main.swift
// Lightweight SwiftSyntax-free CLI with AI-optimized JSON output

import Foundation

/// Simple CLI interface for AI agents - NO SwiftSyntax dependency!
@main
struct SmithValidationCLI {
    static func main() async {
        let args = CommandLine.arguments

        guard args.count == 2 else {
            print(jsonError("Usage: smith-validation <project-path>"))
            return
        }

        let projectPath = args[1]
        let projectURL = URL(fileURLWithPath: projectPath)

        // Validate project exists
        guard FileManager.default.fileExists(atPath: projectPath) else {
            print(jsonError("Project path does not exist: \(projectPath)"))
            return
        }

        // Run lightweight architectural analysis
        let result = await runLightweightAnalysis(projectURL: projectURL)

        // Output AI-optimized JSON
        print(result.asJSON())
    }

    private static func runLightweightAnalysis(projectURL: URL) async -> AIValidationResult {
        let startTime = Date()

        // Find Swift files using file system only
        let swiftFiles = findSwiftFiles(in: projectURL)

        // Analyze files using regex patterns (NO SwiftSyntax!)
        let findings = analyzeFiles(swiftFiles)

        let duration = Date().timeIntervalSince(startTime)

        // Convert to AI-usable format
        return AIValidationResult(
            projectPath: projectURL.path,
            totalFiles: swiftFiles.count,
            findings: findings,
            duration: duration
        )
    }

    /// Find Swift files using file system operations
    private static func findSwiftFiles(in directory: URL) -> [URL] {
        var swiftFiles: [URL] = []

        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return swiftFiles
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }

    /// Analyze Swift files using regex patterns - FAST and lightweight
    private static func analyzeFiles(_ files: [URL]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        for file in files {
            do {
                let content = try String(contentsOf: file)
                let fileFindings = analyzeFile(content: content, file: file)
                findings.append(contentsOf: fileFindings)
            } catch {
                // Skip files that can't be read
            }
        }

        return findings
    }

    /// Fast regex-based file analysis
    private static func analyzeFile(content: String, file: URL) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []
        let lines = content.components(separatedBy: .newlines)

        // Rule 1: TCA Error Handling Analysis
        findings.append(contentsOf: analyzeTCAErrorHandling(content: content, file: file, lines: lines))

        // Rule 2: Monolithic Features Analysis
        findings.append(contentsOf: analyzeMonolithicFeatures(content: content, file: file, lines: lines))

        // Rule 3: SwiftUI View Analysis
        findings.append(contentsOf: analyzeSwiftUIViews(content: content, file: file, lines: lines))

        // Rule 4: General Architecture Analysis
        findings.append(contentsOf: analyzeGeneralArchitecture(content: content, file: file, lines: lines))

        return findings
    }

    /// TCA Error Handling Analysis - FAST regex pattern matching
    private static func analyzeTCAErrorHandling(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // Find Action enums
        let actionEnumPattern = #"(?s)enum\s+(?:Action|Actions)\s*\{.*?\}"#
        let actionEnumRegex = try? NSRegularExpression(pattern: actionEnumPattern, options: [])

        let actionEnumMatches = actionEnumRegex?.matches(in: content, range: NSRange(content.startIndex..., in: content))

        for match in actionEnumMatches ?? [] {
            guard let range = Range(match.range, in: content) else { continue }

            let actionEnumContent = String(content[range])
            let lineNumber = content.prefix(upTo: range.lowerBound).components(separatedBy: .newlines).count

            // Check for error handling patterns
            let hasErrorHandling = actionEnumContent.contains("case.*error") ||
                                  actionEnumContent.contains("case.*failure") ||
                                  actionEnumContent.contains("case.*failed")

            if !hasErrorHandling {
                findings.append(ArchitecturalFinding(
                    ruleName: "TCA-Error-Handling",
                    severity: .critical,
                    file: file.path,
                    line: lineNumber,
                    message: "Action enum lacks error handling cases",
                    suggestion: "Add error-related action cases like 'errorOccurred(String)' or 'loadFailed(Error)' to handle async operation failures",
                    automationConfidence: 0.88
                ))
            }
        }

        return findings
    }

    /// Monolithic Features Analysis - FAST counting
    private static func analyzeMonolithicFeatures(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // Find State structs with too many properties
        for (index, line) in lines.enumerated() {
            if line.contains("struct") && line.contains("State") {
                let structStartIndex = index
                var propertyCount = 0
                var braceCount = 0
                var inStruct = false

                // Simple state counting - no SwiftSyntax needed
                for structLine in lines.dropFirst(structStartIndex) {
                    if structLine.contains("{") {
                        braceCount += 1
                        inStruct = true
                    } else if structLine.contains("}") {
                        braceCount -= 1
                        if braceCount == 0 {
                            break
                        }
                    } else if inStruct && (structLine.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("var ") ||
                                   structLine.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("let ")) {
                        propertyCount += 1
                    }
                }

                if propertyCount > 15 {
                    findings.append(ArchitecturalFinding(
                        ruleName: "TCA-Monolithic-Features",
                        severity: .high,
                        file: file.path,
                        line: index + 1,
                        message: "State struct has \(propertyCount) properties (threshold: 15)",
                        suggestion: "Consider extracting separate features. State structs should ideally have <15 properties.",
                        automationConfidence: 0.75
                    ))
                }
            }

            // Find Action enums with too many cases
            if line.contains("enum") && line.contains("Action") {
                let enumStartIndex = index
                var caseCount = 0
                var braceCount = 0
                var inEnum = false

                for enumLine in lines.dropFirst(enumStartIndex) {
                    if enumLine.contains("{") {
                        braceCount += 1
                        inEnum = true
                    } else if enumLine.contains("}") {
                        braceCount -= 1
                        if braceCount == 0 {
                            break
                        }
                    } else if inEnum && enumLine.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("case ") {
                        caseCount += 1
                    }
                }

                if caseCount > 40 {
                    findings.append(ArchitecturalFinding(
                        ruleName: "TCA-Monolithic-Features",
                        severity: .high,
                        file: file.path,
                        line: index + 1,
                        message: "Action enum has \(caseCount) cases (threshold: 40)",
                        suggestion: "Consider splitting into multiple features. Action enums should ideally have <40 cases.",
                        automationConfidence: 0.70
                    ))
                }
            }
        }

        return findings
    }

    /// SwiftUI View Analysis
    private static func analyzeSwiftUIViews(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        for (index, line) in lines.enumerated() {
            // Find View structs with complex body
            if line.contains("struct") && (line.contains("View") || file.lastPathComponent.contains("View")) {
                let viewStartIndex = index
                var bodyLineCount = 0
                var inViewBody = false

                for viewLine in lines.dropFirst(viewStartIndex) {
                    if viewLine.contains("var body:") {
                        inViewBody = true
                        continue
                    }

                    if inViewBody {
                        bodyLineCount += 1

                        // Count until we hit the next property or end of struct
                        if viewLine.contains("var ") || viewLine.contains("func ") || viewLine.contains("}") {
                            break
                        }
                    }
                }

                if bodyLineCount > 50 {
                    findings.append(ArchitecturalFinding(
                        ruleName: "SwiftUI-View-Complexity",
                        severity: .medium,
                        file: file.path,
                        line: index + 1,
                        message: "View body has \(bodyLineCount) lines (threshold: 50)",
                        suggestion: "Extract complex UI components into separate views to improve maintainability.",
                        automationConfidence: 0.65
                    ))
                }
            }
        }

        return findings
    }

    /// General Architecture Analysis
    private static func analyzeGeneralArchitecture(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // Simple pattern analysis for common issues
        let linesWithImports = lines.filter { $0.hasPrefix("import ") }

        // Too many imports might indicate high coupling
        if linesWithImports.count > 15 {
            findings.append(ArchitecturalFinding(
                ruleName: "General-High-Coupling",
                severity: .medium,
                file: file.path,
                line: 1,
                message: "File has \(linesWithImports.count) imports (threshold: 15)",
                suggestion: "Consider reducing dependencies or using dependency injection to lower coupling.",
                automationConfidence: 0.60
            ))
        }

        return findings
    }

    private static func jsonError(_ message: String) -> String {
        return """
        {
            "error": "\(message)"
        }
        """
    }
}

// MARK: - AI-Optimized Data Structures

/// AI-usable validation result
public struct AIValidationResult: Codable {
    let projectPath: String
    let metadata: Metadata
    let summary: Summary
    let priorityActions: [PriorityAction]
    let decisionMetrics: DecisionMetrics

    init(projectPath: String, totalFiles: Int, findings: [ArchitecturalFinding], duration: TimeInterval) {
        self.projectPath = projectPath
        self.metadata = Metadata(
            version: "1.0.10",
            timestamp: Date(),
            filesAnalyzed: totalFiles,
            duration: duration
        )

        self.summary = Summary(
            healthScore: calculateHealthScore(findings),
            violationsCount: findings.count,
            criticalIssues: findings.filter { $0.severity == .critical }.count,
            automatableFixes: findings.filter { $0.automationConfidence > 0.8 }.count
        )

        let criticalAndHigh = findings.filter {
            $0.severity == .critical || $0.severity == .high
        }
        self.priorityActions = criticalAndHigh.map { PriorityAction(from: $0) }
            .sorted { $0.automationConfidence > $1.automationConfidence }

        self.decisionMetrics = DecisionMetrics(
            refactoringROI: calculateROI(findings),
            techDebtScore: calculateTechDebt(findings),
            blockingCriticalCount: findings.filter { $0.severity == .critical }.count
        )
    }

    /// Export as JSON for AI consumption
    public func asJSON() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return """
            {
                "error": "Failed to encode results"
            }
            """
        }
        return jsonString
    }

    // MARK: - Private Calculations

    private func calculateHealthScore(_ findings: [ArchitecturalFinding]) -> Int {
        if findings.isEmpty { return 100 }
        let score = max(0, 100 - (findings.count / 10))
        return min(score, 100)
    }

    private func calculateROI(_ findings: [ArchitecturalFinding]) -> Double {
        let highConfidenceFixes = findings.filter { $0.automationConfidence > 0.8 }
        guard !findings.isEmpty else { return 0.0 }
        return Double(highConfidenceFixes.count) / Double(findings.count)
    }

    private func calculateTechDebt(_ findings: [ArchitecturalFinding]) -> Double {
        let criticalAndHigh = findings.filter {
            $0.severity == .critical || $0.severity == .high
        }
        guard !findings.isEmpty else { return 0.0 }
        return Double(criticalAndHigh.count) / Double(findings.count)
    }
}

// MARK: - Supporting Types

public struct Metadata: Codable {
    let version: String
    let timestamp: Date
    let filesAnalyzed: Int
    let duration: TimeInterval
}

public struct Summary: Codable {
    let healthScore: Int
    let violationsCount: Int
    let criticalIssues: Int
    let automatableFixes: Int
}

public struct PriorityAction: Codable {
    let type: String
    let severity: String
    let file: String
    let line: Int
    let message: String
    let recommendedAction: String
    let automationConfidence: Double
    let blocking: Bool

    init(from finding: ArchitecturalFinding) {
        self.type = extractType(from: finding.ruleName)
        self.severity = severityToString(finding.severity)
        self.file = finding.file
        self.line = finding.line
        self.message = finding.message
        self.recommendedAction = finding.suggestion
        self.automationConfidence = finding.automationConfidence
        self.blocking = finding.severity == .critical
    }

    private func extractType(from ruleName: String) -> String {
        if ruleName.contains("Monolithic") { return "monolithic_feature" }
        if ruleName.contains("Error") || ruleName.contains("Handling") { return "missing_error_handling" }
        if ruleName.contains("View") { return "swiftui_complexity" }
        if ruleName.contains("Coupling") { return "high_coupling" }
        return "architectural_violation"
    }

    private func severityToString(_ severity: ViolationSeverity) -> String {
        switch severity {
        case .critical: return "critical"
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        }
    }
}

public struct DecisionMetrics: Codable {
    let refactoringROI: Double
    let techDebtScore: Double
    let blockingCriticalCount: Int
}

public struct ArchitecturalFinding: Codable {
    let ruleName: String
    let severity: ViolationSeverity
    let file: String
    let line: Int
    let message: String
    let suggestion: String
    let automationConfidence: Double
}

// MARK: - Lightweight Severity Enum

public enum ViolationSeverity: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

// MARK: - Extensions

extension Array where Element: Hashable {
    var unique: [Element] {
        return Array(Set(self))
    }
}