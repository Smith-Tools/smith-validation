import Foundation
import SourceKittenFramework

/// Smith Validation CLI with SourceKit integration and Human-Friendly Rule Builder
/// Clean architecture: Direct consumption of RulePacks via SourceKit semantic analysis

struct SmithValidationCLI {

    static func main() {
        let args = CommandLine.arguments

        guard args.count == 2 else {
            print(jsonError("Usage: smith-validation <project-path>"))
            return
        }

        let projectPath = args[1]

        // Validate project exists
        guard FileManager.default.fileExists(atPath: projectPath) else {
            print(jsonError("Project path does not exist: \(projectPath)"))
            return
        }

        // Run SourceKit-based analysis with new rule builder
        let analyzer = SourceKitAnalyzer()
        let result = analyzer.analyzeProject(at: projectPath)

        // Output AI-optimized JSON
        print(result.asJSON())
    }

    private static func jsonError(_ message: String) -> String {
        return """
{
  "error": "\(message)",
  "usage": "smith-validation <project-path>",
  "description": "Smith Validation using SourceKit with Human-Friendly Rule Builder"
}
"""
    }
}

SmithValidationCLI.main()

// MARK: - Enhanced SourceKit Analyzer with Rule Builder Integration

struct SourceKitAnalyzer {

    func analyzeProject(at path: String) -> AIValidationResult {
        print("🔍 Starting SourceKit-based architectural analysis with human-friendly rules...")

        var findings: [ArchitecturalFinding] = []
        var fileCount = 0
        var totalLines = 0

        // Find Swift files
        let swiftFiles = findSwiftFiles(at: path)
        fileCount = swiftFiles.count
        print("📁 Found \(fileCount) Swift files")

        // Get all registered rules
        let rules = RuleRegistry.shared.getAllRules()
        print("📋 Loaded \(rules.count) architectural rules")

        // Analyze each file with SourceKit
        for (index, file) in swiftFiles.enumerated() {
            let fileFindings = analyzeFileWithRuleBuilder(file, rules: rules)
            findings.append(contentsOf: fileFindings)

            if let lineCount = try? String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines).count {
                totalLines += lineCount
            }

            if index % 50 == 0 && index > 0 {
                print("📖 Processed \(index)/\(fileCount) files...")
            }
        }

        print("🎯 Analysis complete: \(findings.count) findings from \(fileCount) files")

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

    private func analyzeFileWithRuleBuilder(_ url: URL, rules: [Any]) -> [ArchitecturalFinding] {
        var findings: [ArchitecturalFinding] = []

        do {
            let sourceCode = try String(contentsOf: url, encoding: .utf8)
            let fileName = url.lastPathComponent
            let filePath = url.path
            let lines = sourceCode.components(separatedBy: .newlines).count

            // Parse with SourceKit
            let file = File(path: filePath)
            let structure = try Structure(file: file!)

            // Extract semantic information
            let declarations = extractDeclarations(from: structure.dictionary)

            // Create analyzed code object for rule processing
            let analyzedCode = AnalyzedCode(
                sourceCode: sourceCode,
                declarations: declarations,
                lines: lines
            )

            // Apply all registered rules
            for rule in rules {
                if let simpleRule = rule as? SimpleRule {
                    if let ruleFindings = simpleRule.apply(
                        to: analyzedCode,
                        fileName: fileName,
                        filePath: filePath,
                        lines: lines
                    ) {
                        findings.append(contentsOf: ruleFindings)
                    }
                } else if let arrayRule = rule as? ArrayRule<Any> {
                    // This is a workaround for generic array rules
                    // In practice, you'd want better handling here
                    if let ruleFindings = applyArrayRule(arrayRule, to: analyzedCode, fileName: fileName, filePath: filePath, lines: lines) {
                        findings.append(contentsOf: ruleFindings)
                    }
                }
            }

            // Apply built-in file size rule
            if lines > 150 {
                findings.append(ArchitecturalFinding(
                    fileName: fileName,
                    filePath: filePath,
                    ruleName: "File Size Management",
                    severity: .high,
                    lines: lines,
                    actualValue: "\(lines) lines",
                    expectedValue: "< 150 lines",
                    hasViolation: true,
                    automationConfidence: 0.85,
                    recommendedAction: "Extract smaller components from large file",
                    type: "large_file"
                ))
            }

        } catch {
            findings.append(ArchitecturalFinding(
                fileName: url.lastPathComponent,
                filePath: url.path,
                ruleName: "SourceKit Analysis Error",
                severity: .low,
                lines: 0,
                actualValue: "Cannot analyze with SourceKit: \(error.localizedDescription)",
                expectedValue: "Successful SourceKit parsing",
                hasViolation: true,
                automationConfidence: 0.0,
                recommendedAction: "Check file syntax and SourceKit compatibility",
                type: "sourcekit_error"
            ))
        }

        return findings
    }

    // Helper method to handle generic array rules
    private func applyArrayRule<T>(_ rule: ArrayRule<T>, to code: AnalyzedCode, fileName: String, filePath: String, lines: Int) -> [ArchitecturalFinding]? {
        // This is a simplified approach - in practice you'd want better type safety
        return rule.apply(to: code, fileName: fileName, filePath: filePath, lines: lines)
    }

    private func extractDeclarations(from dict: [String: Any]) -> [DeclarationInfo] {
        var declarations: [DeclarationInfo] = []

        func extract(_ dict: [String: Any]) {
            guard let kind = dict["key.kind"] as? String else { return }

            if isSwiftDeclaration(kind) {
                let declaration = DeclarationInfo(
                    kind: kind,
                    name: dict["key.name"] as? String ?? "",
                    offset: dict["key.offset"] as? Int64 ?? 0,
                    length: dict["key.length"] as? Int64 ?? 0,
                    bodyOffset: dict["key.bodyoffset"] as? Int64,
                    bodyLength: dict["key.bodylength"] as? Int64
                )
                declarations.append(declaration)
            }

            if let substructures = dict["key.substructure"] as? [[String: Any]] {
                for substructure in substructures {
                    extract(substructure)
                }
            }
        }

        extract(dict)
        return declarations
    }

    private func isSwiftDeclaration(_ kind: String) -> Bool {
        let swiftDeclarations = [
            "source.lang.swift.decl.class",
            "source.lang.swift.decl.struct",
            "source.lang.swift.decl.enum",
            "source.lang.swift.decl.function.free",
            "source.lang.swift.decl.function.method.instance",
            "source.lang.swift.decl.var.instance",
            "source.lang.swift.decl.enumcase"
        ]
        return swiftDeclarations.contains(kind)
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

        if !critical.isEmpty {
            recommendations.append("🚨 Address \(critical.count) critical violations immediately")
        }

        if !high.isEmpty {
            recommendations.append("⚠️ Review \(high.count) high-priority violations")
        }

        if violations.count > 10 {
            recommendations.append("📊 Consider comprehensive architectural refactoring")
        }

        if violations.isEmpty {
            recommendations.append("✅ Excellent architectural quality maintained")
        } else {
            recommendations.append("🔧 Address violations systematically using human-friendly rule analysis")
        }

        // Add specific rule-based recommendations
        let ruleGroups = Dictionary(grouping: violations) { $0.ruleName }
        for (ruleName, ruleViolations) in ruleGroups.sorted(by: { $0.key < $1.key }) {
            if ruleViolations.count >= 3 {
                recommendations.append("📋 \(ruleName): \(ruleViolations.count) violations detected")
            }
        }

        return recommendations
    }
}

// MARK: - Data Structures

struct DeclarationInfo {
    let kind: String
    let name: String
    let offset: Int64
    let length: Int64
    let bodyOffset: Int64?
    let bodyLength: Int64?
}

struct AIValidationResult: Codable {
    let analysisType: String
    let timestamp: String
    let projectPath: String
    let summary: Summary
    let findings: [ArchitecturalFinding]
    let recommendations: [String]

    init(timestamp: String, projectPath: String, summary: Summary, findings: [ArchitecturalFinding], recommendations: [String]) {
        self.analysisType = "smith-validation-rule-builder-analysis"
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
