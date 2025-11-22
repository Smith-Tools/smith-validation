// Sources/RulePacks/TCA/TCARegistrar.swift
// TCA RulePack Registration

import Foundation
import SmithValidationCore
// PKL integration temporarily disabled
// @_exported import GeneratedConfig

/// Registrar for TCA architectural rules
public func registerTCARules(with config: Any? = nil) -> [any ValidatableRule] {
    var rules: [any ValidatableRule] = []

    // Rule 1.1: Monolithic Features
    rules.append(TCARule_1_1_MonolithicFeatures())

    // Rule 1.2: Closure Injection
    rules.append(TCARule_1_2_ProperDependencyInjection())

    // Rule 1.3: Code Duplication
    rules.append(TCARule_1_3_CodeDuplication())

    // Rule 1.4: Unclear Organization
    rules.append(TCARule_1_4_UnclearOrganization())

    // Rule 1.5: Tightly Coupled State
    rules.append(TCARule_1_5_TightlyCoupledState())

    // Rule 2.1: Error Handling
    rules.append(TCARule_2_1_ErrorHandling())

    // Rule 2.2: Reducible Complexity
    rules.append(TCARule_2_2_ReducibleComplexity())

    return rules
}