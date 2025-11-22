import Foundation

/// Honest, AI-Optimized Architecture Analysis Engine
/// No custom formatting - just real data and actionable insights

struct HonestAnalyzer {

    /// Perform honest architectural analysis on a real project with configurable detail level
    func analyzeProject(at path: String, level: AnalysisLevel = .critical) -> AIValidationResult {
        var allFindings: [ArchitecturalFinding] = []
        var fileCount = 0
        var totalLines = 0

        // Find and analyze Swift files
        let swiftFiles = findSwiftFiles(at: path)
        fileCount = swiftFiles.count

        for file in swiftFiles {
            if let finding = analyzeFile(file) {
                allFindings.append(finding)
                totalLines += finding.lines
            }
        }

        // Filter findings based on analysis level
        let filteredFindings = filterFindingsByLevel(allFindings, level: level)
        let summary = generateSummary(for: filteredFindings, allFindings: allFindings, fileCount: fileCount, totalLines: totalLines, level: level)
        let recommendations = generateRecommendationsByLevel(filteredFindings, level: level)

        return AIValidationResult(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            projectPath: path,
            summary: summary,
            findings: filteredFindings,
            recommendations: recommendations,
            analysisLevel: level
        )
    }

    // MARK: - Progressive Intelligence Implementation

    private func filterFindingsByLevel(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [ArchitecturalFinding] {
        switch level {
        case .critical:
            // Only critical + high severity violations
            return findings.filter { $0.hasViolation && ($0.severity == .critical || $0.severity == .high) }
        case .standard:
            // All violations (current behavior)
            return findings.filter { $0.hasViolation }
        case .comprehensive:
            // All violations + additional insights (generated separately)
            return findings.filter { $0.hasViolation }
        }
    }

    private func generateSummary(for findings: [ArchitecturalFinding], allFindings: [ArchitecturalFinding], fileCount: Int, totalLines: Int, level: AnalysisLevel) -> Summary {
        let violations = findings.filter { $0.hasViolation }

        // Calculate health score based on filtered findings
        let healthScore = calculateHealthScore(violations)

        // Severity breakdown
        let severityBreakdown = SeverityBreakdown(
            critical: violations.filter { $0.severity == .critical }.count,
            high: violations.filter { $0.severity == .high }.count,
            medium: violations.filter { $0.severity == .medium }.count,
            low: violations.filter { $0.severity == .low }.count
        )

        // Automation metrics
        let automation = Automation(
            automatableFixes: violations.filter { $0.automationConfidence > 0.7 }.count,
            averageConfidence: violations.isEmpty ? 1.0 : violations.reduce(0) { $0 + $1.automationConfidence } / Double(violations.count)
        )

        // For critical mode, show total violations count from all findings for context
        let violationsCount = level == .critical ? allFindings.filter { $0.hasViolation }.count : violations.count

        return Summary(
            totalFiles: fileCount,
            totalLines: totalLines,
            violationsCount: violationsCount,
            healthScore: healthScore,
            severityBreakdown: severityBreakdown,
            automation: automation
        )
    }

    private func generateRecommendationsByLevel(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [String] {
        let violations = findings.filter { $0.hasViolation }
        let critical = violations.filter { $0.severity == .critical }
        let high = violations.filter { $0.severity == .high }

        var recommendations: [String] = []

        switch level {
        case .critical:
            // Focus on immediate action items
            if !critical.isEmpty {
                recommendations.append("🚨 Address \(critical.count) critical violations immediately")
            }
            if !high.isEmpty {
                recommendations.append("⚠️ Review \(high.count) high-priority violations")
            }
            recommendations.append("💡 Use --level=standard for complete analysis")

        case .standard:
            // Standard comprehensive recommendations
            if !critical.isEmpty {
                recommendations.append("🚨 Address \(critical.count) critical violations immediately")
            }
            if !high.isEmpty {
                recommendations.append("⚠️ Review \(high.count) high-priority violations")
            }
            if violations.count > 10 {
                recommendations.append("📊 Consider architectural refactoring - multiple violations detected")
            }
            if violations.isEmpty {
                recommendations.append("✅ Excellent architectural quality maintained")
            } else {
                recommendations.append("🔧 Address violations systematically")
            }

        case .comprehensive:
            // Include strategic insights
            recommendations.append(contentsOf: generateStandardRecommendations(violations))

            // Add strategic insights
            let ruleGroups = Dictionary(grouping: violations) { $0.ruleName }
            if ruleGroups.count > 5 {
                recommendations.append("📈 \(ruleGroups.count) different rule types triggered - consider holistic architectural review")
            }

            let largeFiles = violations.filter { $0.type == "large_file" }
            if largeFiles.count > violations.count / 2 {
                recommendations.append("📏 File size is primary concern - consider modularization strategy")
            }
        }

        return recommendations
    }

    private func generateStandardRecommendations(_ violations: [ArchitecturalFinding]) -> [String] {
        let critical = violations.filter { $0.severity == .critical }
        let high = violations.filter { $0.severity == .high }

        var recommendations: [String] = []

        if !critical.isEmpty {
            recommendations.append("🚨 Address \(critical.count) critical violations immediately")
        }

        if !high.isEmpty {
            recommendations.append("⚠️ Review \(high.count) high-priority violations")
        }

        if violations.count > 10 {
            recommendations.append("📊 Consider architectural refactoring - multiple violations detected")
        }

        if violations.isEmpty {
            recommendations.append("✅ Excellent architectural quality maintained")
        } else {
            recommendations.append("🔧 Address violations systematically using analysis")
        }

        return recommendations
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

