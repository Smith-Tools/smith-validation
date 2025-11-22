// Sources/MaxwellsTCARulesPlugin/MaxwellsTCARulesPlugin.swift
// Swift Compiler Plugin for Maxwell's TCA Architectural Rules
//
// This plugin emits architectural diagnostics during normal Swift compilation,
// eliminating the need for post-pass SwiftSyntax parsing and providing instant feedback.

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Main compiler plugin for Maxwell's TCA architectural rules
@main
struct MaxwellsTCARulesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TCAArchitecturalValidationMacro.self
    ]
}

/// Macro that validates TCA architectural patterns during compilation
public struct TCAArchitecturalValidationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Generate validation code that runs at compile time
        let diagnostics = generateTCADiagnostics(for: declaration, in: context)

        // Emit diagnostics directly during compilation
        for diagnostic in diagnostics {
            context.diagnose(diagnostic)
        }

        return []
    }

    /// Generate TCA architectural diagnostics for the given declaration
    private static func generateTCADiagnostics(
        for declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []

        // Extract source file context
        let sourceLocation = declaration.endLocation(converter: context.locationConverter)
        let filePath = sourceLocation?.file ?? ""

        // Rule 1.1: Monolithic Features - Check State struct properties
        if let structDecl = declaration.as(StructDeclSyntax.self),
           isTCAState(structDecl) {

            let propertyCount = countProperties(in: structDecl)
            if propertyCount > 15 {
                diagnostics.append(Diagnostic(
                    id: MessageID(domain: "MaxwellsTCARules", id: "monolithic-state"),
                    message: .string("🔴 TCA Rule 1.1: State struct has \(propertyCount) properties (>15 threshold) - consider splitting into multiple features"),
                    severity: .error,
                    location: findLocation(in: context, at: declaration)
                ))
            }
        }

        // Rule 1.1: Monolithic Features - Check Action enum cases
        if let enumDecl = declaration.as(EnumDeclSyntax.self),
           isTCAAction(enumDecl) {

            let caseCount = countEnumCases(in: enumDecl)
            if caseCount > 40 {
                diagnostics.append(Diagnostic(
                    id: MessageID(domain: "MaxwellsTCARules", id: "monolithic-action"),
                    message: .string("🔴 TCA Rule 1.1: Action enum has \(caseCount) cases (>40 threshold) - suggests too much responsibility"),
                    severity: .error,
                    location: findLocation(in: context, at: declaration)
                ))
            }
        }

        return diagnostics
    }

    // MARK: - Helper Methods

    /// Check if struct is a TCA State (conforms to @ObservableState or has typical naming)
    private static func isTCAState(_ structDecl: StructDeclSyntax) -> Bool {
        let name = structDecl.name.text

        // Check naming convention
        if name.hasSuffix("State") || name == "State" {
            return true
        }

        // Check for @ObservableState attribute
        for attribute in structDecl.attributes {
            if let attributeName = attribute.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
               attributeName == "ObservableState" {
                return true
            }
        }

        return false
    }

    /// Check if enum is a TCA Action (conforms to @ObservableState or has typical naming)
    private static func isTCAAction(_ enumDecl: EnumDeclSyntax) -> Bool {
        let name = enumDecl.name.text

        // Check naming convention
        if name.hasSuffix("Action") || name == "Action" {
            return true
        }

        return false
    }

    /// Count properties in a struct declaration
    private static func countProperties(in structDecl: StructDeclSyntax) -> Int {
        var count = 0

        for member in structDecl.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self),
               variableDecl.bindings.count > 0 {
                // This is a property declaration
                count += variableDecl.bindings.count
            }
        }

        return count
    }

    /// Count enum cases in an enum declaration
    private static func countEnumCases(in enumDecl: EnumDeclSyntax) -> Int {
        var count = 0

        for member in enumDecl.memberBlock.members {
            if member.decl.is(EnumCaseDeclSyntax.self) {
                count += 1
            }
        }

        return count
    }

    /// Find the appropriate location for diagnostics
    private static func findLocation(
        in context: some MacroExpansionContext,
        at declaration: some DeclGroupSyntax
    ) -> Location {
        return Location(
            filePath: declaration.location(converter: context.locationConverter)?.file ?? "",
            line: declaration.location(converter: context.locationConverter)?.line ?? 0,
            column: declaration.location(converter: context.locationConverter)?.column ?? 0
        )
    }
}