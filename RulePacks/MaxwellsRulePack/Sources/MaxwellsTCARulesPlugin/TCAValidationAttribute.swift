// Sources/MaxwellsTCARulesPlugin/TCAValidationAttribute.swift
// TCA Validation Attribute for Enabling Architectural Rules
//
// Apply @TCAValidation to TCA State and Action declarations to enable
// compile-time architectural validation.

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Macro attribute for enabling TCA architectural validation
///
/// Usage:
/// ```swift
/// @TCAValidation
/// struct FeatureState: ObservableState {
///     // TCA properties will be validated during compilation
/// }
///
/// @TCAValidation
/// enum FeatureAction {
///     // TCA cases will be validated during compilation
/// }
/// ```
@attached(member, names: arbitrary)
public macro TCAValidation() = #externalMacro(module: "MaxwellsTCARulesPlugin", type: "TCAArchitecturalValidationMacro")