// ScrollValidationTests.swift
// Comprehensive tests running smith-validation against Scroll source code

import Testing
import Foundation
import SQLite

@testable import smith_validation

struct ScrollValidationTests {

    @Test("Run complete architectural analysis against Scroll source code")
    func testScrollSourceCodeAnalysis() throws {
        let scrollPath = "/Volumes/Plutopian/_Developer/Scroll/source/Scroll"
        
        // Check if Scroll source code exists, record issue if not available
        guard FileManager.default.fileExists(atPath: scrollPath) else {
            // Record issue to skip test gracefully
            Issue.record("Scroll source code not found at \(scrollPath). Skipping Scroll validation test.")
            return
        }
        
        // Create the analyzer and run analysis
        let analyzer = FileBackedAnalyzer()
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = try analyzer.analyzeProject(at: scrollPath, reloadRules: true)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Core architectural analysis results
            #expect(result.summary.totalFiles > 0, "Should analyze files in Scroll project")
            #expect(result.summary.totalLines > 0, "Should count lines of code")
            #expect(result.summary.healthScore >= 0, "Health score should be valid")
            #expect(result.summary.healthScore <= 100, "Health score should be valid")
            
            // AI-friendly architectural insights
            print("🏗️ Scroll Architectural Analysis Results:")
            print("   📁 Total Files: \(result.summary.totalFiles)")
            print("   📝 Total Lines: \(result.summary.totalLines)")
            print("   🎯 Health Score: \(result.summary.healthScore)/100")
            print("   ⚠️ Violations: \(result.summary.violationsCount)")
            print("   ⏱️ Analysis Time: \(String(format: "%.2f", duration))s")
            
            // Severity breakdown analysis
            let breakdown = result.summary.severityBreakdown
            print("   🔍 Severity Breakdown:")
            print("      🚨 Critical: \(breakdown.critical)")
            print("      ⚠️ High: \(breakdown.high)")
            print("      ⚡ Medium: \(breakdown.medium)")
            print("      💡 Low: \(breakdown.low)")
            
            // Automation potential
            let automation = result.summary.automation
            print("   🤖 Automation Potential:")
            print("      Automatable Fixes: \(automation.automatableFixes)")
            print("      Average Confidence: \(String(format: "%.1f%%", automation.averageConfidence * 100))")
            
            // Analysis insights based on actual violations found
            if result.summary.violationsCount == 0 {
                print("   ✅ Excellent: No architectural violations detected")
            } else {
                print("   📋 Key Findings:")
                for finding in result.findings.prefix(5) {
                    print("      • \(finding.ruleName): \(finding.actualValue)")
                }
            }
            
            print("   🧠 AI-Processed Insights:")
            if result.summary.violationsCount > 0 {
                print("      • 🔧 Address violations systematically using TypeScript rule analysis")
            } else {
                print("      • 🎯 Clean architecture detected with current rule set")
            }
            
        } catch {
            // Report test failure with detailed error
            #expect(Bool(false), "Scroll analysis should not fail: \(error)")
        }
    }
    
    @Test("Validate TypeScript rule performance on large codebase")
    func testTypeScriptRulePerformance() throws {
        let scrollPath = "/Volumes/Plutopian/_Developer/Scroll/source/Scroll"
        
        // Check if Scroll source code exists, record issue if not available
        guard FileManager.default.fileExists(atPath: scrollPath) else {
            Issue.record("Scroll source code not found at \(scrollPath). Skipping performance test.")
            return
        }
        
        let analyzer = FileBackedAnalyzer()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try analyzer.analyzeProject(at: scrollPath, reloadRules: false)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Performance assertions
            #expect(duration < 30.0, "Analysis should complete within 30 seconds")
            #expect(result.summary.totalFiles > 0, "Should process files")
            
            print("⚡ Performance Metrics:")
            print("   Analysis Time: \(String(format: "%.2f", duration))s")
            print("   Files per Second: \(String(format: "%.1f", Double(result.summary.totalFiles) / duration))")
            print("   Lines per Second: \(String(format: "%.0f", Double(result.summary.totalLines) / duration))")
            
            // Performance quality assessment
            if duration < 10.0 {
                print("   🚀 Excellent: Sub-10 second analysis")
            } else if duration < 20.0 {
                print("   ⚡ Good: Sub-20 second analysis")
            } else {
                print("   ⚠️ Needs Optimization: Analysis could be faster")
            }
            
        } catch {
            #expect(Bool(false), "Performance test should not fail: \(error)")
        }
    }
}
