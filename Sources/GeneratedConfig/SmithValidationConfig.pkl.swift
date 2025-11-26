// Code generated from Pkl module `SmithValidationConfig`. DO NOT EDIT.
import Foundation
import PklSwift

public enum SmithValidationConfig {}

extension SmithValidationConfig {
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "SmithValidationConfig"

        /// Per-domain configuration
        public var domainConfig: DomainConfig

        /// Global validation settings
        public var globalSettings: GlobalSettings

        public init(
            domainConfig: DomainConfig,
            globalSettings: GlobalSettings
        ) {
            self.domainConfig = domainConfig
            self.globalSettings = globalSettings
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `SmithValidationConfig.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> SmithValidationConfig.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `SmithValidationConfig.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> SmithValidationConfig.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}

public struct DomainConfig: Decodable, Hashable, Sendable {
    /// TCA-specific configuration
    public var tca: TCAConfig

    /// SwiftUI-specific configuration
    public var swiftui: SwiftUIConfig

    /// Performance-specific configuration
    public var performance: PerformanceConfig

    /// General architecture configuration
    public var general: GeneralConfig

    public init(
        tca: TCAConfig,
        swiftui: SwiftUIConfig,
        performance: PerformanceConfig,
        general: GeneralConfig
    ) {
        self.tca = tca
        self.swiftui = swiftui
        self.performance = performance
        self.general = general
    }
}

public struct TCAConfig: Decodable, Hashable, Sendable {
    /// Rule 1.1: Monolithic Features
    public var rule_1_1_MonolithicFeatures: TCA_Rule_1_1_MonolithicFeatures

    /// Rule 1.2: Closure Injection
    public var rule_1_2_ClosureInjection: TCA_Rule_1_2_ClosureInjection

    /// Rule 1.3: Code Duplication
    public var rule_1_3_CodeDuplication: TCA_Rule_1_3_CodeDuplication

    /// Rule 1.4: Unclear Organization
    public var rule_1_4_UnclearOrganization: TCA_Rule_1_4_UnclearOrganization

    /// Rule 1.5: Tightly Coupled State
    public var rule_1_5_TightlyCoupledState: TCA_Rule_1_5_TightlyCoupledState

    /// Rule 2.1: Error Handling
    public var rule_2_1_ErrorHandling: TCA_Rule_2_1_ErrorHandling

    /// Rule 2.2: Reducible Complexity
    public var rule_2_2_ReducibleComplexity: TCA_Rule_2_2_ReducibleComplexity

    public init(
        rule_1_1_MonolithicFeatures: TCA_Rule_1_1_MonolithicFeatures,
        rule_1_2_ClosureInjection: TCA_Rule_1_2_ClosureInjection,
        rule_1_3_CodeDuplication: TCA_Rule_1_3_CodeDuplication,
        rule_1_4_UnclearOrganization: TCA_Rule_1_4_UnclearOrganization,
        rule_1_5_TightlyCoupledState: TCA_Rule_1_5_TightlyCoupledState,
        rule_2_1_ErrorHandling: TCA_Rule_2_1_ErrorHandling,
        rule_2_2_ReducibleComplexity: TCA_Rule_2_2_ReducibleComplexity
    ) {
        self.rule_1_1_MonolithicFeatures = rule_1_1_MonolithicFeatures
        self.rule_1_2_ClosureInjection = rule_1_2_ClosureInjection
        self.rule_1_3_CodeDuplication = rule_1_3_CodeDuplication
        self.rule_1_4_UnclearOrganization = rule_1_4_UnclearOrganization
        self.rule_1_5_TightlyCoupledState = rule_1_5_TightlyCoupledState
        self.rule_2_1_ErrorHandling = rule_2_1_ErrorHandling
        self.rule_2_2_ReducibleComplexity = rule_2_2_ReducibleComplexity
    }
}

public struct TCA_Rule_1_1_MonolithicFeatures: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxMethods: Int
    public var maxNestedTypes: Int
    public var maxProperties: Int
    public var maxEstimatedComplexity: Int

    public init(
        enabled: Bool,
        severity: String,
        maxMethods: Int,
        maxNestedTypes: Int,
        maxProperties: Int,
        maxEstimatedComplexity: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxMethods = maxMethods
        self.maxNestedTypes = maxNestedTypes
        self.maxProperties = maxProperties
        self.maxEstimatedComplexity = maxEstimatedComplexity
    }
}

public struct TCA_Rule_1_2_ClosureInjection: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxServiceClients: Int
    public var maxDependencyMethods: Int
    public var maxGlobalDependencies: Int

    public init(
        enabled: Bool,
        severity: String,
        maxServiceClients: Int,
        maxDependencyMethods: Int,
        maxGlobalDependencies: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxServiceClients = maxServiceClients
        self.maxDependencyMethods = maxDependencyMethods
        self.maxGlobalDependencies = maxGlobalDependencies
    }
}

public struct TCA_Rule_1_3_CodeDuplication: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var minSimilarityThreshold: Double
    public var maxDuplicateLines: Int

    public init(
        enabled: Bool,
        severity: String,
        minSimilarityThreshold: Double,
        maxDuplicateLines: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.minSimilarityThreshold = minSimilarityThreshold
        self.maxDuplicateLines = maxDuplicateLines
    }
}

public struct TCA_Rule_1_4_UnclearOrganization: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxFeaturesPerFile: Int
    public var maxMixedResponsibilityClasses: Int
    public var maxNestedFeatures: Int

    public init(
        enabled: Bool,
        severity: String,
        maxFeaturesPerFile: Int,
        maxMixedResponsibilityClasses: Int,
        maxNestedFeatures: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxFeaturesPerFile = maxFeaturesPerFile
        self.maxMixedResponsibilityClasses = maxMixedResponsibilityClasses
        self.maxNestedFeatures = maxNestedFeatures
    }
}

public struct TCA_Rule_1_5_TightlyCoupledState: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxStateProperties: Int
    public var maxCrossFeatureReferences: Int
    public var maxDirectStateMutations: Int

    public init(
        enabled: Bool,
        severity: String,
        maxStateProperties: Int,
        maxCrossFeatureReferences: Int,
        maxDirectStateMutations: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxStateProperties = maxStateProperties
        self.maxCrossFeatureReferences = maxCrossFeatureReferences
        self.maxDirectStateMutations = maxDirectStateMutations
    }
}

public struct TCA_Rule_2_1_ErrorHandling: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var requireResultHandling: Bool
    public var maxUnhandledAsyncOperations: Int
    public var requireErrorState: Bool

    public init(
        enabled: Bool,
        severity: String,
        requireResultHandling: Bool,
        maxUnhandledAsyncOperations: Int,
        requireErrorState: Bool
    ) {
        self.enabled = enabled
        self.severity = severity
        self.requireResultHandling = requireResultHandling
        self.maxUnhandledAsyncOperations = maxUnhandledAsyncOperations
        self.requireErrorState = requireErrorState
    }
}

public struct TCA_Rule_2_2_ReducibleComplexity: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxSwitchCases: Int
    public var maxNestingDepth: Int
    public var maxAsyncOperations: Int

    public init(
        enabled: Bool,
        severity: String,
        maxSwitchCases: Int,
        maxNestingDepth: Int,
        maxAsyncOperations: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxSwitchCases = maxSwitchCases
        self.maxNestingDepth = maxNestingDepth
        self.maxAsyncOperations = maxAsyncOperations
    }
}

public struct SwiftUIConfig: Decodable, Hashable, Sendable {
    /// Rule 1.1: View Body Complexity
    public var rule_1_1_ViewBodyComplexity: SwiftUI_Rule_1_1_ViewBodyComplexity

    /// Rule 1.2: State Management
    public var rule_1_2_StateManagement: SwiftUI_Rule_1_2_StateManagement

    public init(
        rule_1_1_ViewBodyComplexity: SwiftUI_Rule_1_1_ViewBodyComplexity,
        rule_1_2_StateManagement: SwiftUI_Rule_1_2_StateManagement
    ) {
        self.rule_1_1_ViewBodyComplexity = rule_1_1_ViewBodyComplexity
        self.rule_1_2_StateManagement = rule_1_2_StateManagement
    }
}

public struct SwiftUI_Rule_1_1_ViewBodyComplexity: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxViewBodyLines: Int
    public var maxNestingDepth: Int
    public var maxConditionalStatements: Int
    public var maxViewModifiers: Int

    public init(
        enabled: Bool,
        severity: String,
        maxViewBodyLines: Int,
        maxNestingDepth: Int,
        maxConditionalStatements: Int,
        maxViewModifiers: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxViewBodyLines = maxViewBodyLines
        self.maxNestingDepth = maxNestingDepth
        self.maxConditionalStatements = maxConditionalStatements
        self.maxViewModifiers = maxViewModifiers
    }
}

public struct SwiftUI_Rule_1_2_StateManagement: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxStateProperties: Int
    public var maxComplexStateProperties: Int

    public init(
        enabled: Bool,
        severity: String,
        maxStateProperties: Int,
        maxComplexStateProperties: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxStateProperties = maxStateProperties
        self.maxComplexStateProperties = maxComplexStateProperties
    }
}

public struct PerformanceConfig: Decodable, Hashable, Sendable {
    /// Rule 1.1: Memory Management
    public var rule_1_1_MemoryManagement: Performance_Rule_1_1_MemoryManagement

    /// Rule 1.2: CPU Usage Patterns
    public var rule_1_2_CPUUsagePatterns: Performance_Rule_1_2_CPUUsagePatterns

    /// Rule 1.3: Performance Anti-Patterns
    public var rule_1_3_PerformanceAntiPatterns: Performance_Rule_1_3_PerformanceAntiPatterns

    /// Rule 1.4: Concurrency Issues
    public var rule_1_4_ConcurrencyIssues: Performance_Rule_1_4_ConcurrencyIssues

    public init(
        rule_1_1_MemoryManagement: Performance_Rule_1_1_MemoryManagement,
        rule_1_2_CPUUsagePatterns: Performance_Rule_1_2_CPUUsagePatterns,
        rule_1_3_PerformanceAntiPatterns: Performance_Rule_1_3_PerformanceAntiPatterns,
        rule_1_4_ConcurrencyIssues: Performance_Rule_1_4_ConcurrencyIssues
    ) {
        self.rule_1_1_MemoryManagement = rule_1_1_MemoryManagement
        self.rule_1_2_CPUUsagePatterns = rule_1_2_CPUUsagePatterns
        self.rule_1_3_PerformanceAntiPatterns = rule_1_3_PerformanceAntiPatterns
        self.rule_1_4_ConcurrencyIssues = rule_1_4_ConcurrencyIssues
    }
}

public struct Performance_Rule_1_1_MemoryManagement: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxRetainCycles: Int
    public var maxStrongReferences: Int
    public var maxMemoryAllocations: Int

    public init(
        enabled: Bool,
        severity: String,
        maxRetainCycles: Int,
        maxStrongReferences: Int,
        maxMemoryAllocations: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxRetainCycles = maxRetainCycles
        self.maxStrongReferences = maxStrongReferences
        self.maxMemoryAllocations = maxMemoryAllocations
    }
}

public struct Performance_Rule_1_2_CPUUsagePatterns: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxNestedLoops: Int
    public var maxRecursiveDepth: Int
    public var maxComplexCalculations: Int

    public init(
        enabled: Bool,
        severity: String,
        maxNestedLoops: Int,
        maxRecursiveDepth: Int,
        maxComplexCalculations: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxNestedLoops = maxNestedLoops
        self.maxRecursiveDepth = maxRecursiveDepth
        self.maxComplexCalculations = maxComplexCalculations
    }
}

public struct Performance_Rule_1_3_PerformanceAntiPatterns: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxStringConcatenations: Int
    public var maxForceCasts: Int
    public var maxLargeValueTypes: Int

    public init(
        enabled: Bool,
        severity: String,
        maxStringConcatenations: Int,
        maxForceCasts: Int,
        maxLargeValueTypes: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxStringConcatenations = maxStringConcatenations
        self.maxForceCasts = maxForceCasts
        self.maxLargeValueTypes = maxLargeValueTypes
    }
}

public struct Performance_Rule_1_4_ConcurrencyIssues: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxSharedResources: Int
    public var maxBlockingCalls: Int
    public var allowMainThreadOperations: Bool

    public init(
        enabled: Bool,
        severity: String,
        maxSharedResources: Int,
        maxBlockingCalls: Int,
        allowMainThreadOperations: Bool
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxSharedResources = maxSharedResources
        self.maxBlockingCalls = maxBlockingCalls
        self.allowMainThreadOperations = allowMainThreadOperations
    }
}

public struct GeneralConfig: Decodable, Hashable, Sendable {
    /// Rule 1.1: Circular Dependencies
    public var rule_1_1_CircularDependencies: General_Rule_1_1_CircularDependencies

    /// Rule 1.2: Module Dependencies
    public var rule_1_2_ModuleDependencies: General_Rule_1_2_ModuleDependencies

    public init(
        rule_1_1_CircularDependencies: General_Rule_1_1_CircularDependencies,
        rule_1_2_ModuleDependencies: General_Rule_1_2_ModuleDependencies
    ) {
        self.rule_1_1_CircularDependencies = rule_1_1_CircularDependencies
        self.rule_1_2_ModuleDependencies = rule_1_2_ModuleDependencies
    }
}

public struct General_Rule_1_1_CircularDependencies: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxDependencyDepth: Int

    public init(
        enabled: Bool,
        severity: String,
        maxDependencyDepth: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxDependencyDepth = maxDependencyDepth
    }
}

public struct General_Rule_1_2_ModuleDependencies: Decodable, Hashable, Sendable {
    public var enabled: Bool
    public var severity: String
    public var maxImportsPerFile: Int
    public var maxDependencyDepth: Int
    public var maxModuleDependencies: Int

    public init(
        enabled: Bool,
        severity: String,
        maxImportsPerFile: Int,
        maxDependencyDepth: Int,
        maxModuleDependencies: Int
    ) {
        self.enabled = enabled
        self.severity = severity
        self.maxImportsPerFile = maxImportsPerFile
        self.maxDependencyDepth = maxDependencyDepth
        self.maxModuleDependencies = maxModuleDependencies
    }
}

public struct GlobalSettings: Decodable, Hashable, Sendable {
    /// Output format for reports
    public var outputFormat: String

    /// Include/exclude file patterns
    public var includePatterns: [String]

    /// Exclude file patterns
    public var excludePatterns: [String]

    /// Maximum number of violations to report
    public var maxViolations: Int

    /// Fail build if violations are found
    public var failOnViolations: Bool

    /// Minimum severity to report
    public var minSeverity: String

    public init(
        outputFormat: String,
        includePatterns: [String],
        excludePatterns: [String],
        maxViolations: Int,
        failOnViolations: Bool,
        minSeverity: String
    ) {
        self.outputFormat = outputFormat
        self.includePatterns = includePatterns
        self.excludePatterns = excludePatterns
        self.maxViolations = maxViolations
        self.failOnViolations = failOnViolations
        self.minSeverity = minSeverity
    }
}