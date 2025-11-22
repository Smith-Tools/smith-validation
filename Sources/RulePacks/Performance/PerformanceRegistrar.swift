// Sources/RulePacks/Performance/PerformanceRegistrar.swift
// Performance Rules Registration

import Foundation
import SmithValidationCore
@_exported import GeneratedConfig

// MARK: - Helper Extensions

extension ArchitecturalViolation.Severity {
    public static func fromString(_ severity: String) -> ArchitecturalViolation.Severity {
        switch severity.lowercased() {
        case "low":
            return .low
        case "medium":
            return .medium
        case "high":
            return .high
        case "critical":
            return .critical
        default:
            return .medium
        }
    }
}

/// Register all Performance architecture rules
public func registerPerformanceRules(with config: SmithValidationConfig.Module? = nil) -> [any ValidatableRule] {
    var rules: [any ValidatableRule] = []

    // Performance Rule 1.1: Memory Management
    if let performanceConfig = config?.domainConfig.performance {
        if performanceConfig.rule_1_1_MemoryManagement.enabled {
            let config = PerformanceRule_1_1_MemoryManagement.Configuration(
                maxRetainCycles: performanceConfig.rule_1_1_MemoryManagement.maxRetainCycles,
                maxStrongReferences: performanceConfig.rule_1_1_MemoryManagement.maxStrongReferences,
                maxMemoryAllocations: performanceConfig.rule_1_1_MemoryManagement.maxMemoryAllocations,
                severity: ArchitecturalViolation.Severity.fromString(performanceConfig.rule_1_1_MemoryManagement.severity)
            )
            rules.append(PerformanceRule_1_1_MemoryManagement(configuration: config))
        }

        // Performance Rule 1.2: CPU Usage Patterns
        if performanceConfig.rule_1_2_CPUUsagePatterns.enabled {
            let config = PerformanceRule_1_2_CPUUsagePatterns.Configuration(
                maxNestedLoops: performanceConfig.rule_1_2_CPUUsagePatterns.maxNestedLoops,
                maxRecursiveDepth: performanceConfig.rule_1_2_CPUUsagePatterns.maxRecursiveDepth,
                maxComplexCalculations: performanceConfig.rule_1_2_CPUUsagePatterns.maxComplexCalculations,
                severity: ArchitecturalViolation.Severity.fromString(performanceConfig.rule_1_2_CPUUsagePatterns.severity)
            )
            rules.append(PerformanceRule_1_2_CPUUsagePatterns(configuration: config))
        }

        // Performance Rule 1.3: Performance Anti-Patterns
        if performanceConfig.rule_1_3_PerformanceAntiPatterns.enabled {
            let config = PerformanceRule_1_3_PerformanceAntiPatterns.Configuration(
                maxStringConcatenations: performanceConfig.rule_1_3_PerformanceAntiPatterns.maxStringConcatenations,
                maxForceCasts: performanceConfig.rule_1_3_PerformanceAntiPatterns.maxForceCasts,
                maxLargeValueTypes: performanceConfig.rule_1_3_PerformanceAntiPatterns.maxLargeValueTypes,
                severity: ArchitecturalViolation.Severity.fromString(performanceConfig.rule_1_3_PerformanceAntiPatterns.severity)
            )
            rules.append(PerformanceRule_1_3_PerformanceAntiPatterns(configuration: config))
        }

        // Performance Rule 1.4: Concurrency Issues
        if performanceConfig.rule_1_4_ConcurrencyIssues.enabled {
            let config = PerformanceRule_1_4_ConcurrencyIssues.Configuration(
                maxSharedResources: performanceConfig.rule_1_4_ConcurrencyIssues.maxSharedResources,
                maxBlockingCalls: performanceConfig.rule_1_4_ConcurrencyIssues.maxBlockingCalls,
                allowMainThreadOperations: performanceConfig.rule_1_4_ConcurrencyIssues.allowMainThreadOperations,
                severity: ArchitecturalViolation.Severity.fromString(performanceConfig.rule_1_4_ConcurrencyIssues.severity)
            )
            rules.append(PerformanceRule_1_4_ConcurrencyIssues(configuration: config))
        }
    } else {
        // Default configurations when no PKL config is provided
        rules.append(PerformanceRule_1_1_MemoryManagement())
        rules.append(PerformanceRule_1_2_CPUUsagePatterns())
        rules.append(PerformanceRule_1_3_PerformanceAntiPatterns())
        rules.append(PerformanceRule_1_4_ConcurrencyIssues())
    }

    return rules
}