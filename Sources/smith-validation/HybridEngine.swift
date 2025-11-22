// Sources/smith-validation/HybridEngine.swift
// Hybrid Swift Testing Engine for efficient architectural validation

import Foundation
import SmithValidationCore
import SwiftSyntax
import SwiftParser

/// Hybrid engine that uses efficient rule execution
public class HybridEngine {

    /// Run architectural validation using efficient execution
    public static func validate(
        directory: URL,
        rulePacks: [String] = ["TCA", "SwiftUI", "General"]
    ) async -> HybridReport {
        print("🚀 Starting hybrid architectural validation...")
        print("📁 Target: \(directory.path)")
        print("🔧 Rule Packs: \(rulePacks.joined(separator: ", "))")

        var allFindings: [HybridFinding] = []
        var executionTime: TimeInterval = 0

        let startTime = Date()

        do {
            // Parse Swift files ONCE for all rule packs
            let swiftFiles = try FileUtils.findSwiftFiles(in: directory)
            let parsedFiles = swiftFiles.compactMap { try? SourceFileSyntax.parse(from: $0) }

            print("📖 Parsed \(parsedFiles.count) files for analysis")

            // Run each rule pack on the same parsed files
            for rulePack in rulePacks {
                print("\n🔍 Executing \(rulePack) rules...")

                let packFindings = await runRulePack(
                    rulePack: rulePack,
                    parsedFiles: parsedFiles
                )

                allFindings.append(contentsOf: packFindings)
                print("✅ \(rulePack): \(packFindings.count) findings")
            }

            executionTime = Date().timeIntervalSince(startTime)

        } catch {
            print("❌ Hybrid engine failed: \(error.localizedDescription)")
            return HybridReport(
                targetPath: directory.path,
                totalFiles: 0,
                findings: [],
                executionTime: 0,
                error: error.localizedDescription
            )
        }

        // Count files using our core infrastructure
        let totalFiles = (try? FileUtils.findSwiftFiles(in: directory).count) ?? 0

        let report = HybridReport(
            targetPath: directory.path,
            totalFiles: totalFiles,
            findings: allFindings,
            executionTime: executionTime
        )

        return report
    }

    /// Run tests for a specific rule pack efficiently
    private static func runRulePack(
        rulePack: String,
        parsedFiles: [SourceFileSyntax]
    ) async -> [HybridFinding] {

        switch rulePack.lowercased() {
        case "tca":
            return await runTCARules(parsedFiles: parsedFiles)
        case "swiftui":
            return await runSwiftUIRules(parsedFiles: parsedFiles)
        case "general":
            return await runGeneralRules(parsedFiles: parsedFiles)
        case "performance":
            return await runPerformanceRules(parsedFiles: parsedFiles)
        default:
            print("⚠️ Unknown rule pack: \(rulePack)")
            return []
        }
    }

    /// Run TCA rules efficiently
    private static func runTCARules(parsedFiles: [SourceFileSyntax]) async -> [HybridFinding] {
        var findings: [HybridFinding] = []

        print("   📖 Running TCA analysis on \(parsedFiles.count) files")

        // Run each TCA rule on the same parsed files
        let tcaRules = registerTCARules()

        for (index, rule) in tcaRules.enumerated() {
            do {
                let violations = try rule.validate(sourceFiles: parsedFiles)

                for violation in violations.violations {
                    let finding = HybridFinding(
                        ruleName: "\(type(of: rule))",
                        severity: violation.severity,
                        message: violation.message,
                        file: violation.location?.file ?? "",
                        line: violation.location?.line ?? 0,
                        suggestion: violation.suggestion ?? ""
                    )
                    findings.append(finding)
                }

                if violations.violations.count > 0 {
                    print("   ✅ TCA Rule \(index + 1): \(violations.violations.count) violations")
                }

            } catch {
                print("   ❌ TCA Rule \(index + 1) failed: \(error.localizedDescription)")
            }
        }

        return findings
    }

    /// Run SwiftUI rules efficiently
    private static func runSwiftUIRules(parsedFiles: [SourceFileSyntax]) async -> [HybridFinding] {
        var findings: [HybridFinding] = []

        print("   📖 Running SwiftUI analysis on \(parsedFiles.count) files")

        // Run each SwiftUI rule on the same parsed files
        let swiftUIRules = registerSwiftUIRules()

        for (index, rule) in swiftUIRules.enumerated() {
            do {
                let violations = try rule.validate(sourceFiles: parsedFiles)

                for violation in violations.violations {
                    let finding = HybridFinding(
                        ruleName: "\(type(of: rule))",
                        severity: violation.severity,
                        message: violation.message,
                        file: violation.location?.file ?? "",
                        line: violation.location?.line ?? 0,
                        suggestion: violation.suggestion ?? ""
                    )
                    findings.append(finding)
                }

                if violations.violations.count > 0 {
                    print("   ✅ SwiftUI Rule \(index + 1): \(violations.violations.count) violations")
                }

            } catch {
                print("   ❌ SwiftUI Rule \(index + 1) failed: \(error.localizedDescription)")
            }
        }

        return findings
    }

    /// Run General rules efficiently
    private static func runGeneralRules(parsedFiles: [SourceFileSyntax]) async -> [HybridFinding] {
        var findings: [HybridFinding] = []

        print("   📖 Running General analysis on \(parsedFiles.count) files")

        // Run each General rule on the same parsed files
        let generalRules = registerGeneralRules()

        for (index, rule) in generalRules.enumerated() {
            do {
                let violations = try rule.validate(sourceFiles: parsedFiles)

                for violation in violations.violations {
                    let finding = HybridFinding(
                        ruleName: "\(type(of: rule))",
                        severity: violation.severity,
                        message: violation.message,
                        file: violation.location?.file ?? "",
                        line: violation.location?.line ?? 0,
                        suggestion: violation.suggestion ?? ""
                    )
                    findings.append(finding)
                }

                if violations.violations.count > 0 {
                    print("   ✅ General Rule \(index + 1): \(violations.violations.count) violations")
                }

            } catch {
                print("   ❌ General Rule \(index + 1) failed: \(error.localizedDescription)")
            }
        }

        return findings
    }

    /// Run Performance rules efficiently
    private static func runPerformanceRules(parsedFiles: [SourceFileSyntax]) async -> [HybridFinding] {
        var findings: [HybridFinding] = []

        print("   ⚠️ Performance rules temporarily disabled")

        return findings
    }
}

/// Test finding representation
public struct HybridFinding {
    let ruleName: String
    let severity: ViolationSeverity
    let message: String
    let file: String
    let line: Int
    let suggestion: String
}

/// Hybrid validation report
public struct HybridReport {
    let targetPath: String
    let totalFiles: Int
    let findings: [HybridFinding]
    let executionTime: TimeInterval
    let error: String?

    init(targetPath: String, totalFiles: Int, findings: [HybridFinding], executionTime: TimeInterval, error: String? = nil) {
        self.targetPath = targetPath
        self.totalFiles = totalFiles
        self.findings = findings
        self.executionTime = executionTime
        self.error = error
    }

    /// Generate formatted report
    public func generateReport() -> String {
        if let error = error {
            return """
            ╔══════════════════════════════════════════════════════════════════════════════╗
            ║                     ❌ HYBRID VALIDATION FAILED                         ║
            ╚══════════════════════════════════════════════════════════════════════════════╝

            🎯 Target: \(targetPath)
            ⏱️  Execution Time: \(String(format: "%.2f", executionTime))s
            ❌ Error: \(error)
            """
        }

        let healthScore = findings.isEmpty ? 100 : max(0, 100 - (findings.count / 50))

        return """
        ╔══════════════════════════════════════════════════════════════════════════════╗
        ║                 🧠 HYBRID SMITH VALIDATION - ARCHITECTURAL REPORT          ║
        ╚══════════════════════════════════════════════════════════════════════════════╝

        📊 VALIDATION SUMMARY
           🎯 Target: \(targetPath)
           📁 Files Analyzed: \(totalFiles)
           📋 Rule Packs: TCA, SwiftUI, General
           ⏱️  Execution Time: \(String(format: "%.2f", executionTime))s
           💪 Health Score: \(healthScore)%

        \(findingsSummary)
        \(detailedFindings)
        """
    }

    private var findingsSummary: String {
        if findings.isEmpty {
            return "✅ NO VIOLATIONS DETECTED - Excellent architectural health!"
        }

        let criticalCount = findings.filter { $0.severity == .critical }.count
        let highCount = findings.filter { $0.severity == .high }.count
        let mediumCount = findings.filter { $0.severity == .medium }.count
        let lowCount = findings.filter { $0.severity == .low }.count

        return """
        🚨 VIOLATIONS OVERVIEW
           Total Findings: \(findings.count)

           🔴 Critical: \(criticalCount)
           🟠 High: \(highCount)
           🟡 Medium: \(mediumCount)
           🟢 Low: \(lowCount)
        """
    }

    private var detailedFindings: String {
        if findings.isEmpty { return "" }

        let groupedFindings = Dictionary(grouping: findings) { $0.ruleName }

        var result = "\n📋 DETAILED FINDINGS:\n"
        result += String(repeating: "─", count: 80) + "\n"

        for (ruleName, ruleFindings) in groupedFindings.sorted(by: { $0.key < $1.key }) {
            result += "\n📂 \(ruleName)\n"
            result += String(repeating: "─", count: 40) + "\n"

            // Show top 5 findings per rule to avoid overwhelming output
            for finding in ruleFindings.prefix(5).sorted(by: {
                severityOrder($0.severity) < severityOrder($1.severity)
            }) {
                let emoji = severityEmoji(finding.severity)
                let fileName = URL(fileURLWithPath: finding.file).lastPathComponent
                result += "   • \(emoji) \(fileName):\(finding.line)\n"
                result += "     \(finding.message)\n"
                if !finding.suggestion.isEmpty {
                    result += "     💡 \(finding.suggestion)\n"
                }
                result += "\n"
            }

            if ruleFindings.count > 5 {
                result += "   ... and \(ruleFindings.count - 5) more findings\n\n"
            }
        }

        return result
    }

    private func severityEmoji(_ severity: ViolationSeverity) -> String {
        switch severity {
        case .critical: return "🔴"
        case .high: return "🟠"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }

    private func severityOrder(_ severity: ViolationSeverity) -> Int {
        switch severity {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}