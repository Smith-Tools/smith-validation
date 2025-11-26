import Foundation

/// Smith Validation CLI with Progressive Intelligence
/// AI-optimized architectural analysis for Swift projects
/// Designed for anthropic AI agents with actionable insights and token efficiency
@main
struct SmithValidationCLI {
    static func main() {
        let args = CommandLine.arguments

        guard args.count >= 2 else {
            print(jsonError("Usage: smith-validation <project-path> [--level=critical|standard|comprehensive] [--format=json|summary]"))
            return
        }

        let projectPath = args[1]

        // Parse analysis level and format options
        var analysisLevel: AnalysisLevel = .critical
        var outputFormat: OutputFormat = .json

        for arg in args.dropFirst() {
            if arg.hasPrefix("--level=") {
                let components = arg.components(separatedBy: "=")
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
            } else if arg == "--format=summary" {
                outputFormat = .summary
            } else if arg == "--format=json" {
                outputFormat = .json
            }
        }

        // Validate project exists
        guard FileManager.default.fileExists(atPath: projectPath) else {
            print(jsonError("Project path does not exist: \(projectPath)"))
            return
        }

        // Run AI-optimized Progressive Intelligence analysis
        let analyzer = AIOptimizedAnalyzer()
        let result = analyzer.analyzeProject(at: projectPath, level: analysisLevel)

        switch outputFormat {
        case .summary:
            print(result.asSummary())
        case .json:
            print(result.asJSON())
        }
    }

    private static func jsonError(_ message: String) -> String {
        return """
{
  "error": "\(message)",
  "usage": "smith-validation <project-path> [--level=critical|standard|comprehensive] [--format=json|summary]",
  "description": "Smith Validation - AI-Optimized Progressive Intelligence Analysis for Anthropic AI Agents"
}
"""
    }
}

// MARK: - Output Formats

enum OutputFormat {
    case json
    case summary
}

// MARK: - Analysis Levels

enum AnalysisLevel: Codable, CaseIterable {
    case critical    // Minimal tokens, fastest, critical violations only
    case standard    // Balanced detail, all violations
    case comprehensive  // Rich detail, full analysis + insights
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

// MARK: - AI-Optimized Analyzer

struct AIOptimizedAnalyzer {

    func analyzeProject(at path: String, level: AnalysisLevel) -> AIOptimizedResult {
        let startTime = Date()
        var findings: [ArchitecturalFinding] = []
        var fileCount = 0
        var totalLines = 0

        // Find Swift files
        let swiftFiles = findSwiftFiles(at: path)
        fileCount = swiftFiles.count

        // Analyze each file with AI-optimized intelligence
        for file in swiftFiles {
            do {
                let content = try String(contentsOf: file)
                let fileLines = content.components(separatedBy: .newlines).count
                totalLines += fileLines

                let fileFindings = analyzeFileForAI(content: content, file: file, level: level, totalLines: fileLines)
                findings.append(contentsOf: fileFindings)
            } catch {
                // Skip files that can't be read
            }
        }

        // Apply progressive intelligence filtering
        let filteredFindings = applyProgressiveIntelligence(findings, level: level)

        let duration = Date().timeIntervalSince(startTime)

        return AIOptimizedResult(
            analysisType: "smith-validation-ai-optimized",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            projectPath: path,
            analysisLevel: level,
            duration: duration,
            summary: AI_OptimizedSummary(
                totalFiles: fileCount,
                totalLines: totalLines,
                violationsCount: filteredFindings.count,
                healthScore: calculateHealthScore(filteredFindings),
                severityBreakdown: SeverityBreakdown(
                    critical: filteredFindings.filter { $0.severity == .critical }.count,
                    high: filteredFindings.filter { $0.severity == .high }.count,
                    medium: filteredFindings.filter { $0.severity == .medium }.count,
                    low: filteredFindings.filter { $0.severity == .low }.count
                ),
                automation: Automation(
                    automatableFixes: filteredFindings.filter { $0.hasViolation && $0.automationConfidence > 0.8 }.count,
                    averageConfidence: filteredFindings.isEmpty ? 1.0 : filteredFindings.reduce(0) { $0 + ($1.hasViolation ? $1.automationConfidence : 0) } / Double(filteredFindings.count)
                ),
                efficiency: calculateEfficiencyScore(filteredFindings, level: level, duration: duration)
            ),
            findings: filteredFindings,
            actionableInsights: generateActionableInsights(filteredFindings, level: level),
            aiRecommendations: generateAIRecommendations(filteredFindings, level: level)
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

    private func analyzeFileForAI(content: String, file: URL, level: AnalysisLevel, totalLines: Int) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []
        let lines = content.components(separatedBy: .newlines)

        switch level {
        case .critical:
            findings.append(contentsOf: analyzeCriticalViolations(content: content, file: file, lines: lines))
        case .standard:
            findings.append(contentsOf: analyzeCriticalViolations(content: content, file: file, lines: lines))
            findings.append(contentsOf: analyzeStandardViolations(content: content, file: file, lines: lines))
        case .comprehensive:
            findings.append(contentsOf: analyzeCriticalViolations(content: content, file: file, lines: lines))
            findings.append(contentsOf: analyzeStandardViolations(content: content, file: file, lines: lines))
            findings.append(contentsOf: analyzeComprehensivePatterns(content: content, file: file, lines: lines, totalLines: totalLines))
        }

        return findings
    }

    // Enhanced analysis methods with AI-optimized features
    private func analyzeCriticalViolations(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // TCA Error Handling Analysis (AI-optimized)
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
                    automationConfidence: 0.92, // Higher confidence for AI actionability
                    recommendedAction: "Add error-related action cases like 'errorOccurred(String)', 'loadFailed(Error)' or 'handleError(Error)'",
                    type: "missing_error_handling"
                ))
            }
        }

        return findings
    }

    private func analyzeStandardViolations(content: String, file: URL, lines: [String]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // Find monolithic State structs (enhanced)
        for (index, line) in lines.enumerated() {
            if line.contains("struct State") || (line.contains("struct") && line.contains("State")) {
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
                    findings.append(ArchitecturalFinding(
                        fileName: file.lastPathComponent,
                        filePath: file.path,
                        ruleName: "TCA-Monolithic-State",
                        severity: .high,
                        lines: propertyCount,
                        actualValue: "State struct with \(propertyCount) properties",
                        expectedValue: "State struct with <15 properties",
                        hasViolation: true,
                        automationConfidence: 0.85,
                        recommendedAction: "Extract separate features or use child reducers. Consider splitting into smaller, focused state management units.",
                        type: "monolithic_feature"
                    ))
                }
            }
        }

        return findings
    }

    private func analyzeComprehensivePatterns(content: String, file: URL, lines: [String], totalLines: Int) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        // High coupling detection (enhanced)
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
                automationConfidence: 0.75,
                recommendedAction: "Consider reducing dependencies, using dependency injection, or extracting utility protocols for better decoupling.",
                type: "high_coupling"
            ))
        }

        // File size analysis (AI-optimized)
        if totalLines > 200 {
            findings.append(ArchitecturalFinding(
                fileName: file.lastPathComponent,
                filePath: file.path,
                ruleName: "File-Size-Management",
                severity: .medium,
                lines: totalLines,
                actualValue: "\(totalLines) lines",
                expectedValue: "<200 lines",
                hasViolation: true,
                automationConfidence: 0.70,
                recommendedAction: "Consider breaking down into smaller, focused modules. Each module should have a single responsibility.",
                type: "file_size_violation"
            ))
        }

        return findings
    }

    private func applyProgressiveIntelligence(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [ArchitecturalFinding] {
        switch level {
        case .critical:
            return findings.filter { $0.severity == .critical || $0.severity == .high }
        case .standard:
            return findings
        case .comprehensive:
            return findings
        }
    }

    private func calculateHealthScore(_ findings: [ArchitecturalFinding]) -> Int {
        let criticalCount = findings.filter { $0.severity == .critical }.count
        let highCount = findings.filter { $0.severity == .high }.count
        let mediumCount = findings.filter { $0.severity == .medium }.count
        let lowCount = findings.filter { $0.severity == .low }.count

        let baseScore = 100
        let criticalPenalty = criticalCount * 25
        let highPenalty = highCount * 15
        let mediumPenalty = mediumCount * 8
        let lowPenalty = lowCount * 3

        return max(0, baseScore - criticalPenalty - highPenalty - mediumPenalty - lowPenalty)
    }

    private func calculateEfficiencyScore(_ findings: [ArchitecturalFinding], level: AnalysisLevel, duration: TimeInterval) -> Efficiency {
        let analysisSpeed = duration < 5.0 ? 1.0 : max(0.3, 10.0 / duration)
        let tokenEfficiency = level == .critical ? 1.0 : level == .standard ? 0.8 : 0.6
        let automationPotential = Double(findings.filter { $0.automationConfidence > 0.8 }.count) / Double(max(1, findings.count))

        return Efficiency(
            analysisSpeed: analysisSpeed,
            tokenEfficiency: tokenEfficiency,
            automationPotential: automationPotential,
            overallScore: (analysisSpeed + tokenEfficiency + automationPotential) / 3.0
        )
    }

    private func generateActionableInsights(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [ActionableInsight] {
        var insights: [ActionableInsight] = []

        let criticalViolations = findings.filter { $0.severity == .critical }
        if !criticalViolations.isEmpty {
            insights.append(ActionableInsight(
                category: "Urgent",
                title: "Critical Architectural Issues",
                description: "Found \(criticalViolations.count) critical violations that require immediate attention",
                actionable: true,
                priority: "high",
                estimatedEffort: criticalViolations.reduce(0) { $0 + Int(($1.automationConfidence * 10).rounded()) }
            ))
        }

        let automationReady = findings.filter { $0.automationConfidence > 0.8 }
        if !automationReady.isEmpty {
            insights.append(ActionableInsight(
                category: "Automation",
                title: "Auto-Fixable Issues",
                description: "\(automationReady.count) violations have high automation confidence (>80%)",
                actionable: true,
                priority: "medium",
                estimatedEffort: automationReady.count * 2
            ))
        }

        return insights
    }

    private func generateAIRecommendations(_ findings: [ArchitecturalFinding], level: AnalysisLevel) -> [AIRecommendation] {
        var recommendations: [AIRecommendation] = []

        // AI-specific recommendations for different levels
        switch level {
        case .critical:
            recommendations.append(AIRecommendation(
                type: "priority",
                title: "Focus on Critical Violations",
                description: "Address all critical violations first as they impact system reliability",
                codeChanges: findings.filter { $0.severity == .critical }.map { $0.recommendedAction },
                estimatedImpact: "high",
                implementationSteps: [
                    "Add missing error handling in TCA Actions",
                    "Break down monolithic state structures"
                ]
            ))
        case .standard:
            recommendations.append(AIRecommendation(
                type: "comprehensive",
                title: "Address All Violations",
                description: "Systematic approach to improve overall architectural health",
                codeChanges: findings.map { $0.recommendedAction },
                estimatedImpact: "medium",
                implementationSteps: [
                    "Refactor large files",
                    "Reduce coupling",
                    "Improve error handling"
                ]
            ))
        case .comprehensive:
            recommendations.append(AIRecommendation(
                type: "strategic",
                title: "Architectural Transformation",
                description: "Comprehensive architectural refactoring for long-term maintainability",
                codeChanges: findings.map { $0.recommendedAction },
                estimatedImpact: "high",
                implementationSteps: [
                    "Modularize large components",
                    "Implement dependency injection",
                    "Establish architectural patterns"
                ]
            ))
        }

        return recommendations
    }
}

// MARK: - AI-Optimized Data Structures

struct AIOptimizedResult: Codable {
    let analysisType: String
    let timestamp: String
    let projectPath: String
    let analysisLevel: AnalysisLevel
    let duration: TimeInterval
    let summary: AI_OptimizedSummary
    let findings: [ArchitecturalFinding]
    let actionableInsights: [ActionableInsight]
    let aiRecommendations: [AIRecommendation]

    func asJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to encode AI-optimized analysis result\"}"
        }
    }

    func asSummary() -> String {
        return """
🔍 AI-OPTIMIZED ANALYSIS SUMMARY
===============================
Project: \(URL(fileURLWithPath: projectPath).lastPathComponent)
Level: \(analysisLevel)
Duration: \(String(format: "%.1f", duration))s

📊 ARCHITECTURAL HEALTH
======================
Health Score: \(summary.healthScore)/100
Files Analyzed: \(summary.totalFiles)
Lines of Code: \(summary.totalLines)

🚨 VIOLATIONS BREAKDOWN
======================
Critical: \(summary.severityBreakdown.critical)
High: \(summary.severityBreakdown.high)
Medium: \(summary.severityBreakdown.medium)
Low: \(summary.severityBreakdown.low)

🤖 AI INSIGHTS
===============
Automatable Fixes: \(summary.automation.automatableFixes)
Automation Confidence: \(String(format: "%.1f", summary.automation.averageConfidence * 100))%
Efficiency Score: \(String(format: "%.1f", summary.efficiency.overallScore * 100))%

🎯 AI RECOMMENDATIONS
======================
\(aiRecommendations.map { "• \($0.title): \($0.description)" }.joined(separator: "\n"))
"""
    }
}

struct AI_OptimizedSummary: Codable {
    let totalFiles: Int
    let totalLines: Int
    let violationsCount: Int
    let healthScore: Int
    let severityBreakdown: SeverityBreakdown
    let automation: Automation
    let efficiency: Efficiency
}

struct Efficiency: Codable {
    let analysisSpeed: Double
    let tokenEfficiency: Double
    let automationPotential: Double
    let overallScore: Double
}

struct ActionableInsight: Codable {
    let category: String
    let title: String
    let description: String
    let actionable: Bool
    let priority: String
    let estimatedEffort: Int // minutes
}

struct AIRecommendation: Codable {
    let type: String
    let title: String
    let description: String
    let codeChanges: [String]
    let estimatedImpact: String
    let implementationSteps: [String]
}