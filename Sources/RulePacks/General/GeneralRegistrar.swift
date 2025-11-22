// Sources/RulePacks/General/GeneralRegistrar.swift
// General Architecture RulePack Registration

import Foundation
import SmithValidationCore
// PKL integration temporarily disabled
// @_exported import GeneratedConfig

/// Registrar for General Architecture rules
public func registerGeneralRules(with config: Any? = nil) -> [any ValidatableRule] {
    var rules: [any ValidatableRule] = []

    // Rule 1.1: Circular Dependencies
    rules.append(GeneralRule_1_CircularDependencies())

    // Rule 1.2: Module Dependencies
    rules.append(GeneralRule_1_2_ModuleDependencies())

    return rules
}