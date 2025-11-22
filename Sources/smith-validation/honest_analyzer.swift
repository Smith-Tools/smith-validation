import Foundation

/// Honest, AI-Optimized Architecture Analysis Engine
/// No custom formatting - just real data and actionable insights

struct HonestAnalyzer {

    /// Perform honest architectural analysis on a real project
    func analyzeProject(at path: String) -> AIValidationResult {
        var findings: [ArchitecturalFinding] = []
        var fileCount = 0
        var totalLines = 0

        // Find and analyze Swift files
        let swiftFiles = findSwiftFiles(at: path)
        fileCount = swiftFiles.count

        for file in swiftFiles {
            if let finding = analyzeFile(file) {
                findings.append(finding)
                totalLines += finding.lines
            }
        }

        return AIValidationResult(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            projectPath: path,
            summary: Summary(
                totalFiles: fileCount,
                totalLines: totalLines,
                violationsCount: findings.filter { $0.hasViolation }.count,
                healthScore: calculateHealthScore(findings),
                severityBreakdown: SeverityBreakdown(
                    critical: findings.filter { $0.severity == .critical }.count,
                    high: findings.filter { $0.severity == .high }.count,
                    medium: findings.filter { $0.severity == .medium }.count,
                    low: findings.filter { $0.severity == .low }.count
                ),
                automation: Automation(
                    automatableFixes: findings.filter { $0.automationConfidence > 0.7 }.count,
                    averageConfidence: findings.isEmpty ? 1.0 : findings.reduce(0) { $0 + $1.automationConfidence } / Double(findings.count)
                )
            ),
            findings: findings,
            recommendations: generateRecommendations(findings)
        )
    }

    // MARK: - Private Analysis Methods

    private func findSwiftFiles(at path: String) -> [URL] {
        var files: [URL] = []

        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: path),
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

    private func analyzeFile(_ url: URL) -> ArchitecturalFinding? {
        do {
            let sourceCode = try String(contentsOf: url, encoding: .utf8)
            let fileName = url.lastPathComponent
            let lines = sourceCode.components(separatedBy: .newlines).count

            // Rule 1: Large file detection
            if lines > 150 {
                return ArchitecturalFinding(
                    fileName: fileName,
                    filePath: url.path,
                    ruleName: "File Size Management",
                    severity: .high,
                    lines: lines,
                    actualValue: "\(lines) lines",
                    expectedValue: "< 150 lines",
                    hasViolation: true,
                    automationConfidence: 0.8,
                    recommendedAction: "Extract smaller components from large file",
                    type: "large_file"
                )
            }

            // Rule 2: Async without error handling
            let hasAsync = sourceCode.contains("async") || sourceCode.contains("await")
            let hasErrorHandling = sourceCode.contains("throws") ||
                                 sourceCode.contains("catch") ||
                                 sourceCode.contains("Result<") ||
                                 sourceCode.lowercased().contains("error")

            if hasAsync && !hasErrorHandling {
                return ArchitecturalFinding(
                    fileName: fileName,
                    filePath: url.path,
                    ruleName: "Async Error Handling",
                    severity: .critical,
                    lines: lines,
                    actualValue: "Async operations without error handling",
                    expectedValue: "Proper error handling for async operations",
                    hasViolation: true,
                    automationConfidence: 0.9,
                    recommendedAction: "Add throws/catch or Result types for async operations",
                    type: "async_error_handling"
                )
            }

            // Rule 3: Check for monolithic structures (simple detection)
            let hasStruct = sourceCode.contains("struct ") || sourceCode.contains("class ")
            if hasStruct && lines > 300 {
                return ArchitecturalFinding(
                    fileName: fileName,
                    filePath: url.path,
                    ruleName: "Structure Size Management",
                    severity: .medium,
                    lines: lines,
                    actualValue: "\(lines) lines in single file",
                    expectedValue: "< 300 lines per file",
                    hasViolation: true,
                    automationConfidence: 0.7,
                    recommendedAction: "Consider breaking down large structure into smaller files",
                    type: "monolithic_structure"
                )
            }

            return nil

        } catch {
            return nil
        }
    }

    private func calculateHealthScore(_ findings: [ArchitecturalFinding]) -> Int {
        let violations = findings.filter { $0.hasViolation }
        let deductions = violations.reduce(0) { total, finding in
            switch finding.severity {
            case .critical: return total + 15
            case .high: return total + 10
            case .medium: return total + 5
            case .low: return total + 2
            }
        }

        return max(0, 100 - deductions)
    }

    private func generateRecommendations(_ findings: [ArchitecturalFinding]) -> [String] {
        let violations = findings.filter { $0.hasViolation }
        let critical = violations.filter { $0.severity == .critical }
        let high = violations.filter { $0.severity == .high }

        var recommendations: [String] = []

        if critical.count > 0 {
            recommendations.append("Address \(critical.count) critical architectural violations immediately")
        }

        if high.count > 0 {
            recommendations.append("Review \(high.count) high-priority architectural issues")
        }

        if violations.count > 10 {
            recommendations.append("Consider architectural refactoring - multiple violations detected")
        }

        if violations.isEmpty {
            recommendations.append("Excellent code quality maintained - no architectural violations")
        } else {
            recommendations.append("Focus on improving file organization and error handling patterns")
        }

        return recommendations
    }
}

// MARK: - Data Structures (AI-Optimized JSON)

struct AIValidationResult: Codable {
    let analysisType: String
    let timestamp: String
    let projectPath: String
    let summary: Summary
    let findings: [ArchitecturalFinding]
    let recommendations: [String]

    init(timestamp: String, projectPath: String, summary: Summary, findings: [ArchitecturalFinding], recommendations: [String]) {
        self.analysisType = "smith-validation-architecture-analysis"
        self.timestamp = timestamp
        self.projectPath = projectPath
        self.summary = summary
        self.findings = findings
        self.recommendations = recommendations
    }

    func asJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to encode analysis result\"}"
        }
    }
}

struct Summary: Codable {
    let totalFiles: Int
    let totalLines: Int
    let violationsCount: Int
    let healthScore: Int
    let severityBreakdown: SeverityBreakdown
    let automation: Automation
}

struct SeverityBreakdown: Codable {
    let critical: Int
    let high: Int
    let medium: Int
    let low: Int
}

struct Automation: Codable {
    let automatableFixes: Int
    let averageConfidence: Double
}

struct ArchitecturalFinding: Codable {
    let fileName: String
    let filePath: String
    let ruleName: String
    let severity: ViolationSeverity
    let lines: Int
    let actualValue: String
    let expectedValue: String
    let hasViolation: Bool
    let automationConfidence: Double
    let recommendedAction: String
    let type: String
}

enum ViolationSeverity: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}
