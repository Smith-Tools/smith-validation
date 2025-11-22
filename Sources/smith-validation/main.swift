import Foundation

/// Smith Validation CLI with Progressive Intelligence
/// AI-optimized architectural analysis for Swift projects
@main
struct SmithValidationCLI {
    static func main() {
        let args = CommandLine.arguments

        guard args.count >= 2 else {
            print(jsonError("Usage: smith-validation <project-path> [--level=critical|standard|comprehensive]"))
            return
        }

        let projectPath = args[1]

        // Parse analysis level (default: critical)
        var analysisLevel: AnalysisLevel = .critical
        if let levelArg = args.first(where: { $0.hasPrefix("--level=") }) {
            let components = levelArg.components(separatedBy: "=")
            if components.count == 2 {
                let levelValue = components[1]
                switch levelValue {
                case "critical":
                    analysisLevel = .critical
                case "standard":
                    analysisLevel = .standard
                case "comprehensive":
                    analysisLevel = .comprehensive
                default:
                    print(jsonError("Invalid level '\(levelValue)'. Use: critical, standard, or comprehensive"))
                    return
                }
            }
        }

        // Validate project exists
        guard FileManager.default.fileExists(atPath: projectPath) else {
            print(jsonError("Project path does not exist: \(projectPath)"))
            return
        }

        // Run Progressive Intelligence analysis
        let analyzer = ProgressiveAnalyzer()
        let result = analyzer.analyzeProject(at: projectPath, level: analysisLevel)
        print(result.asJSON())
    }

    private static func jsonError(_ message: String) -> String {
        return """
{
  "error": "\(message)",
  "usage": "smith-validation <project-path> [--level=critical|standard|comprehensive]",
  "description": "Smith Validation - AI-Optimized Progressive Intelligence Analysis"
}
"""
    }
}

// MARK: - Analysis Levels

enum AnalysisLevel {
    case critical        // Only critical + high severity violations
    case standard        // All violations (current behavior)
    case comprehensive   // Standard + pattern analysis
}

// MARK: - Progressive Intelligence Analyzer

struct ProgressiveAnalyzer {
    func analyzeProject(at path: String, level: AnalysisLevel) -> AIValidationResult {
        let startTime = Date()
        var findings: [ArchitecturalFinding] = []
        var fileCount = 0

        // Find Swift files
        let swiftFiles = findSwiftFiles(at: path)
        fileCount = swiftFiles.count

        // Analyze each file with progressive intelligence
        for file in swiftFiles {
            do {
                let content = try String(contentsOf: file)
                let fileFindings = analyzeFileForIntelligence(content: content, file: file, level: level)
                findings.append(contentsOf: fileFindings)
            } catch {
                // Skip files that can't be read
            }
        }

        // Apply progressive intelligence filtering
        let filteredFindings = applyProgressiveIntelligence(findings, level: level)

        let duration = Date().timeIntervalSince(startTime)

        return AIValidationResult(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            projectPath: path,
            summary: Summary(
                totalFiles: fileCount,
                totalLines: 0, // Not calculated in lightweight mode
                violationsCount: filteredFindings.count,
                healthScore: calculateHealthScore(filteredFindings),
                severityBreakdown: SeverityBreakdown(
                    critical: filteredFindings.filter { $0.severity == .critical }.count,
                    high: filteredFindings.filter { $0.severity == .high }.count,
                    medium: filteredFindings.filter { $0.severity == .medium }.count,
                    low: filteredFindings.filter { $0.severity == .low }.count
                ),
                automation: Automation(
                    automatableFixes: filteredFindings.filter { $0.hasViolation && $0.automationConfidence > 0.7 }.count,
                    averageConfidence: filteredFindings.isEmpty ? 1.0 : filteredFindings.reduce(0) { $0 + ($1.hasViolation ? $1.automationConfidence : 0) } / Double(filteredFindings.count)
                )
            ),
            findings: filteredFindings,
            recommendations: generateProgressiveRecommendations(filteredFindings, level: level),
            analysisLevel: level
        )
    }

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

    private func analyzeFileForIntelligence(content: String, file: URL, level: AnalysisLevel) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []
        let lines = content.components(separatedBy: .newlines)

        // Progressive intelligence: Different analysis depth based on level
        switch level {
        case .critical:
            findings.append(contentsOf: analyzeCriticalViolations(content: content, file: file, lines: lines))
        case .standard:
            findings.append(contentsOf: analyzeCriticalViolations(content: content, file: file, lines: lines))
            findings.append(contentsOf: analyzeStandardViolations(content: content, file: file, lines: lines))
        case .comprehensive:
            findings.append(contentsOf: analyzeCriticalViolations(content: content, file: file, lines: lines))
            findings.append(contentsOf: analyzeStandardViolations(content: content, file: file, lines: lines))
            findings.append(contentsOf: analyzeComprehensivePatterns(content: content, file: file, lines: lines))
        }

        return findings
    }

    private func analyzeCriticalViolations(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // Find TCA Action enums missing error handling
        let actionEnumPattern = #"(?s)enum\s+(?:Action|Actions)\s*\{.*?\}"#
        let actionEnumRegex = try? NSRegularExpression(pattern: actionEnumPattern, options: [])
        let actionEnumMatches = actionEnumRegex?.matches(in: content, range: NSRange(content.startIndex..., in: content))

        for match in actionEnumMatches ?? [] {
            guard let range = Range(match.range, in: content) else { continue }
            let actionEnumContent = String(content[range])

            let hasErrorHandling = actionEnumContent.contains("case.*error") ||
                                  actionEnumContent.contains("case.*failure") ||
                                  actionEnumContent.contains("case.*failed")

            if !hasErrorHandling {
                findings.append(ArchitecturalFinding(
                    fileName: file.lastPathComponent,
                    filePath: file.path,
                    ruleName: "TCA-Missing-Error-Handling",
                    severity: .critical,
                    lines: 0,
                    actualValue: "Action enum without error cases",
                    expectedValue: "Action enum with error handling cases",
                    hasViolation: true,
                    automationConfidence: 0.88,
                    recommendedAction: "Add error-related action cases like 'errorOccurred(String)' or 'loadFailed(Error)'",
                    type: "missing_error_handling"
                ))
            }
        }

        return findings
    }

    private func analyzeStandardViolations(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // Find monolithic State structs
        for (index, line) in lines.enumerated() {
            if line.contains("struct") && line.contains("State") {
                let structStartIndex = index
                var propertyCount = 0
                var braceCount = 0
                var inStruct = false

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
                        fileName: file.lastPathComponent,
                        filePath: file.path,
                        ruleName: "TCA-Monolithic-State",
                        severity: .high,
                        lines: propertyCount,
                        actualValue: "State struct with \(propertyCount) properties",
                        expectedValue: "State struct with <15 properties",
                        hasViolation: true,
                        automationConfidence: 0.75,
                        recommendedAction: "Consider extracting separate features. State structs should ideally have <15 properties.",
                        type: "monolithic_feature"
                    ))
                }
            }
        }

        return findings
    }

    private func analyzeComprehensivePatterns(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // High coupling detection
        let linesWithImports = lines.filter { $0.hasPrefix("import ") }
        if linesWithImports.count > 15 {
            findings.append(ArchitecturalFinding(
                fileName: file.lastPathComponent,
                filePath: file.path,
                ruleName: "General-High-Coupling",
                severity: .medium,
                lines: linesWithImports.count,
                actualValue: "File with \(linesWithImports.count) imports",
                expectedValue: "File with <15 imports",
                hasViolation: true,
                automationConfidence: 0.60,
                recommendedAction: "Consider reducing dependencies or using dependency injection to lower coupling.",
                type: "high_coupling"
            ))
        }

        return findings
    }

    private func applyProgressiveIntelligence(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [ArchitecturalFinding] {
        switch level {
        case .critical:
            // Only show critical and high severity violations
            return findings.filter { $0.severity == .critical || $0.severity == .high }
        case .standard:
            // Show all violations
            return findings
        case .comprehensive:
            // Add pattern-based insights
            return findings + generatePatternInsights(findings)
        }
    }

    private func generatePatternInsights(_ findings: [ArchitecturalFinding]) -> [ArchitecturalFinding] {
        // Add cross-domain insights for comprehensive analysis
        var insights: [ArchitecturalFinding] = []

        // Group violations by file to identify hotspots
        let fileGroups = Dictionary(grouping: findings) { $0.fileName }
        for (fileName, fileFindings) in fileGroups {
            if fileFindings.count >= 5 {
                insights.append(ArchitecturalFinding(
                    fileName: fileName,
                    filePath: fileFindings.first?.filePath ?? "",
                    ruleName: "Architectural-Hotspot",
                    severity: .medium,
                    lines: fileFindings.count,
                    actualValue: "File with \(fileFindings.count) violations",
                    expectedValue: "File with <5 violations",
                    hasViolation: true,
                    automationConfidence: 0.70,
                    recommendedAction: "Consider comprehensive refactoring of this file to address multiple architectural issues.",
                    type: "architectural_hotspot"
                ))
            }
        }

        return insights
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

    private func generateProgressiveRecommendations(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [String] {
        let violations = findings.filter { $0.hasViolation }
        let critical = violations.filter { $0.severity == .critical }
        let high = violations.filter { $0.severity == .high }

        var recommendations: [String] = []

        switch level {
        case .critical:
            if !critical.isEmpty {
                recommendations.append("🚨 Address \(critical.count) critical violations immediately")
            }
            if !high.isEmpty {
                recommendations.append("⚠️ Review \(high.count) high-priority violations")
            }
            if violations.isEmpty {
                recommendations.append("✅ No critical architectural violations detected")
            }

        case .standard:
            if !critical.isEmpty {
                recommendations.append("🚨 Address \(critical.count) critical violations immediately")
            }
            if !high.isEmpty {
                recommendations.append("⚠️ Review \(high.count) high-priority violations")
            }
            if violations.count > 10 {
                recommendations.append("📊 Consider architectural refactoring")
            }
            if violations.isEmpty {
                recommendations.append("✅ Excellent architectural quality maintained")
            } else {
                recommendations.append("🔧 Address violations systematically")
            }

        case .comprehensive:
            if !critical.isEmpty {
                recommendations.append("🚨 Address \(critical.count) critical violations immediately")
            }
            if !high.isEmpty {
                recommendations.append("⚠️ Review \(high.count) high-priority violations")
            }

            // Add comprehensive insights
            let ruleGroups = Dictionary(grouping: violations) { $0.ruleName }
            for (ruleName, ruleViolations) in ruleGroups.sorted(by: { $0.key < $1.key }) {
                if ruleViolations.count >= 3 {
                    recommendations.append("📋 \(ruleName): \(ruleViolations.count) violations")
                }
            }

            let hotspots = violations.filter { $0.ruleName == "Architectural-Hotspot" }
            if !hotspots.isEmpty {
                recommendations.append("🔥 \(hotspots.count) architectural hotspots identified for comprehensive refactoring")
            }

            if violations.isEmpty {
                recommendations.append("✅ Comprehensive analysis shows excellent architectural health")
            } else {
                recommendations.append("🎯 Use comprehensive insights for strategic architectural improvements")
            }
        }

        return recommendations
    }
}

// MARK: - Data Structures

struct AIValidationResult: Codable {
    let analysisType: String
    let analysisLevel: String
    let timestamp: String
    let projectPath: String
    let summary: Summary
    let findings: [ArchitecturalFinding]
    let recommendations: [String]

    init(timestamp: String, projectPath: String, summary: Summary, findings: [ArchitecturalFinding], recommendations: [String], analysisLevel: AnalysisLevel) {
        self.analysisType = "smith-validation-progressive-intelligence"
        self.analysisLevel = String(describing: analysisLevel)
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