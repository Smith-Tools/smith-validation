// Sources/RulePacks/SwiftUI/SwiftUIRegistrar.swift
// SwiftUI RulePack Registration

import Foundation
import SmithValidationCore
// PKL integration temporarily disabled
// @_exported import GeneratedConfig


/// Registrar for SwiftUI rules
public func registerSwiftUIRules(with config: Any? = nil) -> [any ValidatableRule] {
    var rules: [any ValidatableRule] = []

    // Rule 1.1: View Body Complexity
    rules.append(SwiftUIRule_1_1_ViewBodyComplexity())

    // Rule 1.2: State Management
    rules.append(SwiftUIRule_1_2_StateManagement())

    return rules
}