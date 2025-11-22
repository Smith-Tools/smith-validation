// Sources/SmithValidationTests/ArchitecturalTestRunner.swift
// Main entry point for AI agent integration

import Foundation
import Testing
import SmithValidationCore
import SwiftSyntax
import SwiftParser

/// Main test runner for AI agent integration
@Suite("Smith Validation Architectural Analysis")
struct ArchitecturalTestSuite {

    /// Main entry point called by CLI
    static func analyzeProject(at projectPath: String) async -> AIValidationResult {
        // Set up test environment
        let projectURL = URL(fileURLWithPath: projectPath)

        // Create test configuration
        var config = TestConfiguration()
        config.testCaseSelection = .included(["TCAArchitecturalRules", "SwiftUIArchitecturalRules", "GeneralArchitecturalRules"])

        // Create observer to capture results
        let observer = ArchitecturalTestObserver()

        // Run all architectural tests
        let testRun = await TestRunner.run(
            configuration: config,
            observer: observer
        )

        // Convert to AI-usable format
        return AIValidationResult(
            projectPath: projectPath,
            testRun: testRun,
            findings: observer.architecturalFindings
        )
    }

    /// Discover all Swift files in project
    private static func discoverSwiftFiles(in projectURL: URL) throws -> [URL] {
        return try FileUtils.findSwiftFiles(in: projectURL)
    }
}

/// Test observer to capture architectural findings
class ArchitecturalTestObserver: TestObserver {
    var architecturalFindings: [ArchitecturalFinding] = []

    func test(_ test: Test, didRecord issue: Issue) {
        // Convert test issues to architectural findings
        if let archFinding = extractArchitecturalFinding(from: issue) {
            architecturalFindings.append(archFinding)
        }
    }

    private func extractArchitecturalFinding(from issue: Issue) -> ArchitecturalFinding? {
        guard let sourceLocation = issue.sourceLocation,
              let error = issue.associatedError as? ArchitecturalViolation else {
            return nil
        }

        return ArchitecturalFinding(
            ruleName: extractRuleName(from: test.name),
            severity: error.severity,
            file: sourceLocation.fileURL?.path ?? "",
            line: sourceLocation.line,
            message: error.message,
            suggestion: error.suggestion ?? "",
            automationConfidence: calculateAutomationConfidence(error)
        )
    }

    private func extractRuleName(from testName: String) -> String {
        // Extract rule name from test name
        return testName.components(separatedBy: " ").last ?? testName
    }

    private func calculateAutomationConfidence(_ violation: ArchitecturalViolation) -> Double {
        // Calculate confidence for automated fixes based on violation type
        switch violation {
        case .critical: return 0.85
        case .high: return 0.75
        case .medium: return 0.65
        case .low: return 0.55
        }
    }
}

/// AI-usable validation result
public struct AIValidationResult: Codable {
    let projectPath: String
    let metadata: Metadata
    let summary: Summary
    let priorityActions: [PriorityAction]
    let decisionMetrics: DecisionMetrics

    init(projectPath: String, testRun: TestRunResult, findings: [ArchitecturalFinding]) {
        self.projectPath = projectPath
        self.metadata = Metadata(
            version: "1.0.10",
            timestamp: Date(),
            filesAnalyzed: testRun.tests.count,
            duration: testRun.duration
        )

        self.summary = Summary(
            healthScore: calculateHealthScore(findings),
            violationsCount: findings.count,
            criticalIssues: findings.filter { $0.severity == .critical }.count,
            automatableFixes: findings.filter { $0.automationConfidence > 0.8 }.count
        )

        self.priorityActions = findings
            .filter { $0.severity == .critical || $0.severity == .high }
            .map { PriorityAction(from: $0) }
            .sorted { $0.automationConfidence > $1.automationConfidence }

        self.decisionMetrics = DecisionMetrics(
            refactoringROI: calculateROI(findings),
            techDebtScore: calculateTechDebt(findings),
            blockingCriticalCount: findings.filter { $0.severity == .critical }.count
        )
    }

    /// Export as JSON for AI consumption
    public func asJSON() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }

    // MARK: - Private Calculations

    private func calculateHealthScore(_ findings: [ArchitecturalFinding]) -> Int {
        if findings.isEmpty { return 100 }
        let score = max(0, 100 - (findings.count / 50))
        return min(score, 100)
    }

    private func calculateROI(_ findings: [ArchitecturalFinding]) -> Double {
        let highConfidenceFixes = findings.filter { $0.automationConfidence > 0.8 }
        return Double(highConfidenceFixes.count) / Double(findings.count)
    }

    private func calculateTechDebt(_ findings: [ArchitecturalFinding]) -> Double {
        let criticalAndHigh = findings.filter {
            $0.severity == .critical || $0.severity == .high
        }
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
        if ruleName.contains("Error") { return "missing_error_handling" }
        if ruleName.contains("Circular") { return "circular_dependency" }
        if ruleName.contains("State") { return "state_management" }
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